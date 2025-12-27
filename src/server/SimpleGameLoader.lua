-- Script: SimpleGameLoader.lua
-- Loads and initializes the SIMPLE, WORKING game systems
-- Replace the complex broken systems with these

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("===========================================")
print("  THE EMBER GAMES - Simple Mode")
print("===========================================")

-- Load simple systems
local SimpleCombat = require(script.Parent.SimpleCombat)
local SimpleBots = require(script.Parent.SimpleBots)
local SimpleWeapons = require(script.Parent.SimpleWeapons)

-- Initialize all systems
SimpleCombat.init()
SimpleBots.init()
SimpleWeapons.init()

-- Setup player when they join
local function setupPlayer(player)
    print("[SimpleGame] Setting up " .. player.Name)
    
    player.CharacterAdded:Connect(function(character)
        -- Wait for character to load
        task.wait(1)
        
        -- Give them a weapon
        SimpleWeapons:equipWeapon(player, "Sword")
        
        -- Teleport to spawn position
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Spawn away from center
            local angle = math.random() * math.pi * 2
            local spawnPos = Vector3.new(
                math.cos(angle) * 40,
                30,
                math.sin(angle) * 40
            )
            
            -- Find ground
            local result = workspace:Raycast(spawnPos, Vector3.new(0, -100, 0))
            if result then
                spawnPos = result.Position + Vector3.new(0, 5, 0)
            end
            
            hrp.CFrame = CFrame.new(spawnPos)
            print("[SimpleGame] Spawned " .. player.Name)
        end
    end)
    
    -- Chat commands
    player.Chatted:Connect(function(message)
        local args = string.split(string.lower(message), " ")
        local cmd = args[1]
        
        if cmd == "/spawn" then
            -- Spawn bots manually
            local count = tonumber(args[2]) or 5
            SimpleBots:spawnBots(count)
            
        elseif cmd == "/clear" then
            -- Clear all bots
            SimpleBots:clear()
            
        elseif cmd == "/weapon" then
            -- Give weapon
            local weaponId = args[2] or "Sword"
            -- Capitalize first letter
            weaponId = weaponId:sub(1,1):upper() .. weaponId:sub(2)
            SimpleWeapons:equipWeapon(player, weaponId)
            
        elseif cmd == "/heal" then
            local character = player.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
                print("[SimpleGame] Healed " .. player.Name)
            end
            
        elseif cmd == "/help" then
            print("[SimpleGame] Commands:")
            print("  /spawn [count] - Spawn bots")
            print("  /clear - Remove all bots")
            print("  /weapon [name] - Get weapon (Sword, Spear, Axe, WoodenStick)")
            print("  /heal - Restore health")
        end
    end)
    
    -- Trigger initial character setup if already exists
    if player.Character then
        task.spawn(function()
            task.wait(0.5)
            player.CharacterAdded:Fire(player.Character)
        end)
    end
end

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
    setupPlayer(player)
end

-- Handle new players
Players.PlayerAdded:Connect(setupPlayer)

-- Auto-spawn bots after delay
task.delay(10, function()
    print("[SimpleGame] Auto-spawning 10 bots...")
    SimpleBots:spawnBots(10)
end)

print("===========================================")
print("  SIMPLE GAME READY!")
print("  Commands: /spawn, /clear, /weapon, /heal")
print("  LEFT-CLICK to attack!")
print("===========================================")

-- Return module (required for ModuleScript)
return {
    SimpleCombat = SimpleCombat,
    SimpleBots = SimpleBots,
    SimpleWeapons = SimpleWeapons
}
