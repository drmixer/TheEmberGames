-- ServerScript: CharacterSpawner.lua
-- Handles character spawning for The Ember Games
-- Manages player spawn positions, spawn platforms, and arena entry
-- Updated to support Voxel Terrain via Raycasting

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LobbyService = require(script.Parent.LobbyService)
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local CharacterSpawner = {}
CharacterSpawner.spawnPositions = {}
CharacterSpawner.spawnPlatforms = {}
CharacterSpawner.playersSpawned = {}
CharacterSpawner.playersOnPlatform = {}
CharacterSpawner.countdownActive = false
CharacterSpawner.platformsCreated = false

-- Platform configuration
local PLATFORM_CONFIG = {
    SIZE = Vector3.new(6, 1, 6),
    HEIGHT = 4, -- Height above ground
    MATERIAL = Enum.Material.Metal,
    COLOR = Color3.fromRGB(80, 80, 80), -- Dark gray
    GLOW_COLOR = Color3.fromRGB(255, 140, 0), -- Orange glow during countdown
}

local spawnerRemoteEvent = Instance.new("RemoteEvent")
spawnerRemoteEvent.Name = "SpawnerRemoteEvent"
spawnerRemoteEvent.Parent = ReplicatedStorage

local function initializeSpawnPositions()
    local arenaCenter = Vector3.new(0, 0, 0)
    local radius = 35 -- Distance from cornucopia
    
    CharacterSpawner.spawnPositions = {}
    
    for i = 1, 24 do
        local angle = (i - 1) * (2 * math.pi / 24)
        local x = arenaCenter.X + radius * math.cos(angle)
        local z = arenaCenter.Z + radius * math.sin(angle)
        
        -- Raycast to find terrain height
        local origin = Vector3.new(x, 200, z)
        local result = workspace:Raycast(origin, Vector3.new(0, -300, 0))
        local groundY = result and result.Position.Y or 8 -- Default to 8 if nil (flat cornucopia level)
        
        local platformY = groundY + PLATFORM_CONFIG.HEIGHT
        
        -- Position is center of the platform part
        local platformPos = Vector3.new(x, platformY, z)
        
        table.insert(CharacterSpawner.spawnPositions, {
            position = Vector3.new(x, platformY + 4, z), -- Player feet pos
            angle = angle,
            platformPosition = platformPos
        })
    end
    print("[CharacterSpawner] Initialized spawn positions via Raycast")
end

function CharacterSpawner:createSpawnPlatforms()
    if CharacterSpawner.platformsCreated then return CharacterSpawner.spawnPlatforms end
    
    -- Initialize positions first to ensure we have latest terrain data
    initializeSpawnPositions()
    
    local folder = workspace:FindFirstChild("SpawnPlatforms") or Instance.new("Folder")
    folder.Name = "SpawnPlatforms"
    folder.Parent = workspace
    folder:ClearAllChildren()
    
    CharacterSpawner.spawnPlatforms = {}
    
    for i, data in ipairs(CharacterSpawner.spawnPositions) do
        local platform = Instance.new("Part")
        platform.Name = "Platform_" .. i
        platform.Size = PLATFORM_CONFIG.SIZE
        platform.Position = data.platformPosition
        platform.Anchored = true
        platform.CanCollide = true
        platform.Material = PLATFORM_CONFIG.MATERIAL
        platform.Color = PLATFORM_CONFIG.COLOR
        platform.Parent = folder
        
        -- Pillar
        local pillarHeight = PLATFORM_CONFIG.HEIGHT
        local pillar = Instance.new("Part")
        pillar.Size = Vector3.new(2, pillarHeight, 2)
        -- Position should be below platform. Platform Y is center.
        -- Pillar bottom is at GroundY. Pillar Top is at (PlatformY - SIZE.Y/2).
        -- Easier math: just place it halfway between platform and ground.
        pillar.Position = data.platformPosition - Vector3.new(0, pillarHeight/2 + 0.5, 0)
        pillar.Anchored = true
        pillar.CanCollide = true
        pillar.Material = Enum.Material.Concrete
        pillar.Color = Color3.fromRGB(60,60,60)
        pillar.Parent = folder
        
        -- Glow
        local glow = Instance.new("Part")
        glow.Name = "GlowRing"
        glow.Size = Vector3.new(6, 0.2, 6)
        glow.Position = data.platformPosition + Vector3.new(0, 0.6, 0)
        glow.Anchored = true
        glow.CanCollide = false
        glow.Material = Enum.Material.Neon
        glow.Color = PLATFORM_CONFIG.COLOR
        glow.Transparency = 0.5
        glow.Parent = platform -- Attach to platform so it cleans up with it
        
        table.insert(CharacterSpawner.spawnPlatforms, platform)
    end
    
    CharacterSpawner.platformsCreated = true
