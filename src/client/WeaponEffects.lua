-- LocalScript: WeaponEffects.lua
-- Handles weapon swing animations and hit visual effects
-- Creates blood/spark particles on weapon impacts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for remote events
local WeaponRemoteEvent = ReplicatedStorage:WaitForChild("WeaponRemoteEvent", 10)
local DamageRemoteEvent = ReplicatedStorage:WaitForChild("DamageRemoteEvent", 10)

local WeaponEffects = {}
WeaponEffects.activeEffects = {}

-- Configuration
local CONFIG = {
    -- Swing animation
    SWING_DURATION = 0.3,
    SWING_ARC = 120, -- degrees
    
    -- Hit effects
    HIT_PARTICLE_COUNT = 15,
    SPARK_LIFETIME = 0.3,
    BLOOD_LIFETIME = 0.5,
    
    -- Weapon trails
    TRAIL_ENABLED = true,
    TRAIL_LIFETIME = 0.2,
}

-- Particle colors
local PARTICLE_COLORS = {
    SPARK = {
        Color3.fromRGB(255, 200, 100), -- Yellow-orange
        Color3.fromRGB(255, 150, 50),  -- Orange
        Color3.fromRGB(255, 255, 200), -- Bright yellow
    },
    BLOOD = {
        Color3.fromRGB(150, 20, 20),   -- Dark red
        Color3.fromRGB(200, 30, 30),   -- Medium red
        Color3.fromRGB(100, 10, 10),   -- Very dark red
    },
    IMPACT = {
        Color3.fromRGB(200, 200, 200), -- Gray
        Color3.fromRGB(150, 150, 150), -- Dark gray
        Color3.fromRGB(255, 255, 255), -- White
    }
}

-- Create a simple particle burst at position
local function createParticleBurst(position, colors, count, lifetime, speed, size)
    local particleHolder = Instance.new("Part")
    particleHolder.Name = "ParticleEffect"
    particleHolder.Size = Vector3.new(0.1, 0.1, 0.1)
    particleHolder.Position = position
    particleHolder.Anchored = true
    particleHolder.CanCollide = false
    particleHolder.Transparency = 1
    particleHolder.Parent = workspace
    
    -- Create particle emitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(colors)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, size or 0.5),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    emitter.Lifetime = NumberRange.new(lifetime * 0.5, lifetime)
    emitter.Speed = NumberRange.new(speed * 0.5, speed)
    emitter.SpreadAngle = Vector2.new(180, 180) -- Burst in all directions
    emitter.Rate = 0 -- We'll use Emit instead
    emitter.RotSpeed = NumberRange.new(-200, 200)
    emitter.Drag = 3
    emitter.Parent = particleHolder
    
    -- Emit particles
    emitter:Emit(count)
    
    -- Cleanup
    Debris:AddItem(particleHolder, lifetime + 0.5)
    
    return particleHolder
end

-- Create spark effect (metal on metal or weapon hit)
function WeaponEffects:createSparkEffect(position)
    local colors = {
        Color3.fromRGB(255, 255, 150), -- White-Yellow
        Color3.fromRGB(255, 180, 50),  -- Orange
        Color3.fromRGB(255, 220, 100), -- Bright Yellow
    }
    
    -- Colorsequence 
    local colorSeq = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colors[1]),
        ColorSequenceKeypoint.new(0.5, colors[2]),
        ColorSequenceKeypoint.new(1, colors[3])
    })
    
    -- High speed sparks
    createParticleBurst(position, colorSeq, 20, 0.4, 35, 0.2)
    
    -- Add a flash of light
    local flash = Instance.new("Part")
    flash.Name = "SparkFlash"
    flash.Size = Vector3.new(0.8, 0.8, 0.8)
    flash.Position = position
    flash.Anchored = true
    flash.CanCollide = false
    flash.Material = Enum.Material.Neon
    flash.Color = Color3.fromRGB(255, 220, 150)
    flash.Transparency = 0.2
    flash.Parent = workspace
    
    -- Add point light
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 200, 100)
    light.Brightness = 5
    light.Range = 12
    light.Shadows = true
    light.Parent = flash
    
    -- Fade out quickly
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeTween = TweenService:Create(flash, tweenInfo, {
        Transparency = 1,
        Size = Vector3.new(0.1, 0.1, 0.1)
    })
    local lightTween = TweenService:Create(light, tweenInfo, {
        Brightness = 0,
        Range = 0
    })
    
    fadeTween:Play()
    lightTween:Play()
    
    Debris:AddItem(flash, 0.2)
end

-- Create blood/impact effect
function WeaponEffects:createBloodEffect(position)
    local colors = PARTICLE_COLORS.BLOOD
    
    -- Create blood splatter particles
    local particleHolder = Instance.new("Part")
    particleHolder.Name = "BloodEffect"
    particleHolder.Size = Vector3.new(0.1, 0.1, 0.1)
    particleHolder.Position = position
    particleHolder.Anchored = true
    particleHolder.CanCollide = false
    particleHolder.Transparency = 1
    particleHolder.Parent = workspace
    
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Bright red start
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(180, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0)) -- Dark red end
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.6),
        NumberSequenceKeypoint.new(0.2, 0.5),
        NumberSequenceKeypoint.new(1, 0.2)
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.8, 0.4),
        NumberSequenceKeypoint.new(1, 1)
    })
    emitter.Lifetime = NumberRange.new(0.5, 0.8)
    emitter.Speed = NumberRange.new(15, 30) -- Fast splatter
    emitter.SpreadAngle = Vector2.new(360, 360) -- Omnidirectional
    emitter.Rate = 0
    emitter.RotSpeed = NumberRange.new(-300, 300)
    emitter.Acceleration = Vector3.new(0, -60, 0) -- Heavy gravity
    emitter.Drag = 3
    emitter.Parent = particleHolder
    
    -- Main Burst
    emitter:Emit(30)
    
    -- Secondary mist (fine spray)
    local mist = emitter:Clone()
    mist.Speed = NumberRange.new(5, 12)
    mist.Size = NumberSequence.new(0.3, 0.1)
    mist.Acceleration = Vector3.new(0, -20, 0)
    mist.Lifetime = NumberRange.new(0.8, 1.2)
    mist.Parent = particleHolder
    mist:Emit(20)
    
    Debris:AddItem(particleHolder, 2)
