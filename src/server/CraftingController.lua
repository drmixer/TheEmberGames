-- ModuleScript: CraftingController.lua
-- Handles crafting mechanics for The Ember Games
-- Processes recipes and manages player crafting interactions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CraftingController = {}
CraftingController.craftingQueue = {} -- player -> current craft

-- Create RemoteEvents for crafting
local craftRemoteEvent = Instance.new("RemoteEvent")
craftRemoteEvent.Name = "CraftRemoteEvent"
craftRemoteEvent.Parent = ReplicatedStorage

local craftRemoteFunction = Instance.new("RemoteFunction")
craftRemoteFunction.Name = "CraftRemoteFunction"
craftRemoteFunction.Parent = ReplicatedStorage

-- Try to get shared modules
local function getSharedModule(moduleName)
    local success, result = pcall(function()
        -- Try shared folder first
        local shared = ReplicatedStorage:FindFirstChild("shared")
        if shared then
            local module = shared:FindFirstChild(moduleName)
            if module then
                return require(module)
            end
        end
        
        -- Try ReplicatedFirst
        local repFirst = game:GetService("ReplicatedFirst")
        local module = repFirst:FindFirstChild(moduleName)
        if module then
            return require(module)
        end
        
        return nil
    end)
    
    return success and result or nil
end

-- Server-side validation and crafting execution
function CraftingController:init()
    print("[CraftingController] Initializing...")
    
    -- Handle crafting requests from clients
    craftRemoteFunction.OnServerInvoke = function(player, action, ...)
        local args = {...}
        
        if action == "GET_RECIPES" then
            -- Return all recipes
            local CraftingRecipes = getSharedModule("CraftingRecipes")
            if CraftingRecipes then
                return CraftingRecipes.recipes
            end
            return {}
            
        elseif action == "GET_CATEGORIES" then
            local CraftingRecipes = getSharedModule("CraftingRecipes")
            if CraftingRecipes then
                return CraftingRecipes.categories
            end
            return {}
            
        elseif action == "CAN_CRAFT" then
            local recipeId = args[1]
            return CraftingController:canPlayerCraft(player, recipeId)
            
        elseif action == "CRAFT" then
            local recipeId = args[1]
            return CraftingController:attemptCraft(player, recipeId)
        end
        
        return false, "Unknown action"
    end
    
    -- Handle craft start/cancel events
    craftRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}
        
        if action == "START_CRAFT" then
            local recipeId = args[1]
            CraftingController:startCrafting(player, recipeId)
            
        elseif action == "CANCEL_CRAFT" then
            CraftingController:cancelCrafting(player)
        end
    end)
    
    print("[CraftingController] Initialized successfully")
end

-- Check if player can craft a recipe
function CraftingController:canPlayerCraft(player, recipeId)
    local CraftingRecipes = getSharedModule("CraftingRecipes")
    if not CraftingRecipes then
        return false, "Crafting system unavailable"
    end
    
    local recipe = CraftingRecipes.recipes[recipeId]
    if not recipe then
        return false, "Invalid recipe"
    end
    
    -- Get player's inventory
    local InventoryController = nil
    pcall(function()
        InventoryController = require(script.Parent.InventoryController)
    end)
    
    if not InventoryController then
        -- No inventory system, allow crafting for testing
        return true, "Testing mode"
    end
    
    -- Check each ingredient
    for _, ingredient in ipairs(recipe.ingredients) do
        local hasAmount = InventoryController:getItemCount(player, ingredient.itemName) or 0
        if hasAmount < ingredient.amount then
            return false, "Missing: " .. ingredient.itemName .. " (need " .. ingredient.amount .. ", have " .. hasAmount .. ")"
        end
    end
    
    return true, "Can craft"
end

