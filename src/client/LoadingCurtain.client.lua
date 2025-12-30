-- LocalScript: LoadingCurtain.client.lua
-- Creates an immediate black screen to hide initial loading glitches/spawning

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the curtain immediately
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingCurtain"
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 1000 -- Topmost
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Curtain"
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Add a loading logo or text if desired
local text = Instance.new("TextLabel")
text.Size = UDim2.new(1, 0, 0, 50)
text.Position = UDim2.new(0, 0, 0.5, -25)
text.BackgroundTransparency = 1
text.Text = "PREPARING ARENA..."
text.TextColor3 = Color3.fromRGB(200, 200, 200)
text.Font = Enum.Font.GothamBold
text.TextSize = 24
text.Parent = frame

-- Remove the curtain when server says ready
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local spawnerRemote = ReplicatedStorage:WaitForChild("SpawnerRemoteEvent", 10)

if spawnerRemote then
    spawnerRemote.OnClientEvent:Connect(function(action)
        if action == "RESET_CAMERA" then
            local tween = TweenService:Create(frame, TweenInfo.new(1), {BackgroundTransparency = 1})
            local textTween = TweenService:Create(text, TweenInfo.new(1), {TextTransparency = 1})
            tween:Play()
            textTween:Play()
            
            tween.Completed:Connect(function()
                screenGui:Destroy()
            end)
        end
    end)
end

-- Fallback safety
task.delay(6, function()
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
end)
