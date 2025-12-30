-- LocalScript: MatchHUD.lua
-- Core match information display
-- Shows tributes remaining, kills, placement, zone timer utilizing premium UITheme

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local UITheme = require(script.Parent:WaitForChild("UITheme"))

local MatchHUD = {}
MatchHUD.screenGui = nil
MatchHUD.isVisible = false
MatchHUD.tributesRemaining = 24
MatchHUD.playerKills = 0
MatchHUD.matchStartTime = 0
MatchHUD.zoneTimeRemaining = 0

-- Helper to create a standardized stat chip (Glassmorphic pill)
local function createStatChip(parent, icon, startValue)
    local chip = Instance.new("Frame")
    chip.Size = UDim2.new(0, 0, 0, 36) -- Width will be automatic
    chip.AutomaticSize = Enum.AutomaticSize.X
    chip.BackgroundTransparency = 1
    chip.Parent = parent

    -- Background Pill
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    UITheme.applyGlass(bg, 0.4)
    bg.Parent = chip
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = bg
    
    -- Padding for list
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = bg

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Text = icon
    iconLabel.Size = UDim2.new(0, 20, 0, 20)
    iconLabel.BackgroundTransparency = 1
    iconLabel.TextSize = 18
    iconLabel.Parent = bg

    -- Value
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Text = tostring(startValue)
    valueLabel.Size = UDim2.new(0, 0, 0, 20)
    valueLabel.AutomaticSize = Enum.AutomaticSize.X
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = UITheme.Colors.Text
    valueLabel.Font = UITheme.Fonts.Header
    valueLabel.TextSize = 20
    valueLabel.Parent = bg
    
    return chip, valueLabel
end

local function createHUD()
    if MatchHUD.screenGui then MatchHUD.screenGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MatchHUD"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui

    -- Top Right Stats Container (Kills, Alive)
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(0, 300, 0, 50)
    statsContainer.Position = UDim2.new(1, -20, 0, 20) -- Top Right padding
    statsContainer.AnchorPoint = Vector2.new(1, 0)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = screenGui
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.Parent = statsContainer

    -- Kills Chip (Skull Icon)
    local killsChip, killsLabel = createStatChip(statsContainer, "💀", 0)
    MatchHUD.killsLabel = killsLabel
    
    -- Tributes Alive Chip (Person Icon) -- Red tint to signify importance
    local aliveChip, aliveLabel = createStatChip(statsContainer, "👥", 24)
    local aliveBg = aliveChip:FindFirstChild("Background")
    if aliveBg then
        aliveBg.BackgroundColor3 = UITheme.Colors.Danger
        aliveBg.BackgroundTransparency = 0.6
    end
    MatchHUD.aliveLabel = aliveLabel

    -- Zone Info (Below Minimap usually, but let's put it Top Center for visibility)
    local zoneContainer = Instance.new("Frame")
    zoneContainer.Name = "ZoneContainer"
    zoneContainer.Size = UDim2.new(0, 150, 0, 45)
    zoneContainer.Position = UDim2.new(0.5, 0, 0, 20)
    zoneContainer.AnchorPoint = Vector2.new(0.5, 0)
    zoneContainer.BackgroundTransparency = 1
    zoneContainer.Parent = screenGui
    
    UITheme.applyGlass(zoneContainer, 0.5)
    
    local zoneTitle = Instance.new("TextLabel")
    zoneTitle.Text = "ZONE CLOSING"
    zoneTitle.Size = UDim2.new(1, 0, 0, 15)
    zoneTitle.Position = UDim2.new(0, 0, 0, 5)
    zoneTitle.BackgroundTransparency = 1
    zoneTitle.TextColor3 = UITheme.Colors.TextDim
    zoneTitle.Font = UITheme.Fonts.Label
    zoneTitle.TextSize = 10
    zoneTitle.Parent = zoneContainer
    
    local zoneTimer = Instance.new("TextLabel")
    zoneTimer.Name = "Timer"
    zoneTimer.Text = "00:00"
    zoneTimer.Size = UDim2.new(1, 0, 0, 25)
    zoneTimer.Position = UDim2.new(0, 0, 0, 18)
    zoneTimer.BackgroundTransparency = 1
    zoneTimer.TextColor3 = UITheme.Colors.Text
    zoneTimer.Font = UITheme.Fonts.Header
    zoneTimer.TextSize = 22
    zoneTimer.Parent = zoneContainer
    
    MatchHUD.zoneTitle = zoneTitle
    MatchHUD.zoneTimer = zoneTimer
    MatchHUD.zoneContainer = zoneContainer

    MatchHUD.screenGui = screenGui
    return screenGui
end

local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

function MatchHUD:updateTributesRemaining(count)
    if not MatchHUD.aliveLabel then return end
    
    local prev = tonumber(MatchHUD.aliveLabel.Text) or 0
    MatchHUD.aliveLabel.Text = tostring(count)
    
    -- Pop animation on change
    if count ~= prev then
        local tween = TweenService:Create(MatchHUD.aliveLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            TextSize = 28,
            TextColor3 = UITheme.Colors.GoldHighlight
        })
        tween:Play()
        tween.Completed:Connect(function()
            TweenService:Create(MatchHUD.aliveLabel, TweenInfo.new(0.2), {
                TextSize = 20,
                TextColor3 = UITheme.Colors.Text
            }):Play()
        end)
    end
