-- LocalScript: Compass.lua
-- Navigation compass showing cardinal directions and objectives

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Compass = {}
Compass.markers = {}
Compass.objectives = {}

local CONFIG = {
    BAR_WIDTH = 400,
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
}

local CARDINALS = {
    { angle = 0, label = "N", isMajor = true },
    { angle = 45, label = "NE" }, { angle = 90, label = "E" },
    { angle = 135, label = "SE" }, { angle = 180, label = "S" },
    { angle = 225, label = "SW" }, { angle = 270, label = "W" },
    { angle = 315, label = "NW" },
}

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Compass"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, CONFIG.BAR_WIDTH, 0, 30)
    container.Position = UDim2.new(0.5, -200, 0, 95)
    container.BackgroundColor3 = CONFIG.BG_COLOR
    container.BackgroundTransparency = 0.4
    container.ClipsDescendants = true
    container.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container
    
    local center = Instance.new("Frame")
    center.Size = UDim2.new(0, 2, 1, 0)
    center.Position = UDim2.new(0.5, -1, 0, 0)
    center.BackgroundColor3 = CONFIG.ACCENT_COLOR
    center.ZIndex = 10
    center.Parent = container
    
    local degreeLabel = Instance.new("TextLabel")
    degreeLabel.Name = "Degrees"
    degreeLabel.Size = UDim2.new(0, 40, 0, 12)
    degreeLabel.Position = UDim2.new(0.5, -20, 1, 2)
    degreeLabel.BackgroundTransparency = 1
    degreeLabel.Text = "0°"
    degreeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    degreeLabel.TextSize = 10
    degreeLabel.Font = Enum.Font.Gotham
    degreeLabel.Parent = screenGui
    
    local markersFrame = Instance.new("Frame")
    markersFrame.Name = "Markers"
    markersFrame.Size = UDim2.new(3, 0, 1, 0)
    markersFrame.BackgroundTransparency = 1
    markersFrame.Parent = container
    
    for _, c in ipairs(CARDINALS) do
        local m = Instance.new("TextLabel")
        m.Name = c.label
        m.Size = UDim2.new(0, 30, 1, 0)
        m.BackgroundTransparency = 1
        m.Text = c.label
        m.TextColor3 = c.isMajor and CONFIG.ACCENT_COLOR or Color3.new(1,1,1)
        m.TextSize = c.isMajor and 14 or 11
        m.Font = c.isMajor and Enum.Font.GothamBold or Enum.Font.Gotham
        m.Parent = markersFrame
        Compass.markers[c.label] = { frame = m, angle = c.angle }
    end
    
    Compass.screenGui = screenGui
    Compass.markersFrame = markersFrame
    Compass.degreeLabel = degreeLabel
end

local function getHeading()
    local cam = workspace.CurrentCamera
    if cam then
        local lv = cam.CFrame.LookVector
        local h = math.deg(math.atan2(-lv.X, -lv.Z))
        return h < 0 and h + 360 or h
    end
    return 0
end

local function update()
    local heading = getHeading()
    if Compass.degreeLabel then
        Compass.degreeLabel.Text = math.floor(heading) .. "°"
    end
    for _, data in pairs(Compass.markers) do
        local rel = data.angle - heading
        while rel > 180 do rel = rel - 360 end
        while rel < -180 do rel = rel + 360 end
        local xPos = 0.5 + (rel / 180) * 1.1
        data.frame.Position = UDim2.new(xPos, -15, 0, 0)
        data.frame.TextTransparency = math.clamp(math.abs(rel)/90 - 0.3, 0, 1)
    end
end

function Compass:addObjective(id, pos, icon, color)
    Compass:removeObjective(id)
    local m = Instance.new("TextLabel")
    m.Name = id
    m.Size = UDim2.new(0, 20, 0, 20)
    m.BackgroundTransparency = 1
    m.Text = icon or "📍"
    m.TextSize = 14
    m.Parent = Compass.markersFrame
    Compass.objectives[id] = { marker = m, position = pos }
end

function Compass:removeObjective(id)
    if Compass.objectives[id] then
        Compass.objectives[id].marker:Destroy()
        Compass.objectives[id] = nil
    end
end

function Compass.init()
    print("[Compass] Initializing...")
    createUI()
    RunService.RenderStepped:Connect(update)
    print("[Compass] Initialized!")
end

Compass.init()
return Compass
