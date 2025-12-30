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
    

        
    -- Raycast setup to find floor only (ignore trees)
    local mapBase = workspace:FindFirstChild("MapBase")
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    if mapBase then
        raycastParams.FilterDescendantsInstances = {mapBase}
    else
        warn("[CharacterSpawner] MapBase not found, raycast might fail")
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude -- Fallback
        raycastParams.FilterDescendantsInstances = {workspace.CurrentCamera}
    end

    for i = 1, 24 do
        local angle = (i - 1) * (2 * math.pi / 24)
        local x = arenaCenter.X + radius * math.cos(angle)
        local z = arenaCenter.Z + radius * math.sin(angle)
        
        -- Raycast to find terrain height
        local origin = Vector3.new(x, 200, z)
        local result = workspace:Raycast(origin, Vector3.new(0, -300, 0), raycastParams)
        local groundY = result and result.Position.Y or 6 -- Default to floor level (6) if misses
        
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
    
    -- Helper to create a hollow tube shaft
    local function createTube(position, height)
        local tubeGroup = Instance.new("Model")
        tubeGroup.Name = "TubeStructure"
        
        local wallConfig = {
            Size = Vector3.new(8, height, 1), -- Walls slightly wider than platform (6)
            Color = Color3.fromRGB(30, 30, 30),
            Material = Enum.Material.Metal
        }
        
        -- 4 Walls
        local offsets = {
            Vector3.new(0, 0, 4),  -- Front
            Vector3.new(0, 0, -4), -- Back
            Vector3.new(4, 0, 0),  -- Right
            Vector3.new(-4, 0, 0)  -- Left
        }
        
        for i, offset in ipairs(offsets) do
            local wall = Instance.new("Part")
            wall.Name = "Wall_" .. i
            -- Rotate side walls
            if offset.X ~= 0 then
                 wall.Size = Vector3.new(1, height, 8)
            else
                 wall.Size = Vector3.new(8, height, 1)
            end
            
            -- Position: Center - (Height/2) guarantees it goes DOWN from surface
            wall.Position = position - Vector3.new(0, height/2 + 0.5, 0) + offset
            wall.Anchored = true
            wall.CanCollide = true -- Keep players in
            wall.Color = wallConfig.Color
            wall.Material = wallConfig.Material
            wall.Parent = tubeGroup
        end
        
        tubeGroup.Parent = folder
    end

    for i, data in ipairs(CharacterSpawner.spawnPositions) do
        -- Main Platform (Anchored)
        local platform = Instance.new("Part")
        platform.Name = "Platform_" .. i
        platform.Size = PLATFORM_CONFIG.SIZE
        platform.Position = data.platformPosition
        platform.Anchored = true
        platform.CanCollide = true
        platform.Material = PLATFORM_CONFIG.MATERIAL
        platform.Color = PLATFORM_CONFIG.COLOR
        platform:SetAttribute("OriginalCFrame", platform.CFrame) -- Store CFrame instead of Position
        platform.Parent = folder
        
        -- Pillar (Visual support)
        local pillarHeight = PLATFORM_CONFIG.HEIGHT + 30 
        local pillar = Instance.new("Part")
        pillar.Name = "Pillar"
        pillar.Size = Vector3.new(2, pillarHeight, 2)
        pillar.Position = data.platformPosition - Vector3.new(0, 0.5 + pillarHeight/2, 0)
        pillar.Anchored = false -- Welded
        pillar.CanCollide = false 
        pillar.Material = Enum.Material.Concrete
        pillar.Color = Color3.fromRGB(60,60,60)
        pillar.Parent = platform
        
        local pillarWeld = Instance.new("WeldConstraint")
        pillarWeld.Part0 = platform
        pillarWeld.Part1 = pillar
        pillarWeld.Parent = platform
        
        -- Glow Ring
        local glow = Instance.new("Part")
        glow.Name = "GlowRing"
        glow.Size = Vector3.new(6, 0.2, 6)
        glow.Position = data.platformPosition + Vector3.new(0, 0.6, 0)
        glow.Anchored = false
        glow.CanCollide = false
        glow.Material = Enum.Material.Neon
        glow.Color = PLATFORM_CONFIG.COLOR
        glow.Transparency = 0.5
        glow.Parent = platform
        
        local glowWeld = Instance.new("WeldConstraint")
        glowWeld.Part0 = platform
        glowWeld.Part1 = glow
        glowWeld.Parent = platform
        
        -- Create the visual tube shaft
        createTube(data.platformPosition, 40) -- Deep shaft
        
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
    
    -- Teleport logic
    local function teleportToPlatform(char)
         local root = char:WaitForChild("HumanoidRootPart", 10)
         local hum = char:WaitForChild("Humanoid", 10)
         if not root or not hum then return end
         
         -- Remove spawn bubble/forcefield
         for _, child in ipairs(char:GetChildren()) do
             if child:IsA("ForceField") then
                 child:Destroy()
             end
         end
         
         -- Find platform
         local platformName = "Platform_" .. index
         local platformsFolder = workspace:FindFirstChild("SpawnPlatforms")
         local platform = platformsFolder and platformsFolder:FindFirstChild(platformName)
         
         local targetPos = data.position
         if platform then
             -- Position on top of platform
             targetPos = platform.Position + Vector3.new(0, 5, 0) -- Increased to 5 for safety
             root.CFrame = CFrame.new(targetPos, Vector3.new(0, targetPos.Y, 0))
             root.Anchored = true
             hum.WalkSpeed = 0
             hum.JumpPower = 0
             
             -- Reset camera
             task.delay(0.2, function()
                 spawnerRemoteEvent:FireClient(player, "RESET_CAMERA")
             end)
             print("[CharacterSpawner] Teleported (Anchored) " .. player.Name .. " to " .. platformName)
         else
             warn("[CharacterSpawner] Platform " .. platformName .. " missing!")
             -- Fallback
             root.CFrame = CFrame.new(data.position + Vector3.new(0,5,0))
             root.Anchored = true 
         end
         
         CharacterSpawner.playersSpawned[player] = true
         spawnerRemoteEvent:FireClient(player, "SPAWNED_ON_PLATFORM", index, targetPos)
    end

    -- Initial teleport
    if player.Character then
        teleportToPlatform(player.Character)
    end

    -- Listen for respawns during countdown
    local connection
    connection = player.CharacterAdded:Connect(function(char)
        if not CharacterSpawner.countdownActive then
            connection:Disconnect()
            return
        end
        task.wait(0.2) 
        teleportToPlatform(char)
    end)
    
    -- Cleanup connection later
    CharacterSpawner.playersOnPlatform[player] = connection 
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
        
        -- Restore Physics & Movement
        if plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.Anchored = false
            end
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum then
                hum.PlatformStand = false
            end
        end
        
        -- Disconnect listener
        if CharacterSpawner.playersOnPlatform[plr] then
            CharacterSpawner.playersOnPlatform[plr]:Disconnect()
            CharacterSpawner.playersOnPlatform[plr] = nil
        end
    end
    
    -- Start Match
    local MatchService = require(script.Parent.MatchService)
    MatchService:startMatch()
