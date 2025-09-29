-- ServerScript: ServerMain.lua
-- Main initialization script for The Ember Games
-- Loads and initializes all game services

local ServerMain = {}

-- Import all services
local LobbyService = require(script.Parent.LobbyService)
local ArenaService = require(script.Parent.ArenaService) 
local EventsService = require(script.Parent.EventsService)
local PlayerStats = require(script.Parent.PlayerStats)
local CraftingController = require(script.Parent.CraftingController)
local CombatController = require(script.Parent.CombatController)
local InventoryController = require(script.Parent.InventoryController)
local CharacterSpawner = require(script.Parent.CharacterSpawner)
local TestSetup = require(script.Parent.TestSetup)

-- Initialize all services
function ServerMain.init()
    print("Initializing The Ember Games server services...")
    
    -- Initialize services in the correct order
    -- Config is loaded automatically via require()
    
    -- Initialize PlayerStats first (other services may need to access player stats)
    PlayerStats.init()
    
    -- Initialize controllers that depend on basic services
    InventoryController:init()
    CraftingController:init()
    CombatController:init()
    
    -- Initialize spawn system
    CharacterSpawner:init()
    
    -- Initialize ArenaService (creates the game world)
    ArenaService.init()
    
    -- Initialize EventsService (handles game events)
    EventsService.init()
    
    -- Initialize LobbyService last (starts the game flow)
    LobbyService.init()
    
    -- Initialize test setup for MVP
    TestSetup:setupForTesting()
    
    print("All services initialized successfully!")
    
    -- Log server status
    print("The Ember Games server is ready for tributes!")
end

-- Initialize the server when this module is required
ServerMain.init()

-- Return the module for potential further use
return ServerMain