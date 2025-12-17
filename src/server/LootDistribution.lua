-- ModuleScript: LootDistribution.lua (Server)
-- Balanced loot spawning and distribution system
-- Ensures fair item placement and appropriate rarity

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
        { id = "WoodenStick", rarity = "common", weight = 10 },
        { id = "SharpStick", rarity = "common", weight = 8 },
        { id = "StoneKnife", rarity = "common", weight = 8 },
        { id = "HandmadeAxe", rarity = "uncommon", weight = 5 },
        { id = "Slingshot", rarity = "common", weight = 7 },
        { id = "Bow", rarity = "uncommon", weight = 4 },
        { id = "ThrowingKnife", rarity = "uncommon", weight = 6 },
        { id = "Machete", rarity = "rare", weight = 2 },
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
        weapons = 0.35,
        resources = 0.20,
        consumables = 0.25,
        traps = 0.10,
        ammo = 0.10,
        rarityBonus = 1.5, -- 50% more likely to get rare items
    },
    ground = {
        -- Basic loot around the arena
        weapons = 0.15,
        resources = 0.40,
        consumables = 0.25,
        traps = 0.05,
        ammo = 0.15,
        rarityBonus = 1.0,
    },
    supplyDrop = {
        -- Best loot from supply drops
        weapons = 0.40,
        resources = 0.10,
        consumables = 0.30,
        traps = 0.10,
        ammo = 0.10,
        rarityBonus = 2.0, -- 100% more likely to get rare items
    },
}

-- ============ SPAWN CONFIGURATION ============

