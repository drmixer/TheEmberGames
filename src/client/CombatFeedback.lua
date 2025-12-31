-- LocalScript: CombatFeedback.lua
-- Handles combat visual feedback on the client
-- Shows hit markers, damage numbers, screen shake, and combat effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Wait for combat remote events
local DamageRemoteEvent = ReplicatedStorage:FindFirstChild("DamageRemoteEvent") or Instance.new("RemoteEvent")
local WeaponRemoteEvent = ReplicatedStorage:FindFirstChild("WeaponRemoteEvent") or Instance.new("RemoteEvent")

local CombatFeedback = {}
CombatFeedback.screenGui = nil
CombatFeedback.hitMarkerFrame = nil
CombatFeedback.damageVignetteFrame = nil
CombatFeedback.shakingCamera = false
CombatFeedback.originalCameraCFrame = nil

-- Configuration
local CONFIG = {
    HIT_MARKER_SIZE = 40,
    HIT_MARKER_DURATION = 0.3,
    DAMAGE_NUMBER_DURATION = 1.5,
    SCREEN_SHAKE_DURATION = 0.2,
    SCREEN_SHAKE_INTENSITY = 0.5,
    CRITICAL_SHAKE_MULTIPLIER = 2,
    VIGNETTE_DURATION = 0.8,
}

-- Sounds
local SOUNDS = {
    HIT = "rbxassetid://566593606", -- Heavy Punch/Whack (More physical)
    CRITICAL = "rbxassetid://12222005", -- Classic Heavy Hit
    SWING = "rbxassetid://12222216" -- Classic Sword Slash
}

-- Helper to play local sound
local function playLocalSound(soundId, pitch)
    local s = Instance.new("Sound")
    s.SoundId = soundId
    s.Volume = 0.8
    s.PlaybackSpeed = pitch or 1
    s.Parent = workspace
    s.PlayOnRemove = true
    s:Destroy()
end

-- Create the screen GUI
local function createScreenGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CombatFeedbackUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    return screenGui
end

-- Create hit marker element
local function createHitMarkerTemplate()
    local frame = Instance.new("Frame")
    frame.Name = "HitMarker"
    frame.Size = UDim2.new(0, CONFIG.HIT_MARKER_SIZE, 0, CONFIG.HIT_MARKER_SIZE)
    frame.Position = UDim2.new(0.5, -CONFIG.HIT_MARKER_SIZE/2, 0.5, -CONFIG.HIT_MARKER_SIZE/2)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = CombatFeedback.screenGui
    
    -- Create X shape for hit marker using 4 lines
    local lineWidth = 4
    local lineLength = CONFIG.HIT_MARKER_SIZE * 0.4
    local gap = CONFIG.HIT_MARKER_SIZE * 0.15
    
    -- Top-left to center-left
    local line1 = Instance.new("Frame")
    line1.Name = "Line1"
    line1.Size = UDim2.new(0, lineLength, 0, lineWidth)
    line1.Position = UDim2.new(0, gap, 0.5, -lineWidth/2)
    line1.Rotation = -45
    line1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line1.BorderSizePixel = 0
    line1.Parent = frame
    
    -- Top-right to center-right
    local line2 = Instance.new("Frame")
    line2.Name = "Line2"
    line2.Size = UDim2.new(0, lineLength, 0, lineWidth)
    line2.Position = UDim2.new(1, -gap - lineLength, 0.5, -lineWidth/2)
    line2.Rotation = 45
    line2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line2.BorderSizePixel = 0
    line2.Parent = frame
    
    -- Bottom-left to center-left
    local line3 = Instance.new("Frame")
    line3.Name = "Line3"
    line3.Size = UDim2.new(0, lineLength, 0, lineWidth)
    line3.Position = UDim2.new(0, gap, 0.5, -lineWidth/2)
    line3.Rotation = 45
    line3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line3.BorderSizePixel = 0
    line3.Parent = frame
    
    -- Bottom-right to center-right
    local line4 = Instance.new("Frame")
    line4.Name = "Line4"
    line4.Size = UDim2.new(0, lineLength, 0, lineWidth)
    line4.Position = UDim2.new(1, -gap - lineLength, 0.5, -lineWidth/2)
    line4.Rotation = -45
    line4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line4.BorderSizePixel = 0
    line4.Parent = frame
    
    return frame
