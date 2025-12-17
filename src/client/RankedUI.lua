-- LocalScript: RankedUI.lua
-- Displays ranked information and queue for ranked matches

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local RankedUI = {}
RankedUI.isVisible = false
RankedUI.rankData = nil
RankedUI.isQueued = false

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    PANEL_COLOR = Color3.fromRGB(30, 30, 45),
}

local RANK_COLORS = {
    Bronze = Color3.fromRGB(205, 127, 50),
    Silver = Color3.fromRGB(192, 192, 192),
    Gold = Color3.fromRGB(255, 215, 0),
    Platinum = Color3.fromRGB(100, 200, 255),
    Diamond = Color3.fromRGB(185, 242, 255),
    Champion = Color3.fromRGB(255, 100, 150),
}

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RankedUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 400, 0, 450)
    panel.Position = UDim2.new(0.5, -200, 0.5, -225)
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
    title.Text = "⚔️ RANKED"
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
        RankedUI:hide()
    end)
    
    -- Rank display
    local rankFrame = Instance.new("Frame")
    rankFrame.Size = UDim2.new(1, -40, 0, 140)
    rankFrame.Position = UDim2.new(0, 20, 0, 60)
    rankFrame.BackgroundColor3 = CONFIG.PANEL_COLOR
    rankFrame.BorderSizePixel = 0
    rankFrame.Parent = panel
    
    local rankCorner = Instance.new("UICorner")
    rankCorner.CornerRadius = UDim.new(0, 10)
    rankCorner.Parent = rankFrame
    
    local rankIcon = Instance.new("TextLabel")
    rankIcon.Name = "RankIcon"
    rankIcon.Size = UDim2.new(0, 80, 0, 80)
    rankIcon.Position = UDim2.new(0, 15, 0.5, -40)
    rankIcon.BackgroundTransparency = 1
    rankIcon.Text = "🥉"
    rankIcon.TextSize = 60
    rankIcon.Parent = rankFrame
    
    local rankName = Instance.new("TextLabel")
    rankName.Name = "RankName"
    rankName.Size = UDim2.new(0.6, 0, 0, 30)
    rankName.Position = UDim2.new(0, 100, 0, 25)
    rankName.BackgroundTransparency = 1
    rankName.Text = "BRONZE"
    rankName.TextColor3 = RANK_COLORS.Bronze
    rankName.TextSize = 24
    rankName.Font = Enum.Font.GothamBold
    rankName.TextXAlignment = Enum.TextXAlignment.Left
    rankName.Parent = rankFrame
    
    local mmrLabel = Instance.new("TextLabel")
    mmrLabel.Name = "MMRLabel"
    mmrLabel.Size = UDim2.new(0.6, 0, 0, 25)
    mmrLabel.Position = UDim2.new(0, 100, 0, 55)
    mmrLabel.BackgroundTransparency = 1
    mmrLabel.Text = "1200 MMR"
    mmrLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    mmrLabel.TextSize = 18
    mmrLabel.Font = Enum.Font.Gotham
    mmrLabel.TextXAlignment = Enum.TextXAlignment.Left
    mmrLabel.Parent = rankFrame
    
    -- Progress bar
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(0.55, 0, 0, 10)
    progressBg.Position = UDim2.new(0, 100, 0, 90)
    progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = rankFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0.5, 0)
    progressCorner.Parent = progressBg
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0.5, 0, 1, 0)
    progressFill.BackgroundColor3 = CONFIG.ACCENT_COLOR
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0.5, 0)
    progressFillCorner.Parent = progressFill
    
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Size = UDim2.new(0.55, 0, 0, 15)
    progressLabel.Position = UDim2.new(0, 100, 0, 105)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "500/1000 to Silver"
    progressLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    progressLabel.TextSize = 10
    progressLabel.Font = Enum.Font.Gotham
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = rankFrame
    
    -- Stats
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, -40, 0, 100)
    statsFrame.Position = UDim2.new(0, 20, 0, 210)
    statsFrame.BackgroundColor3 = CONFIG.PANEL_COLOR
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = panel
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 10)
    statsCorner.Parent = statsFrame
    
    local stats = {
        { label = "Games", value = "0", icon = "🎮" },
        { label = "Wins", value = "0", icon = "🏆" },
        { label = "Kills", value = "0", icon = "⚔️" },
        { label = "Peak", value = "1200", icon = "📈" },
    }
    
    for i, stat in ipairs(stats) do
        local statFrame = Instance.new("Frame")
        statFrame.Size = UDim2.new(0.25, -5, 1, 0)
        statFrame.Position = UDim2.new((i-1) * 0.25, 0, 0, 0)
        statFrame.BackgroundTransparency = 1
        statFrame.Parent = statsFrame
        
        local statIcon = Instance.new("TextLabel")
        statIcon.Size = UDim2.new(1, 0, 0, 30)
        statIcon.Position = UDim2.new(0, 0, 0, 10)
        statIcon.BackgroundTransparency = 1
        statIcon.Text = stat.icon
        statIcon.TextSize = 24
        statIcon.Parent = statFrame
        
        local statValue = Instance.new("TextLabel")
        statValue.Name = stat.label .. "Value"
        statValue.Size = UDim2.new(1, 0, 0, 25)
        statValue.Position = UDim2.new(0, 0, 0, 40)
        statValue.BackgroundTransparency = 1
        statValue.Text = stat.value
        statValue.TextColor3 = CONFIG.ACCENT_COLOR
        statValue.TextSize = 18
        statValue.Font = Enum.Font.GothamBold
        statValue.Parent = statFrame
        
        local statLabel = Instance.new("TextLabel")
        statLabel.Size = UDim2.new(1, 0, 0, 15)
        statLabel.Position = UDim2.new(0, 0, 0, 65)
        statLabel.BackgroundTransparency = 1
        statLabel.Text = stat.label
        statLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        statLabel.TextSize = 11
        statLabel.Font = Enum.Font.Gotham
        statLabel.Parent = statFrame
    end
    
    -- Queue button
    local queueBtn = Instance.new("TextButton")
    queueBtn.Name = "QueueBtn"
    queueBtn.Size = UDim2.new(1, -40, 0, 55)
    queueBtn.Position = UDim2.new(0, 20, 0, 325)
    queueBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
    queueBtn.BorderSizePixel = 0
    queueBtn.Text = "⚔️ QUEUE FOR RANKED"
    queueBtn.TextColor3 = Color3.new(0,0,0)
    queueBtn.TextSize = 18
    queueBtn.Font = Enum.Font.GothamBold
    queueBtn.Parent = panel
    
    local queueCorner = Instance.new("UICorner")
    queueCorner.CornerRadius = UDim.new(0, 10)
    queueCorner.Parent = queueBtn
    
    -- Warning label for placement
    local placementLabel = Instance.new("TextLabel")
    placementLabel.Name = "PlacementLabel"
    placementLabel.Size = UDim2.new(1, -40, 0, 25)
    placementLabel.Position = UDim2.new(0, 20, 0, 390)
    placementLabel.BackgroundTransparency = 1
    placementLabel.Text = "🎯 10 placement games remaining"
    placementLabel.TextColor3 = Color3.fromRGB(200, 150, 50)
    placementLabel.TextSize = 12
    placementLabel.Font = Enum.Font.GothamBold
    placementLabel.Parent = panel
    
    RankedUI.screenGui = screenGui
    RankedUI.panel = panel
    RankedUI.rankIcon = rankIcon
    RankedUI.rankName = rankName
    RankedUI.mmrLabel = mmrLabel
    RankedUI.progressFill = progressFill
    RankedUI.queueBtn = queueBtn
    RankedUI.placementLabel = placementLabel
    RankedUI.statsFrame = statsFrame
    
    queueBtn.MouseButton1Click:Connect(function()
        if not RankedUI.isQueued then
            RankedUI:queueForRanked()
        end
    end)
