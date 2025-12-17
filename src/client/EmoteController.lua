-- LocalScript: EmoteController.lua
-- Handles custom emotes (Rue's whistle, Katniss salute)
-- Manages unique character emotes and animations

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local EventsRemoteEvent = ReplicatedStorage:WaitForChild("EventsRemoteEvent")

local EmoteController = {}
EmoteController.activeEmotes = {}
EmoteController.emoteWheelVisible = false
EmoteController.emoteWheelFrame = nil
EmoteController.currentAnimation = nil

-- Define available emotes with VERIFIED Roblox animation IDs
-- These are official Roblox animations that work with R15/R6 characters
-- Animation sources: Roblox default emotes + verified catalog animations
EmoteController.emotes = {
    ["ThreeFingerSalute"] = {
        name = "Three Finger Salute",
        key = "F1",
        animationId = "rbxassetid://3360689775", -- Official Roblox Salute emote
        soundId = nil,
        specialEffect = "ShowRespect",
        duration = 2.5
    },
    ["RuesWhistle"] = {
        name = "Rue's Whistle",
        key = "F2", 
        animationId = "rbxassetid://128853357", -- Official Roblox Point emote
        soundId = "rbxassetid://9044353224", -- Bird whistle/tweet sound (verified)
        specialEffect = "MockingjayEcho",
        duration = 3.0
    },
    ["MockingjayCall"] = {
        name = "Mockingjay Call",
        key = "F3",
        animationId = "rbxassetid://128853357", -- Official Roblox Point emote
        soundId = "rbxassetid://9044353224", -- Bird whistle sound (verified)
        specialEffect = "MockingjayResponse",
        duration = 2.5
    },
    ["CornucopiaClaim"] = {
        name = "Claim Cornucopia",
        key = "F4",
        animationId = "rbxassetid://129423030", -- Official Roblox Cheer emote
        soundId = nil,
        specialEffect = nil,
        duration = 3.0
    },
    ["SurvivorsRest"] = {
        name = "Survivor's Rest",
        key = "F5",
        animationId = "rbxassetid://507768375", -- Roblox Sit/Crouch animation
        soundId = nil,
        specialEffect = "CampfireAmbience",
        duration = 5.0
    },
    ["VictorsPose"] = {
        name = "Victor's Pose",
        key = "F6",
        animationId = "rbxassetid://129423030", -- Official Roblox Cheer emote
        soundId = nil,
        specialEffect = nil,
        duration = 3.5
    },
    ["DefianceGesture"] = {
        name = "Defiance Gesture",
        key = "F7",
        animationId = "rbxassetid://128777973", -- Official Roblox Wave emote (fist raised)
        soundId = "rbxassetid://5034047634", -- Cannon/thunder sound (verified)
        specialEffect = "ThunderResponse",
        duration = 2.0
    },
    ["DistrictSalute"] = {
        name = "District Salute",
        key = "F8",
        animationId = "rbxassetid://3360689775", -- Official Roblox Salute emote
        soundId = nil,
        specialEffect = nil,
        duration = 2.5
    }
}

-- Play a sound locally
local function playSound(soundId, volume)
    if not soundId then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.7
    sound.Parent = PlayerGui
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    return sound
end

-- Stop current animation if playing
local function stopCurrentAnimation()
    if EmoteController.currentAnimation then
        EmoteController.currentAnimation:Stop()
        EmoteController.currentAnimation = nil
    end
end

-- Play animation on player character
local function playAnimation(animationId, duration)
    local character = Player.Character
    if not character then return nil end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    
    -- Stop any current emote animation
    stopCurrentAnimation()
    
    -- Create animation instance
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    
    -- Load and play the animation
    local success, animTrack = pcall(function()
        return humanoid:LoadAnimation(animation)
    end)
    
    if not success or not animTrack then
        warn("[EmoteController] Failed to load animation: " .. animationId)
        animation:Destroy()
        return nil
    end
    
    -- Configure animation
    animTrack.Priority = Enum.AnimationPriority.Action
    animTrack.Looped = false
    
    -- Play animation
    animTrack:Play()
    EmoteController.currentAnimation = animTrack
    
    -- Clean up when done
    animTrack.Stopped:Connect(function()
        if EmoteController.currentAnimation == animTrack then
            EmoteController.currentAnimation = nil
        end
    end)
    
    -- Auto-stop after duration
    if duration then
        task.delay(duration, function()
            if animTrack.IsPlaying then
                animTrack:Stop()
            end
        end)
    end
    
    animation:Destroy()
    return animTrack
end

-- Create emote wheel UI
local function createEmoteWheel()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EmoteWheel"
    screenGui.Parent = PlayerGui
    
    local emoteWheelFrame = Instance.new("Frame")
    emoteWheelFrame.Name = "EmoteWheelFrame"
    emoteWheelFrame.Size = UDim2.new(0, 400, 0, 400)
    emoteWheelFrame.Position = UDim2.new(0.5, -200, 0.5, -200)
    emoteWheelFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    emoteWheelFrame.BackgroundTransparency = 0.3
    emoteWheelFrame.BorderSizePixel = 0
    emoteWheelFrame.Visible = false
    emoteWheelFrame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 200)
    corner.Parent = emoteWheelFrame
    
    -- Add golden border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(212, 175, 55)
    stroke.Thickness = 3
    stroke.Parent = emoteWheelFrame
    
    -- Create emote buttons in a circular pattern
    local emoteKeys = {}
    for key in pairs(EmoteController.emotes) do
        table.insert(emoteKeys, key)
    end
    table.sort(emoteKeys) -- Sort for consistent order
    
    local centerX, centerY = 200, 200
    local radius = 130
    local count = #emoteKeys
    
    for i, emoteKey in ipairs(emoteKeys) do
        local angle = (i - 1) * (2 * math.pi / count) - math.pi/2 -- Start from top
        local x = centerX + radius * math.cos(angle)
        local y = centerY + radius * math.sin(angle)
        
        local button = Instance.new("TextButton")
        button.Name = emoteKey
        button.Size = UDim2.new(0, 70, 0, 70)
        button.Position = UDim2.new(0, x - 35, 0, y - 35)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        button.BorderSizePixel = 0
        button.Text = ""
        button.Parent = emoteWheelFrame
        
        -- Round button
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 35)
        btnCorner.Parent = button
        
        -- Button stroke
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(150, 150, 150)
        btnStroke.Thickness = 2
        btnStroke.Parent = button
        
        -- Emote icon/initial
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 0.6, 0)
        iconLabel.Position = UDim2.new(0, 0, 0.1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = string.sub(EmoteController.emotes[emoteKey].name, 1, 2):upper()
        iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextScaled = true
        iconLabel.Parent = button
        
        -- Key hint
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Size = UDim2.new(1, 0, 0.3, 0)
        keyLabel.Position = UDim2.new(0, 0, 0.65, 0)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = EmoteController.emotes[emoteKey].key
        keyLabel.TextColor3 = Color3.fromRGB(212, 175, 55)
        keyLabel.Font = Enum.Font.Gotham
        keyLabel.TextScaled = true
        keyLabel.Parent = button
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(212, 175, 55),
                Size = UDim2.new(0, 80, 0, 80),
                Position = UDim2.new(0, x - 40, 0, y - 40)
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(255, 255, 255)
            }):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                Size = UDim2.new(0, 70, 0, 70),
                Position = UDim2.new(0, x - 35, 0, y - 35)
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(150, 150, 150)
            }):Play()
        end)
        
        -- Connect button to emote
        button.MouseButton1Click:Connect(function()
            EmoteController:executeEmote(emoteKey)
            EmoteController:hideEmoteWheel()
        end)
    end
    
    -- Add center title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.5, 0, 0.15, 0)
    titleLabel.Position = UDim2.new(0.25, 0, 0.42, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "EMOTES"
    titleLabel.TextColor3 = Color3.fromRGB(212, 175, 55)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    titleLabel.Parent = emoteWheelFrame
    
    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(0.6, 0, 0.08, 0)
    subtitleLabel.Position = UDim2.new(0.2, 0, 0.55, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Press G to close"
    subtitleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextScaled = true
    subtitleLabel.Parent = emoteWheelFrame
    
    -- Store reference
    EmoteController.emoteWheelFrame = emoteWheelFrame
    
    return screenGui
end

-- Show emote wheel with animation
function EmoteController:showEmoteWheel()
    if EmoteController.emoteWheelFrame then
        EmoteController.emoteWheelFrame.Visible = true
        EmoteController.emoteWheelFrame.Size = UDim2.new(0, 10, 0, 10)
        EmoteController.emoteWheelFrame.Position = UDim2.new(0.5, -5, 0.5, -5)
        
        TweenService:Create(EmoteController.emoteWheelFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 400, 0, 400),
            Position = UDim2.new(0.5, -200, 0.5, -200)
        }):Play()
        
        EmoteController.emoteWheelVisible = true
    end
