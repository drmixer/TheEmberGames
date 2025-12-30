-- ModuleScript: LootDistribution.lua (Server)
-- Balanced loot spawning and distribution system
-- Ensures fair item placement and appropriate rarity

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local ReplicatedFirst = game:GetService("ReplicatedFirst")

local LootDistribution = {}
LootDistribution.spawnedLoot = {}
LootDistribution.cornucopiaLoot = {}
LootDistribution.groundLoot = {}

-- ============ LOOT TABLES ============

-- Rarity weights (higher = more common)
local RARITY_WEIGHTS = {
    common = 50,
    uncommon = 30,
    rare = 15,
    legendary = 5,
}

-- Item definitions with rarity
local LOOT_TABLES = {
    -- WEAPONS
    weapons = {
        { id = "WoodenStick", rarity = "common", weight = 12 }, -- More junk weapons
        { id = "SharpStick", rarity = "common", weight = 10 },
        { id = "StoneKnife", rarity = "common", weight = 8 },
        { id = "HandmadeAxe", rarity = "uncommon", weight = 4 },
        { id = "Slingshot", rarity = "common", weight = 6 },
        { id = "Bow", rarity = "uncommon", weight = 3 },
        { id = "ThrowingKnife", rarity = "uncommon", weight = 4, quantity = {3, 5} },
        { id = "Machete", rarity = "rare", weight = 1 }, -- Very rare
    },
    
    -- RESOURCES
    resources = {
        { id = "Wood", rarity = "common", weight = 15, quantity = {3, 8} },
        { id = "Stone", rarity = "common", weight = 12, quantity = {2, 6} },
        { id = "Rope", rarity = "common", weight = 10, quantity = {1, 3} },
        { id = "Leaves", rarity = "common", weight = 15, quantity = {5, 12} },
        { id = "Flint", rarity = "uncommon", weight = 6, quantity = {1, 2} },
        { id = "Feathers", rarity = "common", weight = 8, quantity = {3, 6} },
        { id = "BerryBush", rarity = "common", weight = 10, quantity = {2, 5} },
    },
    
    -- CONSUMABLES
    consumables = {
        { id = "Water", rarity = "common", weight = 12, thirstRestore = 30 },
        { id = "Berries", rarity = "common", weight = 10, hungerRestore = 15 },
        { id = "CookedMeat", rarity = "uncommon", weight = 5, hungerRestore = 40 },
        { id = "Bandage", rarity = "uncommon", weight = 6, healthRestore = 25 },
        { id = "MedicineHerb", rarity = "rare", weight = 3, healthRestore = 50 },
        { id = "PurifiedWater", rarity = "uncommon", weight = 4, thirstRestore = 60 },
    },
    
    -- TRAPS
    traps = {
        { id = "TripwireTrap", rarity = "uncommon", weight = 4 },
        { id = "FireTrap", rarity = "rare", weight = 2 },
        { id = "PoisonBerry", rarity = "rare", weight = 2 },
    },
    
    -- AMMO
    ammo = {
        { id = "Rock", rarity = "common", weight = 10, quantity = {5, 10} },
        { id = "Arrow", rarity = "common", weight = 8, quantity = {3, 6} },
        { id = "FireArrow", rarity = "uncommon", weight = 3, quantity = {1, 3} },
        { id = "PoisonArrow", rarity = "rare", weight = 2, quantity = {1, 2} },
    },
}

-- Location-specific loot tables
local LOCATION_LOOT = {
    cornucopia = {
        -- Higher tier loot at cornucopia
        weapons = 0.40,
        resources = 0.15,
        consumables = 0.25,
        traps = 0.10,
        ammo = 0.10,
        rarityBonus = 1.8, -- 80% more likely to get rare items
    },
    ground = {
        -- Basic loot around the arena (SCARCER WEAPONS)
        weapons = 0.10, -- Reduced from 0.15
        resources = 0.50, -- Mostly resources
        consumables = 0.20,
        traps = 0.05,
        ammo = 0.15,
        rarityBonus = 0.8, -- Less likely to get rare items
    },
    supplyDrop = {
        -- Best loot from supply drops
        weapons = 0.50, -- 50% chance of weapon
        resources = 0.05,
        consumables = 0.30, -- High chance of healing
        traps = 0.05,
        ammo = 0.10,
        rarityBonus = 3.0, -- 200% more likely to get rare items
    },
}

