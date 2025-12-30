-- LocalScript: MusicController.lua
-- Manages background music for the menu and loading screens
-- Fades music out when match starts, and back in when returning to lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local MusicController = {}
MusicController.music = nil
MusicController.isPlaying = false

-- Configuration
local MUSIC_ID = "rbxassetid://1845237632" -- Gloriana - Orchestra & Choir
local MAX_VOLUME = 1.0
local FADE_TIME = 2.0

-- Create the music sound object
local function createMusic()
    local sound = Instance.new("Sound")
    sound.Name = "MenuMusic"
    sound.SoundId = MUSIC_ID
    sound.Volume = 0 -- Start at 0 for fade in
    sound.Looped = true
    sound.Parent = SoundService
    return sound
end

function MusicController:fadeIn()
    if not self.music then self.music = createMusic() end
    
    if not self.music.Playing then
        self.music:Play()
    end
    
    local tween = TweenService:Create(self.music, TweenInfo.new(FADE_TIME), {Volume = MAX_VOLUME})
    tween:Play()
    self.isPlaying = true
    print("[MusicController] Fading music in")
end

function MusicController:fadeOut()
    if not self.music then return end
    
    local tween = TweenService:Create(self.music, TweenInfo.new(FADE_TIME), {Volume = 0})
    tween:Play()
    
    -- Optional: Stop after fade (or just keep playing at 0 volume if we want instant resume)
    -- Keeping it playing at 0 volume is often smoother for re-entering
    self.isPlaying = false
    print("[MusicController] Fading music out")
end

function MusicController.init()
    print("[MusicController] Initializing...")
    
    -- Initial start
    MusicController:fadeIn()
    
    -- Connect to Match Events
    task.spawn(function()
        local MatchRemoteEvent = ReplicatedStorage:WaitForChild("MatchRemoteEvent", 30)
        local LobbyRemoteEvent = ReplicatedStorage:WaitForChild("LobbyRemoteEvent", 30)
        
        if MatchRemoteEvent then
            MatchRemoteEvent.OnClientEvent:Connect(function(eventType)
                if eventType == "MATCH_START" or eventType == "MATCH_STARTED" then
                    MusicController:fadeOut()
                elseif eventType == "MATCH_END" or eventType == "RETURN_TO_LOBBY" then
                    -- Delay slightly to allow loading screen to appear?
                    task.delay(1, function()
                        MusicController:fadeIn()
                    end)
                end
            end)
        end
        
        if LobbyRemoteEvent then
            LobbyRemoteEvent.OnClientEvent:Connect(function(eventType)
                if eventType == "MATCH_STARTING" then
                    MusicController:fadeOut()
                end
            end)
        end
    end)
end

MusicController.init()

return MusicController
