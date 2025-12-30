-- ModuleScript: WeaponSystem.lua (Server)
-- Complete weapon system for The Ember Games
-- Handles weapon creation, equipping, attacking with proper hitbox detection

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local WeaponSystem = {}
WeaponSystem.equippedWeapons = {} -- player -> weapon instance
WeaponSystem.weaponCooldowns = {} -- player -> last attack time

-- Create remote event for weapon communication
local weaponSystemRemote = Instance.new("RemoteEvent")
weaponSystemRemote.Name = "WeaponSystemRemote"
weaponSystemRemote.Parent = ReplicatedStorage

-- ============ WEAPON DEFINITIONS ============

local WEAPONS = {
    -- MELEE WEAPONS
    ["WoodenStick"] = {
        type = "melee",
        displayName = "Wooden Stick",
        damage = 8,
        attackSpeed = 0.6, 
        range = 5,
        durability = 20,
        rarity = "common",
        description = "A basic wooden stick. Fast but weak.",
        model = {
            -- Blocky fallback is reliable
            handleSize = Vector3.new(0.2, 3.5, 0.2), 
            handleColor = Color3.fromRGB(139, 90, 43),
            handleMaterial = Enum.Material.Wood,
            bladeSize = Vector3.new(0.1, 0.5, 0.1), -- Tiny nub for detail
            bladeColor = Color3.fromRGB(100, 60, 30),
            bladeOffset = Vector3.new(0.1, 1, 0)
        }
    },
    
    ["SharpStick"] = {
        type = "melee",
        displayName = "Sharp Stick",
        damage = 15,
        attackSpeed = 0.8,
        range = 6,
        durability = 15,
        rarity = "common",
        description = "A sharpened stick. Longer reach.",
        statusEffect = "BLEEDING",
        statusChance = 0.10,
        statusDuration = 5,
        model = {
            meshId = "rbxassetid://121944778", -- Classic Dagger Mesh (Reliable)
            scale = Vector3.new(0.7, 3.0, 0.7), -- Stretched to look like a spear
            textureId = "rbxassetid://121944805", -- Classic Texture
            handleSize = Vector3.new(0.3, 5, 0.3),
            handleColor = Color3.fromRGB(120, 80, 40),
            handleMaterial = Enum.Material.Wood
        }
    },
    
    ["StoneKnife"] = {
        type = "melee",
        displayName = "Stone Knife",
        damage = 12,
        attackSpeed = 0.5,
        range = 4,
        durability = 25,
        rarity = "common",
        description = "A crude stone knife. Fast with bleeding chance.",
        statusEffect = "BLEEDING",
        statusChance = 0.15,
        statusDuration = 5,
        model = {
            meshId = "rbxassetid://121944778", -- Classic Dagger Mesh
            scale = Vector3.new(1, 1, 1),
            textureId = "rbxassetid://121944805",
            handleSize = Vector3.new(0.5, 2, 0.5),
            handleColor = Color3.fromRGB(100, 100, 100),
            handleMaterial = Enum.Material.Slate,
            rotation = Vector3.new(0, -90, 0) -- Orient correctly
        }
    },
    
    ["HandmadeAxe"] = {
        type = "melee",
        displayName = "Handmade Axe",
        damage = 35,
        attackSpeed = 1.2,
        range = 5,
        durability = 12,
        rarity = "uncommon",
        description = "A heavy axe. Slow but powerful.",
        model = {
            handleSize = Vector3.new(0.3, 3.5, 0.3),
            handleColor = Color3.fromRGB(120, 80, 40),
            handleMaterial = Enum.Material.Wood,
            bladeSize = Vector3.new(0.3, 1.5, 1.2),
            bladeColor = Color3.fromRGB(80, 80, 80),
            bladeMaterial = Enum.Material.Slate,
            bladeOffset = Vector3.new(0.5, 1.5, 0)
        }
    },
    
    ["Machete"] = {
        type = "melee",
        displayName = "Machete",
        damage = 40,
        attackSpeed = 0.9,
        range = 5.5,
        durability = 8,
        rarity = "rare",
        description = "A deadly machete. High damage, breaks quickly.",
        statusEffect = "BLEEDING",
        statusChance = 0.25,
        statusDuration = 8,
        model = {
            handleSize = Vector3.new(0.25, 1.5, 0.25),
            handleColor = Color3.fromRGB(50, 40, 30),
            handleMaterial = Enum.Material.Wood,
            bladeSize = Vector3.new(0.1, 2.5, 0.5),
            bladeColor = Color3.fromRGB(150, 150, 160),
            bladeMaterial = Enum.Material.Metal
        }
    },

    -- BIOME WEAPONS (New)
    ["IceSword"] = {
        type = "melee",
        displayName = "Glacial Blade",
        damage = 32,
        attackSpeed = 0.7, -- Fast
        range = 5,
        durability = 30,
        rarity = "rare",
        description = "A sword forged from permafrost. Chills enemies.",
        statusEffect = "SLOW",
        statusChance = 0.3,
        statusDuration = 3,
        model = {
            handleSize = Vector3.new(0.25, 1.2, 0.25),
            handleColor = Color3.fromRGB(50, 50, 80),
            handleMaterial = Enum.Material.Wood,
            bladeSize = Vector3.new(0.15, 3.5, 0.4),
            bladeColor = Color3.fromRGB(180, 230, 255),
            bladeMaterial = Enum.Material.Ice
        }
    },

    ["BambooSpear"] = {
        type = "melee",
        displayName = "Bamboo Spear",
        damage = 22,
        attackSpeed = 0.5, -- Very fast
        range = 7.5, -- Long reach
        durability = 25,
        rarity = "uncommon",
        description = "A lightweight, long-reaching spear from the jungle.",
        model = {
            handleSize = Vector3.new(0.2, 7, 0.2), -- Long
            handleColor = Color3.fromRGB(100, 180, 80),
            handleMaterial = Enum.Material.Wood,
            tipSize = Vector3.new(0.15, 0.8, 0.15),
            tipColor = Color3.fromRGB(50, 120, 40)
        }
    },

    ["ObsidianAxe"] = {
        type = "melee",
        displayName = "Volcanic Axe",
        damage = 45, -- High damage
        attackSpeed = 1.4, -- Slow
        range = 5,
        durability = 40,
        rarity = "epic",
        description = "Heavy axe forged from volcanic glass.",
        model = {
            handleSize = Vector3.new(0.35, 4, 0.35),
            handleColor = Color3.fromRGB(40, 40, 40),
            handleMaterial = Enum.Material.Rock,
            bladeSize = Vector3.new(0.4, 2, 1.5),
            bladeColor = Color3.fromRGB(20, 10, 10),
            bladeMaterial = Enum.Material.Slate,
            bladeOffset = Vector3.new(0.5, 1.8, 0)
        }
    },
    
    -- RANGED WEAPONS
    ["Slingshot"] = {
        type = "ranged",
        displayName = "Slingshot",
        damage = 15,
        attackSpeed = 1.0,
        range = 50,
        projectileSpeed = 100,
        durability = 30,
        rarity = "common",
        description = "A simple slingshot. Long range, low damage.",
        ammoType = "SlingshotAmmo",
        ammoPerShot = 1,
        model = {
            -- Blocky fallback
            handleSize = Vector3.new(0.3, 1.5, 0.3),
            handleColor = Color3.fromRGB(139, 90, 43),
            handleMaterial = Enum.Material.Wood
        }
    },
    
    ["Bow"] = {
        type = "ranged",
        displayName = "Bow",
        damage = 30,
        attackSpeed = 1.5,
        range = 80,
        projectileSpeed = 120,
        durability = 20,
        rarity = "uncommon",
        description = "A hunting bow. High damage with arrow arc.",
        ammoType = "Arrow",
        ammoPerShot = 1,
        chargeTime = 0.5, -- seconds to fully charge
        statusEffect = "BLEEDING",
        statusChance = 0.20,
        statusDuration = 6,
        model = {
            meshId = "rbxassetid://471832062", -- Classic Bow Mesh
            scale = Vector3.new(2, 2, 2),
            bowSize = Vector3.new(0.15, 4, 0.5),
            bowColor = Color3.fromRGB(100, 70, 40),
            bowMaterial = Enum.Material.Wood
        }
    },
    
    ["ThrowingKnife"] = {
        type = "thrown",
        displayName = "Throwing Knife",
        damage = 25,
        attackSpeed = 0.4,
        range = 40,
        projectileSpeed = 150,
        durability = 1, -- Single use
        rarity = "uncommon",
        stackSize = 5,
        description = "A balanced throwing knife. Fast and accurate.",
        ammoType = "ThrowingKnife",
        model = {
            meshId = "rbxassetid://121944778", -- Classic Dagger
            scale = Vector3.new(0.6, 0.6, 0.6),
            textureId = "rbxassetid://121944805",
            bladeSize = Vector3.new(0.1, 2, 0.3),
            bladeColor = Color3.fromRGB(150, 150, 160),
            bladeMaterial = Enum.Material.Metal
        }
    },
    
    -- TRAPS
    ["FireTrap"] = {
        type = "trap",
        displayName = "Fire Trap",
        damage = 30,
        damageType = "fire",
        duration = 5,
        radius = 8,
        rarity = "uncommon",
        description = "Explodes in flames when triggered.",
        model = {
            baseSize = Vector3.new(2, 0.5, 2),
            baseColor = Color3.fromRGB(80, 40, 20),
            baseMaterial = Enum.Material.Wood
        }
    },
    
    ["TripwireTrap"] = {
        type = "trap",
        displayName = "Tripwire Trap",
        damage = 10,
        statusEffect = "IMMOBILIZE",
        statusDuration = 3,
        rarity = "common",
        description = "Immobilizes players who trigger it.",
        model = {
            wireLength = 10,
            wireColor = Color3.fromRGB(139, 90, 43)
        }
    },
    
    ["PoisonBerry"] = {
        type = "bait",
        displayName = "Poison Berry",
        damage = 40,
        statusEffect = "POISON",
        statusDuration = 10,
        rarity = "uncommon",
        description = "Looks edible but causes severe poisoning.",
        model = {
            berrySize = Vector3.new(0.3, 0.3, 0.3),
            berryColor = Color3.fromRGB(100, 0, 150)
        }
    }
}

