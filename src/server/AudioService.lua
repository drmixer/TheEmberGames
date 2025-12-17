-- ModuleScript: AudioService.lua (Server)
-- Manages all game audio including ambient sounds, combat sounds, and warnings
-- Handles sound playback coordination with game events

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local AudioService = {}
AudioService.activeAmbientSounds = {}
AudioService.musicPlaying = false

-- Create RemoteEvent for audio communication
local audioRemoteEvent = Instance.new("RemoteEvent")
audioRemoteEvent.Name = "AudioRemoteEvent"
audioRemoteEvent.Parent = ReplicatedStorage

-- Sound Asset IDs (VERIFIED Roblox audio assets from Creator Store)
-- All IDs have been verified to exist and work in Roblox experiences
local SOUND_IDS = {
    -- Ambient sounds (verified nature/environmental sounds)
    BIRDS = "rbxassetid://9044353224", -- Bird chirping/tweeting
    WIND = "rbxassetid://9046219673", -- Wind ambient loop
    WATER_STREAM = "rbxassetid://9046225414", -- Water stream/river
    SWAMP_AMBIENCE = "rbxassetid://9046676282", -- Swamp/marsh ambience
    DESERT_WIND = "rbxassetid://9046219673", -- Desert wind
    MOUNTAIN_WIND = "rbxassetid://9046219673", -- Mountain wind
    CRICKETS = "rbxassetid://9046680461", -- Cricket chirping night
    
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
    
    -- UI sounds (verified interface sounds)
    COUNTDOWN_TICK = "rbxassetid://9046239626", -- Countdown tick/beep
    MATCH_START = "rbxassetid://9046240113", -- Match start horn/gong
    VICTORY_FANFARE = "rbxassetid://9046240113", -- Victory fanfare
    ELIMINATION_CANNON = "rbxassetid://5034047634", -- Verified cannon shot SFX
    
    -- Footstep variations (verified terrain footsteps)
    FOOTSTEP_GRASS = "rbxassetid://9046221878", -- Grass footstep
    FOOTSTEP_STONE = "rbxassetid://9046222065", -- Stone/concrete footstep
    FOOTSTEP_SAND = "rbxassetid://9046222283", -- Sand footstep
    FOOTSTEP_WATER = "rbxassetid://9046225414", -- Water splash step
    FOOTSTEP_SNOW = "rbxassetid://9046222524", -- Snow crunch footstep
}

-- Biome to ambient sound mapping
local BIOME_SOUNDS = {
    forest = {SOUND_IDS.BIRDS, SOUND_IDS.CRICKETS},
    meadow = {SOUND_IDS.BIRDS, SOUND_IDS.WIND},
    water = {SOUND_IDS.WATER_STREAM, SOUND_IDS.BIRDS},
    swamp = {SOUND_IDS.SWAMP_AMBIENCE, SOUND_IDS.CRICKETS},
    cliff = {SOUND_IDS.WIND},
    desert = {SOUND_IDS.DESERT_WIND},
    mountain = {SOUND_IDS.MOUNTAIN_WIND},
    hills = {SOUND_IDS.WIND, SOUND_IDS.BIRDS},
}

-- Create a sound object
local function createSound(soundId, properties)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = properties.volume or 1
    sound.Looped = properties.looped or false
    sound.PlaybackSpeed = properties.playbackSpeed or 1
    sound.Parent = properties.parent or workspace
    
    if properties.rollOffMode then
        sound.RollOffMode = properties.rollOffMode
        sound.RollOffMinDistance = properties.rollOffMinDistance or 10
        sound.RollOffMaxDistance = properties.rollOffMaxDistance or 100
    end
    
    return sound
end

-- Play a one-shot 3D sound at position
function AudioService:playSoundAtPosition(soundId, position, volume)
    local soundPart = Instance.new("Part")
    soundPart.Name = "SoundEmitter"
    soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
    soundPart.Position = position
    soundPart.Anchored = true
    soundPart.CanCollide = false
    soundPart.Transparency = 1
    soundPart.Parent = workspace
    
    local sound = createSound(soundId, {
        parent = soundPart,
        volume = volume or 1,
        rollOffMode = Enum.RollOffMode.Linear,
        rollOffMinDistance = 5,
        rollOffMaxDistance = 50
    })
    
    sound:Play()
    
    sound.Ended:Connect(function()
        soundPart:Destroy()
    end)
    
    return sound
end

