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

-- Spawn Loot (Using LootDistribution)
function ArenaService:spawnCornucopiaLoot()
    if ArenaService.cornucopiaLootSpawned then return end
    
    local success, LootDistribution = pcall(function()
        return require(script.Parent.LootDistribution)
    end)
    
    if success and LootDistribution then
        -- Find the Cornucopia Pedestals
        local mapBase = Workspace:FindFirstChild("MapBase")
        local center = Vector3.new(0, 0, 0)
        
        -- If MapBase exists, use its pedestals, otherwise pass center
        LootDistribution:spawnCornucopiaLoot(center)
    else
        warn("[ArenaService] Failed to load LootDistribution")
    end
    
    ArenaService.cornucopiaLootSpawned = true
    arenaRemoteEvent:FireAllClients("CORNUCOPIA_LOOT_SPAWNED")
end

function ArenaService:spawnBiomeLoot()
    local success, LootDistribution = pcall(function()
        return require(script.Parent.LootDistribution)
    end)
    
    if success and LootDistribution then
        local arenaSize = 1000 -- Should match Config
        LootDistribution:spawnGroundLoot(arenaSize)
    else
        warn("[ArenaService] Failed to load LootDistribution for Biome Loot")
    end
    
    print("[ArenaService] Biome Loot Spawned via LootDistribution")
end

function ArenaService:initializeMatch()
    -- arenaSetupComplete just means the map geometry is ready. 
    -- We still need to spawn dynamic content for the match.
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
