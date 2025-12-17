-- LocalScript: NotificationManager.lua
-- Unified notification system for all game events

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local NotificationManager = {}
NotificationManager.queue = {}
NotificationManager.activeNotifications = {}
NotificationManager.maxVisible = 4

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    SUCCESS_COLOR = Color3.fromRGB(50, 200, 50),
    WARNING_COLOR = Color3.fromRGB(255, 200, 50),
    DANGER_COLOR = Color3.fromRGB(200, 50, 50),
    INFO_COLOR = Color3.fromRGB(100, 150, 255),
    DURATION = 4,
}

local ICONS = {
    achievement = "🏆", challenge = "📋", level_up = "⬆️",
    item = "📦", warning = "⚠️", zone = "🌀",
    alliance = "🤝", elimination = "💀", info = "ℹ️",
}

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationManager"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 320, 0, 400)
    container.Position = UDim2.new(1, -330, 0.5, -200)
    container.BackgroundTransparency = 1
    container.Parent = screenGui
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Parent = container
    
    NotificationManager.screenGui = screenGui
    NotificationManager.container = container
end

local function createNotification(data)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 60)
    notif.BackgroundColor3 = CONFIG.BG_COLOR
    notif.BackgroundTransparency = 0.2
    notif.BorderSizePixel = 0
    notif.Parent = NotificationManager.container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif
    
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.BackgroundColor3 = data.color or CONFIG.ACCENT_COLOR
    accent.BorderSizePixel = 0
    accent.Parent = notif
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, 12, 0.5, -15)
    icon.BackgroundTransparency = 1
    icon.Text = ICONS[data.type] or "📢"
    icon.TextSize = 20
    icon.Parent = notif
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 20)
    title.Position = UDim2.new(0, 50, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = data.title or "Notification"
    title.TextColor3 = data.color or CONFIG.ACCENT_COLOR
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notif
    
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, -60, 0, 30)
    message.Position = UDim2.new(0, 50, 0, 26)
    message.BackgroundTransparency = 1
    message.Text = data.message or ""
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.TextSize = 12
    message.Font = Enum.Font.Gotham
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = true
    message.Parent = notif
    
    -- Animate in
    notif.Position = UDim2.new(1, 50, 0, 0)
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    -- Auto remove
    task.delay(data.duration or CONFIG.DURATION, function()
        TweenService:Create(notif, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 50, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.3, function()
            notif:Destroy()
        end)
    end)
    
    return notif
end

function NotificationManager:notify(data)
    createNotification(data)
end

function NotificationManager:success(title, msg)
    self:notify({ type = "achievement", title = title, message = msg, color = CONFIG.SUCCESS_COLOR })
end

function NotificationManager:warning(title, msg)
    self:notify({ type = "warning", title = title, message = msg, color = CONFIG.WARNING_COLOR })
end

function NotificationManager:danger(title, msg)
    self:notify({ type = "zone", title = title, message = msg, color = CONFIG.DANGER_COLOR })
end

function NotificationManager:info(title, msg)
    self:notify({ type = "info", title = title, message = msg, color = CONFIG.INFO_COLOR })
end

function NotificationManager.init()
    print("[NotificationManager] Initializing...")
    createUI()
    
    local remote = ReplicatedStorage:FindFirstChild("NotificationRemote")
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = "NotificationRemote"
        remote.Parent = ReplicatedStorage
    end
    
    remote.OnClientEvent:Connect(function(data)
        NotificationManager:notify(data)
    end)
    
    print("[NotificationManager] Initialized!")
end

NotificationManager.init()
return NotificationManager
