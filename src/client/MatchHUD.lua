-- LocalScript: MatchHUD.lua
-- Core match information display
-- Shows tributes remaining, kills, placement, zone timer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local MatchHUD = {}
MatchHUD.screenGui = nil
MatchHUD.isVisible = true
MatchHUD.tributesRemaining = 24
MatchHUD.playerKills = 0
MatchHUD.matchStartTime = 0
MatchHUD.zoneTimeRemaining = 0

-- Configuration
local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55), -- Gold
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    DANGER_COLOR = Color3.fromRGB(200, 50, 50),
    SAFE_COLOR = Color3.fromRGB(50, 200, 50),
    UPDATE_INTERVAL = 0.5,
}

-- Create the HUD
local function createHUD()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MatchHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Main container (top center)
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(0, 300, 0, 80)
    mainContainer.Position = UDim2.new(0.5, -150, 0, 10)
    mainContainer.BackgroundColor3 = CONFIG.BG_COLOR
    mainContainer.BackgroundTransparency = 0.3
    mainContainer.BorderSizePixel = 0
    mainContainer.Parent = screenGui
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 12)
    containerCorner.Parent = mainContainer
    
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = CONFIG.ACCENT_COLOR
    containerStroke.Thickness = 2
    containerStroke.Transparency = 0.5
    containerStroke.Parent = mainContainer
    
    -- Tributes Remaining (center, prominent)
    local tributesFrame = Instance.new("Frame")
    tributesFrame.Name = "TributesFrame"
    tributesFrame.Size = UDim2.new(0, 120, 0, 60)
    tributesFrame.Position = UDim2.new(0.5, -60, 0, 5)
    tributesFrame.BackgroundTransparency = 1
    tributesFrame.Parent = mainContainer
    
    local tributesIcon = Instance.new("TextLabel")
    tributesIcon.Name = "Icon"
    tributesIcon.Size = UDim2.new(0, 30, 0, 30)
    tributesIcon.Position = UDim2.new(0, 0, 0, 5)
    tributesIcon.BackgroundTransparency = 1
    tributesIcon.Text = "👥"
    tributesIcon.TextSize = 24
    tributesIcon.Parent = tributesFrame
    
    local tributesCount = Instance.new("TextLabel")
    tributesCount.Name = "Count"
    tributesCount.Size = UDim2.new(0, 60, 0, 40)
    tributesCount.Position = UDim2.new(0, 35, 0, 0)
    tributesCount.BackgroundTransparency = 1
    tributesCount.Text = "24"
    tributesCount.TextColor3 = Color3.fromRGB(255, 255, 255)
    tributesCount.TextSize = 36
    tributesCount.Font = Enum.Font.GothamBold
    tributesCount.TextXAlignment = Enum.TextXAlignment.Left
    tributesCount.Parent = tributesFrame
    
    local tributesLabel = Instance.new("TextLabel")
    tributesLabel.Name = "Label"
    tributesLabel.Size = UDim2.new(1, 0, 0, 15)
    tributesLabel.Position = UDim2.new(0, 0, 0, 42)
    tributesLabel.BackgroundTransparency = 1
    tributesLabel.Text = "TRIBUTES ALIVE"
    tributesLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    tributesLabel.TextSize = 10
    tributesLabel.Font = Enum.Font.Gotham
    tributesLabel.Parent = tributesFrame
    
    -- Kills (left side)
    local killsFrame = Instance.new("Frame")
    killsFrame.Name = "KillsFrame"
    killsFrame.Size = UDim2.new(0, 80, 0, 60)
    killsFrame.Position = UDim2.new(0, 10, 0, 10)
    killsFrame.BackgroundTransparency = 1
    killsFrame.Parent = mainContainer
    
    local killsIcon = Instance.new("TextLabel")
    killsIcon.Name = "Icon"
    killsIcon.Size = UDim2.new(0, 25, 0, 25)
    killsIcon.BackgroundTransparency = 1
    killsIcon.Text = "⚔️"
    killsIcon.TextSize = 18
    killsIcon.Parent = killsFrame
    
    local killsCount = Instance.new("TextLabel")
    killsCount.Name = "Count"
    killsCount.Size = UDim2.new(0, 40, 0, 30)
    killsCount.Position = UDim2.new(0, 28, 0, -3)
    killsCount.BackgroundTransparency = 1
    killsCount.Text = "0"
    killsCount.TextColor3 = CONFIG.ACCENT_COLOR
    killsCount.TextSize = 28
    killsCount.Font = Enum.Font.GothamBold
    killsCount.TextXAlignment = Enum.TextXAlignment.Left
    killsCount.Parent = killsFrame
    
    local killsLabel = Instance.new("TextLabel")
    killsLabel.Name = "Label"
    killsLabel.Size = UDim2.new(1, 0, 0, 15)
    killsLabel.Position = UDim2.new(0, 0, 0, 28)
    killsLabel.BackgroundTransparency = 1
    killsLabel.Text = "KILLS"
    killsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    killsLabel.TextSize = 10
    killsLabel.Font = Enum.Font.Gotham
    killsLabel.Parent = killsFrame
    
    -- Zone Timer (right side)
    local zoneFrame = Instance.new("Frame")
    zoneFrame.Name = "ZoneFrame"
    zoneFrame.Size = UDim2.new(0, 80, 0, 60)
    zoneFrame.Position = UDim2.new(1, -90, 0, 10)
    zoneFrame.BackgroundTransparency = 1
    zoneFrame.Parent = mainContainer
    
    local zoneIcon = Instance.new("TextLabel")
    zoneIcon.Name = "Icon"
    zoneIcon.Size = UDim2.new(0, 25, 0, 25)
    zoneIcon.BackgroundTransparency = 1
    zoneIcon.Text = "🌀"
    zoneIcon.TextSize = 18
    zoneIcon.Parent = zoneFrame
    
    local zoneTime = Instance.new("TextLabel")
    zoneTime.Name = "Time"
    zoneTime.Size = UDim2.new(0, 50, 0, 30)
    zoneTime.Position = UDim2.new(0, 28, 0, -3)
    zoneTime.BackgroundTransparency = 1
    zoneTime.Text = "2:00"
    zoneTime.TextColor3 = Color3.fromRGB(255, 255, 255)
    zoneTime.TextSize = 22
    zoneTime.Font = Enum.Font.GothamBold
    zoneTime.TextXAlignment = Enum.TextXAlignment.Left
    zoneTime.Parent = zoneFrame
    
    local zoneLabel = Instance.new("TextLabel")
    zoneLabel.Name = "Label"
    zoneLabel.Size = UDim2.new(1, 0, 0, 15)
    zoneLabel.Position = UDim2.new(0, 0, 0, 28)
    zoneLabel.BackgroundTransparency = 1
    zoneLabel.Text = "ZONE CLOSES"
    zoneLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    zoneLabel.TextSize = 10
    zoneLabel.Font = Enum.Font.Gotham
    zoneLabel.Parent = zoneFrame
    
    -- Match Time (bottom bar)
    local matchTimeBar = Instance.new("Frame")
    matchTimeBar.Name = "MatchTimeBar"
    matchTimeBar.Size = UDim2.new(1, -20, 0, 16)
    matchTimeBar.Position = UDim2.new(0, 10, 1, -20)
    matchTimeBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    matchTimeBar.BorderSizePixel = 0
    matchTimeBar.Parent = mainContainer
    
    local matchTimeCorner = Instance.new("UICorner")
    matchTimeCorner.CornerRadius = UDim.new(0, 4)
    matchTimeCorner.Parent = matchTimeBar
    
    local matchTimeLabel = Instance.new("TextLabel")
    matchTimeLabel.Name = "MatchTime"
    matchTimeLabel.Size = UDim2.new(1, 0, 1, 0)
    matchTimeLabel.BackgroundTransparency = 1
    matchTimeLabel.Text = "⏱️ Match Time: 0:00"
    matchTimeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    matchTimeLabel.TextSize = 11
    matchTimeLabel.Font = Enum.Font.Gotham
    matchTimeLabel.Parent = matchTimeBar
    
    -- Placement indicator (shows when tributes < 10)
    local placementFrame = Instance.new("Frame")
    placementFrame.Name = "PlacementFrame"
    placementFrame.Size = UDim2.new(0, 100, 0, 35)
    placementFrame.Position = UDim2.new(0.5, -50, 1, 5)
    placementFrame.BackgroundColor3 = CONFIG.BG_COLOR
    placementFrame.BackgroundTransparency = 0.3
    placementFrame.BorderSizePixel = 0
    placementFrame.Visible = false
    placementFrame.Parent = mainContainer
    
    local placementCorner = Instance.new("UICorner")
    placementCorner.CornerRadius = UDim.new(0, 8)
    placementCorner.Parent = placementFrame
    
    local placementStroke = Instance.new("UIStroke")
    placementStroke.Color = CONFIG.ACCENT_COLOR
    placementStroke.Thickness = 1
    placementStroke.Parent = placementFrame
    
    local placementText = Instance.new("TextLabel")
    placementText.Name = "Text"
    placementText.Size = UDim2.new(1, 0, 1, 0)
    placementText.BackgroundTransparency = 1
    placementText.Text = "TOP 10"
    placementText.TextColor3 = CONFIG.ACCENT_COLOR
    placementText.TextSize = 16
    placementText.Font = Enum.Font.GothamBold
    placementText.Parent = placementFrame
    
    -- Store references
    MatchHUD.screenGui = screenGui
    MatchHUD.mainContainer = mainContainer
    MatchHUD.tributesCount = tributesCount
    MatchHUD.killsCount = killsCount
    MatchHUD.zoneTime = zoneTime
    MatchHUD.zoneLabel = zoneLabel
    MatchHUD.matchTimeLabel = matchTimeLabel
    MatchHUD.placementFrame = placementFrame
    MatchHUD.placementText = placementText
    
    return screenGui
