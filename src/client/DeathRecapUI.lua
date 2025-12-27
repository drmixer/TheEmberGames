-- LocalScript: DeathRecapUI.lua
-- "Game Over" screen with stats and spectate options

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Import our Theme
local UITheme = require(script.Parent:WaitForChild("UITheme"))

local DeathRecapUI = {}
DeathRecapUI.screenGui = nil
DeathRecapUI.blur = nil

-- Create the UI
local function createUI()
    if DeathRecapUI.screenGui then DeathRecapUI.screenGui:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DeathRecapUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Enabled = false
    screenGui.Parent = PlayerGui
    
    -- Blur Effect (initially disabled)
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = game:GetService("Lighting")
    DeathRecapUI.blur = blur
    
    -- Main Container (Full Screen)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = Color3.new(0, 0, 0)
    container.BackgroundTransparency = 1 -- Start transparent
    container.Parent = screenGui
    
    -- "ELIMINATED" Text
    local title = Instance.new("TextLabel")
    title.Text = "ELIMINATED"
    title.Font = UITheme.Fonts.Title
    title.TextSize = 80
    title.TextColor3 = Color3.fromRGB(255, 50, 50)
    title.Size = UDim2.new(1, 0, 0, 100)
    title.Position = UDim2.new(0, 0, 0.2, 0)
    title.BackgroundTransparency = 1
    title.TextTransparency = 1
    title.Parent = container
    
    -- Stats Card
    local statsCard = Instance.new("Frame")
    statsCard.Size = UDim2.new(0, 500, 0, 300)
    statsCard.Position = UDim2.new(0.5, -250, 0.4, 0)
    UITheme.applyGlass(statsCard, 0.3)
    statsCard.BackgroundTransparency = 1 -- Start hidden
    statsCard.Parent = container
    
    -- Placement Badge
    local placeLabel = Instance.new("TextLabel")
    placeLabel.Name = "Placement"
    placeLabel.Text = "#12"
    placeLabel.Font = UITheme.Fonts.Header
    placeLabel.TextSize = 60
    placeLabel.TextColor3 = UITheme.Colors.Gold
    placeLabel.Size = UDim2.new(1, 0, 0, 80)
    placeLabel.BackgroundTransparency = 1
    placeLabel.Parent = statsCard
    
    local placeSub = Instance.new("TextLabel")
    placeSub.Text = "PLACEMENT"
    placeSub.Font = UITheme.Fonts.Label
    placeSub.TextSize = 14
    placeSub.TextColor3 = UITheme.Colors.TextDim
    placeSub.Size = UDim2.new(1, 0, 0, 20)
    placeSub.Position = UDim2.new(0, 0, 0, 65)
    placeSub.BackgroundTransparency = 1
    placeSub.Parent = statsCard
    
    -- Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0.8, 0, 0, 1)
    divider.Position = UDim2.new(0.1, 0, 0, 100)
    divider.BackgroundColor3 = UITheme.Colors.TextDim
    divider.BackgroundTransparency = 0.5
    divider.BorderSizePixel = 0
    divider.Parent = statsCard
    
    -- Details List
    local details = Instance.new("Frame")
    details.Size = UDim2.new(1, -60, 0, 150)
    details.Position = UDim2.new(0, 30, 0, 120)
    details.BackgroundTransparency = 1
    details.Parent = statsCard
    
    local function createStatRow(y, label, valName)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.Position = UDim2.new(0, 0, 0, y)
        row.BackgroundTransparency = 1
        row.Parent = details
        
        local l = Instance.new("TextLabel")
        l.Text = label
        l.Font = UITheme.Fonts.Body
        l.TextSize = 18
        l.TextColor3 = UITheme.Colors.TextDim
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Size = UDim2.new(0.5, 0, 1, 0)
        l.BackgroundTransparency = 1
        l.Parent = row
        
        local v = Instance.new("TextLabel")
        v.Name = valName
        v.Text = "--"
        v.Font = UITheme.Fonts.Bold
        v.TextSize = 18
        v.TextColor3 = UITheme.Colors.Text
        v.TextXAlignment = Enum.TextXAlignment.Right
        v.Size = UDim2.new(0.5, 0, 1, 0)
        v.Position = UDim2.new(0.5, 0, 0, 0)
        v.BackgroundTransparency = 1
        v.Parent = row
    end
    
    createStatRow(0, "Eliminated By", "KillerName")
    createStatRow(40, "Time Survived", "SurvivalTime")
    createStatRow(80, "Your Kills", "Kills")
    
    -- Buttons
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, 0, 0, 60)
    btnContainer.Position = UDim2.new(0, 0, 1, 20) -- Below card
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = statsCard
    
    local spectateBtn = UITheme.createButton({
        Text = "SPECTATE",
        Size = UDim2.new(0.45, 0, 1, 0),
        OnClick = function()
            -- Switch to spectate mode
            DeathRecapUI:hide()
            local specMode = require(script.Parent:WaitForChild("SpectatorMode"))
            specMode:enable()
        end
    })
    spectateBtn.Position = UDim2.new(0, 0, 0, 0)
    spectateBtn.Parent = btnContainer
    
    local lobbyBtn = UITheme.createButton({
        Text = "RETURN TO LOBBY",
        Size = UDim2.new(0.45, 0, 1, 0),
        OnClick = function()
            -- Ask server to return to lobby (or just wait for match end)
            -- For now, just spectate is fine, or re-join queue?
            -- Usually this button quits the match in a BR. 
            -- Here we'll just hide and maybe show a "Exit Match" prompt
            game:Shutdown() -- Drastic, but for testing. In real game, teleport to lobby place.
        end
    })
    lobbyBtn.Position = UDim2.new(0.55, 0, 0, 0)
    
    -- Override color for lobby btn (secondary action)
    local lobbyStroke = lobbyBtn:FindFirstChild("UIStroke")
    if lobbyStroke then lobbyStroke.Color = Color3.fromRGB(100, 100, 100) end
    lobbyBtn.Parent = btnContainer
    
    DeathRecapUI.screenGui = screenGui
    DeathRecapUI.container = container
    DeathRecapUI.statsCard = statsCard
    DeathRecapUI.title = title
    
    return screenGui