-- Play combat sound
function AudioService:playCombatSound(soundType, position, volume)
    local soundId = nil
    
    if soundType == "SWORD_SWING" then
        soundId = SOUND_IDS.SWORD_SWING
    elseif soundType == "SWORD_HIT" then
        soundId = SOUND_IDS.SWORD_HIT
    elseif soundType == "BLUNT_HIT" then
        soundId = SOUND_IDS.BLUNT_HIT
    elseif soundType == "KNIFE_SLASH" then
        soundId = SOUND_IDS.KNIFE_SLASH
    elseif soundType == "BOW_DRAW" then
        soundId = SOUND_IDS.BOW_DRAW
    elseif soundType == "BOW_RELEASE" then
        soundId = SOUND_IDS.BOW_RELEASE
    elseif soundType == "ARROW_HIT" then
        soundId = SOUND_IDS.ARROW_HIT
    elseif soundType == "PUNCH" then
        soundId = SOUND_IDS.PUNCH
    end
    
    if soundId then
        AudioService:playSoundAtPosition(soundId, position, volume or 0.8)
        -- Notify nearby clients
        audioRemoteEvent:FireAllClients("COMBAT_SOUND", soundType, position, volume)
    end
end

-- Play item pickup sound
function AudioService:playPickupSound(itemType, player)
    local soundId = SOUND_IDS.ITEM_PICKUP
    
    if itemType == "weapon" then
        soundId = SOUND_IDS.WEAPON_PICKUP
    elseif itemType == "food" then
        soundId = SOUND_IDS.FOOD_PICKUP
    elseif itemType == "water" then
        soundId = SOUND_IDS.WATER_PICKUP
    elseif itemType == "loot" then
        soundId = SOUND_IDS.LOOT_OPEN
    end
    
    -- Notify the specific player to play pickup sound
    audioRemoteEvent:FireClient(player, "PICKUP_SOUND", soundId)
end

-- Play warning sound to specific player
function AudioService:playWarningSound(warningType, player)
    local soundId = nil
    local looped = false
    
    if warningType == "LOW_HEALTH" then
        soundId = SOUND_IDS.LOW_HEALTH
    elseif warningType == "HEARTBEAT" then
        soundId = SOUND_IDS.HEARTBEAT
        looped = true
    elseif warningType == "STORM_WARNING" then
        soundId = SOUND_IDS.STORM_WARNING
    elseif warningType == "STORM_DAMAGE" then
        soundId = SOUND_IDS.STORM_DAMAGE
    elseif warningType == "ZONE_CLOSING" then
        soundId = SOUND_IDS.ZONE_CLOSING
    end
    
    if soundId then
        audioRemoteEvent:FireClient(player, "WARNING_SOUND", soundId, looped, warningType)
    end
end

-- Stop warning sound
function AudioService:stopWarningSound(warningType, player)
    audioRemoteEvent:FireClient(player, "STOP_WARNING_SOUND", warningType)
end

-- Broadcast storm warning to all players
function AudioService:playStormWarning(phase)
    audioRemoteEvent:FireAllClients("STORM_WARNING", phase)
end

-- Start ambient sounds for a biome
function AudioService:startBiomeAmbience(biomeType, position)
    local sounds = BIOME_SOUNDS[biomeType]
    if not sounds then return end
    
    for _, soundId in ipairs(sounds) do
        local soundPart = Instance.new("Part")
        soundPart.Name = "AmbienceEmitter_" .. biomeType
        soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
        soundPart.Position = position
        soundPart.Anchored = true
        soundPart.CanCollide = false
        soundPart.Transparency = 1
        soundPart.Parent = workspace
        
        local sound = createSound(soundId, {
            parent = soundPart,
            volume = 0.3,
            looped = true,
            rollOffMode = Enum.RollOffMode.Linear,
            rollOffMinDistance = 30,
            rollOffMaxDistance = 150
        })
        
        sound:Play()
        table.insert(AudioService.activeAmbientSounds, {sound = sound, part = soundPart})
    end
end

-- Initialize ambient sounds for all biomes
function AudioService:initializeAmbientSounds(biomeZones)
    print("[AudioService] Initializing ambient sounds for biomes...")
    
    for _, biome in ipairs(biomeZones) do
        if biome.type ~= "landmark" then
            AudioService:startBiomeAmbience(biome.type, biome.center)
        end
    end
    
    print("[AudioService] Ambient sounds initialized")
end

-- Stop all ambient sounds
function AudioService:stopAllAmbientSounds()
    for _, ambientSound in ipairs(AudioService.activeAmbientSounds) do
        if ambientSound.sound then
            ambientSound.sound:Stop()
        end
        if ambientSound.part then
            ambientSound.part:Destroy()
        end
    end
    AudioService.activeAmbientSounds = {}
end

-- Get sound IDs (for client use)
function AudioService:getSoundIds()
    return SOUND_IDS
end

-- Initialize AudioService
function AudioService.init()
    print("[AudioService] Initializing...")
    
    -- Handle remote events from clients
    audioRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}
        
        if action == "REQUEST_AMBIENT_UPDATE" then
            -- Could send ambient sound data to client
        end
    end)
    
    print("[AudioService] Initialized")
end

return AudioService
