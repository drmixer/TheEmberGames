-- LocalScript: CameraHider.client.lua
-- Forces camera to look at the sky until the player is safely on the platform

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Start hidden by default to prevent "Under Cornucopia" flash
local isHidden = true

local function updateCamera()
    if isHidden and camera then
        camera.CameraType = Enum.CameraType.Scriptable
        -- Look at the arena center from high up (Bird's eye view)
        camera.CFrame = CFrame.new(0, 300, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    end
end

-- Force immediately (don't wait for first frame)
if isHidden and camera then
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.new(0, 300, 0) * CFrame.Angles(math.rad(-90), 0, 0)
end

-- Bind with high priority to override default camera
RunService:BindToRenderStep("CameraHider", Enum.RenderPriority.Camera.Value + 10, updateCamera)

-- Async Listener for server command to release camera
task.spawn(function()
    local spawnerRemote = ReplicatedStorage:WaitForChild("SpawnerRemoteEvent", 30)
    
    if spawnerRemote then
        spawnerRemote.OnClientEvent:Connect(function(action)
            if action == "RESET_CAMERA" then
                print("[CameraHider] Server requested camera release")
                isHidden = false
                pcall(function() RunService:UnbindFromRenderStep("CameraHider") end)
                
                if camera then
                    camera.CameraType = Enum.CameraType.Custom
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        camera.CameraSubject = player.Character.Humanoid
                    end
                end
            end
        end)
    end
end)

-- Safety fallback
task.delay(10, function()
    if isHidden then
        isHidden = false
        pcall(function() RunService:UnbindFromRenderStep("CameraHider") end)
        if camera then camera.CameraType = Enum.CameraType.Custom end
    end
end)

