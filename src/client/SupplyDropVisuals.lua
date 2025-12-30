-- LocalScript: SupplyDropVisuals.lua
-- Handles visual effects for supply drops
-- Creates parachute animations, landing indicators, and crate visuals

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for remote events
local EventsRemoteEvent = ReplicatedStorage:WaitForChild("EventsRemoteEvent", 10)

local SupplyDropVisuals = {}
SupplyDropVisuals.activeDrops = {}
SupplyDropVisuals.screenGui = nil

-- Configuration
local CONFIG = {
    DROP_HEIGHT = 150, -- Starting height
    DROP_DURATION = 12, -- Seconds to fall
    PARACHUTE_SIZE = 8, -- Parachute radius
    CRATE_SIZE = Vector3.new(4, 3, 4),
    BEACON_HEIGHT = 100,
    BEACON_DURATION = 30, -- How long beacon stays visible
}

-- Sound IDs (VERIFIED Roblox audio assets)
local SOUND_IDS = {
    HOVERCRAFT = "rbxassetid://9046683891", -- Verified aircraft/siren approach
    PARACHUTE_DEPLOY = "rbxassetid://9046219673", -- Verified wind deploy sound
    CRATE_LAND = "rbxassetid://3041190784", -- Verified impact sound
    CRATE_OPEN = "rbxassetid://9046219171", -- Verified chest/container open
}

-- Create screen GUI for indicators
local function createScreenGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SupplyDropUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    return screenGui
end

-- Play local sound
local function playSound(soundId, volume, parent)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.8
    sound.Parent = parent or PlayerGui
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    return sound
end

-- Helper to find safe ground Y, ignoring sky lobby
local function getSafeGroundY(x, z, startHeight)
    startHeight = startHeight or 250 -- Start below potential sky lobby
    
    local rayOrigin = Vector3.new(x, startHeight, z)
    local rayDir = Vector3.new(0, -500, 0)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    -- Try to exclude Lobby and specific sky parts if found
    local exclusions = {
        workspace:FindFirstChild("Lobby"), 
        workspace:FindFirstChild("SkyPlatform"),
        workspace:FindFirstChild("LobbySpawn") -- Added correct name
    } 
    rayParams.FilterDescendantsInstances = exclusions
    
    local rayResult = workspace:Raycast(rayOrigin, rayDir, rayParams)
    
    if rayResult then
        -- Double check height - if it's remarkably high (>150), it might still be a sky platform we missed
        if rayResult.Position.Y > 150 then
            print("[SupplyDropVisuals] Raycast hit high object: " .. rayResult.Instance.Name .. " at Y=" .. rayResult.Position.Y .. ". Ignoring.")
            -- Try casting deeper or just fallback
            return 5 -- Fallback to low ground
        end
        return rayResult.Position.Y
    end
    
    return 5 -- Fallback
end

-- Create landing zone indicator (circle on ground)
local function createLandingIndicator(position)
    -- Align indicator with ground
    local groundY = getSafeGroundY(position.X, position.Z)

    local indicator = Instance.new("Part")
    indicator.Name = "LandingIndicator"
    indicator.Size = Vector3.new(15, 0.2, 15)
    indicator.Position = Vector3.new(position.X, groundY + 0.5, position.Z)
    indicator.Anchored = true
    indicator.CanCollide = false
    indicator.Material = Enum.Material.Neon
    indicator.Color = Color3.fromRGB(255, 200, 50)
    indicator.Transparency = 0.3
    indicator.Shape = Enum.PartType.Cylinder
    indicator.Orientation = Vector3.new(0, 0, 90)
    indicator.Parent = workspace
    
    -- Pulsing animation
    local pulseConnection
    local pulseTime = 0
    pulseConnection = RunService.Heartbeat:Connect(function(dt)
        if not indicator or not indicator.Parent then
            pulseConnection:Disconnect()
            return
        end
        
        pulseTime = pulseTime + dt
        local pulse = math.sin(pulseTime * 4) * 0.3 + 0.5
        indicator.Transparency = pulse
        
        -- Rotate slowly
        indicator.CFrame = indicator.CFrame * CFrame.Angles(0, dt * 0.5, 0)
    end)
    
    return indicator
end

