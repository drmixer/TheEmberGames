-- LocalScript: VictoryUI.lua
-- Handles victory sequence display, elimination announcements, and match end UI
-- Creates dramatic, premium visual effects for winner announcement using UITheme

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local UITheme = require(script.Parent:WaitForChild("UITheme"))
local MatchRemoteEvent = ReplicatedStorage:WaitForChild("MatchRemoteEvent", 10)

local VictoryUI = {}
VictoryUI.screenGui = nil
VictoryUI.mainFrame = nil
VictoryUI.cleanupTasks = {}

local SOUND_IDS = {
    CANNON = "rbxassetid://1837108707",
    VICTORY_FANFARE = "rbxassetid://1837130432",
    DEFEAT_GONG = "rbxassetid://9046240113", -- Deep gong
    COUNTDOWN_BEEP = "rbxassetid://138084957",
    FIREWORK = "rbxassetid://130788893",
}

-- Create the base overlay
local function createScreenGui()
    if VictoryUI.screenGui then VictoryUI.screenGui:Destroy() end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VictoryUIScreen"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 100 -- Top layer
    screenGui.Parent = PlayerGui
    return screenGui
end

-- Premium Elimination Popup (Banner style from top)
function VictoryUI:showEliminationPopup(data)
    if not VictoryUI.screenGui then return end
    
    local banner = Instance.new("Frame")
    banner.Name = "DeathBanner"
    banner.Size = UDim2.new(0, 400, 0, 70)
    banner.Position = UDim2.new(0.5, 0, -0.2, 0) -- Start off screen
    banner.AnchorPoint = Vector2.new(0.5, 0)
    banner.BackgroundTransparency = 1
    banner.Parent = VictoryUI.screenGui
    
    -- Glass Background
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    UITheme.applyGlass(bg, 0.2)
    bg.BackgroundColor3 = UITheme.Colors.Danger -- Red tint for kills
    bg.BackgroundTransparency = 0.6
    bg.Parent = banner
    
    -- Skull Icon
    local icon = Instance.new("TextLabel")
    icon.Text = "💀"
    icon.Size = UDim2.new(0, 50, 1, 0)
    icon.BackgroundTransparency = 1
    icon.TextSize = 32
    icon.Parent = banner
    
    -- Text Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -60, 1, 0)
    content.Position = UDim2.new(0, 60, 0, 0)
    content.BackgroundTransparency = 1
    content.Parent = banner
    
    local title = Instance.new("TextLabel")
    title.Text = string.upper(data.playerName) .. " FALLEN"
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.Position = UDim2.new(0, 0, 0.1, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = UITheme.Colors.Text
    title.Font = UITheme.Fonts.Header
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = content
    
    local sub = Instance.new("TextLabel")
    sub.Text = data.remainingPlayers .. " TRIBUTES REMAIN"
    sub.Size = UDim2.new(1, 0, 0.4, 0)
    sub.Position = UDim2.new(0, 0, 0.5, 0)
    sub.BackgroundTransparency = 1
    sub.TextColor3 = UITheme.Colors.TextDim
    sub.Font = UITheme.Fonts.Label
    sub.TextSize = 14
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = content
    
    -- Animate In
    local sound = Instance.new("Sound", PlayerGui)
    sound.SoundId = SOUND_IDS.CANNON
    sound:Play()
    Debris:AddItem(sound, 3)
    
    local tweenIn = TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.1, 0) -- Top Center
    })
    tweenIn:Play()
    
    -- Animate Out
    task.delay(3.5, function()
         local tweenOut = TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, -0.2, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Connect(function() banner:Destroy() end)
    end)
end