end

-- Hide emote wheel with animation
function EmoteController:hideEmoteWheel()
    if EmoteController.emoteWheelFrame then
        TweenService:Create(EmoteController.emoteWheelFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0.5, -5, 0.5, -5)
        }):Play()
        
        task.delay(0.2, function()
            if EmoteController.emoteWheelFrame then
                EmoteController.emoteWheelFrame.Visible = false
            end
        end)
        
        EmoteController.emoteWheelVisible = false
    end
end

-- Execute an emote
function EmoteController:executeEmote(emoteKey)
    local emoteData = EmoteController.emotes[emoteKey]
    if not emoteData then
        warn("[EmoteController] Invalid emote: " .. tostring(emoteKey))
        return
    end
    
    print("[EmoteController] Executing emote: " .. emoteData.name)
    
    -- Play the animation
    local animTrack = playAnimation(emoteData.animationId, emoteData.duration)
    
    -- Play the sound if available
    if emoteData.soundId then
        playSound(emoteData.soundId, 0.7)
    end
    
    -- Handle special effects
    if emoteData.specialEffect then
        if emoteData.specialEffect == "MockingjayEcho" or emoteData.specialEffect == "MockingjayResponse" then
            -- Trigger mockingjays to respond after a delay
            task.delay(1.5, function()
                -- Echo whistle back (verified bird whistle)
                playSound("rbxassetid://9044353224", 0.4)
                task.delay(0.8, function()
                    playSound("rbxassetid://9044353224", 0.3)
                end)
            end)
            EventsRemoteEvent:FireServer("TRIGGER_SPECIAL_EFFECT", "MockingjayResponse")
            
        elseif emoteData.specialEffect == "ThunderResponse" then
            -- Distant thunder after defiance gesture (verified cannon sound)
            task.delay(2, function()
                playSound("rbxassetid://5034047634", 0.5)
            end)
            EventsRemoteEvent:FireServer("TRIGGER_SPECIAL_EFFECT", "ThunderResponse")
            
        elseif emoteData.specialEffect == "CampfireAmbience" then
            EventsRemoteEvent:FireServer("TRIGGER_SPECIAL_EFFECT", "CampfireAmbience")
            
        elseif emoteData.specialEffect == "ShowRespect" then
            -- Other players might receive notification of the salute
            EventsRemoteEvent:FireServer("TRIGGER_SPECIAL_EFFECT", "RespectShown")
        end
    end
