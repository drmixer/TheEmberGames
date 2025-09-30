-- ServerScript: DevelopmentArenaService.lua
-- Development version of ArenaService that creates visible arena elements for testing

local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.shared.Config)

-- Create visual arena boundaries for development/testing
local function createVisibleArenaBoundaries()
    local arenaSize = Config.ARENA_SIZE
    local wallHeight = 200
    
    -- Create ground platform at center
    local ground = Instance.new("Part")
    ground.Name = "ArenaGround"
    ground.Size = Vector3.new(arenaSize, 1, arenaSize)
    ground.Position = Vector3.new(0, 0, 0)
    ground.Anchored = true
    ground.CanCollide = true
    ground.Material = Enum.Material.Grass
    ground.Color = Color3.fromRGB(34, 139, 34) -- Green
    ground.Parent = Workspace
    
    -- Create visible walls at the edge of the arena
    -- North wall
    local northWall = Instance.new("Part")
    northWall.Name = "ArenaBoundary_North"
    northWall.Size = Vector3.new(arenaSize, wallHeight, 5)
    northWall.Position = Vector3.new(0, wallHeight/2, -arenaSize/2 - 2.5)
    northWall.Anchored = true
    northWall.CanCollide = true
    northWall.Material = Enum.Material.Brick
    northWall.Color = Color3.fromRGB(139, 69, 19) -- Brown
    northWall.Parent = Workspace
    
    -- South wall
    local southWall = northWall:Clone()
    southWall.Name = "ArenaBoundary_South"
    southWall.Position = Vector3.new(0, wallHeight/2, arenaSize/2 + 2.5)
    southWall.Parent = Workspace
    
    -- East wall
    local eastWall = Instance.new("Part")
    eastWall.Name = "ArenaBoundary_East"
    eastWall.Size = Vector3.new(5, wallHeight, arenaSize)
    eastWall.Position = Vector3.new(arenaSize/2 + 2.5, wallHeight/2, 0)
    eastWall.Anchored = true
    eastWall.CanCollide = true
    eastWall.Material = Enum.Material.Brick
    eastWall.Color = Color3.fromRGB(139, 69, 19)
    eastWall.Parent = Workspace
    
    -- West wall
    local westWall = eastWall:Clone()
    westWall.Name = "ArenaBoundary_West"
    westWall.Position = Vector3.new(-arenaSize/2 - 2.5, wallHeight/2, 0)
    westWall.Parent = Workspace
    
    print("Development Arena boundaries created - visible in editor")
end

-- Create visible Cornucopia landmark
local function createVisibleCornucopia()
    -- Create the iconic spiral horn structure
    local cornucopiaBase = Instance.new("Part")
    cornucopiaBase.Name = "Cornucopia"
    cornucopiaBase.Size = Vector3.new(30, 15, 30)
    cornucopiaBase.Position = Vector3.new(0, 7.5, 0)
    cornucopiaBase.Anchored = true
    cornucopiaBase.CanCollide = true
    cornucopiaBase.Material = Enum.Material.Brick
    cornucopiaBase.Color = Color3.fromRGB(210, 180, 140) -- Bronze-like
    cornucopiaBase.Parent = Workspace
    
    -- Add a decorative horn structure
    local horn = Instance.new("WedgePart")
    horn.Name = "CornucopiaHorn"
    horn.Size = Vector3.new(10, 20, 20)
    horn.CFrame = cornucopiaBase.CFrame * CFrame.new(0, 15, 0) * CFrame.Angles(0, 0, math.rad(90))
    horn.Anchored = true
    horn.CanCollide = true -- Make collidable for dev testing
    horn.Material = Enum.Material.Brick
    horn.Color = Color3.fromRGB(210, 180, 140)
    horn.Parent = Workspace
    
    print("Development Cornucopia landmark created - visible in editor")
end

-- Create some visual biomes for development
local function createVisibleBiomes()
    -- Create a few visual markers for different biomes
    local biomeMarkers = {
        {name = "Forest_NE", pos = Vector3.new(200, 5, -200), color = Color3.fromRGB(0, 100, 0), size = Vector3.new(100, 1, 100)},
        {name = "Forest_NW", pos = Vector3.new(-200, 5, -200), color = Color3.fromRGB(0, 100, 0), size = Vector3.new(100, 1, 100)},
        {name = "Meadow_SE", pos = Vector3.new(200, 5, 200), color = Color3.fromRGB(144, 238, 144), size = Vector3.new(100, 1, 100)},
        {name = "Meadow_SW", pos = Vector3.new(-200, 5, 200), color = Color3.fromRGB(144, 238, 144), size = Vector3.new(100, 1, 100)},
        {name = "River_S", pos = Vector3.new(0, 5, 300), color = Color3.fromRGB(30, 144, 255), size = Vector3.new(120, 1, 120)},
    }
    
    for _, marker in ipairs(biomeMarkers) do
        local part = Instance.new("Part")
        part.Name = "Biome_" .. marker.name
        part.Size = marker.size
        part.Position = marker.pos
        part.Anchored = true
        part.CanCollide = false -- Don't impede movement
        part.Material = Enum.Material.Neon
        part.Color = marker.color
        part.Transparency = 0.7 -- Semi-transparent
        part.Parent = Workspace
        
        print("Created biome marker: " .. marker.name)
    end
end

-- Initialize development arena
print("DevelopmentArenaService: Creating visible arena elements...")
createVisibleArenaBoundaries()
createVisibleCornucopia()
createVisibleBiomes()
print("DevelopmentArenaService: Arena created successfully for testing")