-- Create parachute visual
local function createParachute(cratePosition)
    local parachuteHolder = Instance.new("Model")
    parachuteHolder.Name = "Parachute"
    
    -- Parachute canopy (half sphere approximation)
    local canopy = Instance.new("Part")
    canopy.Name = "Canopy"
    canopy.Size = Vector3.new(CONFIG.PARACHUTE_SIZE * 2, CONFIG.PARACHUTE_SIZE, CONFIG.PARACHUTE_SIZE * 2)
    canopy.Shape = Enum.PartType.Ball
    canopy.Position = cratePosition + Vector3.new(0, 6, 0)
    canopy.Anchored = true
    canopy.CanCollide = false
    canopy.Material = Enum.Material.Fabric
    canopy.Color = Color3.fromRGB(220, 220, 220) -- Silver/white
    canopy.Parent = parachuteHolder
    
    -- Parachute strings (simple lines)
    for i = 1, 6 do
        local angle = (i - 1) * (math.pi * 2 / 6)
        local stringPart = Instance.new("Part")
        stringPart.Name = "String" .. i
        stringPart.Size = Vector3.new(0.1, 8, 0.1)
        stringPart.Material = Enum.Material.Fabric -- Changed from Rope (invalid enum) to Fabric
        stringPart.Color = Color3.fromRGB(139, 90, 43) -- Rope color
        stringPart.Anchored = true
        stringPart.CanCollide = false
        
        local offsetX = math.cos(angle) * 3
        local offsetZ = math.sin(angle) * 3
        stringPart.Position = cratePosition + Vector3.new(offsetX, 3, offsetZ)
        stringPart.CFrame = CFrame.new(stringPart.Position, cratePosition)
        stringPart.Parent = parachuteHolder
    end
    
    parachuteHolder.Parent = workspace
    return parachuteHolder
end

-- Create supply crate
local function createSupplyCrate(position, crateId)
    local crate = Instance.new("Model")
    crate.Name = "SupplyCrate_" .. (crateId or "unknown")
    
    -- Main crate body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = CONFIG.CRATE_SIZE
    body.Position = position
    body.Anchored = true
    body.CanCollide = true
    body.Material = Enum.Material.Metal
    body.Color = Color3.fromRGB(60, 60, 70) -- Dark metal
    body.Parent = crate
    
    -- Lid (separate part for opening animation)
    local lid = Instance.new("Part")
    lid.Name = "Lid"
    lid.Size = Vector3.new(CONFIG.CRATE_SIZE.X, 0.3, CONFIG.CRATE_SIZE.Z)
    lid.Position = position + Vector3.new(0, CONFIG.CRATE_SIZE.Y / 2 + 0.15, 0)
    lid.Anchored = true
    lid.CanCollide = false
    lid.Material = Enum.Material.Metal
    lid.Color = Color3.fromRGB(80, 80, 90)
    lid.Parent = crate
    
    -- Add golden accents
    local accent1 = Instance.new("Part")
    accent1.Name = "Accent1"
    accent1.Size = Vector3.new(CONFIG.CRATE_SIZE.X + 0.2, 0.3, 0.3)
    accent1.Position = position + Vector3.new(0, 0, CONFIG.CRATE_SIZE.Z / 2)
    accent1.Anchored = true
    accent1.CanCollide = false
    accent1.Material = Enum.Material.Metal
    accent1.Color = Color3.fromRGB(212, 175, 55)
    accent1.Parent = crate
    
    local accent2 = accent1:Clone()
    accent2.Name = "Accent2"
    accent2.Position = position + Vector3.new(0, 0, -CONFIG.CRATE_SIZE.Z / 2)
    accent2.Parent = crate
    
    -- Capitol symbol on lid
    local symbol = Instance.new("Part")
    symbol.Name = "Symbol"
    symbol.Size = Vector3.new(2, 0.1, 2)
    symbol.Position = position + Vector3.new(0, CONFIG.CRATE_SIZE.Y / 2 + 0.25, 0)
    symbol.Anchored = true
    symbol.CanCollide = false
    symbol.Material = Enum.Material.Neon
    symbol.Color = Color3.fromRGB(212, 175, 55)
    symbol.Shape = Enum.PartType.Cylinder
    symbol.Orientation = Vector3.new(0, 0, 90)
    symbol.Parent = crate
    
    -- Glowing effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(255, 200, 100)
    pointLight.Brightness = 2
    pointLight.Range = 15
    pointLight.Parent = symbol
    
    crate.PrimaryPart = body
    crate.Parent = workspace
    
    return crate
end

