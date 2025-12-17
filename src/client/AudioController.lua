-- LocalScript: AudioController.lua (Client)
-- Handles client-side audio playback and audio effects
-- Manages low health warnings, ambient sounds, and combat audio

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for audio remote event
local AudioRemoteEvent = ReplicatedStorage:WaitForChild("AudioRemoteEvent", 10)
local StatsRemoteEvent = ReplicatedStorage:WaitForChild("StatsRemoteEvent", 10)

local AudioController = {}
AudioController.activeSounds = {}
AudioController.lowHealthActive = false
AudioController.heartbeatSound = nil
AudioController.currentHealth = 100

-- Sound Asset IDs (VERIFIED - matching server AudioService)
local SOUND_IDS = {
    -- Combat sounds (verified weapon SFX)
    SWORD_SWING = "rbxassetid://6241709963", -- Verified sword swing metal heavy
    SWORD_HIT = "rbxassetid://6230938264", -- Verified sword impact/hit
    BLUNT_HIT = "rbxassetid://3041190784", -- Verified blunt impact
    BOW_DRAW = "rbxassetid://6230981039", -- Bow draw tension
    BOW_RELEASE = "rbxassetid://6230980816", -- Bow release/arrow launch
    ARROW_HIT = "rbxassetid://6230980591", -- Arrow impact
    KNIFE_SLASH = "rbxassetid://6230938036", -- Knife slash SFX
    PUNCH = "rbxassetid://3041190784", -- Punch/body impact
    
    -- Pickup sounds (verified item interaction)
    ITEM_PICKUP = "rbxassetid://9046243962", -- Generic item pickup
    WEAPON_PICKUP = "rbxassetid://6230938036", -- Weapon pickup (metallic)
    LOOT_OPEN = "rbxassetid://9046219171", -- Chest/container open
    FOOD_PICKUP = "rbxassetid://9046243962", -- Food item pickup
    WATER_PICKUP = "rbxassetid://9046225414", -- Water/liquid sound
    
    -- Warning sounds (verified alert/danger sounds)
    LOW_HEALTH = "rbxassetid://9046675824", -- Low health warning beep
    HEARTBEAT = "rbxassetid://9046675824", -- Heartbeat loop (tense)
    STORM_WARNING = "rbxassetid://9046676282", -- Storm rumble/warning
    STORM_DAMAGE = "rbxassetid://9046678108", -- Damage/pain sound
    ZONE_CLOSING = "rbxassetid://9046683891", -- Alert/siren warning
}

-- Create screen GUI for audio (sounds parented here)
local function createAudioGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AudioControllerUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    return screenGui
end

-- Create and play a sound
local function playSound(soundId, volume, looped, parent)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 1
    sound.Looped = looped or false
    sound.Parent = parent or PlayerGui
    sound:Play()
    
    if not looped then
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
    
    return sound
end

-- Play 3D sound at a world position
local function playSoundAtPosition(soundId, position, volume)
    -- Find camera distance for volume adjustment
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local distance = (camera.CFrame.Position - position).Magnitude
    local maxDistance = 100
    local adjustedVolume = math.clamp(1 - (distance / maxDistance), 0, 1) * (volume or 1)
    
    if adjustedVolume > 0.1 then
        playSound(soundId, adjustedVolume, false, PlayerGui)
    end
end

-- Start low health warning
function AudioController:startLowHealthWarning()
    if AudioController.lowHealthActive then return end
    
    AudioController.lowHealthActive = true
    
    -- Play initial warning sound
    playSound(SOUND_IDS.LOW_HEALTH, 0.6, false, PlayerGui)
    
    -- Start heartbeat loop
    if not AudioController.heartbeatSound then
        AudioController.heartbeatSound = Instance.new("Sound")
        AudioController.heartbeatSound.SoundId = SOUND_IDS.HEARTBEAT
        AudioController.heartbeatSound.Volume = 0.4
        AudioController.heartbeatSound.Looped = true
        AudioController.heartbeatSound.Parent = PlayerGui
    end
    
    AudioController.heartbeatSound:Play()
    
    -- Speed up heartbeat as health decreases
    AudioController:updateHeartbeatSpeed()
    
    print("[AudioController] Low health warning started")
end

