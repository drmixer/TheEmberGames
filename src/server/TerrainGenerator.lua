-- ServerScript: TerrainGenerator.lua
-- Creates visual terrain for arena biomes
-- Generates trees, rocks, vegetation, and biome-specific decorations

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local TerrainGenerator = {}
TerrainGenerator.generatedDecorations = {}

-- Color palettes for different biomes
local BIOME_COLORS = {
    forest = {
        ground = Color3.fromRGB(34, 79, 34),       -- Dark forest green
        grass = Color3.fromRGB(50, 120, 50),       -- Medium green
        trees = Color3.fromRGB(30, 60, 30),        -- Dark green leaves
        trunks = Color3.fromRGB(80, 50, 30),       -- Brown
    },
    meadow = {
        ground = Color3.fromRGB(86, 125, 70),      -- Light green
        grass = Color3.fromRGB(124, 176, 78),      -- Bright green
        flowers = {
            Color3.fromRGB(255, 200, 100),         -- Yellow
            Color3.fromRGB(255, 100, 150),         -- Pink
            Color3.fromRGB(150, 100, 255),         -- Purple
            Color3.fromRGB(255, 255, 255),         -- White
        }
    },
    water = {
        ground = Color3.fromRGB(60, 80, 60),       -- Muddy green
        water = Color3.fromRGB(50, 130, 180),      -- Blue water
        rocks = Color3.fromRGB(120, 120, 130),     -- Gray rocks
        reeds = Color3.fromRGB(100, 130, 70),      -- Reed green
    },
    swamp = {
        ground = Color3.fromRGB(50, 60, 40),       -- Dark murky
        water = Color3.fromRGB(60, 80, 50),        -- Green murky water
        trees = Color3.fromRGB(60, 70, 50),        -- Dead tree color
        fog = Color3.fromRGB(150, 180, 150),       -- Foggy green
    },
    cliff = {
        ground = Color3.fromRGB(80, 70, 60),       -- Rocky brown
        rocks = Color3.fromRGB(100, 95, 90),       -- Gray-brown
        stone = Color3.fromRGB(70, 70, 75),        -- Dark stone
    },
    desert = {
        ground = Color3.fromRGB(210, 180, 140),    -- Sand
        sand = Color3.fromRGB(230, 200, 160),      -- Light sand
        rocks = Color3.fromRGB(180, 140, 100),     -- Desert rock
        cactus = Color3.fromRGB(60, 130, 60),      -- Cactus green
    },
    mountain = {
        ground = Color3.fromRGB(90, 85, 80),       -- Mountain gray
        snow = Color3.fromRGB(240, 245, 250),      -- White snow
        rocks = Color3.fromRGB(70, 70, 75),        -- Dark rock
        ice = Color3.fromRGB(180, 210, 230),       -- Light blue ice
    },
    hills = {
        ground = Color3.fromRGB(100, 140, 70),     -- Green-brown
        grass = Color3.fromRGB(80, 130, 60),       -- Hill grass
        rocks = Color3.fromRGB(130, 120, 110),     -- Mixed rocks
    },
}

-- Create a folder to hold all decorations
local function getDecorationFolder()
    local folder = Workspace:FindFirstChild("ArenaDecorations")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ArenaDecorations"
        folder.Parent = Workspace
    end
    return folder
end

-- Create a simple tree
local function createTree(position, biomeType)
    local folder = getDecorationFolder()
    local colors = BIOME_COLORS[biomeType] or BIOME_COLORS.forest
    
    local treeModel = Instance.new("Model")
    treeModel.Name = "Tree"
    
    -- Trunk
    local trunkHeight = math.random(8, 15)
    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Size = Vector3.new(2, trunkHeight, 2)
    trunk.Position = position + Vector3.new(0, trunkHeight / 2, 0)
    trunk.Anchored = true
    trunk.CanCollide = true
    trunk.Material = Enum.Material.Wood
    trunk.Color = colors.trunks or Color3.fromRGB(80, 50, 30)
    trunk.Parent = treeModel
    
    -- Leaves (multiple layers for fuller appearance)
    local leafSizes = {{8, 4, 8}, {10, 5, 10}, {7, 3, 7}}
    local leafOffsets = {0, 4, 8}
    
    for i, size in ipairs(leafSizes) do
        local leaves = Instance.new("Part")
        leaves.Name = "Leaves" .. i
        leaves.Size = Vector3.new(size[1], size[2], size[3])
        leaves.Position = position + Vector3.new(0, trunkHeight + leafOffsets[i], 0)
        leaves.Anchored = true
        leaves.CanCollide = false -- Don't block projectiles
        leaves.Material = Enum.Material.Grass
        leaves.Color = colors.trees or Color3.fromRGB(30, 80, 30)
        leaves.Parent = treeModel
    end
    
    treeModel.Parent = folder
    table.insert(TerrainGenerator.generatedDecorations, treeModel)
    
    return treeModel
