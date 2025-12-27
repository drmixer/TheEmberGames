-- ServerScript: TerrainGenerator.lua
-- Generates Voxel Terrain for The Ember Games
-- Uses Perlin Noise for natural landscapes, hills, rivers, and biomes

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local TerrainGenerator = {}
TerrainGenerator.generatedDecorations = {}
TerrainGenerator.SEED = math.random(1, 100000)
TerrainGenerator.CHUNK_SIZE = 16
TerrainGenerator.RESOLUTION = 4 -- Studs per voxel (4 is Roblox default)

-- Terrain Materials Map
local BIOME_MATERIALS = {
    forest = {Enum.Material.Grass, Enum.Material.Mud},
    meadow = {Enum.Material.Grass, Enum.Material.LeafyGrass},
    water = {Enum.Material.Sand, Enum.Material.Mud}, -- Ground under water
    swamp = {Enum.Material.Mud, Enum.Material.Ground},
    cliff = {Enum.Material.Rock, Enum.Material.Slate},
    desert = {Enum.Material.Sand, Enum.Material.Sandstone},
    mountain = {Enum.Material.Snow, Enum.Material.Rock},
    hills = {Enum.Material.Grass, Enum.Material.Ground}
}

-- Decorations (Keep existing logic but adapted)
-- ... (I will omit full decoration logic here for brevity, assuming we call back to the old helper methods or re-implement)
-- Actually, let's keep the decoration logic but update it to raycast down to find the terrain height!

-- Helper: Get Height at (x, z)
function TerrainGenerator:getHeight(x, z, biomeType)
    local seed = TerrainGenerator.SEED
    local frequency = 0.005
    local amplitude = 20
    local baseHeight = 10 -- Minimum ground level
    
    -- Biome specific overrides
    if biomeType == "mountain" then
        amplitude = 80
        frequency = 0.008
    elseif biomeType == "hills" then
        amplitude = 40
        frequency = 0.006
    elseif biomeType == "water" then
        amplitude = 25
        baseHeight = -5 -- Dig down
    elseif biomeType == "cliff" then
        amplitude = 60
        frequency = 0.015
    elseif biomeType == "swamp" then
        amplitude = 5 -- Flat
        baseHeight = -2 -- Low
    elseif biomeType == "cornucopia" then
        -- Flat center
        return 8, Enum.Material.Pavement
    end
    
    local noise = math.noise(x * frequency + seed, z * frequency + seed, 0)
    
    -- Additional detail noise
    local detail = math.noise(x * 0.05 + seed, z * 0.05 + seed, 123) * 2
    
    return baseHeight + (noise * amplitude) + detail
end

