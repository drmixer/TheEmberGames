-- ServerScript: DevelopmentSetup.lua
-- Development setup for The Ember Games
-- Ensures arena is created for testing even outside normal game flow

local Players = game:GetService("Players")

-- Force spawn player immediately when they join
Players.PlayerAdded:Connect(function(player)
    print("DevelopmentSetup: New player detected, spawning...")
    
    -- Give a moment for the player to fully load
    wait(2)  -- Increased wait time to ensure arena is fully created
    
    -- Spawn the player at a specific location for development
    local spawnLocation = Vector3.new(0, 20, 0) -- Start well above ground to see the Cornucopia
    
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Wait a bit longer for character to load completely
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
        if humanoidRootPart then
            humanoidRootPart.CFrame = CFrame.new(spawnLocation)
            print("DevelopmentSetup: Player spawned at test location (0, 20, 0)")
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
    wait(2) -- Ensure arena is created first
    player.CharacterAdded:Connect(function(character)
        wait(1)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
        if humanoidRootPart then
            humanoidRootPart.CFrame = CFrame.new(Vector3.new(0, 20, 0))
        end
    end)
    
    if not player.Character then
        player:LoadCharacter()
    end
end

print("DevelopmentSetup: Ready for development testing - spawning at (0, 20, 0)")
print("Arena elements created by DevelopmentArenaService in separate script")