-- ============ SPAWN CONFIGURATION ============

local SPAWN_CONFIG = {
    -- Cornucopia items
    CORNUCOPIA_ITEM_COUNT = 48,  -- Items at center (2 per player for 24)
    CORNUCOPIA_RADIUS = 30,       -- Radius around center to spawn
    
    -- Ground loot (SIGNIFICANTLY REDUCED DENSITY)
    -- Was 0.0001 (~100 items), now 0.00004 (~40 items)
    GROUND_LOOT_DENSITY = 0.00004,   
    ARENA_SIZE = 1024,
    MIN_DISTANCE_BETWEEN_LOOT = 25, -- Increased spread distance
    
    -- Per-biome adjustments
    BIOME_LOOT_MULTIPLIERS = {
        forest = 1.2,    -- More resources in forest
        meadow = 1.0,
        river = 0.8,     -- Less loot near water
        swamp = 0.9,
        cliffs = 0.7,    -- Hard to find loot on cliffs
        desert = 0.6,    -- Scarce in desert
        mountains = 0.5, -- Very scarce in mountains
    },
}

-- ============ WEIGHTED RANDOM SELECTION ============

local function weightedRandom(items, rarityBonus)
    rarityBonus = rarityBonus or 1.0
    
    -- Calculate total weight
    local totalWeight = 0
    for _, item in ipairs(items) do
        local weight = item.weight
        -- Apply rarity bonus for rare/legendary items
        if item.rarity == "rare" or item.rarity == "legendary" then
            weight = weight * rarityBonus
        -- Apply negative bonus for common if bonus is high? No, simple multiplier is safer
        elseif item.rarity == "common" and rarityBonus > 1.5 then
            weight = weight * 0.8 -- Reduce common chance slightly in high-tier zones
        end
        totalWeight = totalWeight + weight
    end
    
    -- Select random item
    local rand = math.random() * totalWeight
    local cumulative = 0
    
    for _, item in ipairs(items) do
        local weight = item.weight
        if item.rarity == "rare" or item.rarity == "legendary" then
            weight = weight * rarityBonus
        elseif item.rarity == "common" and rarityBonus > 1.5 then
            weight = weight * 0.8
        end
        cumulative = cumulative + weight
        if rand <= cumulative then
            return item
        end
    end
    
    return items[1] -- Fallback
end

local function selectCategory(locationConfig)
    local rand = math.random()
    local cumulative = 0
    
    for category, chance in pairs(locationConfig) do
        if category ~= "rarityBonus" then
            cumulative = cumulative + chance
            if rand <= cumulative then
                return category
            end
        end
    end
    
    return "resources" -- Fallback
end

-- ============ LOOT GENERATION ============

function LootDistribution:generateLootItem(locationType)
    local locationConfig = LOCATION_LOOT[locationType] or LOCATION_LOOT.ground
    
    -- Select category
    local category = selectCategory(locationConfig)
    local lootTable = LOOT_TABLES[category]
    
    if not lootTable or #lootTable == 0 then
        return nil
    end
    
    -- Select item from category
    local item = weightedRandom(lootTable, locationConfig.rarityBonus)
    
    -- Generate quantity if applicable
    local quantity = 1
    if item.quantity then
        quantity = math.random(item.quantity[1], item.quantity[2])
        -- Supply drops give max quantity
        if locationType == "supplyDrop" then
            quantity = item.quantity[2]
        end
    end
    
    return {
        id = item.id,
        category = category,
        rarity = item.rarity,
        quantity = quantity,
        properties = {
            hungerRestore = item.hungerRestore,
            thirstRestore = item.thirstRestore,
            healthRestore = item.healthRestore,
        },
    }
end

-- ============ CREATION HELPER ============