end

-- Format time as M:SS
local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

-- Update tributes remaining with animation
function MatchHUD:updateTributesRemaining(count)
    local previousCount = MatchHUD.tributesRemaining
    MatchHUD.tributesRemaining = count
    
    if MatchHUD.tributesCount then
        MatchHUD.tributesCount.Text = tostring(count)
        
        -- Animate on change
        if count < previousCount then
            -- Flash red on elimination
            local originalColor = MatchHUD.tributesCount.TextColor3
            MatchHUD.tributesCount.TextColor3 = CONFIG.DANGER_COLOR
            MatchHUD.tributesCount.TextSize = 42
            
            TweenService:Create(MatchHUD.tributesCount, TweenInfo.new(0.5), {
                TextColor3 = originalColor,
                TextSize = 36
            }):Play()
        end
        
        -- Show placement when getting close to end
        if count <= 10 and MatchHUD.placementFrame then
            MatchHUD.placementFrame.Visible = true
            MatchHUD.placementText.Text = "TOP " .. count
            
            if count <= 5 then
                MatchHUD.placementText.TextColor3 = CONFIG.ACCENT_COLOR
            elseif count <= 3 then
                MatchHUD.placementText.TextColor3 = Color3.fromRGB(255, 215, 0) -- Bright gold
            end
        end
    end