-- ============ WEAPON MODEL CREATION ============

local function getWeaponColor(weaponId)
    if string.find(weaponId, "Stone") then return Enum.Material.Slate, Color3.fromRGB(100, 100, 100) end
    if string.find(weaponId, "Iron") or string.find(weaponId, "Machete") then return Enum.Material.Metal, Color3.fromRGB(150, 150, 160) end
    if string.find(weaponId, "Ice") then return Enum.Material.Ice, Color3.fromRGB(180, 230, 255) end
    if string.find(weaponId, "Obsidian") then return Enum.Material.Rock, Color3.fromRGB(20, 10, 10) end
    return Enum.Material.Wood, Color3.fromRGB(139, 90, 43) -- Default Wood
end

local function createMeleeWeaponModel(weaponId, weaponDef)
    local weapon = Instance.new("Tool")
    weapon.Name = weaponId
    weapon.RequiresHandle = true
    weapon.CanBeDropped = true
    
    local material, mainColor = getWeaponColor(weaponId)
    
    -- 1. HANDLE (Base)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Material = Enum.Material.Wood -- Handles are usually wood
    handle.Color = Color3.fromRGB(120, 90, 50)
    handle.Size = Vector3.new(0.3, 1, 0.3)
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = weapon
    
    -- 2. PROCEDURAL BLADE/HEAD CONSTRUCTION
    if weaponId == "WoodenStick" then
        handle.Size = Vector3.new(0.25, 3.8, 0.25)
        handle.Material = Enum.Material.Wood
        handle.Shape = Enum.PartType.Cylinder
        handle.CFrame = handle.CFrame * CFrame.Angles(0, 0, math.rad(90))
        
        -- Make it look like a natural branch
        local mainBranch = Instance.new("Part")
        mainBranch.Size = Vector3.new(0.15, 1.2, 0.15) 
        mainBranch.Color = handle.Color
        mainBranch.Material = handle.Material
        mainBranch.CanCollide = false
        mainBranch.Parent = weapon
        local w1 = Instance.new("Weld", mainBranch)
        w1.Part0 = handle
        w1.Part1 = mainBranch
        w1.C0 = CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(35))
        
        local smallBranch = Instance.new("Part")
        smallBranch.Size = Vector3.new(0.1, 0.6, 0.1)
        smallBranch.Color = handle.Color
        smallBranch.Material = handle.Material
        smallBranch.CanCollide = false
        smallBranch.Parent = weapon
        local w2 = Instance.new("Weld", smallBranch)
        w2.Part0 = handle
        w2.Part1 = smallBranch
        w2.C0 = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, math.rad(90), math.rad(-25))
        
    elseif weaponId == "SharpStick" or weaponId == "BambooSpear" then
        handle.Size = Vector3.new(0.3, 6, 0.3) -- Long shaft
        handle.Shape = Enum.PartType.Cylinder
        
        -- Tip
        local tip = Instance.new("Part")
        tip.Size = Vector3.new(0.4, 1.5, 0.4)
        tip.Color = Color3.fromRGB(200, 200, 200)
        tip.Material = Enum.Material.Metal
        tip.CanCollide = false
        tip.Parent = weapon
        
        -- Make tip cone-ish using SpecialMesh
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://1033714" -- Classic Cone Mesh (Native to Roblox)
        mesh.Scale = Vector3.new(0.3, 1.5, 0.3)
        mesh.Parent = tip
        
        local w = Instance.new("Weld", tip)
        w.Part0 = handle
        w.Part1 = tip
        w.C0 = CFrame.new(0, 3, 0) 
        
    elseif weaponId == "StoneKnife" or weaponId == "Machete" or weaponId == "IceSword" then
        handle.Size = Vector3.new(0.3, 1.2, 0.3)
        
        local blade = Instance.new("Part")
        blade.Size = Vector3.new(0.1, 2.5, 0.5)
        blade.Color = mainColor
        blade.Material = material
        blade.CanCollide = false
        blade.Parent = weapon
        
        -- Bevel blade with wedge if needed, or just block for reliability
        local w = Instance.new("Weld", blade)
        w.Part0 = handle
        w.Part1 = blade
        w.C0 = CFrame.new(0, 1.8, 0)
        
    elseif weaponId == "HandmadeAxe" or weaponId == "ObsidianAxe" then
        handle.Size = Vector3.new(0.3, 3.5, 0.3)
        
        local head = Instance.new("Part")
        head.Size = Vector3.new(1.5, 0.8, 0.5)
        head.Color = mainColor
        head.Material = material
        head.CanCollide = false
        head.Parent = weapon
        
        local w = Instance.new("Weld", head)
        w.Part0 = handle
        w.Part1 = head
        w.C0 = CFrame.new(0, 1.5, 0)
        
        local edge = Instance.new("Part")
        edge.Size = Vector3.new(0.2, 1, 0.5)
        edge.Color = Color3.new(0.8, 0.8, 0.8) -- Sharpened edge
        edge.Parent = weapon
        local w2 = Instance.new("Weld", edge)
        w2.Part0 = head
        w2.Part1 = edge
        w2.C0 = CFrame.new(0.8, 0, 0)
    end
    
    -- Fix Grip (Hold at bottom of handle)
    local gripY = -handle.Size.Y/2 + 0.5
    weapon.Grip = CFrame.new(0, gripY, 0)
    
    -- Physics Cleanup
    for _, part in pairs(weapon:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Massless = true
            part.CanCollide = false
            part.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
        end
    end
    
    -- Attributes
    weapon:SetAttribute("WeaponId", weaponId)
    weapon:SetAttribute("Type", weaponDef.type)
    weapon:SetAttribute("Damage", weaponDef.damage)
    weapon:SetAttribute("Range", weaponDef.range)
    weapon:SetAttribute("AttackSpeed", weaponDef.attackSpeed)
    
    return weapon
end

local function createRangedWeaponModel(weaponId, weaponDef)
    local weapon = Instance.new("Tool")
    weapon.Name = weaponId
    weapon.RequiresHandle = true
    weapon.CanBeDropped = true
    
    if weaponId == "Slingshot" then
        -- SLINGSHOT CONSTRUCTION
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.4, 1.5, 0.4)
        handle.Material = Enum.Material.Wood
        handle.Color = Color3.fromRGB(139, 90, 43)
        handle.CanCollide = false
        handle.Massless = true
        handle.Parent = weapon
        
        -- Y-Shape Forks
        local leftFork = Instance.new("Part")
        leftFork.Size = Vector3.new(0.2, 0.8, 0.2)
        leftFork.Color = handle.Color
        leftFork.Material = handle.Material
        leftFork.CanCollide = false
        leftFork.Parent = weapon
        local w1 = Instance.new("Weld", leftFork)
        w1.Part0 = handle
        w1.Part1 = leftFork
        w1.C0 = CFrame.new(-0.3, 0.8, 0) * CFrame.Angles(0, 0, math.rad(30))
        
        local rightFork = Instance.new("Part")
        rightFork.Size = Vector3.new(0.2, 0.8, 0.2)
        rightFork.Color = handle.Color
        rightFork.Material = handle.Material
        rightFork.CanCollide = false
        rightFork.Parent = weapon
        local w2 = Instance.new("Weld", rightFork)
        w2.Part0 = handle
        w2.Part1 = rightFork
        w2.C0 = CFrame.new(0.3, 0.8, 0) * CFrame.Angles(0, 0, math.rad(-30))
        
        -- Rubber Band
        local band = Instance.new("Part")
        band.Size = Vector3.new(0.8, 0.1, 0.1)
        band.Color = Color3.fromRGB(50, 50, 50)
        band.Material = Enum.Material.Fabric
        band.CanCollide = false
        band.Parent = weapon
        local w3 = Instance.new("Weld", band)
        w3.Part0 = handle
        w3.Part1 = band
        w3.C0 = CFrame.new(0, 1.2, 0)
        
        -- Grip adjustment
        weapon.Grip = CFrame.new(0, -0.5, 0)
        
    else
        -- BOW CONSTRUCTION (Default)
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.3, 1.5, 0.3)
        handle.Material = Enum.Material.Wood
        handle.Color = Color3.fromRGB(100, 60, 20)
        handle.CanCollide = false
        handle.Massless = true
        handle.Parent = weapon
        
        -- Top Limb
        local topLimb = Instance.new("Part")
        topLimb.Size = Vector3.new(0.2, 2, 0.2)
        topLimb.Color = handle.Color
        topLimb.Material = handle.Material
        topLimb.CanCollide = false
        topLimb.Parent = weapon
        local w1 = Instance.new("Weld", topLimb)
        w1.Part0 = handle
        w1.Part1 = topLimb
        w1.C0 = CFrame.new(0, 1.5, 0.5) * CFrame.Angles(math.rad(20), 0, 0)
        
        -- Bottom Limb
        local botLimb = Instance.new("Part")
        botLimb.Size = Vector3.new(0.2, 2, 0.2)
        botLimb.Color = handle.Color
        botLimb.Material = handle.Material
        botLimb.CanCollide = false
        botLimb.Parent = weapon
        local w2 = Instance.new("Weld", botLimb)
        w2.Part0 = handle
        w2.Part1 = botLimb
        w2.C0 = CFrame.new(0, -1.5, 0.5) * CFrame.Angles(math.rad(-20), 0, 0)
        
        -- String
        local bowString = Instance.new("Part")
        bowString.Size = Vector3.new(0.05, 4.5, 0.05)
        bowString.Color = Color3.new(1,1,1)
        bowString.Material = Enum.Material.Fabric
        bowString.CanCollide = false
        bowString.Parent = weapon
        local w3 = Instance.new("Weld", bowString)
        w3.Part0 = handle
        w3.Part1 = bowString
        w3.C0 = CFrame.new(0, 0, 1.2)
        
        -- Bow Grip Adjustment (Rotated to face forward)
        weapon.Grip = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-90), 0)
    end
    
    -- Attributes
    weapon:SetAttribute("WeaponId", weaponId)
    weapon:SetAttribute("Type", weaponDef.type)
    weapon:SetAttribute("Damage", weaponDef.damage)
    weapon:SetAttribute("ProjectileSpeed", weaponDef.projectileSpeed)
    weapon:SetAttribute("AmmoType", weaponDef.ammoType)
    if weaponDef.chargeTime then weapon:SetAttribute("ChargeTime", weaponDef.chargeTime) end

    -- Physics Cleanup
    for _, part in pairs(weapon:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Massless = true
            part.CanCollide = false
            part.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
        end
    end

    return weapon
end

local function createThrownWeaponModel(weaponId, weaponDef)
    -- Just reuse Melee Knife model but smaller
    local weapon = createMeleeWeaponModel("StoneKnife", weaponDef)
    weapon.Name = weaponId
    
    local h = weapon:FindFirstChild("Handle")
    if h then
        h.Size = h.Size * 0.6 -- Smaller
    end
    
    -- Attributes (CRITICAL: Must set ALL ranged attributes or projectile fails)
    weapon:SetAttribute("WeaponId", weaponId)
    weapon:SetAttribute("Type", "thrown") -- Override melee type from base model
    weapon:SetAttribute("Damage", weaponDef.damage)
    weapon:SetAttribute("Range", weaponDef.range)
    weapon:SetAttribute("ProjectileSpeed", weaponDef.projectileSpeed)
    weapon:SetAttribute("AmmoType", weaponDef.ammoType)
    if weaponDef.chargeTime then weapon:SetAttribute("ChargeTime", weaponDef.chargeTime) end
    
    return weapon
end

-- ============ WEAPON CREATION ENTRY POINT ============

function WeaponSystem:createWeapon(weaponId)
    local weaponDef = WEAPONS[weaponId]
    if not weaponDef then
        warn("[WeaponSystem] Unknown weapon: " .. tostring(weaponId))
        return nil
    end
    
    local weapon
    
    if weaponDef.type == "melee" then
        weapon = createMeleeWeaponModel(weaponId, weaponDef)
    elseif weaponDef.type == "ranged" then
        weapon = createRangedWeaponModel(weaponId, weaponDef)
    elseif weaponDef.type == "thrown" then
        weapon = createThrownWeaponModel(weaponId, weaponDef)
    else
        -- Fallback
        weapon = createMeleeWeaponModel(weaponId, weaponDef)
        weapon:SetAttribute("Type", weaponDef.type)
    end
    
    return weapon
end

-- Give a weapon to a player
function WeaponSystem:giveWeapon(player, weaponId)
    local weapon = WeaponSystem:createWeapon(weaponId)
    if not weapon then return nil end
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        weapon.Parent = backpack
        print("[WeaponSystem] Gave " .. weaponId .. " to " .. player.Name)
        
        -- Notify client
        weaponSystemRemote:FireClient(player, "WEAPON_RECEIVED", weaponId, WEAPONS[weaponId])
    end
    
    return weapon
end

-- ============ ATTACK HANDLING ============

function WeaponSystem:canAttack(player)
    local lastAttack = WeaponSystem.weaponCooldowns[player] or 0
    local character = player.Character
    
    if not character then return false end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return false end
    
    local attackSpeed = equippedTool:GetAttribute("AttackSpeed") or 1
    local now = tick()
    
    if now - lastAttack < attackSpeed then
        return false
    end
    
    return true
end

-- Process melee attack with proper raycasting
function WeaponSystem:processMeleeAttack(player, direction)
    if not WeaponSystem:canAttack(player) then return end
    
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    local range = equippedTool:GetAttribute("Range") or 5
    local damage = equippedTool:GetAttribute("Damage") or 10
    local weaponId = equippedTool:GetAttribute("WeaponId")
    
    -- Update cooldown
    WeaponSystem.weaponCooldowns[player] = tick()
    
    -- Send swing animation to all clients
    weaponSystemRemote:FireAllClients("WEAPON_SWING", player.UserId, weaponId)
    
    -- Raycast for hit detection
    local origin = hrp.Position
    local rayDirection = direction.Unit * range
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character}
    
    local result = workspace:Raycast(origin, rayDirection, raycastParams)
    
    -- Also check with a wider sphere for better hit detection
    local targetHit = nil
    local hitPosition = origin + rayDirection
    
    if result then
        hitPosition = result.Position
        local hitPart = result.Instance
        local char = hitPart.Parent
        
        -- Check if it's a character (Player or Bot)
        if char:FindFirstChild("Humanoid") then
             targetHit = char
        elseif char.Parent:FindFirstChild("Humanoid") then
             targetHit = char.Parent
        end
    end
    
    -- If raycast didn't hit, try sphere detection (Cone Check)
    if not targetHit then
        -- Use OverlapParams to find any character in range
        local overlapParams = OverlapParams.new()
        overlapParams.FilterDescendantsInstances = {character}
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local parts = workspace:GetPartBoundsInRadius(origin, range, overlapParams)
        local potentialTargets = {}
        
        for _, part in ipairs(parts) do
            local char = part.Parent
            local hum = char:FindFirstChild("Humanoid")
            if hum and char ~= character and hum.Health > 0 and not potentialTargets[char] then
                potentialTargets[char] = true
                
                -- Check Direction (Cone)
                local charHrp = char:FindFirstChild("HumanoidRootPart")
                if charHrp then
                    local toTarget = charHrp.Position - origin
                    local dot = toTarget.Unit:Dot(direction.Unit)
                    
                    if dot > 0.4 then -- Within ~65 degree cone
                         targetHit = char
                         hitPosition = charHrp.Position
                         break -- Switch to closest check if needed, but first found is decent for now
                    end
                end
            end
        end
    end
    
    -- Apply damage if we hit someone
    if targetHit then
        WeaponSystem:applyDamage(player, targetHit, equippedTool, hitPosition)
    else
        -- Hit nothing - send miss event
        weaponSystemRemote:FireAllClients("WEAPON_HIT", hitPosition, "miss")
    end
    
    -- Reduce durability
    WeaponSystem:reduceDurability(player, equippedTool)
