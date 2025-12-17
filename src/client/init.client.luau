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
local StarterGui = require(script.Parent.StarterGui)
local UIController = require(script.Parent.UIController)
local EmoteController = require(script.Parent.EmoteController)
local CraftingGui = require(script.Parent.CraftingGui)
local CombatGui = require(script.Parent.CombatGui)
local InventoryGui = require(script.Parent.InventoryGui)
local SpectatorMode = require(script.Parent.SpectatorMode)
local ControllerSupport = require(script.Parent.ControllerSupport)
local MobileSupport = require(script.Parent.MobileSupport)

print("The Ember Games client started successfully!")