end

-- Update kill count
function MatchHUD:updateKills(count)
    MatchHUD.playerKills = count
    
    if MatchHUD.killsCount then
        local previousText = MatchHUD.killsCount.Text
        MatchHUD.killsCount.Text = tostring(count)
        
        -- Animate on new kill
        if tostring(count) ~= previousText then
            MatchHUD.killsCount.TextSize = 34
            TweenService:Create(MatchHUD.killsCount, TweenInfo.new(0.3), {
                TextSize = 28
            }):Play()
        end
    end
end

-- Update zone timer
function MatchHUD:updateZoneTimer(seconds, isClosing)
    MatchHUD.zoneTimeRemaining = seconds
    
    if MatchHUD.zoneTime then
        MatchHUD.zoneTime.Text = formatTime(seconds)
        
        -- Change color when zone is closing or low time
        if isClosing then
            MatchHUD.zoneTime.TextColor3 = CONFIG.DANGER_COLOR
            MatchHUD.zoneLabel.Text = "ZONE CLOSING"
            MatchHUD.zoneLabel.TextColor3 = CONFIG.DANGER_COLOR
        elseif seconds <= 30 then
            MatchHUD.zoneTime.TextColor3 = Color3.fromRGB(255, 200, 50) -- Warning
        else
            MatchHUD.zoneTime.TextColor3 = Color3.fromRGB(255, 255, 255)
            MatchHUD.zoneLabel.Text = "ZONE CLOSES"
            MatchHUD.zoneLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end