function LootDistribution:createLootCrate(item)
    local lootFolder = workspace:FindFirstChild("Loot") or Instance.new("Folder")
    lootFolder.Name = "Loot"
    lootFolder.Parent = workspace
    
    local crate = Instance.new("Part")
    crate.Name = "Loot_" .. item.id
    crate.Size = Vector3.new(1.5, 1.5, 1.5)
    crate.Position = item.position or Vector3.new(0, 10, 0)
    crate.Anchored = true
    crate.CanCollide = false -- Don't trip players
    crate.Material = Enum.Material.Plastic
    
    -- Color coding
    if item.category == "weapons" then
        crate.Color = Color3.fromRGB(255, 100, 100) -- Red for weapons
    elseif item.category == "consumables" then
        crate.Color = Color3.fromRGB(100, 255, 100) -- Green
    else
        crate.Color = Color3.fromRGB(200, 200, 200) -- White
    end
    
    -- Add visual mesh if possible (simple shapes)
    if item.category == "weapons" then
        crate.Shape = Enum.PartType.Block
    else
        crate.Shape = Enum.PartType.Ball
    end
    
    crate.Parent = lootFolder
    item.crate = crate
    
    -- Billboard UI for rarity/name
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.Adornee = crate
    billboard.AlwaysOnTop = false -- Keep it realistic
    billboard.MaxDistance = 30 -- Only show when close
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = item.id .. "\n" .. (item.quantity > 1 and "x"..item.quantity or "")
    label.TextColor3 = Color3.new(1,1,1)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard
    billboard.Parent = crate
    
    -- ProximityPrompt for interaction
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Pick Up"
    prompt.ObjectText = item.id
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.Parent = crate
    
    prompt.Triggered:Connect(function(player)
        self:pickupLoot(player, crate, item)
    end)
    
    table.insert(self.spawnedLoot, item)
end

-- ============ CORNUCOPIA LOOT ============

