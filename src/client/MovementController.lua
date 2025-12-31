-- LocalScript: MovementController.lua
-- Handles Sprint, Crouch, and Dynamic FOV
-- Adds tactical movement depth to the game

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local MovementController = {}
MovementController.isSprinting = false
MovementController.isCrouching = false
MovementController.stamina = 100
MovementController.lastSprintTime = 0

-- Config
local CONFIG = {
    WALK_SPEED = 16,
    SPRINT_SPEED = 25,
    CROUCH_SPEED = 8,
    
    JUMP_POWER_NORMAL = 50,
    JUMP_POWER_CROUCH = 0, -- No jump while checked
    
    FOV_NORMAL = 70,
    FOV_SPRINT = 85,
    
    STAMINA_MAX = 100,
    STAMINA_DRAIN = 15, -- Per second
    STAMINA_REGEN = 10, -- Per second
    STAMINA_COOLDOWN = 1.5 -- Seconds before regen starts
}

-- Animations (Ids or keyframe sequences would go here)
-- We will just use Speed modification for MVP

function MovementController:updateCameraFOV(dt)
    local targetFOV = CONFIG.FOV_NORMAL
    if MovementController.isSprinting then
        targetFOV = CONFIG.FOV_SPRINT
    end
    
    -- Smoothly interpolate FOV
    Camera.FieldOfView = Camera.FieldOfView + (targetFOV - Camera.FieldOfView) * dt * 5
end

function MovementController:updateStamina(dt)
    if MovementController.isSprinting and Player.Character and Player.Character.Humanoid.MoveDirection.Magnitude > 0 then
        -- Drain
        MovementController.stamina = math.max(0, MovementController.stamina - CONFIG.STAMINA_DRAIN * dt)
        MovementController.lastSprintTime = tick()
        
        -- Stop sprinting if empty
        if MovementController.stamina <= 0 then
            MovementController:stopSprinting()
        end
    elseif tick() - MovementController.lastSprintTime > CONFIG.STAMINA_COOLDOWN then
        -- Regen
        MovementController.stamina = math.min(CONFIG.STAMINA_MAX, MovementController.stamina + CONFIG.STAMINA_REGEN * dt)
    end
end

function MovementController:startSprinting()
    if MovementController.isCrouching then MovementController:stopCrouching() end
    if MovementController.stamina < 10 then return end -- Need minimum stamina
    
    MovementController.isSprinting = true
    local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = CONFIG.SPRINT_SPEED
    end
end

function MovementController:stopSprinting()
    MovementController.isSprinting = false
    local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = CONFIG.WALK_SPEED
    end
end

function MovementController:startCrouching()
    if MovementController.isSprinting then MovementController:stopSprinting() end
    
    MovementController.isCrouching = true
    local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
    if hum then
        if not MovementController.originalHipHeight then
            MovementController.originalHipHeight = hum.HipHeight -- Cache it
        end
        
        hum.WalkSpeed = CONFIG.CROUCH_SPEED
        hum.JumpPower = CONFIG.JUMP_POWER_CROUCH
        
        -- Crouch behavior (Camera offset only since we lack animation)
        -- This avoids clipping into the ground
        TweenService:Create(hum, TweenInfo.new(0.3), {CameraOffset = Vector3.new(0, -1.5, 0)}):Play()
    end
end

function MovementController:stopCrouching()
    MovementController.isCrouching = false
    local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = CONFIG.WALK_SPEED
        hum.JumpPower = CONFIG.JUMP_POWER_NORMAL
        
        TweenService:Create(hum, TweenInfo.new(0.3), {CameraOffset = Vector3.new(0, 0, 0)}):Play()
    end
end

-- ============ DODGE MECHANIC ============
MovementController.lastDodgeTime = 0
MovementController.DODGE_COOLDOWN = 1.5
MovementController.DODGE_FORCE = 6000 -- Mass dependent, assume ~100 mass

function MovementController:dodge()
    local now = tick()
    if now - MovementController.lastDodgeTime < MovementController.DODGE_COOLDOWN then return end
    
    local char = Player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    
    -- Consume Stamina
    if MovementController.stamina < 20 then return end
    MovementController.stamina = MovementController.stamina - 20
    MovementController.lastDodgeTime = now
    
    -- Direction
    local dir = hum.MoveDirection
    if dir.Magnitude == 0 then
        dir = hrp.CFrame.LookVector * -1 -- Back hop if standing still
    end
    
    -- Apply Impulse
    -- Calculate mass for consistent force
    local mass = 0
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then mass = mass + part:GetMass() end
    end
    
    local force = dir * (mass * 40) -- 40 is a good multiplier for a dash
    hrp:ApplyImpulse(force + Vector3.new(0, mass * 5, 0)) -- Slight hop
    
    -- Visuals
    -- Play roll animation if we had one, for now, simple lower
    if not MovementController.isCrouching then
        TweenService:Create(hum, TweenInfo.new(0.2), {CameraOffset = Vector3.new(0, -1.5, 0)}):Play()
        task.delay(0.2, function()
             TweenService:Create(hum, TweenInfo.new(0.3), {CameraOffset = Vector3.new(0, 0, 0)}):Play()
        end)
    end
    
    -- Sound (Dash whoosh)
    local s = Instance.new("Sound", hrp)
    s.SoundId = "rbxassetid://131070501" -- Jump/Air sound
    s.Volume = 0.5
    s.Pitch = 1.2
    s.PlayOnRemove = true
    s:Destroy()
end

local function onInputBegan(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift then
        MovementController:startSprinting()
    elseif input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
        if MovementController.isCrouching then
            MovementController:stopCrouching()
        else
            MovementController:startCrouching()
        end
    elseif input.KeyCode == Enum.KeyCode.LeftAlt then
        MovementController:dodge()
    end
end

local function onInputEnded(input, gpe)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        MovementController:stopSprinting()
    end
end

function MovementController.init()
    print("[MovementController] Initializing...")
    UserInputService.InputBegan:Connect(onInputBegan)
    UserInputService.InputEnded:Connect(onInputEnded)
    
    RunService.RenderStepped:Connect(function(dt)
        MovementController:updateCameraFOV(dt)
        MovementController:updateStamina(dt)
    end)
    
    -- Reset on spawn
    Player.CharacterAdded:Connect(function(char)
        MovementController.isSprinting = false
        MovementController.isCrouching = false
        MovementController.originalHipHeight = nil
        MovementController.stamina = CONFIG.STAMINA_MAX
        
        -- NUCLEAR OPTION: Continuously destroy default sounds
        -- This overrides any Roblox behavior by checking every frame
        RunService.Heartbeat:Connect(function()
            if not char then return end
            
            -- Check Head and RootPart specifically (most common locations)
            local partsToCheck = {char:FindFirstChild("Head"), char:FindFirstChild("HumanoidRootPart")}
            
            for _, part in pairs(partsToCheck) do
                if part then
                    for _, child in pairs(part:GetChildren()) do
                        if child:IsA("Sound") then
                            if child.Name == "Running" or child.Name == "Walking" or child.Name == "Jumping" or child.Name == "Landing" or child.Name == "Climbing" or child.Name == "GettingUp" then
                                if child.Playing then child:Stop() end
                                child:Destroy()
                            end
                        end
                    end
                end
            end
        end)
    end)
end

MovementController.init()
return MovementController