-- Start a crafting process (with time)
function CraftingController:startCrafting(player, recipeId)
    -- Check if already crafting
    if CraftingController.craftingQueue[player] then
        craftRemoteEvent:FireClient(player, "CRAFT_ERROR", "Already crafting something")
        return
    end
    
    -- Check if can craft
    local canCraft, reason = CraftingController:canPlayerCraft(player, recipeId)
    if not canCraft then
        craftRemoteEvent:FireClient(player, "CRAFT_ERROR", reason)
        return
    end
    
    local CraftingRecipes = getSharedModule("CraftingRecipes")
    local recipe = CraftingRecipes.recipes[recipeId]
    
    -- Start crafting
    local craftTime = recipe.craftTime or 3
    local startTime = tick()
    
    CraftingController.craftingQueue[player] = {
        recipeId = recipeId,
        startTime = startTime,
        endTime = startTime + craftTime
    }
    
    -- Notify client that crafting started
    craftRemoteEvent:FireClient(player, "CRAFT_STARTED", recipeId, craftTime)
    
    print("[CraftingController] " .. player.Name .. " started crafting " .. recipe.name .. " (" .. craftTime .. "s)")
    
    -- Wait for craft to complete
    task.spawn(function()
        task.wait(craftTime)
        
        -- Check if still crafting same item
        local currentCraft = CraftingController.craftingQueue[player]
        if currentCraft and currentCraft.recipeId == recipeId then
            CraftingController:completeCrafting(player, recipeId)
        end
    end)
end

-- Cancel current crafting
function CraftingController:cancelCrafting(player)
    if CraftingController.craftingQueue[player] then
        local recipeId = CraftingController.craftingQueue[player].recipeId
        CraftingController.craftingQueue[player] = nil
        
        craftRemoteEvent:FireClient(player, "CRAFT_CANCELLED", recipeId)
        print("[CraftingController] " .. player.Name .. " cancelled crafting")
    end
end

-- Complete crafting and give item
function CraftingController:completeCrafting(player, recipeId)
    local CraftingRecipes = getSharedModule("CraftingRecipes")
    local recipe = CraftingRecipes.recipes[recipeId]
    
    if not recipe then
        CraftingController.craftingQueue[player] = nil
        return
    end
    
    -- Get controllers
    local InventoryController = nil
    pcall(function()
        InventoryController = require(script.Parent.InventoryController)
    end)
    
    local WeaponSystem = nil
    pcall(function()
        WeaponSystem = require(script.Parent.WeaponSystem)
    end)
    
    -- Consume ingredients
    if InventoryController then
        for _, ingredient in ipairs(recipe.ingredients) do
            InventoryController:removeItem(player, ingredient.itemName, ingredient.amount)
        end
    end
    
    -- Give crafted item
    local resultItem = recipe.result.itemName
    local resultAmount = recipe.result.amount
    
    -- Check if it's a weapon
    if recipe.category == "WEAPONS" and WeaponSystem then
        -- Give weapon via WeaponSystem
        for i = 1, resultAmount do
            WeaponSystem:giveWeapon(player, resultItem)
        end
    elseif recipe.category == "TRAPS" and WeaponSystem then
        -- Give trap via WeaponSystem
        for i = 1, resultAmount do
            WeaponSystem:giveWeapon(player, resultItem)
        end
    elseif InventoryController then
        -- Give as inventory item
        InventoryController:addItem(player, resultItem, resultAmount)
    end
    
    -- Clear crafting queue
    CraftingController.craftingQueue[player] = nil
    
    -- Notify client
    craftRemoteEvent:FireClient(player, "CRAFT_COMPLETE", recipeId, resultItem, resultAmount)
    
    print("[CraftingController] " .. player.Name .. " crafted " .. resultAmount .. "x " .. recipe.name)
end

-- Attempt to craft (instant craft for simple items)
function CraftingController:attemptCraft(player, recipeId)
    local canCraft, reason = CraftingController:canPlayerCraft(player, recipeId)
    if not canCraft then
        return false, reason
    end
    
    local CraftingRecipes = getSharedModule("CraftingRecipes")
    local recipe = CraftingRecipes.recipes[recipeId]
    
    if not recipe then
        return false, "Invalid recipe"
    end
    
    -- For instant crafting (testing or quick items)
    CraftingController:completeCrafting(player, recipeId)
    
    return true, "Crafted " .. recipe.result.amount .. "x " .. recipe.name
end

-- Get current crafting progress for player
function CraftingController:getCraftingProgress(player)
    local craft = CraftingController.craftingQueue[player]
    if not craft then
        return nil
    end
    
    local now = tick()
    local totalTime = craft.endTime - craft.startTime
    local elapsed = now - craft.startTime
    local progress = math.clamp(elapsed / totalTime, 0, 1)
    
    return {
        recipeId = craft.recipeId,
        progress = progress,
        remainingTime = math.max(0, craft.endTime - now)
    }
end

return CraftingController