end

function RankedUI:updateDisplay()
    if not RankedUI.rankData then return end
    local data = RankedUI.rankData
    
    RankedUI.rankIcon.Text = data.rankIcon or "🥉"
    RankedUI.rankName.Text = (data.rankName or "Bronze"):upper()
    RankedUI.rankName.TextColor3 = RANK_COLORS[data.rankName] or RANK_COLORS.Bronze
    RankedUI.mmrLabel.Text = (data.mmr or 1200) .. " MMR"
    RankedUI.progressFill.Size = UDim2.new(data.progressToNext or 0.5, 0, 1, 0)
    
    if data.isPlacement then
        RankedUI.placementLabel.Visible = true
        RankedUI.placementLabel.Text = "🎯 " .. data.placementGamesLeft .. " placement games remaining"
    else
        RankedUI.placementLabel.Visible = false
    end
    
    -- Update stats
    local statsFrame = RankedUI.statsFrame
    local gamesValue = statsFrame:FindFirstChild("GamesValue", true)
    if gamesValue then gamesValue.Text = tostring(data.gamesPlayed or 0) end
    
    local winsValue = statsFrame:FindFirstChild("WinsValue", true)
    if winsValue then winsValue.Text = tostring(data.wins or 0) end
    
    local peakValue = statsFrame:FindFirstChild("PeakValue", true)
    if peakValue then peakValue.Text = tostring(data.peakMMR or 1200) end
end

function RankedUI:queueForRanked()
    local rankedRemote = ReplicatedStorage:FindFirstChild("RankedRemote")
    if rankedRemote then
        rankedRemote:FireServer("QUEUE")
        RankedUI.isQueued = true
        RankedUI.queueBtn.Text = "⏳ SEARCHING..."
        RankedUI.queueBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end
end

function RankedUI:show()
    if RankedUI.panel then
        RankedUI.panel.Visible = true
        RankedUI.isVisible = true
        
        -- Request fresh data
        local rankedRemote = ReplicatedStorage:FindFirstChild("RankedRemote")
        if rankedRemote then
            rankedRemote:FireServer("GET_RANK")
        end
    end
end

function RankedUI:hide()
    if RankedUI.panel then
        RankedUI.panel.Visible = false
        RankedUI.isVisible = false
    end
end

function RankedUI:toggle()
    if RankedUI.isVisible then
        RankedUI:hide()
    else
        RankedUI:show()
    end
end

function RankedUI.init()
    print("[RankedUI] Initializing...")
    createUI()
    
    local rankedRemote = ReplicatedStorage:FindFirstChild("RankedRemote")
    if rankedRemote then
        rankedRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "RANK_DATA" then
                RankedUI.rankData = data
                RankedUI:updateDisplay()
            elseif eventType == "QUEUED" then
                RankedUI.isQueued = true
                RankedUI.queueBtn.Text = "⏳ SEARCHING... (" .. data.estimatedWait .. "s)"
            elseif eventType == "MATCH_RESULT" then
                -- Show MMR change
                print("[RankedUI] Match result: " .. data.mmrChange .. " MMR")
            end
        end)
    end
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.R and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            RankedUI:toggle()
        end
    end)
    
    print("[RankedUI] Initialized! Press Shift+R to open")
end

RankedUI.init()
return RankedUI