-- Update match time
function MatchHUD:updateMatchTime(seconds)
    if MatchHUD.matchTimeLabel then
        MatchHUD.matchTimeLabel.Text = "⏱️ Match Time: " .. formatTime(seconds)
    end
end

-- Start match timer
function MatchHUD:startMatchTimer()
    MatchHUD.matchStartTime = tick()
end

-- Show/hide HUD
function MatchHUD:show()
    if MatchHUD.screenGui then
        MatchHUD.screenGui.Enabled = true
        MatchHUD.isVisible = true
    end
end

function MatchHUD:hide()
    if MatchHUD.screenGui then
        MatchHUD.screenGui.Enabled = false
        MatchHUD.isVisible = false
    end
end

-- Reset HUD for new match
function MatchHUD:reset()
    MatchHUD.tributesRemaining = 24
    MatchHUD.playerKills = 0
    MatchHUD.matchStartTime = tick()
    MatchHUD.zoneTimeRemaining = 120
    
    if MatchHUD.tributesCount then
        MatchHUD.tributesCount.Text = "24"
    end
    if MatchHUD.killsCount then
        MatchHUD.killsCount.Text = "0"
    end
    if MatchHUD.placementFrame then
        MatchHUD.placementFrame.Visible = false
    end
end

-- Initialize
function MatchHUD.init()
    print("[MatchHUD] Initializing...")
    
    createHUD()
    
    -- Hide by default (show when match starts)
    MatchHUD:hide()
    
    -- Connect to remote events
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        matchRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "TRIBUTE_ELIMINATED" then
                MatchHUD:updateTributesRemaining(data.remaining)
            elseif eventType == "PLAYER_KILL" then
                MatchHUD:updateKills(MatchHUD.playerKills + 1)
            elseif eventType == "ZONE_UPDATE" then
                MatchHUD:updateZoneTimer(data.timeRemaining, data.isClosing)
            elseif eventType == "MATCH_START" then
                MatchHUD:reset()
                MatchHUD:show()
            elseif eventType == "MATCH_END" then
                -- Keep visible for final stats
            end
        end)
    end
    
    -- Also connect to LobbyRemoteEvent for MATCH_STARTING
    local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemoteEvent", 10)
    if lobbyRemote then
        lobbyRemote.OnClientEvent:Connect(function(eventType)
            if eventType == "MATCH_STARTING" then
                MatchHUD:reset()
                MatchHUD:show()
                MatchHUD:startMatchTimer()
            end
        end)
    end
    
    -- Update match time every second
    task.spawn(function()
        while true do
            task.wait(1)
            if MatchHUD.matchStartTime > 0 and MatchHUD.isVisible then
                local elapsed = tick() - MatchHUD.matchStartTime
                MatchHUD:updateMatchTime(elapsed)
            end
        end
    end)
    
    print("[MatchHUD] Initialized successfully!")
end

-- Initialize when module loads
MatchHUD.init()

return MatchHUD
