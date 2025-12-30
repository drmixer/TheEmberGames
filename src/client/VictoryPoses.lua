-- LocalScript: VictoryPoses.lua
-- Handles victory pose animations and effects when a player wins
-- Provides multiple pose options that can be unlocked and selected

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local VictoryPoses = {}
VictoryPoses.currentPose = nil
VictoryPoses.poseConnection = nil
VictoryPoses.selectedPose = "triumphant" -- Default

-- Victory pose configurations
local VICTORY_POSES = {
    ["triumphant"] = {
        name = "Triumphant Victor",
        description = "Raise your arms in glorious victory",
        animationId = "rbxassetid://129423030", -- Cheer animation
        duration = 5,
        cameraAngle = "front",
        effects = {"confetti", "spotlight"},
        rarity = "Common"
    },
    
    ["salute"] = {
        name = "Tribute's Salute",
        description = "Honor the fallen with the three-finger salute",
        animationId = "rbxassetid://3360689775", -- Salute animation
        duration = 5,
        cameraAngle = "dramatic",
        effects = {"mockingjay", "spotlight"},
        rarity = "Rare"
    },
    
    ["defiant"] = {
        name = "Defiant Champion",
        description = "Show the Capitol your defiance",
        animationId = "rbxassetid://128777973", -- Wave/fist animation
        duration = 5,
        cameraAngle = "low",
        effects = {"thunder", "flames"},
        rarity = "Epic"
    },
    
    ["humble"] = {
        name = "Humble Survivor",
        description = "A quiet moment of reflection",
        animationId = "rbxassetid://507768375", -- Sit/rest animation
        duration = 5,
        cameraAngle = "side",
        effects = {"embers", "spotlight"},
        rarity = "Common"
    },
    
    ["mockingjay"] = {
        name = "Mockingjay's Call",
        description = "Whistle the four-note tune of rebellion",
        animationId = "rbxassetid://128853357", -- Point animation
        duration = 6,
        cameraAngle = "front",
        effects = {"mockingjay", "birds"},
        rarity = "Legendary"
    },
    
    ["flames"] = {
        name = "Girl on Fire",
        description = "Engulfed in the flames of victory",
        animationId = "rbxassetid://129423030", -- Cheer with flames
        duration = 5,
        cameraAngle = "orbit",
        effects = {"flames", "embers", "spotlight"},
        rarity = "Legendary"
    },
    
    ["district"] = {
        name = "District Pride",
        description = "Represent your district with honor",
        animationId = "rbxassetid://128853357", -- Point animation
        duration = 5,
        cameraAngle = "front",
        effects = {"district_banner", "confetti"},
        rarity = "Rare"
    }
}

-- Effect creators
local function createConfettiEffect(position)
    local colors = {
        Color3.fromRGB(255, 215, 0),
        Color3.fromRGB(255, 100, 100),
        Color3.fromRGB(100, 255, 100),
        Color3.fromRGB(100, 100, 255),
        Color3.fromRGB(255, 200, 100)
    }
    
    for i = 1, 50 do
        local confetti = Instance.new("Part")
        confetti.Size = Vector3.new(0.2, 0.2, 0.05)
        confetti.Position = position + Vector3.new(
            (math.random() - 0.5) * 10,
            math.random() * 5 + 10,
            (math.random() - 0.5) * 10
        )
        confetti.Anchored = false
        confetti.CanCollide = false
        confetti.Material = Enum.Material.Neon
        confetti.Color = colors[math.random(1, #colors)]
        confetti.Parent = workspace
        
        -- Add slight rotation
        confetti.CFrame = confetti.CFrame * CFrame.Angles(
            math.random() * math.pi * 2,
            math.random() * math.pi * 2,
            math.random() * math.pi * 2
        )
        
        Debris:AddItem(confetti, 5)
    end
end

local function createSpotlightEffect(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local spotlight = Instance.new("SpotLight")
    spotlight.Brightness = 5
    spotlight.Range = 30
    spotlight.Angle = 45
    spotlight.Color = Color3.fromRGB(255, 255, 220)
    spotlight.Face = Enum.NormalId.Bottom
    spotlight.Parent = hrp
    
    -- Create spotlight beam from above
    local beamPart = Instance.new("Part")
    beamPart.Size = Vector3.new(8, 0.2, 8)
    beamPart.Position = hrp.Position + Vector3.new(0, 20, 0)
    beamPart.Anchored = true
    beamPart.CanCollide = false
    beamPart.Material = Enum.Material.Neon
    beamPart.Color = Color3.fromRGB(255, 255, 200)
    beamPart.Transparency = 0.7
    beamPart.Shape = Enum.PartType.Cylinder
    beamPart.Orientation = Vector3.new(0, 0, 90)
    beamPart.Parent = workspace
    
    Debris:AddItem(spotlight, 6)
    Debris:AddItem(beamPart, 6)
    
    return spotlight
end

local function createFlamesEffect(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local fire = Instance.new("Fire")
    fire.Size = 10
    fire.Heat = 10
    fire.Color = Color3.fromRGB(255, 150, 50)
    fire.SecondaryColor = Color3.fromRGB(255, 50, 0)
    fire.Parent = hrp
    
    Debris:AddItem(fire, 6)
    
    return fire
end

local function createEmbersEffect(position)
    local emitter = Instance.new("Part")
    emitter.Size = Vector3.new(10, 0.1, 10)
    emitter.Position = position
    emitter.Anchored = true
    emitter.CanCollide = false
    emitter.Transparency = 1
    emitter.Parent = workspace
    
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
    })
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0)
    })
    particles.Lifetime = NumberRange.new(2, 4)
    particles.Speed = NumberRange.new(5, 10)
    particles.SpreadAngle = Vector2.new(30, 30)
    particles.Rate = 20
    particles.LightEmission = 1
    particles.Parent = emitter
    
    Debris:AddItem(emitter, 7)
    
    return emitter