end

-- Create a dead/swamp tree
local function createDeadTree(position)
    local folder = getDecorationFolder()
    local colors = BIOME_COLORS.swamp
    
    local treeModel = Instance.new("Model")
    treeModel.Name = "DeadTree"
    
    -- Twisted trunk
    local trunkHeight = math.random(6, 12)
    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Size = Vector3.new(1.5, trunkHeight, 1.5)
    trunk.Position = position + Vector3.new(0, trunkHeight / 2, 0)
    trunk.Anchored = true
    trunk.CanCollide = true
    trunk.Material = Enum.Material.Wood
    trunk.Color = Color3.fromRGB(60, 50, 40) -- Dead gray-brown
    trunk.Parent = treeModel
    
    -- Bare branches
    for i = 1, 3 do
        local branch = Instance.new("Part")
        branch.Name = "Branch" .. i
        branch.Size = Vector3.new(0.5, 4, 0.5)
        local angle = math.rad(30 + math.random(-15, 15))
        branch.CFrame = CFrame.new(position + Vector3.new(0, trunkHeight - 2 + i, 0)) * CFrame.Angles(0, math.rad(i * 120), angle)
        branch.Anchored = true
        branch.CanCollide = false
        branch.Material = Enum.Material.Wood
        branch.Color = Color3.fromRGB(50, 45, 35)
        branch.Parent = treeModel
    end
    
    treeModel.Parent = folder
    table.insert(TerrainGenerator.generatedDecorations, treeModel)
    
    return treeModel
end

-- Create a rock formation
local function createRock(position, size, biomeType)
    local folder = getDecorationFolder()
    local colors = BIOME_COLORS[biomeType] or BIOME_COLORS.cliff
    
    local rockModel = Instance.new("Model")
    rockModel.Name = "Rock"
    
    -- Main rock
    local rock = Instance.new("Part")
    rock.Name = "MainRock"
    rock.Size = Vector3.new(size * 2, size * 1.5, size * 2)
    rock.Position = position + Vector3.new(0, size * 0.75, 0)
    rock.Anchored = true
    rock.CanCollide = true
    rock.Material = Enum.Material.Rock
    rock.Color = colors.rocks or Color3.fromRGB(100, 100, 100)
    rock.Parent = rockModel
    
    -- Add smaller rocks around
    for i = 1, math.random(1, 3) do
        local smallRock = Instance.new("Part")
        smallRock.Name = "SmallRock" .. i
        local smallSize = size * math.random(30, 60) / 100
        smallRock.Size = Vector3.new(smallSize, smallSize * 0.7, smallSize)
        local offset = Vector3.new(
            math.random(-3, 3),
            smallSize * 0.35,
            math.random(-3, 3)
        )
        smallRock.Position = position + offset
        smallRock.Anchored = true
        smallRock.CanCollide = true
        smallRock.Material = Enum.Material.Rock
        smallRock.Color = colors.rocks or Color3.fromRGB(110, 105, 100)
        smallRock.Parent = rockModel
    end
    
    rockModel.Parent = folder
    table.insert(TerrainGenerator.generatedDecorations, rockModel)
    
    return rockModel
end

-- Create a bush/shrub
local function createBush(position, biomeType)
    local folder = getDecorationFolder()
    local colors = BIOME_COLORS[biomeType] or BIOME_COLORS.meadow
    
    local bush = Instance.new("Part")
    bush.Name = "Bush"
    local bushSize = math.random(2, 4)
    bush.Size = Vector3.new(bushSize, bushSize * 0.7, bushSize)
    bush.Position = position + Vector3.new(0, bushSize * 0.35, 0)
    bush.Anchored = true
    bush.CanCollide = false -- Players can walk through
    bush.Material = Enum.Material.Grass
    bush.Color = colors.grass or Color3.fromRGB(60, 120, 60)
    bush.Parent = folder
    
    table.insert(TerrainGenerator.generatedDecorations, bush)
    
    return bush
end

