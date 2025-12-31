-- LocalScript: TutorialUI.lua
-- Guides new players through game mechanics
-- Step-by-step tutorial with optional skip

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local TutorialUI = {}
TutorialUI.isActive = false
TutorialUI.currentStep = 0
TutorialUI.completed = false

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
}

-- Tutorial steps
local TUTORIAL_STEPS = {
    {
        title = "Welcome, Tribute! 🔥",
        message = "Welcome to The Phoenix Games. This quick tutorial will teach you the basics of survival. May the odds be ever in your favor!",
        icon = "🏟️",
        action = nil, -- Just read and continue
    },
    {
        title = "Movement",
        message = "Use WASD to move around the arena. Press SPACE to jump. Use SHIFT to sprint (consumes stamina).",
        icon = "🏃",
        action = "MOVE", -- Wait for player to move
    },
    {
        title = "Camera Control",
        message = "Move your mouse to look around. Use the scroll wheel to zoom in and out.",
        icon = "👁️",
        action = nil,
    },
    {
        title = "Picking Up Items",
        message = "Walk over items on the ground to pick them up. Press E to interact with objects and containers.",
        icon = "📦",
        action = nil,
    },
    {
        title = "Inventory",
        message = "Press TAB or I to open your inventory. Drag items to equip them. Click to use consumables.",
        icon = "🎒",
        action = nil,
    },
    {
        title = "Crafting",
        message = "Press F to open the crafting menu. Combine resources to create tools, weapons, and survival items.",
        icon = "🔨",
        action = nil,
    },
    {
        title = "Combat",
        message = "Click to attack with your equipped weapon. Hold to charge ranged weapons for more power. Right-click to block (if available).",
        icon = "⚔️",
        action = nil,
    },
    {
        title = "The Zone",
        message = "Stay inside the safe zone! The red zone deals damage over time. Watch the minimap (M) and compass for zone location.",
        icon = "🌀",
        action = nil,
    },
    {
        title = "Alliances",
        message = "Press P to open alliances. Team up with other tributes, but beware - betrayal is always possible...",
        icon = "🤝",
        action = nil,
    },
    {
        title = "Emotes",
        message = "Press G to open the emote wheel. Use emotes to communicate with other tributes.",
        icon = "👋",
        action = nil,
    },
    {
        title = "Battle Pass",
        message = "Press B to view your Battle Pass progress. Complete challenges to earn XP and unlock rewards!",
        icon = "🏆",
        action = nil,
    },
    {
        title = "Ready for the Arena!",
        message = "You're ready! Remember: survival is everything. Gather resources, form alliances wisely, and be the last tribute standing!",
        icon = "🔥",
        action = nil,
    },
}

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TutorialUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.Visible = false
    backdrop.Parent = screenGui
    
    -- Tutorial panel
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 450, 0, 280)
    panel.Position = UDim2.new(0.5, -225, 0.5, -140)
    panel.BackgroundColor3 = CONFIG.BG_COLOR
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.ACCENT_COLOR
    stroke.Thickness = 2
    stroke.Parent = panel
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0.5, -30, 0, 20)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "🔥"
    iconLabel.TextSize = 48
    iconLabel.Parent = panel
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 35)
    title.Position = UDim2.new(0, 20, 0, 85)
    title.BackgroundTransparency = 1
    title.Text = "Welcome!"
    title.TextColor3 = CONFIG.ACCENT_COLOR
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = panel
    
    -- Message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -40, 0, 70)
    message.Position = UDim2.new(0, 20, 0, 125)
    message.BackgroundTransparency = 1
    message.Text = "Welcome to the tutorial!"
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.TextSize = 16
    message.Font = Enum.Font.Gotham
    message.TextWrapped = true
    message.TextYAlignment = Enum.TextYAlignment.Top
    message.Parent = panel
    
    -- Progress indicator
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0.8, 0, 0, 6)
    progressBar.Position = UDim2.new(0.1, 0, 0, 205)
    progressBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = panel
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0.5, 0)
    progressCorner.Parent = progressBar
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = CONFIG.ACCENT_COLOR
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBar
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0.5, 0)
    fillCorner.Parent = progressFill
    
    local stepLabel = Instance.new("TextLabel")
    stepLabel.Name = "StepLabel"
    stepLabel.Size = UDim2.new(1, 0, 0, 20)
    stepLabel.Position = UDim2.new(0, 0, 0, 212)
    stepLabel.BackgroundTransparency = 1
    stepLabel.Text = "1 / 12"
    stepLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    stepLabel.TextSize = 12
    stepLabel.Font = Enum.Font.Gotham
    stepLabel.Parent = panel
    
    -- Buttons
    local nextBtn = Instance.new("TextButton")
    nextBtn.Name = "NextButton"
    nextBtn.Size = UDim2.new(0, 120, 0, 40)
    nextBtn.Position = UDim2.new(1, -140, 1, -55)
    nextBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
    nextBtn.BorderSizePixel = 0
    nextBtn.Text = "Next →"
    nextBtn.TextColor3 = Color3.new(0, 0, 0)
    nextBtn.TextSize = 16
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.Parent = panel
    
    local nextCorner = Instance.new("UICorner")
    nextCorner.CornerRadius = UDim.new(0, 8)
    nextCorner.Parent = nextBtn
    
    local skipBtn = Instance.new("TextButton")
    skipBtn.Name = "SkipButton"
    skipBtn.Size = UDim2.new(0, 100, 0, 40)
    skipBtn.Position = UDim2.new(0, 20, 1, -55)
    skipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    skipBtn.BorderSizePixel = 0
    skipBtn.Text = "Skip Tutorial"
    skipBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    skipBtn.TextSize = 12
    skipBtn.Font = Enum.Font.Gotham
    skipBtn.Parent = panel
    
    local skipCorner = Instance.new("UICorner")
    skipCorner.CornerRadius = UDim.new(0, 8)
    skipCorner.Parent = skipBtn
    
    -- Store references
    TutorialUI.screenGui = screenGui
    TutorialUI.backdrop = backdrop
    TutorialUI.panel = panel
    TutorialUI.iconLabel = iconLabel
    TutorialUI.title = title
    TutorialUI.message = message
    TutorialUI.progressFill = progressFill
    TutorialUI.stepLabel = stepLabel
    TutorialUI.nextBtn = nextBtn
    TutorialUI.skipBtn = skipBtn
    
    -- Button events
    nextBtn.MouseButton1Click:Connect(function()
        TutorialUI:nextStep()
    end)
    
    skipBtn.MouseButton1Click:Connect(function()
        TutorialUI:complete()
    end)
