-- LocalScript: LeaderboardUI.lua
-- Global and seasonal rankings display
-- Shows wins, kills, survival time, etc.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local LeaderboardUI = {}
LeaderboardUI.isVisible = false
LeaderboardUI.currentCategory = "wins"
LeaderboardUI.currentFilter = "alltime"

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    PANEL_COLOR = Color3.fromRGB(30, 30, 45),
    GOLD_COLOR = Color3.fromRGB(255, 215, 0),
    SILVER_COLOR = Color3.fromRGB(192, 192, 192),
    BRONZE_COLOR = Color3.fromRGB(205, 127, 50),
}

local CATEGORIES = {
    { id = "wins", name = "Most Wins", icon = "🏆" },
    { id = "kills", name = "Most Kills", icon = "⚔️" },
    { id = "highestKillGame", name = "Highest Kill Game", icon = "💀" },
    { id = "totalSurvivalTime", name = "Survival Time", icon = "⏱️" },
    { id = "tier", name = "Season Tier", icon = "⭐" },
}

local FILTERS = {
    { id = "daily", name = "Daily" },
    { id = "weekly", name = "Weekly" },
    { id = "alltime", name = "All Time" },
}

-- Mock data (would come from server in production)
local mockLeaderboardData = {
    wins = {
        { rank = 1, name = "Katniss_Fan", value = 127, isYou = false },
        { rank = 2, name = "PeetaMellark", value = 98, isYou = false },
        { rank = 3, name = "District12Rep", value = 87, isYou = false },
        { rank = 4, name = "CareerTribute", value = 76, isYou = false },
        { rank = 5, name = "MockingJay24", value = 65, isYou = false },
        { rank = 6, name = "Volunteer", value = 54, isYou = true },
        { rank = 7, name = "GameMaker01", value = 43, isYou = false },
        { rank = 8, name = "NightlockBerry", value = 32, isYou = false },
        { rank = 9, name = "FinnickFan", value = 21, isYou = false },
        { rank = 10, name = "OdairSwimmer", value = 10, isYou = false },
    },
}

