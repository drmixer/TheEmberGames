-- LocalScript: TrailEffects.lua
-- Handles player trail effects and visual flair
-- Trails can be earned through victories and achievements

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer

local TrailEffects = {}
TrailEffects.activeTrail = nil
TrailEffects.trailConnection = nil

-- Trail configurations
local TRAIL_CONFIGS = {
    -- Default trails (available to all)
    ["ember"] = {
        name = "Ember Trail",
        description = "Flames follow in your wake",
        color1 = Color3.fromRGB(255, 100, 0),
        color2 = Color3.fromRGB(255, 50, 0),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lifetime = 0.8,
        minLength = 0.1,
        widthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0.3)
        }),
        lightEmission = 1,
        texture = "", -- Solid trail
        rarity = "Common"
    },
    
    ["golden"] = {
        name = "Victor's Gold",
        description = "A trail fit for champions",
        color1 = Color3.fromRGB(255, 215, 0),
        color2 = Color3.fromRGB(255, 180, 50),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lifetime = 1.0,
        minLength = 0.1,
        widthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.8),
            NumberSequenceKeypoint.new(1, 0.2)
        }),
        lightEmission = 0.8,
        texture = "",
        rarity = "Rare"
    },
    
    ["mockingjay"] = {
        name = "Mockingjay Feathers",
        description = "Feathers trail behind the symbol of rebellion",
        color1 = Color3.fromRGB(50, 50, 60),
        color2 = Color3.fromRGB(100, 80, 50),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.4),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lifetime = 1.2,
        minLength = 0.05,
        widthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(1, 0.1)
        }),
        lightEmission = 0.2,
        texture = "",
        rarity = "Epic"
    },
    
    ["nightlock"] = {
        name = "Nightlock Poison",
        description = "Deadly beauty trails behind",
        color1 = Color3.fromRGB(100, 0, 150),
        color2 = Color3.fromRGB(50, 0, 80),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lifetime = 1.5,
        minLength = 0.1,
        widthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1.2),
            NumberSequenceKeypoint.new(0.3, 1),
            NumberSequenceKeypoint.new(1, 0.1)
        }),
        lightEmission = 0.5,
        texture = "",
        rarity = "Legendary"
    },
    
    ["ice"] = {
        name = "Frozen Path",
        description = "Leave winter in your wake",
        color1 = Color3.fromRGB(150, 220, 255),
        color2 = Color3.fromRGB(200, 240, 255),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lifetime = 0.7,
        minLength = 0.1,
        widthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.9),
            NumberSequenceKeypoint.new(1, 0.4)
        }),
        lightEmission = 0.6,
        texture = "",
        rarity = "Rare"
    },
    
    ["district"] = {
        name = "District Pride",
        description = "Show your district colors with pride",
        color1 = Color3.fromRGB(200, 200, 200), -- Will be set based on district
        color2 = Color3.fromRGB(100, 100, 100),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.4),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lifetime = 0.6,
        minLength = 0.1,
        widthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(1, 0.3)
        }),
        lightEmission = 0.3,
        texture = "",
        rarity = "Common"
    },
    
    ["rainbow"] = {
        name = "Capitol Spectacle",
        description = "The Capitol's finest display",
        color1 = Color3.fromRGB(255, 100, 100), -- Will cycle
        color2 = Color3.fromRGB(100, 100, 255),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lifetime = 1.0,
        minLength = 0.05,
        widthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0.2)
        }),
        lightEmission = 1,
        texture = "",
        rarity = "Legendary",
        animated = true
    }
}

-- District colors for district trail
local DISTRICT_COLORS = {
    [1] = Color3.fromRGB(200, 180, 100), -- Luxury - Gold
    [2] = Color3.fromRGB(120, 120, 140), -- Masonry - Gray
    [3] = Color3.fromRGB(255, 220, 0),   -- Technology - Yellow
    [4] = Color3.fromRGB(0, 150, 200),   -- Fishing - Teal
    [5] = Color3.fromRGB(255, 165, 0),   -- Power - Orange
    [6] = Color3.fromRGB(100, 100, 110), -- Transportation - Gray
    [7] = Color3.fromRGB(34, 139, 34),   -- Lumber - Green
    [8] = Color3.fromRGB(220, 220, 220), -- Textiles - White
    [9] = Color3.fromRGB(218, 165, 32),  -- Grain - Wheat
    [10] = Color3.fromRGB(139, 90, 43),  -- Livestock - Brown
    [11] = Color3.fromRGB(50, 150, 50),  -- Agriculture - Green
    [12] = Color3.fromRGB(50, 50, 60),   -- Mining - Coal
}

