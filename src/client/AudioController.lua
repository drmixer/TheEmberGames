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
-- Remote events (initialized in init)
local AudioRemoteEvent = nil
local StatsRemoteEvent = nil

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
    
    -- UI Sounds (Premium Interaction)
    UI_HOVER = "rbxassetid://6895079853", -- Subtle tick
    UI_CLICK = "rbxassetid://6042053626", -- Satisfying click
    UI_ERROR = "rbxassetid://6042052926", -- Error
    UI_EQUIP = "rbxassetid://6035183870", -- Equip
    UI_NOTIFICATION = "rbxassetid://6035184620", -- Notification
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

-- Play UI Sound
function AudioController:playUISound(soundName)
    local id = SOUND_IDS[soundName] or SOUND_IDS.UI_CLICK
    playSound(id, 0.5, false, PlayerGui)
end

-- Auto-connect button for generic hover/click sounds
function AudioController:connectButton(button)
    if not button then return end
    
    button.MouseEnter:Connect(function()
        AudioController:playUISound("UI_HOVER")
    end)
    
    button.MouseButton1Click:Connect(function()
        AudioController:playUISound("UI_CLICK")
    end)
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

-- Storm Audio Logic
AudioController.stormAudio = {
    windSound = nil,
    rumbleSound = nil,
    active = false,
    connection = nil,
    currentPhase = 0,
    center = Vector3.new(0, 0, 0),
    radius = 1000,
    warningSound = nil
}

function AudioController:startStormAudio(phase, radius, center)
    local sa = AudioController.stormAudio
    sa.currentPhase = phase
    sa.radius = radius or 1000
    sa.center = center or Vector3.new(0, 0, 0)
    
    if sa.active then return end
    sa.active = true
    
    -- Create looped ambient sounds
    if not sa.windSound then
        sa.windSound = Instance.new("Sound")
        sa.windSound.Name = "StormWind"
        sa.windSound.SoundId = "rbxassetid://9046676282" -- Howling wind
        sa.windSound.Volume = 0
        sa.windSound.Looped = true
        sa.windSound.Parent = PlayerGui
        sa.windSound:Play()
    end
    
    if not sa.rumbleSound then
        sa.rumbleSound = Instance.new("Sound")
        sa.rumbleSound.Name = "StormRumble"
        sa.rumbleSound.SoundId = "rbxassetid://9114243671" -- Deep rumble
        sa.rumbleSound.Volume = 0
        sa.rumbleSound.Looped = true
        sa.rumbleSound.Pitch = 0.5
        sa.rumbleSound.Parent = PlayerGui
        sa.rumbleSound:Play()
    end
    
    -- Play phase warning sound
    local volume = 0.3 + (phase * 0.1)
    sa.warningSound = playSound(SOUND_IDS.ZONE_CLOSING, math.min(volume, 0.8), false, PlayerGui)
    
    print("[AudioController] Storm audio started - Phase " .. phase)
    
    -- Connect heartbeat for dynamic proximity audio
    if sa.connection then sa.connection:Disconnect() end
    
    sa.connection = RunService.Heartbeat:Connect(function()
        if not sa.active or not Player.Character then return end
        
        local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- Calculate distance to storm edge
        local playerDist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - sa.center).Magnitude
        local distToEdge = math.abs(sa.radius - playerDist)
        local isInside = playerDist < sa.radius
        
        -- Audio logic:
        -- 1. Inside safe zone: quiet, gets louder near edge
        -- 2. Outside safe zone: LOUD, muffled/distorted
        
        local targetWindVol = 0
        local targetRumbleVol = 0
        local targetPitch = 1
        
        if isInside then
            -- Safe, but hear it coming
            if distToEdge < 200 then
                -- Within 200 studs of edge, fade in
                local proximity = 1 - (distToEdge / 200) -- 0 to 1
                targetWindVol = 0.1 + (proximity * 0.4)
                targetRumbleVol = proximity * 0.3
            else
                -- Deep inside safe zone
                targetWindVol = 0.05 -- Faint background
                targetRumbleVol = 0
            end
        else
            -- IN THE STORM
            targetWindVol = 0.8 + (math.random() * 0.2) -- 0.8-1.0 fluctuating
            targetRumbleVol = 0.6
            targetPitch = 0.8 -- Lower pitch feels oppressive
            
            -- Screen shake or other effects could trigger here too
        end
        
        -- Smoothly interpolate volume
        if sa.windSound then
            sa.windSound.Volume = sa.windSound.Volume + (targetWindVol - sa.windSound.Volume) * 0.1
            sa.windSound.Pitch = targetPitch
        end
        
        if sa.rumbleSound then
            sa.rumbleSound.Volume = sa.rumbleSound.Volume + (targetRumbleVol - sa.rumbleSound.Volume) * 0.1
        end
    end)
end

function AudioController:stopStormAudio()
    local sa = AudioController.stormAudio
    sa.active = false
    
    if sa.connection then 
        sa.connection:Disconnect() 
        sa.connection = nil
    end
    
    if sa.windSound then
        TweenService:Create(sa.windSound, TweenInfo.new(2), {Volume = 0}):Play()
        task.delay(2, function() 
            if sa.windSound then sa.windSound:Stop() end 
        end)
    end
    
    if sa.rumbleSound then
        TweenService:Create(sa.rumbleSound, TweenInfo.new(2), {Volume = 0}):Play()
        task.delay(2, function() 
            if sa.rumbleSound then sa.rumbleSound:Stop() end 
        end)
    end
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
-- Initialize AudioController
function AudioController.init()
    print("[AudioController] Initializing...")
    
    createAudioGui()
    
    -- Connect to audio remote events asynchronously
    task.spawn(function()
        AudioRemoteEvent = ReplicatedStorage:WaitForChild("AudioRemoteEvent", 30)
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
                    local radius = args[2] -- Expecting radius now
                    local center = args[3] -- Expecting center now
                    -- Use new storm audio system if radius/center provided
                    if radius then
                        AudioController:startStormAudio(phase, radius, center)
                    else
                        AudioController:startStormAudio(phase, 1000, Vector3.new(0,0,0)) -- Fallback
                    end
                elseif eventType == "MATCH_END" then
                    AudioController:stopStormAudio()
                end
            end)
        else
            warn("[AudioController] AudioRemoteEvent timed out")
        end
    end)
    
    -- Connect to EventsRemote for storm phases (backup/main source)
    task.spawn(function()
        local EventsRemoteEvent = ReplicatedStorage:WaitForChild("EventsRemoteEvent", 30)
        if EventsRemoteEvent then
            EventsRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
                local args = {...}
                if eventType == "STORM_PHASE_ACTIVE" then
                    local phase = args[1]
                    local radius = args[2]
                    local center = args[3]
                    AudioController:startStormAudio(phase, radius, center)
                end
            end)
        end
    end)
    
    -- Connect to stats for health monitoring
    task.spawn(function()
        StatsRemoteEvent = ReplicatedStorage:WaitForChild("StatsRemoteEvent", 30)
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
    end)
    
    print("[AudioController] Initialized successfully (Connecting remotes async)")
end

-- Initialize when module loads
AudioController.init()

return AudioController
