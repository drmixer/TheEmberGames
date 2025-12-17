-- ModuleScript: ArenaVariants.lua (Server)
-- Manages different arena variants with unique themes and hazards
-- Rotates arenas and provides variety to matches

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local ArenaVariants = {}
ArenaVariants.currentVariant = nil
ArenaVariants.variantRotation = {}

-- Arena variant configurations
local ARENA_VARIANTS = {
    ["classic"] = {
        name = "The Classic Arena",
        description = "The original Hunger Games arena with all biomes",
        theme = "forest",
        
        -- Lighting settings
        lighting = {
            brightness = 2,
            ambient = Color3.fromRGB(128, 150, 128),
            outdoorAmbient = Color3.fromRGB(150, 180, 150),
            clockTime = 14, -- 2 PM
            fogEnd = 1000,
            fogColor = Color3.fromRGB(180, 200, 180),
        },
        
        -- Biome weights (how common each biome is)
        biomeWeights = {
            forest = 0.25,
            meadow = 0.20,
            water = 0.15,
            swamp = 0.15,
            cliff = 0.10,
            desert = 0.10,
            mountain = 0.05,
        },
        
        -- Special hazards
        hazards = { "storm", "wildFire", "poisonFog" },
        hazardFrequency = 300, -- seconds between hazards
        
        -- Loot modifiers
        lootModifiers = {
            weaponSpawnRate = 1.0,
            supplyDropFrequency = 180,
        },
        
        -- Weather
        weather = "clear",
    },
    
    ["frozen"] = {
        name = "Frozen Tundra",
        description = "A frozen wasteland where cold is your enemy",
        theme = "winter",
        
        lighting = {
            brightness = 2.5,
            ambient = Color3.fromRGB(180, 200, 220),
            outdoorAmbient = Color3.fromRGB(200, 220, 240),
            clockTime = 11,
            fogEnd = 500,
            fogColor = Color3.fromRGB(220, 230, 240),
        },
        
        biomeWeights = {
            mountain = 0.40,
            cliff = 0.25,
            forest = 0.15,
            water = 0.10, -- Frozen lakes
            meadow = 0.10,
        },
        
        hazards = { "blizzard", "avalanche", "frostbite" },
        hazardFrequency = 240,
        
        lootModifiers = {
            weaponSpawnRate = 0.9,
            supplyDropFrequency = 150,
            fireStarterBonus = true, -- Fire starters more valuable
        },
        
        -- Special mechanics
        specialMechanics = {
            coldDamage = true, -- Take damage when not near fire
            slipperyIce = true,
            reducedVisibility = true,
        },
        
        weather = "snow",
    },
    
    ["volcanic"] = {
        name = "Volcanic Wasteland",
        description = "A hellscape of lava and ash",
        theme = "volcanic",
        
        lighting = {
            brightness = 1.5,
            ambient = Color3.fromRGB(150, 100, 80),
            outdoorAmbient = Color3.fromRGB(180, 120, 80),
            clockTime = 18, -- Sunset
            fogEnd = 400,
            fogColor = Color3.fromRGB(100, 60, 40),
        },
        
        biomeWeights = {
            cliff = 0.35,
            desert = 0.30,
            mountain = 0.20,
            meadow = 0.10,
            forest = 0.05, -- Dead trees
        },
        
        hazards = { "lavaFlow", "eruption", "ashStorm" },
        hazardFrequency = 200,
        
        lootModifiers = {
            weaponSpawnRate = 1.2, -- More weapons
            supplyDropFrequency = 200,
            heatResistanceBonus = true,
        },
        
        specialMechanics = {
            lavaPools = true,
            groundShake = true,
            heatDamage = true,
        },
        
        weather = "ash",
    },
    
    ["jungle"] = {
        name = "Deadly Jungle",
        description = "A dense jungle full of danger",
        theme = "jungle",
        
        lighting = {
            brightness = 1.8,
            ambient = Color3.fromRGB(80, 120, 60),
            outdoorAmbient = Color3.fromRGB(100, 150, 80),
            clockTime = 12,
            fogEnd = 300,
            fogColor = Color3.fromRGB(60, 100, 40),
        },
        
        biomeWeights = {
            forest = 0.40,
            swamp = 0.25,
            water = 0.20,
            meadow = 0.10,
            cliff = 0.05,
        },
        
        hazards = { "poisonFog", "insectSwarm", "flood" },
        hazardFrequency = 180,
        
        lootModifiers = {
            weaponSpawnRate = 0.8,
            supplyDropFrequency = 160,
            plantResourcesBonus = true,
        },
        
        specialMechanics = {
            denseVegetation = true, -- Reduced visibility
            hiddenTraps = true,
            venomousCreatures = true,
        },
        
        weather = "humid",
    },
    
    ["night"] = {
        name = "Eternal Night",
        description = "The arena shrouded in permanent darkness",
        theme = "night",
        
        lighting = {
            brightness = 0.5,
            ambient = Color3.fromRGB(20, 20, 40),
            outdoorAmbient = Color3.fromRGB(30, 30, 60),
            clockTime = 0, -- Midnight
            fogEnd = 200,
            fogColor = Color3.fromRGB(10, 10, 20),
        },
        
        biomeWeights = {
            forest = 0.30,
            swamp = 0.25,
            meadow = 0.20,
            cliff = 0.15,
            water = 0.10,
        },
        
        hazards = { "poisonFog", "wildFire", "nightmareMutts" },
        hazardFrequency = 150,
        
        lootModifiers = {
            weaponSpawnRate = 1.1,
            supplyDropFrequency = 140,
            torchBonus = true,
        },
        
        specialMechanics = {
            limitedVision = true,
            soundAmplified = true, -- Footsteps louder
            nightVisionRare = true,
        },
        
        weather = "clear",
    },
    
    ["urban"] = {
        name = "Capitol Ruins",
        description = "Fight in the ruins of a destroyed city",
        theme = "urban",
        
        lighting = {
            brightness = 2,
            ambient = Color3.fromRGB(100, 100, 110),
            outdoorAmbient = Color3.fromRGB(130, 130, 140),
            clockTime = 15,
            fogEnd = 600,
            fogColor = Color3.fromRGB(120, 120, 130),
        },
        
        biomeWeights = {
            cliff = 0.40, -- Ruined buildings
            meadow = 0.25, -- Overgrown areas
            water = 0.15, -- Flooded streets
            forest = 0.15, -- Overgrown parks
            swamp = 0.05,
        },
        
        hazards = { "buildingCollapse", "explosiveTrap", "poisonFog" },
        hazardFrequency = 200,
        
        lootModifiers = {
            weaponSpawnRate = 1.5, -- Lots of scavenging
            supplyDropFrequency = 220,
            urbanLootBonus = true,
        },
        
        specialMechanics = {
            verticalGameplay = true, -- Buildings to climb
            echoingSound = true,
            collapsingStructures = true,
        },
        
        weather = "overcast",
    },
}