end

function CharacterSpawner:activatePlatformGlow(active)
    for _, plat in ipairs(CharacterSpawner.spawnPlatforms) do
        local glow = plat:FindFirstChild("GlowRing")
        if glow then
            glow.Color = active and PLATFORM_CONFIG.GLOW_COLOR or PLATFORM_CONFIG.COLOR
            glow.Transparency = active and 0.2 or 0.5
        end
    end
end

function CharacterSpawner:setPlayerMovementLock(player, locked)
    if not player.Character then return end
    local hum = player.Character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = locked and 0 or 16
        hum.JumpPower = locked and 0 or 50
    end
    spawnerRemoteEvent:FireClient(player, "MOVEMENT_LOCKED", locked)
end

function CharacterSpawner:spawnPlayer(player)
    if CharacterSpawner.playersSpawned[player] then return end
    
    -- Simple round robin spawn assignment
    local index = (#Players:GetPlayers() % 24) + 1
    if LobbyService.lobbyPlayers[player] then
        index = LobbyService.lobbyPlayers[player].districtNumber or index
    end
    
    local data = CharacterSpawner.spawnPositions[index]
    if not data then return end
    
    player:LoadCharacter() -- Force Respawn
    
    -- Teleport when Character loads
    local connection
    connection = player.CharacterAdded:Connect(function(char)
        connection:Disconnect()
        local root = char:WaitForChild("HumanoidRootPart")
        local hum = char:WaitForChild("Humanoid")
        task.wait(0.1)
        root.CFrame = CFrame.new(data.position, Vector3.new(0, data.position.Y, 0)) -- Look at center
        
        if CharacterSpawner.countdownActive then
            CharacterSpawner:setPlayerMovementLock(player, true)
        end
        
        -- Give Items
        local inv = require(script.Parent.InventoryController)
        inv:addItem(player, "Apples", 2)
        inv:addItem(player, "Water", 1)
        
        CharacterSpawner.playersSpawned[player] = true
        spawnerRemoteEvent:FireClient(player, "SPAWNED_ON_PLATFORM", index, data.position)
    end)
end

function CharacterSpawner:startCountdown(duration)
    CharacterSpawner.countdownActive = true
    CharacterSpawner:activatePlatformGlow(true)
    for plr, _ in pairs(CharacterSpawner.playersSpawned) do
        CharacterSpawner:setPlayerMovementLock(plr, true)
    end
    spawnerRemoteEvent:FireAllClients("COUNTDOWN_STARTED", duration)
end

function CharacterSpawner:endCountdown()
    CharacterSpawner.countdownActive = false
    CharacterSpawner:activatePlatformGlow(false)
    for plr, _ in pairs(CharacterSpawner.playersSpawned) do
        CharacterSpawner:setPlayerMovementLock(plr, false)
    end
    
    -- Start Match
    local MatchService = require(script.Parent.MatchService)
    MatchService:startMatch()
end

function CharacterSpawner:init()
    print("[CharacterSpawner] Initializing")
    
    -- Delay init slightly to let terrain generate
    task.delay(2, function()
        CharacterSpawner:createSpawnPlatforms()
    end)
end

return CharacterSpawner
