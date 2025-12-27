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

-- Full Screen Victory/Defeat Display
function VictoryUI:showVictorySequence(data)
    if not VictoryUI.screenGui then return end
    
    local isWinner = (data.winnerId == Player.UserId)
    local mainColor = isWinner and UITheme.Colors.Gold or UITheme.Colors.Danger
    local titleText = isWinner and "VICTORY" or "ELIMINATED"
    
    -- Main Container (Fade In)
    local screen = Instance.new("Frame")
    screen.Size = UDim2.new(1, 0, 1, 0)
    screen.BackgroundColor3 = Color3.new(0,0,0)
    screen.BackgroundTransparency = 1 -- Start transparent
    screen.Parent = VictoryUI.screenGui
    
    -- Animate background darkness
    TweenService:Create(screen, TweenInfo.new(1), {BackgroundTransparency = 0.3}):Play()
    
    -- Center Emphasis Strip (Cinematic Letterbox Style)
    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(1, 0, 0, 200)
    strip.Position = UDim2.new(0, 0, 0.5, 0)
    strip.AnchorPoint = Vector2.new(0, 0.5)
    UITheme.applyGlass(strip, 0.1) -- Very dark glass
    strip.BackgroundColor3 = mainColor
    strip.BackgroundTransparency = 0.8
    strip.Parent = screen
    
    -- Big Title
    local title = Instance.new("TextLabel")
    title.Text = titleText
    title.Size = UDim2.new(1, 0, 0, 80)
    title.Position = UDim2.new(0, 0, 0.5, -40)
    title.AnchorPoint = Vector2.new(0, 0.5)
    title.BackgroundTransparency = 1
    title.TextColor3 = mainColor
    title.Font = UITheme.Fonts.Title
    title.TextSize = 80
    title.Parent = strip
    
    -- Winner Name (if checking someone else win)
    if not isWinner then
        local sub = Instance.new("TextLabel")
        sub.Text = "Winner: " .. (data.winner or "Unknown")
        sub.Size = UDim2.new(1, 0, 0, 30)
        sub.Position = UDim2.new(0, 0, 0.8, 0)
        sub.BackgroundTransparency = 1
        sub.TextColor3 = UITheme.Colors.Text
        sub.Font = UITheme.Fonts.Label
        sub.TextSize = 24
        sub.Parent = strip
    else
        -- Confetti for winner
        local sub = Instance.new("TextLabel")
        sub.Text = "THE ARENA IS YOURS"
        sub.Size = UDim2.new(1, 0, 0, 30)
        sub.Position = UDim2.new(0, 0, 0.8, 0)
        sub.BackgroundTransparency = 1
        sub.TextColor3 = UITheme.Colors.GoldHighlight
        sub.Font = UITheme.Fonts.Label
        sub.TextSize = 18
        sub.LetterSpacing = 3
        sub.Parent = strip
        
        -- Play fanfare
        local sound = Instance.new("Sound", PlayerGui)
        sound.SoundId = SOUND_IDS.VICTORY_FANFARE
        sound:Play()
    end
    
    -- Stats Row (Bottom)
    local statsRow = Instance.new("Frame")
    statsRow.Size = UDim2.new(0, 600, 0, 60)
    statsRow.Position = UDim2.new(0.5, 0, 0.7, 0) -- Below strip
    statsRow.AnchorPoint = Vector2.new(0.5, 0)
    statsRow.BackgroundTransparency = 1
    statsRow.Parent = screen
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 20)
    layout.Parent = statsRow
    
    -- Helper to create stat pill
    local function makeStat(label, value)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 150, 1, 0)
        UITheme.applyGlass(frame, 0.4)
        frame.Parent = statsRow
        
        local l = Instance.new("TextLabel")
        l.Text = label
        l.Size = UDim2.new(1, 0, 0.4, 0)
        l.BackgroundTransparency = 1
        l.TextColor3 = UITheme.Colors.TextDim
        l.Font = UITheme.Fonts.Label
        l.TextSize = 12
        l.Parent = frame
        
        local v = Instance.new("TextLabel")
        v.Text = value
        v.Size = UDim2.new(1, 0, 0.6, 0)
        v.Position = UDim2.new(0,0,0.4,0)
        v.BackgroundTransparency = 1
        v.TextColor3 = UITheme.Colors.Text
        v.Font = UITheme.Fonts.Header
        v.TextSize = 22
        v.Parent = frame
    end
    
    makeStat("ELIMINATIONS", tostring(data.kills or 0))
    makeStat("TIME SURVIVED", string.format("%d:%02d", math.floor((data.matchDuration or 0)/60), (data.matchDuration or 0)%60))
    makeStat("PLACEMENT", "#" .. (data.placement or "1"))
    
    -- Return Button (Bottom Center)
    local btn = UITheme.createButton({
        Text = "RETURN TO LOBBY",
        Size = UDim2.new(0, 250, 0, 50),
        Position = UDim2.new(0.5, -125, 0.85, 0),
        OnClick = function()
            -- logic handled by server kick or client request usually
            print("Requesting Lobby Return") 
        end
    })
    btn.Parent = screen
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
            end
        end)
    end
end

VictoryUI.init()
return VictoryUI