end

-- Create damage vignette (red screen edges when taking damage)
local function createDamageVignette()
    local frame = Instance.new("Frame")
    frame.Name = "DamageVignette"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.ZIndex = 10
    frame.Parent = CombatFeedback.screenGui
    
    -- Create gradient edges
    local topEdge = Instance.new("Frame")
    topEdge.Name = "TopEdge"
    topEdge.Size = UDim2.new(1, 0, 0.15, 0)
    topEdge.Position = UDim2.new(0, 0, 0, 0)
    topEdge.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    topEdge.BackgroundTransparency = 0.5
    topEdge.BorderSizePixel = 0
    topEdge.Parent = frame
    
    local topGradient = Instance.new("UIGradient")
    topGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    topGradient.Rotation = 90
    topGradient.Parent = topEdge
    
    local bottomEdge = topEdge:Clone()
    bottomEdge.Name = "BottomEdge"
    bottomEdge.Position = UDim2.new(0, 0, 0.85, 0)
    local bottomGradient = bottomEdge:FindFirstChild("UIGradient")
    if bottomGradient then
        bottomGradient.Rotation = -90
    end
    bottomEdge.Parent = frame
    
    local leftEdge = Instance.new("Frame")
    leftEdge.Name = "LeftEdge"
    leftEdge.Size = UDim2.new(0.1, 0, 1, 0)
    leftEdge.Position = UDim2.new(0, 0, 0, 0)
    leftEdge.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    leftEdge.BackgroundTransparency = 0.5
    leftEdge.BorderSizePixel = 0
    leftEdge.Parent = frame
    
    local leftGradient = Instance.new("UIGradient")
    leftGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    leftGradient.Rotation = 0
    leftGradient.Parent = leftEdge
    
    local rightEdge = leftEdge:Clone()
    rightEdge.Name = "RightEdge"
    rightEdge.Position = UDim2.new(0.9, 0, 0, 0)
    local rightGradient = rightEdge:FindFirstChild("UIGradient")
    if rightGradient then
        rightGradient.Rotation = 180
    end
    rightEdge.Parent = frame
    
    return frame
end

-- Show hit marker (when player hits someone)
function CombatFeedback:showHitMarker(isCritical)
    if not CombatFeedback.hitMarkerFrame then return end
    
    local hitMarker = CombatFeedback.hitMarkerFrame
    
    -- Set color based on critical hit
    local color = isCritical and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 255, 255)
    for _, child in pairs(hitMarker:GetChildren()) do
        if child:IsA("Frame") then
            child.BackgroundColor3 = color
        end
    end
    
    -- Animate in
    hitMarker.Visible = true
    local startSize = isCritical and 1.3 or 1
    hitMarker.Size = UDim2.new(0, CONFIG.HIT_MARKER_SIZE * startSize, 0, CONFIG.HIT_MARKER_SIZE * startSize)
    hitMarker.Position = UDim2.new(0.5, -CONFIG.HIT_MARKER_SIZE * startSize/2, 0.5, -CONFIG.HIT_MARKER_SIZE * startSize/2)
    hitMarker.Rotation = math.random(-20, 20)
    
    -- Play Sound
    if isCritical then
        playLocalSound(SOUNDS.CRITICAL, 1.1)
    else
        playLocalSound(SOUNDS.HIT, math.random(95, 115)/100)
    end
    
    -- Shrink and fade out
    local tweenInfo = TweenInfo.new(CONFIG.HIT_MARKER_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hitMarker, tweenInfo, {
        Size = UDim2.new(0, CONFIG.HIT_MARKER_SIZE * 0.5, 0, CONFIG.HIT_MARKER_SIZE * 0.5),
        Position = UDim2.new(0.5, -CONFIG.HIT_MARKER_SIZE * 0.25, 0.5, -CONFIG.HIT_MARKER_SIZE * 0.25),
        Rotation = 0
    })
    tween:Play()
    
    -- Hide after duration
    task.delay(CONFIG.HIT_MARKER_DURATION, function()
        hitMarker.Visible = false
    end)
end