-- Create trail attachment points
local function createTrailAttachments(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end
    
    -- Check if attachments already exist
    local att0 = hrp:FindFirstChild("TrailAttachment0")
    local att1 = hrp:FindFirstChild("TrailAttachment1")
    
    if att0 and att1 then
        return att0, att1
    end
    
    -- Create new attachments
    att0 = Instance.new("Attachment")
    att0.Name = "TrailAttachment0"
    att0.Position = Vector3.new(0, 0.5, 0)
    att0.Parent = hrp
    
    att1 = Instance.new("Attachment")
    att1.Name = "TrailAttachment1"
    att1.Position = Vector3.new(0, -0.5, 0)
    att1.Parent = hrp
    
    return att0, att1
end

-- Create trail from config
local function createTrail(config, attachment0, attachment1)
    local trail = Instance.new("Trail")
    trail.Name = "PlayerTrail"
    trail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, config.color1),
        ColorSequenceKeypoint.new(1, config.color2)
    })
    trail.Transparency = config.transparency
    trail.Lifetime = config.lifetime
    trail.MinLength = config.minLength
    trail.WidthScale = config.widthScale
    trail.LightEmission = config.lightEmission
    trail.LightInfluence = 0
    trail.FaceCamera = true
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Enabled = true
    trail.Parent = attachment0.Parent
    
    return trail
end

-- Set player's active trail
function TrailEffects:setTrail(trailId)
    local character = Player.Character
    if not character then return false end
    
    local config = TRAIL_CONFIGS[trailId]
    if not config then
        warn("[TrailEffects] Unknown trail: " .. tostring(trailId))
        return false
    end
    
    -- Remove existing trail
    TrailEffects:removeTrail()
    
    -- Create attachments
    local att0, att1 = createTrailAttachments(character)
    if not att0 or not att1 then
        return false
    end
    
    -- Handle district trail - set color based on player's district
    if trailId == "district" then
        local district = Player:GetAttribute("District") or 12
        config = table.clone(config)
        config.color1 = DISTRICT_COLORS[district] or DISTRICT_COLORS[12]
        config.color2 = config.color1:Lerp(Color3.fromRGB(0, 0, 0), 0.3)
    end
    
    -- Create the trail
    local trail = createTrail(config, att0, att1)
    TrailEffects.activeTrail = trail
    
    -- Handle animated trails (rainbow)
    if config.animated and trailId == "rainbow" then
        local hue = 0
        TrailEffects.trailConnection = RunService.Heartbeat:Connect(function(dt)
            if not trail or not trail.Parent then
                if TrailEffects.trailConnection then
                    TrailEffects.trailConnection:Disconnect()
                end
                return
            end
            
            hue = (hue + dt * 0.5) % 1
            local color1 = Color3.fromHSV(hue, 0.8, 1)
            local color2 = Color3.fromHSV((hue + 0.3) % 1, 0.8, 1)
            
            trail.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, color1),
                ColorSequenceKeypoint.new(1, color2)
            })
        end)
    end
    
    print("[TrailEffects] Trail set: " .. config.name)
    return true
end

-- Remove player's trail
function TrailEffects:removeTrail()
    if TrailEffects.trailConnection then
        TrailEffects.trailConnection:Disconnect()
        TrailEffects.trailConnection = nil
    end
    
    if TrailEffects.activeTrail then
        TrailEffects.activeTrail:Destroy()
        TrailEffects.activeTrail = nil
    end
    
    -- Also clean up attachments if no trail
    local character = Player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local existingTrail = hrp:FindFirstChild("PlayerTrail")
            if existingTrail then
                existingTrail:Destroy()
            end
        end
    end
end

-- Get available trails
function TrailEffects:getAvailableTrails()
    local trails = {}
    for id, config in pairs(TRAIL_CONFIGS) do
        table.insert(trails, {
            id = id,
            name = config.name,
            description = config.description,
            rarity = config.rarity
        })
    end
    return trails
end

-- Handle character respawn
local function onCharacterAdded(character)
    -- Re-apply trail if one was active
    local lastTrailId = Player:GetAttribute("EquippedTrail")
    if lastTrailId and TRAIL_CONFIGS[lastTrailId] then
        task.wait(0.5) -- Wait for character to fully load
        TrailEffects:setTrail(lastTrailId)
    end
end

-- Initialize
function TrailEffects.init()
    print("[TrailEffects] Initializing...")
    
    -- Connect to character events
    if Player.Character then
        onCharacterAdded(Player.Character)
    end
    
    Player.CharacterAdded:Connect(onCharacterAdded)
    
    -- Connect to server events for trail changes
    local eventsRemote = ReplicatedStorage:FindFirstChild("EventsRemoteEvent")
    if eventsRemote then
        eventsRemote.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "SET_TRAIL" then
                local trailId = args[1]
                if trailId then
                    TrailEffects:setTrail(trailId)
                    Player:SetAttribute("EquippedTrail", trailId)
                end
            elseif eventType == "REMOVE_TRAIL" then
                TrailEffects:removeTrail()
                Player:SetAttribute("EquippedTrail", nil)
            end
        end)
    end
    
    -- Auto-apply default ember trail for testing
    task.spawn(function()
        task.wait(2)
        if Player.Character and not TrailEffects.activeTrail then
            -- TrailEffects:setTrail("ember") -- Uncomment to auto-apply
        end
    end)
    
    print("[TrailEffects] Initialized with " .. tostring(#TrailEffects:getAvailableTrails()) .. " trail types")
end

-- Initialize when module loads
TrailEffects.init()

return TrailEffects
