-- ModuleScript: Config.lua
-- Central place for constants (match length, player caps)
-- Contains all configurable game settings and parameters

local Config = {}

-- Debug/Testing mode - SET TO FALSE FOR PRODUCTION
Config.DEBUG_MODE = true -- Enable/disable debug features

-- Game settings (adjusted for DEBUG_MODE)
if Config.DEBUG_MODE then
    Config.PLAYER_MIN = 1 -- Allow single player testing
    Config.LOBBY_TIME = 5 -- Short lobby time for testing (5 seconds)
    Config.COUNTDOWN_TIME = 5 -- Short countdown for testing (5 seconds)
else
    Config.PLAYER_MIN = 12 -- Minimum number of players to start match
    Config.LOBBY_TIME = 120 -- Time in lobby before match starts (2 minutes)
    Config.COUNTDOWN_TIME = 60 -- Time for final tribute countdown before match begins
end

Config.MATCH_LENGTH = 1200 -- Match length in seconds (20 minutes)
Config.PLAYER_CAP = 24 -- Maximum number of players per match
Config.STORM_PHASES = 7 -- Number of storm phases in the game

-- Bot settings
Config.BOTS_ENABLED = true -- Whether to fill empty slots with AI bots
Config.BOT_FILL_COUNT = 23 -- How many bots to spawn (24 total - 1 player = 23 bots for solo)

-- Player stats
Config.MAX_HEALTH = 100
Config.MAX_HUNGER = 100
Config.MAX_THIRST = 100

-- Arena settings
Config.ARENA_SIZE = 1024 -- Size of the square arena in studs

-- Combat settings
Config.WEAPON_DURABILITY_ENABLED = true -- Whether weapons break after extended use
Config.CRITICAL_HIT_CHANCE = 0.1 -- 10% chance for critical hits
Config.CRITICAL_HIT_MULTIPLIER = 2 -- 2x damage for critical hits

return Config