-- ServerScript: TerrainGenerator.lua
-- "The Ember Games" Map Generator
-- Optimized: Uses Part-based generation (WedgeParts) for stylized Low Poly terrain
-- Features: Perlin Noise, Biomes (2D Regions), Water, and Structure placement

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TerrainGenerator = {}
TerrainGenerator.SEED = math.random(1, 10000)
TerrainGenerator.MAP_SIZE = 1400 -- Expanded to prevent edges showing
TerrainGenerator.CHUNK_SIZE = 20 -- Size of each terrain tile
TerrainGenerator.AMPLITUDE = 60 -- Max height
TerrainGenerator.SCALE = 150 -- Noise zoom
TerrainGenerator.WATER_LEVEL = -8 -- REVERTED: Back to original water level

-- Biomes Configuration (Default, can be overridden)
local DEFAULT_BIOME_ZONES = {
    { name = "Desert", center = Vector3.new(0, 0, -500), radius = 600, type = "desert" }, -- Priority Desert
    { name = "Forest", center = Vector3.new(350, 0, 350), radius = 350, type = "forest" },
    { name = "Meadow", center = Vector3.new(-350, 0, 350), radius = 350, type = "meadow" },
    { name = "Swamp", center = Vector3.new(-350, 0, -350), radius = 350, type = "swamp" },
    { name = "Mountain", center = Vector3.new(350, 0, -350), radius = 400, type = "mountain" },
}
TerrainGenerator.activeZones = DEFAULT_BIOME_ZONES

-- Colors and Materials for Biomes
local COLORS = {
    GRASS_FOREST = Color3.fromRGB(66, 115, 66),
    GRASS_MEADOW = Color3.fromRGB(98, 168, 98),
    GRASS_SWAMP = Color3.fromRGB(47, 71, 47),
    DIRT = Color3.fromRGB(117, 88, 68),
    ROCK = Color3.fromRGB(100, 100, 100),
    SAND = Color3.fromRGB(235, 200, 130),
    RED_SAND = Color3.fromRGB(200, 140, 100),
    SNOW = Color3.fromRGB(240, 245, 255),
    WATER = Color3.fromRGB(60, 160, 220),
    
    -- Trees
    TREE_TRUNK = Color3.fromRGB(94, 69, 53),
    TREE_LEAVES_1 = Color3.fromRGB(56, 122, 56),
    TREE_LEAVES_2 = Color3.fromRGB(108, 158, 66),
    PINE_LEAVES = Color3.fromRGB(30, 70, 40),
    CACTUS = Color3.fromRGB(80, 140, 60),
    
    CORNUCOPIA = Color3.fromRGB(50, 50, 55)
}

-- Helpers
local function createPart(name, size, pos, color, material, parent)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = pos
    p.Color = color
    p.Material = material
    p.Anchored = true
    p.CanCollide = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

-- Noise Function Wrapper
function TerrainGenerator:getNoiseHeight(x, z)
    -- Flatten center for Cornucopia (Radius 80)
    local dist = math.sqrt(x*x + z*z)
    local centerRadius = 80
    local blendRadius = 120
    
    -- Base noise
    local noise = math.noise(x / self.SCALE, z / self.SCALE, self.SEED)
    local height = noise * self.AMPLITUDE + 5 -- REVERTED: Lift set back to +5 (was +40)
    
    -- Additional detail noise
    local detail = math.noise(x / (self.SCALE/3), z / (self.SCALE/3), self.SEED * 2) * 10
    height = height + detail
    
    -- Mountain Boost
    for _, zone in ipairs(self.activeZones) do
        if zone.type == "mountain" then
             local distToMtn = math.sqrt((x - zone.center.X)^2 + (z - zone.center.Z)^2)
             if distToMtn < zone.radius then
                 -- Peak height boost (Parabolic)
                 local boostFactor = 1 - (distToMtn / zone.radius)
                 
                 -- Make mountains massive and always positive
                 -- Use abs(noise) to ensure mountains are bulky
                 local mountainShape = (math.abs(noise) + 0.5) -- 0.5 to 1.0 range approx
                 
                 -- Add up to 130 studs extra height
                 height = height + (boostFactor * boostFactor * 130 * mountainShape)
             end
        end
    end
    
    if dist < centerRadius then
        return 5 -- REVERTED: Flat center at 5
    elseif dist < blendRadius then
        local alpha = (dist - centerRadius) / (blendRadius - centerRadius)
        return 5 + (height - 5) * alpha
    else
        return height
    end
end

