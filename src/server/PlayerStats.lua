-- ServerScript: PlayerStats.lua
-- Manages health, hunger, thirst systems
-- Tracks and updates player vital stats during matches

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local PlayerStats = {}
PlayerStats.playerStats = {}
PlayerStats.statsUpdateConnection = nil

-- RemoteEvents for client communication
local statsRemoteEvent = Instance.new("RemoteEvent")
statsRemoteEvent.Name = "StatsRemoteEvent"
statsRemoteEvent.Parent = ReplicatedStorage

-- Initialize player stats
local function initializePlayerStats(player)
    PlayerStats.playerStats[player] = {
        health = Config.MAX_HEALTH,
        hunger = Config.MAX_HUNGER,
        thirst = Config.MAX_THIRST,
        maxHealth = Config.MAX_HEALTH,
        maxHunger = Config.MAX_HUNGER,
        maxThirst = Config.MAX_THIRST,
        healthRegenRate = 0, -- HP per second
        hungerDrainRate = 1/45, -- per second during activity
        thirstDrainRate = 1/30, -- per second during activity
        statusEffects = {}, -- Active status effects like poison, bleeding
        lastUpdate = tick(),
        lastActivity = tick()
    }
    
    -- Send initial stats to client
    statsRemoteEvent:FireClient(player, "INITIAL_STATS", PlayerStats.playerStats[player])
end

-- Get player's current stats
function PlayerStats:getPlayerStats(player)
    return PlayerStats.playerStats[player]
end

-- Update a player's stat
function PlayerStats:updateStat(player, statName, value, additive)
    if not PlayerStats.playerStats[player] then
        return
    end
    
    local stats = PlayerStats.playerStats[player]
    local oldValue = stats[statName]
    
    if additive then
        stats[statName] = math.clamp(stats[statName] + value, 0, stats["max" .. statName:sub(1,1):upper() .. statName:sub(2)])
    else
        stats[statName] = math.clamp(value, 0, stats["max" .. statName:sub(1,1):upper() .. statName:sub(2)])
    end
    
    local newValue = stats[statName]
    
    -- Check for stat-based events
    if statName == "health" and newValue <= 0 then
        -- Player has died
        PlayerStats:playerEliminated(player)
    end
    
    -- Send update to client
    statsRemoteEvent:FireClient(player, "STAT_UPDATE", statName, newValue, oldValue)
    
    return newValue
end

-- Apply damage to player
function PlayerStats:applyDamage(player, amount, damageType)
    if not PlayerStats.playerStats[player] then
        return
    end
    
    local currentHealth = PlayerStats.playerStats[player].health
    local newHealth = math.max(0, currentHealth - amount)
    
    PlayerStats:updateStat(player, "health", newHealth, false)
    
    -- Log damage for potential future use
    print("Player " .. player.Name .. " took " .. amount .. " " .. (damageType or "unknown") .. " damage. Health: " .. newHealth)
    
    return newHealth
end

-- Add status effect to player
function PlayerStats:addStatusEffect(player, effectName, duration, intensity)
    if not PlayerStats.playerStats[player] then
        return
    end
    
    local stats = PlayerStats.playerStats[player]
    
    -- Add or update the status effect
    stats.statusEffects[effectName] = {
        startTime = tick(),
        duration = duration,
        intensity = intensity or 1,
        active = true
    }
    
    -- Apply immediate effect if applicable
    if effectName == "BLEEDING" then
        -- Bleeding damage is handled in the update loop
    elseif effectName == "POISON" then
        -- Poison damage is handled in the update loop
    elseif effectName == "HYPOTHERMIA" then
        -- Hypothermia effects handled in update loop
    end
    
    -- Notify client
    statsRemoteEvent:FireClient(player, "STATUS_EFFECT_ADDED", effectName, duration, intensity)
end

-- Remove status effect from player
function PlayerStats:removeStatusEffect(player, effectName)
    if not PlayerStats.playerStats[player] then
        return
    end
    
    local stats = PlayerStats.playerStats[player]
    
    if stats.statusEffects[effectName] then
        stats.statusEffects[effectName] = nil
        statsRemoteEvent:FireClient(player, "STATUS_EFFECT_REMOVED", effectName)
    end
end

-- Player eliminated
function PlayerStats:playerEliminated(player)
    if not PlayerStats.playerStats[player] then
        return
    end
    
    print("Player " .. player.Name .. " has been eliminated")
    
    -- Notify clients
    statsRemoteEvent:FireAllClients("PLAYER_ELIMINATED", player.UserId, player.Name)
    
    -- Remove player's stats
    PlayerStats.playerStats[player] = nil
    
    -- Play elimination effects via EventsService or similar
end

