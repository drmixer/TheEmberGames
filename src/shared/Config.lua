-- ModuleScript: Config.lua
-- Central place for constants (match length, player caps)
-- Contains all configurable game settings and parameters

local Config = {}

-- Game settings
Config.MATCH_LENGTH = 1200 -- Match length in seconds (20 minutes)
Config.PLAYER_MIN = 12 -- Minimum number of players to start match
Config.PLAYER_CAP = 24 -- Maximum number of players per match
Config.LOBBY_TIME = 120 -- Time in lobby before match starts (2 minutes)
Config.STORM_PHASES = 7 -- Number of storm phases in the game
Config.COUNTDOWN_TIME = 60 -- Time for final tribute countdown before match begins

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

-- Other constants
Config.DEBUG_MODE = false -- Enable/disable debug features

return Config