-- LocalScript: Minimap.lua
-- In-game minimap showing arena, player position, objectives
-- Toggle with M key for full-screen view

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Minimap = {}
Minimap.isMinimized = true
Minimap.markers = {}
Minimap.zoneRadius = 200
Minimap.zoneShrinking = false

local CONFIG = {
    MINIMAP_SIZE = 150,
    FULLMAP_SIZE = 400,
    ARENA_RADIUS = 250, -- Arena world size
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    PLAYER_COLOR = Color3.fromRGB(255, 255, 255),
    ALLY_COLOR = Color3.fromRGB(50, 200, 50),
    ZONE_COLOR = Color3.fromRGB(200, 50, 50),
    OBJECTIVE_COLOR = Color3.fromRGB(255, 215, 0),
    BIOME_COLORS = {
        forest = Color3.fromRGB(34, 85, 34),
        meadow = Color3.fromRGB(90, 130, 60),
        water = Color3.fromRGB(30, 80, 120),
        swamp = Color3.fromRGB(60, 70, 50),
        cliff = Color3.fromRGB(100, 90, 80),
        desert = Color3.fromRGB(180, 160, 120),
        mountain = Color3.fromRGB(80, 80, 90),
    },
}

local function worldToMinimap(worldPos, mapFrame)
    local mapSize = mapFrame.AbsoluteSize.X
    local scale = mapSize / (CONFIG.ARENA_RADIUS * 2)
    
    local relX = (worldPos.X / CONFIG.ARENA_RADIUS) * 0.5 + 0.5
    local relY = (worldPos.Z / CONFIG.ARENA_RADIUS) * 0.5 + 0.5
    
    return UDim2.new(relX, -4, relY, -4)
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Minimap"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    -- Mini map container (top right)
    local mapContainer = Instance.new("Frame")
    mapContainer.Name = "MapContainer"
    mapContainer.Size = UDim2.new(0, CONFIG.MINIMAP_SIZE, 0, CONFIG.MINIMAP_SIZE)
    mapContainer.Position = UDim2.new(1, -CONFIG.MINIMAP_SIZE - 10, 0, 130)
    mapContainer.BackgroundColor3 = CONFIG.BG_COLOR
    mapContainer.BorderSizePixel = 0
    mapContainer.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mapContainer
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.ACCENT_COLOR
    stroke.Thickness = 2
    stroke.Parent = mapContainer
    
    -- Map background (arena representation)
    local mapBg = Instance.new("Frame")
    mapBg.Name = "MapBackground"
    mapBg.Size = UDim2.new(1, -10, 1, -10)
    mapBg.Position = UDim2.new(0, 5, 0, 5)
    mapBg.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
    mapBg.BorderSizePixel = 0
    mapBg.ClipsDescendants = true
    mapBg.Parent = mapContainer
    
    local mapCorner = Instance.new("UICorner")
    mapCorner.CornerRadius = UDim.new(0, 6)
    mapCorner.Parent = mapBg
    
    -- Zone circle (represents safe zone)
    local zoneCircle = Instance.new("Frame")
    zoneCircle.Name = "ZoneCircle"
    zoneCircle.Size = UDim2.new(0.8, 0, 0.8, 0)
    zoneCircle.Position = UDim2.new(0.1, 0, 0.1, 0)
    zoneCircle.BackgroundTransparency = 1
    zoneCircle.Parent = mapBg
    
    local zoneStroke = Instance.new("UIStroke")
    zoneStroke.Color = CONFIG.ZONE_COLOR
    zoneStroke.Thickness = 2
    zoneStroke.Parent = zoneCircle
    
    local zoneCorner = Instance.new("UICorner")
    zoneCorner.CornerRadius = UDim.new(0.5, 0)
    zoneCorner.Parent = zoneCircle
    
    -- Danger zone (outside circle)
    local dangerOverlay = Instance.new("Frame")
    dangerOverlay.Name = "DangerOverlay"
    dangerOverlay.Size = UDim2.new(1, 0, 1, 0)
    dangerOverlay.BackgroundColor3 = CONFIG.ZONE_COLOR
    dangerOverlay.BackgroundTransparency = 0.8
    dangerOverlay.BorderSizePixel = 0
    dangerOverlay.ZIndex = 1
    dangerOverlay.Parent = mapBg
    
    -- Player marker
    local playerMarker = Instance.new("Frame")
    playerMarker.Name = "PlayerMarker"
    playerMarker.Size = UDim2.new(0, 8, 0, 8)
    playerMarker.Position = UDim2.new(0.5, -4, 0.5, -4)
    playerMarker.BackgroundColor3 = CONFIG.PLAYER_COLOR
    playerMarker.BorderSizePixel = 0
    playerMarker.ZIndex = 10
    playerMarker.Parent = mapBg
    
    local playerCorner = Instance.new("UICorner")
    playerCorner.CornerRadius = UDim.new(0.5, 0)
    playerCorner.Parent = playerMarker
    
    -- Direction indicator
    local directionIndicator = Instance.new("Frame")
    directionIndicator.Name = "Direction"
    directionIndicator.Size = UDim2.new(0, 3, 0, 10)
    directionIndicator.Position = UDim2.new(0.5, -1.5, 0, -8)
    directionIndicator.BackgroundColor3 = CONFIG.PLAYER_COLOR
    directionIndicator.BorderSizePixel = 0
    directionIndicator.Parent = playerMarker
    
    -- Cornucopia marker
    local cornucopiaMarker = Instance.new("TextLabel")
    cornucopiaMarker.Name = "Cornucopia"
    cornucopiaMarker.Size = UDim2.new(0, 16, 0, 16)
    cornucopiaMarker.Position = UDim2.new(0.5, -8, 0.5, -8)
    cornucopiaMarker.BackgroundTransparency = 1
    cornucopiaMarker.Text = "🏛️"
    cornucopiaMarker.TextSize = 14
    cornucopiaMarker.ZIndex = 5
    cornucopiaMarker.Parent = mapBg
    
    -- Cardinal directions
    local directions = {
        {label = "N", pos = UDim2.new(0.5, -5, 0, 2)},
        {label = "S", pos = UDim2.new(0.5, -5, 1, -15)},
        {label = "E", pos = UDim2.new(1, -12, 0.5, -6)},
        {label = "W", pos = UDim2.new(0, 2, 0.5, -6)},
    }
    
    for _, dir in ipairs(directions) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 12, 0, 12)
        label.Position = dir.pos
        label.BackgroundTransparency = 1
        label.Text = dir.label
        label.TextColor3 = Color3.fromRGB(180, 180, 180)
        label.TextSize = 10
        label.Font = Enum.Font.GothamBold
        label.ZIndex = 15
        label.Parent = mapBg
    end
    
    -- Toggle hint
    local toggleHint = Instance.new("TextLabel")
    toggleHint.Size = UDim2.new(1, 0, 0, 15)
    toggleHint.Position = UDim2.new(0, 0, 1, 2)
    toggleHint.BackgroundTransparency = 1
    toggleHint.Text = "Press M to expand"
    toggleHint.TextColor3 = Color3.fromRGB(120, 120, 120)
    toggleHint.TextSize = 10
    toggleHint.Font = Enum.Font.Gotham
    toggleHint.Parent = mapContainer
    
    -- Markers container
    local markersContainer = Instance.new("Folder")
    markersContainer.Name = "Markers"
    markersContainer.Parent = mapBg
    
    Minimap.screenGui = screenGui
    Minimap.mapContainer = mapContainer
    Minimap.mapBg = mapBg
    Minimap.playerMarker = playerMarker
    Minimap.directionIndicator = directionIndicator
    Minimap.zoneCircle = zoneCircle
    Minimap.markersContainer = markersContainer
    Minimap.toggleHint = toggleHint
