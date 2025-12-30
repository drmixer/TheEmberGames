-- LocalScript: HazardVisuals.lua
-- Handles visual effects for Gamemaker hazard events
-- Creates acid rain, wildfire, and poison fog visual effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Wait for remote events
local EventsRemoteEvent = ReplicatedStorage:WaitForChild("EventsRemoteEvent", 10)

local HazardVisuals = {}
HazardVisuals.activeHazards = {}
HazardVisuals.screenGui = nil
HazardVisuals.warningFrame = nil

-- Configuration
local CONFIG = {
    -- Acid Rain settings
    ACID_RAIN_COLOR = Color3.fromRGB(180, 255, 100),
    ACID_RAIN_DENSITY = 50,
    
    -- Wildfire settings
    FIRE_COLOR_PRIMARY = Color3.fromRGB(255, 100, 20),
    FIRE_COLOR_SECONDARY = Color3.fromRGB(255, 200, 50),
    FIRE_SPREAD_SPEED = 5, -- Studs per second
    
    -- Poison fog settings
    FOG_COLOR = Color3.fromRGB(80, 200, 80),
    FOG_DENSITY = 0.8,
    FOG_DAMAGE_INTERVAL = 1,
    
    -- Warning display
    WARNING_DURATION = 5,
}

-- Sound IDs
local SOUND_IDS = {
    ACID_RAIN = "rbxassetid://9114249095", -- Reusing poison hiss for acid burn/hiss
    FIRE_CRACKLING = "rbxassetid://9114243671",
    POISON_HISS = "rbxassetid://9114249095",
    HAZARD_WARNING = "rbxassetid://6895079853",
}

-- Create screen GUI
local function createScreenGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HazardVisualsUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    return screenGui
end

-- Play local sound
local function playSound(soundId, volume, looped, parent)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.8
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

-- Create hazard warning UI
local function createWarningUI()
    local warningFrame = Instance.new("Frame")
    warningFrame.Name = "HazardWarning"
    warningFrame.Size = UDim2.new(0.5, 0, 0.15, 0)
    warningFrame.Position = UDim2.new(0.25, 0, 0.1, 0)
    warningFrame.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    warningFrame.BackgroundTransparency = 0.3
    warningFrame.BorderSizePixel = 0
    warningFrame.Visible = false
    warningFrame.Parent = HazardVisuals.screenGui
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = warningFrame
    
    -- Red border
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 50, 50)
    stroke.Thickness = 3
    stroke.Parent = warningFrame
    
    -- Warning icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0.15, 0, 0.8, 0)
    iconLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "⚠️"
    iconLabel.TextScaled = true
    iconLabel.Parent = warningFrame
    
    -- Warning title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0.8, 0, 0.5, 0)
    titleLabel.Position = UDim2.new(0.18, 0, 0.05, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "GAMEMAKER EVENT"
    titleLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextStrokeTransparency = 0
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = warningFrame
    
    -- Warning description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "DescLabel"
    descLabel.Size = UDim2.new(0.8, 0, 0.4, 0)
    descLabel.Position = UDim2.new(0.18, 0, 0.52, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = "Danger incoming!"
    descLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextScaled = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = warningFrame
    
    HazardVisuals.warningFrame = warningFrame
    return warningFrame
end

-- Show hazard warning
function HazardVisuals:showWarning(title, description, duration)
    if not HazardVisuals.warningFrame then return end
    
    local titleLabel = HazardVisuals.warningFrame:FindFirstChild("TitleLabel")
    local descLabel = HazardVisuals.warningFrame:FindFirstChild("DescLabel")
    
    if titleLabel then titleLabel.Text = title end
    if descLabel then descLabel.Text = description end
    
    -- Play warning sound
    playSound(SOUND_IDS.HAZARD_WARNING, 0.8)
    
    -- Show with animation
    HazardVisuals.warningFrame.Position = UDim2.new(0.25, 0, -0.2, 0)
    HazardVisuals.warningFrame.Visible = true
    
    TweenService:Create(HazardVisuals.warningFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.25, 0, 0.05, 0)
    }):Play()
    
    -- Pulse animation
    local stroke = HazardVisuals.warningFrame:FindFirstChildOfClass("UIStroke")
    if stroke then
        task.spawn(function()
            local pulseTime = 0
            while HazardVisuals.warningFrame.Visible do
                pulseTime = pulseTime + 0.05
                stroke.Transparency = 0.3 + math.sin(pulseTime * 8) * 0.3
                task.wait(0.05)
            end
        end)
    end
    
    -- Hide after duration
    task.delay(duration or CONFIG.WARNING_DURATION, function()
        TweenService:Create(HazardVisuals.warningFrame, TweenInfo.new(0.3), {
            Position = UDim2.new(0.25, 0, -0.2, 0)
        }):Play()
        
        task.delay(0.3, function()
            HazardVisuals.warningFrame.Visible = false
        end)
    end)
