-- ModuleScript: DistrictCostumes.lua (Server)
-- Assigns and applies district-specific costume colors to players
-- Creates visual distinction between tributes from different districts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local DistrictCostumes = {}

-- Create remote event for costume updates
local costumeRemoteEvent = Instance.new("RemoteEvent")
costumeRemoteEvent.Name = "CostumeRemoteEvent"
costumeRemoteEvent.Parent = ReplicatedStorage

-- District color schemes (primary color, secondary color, accent)
local DISTRICT_COLORS = {
    [1] = { -- District 1: Luxury - Gold and Purple
        primary = Color3.fromRGB(212, 175, 55),
        secondary = Color3.fromRGB(128, 0, 128),
        accent = Color3.fromRGB(255, 215, 0),
        name = "Luxury"
    },
    [2] = { -- District 2: Masonry - Gray and Red
        primary = Color3.fromRGB(128, 128, 128),
        secondary = Color3.fromRGB(139, 0, 0),
        accent = Color3.fromRGB(169, 169, 169),
        name = "Masonry"
    },
    [3] = { -- District 3: Technology - Blue and Silver
        primary = Color3.fromRGB(0, 100, 200),
        secondary = Color3.fromRGB(192, 192, 192),
        accent = Color3.fromRGB(0, 191, 255),
        name = "Technology"
    },
    [4] = { -- District 4: Fishing - Teal and White
        primary = Color3.fromRGB(0, 128, 128),
        secondary = Color3.fromRGB(240, 248, 255),
        accent = Color3.fromRGB(64, 224, 208),
        name = "Fishing"
    },
    [5] = { -- District 5: Power - Yellow and Black
        primary = Color3.fromRGB(255, 215, 0),
        secondary = Color3.fromRGB(30, 30, 30),
        accent = Color3.fromRGB(255, 255, 0),
        name = "Power"
    },
    [6] = { -- District 6: Transportation - Orange and Gray
        primary = Color3.fromRGB(255, 140, 0),
        secondary = Color3.fromRGB(105, 105, 105),
        accent = Color3.fromRGB(255, 165, 0),
        name = "Transportation"
    },
    [7] = { -- District 7: Lumber - Green and Brown
        primary = Color3.fromRGB(34, 139, 34),
        secondary = Color3.fromRGB(139, 90, 43),
        accent = Color3.fromRGB(0, 100, 0),
        name = "Lumber"
    },
    [8] = { -- District 8: Textiles - Pink and White
        primary = Color3.fromRGB(255, 105, 180),
        secondary = Color3.fromRGB(255, 255, 255),
        accent = Color3.fromRGB(255, 182, 193),
        name = "Textiles"
    },
    [9] = { -- District 9: Grain - Wheat and Brown
        primary = Color3.fromRGB(245, 222, 179),
        secondary = Color3.fromRGB(160, 82, 45),
        accent = Color3.fromRGB(218, 165, 32),
        name = "Grain"
    },
    [10] = { -- District 10: Livestock - Brown and Tan
        primary = Color3.fromRGB(139, 69, 19),
        secondary = Color3.fromRGB(210, 180, 140),
        accent = Color3.fromRGB(160, 82, 45),
        name = "Livestock"
    },
    [11] = { -- District 11: Agriculture - Dark Green and Gold
        primary = Color3.fromRGB(0, 100, 0),
        secondary = Color3.fromRGB(218, 165, 32),
        accent = Color3.fromRGB(107, 142, 35),
        name = "Agriculture"
    },
    [12] = { -- District 12: Mining - Black and Gray
        primary = Color3.fromRGB(40, 40, 40),
        secondary = Color3.fromRGB(128, 128, 128),
        accent = Color3.fromRGB(70, 70, 70),
        name = "Mining"
    }
}

