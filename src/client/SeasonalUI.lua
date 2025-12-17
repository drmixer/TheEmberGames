-- LocalScript: SeasonalUI.lua
-- Client UI for seasonal rewards, battle pass, and challenges
-- Shows tier progression, rewards, and challenge tracking

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for remote event
local SeasonalRemoteEvent = ReplicatedStorage:WaitForChild("SeasonalRemoteEvent", 10)

local SeasonalUI = {}
SeasonalUI.screenGui = nil
SeasonalUI.mainFrame = nil
SeasonalUI.isVisible = false
SeasonalUI.seasonInfo = nil

-- Configuration
local CONFIG = {
    PANEL_SIZE = UDim2.new(0, 600, 0, 450),
    TOGGLE_KEY = Enum.KeyCode.B, -- Press B for Battle Pass
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55), -- Gold
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    TIER_COLOR = Color3.fromRGB(50, 50, 70),
    LOCKED_COLOR = Color3.fromRGB(40, 40, 50),
    UNLOCKED_COLOR = Color3.fromRGB(60, 100, 60),
}

-- Rarity colors
local RARITY_COLORS = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(50, 150, 255),
    Epic = Color3.fromRGB(150, 50, 200),
    Legendary = Color3.fromRGB(255, 180, 50),
}

-- Play sound
local function playSound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.Parent = PlayerGui
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

-- Create the main UI
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SeasonalUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Main panel
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainPanel"
    mainFrame.Size = CONFIG.PANEL_SIZE
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    mainFrame.BackgroundColor3 = CONFIG.BG_COLOR
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.ACCENT_COLOR
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 15)
    headerFix.Position = UDim2.new(0, 0, 1, -15)
    headerFix.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    -- Season title
    local seasonTitle = Instance.new("TextLabel")
    seasonTitle.Name = "SeasonTitle"
    seasonTitle.Size = UDim2.new(0.6, 0, 0.5, 0)
    seasonTitle.Position = UDim2.new(0.02, 0, 0.1, 0)
    seasonTitle.BackgroundTransparency = 1
    seasonTitle.Text = "🔥 SEASON 1: MOCKINGJAY"
    seasonTitle.TextColor3 = CONFIG.ACCENT_COLOR
    seasonTitle.TextSize = 22
    seasonTitle.Font = Enum.Font.GothamBold
    seasonTitle.TextXAlignment = Enum.TextXAlignment.Left
    seasonTitle.Parent = header
    
    -- Tier display
    local tierDisplay = Instance.new("TextLabel")
    tierDisplay.Name = "TierDisplay"
    tierDisplay.Size = UDim2.new(0.3, 0, 0.4, 0)
    tierDisplay.Position = UDim2.new(0.68, 0, 0.1, 0)
    tierDisplay.BackgroundTransparency = 1
    tierDisplay.Text = "TIER 0"
    tierDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
    tierDisplay.TextSize = 24
    tierDisplay.Font = Enum.Font.GothamBold
    tierDisplay.TextXAlignment = Enum.TextXAlignment.Right
    tierDisplay.Parent = header
    
    -- XP progress bar
    local xpBarBg = Instance.new("Frame")
    xpBarBg.Name = "XPBarBackground"
    xpBarBg.Size = UDim2.new(0.96, 0, 0, 8)
    xpBarBg.Position = UDim2.new(0.02, 0, 0.75, 0)
    xpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    xpBarBg.BorderSizePixel = 0
    xpBarBg.Parent = header
    
    local xpBarCorner = Instance.new("UICorner")
    xpBarCorner.CornerRadius = UDim.new(0.5, 0)
    xpBarCorner.Parent = xpBarBg
    
    local xpBarFill = Instance.new("Frame")
    xpBarFill.Name = "Fill"
    xpBarFill.Size = UDim2.new(0.5, 0, 1, 0)
    xpBarFill.BackgroundColor3 = CONFIG.ACCENT_COLOR
    xpBarFill.BorderSizePixel = 0
    xpBarFill.Parent = xpBarBg
    
    local xpFillCorner = Instance.new("UICorner")
    xpFillCorner.CornerRadius = UDim.new(0.5, 0)
    xpFillCorner.Parent = xpBarFill
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        SeasonalUI:hide()
    end)
    
    -- Tab buttons
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, 35)
    tabContainer.Position = UDim2.new(0, 0, 0, 65)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    local tabs = {"Rewards", "Challenges", "Stats"}
    for i, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "Tab"
        tabBtn.Size = UDim2.new(0.32, 0, 0, 30)
        tabBtn.Position = UDim2.new((i - 1) * 0.33 + 0.005, 0, 0, 0)
        tabBtn.BackgroundColor3 = i == 1 and CONFIG.ACCENT_COLOR or Color3.fromRGB(50, 50, 60)
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tabName
        tabBtn.TextColor3 = i == 1 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
        tabBtn.TextSize = 14
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tabBtn
        
        tabBtn.MouseButton1Click:Connect(function()
            SeasonalUI:switchTab(tabName)
        end)
    end
    
    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -115)
    contentArea.Position = UDim2.new(0, 10, 0, 105)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame
    
    -- Rewards page (tier grid)
    local rewardsPage = Instance.new("ScrollingFrame")
    rewardsPage.Name = "RewardsPage"
    rewardsPage.Size = UDim2.new(1, 0, 1, 0)
    rewardsPage.BackgroundTransparency = 1
    rewardsPage.ScrollBarThickness = 6
    rewardsPage.ScrollBarImageColor3 = CONFIG.ACCENT_COLOR
    rewardsPage.CanvasSize = UDim2.new(0, 0, 0, 1000)
    rewardsPage.Parent = contentArea
    
    local rewardsGrid = Instance.new("UIGridLayout")
    rewardsGrid.CellSize = UDim2.new(0, 90, 0, 100)
    rewardsGrid.CellPadding = UDim2.new(0, 8, 0, 8)
    rewardsGrid.SortOrder = Enum.SortOrder.LayoutOrder
    rewardsGrid.Parent = rewardsPage
    
    -- Challenges page
    local challengesPage = Instance.new("ScrollingFrame")
    challengesPage.Name = "ChallengesPage"
    challengesPage.Size = UDim2.new(1, 0, 1, 0)
    challengesPage.BackgroundTransparency = 1
    challengesPage.ScrollBarThickness = 6
    challengesPage.ScrollBarImageColor3 = CONFIG.ACCENT_COLOR
    challengesPage.CanvasSize = UDim2.new(0, 0, 0, 400)
    challengesPage.Visible = false
    challengesPage.Parent = contentArea
    
    local challengesLayout = Instance.new("UIListLayout")
    challengesLayout.Padding = UDim.new(0, 8)
    challengesLayout.Parent = challengesPage
    
    -- Stats page
    local statsPage = Instance.new("Frame")
    statsPage.Name = "StatsPage"
    statsPage.Size = UDim2.new(1, 0, 1, 0)
    statsPage.BackgroundTransparency = 1
    statsPage.Visible = false
    statsPage.Parent = contentArea
    
    -- Store references
    SeasonalUI.screenGui = screenGui
    SeasonalUI.mainFrame = mainFrame
    SeasonalUI.seasonTitle = seasonTitle
    SeasonalUI.tierDisplay = tierDisplay
    SeasonalUI.xpBarFill = xpBarFill
    SeasonalUI.rewardsPage = rewardsPage
    SeasonalUI.challengesPage = challengesPage
    SeasonalUI.statsPage = statsPage
    SeasonalUI.tabContainer = tabContainer
    SeasonalUI.contentArea = contentArea
    
    return screenGui
