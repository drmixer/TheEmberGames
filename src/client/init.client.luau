-- init.client.luau
-- Main entry point for The Ember Games client
-- This file bootstraps all client scripts

print("The Ember Games client initializing...")

-- Wait for player and character to be ready
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Wait for the player's GUI to be ready
Player:WaitForChild("PlayerGui")

-- Load all client modules (they auto-initialize on require)
-- Note: script refers to the client folder, so children are accessed directly
local StarterGui = require(script.StarterGui)
local UIController = require(script.UIController)
local EmoteController = require(script.EmoteController)
local CraftingGui = require(script.CraftingGui)
local CombatGui = require(script.CombatGui)
local InventoryGui = require(script.InventoryGui)
local SpectatorMode = require(script.SpectatorMode)
local ControllerSupport = require(script.ControllerSupport)
local MobileSupport = require(script.MobileSupport)

print("The Ember Games client started successfully!")