end

-- Process ranged attack
function WeaponSystem:processRangedAttack(player, direction, chargeAmount)
    if not WeaponSystem:canAttack(player) then return end
    
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    local damage = equippedTool:GetAttribute("Damage") or 10
    local projectileSpeed = equippedTool:GetAttribute("ProjectileSpeed") or 120 -- Increased default
    local range = equippedTool:GetAttribute("Range") or 80
    local weaponId = equippedTool:GetAttribute("WeaponId")
    local ammoType = equippedTool:GetAttribute("AmmoType")
    
    -- Scale damage and speed by charge amount (0-1)
    chargeAmount = math.clamp(chargeAmount or 1, 0.3, 1)
    local actualDamage = damage * chargeAmount
    local actualSpeed = projectileSpeed * chargeAmount
    
    -- Check for ammo (Ranged Weapons)
    local weaponType = equippedTool:GetAttribute("Type")
    
    if weaponType == "ranged" and ammoType then
        -- Get InventoryController
        local success, InventoryController = pcall(function()
            return require(script.Parent.InventoryController)
        end)
        
        if success and InventoryController then
            local ammoCount = InventoryController:getItemCount(player, ammoType)
            if ammoCount < 1 then
                -- No ammo - play click sound and fail
                -- weaponSystemRemote:FireClient(player, "NO_AMMO") -- Optional feedback
                return
            end
            
            -- Consume ammo
            InventoryController:removeItem(player, ammoType, 1)
        end
    end
    
    -- Handle Thrown Weapons (Consume the weapon itself)
    if weaponType == "thrown" then
        -- Get InventoryController
        local success, InventoryController = pcall(function()
            return require(script.Parent.InventoryController)
        end)
        
        if success and InventoryController then
             local weaponName = equippedTool:GetAttribute("WeaponId") or equippedTool.Name
             
             -- Decrease count
             InventoryController:removeItem(player, weaponName, 1)
             
             -- Check if any left
             local count = InventoryController:getItemCount(player, weaponName)
             if count <= 0 then
                  equippedTool:Destroy()
             end
        else
             -- Fallback if no InventoryController
             equippedTool:Destroy()
        end
        
        -- Prevent durability reduction for thrown weapons (since they are consumed)
        -- Removing faulty return here
    end
    
    -- Update cooldown
    WeaponSystem.weaponCooldowns[player] = tick()
    
    -- Create projectile
    local projectileId = WeaponSystem:createProjectile(player, hrp.Position, direction, actualSpeed, actualDamage, range, ammoType)
    
    -- Send shoot animation to clients
    weaponSystemRemote:FireAllClients("WEAPON_SHOOT", player.UserId, weaponId, direction)
    
    -- Reduce durability
    if weaponType ~= "thrown" then
        WeaponSystem:reduceDurability(player, equippedTool)
    end
    
    return projectileId