end

-- Create combined hit effect (sparks + impact)
function WeaponEffects:createHitEffect(position, hitType)
    if hitType == "metal" or hitType == "weapon" then
        WeaponEffects:createSparkEffect(position)
    elseif hitType == "flesh" or hitType == "player" then
        WeaponEffects:createBloodEffect(position)
        -- Also small sparks for visual interest
        WeaponEffects:createSparkEffect(position + Vector3.new(0, 0.5, 0))
    else
        -- Default: mixed effect
        WeaponEffects:createSparkEffect(position)
    end
end

-- Create weapon swing trail
function WeaponEffects:createSwingTrail(startPosition, endPosition, color)
    if not CONFIG.TRAIL_ENABLED then return end
    
    local distance = (endPosition - startPosition).Magnitude
    local midPoint = (startPosition + endPosition) / 2
    
    -- Create trail part
    local trail = Instance.new("Part")
    trail.Name = "WeaponTrail"
    trail.Size = Vector3.new(0.2, 0.2, distance)
    trail.CFrame = CFrame.new(midPoint, endPosition)
    trail.Anchored = true
    trail.CanCollide = false
    trail.Material = Enum.Material.Neon
    trail.Color = color or Color3.fromRGB(200, 200, 200)
    trail.Transparency = 0.3
    trail.Parent = workspace
    
    -- Fade and shrink
    local tweenInfo = TweenInfo.new(CONFIG.TRAIL_LIFETIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(trail, tweenInfo, {
        Transparency = 1,
        Size = Vector3.new(0.05, 0.05, distance * 0.8)
    })
    tween:Play()
    
    Debris:AddItem(trail, CONFIG.TRAIL_LIFETIME + 0.1)
end

-- Animate weapon swing (visual only - applied to character's arm)
function WeaponEffects:animateWeaponSwing(character, weaponType)
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Create a simple animation using motor adjustments
    -- In a real implementation, you'd use proper AnimationTracks
    
    local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightUpperArm")
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    
    if not rightArm or not torso then return end
    
    -- Get humanoid root part for swing effect position
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Create visual swing arc
    local swingStart = hrp.Position + hrp.CFrame.RightVector * 2 + Vector3.new(0, 1, 0)
    local swingEnd = hrp.Position + hrp.CFrame.LookVector * 3 + Vector3.new(0, 0.5, 0)
    
    -- Weapon-specific colors
    local trailColor = Color3.fromRGB(200, 200, 200)
    if weaponType == "Sword" or weaponType == "Machete" then
        trailColor = Color3.fromRGB(180, 200, 220) -- Steel blue
    elseif weaponType == "Axe" then
        trailColor = Color3.fromRGB(150, 150, 150) -- Dark gray
    elseif weaponType == "Spear" then
        trailColor = Color3.fromRGB(200, 180, 140) -- Wood/bronze
    elseif weaponType == "Knife" then
        trailColor = Color3.fromRGB(220, 220, 230) -- Shiny
    end
    
    WeaponEffects:createSwingTrail(swingStart, swingEnd, trailColor)
end

-- Flash screen for critical hits (attacker sees this)
function WeaponEffects:flashCriticalHit()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CritFlash"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    flash.BackgroundTransparency = 0.7
    flash.BorderSizePixel = 0
    flash.Parent = screenGui
    
    -- Quick fade out
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(flash, tweenInfo, {
        BackgroundTransparency = 1
    })
    tween:Play()
    
    Debris:AddItem(screenGui, 0.2)
end

-- Initialize WeaponEffects
function WeaponEffects.init()
    print("[WeaponEffects] Initializing...")
    
    -- Connect to weapon events
    if WeaponRemoteEvent then
        WeaponRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "WEAPON_SWING" then
                local weaponType = args[1]
                local character = Player.Character
                WeaponEffects:animateWeaponSwing(character, weaponType)
                
            elseif eventType == "WEAPON_HIT" then
                local position = args[1]
                local hitType = args[2]
                WeaponEffects:createHitEffect(position, hitType)
            end
        end)
    end
    
    -- Connect to damage events for hit effects
    if DamageRemoteEvent then
        DamageRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "PLAYER_DAMAGE" then
                local targetUserId = args[1]
                local damage = args[2]
                local isCritical = args[3]
                
                -- Find target player for effect position
                local targetPlayer = Players:GetPlayerByUserId(targetUserId)
                if targetPlayer and targetPlayer.Character then
                    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        -- Create hit effect at target
                        WeaponEffects:createHitEffect(hrp.Position, "player")
                        
                        -- Flash for critical if this player dealt the damage
                        if isCritical and targetUserId ~= Player.UserId then
                            WeaponEffects:flashCriticalHit()
                        end
                    end
                end
            end
        end)
    end
    
    print("[WeaponEffects] Initialized successfully")
end

-- Initialize when module loads
WeaponEffects.init()

return WeaponEffects