-- Create vertical beacon
local function createBeacon(position)
    local beacon = Instance.new("Part")
    beacon.Name = "SupplyBeacon"
    beacon.Size = Vector3.new(1, CONFIG.BEACON_HEIGHT, 1)
    beacon.Position = position + Vector3.new(0, CONFIG.BEACON_HEIGHT / 2, 0)
    beacon.Anchored = true
    beacon.CanCollide = false
    beacon.Material = Enum.Material.Neon
    beacon.Color = Color3.fromRGB(255, 200, 50)
    beacon.Transparency = 0.5
    beacon.Parent = workspace
    
    -- Animate beacon
    local beaconTime = 0
    local beaconConnection
    beaconConnection = RunService.Heartbeat:Connect(function(dt)
        if not beacon or not beacon.Parent then
            beaconConnection:Disconnect()
            return
        end
        
        beaconTime = beaconTime + dt
        beacon.Transparency = 0.3 + math.sin(beaconTime * 3) * 0.3
    end)
    
    return beacon
end

-- Animate supply drop falling
local function animateDropFall(dropId, startPosition, endPosition, callback)
    local drop = SupplyDropVisuals.activeDrops[dropId]
    if not drop then return end
    
    local duration = CONFIG.DROP_DURATION
    local startTime = tick()
    
    local fallConnection
    fallConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        -- Ease out for realistic parachute slowdown
        local easedProgress = 1 - math.pow(1 - progress, 2)
        
        local currentPosition = startPosition:Lerp(endPosition, easedProgress)
        
        -- Update crate position
        if drop.crate and drop.crate.PrimaryPart then
            drop.crate:SetPrimaryPartCFrame(CFrame.new(currentPosition))
        end
        
        -- Update parachute position
        if drop.parachute then
            local canopy = drop.parachute:FindFirstChild("Canopy")
            if canopy then
                canopy.Position = currentPosition + Vector3.new(0, 6, 0)
            end
            
            -- Update strings
            for i = 1, 6 do
                local stringPart = drop.parachute:FindFirstChild("String" .. i)
                if stringPart then
                    local angle = (i - 1) * (math.pi * 2 / 6)
                    local offsetX = math.cos(angle) * 3
                    local offsetZ = math.sin(angle) * 3
                    stringPart.Position = currentPosition + Vector3.new(offsetX, 3, offsetZ)
                    stringPart.CFrame = CFrame.new(stringPart.Position, currentPosition)
                end
            end
        end
        
        -- Sway animation
        if drop.crate and drop.crate.PrimaryPart then
            local sway = math.sin(elapsed * 2) * 3
            drop.crate.PrimaryPart.CFrame = drop.crate.PrimaryPart.CFrame * CFrame.Angles(0, 0, math.rad(sway * 0.1))
        end
        
        if progress >= 1 then
            fallConnection:Disconnect()
            
            -- Remove parachute
            if drop.parachute then
                drop.parachute:Destroy()
                drop.parachute = nil
            end
            
            -- Play landing sound
            if drop.crate and drop.crate.PrimaryPart then
                playSound(SOUND_IDS.CRATE_LAND, 0.8, drop.crate.PrimaryPart)
            end
            
            -- Create beacon at landing site
            drop.beacon = createBeacon(endPosition)
            
            -- Mark as landed
            drop.landed = true
            
            if callback then
                callback()
            end
        end
    end)
    
    return fallConnection
end

-- Helper to find safe ground Y, ignoring sky lobby
local function getSafeGroundY(x, z, startHeight)
    startHeight = startHeight or 250 -- Start below potential sky lobby
    
    local rayOrigin = Vector3.new(x, startHeight, z)
    local rayDir = Vector3.new(0, -500, 0)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    -- Try to exclude Lobby and specific sky parts if found
    local exclusions = {
        workspace:FindFirstChild("Lobby"), 
        workspace:FindFirstChild("SkyPlatform"),
        workspace:FindFirstChild("LobbySpawn")
    } 
    rayParams.FilterDescendantsInstances = exclusions
    
    local rayResult = workspace:Raycast(rayOrigin, rayDir, rayParams)
    
    if rayResult then
        -- Double check height - if it's remarkably high (>150), it might still be a sky platform we missed
        if rayResult.Position.Y > 150 then
            print("[SupplyDropVisuals] Raycast hit high object: " .. rayResult.Instance.Name .. " at Y=" .. rayResult.Position.Y .. ". Ignoring.")
            -- Try casting deeper or just fallback
            return 5 -- Fallback to low ground
        end
        return rayResult.Position.Y
    end
    
    return 5 -- Fallback
