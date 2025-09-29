-- ModuleScript: CraftingRecipes.lua
-- Defines item recipes for the crafting system
-- Contains all available crafting combinations and requirements

local CraftingRecipes = {}

-- Crafting recipes table
CraftingRecipes.recipes = {
    -- Example recipe format:
    -- {
    --     name = "Recipe Name",
    --     ingredients = {
    --         { itemName = "Wood", amount = 3 },
    --         { itemName = "Stone", amount = 1 }
    --     },
    --     result = { itemName = "Torch", amount = 2 }
    -- }
    
    campfire = {
        name = "Campfire",
        ingredients = {
            { itemName = "Wood", amount = 5 },
            { itemName = "Kindling", amount = 2 }
        },
        result = { itemName = "Campfire", amount = 1 }
    },
    
    bow = {
        name = "Bow",
        ingredients = {
            { itemName = "Wood", amount = 4 },
            { itemName = "Vines", amount = 2 }
        },
        result = { itemName = "Bow", amount = 1 }
    },
    
    arrow = {
        name = "Arrow",
        ingredients = {
            { itemName = "Stick", amount = 1 },
            { itemName = "Feather", amount = 1 },
            { itemName = "Flint", amount = 1 }
        },
        result = { itemName = "Arrow", amount = 3 }
    }
}

return CraftingRecipes