function LootDistribution:spawnCornucopiaLoot(centerPosition)
    print("[LootDistribution] Spawning Cornucopia loot on Pedestals...")
    
    local spawnedItems = {}
    
    -- Find pedestals in MapBase
    local mapBase = workspace:FindFirstChild("MapBase")
    local pedestals = {}
    
    if mapBase then
        for _, child in ipairs(mapBase:GetChildren()) do
            if child.Name == "Pedestal" then
                table.insert(pedestals, child)
            end
        end
    end
    
    if #pedestals == 0 then
        warn("[LootDistribution] No pedestals found! Falling back to ring generation.")
        -- Fallback to old logic if no pedestals
        local itemCount = SPAWN_CONFIG.CORNUCOPIA_ITEM_COUNT
        for i = 1, itemCount do
            local item = self:generateLootItem("cornucopia")
            if item then
                local angle = (i / itemCount) * math.pi * 2
                local radius = SPAWN_CONFIG.CORNUCOPIA_RADIUS * (0.5 + math.random() * 0.5)
                local position = centerPosition + Vector3.new(
                    math.cos(angle) * radius,
                    1,
                    math.sin(angle) * radius
                )
                item.position = position
                table.insert(spawnedItems, item)
                self:createLootCrate(item)
            end
        end
    else
        print("[LootDistribution] Found " .. #pedestals .. " pedestals.")
        for _, pedestal in ipairs(pedestals) do
            -- Generate a weapon specifically for pedestals often
            local item = self:generateLootItem("cornucopia") 
            -- Force weapon for pedestals to ensure good start
            if math.random() < 0.7 then -- 70% chance to be weapon on pedestal
                 local weaponTable = LOOT_TABLES.weapons
                 local selectedWeapon = weightedRandom(weaponTable, 1.5)
                 
                 -- Calculate quantity (default 1, or random range if defined)
                 local qty = 1
                 if selectedWeapon.quantity then
                     qty = math.random(selectedWeapon.quantity[1], selectedWeapon.quantity[2])
                 end

                 item = {
                    id = selectedWeapon.id,
                    category = "weapons",
                    rarity = selectedWeapon.rarity,
                    quantity = qty
                 }
            end

            if item then
                -- Place ON TOP of pedestal
                item.position = pedestal.Position + Vector3.new(0, pedestal.Size.Y/2 + 0.75, 0)
                table.insert(spawnedItems, item)
                self:createLootCrate(item)
            end
        end
    end
    
    self.cornucopiaLoot = spawnedItems
    print("[LootDistribution] Spawned " .. #spawnedItems .. " items at Cornucopia")
    
    return spawnedItems
end

-- ============ GROUND LOOT ============

function LootDistribution:spawnGroundLoot(arenaSize)
    print("[LootDistribution] Spawning ground loot across arena (SCARCE)...")
    
    local spawnedItems = {}
    local halfSize = arenaSize / 2
    local gridSize = SPAWN_CONFIG.MIN_DISTANCE_BETWEEN_LOOT
    
    local totalArea = arenaSize * arenaSize
    local baseLootCount = math.floor(totalArea * SPAWN_CONFIG.GROUND_LOOT_DENSITY)
    
    print("[LootDistribution] Target ground loot count: " .. baseLootCount)
    
    local attempts = 0
    local maxAttempts = baseLootCount * 20 -- Needs many attempts to find good spots
    
    -- Raycast params
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    local mapGeometry = workspace:FindFirstChild("MapGeometry")
    local mapBase = workspace:FindFirstChild("MapBase")
    local filterList = {}
    if mapGeometry then table.insert(filterList, mapGeometry) end
    if mapBase then table.insert(filterList, mapBase) end
    rayParams.FilterDescendantsInstances = filterList
    
    while #spawnedItems < baseLootCount and attempts < maxAttempts do
        attempts = attempts + 1
        local x = math.random(-halfSize + 50, halfSize - 50)
        local z = math.random(-halfSize + 50, halfSize - 50)
        
        -- Raycast to find ground
        local origin = Vector3.new(x, 200, z)
        local direction = Vector3.new(0, -300, 0)
        local rayResult = workspace:Raycast(origin, direction, rayParams)
        
        if rayResult and rayResult.Position.Y > -5 then -- Don't spawn in water
             local position = rayResult.Position + Vector3.new(0, 1, 0)
        
            local tooClose = false
            for _, existingItem in ipairs(spawnedItems) do
                if (existingItem.position - position).Magnitude < gridSize then
                    tooClose = true
                    break
                end
            end
            if position.Magnitude < SPAWN_CONFIG.CORNUCOPIA_RADIUS * 2 then tooClose = true end
            
            if not tooClose then
                local item = self:generateLootItem("ground")
                if item then
                    item.position = position
                    table.insert(spawnedItems, item)
                    self:createLootCrate(item)
                end
            end
        end
    end
    self.groundLoot = spawnedItems
    print("[LootDistribution] Spawned " .. #spawnedItems .. " ground loot items")
    return spawnedItems
end

-- ============ SUPPLY DROP LOOT ============

function LootDistribution:spawnSupplyDrop(position, dropId)
    print("[LootDistribution] Creating Supply Drop interaction at " .. tostring(position))
    
    -- Create invisible trigger part that acts as the "Crate" for interaction
    -- Visuals are handled by Client (SupplyDropVisuals.lua)
    
    local dropTrigger = Instance.new("Part")
    dropTrigger.Name = "SupplyDropTrigger_" .. (dropId or "Unknown")
    dropTrigger.Size = Vector3.new(6, 6, 6)
    dropTrigger.Position = position + Vector3.new(0, 3, 0)
    dropTrigger.Transparency = 1
    dropTrigger.Anchored = true
    dropTrigger.CanCollide = false
    dropTrigger.Parent = workspace
    
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Open Supply Crate"
    prompt.ObjectText = "High-Tier Loot"
    prompt.HoldDuration = 2.0 -- Takes time to open
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = dropTrigger
    
    prompt.Triggered:Connect(function(player)
        print("[LootDistribution] Supply Drop opened by " .. player.Name)
        
        -- Disconnect listener immediately
        prompt.Enabled = false
        dropTrigger:Destroy()
        
        -- Fire event for visuals (animation, sound)
        local eventsRemote = ReplicatedStorage:FindFirstChild("EventsRemoteEvent")
        if eventsRemote then
            eventsRemote:FireAllClients("SUPPLY_DROP_OPENED", dropId)
        end
        
        -- Spawn high tier loot
        self:spawnSupplyDropLoot(position)
    end)
    
    -- Auto-cleanup if not opened in 10 minutes
    Debris:AddItem(dropTrigger, 600)
end

function LootDistribution:spawnSupplyDropLoot(centerPosition)
    local itemCount = math.random(4, 6)
    
    for i = 1, itemCount do
        -- Generate HIGH TIER item
        local item = self:generateLootItem("supplyDrop")
        
        if item then
            -- Scatter around
            local angle = (i / itemCount) * math.pi * 2 + math.random()
            local radius = math.random(5, 10)
            local offset = Vector3.new(math.cos(angle) * radius, 1, math.sin(angle) * radius)
            local pos = centerPosition + offset
            
            -- Raycast to snap to ground
            local rayOrigin = pos + Vector3.new(0, 5, 0)
            local rayRes = workspace:Raycast(rayOrigin, Vector3.new(0, -10, 0))
            if rayRes then
                item.position = rayRes.Position + Vector3.new(0, 1, 0)
            else
                item.position = pos
            end
            
            self:createLootCrate(item)
            
            -- Add visual effect to loot (Glow)
            if item.crate then
                 local highlight = Instance.new("Highlight")
                 highlight.FillColor = Color3.fromRGB(255, 215, 0)
                 highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                 highlight.FillTransparency = 0.5
                 highlight.OutlineTransparency = 0
                 highlight.Parent = item.crate
            end
        end
    end
end

-- ============ LOOT PICKUP ============

function LootDistribution:pickupLoot(player, crate, itemData)
    if not crate or not crate.Parent then return end
    
    -- 1. Give to Inventory (Data/UI)
    local success, InventoryController = pcall(function()
        return require(script.Parent.InventoryController)
    end)
    
    local inventorySuccess = false
    if success and InventoryController then
        inventorySuccess = InventoryController:addItem(player, itemData.id, itemData.quantity)
    end
    
    -- 2. If it's a weapon, ALSO give the Tool
    if inventorySuccess or (not success) then
         if itemData.category == "weapons" then
            local weaponSuccess, WeaponSystem = pcall(function()
                return require(script.Parent.WeaponSystem)
            end)
            if weaponSuccess and WeaponSystem then
                -- Give the weapon (multiple times if quantity > 1, e.g. Throwing Knives)
                local count = itemData.quantity or 1
                for i = 1, count do
                    WeaponSystem:giveWeapon(player, itemData.id)
                end
                
                -- Give Starter Ammo for Ranged Weapons
                if itemData.id == "Bow" then
                     InventoryController:addItem(player, "Arrow", 5)
                     -- Notification for ammo
                     local pickupRemote = ReplicatedStorage:FindFirstChild("LootRemote")
                     if pickupRemote then
                        pickupRemote:FireClient(player, "PICKUP", {id="Arrow", quantity=5, category="ammo"})
                     end
                elseif itemData.id == "Slingshot" then
                     InventoryController:addItem(player, "SlingshotAmmo", 10)
                     local pickupRemote = ReplicatedStorage:FindFirstChild("LootRemote")
                     if pickupRemote then
                        pickupRemote:FireClient(player, "PICKUP", {id="SlingshotAmmo", quantity=10, category="ammo"})
                     end
                end
            end
        end
        
        -- Success flow
        local audioSuccess, AudioService = pcall(function()
            return require(script.Parent.AudioService)
        end)
        if audioSuccess and AudioService then
            AudioService:playPickupSound(itemData.category or "loot", player)
        end
        
        local pickupRemote = ReplicatedStorage:FindFirstChild("LootRemote")
        if pickupRemote then
            pickupRemote:FireClient(player, "PICKUP", itemData)
        end
        
        crate:Destroy()
        
        for i, item in ipairs(self.spawnedLoot) do
            if item.crate == crate then
                table.remove(self.spawnedLoot, i)
                break
            end
        end
        
    else
        -- Inventory Full
        local pickupRemote = ReplicatedStorage:FindFirstChild("LootRemote")
        if pickupRemote then
            pickupRemote:FireClient(player, "INVENTORY_FULL")
        end
    end
end

-- ============ RESPAWN LOGIC ============

function LootDistribution:respawnLoot()
    -- Clear existing loot
    local lootFolder = workspace:FindFirstChild("Loot")
    if lootFolder then
        lootFolder:ClearAllChildren()
    end
    
    self.cornucopiaLoot = {}
    self.groundLoot = {}
    self.spawnedLoot = {}
    
    -- Respawn all loot
    self:spawnCornucopiaLoot(Vector3.new(0, 5, 0))
    self:spawnGroundLoot(SPAWN_CONFIG.ARENA_SIZE)
    
    -- Combine all loot tracking
    for _, item in ipairs(self.cornucopiaLoot) do
        table.insert(self.spawnedLoot, item)
    end
    for _, item in ipairs(self.groundLoot) do
        table.insert(self.spawnedLoot, item)
    end
end

-- ============ INITIALIZATION ============

function LootDistribution.init()
    print("[LootDistribution] Initializing...")
    
    -- Create remote event for loot notifications
    local lootRemote = Instance.new("RemoteEvent")
    lootRemote.Name = "LootRemote"
    lootRemote.Parent = ReplicatedStorage
    
    print("[LootDistribution] Initialized - ready to spawn loot")
end

return LootDistribution
