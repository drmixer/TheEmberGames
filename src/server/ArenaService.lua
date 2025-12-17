-- ServerScript: ArenaService.lua
-- Handles arena setup, Cornucopia loot spawn
-- Manages arena boundaries, hazards, and dynamic environment changes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)
local CraftingRecipes = require(ReplicatedFirst.CraftingRecipes)

local ArenaService = {}
ArenaService.arenaSetupComplete = false
ArenaService.cornucopiaLootSpawned = false
ArenaService.arenaBoundaries = {}
ArenaService.biomeZones = {}
ArenaService.cornucopiaModel = nil -- Store reference to Cornucopia

-- RemoteEvents for client communication
local arenaRemoteEvent = Instance.new("RemoteEvent")
arenaRemoteEvent.Name = "ArenaRemoteEvent"
arenaRemoteEvent.Parent = ReplicatedStorage

-- Define biome zones in the arena
local function setupBiomeZones()
    -- Define the circular arena with different biomes
    ArenaService.biomeZones = {
        -- Central Area
        {
            name = "Cornucopia",
            center = Vector3.new(0, 0, 0),
            radius = 30,
            type = "landmark",
            description = "The center of the arena, with valuable starting supplies"
        },
        
        -- Inner Ring Biomes
        {
            name = "DenseForest_NW",
            center = Vector3.new(-200, 0, -200),
            radius = 100,
            type = "forest",
            description = "Dense forest with cover and resources"
        },
        {
            name = "DenseForest_NE",
            center = Vector3.new(200, 0, -200),
            radius = 100,
            type = "forest", 
            description = "Dense forest with cover and resources"
        },
        {
            name = "OpenMeadow_SW",
            center = Vector3.new(-200, 0, 200),
            radius = 100,
            type = "meadow",
            description = "Open grassland with clear sightlines"
        },
        {
            name = "OpenMeadow_SE", 
            center = Vector3.new(200, 0, 200),
            radius = 100,
            type = "meadow",
            description = "Open grassland with clear sightlines"
        },
        {
            name = "RiverDistrict_S",
            center = Vector3.new(0, 0, 300),
            radius = 120,
            type = "water",
            description = "Winding river with water sources and crossing points"
        },
        
        -- Outer Ring Biomes
        {
            name = "Swamp_NW",
            center = Vector3.new(-350, 0, -350),
            radius = 100,
            type = "swamp",
            description = "Murky swamp with hazards and medicinal plants"
        },
        {
            name = "RockyCliffs_NE",
            center = Vector3.new(350, 0, -350),
            radius = 100,
            type = "cliff",
            description = "High elevation rocky area with strategic positions"
        },
        {
            name = "Desert_Mesa_N",
            center = Vector3.new(0, 0, -400),
            radius = 120,
            type = "desert",
            description = "Arid mesa with harsh conditions and unique resources"
        },
        
        -- Outer Edge Biomes
        {
            name = "MountainRange_W",
            center = Vector3.new(-450, 0, 0),
            radius = 150,
            type = "mountain",
            description = "Snow-covered peaks with harsh weather"
        },
        {
            name = "RollingHills_E",
            center = Vector3.new(450, 0, 0),
            radius = 150,
            type = "hills",
            description = "Gentle slopes with moderate risk/reward"
        }
    }
    
    print("Biome zones defined: " .. #ArenaService.biomeZones)
end

-- Create arena boundaries
local function createArenaBoundaries()
    -- Create invisible walls at the edge of the arena
    local arenaSize = Config.ARENA_SIZE
    local wallHeight = 200
    
    -- North wall
    local northWall = Instance.new("Part")
    northWall.Name = "ArenaBoundary_North"
    northWall.Size = Vector3.new(arenaSize, wallHeight, 20)
    northWall.Position = Vector3.new(0, wallHeight/2, -arenaSize/2 - 10)
    northWall.Anchored = true
    northWall.CanCollide = true
    northWall.Material = Enum.Material.Neon
    northWall.Color = Color3.fromRGB(255, 0, 0) -- Red to indicate danger
    northWall.Transparency = 1 -- Invisible but collidable
    northWall.Parent = Workspace
    
    -- South wall
    local southWall = northWall:Clone()
    southWall.Name = "ArenaBoundary_South"
    southWall.Position = Vector3.new(0, wallHeight/2, arenaSize/2 + 10)
    southWall.Parent = Workspace
    
    -- East wall
    local eastWall = Instance.new("Part")
    eastWall.Name = "ArenaBoundary_East"
    eastWall.Size = Vector3.new(20, wallHeight, arenaSize)
    eastWall.Position = Vector3.new(arenaSize/2 + 10, wallHeight/2, 0)
    eastWall.Anchored = true
    eastWall.CanCollide = true
    eastWall.Material = Enum.Material.Neon
    eastWall.Color = Color3.fromRGB(255, 0, 0)
    eastWall.Transparency = 1
    eastWall.Parent = Workspace
    
    -- West wall
    local westWall = eastWall:Clone()
    westWall.Name = "ArenaBoundary_West"
    westWall.Position = Vector3.new(-arenaSize/2 - 10, wallHeight/2, 0)
    westWall.Parent = Workspace
    
    ArenaService.arenaBoundaries = {northWall, southWall, eastWall, westWall}
    
    print("Arena boundaries created")
end

-- Create ground plane
local function createGroundPlane()
    local ground = Instance.new("Part")
    ground.Name = "ArenaGround"
    ground.Size = Vector3.new(Config.ARENA_SIZE, 1, Config.ARENA_SIZE) -- 1 stud high, but covers full arena
    ground.Position = Vector3.new(0, 0, 0) -- At Y=0, so the top surface is at Y=0.5
    ground.Anchored = true
    ground.CanCollide = true
    ground.Material = Enum.Material.Grass
    ground.Color = Color3.fromRGB(34, 139, 34) -- Forest green
    ground.Parent = Workspace
    
    print("Arena ground created")
end

-- Create Cornucopia landmark
local function createCornucopia()
    -- Create the iconic spiral horn structure
    local cornucopiaBase = Instance.new("Part")
    cornucopiaBase.Name = "Cornucopia"
    cornucopiaBase.Size = Vector3.new(30, 15, 30)
    cornucopiaBase.Position = Vector3.new(0, 7.5, 0) -- Now positioned at Y=7.5 above the ground
    cornucopiaBase.Anchored = true
    cornucopiaBase.CanCollide = true
    cornucopiaBase.Material = Enum.Material.SmoothPlastic
    cornucopiaBase.Color = Color3.fromRGB(210, 180, 140) -- Bronze-like
    cornucopiaBase.Parent = Workspace
    
    -- Add a decorative horn structure
    local horn = Instance.new("WedgePart")
    horn.Size = Vector3.new(10, 20, 20)
    horn.CFrame = cornucopiaBase.CFrame * CFrame.new(0, 15, 0) * CFrame.Angles(0, 0, math.rad(90))
    horn.Anchored = true
    horn.CanCollide = false -- Don't block movement
    horn.Material = Enum.Material.SmoothPlastic
    horn.Color = Color3.fromRGB(210, 180, 140)
    horn.Parent = Workspace
    
    -- Store reference for loot spawning
    ArenaService.cornucopiaModel = cornucopiaBase
    
    print("Cornucopia landmark created")
end

-- Spawn loot at Cornucopia for match start
function ArenaService:spawnCornucopiaLoot()
    if ArenaService.cornucopiaLootSpawned then
        return
    end
    
    -- High-tier weapons, armor, and survival supplies
    local cornucopiaLoot = {
        -- Weapons
        {name = "Sword", positionOffset = Vector3.new(-8, 2, -8), rarity = "high"},
        {name = "Bow", positionOffset = Vector3.new(-5, 2, -8), rarity = "high"},
        {name = "Spear", positionOffset = Vector3.new(-2, 2, -8), rarity = "medium"},
        {name = "Knife", positionOffset = Vector3.new(1, 2, -8), rarity = "medium"},
        {name = "Axe", positionOffset = Vector3.new(4, 2, -8), rarity = "medium"},
        {name = "Machete", positionOffset = Vector3.new(7, 2, -8), rarity = "high"},
        
        -- Survival supplies
        {name = "Medkit", positionOffset = Vector3.new(-8, 2, -5), rarity = "high"},
        {name = "Water Bottle", positionOffset = Vector3.new(-5, 2, -5), rarity = "medium"},
        {name = "Food Rations", positionOffset = Vector3.new(-2, 2, -5), rarity = "medium"},
        {name = "Camping Kit", positionOffset = Vector3.new(1, 2, -5), rarity = "medium"},
        {name = "First Aid Kit", positionOffset = Vector3.new(4, 2, -5), rarity = "high"},
        {name = "Cooking Kit", positionOffset = Vector3.new(7, 2, -5), rarity = "medium"},
        
        -- Crafting materials
        {name = "Wood Bundle", positionOffset = Vector3.new(-8, 2, -2), rarity = "low"},
        {name = "Stone Set", positionOffset = Vector3.new(-5, 2, -2), rarity = "low"},
        {name = "Vine Reel", positionOffset = Vector3.new(-2, 2, -2), rarity = "low"},
        {name = "Metal Scraps", positionOffset = Vector3.new(1, 2, -2), rarity = "medium"},
        {name = "Leather Pieces", positionOffset = Vector3.new(4, 2, -2), rarity = "medium"},
        {name = "Advanced Materials", positionOffset = Vector3.new(7, 2, -2), rarity = "high"},
        
        -- Special items
        {name = "Compass", positionOffset = Vector3.new(-8, 2, 1), rarity = "medium"},
        {name = "Night Vision Goggles", positionOffset = Vector3.new(-5, 2, 1), rarity = "high"},
        {name = "Multi-tool", positionOffset = Vector3.new(-2, 2, 1), rarity = "medium"},
        {name = "Emergency Beacon", positionOffset = Vector3.new(1, 2, 1), rarity = "high"},
        {name = "Rope Ladder", positionOffset = Vector3.new(4, 2, 1), rarity = "medium"},
        {name = "Water Purifier", positionOffset = Vector3.new(7, 2, 1), rarity = "high"}
    }
    
    for _, lootItem in ipairs(cornucopiaLoot) do
        local lootPart = Instance.new("Part")
        lootPart.Name = "Loot_" .. lootItem.name
        lootPart.Size = Vector3.new(3, 1, 3)
        lootPart.Position = Vector3.new(0, 0, 0) + lootItem.positionOffset
        lootPart.Anchored = true
        lootPart.CanCollide = false -- Don't impede movement
        lootPart.Material = Enum.Material.Neon
        
        -- Color based on rarity
        if lootItem.rarity == "high" then
            lootPart.Color = Color3.fromRGB(255, 215, 0) -- Gold
        elseif lootItem.rarity == "medium" then
            lootPart.Color = Color3.fromRGB(192, 192, 192) -- Silver
        else
            lootPart.Color = Color3.fromRGB(255, 255, 255) -- White
        end
        
        lootPart.Parent = Workspace
        
        -- Add special visual effect for special items
        if lootItem.rarity == "high" then
            local sparkles = Instance.new("Sparkles")
            sparkles.Parent = lootPart
        end
        
        -- Add a label for the item type
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Size = UDim2.new(0, 10, 0, 3)
        billboardGui.Adornee = lootPart
        billboardGui.Parent = lootPart
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Text = lootItem.name
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = true
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.Parent = billboardGui
    end
    
    ArenaService.cornucopiaLootSpawned = true
    print("Cornucopia loot spawned")
    
    -- Notify clients
    arenaRemoteEvent:FireAllClients("CORNUCOPIA_LOOT_SPAWNED")
end

-- Spawn random loot in biomes
function ArenaService:spawnBiomeLoot()
    -- Spawn lower-tier loot and crafting materials in biomes
    for _, biome in ipairs(ArenaService.biomeZones) do
        if biome.type ~= "landmark" then -- Don't spawn random loot in Cornucopia
            -- Calculate number of loot spawns based on biome size
            local lootCount = math.random(5, 15)
            
            for i = 1, lootCount do
                local angle = math.random() * 2 * math.pi
                local distance = math.random(5, biome.radius * 0.7) -- Don't place too close to edge
                local position = biome.center + Vector3.new(
                    math.cos(angle) * distance,
                    2, -- Height above ground
                    math.sin(angle) * distance
                )
                
                -- Determine loot type based on biome
                local lootType = ""
                local rarity = "low"
                
                if biome.type == "forest" then
                    local lootTypes = {"Wood", "Edible Berries", "Medicinal Herbs", "Vines"}
                    lootType = lootTypes[math.random(1, #lootTypes)]
                elseif biome.type == "meadow" then
                    local lootTypes = {"Wild Vegetables", "Grains", "Edible Plants", "Clean Water"}
                    lootType = lootTypes[math.random(1, #lootTypes)]
                elseif biome.type == "water" then
                    lootType = "Fresh Water Source"
                    rarity = "medium" -- Water is important for survival
                elseif biome.type == "swamp" then
                    local lootTypes = {"Poison Plants", "Medicinal Herbs", "Toxic Berries", "Mud Samples"}
                    lootType = lootTypes[math.random(1, #lootTypes)]
                elseif biome.type == "cliff" then
                    local lootTypes = {"Stone", "Ore", "Rock Samples", "Cave Materials"}
                    lootType = lootTypes[math.random(1, #lootTypes)]
                elseif biome.type == "desert" then
                    local lootTypes = {"Cactus Fruit", "Special Stone", "Heat Protection", "Desert Herbs"}
                    lootType = lootTypes[math.random(1, #lootTypes)]
                elseif biome.type == "mountain" then
                    local lootTypes = {"Insulation Materials", "Cold-Weather Gear", "Mountain Herbs", "Special Stone"}
                    lootType = lootTypes[math.random(1, #lootTypes)]
                elseif biome.type == "hills" then
                    local lootTypes = {"Mixed Resources", "Herbs", "Stones", "Plants"}
                    lootType = lootTypes[math.random(1, #lootTypes)]
                end
                
                -- Create loot part
                local lootPart = Instance.new("Part")
                lootPart.Name = "Loot_" .. lootType
                lootPart.Size = Vector3.new(2, 0.5, 2)
                lootPart.Position = position
                lootPart.Anchored = true
                lootPart.CanCollide = false
                lootPart.Material = Enum.Material.Neon
                
                if rarity == "high" then
                    lootPart.Color = Color3.fromRGB(255, 215, 0) -- Gold
                elseif rarity == "medium" then
                    lootPart.Color = Color3.fromRGB(192, 192, 192) -- Silver
                else
                    lootPart.Color = Color3.fromRGB(255, 255, 255) -- White
                end
                
                lootPart.Parent = Workspace
            end
        end
    end
    
    print("Biome loot spawned")
end

-- Initialize arena for match
function ArenaService:initializeMatch()
    if ArenaService.arenaSetupComplete then
        return
    end
    
    -- Reset loot status
    ArenaService.cornucopiaLootSpawned = false
    
    -- Spawn Cornucopia loot
    ArenaService:spawnCornucopiaLoot()
    
    -- Spawn biome loot
    ArenaService:spawnBiomeLoot()
    
    print("Arena initialized for match")
    
    -- Notify clients
    arenaRemoteEvent:FireAllClients("ARENA_INITIALIZED")
end

-- Initialize arena service
function ArenaService.init()
    print("[ArenaService] Initializing...")
    
    -- Set up biome zones
    setupBiomeZones()
    
    -- Create ground plane first
    createGroundPlane()
    
    -- Create arena boundaries
    createArenaBoundaries()
    
    -- Create Cornucopia landmark
    createCornucopia()
    
    -- Generate terrain decorations for all biomes
    local success, TerrainGenerator = pcall(function()
        return require(script.Parent.TerrainGenerator)
    end)
    
    if success and TerrainGenerator then
        TerrainGenerator.init()
        TerrainGenerator:generateAllTerrain(ArenaService.biomeZones)
    else
        warn("[ArenaService] TerrainGenerator not available - using basic arena")
    end
    
    ArenaService.arenaSetupComplete = true
    
    print("[ArenaService] Arena setup complete")
    
    -- Handle remote events from other services
    arenaRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        -- Handle client requests if needed
    end)
end

return ArenaService
