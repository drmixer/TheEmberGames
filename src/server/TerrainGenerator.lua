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

-- Helper: Spawn harvestable resource node
local function spawnResourceNode(resourceName, resourceData, position)
    local part = Instance.new("Part")
    part.Name = "ResourceNode_" .. resourceName
    part.Size = Vector3.new(4, 4, 4) -- Default size
    
    -- Customize appearance based on resource
    if resourceName:find("Wood") or resourceName:find("Tree") then
        local height = math.random(10, 18)
        part.Size = Vector3.new(2, height, 2)
        part.Position = position + Vector3.new(0, height/2, 0)
        part.Color = Color3.fromRGB(90, 60, 40)
        part.Material = Enum.Material.Wood
        
        -- Add leaves for trees
        local leaves = Instance.new("Part")
        leaves.Name = "Leaves"
        leaves.Size = Vector3.new(8, 6, 8)
        leaves.Position = position + Vector3.new(0, height, 0)
        leaves.Color = Color3.fromRGB(40, 90, 40)
        leaves.Material = Enum.Material.Grass
        leaves.Anchored = true
        leaves.CanCollide = false
        leaves.Parent = getDecorationFolder()
        
    elseif resourceName:find("Stone") or resourceName:find("Rock") or resourceName:find("Coal") then
        part.Size = Vector3.new(math.random(4,6), math.random(3,5), math.random(4,6))
        part.Position = position + Vector3.new(0, part.Size.Y/2, 0)
        part.Material = Enum.Material.Slate
        part.Shape = Enum.PartType.Ball
        
        if resourceName:find("Coal") then
            part.Color = Color3.fromRGB(20, 20, 20)
        elseif resourceName:find("Frozen") then
            part.Color = Color3.fromRGB(200, 240, 255)
            part.Material = Enum.Material.Ice
        elseif resourceName:find("Volcanic") then
            part.Color = Color3.fromRGB(40, 40, 40)
            part.Material = Enum.Material.Basalt
        else
            part.Color = Color3.fromRGB(100, 100, 105)
        end
        
    elseif resourceName:find("Berry") or resourceName:find("Herb") or resourceName:find("Flower") then
        part.Size = Vector3.new(3, 3, 3)
        part.Position = position + Vector3.new(0, 1.5, 0)
        part.Shape = Enum.PartType.Ball
        part.Material = Enum.Material.Grass
        part.Color = Color3.fromRGB(80, 140, 60)
        part.CanCollide = false -- Walk through bushes
        
    else
        -- Generic pickup
        part.Size = Vector3.new(2, 2, 2)
        part.Position = position + Vector3.new(0, 1, 0)
        part.Color = Color3.fromRGB(200, 200, 200)
        part.Material = Enum.Material.Plastic
    end
    
    part.Anchored = true
    part.Parent = getDecorationFolder()
    
    -- Tag as harvestable
    part:SetAttribute("IsResource", true)
    part:SetAttribute("ResourceName", resourceName)
    part:SetAttribute("Amount", math.random(1, 3))
    
    -- Add Prompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Gather " .. (resourceData.displayName or resourceName)
    prompt.ObjectText = resourceData.rarity .. " Material"
    prompt.HoldDuration = resourceData.gatherTime or 1
    prompt.MaxActivationDistance = 8
    prompt.Parent = part
    
    return part
end

function TerrainGenerator:spawnDecorations(biomeData)
    -- Fix: Correctly require from ReplicatedStorage (assuming src/shared maps there)
    local BiomeResources 
    local success, module = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("BiomeResources")) 
    end)
    
    if not success then
        -- Fallback if mapped differently (e.g. inside a Shared folder)
        success, module = pcall(function()
             return require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BiomeResources"))
        end)
    end
    
    if not success then
        warn("[TerrainGenerator] Failed to load BiomeResources!")
        return
    end
    BiomeResources = module
    
    local count = math.floor(biomeData.radius / 8) -- Density (slightly lower for meaningful resources)
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
        local direction = Vector3.new(0, -300, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {getDecorationFolder()} -- Don't hit other decor
        
        local result = Workspace:Raycast(origin, direction, raycastParams)
        
        if result and result.Instance:IsA("Terrain") then
            -- Check water depth (don't spawn underwater unless water resource)
            if result.Position.Y < -2 then continue end 
            
            local pos = result.Position
            local biome = biomeData.type
            
            -- Decide what to spawn using BiomeResources
            local resourceName, resourceData = BiomeResources:getRandomResourceForBiome(biome)
            
            if resourceName then
                spawnResourceNode(resourceName, resourceData, pos)
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