end

local function createThunderEffect()
    -- Screen flash
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ThunderFlash"
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui
    
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flash.BackgroundTransparency = 0.3
    flash.Parent = screenGui
    
    TweenService:Create(flash, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    }):Play()
    
    Debris:AddItem(screenGui, 1)
    
    -- Play thunder sound
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://5034047634"
    sound.Volume = 0.8
    sound.Parent = PlayerGui
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

local function createMockingjayEffect(position)
    -- Bird particle effect
    for i = 1, 5 do
        local bird = Instance.new("Part")
        bird.Size = Vector3.new(0.5, 0.3, 0.5)
        bird.Position = position + Vector3.new(
            (math.random() - 0.5) * 5,
            math.random() * 3 + 5,
            (math.random() - 0.5) * 5
        )
        bird.Anchored = true
        bird.CanCollide = false
        bird.Material = Enum.Material.SmoothPlastic
        bird.Color = Color3.fromRGB(30, 30, 40)
        bird.Parent = workspace
        
        -- Fly away animation
        local endPos = bird.Position + Vector3.new(
            (math.random() - 0.5) * 50,
            math.random() * 20 + 10,
            (math.random() - 0.5) * 50
        )
        
        TweenService:Create(bird, TweenInfo.new(3, Enum.EasingStyle.Quad), {
            Position = endPos,
            Transparency = 1
        }):Play()
        
        Debris:AddItem(bird, 3.5)
    end
    
    -- Play whistle sound
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9044353224"
    sound.Volume = 0.7
    sound.Parent = PlayerGui
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Play effects for a pose
local function playEffects(effectList, character, position)
    for _, effect in ipairs(effectList) do
        if effect == "confetti" then
            createConfettiEffect(position)
        elseif effect == "spotlight" then
            createSpotlightEffect(character)
        elseif effect == "flames" then
            createFlamesEffect(character)
        elseif effect == "embers" then
            createEmbersEffect(position)
        elseif effect == "thunder" then
            createThunderEffect()
        elseif effect == "mockingjay" then
            createMockingjayEffect(position)
        elseif effect == "birds" then
            createMockingjayEffect(position)
        end
    end
end

-- Camera angle setups
local function setupCamera(character, angleType, duration)
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local originalCameraType = camera.CameraType
    camera.CameraType = Enum.CameraType.Scriptable
    
    local position = hrp.Position
    local startTime = tick()
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        
        if elapsed >= duration then
            camera.CameraType = originalCameraType
            connection:Disconnect()
            return
        end
        
        local progress = elapsed / duration
        
        if angleType == "front" then
            local offset = Vector3.new(0, 3, 10)
            camera.CFrame = CFrame.new(hrp.Position + offset, hrp.Position + Vector3.new(0, 1, 0))
            
        elseif angleType == "dramatic" then
            local angle = progress * math.pi * 0.3 - math.pi * 0.15
            local offset = Vector3.new(math.sin(angle) * 8, 4, math.cos(angle) * 8)
            camera.CFrame = CFrame.new(hrp.Position + offset, hrp.Position + Vector3.new(0, 2, 0))
            
        elseif angleType == "low" then
            local offset = Vector3.new(0, -1, 8)
            camera.CFrame = CFrame.new(hrp.Position + offset, hrp.Position + Vector3.new(0, 2, 0))
            
        elseif angleType == "side" then
            local offset = Vector3.new(8, 2, 0)
            camera.CFrame = CFrame.new(hrp.Position + offset, hrp.Position + Vector3.new(0, 1, 0))
            
        elseif angleType == "orbit" then
            local angle = progress * math.pi * 2
            local radius = 10
            local height = 3 + math.sin(progress * math.pi * 4) * 2
            local offset = Vector3.new(math.sin(angle) * radius, height, math.cos(angle) * radius)
            camera.CFrame = CFrame.new(hrp.Position + offset, hrp.Position + Vector3.new(0, 1, 0))
        end
    end)
    
    return connection