-- Apply arena variant
function ArenaVariants:applyVariant(variantId)
    local variant = ARENA_VARIANTS[variantId]
    if not variant then
        warn("[ArenaVariants] Unknown variant: " .. tostring(variantId))
        return false
    end
    
    ArenaVariants.currentVariant = variant
    
    print("[ArenaVariants] Applying variant: " .. variant.name)
    
    -- Apply lighting
    if variant.lighting then
        Lighting.Brightness = variant.lighting.brightness
        Lighting.Ambient = variant.lighting.ambient
        Lighting.OutdoorAmbient = variant.lighting.outdoorAmbient
        Lighting.ClockTime = variant.lighting.clockTime
        Lighting.FogEnd = variant.lighting.fogEnd
        Lighting.FogColor = variant.lighting.fogColor
    end
    
    -- Apply weather effects
    ArenaVariants:applyWeather(variant.weather)
    
    -- Notify all players
    local variantRemote = ReplicatedStorage:FindFirstChild("ArenaVariantRemote")
    if variantRemote then
        variantRemote:FireAllClients("VARIANT_APPLIED", {
            id = variantId,
            name = variant.name,
            description = variant.description,
            theme = variant.theme,
            specialMechanics = variant.specialMechanics
        })
    end
    
    return true
end

-- Apply weather effects
function ArenaVariants:applyWeather(weatherType)
    -- Clear existing weather
    local existingWeather = workspace:FindFirstChild("WeatherEffects")
    if existingWeather then
        existingWeather:Destroy()
    end
    
    if weatherType == "clear" then
        return
    end
    
    local weatherFolder = Instance.new("Folder")
    weatherFolder.Name = "WeatherEffects"
    weatherFolder.Parent = workspace
    
    if weatherType == "snow" then
        -- Create snow particle emitter
        local snowEmitter = Instance.new("Part")
        snowEmitter.Name = "SnowEmitter"
        snowEmitter.Size = Vector3.new(500, 1, 500)
        snowEmitter.Position = Vector3.new(0, 100, 0)
        snowEmitter.Anchored = true
        snowEmitter.CanCollide = false
        snowEmitter.Transparency = 1
        snowEmitter.Parent = weatherFolder
        
        local particles = Instance.new("ParticleEmitter")
        particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        particles.Size = NumberSequence.new(0.3)
        particles.Lifetime = NumberRange.new(5, 8)
        particles.Speed = NumberRange.new(5, 10)
        particles.SpreadAngle = Vector2.new(30, 30)
        particles.Rate = 100
        particles.Rotation = NumberRange.new(0, 360)
        particles.RotSpeed = NumberRange.new(20, 50)
        particles.EmissionDirection = Enum.NormalId.Bottom
        particles.Parent = snowEmitter
        
    elseif weatherType == "ash" then
        local ashEmitter = Instance.new("Part")
        ashEmitter.Name = "AshEmitter"
        ashEmitter.Size = Vector3.new(500, 1, 500)
        ashEmitter.Position = Vector3.new(0, 100, 0)
        ashEmitter.Anchored = true
        ashEmitter.CanCollide = false
        ashEmitter.Transparency = 1
        ashEmitter.Parent = weatherFolder
        
        local particles = Instance.new("ParticleEmitter")
        particles.Color = ColorSequence.new(Color3.fromRGB(80, 80, 80))
        particles.Size = NumberSequence.new(0.2, 0.4)
        particles.Lifetime = NumberRange.new(4, 7)
        particles.Speed = NumberRange.new(3, 8)
        particles.SpreadAngle = Vector2.new(45, 45)
        particles.Rate = 80
        particles.Transparency = NumberSequence.new(0.3, 0.8)
        particles.EmissionDirection = Enum.NormalId.Bottom
        particles.Parent = ashEmitter
        
    elseif weatherType == "humid" then
        -- Fog/mist effect
        Lighting.FogEnd = 200
        Lighting.FogStart = 50
        
    elseif weatherType == "overcast" then
        -- Darker sky
        Lighting.Brightness = Lighting.Brightness * 0.8
    end
