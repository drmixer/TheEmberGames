-- ServerScript: ServerMain.lua
-- Main initialization script for The Ember Games
-- Loads and initializes all game services
-- Updated to include Premium Lighting

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
local LightingService = require(script.Parent.LightingService)
local DefaultSpawn = require(script.Parent.DefaultSpawn) -- Ensure lobby spawn is managed/hidden

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
    
    -- Initialize PlayerStats first
    PlayerStats.init()
    
    -- Initialize Lighting (Premium Visuals)
    LightingService.init()
    
    -- Initialize Lobby Spawn (Hidden)
    DefaultSpawn.init()
    
    -- Initialize controllers
    InventoryController:init()
    CraftingController:init()
    CombatController:init()
    WeaponSystem.init()
    AudioService.init()
    DistrictCostumes.init()
    CharacterSpawner:init()
    ArenaService.init()
    EventsService.init()
    MatchService.init()
    
    local BotController = require(script.Parent.BotController)
    BotController.init()
    LobbyService.init()
    TestSetup:setupForTesting()
    
    -- Phase 5
    PerformanceOptimizer.init()
    SyncManager.init()
    LootDistribution.init()
    TestingService.init()
    ValidationRunner.init()
    
    -- Phase 6
    AllianceSystem.init()
    SeasonalRewards.init()
    ArenaVariants.init()
    
    -- Phase 7
    local DataManager = require(script.Parent.DataManager)
    DataManager.init()
    
    local PingService = require(script.Parent.PingService)
    PingService.init()
    
    local LeaderboardService = require(script.Parent.LeaderboardService)
    LeaderboardService.init()
    
    local PartyService = require(script.Parent.PartyService)
    PartyService.init()
    
    local PrivateMatchService = require(script.Parent.PrivateMatchService)
    PrivateMatchService.init()
    
    local RankedService = require(script.Parent.RankedService)
    RankedService.init()
    
    local ReplayService = require(script.Parent.ReplayService)
    ReplayService.init()
    
    local ShopService = require(script.Parent.ShopService)
    ShopService.init()
    
    print("[ServerMain] All services initialized successfully!")
    print("[ServerMain] 🔥 The Ember Games is RELEASE READY! 🔥")
end

ServerMain.init()
return ServerMain