-- Body part mapping for costume application
local BODY_PARTS = {
    shirt = {"Torso", "UpperTorso", "LowerTorso"},
    pants = {"Left Leg", "Right Leg", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"},
    arms = {"Left Arm", "Right Arm", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand"}
}

-- Get district colors
function DistrictCostumes:getDistrictColors(district)
    return DISTRICT_COLORS[district] or DISTRICT_COLORS[12] -- Default to District 12
end

-- Get district name
function DistrictCostumes:getDistrictName(district)
    local colors = DISTRICT_COLORS[district]
    return colors and colors.name or "Unknown"
end

-- Apply costume colors to a character
function DistrictCostumes:applyDistrictCostume(player, district)
    local character = player.Character
    if not character then
        warn("[DistrictCostumes] No character found for " .. player.Name)
        return
    end
    
    local colors = DistrictCostumes:getDistrictColors(district)
    if not colors then
        warn("[DistrictCostumes] Invalid district: " .. tostring(district))
        return
    end
    
    print("[DistrictCostumes] Applying District " .. district .. " costume to " .. player.Name)
    
    -- Apply shirt color (torso)
    for _, partName in ipairs(BODY_PARTS.shirt) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Color = colors.primary
        end
    end
    
    -- Apply pants color (legs)
    for _, partName in ipairs(BODY_PARTS.pants) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Color = colors.secondary
        end
    end
    
    -- Apply arm color (matching shirt or variation)
    for _, partName in ipairs(BODY_PARTS.arms) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Color = colors.primary
        end
    end
    
    -- Add district indicator (billboard GUI above head)
    local head = character:FindFirstChild("Head")
    if head then
        -- Remove existing indicator
        local existingGui = head:FindFirstChild("DistrictIndicator")
        if existingGui then
            existingGui:Destroy()
        end
        
        -- Create new indicator
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "DistrictIndicator"
        billboardGui.Size = UDim2.new(0, 100, 0, 30)
        billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
        billboardGui.AlwaysOnTop = false
        billboardGui.Parent = head
        
        -- District label
        local districtLabel = Instance.new("TextLabel")
        districtLabel.Size = UDim2.new(1, 0, 1, 0)
        districtLabel.BackgroundTransparency = 1
        districtLabel.Text = "D" .. tostring(district)
        districtLabel.TextColor3 = colors.accent
        districtLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        districtLabel.TextStrokeTransparency = 0.3
        districtLabel.Font = Enum.Font.GothamBold
        districtLabel.TextScaled = true
        districtLabel.Parent = billboardGui
    end
    
    -- Add shoulder accent (small colored part)
    DistrictCostumes:addShoulderAccent(character, colors.accent)
    
    -- Notify client
    costumeRemoteEvent:FireClient(player, "COSTUME_APPLIED", district, colors)
    
    print("[DistrictCostumes] Costume applied for " .. player.Name .. " - District " .. district .. " (" .. colors.name .. ")")
end

-- Add shoulder accent decoration
function DistrictCostumes:addShoulderAccent(character, accentColor)
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if not torso then return end
    
    -- Remove existing accents
    local existingAccent = character:FindFirstChild("DistrictAccent")
    if existingAccent then
        existingAccent:Destroy()
    end
    
    -- Create shoulder accent
    local accent = Instance.new("Part")
    accent.Name = "DistrictAccent"
    accent.Size = Vector3.new(0.8, 0.15, 0.4)
    accent.Material = Enum.Material.Neon
    accent.Color = accentColor
    accent.CanCollide = false
    accent.Massless = true
    accent.Parent = character
    
    -- Weld to torso
    local weld = Instance.new("Weld")
    weld.Part0 = torso
    weld.Part1 = accent
    weld.C0 = CFrame.new(0.6, 0.7, 0) -- Right shoulder position
    weld.Parent = accent
    
    -- Create left shoulder accent
    local accentLeft = accent:Clone()
    accentLeft.Name = "DistrictAccentLeft"
    accentLeft.Parent = character
    
    local weldLeft = accentLeft:FindFirstChild("Weld")
    if weldLeft then
        weldLeft.C0 = CFrame.new(-0.6, 0.7, 0) -- Left shoulder position
    else
        weldLeft = Instance.new("Weld")
        weldLeft.Part0 = torso
        weldLeft.Part1 = accentLeft
        weldLeft.C0 = CFrame.new(-0.6, 0.7, 0)
        weldLeft.Parent = accentLeft
    end
end

-- Remove costume from character
function DistrictCostumes:removeCostume(player)
    local character = player.Character
    if not character then return end
    
    -- Remove district indicator
    local head = character:FindFirstChild("Head")
    if head then
        local indicator = head:FindFirstChild("DistrictIndicator")
        if indicator then
            indicator:Destroy()
        end
    end
    
    -- Remove accents
    local accent = character:FindFirstChild("DistrictAccent")
    if accent then
        accent:Destroy()
    end
    
    local accentLeft = character:FindFirstChild("DistrictAccentLeft")
    if accentLeft then
        accentLeft:Destroy()
    end
    
    print("[DistrictCostumes] Costume removed for " .. player.Name)
end

-- Initialize DistrictCostumes
function DistrictCostumes.init()
    print("[DistrictCostumes] Initializing...")
    
    -- Handle costume requests
    costumeRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}
        
        if action == "REQUEST_COSTUME" then
            -- Player requesting their costume be applied
            local district = args[1]
            if district then
                DistrictCostumes:applyDistrictCostume(player, district)
            end
        end
    end)
    
    print("[DistrictCostumes] Initialized with " .. #DISTRICT_COLORS .. " district costumes")
end

return DistrictCostumes