end

-- Switch tab
function SeasonalUI:switchTab(tabName)
    -- Update tab buttons
    for _, child in pairs(SeasonalUI.tabContainer:GetChildren()) do
        if child:IsA("TextButton") then
            local isActive = child.Name == tabName .. "Tab"
            child.BackgroundColor3 = isActive and CONFIG.ACCENT_COLOR or Color3.fromRGB(50, 50, 60)
            child.TextColor3 = isActive and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
        end
    end
    
    -- Show/hide pages
    SeasonalUI.rewardsPage.Visible = tabName == "Rewards"
    SeasonalUI.challengesPage.Visible = tabName == "Challenges"
    SeasonalUI.statsPage.Visible = tabName == "Stats"
end

-- Create tier reward card
local function createTierCard(tier, reward, isUnlocked, currentTier)
    local card = Instance.new("Frame")
    card.Name = "Tier" .. tier
    card.LayoutOrder = tier
    card.BackgroundColor3 = isUnlocked and CONFIG.UNLOCKED_COLOR or CONFIG.LOCKED_COLOR
    card.BorderSizePixel = 0
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- Current tier indicator
    if tier == currentTier + 1 then
        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = CONFIG.ACCENT_COLOR
        cardStroke.Thickness = 2
        cardStroke.Parent = card
    end
    
    -- Tier number
    local tierLabel = Instance.new("TextLabel")
    tierLabel.Size = UDim2.new(1, 0, 0, 20)
    tierLabel.Position = UDim2.new(0, 0, 0, 5)
    tierLabel.BackgroundTransparency = 1
    tierLabel.Text = "TIER " .. tier
    tierLabel.TextColor3 = CONFIG.ACCENT_COLOR
    tierLabel.TextSize = 12
    tierLabel.Font = Enum.Font.GothamBold
    tierLabel.Parent = card
    
    -- Reward icon (placeholder)
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 40, 0, 40)
    iconFrame.Position = UDim2.new(0.5, -20, 0, 28)
    iconFrame.BackgroundColor3 = isUnlocked and RARITY_COLORS.Rare or Color3.fromRGB(60, 60, 70)
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = card
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = iconFrame
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = reward and reward.type == "trail" and "✨" or "🎁"
    iconLabel.TextSize = 20
    iconLabel.Parent = iconFrame
    
    -- Reward name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -6, 0, 24)
    nameLabel.Position = UDim2.new(0, 3, 1, -26)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = reward and reward.name or "Tier " .. tier
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    nameLabel.TextSize = 9
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextWrapped = true
    nameLabel.Parent = card
    
    -- Lock overlay
    if not isUnlocked then
        local lockOverlay = Instance.new("Frame")
        lockOverlay.Size = UDim2.new(1, 0, 1, 0)
        lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        lockOverlay.BackgroundTransparency = 0.5
        lockOverlay.BorderSizePixel = 0
        lockOverlay.Parent = card
        
        local lockCorner = Instance.new("UICorner")
        lockCorner.CornerRadius = UDim.new(0, 8)
        lockCorner.Parent = lockOverlay
        
        local lockIcon = Instance.new("TextLabel")
        lockIcon.Size = UDim2.new(1, 0, 1, 0)
        lockIcon.BackgroundTransparency = 1
        lockIcon.Text = "🔒"
        lockIcon.TextSize = 24
        lockIcon.Parent = lockOverlay
    end
    
    return card
