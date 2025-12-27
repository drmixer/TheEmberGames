-- ModuleScript: BiomeResources.lua
-- Defines biome-specific resources that can only be found in certain areas
-- Adds exploration incentive and strategic depth to crafting

local BiomeResources = {}

-- ============ RESOURCE DEFINITIONS ============
-- Each resource has: displayName, description, rarity, gatherTime, stackSize

BiomeResources.resources = {
    -- ============ UNIVERSAL RESOURCES ============
    -- Found in most biomes
    Wood = {
        displayName = "Wood",
        description = "Basic wood. Found everywhere trees grow.",
        icon = "🪵",
        rarity = "common",
        gatherTime = 1.5,
        stackSize = 50,
        biomes = {"forest", "meadow", "swamp", "cliff", "jungle"},
    },
    Stone = {
        displayName = "Stone",
        description = "Common stone. Found near rocky areas.",
        icon = "🪨",
        rarity = "common",
        gatherTime = 2,
        stackSize = 50,
        biomes = {"cliff", "mountain", "desert", "volcanic", "urban"},
    },
    Stick = {
        displayName = "Stick",
        description = "A small stick. Gathered from underbrush.",
        icon = "🌿",
        rarity = "common",
        gatherTime = 0.5,
        stackSize = 99,
        biomes = {"forest", "meadow", "swamp", "jungle"},
    },
    Vines = {
        displayName = "Vines",
        description = "Flexible vines for crafting.",
        icon = "🌱",
        rarity = "common",
        gatherTime = 1,
        stackSize = 30,
        biomes = {"forest", "swamp", "jungle"},
    },
    Cloth = {
        displayName = "Cloth",
        description = "Scrap cloth from abandoned supplies.",
        icon = "🧵",
        rarity = "uncommon",
        gatherTime = 1,
        stackSize = 20,
        biomes = {"urban", "cornucopia"},
    },
    
    -- ============ FOREST BIOME ============
    HardWood = {
        displayName = "Hard Wood",
        description = "Dense, quality wood from old forest trees. Makes better weapons.",
        icon = "🌳",
        rarity = "uncommon",
        gatherTime = 3,
        stackSize = 30,
        biomes = {"forest"},
        bonuses = { durabilityBonus = 1.25 }, -- +25% durability on crafted items
    },
    Herbs = {
        displayName = "Forest Herbs",
        description = "Medicinal herbs found in the forest undergrowth.",
        icon = "🌿",
        rarity = "uncommon",
        gatherTime = 2,
        stackSize = 20,
        biomes = {"forest", "meadow"},
    },
    Feather = {
        displayName = "Feather",
        description = "Bird feathers for fletching arrows.",
        icon = "🪶",
        rarity = "common",
        gatherTime = 0.5,
        stackSize = 50,
        biomes = {"forest", "meadow", "jungle"},
    },
    Kindling = {
        displayName = "Kindling",
        description = "Dry leaves and twigs for starting fires.",
        icon = "🍂",
        rarity = "common",
        gatherTime = 1,
        stackSize = 30,
        biomes = {"forest", "meadow"},
    },
    
    -- ============ MOUNTAIN / FROZEN BIOME ============
    FrozenStone = {
        displayName = "Frozen Stone",
        description = "Ice-hardened stone from the tundra. Extra damage on crafted weapons.",
        icon = "❄️",
        rarity = "uncommon",
        gatherTime = 3,
        stackSize = 25,
        biomes = {"mountain", "frozen"},
        bonuses = { damageBonus = 1.15 }, -- +15% damage
    },
    IceFragment = {
        displayName = "Ice Fragment",
        description = "Pure ice that can slow enemies.",
        icon = "🧊",
        rarity = "rare",
        gatherTime = 2.5,
        stackSize = 15,
        biomes = {"frozen"},
        bonuses = { slowEffect = 2 }, -- 2 second slow on hit
    },
    PineResin = {
        displayName = "Pine Resin",
        description = "Sticky resin for firestarting and crafting.",
        icon = "🫧",
        rarity = "uncommon",
        gatherTime = 2,
        stackSize = 20,
        biomes = {"mountain", "forest"},
    },
    
    -- ============ VOLCANIC BIOME ============
    VolcanicRock = {
        displayName = "Volcanic Rock",
        description = "Heat-forged obsidian. Creates weapons with burning effect.",
        icon = "🔥",
        rarity = "rare",
        gatherTime = 4,
        stackSize = 15,
        biomes = {"volcanic"},
        bonuses = { burnChance = 0.20, burnDuration = 3 }, -- 20% burn chance
    },
    Sulfur = {
        displayName = "Sulfur",
        description = "Yellow mineral for explosive traps.",
        icon = "💛",
        rarity = "uncommon",
        gatherTime = 2,
        stackSize = 20,
        biomes = {"volcanic"},
    },
    Coal = {
        displayName = "Coal",
        description = "Fuel for fires and crafting.",
        icon = "⚫",
        rarity = "common",
        gatherTime = 1.5,
        stackSize = 40,
        biomes = {"volcanic", "mountain", "urban"},
    },
    
    -- ============ JUNGLE BIOME ============
    ToxicBlossom = {
        displayName = "Toxic Blossom",
        description = "Poisonous flower petals. Coat weapons for poison damage.",
        icon = "🌺",
        rarity = "rare",
        gatherTime = 2,
        stackSize = 10,
        biomes = {"jungle"},
        bonuses = { poisonChance = 0.25, poisonDuration = 5 },
    },
    BambooStalk = {
        displayName = "Bamboo Stalk",
        description = "Strong, flexible bamboo for superior spears and bows.",
        icon = "🎋",
        rarity = "uncommon",
        gatherTime = 2,
        stackSize = 20,
        biomes = {"jungle"},
        bonuses = { attackSpeedBonus = 1.10 }, -- +10% attack speed
    },
    NightmareBerry = {
        displayName = "Nightmare Berry",
        description = "Extremely toxic berries for poison crafting.",
        icon = "🫐",
        rarity = "rare",
        gatherTime = 1.5,
        stackSize = 10,
        biomes = {"jungle", "swamp"},
    },
    
    -- ============ SWAMP BIOME ============
    MangroveRoot = {
        displayName = "Mangrove Root",
        description = "Tangled roots that make durable bindings.",
        icon = "🌿",
        rarity = "uncommon",
        gatherTime = 2.5,
        stackSize = 20,
        biomes = {"swamp"},
        bonuses = { durabilityBonus = 1.15 },
    },
    MudClay = {
        displayName = "Mud Clay",
        description = "Thick clay for crafting and camouflage.",
        icon = "🟤",
        rarity = "common",
        gatherTime = 1,
        stackSize = 40,
        biomes = {"swamp"},
    },
    GlowMoss = {
        displayName = "Glow Moss",
        description = "Luminescent moss that provides faint light.",
        icon = "✨",
        rarity = "uncommon",
        gatherTime = 1.5,
        stackSize = 20,
        biomes = {"swamp", "jungle"},
    },
    
    -- ============ DESERT BIOME ============
    Flint = {
        displayName = "Flint",
        description = "Sharp, chippable stone for arrowheads and fire-starting.",
        icon = "🔶",
        rarity = "uncommon",
        gatherTime = 2,
        stackSize = 30,
        biomes = {"desert", "cliff"},
    },
    CactusFiber = {
        displayName = "Cactus Fiber",
        description = "Tough plant fibers for rope and bindings.",
        icon = "🌵",
        rarity = "common",
        gatherTime = 1.5,
        stackSize = 30,
        biomes = {"desert"},
    },
    SandStone = {
        displayName = "Sandstone",
        description = "Soft stone that's easy to shape.",
        icon = "🟨",
        rarity = "common",
        gatherTime = 1.5,
        stackSize = 40,
        biomes = {"desert"},
    },
    
    -- ============ URBAN / RUINS BIOME ============
    ScrapMetal = {
        displayName = "Scrap Metal",
        description = "Metal salvage from ruins. Superior weapon material.",
        icon = "⚙️",
        rarity = "uncommon",
        gatherTime = 3,
        stackSize = 20,
        biomes = {"urban"},
        bonuses = { damageBonus = 1.20 },
    },
    Wire = {
        displayName = "Wire",
        description = "Copper wire for traps and electronics.",
        icon = "➰",
        rarity = "uncommon",
        gatherTime = 2,
        stackSize = 25,
        biomes = {"urban"},
    },
    GlassShard = {
        displayName = "Glass Shard",
        description = "Sharp glass for makeshift weapons.",
        icon = "💎",
        rarity = "common",
        gatherTime = 1,
        stackSize = 30,
        biomes = {"urban"},
        bonuses = { bleedChance = 0.30, bleedDuration = 4 },
    },
    Metal = {
        displayName = "Metal",
        description = "Sturdy metal scrap.",
        icon = "🔩",
        rarity = "uncommon",
        gatherTime = 2.5,
        stackSize = 20,
        biomes = {"urban", "cornucopia"},
    },
    
    -- ============ WATER BIOME ============
    WaterSource = {
        displayName = "Water Source",
        description = "Clean water for drinking and crafting.",
        icon = "💧",
        rarity = "common",
        gatherTime = 2,
        stackSize = 10,
        biomes = {"water", "swamp"},
    },
    ReedStalk = {
        displayName = "Reed Stalk",
        description = "Hollow reeds for blowguns and dart tubes.",
        icon = "🌾",
        rarity = "common",
        gatherTime = 1,
        stackSize = 30,
        biomes = {"water", "swamp", "meadow"},
    },
    Fish = {
        displayName = "Fish",
        description = "Fresh fish for eating.",
        icon = "🐟",
        rarity = "uncommon",
        gatherTime = 3,
        stackSize = 10,
        biomes = {"water"},
    },
    
    -- ============ CONSUMABLES ============
    Berry = {
        displayName = "Berry",
        description = "Edible berries that restore hunger.",
        icon = "🍇",
        rarity = "common",
        gatherTime = 0.5,
        stackSize = 20,
        biomes = {"forest", "meadow", "jungle"},
    },
    Mushroom = {
        displayName = "Mushroom",
        description = "Edible mushroom.",
        icon = "🍄",
        rarity = "common",
        gatherTime = 0.5,
        stackSize = 20,
        biomes = {"forest", "swamp"},
    },
    EmptyBottle = {
        displayName = "Empty Bottle",
        description = "Glass bottle for holding water.",
        icon = "🫙",
        rarity = "uncommon",
        gatherTime = 1,
        stackSize = 5,
        biomes = {"urban", "cornucopia"},
    },
    Hook = {
        displayName = "Hook",
        description = "Metal hook for fishing or traps.",
        icon = "🪝",
        rarity = "uncommon",
        gatherTime = 1.5,
        stackSize = 10,
        biomes = {"urban", "cornucopia"},
    },
}