end

-- Create projectile
function WeaponSystem:createProjectile(player, origin, direction, speed, damage, maxRange, projectileType)
    local projectile = Instance.new("Part")
    projectile.Name = "Projectile"
    projectile.Size = Vector3.new(1, 1, 3) -- Much BIGGER HITBOX
    projectile.Transparency = 1 -- Invisible hitbox
    projectile.CanCollide = false
    projectile.Anchored = false
    projectile.Position = origin + direction.Unit * 3 + Vector3.new(0, 1, 0) -- Spawn slightly higher/forward
    projectile.CFrame = CFrame.lookAt(projectile.Position, projectile.Position + direction)
    projectile.Massless = true
    projectile.Parent = workspace
    
    -- Visual Mesh
    local visual
    if projectileType == "rock" or projectileType == "SlingshotAmmo" then
        -- Rock Visual
        visual = Instance.new("Part")
        visual.Size = Vector3.new(0.5, 0.5, 0.5)
        visual.Color = Color3.fromRGB(80, 80, 80)
        visual.Material = Enum.Material.Slate
        visual.Shape = Enum.PartType.Ball
        visual.CanCollide = false
        visual.Massless = true
        visual.Parent = projectile
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = projectile
        weld.Part1 = visual
        weld.Parent = projectile
    else
        -- Arrow Visual (Default)
        visual = Instance.new("Part")
        visual.Size = Vector3.new(0.2, 0.2, 2.5)
        visual.Color = Color3.fromRGB(139, 90, 43)
        visual.Material = Enum.Material.Wood
        visual.CanCollide = false
        visual.Massless = true
        visual.Parent = projectile
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = projectile
        weld.Part1 = visual
        weld.Parent = projectile
        
        -- Visual Tip
        local tip = Instance.new("Part")
        tip.Size = Vector3.new(0.3, 0.3, 0.5)
        tip.Color = Color3.fromRGB(150, 150, 150)
        tip.Material = Enum.Material.Metal
        tip.CanCollide = false
        tip.Massless = true
        tip.Parent = projectile
        
        local tipWeld = Instance.new("Weld")
        tipWeld.Part0 = visual
        tipWeld.Part1 = tip
        tipWeld.C0 = CFrame.new(0, 0, -1.2)
        tipWeld.Parent = tip
    end
    
    -- Apply velocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = direction.Unit * speed
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = projectile
    
    -- Gravity arc (simulated by reducing Y force over time)
    if projectileType == "arrow" or projectileType == "rock" or projectileType == "SlingshotAmmo" or projectileType == "knife" then
        task.delay(0.5, function() -- Increased to 0.5s for better range
            if projectile and projectile.Parent and bodyVelocity.Parent then
                bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge) -- Let gravity take Y
            end
        end)
    end
    
    -- Track projectile
    local startPos = projectile.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {player.Character, projectile}
    
    local connection
    
    connection = RunService.Heartbeat:Connect(function()
        if not projectile or not projectile.Parent then
            connection:Disconnect()
            return
        end
        
        local currentPos = projectile.Position
        local distance = (currentPos - startPos).Magnitude
        if distance > maxRange then
            connection:Disconnect()
            projectile:Destroy()
            return
        end
        
        -- Spherecast for better collision thickness
        local fwd = projectile.CFrame.LookVector
        local rayResult = workspace:Spherecast(currentPos, 1.5, fwd * 4, rayParams) -- 1.5 stud radius

        if rayResult then
            local hitPart = rayResult.Instance
            
            -- Valid hit? (Solid object or humanoid part)
            if hitPart.CanCollide or hitPart.Parent:FindFirstChild("Humanoid") or hitPart.Parent.Parent:FindFirstChild("Humanoid") then
                print("[WeaponSystem] Hit: " .. hitPart.Name) -- Enabled debug
                    
                    connection:Disconnect()
                    
                    -- Check for character/humanoid hit
                    local hitChar = hitPart.Parent
                    local hitHumanoid = hitChar:FindFirstChild("Humanoid") or (hitChar.Parent and hitChar.Parent:FindFirstChild("Humanoid"))
                    
                    if hitHumanoid then
                        hitChar = hitHumanoid.Parent
                        local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
                        
                        -- Apply damage (Filter handles self-hit)
                        WeaponSystem:applyDamage(player, hitChar, {GetAttribute = function(s, a) return (a=="Damage" and damage) or nil end}, currentPos) 
                    end
                    
                    -- Visual stick effect
                    projectile.Anchored = true
                    if bodyVelocity then bodyVelocity:Destroy() end
                    
                    -- Simple "embed" visual
                    projectile.CFrame = CFrame.lookAt(rayResult.Position, rayResult.Position + fwd)
                    
                    Debris:AddItem(projectile, 5)
                    return
             end
        end
    end)
    
    Debris:AddItem(projectile, 8) -- Failsafe cleanup
    
    return projectile
