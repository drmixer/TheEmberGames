-- ModuleScript: CraftingRecipes.lua
-- Defines item recipes for the crafting system
-- Contains all available crafting combinations and requirements

local CraftingRecipes = {}

-- Recipe categories
CraftingRecipes.categories = {
    "WEAPONS",
    "AMMO",
    "TRAPS",
    "SURVIVAL",
    "TOOLS"
}

-- Crafting recipes table
CraftingRecipes.recipes = {
    -- ============ WEAPONS ============
    
    wooden_stick = {
        name = "Wooden Stick",
        category = "WEAPONS",
        ingredients = {
            { itemName = "Wood", amount = 2 }
        },
        result = { itemName = "WoodenStick", amount = 1 },
        craftTime = 2,
        description = "A basic wooden weapon. Fast but weak."
    },
    
    sharp_stick = {
        name = "Sharp Stick",
        category = "WEAPONS",
        ingredients = {
            { itemName = "Wood", amount = 3 },
            { itemName = "Stone", amount = 1 }
        },
        result = { itemName = "SharpStick", amount = 1 },
        craftTime = 4,
        description = "A sharpened spear. Good reach with bleed chance."
    },
    
    stone_knife = {
        name = "Stone Knife",
        category = "WEAPONS",
        ingredients = {
            { itemName = "Stone", amount = 2 },
            { itemName = "Wood", amount = 1 }
        },
        result = { itemName = "StoneKnife", amount = 1 },
        craftTime = 3,
        description = "A crude knife. Fast attacks with bleeding."
    },
    
    handmade_axe = {
        name = "Handmade Axe",
        category = "WEAPONS",
        ingredients = {
            { itemName = "Wood", amount = 3 },
            { itemName = "Stone", amount = 3 },
            { itemName = "Vines", amount = 1 }
        },
        result = { itemName = "HandmadeAxe", amount = 1 },
        craftTime = 6,
        description = "A heavy axe. Slow but powerful."
    },
    
    slingshot = {
        name = "Slingshot",
        category = "WEAPONS",
        ingredients = {
            { itemName = "Wood", amount = 2 },
            { itemName = "Vines", amount = 2 }
        },
        result = { itemName = "Slingshot", amount = 1 },
        craftTime = 3,
        description = "A simple slingshot. Uses rocks as ammo."
    },
    
    bow = {
        name = "Bow",
        category = "WEAPONS",
        ingredients = {
            { itemName = "Wood", amount = 4 },
            { itemName = "Vines", amount = 3 }
        },
        result = { itemName = "Bow", amount = 1 },
        craftTime = 5,
        description = "A hunting bow. Requires arrows to use."
    },
    
    throwing_knife = {
        name = "Throwing Knife",
        category = "WEAPONS",
        ingredients = {
            { itemName = "Stone", amount = 2 },
            { itemName = "Feather", amount = 1 }
        },
        result = { itemName = "ThrowingKnife", amount = 3 },
        craftTime = 4,
        description = "Balanced throwing knives. Fast and accurate."
    },
    
    -- ============ AMMO ============
    
    arrow = {
        name = "Arrow",
        category = "AMMO",
        ingredients = {
            { itemName = "Stick", amount = 1 },
            { itemName = "Feather", amount = 1 },
            { itemName = "Flint", amount = 1 }
        },
        result = { itemName = "Arrow", amount = 3 },
        craftTime = 2,
        description = "Standard arrows for the bow."
    },
    
    fire_arrow = {
        name = "Fire Arrow",
        category = "AMMO",
        ingredients = {
            { itemName = "Arrow", amount = 3 },
            { itemName = "Cloth", amount = 1 },
            { itemName = "Coal", amount = 1 }
        },
        result = { itemName = "FireArrow", amount = 3 },
        craftTime = 3,
        description = "Arrows that ignite targets on hit."
    },
    
    poison_arrow = {
        name = "Poison Arrow",
        category = "AMMO",
        ingredients = {
            { itemName = "Arrow", amount = 3 },
            { itemName = "NightmareBerry", amount = 2 }
        },
        result = { itemName = "PoisonArrow", amount = 3 },
        craftTime = 3,
        description = "Arrows coated in deadly poison."
    },
    
    slingshot_ammo = {
        name = "Smooth Stones",
        category = "AMMO",
        ingredients = {
            { itemName = "Stone", amount = 2 }
        },
        result = { itemName = "SlingshotAmmo", amount = 5 },
        craftTime = 1,
        description = "Polished stones for the slingshot."
    },
    
    -- ============ TRAPS ============
    
    fire_trap = {
        name = "Fire Trap",
        category = "TRAPS",
        ingredients = {
            { itemName = "Wood", amount = 3 },
            { itemName = "Coal", amount = 2 },
            { itemName = "Cloth", amount = 1 }
        },
        result = { itemName = "FireTrap", amount = 1 },
        craftTime = 5,
        description = "Explodes in flames when triggered."
    },
    
    tripwire_trap = {
        name = "Tripwire Trap",
        category = "TRAPS",
        ingredients = {
            { itemName = "Vines", amount = 3 },
            { itemName = "Stick", amount = 2 }
        },
        result = { itemName = "TripwireTrap", amount = 1 },
        craftTime = 4,
        description = "Immobilizes players who trigger it."
    },
    
    poison_bait = {
        name = "Poison Bait",
        category = "TRAPS",
        ingredients = {
            { itemName = "Berry", amount = 2 },
            { itemName = "NightmareBerry", amount = 1 }
        },
        result = { itemName = "PoisonBerry", amount = 1 },
        craftTime = 2,
        description = "Looks edible but causes severe poisoning."
    },
    
    -- ============ SURVIVAL ============
    
    campfire = {
        name = "Campfire",
        category = "SURVIVAL",
        ingredients = {
            { itemName = "Wood", amount = 5 },
            { itemName = "Kindling", amount = 2 }
        },
        result = { itemName = "Campfire", amount = 1 },
        craftTime = 4,
        description = "A warm campfire. Cook food and stay warm."
    },
    
    torch = {
        name = "Torch",
        category = "SURVIVAL",
        ingredients = {
            { itemName = "Stick", amount = 1 },
            { itemName = "Cloth", amount = 1 },
            { itemName = "Coal", amount = 1 }
        },
        result = { itemName = "Torch", amount = 2 },
        craftTime = 2,
        description = "A light source. Also useful as a weapon."
    },
    
    bandage = {
        name = "Bandage",
        category = "SURVIVAL",
        ingredients = {
            { itemName = "Cloth", amount = 2 },
            { itemName = "Herbs", amount = 1 }
        },
        result = { itemName = "Bandage", amount = 1 },
        craftTime = 2,
        description = "Stops bleeding and restores some health."
    },
    
    water_bottle = {
        name = "Water Bottle",
        category = "SURVIVAL",
        ingredients = {
            { itemName = "WaterSource", amount = 1 },
            { itemName = "EmptyBottle", amount = 1 }
        },
        result = { itemName = "WaterBottle", amount = 1 },
        craftTime = 1,
        description = "Clean drinking water."
    },
    
    -- ============ TOOLS ============
    
    lockpick = {
        name = "Lockpick",
        category = "TOOLS",
        ingredients = {
            { itemName = "Metal", amount = 1 },
            { itemName = "Wire", amount = 1 }
        },
        result = { itemName = "Lockpick", amount = 1 },
        craftTime = 3,
        description = "Opens locked supply crates."
    },
    
    fishing_rod = {
        name = "Fishing Rod",
        category = "TOOLS",
        ingredients = {
            { itemName = "Wood", amount = 3 },
            { itemName = "Vines", amount = 2 },
            { itemName = "Hook", amount = 1 }
        },
        result = { itemName = "FishingRod", amount = 1 },
        craftTime = 4,
        description = "Catch fish from water sources."
    }
}