end

-- Create landing zone indicator (circle on ground)
local function createLandingIndicator(position)
    -- Align indicator with ground
    local groundY = getSafeGroundY(position.X, position.Z)

    local indicator = Instance.new("Part")
    indicator.Name = "LandingIndicator"
    indicator.Size = Vector3.new(15, 0.2, 15)
    indicator.Position = Vector3.new(position.X, groundY + 0.5, position.Z)
    indicator.Anchored = true
    indicator.CanCollide = false
    indicator.Material = Enum.Material.Neon
    indicator.Color = Color3.fromRGB(255, 200, 50)
    indicator.Transparency = 0.3
    indicator.Shape = Enum.PartType.Cylinder
    indicator.Orientation = Vector3.new(0, 0, 90)
    indicator.Parent = workspace
    
    -- Pulsing animation
    local pulseConnection
    local pulseTime = 0
    pulseConnection = RunService.Heartbeat:Connect(function(dt)
        if not indicator or not indicator.Parent then
            pulseConnection:Disconnect()
            return
        end
        
        pulseTime = pulseTime + dt
        local pulse = math.sin(pulseTime * 4) * 0.3 + 0.5
        indicator.Transparency = pulse
        
        -- Rotate slowly
        indicator.CFrame = indicator.CFrame * CFrame.Angles(0, dt * 0.5, 0)
    end)
    
    return indicator
end

-- Create supply crate
local function createSupplyCrate(position, crateId)
    local crate = Instance.new("Model")
    crate.Name = "SupplyCrate_" .. (crateId or "unknown")
    
    -- Main crate body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = CONFIG.CRATE_SIZE
    body.Position = position
    body.Anchored = true
    body.CanCollide = true
    body.Material = Enum.Material.Metal
    body.Color = Color3.fromRGB(60, 60, 70) -- Dark metal
    body.Parent = crate
    
    -- Lid (separate part for opening animation)
    local lid = Instance.new("Part")
    lid.Name = "Lid"
    lid.Size = Vector3.new(CONFIG.CRATE_SIZE.X, 0.3, CONFIG.CRATE_SIZE.Z)
    lid.Position = position + Vector3.new(0, CONFIG.CRATE_SIZE.Y / 2 + 0.15, 0)
    lid.Anchored = true
    lid.CanCollide = false
    lid.Material = Enum.Material.Metal
    lid.Color = Color3.fromRGB(80, 80, 90)
    lid.Parent = crate
    
    -- Add golden accents
    local accent1 = Instance.new("Part")
    accent1.Name = "Accent1"
    accent1.Size = Vector3.new(CONFIG.CRATE_SIZE.X + 0.2, 0.3, 0.3)
    accent1.Position = position + Vector3.new(0, 0, CONFIG.CRATE_SIZE.Z / 2)
    accent1.Anchored = true
    accent1.CanCollide = false
    accent1.Material = Enum.Material.Metal
    accent1.Color = Color3.fromRGB(212, 175, 55)
    accent1.Parent = crate
    
    local accent2 = accent1:Clone()
    accent2.Name = "Accent2"
    accent2.Position = position + Vector3.new(0, 0, -CONFIG.CRATE_SIZE.Z / 2)
    accent2.Parent = crate
    
    -- Capitol symbol on lid
    local symbol = Instance.new("Part")
    symbol.Name = "Symbol"
    symbol.Size = Vector3.new(2, 0.1, 2)
    symbol.Position = position + Vector3.new(0, CONFIG.CRATE_SIZE.Y / 2 + 0.25, 0)
    symbol.Anchored = true
    symbol.CanCollide = false
    symbol.Material = Enum.Material.Neon
    symbol.Color = Color3.fromRGB(212, 175, 55)
    symbol.Shape = Enum.PartType.Cylinder
    symbol.Orientation = Vector3.new(0, 0, 90)
    symbol.Parent = crate
    
    -- Glowing effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(255, 200, 100)
    pointLight.Brightness = 2
    pointLight.Range = 15
    pointLight.Parent = symbol
    
    crate.PrimaryPart = body
    crate.Parent = workspace
    
    return crate
end