-- Determine Biome based on X,Z position relative to Zones
function TerrainGenerator:getBiome(x, z)
    local pos = Vector3.new(x, 0, z)
    
    -- Cornucopia Check
    if math.sqrt(x*x + z*z) < 100 then
        return "cornucopia"
    end
    
    -- Check zones
    for _, zone in ipairs(self.activeZones) do
        local dist = (pos - Vector3.new(zone.center.X, 0, zone.center.Z)).Magnitude
        if dist < zone.radius then
            return zone.type
        end
    end
    
    -- Default fallback
    return "forest"
end

-- Prop Generators
local function spawnTree(pos, parent, biome)
    local height = math.random(12, 18)
    local width = math.random(15, 25) / 10
    
    local trunkColor = COLORS.TREE_TRUNK
    local leaves1 = COLORS.TREE_LEAVES_1
    local leaves2 = COLORS.TREE_LEAVES_2
    local shape = "Normal"
    
    if biome == "swamp" then
        height = math.random(10, 15)
        trunkColor = Color3.fromRGB(60, 50, 40) -- Darker wood
        leaves1 = Color3.fromRGB(40, 70, 40) -- Dark green
        leaves2 = Color3.fromRGB(60, 90, 50)
    elseif biome == "mountain" or pos.Y > 30 then
        shape = "Pine"
        height = math.random(18, 25)
        leaves1 = COLORS.PINE_LEAVES
        leaves2 = Color3.fromRGB(50, 90, 60)
    elseif biome == "forest" then
        -- Default
    end
    
    -- Snow Logic (Reverted threshold)
    if pos.Y > 50 then 
        leaves2 = COLORS.SNOW -- Snowy tips
        leaves1 = Color3.fromRGB(80, 100, 90) -- Frozen leaves
    end
    
    -- Trunk
    -- Sink trunk 1.5 studs into ground to fix floating on slopes
    local trunk = createPart("Trunk", Vector3.new(width, height, width), pos + Vector3.new(0, height/2 - 1.5, 0), trunkColor, Enum.Material.Wood, parent)
    
    -- Leaves
    local leafSize = math.random(8, 14)
    local leavesCenter = pos + Vector3.new(0, height - 1.5, 0) -- Top of trunk (adjusted)
    
    if shape == "Pine" then
        -- Cone-like structure (3 tiers of leaves)
        for i = 1, 3 do
            local tierSize = leafSize * (1 - (i-1)*0.25)
            local yOffset = (i-1) * 4
            local l = createPart("PineLeaves", Vector3.new(tierSize, tierSize, tierSize), leavesCenter + Vector3.new(0, yOffset - 2, 0), (i==3 and leaves2 or leaves1), Enum.Material.Plastic, parent)
            l.CanCollide = false
            l.CFrame = l.CFrame * CFrame.Angles(math.rad(math.random(0,360)), math.rad(math.random(0,360)), math.rad(math.random(0,360)))
        end
    else
        -- Standard Tree
        local l1 = createPart("Leaves", Vector3.new(leafSize, leafSize, leafSize), leavesCenter, leaves1, Enum.Material.Plastic, parent)
        l1.CanCollide = false
        
        local l2 = createPart("Leaves", Vector3.new(leafSize, leafSize, leafSize), leavesCenter, leaves2, Enum.Material.Plastic, parent)
        l2.CFrame = CFrame.new(leavesCenter) * CFrame.Angles(math.rad(45), math.rad(45), 0)
        l2.CanCollide = false
    end
end

local function spawnCactus(pos, parent)
    local height = math.random(8, 14)
    local width = math.random(20, 30) / 10
    
    local c = createPart("Cactus", Vector3.new(width, height, width), pos + Vector3.new(0, height/2 - 1, 0), COLORS.CACTUS, Enum.Material.Plastic, parent)
    
    -- Arm
    if math.random() > 0.5 then
        local armHeight = height * 0.4
        local armY = pos.Y + height * 0.6
        local arm = createPart("CactusArm", Vector3.new(width, width, armHeight), Vector3.new(pos.X + width, armY, pos.Z), COLORS.CACTUS, Enum.Material.Plastic, parent)
        local armUp = createPart("CactusArmUp", Vector3.new(width, armHeight, width), Vector3.new(pos.X + width + width/2, armY + armHeight/2, pos.Z), COLORS.CACTUS, Enum.Material.Plastic, parent)
    end
end

local function spawnRock(pos, parent, biome)
    local size = math.random(3, 8)
    local color = COLORS.ROCK
    if biome == "desert" then color = Color3.fromRGB(180, 130, 90) end -- Sandstone
    if biome == "cornucopia" then return end -- No rocks in base
    
    local p = createPart("Rock", Vector3.new(size, size*0.8, size), pos + Vector3.new(0, size/3 - 0.5, 0), color, Enum.Material.Slate, parent)
    p.CFrame = CFrame.new(pos + Vector3.new(0, size/3 - 0.5, 0)) * CFrame.Angles(math.random(), math.random(), math.random())
    return p