-- Create floating damage number in world space
function CombatFeedback:showDamageNumber(targetPosition, damage, isCritical)
    -- Create billboard GUI at target position
    local billboardPart = Instance.new("Part")
    billboardPart.Name = "DamageNumberAnchor"
    billboardPart.Size = Vector3.new(0.1, 0.1, 0.1)
    billboardPart.Position = targetPosition + Vector3.new(math.random(-2, 2)/2, 3, math.random(-2, 2)/2)
    billboardPart.Anchored = true
    billboardPart.CanCollide = false
    billboardPart.Transparency = 1
    billboardPart.Parent = workspace
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 0, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Adornee = billboardPart
    billboardGui.Parent = billboardPart
    
    local damageLabel = Instance.new("TextLabel")
    damageLabel.Size = UDim2.new(1, 0, 1, 0)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = tostring(math.floor(damage))
    damageLabel.TextScaled = true
    damageLabel.Font = Enum.Font.GothamBold
    
    if isCritical then
        damageLabel.TextColor3 = Color3.fromRGB(255, 200, 0) -- Gold for critical
        damageLabel.Text = "💥 " .. tostring(math.floor(damage)) .. "!"
        damageLabel.Rotation = math.random(-15, 15)
    else
        damageLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- Red for normal
    end
    
    damageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    damageLabel.TextStrokeTransparency = 0
    damageLabel.Parent = billboardGui
    
    -- Animate floating up and fading
    local startY = billboardPart.Position.Y
    local endY = startY + 5
    local startTime = tick()
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / CONFIG.DAMAGE_NUMBER_DURATION, 1)
        
        -- Move up with ease-out
        local easedProgress = 1 - math.pow(1 - progress, 2)
        billboardPart.Position = Vector3.new(
            billboardPart.Position.X,
            startY + (endY - startY) * easedProgress,
            billboardPart.Position.Z
        )
        
        -- Fade out in second half
        if progress > 0.5 then
            local fadeProgress = (progress - 0.5) * 2
            damageLabel.TextTransparency = fadeProgress
            damageLabel.TextStrokeTransparency = fadeProgress
        end
        
        if progress >= 1 then
            connection:Disconnect()
            billboardPart:Destroy()
        end
    end)
end

-- Show screen damage effect (vignette)
function CombatFeedback:showDamageVignette(intensity)
    if not CombatFeedback.damageVignetteFrame then return end
    
    local vignette = CombatFeedback.damageVignetteFrame
    
    -- Set intensity
    local transparency = 0.3 + (1 - intensity) * 0.5
    for _, child in pairs(vignette:GetChildren()) do
        if child:IsA("Frame") then
            child.BackgroundTransparency = transparency
        end
    end
    
    vignette.Visible = true
    
    -- Fade out
    task.delay(0.1, function()
        for i = 1, 10 do
            task.wait(CONFIG.VIGNETTE_DURATION / 10)
            for _, child in pairs(vignette:GetChildren()) do
                if child:IsA("Frame") then
                    child.BackgroundTransparency = child.BackgroundTransparency + (1 - transparency) / 10
                end
            end
        end
        vignette.Visible = false
    end)
end

-- Screen shake effect
function CombatFeedback:shakeScreen(intensity, duration)
    if CombatFeedback.shakingCamera then return end
    
    CombatFeedback.shakingCamera = true
    local startTime = tick()
    local actualDuration = duration or CONFIG.SCREEN_SHAKE_DURATION
    local actualIntensity = intensity or CONFIG.SCREEN_SHAKE_INTENSITY
    
    local humanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
    if not humanoid then 
        CombatFeedback.shakingCamera = false
        return 
    end
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local progress = elapsed / actualDuration
        
        if progress >= 1 then
            connection:Disconnect()
            humanoid.CameraOffset = Vector3.new(0, 0, 0)
            CombatFeedback.shakingCamera = false
            return
        end
        
        -- Decrease intensity over time
        local currentIntensity = actualIntensity * (1 - progress)
        
        -- Random shake offset
        local offsetX = (math.random() - 0.5) * 2 * currentIntensity
        local offsetY = (math.random() - 0.5) * 2 * currentIntensity
        local offsetZ = (math.random() - 0.5) * currentIntensity * 0.5
        
        humanoid.CameraOffset = Vector3.new(offsetX, offsetY, offsetZ)
    end)
end

