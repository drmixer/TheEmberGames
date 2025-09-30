-- ServerScript: DevelopmentSetup.lua
-- Development setup for The Ember Games
-- Ensures arena is created for testing even outside normal game flow

local ArenaService = require(script.Parent.ArenaService)
local CharacterSpawner = require(script.Parent.CharacterSpawner)
local Players = game:GetService("Players")

-- Create arena and boundaries immediately for development/testing
print("DevelopmentSetup: Creating arena for testing...")

-- Initialize arena service to create boundaries and Cornucopia
ArenaService:init()

-- Wait a moment for initialization to complete
wait(0.5)

-- Initialize and create match arena (this should create Cornucopia)
ArenaService:initializeMatch()

print("DevelopmentSetup: Arena created successfully for testing")

-- Force spawn player immediately when they join
Players.PlayerAdded:Connect(function(player)
    print("DevelopmentSetup: New player detected, spawning...")
    
    -- Give a moment for the player to fully load
    wait(1)
    
    -- Spawn the player at a specific location for development
    local spawnLocation = Vector3.new(0, 10, 0) -- Start above ground to see the Cornucopia
    
    player.CharacterAdded:Connect(function(character)
        wait(0.5) -- Wait for character to load completely
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        if humanoidRootPart then
            humanoidRootPart.CFrame = CFrame.new(spawnLocation)
            print("DevelopmentSetup: Player spawned at test location")
        end
    end)
    
    -- Load the character if not already loaded
    if not player.Character then
        player:LoadCharacter()
    end
end)

-- For development, immediately spawn if players are already present
for _, player in pairs(Players:GetPlayers()) do
    print("DevelopmentSetup: Player already present, spawning...")
    player.CharacterAdded:Connect(function(character)
        wait(0.5)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        if humanoidRootPart then
            humanoidRootPart.CFrame = CFrame.new(Vector3.new(0, 10, 0))
        end
    end)
    
    if not player.Character then
        player:LoadCharacter()
    end
end

print("DevelopmentSetup: Ready for development testing - arena should be visible at origin")