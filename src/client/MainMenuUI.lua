-- LocalScript: MainMenuUI.lua
-- Central hub for The Ember Games
-- Displays before matches with access to all features

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local MainMenuUI = {}
MainMenuUI.isVisible = false
MainMenuUI.isInMatch = false

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(15, 15, 25),
    BUTTON_COLOR = Color3.fromRGB(30, 30, 45),
    BUTTON_HOVER = Color3.fromRGB(45, 45, 65),
}

-- Create animated ember particles
local function createEmberParticle(parent)
    local ember = Instance.new("Frame")
    ember.Size = UDim2.new(0, math.random(3, 6), 0, math.random(3, 6))
    ember.Position = UDim2.new(math.random(), 0, 1.1, 0)
    ember.BackgroundColor3 = Color3.fromRGB(255, math.random(100, 180), 0)
    ember.BorderSizePixel = 0
    ember.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ember
    
    local duration = math.random(3, 6)
    local xDrift = math.random(-50, 50)
    
    TweenService:Create(ember, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Position = UDim2.new(ember.Position.X.Scale, xDrift, -0.1, 0),
        BackgroundTransparency = 1
    }):Play()
    
    task.delay(duration, function()
        ember:Destroy()
    end)
end

-- Create menu button
local function createMenuButton(text, icon, yPos, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 280, 0, 55)
    button.Position = UDim2.new(0.5, -140, 0, yPos)
    button.BackgroundColor3 = CONFIG.BUTTON_COLOR
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.ACCENT_COLOR
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = button
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 40, 1, 0)
    iconLabel.Position = UDim2.new(0, 10, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 24
    iconLabel.Parent = button
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -60, 1, 0)
    textLabel.Position = UDim2.new(0, 55, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 18
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = CONFIG.BUTTON_HOVER
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {
            Transparency = 0
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = CONFIG.BUTTON_COLOR
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {
            Transparency = 0.5
        }):Play()
    end)
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainMenuUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Full screen background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = CONFIG.BG_COLOR
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    -- Gradient overlay
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 10, 5)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 5, 15))
    })
    gradient.Rotation = 45
    gradient.Parent = background
    
    -- Ember container
    local emberContainer = Instance.new("Frame")
    emberContainer.Name = "Embers"
    emberContainer.Size = UDim2.new(1, 0, 1, 0)
    emberContainer.BackgroundTransparency = 1
    emberContainer.Parent = background
    
    -- Title
    local titleContainer = Instance.new("Frame")
    titleContainer.Size = UDim2.new(1, 0, 0, 150)
    titleContainer.Position = UDim2.new(0, 0, 0, 80)
    titleContainer.BackgroundTransparency = 1
    titleContainer.Parent = background
    
    local titleIcon = Instance.new("TextLabel")
    titleIcon.Size = UDim2.new(1, 0, 0, 50)
    titleIcon.BackgroundTransparency = 1
    titleIcon.Text = "🔥"
    titleIcon.TextSize = 40
    titleIcon.Parent = titleContainer
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 45)
    title.BackgroundTransparency = 1
    title.Text = "THE EMBER GAMES"
    title.TextColor3 = CONFIG.ACCENT_COLOR
    title.TextSize = 48
    title.Font = Enum.Font.GothamBold
    title.Parent = titleContainer
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 25)
    subtitle.Position = UDim2.new(0, 0, 0, 110)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "May the odds be ever in your favor"
    subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
    subtitle.TextSize = 16
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.Parent = titleContainer
    
    -- Player info panel
    local playerInfo = Instance.new("Frame")
    playerInfo.Size = UDim2.new(0, 200, 0, 60)
    playerInfo.Position = UDim2.new(0, 20, 0, 20)
    playerInfo.BackgroundColor3 = CONFIG.BUTTON_COLOR
    playerInfo.BackgroundTransparency = 0.3
    playerInfo.BorderSizePixel = 0
    playerInfo.Parent = background
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = playerInfo
    
    local playerName = Instance.new("TextLabel")
    playerName.Size = UDim2.new(1, -10, 0, 25)
    playerName.Position = UDim2.new(0, 10, 0, 8)
    playerName.BackgroundTransparency = 1
    playerName.Text = Player.DisplayName
    playerName.TextColor3 = CONFIG.ACCENT_COLOR
    playerName.TextSize = 16
    playerName.Font = Enum.Font.GothamBold
    playerName.TextXAlignment = Enum.TextXAlignment.Left
    playerName.Parent = playerInfo
    
    local tierLabel = Instance.new("TextLabel")
    tierLabel.Size = UDim2.new(1, -10, 0, 20)
    tierLabel.Position = UDim2.new(0, 10, 0, 32)
    tierLabel.BackgroundTransparency = 1
    tierLabel.Text = "⭐ Season 1 • Tier 0"
    tierLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    tierLabel.TextSize = 12
    tierLabel.Font = Enum.Font.Gotham
    tierLabel.TextXAlignment = Enum.TextXAlignment.Left
    tierLabel.Parent = playerInfo
    
    -- Menu buttons container
    local menuContainer = Instance.new("Frame")
    menuContainer.Size = UDim2.new(0, 300, 0, 400)
    menuContainer.Position = UDim2.new(0.5, -150, 0.5, -100)
    menuContainer.BackgroundTransparency = 1
    menuContainer.Parent = background
    
    -- Play button (main)
    local playBtn = createMenuButton("ENTER THE ARENA", "⚔️", 0, function()
        MainMenuUI:hide()
        local lobbyRemote = ReplicatedStorage:FindFirstChild("LobbyRemoteEvent")
        if lobbyRemote then
            lobbyRemote:FireServer("QUEUE_FOR_MATCH")
        end
    end)
    playBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
    playBtn.Parent = menuContainer
    
    local playStroke = playBtn:FindFirstChild("UIStroke")
    if playStroke then playStroke.Color = Color3.fromRGB(100, 200, 100) end
    
    -- Battle Pass button
    local battlePassBtn = createMenuButton("Battle Pass", "🏆", 70, function()
        local seasonUI = PlayerGui:FindFirstChild("SeasonalUI")
        if seasonUI then
            local mainPanel = seasonUI:FindFirstChild("MainPanel")
            if mainPanel then mainPanel.Visible = true end
        end
    end)
    battlePassBtn.Parent = menuContainer
    
    -- Customize button
    local customizeBtn = createMenuButton("Customize", "✨", 140, function()
        print("[MainMenu] Opening cosmetics...")
        -- TODO: Open CosmeticsUI
    end)
    customizeBtn.Parent = menuContainer
    
    -- Alliance button
    local allianceBtn = createMenuButton("Alliances", "🤝", 210, function()
        local allianceUI = PlayerGui:FindFirstChild("AllianceUI")
        if allianceUI then
            local mainPanel = allianceUI:FindFirstChild("MainPanel")
            if mainPanel then mainPanel.Visible = not mainPanel.Visible end
        end
    end)
    allianceBtn.Parent = menuContainer
    
    -- Settings button
    local settingsBtn = createMenuButton("Settings", "⚙️", 280, function()
        print("[MainMenu] Opening settings...")
        -- TODO: Open SettingsUI
    end)
    settingsBtn.Parent = menuContainer
    
    -- Version info
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(0, 200, 0, 20)
    versionLabel.Position = UDim2.new(1, -210, 1, -30)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "v1.0.0 • Season 1"
    versionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    versionLabel.TextSize = 12
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextXAlignment = Enum.TextXAlignment.Right
    versionLabel.Parent = background
    
    MainMenuUI.screenGui = screenGui
    MainMenuUI.background = background
    MainMenuUI.emberContainer = emberContainer
    MainMenuUI.tierLabel = tierLabel
    
    -- Spawn ember particles
    task.spawn(function()
        while MainMenuUI.screenGui do
            if MainMenuUI.isVisible then
                createEmberParticle(emberContainer)
            end
            task.wait(0.15)
        end
    end)
    
    return screenGui
