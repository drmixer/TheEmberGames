-- LocalScript: StatusHUD.lua
-- Displays player Health, Hunger, Thirst, and active Status Effects
-- Premium "The Ember Games" styling using Glassmorphism

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local UITheme = require(script.Parent:WaitForChild("UITheme"))

local StatusHUD = {}
StatusHUD.screenGui = nil
StatusHUD.stats = {
    health = 100,
    maxHealth = 100,
    hunger = 100,
    maxHunger = 100,
    thirst = 100,
    maxThirst = 100
}
StatusHUD.bars = {}
StatusHUD.effects = {}

-- Constants
local BAR_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PULSE_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

-- Helper to create a progress bar
local function createBar(parent, name, color, icon, position, size)
    local container = Instance.new("Frame")
    container.Name = name .. "Container"
    container.Size = size
    container.Position = position
    container.BackgroundTransparency = 1
    container.Parent = parent

    -- Background
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    UITheme.applyGlass(bg, 0.5)
    bg.Parent = container

    -- Fill Container (Mask)
    local fillContainer = Instance.new("Frame")
    fillContainer.Name = "FillContainer"
    fillContainer.Size = UDim2.new(1, -6, 1, -6)
    fillContainer.Position = UDim2.new(0, 3, 0, 3)
    fillContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    fillContainer.BackgroundTransparency = 0.5
    fillContainer.BorderSizePixel = 0
    fillContainer.ClipsDescendants = true
    fillContainer.Parent = bg
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = fillContainer

    -- The Fill Bar itself
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0) -- Starts full
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = fillContainer
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fill

    -- Icon
    if icon then
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Name = "Icon"
        iconLabel.Text = icon
        iconLabel.Size = UDim2.new(0, 35, 0, 35)
        iconLabel.Position = UDim2.new(0, -40, 0.5, -17)
        iconLabel.BackgroundTransparency = 1
        iconLabel.TextSize = 28
        iconLabel.Parent = bg
    end
    
    -- Value Text (Overlay)
    local valueText = Instance.new("TextLabel")
    valueText.Name = "Value"
    valueText.Size = UDim2.new(1, 0, 1, 0)
    valueText.BackgroundTransparency = 1
    valueText.Font = UITheme.Fonts.Label
    valueText.TextSize = 18 -- Larger text
    valueText.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueText.TextTransparency = 0
    valueText.TextStrokeTransparency = 0.5
    valueText.Text = "100%"
    valueText.Parent = bg

    return fill, valueText, container
end

-- ... status effect visual helper ...

function StatusHUD:create()
    if StatusHUD.screenGui then StatusHUD.screenGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatusHUD"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10 -- Above most things
    screenGui.Parent = PlayerGui
    StatusHUD.screenGui = screenGui

    -- Main Container (Bottom Left)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 450, 0, 150) -- Increased container size
    mainFrame.Position = UDim2.new(0, 20, 1, -20) -- Bottom Left padding
    mainFrame.AnchorPoint = Vector2.new(0, 1)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui

    -- 1. Health Bar (Large, Bottom)
    local healthFill, healthText, healthContainer = createBar(
        mainFrame, 
        "Health", 
        UITheme.Colors.Success, 
        "❤️", 
        UDim2.new(0, 50, 1, -45), -- Pos
        UDim2.new(0, 350, 0, 40) -- Size (Larger)
    )
    StatusHUD.bars.health = {fill = healthFill, text = healthText, container = healthContainer}
    
    -- 2. Hunger Bar (Smaller, Above Health)
    local hungerFill, hungerText, hungerContainer = createBar(
        mainFrame, 
        "Hunger", 
        Color3.fromRGB(255, 150, 50), -- Orange
        "🍖", 
        UDim2.new(0, 50, 1, -95), 
        UDim2.new(0, 160, 0, 28)
    )
    StatusHUD.bars.hunger = {fill = hungerFill, text = hungerText, container = hungerContainer}

    -- 3. Thirst Bar (Smaller, Beside Hunger)
    local thirstFill, thirstText, thirstContainer = createBar(
        mainFrame, 
        "Thirst", 
        Color3.fromRGB(50, 150, 255), -- Blue
        "💧", 
        UDim2.new(0, 260, 1, -95), -- Shifted right to avoid overlap (Icon needs ~40px)
        UDim2.new(0, 160, 0, 28)
    )
    StatusHUD.bars.thirst = {fill = thirstFill, text = thirstText, container = thirstContainer}

    -- 4. Status Effects Container (Above Bars)
    local effectsContainer = Instance.new("Frame")
    effectsContainer.Name = "StatusEffects"
    effectsContainer.Size = UDim2.new(1, 0, 0, 50)
    effectsContainer.Position = UDim2.new(0, 0, 0, 0)
    effectsContainer.BackgroundTransparency = 1
    effectsContainer.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 5)
    layout.Parent = effectsContainer
    
    StatusHUD.effectsContainer = effectsContainer