local SPAWN_CONFIG = {
    -- Cornucopia items
    CORNUCOPIA_ITEM_COUNT = 48,  -- Items at center (2 per player for 24)
    CORNUCOPIA_RADIUS = 30,       -- Radius around center to spawn
    
    -- Ground loot
    GROUND_LOOT_DENSITY = 0.05,   -- Items per square stud
    ARENA_SIZE = 1024,
    MIN_DISTANCE_BETWEEN_LOOT = 15,
    
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

-- ============ CORNUCOPIA LOOT ============

function LootDistribution:spawnCornucopiaLoot(centerPosition)
    print("[LootDistribution] Spawning Cornucopia loot...")
    
    local spawnedItems = {}
    local itemCount = SPAWN_CONFIG.CORNUCOPIA_ITEM_COUNT
    
    for i = 1, itemCount do
        local item = self:generateLootItem("cornucopia")
        if item then
            -- Calculate position in ring around cornucopia
            local angle = (i / itemCount) * math.pi * 2
            local radius = SPAWN_CONFIG.CORNUCOPIA_RADIUS * (0.5 + math.random() * 0.5)
            local position = centerPosition + Vector3.new(
                math.cos(angle) * radius,
                1, -- Slightly above ground
                math.sin(angle) * radius
            )
            
            item.position = position
            table.insert(spawnedItems, item)
            
            -- Create visual loot crate
            self:createLootCrate(item)
        end
    end
    
    self.cornucopiaLoot = spawnedItems
    print("[LootDistribution] Spawned " .. #spawnedItems .. " items at Cornucopia")
    
    return spawnedItems
end

-- ============ GROUND LOOT ============

function LootDistribution:spawnGroundLoot(arenaSize)
    print("[LootDistribution] Spawning ground loot across arena...")
    
    local spawnedItems = {}
    local halfSize = arenaSize / 2
    local gridSize = SPAWN_CONFIG.MIN_DISTANCE_BETWEEN_LOOT
    
    -- Calculate base loot count
    local totalArea = arenaSize * arenaSize
    local baseLootCount = math.floor(totalArea * SPAWN_CONFIG.GROUND_LOOT_DENSITY)
    
    -- Spawn in grid pattern with randomization
    local attempts = 0
    local maxAttempts = baseLootCount * 3
    
    while #spawnedItems < baseLootCount and attempts < maxAttempts do
        attempts = attempts + 1
        
        -- Random position
        local x = math.random(-halfSize + 50, halfSize - 50)
        local z = math.random(-halfSize + 50, halfSize - 50)
        local position = Vector3.new(x, 1, z)
        
        -- Check minimum distance from other loot
        local tooClose = false
        for _, existingItem in ipairs(spawnedItems) do
            if (existingItem.position - position).Magnitude < gridSize then
                tooClose = true
                break
            end
        end
        
        -- Skip center area (cornucopia)
        if position.Magnitude < SPAWN_CONFIG.CORNUCOPIA_RADIUS * 2 then
            tooClose = true
        end
        
        if not tooClose then
            local item = self:generateLootItem("ground")
            if item then
                item.position = position
                table.insert(spawnedItems, item)
                
                -- Create visual for ground loot
                self:createLootCrate(item)
            end
        end
    end
    
    self.groundLoot = spawnedItems
    print("[LootDistribution] Spawned " .. #spawnedItems .. " ground loot items")
    
    return spawnedItems
end

-- ============ SUPPLY DROP LOOT ============

function LootDistribution:generateSupplyDropLoot()
    local items = {}
    local itemCount = math.random(3, 5) -- 3-5 items per supply drop
    
    for i = 1, itemCount do
        local item = self:generateLootItem("supplyDrop")
        if item then
            table.insert(items, item)
        end
    end
    
    return items
end

-- ============ VISUAL LOOT CREATION ============

function LootDistribution:createLootCrate(itemData)
    local crate = Instance.new("Part")
    crate.Name = "LootCrate_" .. itemData.id
    crate.Size = Vector3.new(2, 1.5, 2)
    crate.Position = itemData.position
    crate.Anchored = true
    crate.CanCollide = true
    
    -- Color based on rarity
    if itemData.rarity == "legendary" then
        crate.Color = Color3.fromRGB(255, 215, 0) -- Gold
        crate.Material = Enum.Material.Neon
    elseif itemData.rarity == "rare" then
        crate.Color = Color3.fromRGB(138, 43, 226) -- Purple
        crate.Material = Enum.Material.SmoothPlastic
    elseif itemData.rarity == "uncommon" then
        crate.Color = Color3.fromRGB(65, 105, 225) -- Blue
        crate.Material = Enum.Material.SmoothPlastic
    else
        crate.Color = Color3.fromRGB(139, 90, 43) -- Brown
        crate.Material = Enum.Material.Wood
    end
    
    -- Store item data
    crate:SetAttribute("ItemId", itemData.id)
    crate:SetAttribute("Category", itemData.category)
    crate:SetAttribute("Rarity", itemData.rarity)
    crate:SetAttribute("Quantity", itemData.quantity)
    
    -- Add interaction prompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Pick Up"
    prompt.ObjectText = itemData.id .. (itemData.quantity > 1 and (" x" .. itemData.quantity) or "")
    prompt.MaxActivationDistance = 8
    prompt.HoldDuration = 0.5
    prompt.Parent = crate
    
    -- Handle pickup
    prompt.Triggered:Connect(function(player)
        self:pickupLoot(player, crate, itemData)
    end)
    
    -- Find or create loot folder
    local lootFolder = workspace:FindFirstChild("Loot")
    if not lootFolder then
        lootFolder = Instance.new("Folder")
        lootFolder.Name = "Loot"
        lootFolder.Parent = workspace
    end
    
    crate.Parent = lootFolder
    itemData.crate = crate
    
    return crate
end

-- ============ LOOT PICKUP ============

function LootDistribution:pickupLoot(player, crate, itemData)
    if not crate or not crate.Parent then return end
    
    -- Get inventory controller
    local success, InventoryController = pcall(function()
        return require(script.Parent.InventoryController)
    end)
    
    if success and InventoryController then
        -- Add to inventory
        local added = InventoryController:addItem(player, itemData.id, itemData.quantity)
        
        if added then
            -- Play pickup sound via AudioService
            local audioSuccess, AudioService = pcall(function()
                return require(script.Parent.AudioService)
            end)
            
            if audioSuccess and AudioService then
                AudioService:playPickupSound(crate.Position, itemData.rarity)
            end
            
            -- Notify player
            local pickupRemote = ReplicatedStorage:FindFirstChild("LootRemote")
            if pickupRemote then
                pickupRemote:FireClient(player, "PICKUP", itemData)
            end
            
            -- Remove crate
            crate:Destroy()
            
            -- Remove from tracking
            for i, item in ipairs(self.spawnedLoot) do
                if item.crate == crate then
                    table.remove(self.spawnedLoot, i)
                    break
                end
            end
        else
            -- Inventory full notification
            local pickupRemote = ReplicatedStorage:FindFirstChild("LootRemote")
            if pickupRemote then
                pickupRemote:FireClient(player, "INVENTORY_FULL")
            end
        end
    else
        -- Fallback: just give weapon if it's a weapon
        if itemData.category == "weapons" then
            local weaponSuccess, WeaponSystem = pcall(function()
                return require(script.Parent.WeaponSystem)
            end)
            
            if weaponSuccess and WeaponSystem then
                WeaponSystem:giveWeapon(player, itemData.id)
                crate:Destroy()
            end
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