end

-- ==================== ACID RAIN EFFECT ====================

function HazardVisuals:createAcidRainEffect(position, radius, duration)
    print("[HazardVisuals] Creating ACID RAIN effect")
    
    local hazardId = "acid_rain_" .. tostring(tick())
    
    -- Show warning
    HazardVisuals:showWarning("⚠️ ACID RAIN", "Seek shelter! The rain is acidic!", 5)
    
    -- Create atmosphere effect
    local colorCorr = Instance.new("ColorCorrectionEffect")
    colorCorr.Name = "AcidRainTint"
    colorCorr.TintColor = Color3.fromRGB(200, 255, 180) -- Sickly green
    colorCorr.Saturation = -0.2
    colorCorr.Contrast = 0.1
    colorCorr.Parent = Lighting
    
    -- Create rain particle part attached to camera
    local rainPart = Instance.new("Part")
    rainPart.Name = "rainPart"
    rainPart.Size = Vector3.new(100, 1, 100)
    rainPart.Transparency = 1
    rainPart.CanCollide = false
    rainPart.Anchored = true
    rainPart.Parent = workspace
    
    local rainEmitter = Instance.new("ParticleEmitter")
    rainEmitter.Texture = "rbxassetid://241595494" -- Generic drop/streak
    rainEmitter.Color = ColorSequence.new(CONFIG.ACID_RAIN_COLOR)
    rainEmitter.Size = NumberSequence.new(0.5, 0.2)
    rainEmitter.Transparency = NumberSequence.new(0.2, 0.8)
    rainEmitter.Lifetime = NumberRange.new(1, 1.5)
    rainEmitter.Speed = NumberRange.new(50, 70) -- Fast falling
    rainEmitter.SpreadAngle = Vector2.new(0, 0)
    rainEmitter.Acceleration = Vector3.new(0, -50, 0) -- Gravity
    rainEmitter.Rate = 500 -- Heavy rain
    rainEmitter.EmissionDirection = Enum.NormalId.Bottom
    rainEmitter.Parent = rainPart
    
    -- Sound
    local rainSound = playSound(SOUND_IDS.ACID_RAIN, 0.5, true, PlayerGui)

    -- Animate rain following camera
    local rainConnection
    local startTime = tick()
    
    rainConnection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        
        if elapsed >= duration then
            rainConnection:Disconnect()
            
            -- Fade out
            TweenService:Create(colorCorr, TweenInfo.new(2), {TintColor = Color3.fromRGB(255, 255, 255), Saturation = 0, Contrast = 0}):Play()
            rainEmitter.Enabled = false
            TweenService:Create(rainSound, TweenInfo.new(2), {Volume = 0}):Play()
            
            Debris:AddItem(colorCorr, 2)
            Debris:AddItem(rainPart, 3)
            Debris:AddItem(rainSound, 2)
            
            HazardVisuals.activeHazards[hazardId] = nil
            return
        end
        
        -- Update rain position above camera
        if Camera then
            rainPart.CFrame = CFrame.new(Camera.CFrame.Position + Vector3.new(0, 30, 0))
        end
    end)
    
    -- Store hazard reference
    HazardVisuals.activeHazards[hazardId] = {
        type = "ACID_RAIN",
        part = rainPart,
        effect = colorCorr,
        sound = rainSound,
        connection = rainConnection
    }
    
    return hazardId
end

-- ==================== WILDFIRE EFFECT ====================

