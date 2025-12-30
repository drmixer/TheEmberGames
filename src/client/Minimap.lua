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

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst:WaitForChild("Config"))

local Minimap = {}
Minimap.markers = {}
Minimap.zoneRadius = Config.ARENA_SIZE / 2
Minimap.zoneShrinking = false
Minimap.isMinimized = true

local CONFIG = {
    MINIMAP_SIZE = 200, -- Increased from 150
    FULLMAP_SIZE = 400,
    ARENA_RADIUS = Config.ARENA_SIZE / 2, -- Correct arena radius from Config (512)
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
    zoneCircle.Size = UDim2.new(1, 0, 1, 0) -- Start full size
    zoneCircle.Position = UDim2.new(0, 0, 0, 0)
    zoneCircle.BackgroundTransparency = 1
    zoneCircle.Visible = false -- Hide until active
    zoneCircle.Parent = mapBg
    
    local zoneStroke = Instance.new("UIStroke")
    zoneStroke.Color = CONFIG.ZONE_COLOR
    zoneStroke.Thickness = 3 -- Thicker line
    zoneStroke.Parent = zoneCircle
    
    local zoneCorner = Instance.new("UICorner")
    zoneCorner.CornerRadius = UDim.new(0.5, 0)
    zoneCorner.Parent = zoneCircle
    
    -- Danger zone (outside circle)
    local dangerOverlay = Instance.new("Frame")
    dangerOverlay.Name = "DangerOverlay"
    dangerOverlay.Size = UDim2.new(1, 0, 1, 0)
    dangerOverlay.BackgroundColor3 = CONFIG.ZONE_COLOR
    dangerOverlay.BackgroundTransparency = 1 -- Hide for now, logic not fully implemented for hole punch
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

    -- Damage Indicator
    local damageLabel = Instance.new("TextLabel")
    damageLabel.Name = "DamageLabel"
    damageLabel.Size = UDim2.new(1, 0, 0, 20)
    damageLabel.Position = UDim2.new(0, 0, 0, -25) -- Higher above map
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = "" -- Hidden by default
    damageLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- Bright Red/Orange
    damageLabel.TextSize = 16 -- Larger
    damageLabel.Font = Enum.Font.GothamBlack -- Thicker font
    damageLabel.TextStrokeTransparency = 0 -- Black outline
    damageLabel.TextStrokeColor3 = Color3.new(0,0,0)
    damageLabel.Parent = mapContainer
    
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
    Minimap.zoneCircle = zoneCircle
    Minimap.markersContainer = markersContainer
    Minimap.toggleHint = toggleHint
    Minimap.damageLabel = damageLabel
    Minimap.mapBg = mapBg -- Added to table for access
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
function Minimap:updateZone(targetRadius, center, duration, startRadius, damage)
    Minimap.zoneRadius = targetRadius
    duration = duration or 1
    Minimap.zoneCircle.Visible = true -- Show when active
    
    -- Update damage text
    if damage and damage > 0 then
        Minimap.damageLabel.Text = string.format("STORM DAMAGE: %d HP/s", damage)
        Minimap.damageLabel.Visible = true
        
        -- Flash effect
        task.spawn(function()
            local t = 0
            while Minimap.damageLabel.Visible do
                t = t + 0.1
                local scale = 1 + math.sin(t*5)*0.1
                Minimap.damageLabel.TextSize = 16 * scale
                task.wait(0.05)
            end
        end)
    else
        Minimap.damageLabel.Visible = false
    end

    local function getScale(r)
        -- Linear scale: Radius / MaxRadius
        -- Since map is 2*MaxRadius width, and circle size is relative to map size (0..1)
        -- Size = (2*r) / (2*MaxRadius) = r / MaxRadius
        return math.clamp(r / CONFIG.ARENA_RADIUS, 0, 1)
    end
    
    local targetSize = getScale(targetRadius)
    
    -- Snap to start size if provided (for smooth shrinking)
    if startRadius then
        local startSize = getScale(startRadius)
        Minimap.zoneCircle.Size = UDim2.new(startSize, 0, startSize, 0)
        Minimap.zoneCircle.Position = UDim2.new(0.5 - startSize/2, 0, 0.5 - startSize/2, 0)
    end
    
    -- Tween to target size
    TweenService:Create(Minimap.zoneCircle, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(targetSize, 0, targetSize, 0),
        Position = UDim2.new(0.5 - targetSize/2, 0, 0.5 - targetSize/2, 0)
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
    Minimap:hide() -- Hide initially (lobby only)
    
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
            if eventType == "MATCH_START" then
                Minimap:show()
            end
        end)
    end
    
    -- Listen for Lobby/Countdown events to show Map early (during tube rise)
    local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemoteEvent", 5)
    if lobbyRemote then
        lobbyRemote.OnClientEvent:Connect(function(eventType, ...)
            if eventType == "COUNTDOWN_START" or eventType == "MATCH_STARTING" then
                Minimap:show()
            elseif eventType == "COUNTDOWN_CANCELLED" or eventType == "LOBBY_RETURN" then
                Minimap:hide()
            end
        end)
    else
        warn("[Minimap] LobbyRemoteEvent not found!")
    end
    
    local eventsRemote = ReplicatedStorage:WaitForChild("EventsRemoteEvent", 10)
    if eventsRemote then
        eventsRemote.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            if eventType == "STORM_PHASE_ACTIVE" then
                -- args: phase, targetRadius, center, duration, startRadius, damage
                local targetRadius = args[2]
                local center = args[3]
                local duration = args[4] or 1
                local startRadius = args[5]
                local damage = args[6]
                
                Minimap:updateZone(targetRadius, center, duration, startRadius, damage)
            elseif eventType == "SUPPLY_DROP_DEPLOYED" then
                -- args: position, dropId
                local position = args[1]
                local dropId = args[2]
                Minimap:addMarker("supply_" .. dropId, position, "📦", Color3.fromRGB(255, 215, 0))
            elseif eventType == "SUPPLY_DROP_CLEANUP" then
                local dropId = args[1]
                Minimap:removeMarker("supply_" .. dropId)
            end
        end)
    end
    
    print("[Minimap] Initialized! Press M to toggle fullscreen")
end

Minimap.init()
return Minimap