end

-- Terrain Mesh Generation
function TerrainGenerator:draw3DTriangle(a, b, c, parent, color, material)
    local ab, ac, bc = b - a, c - a, c - b
    local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)

    if abd > acd and abd > bcd then
        c, a = a, c
    elseif acd > bcd and acd > abd then
        a, b = b, a
    end

    ab, ac, bc = b - a, c - a, c - b

    local right = ac:Cross(ab).Unit
    local up = bc:Cross(right).Unit
    local back = bc.Unit

    local height = math.abs(ab:Dot(up))
    local width1 = math.abs(ab:Dot(back))
    local width2 = math.abs(ac:Dot(back))

    -- Wedge 1
    local w1 = Instance.new("WedgePart")
    w1.Name = "TerrainWedge"
    w1.Material = material
    w1.Color = color
    w1.Anchored = true
    w1.CanCollide = true
    w1.Size = Vector3.new(0.2, height, width1)
    w1.CFrame = CFrame.fromMatrix((a + b)/2, right, up, back)
    w1.Parent = parent

    -- Wedge 2
    local w2 = Instance.new("WedgePart")
    w2.Name = "TerrainWedge"
    w2.Material = material
    w2.Color = color
    w2.Anchored = true
    w2.CanCollide = true
    w2.Size = Vector3.new(0.2, height, width2)
    w2.CFrame = CFrame.fromMatrix((a + c)/2, -right, up, -back)
    w2.Parent = parent
    
    return w1, w2
end

function TerrainGenerator:createQuad(p1, p2, p3, p4, color, material, parent)
    self:draw3DTriangle(p1, p2, p3, parent, color, material)
    self:draw3DTriangle(p3, p4, p2, parent, color, material)
end

function TerrainGenerator:generateGround()
    local baseFolder = Instance.new("Folder")
    baseFolder.Name = "MapBase"
    baseFolder.Parent = Workspace
    
    local propsFolder = Instance.new("Folder")
    propsFolder.Name = "MapProps"
    propsFolder.Parent = Workspace
    
    local geometryFolder = Instance.new("Folder")
    geometryFolder.Name = "MapGeometry"
    geometryFolder.Parent = Workspace
    
    -- World Foundation (Hides Void)
    -- Massive 200-thick block to catch ANY deep basins
    local foundation = createPart("WorldFoundation", Vector3.new(3000, 200, 3000), Vector3.new(0, -100, 0), Color3.fromRGB(40, 30, 20), Enum.Material.Slate, geometryFolder)
    
    -- Water Plane
    local waterSize = self.MAP_SIZE * 1.5
    local water = createPart("Water", Vector3.new(waterSize, 1, waterSize), Vector3.new(0, self.WATER_LEVEL, 0), COLORS.WATER, Enum.Material.Glass, geometryFolder)
    water.Transparency = 0.4
    water.CanCollide = false
    
    -- Generate Grid
    local steps = math.floor(self.MAP_SIZE / self.CHUNK_SIZE)
    local offset = -self.MAP_SIZE / 2
    
    for x = 0, steps - 1 do
        for z = 0, steps - 1 do
            local x1 = offset + (x * self.CHUNK_SIZE)
            local z1 = offset + (z * self.CHUNK_SIZE)
            local x2 = x1 + self.CHUNK_SIZE
            local z2 = z1 + self.CHUNK_SIZE
            
            local y1 = self:getNoiseHeight(x1, z1)
            local y2 = self:getNoiseHeight(x2, z1)
            local y3 = self:getNoiseHeight(x1, z2)
            local y4 = self:getNoiseHeight(x2, z2)
            
            local avgY = (y1 + y2 + y3 + y4) / 4
            local centerX = (x1 + x2)/2
            local centerZ = (z1 + z2)/2
            
            local biome = self:getBiome(centerX, centerZ)
            
            local color = COLORS.GRASS_FOREST
            local material = Enum.Material.Grass
            
            -- Biome-specific texturing
            if avgY < self.WATER_LEVEL + 2 then
                color = COLORS.SAND
                material = Enum.Material.Sand
            elseif avgY > 50 then  -- REVERTED Snow height
                 color = COLORS.SNOW
                 material = Enum.Material.Snow
            elseif avgY > 25 then
                 if biome == "desert" then color = COLORS.RED_SAND; material = Enum.Material.Slate
                 else color = COLORS.ROCK; material = Enum.Material.Slate end
            else
                -- Ground Level
                if biome == "desert" then
                     color = COLORS.SAND
                     material = Enum.Material.Sand
                elseif biome == "swamp" then
                     color = COLORS.GRASS_SWAMP
                     material = Enum.Material.Grass
                elseif biome == "meadow" then
                     color = COLORS.GRASS_MEADOW
                elseif biome == "cornucopia" then
                     color = Color3.fromRGB(80, 80, 80) -- Dark Stone
                     material = Enum.Material.Cobblestone
                end
            end
            
            self:createQuad(Vector3.new(x1, y1, z1), Vector3.new(x2, y2, z1), Vector3.new(x1, y3, z2), Vector3.new(x2, y4, z2), color, material, geometryFolder)
        end
        if x % 5 == 0 then task.wait() end 
    end
    
    -- Walls
    local wallHeight = 80
    local thickness = 5
    local radius = self.MAP_SIZE / 2
    local circumference = 2 * math.pi * radius
    local segments = 64
    local segLen = circumference / segments
    
    for i = 1, segments do
        local angle = (i/segments) * math.pi * 2
        local x = math.cos(angle) * (radius)
        local z = math.sin(angle) * (radius)
        local pos = Vector3.new(x, wallHeight/2 - 20, z) 
        
        local wall = createPart("ArenaWall", Vector3.new(thickness, wallHeight, segLen * 1.05), pos, Color3.fromRGB(40,40,40), Enum.Material.Slate, geometryFolder)
        wall.CFrame = CFrame.new(pos) * CFrame.Angles(0, -angle, 0)
    end
    
    return baseFolder, propsFolder, geometryFolder