end

-- Apply damage to target
function WeaponSystem:applyDamage(attacker, target, weapon, hitPosition)
    local damage = weapon:GetAttribute("Damage") or 10
    local statusEffect = weapon:GetAttribute("StatusEffect")
    local statusChance = weapon:GetAttribute("StatusChance") or 0
    local statusDuration = weapon:GetAttribute("StatusDuration") or 5
    
    -- Get Config for critical hits
    local success, Config = pcall(function()
        return require(game:GetService("ReplicatedFirst"):WaitForChild("Config", 1))
    end)
    
    -- Calculate critical hit
    local critChance = success and Config.CRITICAL_HIT_CHANCE or 0.1
    local critMultiplier = success and Config.CRITICAL_HIT_MULTIPLIER or 2
    local isCritical = math.random() < critChance
    
    if isCritical then
        damage = damage * critMultiplier
    end
    
    -- Apply damage via PlayerStats if it's a player
    local psSuccess, PlayerStats = pcall(function()
        return require(script.Parent.PlayerStats)
    end)
    
    local targetPlayer = Players:GetPlayerFromCharacter(target)
    
    if targetPlayer and psSuccess and PlayerStats then
        PlayerStats:applyDamage(targetPlayer, damage, weapon:GetAttribute("WeaponId") or "Unknown")
    else
        -- Fallback: directly damage humanoid (NPCs, Bots, or if PlayerStats fails)
        local humanoid = target:FindFirstChild("Humanoid") or (target.Parent and target.Parent:FindFirstChild("Humanoid"))
        if humanoid then
            humanoid:TakeDamage(damage)
            
            -- TRIGGER BOT STUN/REACTION
            local botSuccess, BotController = pcall(function() return require(script.Parent.BotController) end)
            if botSuccess and BotController then
                -- Check if this is a managed bot
                for _, bot in pairs(BotController.bots) do
                    if bot.character == target then
                         BotController:onBotHit(bot, damage, attacker)
                         break
                    end
                end
            end
        end
    end
    
    -- Apply status effect
    if statusEffect and math.random() < statusChance then
        if targetPlayer and psSuccess and PlayerStats then
            PlayerStats:addStatusEffect(targetPlayer, statusEffect, statusDuration, 1) -- Fix: Pass Player not Character
        end
    end
    
    -- Send damage event
    weaponSystemRemote:FireAllClients("WEAPON_HIT", hitPosition, "player", damage, isCritical)
    
    -- Play audio
    local audioSuccess, AudioService = pcall(function()
        return require(script.Parent.AudioService)
    end)
    
    if audioSuccess and AudioService then
        local soundType = weapon:GetAttribute("Type") == "ranged" and "ARROW_HIT" or "SWORD_HIT"
        AudioService:playCombatSound(soundType, hitPosition, isCritical and 1.2 or 0.8)
    end
    
    print("[WeaponSystem] " .. attacker.Name .. " hit " .. target.Name .. " for " .. damage .. (isCritical and " (CRITICAL!)" or ""))