-- Update player stats for survival systems
local function updatePlayerStats()
    local currentTime = tick()
    
    for player, stats in pairs(PlayerStats.playerStats) do
        if player and player.Parent then -- Make sure player still exists
            local timeDelta = currentTime - stats.lastUpdate
            
            if timeDelta > 0 then
                -- Update hunger based on activity
                local hungerDrain = stats.hungerDrainRate * timeDelta
                if currentTime - stats.lastActivity > 10 then -- If inactive for 10+ seconds
                    hungerDrain = hungerDrain * 0.5 -- Reduced drain when inactive
                end
                PlayerStats:updateStat(player, "hunger", -hungerDrain, true)
                
                -- Update thirst based on activity
                local thirstDrain = stats.thirstDrainRate * timeDelta
                if currentTime - stats.lastActivity > 10 then -- If inactive for 10+ seconds
                    thirstDrain = thirstDrain * 0.7 -- Reduced drain when inactive
                end
                PlayerStats:updateStat(player, "thirst", -thirstDrain, true)
                
                -- Health regeneration depends on hunger and thirst levels
                if stats.hunger > 50 and stats.thirst > 50 then
                    -- Natural regeneration
                    local healthRegen = stats.healthRegenRate * timeDelta
                    PlayerStats:updateStat(player, "health", healthRegen, true)
                elseif stats.hunger <= 25 or stats.thirst <= 25 then
                    -- Health deterioration at low survival stats
                    PlayerStats:updateStat(player, "health", -timeDelta * 0.5, true)
                end
                
                -- Apply status effects
                for effectName, effectData in pairs(stats.statusEffects) do
                    if effectData.active then
                        local effectTime = currentTime - effectData.startTime
                        
                        if effectTime >= effectData.duration then
                            -- Effect duration ended
                            PlayerStats:removeStatusEffect(player, effectName)
                        else
                            -- Apply ongoing effect damage/healing
                            if effectName == "BLEEDING" then
                                -- Bleeding: 2 HP every 2 seconds
                                if math.floor(effectTime * 10) % 20 == 0 then
                                    PlayerStats:applyDamage(player, 2 * effectData.intensity, "BLEEDING")
                                end
                            elseif effectName == "POISON" then
                                -- Poison: 3 HP every 1.5 seconds
                                if math.floor(effectTime * 10) % 15 == 0 then
                                    PlayerStats:applyDamage(player, 3 * effectData.intensity, "POISON")
                                end
                            elseif effectName == "HYPOTHERMIA" then
                                -- Hypothermia: 1 HP every 5 seconds
                                if math.floor(effectTime) % 5 == 0 then
                                    PlayerStats:applyDamage(player, 1 * effectData.intensity, "HYPOTHERMIA")
                                end
                            end
                        end
                    end
                end
                
                -- Update last update time
                stats.lastUpdate = currentTime
            end
        end
    end
end

-- Track player activity
local function trackPlayerActivity(player)
    if PlayerStats.playerStats[player] then
        PlayerStats.playerStats[player].lastActivity = tick()
    end
end

-- Player joined game
local function onPlayerAdded(player)
    initializePlayerStats(player)
    
    -- Track player activity for survival systems
    player.CharacterAdded:Connect(function(character)
        -- Connect to character movement/input
        task.wait(1) -- Wait for character to fully load
        trackPlayerActivity(player)
        
        -- Connect to humanoid root part movement
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        if humanoidRootPart then
            local connection
            connection = humanoidRootPart.AncestryChanged:Connect(function()
                if not humanoidRootPart.Parent then
                    connection:Disconnect()
                    trackPlayerActivity(player)
                end
            end)
        end
    end)
    
    -- Track input activity
    player.Idled:Connect(function()
        trackPlayerActivity(player)
    end)
    
    -- Store reference for cleanup
    player.AncestryChanged:Connect(function()
        if not player.Parent then
            -- Player left
            if PlayerStats.playerStats[player] then
                PlayerStats.playerStats[player] = nil
            end
        end
    end)
    
    -- Initialize for existing character if present
    if player.Character then
        trackPlayerActivity(player)
    end
end

-- Initialize player stats service
function PlayerStats.init()
    print("PlayerStats initialized")
    
    -- Connect to player events
    Players.PlayerAdded:Connect(onPlayerAdded)
    
    -- Initialize stats for existing players
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    
    -- Start regular update loop
    if not PlayerStats.statsUpdateConnection then
        PlayerStats.statsUpdateConnection = RunService.Heartbeat:Connect(updatePlayerStats)
    end
    
    -- Handle remote events from clients (stat changes, status effects, etc.)
    statsRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}
        
        if action == "RESTORE_HEALTH" then
            local amount = args[1]
            PlayerStats:updateStat(player, "health", amount, true)
        elseif action == "RESTORE_HUNGER" then
            local amount = args[1]
            PlayerStats:updateStat(player, "hunger", amount, true)
        elseif action == "RESTORE_THIRST" then
            local amount = args[1]
            PlayerStats:updateStat(player, "thirst", amount, true)
        elseif action == "APPLY_STATUS_EFFECT" then
            local effectName, duration, intensity = args[1], args[2], args[3]
            PlayerStats:addStatusEffect(player, effectName, duration, intensity)
        elseif action == "REMOVE_STATUS_EFFECT" then
            local effectName = args[1]
            PlayerStats:removeStatusEffect(player, effectName)
        end
    end)
end

return PlayerStats