end


function CharacterSpawner:preparePlatforms()
    print("[CharacterSpawner] Lowering platforms to tube start position...")
    for _, platform in ipairs(CharacterSpawner.spawnPlatforms) do
        local origCF = platform:GetAttribute("OriginalCFrame")
        if origCF then
            -- Move down 25 studs (deep enough for tube effect)
            local downCF = origCF - Vector3.new(0, 25, 0)
            platform.CFrame = downCF -- Using CFrame updates welds safely
        end
    end
end

function CharacterSpawner:risePlatforms(duration)
    print("[CharacterSpawner] Initiating platform rise sequence (" .. duration .. "s)")
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- 1. Tween Platforms
    for _, platform in ipairs(CharacterSpawner.spawnPlatforms) do
        local origCF = platform:GetAttribute("OriginalCFrame")
        if origCF then
           TweenService:Create(platform, tweenInfo, {CFrame = origCF}):Play()
        end
    end
    
    -- 2. Tween Players (Manual CFrame Tween)
    for player, _ in pairs(CharacterSpawner.playersSpawned) do
         if player.Character and player.Character.PrimaryPart then
             local currentCF = player.Character.PrimaryPart.CFrame
             local targetCF = currentCF + Vector3.new(0, 25, 0) -- Rise same amount
             
             TweenService:Create(player.Character.PrimaryPart, tweenInfo, {CFrame = targetCF}):Play()
         end
    end
    
    -- 3. Tween Bots (Manual CFrame Tween)
    -- We must find all bots that were placed on platforms
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChild("IsBot") and child.PrimaryPart then
            -- Only tween if it's on a platform (optional check: if anchored)
             local currentCF = child.PrimaryPart.CFrame
             local targetCF = currentCF + Vector3.new(0, 25, 0)
             
             TweenService:Create(child.PrimaryPart, tweenInfo, {CFrame = targetCF}):Play()
        end
    end
    
    -- 4. Notify Clients for FX
    spawnerRemoteEvent:FireAllClients("RISE_SEQUENCE_START", duration)
end

function CharacterSpawner:init()
    print("[CharacterSpawner] Initializing")
    
    -- Delay init slightly to let terrain generate
    task.delay(2, function()
        CharacterSpawner:createSpawnPlatforms()
    end)
end

return CharacterSpawner