end

-- Reduce weapon durability
function WeaponSystem:reduceDurability(player, weapon)
    -- Check if durability is enabled
    if not Config.WEAPON_DURABILITY_ENABLED then
        return -- Durability disabled, don't reduce
    end
    
    local currentDurability = weapon:GetAttribute("CurrentDurability") or 1
    currentDurability = currentDurability - 1
    
    weapon:SetAttribute("CurrentDurability", currentDurability)
    
    if currentDurability <= 0 then
        -- Weapon broke
        weaponSystemRemote:FireClient(player, "WEAPON_BROKEN", weapon:GetAttribute("WeaponId"))
        print("[WeaponSystem] " .. player.Name .. "'s " .. weapon.Name .. " has broken!")
        weapon:Destroy()
    else
        -- Update durability display
        weaponSystemRemote:FireClient(player, "DURABILITY_UPDATE", weapon:GetAttribute("WeaponId"), currentDurability)
    end
end

-- ============ TRAP PLACEMENT ============

function WeaponSystem:placeTrap(player, trapId, position)
    local trapDef = WEAPONS[trapId]
    if not trapDef or trapDef.type ~= "trap" then
        warn("[WeaponSystem] Invalid trap: " .. tostring(trapId))
        return nil
    end
    
    -- Create trap in world
    local trap = Instance.new("Part")
    trap.Name = "Trap_" .. trapId
    trap.Size = trapDef.model.baseSize or Vector3.new(2, 0.5, 2)
    trap.Color = trapDef.model.baseColor or Color3.fromRGB(80, 40, 20)
    trap.Material = trapDef.model.baseMaterial or Enum.Material.Wood
    trap.Position = position + Vector3.new(0, 0.25, 0)
    trap.Anchored = true
    trap.CanCollide = false
    trap.Transparency = 0.3 -- Slightly visible
    trap.Parent = workspace
    
    trap:SetAttribute("TrapId", trapId)
    trap:SetAttribute("OwnerId", player.UserId)
    trap:SetAttribute("Damage", trapDef.damage)
    trap:SetAttribute("DamageType", trapDef.damageType)
    trap:SetAttribute("StatusEffect", trapDef.statusEffect)
    trap:SetAttribute("StatusDuration", trapDef.statusDuration)
    trap:SetAttribute("Radius", trapDef.radius or 5)
    
    -- Set up trigger detection
    local touchConnection
    touchConnection = trap.Touched:Connect(function(hit)
        local touchPlayer = Players:GetPlayerFromCharacter(hit.Parent)
        if touchPlayer and touchPlayer ~= player then
            touchConnection:Disconnect()
            WeaponSystem:triggerTrap(trap, touchPlayer, player)
        end
    end)
    
    print("[WeaponSystem] " .. player.Name .. " placed " .. trapId .. " at " .. tostring(position))
    
    return trap