end

-- Get current variant
function ArenaVariants:getCurrentVariant()
    return ArenaVariants.currentVariant
end

-- Get all variants for UI
function ArenaVariants:getAllVariants()
    local variants = {}
    for id, variant in pairs(ARENA_VARIANTS) do
        table.insert(variants, {
            id = id,
            name = variant.name,
            description = variant.description,
            theme = variant.theme
        })
    end
    return variants
end

-- Select random variant
function ArenaVariants:selectRandomVariant()
    local variantIds = {}
    for id in pairs(ARENA_VARIANTS) do
        table.insert(variantIds, id)
    end
    
    local randomIndex = math.random(1, #variantIds)
    return variantIds[randomIndex]
end

-- Get hazard config for current variant
function ArenaVariants:getHazardConfig()
    if not ArenaVariants.currentVariant then
        return nil
    end
    
    return {
        hazards = ArenaVariants.currentVariant.hazards,
        frequency = ArenaVariants.currentVariant.hazardFrequency
    }
end

-- Get loot modifiers for current variant
function ArenaVariants:getLootModifiers()
    if not ArenaVariants.currentVariant then
        return { weaponSpawnRate = 1.0, supplyDropFrequency = 180 }
    end
    
    return ArenaVariants.currentVariant.lootModifiers
end

-- Initialize ArenaVariants
function ArenaVariants.init()
    print("[ArenaVariants] Initializing...")
    
    -- Create remote event
    local variantRemote = Instance.new("RemoteEvent")
    variantRemote.Name = "ArenaVariantRemote"
    variantRemote.Parent = ReplicatedStorage
    
    -- Handle remote events
    variantRemote.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}
        
        if action == "GET_VARIANTS" then
            local variants = ArenaVariants:getAllVariants()
            variantRemote:FireClient(player, "VARIANTS_LIST", variants)
            
        elseif action == "GET_CURRENT" then
            if ArenaVariants.currentVariant then
                variantRemote:FireClient(player, "CURRENT_VARIANT", {
                    name = ArenaVariants.currentVariant.name,
                    description = ArenaVariants.currentVariant.description,
                    theme = ArenaVariants.currentVariant.theme
                })
            end
        end
    end)
    
    -- Apply default variant
    ArenaVariants:applyVariant("classic")
    
    print("[ArenaVariants] Initialized with " .. tostring(#ArenaVariants:getAllVariants()) .. " arena variants")
end

return ArenaVariants