end

-- Create challenge card
local function createChallengeCard(challenge, challengeType)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = challenge.completed and CONFIG.UNLOCKED_COLOR or CONFIG.TIER_COLOR
    card.BorderSizePixel = 0
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- Challenge type badge
    local typeBadge = Instance.new("Frame")
    typeBadge.Size = UDim2.new(0, 60, 0, 20)
    typeBadge.Position = UDim2.new(0, 10, 0, 5)
    typeBadge.BackgroundColor3 = challengeType == "daily" and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 100, 50)
    typeBadge.BorderSizePixel = 0
    typeBadge.Parent = card
    
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 4)
    badgeCorner.Parent = typeBadge
    
    local badgeLabel = Instance.new("TextLabel")
    badgeLabel.Size = UDim2.new(1, 0, 1, 0)
    badgeLabel.BackgroundTransparency = 1
    badgeLabel.Text = challengeType == "daily" and "DAILY" or "WEEKLY"
    badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    badgeLabel.TextSize = 10
    badgeLabel.Font = Enum.Font.GothamBold
    badgeLabel.Parent = typeBadge
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.7, 0, 0, 20)
    descLabel.Position = UDim2.new(0, 10, 0, 28)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = challenge.description
    descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    descLabel.TextSize = 14
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = card
    
    -- Progress bar
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(0.6, 0, 0, 6)
    progressBg.Position = UDim2.new(0, 10, 1, -12)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = card
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0.5, 0)
    progressCorner.Parent = progressBg
    
    local progressFill = Instance.new("Frame")
    local fillAmount = math.min(challenge.progress / challenge.target, 1)
    progressFill.Size = UDim2.new(fillAmount, 0, 1, 0)
    progressFill.BackgroundColor3 = challenge.completed and Color3.fromRGB(50, 200, 50) or CONFIG.ACCENT_COLOR
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0.5, 0)
    fillCorner.Parent = progressFill
    
    -- XP reward
    local xpLabel = Instance.new("TextLabel")
    xpLabel.Size = UDim2.new(0, 80, 0, 30)
    xpLabel.Position = UDim2.new(1, -90, 0.5, -15)
    xpLabel.BackgroundTransparency = 1
    xpLabel.Text = "+" .. challenge.xp .. " XP"
    xpLabel.TextColor3 = CONFIG.ACCENT_COLOR
    xpLabel.TextSize = 16
    xpLabel.Font = Enum.Font.GothamBold
    xpLabel.Parent = card
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Size = UDim2.new(0, 60, 0, 20)
    progressText.Position = UDim2.new(0.65, 0, 1, -18)
    progressText.BackgroundTransparency = 1
    progressText.Text = challenge.progress .. "/" .. challenge.target
    progressText.TextColor3 = Color3.fromRGB(150, 150, 150)
    progressText.TextSize = 12
    progressText.Font = Enum.Font.Gotham
    progressText.Parent = card
    
    return card
