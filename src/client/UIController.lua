-- LocalScript: UIController.lua
-- Controls HUD for health/hunger/thirst bars
-- Manages UI elements and real-time stat displays

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local StatsRemoteEvent = ReplicatedStorage:WaitForChild("StatsRemoteEvent", 10)
local LobbyRemoteEvent = ReplicatedStorage:WaitForChild("LobbyRemoteEvent", 10)

local UIController = {}
UIController.uiScreenGui = nil
UIController.healthBar = nil
UIController.hungerBar = nil
UIController.thirstBar = nil
UIController.countdownLabel = nil
UIController.statusText = nil
UIController.currentStats = {}
UIController.uiVisible = true

-- Create the UI elements
local function createUI()
    -- Create main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EmberGamesHUD"
    screenGui.Parent = PlayerGui
    
    -- Create frame for all stats
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(0, 250, 0, 180)
    statsFrame.Position = UDim2.new(0, 20, 0, 100)
    statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statsFrame.BackgroundTransparency = 0.5
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = screenGui
    
    -- Health bar
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthFrame"
    healthFrame.Size = UDim2.new(1, 0, 0, 30)
    healthFrame.Position = UDim2.new(0, 0, 0, 0)
    healthFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthFrame.BorderSizePixel = 0
    healthFrame.Parent = statsFrame
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(0, 60, 1, 0)
    healthLabel.Position = UDim2.new(0, 0, 0, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "HEALTH"
    healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.Parent = healthFrame
    
    local healthBarContainer = Instance.new("Frame")
    healthBarContainer.Name = "HealthBarContainer"
    healthBarContainer.Size = UDim2.new(1, -70, 0.6, 0)
    healthBarContainer.Position = UDim2.new(0, 70, 0, 6)
    healthBarContainer.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    healthBarContainer.BorderSizePixel = 0
    healthBarContainer.Parent = healthFrame
    
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarContainer
    
    -- Hunger bar
    local hungerFrame = healthFrame:Clone()
    hungerFrame.Name = "HungerFrame"
    hungerFrame.Position = UDim2.new(0, 0, 0, 40)
    hungerFrame.Parent = statsFrame
    
    local hungerLabel = hungerFrame.HealthLabel:Clone()
    hungerLabel.Text = "HUNGER"
    hungerLabel.Parent = hungerFrame
    
    local hungerBarContainer = hungerFrame.HealthBarContainer:Clone()
    hungerBarContainer.Parent = hungerFrame
    
    local hungerBar = Instance.new("Frame")
    hungerBar.Name = "HungerBar"
    hungerBar.Size = UDim2.new(1, 0, 1, 0)
    hungerBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50) -- Yellow/Orange
    hungerBar.BorderSizePixel = 0
    hungerBar.Parent = hungerBarContainer
    
    -- Thirst bar
    local thirstFrame = healthFrame:Clone()
    thirstFrame.Name = "ThirstFrame"
    thirstFrame.Position = UDim2.new(0, 0, 0, 80)
    thirstFrame.Parent = statsFrame
    
    local thirstLabel = thirstFrame.HealthLabel:Clone()
    thirstLabel.Text = "THIRST"
    thirstLabel.Parent = thirstFrame
    
    local thirstBarContainer = thirstFrame.HealthBarContainer:Clone()
    thirstBarContainer.Parent = thirstFrame
    
    local thirstBar = Instance.new("Frame")
    thirstBar.Name = "ThirstBar"
    thirstBar.Size = UDim2.new(1, 0, 1, 0)
    thirstBar.BackgroundColor3 = Color3.fromRGB(50, 150, 255) -- Blue
    thirstBar.BorderSizePixel = 0
    thirstBar.Parent = thirstBarContainer
    
    -- Status text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 0, 40)
    statusText.Position = UDim2.new(0, 0, 0, 120)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Survive the Games"
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.TextScaled = true
    statusText.Font = Enum.Font.Gotham
    statusText.Parent = statsFrame
    
    -- Countdown timer (initially hidden)
    local countdownFrame = Instance.new("Frame")
    countdownFrame.Name = "CountdownFrame"
    countdownFrame.Size = UDim2.new(0, 300, 0, 100)
    countdownFrame.Position = UDim2.new(0.5, -150, 0.1, 0)
    countdownFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    countdownFrame.BackgroundTransparency = 0.5
    countdownFrame.BorderSizePixel = 0
    countdownFrame.Visible = false
    countdownFrame.Parent = screenGui
    
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownLabel"
    countdownLabel.Size = UDim2.new(1, 0, 1, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "60"
    countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.Parent = countdownFrame
    
    -- Store references
    UIController.uiScreenGui = screenGui
    UIController.healthBar = healthBar
    UIController.hungerBar = hungerBar
    UIController.thirstBar = thirstBar
    UIController.countdownLabel = countdownLabel
    UIController.statusText = statusText
    
    return screenGui
end

-- Update a stat bar
local function updateStatBar(bar, value, maxValue)
    if bar and value and maxValue then
        local ratio = value / maxValue
        ratio = math.clamp(ratio, 0, 1)
        
        -- Tween the width
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(bar, tweenInfo, {Size = UDim2.new(ratio, 0, 1, 0)})
        tween:Play()
        
        -- Change color based on level
        if ratio > 0.5 then
            bar.BackgroundColor3 = bar.Name == "HealthBar" and Color3.fromRGB(255, 50, 50) or 
                                  bar.Name == "HungerBar" and Color3.fromRGB(255, 200, 50) or 
                                  Color3.fromRGB(50, 150, 255)
        elseif ratio > 0.25 then
            bar.BackgroundColor3 = Color3.fromRGB(255, 150, 50) -- Orange
        else
            bar.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red
        end
    end
end

-- Update UI with new stat values
function UIController:updateStats(statName, newValue, oldValue)
    if not UIController.currentStats then
        UIController.currentStats = {}
    end
    
    UIController.currentStats[statName] = newValue
    
    -- Update the appropriate bar
    if statName == "health" and UIController.healthBar then
        updateStatBar(UIController.healthBar, newValue, 100)
    elseif statName == "hunger" and UIController.hungerBar then
        updateStatBar(UIController.hungerBar, newValue, 100)
    elseif statName == "thirst" and UIController.thirstBar then
        updateStatBar(UIController.thirstBar, newValue, 100)
    end
    
    -- Update status text based on stats
    UIController:updateStatusText()
end

-- Update status text based on current stats
function UIController:updateStatusText()
    if not UIController.statusText then return end
    
    local health = UIController.currentStats.health or 100
    local hunger = UIController.currentStats.hunger or 100
    local thirst = UIController.currentStats.thirst or 100
    
    local status = ""
    
    if health < 25 then
        status = "Near Death - Find Health!"
    elseif hunger < 25 then
        status = "Starving - Find Food!"
    elseif thirst < 25 then
        status = "Dehydrated - Find Water!"
    elseif health < 50 then
        status = "Injured - Be Careful"
    elseif hunger < 50 then
        status = "Getting Hungry"
    elseif thirst < 50 then
        status = "Getting Thirsty"
    else
        status = "Survive the Games"
    end
    
    UIController.statusText.Text = status
end

-- Show/hide countdown UI
function UIController:showCountdown(visible, timeLeft)
    if UIController.uiScreenGui then
        local countdownFrame = UIController.uiScreenGui:FindFirstChild("CountdownFrame")
        if countdownFrame then
            countdownFrame.Visible = visible
            if visible and timeLeft and UIController.countdownLabel then
                UIController.countdownLabel.Text = tostring(math.ceil(timeLeft))
            end
        end
    end
end

-- Handle lobby status updates
function UIController:handleLobbyStatus(status)
    -- Update UI based on game state
    if status.gameState == "Countdown" then
        UIController:showCountdown(true, status.countdownTime)
    else
        UIController:showCountdown(false)
    end
end

-- Initialize UI controller
function UIController.init()
    print("UIController initialized")
    
    -- Create the UI
    createUI()
    
    -- Hide by default (show when match starts)
    if UIController.uiScreenGui then
        UIController.uiScreenGui.Enabled = false
        UIController.uiVisible = false
    end
    
    -- Connect to stats updates from server (if RemoteEvent exists)
    if StatsRemoteEvent then
        StatsRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "INITIAL_STATS" then
                local stats = args[1]
                UIController.currentStats = stats
                
                -- Update all bars with initial values
                if stats.health then
                    updateStatBar(UIController.healthBar, stats.health, stats.maxHealth or 100)
                end
                if stats.hunger then
                    updateStatBar(UIController.hungerBar, stats.hunger, stats.maxHunger or 100)
                end
                if stats.thirst then
                    updateStatBar(UIController.thirstBar, stats.thirst, stats.maxThirst or 100)
                end
                
                UIController:updateStatusText()
            elseif eventType == "STAT_UPDATE" then
                local statName, newValue, oldValue = args[1], args[2], args[3]
                UIController:updateStats(statName, newValue, oldValue)
            elseif eventType == "STATUS_EFFECT_ADDED" then
                local effectName = args[1]
                -- Maybe show status effect indicator
                print("Status effect applied: " .. effectName)
            elseif eventType == "PLAYER_ELIMINATED" then
                -- Handle elimination UI changes if this is the current player
                local eliminatedUserId, eliminatedName = args[1], args[2]
                if eliminatedUserId == Player.UserId then
                    -- This player was eliminated
                    UIController.statusText.Text = "ELIMINATED - Awaiting Tribute Ceremony"
                else
                    -- Another player was eliminated
                    UIController.statusText.Text = eliminatedName .. " eliminated! Tribute count: TBA"
                end
            end
        end)
    else
        warn("[UIController] StatsRemoteEvent not found - stats display may not work")
    end
    
    -- Connect to lobby updates (if RemoteEvent exists)
    if LobbyRemoteEvent then
        LobbyRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "COUNTDOWN_START" then
                local timeLeft = args[1]
                UIController:showCountdown(true, timeLeft)
                UIController.statusText.Text = "Countdown to Games Beginning!"
            elseif eventType == "COUNTDOWN_UPDATE" then
                local timeLeft = args[1]
                if UIController.countdownLabel then
                    UIController.countdownLabel.Text = tostring(timeLeft)
                end
            elseif eventType == "COUNTDOWN_CANCELLED" then
                UIController:showCountdown(false)
                UIController.statusText.Text = "Match Delayed - Tributes Gathering"
            elseif eventType == "MATCH_STARTING" then
                -- Show the HUD when match starts
                if UIController.uiScreenGui then
                    UIController.uiScreenGui.Enabled = true
                    UIController.uiVisible = true
                end
                UIController:showCountdown(true, 0)
                task.wait(1)
                UIController:showCountdown(false)
                UIController.statusText.Text = "THE GAMES HAVE BEGUN!"
            elseif eventType == "LOBBY_STATUS" then
                local status = args[1]
                UIController:handleLobbyStatus(status)
            elseif eventType == "ASSIGN_DISTRICT" then
                local districtNumber = args[1]
                UIController.statusText.Text = "You are District " .. districtNumber
            end
        end)
    else
        warn("[UIController] LobbyRemoteEvent not found - lobby updates may not work")
    end
    
    print("UIController initialized and connected to events")
end

-- Initialize the UI controller when the module is loaded
UIController.init()

return UIController