local function createLeaderboardEntry(parent, data, yPos)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -10, 0, 45)
    entry.Position = UDim2.new(0, 5, 0, yPos)
    entry.BackgroundColor3 = data.isYou and Color3.fromRGB(50, 50, 30) or CONFIG.PANEL_COLOR
    entry.BorderSizePixel = 0
    entry.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = entry
    
    if data.isYou then
        local stroke = Instance.new("UIStroke")
        stroke.Color = CONFIG.ACCENT_COLOR
        stroke.Thickness = 1
        stroke.Parent = entry
    end
    
    -- Rank
    local rankColor = CONFIG.ACCENT_COLOR
    if data.rank == 1 then rankColor = CONFIG.GOLD_COLOR
    elseif data.rank == 2 then rankColor = CONFIG.SILVER_COLOR
    elseif data.rank == 3 then rankColor = CONFIG.BRONZE_COLOR end
    
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(0, 40, 1, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = "#" .. data.rank
    rankLabel.TextColor3 = rankColor
    rankLabel.TextSize = 18
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.Parent = entry
    
    -- Medal for top 3
    if data.rank <= 3 then
        local medal = Instance.new("TextLabel")
        medal.Size = UDim2.new(0, 25, 0, 25)
        medal.Position = UDim2.new(0, 40, 0.5, -12)
        medal.BackgroundTransparency = 1
        medal.Text = data.rank == 1 and "🥇" or (data.rank == 2 and "🥈" or "🥉")
        medal.TextSize = 20
        medal.Parent = entry
    end
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, data.rank <= 3 and 70 or 45, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.name .. (data.isYou and " (You)" or "")
    nameLabel.TextColor3 = data.isYou and CONFIG.ACCENT_COLOR or Color3.fromRGB(220, 220, 220)
    nameLabel.TextSize = 14
    nameLabel.Font = data.isYou and Enum.Font.GothamBold or Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entry
    
    -- Value
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 80, 1, 0)
    valueLabel.Position = UDim2.new(1, -90, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(data.value)
    valueLabel.TextColor3 = CONFIG.ACCENT_COLOR
    valueLabel.TextSize = 18
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = entry
    
    return entry
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LeaderboardUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 500, 0, 550)
    panel.Position = UDim2.new(0.5, -250, 0.5, -275)
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
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = CONFIG.PANEL_COLOR
    header.BorderSizePixel = 0
    header.Parent = panel
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "🏆 LEADERBOARDS"
    title.TextColor3 = CONFIG.ACCENT_COLOR
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        LeaderboardUI:hide()
    end)
    
    -- Category tabs
    local categoryContainer = Instance.new("Frame")
    categoryContainer.Size = UDim2.new(1, -20, 0, 35)
    categoryContainer.Position = UDim2.new(0, 10, 0, 55)
    categoryContainer.BackgroundTransparency = 1
    categoryContainer.Parent = panel
    
    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.FillDirection = Enum.FillDirection.Horizontal
    categoryLayout.Padding = UDim.new(0, 5)
    categoryLayout.Parent = categoryContainer
    
    for _, cat in ipairs(CATEGORIES) do
        local catBtn = Instance.new("TextButton")
        catBtn.Name = cat.id
        catBtn.Size = UDim2.new(0, 90, 0, 30)
        catBtn.BackgroundColor3 = cat.id == LeaderboardUI.currentCategory and CONFIG.ACCENT_COLOR or CONFIG.PANEL_COLOR
        catBtn.BorderSizePixel = 0
        catBtn.Text = cat.icon .. " " .. cat.name:sub(1, 6)
        catBtn.TextColor3 = cat.id == LeaderboardUI.currentCategory and Color3.new(0,0,0) or Color3.new(1,1,1)
        catBtn.TextSize = 10
        catBtn.Font = Enum.Font.GothamBold
        catBtn.Parent = categoryContainer
        
        local catCorner = Instance.new("UICorner")
        catCorner.CornerRadius = UDim.new(0, 6)
        catCorner.Parent = catBtn
        
        catBtn.MouseButton1Click:Connect(function()
            LeaderboardUI.currentCategory = cat.id
            LeaderboardUI:refresh()
        end)
    end
    
    -- Filter tabs
    local filterContainer = Instance.new("Frame")
    filterContainer.Size = UDim2.new(0, 200, 0, 25)
    filterContainer.Position = UDim2.new(0.5, -100, 0, 95)
    filterContainer.BackgroundTransparency = 1
    filterContainer.Parent = panel
    
    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.Padding = UDim.new(0, 5)
    filterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    filterLayout.Parent = filterContainer
    
    for _, filter in ipairs(FILTERS) do
        local filterBtn = Instance.new("TextButton")
        filterBtn.Name = filter.id
        filterBtn.Size = UDim2.new(0, 60, 0, 22)
        filterBtn.BackgroundColor3 = filter.id == LeaderboardUI.currentFilter and CONFIG.ACCENT_COLOR or Color3.fromRGB(50, 50, 60)
        filterBtn.BorderSizePixel = 0
        filterBtn.Text = filter.name
        filterBtn.TextColor3 = filter.id == LeaderboardUI.currentFilter and Color3.new(0,0,0) or Color3.fromRGB(180, 180, 180)
        filterBtn.TextSize = 11
        filterBtn.Font = Enum.Font.Gotham
        filterBtn.Parent = filterContainer
        
        local filterCorner = Instance.new("UICorner")
        filterCorner.CornerRadius = UDim.new(0, 4)
        filterCorner.Parent = filterBtn
        
        filterBtn.MouseButton1Click:Connect(function()
            LeaderboardUI.currentFilter = filter.id
            LeaderboardUI:refresh()
        end)
    end
    
    -- Leaderboard list
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Name = "List"
    listContainer.Size = UDim2.new(1, -20, 1, -180)
    listContainer.Position = UDim2.new(0, 10, 0, 125)
    listContainer.BackgroundTransparency = 1
    listContainer.ScrollBarThickness = 6
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 500)
    listContainer.Parent = panel
    
    -- Your rank display
    local yourRank = Instance.new("Frame")
    yourRank.Size = UDim2.new(1, -20, 0, 40)
    yourRank.Position = UDim2.new(0, 10, 1, -50)
    yourRank.BackgroundColor3 = CONFIG.PANEL_COLOR
    yourRank.BorderSizePixel = 0
    yourRank.Parent = panel
    
    local yourRankCorner = Instance.new("UICorner")
    yourRankCorner.CornerRadius = UDim.new(0, 8)
    yourRankCorner.Parent = yourRank
    
    local yourRankLabel = Instance.new("TextLabel")
    yourRankLabel.Name = "YourRank"
    yourRankLabel.Size = UDim2.new(1, 0, 1, 0)
    yourRankLabel.BackgroundTransparency = 1
    yourRankLabel.Text = "Your Rank: #6 (54 wins)"
    yourRankLabel.TextColor3 = CONFIG.ACCENT_COLOR
    yourRankLabel.TextSize = 16
    yourRankLabel.Font = Enum.Font.GothamBold
    yourRankLabel.Parent = yourRank
    
    LeaderboardUI.screenGui = screenGui
    LeaderboardUI.panel = panel
    LeaderboardUI.listContainer = listContainer
    LeaderboardUI.categoryContainer = categoryContainer
    LeaderboardUI.filterContainer = filterContainer
    LeaderboardUI.yourRankLabel = yourRankLabel