end

function StatusHUD:updateStat(statName, value, maxValue)
    local bar = StatusHUD.bars[statName]
    if not bar then return end
    
    maxValue = maxValue or 100
    local ratio = math.clamp(value / maxValue, 0, 1)
    
    -- Update Text
    bar.text.Text = math.floor(value) .. " / " .. maxValue
    
    -- Tween Fill
    TweenService:Create(bar.fill, BAR_TWEEN_INFO, {Size = UDim2.new(ratio, 0, 1, 0)}):Play()
    
    -- Health Dynamic Color (Green -> Yellow -> Red)
    if statName == "health" then
        local color = UITheme.Colors.Success
        if ratio < 0.3 then
            color = UITheme.Colors.Danger
            -- Pulse effect if critical
            if not StatusHUD.lowHealthTween then
                 StatusHUD.lowHealthTween = TweenService:Create(bar.container.Background, PULSE_TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(100, 0, 0)})
                 StatusHUD.lowHealthTween:Play()
            end
        elseif ratio < 0.6 then
            color = Color3.fromRGB(241, 196, 15) -- Gold/Yellow
            if StatusHUD.lowHealthTween then
                StatusHUD.lowHealthTween:Cancel()
                StatusHUD.lowHealthTween = nil
                bar.container.Background.BackgroundColor3 = UITheme.Colors.Surface
            end
        else
            if StatusHUD.lowHealthTween then
                StatusHUD.lowHealthTween:Cancel()
                StatusHUD.lowHealthTween = nil
                bar.container.Background.BackgroundColor3 = UITheme.Colors.Surface
            end
        end
        TweenService:Create(bar.fill, BAR_TWEEN_INFO, {BackgroundColor3 = color}):Play()
    end
end

function StatusHUD:show()
    if StatusHUD.screenGui then StatusHUD.screenGui.Enabled = true end
end

function StatusHUD:hide()
    if StatusHUD.screenGui then StatusHUD.screenGui.Enabled = false end
end

function StatusHUD.init()
    print("[StatusHUD] Initializing...")
    StatusHUD:create()
    StatusHUD:hide() -- Only show during match
    
    -- Listen for match start from MatchRemoteEvent
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        matchRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "MATCH_START" then
                StatusHUD:show()
            end
        end)
    end

    -- Listen for Lobby/Countdown events to show HUD early (during tube rise)
    local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemoteEvent", 5)
    if lobbyRemote then
        lobbyRemote.OnClientEvent:Connect(function(eventType, ...)
            if eventType == "COUNTDOWN_START" or eventType == "MATCH_STARTING" then
                StatusHUD:show()
            elseif eventType == "COUNTDOWN_CANCELLED" or eventType == "LOBBY_RETURN" then
                StatusHUD:hide()
            end
        end)
    else
        warn("[StatusHUD] LobbyRemoteEvent not found!")
    end
    
    -- Wait for StatsRemoteEvent
    local remote = ReplicatedStorage:WaitForChild("StatsRemoteEvent", 10)
    if not remote then
        warn("[StatusHUD] StatsRemoteEvent not found!")
        return 
    end
    
    remote.OnClientEvent:Connect(function(action, ...)
        local args = {...}
        
        if action == "INITIAL_STATS" then
            local stats = args[1]
            -- Store initial stats locally so we know max values
            StatusHUD.stats = stats
            
            StatusHUD:updateStat("health", stats.health, stats.maxHealth)
            StatusHUD:updateStat("hunger", stats.hunger, stats.maxHunger)
            StatusHUD:updateStat("thirst", stats.thirst, stats.maxThirst)
            
        elseif action == "STAT_UPDATE" then
            local statName, newValue = args[1], args[2]
            
            -- Update local state
            if StatusHUD.stats then
                StatusHUD.stats[statName] = newValue
            end
            
            -- Determine max value from stored state
            local maxVal = 100
            if StatusHUD.stats then
                if statName == "health" then maxVal = StatusHUD.stats.maxHealth
                elseif statName == "hunger" then maxVal = StatusHUD.stats.maxHunger
                elseif statName == "thirst" then maxVal = StatusHUD.stats.maxThirst
                end
            end
            
            StatusHUD:updateStat(statName, newValue, maxVal)
             
        elseif action == "STATUS_EFFECT_ADDED" then
            local name, duration, intensity = args[1], args[2], args[3]
            applyStatusEffectVisual(name, duration, intensity)
            
        elseif action == "STATUS_EFFECT_REMOVED" then
            local name = args[1]
            if StatusHUD.effectsContainer then
                local frame = StatusHUD.effectsContainer:FindFirstChild(name)
                if frame then frame:Destroy() end
            end
        end
    end)
    
    -- Request initial data in case we missed the join event
    remote:FireServer("REQUEST_STATS")
end

StatusHUD.init()
return StatusHUD
