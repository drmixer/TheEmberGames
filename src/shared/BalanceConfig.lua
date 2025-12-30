-- ModuleScript: BalanceConfig.lua
-- Centralized game balance configuration for easy tuning
-- All damage, timing, and gameplay values in one place

local BalanceConfig = {}

-- ============ SURVIVAL BALANCE ============

BalanceConfig.Survival = {
    -- Hunger settings (TUNED for balanced gameplay - 20 min match)
    HUNGER_DRAIN_ACTIVE = 1/12,      -- 1 point every 12 seconds (~5/min). Needs ~2 meals per match.
    HUNGER_DRAIN_IDLE = 1/24,        -- 1 point every 24 seconds (~2.5/min).
    HUNGER_CRITICAL = 25,            -- HP drain starts below this
    HUNGER_HEALTHY = 50,             -- Regen starts above this
    
    -- Thirst settings (TUNED - thirst is more urgent)
    THIRST_DRAIN_ACTIVE = 1/8,       -- 1 point every 8 seconds (~7.5/min). Needs ~3 drinks per match.
    THIRST_DRAIN_IDLE = 1/16,        -- 1 point every 16 seconds (~3.75/min).
    THIRST_CRITICAL = 25,            -- HP drain starts below this
    THIRST_HEALTHY = 50,             -- Regen starts above this
    
    -- Health regeneration (TUNED)
    HEALTH_REGEN_RATE = 1.0,         -- 1 HP per second when healthy (Full heal in 100s)
    HEALTH_DRAIN_RATE = 2.0,         -- 2 HP per second when starving (Quick death in 50s)
    
    -- Reference: 20 minute match (1200 seconds)
    -- Hunger: 1200s / 12s = 100 points lost (Full bar)
    -- Thirst: 1200s / 8s = 150 points lost (1.5 Bars)
}

-- ============ WEAPON DAMAGE BALANCE ============

BalanceConfig.Weapons = {
    -- MELEE WEAPONS (Damage, Attack Speed, Range)
    WoodenStick = {
        damage = 15,
        attackSpeed = 0.6,
        range = 5,
        durability = 20,
    },
    SharpStick = {
        damage = 25,
        attackSpeed = 0.8,
        range = 6,
        durability = 15,
        bleedChance = 0.10,
        bleedDuration = 5,
    },
    StoneKnife = {
        damage = 20,
        attackSpeed = 0.5,
        range = 4,
        durability = 25,
        bleedChance = 0.15,
        bleedDuration = 5,
    },
    HandmadeAxe = {
        damage = 35,
        attackSpeed = 1.2,
        range = 5,
        durability = 12,
    },
    Machete = {
        damage = 40,
        attackSpeed = 0.9,
        range = 5.5,
        durability = 8,
        bleedChance = 0.25,
        bleedDuration = 8,
    },
    
    -- RANGED WEAPONS
    Slingshot = {
        damage = 15,
        attackSpeed = 1.0,
        range = 50,
        projectileSpeed = 100,
        durability = 30,
    },
    Bow = {
        damage = 30,
        attackSpeed = 1.5,
        range = 80,
        projectileSpeed = 120,
        durability = 20,
        chargeTime = 0.5,
        bleedChance = 0.20,
        bleedDuration = 6,
    },
    ThrowingKnife = {
        damage = 25,
        attackSpeed = 0.4,
        range = 40,
        projectileSpeed = 150,
        stackSize = 5,
    },
    
    -- TRAPS
    FireTrap = {
        damage = 30,
        radius = 8,
        duration = 5,
    },
    TripwireTrap = {
        damage = 10,
        immobilizeDuration = 3,
    },
    PoisonBerry = {
        damage = 40,
        poisonDuration = 10,
    },
}

-- ============ COMBAT BALANCE ============