end

function LeaderboardUI:refresh()
    -- Clear list
    for _, child in pairs(LeaderboardUI.listContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    -- Update category buttons
    for _, child in pairs(LeaderboardUI.categoryContainer:GetChildren()) do
        if child:IsA("TextButton") then
            local isActive = child.Name == LeaderboardUI.currentCategory
            TweenService:Create(child, TweenInfo.new(0.15), {
                BackgroundColor3 = isActive and CONFIG.ACCENT_COLOR or CONFIG.PANEL_COLOR
            }):Play()
            child.TextColor3 = isActive and Color3.new(0,0,0) or Color3.new(1,1,1)
        end
    end
    
    -- Update filter buttons
    for _, child in pairs(LeaderboardUI.filterContainer:GetChildren()) do
        if child:IsA("TextButton") then
            local isActive = child.Name == LeaderboardUI.currentFilter
            TweenService:Create(child, TweenInfo.new(0.15), {
                BackgroundColor3 = isActive and CONFIG.ACCENT_COLOR or Color3.fromRGB(50, 50, 60)
            }):Play()
            child.TextColor3 = isActive and Color3.new(0,0,0) or Color3.fromRGB(180, 180, 180)
        end
    end
    
    -- Populate list (using mock data for now)
    local data = mockLeaderboardData[LeaderboardUI.currentCategory] or mockLeaderboardData.wins
    local yPos = 0
    
    for _, entry in ipairs(data) do
        createLeaderboardEntry(LeaderboardUI.listContainer, entry, yPos)
        yPos = yPos + 50
    end
    
    LeaderboardUI.listContainer.CanvasSize = UDim2.new(0, 0, 0, yPos)
    
    -- Find your rank
    for _, entry in ipairs(data) do
        if entry.isYou then
            LeaderboardUI.yourRankLabel.Text = "Your Rank: #" .. entry.rank .. " (" .. entry.value .. ")"
        end
    end
end

function LeaderboardUI:show()
    if LeaderboardUI.panel then
        LeaderboardUI.panel.Visible = true
        LeaderboardUI.isVisible = true
        LeaderboardUI:refresh()
    end
end

function LeaderboardUI:hide()
    if LeaderboardUI.panel then
        LeaderboardUI.panel.Visible = false
        LeaderboardUI.isVisible = false
    end
end

function LeaderboardUI:toggle()
    if LeaderboardUI.isVisible then
        LeaderboardUI:hide()
    else
        LeaderboardUI:show()
    end
end

function LeaderboardUI.init()
    print("[LeaderboardUI] Initializing...")
    createUI()
    LeaderboardUI:refresh()
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.L then
            LeaderboardUI:toggle()
        end
    end)
    
    print("[LeaderboardUI] Initialized! Press L to open")
end

LeaderboardUI.init()
return LeaderboardUI