end

-- Play victory pose
function VictoryPoses:playPose(poseId, targetCharacter)
    local character = targetCharacter or Player.Character
    if not character then return false end
    
    local poseConfig = VICTORY_POSES[poseId]
    if not poseConfig then
        warn("[VictoryPoses] Unknown pose: " .. tostring(poseId))
        return false
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    print("[VictoryPoses] Playing pose: " .. poseConfig.name .. " on " .. character.Name)
    
    -- Stop any current pose
    VictoryPoses:stopPose()
    
    -- Play animation (Client-side play on another character works and is visible locally)
    local animation = Instance.new("Animation")
    animation.AnimationId = poseConfig.animationId
    
    local animator = humanoid:FindFirstChild("Animator") or humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    
    local animTrack = animator:LoadAnimation(animation)
    animTrack.Priority = Enum.AnimationPriority.Action4
    animTrack.Looped = true
    animTrack:Play()
    
    VictoryPoses.currentPose = {
        track = animTrack,
        animation = animation
    }
    
    -- Setup camera (Orbit the WINNER)
    VictoryPoses.poseConnection = setupCamera(character, poseConfig.cameraAngle, poseConfig.duration)
    
    -- Play effects
    playEffects(poseConfig.effects, character, hrp.Position)
    
    -- Auto-stop after duration
    task.delay(poseConfig.duration, function()
        VictoryPoses:stopPose()
    end)
    
    return true
end

-- Stop current pose
function VictoryPoses:stopPose()
    if VictoryPoses.currentPose then
        if VictoryPoses.currentPose.track then
            VictoryPoses.currentPose.track:Stop()
        end
        if VictoryPoses.currentPose.animation then
            VictoryPoses.currentPose.animation:Destroy()
        end
        VictoryPoses.currentPose = nil
    end
    
    if VictoryPoses.poseConnection then
        VictoryPoses.poseConnection:Disconnect()
        VictoryPoses.poseConnection = nil
    end
end

-- Set selected pose
function VictoryPoses:setSelectedPose(poseId)
    if VICTORY_POSES[poseId] then
        VictoryPoses.selectedPose = poseId
        Player:SetAttribute("SelectedVictoryPose", poseId)
        print("[VictoryPoses] Selected pose: " .. VICTORY_POSES[poseId].name)
        return true
    end
    return false
end

-- Get available poses
function VictoryPoses:getAvailablePoses()
    local poses = {}
    for id, config in pairs(VICTORY_POSES) do
        table.insert(poses, {
            id = id,
            name = config.name,
            description = config.description,
            rarity = config.rarity
        })
    end
    return poses
end

-- Initialize
function VictoryPoses.init()
    print("[VictoryPoses] Initializing...")
    
    -- Connect to match events
    local matchRemote = ReplicatedStorage:WaitForChild("MatchRemoteEvent", 10)
    if matchRemote then
        matchRemote.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "VICTORY_SEQUENCE" then
                local data = args[1]
                local winnerId = data.winnerId
                
                if winnerId then
                    local winnerPlayer = Players:GetPlayerByUserId(winnerId)
                    if winnerPlayer and winnerPlayer.Character then
                         -- Everyone watches the winner
                         -- Try to get their preferred pose (if replicated attribute exists), else default
                         local poseId = winnerPlayer:GetAttribute("SelectedVictoryPose") or "triumphant"
                         
                         -- Delay slightly to allow UI to fade in
                         task.wait(0.5)
                         VictoryPoses:playPose(poseId, winnerPlayer.Character)
                    end
                end
            end
        end)
    end
    
    print("[VictoryPoses] Initialized with " .. tostring(#VictoryPoses:getAvailablePoses()) .. " poses")
end

-- Initialize when module loads
VictoryPoses.init()

return VictoryPoses
