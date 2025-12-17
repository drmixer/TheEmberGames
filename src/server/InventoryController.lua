-- ModuleScript: InventoryController.lua
-- Handles inventory management for The Ember Games
-- Manages player items, resources, and inventory UI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local InventoryController = {}
InventoryController.playerInventories = {}

-- Create RemoteEvents for inventory
local inventoryRemoteEvent = Instance.new("RemoteEvent")
inventoryRemoteEvent.Name = "InventoryRemoteEvent"
inventoryRemoteEvent.Parent = ReplicatedStorage

-- Initialize InventoryController
function InventoryController:init()
    print("InventoryController initialized")
    
    -- Connect player events
    Players.PlayerAdded:Connect(function(player)
        InventoryController:initializePlayerInventory(player)
    end)
    
    -- Initialize for existing players
    for _, player in pairs(Players:GetPlayers()) do
        InventoryController:initializePlayerInventory(player)
    end
    
    -- Handle inventory requests from clients
    inventoryRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}
        
        if action == "ADD_ITEM" then
            local itemName, amount = args[1], args[2] or 1
            InventoryController:addItem(player, itemName, amount)
        elseif action == "REMOVE_ITEM" then
            local itemName, amount = args[1], args[2] or 1
            InventoryController:removeItem(player, itemName, amount)
        elseif action == "USE_ITEM" then
            local itemName = args[1]
            InventoryController:useItem(player, itemName)
        elseif action == "SWAP_SLOTS" then
            local fromSlot, toSlot = args[1], args[2]
            InventoryController:swapSlots(player, fromSlot, toSlot)
        elseif action == "REQUEST_INVENTORY" then
            InventoryController:sendInventoryToClient(player)
        end
    end)
end

-- Initialize player inventory
function InventoryController:initializePlayerInventory(player)
    if not InventoryController.playerInventories[player] then
        InventoryController.playerInventories[player] = {
            slots = {}, -- Array of {name, amount, metadata}
            maxSize = 20, -- Maximum inventory slots
            activeSlot = 1 -- Currently selected slot
        }
        
        -- Initialize slots with empty items
        for i = 1, InventoryController.playerInventories[player].maxSize do
            InventoryController.playerInventories[player].slots[i] = {
                name = nil,
                amount = 0,
                metadata = {}
            }
        end
        
        print("Initialized inventory for player: " .. player.Name)
    end
end

-- Add item to player inventory
function InventoryController:addItem(player, itemName, amount)
    if not InventoryController.playerInventories[player] then
        InventoryController:initializePlayerInventory(player)
    end
    
    local inventory = InventoryController.playerInventories[player]
    amount = amount or 1
    
    -- Try to add to existing stack first
    for i, slot in ipairs(inventory.slots) do
        if slot.name == itemName then
            slot.amount = slot.amount + amount
            -- Notify client
            inventoryRemoteEvent:FireClient(player, "ITEM_ADDED", itemName, amount, i)
            print(player.Name .. " received " .. amount .. "x " .. itemName .. ". Total: " .. slot.amount)
            return true
        end
    end
    
    -- If no stack found, find first empty slot
    for i, slot in ipairs(inventory.slots) do
        if not slot.name or slot.name == "" or slot.amount <= 0 then
            slot.name = itemName
            slot.amount = amount
            -- Notify client
            inventoryRemoteEvent:FireClient(player, "ITEM_ADDED", itemName, amount, i)
            print(player.Name .. " received " .. amount .. "x " .. itemName .. " in slot " .. i)
            return true
        end
    end
    
    -- Inventory is full
    print("Failed to add " .. itemName .. " to " .. player.Name .. "'s inventory - inventory full")
    inventoryRemoteEvent:FireClient(player, "INVENTORY_FULL", itemName, amount)
    return false
end

-- Remove item from player inventory
function InventoryController:removeItem(player, itemName, amount)
    if not InventoryController.playerInventories[player] then
        return false
    end
    
    local inventory = InventoryController.playerInventories[player]
    amount = amount or 1
    local removed = 0
    
    for i, slot in ipairs(inventory.slots) do
        if slot.name == itemName then
            local removeAmount = math.min(slot.amount, amount - removed)
            slot.amount = slot.amount - removeAmount
            removed = removed + removeAmount
            
            if slot.amount <= 0 then
                slot.name = nil
                slot.amount = 0
                slot.metadata = {}
            end
            
            -- Notify client
            inventoryRemoteEvent:FireClient(player, "ITEM_REMOVED", itemName, removeAmount, i)
            
            if removed >= amount then
                break
            end
        end
    end
    
    local successfullyRemoved = removed >= amount
    if successfullyRemoved then
        print("Removed " .. removed .. "x " .. itemName .. " from " .. player.Name .. "'s inventory")
    else
        print("Could not remove " .. amount .. "x " .. itemName .. " from " .. player.Name .. "'s inventory - only removed " .. removed)
    end
    
    return successfullyRemoved
