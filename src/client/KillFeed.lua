-- LocalScript: KillFeed.lua
-- Real-time elimination notifications
-- Shows who eliminated whom with weapon information

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local KillFeed = {}
KillFeed.screenGui = nil
KillFeed.feedContainer = nil
KillFeed.maxItems = 6
KillFeed.items = {}

-- Configuration
local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55), -- Gold
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    YOUR_KILL_COLOR = Color3.fromRGB(255, 215, 0), -- Bright gold for your kills
    ALLY_KILL_COLOR = Color3.fromRGB(50, 200, 50), -- Green for ally kills
    BETRAYAL_COLOR = Color3.fromRGB(200, 50, 50), -- Red for betrayals
    DEATH_COLOR = Color3.fromRGB(150, 50, 50), -- Red when you die
    DEFAULT_COLOR = Color3.fromRGB(255, 255, 255), -- White for other kills
    FADE_TIME = 5, -- Seconds before fading
    ITEM_HEIGHT = 28,
}

-- Weapon icons
local WEAPON_ICONS = {
    sword = "⚔️",
    spear = "🔱",
    knife = "🗡️",
    axe = "🪓",
    bow = "🏹",
    slingshot = "🎯",
    throwing_knife = "🗡️",
    trap = "⚠️",
    fire_trap = "🔥",
    poison = "☠️",
    fall = "💨",
    zone = "🌀",
    unknown = "💀",
}

-- Play sound
local function playSound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.3
    sound.Parent = PlayerGui
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

-- Create the kill feed UI
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KillFeed"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Container for feed items (top right)
    local feedContainer = Instance.new("Frame")
    feedContainer.Name = "FeedContainer"
    feedContainer.Size = UDim2.new(0, 280, 0, 200)
    feedContainer.Position = UDim2.new(1, -290, 0, 100)
    feedContainer.BackgroundTransparency = 1
    feedContainer.Parent = screenGui
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = feedContainer
    
    KillFeed.screenGui = screenGui
    KillFeed.feedContainer = feedContainer
    
    return screenGui
end

-- Create a kill feed item
local function createFeedItem(killerName, victimName, weaponType, isYourKill, isYourDeath, isAllyKill, isBetrayal)
    local item = Instance.new("Frame")
    item.Name = "FeedItem"
    item.Size = UDim2.new(0, 280, 0, CONFIG.ITEM_HEIGHT)
    item.BackgroundColor3 = CONFIG.BG_COLOR
    item.BackgroundTransparency = 0.4
    item.BorderSizePixel = 0
    item.LayoutOrder = tick() * 1000 -- Ensures newest at top
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = item
    
    -- Determine colors
    local killerColor = CONFIG.DEFAULT_COLOR
    local victimColor = CONFIG.DEFAULT_COLOR
    local bgHighlight = false
    
    if isBetrayal then
        killerColor = CONFIG.BETRAYAL_COLOR
        bgHighlight = true
        item.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
    elseif isYourKill then
        killerColor = CONFIG.YOUR_KILL_COLOR
        bgHighlight = true
        item.BackgroundColor3 = Color3.fromRGB(40, 40, 20)
    elseif isYourDeath then
        victimColor = CONFIG.DEATH_COLOR
        bgHighlight = true
        item.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
    elseif isAllyKill then
        killerColor = CONFIG.ALLY_KILL_COLOR
    end
    
    -- Left accent bar
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 1, 0)
    accentBar.BackgroundColor3 = killerColor
    accentBar.BorderSizePixel = 0
    accentBar.Parent = item
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 3)
    accentCorner.Parent = accentBar
    
    -- Weapon icon
    local weaponIcon = Instance.new("TextLabel")
    weaponIcon.Name = "WeaponIcon"
    weaponIcon.Size = UDim2.new(0, 24, 0, 24)
    weaponIcon.Position = UDim2.new(0, 8, 0.5, -12)
    weaponIcon.BackgroundTransparency = 1
    weaponIcon.Text = WEAPON_ICONS[weaponType] or WEAPON_ICONS.unknown
    weaponIcon.TextSize = 16
    weaponIcon.Parent = item
    
    -- Kill message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -40, 1, 0)
    message.Position = UDim2.new(0, 35, 0, 0)
    message.BackgroundTransparency = 1
    message.TextSize = 12
    message.Font = Enum.Font.Gotham
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.RichText = true
    message.Parent = item
    
    -- Build rich text message
    local killerHex = string.format("#%02X%02X%02X", 
        math.floor(killerColor.R * 255), 
        math.floor(killerColor.G * 255), 
        math.floor(killerColor.B * 255))
    local victimHex = string.format("#%02X%02X%02X",
        math.floor(victimColor.R * 255),
        math.floor(victimColor.G * 255),
        math.floor(victimColor.B * 255))
    
    local messageText = string.format(
        '<font color="%s"><b>%s</b></font> eliminated <font color="%s"><b>%s</b></font>',
        killerHex, killerName,
        victimHex, victimName
    )
    
    if isBetrayal then
        messageText = messageText .. ' <font color="#FF5555">[BETRAYAL]</font>'
    end
    
    message.Text = messageText
    
    return item