-- Get recipe by ID
function CraftingRecipes:getRecipe(recipeId)
    return CraftingRecipes.recipes[recipeId]
end

-- Get all recipes in a category
function CraftingRecipes:getRecipesByCategory(category)
    local result = {}
    for id, recipe in pairs(CraftingRecipes.recipes) do
        if recipe.category == category then
            result[id] = recipe
        end
    end
    return result
end

-- Check if player can craft recipe (given their inventory)
function CraftingRecipes:canCraft(recipeId, playerInventory)
    local recipe = CraftingRecipes.recipes[recipeId]
    if not recipe then return false, "Invalid recipe" end
    
    for _, ingredient in ipairs(recipe.ingredients) do
        local playerAmount = playerInventory[ingredient.itemName] or 0
        if playerAmount < ingredient.amount then
            return false, "Missing " .. ingredient.itemName
        end
    end
    
    return true, "Can craft"
end

-- Get all recipes that can be crafted with given inventory
function CraftingRecipes:getAvailableRecipes(playerInventory)
    local available = {}
    for id, recipe in pairs(CraftingRecipes.recipes) do
        local canCraft, _ = CraftingRecipes:canCraft(id, playerInventory)
        if canCraft then
            table.insert(available, id)
        end
    end
    return available
end

return CraftingRecipes