end

-- Update display with season info
function SeasonalUI:updateDisplay(info)
    if not info then return end
    
    SeasonalUI.seasonInfo = info
    
    -- Update header
    SeasonalUI.seasonTitle.Text = "🔥 " .. info.seasonName:upper()
    SeasonalUI.tierDisplay.Text = "TIER " .. info.currentTier
    
    -- Update XP bar
    TweenService:Create(SeasonalUI.xpBarFill, TweenInfo.new(0.5), {
        Size = UDim2.new(info.tierProgress, 0, 1, 0)
    }):Play()
    
    -- Clear and rebuild rewards grid
    for _, child in pairs(SeasonalUI.rewardsPage:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create tier cards
    for tier = 1, info.maxTier do
        local reward = info.allTierRewards[tier]
        local isUnlocked = tier <= info.currentTier
        local card = createTierCard(tier, reward, isUnlocked, info.currentTier)
        card.Parent = SeasonalUI.rewardsPage
    end
    
    -- Update canvas size
    local rows = math.ceil(info.maxTier / 6)
    SeasonalUI.rewardsPage.CanvasSize = UDim2.new(0, 0, 0, rows * 108)
    
    -- Update challenges
    for _, child in pairs(SeasonalUI.challengesPage:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add daily challenges header
    local dailyHeader = Instance.new("TextLabel")
    dailyHeader.Size = UDim2.new(1, 0, 0, 25)
    dailyHeader.BackgroundTransparency = 1
    dailyHeader.Text = "📅 Daily Challenges"
    dailyHeader.TextColor3 = CONFIG.ACCENT_COLOR
    dailyHeader.TextSize = 16
    dailyHeader.Font = Enum.Font.GothamBold
    dailyHeader.TextXAlignment = Enum.TextXAlignment.Left
    dailyHeader.Parent = SeasonalUI.challengesPage
    
    for _, challenge in ipairs(info.challenges.daily or {}) do
        local card = createChallengeCard(challenge, "daily")
        card.Parent = SeasonalUI.challengesPage
    end
    
    -- Add weekly challenges header
    local weeklyHeader = Instance.new("TextLabel")
    weeklyHeader.Size = UDim2.new(1, 0, 0, 25)
    weeklyHeader.BackgroundTransparency = 1
    weeklyHeader.Text = "📆 Weekly Challenges"
    weeklyHeader.TextColor3 = CONFIG.ACCENT_COLOR
    weeklyHeader.TextSize = 16
    weeklyHeader.Font = Enum.Font.GothamBold
    weeklyHeader.TextXAlignment = Enum.TextXAlignment.Left
    weeklyHeader.Parent = SeasonalUI.challengesPage
    
    for _, challenge in ipairs(info.challenges.weekly or {}) do
        local card = createChallengeCard(challenge, "weekly")
        card.Parent = SeasonalUI.challengesPage
    end
    
    -- Update stats page
    SeasonalUI:updateStatsPage(info.stats)
end

-- Update stats page
function SeasonalUI:updateStatsPage(stats)
    -- Clear existing
    for _, child in pairs(SeasonalUI.statsPage:GetChildren()) do
        child:Destroy()
    end
    
    stats = stats or {}
    
    local statsList = {
        { label = "Matches Played", value = stats.matchesPlayed or 0 },
        { label = "Total Eliminations", value = stats.kills or 0 },
        { label = "Victories", value = stats.wins or 0 },
        { label = "Total Survival Time", value = math.floor((stats.totalSurvivalTime or 0) / 60) .. " min" },
    }
    
    for i, stat in ipairs(statsList) do
        local statFrame = Instance.new("Frame")
        statFrame.Size = UDim2.new(0.48, 0, 0, 70)
        statFrame.Position = UDim2.new(((i - 1) % 2) * 0.52, 0, 0, math.floor((i - 1) / 2) * 80)
        statFrame.BackgroundColor3 = CONFIG.TIER_COLOR
        statFrame.BorderSizePixel = 0
        statFrame.Parent = SeasonalUI.statsPage
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = statFrame
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, 0, 0.6, 0)
        valueLabel.Position = UDim2.new(0, 0, 0, 5)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(stat.value)
        valueLabel.TextColor3 = CONFIG.ACCENT_COLOR
        valueLabel.TextSize = 28
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.Parent = statFrame
        
        local labelLabel = Instance.new("TextLabel")
        labelLabel.Size = UDim2.new(1, 0, 0.35, 0)
        labelLabel.Position = UDim2.new(0, 0, 0.6, 0)
        labelLabel.BackgroundTransparency = 1
        labelLabel.Text = stat.label
        labelLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        labelLabel.TextSize = 12
        labelLabel.Font = Enum.Font.Gotham
        labelLabel.Parent = statFrame
    end
end

-- Show UI
function SeasonalUI:show()
    if SeasonalUI.mainFrame then
        SeasonalUI.mainFrame.Visible = true
        SeasonalUI.isVisible = true
        
        -- Request latest season info
        if SeasonalRemoteEvent then
            SeasonalRemoteEvent:FireServer("GET_SEASON_INFO")
        end
        
        -- Animate in
        SeasonalUI.mainFrame.Position = UDim2.new(0.5, -300, 0.6, -225)
        TweenService:Create(SeasonalUI.mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -300, 0.5, -225)
        }):Play()
    end