function HazardVisuals:createWildfireEffect(position, radius, duration)
    print("[HazardVisuals] Creating wildfire effect at " .. tostring(position))
    
    local hazardId = "fire_" .. tostring(tick())
    
    -- Show warning
    HazardVisuals:showWarning("🔥 WILDFIRE ALERT", "Fire is spreading! Evacuate the area immediately!", 5)
    
    -- Create fire holder
    local fireHolder = Instance.new("Model")
    fireHolder.Name = "Wildfire"
    fireHolder.Parent = workspace
    
    -- Create fire base (heat distortion area)
    local fireBase = Instance.new("Part")
    fireBase.Name = "FireBase"
    fireBase.Size = Vector3.new(radius * 2, 2, radius * 2)
    fireBase.Position = position + Vector3.new(0, 1, 0)
    fireBase.Anchored = true
    fireBase.CanCollide = false
    fireBase.Material = Enum.Material.Neon
    fireBase.Color = Color3.fromRGB(255, 50, 0)
    fireBase.Transparency = 0.7
    fireBase.Parent = fireHolder
    
    -- Create multiple fire columns
    local fireColumns = {}
    local numColumns = math.floor(radius / 3)
    
    for i = 1, numColumns do
        local angle = (i / numColumns) * math.pi * 2
        local distance = math.random(radius * 0.3, radius * 0.9)
        local offsetX = math.cos(angle) * distance
        local offsetZ = math.sin(angle) * distance
        
        local column = Instance.new("Part")
        column.Name = "FireColumn" .. i
        column.Size = Vector3.new(3, math.random(5, 12), 3)
        column.Position = position + Vector3.new(offsetX, column.Size.Y / 2, offsetZ)
        column.Anchored = true
        column.CanCollide = false
        column.Material = Enum.Material.Neon
        column.Color = CONFIG.FIRE_COLOR_PRIMARY
        column.Transparency = 0.3
        column.Parent = fireHolder
        
        -- Add fire particle emitter
        local fireEmitter = Instance.new("ParticleEmitter")
        fireEmitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.FIRE_COLOR_SECONDARY),
            ColorSequenceKeypoint.new(0.5, CONFIG.FIRE_COLOR_PRIMARY),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 0))
        })
        fireEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 2),
            NumberSequenceKeypoint.new(0.5, 4),
            NumberSequenceKeypoint.new(1, 0)
        })
        fireEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        })
        fireEmitter.Lifetime = NumberRange.new(0.5, 1.5)
        fireEmitter.Speed = NumberRange.new(5, 15)
        fireEmitter.SpreadAngle = Vector2.new(15, 15)
        fireEmitter.Rate = 30
        fireEmitter.Acceleration = Vector3.new(0, 10, 0)
        fireEmitter.LightEmission = 1
        fireEmitter.Parent = column
        
        -- Add point light
        local fireLight = Instance.new("PointLight")
        fireLight.Color = CONFIG.FIRE_COLOR_PRIMARY
        fireLight.Brightness = 2
        fireLight.Range = 15
        fireLight.Parent = column
        
        table.insert(fireColumns, {column = column, emitter = fireEmitter, light = fireLight})
    end
    
    -- Add smoke
    local smokeEmitter = Instance.new("ParticleEmitter")
    smokeEmitter.Color = ColorSequence.new(Color3.fromRGB(60, 60, 60))
    smokeEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 5),
        NumberSequenceKeypoint.new(1, 15)
    })
    smokeEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    smokeEmitter.Lifetime = NumberRange.new(3, 6)
    smokeEmitter.Speed = NumberRange.new(10, 20)
    smokeEmitter.Rate = 20
    smokeEmitter.Acceleration = Vector3.new(0, 5, 0)
    smokeEmitter.Parent = fireBase
    
    -- Play fire sound
    local fireSound = playSound(SOUND_IDS.FIRE_CRACKLING, 0.7, true, fireBase)
    
    -- Animate fire
    local fireConnection
    local startTime = tick()
    
    fireConnection = RunService.Heartbeat:Connect(function(dt)
        local elapsed = tick() - startTime
        
        if elapsed >= duration then
            fireConnection:Disconnect()
            
            -- Stop emitters
            for _, col in ipairs(fireColumns) do
                col.emitter.Enabled = false
                TweenService:Create(col.column, TweenInfo.new(2), {Transparency = 1}):Play()
            end
            smokeEmitter.Enabled = false
            
            if fireSound then
                TweenService:Create(fireSound, TweenInfo.new(2), {Volume = 0}):Play()
            end
            
            Debris:AddItem(fireHolder, 5)
            HazardVisuals.activeHazards[hazardId] = nil
            return
        end
        
        -- Animate fire columns (flicker)
        for i, col in ipairs(fireColumns) do
            local flicker = 0.2 + math.sin(elapsed * 10 + i) * 0.1
            col.column.Transparency = 0.3 + flicker
            col.light.Brightness = 2 + math.sin(elapsed * 8 + i) * 0.5
        end
    end)
    
    -- Store hazard reference
    HazardVisuals.activeHazards[hazardId] = {
        type = "WILDFIRE",
        model = fireHolder,
        sound = fireSound,
        connection = fireConnection
    }
    
    return hazardId
