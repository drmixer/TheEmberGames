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

-- Define available emotes
EmoteController.emotes = {
    ["ThreeFingerSalute"] = {
        name = "Three Finger Salute",
        key = "F1",
        animationId = "rbxassetid://0", -- Placeholder, would be actual animation
        soundId = nil,
        specialEffect = "ShowRespect"
    },
    ["RuesWhistle"] = {
        name = "Rue's Whistle",
        key = "F2", 
        animationId = "rbxassetid://0", -- Placeholder
        soundId = "rbxassetid://0", -- Placeholder
        specialEffect = "MockingjayEcho"
    },
    ["MockingjayCall"] = {
        name = "Mockingjay Call",
        key = "F3",
        animationId = "rbxassetid://0", -- Placeholder
        soundId = "rbxassetid://0", -- Placeholder
        specialEffect = "MockingjayResponse"
    },
    ["CornucopiaClaim"] = {
        name = "Claim Cornucopia",
        key = "F4",
        animationId = "rbxassetid://0", -- Placeholder
        soundId = nil,
        specialEffect = nil
    },
    ["SurvivorsRest"] = {
        name = "Survivor's Rest",
        key = "F5",
        animationId = "rbxassetid://0", -- Placeholder
        soundId = nil,
        specialEffect = "CampfireAmbience"
    },
    ["VictorsPose"] = {
        name = "Victor's Pose",
        key = "F6",
        animationId = "rbxassetid://0", -- Placeholder
        soundId = nil,
        specialEffect = nil
    },
    ["DefianceGesture"] = {
        name = "Defiance Gesture",
        key = "F7",
        animationId = "rbxassetid://0", -- Placeholder
        soundId = "rbxassetid://0", -- Placeholder
        specialEffect = "ThunderResponse"
    },
    ["DistrictSalute"] = {
        name = "District Salute",
        key = "F8",
        animationId = "rbxassetid://0", -- Placeholder
        soundId = nil,
        specialEffect = nil
    }
}

-- Create emote wheel UI
local function createEmoteWheel()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EmoteWheel"
    screenGui.Parent = PlayerGui
    
    local emoteWheelFrame = Instance.new("Frame")
    emoteWheelFrame.Name = "EmoteWheelFrame"
    emoteWheelFrame.Size = UDim2.new(0, 400, 0, 400)
    emoteWheelFrame.Position = UDim2.new(0.5, -200, 0.5, -200)
    emoteWheelFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    emoteWheelFrame.BackgroundTransparency = 0.7
    emoteWheelFrame.BorderSizePixel = 0
    emoteWheelFrame.Visible = false
    emoteWheelFrame.Parent = screenGui
    
    -- Create emote buttons in a circular pattern
    local emoteKeys = {}
    for key in pairs(EmoteController.emotes) do
        table.insert(emoteKeys, key)
    end
    
    local centerX, centerY = 200, 200
    local radius = 120
    local count = #emoteKeys
    
    for i, emoteKey in ipairs(emoteKeys) do
        local angle = (i - 1) * (2 * math.pi / count) - math.pi/2 -- Start from top
        local x = centerX + radius * math.cos(angle)
        local y = centerY + radius * math.sin(angle)
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 60, 0, 60)
        button.Position = UDim2.new(0, x - 30, 0, y - 30)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.BorderColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = string.sub(EmoteController.emotes[emoteKey].name, 1, 1) -- First letter
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamBold
        button.TextScaled = true
        button.Parent = emoteWheelFrame
        
        -- Add number indicator
        local numberLabel = Instance.new("TextLabel")
        numberLabel.Size = UDim2.new(0, 20, 0, 20)
        numberLabel.Position = UDim2.new(1, -20, 0, 0)
        numberLabel.BackgroundTransparency = 1
        numberLabel.Text = i
        numberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        numberLabel.Font = Enum.Font.GothamBold
        numberLabel.TextScaled = true
        numberLabel.Parent = button
        
        -- Connect button to emote
        button.MouseButton1Click:Connect(function()
            EmoteController:executeEmote(emoteKey)
            EmoteController:hideEmoteWheel()
        end)
    end
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "EMOTE WHEEL"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    titleLabel.Parent = emoteWheelFrame
    
    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 30)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    closeButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextScaled = true
    closeButton.Parent = emoteWheelFrame
    
    closeButton.MouseButton1Click:Connect(function()
        EmoteController:hideEmoteWheel()
    end)
    
    -- Store reference
    EmoteController.emoteWheelFrame = emoteWheelFrame
    
    return screenGui
end

-- Show emote wheel
function EmoteController:showEmoteWheel()
    if EmoteController.emoteWheelFrame then
        EmoteController.emoteWheelFrame.Visible = true
        EmoteController.emoteWheelVisible = true
    end
end

-- Hide emote wheel
function EmoteController:hideEmoteWheel()
    if EmoteController.emoteWheelFrame then
        EmoteController.emoteWheelFrame.Visible = false
        EmoteController.emoteWheelVisible = false
    end
end

-- Execute an emote
function EmoteController:executeEmote(emoteKey)
    local emoteData = EmoteController.emotes[emoteKey]
    if not emoteData then
        print("Invalid emote: " .. tostring(emoteKey))
        return
    end
    
    print("Executing emote: " .. emoteData.name)
    
    -- In a real implementation, we would:
    -- 1. Play the animation on the player character
    -- 2. Play any associated sounds
    -- 3. Trigger server events for special effects
    
    -- For now, we'll just log the action
    -- In a real game, we would send a remote event to the server
    -- EventsRemoteEvent:FireServer("EXECUTE_EMOTE", emoteKey)
    
    -- Handle special effects
    if emoteData.specialEffect == "MockingjayEcho" then
        -- This would trigger mockingjays in the environment
        EventsRemoteEvent:FireServer("TRIGGER_SPECIAL_EFFECT", "MockingjayResponse")
    elseif emoteData.specialEffect == "ThunderResponse" then
        -- This would create a subtle thunder effect in the distance
        EventsRemoteEvent:FireServer("TRIGGER_SPECIAL_EFFECT", "ThunderResponse")
    elseif emoteData.specialEffect == "CampfireAmbience" then
        -- This would play ambient fire sounds if near a campfire
        EventsRemoteEvent:FireServer("TRIGGER_SPECIAL_EFFECT", "CampfireAmbience")
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