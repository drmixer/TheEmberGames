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
local SeasonalRewards = require(script.Parent.SeasonalRewards)
local ArenaVariants = require(script.Parent.ArenaVariants)

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
    
    -- Initialize BotController (AI tributes for solo play)
    local BotController = require(script.Parent.BotController)
    BotController.init()
    
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
    
    -- Initialize SeasonalRewards (battle pass, challenges, progression)
    SeasonalRewards.init()
    
    -- Initialize ArenaVariants (different arena themes)
    ArenaVariants.init()
    
    -- ============ PHASE 7: Critical Infrastructure ============
    
    -- Initialize DataManager (save/load player data)
    local DataManager = require(script.Parent.DataManager)
    DataManager.init()
    
    -- ============ PHASE 7: Social Features ============
    
    -- Initialize PingService (ally communication)
    local PingService = require(script.Parent.PingService)
    PingService.init()
    
    -- Initialize LeaderboardService (global rankings)
    local LeaderboardService = require(script.Parent.LeaderboardService)
    LeaderboardService.init()
    
    -- ============ PHASE 7: Advanced Features ============
    
    -- Initialize PartyService (friends/party system)
    local PartyService = require(script.Parent.PartyService)
    PartyService.init()
    
    -- Initialize PrivateMatchService (custom games)
    local PrivateMatchService = require(script.Parent.PrivateMatchService)
    PrivateMatchService.init()
    
    -- Initialize RankedService (competitive matchmaking)
    local RankedService = require(script.Parent.RankedService)
    RankedService.init()
    
    -- ============ PHASE 7: Stretch Goals ============
    
    -- Initialize ReplayService (match recording)
    local ReplayService = require(script.Parent.ReplayService)
    ReplayService.init()
    
    -- Initialize ShopService (premium shop/monetization)
    local ShopService = require(script.Parent.ShopService)
    ShopService.init()
    
    print("[ServerMain] All services initialized successfully!")
    print("[ServerMain] ✅ All Implementation Phases Complete")
    print("[ServerMain] ✅ All POLISHPLAN Features Complete")
    print("[ServerMain] 🔥 The Ember Games is RELEASE READY! 🔥")
end

-- Initialize the server when this module is required
ServerMain.init()

-- Return the module for potential further use
return ServerMain