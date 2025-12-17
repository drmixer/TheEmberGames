-- init.client.luau
-- Main entry point for The Ember Games client
-- This file bootstraps all client scripts

print("The Ember Games client initializing...")

-- Wait for player and character to be ready
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Wait for the player's GUI to be ready
Player:WaitForChild("PlayerGui")

-- Load client modules one at a time with error handling
local function safeRequire(moduleName)
    local success, result = pcall(function()
        return require(script[moduleName])
    end)
    if success then
        print("Loaded: " .. moduleName)
        return result
    else
        warn("Failed to load " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

-- Load core UI first
safeRequire("UIController")
safeRequire("StarterGui")

-- Load other client modules
safeRequire("EmoteController")
safeRequire("CraftingGui")
safeRequire("CombatGui")
safeRequire("InventoryGui")
safeRequire("SpectatorMode")
safeRequire("ControllerSupport")
safeRequire("MobileSupport")

print("The Ember Games client started successfully!")