-- Generate a single column of terrain
local function generateColumn(x, z, biomeData)
    local height = TerrainGenerator:getHeight(x, z, biomeData.type)
    local materialList = BIOME_MATERIALS[biomeData.type] or {Enum.Material.Grass}
    local material = materialList[math.random(1, #materialList)]
    
    -- Water Handling
    local seaLevel = 0
    if biomeData.type == "water" or biomeData.type == "swamp" then
        seaLevel = 2 
    end
    
    -- Fill Ground
    Workspace.Terrain:FillBlock(CFrame.new(x, height/2 - 10, z), Vector3.new(4, height + 20, 4), material)
    
    -- Fill Water if below sea level
    if height < seaLevel then
        Workspace.Terrain:FillBlock(
            CFrame.new(x, (seaLevel + height)/2, z), 
            Vector3.new(4, seaLevel - height, 4), 
            Enum.Material.Water
        )
    end
    
    return height
end

-- Decoration Helpers (Simplified from original)
local function getDecorationFolder()
    local folder = Workspace:FindFirstChild("ArenaDecorations") or Instance.new("Folder")
    folder.Name = "ArenaDecorations"
    folder.Parent = Workspace
    return folder
end

local function spawnProp(name, cframe, size, color, material, meshFunc)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.Material = material
    part.Color = color
    part.Parent = getDecorationFolder()
    return part
end

function TerrainGenerator:spawnDecorations(biomeData)
    local count = math.floor(biomeData.radius / 5) -- Density
    local center = biomeData.center
    local radius = biomeData.radius
    
    for i = 1, count do
        -- Random position in circle
        local theta = math.random() * 2 * math.pi
        local r = math.sqrt(math.random()) * radius
        local x = center.X + r * math.cos(theta)
        local z = center.Z + r * math.sin(theta)
        
        -- Raycast to find terrain height
        local origin = Vector3.new(x, 200, z)
        local result = Workspace:Raycast(origin, Vector3.new(0, -300, 0))
        
        if result and result.Instance:IsA("Terrain") then
            local pos = result.Position
            local biome = biomeData.type
            
            if biome == "forest" and math.random() > 0.5 then
                -- Trunk
                 spawnProp("TreeTrunk", CFrame.new(pos + Vector3.new(0,6,0)), Vector3.new(2,12,2), Color3.fromRGB(90,60,40), Enum.Material.Wood)
                 -- Leaves
                 spawnProp("TreeLeaves", CFrame.new(pos + Vector3.new(0,12,0)), Vector3.new(10,8,10), Color3.fromRGB(40,90,40), Enum.Material.Grass)
            elseif biome == "meadow" and math.random() > 0.8 then
                 spawnProp("Bush", CFrame.new(pos + Vector3.new(0,1,0)), Vector3.new(4,3,4), Color3.fromRGB(80,140,60), Enum.Material.Grass)
            elseif biome == "mountain" and math.random() > 0.7 then
                 spawnProp("Rock", CFrame.new(pos + Vector3.new(0,2,0)) * CFrame.Angles(math.random(), math.random(), math.random()), Vector3.new(6,6,6), Color3.fromRGB(100,100,105), Enum.Material.Slate)
            elseif biome == "desert" and math.random() > 0.9 then
                 spawnProp("Cactus", CFrame.new(pos + Vector3.new(0,4,0)), Vector3.new(2,8,2), Color3.fromRGB(60,120,60), Enum.Material.Plastic)
            end
        end
    end
end


function TerrainGenerator:generateAllTerrain(biomeZones)
    print("[TerrainGenerator] Generating Voxel Terrain...")
    Workspace.Terrain:Clear()
    
    -- 1. Create Base Flat Terrain (Safety net)
    -- Actually, let's just generate the biomes.
    
    local mapSize = 1000 -- Total map size
    local step = 4 -- Resolution
    
    -- Start Timer
    local startTime = tick()
    
    -- Iterate through the map area
    for x = -mapSize/2, mapSize/2, step do
        for z = -mapSize/2, mapSize/2, step do
            
            -- Determine which biome controls this pixel
            -- Distance check to all biomes
            local bestBiome = {type = "forest"} -- Default
            local minDidst = 999999
            
            for _, b in ipairs(biomeZones) do
                local dist = math.sqrt((x - b.center.X)^2 + (z - b.center.Z)^2)
                if dist < minDidst then
                    minDidst = dist
                    bestBiome = b
                end
            end
            
            -- If strictly outside any biome radius, maybe blend?
            -- For now, nearest center wins (Voronoi-ish style)
            
            -- Force Cornucopia Flatness
            local centerDist = math.sqrt(x^2 + z^2)
            if centerDist < 40 then
                bestBiome = {type = "cornucopia"}
            end
            
            generateColumn(x, z, bestBiome)
        end
        
        -- Yield every few rows to prevent crash
        if x % 64 == 0 then task.wait() end
    end
    
    print("[TerrainGenerator] Voxel Terrain Done in " .. (tick() - startTime) .. "s. Spawning Decor...")
    
    -- 2. Spawn Decorations
    for _, biome in ipairs(biomeZones) do
        TerrainGenerator:spawnDecorations(biome)
        task.wait()
    end
    
    print("[TerrainGenerator] Generation Complete.")
end

function TerrainGenerator:clearTerrain()
    Workspace.Terrain:Clear()
    if Workspace:FindFirstChild("ArenaDecorations") then
        Workspace.ArenaDecorations:Destroy()
    end
end

function TerrainGenerator.init()
    print("[TerrainGenerator] Voxel Engine Ready")
end

return TerrainGenerator
