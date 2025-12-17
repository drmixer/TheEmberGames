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
local MatchService = require(script.Parent.MatchService)
local AudioService = require(script.Parent.AudioService)
local DistrictCostumes = require(script.Parent.DistrictCostumes)
local WeaponSystem = require(script.Parent.WeaponSystem)
local TestSetup = require(script.Parent.TestSetup)
local TestingService = require(script.Parent.TestingService)

-- Phase 5: Multiplayer & Performance modules
local PerformanceOptimizer = require(script.Parent.PerformanceOptimizer)
local SyncManager = require(script.Parent.SyncManager)
local LootDistribution = require(script.Parent.LootDistribution)
local ValidationRunner = require(script.Parent.ValidationRunner)

-- Phase 6: Polish & Advanced Features
local AllianceSystem = require(script.Parent.AllianceSystem)

-- Initialize all services
function ServerMain.init()
    print("[ServerMain] Initializing The Ember Games server services...")
    
    -- Initialize services in the correct order
    -- Config is loaded automatically via require()
    
    -- Initialize PlayerStats first (other services may need to access player stats)
    PlayerStats.init()
    
    -- Initialize controllers that depend on basic services
    InventoryController:init()
    CraftingController:init()
    CombatController:init()
    WeaponSystem.init()
    
    -- Initialize AudioService
    AudioService.init()
    
    -- Initialize DistrictCostumes
    DistrictCostumes.init()
    
    -- Initialize spawn system
    CharacterSpawner:init()
    
    -- Initialize ArenaService (creates the game world)
    ArenaService.init()
    
    -- Initialize EventsService (handles game events)
    EventsService.init()
    
    -- Initialize MatchService (victory detection, game state)
    MatchService.init()
    
    -- Initialize LobbyService last (starts the game flow)
    LobbyService.init()
    
    -- Initialize test setup for MVP
    TestSetup:setupForTesting()
    
    -- ============ PHASE 5: Multiplayer & Performance ============
    
    -- Initialize PerformanceOptimizer (object pooling, network batching)
    PerformanceOptimizer.init()
    
    -- Initialize SyncManager (client-server synchronization)
    SyncManager.init()
    
    -- Initialize LootDistribution (balanced loot spawning)
    LootDistribution.init()
    
    -- Initialize TestingService (admin tools, balance testing)
    TestingService.init()
    
    -- Initialize ValidationRunner (automated tests)
    ValidationRunner.init()
    
    -- ============ PHASE 6: Polish & Advanced Features ============
    
    -- Initialize AllianceSystem (player alliances, betrayal mechanics)
    AllianceSystem.init()
    
    print("[ServerMain] All services initialized successfully!")
    print("[ServerMain] ✅ Phase 5 Complete - All multiplayer systems active")
    print("[ServerMain] ✅ Phase 6 Polish - Alliance system, cosmetics enabled")
    print("[ServerMain] The Ember Games server is ready for tributes!")
end

-- Initialize the server when this module is required
ServerMain.init()

-- Return the module for potential further use
return ServerMain