-- LocalScript: MainMenuUI.lua
-- Central hub for The Ember Games
-- Displays before matches with access to all features

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Import our new Design System
local UITheme = require(script.Parent:WaitForChild("UITheme"))

local MainMenuUI = {}
MainMenuUI.isVisible = false
MainMenuUI.isInMatch = false
MainMenuUI.connections = {}

-- Create realistic ember particle with rotation and fading
local function createEmberParticle(parent)
    local ember = Instance.new("Frame")
    local size = math.random(2, 5)
    ember.Size = UDim2.new(0, size, 0, size)
    
    -- Start from bottom, random X
    local startX = math.random()
    ember.Position = UDim2.new(startX, 0, 1.1, 0)
    
    -- Random ember color (Orange -> Gold -> Red)
    local colors = {
        Color3.fromRGB(255, 100, 0), -- Orange
        Color3.fromRGB(255, 180, 0), -- Gold
        Color3.fromRGB(255, 50, 0)   -- Red
    }
    ember.BackgroundColor3 = colors[math.random(1, #colors)]
    ember.BorderSizePixel = 0
    ember.Rotation = math.random(0, 360)
    ember.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ember
    
    -- Animation parameters
    local duration = math.random(4, 8)
    local xDrift = math.random(-100, 100) -- In pixels
    local endRotation = math.random(-180, 180)
    
    -- Float up and fade out
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local goal = {
        Position = UDim2.new(startX, xDrift, -0.1, 0),
        BackgroundTransparency = 1,
        Rotation = ember.Rotation + endRotation
    }
    
    local tween = TweenService:Create(ember, tweenInfo, goal)
    tween:Play()
    tween.Completed:Connect(function()
        ember:Destroy()
    end)
end

-- Create the modern left-side navigation
local function createSidebar(parent)
    local container = Instance.new("Frame")
    container.Name = "Sidebar"
    container.Size = UDim2.new(0, 280, 1, 0) -- Full height, fixed width
    container.Position = UDim2.new(0, 40, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Logo Area
    local logoArea = Instance.new("Frame")
    logoArea.Size = UDim2.new(1, 0, 0, 150)
    logoArea.BackgroundTransparency = 1
    logoArea.Parent = container
    
    local logoText = Instance.new("TextLabel")
    logoText.Text = "THE\nEMBER\nGAMES"
    logoText.Size = UDim2.new(1, 0, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Font = UITheme.Fonts.Title
    logoText.TextSize = 48
    logoText.TextColor3 = UITheme.Colors.Gold
    logoText.TextXAlignment = Enum.TextXAlignment.Left
    logoText.TextYAlignment = Enum.TextYAlignment.Bottom
    
    -- Add glowing stroke/shadow to text
    local textStroke = Instance.new("UIStroke")
    textStroke.Thickness = 2
    textStroke.Color = Color3.new(0,0,0)
    textStroke.Parent = logoText
    logoText.Parent = logoArea
    
    -- Navigation Buttons Container
    local navContainer = Instance.new("Frame")
    navContainer.Size = UDim2.new(1, 0, 0, 500)
    navContainer.Position = UDim2.new(0, 0, 0, 180)
    navContainer.BackgroundTransparency = 1
    navContainer.Parent = container
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 15)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = navContainer
    
    -- Function to add buttons
    local function addButton(text, icon, order, colorOverride, callback)
        local btn = UITheme.createButton({
            Text = "      " .. text, -- Space for icon
            Size = UDim2.new(1, 0, 0, 60),
            OnClick = callback
        })
        btn.LayoutOrder = order
        btn.Parent = navContainer
        
        -- Override color if special (like Play button)
        if colorOverride then
            -- We'd need to manually tween this in the Theme, but for now direct set
            local stroke = btn:FindFirstChild("UIStroke")
            if stroke then stroke.Color = colorOverride end
        end
        
        -- Icon
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Text = icon
        iconLabel.Size = UDim2.new(0, 40, 1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.TextSize = 24
        iconLabel.Position = UDim2.new(0, 15, 0, 0)
        iconLabel.Parent = btn
    end
    
    -- 1. PLAY (Primary)
    addButton("PLAY", "⚔️", 1, UITheme.Colors.Success, function()
        MainMenuUI:hide()
        local lobbyRemote = ReplicatedStorage:FindFirstChild("LobbyRemoteEvent")
        if lobbyRemote then lobbyRemote:FireServer("QUEUE_FOR_MATCH") end
    end)
    
    -- 2. BATTLE PASS
    addButton("BATTLE PASS", "🏆", 2, UITheme.Colors.Gold, function()
        local seasonUI = PlayerGui:FindFirstChild("SeasonalUI")
        if seasonUI and seasonUI:FindFirstChild("MainPanel") then
            seasonUI.MainPanel.Visible = true
        end
    end)
    
    -- 3. CUSTOMIZE
    addButton("LOCKER", "👕", 3, nil, function()
        -- Open CosmeticsUI
        print("Opening Locker")
    end)
    
    -- 4. ALLIANCES
    addButton("ALLIANCES", "🤝", 4, nil, function()
        local allianceUI = PlayerGui:FindFirstChild("AllianceUI")
        if allianceUI and allianceUI:FindFirstChild("MainPanel") then
            allianceUI.MainPanel.Visible = not allianceUI.MainPanel.Visible
        end
    end)
    
    -- 5. SETTINGS
    addButton("SETTINGS", "⚙️", 5, nil, function()
        -- Open Settings
        print("Opening Settings")
    end)
end

-- Create a "News/Events" card on the right
local function createNewsCard(parent)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 300, 0, 400)
    card.Position = UDim2.new(1, -340, 0.5, -200) -- Right aligned
    parent = parent
    
    UITheme.applyGlass(card, 0.4)
    card.Parent = parent
    
    local title = Instance.new("TextLabel")
    title.Text = "UPDATE 1.0"
    title.Font = UITheme.Fonts.Header
    title.TextSize = 24
    title.TextColor3 = UITheme.Colors.Gold
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card
    
    local body = Instance.new("TextLabel")
    body.Text = "Welcome to Season 1 of The Ember Games!\n\n• New Arena: The scorched forest\n• 3 New Weapons\n• Ranked Mode Live\n\nMay the odds be ever in your favor."
    body.Font = UITheme.Fonts.Body
    body.TextSize = 16
    body.TextColor3 = UITheme.Colors.Text
    body.Size = UDim2.new(1, -40, 1, -60)
    body.Position = UDim2.new(0, 20, 0, 60)
    body.BackgroundTransparency = 1
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
    body.Parent = card
end

-- Top Right Player Stats
local function createPlayerStats(parent)
    local stats = Instance.new("Frame")
    stats.Size = UDim2.new(0, 250, 0, 80)
    stats.Position = UDim2.new(1, -290, 0, 40)
    UITheme.applyGlass(stats, 0.5)
    stats.Parent = parent
    
    local name = Instance.new("TextLabel")
    name.Text = Player.DisplayName
    name.Font = UITheme.Fonts.Header
    name.TextSize = 18
    name.TextColor3 = UITheme.Colors.Gold
    name.Size = UDim2.new(1, -20, 0, 30)
    name.Position = UDim2.new(0, 20, 0, 10)
    name.BackgroundTransparency = 1
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = stats
    
    local level = Instance.new("TextLabel")
    level.Text = "Level 1 • 0 XP" -- Placeholder
    level.Font = UITheme.Fonts.Label
    level.TextSize = 14
    level.TextColor3 = UITheme.Colors.TextDim
    level.Size = UDim2.new(1, -20, 0, 20)
    level.Position = UDim2.new(0, 20, 0, 40)
    level.BackgroundTransparency = 1
    level.TextXAlignment = Enum.TextXAlignment.Left
    level.Parent = stats
end

local function createUI()
    if MainMenuUI.screenGui then MainMenuUI.screenGui:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainMenuUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true -- Fullscreen including topbar
    screenGui.Parent = PlayerGui
    
    -- Background Frame
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = UITheme.Colors.Background
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    -- Deep Vignette
    local vignette = Instance.new("ImageLabel")
    vignette.Size = UDim2.new(1, 0, 1, 0)
    vignette.BackgroundTransparency = 1
    vignette.Image = "rbxassetid://10842050222" -- Generic gradient/vignette texture if available, otherwise transparency handles it
    vignette.ImageColor3 = Color3.new(0,0,0)
    vignette.ImageTransparency = 0.3
    vignette.Parent = background
    
    -- Ember Container (Behind UI)
    local emberContainer = Instance.new("Frame")
    emberContainer.Size = UDim2.new(1, 0, 1, 0)
    emberContainer.BackgroundTransparency = 1
    emberContainer.Parent = background
    
    -- Build Layouts
    createSidebar(background)
    createNewsCard(background)
    createPlayerStats(background)
    
    -- Version footer
    local version = Instance.new("TextLabel")
    version.Text = "v1.0.0 BETA"
    version.Size = UDim2.new(1, -20, 0, 20)
    version.Position = UDim2.new(0, 0, 1, -25)
    version.BackgroundTransparency = 1
    version.TextXAlignment = Enum.TextXAlignment.Right
    version.TextColor3 = UITheme.Colors.TextDim
    version.TextTransparency = 0.5
    version.Parent = background
    
    MainMenuUI.screenGui = screenGui
    MainMenuUI.emberContainer = emberContainer
    
    -- Particle Loop
    task.spawn(function()
        while screenGui.Parent do
            if MainMenuUI.isVisible then
                createEmberParticle(emberContainer)
            end
            task.wait(0.2)
        end
    end)
    
    return screenGui
end

function MainMenuUI:show()
    if not MainMenuUI.screenGui then createUI() end
    MainMenuUI.screenGui.Enabled = true
    MainMenuUI.isVisible = true
    
    -- Camera manipulation could go here (e.g. pan across arena)
end

function MainMenuUI:hide()
    if MainMenuUI.screenGui then
        MainMenuUI.screenGui.Enabled = false
        MainMenuUI.isVisible = false
    end
end

function MainMenuUI.init()
    print("[MainMenuUI] Initializing...")
    createUI()
    MainMenuUI:show()
    
    -- Lobby Event Listeners
    local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemoteEvent", 10)
    if lobbyRemote then
        lobbyRemote.OnClientEvent:Connect(function(eventType)
            if eventType == "MATCH_STARTING" then
                MainMenuUI:hide()
            end
        end)
    end
    
     -- Match Event Listeners
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        matchRemote.OnClientEvent:Connect(function(eventType)
            if eventType == "MATCH_START" then
                MainMenuUI:hide()
            elseif eventType == "MATCH_END" then
                task.delay(5, function() MainMenuUI:show() end)
            end
        end)
    end
end

MainMenuUI.init()
return MainMenuUI
