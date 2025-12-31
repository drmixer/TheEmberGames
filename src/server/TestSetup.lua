-- ServerScript: TestSetup.lua
-- Testing setup for The Ember Games MVP
-- Helps configure game state for manual testing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TestSetup = {}

-- Teleport player to a safe spawn location (NOT on cornucopia)
local function teleportToSafeSpawn(player)
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Spawn AWAY from center (cornucopia) - 40 studs out
    local angle = math.random() * math.pi * 2
    local spawnX = math.cos(angle) * 40
    local spawnZ = math.sin(angle) * 40
    
    -- Find ground via raycast
    local origin = Vector3.new(spawnX, 200, spawnZ)
    local result = workspace:Raycast(origin, Vector3.new(0, -400, 0))
    
    local groundY = 20 -- Default fallback
    if result then
        groundY = result.Position.Y
    end
    
    -- Teleport player above ground
    hrp.CFrame = CFrame.new(spawnX, groundY + 5, spawnZ)
    print("[TestSetup] Teleported " .. player.Name .. " to spawn position")
end

-- Give test weapons to player (as actual Tools) and auto-equip
local function giveTestWeapons(player)
    local character = player.Character
    if not character then 
        print("[TestSetup] No character for " .. player.Name)
        return 
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        print("[TestSetup] No humanoid for " .. player.Name)
        return
    end
    
    local success, WeaponSystem = pcall(function()
        return require(script.Parent.WeaponSystem)
    end)
    
    if not success or not WeaponSystem then
        print("[TestSetup] Failed to load WeaponSystem")
        return
    end
    
    -- Give weapon (goes to Backpack) - SharpStick has a pointed tip!
    local weapon = WeaponSystem:giveWeapon(player, "SharpStick")
    
    if weapon then
        task.wait(0.3) -- Wait for replication
        
        -- Find weapon in Backpack and equip it
        local backpack = player:FindFirstChild("Backpack")
        local toolToEquip = nil
        
        if backpack then
            toolToEquip = backpack:FindFirstChild("Sharp Stick") -- Display name
            if not toolToEquip then
                -- Try by Tool class
                for _, child in pairs(backpack:GetChildren()) do
                    if child:IsA("Tool") then
                        toolToEquip = child
                        break
                    end
                end
            end
        end
        
        if toolToEquip then
            humanoid:EquipTool(toolToEquip)
            print("[TestSetup] Equipped " .. toolToEquip.Name .. " to " .. player.Name)
            print("[TestSetup] LEFT CLICK to attack!")
        else
            -- Try direct equip if still available
            if weapon.Parent then
                humanoid:EquipTool(weapon)
                print("[TestSetup] Direct equipped weapon to " .. player.Name)
            else
                print("[TestSetup] ERROR: Weapon not found in backpack!")
            end
        end
        
        -- Verify weapon is in character's hand
        task.wait(0.2)
        local equipped = character:FindFirstChildOfClass("Tool")
        if equipped then
            print("[TestSetup] ✓ Weapon confirmed in hand: " .. equipped.Name)
            print("[TestSetup] Attributes: Type=" .. tostring(equipped:GetAttribute("Type")) .. 
                  ", Damage=" .. tostring(equipped:GetAttribute("Damage")))
        else
            print("[TestSetup] ✗ No weapon in character! Check Backpack...")
            if backpack then
                for _, child in pairs(backpack:GetChildren()) do
                    print("[TestSetup]   Backpack item: " .. child.Name)
                end
            end
        end
    else
        print("[TestSetup] Failed to create weapon!")
    end
end

-- Setup a single player with commands and spawning
local function setupPlayer(player)
    print("[TestSetup] Setting up player: " .. player.Name)
    
    -- Setup chat commands
    player.Chatted:Connect(function(msg)
        local args = string.split(msg, " ")
        local cmd = args[1]:lower()
        
        if cmd == "/tp" then
            teleportToSafeSpawn(player)
        elseif cmd == "/give" then
            local weapon = args[2] or "WoodenStick"
            local WeaponSystem = require(script.Parent.WeaponSystem)
            WeaponSystem:giveWeapon(player, weapon)
            print("Gave " .. weapon)
        elseif cmd == "/heal" then
            local hum = player.Character and player.Character:FindFirstChild("Humanoid")
            if hum then hum.Health = hum.MaxHealth end
        elseif cmd == "/die" then
            local MatchService = require(script.Parent.MatchService)
            MatchService:eliminatePlayer(player)
        elseif cmd == "/bots" then
            local count = tonumber(args[2]) or 5
            local BotController = require(script.Parent.BotController)
            BotController:fillWithBots(count + 1) -- +1 for player
            print("Spawned " .. count .. " bots")
        elseif cmd == "/drop" then
            local TestingService = require(script.Parent.TestingService)
            TestingService:spawnSupplyDrop()
            print("Force spawned supply drop!")
        elseif cmd == "/hazard" then
            local TestingService = require(script.Parent.TestingService)
            local types = {"WILDFIRE", "POISON_FOG", "ACID_RAIN"}
            local type = args[2] or types[math.random(1, #types)]
            TestingService:triggerHazard(type)
            print("Triggered hazard: " .. type)
        elseif cmd == "/storm" then
            local phase = tonumber(args[2]) or 1
            local TestingService = require(script.Parent.TestingService)
            TestingService:skipToStormPhase(phase)
            print("Skipped to storm phase " .. phase)
        elseif cmd == "/clean" then
             local TestingService = require(script.Parent.TestingService)
             TestingService:removeAllBots()
             print("Cleaned up bots")
        elseif cmd == "/time" then
            local hour = tonumber(args[2]) or 12
            game:GetService("Lighting").ClockTime = hour
            print("Set time to " .. hour)
        elseif cmd == "/fallen" then
            local MatchService = require(script.Parent.MatchService)
            if MatchService:triggerNightRecap() then
                print("Triggered Night Recap!")
            else
                print("No fallen tributes to show.")
            end
        end
    end)
    
    -- When character spawns
    player.CharacterAdded:Connect(function(char)
        -- Test setup disabled to allow proper game loop spawning
        -- task.wait(0.5)
        -- teleportToSafeSpawn(player)
        -- giveTestWeapons(player) 
    end)
    
    -- If character already exists, do it now
    if player.Character then
       -- task.spawn(function()
       --     task.wait(0.5)
       --     teleportToSafeSpawn(player)
       -- end)
    end
end

-- Setup function for testing
function TestSetup:setupForTesting()
    print("[TestSetup] Initializing test mode...")
    
    -- Override config - but KEEP bots enabled
    local ReplicatedFirst = game:GetService("ReplicatedFirst")
    local Config = require(ReplicatedFirst.Config)
    Config.PLAYER_MIN = 1
    -- Config.BOTS_ENABLED is already set in Config.lua, don't override here
    
    print("[TestSetup] Test mode enabled")
    
    -- Handle NEW players
    Players.PlayerAdded:Connect(function(player)
        task.wait(1)
        setupPlayer(player)
    end)
    
    -- Handle EXISTING players
    for _, player in pairs(Players:GetPlayers()) do
        setupPlayer(player)
    end
    
    print("[TestSetup] Ready! Commands: /tp, /give, /drop, /hazard, /heal")
end

return TestSetup