-- Handle taking damage (called when this player is hit)
function CombatFeedback:onTakeDamage(damage, isCritical)
    -- Show damage vignette
    local intensity = math.clamp(damage / 50, 0.3, 1)
    CombatFeedback:showDamageVignette(intensity)
    
    -- Screen shake
    local shakeIntensity = isCritical and CONFIG.SCREEN_SHAKE_INTENSITY * CONFIG.CRITICAL_SHAKE_MULTIPLIER or CONFIG.SCREEN_SHAKE_INTENSITY
    local shakeDuration = isCritical and CONFIG.SCREEN_SHAKE_DURATION * 1.5 or CONFIG.SCREEN_SHAKE_DURATION
    CombatFeedback:shakeScreen(shakeIntensity * (damage / 30), shakeDuration)
end

-- Handle dealing damage (called when this player hits someone)
function CombatFeedback:onDealDamage(targetPosition, damage, isCritical)
    -- Show hit marker
    CombatFeedback:showHitMarker(isCritical)
    
    -- Show floating damage number
    CombatFeedback:showDamageNumber(targetPosition, damage, isCritical)
    
    -- Critical Hit Juice
    if isCritical then
        CombatFeedback:flashScreen(Color3.new(1, 1, 1), 0.1) -- White flash
        CombatFeedback:hitStop(0.05) -- Brief pause/freeze
        CombatFeedback:shakeScreen(0.5, 0.2) -- Extra shake
    end
end

-- Create a flash effect overlay
function CombatFeedback:flashScreen(color, duration)
    local flash = Instance.new("Frame")
    flash.Name = "FlashOverlay"
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = color
    flash.BackgroundTransparency = 0.6
    flash.BorderSizePixel = 0
    flash.Parent = CombatFeedback.screenGui
    
    game:GetService("Debris"):AddItem(flash, duration)
    
    TweenService:Create(flash, TweenInfo.new(duration), {BackgroundTransparency = 1}):Play()
end

-- Simulate hit stop (brief freeze)
function CombatFeedback:hitStop(duration)
    -- We can't easily pause the engine, but we can pause character animations
    -- for a split second to simulate impact weight
    task.spawn(function()
        local char = Player.Character
        local animator = char and char:FindFirstChild("Humanoid") and char.Humanoid:FindFirstChild("Animator")
        
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:AdjustSpeed(0)
            end
            
            task.wait(duration)
            
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:AdjustSpeed(1)
            end
        end
    end)
end

-- Initialize combat feedback system
function CombatFeedback.init()
    print("[CombatFeedback] Initializing...")
    
    -- Create UI elements
    CombatFeedback.screenGui = createScreenGui()
    CombatFeedback.hitMarkerFrame = createHitMarkerTemplate()
    CombatFeedback.damageVignetteFrame = createDamageVignette()
    
    -- Connect to damage events
    if DamageRemoteEvent then
        DamageRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "PLAYER_DAMAGE" then
                local targetUserId = args[1]
                local damage = args[2]
                local isCritical = args[3]
                
                -- Check if this player took damage
                if targetUserId == Player.UserId then
                    CombatFeedback:onTakeDamage(damage, isCritical)
                else
                    -- This player dealt damage to someone else
                    -- Get target position for damage number
                    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
                    if targetPlayer and targetPlayer.Character then
                        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP then
                            CombatFeedback:onDealDamage(targetHRP.Position, damage, isCritical)
                        end
                    end
                end
                
            elseif eventType == "HIT_CONFIRM" then
                -- Explicit hit confirmation from server
                local targetPosition = args[1]
                local damage = args[2]
                local isCritical = args[3]
                CombatFeedback:onDealDamage(targetPosition, damage, isCritical)
            end
        end)
    else
        warn("[CombatFeedback] DamageRemoteEvent not found")
    end
    
    -- Connect to weapon events
    if WeaponRemoteEvent then
        WeaponRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "WEAPON_SWING" then
                -- Could add weapon swing visual effect here
            elseif eventType == "WEAPON_BROKEN" then
                local weaponType = args[1]
                -- Show weapon broken notification
                print("[CombatFeedback] Weapon broken: " .. tostring(weaponType))
            end
        end)
    end
    
    print("[CombatFeedback] Initialized successfully")
end

-- Initialize when module loads
CombatFeedback.init()

return CombatFeedback