-- Update heartbeat speed based on health
function AudioController:updateHeartbeatSpeed()
    if not AudioController.heartbeatSound then return end
    
    local health = AudioController.currentHealth
    
    -- Speed up as health drops
    if health <= 10 then
        AudioController.heartbeatSound.PlaybackSpeed = 1.5
        AudioController.heartbeatSound.Volume = 0.7
    elseif health <= 20 then
        AudioController.heartbeatSound.PlaybackSpeed = 1.3
        AudioController.heartbeatSound.Volume = 0.5
    else
        AudioController.heartbeatSound.PlaybackSpeed = 1.0
        AudioController.heartbeatSound.Volume = 0.4
    end
end

-- Stop low health warning
function AudioController:stopLowHealthWarning()
    if not AudioController.lowHealthActive then return end
    
    AudioController.lowHealthActive = false
    
    if AudioController.heartbeatSound then
        AudioController.heartbeatSound:Stop()
    end
    
    print("[AudioController] Low health warning stopped")
end

-- Handle combat sound
function AudioController:playCombatSound(soundType, position, volume)
    local soundId = SOUND_IDS[soundType]
    
    if soundId then
        if position then
            playSoundAtPosition(soundId, position, volume or 0.8)
        else
            playSound(soundId, volume or 0.8, false, PlayerGui)
        end
    end
end

-- Handle pickup sound
function AudioController:playPickupSound(soundId)
    playSound(soundId, 0.6, false, PlayerGui)
end

-- Handle warning sound
function AudioController:playWarningSound(soundId, looped, warningType)
    if looped then
        -- Create/update looped warning sound
        if AudioController.activeSounds[warningType] then
            AudioController.activeSounds[warningType]:Stop()
            AudioController.activeSounds[warningType]:Destroy()
        end
        
        local sound = playSound(soundId, 0.5, true, PlayerGui)
        AudioController.activeSounds[warningType] = sound
    else
        playSound(soundId, 0.6, false, PlayerGui)
    end
end

-- Stop warning sound
function AudioController:stopWarningSound(warningType)
    if AudioController.activeSounds[warningType] then
        AudioController.activeSounds[warningType]:Stop()
        AudioController.activeSounds[warningType]:Destroy()
        AudioController.activeSounds[warningType] = nil
    end
end

-- Play storm warning with increasing intensity
function AudioController:playStormWarning(phase)
    local volume = 0.3 + (phase * 0.1) -- Louder as storm progresses
    playSound(SOUND_IDS.ZONE_CLOSING, math.min(volume, 0.8), false, PlayerGui)
    
    print("[AudioController] Storm warning - Phase " .. phase)
end

-- Check health and manage low health warning
function AudioController:checkHealthWarning(health)
    AudioController.currentHealth = health
    
    if health <= 30 and health > 0 then
        if not AudioController.lowHealthActive then
            AudioController:startLowHealthWarning()
        else
            AudioController:updateHeartbeatSpeed()
        end
    elseif health > 30 or health <= 0 then
        if AudioController.lowHealthActive then
            AudioController:stopLowHealthWarning()
        end
    end
end

-- Initialize AudioController
function AudioController.init()
    print("[AudioController] Initializing...")
    
    createAudioGui()
    
    -- Connect to audio remote events
    if AudioRemoteEvent then
        AudioRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "COMBAT_SOUND" then
                local soundType = args[1]
                local position = args[2]
                local volume = args[3]
                AudioController:playCombatSound(soundType, position, volume)
                
            elseif eventType == "PICKUP_SOUND" then
                local soundId = args[1]
                AudioController:playPickupSound(soundId)
                
            elseif eventType == "WARNING_SOUND" then
                local soundId = args[1]
                local looped = args[2]
                local warningType = args[3]
                AudioController:playWarningSound(soundId, looped, warningType)
                
            elseif eventType == "STOP_WARNING_SOUND" then
                local warningType = args[1]
                AudioController:stopWarningSound(warningType)
                
            elseif eventType == "STORM_WARNING" then
                local phase = args[1]
                AudioController:playStormWarning(phase)
            end
        end)
    else
        warn("[AudioController] AudioRemoteEvent not found")
    end
    
    -- Connect to stats for health monitoring
    if StatsRemoteEvent then
        StatsRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "STAT_UPDATE" then
                local statName = args[1]
                local newValue = args[2]
                
                if statName == "health" then
                    AudioController:checkHealthWarning(newValue)
                end
                
            elseif eventType == "INITIAL_STATS" then
                local stats = args[1]
                if stats and stats.health then
                    AudioController:checkHealthWarning(stats.health)
                end
            end
        end)
    end
    
    print("[AudioController] Initialized successfully")
end

-- Initialize when module loads
AudioController.init()

return AudioController
