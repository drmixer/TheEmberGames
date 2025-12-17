-- ModuleScript: CombatController.lua
-- Handles combat mechanics for The Ember Games
-- Manages weapon systems, damage calculation, and combat effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)
local PlayerStats = require(script.Parent.PlayerStats)

local CombatController = {}
CombatController.activeWeapons = {}

-- Create RemoteEvents for combat
local damageRemoteEvent = Instance.new("RemoteEvent")
damageRemoteEvent.Name = "DamageRemoteEvent"
damageRemoteEvent.Parent = ReplicatedStorage

local weaponRemoteEvent = Instance.new("RemoteEvent")
weaponRemoteEvent.Name = "WeaponRemoteEvent"
weaponRemoteEvent.Parent = ReplicatedStorage

-- Initialize CombatController
function CombatController:init()
    print("CombatController initialized")
    
    -- Handle weapon attacks from clients
    weaponRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}
        
        if action == "ATTACK" then
            local targetPlayer = args[1]
            local weaponType = args[2]
            CombatController:processAttack(player, targetPlayer, weaponType)
        elseif action == "SWING_WEAPON" then
            -- Handle weapon swing animation/detection
            local weaponType = args[1]
            CombatController:detectNearbyTargets(player, weaponType)
        end
    end)
end

-- Process an attack from one player to another
function CombatController:processAttack(attacker, target, weaponType)
    if not attacker or not target then
        return
    end
    
    -- Get weapon stats based on type
    local weaponStats = CombatController:getWeaponStats(weaponType)
    if not weaponStats then
        warn("Invalid weapon type: " .. tostring(weaponType))
        return
    end
    
    -- Calculate damage with possible critical hit
    local damage = weaponStats.damage
    local isCritical = math.random() < Config.CRITICAL_HIT_CHANCE
    if isCritical then
        damage = damage * Config.CRITICAL_HIT_MULTIPLIER
        print(attacker.Name .. " scored a critical hit on " .. target.Name .. " for " .. damage .. " damage!")
    end
    
    -- Apply damage to target
    local newHealth = PlayerStats:applyDamage(target, damage, weaponType)
    
    -- Apply status effects if applicable
    if weaponStats.statusEffect and math.random() < (weaponStats.statusChance or 0.15) then
        PlayerStats:addStatusEffect(target, weaponStats.statusEffect, weaponStats.statusDuration or 10, 1)
    end
    
    -- Get hit position for effects
    local hitPosition = Vector3.new(0, 0, 0)
    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        hitPosition = target.Character.HumanoidRootPart.Position
    end
    
    -- Play combat sounds via AudioService
    local success, AudioService = pcall(function()
        return require(script.Parent.AudioService)
    end)
    
    if success and AudioService then
        -- Determine sound type based on weapon
        local soundType = "BLUNT_HIT"
        if weaponType == "Sword" or weaponType == "Machete" or weaponType == "Knife" then
            soundType = "SWORD_HIT"
        elseif weaponType == "Spear" then
            soundType = "SWORD_HIT"
        elseif weaponType == "Bow" then
            soundType = "ARROW_HIT"
        end
        
        AudioService:playCombatSound(soundType, hitPosition, isCritical and 1.2 or 0.8)
    end
    
    -- Send damage notification to clients
    damageRemoteEvent:FireAllClients("PLAYER_DAMAGE", target.UserId, damage, isCritical)
    
    -- Send weapon hit event for visual effects
    weaponRemoteEvent:FireAllClients("WEAPON_HIT", hitPosition, "player")
    
    -- Handle weapon durability if enabled
    if Config.WEAPON_DURABILITY_ENABLED then
        CombatController:reduceWeaponDurability(attacker, weaponType)
    end
    
    print("[CombatController] " .. attacker.Name .. " attacked " .. target.Name .. " with " .. weaponType .. " for " .. damage .. " damage")
end

-- Get weapon statistics
function CombatController:getWeaponStats(weaponType)
    local weapons = {
        ["Spear"] = {
            damage = 25,
            statusEffect = "BLEEDING",
            statusChance = 0.15,
            statusDuration = 5,
            durability = 15
        },
        ["Knife"] = {
            damage = 20,
            statusEffect = "BLEEDING", 
            statusChance = 0.20,
            statusDuration = 5,
            durability = 25
        },
        ["Bow"] = {
            damage = 30,
            statusEffect = nil,
            statusChance = 0,
            statusDuration = 0,
            durability = 20
        },
        ["Axe"] = {
            damage = 35,
            statusEffect = nil,
            statusChance = 0,
            statusDuration = 0,
            durability = 12
        },
        ["Machete"] = {
            damage = 40,
            statusEffect = nil,
            statusChance = 0,
            statusDuration = 0,
            durability = 8
        },
        ["Stick"] = {
            damage = 15,
            statusEffect = nil,
            statusChance = 0,
            statusDuration = 0,
            durability = 20
        },
        ["Rock"] = {
            damage = 12,
            statusEffect = nil,
            statusChance = 0,
            statusDuration = 0,
            durability = 1 -- Single use
        }
    }
    
    return weapons[weaponType]
end

-- Reduce weapon durability
function CombatController:reduceWeaponDurability(player, weaponType)
    if not CombatController.activeWeapons[player] then
        CombatController.activeWeapons[player] = {}
    end
    
    if not CombatController.activeWeapons[player][weaponType] then
        CombatController.activeWeapons[player][weaponType] = CombatController:getWeaponStats(weaponType).durability or 10
    end
    
    CombatController.activeWeapons[player][weaponType] = CombatController.activeWeapons[player][weaponType] - 1
    
    if CombatController.activeWeapons[player][weaponType] <= 0 then
        -- Weapon is broken
        weaponRemoteEvent:FireClient(player, "WEAPON_BROKEN", weaponType)
        print(player.Name .. "'s " .. weaponType .. " has broken!")
        -- Remove weapon from player's inventory in a real implementation
    else
        -- Send durability update
        weaponRemoteEvent:FireClient(player, "WEAPON_DURABILITY_UPDATE", weaponType, CombatController.activeWeapons[player][weaponType])
    end
end

-- Detect nearby targets for melee weapons
function CombatController:detectNearbyTargets(player, weaponType)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local weaponStats = CombatController:getWeaponStats(weaponType)
    if not weaponStats then return end
    
    local range = 6 -- Default melee range in studs
    
    if weaponType == "Spear" then
        range = 7
    elseif weaponType == "Stick" then
        range = 5
    end
    
    -- Create a sphere around the player to detect targets
    local region = Region3.new(
        humanoidRootPart.Position - Vector3.new(range, range, range),
        humanoidRootPart.Position + Vector3.new(range, range, range)
    )
    
    local parts = game.Workspace:FindPartsInRegion3(region, nil, 10) -- Limit to 10 parts
    
    for _, part in pairs(parts) do
        local targetPlayer = Players:GetPlayerFromCharacter(part.Parent)
        
        if targetPlayer and targetPlayer ~= player then
            -- Calculate distance
            local distance = (part.Position - humanoidRootPart.Position).Magnitude
            
            if distance <= range then
                -- Process the attack
                CombatController:processAttack(player, targetPlayer, weaponType)
                
                -- Only attack first valid target for simplicity
                break
            end
        end
    end
end

return CombatController