end

-- Trigger a trap
function WeaponSystem:triggerTrap(trap, victim, owner)
    local trapId = trap:GetAttribute("TrapId")
    local damage = trap:GetAttribute("Damage") or 20
    local statusEffect = trap:GetAttribute("StatusEffect")
    local statusDuration = trap:GetAttribute("StatusDuration") or 5
    local radius = trap:GetAttribute("Radius") or 5
    
    print("[WeaponSystem] " .. victim.Name .. " triggered " .. trapId .. " placed by " .. (owner and owner.Name or "unknown"))
    
    -- Apply damage to victim
    local humanoid = victim.Character and victim.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:TakeDamage(damage)
    end
    
    -- Apply status effect
    if statusEffect then
        local psSuccess, PlayerStats = pcall(function()
            return require(script.Parent.PlayerStats)
        end)
        
        if psSuccess and PlayerStats then
            PlayerStats:addStatusEffect(victim, statusEffect, statusDuration, 1)
        end
    end
    
    -- Fire trap effect (area damage)
    if trapId == "FireTrap" then
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer.Character then
                local hrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = (hrp.Position - trap.Position).Magnitude
                    if distance <= radius then
                        local otherHumanoid = otherPlayer.Character:FindFirstChild("Humanoid")
                        if otherHumanoid then
                            otherHumanoid:TakeDamage(damage * 0.5) -- Half damage for area
                        end
                    end
                end
            end
        end
    end
    
    -- Visual effect
    weaponSystemRemote:FireAllClients("TRAP_TRIGGERED", trap.Position, trapId)
    
    -- Destroy trap
    trap:Destroy()