-- ============ BIOME RESOURCE SPAWNING ============
-- Defines what resources spawn in each biome and their spawn weights

BiomeResources.biomeSpawnWeights = {
    forest = {
        Wood = 0.25,
        Stick = 0.20,
        Vines = 0.15,
        HardWood = 0.08,
        Herbs = 0.10,
        Feather = 0.08,
        Kindling = 0.10,
        Berry = 0.04,
    },
    meadow = {
        Stick = 0.25,
        Herbs = 0.20,
        Feather = 0.15,
        Kindling = 0.15,
        Berry = 0.10,
        ReedStalk = 0.10,
        Wood = 0.05,
    },
    mountain = {
        Stone = 0.30,
        FrozenStone = 0.15,
        PineResin = 0.15,
        Coal = 0.15,
        Flint = 0.10,
        IceFragment = 0.05,
        Wood = 0.10,
    },
    frozen = {
        FrozenStone = 0.25,
        IceFragment = 0.15,
        Stone = 0.20,
        PineResin = 0.15,
        Coal = 0.10,
        Wood = 0.15,
    },
    volcanic = {
        VolcanicRock = 0.20,
        Sulfur = 0.20,
        Coal = 0.25,
        Stone = 0.20,
        ScrapMetal = 0.10,
        Flint = 0.05,
    },
    jungle = {
        BambooStalk = 0.20,
        ToxicBlossom = 0.10,
        NightmareBerry = 0.08,
        Vines = 0.20,
        Feather = 0.12,
        Wood = 0.15,
        GlowMoss = 0.10,
        Berry = 0.05,
    },
    swamp = {
        MangroveRoot = 0.18,
        MudClay = 0.20,
        GlowMoss = 0.12,
        NightmareBerry = 0.10,
        Vines = 0.15,
        WaterSource = 0.10,
        ReedStalk = 0.10,
        Mushroom = 0.05,
    },
    desert = {
        SandStone = 0.25,
        Flint = 0.20,
        CactusFiber = 0.25,
        Stone = 0.20,
        Stick = 0.10,
    },
    cliff = {
        Stone = 0.35,
        Flint = 0.25,
        Wood = 0.15,
        Vines = 0.10,
        Stick = 0.15,
    },
    urban = {
        ScrapMetal = 0.20,
        Wire = 0.15,
        GlassShard = 0.15,
        Metal = 0.15,
        Cloth = 0.15,
        Coal = 0.10,
        EmptyBottle = 0.05,
        Hook = 0.05,
    },
    water = {
        WaterSource = 0.30,
        ReedStalk = 0.25,
        Fish = 0.20,
        Stick = 0.15,
        Vines = 0.10,
    },
    cornucopia = {
        Metal = 0.20,
        Cloth = 0.20,
        EmptyBottle = 0.15,
        Hook = 0.15,
        ScrapMetal = 0.15,
        Wire = 0.15,
    },
}