-- Create vertical beacon
local function createBeacon(position)
    local beacon = Instance.new("Part")
    beacon.Name = "SupplyBeacon"
    beacon.Size = Vector3.new(1, CONFIG.BEACON_HEIGHT, 1)
    beacon.Position = position + Vector3.new(0, CONFIG.BEACON_HEIGHT / 2, 0)
    beacon.Anchored = true
    beacon.CanCollide = false
    beacon.Material = Enum.Material.Neon
    beacon.Color = Color3.fromRGB(255, 200, 50)
    beacon.Transparency = 0.5
    beacon.Parent = workspace
    
    -- Animate beacon
    local beaconTime = 0
    local beaconConnection
    beaconConnection = RunService.Heartbeat:Connect(function(dt)
        if not beacon or not beacon.Parent then
            beaconConnection:Disconnect()
            return
        end
        
        beaconTime = beaconTime + dt
        beacon.Transparency = 0.3 + math.sin(beaconTime * 3) * 0.3
    end)
    
    return beacon
end

-- Animate supply drop falling
local function animateDropFall(dropId, startPosition, endPosition, callback)
    local drop = SupplyDropVisuals.activeDrops[dropId]
    if not drop then return end
    
    local duration = CONFIG.DROP_DURATION
    local startTime = tick()
    
    local fallConnection
    fallConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        -- Ease out for realistic parachute slowdown
        local easedProgress = 1 - math.pow(1 - progress, 2)
        
        local currentPosition = startPosition:Lerp(endPosition, easedProgress)
        
        -- Update crate position
        if drop.crate and drop.crate.PrimaryPart then
            drop.crate:SetPrimaryPartCFrame(CFrame.new(currentPosition))
        end
        
        -- Update parachute position
        if drop.parachute then
            local canopy = drop.parachute:FindFirstChild("Canopy")
            if canopy then
                canopy.Position = currentPosition + Vector3.new(0, 6, 0)
            end
            
            -- Update strings
            for i = 1, 6 do
                local stringPart = drop.parachute:FindFirstChild("String" .. i)
                if stringPart then
                    local angle = (i - 1) * (math.pi * 2 / 6)
                    local offsetX = math.cos(angle) * 3
                    local offsetZ = math.sin(angle) * 3
                    stringPart.Position = currentPosition + Vector3.new(offsetX, 3, offsetZ)
                    stringPart.CFrame = CFrame.new(stringPart.Position, currentPosition)
                end
            end
        end
        
        -- Sway animation
        if drop.crate and drop.crate.PrimaryPart then
            local sway = math.sin(elapsed * 2) * 3
            drop.crate.PrimaryPart.CFrame = drop.crate.PrimaryPart.CFrame * CFrame.Angles(0, 0, math.rad(sway * 0.1))
        end
        
        if progress >= 1 then
            fallConnection:Disconnect()
            
            -- Remove parachute
            if drop.parachute then
                drop.parachute:Destroy()
                drop.parachute = nil
            end
            
            -- Play landing sound
            if drop.crate and drop.crate.PrimaryPart then
                playSound(SOUND_IDS.CRATE_LAND, 0.8, drop.crate.PrimaryPart)
            end
            
            -- Create beacon at landing site
            drop.beacon = createBeacon(endPosition)
            
            -- Mark as landed
            drop.landed = true
            
            if callback then
                callback()
            end
        end
    end)
    
    return fallConnection
end