end

-- Hide UI
function SeasonalUI:hide()
    if SeasonalUI.mainFrame then
        TweenService:Create(SeasonalUI.mainFrame, TweenInfo.new(0.2), {
            Position = UDim2.new(0.5, -300, 0.6, -225)
        }):Play()
        
        task.delay(0.2, function()
            SeasonalUI.mainFrame.Visible = false
            SeasonalUI.isVisible = false
        end)
    end
end

-- Toggle UI
function SeasonalUI:toggle()
    if SeasonalUI.isVisible then
        SeasonalUI:hide()
    else
        SeasonalUI:show()
    end
end

-- Show XP popup
function SeasonalUI:showXPPopup(amount, reason)
    local popup = Instance.new("TextLabel")
    popup.Size = UDim2.new(0, 200, 0, 40)
    popup.Position = UDim2.new(0.5, -100, 0.8, 0)
    popup.BackgroundColor3 = CONFIG.BG_COLOR
    popup.BackgroundTransparency = 0.3
    popup.BorderSizePixel = 0
    popup.Text = "+" .. amount .. " XP - " .. reason
    popup.TextColor3 = CONFIG.ACCENT_COLOR
    popup.TextSize = 14
    popup.Font = Enum.Font.GothamBold
    popup.Parent = SeasonalUI.screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = popup
    
    -- Animate
    TweenService:Create(popup, TweenInfo.new(0.3), {
        Position = UDim2.new(0.5, -100, 0.75, 0)
    }):Play()
    
    task.delay(2, function()
        TweenService:Create(popup, TweenInfo.new(0.3), {
            Position = UDim2.new(0.5, -100, 0.8, 0),
            BackgroundTransparency = 1,
            TextTransparency = 1
        }):Play()
        task.delay(0.3, function()
            popup:Destroy()
        end)
    end)
end

-- Initialize
function SeasonalUI.init()
    print("[SeasonalUI] Initializing...")
    
    createUI()
    
    -- Handle keyboard input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONFIG.TOGGLE_KEY then
            SeasonalUI:toggle()
        end
    end)
    
    -- Handle server events
    if SeasonalRemoteEvent then
        SeasonalRemoteEvent.OnClientEvent:Connect(function(eventType, data)
            if eventType == "SEASON_INFO" then
                SeasonalUI:updateDisplay(data)
                
            elseif eventType == "XP_AWARDED" then
                SeasonalUI:showXPPopup(data.amount, data.reason)
                if SeasonalUI.seasonInfo then
                    SeasonalUI.seasonInfo.currentXP = data.totalXP
                    SeasonalUI.seasonInfo.currentTier = data.tier
                    SeasonalUI.seasonInfo.tierProgress = data.tierProgress
                    
                    -- Update tier display immediately
                    SeasonalUI.tierDisplay.Text = "TIER " .. data.tier
                    TweenService:Create(SeasonalUI.xpBarFill, TweenInfo.new(0.3), {
                        Size = UDim2.new(data.tierProgress, 0, 1, 0)
                    }):Play()
                end
                
            elseif eventType == "REWARD_UNLOCKED" then
                -- Show reward unlock notification
                playSound("rbxassetid://9046240113", 0.6)
                print("[SeasonalUI] Unlocked: " .. data.reward.name)
                
            elseif eventType == "CHALLENGE_COMPLETED" then
                playSound("rbxassetid://9046239626", 0.5)
                print("[SeasonalUI] Challenge completed: " .. data.challenge.description)
            end
        end)
    end
    
    print("[SeasonalUI] Initialized - Press B to open Battle Pass")
end

-- Initialize when module loads
SeasonalUI.init()

return SeasonalUI