end

-- Update player position on minimap
local function updatePlayerPosition()
    local character = Player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local pos = humanoidRootPart.Position
    local newPos = worldToMinimap(pos, Minimap.mapBg)
    Minimap.playerMarker.Position = newPos
    
    -- Update rotation
    local camera = workspace.CurrentCamera
    if camera then
        local lookVector = camera.CFrame.LookVector
        local angle = math.deg(math.atan2(-lookVector.X, -lookVector.Z))
        Minimap.playerMarker.Rotation = angle
    end
end

-- Add objective marker
function Minimap:addMarker(id, worldPos, icon, color)
    Minimap:removeMarker(id)
    
    local marker = Instance.new("TextLabel")
    marker.Name = id
    marker.Size = UDim2.new(0, 14, 0, 14)
    marker.BackgroundTransparency = 1
    marker.Text = icon or "📍"
    marker.TextSize = 12
    marker.ZIndex = 8
    marker.Parent = Minimap.markersContainer
    
    Minimap.markers[id] = {
        marker = marker,
        worldPos = worldPos
    }
    
    -- Position marker
    marker.Position = worldToMinimap(worldPos, Minimap.mapBg)
end

-- Remove marker
function Minimap:removeMarker(id)
    local data = Minimap.markers[id]
    if data and data.marker then
        data.marker:Destroy()
    end
    Minimap.markers[id] = nil