-- ============ UTILITY FUNCTIONS ============

-- Get a random resource for a given biome
function BiomeResources:getRandomResourceForBiome(biomeName)
    local spawnWeights = BiomeResources.biomeSpawnWeights[biomeName]
    if not spawnWeights then
        -- Fallback to generic resources
        spawnWeights = BiomeResources.biomeSpawnWeights.forest
    end
    
    -- Weighted random selection
    local totalWeight = 0
    for _, weight in pairs(spawnWeights) do
        totalWeight = totalWeight + weight
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for resourceName, weight in pairs(spawnWeights) do
        currentWeight = currentWeight + weight
        if random <= currentWeight then
            return resourceName, BiomeResources.resources[resourceName]
        end
    end
    
    -- Fallback
    return "Wood", BiomeResources.resources.Wood
end

-- Get all resources available in a specific biome
function BiomeResources:getResourcesForBiome(biomeName)
    local result = {}
    for resourceName, resourceData in pairs(BiomeResources.resources) do
        for _, biome in ipairs(resourceData.biomes) do
            if biome == biomeName then
                result[resourceName] = resourceData
                break
            end
        end
    end
    return result
end

-- Check if a resource can be found in a specific biome
function BiomeResources:canFindInBiome(resourceName, biomeName)
    local resource = BiomeResources.resources[resourceName]
    if not resource then return false end
    
    for _, biome in ipairs(resource.biomes) do
        if biome == biomeName then
            return true
        end
    end
    return false
end

-- Get resource bonuses (for crafting)
function BiomeResources:getResourceBonuses(resourceName)
    local resource = BiomeResources.resources[resourceName]
    if resource and resource.bonuses then
        return resource.bonuses
    end
    return {}
end

-- Get resource info by name
function BiomeResources:getResource(resourceName)
    return BiomeResources.resources[resourceName]
end

return BiomeResources