-- Full Screen Victory/Defeat Display (Refined)
function VictoryUI:showVictorySequence(data)
    if not VictoryUI.screenGui then return end
    
    -- Clear any existing UI
    for _, child in pairs(VictoryUI.screenGui:GetChildren()) do
        child:Destroy() 
    end
    
    local isWinner = (data.winnerId == Player.UserId)
    
    if not isWinner then return end -- Only show big victory for winner? Assuming yes based on req. If not, text changes to ELIMINATED.
    
    -- Main Container
    local screen = Instance.new("Frame")
    screen.Size = UDim2.new(1, 0, 1, 0)
    screen.BackgroundTransparency = 1 
    screen.Parent = VictoryUI.screenGui
    
    -- Play fanfare
    local sound = Instance.new("Sound", PlayerGui)
    sound.SoundId = SOUND_IDS.VICTORY_FANFARE
    sound:Play()
    
    -- 1. BIG VICTORY TEXT
    local title = Instance.new("TextLabel")
    title.Text = "VICTORY"
    title.Size = UDim2.new(1, 0, 0, 150)
    title.Position = UDim2.new(0.5, 0, 0.4, 0)
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.BackgroundTransparency = 1
    title.TextColor3 = UITheme.Colors.Gold
    title.Font = UITheme.Fonts.Title
    title.TextSize = 100
    title.TextStrokeTransparency = 0.5
    title.TextStrokeColor3 = Color3.new(0,0,0)
    title.Parent = screen
    
    -- Animate Title Pop-in
    title.TextTransparency = 1
    title.TextSize = 150
    local tweenIn = TweenService:Create(title, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextTransparency = 0,
        TextSize = 100
    })
    tweenIn:Play()
    
    -- Flame/Ember Decoration (Visual only)
    -- Flame/Ember Decoration (Procedural - No Asset ID to fail)
    -- Using a Frame with UIGradient to simulate a fire glow
    local glowFrame = Instance.new("Frame")
    glowFrame.Size = UDim2.new(0, 500, 0, 500)
    glowFrame.Position = UDim2.new(0.5, 0, 0.4, 0)
    glowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    glowFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glowFrame.BackgroundTransparency = 0 -- Gradient will control transparency
    glowFrame.BorderSizePixel = 0
    glowFrame.ZIndex = 0
    glowFrame.Parent = screen
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)), -- Yellow Center
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 0)), -- Orange Middle
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 0, 0)) -- Red Edge
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0), -- Opaque center
        NumberSequenceKeypoint.new(0.6, 0.2),
        NumberSequenceKeypoint.new(1, 1) -- Transparent edges
    })
    gradient.Rotation = 45
    gradient.Parent = glowFrame
    
    -- Round mask
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) -- Circle
    corner.Parent = glowFrame
    
    -- Animate Pulse
    local tweenPulse = TweenService:Create(glowFrame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Size = UDim2.new(0, 600, 0, 600),
        BackgroundTransparency = 0.2
    })
    tweenPulse:Play()
    
    -- Rotate Gradient
    task.spawn(function()
        local rot = 0
        while glowFrame.Parent do
            rot = rot + 2
            gradient.Rotation = rot
            task.wait(0.05)
        end
    end)
    
    -- 2. Countdown Return Logic
    task.delay(4, function()
        if not screen or not screen.Parent then return end
        
        local returnLabel = Instance.new("TextLabel")
        returnLabel.Text = "Returning to main menu in 3..."
        returnLabel.Size = UDim2.new(1, 0, 0, 50)
        returnLabel.Position = UDim2.new(0, 0, 0.85, 0)
        returnLabel.BackgroundTransparency = 1
        returnLabel.TextColor3 = UITheme.Colors.Text
        returnLabel.Font = UITheme.Fonts.Header
        returnLabel.TextSize = 24
        returnLabel.TextTransparency = 1
        returnLabel.Parent = screen
        
        TweenService:Create(returnLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
        
        -- Countdown
        task.delay(1, function() returnLabel.Text = "Returning to main menu in 2..." end)
        task.delay(2, function() returnLabel.Text = "Returning to main menu in 1..." end)
        task.delay(3, function() returnLabel.Text = "Returning to main menu..." end)
    end)
end

-- Premium Countdown (Top Overlay)
function VictoryUI:showCountdownOverlay(seconds)
    if not VictoryUI.screenGui then return end
    
    local existing = VictoryUI.screenGui:FindFirstChild("CountdownFrame")
    if not existing then
        existing = Instance.new("Frame")
        existing.Name = "CountdownFrame"
        existing.Size = UDim2.new(1, 0, 1, 0)
        existing.BackgroundTransparency = 1
        existing.Parent = VictoryUI.screenGui
        
        -- Center Number
        local num = Instance.new("TextLabel")
        num.Name = "Number"
        num.Size = UDim2.new(0, 200, 0, 200)
        num.Position = UDim2.new(0.5, 0, 0.4, 0)
        num.AnchorPoint = Vector2.new(0.5, 0.5)
        num.BackgroundTransparency = 1
        num.Font = UITheme.Fonts.Title
        num.TextSize = 120
        num.TextColor3 = UITheme.Colors.Text
        num.Parent = existing
        
        local sub = Instance.new("TextLabel")
        sub.Text = "PREPARE FOR BATTLE"
        sub.Size = UDim2.new(1, 0, 0, 30)
        sub.Position = UDim2.new(0.5, 0, 0.5, 50)
        sub.AnchorPoint = Vector2.new(0.5, 0)
        sub.BackgroundTransparency = 1
        sub.Font = UITheme.Fonts.Header
        sub.TextColor3 = UITheme.Colors.Gold
        sub.TextSize = 24
        sub.Parent = existing
    end
    
    local label = existing:FindFirstChild("Number")
    if label then
        label.Text = tostring(seconds)
        -- Pulse
        label.TextTransparency = 0.5
        TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0, TextSize = 140}):Play()
        task.delay(0.5, function() label.TextSize = 120 end)
        
        if seconds <= 3 then
             label.TextColor3 = UITheme.Colors.Danger
             local sound = Instance.new("Sound", PlayerGui)
             sound.SoundId = SOUND_IDS.COUNTDOWN_BEEP
             sound:Play()
             Debris:AddItem(sound, 1)
        end
    end