end

function TerrainGenerator:spawnCornucopia(folder)
    print("[TerrainGenerator] Spawning Cornucopia")
    
    -- REVERTED : Terrain at center is Y=5. Plate height is 2. Center at 6 puts bottom at 5.
    createPart("CornucopiaPlate", Vector3.new(60, 2, 60), Vector3.new(0, 6, 0), COLORS.CORNUCOPIA, Enum.Material.Concrete, folder)
    
    local hornColor = Color3.fromRGB(200, 180, 50)
    for i = 1, 3 do
        local w = Instance.new("WedgePart")
        w.Name = "HornPart"
        w.Size = Vector3.new(4, 25, 6)
        w.Color = hornColor
        w.Material = Enum.Material.Metal
        w.Anchored = true
        w.Parent = folder
        w.CFrame = CFrame.new(0, 17, 0) * CFrame.Angles(0, math.rad(i * 120), math.rad(20)) * CFrame.new(8, 0, 0)
    end
    
    local count = 24
    local radius = 22
    for i = 1, count do
        local angle = (i/count) * math.pi * 2
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        createPart("Pedestal", Vector3.new(3, 1, 3), Vector3.new(x, 7.5, z), Color3.fromRGB(30,30,30), Enum.Material.Metal, folder)
    end
end

function TerrainGenerator:populateBiomes(folder)
    print("[TerrainGenerator] Populating Biomes")
    
    -- Increased count for larger map
    local objectCount = 1500
    
    for _ = 1, objectCount do
        local x = math.random(-self.MAP_SIZE/2 + 20, self.MAP_SIZE/2 - 20)
        local z = math.random(-self.MAP_SIZE/2 + 20, self.MAP_SIZE/2 - 20)
        
        if math.sqrt(x*x + z*z) > 80 then
            local y = self:getNoiseHeight(x, z)
            local biome = self:getBiome(x, z)
            
            -- Only spawn if not in deep water
            if y > self.WATER_LEVEL then
                if biome == "desert" then
                     spawnCactus(Vector3.new(x, y, z), folder)
                     spawnRock(Vector3.new(x+5, y, z+5), folder, "desert")
                else
                     spawnTree(Vector3.new(x, y, z), folder, biome)
                     if math.random() < 0.3 then
                         spawnRock(Vector3.new(x+5, y, z+5), folder, biome)
                     end
                end
            end
        end
    end
end

function TerrainGenerator:generateAllTerrain(biomeZones)
    if biomeZones then
        self.activeZones = biomeZones
    end
    
    self:clearTerrain()
    local baseFolder, propsFolder, geoFolder = self:generateGround()
    self:spawnCornucopia(baseFolder)
    self:populateBiomes(propsFolder)
    print("[TerrainGenerator] Map Generation Complete.")
end

function TerrainGenerator:clearTerrain()
    if Workspace:FindFirstChild("MapGeometry") then Workspace.MapGeometry:Destroy() end
    if Workspace:FindFirstChild("MapBase") then Workspace.MapBase:Destroy() end
    if Workspace:FindFirstChild("MapProps") then Workspace.MapProps:Destroy() end
    if Workspace:FindFirstChild("Baseplate") then Workspace.Baseplate:Destroy() end
    Workspace.Terrain:Clear()
end

function TerrainGenerator.init()
    print("[TerrainGenerator] Initialized Enhanced Generator")
end

return TerrainGenerator
