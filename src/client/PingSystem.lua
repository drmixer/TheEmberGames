-- LocalScript: PingSystem.lua
-- Allows players to mark locations for allies
-- Different ping types for communication

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Mouse = Player:GetMouse()

local PingSystem = {}
PingSystem.activePings = {}
PingSystem.lastPingTime = 0
PingSystem.pingCooldown = 2

local CONFIG = {
    PING_DURATION = 8,
    MAX_DISTANCE = 500,
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    PING_TYPES = {
        location = { icon = "📍", color = Color3.fromRGB(255, 255, 100), name = "Location" },
        enemy = { icon = "⚠️", color = Color3.fromRGB(255, 50, 50), name = "Enemy" },
        loot = { icon = "📦", color = Color3.fromRGB(100, 200, 255), name = "Loot" },
        danger = { icon = "☠️", color = Color3.fromRGB(200, 50, 200), name = "Danger" },
        going = { icon = "➡️", color = Color3.fromRGB(50, 200, 50), name = "Going Here" },
    },
}

local function playSound(id, vol)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = vol or 0.3
    s.Parent = PlayerGui
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

-- Create ping wheel UI
local function createPingWheel()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PingWheel"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local wheel = Instance.new("Frame")
    wheel.Name = "Wheel"
    wheel.Size = UDim2.new(0, 200, 0, 200)
    wheel.Position = UDim2.new(0.5, -100, 0.5, -100)
    wheel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    wheel.BackgroundTransparency = 0.3
    wheel.Visible = false
    wheel.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = wheel
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.ACCENT_COLOR
    stroke.Thickness = 2
    stroke.Parent = wheel
    
    -- Center label
    local centerLabel = Instance.new("TextLabel")
    centerLabel.Size = UDim2.new(0, 80, 0, 30)
    centerLabel.Position = UDim2.new(0.5, -40, 0.5, -15)
    centerLabel.BackgroundTransparency = 1
    centerLabel.Text = "PING"
    centerLabel.TextColor3 = CONFIG.ACCENT_COLOR
    centerLabel.TextSize = 16
    centerLabel.Font = Enum.Font.GothamBold
    centerLabel.Parent = wheel
    
    -- Create ping type buttons
    local types = {"location", "enemy", "loot", "danger", "going"}
    local angleStep = (math.pi * 2) / #types
    
    for i, pingType in ipairs(types) do
        local data = CONFIG.PING_TYPES[pingType]
        local angle = angleStep * (i - 1) - math.pi / 2
        local radius = 70
        
        local btn = Instance.new("TextButton")
        btn.Name = pingType
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.Position = UDim2.new(0.5, math.cos(angle) * radius - 25, 0.5, math.sin(angle) * radius - 25)
        btn.BackgroundColor3 = data.color
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.Text = data.icon
        btn.TextSize = 24
        btn.Parent = wheel
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0.5, 0)
        btnCorner.Parent = btn
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 55, 0, 55),
                Position = UDim2.new(0.5, math.cos(angle) * radius - 27.5, 0.5, math.sin(angle) * radius - 27.5)
            }):Play()
            centerLabel.Text = data.name:upper()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {
                BackgroundTransparency = 0.3,
                Size = UDim2.new(0, 50, 0, 50),
                Position = UDim2.new(0.5, math.cos(angle) * radius - 25, 0.5, math.sin(angle) * radius - 25)
            }):Play()
            centerLabel.Text = "PING"
        end)
        
        btn.MouseButton1Click:Connect(function()
            PingSystem:sendPing(pingType)
            PingSystem:hideWheel()
        end)
    end
    
    PingSystem.screenGui = screenGui
    PingSystem.wheel = wheel
end