BalanceConfig.Combat = {
    -- Critical hits
    CRITICAL_HIT_CHANCE = 0.10,      -- 10% chance
    CRITICAL_HIT_MULTIPLIER = 2.0,   -- 2x damage
    
    -- Status effects
    BLEED_DAMAGE_PER_TICK = 2,       -- HP lost per tick
    BLEED_TICK_INTERVAL = 2,         -- Seconds between ticks
    POISON_DAMAGE_PER_TICK = 3,      -- HP lost per tick
    POISON_TICK_INTERVAL = 1.5,      -- Seconds between ticks
    HYPOTHERMIA_DAMAGE_PER_TICK = 1, -- HP lost per tick
    HYPOTHERMIA_TICK_INTERVAL = 5,   -- Seconds between ticks
    
    -- Damage reduction (future armor system)
    BASE_DAMAGE_REDUCTION = 0,       -- 0% base reduction
    MAX_DAMAGE_REDUCTION = 0.75,     -- 75% max reduction with armor
}

-- ============ STORM BALANCE ============

BalanceConfig.Storm = {
    -- Phase timing (in seconds)
    PHASE_1_DELAY = 300,     -- 5 minutes before first storm
    
    PHASE_DURATIONS = {
        [1] = 300,  -- 5 minutes for phase 1
        [2] = 240,  -- 4 minutes for phase 2
        [3] = 180,  -- 3 minutes for phase 3
        [4] = 120,  -- 2 minutes for phase 4
        [5] = 90,   -- 1.5 minutes for phase 5
        [6] = 60,   -- 1 minute for phase 6
        [7] = 60,   -- 1 minute for final phase
    },
    
    -- Storm damage per phase (damage per second)
    PHASE_DAMAGE = {
        [1] = 1,    -- 1 HP/s
        [2] = 2,    -- 2 HP/s
        [3] = 3,    -- 3 HP/s
        [4] = 5,    -- 5 HP/s
        [5] = 8,    -- 8 HP/s
        [6] = 12,   -- 12 HP/s
        [7] = 20,   -- 20 HP/s (instant death territory)
    },
    
    -- Arena size per phase (as percentage of original radius)
    PHASE_SIZE = {
        [1] = 0.85, -- 85% of arena
        [2] = 0.70, -- 70% of arena
        [3] = 0.55, -- 55% of arena
        [4] = 0.40, -- 40% of arena
        [5] = 0.25, -- 25% of arena
        [6] = 0.15, -- 15% of arena
        [7] = 0.05, -- 5% of arena (very small)
    },
}

-- ============ HAZARD BALANCE ============

BalanceConfig.Hazards = {
    -- Flood
    FLOOD_RADIUS = 50,
    FLOOD_DURATION = 60,
    FLOOD_DAMAGE_PER_SECOND = 5,
    
    -- Poison Fog
    POISON_FOG_RADIUS = 30,
    POISON_FOG_DURATION = 45,
    POISON_FOG_DAMAGE_PER_SECOND = 4,
    
    -- Wildfire
    WILDFIRE_RADIUS = 20,
    WILDFIRE_DURATION = 90,
    WILDFIRE_DAMAGE_PER_SECOND = 8,
    
    -- Event timing
    MIN_TIME_BETWEEN_HAZARDS = 240,  -- 4 minutes
    MAX_TIME_BETWEEN_HAZARDS = 480,  -- 8 minutes
}

-- ============ SUPPLY DROP BALANCE ============

BalanceConfig.SupplyDrops = {
    -- Timing
    FIRST_DROP_DELAY = 120,          -- 2 minutes after match start
    MIN_TIME_BETWEEN_DROPS = 300,    -- 5 minutes minimum
    MAX_TIME_BETWEEN_DROPS = 600,    -- 10 minutes maximum
    
    -- Duration
    DROP_ACTIVE_DURATION = 300,      -- 5 minutes active
    
    -- Loot quality
    RARE_ITEM_CHANCE = 0.60,         -- 60% chance for rare item
    LEGENDARY_ITEM_CHANCE = 0.15,    -- 15% chance for legendary
}

-- ============ MATCH FLOW BALANCE ============

BalanceConfig.Match = {
    -- Lobby
    MIN_PLAYERS = 12,
    MAX_PLAYERS = 24,
    LOBBY_COUNTDOWN = 120,           -- 2 minutes
    
    -- Pre-match
    SPAWN_PLATFORM_LOCK_TIME = 60,   -- 60 second countdown on platforms
    
    -- Match length
    MAX_MATCH_TIME = 1200,           -- 20 minutes max
    
    -- Victory
    VICTORY_SCREEN_DURATION = 15,    -- 15 seconds before returning to lobby
}