end

-- Show current step
function TutorialUI:showStep(stepNum)
    local step = TUTORIAL_STEPS[stepNum]
    if not step then
        TutorialUI:complete()
        return
    end
    
    TutorialUI.currentStep = stepNum
    
    -- Animate out old content
    TweenService:Create(TutorialUI.panel, TweenInfo.new(0.15), {
        Position = UDim2.new(0.5, -225, 0.5, -130)
    }):Play()
    
    task.delay(0.15, function()
        -- Update content
        TutorialUI.iconLabel.Text = step.icon
        TutorialUI.title.Text = step.title
        TutorialUI.message.Text = step.message
        TutorialUI.stepLabel.Text = stepNum .. " / " .. #TUTORIAL_STEPS
        
        -- Update progress
        local progress = (stepNum - 1) / (#TUTORIAL_STEPS - 1)
        TweenService:Create(TutorialUI.progressFill, TweenInfo.new(0.3), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
        
        -- Update button text
        if stepNum == #TUTORIAL_STEPS then
            TutorialUI.nextBtn.Text = "Complete! ✓"
        else
            TutorialUI.nextBtn.Text = "Next →"
        end
        
        -- Animate in
        TweenService:Create(TutorialUI.panel, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Position = UDim2.new(0.5, -225, 0.5, -140)
        }):Play()
    end)
end

-- Next step
function TutorialUI:nextStep()
    if TutorialUI.currentStep >= #TUTORIAL_STEPS then
        TutorialUI:complete()
    else
        TutorialUI:showStep(TutorialUI.currentStep + 1)
    end
end

-- Complete tutorial
function TutorialUI:complete()
    TutorialUI.completed = true
    TutorialUI.isActive = false
    
    -- Hide with animation
    TweenService:Create(TutorialUI.panel, TweenInfo.new(0.3), {
        Position = UDim2.new(0.5, -225, 0.6, -140),
        BackgroundTransparency = 1
    }):Play()
    
    TweenService:Create(TutorialUI.backdrop, TweenInfo.new(0.3), {
        BackgroundTransparency = 1
    }):Play()
    
    task.delay(0.3, function()
        TutorialUI.panel.Visible = false
        TutorialUI.backdrop.Visible = false
    end)
    
    -- Notify server
    local dataRemote = ReplicatedStorage:FindFirstChild("DataRemote")
    if dataRemote then
        dataRemote:FireServer("TUTORIAL_COMPLETE")
    end
    
    -- Show notification
    local notifManager = PlayerGui:FindFirstChild("NotificationManager")
    if notifManager then
        -- TODO: Use NotificationManager
    end
    
    print("[TutorialUI] Tutorial completed!")
end

-- Start tutorial
function TutorialUI:start()
    if TutorialUI.completed then return end
    
    TutorialUI.isActive = true
    TutorialUI.backdrop.Visible = true
    TutorialUI.panel.Visible = true
    
    -- Animate in
    TutorialUI.backdrop.BackgroundTransparency = 1
    TutorialUI.panel.BackgroundTransparency = 1
    TutorialUI.panel.Position = UDim2.new(0.5, -225, 0.4, -140)
    
    TweenService:Create(TutorialUI.backdrop, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.5
    }):Play()
    
    TweenService:Create(TutorialUI.panel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        BackgroundTransparency = 0,
        Position = UDim2.new(0.5, -225, 0.5, -140)
    }):Play()
    
    TutorialUI:showStep(1)
end

-- Check if should show tutorial
function TutorialUI:shouldShowTutorial()
    -- Will be updated from DataManager
    return not TutorialUI.completed
end

-- Initialize
function TutorialUI.init()
    print("[TutorialUI] Initializing...")
    
    createUI()
    
    -- Check player data for tutorial status
    local dataRemote = ReplicatedStorage:FindFirstChild("DataRemote")
    if dataRemote then
        dataRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "DATA_LOADED" then
                if data.tutorial and data.tutorial.completed then
                    TutorialUI.completed = true
                else
                    -- Auto-start tutorial for new players after delay
                    task.delay(3, function()
                        if not TutorialUI.completed then
                            TutorialUI:start()
                        end
                    end)
                end
            end
        end)
    else
        -- No data system, show tutorial after delay
        task.delay(5, function()
            if not TutorialUI.completed then
                TutorialUI:start()
            end
        end)
    end
    
    print("[TutorialUI] Initialized!")
end

TutorialUI.init()
return TutorialUI
