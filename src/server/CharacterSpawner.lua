-- ServerScript: CharacterSpawner.lua
-- Handles character spawning for The Ember Games
-- Manages player spawn positions, spawn platforms, and arena entry

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LobbyService = require(script.Parent.LobbyService)
local PlayerStats = require(script.Parent.PlayerStats)
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
    HEIGHT = 3, -- Height above ground
    MATERIAL = Enum.Material.Metal,
    COLOR = Color3.fromRGB(80, 80, 80), -- Dark gray
    GLOW_COLOR = Color3.fromRGB(255, 140, 0), -- Orange glow during countdown
}

-- RemoteEvents for spawn management
local spawnerRemoteEvent = Instance.new("RemoteEvent")
spawnerRemoteEvent.Name = "SpawnerRemoteEvent"
spawnerRemoteEvent.Parent = ReplicatedStorage

-- Initialize spawn positions around the Cornucopia
local function initializeSpawnPositions()
    local arenaCenter = Vector3.new(0, 0, 0) -- Center of arena
    local radius = 40 -- Distance from center to spawn platforms
    
    for i = 1, Config.PLAYER_CAP do
        local angle = (i - 1) * (2 * math.pi / Config.PLAYER_CAP)
        local x = arenaCenter.X + radius * math.cos(angle)
        local z = arenaCenter.Z + radius * math.sin(angle)
        
        -- Y position is on top of the platform (ground level + platform height + half platform thickness)
        local groundY = 0.5 -- Top of ground plane
        local platformY = groundY + PLATFORM_CONFIG.HEIGHT + PLATFORM_CONFIG.SIZE.Y / 2
        
        -- Store spawn position (where player stands) - on top of platform
        table.insert(CharacterSpawner.spawnPositions, {
            position = Vector3.new(x, platformY + 3, z), -- 3 studs above platform
            angle = angle,
            platformPosition = Vector3.new(x, groundY + PLATFORM_CONFIG.HEIGHT, z)
        })
    end
    
    print("[CharacterSpawner] Initialized " .. #CharacterSpawner.spawnPositions .. " spawn positions around Cornucopia")
end

-- Create spawn platforms around Cornucopia
function CharacterSpawner:createSpawnPlatforms()
    if CharacterSpawner.platformsCreated then
        return CharacterSpawner.spawnPlatforms
    end
    
    -- Clear any existing platforms
    for _, platform in ipairs(CharacterSpawner.spawnPlatforms) do
        if platform and platform.Parent then
            platform:Destroy()
        end
    end
    CharacterSpawner.spawnPlatforms = {}
    
    -- Create a folder to hold platforms
    local platformFolder = workspace:FindFirstChild("SpawnPlatforms")
    if not platformFolder then
        platformFolder = Instance.new("Folder")
        platformFolder.Name = "SpawnPlatforms"
        platformFolder.Parent = workspace
    end
    
    for i, spawnData in ipairs(CharacterSpawner.spawnPositions) do
        -- Create platform base
        local platform = Instance.new("Part")
        platform.Name = "SpawnPlatform_" .. i
        platform.Size = PLATFORM_CONFIG.SIZE
        platform.Position = spawnData.platformPosition
        platform.Anchored = true
        platform.CanCollide = true
        platform.Material = PLATFORM_CONFIG.MATERIAL
        platform.Color = PLATFORM_CONFIG.COLOR
        platform.Parent = platformFolder
        
        -- Add a pedestal/pillar under the platform
        local pillar = Instance.new("Part")
        pillar.Name = "Pillar"
        pillar.Size = Vector3.new(2, PLATFORM_CONFIG.HEIGHT, 2)
        pillar.Position = spawnData.platformPosition - Vector3.new(0, PLATFORM_CONFIG.HEIGHT / 2 + 0.5, 0)
        pillar.Anchored = true
        pillar.CanCollide = true
        pillar.Material = Enum.Material.Concrete
        pillar.Color = Color3.fromRGB(60, 60, 60)
        pillar.Parent = platform
        
        -- Add glowing ring on platform edge
        local ring = Instance.new("Part")
        ring.Name = "GlowRing"
        ring.Size = Vector3.new(PLATFORM_CONFIG.SIZE.X, 0.2, PLATFORM_CONFIG.SIZE.Z)
        ring.Position = spawnData.platformPosition + Vector3.new(0, 0.6, 0)
        ring.Anchored = true
        ring.CanCollide = false
        ring.Material = Enum.Material.Neon
        ring.Color = PLATFORM_CONFIG.COLOR
        ring.Transparency = 0.5
        ring.Parent = platform
        
        -- Add district number display
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Size = UDim2.new(4, 0, 2, 0)
        billboardGui.StudsOffset = Vector3.new(0, 4, 0)
        billboardGui.Adornee = platform
        billboardGui.AlwaysOnTop = false
        billboardGui.Parent = platform
        
        local districtLabel = Instance.new("TextLabel")
        districtLabel.Size = UDim2.new(1, 0, 1, 0)
        districtLabel.BackgroundTransparency = 1
        districtLabel.TextScaled = true
        districtLabel.Font = Enum.Font.GothamBold
        districtLabel.Text = "DISTRICT " .. i
        districtLabel.TextColor3 = Color3.new(1, 1, 1)
        districtLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        districtLabel.TextStrokeTransparency = 0.5
        districtLabel.Parent = billboardGui
        
        table.insert(CharacterSpawner.spawnPlatforms, platform)
    end
    
    CharacterSpawner.platformsCreated = true
    print("[CharacterSpawner] Created " .. #CharacterSpawner.spawnPlatforms .. " spawn platforms")
    
    return CharacterSpawner.spawnPlatforms
end

-- Activate platform glow during countdown
function CharacterSpawner:activatePlatformGlow(activate)
    for _, platform in ipairs(CharacterSpawner.spawnPlatforms) do
        local ring = platform:FindFirstChild("GlowRing")
        if ring then
            if activate then
                ring.Color = PLATFORM_CONFIG.GLOW_COLOR
                ring.Transparency = 0.2
            else
                ring.Color = PLATFORM_CONFIG.COLOR
                ring.Transparency = 0.5
            end
        end
    end
end

-- Lock player movement (during countdown)
function CharacterSpawner:setPlayerMovementLock(player, locked)
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if humanoid then
        if locked then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        else
            humanoid.WalkSpeed = 16 -- Default speed
            humanoid.JumpPower = 50 -- Default jump
        end
    end
    
    CharacterSpawner.playersOnPlatform[player] = locked
    spawnerRemoteEvent:FireClient(player, "MOVEMENT_LOCKED", locked)
end

-- Spawn a player character on their designated platform
function CharacterSpawner:spawnPlayer(player)
    if CharacterSpawner.playersSpawned[player] then
        return -- Already spawned
    end
    
    -- Get spawn position for this player based on their district/lobby position
    local playerIndex = 1
    if LobbyService.lobbyPlayers[player] then
        playerIndex = LobbyService.lobbyPlayers[player].districtNumber or 1
    end
    
    -- Adjust to ensure within bounds
    playerIndex = math.clamp(playerIndex, 1, #CharacterSpawner.spawnPositions)
    local spawnData = CharacterSpawner.spawnPositions[playerIndex]
    
    if not spawnData then
        print("[CharacterSpawner] No spawn position available for player: " .. player.Name)
        return
    end
    
    -- Store connection to clean up later
    local characterConnection
    characterConnection = player.CharacterAdded:Connect(function(character)
        characterConnection:Disconnect()
        
        local humanoid = character:WaitForChild("Humanoid")
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Wait for character to fully load
        task.wait(0.1)
        
        if humanoidRootPart and humanoidRootPart.Parent then
            -- Position character on platform facing center
            local lookAt = Vector3.new(0, spawnData.position.Y, 0) -- Look at arena center
            local cf = CFrame.new(spawnData.position, lookAt)
            humanoidRootPart.CFrame = cf
            
            -- Lock movement during countdown
            if CharacterSpawner.countdownActive then
                CharacterSpawner:setPlayerMovementLock(player, true)
            end
            
            -- Initialize character with starting items
            CharacterSpawner:giveStartingItems(player, character)
            
            -- Mark player as spawned
            CharacterSpawner.playersSpawned[player] = true
            
            print("[CharacterSpawner] Spawned " .. player.Name .. " on platform " .. playerIndex)
            
            -- Notify client
            spawnerRemoteEvent:FireClient(player, "SPAWNED_ON_PLATFORM", playerIndex, spawnData.position)
        end
    end)
    
    -- Actually spawn the character
    player:LoadCharacter()
end

-- Start the pre-match countdown
function CharacterSpawner:startCountdown(duration)
    CharacterSpawner.countdownActive = true
    
    -- Activate platform glow
    CharacterSpawner:activatePlatformGlow(true)
    
    -- Lock all spawned players
    for player, _ in pairs(CharacterSpawner.playersSpawned) do
        if player and player.Parent and player.Character then
            CharacterSpawner:setPlayerMovementLock(player, true)
        end
    end
    
    print("[CharacterSpawner] Countdown started: " .. duration .. " seconds")
    spawnerRemoteEvent:FireAllClients("COUNTDOWN_STARTED", duration)
end

-- End the countdown and release players
function CharacterSpawner:endCountdown()
    CharacterSpawner.countdownActive = false
    
    -- Deactivate platform glow
    CharacterSpawner:activatePlatformGlow(false)
    
    -- Unlock all players
    for player, _ in pairs(CharacterSpawner.playersSpawned) do
        if player and player.Parent and player.Character then
            CharacterSpawner:setPlayerMovementLock(player, false)
        end
    end
    
    print("[CharacterSpawner] Countdown ended - players released!")
    spawnerRemoteEvent:FireAllClients("COUNTDOWN_ENDED")
    
    -- Start match via MatchService
    local MatchService = require(script.Parent.MatchService)
    MatchService:startMatch()
end

-- Give player starting items (minimal to encourage resource gathering)
function CharacterSpawner:giveStartingItems(player, character)
    -- Try to get inventory controller
    local success, InventoryController = pcall(function()
        return require(script.Parent.InventoryController)
    end)
    
    if success and InventoryController then
        -- Give basic survival items
        InventoryController:addItem(player, "Water Bottle", 1)
        InventoryController:addItem(player, "Edible Berries", 3)
        InventoryController:addItem(player, "Wood", 2)
        InventoryController:addItem(player, "Stone", 1)
        
        print("[CharacterSpawner] Gave starting items to " .. player.Name)
    end
end

-- Reset spawner state for new match
function CharacterSpawner:resetForNewMatch()
    CharacterSpawner.playersSpawned = {}
    CharacterSpawner.playersOnPlatform = {}
    CharacterSpawner.countdownActive = false
    
    -- Recreate platforms
    CharacterSpawner.platformsCreated = false
    CharacterSpawner:createSpawnPlatforms()
    
    print("[CharacterSpawner] Reset for new match")
end

-- Initialize CharacterSpawner
function CharacterSpawner:init()
    print("[CharacterSpawner] Initializing...")
    
    -- Initialize spawn positions
    initializeSpawnPositions()
    
    -- Create spawn platforms
    CharacterSpawner:createSpawnPlatforms()
    
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        -- For MVP testing, spawn immediately when player joins
        -- In real game, this would only happen at match start based on LobbyService
        task.wait(2) -- Give other systems time to initialize
        CharacterSpawner:spawnPlayer(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            task.wait(1)
            CharacterSpawner:spawnPlayer(player)
        end)
    end
    
    -- Handle remote events from clients
    spawnerRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        if action == "REQUEST_SPAWN" then
            CharacterSpawner:spawnPlayer(player)
        elseif action == "PLAYER_ELIMINATED" then
            -- In real game, player goes to spectator
            -- For MVP testing, handled by MatchService
        end
    end)
    
    print("[CharacterSpawner] Initialized successfully")
end

return CharacterSpawner