end

function MainMenuUI:show()
    if MainMenuUI.background then
        MainMenuUI.background.Visible = true
        MainMenuUI.isVisible = true
    end
end

function MainMenuUI:hide()
    if MainMenuUI.background then
        MainMenuUI.background.Visible = false
        MainMenuUI.isVisible = false
    end
end

function MainMenuUI:updateTier(tier)
    if MainMenuUI.tierLabel then
        MainMenuUI.tierLabel.Text = "⭐ Season 1 • Tier " .. tier
    end
end

function MainMenuUI.init()
    print("[MainMenuUI] Initializing...")
    createUI()
    
    -- Show menu initially
    MainMenuUI:show()
    
    -- Hide when match starts
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        matchRemote.OnClientEvent:Connect(function(eventType)
            if eventType == "MATCH_START" then
                MainMenuUI:hide()
                MainMenuUI.isInMatch = true
            elseif eventType == "MATCH_END" then
                MainMenuUI.isInMatch = false
                task.delay(5, function()
                    if not MainMenuUI.isInMatch then
                        MainMenuUI:show()
                    end
                end)
            end
        end)
    end
    
    -- Update tier from seasonal system
    local seasonRemote = ReplicatedStorage:FindFirstChild("SeasonalRemoteEvent")
    if seasonRemote then
        seasonRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "SEASON_INFO" and data.currentTier then
                MainMenuUI:updateTier(data.currentTier)
            end
        end)
    end
    
    print("[MainMenuUI] Initialized!")
end

MainMenuUI.init()
return MainMenuUI
