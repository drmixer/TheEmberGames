
-- ModuleScript: DistrictCostumes.lua (Server)
-- Assigns realistic survivor outfits to tributes
-- Replaces neon colors with high-quality clothing assets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DistrictCostumes = {}

-- Create remote event for costume updates
local costumeRemoteEvent = Instance.new("RemoteEvent")
costumeRemoteEvent.Name = "CostumeRemoteEvent"
costumeRemoteEvent.Parent = ReplicatedStorage

-- Pool of high-quality survivor/tactical outfits (ShirtID, PantsID)
local TRIBUTE_OUTFITS = {
    {shirt = 144076358, pants = 144076468}, -- Green Camo
    {shirt = 606361074, pants = 606364287}, -- Urban Camo
    {shirt = 856424097, pants = 856424364}, -- Dark Tactical
    {shirt = 3670737444, pants = 3670737637}, -- Worn Survivor
    {shirt = 574665489, pants = 574665806}, -- Combat Green
    {shirt = 129457662, pants = 129457639}, -- Gray Fatigues
    {shirt = 1545629168, pants = 1545630664}, -- Black Ops
    {shirt = 398633519, pants = 398633812}, -- Forest Camo
    {shirt = 911252726, pants = 911252996}, -- Mercenary
    {shirt = 2526569107, pants = 2526569345}, -- Scavenger
    {shirt = 267676735, pants = 267676771}, -- Torn Clothes
    {shirt = 463777558, pants = 463777797}, -- Rebel Gear
}

-- Simplified district colors for accents/indicators
local SIMPLIFIED_DISTRICT_COLORS = {
    [1] = Color3.fromRGB(212, 175, 55), -- Gold
    [2] = Color3.fromRGB(139, 0, 0), -- Red
    [3] = Color3.fromRGB(0, 100, 200), -- Blue
    [4] = Color3.fromRGB(0, 128, 128), -- Teal
    [5] = Color3.fromRGB(255, 215, 0), -- Yellow
    [6] = Color3.fromRGB(255, 140, 0), -- Orange
    [7] = Color3.fromRGB(34, 139, 34), -- Green
    [8] = Color3.fromRGB(255, 105, 180), -- Pink
    [9] = Color3.fromRGB(245, 222, 179), -- Wheat
    [10] = Color3.fromRGB(139, 69, 19), -- Brown
    [11] = Color3.fromRGB(0, 100, 0), -- Dark Green
    [12] = Color3.fromRGB(40, 40, 40), -- Dark Gray
}

-- Body part mapping for costume application
local BODY_PARTS = {
    shirt = {"Torso", "UpperTorso", "LowerTorso"},
    pants = {"Left Leg", "Right Leg", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"},
    arms = {"Left Arm", "Right Arm", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand"}
}

-- Apply costume logic
function DistrictCostumes:applyDistrictCostume(playerOrBot, district)
    -- Handle both Player Instance and Bot Table inputs
    local character
    local playerName = "Unknown"
    local isRealPlayer = false
    
    if typeof(playerOrBot) == "Instance" and playerOrBot:IsA("Player") then
        character = playerOrBot.Character
        playerName = playerOrBot.Name
        isRealPlayer = true
    elseif type(playerOrBot) == "table" and playerOrBot.Character then
        character = playerOrBot.Character
        playerName = playerOrBot.Name or "Bot"
    end
    
    if not character then
        warn("[DistrictCostumes] No character found for " .. playerName)
        return
    end
    
    -- Pick an outfit based on district (consistent mapping)
    local outfitIndex = ((district - 1) % #TRIBUTE_OUTFITS) + 1
    local outfit = TRIBUTE_OUTFITS[outfitIndex]
    
    print("[DistrictCostumes] Applying Outfit " .. outfitIndex .. " to " .. playerName)
    
    -- Clean up existing clothing
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("CharacterMesh") then
             child:Destroy()
        end
    end
    
    -- FALLBACK: Paint the body parts first (so they aren't naked if assets fail)
    -- We use the SIMPLIFIED_DISTRICT_COLORS for this base layer
    local colors = SIMPLIFIED_DISTRICT_COLORS[district] or Color3.fromRGB(128,128,128)
    
    -- Apply shirt color (torso & arms)
    for _, partName in ipairs(BODY_PARTS.shirt) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Color = colors
            part.Material = Enum.Material.Fabric
        end
    end
    for _, partName in ipairs(BODY_PARTS.arms) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Color = colors
            part.Material = Enum.Material.Fabric -- Long sleeves
        end
    end
    
    -- Apply pants color (legs)
    for _, partName in ipairs(BODY_PARTS.pants) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Color = Color3.fromRGB(50, 50, 50) -- Dark gray/black pants base
            part.Material = Enum.Material.Fabric
        end
    end

    -- Create new Shirt (Overlays the paint)
    local shirt = Instance.new("Shirt")
    shirt.Name = "TributeShirt"
    shirt.ShirtTemplate = "rbxassetid://" .. outfit.shirt
    shirt.Parent = character
    
    -- Create new Pants (Overlays the paint)
    local pants = Instance.new("Pants")
    pants.Name = "TributePants"
    pants.PantsTemplate = "rbxassetid://" .. outfit.pants
    pants.Parent = character
    
    -- Reset Head/Face colors to skin tone (don't paint the head district color!)
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        if not isRealPlayer then
             head.Color = Color3.fromRGB(255, 204, 153)
        end
    end

    
    -- Add shoulder accent (Simple colored band for identification)
    -- Add shoulder accent (REMOVED - Causing visual glitches)
    -- DistrictCostumes:addShoulderAccent(character, SIMPLIFIED_DISTRICT_COLORS[district] or Color3.fromRGB(200, 200, 200))
    
    -- Add district indicator (billboard GUI above head)
    local head = character:FindFirstChild("Head")
    if head then
        -- Remove existing
        local existingGui = head:FindFirstChild("DistrictIndicator")
        if existingGui then existingGui:Destroy() end
        
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "DistrictIndicator"
        billboardGui.Size = UDim2.new(0, 100, 0, 30)
        billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
        billboardGui.AlwaysOnTop = false
        billboardGui.Parent = head
        
        local districtLabel = Instance.new("TextLabel")
        districtLabel.Size = UDim2.new(1, 0, 1, 0)
        districtLabel.BackgroundTransparency = 1
        districtLabel.Text = "D" .. tostring(district)
        districtLabel.TextColor3 = SIMPLIFIED_DISTRICT_COLORS[district] or Color3.fromRGB(200, 200, 200)
        districtLabel.TextStrokeTransparency = 0
        districtLabel.Font = Enum.Font.GothamBold
        districtLabel.TextScaled = true
        districtLabel.Parent = billboardGui
    end

    -- Notify client (Only if it's a real player)
    if isRealPlayer then
        costumeRemoteEvent:FireClient(playerOrBot, "COSTUME_APPLIED", district, outfit)
    end
    
    print("[DistrictCostumes] Costume applied for " .. playerName .. " - District " .. district .. " (Outfit " .. outfitIndex .. ")")
end

-- Add shoulder accent decoration
function DistrictCostumes:addShoulderAccent(character, accentColor)
    -- Disabled to prevent visual glitches (floating block)
    -- Kept stub for API compatibility
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
    
    print("[DistrictCostumes] Initialized with " .. #TRIBUTE_OUTFITS .. " tribute outfits")
end

return DistrictCostumes