end

-- Add a kill to the feed
function KillFeed:addKill(killerName, victimName, weaponType, isBetrayal)
    local isYourKill = killerName == Player.Name
    local isYourDeath = victimName == Player.Name
    local isAllyKill = false -- TODO: Check alliance
    
    local item = createFeedItem(killerName, victimName, weaponType, isYourKill, isYourDeath, isAllyKill, isBetrayal)
    item.Parent = KillFeed.feedContainer
    
    -- Animate in
    item.Position = UDim2.new(0, 50, 0, 0)
    item.BackgroundTransparency = 1
    
    TweenService:Create(item, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.4
    }):Play()
    
    -- Play sound
    if isYourKill then
        playSound("rbxassetid://9046240113", 0.4) -- Victory sound
    elseif isYourDeath then
        playSound("rbxassetid://5034047634", 0.3) -- Cannon sound
    else
        playSound("rbxassetid://4590662766", 0.5) -- Verified UI Click
    end
    
    -- Track items
    table.insert(KillFeed.items, {
        frame = item,
        createdAt = tick()
    })
    
    -- Remove excess items
    while #KillFeed.items > KillFeed.maxItems do
        local oldItem = table.remove(KillFeed.items, 1)
        if oldItem.frame then
            oldItem.frame:Destroy()
        end
    end
    
    -- Schedule fade out
    task.delay(CONFIG.FADE_TIME, function()
        if item and item.Parent then
            TweenService:Create(item, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, -50, 0, 0)
            }):Play()
            
            task.delay(0.5, function()
                if item and item.Parent then
                    item:Destroy()
                end
            end)
        end
    end)
end

-- Add special announcements
function KillFeed:addAnnouncement(text, color)
    local item = Instance.new("Frame")
    item.Name = "Announcement"
    item.Size = UDim2.new(0, 280, 0, CONFIG.ITEM_HEIGHT)
    item.BackgroundColor3 = color or CONFIG.ACCENT_COLOR
    item.BackgroundTransparency = 0.3
    item.BorderSizePixel = 0
    item.LayoutOrder = tick() * 1000
    item.Parent = KillFeed.feedContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = item
    
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, -10, 1, 0)
    message.Position = UDim2.new(0, 5, 0, 0)
    message.BackgroundTransparency = 1
    message.Text = "📢 " .. text
    message.TextColor3 = Color3.fromRGB(255, 255, 255)
    message.TextSize = 12
    message.Font = Enum.Font.GothamBold
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.Parent = item
    
    -- Animate in
    item.Position = UDim2.new(0, 50, 0, 0)
    TweenService:Create(item, TweenInfo.new(0.3), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    -- Fade out
    task.delay(CONFIG.FADE_TIME + 2, function()
        if item and item.Parent then
            TweenService:Create(item, TweenInfo.new(0.5), {
                BackgroundTransparency = 1
            }):Play()
            task.delay(0.5, function()
                if item.Parent then item:Destroy() end
            end)
        end
    end)
end

-- Clear all items
function KillFeed:clear()
    for _, item in ipairs(KillFeed.items) do
        if item.frame then
            item.frame:Destroy()
        end
    end
    KillFeed.items = {}
end

-- Initialize
function KillFeed.init()
    print("[KillFeed] Initializing...")
    
    createUI()
    
    -- Connect to remote events
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        matchRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "TRIBUTE_ELIMINATED" then
                KillFeed:addKill(
                    data.killerName or "The Arena",
                    data.victimName or "A Tribute",
                    data.weaponType or "unknown",
                    data.isBetrayal or false
                )
            elseif eventType == "ANNOUNCEMENT" then
                KillFeed:addAnnouncement(data.text, data.color)
            elseif eventType == "MATCH_START" then
                KillFeed:clear()
            end
        end)
    end
    
    -- Create remote if doesn't exist (for testing)
    if not matchRemote then
        matchRemote = Instance.new("RemoteEvent")
        matchRemote.Name = "MatchRemoteEvent"
        matchRemote.Parent = ReplicatedStorage
    end
    
    print("[KillFeed] Initialized successfully!")
end

-- Initialize when module loads
KillFeed.init()

return KillFeed