end

-- ============ INITIALIZATION ============

function WeaponSystem.init()
    print("[WeaponSystem] Initializing...")
    
    -- Handle weapon events from clients
    weaponSystemRemote.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}
        
        if action == "MELEE_ATTACK" then
            -- Deprecated: Use SWING and HIT
            local direction = args[1]
            if direction then
                WeaponSystem:processMeleeAttack(player, direction)
            end
            
        elseif action == "MELEE_SWING" then
            local direction = args[1]
            local character = player.Character
            if character then
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                     -- Broadcast swing to others
                     weaponSystemRemote:FireAllClients("WEAPON_SWING", player.UserId, tool:GetAttribute("WeaponId"))
                     
                     -- Update cooldown
                     WeaponSystem.weaponCooldowns[player] = tick()
                     WeaponSystem:reduceDurability(player, tool)
                end
            end
            
        elseif action == "MELEE_HIT" then
            local target = args[1] -- Can be Player OR Bot Model
            local hitPos = args[2]
            
            if target and hitPos then
                local character = player.Character
                if not character then return end
                
                local tool = character:FindFirstChildOfClass("Tool")
                if not tool or tool:GetAttribute("Type") ~= "melee" then return end
                
                local attPos = character.HumanoidRootPart.Position
                
                -- Determine if target is a Player or a Bot
                local targetChar = nil
                local targetHumanoid = nil
                local isBot = false
                
                if typeof(target) == "Instance" then
                    -- It's a bot model passed directly
                    if target:IsA("Model") and target:FindFirstChild("Humanoid") then
                        targetChar = target
                        targetHumanoid = target.Humanoid
                        isBot = target:FindFirstChild("IsBot") ~= nil
                    end
                elseif target.Character then
                    -- It's a Player
                    targetChar = target.Character
                    targetHumanoid = targetChar:FindFirstChild("Humanoid")
                end
                
                if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and targetHumanoid then
                    local targetPos = targetChar.HumanoidRootPart.Position
                    
                    -- Distance Check (Range + Buffer for lag)
                    local range = tool:GetAttribute("Range") or 5
                    local maxDist = range + 8 -- Generous buffer
                    local dist = (attPos - targetPos).Magnitude
                    
                    if dist <= maxDist then
                        -- Apply damage directly to humanoid
                        local damage = tool:GetAttribute("Damage") or 10
                        local isCrit = math.random() < Config.CRITICAL_HIT_CHANCE
                        if isCrit then
                            damage = damage * Config.CRITICAL_HIT_MULTIPLIER
                        end
                        
                        targetHumanoid:TakeDamage(damage)
                        print("[WeaponSystem] " .. player.Name .. " hit " .. targetChar.Name .. " for " .. damage .. (isCrit and " (CRIT!)" or ""))
                        
                        -- Update cooldown and durability
                        WeaponSystem.weaponCooldowns[player] = tick()
                        WeaponSystem:reduceDurability(player, tool)
                        
                        -- Notify clients of hit
                        weaponSystemRemote:FireAllClients("DAMAGE_DEALT", player.UserId, targetChar.Name, damage, hitPos, isCrit)
                        
                        -- Check for kill
                        if targetHumanoid.Health <= 0 then
                            if isBot then
                                -- Bot killed - notify BotController
                                local success, BotController = pcall(function()
                                    return require(script.Parent.BotController)
                                end)
                                if success then
                                    for _, bot in pairs(BotController.bots) do
                                        if bot.character == targetChar then
                                            BotController:eliminateBot(bot)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    else
                        warn(player.Name .. " hit rejected: Too far ("..math.floor(dist).."/"..range..")")
                    end
                end
            end
            
        elseif action == "RANGED_ATTACK" then
            local direction = args[1]
            local charge = args[2]
            local direction = args[1]
            local charge = args[2]
            if direction then
                WeaponSystem:processRangedAttack(player, direction, charge)
            end
            
        elseif action == "PLACE_TRAP" then
            local trapId = args[1]
            local position = args[2]
            if trapId and position then
                WeaponSystem:placeTrap(player, trapId, position)
            end
            
        elseif action == "REQUEST_WEAPON" then
            -- Debug/testing - give player a weapon
            local weaponId = args[1]
            if weaponId then
                WeaponSystem:giveWeapon(player, weaponId)
            end
        end
    end)
    local weaponCount = 0
    for _ in pairs(WEAPONS) do weaponCount = weaponCount + 1 end
    print("[WeaponSystem] Initialized with " .. weaponCount .. " weapon types")
    print("[WeaponSystem] Ready!")
end

-- Get weapon definition
function WeaponSystem:getWeaponDefinition(weaponId)
    return WEAPONS[weaponId]
end

-- Get all weapon IDs
function WeaponSystem:getAllWeaponIds()
    local ids = {}
    for id, _ in pairs(WEAPONS) do
        table.insert(ids, id)
    end
    return ids
end

return WeaponSystem
