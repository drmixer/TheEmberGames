-- ServerScript: ArenaService.lua
-- Handles arena setup, Cornucopia loot spawn
-- Manages arena boundaries, hazards, and dynamic environment changes
-- Updated with Raycast Loot Spawning

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local ArenaService = {}
ArenaService.arenaSetupComplete = false
ArenaService.cornucopiaLootSpawned = false
ArenaService.biomeZones = {}
ArenaService.cornucopiaModel = nil 

-- RemoteEvents
local arenaRemoteEvent = Instance.new("RemoteEvent")
arenaRemoteEvent.Name = "ArenaRemoteEvent"
arenaRemoteEvent.Parent = ReplicatedStorage

-- Define biome zones
local function setupBiomeZones()
    ArenaService.biomeZones = {
        {
            name = "Cornucopia",
            center = Vector3.new(0, 0, 0),
            radius = 45,
            type = "cornucopia",
            description = "The center of the arena"
        },
        -- Quadrants
        { name = "Green Forest", center = Vector3.new(250, 0, 250), radius = 200, type = "forest" },
        { name = "Golden Meadow", center = Vector3.new(-250, 0, 250), radius = 200, type = "meadow" },
        { name = "Dead Swamp", center = Vector3.new(-250, 0, -250), radius = 200, type = "swamp" },
        { name = "Rocky Peaks", center = Vector3.new(250, 0, -250), radius = 200, type = "mountain" },
        
        -- Transitions/Features
        { name = "Southern River", center = Vector3.new(0, 0, 300), radius = 100, type = "water" },
        { name = "Northern Dust", center = Vector3.new(0, 0, -300), radius = 100, type = "desert" },
    }
end

-- Create Invisible Walls
local function createArenaBoundaries()
    local arenaSize = 1000 -- Config.ARENA_SIZE usually
    local wallHeight = 300
    
    local folder = Instance.new("Folder")
    folder.Name = "ArenaBoundaries"
    folder.Parent = Workspace
    
    local function makeWall(pos, size)
        local wall = Instance.new("Part")
        wall.Name = "Boundary"
        wall.Size = size
        wall.Position = pos
        wall.Anchored = true
        wall.CanCollide = true
        wall.Transparency = 1
        wall.Material = Enum.Material.ForceField -- Just in case visibility toggled
        wall.Parent = folder
    end
    
    makeWall(Vector3.new(0, wallHeight/2, -arenaSize/2), Vector3.new(arenaSize, wallHeight, 10))
    makeWall(Vector3.new(0, wallHeight/2, arenaSize/2), Vector3.new(arenaSize, wallHeight, 10))
    makeWall(Vector3.new(arenaSize/2, wallHeight/2, 0), Vector3.new(10, wallHeight, arenaSize))
    makeWall(Vector3.new(-arenaSize/2, wallHeight/2, 0), Vector3.new(10, wallHeight, arenaSize))
end

-- Create Cornucopia Structure
local function createCornucopia()
    local cornucopiaBase = Instance.new("Part")
    cornucopiaBase.Name = "Cornucopia"
    cornucopiaBase.Size = Vector3.new(40, 4, 40)
    cornucopiaBase.Position = Vector3.new(0, 10, 0) -- Slightly elevated platform
    cornucopiaBase.Anchored = true
    cornucopiaBase.CanCollide = true
    cornucopiaBase.Material = Enum.Material.Metal
    cornucopiaBase.Color = Color3.fromRGB(180, 160, 120) -- Bronze
    cornucopiaBase.Parent = Workspace
    
    -- Decorative Horn
    local horn = Instance.new("Part") 
    horn.Size = Vector3.new(10, 20, 10)
    horn.CFrame = cornucopiaBase.CFrame * CFrame.new(0, 12, 0)
    horn.Anchored = true
    horn.Material = Enum.Material.Metal
    horn.Color = Color3.fromRGB(200, 180, 50) -- Gold
    horn.Parent = Workspace
    
    ArenaService.cornucopiaModel = cornucopiaBase
end

-- Spawn Loot (Simplified for new terrain)
function ArenaService:spawnCornucopiaLoot()
    if ArenaService.cornucopiaLootSpawned then return end
    
    local items = {
        "Sword", "Bow", "Spear", "Axe", "Medkit", "Backpack"
    }
    
    for i = 1, 12 do
        local angle = (i / 12) * math.pi * 2
        local dist = 10
        local pos = Vector3.new(math.cos(angle)*dist, 14, math.sin(angle)*dist) -- On platform
        
        local part = Instance.new("Part")
        part.Name = "Loot_" .. items[math.random(1, #items)]
        part.Size = Vector3.new(2,2,2)
        part.Position = pos
        part.Anchored = true
        part.CanCollide = false
        part.Color = Color3.fromRGB(255, 215, 0) -- Gold Box placeholder
        part.Parent = Workspace
    end
    
    ArenaService.cornucopiaLootSpawned = true
    arenaRemoteEvent:FireAllClients("CORNUCOPIA_LOOT_SPAWNED")
end

function ArenaService:spawnBiomeLoot()
    -- Spawn random spread loot across biomes
    for _, biome in ipairs(ArenaService.biomeZones) do
        if biome.type ~= "cornucopia" then
            local count = math.random(5, 10)
            for i = 1, count do
                local theta = math.random() * 2 * math.pi
                local r = math.sqrt(math.random()) * (biome.radius * 0.8)
                local x = biome.center.X + r * math.cos(theta)
                local z = biome.center.Z + r * math.sin(theta)
                
                -- Raycast down to find ground
                local rayOrigin = Vector3.new(x, 150, z)
                local rayDir = Vector3.new(0, -200, 0)
                local result = Workspace:Raycast(rayOrigin, rayDir)
                
                if result then
                    local groundPos = result.Position
                    if result.Instance.Name ~= "Water" then -- Avoid underwater loot if possible
                         local box = Instance.new("Part")
                         box.Name = "BiomeLoot"
                         box.Size = Vector3.new(2, 2, 2)
                         box.Position = groundPos + Vector3.new(0, 1, 0)
                         box.Anchored = true
                         box.CanCollide = false
                         box.Color = Color3.fromRGB(150, 150, 150)
                         box.Material = Enum.Material.Wood
                         box.Parent = Workspace
                    end
                end
            end
        end
    end
    print("[ArenaService] Biome Loot Spawned via Raycast")
end

function ArenaService:initializeMatch()
    if ArenaService.arenaSetupComplete then return end
    ArenaService:spawnCornucopiaLoot()
    ArenaService:spawnBiomeLoot()
    arenaRemoteEvent:FireAllClients("ARENA_INITIALIZED")
end

function ArenaService.init()
    print("[ArenaService] Initializing...")
    setupBiomeZones()
    createArenaBoundaries()
    createCornucopia()
    
    -- Generate Terrain
    local success, TerrainGenerator = pcall(function() return require(script.Parent.TerrainGenerator) end)
    if success and TerrainGenerator then
        TerrainGenerator.init()
        TerrainGenerator:generateAllTerrain(ArenaService.biomeZones)
    else
        warn("[ArenaService] Failed to load TerrainGenerator!")
    end
    
    ArenaService.arenaSetupComplete = true
    print("[ArenaService] Setup Complete")
end

return ArenaService