end

function DeathRecapUI:show(data)
    if not DeathRecapUI.screenGui then createUI() end
    
    -- data = { placement, killerName, survivalTime, kills }
    
    -- Update stats
    local statsCard = DeathRecapUI.statsCard
    statsCard.Placement.Text = "#" .. tostring(data.placement or "?")
    
    local details = statsCard:FindFirstChild("Frame") -- Details frame
    if details then
        local frames = details:GetChildren()
        
        -- Helper to find dynamic update labels
        local function setText(name, text)
            for _, row in pairs(frames) do
                local label = row:FindFirstChild(name)
                if label then label.Text = text end
            end
        end
        
        setText("KillerName", data.killerName or "Environment")
        
        -- Format time
        local seconds = data.survivalTime or 0
        local mins = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        setText("SurvivalTime", string.format("%d:%02d", mins, secs))
        
        setText("Kills", tostring(data.kills or 0))
    end
    
    -- Enable Screen
    DeathRecapUI.screenGui.Enabled = true
    
    -- Animate In
    -- 1. Red Flash
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.new(0.8, 0, 0)
    flash.BackgroundTransparency = 0.5
    flash.Parent = DeathRecapUI.screenGui
    TweenService:Create(flash, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    game:GetService("Debris"):AddItem(flash, 0.5)
    
    -- 2. Fade in Blur
    TweenService:Create(DeathRecapUI.blur, TweenInfo.new(1), {Size = 24}):Play()
    
    -- 3. Fade in Background
    TweenService:Create(DeathRecapUI.container, TweenInfo.new(1), {BackgroundTransparency = 0.3}):Play()
    
    -- 4. Text Slam
    DeathRecapUI.title.TextTransparency = 0
    DeathRecapUI.title.Position = UDim2.new(0, 0, 0, 0) -- Higher up
    DeathRecapUI.title.Size = UDim2.new(1, 0, 0.4, 0) -- Big
    
    local slamGoal = {
        Size = UDim2.new(1, 0, 0, 100),
        Position = UDim2.new(0, 0, 0.2, 0),
        TextTransparency = 0
    }
    local slamTween = TweenService:Create(DeathRecapUI.title, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), slamGoal)
    slamTween:Play()
    
    -- 5. Show Card after delay
    task.delay(1, function()
        DeathRecapUI.statsCard.Position = UDim2.new(0.5, -250, 0.5, 0) -- Start lower
        DeathRecapUI.statsCard.BackgroundTransparency = 1
        
        local cardTween = TweenService:Create(DeathRecapUI.statsCard, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -250, 0.4, 0),
            BackgroundTransparency = 0 -- Theme glass effect handles actual transparency, this is just for container
        })
        cardTween:Play()
        
        -- Ensure buttons are visible
    end)
end

function DeathRecapUI:hide()
    if DeathRecapUI.screenGui then
        DeathRecapUI.screenGui.Enabled = false
        if DeathRecapUI.blur then DeathRecapUI.blur.Size = 0 end
    end
end

function DeathRecapUI.init()
    print("[DeathRecapUI] Initializing...")
    createUI()
    
    -- Listen for elimination event
    local MatchRemoteEvent = ReplicatedStorage:WaitForChild("MatchRemoteEvent", 10)
    if MatchRemoteEvent then
        MatchRemoteEvent.OnClientEvent:Connect(function(eventType, data)
            if eventType == "ENTER_SPECTATOR_MODE" then
                -- data contains { placement, survivalTime, kills }
                -- Need killer name? Passed in distinct event?
                -- Usually we get PLAYER_ELIMINATED too.
                
                -- Let's merge data or wait for explicit call?
                -- Ideally MatchService sends a "SHOW_DEATH_SCREEN"
                
                DeathRecapUI:show({
                    placement = data.placement,
                    survivalTime = data.survivalTime,
                    kills = data.kills,
                    killerName = data.killerName or "Unknown" -- Might need to be added to payload server-side
                })
            end
        end)
    end
end

DeathRecapUI.init()
return DeathRecapUI
