-- ServerScript: CharacterSpawner.lua
-- Handles character spawning for The Ember Games
-- Manages player spawn positions and arena entry

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LobbyService = require(script.Parent.LobbyService)
local PlayerStats = require(script.Parent.PlayerStats)
local Config = require(script.Parent.Parent.shared.Config)

local CharacterSpawner = {}
CharacterSpawner.spawnPositions = {}
CharacterSpawner.playersSpawned = {}

-- Initialize spawn positions around the Cornucopia
local function initializeSpawnPositions()
    local arenaCenter = Vector3.new(0, 7.5, 0) -- Center of Cornucopia base (which is at Y=7.5 with height 15)
    local radius = 35 -- Distance from center
    
    for i = 1, Config.PLAYER_CAP do
        local angle = (i - 1) * (2 * math.pi / Config.PLAYER_CAP)
        local x = arenaCenter.X + radius * math.cos(angle)
        local z = arenaCenter.Z + radius * math.sin(angle)
        
        -- Find appropriate Y position (above ground level)
        local groundY = 8 -- Above the ground plane (top of ground is at Y=0.5, Cornucopia base is at Y=7.5 with height 15, so Y=8 is just above the base)
        
        table.insert(CharacterSpawner.spawnPositions, Vector3.new(x, groundY, z))
    end
    
    print("Initialized " .. #CharacterSpawner.spawnPositions .. " spawn positions around Cornucopia")
end

-- Spawn a player character
function CharacterSpawner:spawnPlayer(player)
    if CharacterSpawner.playersSpawned[player] then
        return -- Already spawned
    end
    
    -- Get spawn position for this player based on their district/lobby position
    local playerIndex = 0
    for i, lobbyPlayer in pairs(LobbyService.lobbyPlayers) do
        if i == player then
            playerIndex = lobbyPlayer.districtNumber or 1
            break
        end
    end
    
    -- Adjust to ensure within bounds
    playerIndex = math.clamp(playerIndex, 1, #CharacterSpawner.spawnPositions)
    local spawnPosition = CharacterSpawner.spawnPositions[playerIndex]
    
    if not spawnPosition then
        print("No spawn position available for player: " .. player.Name)
        return
    end
    
    -- Spawn the character
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Move character to spawn position after a delay to ensure load
        task.wait(0.5)
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.CFrame = CFrame.new(spawnPosition)
            
            -- Initialize character with starting items
            CharacterSpawner:giveStartingItems(player, character)
            
            -- Set spawn as complete to prevent re-spawning during match
            CharacterSpawner.playersSpawned[player] = true
            print("Spawned " .. player.Name .. " at position: " .. tostring(spawnPosition))
        end
    end)
    
    -- Actually spawn the character
    player:LoadCharacter()
end

-- Give player starting items (minimal to encourage resource gathering)
function CharacterSpawner:giveStartingItems(player, character)
    -- In a real implementation, we would give minimal starting resources
    -- For now, we'll just send a request to the inventory system
    local InventoryController = require(script.Parent.InventoryController)
    
    -- Give basic survival items
    InventoryController:addItem(player, "Water Bottle", 1)
    InventoryController:addItem(player, "Edible Berries", 3)
    InventoryController:addItem(player, "Wood", 2)
    InventoryController:addItem(player, "Stone", 1)
    
    print("Gave starting items to " .. player.Name)
end

-- Respawn eliminated player (for testing, in real game eliminated players go to spectator)
function CharacterSpawner:respawnPlayer(player)
    -- In the real game, eliminated players should go to spectator mode
    -- But for MVP testing, we might want to allow respawning
    -- In a real implementation, this would be disabled or limited
    
    task.wait(3) -- Delay before respawn
    CharacterSpawner:spawnPlayer(player)
end

-- Initialize CharacterSpawner
function CharacterSpawner:init()
    print("CharacterSpawner initialized")
    
    -- Initialize spawn positions
    initializeSpawnPositions()
    
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        -- Set starting spawn location before character loads
        player.SpawnLocation = workspace -- Will be handled manually
        
        -- When game starts, spawn the player
        -- We'll connect to lobby events to handle spawning at the right time
    end)
    
    -- Connect to lobby events to handle spawning when appropriate
    -- This would be triggered when the match officially begins
    -- For MVP, we'll also handle direct spawning when players join
    Players.PlayerAdded:Connect(function(player)
        -- For MVP testing, spawn immediately when player joins
        -- In real game, this would only happen at match start
        task.wait(2) -- Give other systems time to initialize
        CharacterSpawner:spawnPlayer(player)
    end)
    
    -- Handle player elimination and potential respawn (for testing)
    local StatsRemoteEvent = ReplicatedStorage:WaitForChild("StatsRemoteEvent")
    StatsRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        if action == "PLAYER_ELIMINATED" then
            -- In real game, player goes to spectator
            -- For MVP, we might auto-respawn after delay for continued testing
        end
    end)
end

return CharacterSpawner