-- Create 3D world ping marker
local function createWorldPing(position, pingType, playerName)
    local data = CONFIG.PING_TYPES[pingType] or CONFIG.PING_TYPES.location
    
    local part = Instance.new("Part")
    part.Name = "Ping_" .. playerName
    part.Size = Vector3.new(1, 1, 1)
    part.Position = position + Vector3.new(0, 2, 0)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = workspace
    
    -- Billboard GUI
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 60, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 1, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = billboard
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 0, 40)
    icon.BackgroundTransparency = 1
    icon.Text = data.icon
    icon.TextSize = 32
    icon.Parent = container
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, 40)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName
    nameLabel.TextColor3 = data.color
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = container
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "Distance"
    distLabel.Size = UDim2.new(1, 0, 0, 15)
    distLabel.Position = UDim2.new(0, 0, 0, 58)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    distLabel.TextSize = 10
    distLabel.Font = Enum.Font.Gotham
    distLabel.Parent = container
    
    -- Ground ring
    local ring = Instance.new("Part")
    ring.Size = Vector3.new(4, 0.1, 4)
    ring.Position = position
    ring.Anchored = true
    ring.CanCollide = false
    ring.Color = data.color
    ring.Material = Enum.Material.Neon
    ring.Transparency = 0.5
    ring.Parent = workspace
    
    local mesh = Instance.new("CylinderMesh")
    mesh.Parent = ring
    
    -- Animate ring
    task.spawn(function()
        local t = 0
        while ring.Parent do
            t = t + 0.05
            ring.Size = Vector3.new(3 + math.sin(t) * 0.5, 0.1, 3 + math.sin(t) * 0.5)
            ring.Transparency = 0.4 + math.sin(t) * 0.2
            task.wait(0.03)
        end
    end)
    
    -- Update distance
    task.spawn(function()
        while part.Parent do
            local char = Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local dist = (char.HumanoidRootPart.Position - position).Magnitude
                distLabel.Text = math.floor(dist) .. "m"
            end
            task.wait(0.5)
        end
    end)
    
    return { part = part, ring = ring, createdAt = tick() }
end

-- Show ping wheel
function PingSystem:showWheel()
    if PingSystem.wheel then
        PingSystem.wheel.Visible = true
        PingSystem.wheel.Size = UDim2.new(0, 0, 0, 0)
        PingSystem.wheel.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        TweenService:Create(PingSystem.wheel, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 200, 0, 200),
            Position = UDim2.new(0.5, -100, 0.5, -100)
        }):Play()
    end
end

-- Hide ping wheel
function PingSystem:hideWheel()
    if PingSystem.wheel then
        TweenService:Create(PingSystem.wheel, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        task.delay(0.15, function()
            PingSystem.wheel.Visible = false
        end)
    end
end

-- Send ping to server
function PingSystem:sendPing(pingType)
    local now = tick()
    if now - PingSystem.lastPingTime < PingSystem.pingCooldown then
        return -- Cooldown
    end
    
    -- Raycast to find ping location
    local camera = workspace.CurrentCamera
    local ray = camera:ViewportPointToRay(Mouse.X, Mouse.Y)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {Player.Character}
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * CONFIG.MAX_DISTANCE, raycastParams)
    
    if result then
        PingSystem.lastPingTime = now
        
        local position = result.Position
        
        -- Create local ping immediately
        local pingData = createWorldPing(position, pingType, Player.DisplayName)
        table.insert(PingSystem.activePings, pingData)
        
        -- Play sound
        playSound("rbxassetid://9046239626", 0.4)
        
        -- Send to server for allies
        local pingRemote = ReplicatedStorage:FindFirstChild("PingRemote")
        if pingRemote then
            pingRemote:FireServer("PING", {
                position = position,
                pingType = pingType
            })
        end
        
        -- Auto-remove after duration
        task.delay(CONFIG.PING_DURATION, function()
            if pingData.part then pingData.part:Destroy() end
            if pingData.ring then pingData.ring:Destroy() end
        end)
    end
end

-- Receive ping from ally
function PingSystem:receivePing(playerName, position, pingType)
    local pingData = createWorldPing(position, pingType, playerName)
    table.insert(PingSystem.activePings, pingData)
    
    playSound("rbxassetid://9046239626", 0.3)
    
    task.delay(CONFIG.PING_DURATION, function()
        if pingData.part then pingData.part:Destroy() end
        if pingData.ring then pingData.ring:Destroy() end
    end)
end

-- Initialize
function PingSystem.init()
    print("[PingSystem] Initializing...")
    
    createPingWheel()
    
    -- Create remote if needed
    local pingRemote = ReplicatedStorage:FindFirstChild("PingRemote")
    if not pingRemote then
        pingRemote = Instance.new("RemoteEvent")
        pingRemote.Name = "PingRemote"
        pingRemote.Parent = ReplicatedStorage
    end
    
    -- Listen for ally pings
    pingRemote.OnClientEvent:Connect(function(eventType, data)
        if eventType == "ALLY_PING" then
            PingSystem:receivePing(data.playerName, data.position, data.pingType)
        end
    end)
    
    -- Middle mouse or Z key to ping
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton3 or input.KeyCode == Enum.KeyCode.Z then
            PingSystem:showWheel()
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton3 or input.KeyCode == Enum.KeyCode.Z then
            PingSystem:hideWheel()
        end
    end)
    
    -- Quick ping with just click (location type)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.V then
            PingSystem:sendPing("location")
        end
    end)
    
    print("[PingSystem] Initialized! Middle mouse/Z for ping wheel, V for quick ping")
end

PingSystem.init()
return PingSystem