-- ============ CONSUMABLES BALANCE ============

BalanceConfig.Consumables = {
    Apple = {
        hunger = 20,
        thirst = 10,
        health = 5,
        duration = 1.5, -- Time to eat
        animation = "Eat",
        sound = "rbxassetid://160212768", -- Crunch
    },
    Bread = {
        hunger = 40,
        thirst = -5, -- Dry
        health = 10,
        duration = 2,
        animation = "Eat",
        sound = "rbxassetid://160212768",
    },
    WaterBottle = {
        hunger = 0,
        thirst = 50,
        health = 0,
        duration = 2,
        animation = "Drink",
        sound = "rbxassetid://4765792476", -- Slurp
    },
    Medkit = {
        hunger = 0,
        thirst = 0,
        health = 75,
        duration = 4,
        animation = "Bandage",
    },
}

-- ============ CRAFTING BALANCE ============

BalanceConfig.Crafting = {
    -- Crafting times (in seconds)
    BASIC_CRAFT_TIME = 2,
    MEDIUM_CRAFT_TIME = 4,
    ADVANCED_CRAFT_TIME = 6,
    WEAPON_CRAFT_TIME = 8,
    
    -- Crafting interrupt penalty
    CANCEL_PENALTY = 0.5,            -- Lose 50% progress on cancel
}

-- ============ DEBUG PRESETS ============
-- For testing different balance scenarios

BalanceConfig.Presets = {
    -- Fast match for testing
    QuickTest = {
        ["Match.SPAWN_PLATFORM_LOCK_TIME"] = 5,
        ["Match.MIN_PLAYERS"] = 1,
        ["Storm.PHASE_1_DELAY"] = 30,
        ["Storm.PHASE_DURATIONS"] = {
            [1] = 30, [2] = 30, [3] = 30, [4] = 30, [5] = 30, [6] = 30, [7] = 30
        },
        ["SupplyDrops.FIRST_DROP_DELAY"] = 10,
    },
    
    -- High damage for action-packed matches
    HighAction = {
        ["Weapons.WoodenStick.damage"] = 25,
        ["Weapons.SharpStick.damage"] = 40,
        ["Weapons.StoneKnife.damage"] = 35,
        ["Weapons.HandmadeAxe.damage"] = 55,
        ["Weapons.Machete.damage"] = 65,
        ["Combat.CRITICAL_HIT_CHANCE"] = 0.20,
    },
    
    -- Survival focused
    HardcoreSurvival = {
        ["Survival.HUNGER_DRAIN_ACTIVE"] = 1/30,
        ["Survival.THIRST_DRAIN_ACTIVE"] = 1/20,
        ["Survival.HEALTH_REGEN_RATE"] = 0.2,
    },
}

-- Apply a preset
function BalanceConfig:applyPreset(presetName)
    local preset = BalanceConfig.Presets[presetName]
    if not preset then
        warn("[BalanceConfig] Unknown preset: " .. tostring(presetName))
        return false
    end
    
    for path, value in pairs(preset) do
        local parts = string.split(path, ".")
        local target = BalanceConfig
        
        for i = 1, #parts - 1 do
            target = target[parts[i]]
            if not target then
                warn("[BalanceConfig] Invalid path: " .. path)
                break
            end
        end
        
        if target then
            target[parts[#parts]] = value
        end
    end
    
    print("[BalanceConfig] Applied preset: " .. presetName)
    return true
end

-- Get a value by path (e.g., "Weapons.WoodenStick.damage")
function BalanceConfig:getValue(path)
    local parts = string.split(path, ".")
    local target = BalanceConfig
    
    for _, part in ipairs(parts) do
        target = target[part]
        if target == nil then
            return nil
        end
    end
    
    return target
end

-- Set a value by path
function BalanceConfig:setValue(path, value)
    local parts = string.split(path, ".")
    local target = BalanceConfig
    
    for i = 1, #parts - 1 do
        target = target[parts[i]]
        if not target then
            warn("[BalanceConfig] Invalid path: " .. path)
            return false
        end
    end
    
    target[parts[#parts]] = value
    print("[BalanceConfig] Set " .. path .. " = " .. tostring(value))
    return true
end

return BalanceConfig