end

-- Handle keyboard input for emotes
local function setupKeyboardInput()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Toggle emote wheel with 'G' key
        if input.KeyCode == Enum.KeyCode.G then
            if EmoteController.emoteWheelVisible then
                EmoteController:hideEmoteWheel()
            else
                EmoteController:showEmoteWheel()
            end
        end
        
        -- Quick emote keys (F1-F8)
        if input.KeyCode == Enum.KeyCode.F1 then
            EmoteController:executeEmote("ThreeFingerSalute")
        elseif input.KeyCode == Enum.KeyCode.F2 then
            EmoteController:executeEmote("RuesWhistle")
        elseif input.KeyCode == Enum.KeyCode.F3 then
            EmoteController:executeEmote("MockingjayCall")
        elseif input.KeyCode == Enum.KeyCode.F4 then
            EmoteController:executeEmote("CornucopiaClaim")
        elseif input.KeyCode == Enum.KeyCode.F5 then
            EmoteController:executeEmote("SurvivorsRest")
        elseif input.KeyCode == Enum.KeyCode.F6 then
            EmoteController:executeEmote("VictorsPose")
        elseif input.KeyCode == Enum.KeyCode.F7 then
            EmoteController:executeEmote("DefianceGesture")
        elseif input.KeyCode == Enum.KeyCode.F8 then
            EmoteController:executeEmote("DistrictSalute")
        end
    end)
end

-- Initialize emote controller
function EmoteController.init()
    print("EmoteController initialized")
    
    -- Create emote wheel UI
    createEmoteWheel()
    
    -- Setup keyboard input
    setupKeyboardInput()
    
    -- Connect to server events for special emote effects
    EventsRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
        local args = {...}
        
        if eventType == "MOCKINGJAY_RESPONSE" then
            -- Visual/audio feedback for mockingjay response
            print("Mockingjays are responding to your whistle!")
        elseif eventType == "THUNDER_RESPONSE" then
            -- Audio feedback for defiance gesture
            print("The sky rumbles in response to your defiance!")
        elseif eventType == "CAMPFIRE_AMBIENCE" then
            -- Ambient sound when resting by campfire
            print("The fire crackles warmly as you rest...")
        end
    end)
    
    print("EmoteController initialized with " .. tostring(#EmoteController.emotes) .. " emotes")
end

-- Initialize the emote controller when the module is loaded
EmoteController.init()

return EmoteController