-- Create flowers (meadow decoration)
local function createFlowerPatch(position)
    local folder = getDecorationFolder()
    local colors = BIOME_COLORS.meadow
    
    local flowerModel = Instance.new("Model")
    flowerModel.Name = "FlowerPatch"
    
    for i = 1, math.random(3, 7) do
        local flower = Instance.new("Part")
        flower.Name = "Flower" .. i
        flower.Size = Vector3.new(0.5, 1.5, 0.5)
        local offset = Vector3.new(
            math.random(-2, 2),
            0.75,
            math.random(-2, 2)
        )
        flower.Position = position + offset
        flower.Anchored = true
        flower.CanCollide = false
        flower.Material = Enum.Material.SmoothPlastic
        flower.Color = colors.flowers[math.random(1, #colors.flowers)]
        flower.Parent = flowerModel
    end
    
    flowerModel.Parent = folder
    table.insert(TerrainGenerator.generatedDecorations, flowerModel)
    
    return flowerModel
end

-- Create a cactus
local function createCactus(position)
    local folder = getDecorationFolder()
    local colors = BIOME_COLORS.desert
    
    local cactusModel = Instance.new("Model")
    cactusModel.Name = "Cactus"
    
    -- Main body
    local cactusHeight = math.random(4, 8)
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(2, cactusHeight, 2)
    body.Position = position + Vector3.new(0, cactusHeight / 2, 0)
    body.Anchored = true
    body.CanCollide = true
    body.Material = Enum.Material.SmoothPlastic
    body.Color = colors.cactus
    body.Parent = cactusModel
    
    -- Arms (optional)
    if math.random() > 0.5 then
        local arm = Instance.new("Part")
        arm.Name = "Arm"
        arm.Size = Vector3.new(1, 3, 1)
        arm.Position = position + Vector3.new(1.5, cactusHeight * 0.6, 0)
        arm.Anchored = true
        arm.CanCollide = false
        arm.Material = Enum.Material.SmoothPlastic
        arm.Color = colors.cactus
        arm.Parent = cactusModel
    end
    
    cactusModel.Parent = folder
    table.insert(TerrainGenerator.generatedDecorations, cactusModel)
    
    return cactusModel
end

-- Create water puddle/pool
local function createWaterPool(position, size)
    local folder = getDecorationFolder()
    local colors = BIOME_COLORS.water
    
    local pool = Instance.new("Part")
    pool.Name = "WaterPool"
    pool.Size = Vector3.new(size, 0.5, size)
    pool.Position = position + Vector3.new(0, 0.25, 0)
    pool.Anchored = true
    pool.CanCollide = false
    pool.Material = Enum.Material.Water
    pool.Color = colors.water
    pool.Transparency = 0.3
    pool.Parent = folder
    
    table.insert(TerrainGenerator.generatedDecorations, pool)
    
    return pool
end

-- Create a snow patch (for mountain biome)
local function createSnowPatch(position, size)
    local folder = getDecorationFolder()
    local colors = BIOME_COLORS.mountain
    
    local snow = Instance.new("Part")
    snow.Name = "SnowPatch"
    snow.Size = Vector3.new(size, 0.3, size)
    snow.Position = position + Vector3.new(0, 0.15, 0)
    snow.Anchored = true
    snow.CanCollide = false
    snow.Material = Enum.Material.Snow
    snow.Color = colors.snow
    snow.Parent = folder
    
    table.insert(TerrainGenerator.generatedDecorations, snow)
    
    return snow
end

-- Generate biome ground color variation
local function createGroundPatch(position, size, biomeType)
    local folder = getDecorationFolder()
    local colors = BIOME_COLORS[biomeType] or BIOME_COLORS.meadow
    
    local ground = Instance.new("Part")
    ground.Name = "GroundPatch"
    ground.Size = Vector3.new(size, 0.2, size)
    ground.Position = position + Vector3.new(0, 0.6, 0) -- Just above main ground
    ground.Anchored = true
    ground.CanCollide = false
    ground.Material = biomeType == "desert" and Enum.Material.Sand or Enum.Material.Grass
    ground.Color = colors.ground
    ground.Parent = folder
    
    table.insert(TerrainGenerator.generatedDecorations, ground)
    
    return ground
end

-- Generate decorations for a specific biome
function TerrainGenerator:generateBiomeTerrain(biomeData)
    local biomeType = biomeData.type
    local center = biomeData.center
    local radius = biomeData.radius
    
    print("[TerrainGenerator] Generating terrain for " .. biomeData.name .. " (" .. biomeType .. ")")
    
    -- Generate ground patches for color variation
    local patchCount = math.floor(radius / 15)
    for i = 1, patchCount do
        local angle = math.random() * 2 * math.pi
        local distance = math.random(5, math.floor(radius * 0.9))
        local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
        createGroundPatch(pos, math.random(15, 30), biomeType)
    end
    
    -- Generate biome-specific decorations
    if biomeType == "forest" then
        -- Dense trees
        local treeCount = math.floor(radius / 8)
        for i = 1, treeCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(10, math.floor(radius * 0.85))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createTree(pos, "forest")
        end
        
        -- Bushes
        local bushCount = math.floor(radius / 12)
        for i = 1, bushCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(5, math.floor(radius * 0.9))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createBush(pos, "forest")
        end
        
        -- Rocks
        local rockCount = math.floor(radius / 25)
        for i = 1, rockCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(10, math.floor(radius * 0.8))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createRock(pos, math.random(2, 4), "forest")
        end
        
    elseif biomeType == "meadow" then
        -- Scattered trees
        local treeCount = math.floor(radius / 30)
        for i = 1, treeCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(15, math.floor(radius * 0.85))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createTree(pos, "meadow")
        end
        
        -- Flower patches
        local flowerCount = math.floor(radius / 10)
        for i = 1, flowerCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(5, math.floor(radius * 0.9))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createFlowerPatch(pos)
        end
        
        -- Bushes
        local bushCount = math.floor(radius / 20)
        for i = 1, bushCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(10, math.floor(radius * 0.85))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createBush(pos, "meadow")
        end
        
    elseif biomeType == "water" then
        -- Water pools
        local poolCount = math.floor(radius / 20)
        for i = 1, poolCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(5, math.floor(radius * 0.7))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createWaterPool(pos, math.random(10, 25))
        end
        
        -- River rocks
        local rockCount = math.floor(radius / 15)
        for i = 1, rockCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(10, math.floor(radius * 0.85))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createRock(pos, math.random(1, 3), "water")
        end
        
    elseif biomeType == "swamp" then
        -- Dead trees
        local treeCount = math.floor(radius / 12)
        for i = 1, treeCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(8, math.floor(radius * 0.85))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createDeadTree(pos)
        end
        
        -- Murky water pools
        local poolCount = math.floor(radius / 18)
        for i = 1, poolCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(5, math.floor(radius * 0.8))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            local pool = createWaterPool(pos, math.random(8, 18))
            pool.Color = BIOME_COLORS.swamp.water
            pool.Transparency = 0.5
        end
        
    elseif biomeType == "cliff" then
        -- Large rock formations
        local rockCount = math.floor(radius / 12)
        for i = 1, rockCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(8, math.floor(radius * 0.85))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createRock(pos, math.random(4, 8), "cliff")
        end
        
    elseif biomeType == "desert" then
        -- Cacti
        local cactusCount = math.floor(radius / 20)
        for i = 1, cactusCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(10, math.floor(radius * 0.85))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createCactus(pos)
        end
        
        -- Desert rocks
        local rockCount = math.floor(radius / 25)
        for i = 1, rockCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(8, math.floor(radius * 0.8))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createRock(pos, math.random(2, 5), "desert")
        end
        
    elseif biomeType == "mountain" then
        -- Large rocks/boulders
        local rockCount = math.floor(radius / 10)
        for i = 1, rockCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(8, math.floor(radius * 0.85))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createRock(pos, math.random(4, 10), "mountain")
        end
        
        -- Snow patches
        local snowCount = math.floor(radius / 15)
        for i = 1, snowCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(5, math.floor(radius * 0.9))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createSnowPatch(pos, math.random(10, 20))
        end
        
    elseif biomeType == "hills" then
        -- Scattered trees
        local treeCount = math.floor(radius / 25)
        for i = 1, treeCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(15, math.floor(radius * 0.85))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createTree(pos, "hills")
        end
        
        -- Mixed rocks
        local rockCount = math.floor(radius / 20)
        for i = 1, rockCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(10, math.floor(radius * 0.85))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createRock(pos, math.random(2, 5), "hills")
        end
        
        -- Bushes
        local bushCount = math.floor(radius / 18)
        for i = 1, bushCount do
            local angle = math.random() * 2 * math.pi
            local distance = math.random(8, math.floor(radius * 0.9))
            local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            createBush(pos, "hills")
        end
    end
    
    print("[TerrainGenerator] Completed terrain for " .. biomeData.name)
end

-- Generate all arena terrain
function TerrainGenerator:generateAllTerrain(biomeZones)
    print("[TerrainGenerator] Starting full terrain generation...")
    
    for _, biome in ipairs(biomeZones) do
        if biome.type ~= "landmark" then -- Skip Cornucopia center
            TerrainGenerator:generateBiomeTerrain(biome)
        end
    end
    
    print("[TerrainGenerator] Terrain generation complete. Created " .. #TerrainGenerator.generatedDecorations .. " decorations")
end

-- Clear all generated terrain
function TerrainGenerator:clearTerrain()
    local folder = Workspace:FindFirstChild("ArenaDecorations")
    if folder then
        folder:Destroy()
    end
    TerrainGenerator.generatedDecorations = {}
    print("[TerrainGenerator] Terrain cleared")
end

-- Initialize terrain generator
function TerrainGenerator.init()
    print("[TerrainGenerator] Initialized")
end

return TerrainGenerator