end

-- Update zone
function Minimap:updateZone(radius, center)
    Minimap.zoneRadius = radius
    
    local mapScale = radius / CONFIG.ARENA_RADIUS
    local size = mapScale * 0.8
    
    TweenService:Create(Minimap.zoneCircle, TweenInfo.new(1), {
        Size = UDim2.new(size, 0, size, 0),
        Position = UDim2.new(0.5 - size/2, 0, 0.5 - size/2, 0)
    }):Play()
end

-- Toggle fullscreen
function Minimap:toggleFullscreen()
    Minimap.isMinimized = not Minimap.isMinimized
    
    local targetSize = Minimap.isMinimized 
        and UDim2.new(0, CONFIG.MINIMAP_SIZE, 0, CONFIG.MINIMAP_SIZE)
        or UDim2.new(0, CONFIG.FULLMAP_SIZE, 0, CONFIG.FULLMAP_SIZE)
    
    local targetPos = Minimap.isMinimized
        and UDim2.new(1, -CONFIG.MINIMAP_SIZE - 10, 0, 130)
        or UDim2.new(0.5, -CONFIG.FULLMAP_SIZE/2, 0.5, -CONFIG.FULLMAP_SIZE/2)
    
    TweenService:Create(Minimap.mapContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = targetSize,
        Position = targetPos
    }):Play()
    
    Minimap.toggleHint.Text = Minimap.isMinimized and "Press M to expand" or "Press M to minimize"
end

-- Show/hide
function Minimap:show()
    Minimap.screenGui.Enabled = true
end

function Minimap:hide()
    Minimap.screenGui.Enabled = false
end

-- Initialize
function Minimap.init()
    print("[Minimap] Initializing...")
    
    createUI()
    
    -- Update position every frame
    RunService.RenderStepped:Connect(updatePlayerPosition)
    
    -- Toggle key
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.M then
            Minimap:toggleFullscreen()
        end
    end)
    
    -- Listen for game events
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        matchRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "ZONE_UPDATE" then
                Minimap:updateZone(data.radius, data.center)
            elseif eventType == "SUPPLY_DROP" then
                Minimap:addMarker("supply_" .. data.id, data.position, "📦")
            elseif eventType == "MATCH_START" then
                Minimap:show()
            end
        end)
    end
    
    print("[Minimap] Initialized! Press M to toggle fullscreen")
end

Minimap.init()
return Minimap
