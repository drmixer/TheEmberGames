A-- LocalScript: TributeIntro.lua
-- Handles the cinematic "Tube Rise" sequence visuals and audio
-- Adds a premium feel to the match start

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local SpawnerRemoteEvent = ReplicatedStorage:WaitForChild("SpawnerRemoteEvent")

local TributeIntro = {}

local SOUND_IDS = {
    RISE_MECHANISM = "rbxassetid://156644485", -- Heavy mechanical lifting
    RISE_AMBIENCE = "rbxassetid://306422326", -- Machinery ambience
    LOCK_THUD = "rbxassetid://3398620867", -- Metal Thud when locking in place
}

function TributeIntro.playRiseSequence(duration)
    print("[TributeIntro] Starting Rise Sequence")
    
    -- 1. Camera Visuals (Force look at Cornucopia/Center)
    -- 1. Camera Visuals (Force look at Cornucopia/Center)
    Camera.CameraType = Enum.CameraType.Scriptable
    
    local root = Player.Character and Player.Character.PrimaryPart
    local center = Vector3.new(0, 5, 0) -- Look slightly above center

    
    -- 2. Camera Shake Effect
    local shakeActive = true
    local startTime = tick()
    
    -- Play Sounds
    local mechSound = Instance.new("Sound")
    mechSound.SoundId = SOUND_IDS.RISE_MECHANISM
    mechSound.Volume = 1.2
    mechSound.PlaybackSpeed = 0.8 -- Make it sound deeper heavier
    mechSound.Parent = workspace
    mechSound:Play()
    
    -- Camera Loop
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not shakeActive then 
            connection:Disconnect()
            return 
        end
        
        -- Update Camera Position (Follow player as they rise)
        if Player.Character and Player.Character.PrimaryPart then
             local currentRoot = Player.Character.PrimaryPart
             local currentRoot = Player.Character.PrimaryPart
             
             -- Fix: Keep camera behind player, looking forward (No center lock)
             local fwd = currentRoot.CFrame.LookVector
             local camPos = currentRoot.Position - (fwd * 10) + Vector3.new(0, 4, 0)
             
             -- Maintain standard third-person angle
             Camera.CFrame = CFrame.lookAt(camPos, currentRoot.Position + Vector3.new(0, 2, 0))
        end
        
        local elapsed = tick() - startTime
        local progress = math.clamp(elapsed / duration, 0, 1)
        
        -- Fade out intensity near the end to prevent snap
        local fade = 1 - (progress ^ 4) -- Keeps intensity high until end, then drops
        local intensity = 0.3 * fade
        
        local rx = (math.random() - 0.5) * intensity
        local ry = (math.random() - 0.5) * intensity
        local rz = (math.random() - 0.5) * intensity / 2
        
        -- Apply shake offset to camera
        local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
        if hum then
            hum.CameraOffset = Vector3.new(rx, ry, rz)
        end
        
        -- Stop when done
        if progress >= 1 then
            shakeActive = false
            if hum then hum.CameraOffset = Vector3.new(0,0,0) end
            
            -- Final Thud
            local thud = Instance.new("Sound")
            thud.SoundId = SOUND_IDS.LOCK_THUD
            thud.Volume = 2
            thud.Parent = workspace
            thud:Play()
            game:GetService("Debris"):AddItem(thud, 2)
            
            mechSound:Stop()
            mechSound:Destroy()
            
            -- TRANSITION FIX: Smoothly blend to player's view before releasing control
            local transitionStart = tick()
            local transitionDuration = 0.5
            local startTransCF = Camera.CFrame
            
            local transConnection
            transConnection = RunService.RenderStepped:Connect(function()
                local t = (tick() - transitionStart) / transitionDuration
                
                -- Target: Player's Head CFrame (First Person / Close Third)
                local char = Player.Character
                if not char then return end
                local head = char:FindFirstChild("Head") 
                if not head then return end
                
                -- We want to match where the custom camera starts (usually slightly behind)
                -- But smooth lerp to head is a good robust reset
                local targetCF = head.CFrame * CFrame.new(0, 0, 0) -- Or desired start offset
                
                if t >= 1 then
                    transConnection:Disconnect()
                    Camera.CameraType = Enum.CameraType.Custom
                    -- Explicitly set Subject to ensure it locks back correctly
                    Camera.CameraSubject = char:FindFirstChild("Humanoid")
                    return
                end
                
                Camera.CFrame = startTransCF:Lerp(targetCF, t)
            end)
        end
    end)
end

function TributeIntro.init()
    print("[TributeIntro] Visuals Initialized")
    
    SpawnerRemoteEvent.OnClientEvent:Connect(function(eventType, duration)
        if eventType == "RISE_SEQUENCE_START" then
            TributeIntro.playRiseSequence(duration or 6)
        end
    end)
end

TributeIntro.init()

return TributeIntro