end

-- ==================== POISON FOG EFFECT ====================

function HazardVisuals:createPoisonFogEffect(position, radius, duration)
    print("[HazardVisuals] Creating poison fog effect at " .. tostring(position))
    
    local hazardId = "fog_" .. tostring(tick())
    
    -- Show warning
    HazardVisuals:showWarning("☠️ POISON FOG", "Toxic gas detected! Hold your breath and run!", 5)
    
    -- Create fog holder
    local fogHolder = Instance.new("Model")
    fogHolder.Name = "PoisonFog"
    fogHolder.Parent = workspace
    
    -- Create fog base
    local fogBase = Instance.new("Part")
    fogBase.Name = "FogBase"
    fogBase.Size = Vector3.new(radius * 2, 10, radius * 2)
    fogBase.Position = position + Vector3.new(0, 5, 0)
    fogBase.Anchored = true
    fogBase.CanCollide = false
    fogBase.Material = Enum.Material.SmoothPlastic
    fogBase.Color = CONFIG.FOG_COLOR
    fogBase.Transparency = 0.8
    fogBase.Parent = fogHolder
    
    -- Create fog particles
    local fogEmitter = Instance.new("ParticleEmitter")
    fogEmitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.FOG_COLOR),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 255, 100))
    })
    fogEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 10),
        NumberSequenceKeypoint.new(0.5, 20),
        NumberSequenceKeypoint.new(1, 15)
    })
    fogEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.6),
        NumberSequenceKeypoint.new(0.5, 0.4),
        NumberSequenceKeypoint.new(1, 0.8)
    })
    fogEmitter.Lifetime = NumberRange.new(3, 6)
    fogEmitter.Speed = NumberRange.new(2, 5)
    fogEmitter.SpreadAngle = Vector2.new(180, 180)
    fogEmitter.Rate = 15
    fogEmitter.RotSpeed = NumberRange.new(-30, 30)
    fogEmitter.Parent = fogBase
    
    -- Create skull particles (toxic indicator)
    local skullEmitter = Instance.new("ParticleEmitter")
    skullEmitter.Texture = "rbxassetid://243660364" -- Skull texture
    skullEmitter.Color = ColorSequence.new(Color3.fromRGB(150, 255, 150))
    skullEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.2, 2),
        NumberSequenceKeypoint.new(1, 0)
    })
    skullEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    skullEmitter.Lifetime = NumberRange.new(2, 4)
    skullEmitter.Speed = NumberRange.new(3, 8)
    skullEmitter.SpreadAngle = Vector2.new(60, 60)
    skullEmitter.Rate = 3
    skullEmitter.Acceleration = Vector3.new(0, 2, 0)
    skullEmitter.Parent = fogBase
    
    -- Add eerie green light
    local fogLight = Instance.new("PointLight")
    fogLight.Color = CONFIG.FOG_COLOR
    fogLight.Brightness = 1
    fogLight.Range = radius
    fogLight.Parent = fogBase
    
    -- Play poison sound
    local fogSound = playSound(SOUND_IDS.POISON_HISS, 0.5, true, fogBase)
    
    -- Create screen effect when player is inside
    local poisonOverlay = Instance.new("Frame")
    poisonOverlay.Name = "PoisonOverlay"
    poisonOverlay.Size = UDim2.new(1, 0, 1, 0)
    poisonOverlay.BackgroundColor3 = CONFIG.FOG_COLOR
    poisonOverlay.BackgroundTransparency = 1
    poisonOverlay.BorderSizePixel = 0
    poisonOverlay.Parent = HazardVisuals.screenGui
    
    -- Animate fog
    local fogConnection
    local startTime = tick()
    
    fogConnection = RunService.Heartbeat:Connect(function(dt)
        local elapsed = tick() - startTime
        
        if elapsed >= duration then
            fogConnection:Disconnect()
            
            -- Fade out fog
            fogEmitter.Enabled = false
            skullEmitter.Enabled = false
            
            TweenService:Create(fogBase, TweenInfo.new(3), {Transparency = 1}):Play()
            TweenService:Create(poisonOverlay, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
            
            if fogSound then
                TweenService:Create(fogSound, TweenInfo.new(2), {Volume = 0}):Play()
            end
            
            Debris:AddItem(fogHolder, 5)
            Debris:AddItem(poisonOverlay, 2)
            HazardVisuals.activeHazards[hazardId] = nil
            return
        end
        
        -- Check if player is in fog
        local character = Player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local playerPos = character.HumanoidRootPart.Position
            local distance = (Vector3.new(playerPos.X, 0, playerPos.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude
            
            if distance < radius and playerPos.Y < position.Y + 10 then
                -- Player is in fog - show overlay
                local targetTrans = 0.7 + math.sin(elapsed * 3) * 0.1
                poisonOverlay.BackgroundTransparency = targetTrans
            else
                poisonOverlay.BackgroundTransparency = 1
            end
        end
        
        -- Animate fog swirl
        fogBase.CFrame = fogBase.CFrame * CFrame.Angles(0, dt * 0.1, 0)
        fogLight.Brightness = 1 + math.sin(elapsed * 2) * 0.3
    end)
    
    -- Store hazard reference
    HazardVisuals.activeHazards[hazardId] = {
        type = "POISON_FOG",
        model = fogHolder,
        overlay = poisonOverlay,
        sound = fogSound,
        connection = fogConnection
    }
    
    return hazardId
end

-- Cleanup a specific hazard
function HazardVisuals:cleanupHazard(hazardId)
    local hazard = HazardVisuals.activeHazards[hazardId]
    if not hazard then return end
    
    if hazard.connection then
        hazard.connection:Disconnect()
    end
    
    if hazard.sound then
        hazard.sound:Stop()
        hazard.sound:Destroy()
    end
    
    if hazard.part then
        hazard.part:Destroy()
    end
    
    if hazard.model then
        hazard.model:Destroy()
    end
    
    if hazard.overlay then
        hazard.overlay:Destroy()
    end
    
    if hazard.effect then
        hazard.effect:Destroy()
    end
    
    HazardVisuals.activeHazards[hazardId] = nil
end

-- Cleanup all hazards
function HazardVisuals:cleanupAllHazards()
    for hazardId, _ in pairs(HazardVisuals.activeHazards) do
        HazardVisuals:cleanupHazard(hazardId)
    end
end

-- Initialize
function HazardVisuals.init()
    print("[HazardVisuals] Initializing...")
    
    HazardVisuals.screenGui = createScreenGui()
    createWarningUI()
    
    -- Connect to events
    if EventsRemoteEvent then
        EventsRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "HAZARD_EVENT" then
                local eventData = args[1]
                if not eventData then return end
                
                if eventData.type == "ACID_RAIN" then
                    HazardVisuals:createAcidRainEffect(eventData.position, eventData.radius, eventData.duration)
                elseif eventData.type == "WILDFIRE" then
                    HazardVisuals:createWildfireEffect(eventData.position, eventData.radius, eventData.duration)
                elseif eventData.type == "POISON_FOG" then
                    HazardVisuals:createPoisonFogEffect(eventData.position, eventData.radius, eventData.duration)
                end
                
            elseif eventType == "HAZARD_EVENT_END" then
                local hazardType = args[1]
                -- Could clean up specific type if needed
                
            elseif eventType == "MATCH_ENDED" then
                -- Cleanup all hazards on match end
                HazardVisuals:cleanupAllHazards()
            end
        end)
    end
    
    print("[HazardVisuals] Initialized successfully")
end

-- Initialize when loaded
HazardVisuals.init()

return HazardVisuals