end

function VictoryUI:hideCountdownOverlay()
    local existing = VictoryUI.screenGui and VictoryUI.screenGui:FindFirstChild("CountdownFrame")
    if existing then existing:Destroy() end
end

-- Spectator Mode Overlay (Bottom Bar)
function VictoryUI:showSpectatorUI(data)
    if not VictoryUI.screenGui then return end
    
    -- Clear old full-screen if player died and we are switching to spec UI
    -- We keep elimination popup, but remove other clutter
    
    local specBar = Instance.new("Frame")
    specBar.Name = "SpectatorBar"
    specBar.Size = UDim2.new(1, 0, 0, 80)
    specBar.Position = UDim2.new(0, 0, 1, -80)
    UITheme.applyGlass(specBar, 0.2)
    specBar.BackgroundColor3 = Color3.fromRGB(0,0,0)
    specBar.Parent = VictoryUI.screenGui
    
    local label = Instance.new("TextLabel")
    label.Text = "SPECTATING"
    label.Size = UDim2.new(0.2, 0, 1, 0)
    label.Position = UDim2.new(0, 20, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = UITheme.Colors.Danger
    label.Font = UITheme.Fonts.Header
    label.TextSize = 24
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = specBar
    
    -- Show their own stats
    local stats = Instance.new("TextLabel")
    stats.Text = "You placed #" .. (data.placement or "?")
    stats.Size = UDim2.new(0.3, 0, 1, 0)
    stats.Position = UDim2.new(0.8, 0, 0, 0)
    stats.BackgroundTransparency = 1
    stats.TextColor3 = UITheme.Colors.TextDim
    stats.Font = UITheme.Fonts.Body
    stats.TextSize = 18
    stats.Parent = specBar
end

function VictoryUI.init()
    print("[VictoryUI] Initializing Premium Victory System")
    VictoryUI.screenGui = createScreenGui()
    
    if MatchRemoteEvent then
        MatchRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            if eventType == "PLAYER_ELIMINATED" then
                VictoryUI:showEliminationPopup(args[1])
            elseif eventType == "VICTORY_SEQUENCE" then
                VictoryUI:showVictorySequence(args[1])
            elseif eventType == "ENTER_SPECTATOR_MODE" then
                VictoryUI:showSpectatorUI(args[1])
            elseif eventType == "COUNTDOWN_BEEP" then
                VictoryUI:showCountdownOverlay(args[1])
            elseif eventType == "MATCH_START_HORN" then
                VictoryUI:hideCountdownOverlay()
            elseif eventType == "RETURN_TO_LOBBY" then
                if VictoryUI.screenGui then
                    for _, child in pairs(VictoryUI.screenGui:GetChildren()) do
                        child:Destroy()
                    end
                end
            end
        end)
    end
end

VictoryUI.init()
return VictoryUI