end

function MatchHUD:updateKills(count)
    if not MatchHUD.killsLabel then return end
    
    local prev = tonumber(MatchHUD.killsLabel.Text) or 0
    MatchHUD.killsLabel.Text = tostring(count)
    
    if count > prev then
        -- Gold flash for kills
        local tween = TweenService:Create(MatchHUD.killsLabel, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {
            TextSize = 28,
            TextColor3 = UITheme.Colors.Gold
        })
        tween:Play()
        tween.Completed:Connect(function()
            TweenService:Create(MatchHUD.killsLabel, TweenInfo.new(0.2), {
                TextSize = 20,
                TextColor3 = UITheme.Colors.Text
            }):Play()
        end)
    end
end

function MatchHUD:updateZoneTimer(seconds, isClosing)
    if not MatchHUD.zoneTimer then return end
    
    MatchHUD.zoneTimer.Text = formatTime(seconds)
    
    if isClosing then
        MatchHUD.zoneTitle.Text = "ZONE CLOSING"
        MatchHUD.zoneTitle.TextColor3 = UITheme.Colors.Danger
        MatchHUD.zoneTimer.TextColor3 = UITheme.Colors.Danger
    else
        MatchHUD.zoneTitle.Text = "NEXT ZONE"
        MatchHUD.zoneTitle.TextColor3 = UITheme.Colors.TextDim
        MatchHUD.zoneTimer.TextColor3 = UITheme.Colors.Text
    end
end

function MatchHUD:show()
    if not MatchHUD.screenGui then createHUD() end
    MatchHUD.screenGui.Enabled = true
    MatchHUD.isVisible = true
end

function MatchHUD:hide()
    if MatchHUD.screenGui then
        MatchHUD.screenGui.Enabled = false
        MatchHUD.isVisible = false
    end
end

function MatchHUD.init()
    print("[MatchHUD] Initializing Premium HUD")
    createHUD()
    MatchHUD:hide() -- Hide initially
    
    -- Connect events
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        matchRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "MATCH_START" then
                MatchHUD:show()
                MatchHUD:updateTributesRemaining(data and data.tributes or 24)
            elseif eventType == "TRIBUTE_ELIMINATED" then
                MatchHUD:updateTributesRemaining(data.remaining)
            elseif eventType == "ZONE_UPDATE" then
                MatchHUD:updateZoneTimer(data.timeRemaining, data.isClosing)
            end
        end)
    end
    
    -- Connect to EventsRemote for storm updates
    local eventsRemote = ReplicatedStorage:WaitForChild("EventsRemoteEvent", 5)
    if eventsRemote then
        eventsRemote.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            if eventType == "STORM_PHASE_ACTIVE" then
                -- args: phase, radius, center, duration
                local phase = args[1]
                local duration = args[4] or 60
                
                if MatchHUD.zoneTitle then
                    MatchHUD.zoneTitle.Text = "STORM PHASE " .. tostring(phase)
                    MatchHUD.zoneTitle.TextColor3 = UITheme.Colors.Danger
                    MatchHUD.zoneContainer.Visible = true
                end
                
                -- Start local countdown
                MatchHUD:startZoneTimer(duration)
                
                -- Flash screen red briefly
                if MatchHUD.screenGui then
                    local flash = Instance.new("Frame")
                    flash.Size = UDim2.new(1,0,1,0)
                    flash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    flash.BackgroundTransparency = 0.8
                    flash.BorderSizePixel = 0
                    flash.ZIndex = -1
                    flash.Parent = MatchHUD.screenGui
                    
                    local tween = TweenService:Create(flash, TweenInfo.new(1), {BackgroundTransparency = 1})
                    tween:Play()
                    tween.Completed:Connect(function() flash:Destroy() end)
                end
            end
        end)
    end
end

-- New method to handle countdown
function MatchHUD:startZoneTimer(duration)
    MatchHUD.zoneTimeRemaining = duration
    
    if MatchHUD.timerConnection then MatchHUD.timerConnection:Disconnect() end
    
    local startTime = tick()
    MatchHUD.timerConnection = RunService.Stepped:Connect(function()
        local elapsed = tick() - startTime
        local remaining = math.max(0, duration - elapsed)
        
        MatchHUD:updateZoneTimer(remaining, true)
        
        if remaining <= 0 then
            if MatchHUD.timerConnection then MatchHUD.timerConnection:Disconnect() end
            MatchHUD:updateZoneTimer(0, false)
        end
    end)
end

MatchHUD.init()
return MatchHUD