-- Start a supply drop
function SupplyDropVisuals:startSupplyDrop(dropId, targetPosition)
    print("[SupplyDropVisuals] Supply drop incoming at " .. tostring(targetPosition))
    
    -- Calculate start position (high in sky)
    local startPosition = Vector3.new(targetPosition.X, CONFIG.DROP_HEIGHT, targetPosition.Z)
    
    -- Raycast to find highest ground point in crate footprint (prevent burying)
    local maxY = -1000
    local offsets = {
        Vector3.new(0, 0, 0),    -- Center
        Vector3.new(2, 0, 2),    -- Corners
        Vector3.new(2, 0, -2),
        Vector3.new(-2, 0, 2),
        Vector3.new(-2, 0, -2)
    }
    
    for _, offset in ipairs(offsets) do
        local y = getSafeGroundY(targetPosition.X + offset.X, targetPosition.Z + offset.Z)
        if y > maxY then
            maxY = y
        end
    end
    
    if maxY == -1000 then maxY = 5 end -- Fallback
    
    local endPosition = Vector3.new(targetPosition.X, maxY + 1.5, targetPosition.Z) -- Ground level adjusted for crate bottom
    
    -- Play hovercraft sound
    playSound(SOUND_IDS.HOVERCRAFT, 0.6)
    
    -- Create landing indicator
    local indicator = createLandingIndicator(targetPosition)
    
    -- Wait for "drop" from hovercraft
    task.wait(3)
    
    -- Play parachute deploy sound
    playSound(SOUND_IDS.PARACHUTE_DEPLOY, 0.5)
    
    -- Create crate and parachute
    local crate = createSupplyCrate(startPosition, dropId)
    local parachute = createParachute(startPosition)
    
    -- Store active drop
    SupplyDropVisuals.activeDrops[dropId] = {
        crate = crate,
        parachute = parachute,
        indicator = indicator,
        beacon = nil,
        landed = false
    }
    
    -- Animate the fall
    animateDropFall(dropId, startPosition, endPosition, function()
        -- Remove indicator after landing
        if indicator and indicator.Parent then
            TweenService:Create(indicator, TweenInfo.new(1), {
                Transparency = 1
            }):Play()
            Debris:AddItem(indicator, 1.5)
        end
        
        print("[SupplyDropVisuals] Supply drop " .. dropId .. " has landed!")
    end)
end

-- Open a supply crate (called when player interacts)
function SupplyDropVisuals:openCrate(dropId)
    local drop = SupplyDropVisuals.activeDrops[dropId]
    if not drop or not drop.landed then return end
    
    print("[SupplyDropVisuals] Opening crate " .. dropId)
    
    -- Play open sound
    if drop.crate then
        playSound(SOUND_IDS.CRATE_OPEN, 0.7)
        
        -- Animate lid opening
        local lid = drop.crate:FindFirstChild("Lid")
        if lid then
            TweenService:Create(lid, TweenInfo.new(0.5), {
                CFrame = lid.CFrame * CFrame.Angles(math.rad(-120), 0, 0) + Vector3.new(0, 0, -2)
            }):Play()
        end
        
        -- Burst of particles
        local symbol = drop.crate:FindFirstChild("Symbol")
        if symbol then
            local emitter = Instance.new("ParticleEmitter")
            emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
            emitter.Size = NumberSequence.new(0.5, 0)
            emitter.Lifetime = NumberRange.new(1, 2)
            emitter.Speed = NumberRange.new(10, 20)
            emitter.SpreadAngle = Vector2.new(180, 180)
            emitter.Rate = 0
            emitter.Parent = symbol
            emitter:Emit(30)
            
            Debris:AddItem(emitter, 2)
        end
    end
    
    -- Remove beacon
    if drop.beacon then
        TweenService:Create(drop.beacon, TweenInfo.new(1), {
            Transparency = 1
        }):Play()
        Debris:AddItem(drop.beacon, 1.5)
    end
end

-- Cleanup supply drop
function SupplyDropVisuals:cleanupDrop(dropId)
    local drop = SupplyDropVisuals.activeDrops[dropId]
    if not drop then return end
    
    if drop.crate then
        drop.crate:Destroy()
    end
    if drop.parachute then
        drop.parachute:Destroy()
    end
    if drop.indicator then
        drop.indicator:Destroy()
    end
    if drop.beacon then
        drop.beacon:Destroy()
    end
    
    SupplyDropVisuals.activeDrops[dropId] = nil
end

-- Initialize
function SupplyDropVisuals.init()
    print("[SupplyDropVisuals] Initializing...")
    
    SupplyDropVisuals.screenGui = createScreenGui()
    
    -- Connect to events
    if EventsRemoteEvent then
        EventsRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "SUPPLY_DROP_DEPLOYED" then
                local position = args[1]
                local dropId = args[2] or tostring(tick())
                SupplyDropVisuals:startSupplyDrop(dropId, position)
                
            elseif eventType == "SUPPLY_DROP_OPENED" then
                local dropId = args[1]
                SupplyDropVisuals:openCrate(dropId)
                
            elseif eventType == "SUPPLY_DROP_CLEANUP" then
                local dropId = args[1]
                SupplyDropVisuals:cleanupDrop(dropId)
            end
        end)
    end
    
    print("[SupplyDropVisuals] Initialized successfully")
end

-- Initialize when loaded
SupplyDropVisuals.init()

return SupplyDropVisuals