end

-- Use an item from inventory
function InventoryController:useItem(player, itemName)
    if not InventoryController.playerInventories[player] then
        return false
    end
    
    local inventory = InventoryController.playerInventories[player]
    
    -- Find the item in inventory
    for i, slot in ipairs(inventory.slots) do
        if slot.name == itemName and slot.amount > 0 then
            -- Process item use based on item type
            local success = InventoryController:processItemUse(player, itemName, slot.metadata)
            
            if success then
                slot.amount = slot.amount - 1
                if slot.amount <= 0 then
                    slot.name = nil
                    slot.amount = 0
                    slot.metadata = {}
                end
                
                -- Notify client
                inventoryRemoteEvent:FireClient(player, "ITEM_USED", itemName, i)
                
                print(player.Name .. " used 1x " .. itemName)
                return true
            end
        end
    end
    
    return false
end

-- Process item use based on item type
function InventoryController:processItemUse(player, itemName, metadata)
    -- Import PlayerStats to modify player stats
    local PlayerStats = require(script.Parent.PlayerStats)
    
    -- Item effects based on type
    local itemEffects = {
        -- Health restoration
        ["Medkit"] = function(p) PlayerStats:updateStat(p, "health", 50, true); return true end,
        ["Healing Herb"] = function(p) PlayerStats:updateStat(p, "health", 15, true); return true end,
        ["First Aid Kit"] = function(p) PlayerStats:updateStat(p, "health", 30, true); return true end,
        
        -- Hunger restoration
        ["Food Rations"] = function(p) PlayerStats:updateStat(p, "hunger", 40, true); return true end,
        ["Cooked Meat"] = function(p) PlayerStats:updateStat(p, "hunger", 30, true); return true end,
        ["Edible Berries"] = function(p) PlayerStats:updateStat(p, "hunger", 15, true); return true end,
        ["Wild Vegetables"] = function(p) PlayerStats:updateStat(p, "hunger", 10, true); return true end,
        
        -- Thirst restoration
        ["Water Bottle"] = function(p) PlayerStats:updateStat(p, "thirst", 40, true); return true end,
        ["Fresh Water Source"] = function(p) PlayerStats:updateStat(p, "thirst", 30, true); return true end,
        
        -- Crafting materials
        ["Wood"] = function(p) return true end,
        ["Stone"] = function(p) return true end,
        ["Vines"] = function(p) return true end,
        ["Leather Pieces"] = function(p) return true end,
        
        -- Weapons and tools
        ["Spear"] = function(p) return true end,
        ["Knife"] = function(p) return true end,
        ["Bow"] = function(p) return true end,
        ["Axe"] = function(p) return true end,
        ["Machete"] = function(p) return true end,
    }
    
    local effect = itemEffects[itemName]
    if effect then
        return effect(player)
    else
        print("No effect defined for item: " .. itemName)
        return false
    end
end

-- Swap slots in inventory
function InventoryController:swapSlots(player, fromSlot, toSlot)
    if not InventoryController.playerInventories[player] then
        return
    end
    
    local inventory = InventoryController.playerInventories[player]
    
    if fromSlot < 1 or fromSlot > #inventory.slots or toSlot < 1 or toSlot > #inventory.slots then
        return
    end
    
    -- Swap the items
    local temp = inventory.slots[fromSlot]
    inventory.slots[fromSlot] = inventory.slots[toSlot]
    inventory.slots[toSlot] = temp
    
    -- Notify client
    inventoryRemoteEvent:FireClient(player, "SLOTS_SWAPPED", fromSlot, toSlot, inventory.slots[fromSlot], inventory.slots[toSlot])
end

-- Send inventory to client
function InventoryController:sendInventoryToClient(player)
    if not InventoryController.playerInventories[player] then
        return
    end
    
    local inventory = InventoryController.playerInventories[player]
    local inventoryData = {
        slots = {},
        maxSize = inventory.maxSize,
        activeSlot = inventory.activeSlot
    }
    
    for i, slot in ipairs(inventory.slots) do
        inventoryData.slots[i] = {
            name = slot.name,
            amount = slot.amount,
            metadata = slot.metadata
        }
    end
    
    inventoryRemoteEvent:FireClient(player, "FULL_INVENTORY_UPDATE", inventoryData)
end

return InventoryController