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
        damage = 15,
        attackSpeed = 0.6, -- seconds between attacks
        range = 5,
        durability = 20,
        rarity = "common",
        description = "A basic wooden stick. Fast but weak.",
        model = {
            handleSize = Vector3.new(0.3, 3.5, 0.3), -- Thin stick
            handleColor = Color3.fromRGB(139, 90, 43),
            handleMaterial = Enum.Material.Wood,
            bladeSize = nil,
            bladeColor = nil
        }
    },
    
    ["SharpStick"] = {
        type = "melee",
        displayName = "Sharp Stick",
        damage = 25,
        attackSpeed = 0.8,
        range = 6,
        durability = 15,
        rarity = "common",
        description = "A sharpened stick. Longer reach.",
        statusEffect = "BLEEDING",
        statusChance = 0.10,
        statusDuration = 5,
        model = {
            handleSize = Vector3.new(0.4, 5, 0.4), -- Thicker for visibility
            handleColor = Color3.fromRGB(120, 80, 40),
            handleMaterial = Enum.Material.Wood,
            tipSize = Vector3.new(0.3, 1, 0.3), -- Bigger tip
            tipColor = Color3.fromRGB(100, 100, 110) -- Metal gray
        }
    },
    
    ["StoneKnife"] = {
        type = "melee",
        displayName = "Stone Knife",
        damage = 20,
        attackSpeed = 0.5,
        range = 4,
        durability = 25,
        rarity = "common",
        description = "A crude stone knife. Fast with bleeding chance.",
        statusEffect = "BLEEDING",
        statusChance = 0.15,
        statusDuration = 5,
        model = {
            handleSize = Vector3.new(0.2, 1.2, 0.2),
            handleColor = Color3.fromRGB(139, 90, 43),
            handleMaterial = Enum.Material.Wood,
            bladeSize = Vector3.new(0.15, 1.5, 0.4),
            bladeColor = Color3.fromRGB(100, 100, 100),
            bladeMaterial = Enum.Material.Slate
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
        ammoType = "rock",
        ammoPerShot = 1,
        model = {
            handleSize = Vector3.new(0.3, 2, 0.3),
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
        ammoType = "arrow",
        ammoPerShot = 1,
        chargeTime = 0.5, -- seconds to fully charge
        statusEffect = "BLEEDING",
        statusChance = 0.20,
        statusDuration = 6,
        model = {
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
        model = {
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

local function createMeleeWeaponModel(weaponId, weaponDef)
    local weapon = Instance.new("Tool")
    weapon.Name = weaponId
    weapon.RequiresHandle = true
    weapon.CanBeDropped = true
    
    -- Create handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = weaponDef.model.handleSize or Vector3.new(0.3, 3, 0.3)
    handle.Color = weaponDef.model.handleColor or Color3.fromRGB(139, 90, 43)
    handle.Material = weaponDef.model.handleMaterial or Enum.Material.Wood
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = weapon
    
    -- Create blade if exists
    if weaponDef.model.bladeSize then
        local blade = Instance.new("Part")
        blade.Name = "Blade"
        blade.Size = weaponDef.model.bladeSize
        blade.Color = weaponDef.model.bladeColor or Color3.fromRGB(150, 150, 160)
        blade.Material = weaponDef.model.bladeMaterial or Enum.Material.Metal
        blade.CanCollide = false
        blade.Massless = true
        blade.Parent = weapon
        
        -- Weld blade to handle
        local weld = Instance.new("Weld")
        weld.Part0 = handle
        weld.Part1 = blade
        local offset = weaponDef.model.bladeOffset or Vector3.new(0, handle.Size.Y / 2 + blade.Size.Y / 2, 0)
        weld.C0 = CFrame.new(offset)
        weld.Parent = blade
    end
    
    -- Create tip if exists (for spears) - make it look pointed
    if weaponDef.model.tipSize then
        local tip = Instance.new("Part")
        tip.Name = "Tip"
        tip.Size = Vector3.new(0.4, 1.5, 0.4) -- Bigger visible tip
        tip.Color = Color3.fromRGB(120, 120, 130) -- Metal gray
        tip.Material = Enum.Material.Metal
        tip.CanCollide = false
        tip.Massless = true
        tip.Parent = weapon
        
        -- Use wedge mesh for pointed look like a spear head
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Wedge
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = tip
        
        local weld = Instance.new("Weld")
        weld.Part0 = handle
        weld.Part1 = tip
        -- Position at top of handle, rotated to point up
        weld.C0 = CFrame.new(0, handle.Size.Y / 2 + 0.6, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        weld.Parent = tip
    end
    
    -- Store weapon data as attributes
    weapon:SetAttribute("WeaponId", weaponId)
    weapon:SetAttribute("Damage", weaponDef.damage)
    weapon:SetAttribute("Range", weaponDef.range)
    weapon:SetAttribute("AttackSpeed", weaponDef.attackSpeed)
    weapon:SetAttribute("Durability", weaponDef.durability)
    weapon:SetAttribute("CurrentDurability", weaponDef.durability)
    weapon:SetAttribute("Type", weaponDef.type)
    weapon:SetAttribute("Rarity", weaponDef.rarity)
    
    if weaponDef.statusEffect then
        weapon:SetAttribute("StatusEffect", weaponDef.statusEffect)
        weapon:SetAttribute("StatusChance", weaponDef.statusChance)
        weapon:SetAttribute("StatusDuration", weaponDef.statusDuration)
    end
    
    return weapon
end

local function createRangedWeaponModel(weaponId, weaponDef)
    local weapon = Instance.new("Tool")
    weapon.Name = weaponId
    weapon.RequiresHandle = true
    weapon.CanBeDropped = true
    
    -- Create handle (bow body)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    
    if weaponDef.model.bowSize then
        handle.Size = weaponDef.model.bowSize
        handle.Color = weaponDef.model.bowColor
        handle.Material = weaponDef.model.bowMaterial
    else
        handle.Size = weaponDef.model.handleSize
        handle.Color = weaponDef.model.handleColor
        handle.Material = weaponDef.model.handleMaterial
    end
    
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = weapon
    
    -- Store weapon data
    weapon:SetAttribute("WeaponId", weaponId)
    weapon:SetAttribute("Damage", weaponDef.damage)
    weapon:SetAttribute("Range", weaponDef.range)
    weapon:SetAttribute("ProjectileSpeed", weaponDef.projectileSpeed)
    weapon:SetAttribute("AttackSpeed", weaponDef.attackSpeed)
    weapon:SetAttribute("Durability", weaponDef.durability)
    weapon:SetAttribute("CurrentDurability", weaponDef.durability)
    weapon:SetAttribute("Type", weaponDef.type)
    weapon:SetAttribute("Rarity", weaponDef.rarity)
    weapon:SetAttribute("AmmoType", weaponDef.ammoType)
    
    if weaponDef.chargeTime then
        weapon:SetAttribute("ChargeTime", weaponDef.chargeTime)
    end
    
    return weapon
end

local function createThrownWeaponModel(weaponId, weaponDef)
    local weapon = Instance.new("Tool")
    weapon.Name = weaponId
    weapon.RequiresHandle = true
    weapon.CanBeDropped = true
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = weaponDef.model.bladeSize or Vector3.new(0.1, 2, 0.3)
    handle.Color = weaponDef.model.bladeColor or Color3.fromRGB(150, 150, 160)
    handle.Material = weaponDef.model.bladeMaterial or Enum.Material.Metal
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = weapon
    
    weapon:SetAttribute("WeaponId", weaponId)
    weapon:SetAttribute("Damage", weaponDef.damage)
    weapon:SetAttribute("Range", weaponDef.range)
    weapon:SetAttribute("ProjectileSpeed", weaponDef.projectileSpeed)
    weapon:SetAttribute("AttackSpeed", weaponDef.attackSpeed)
    weapon:SetAttribute("Type", weaponDef.type)
    weapon:SetAttribute("Rarity", weaponDef.rarity)
    weapon:SetAttribute("StackSize", weaponDef.stackSize or 1)
    
    return weapon
end

-- ============ WEAPON CREATION ============

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
        -- Traps and baits
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
        
        -- Check if we hit a player
        local hitPart = result.Instance
        local hitPlayer = Players:GetPlayerFromCharacter(hitPart.Parent)
        
        if hitPlayer then
            targetHit = hitPlayer
        end
    end
    
    -- If raycast didn't hit, try sphere detection
    if not targetHit then
        -- Find all players within range in front direction
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                if otherHrp then
                    local toTarget = otherHrp.Position - origin
                    local distance = toTarget.Magnitude
                    
                    -- Check if within range and roughly in attack direction
                    if distance <= range then
                        local dot = toTarget.Unit:Dot(direction.Unit)
                        if dot > 0.3 then -- Within ~70 degree cone
                            targetHit = otherPlayer
                            hitPosition = otherHrp.Position
                            break
                        end
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
    local projectileSpeed = equippedTool:GetAttribute("ProjectileSpeed") or 100
    local range = equippedTool:GetAttribute("Range") or 50
    local weaponId = equippedTool:GetAttribute("WeaponId")
    local ammoType = equippedTool:GetAttribute("AmmoType")
    
    -- Scale damage and speed by charge amount (0-1)
    chargeAmount = math.clamp(chargeAmount or 1, 0.3, 1)
    local actualDamage = damage * chargeAmount
    local actualSpeed = projectileSpeed * chargeAmount
    
    -- Update cooldown
    WeaponSystem.weaponCooldowns[player] = tick()
    
    -- Create projectile
    local projectileId = WeaponSystem:createProjectile(player, hrp.Position, direction, actualSpeed, actualDamage, range, ammoType)
    
    -- Send shoot animation to clients
    weaponSystemRemote:FireAllClients("WEAPON_SHOOT", player.UserId, weaponId, direction)
    
    -- Reduce durability
    WeaponSystem:reduceDurability(player, equippedTool)
    
    return projectileId
end

-- Create projectile
function WeaponSystem:createProjectile(player, origin, direction, speed, damage, maxRange, projectileType)
    local projectile = Instance.new("Part")
    projectile.Name = "Projectile"
    projectile.Size = Vector3.new(0.2, 0.2, 1.5)
    projectile.Color = Color3.fromRGB(100, 70, 40)
    projectile.Material = Enum.Material.Wood
    projectile.CanCollide = false
    projectile.Anchored = false
    projectile.Position = origin + direction.Unit * 2
    projectile.CFrame = CFrame.lookAt(projectile.Position, projectile.Position + direction)
    projectile.Parent = workspace
    
    -- Arrow appearance
    if projectileType == "arrow" then
        local tip = Instance.new("Part")
        tip.Size = Vector3.new(0.15, 0.3, 0.15)
        tip.Color = Color3.fromRGB(80, 80, 80)
        tip.Material = Enum.Material.Metal
        tip.CanCollide = false
        tip.Massless = true
        tip.Parent = projectile
        
        local weld = Instance.new("Weld")
        weld.Part0 = projectile
        weld.Part1 = tip
        weld.C0 = CFrame.new(0, 0, -0.9)
        weld.Parent = tip
    end
    
    -- Apply velocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = direction.Unit * speed
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = projectile
    
    -- Add gravity for arrows
    if projectileType == "arrow" then
        task.delay(0.2, function()
            if projectile and projectile.Parent then
                bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
                projectile.Anchored = false
            end
        end)
    end
    
    -- Track projectile
    local startPos = origin
    local hit = false
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not projectile or not projectile.Parent then
            connection:Disconnect()
            return
        end
        
        local distance = (projectile.Position - startPos).Magnitude
        if distance > maxRange then
            connection:Disconnect()
            projectile:Destroy()
            return
        end
        
        -- Check for collision
        local rayResult = workspace:Raycast(
            projectile.Position,
            projectile.CFrame.LookVector * 2,
            RaycastParams.new()
        )
        
        if rayResult then
            connection:Disconnect()
            
            local hitPart = rayResult.Instance
            local hitPlayer = Players:GetPlayerFromCharacter(hitPart.Parent)
            
            if hitPlayer and hitPlayer ~= player then
                -- We hit a player
                local targetChar = hitPlayer.Character
                if targetChar then
                    local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
                    local hitPos = targetHrp and targetHrp.Position or rayResult.Position
                    
                    -- Create fake tool for damage application
                    local fakeWeapon = Instance.new("Tool")
                    fakeWeapon:SetAttribute("Damage", damage)
                    fakeWeapon:SetAttribute("StatusEffect", "BLEEDING")
                    fakeWeapon:SetAttribute("StatusChance", 0.2)
                    fakeWeapon:SetAttribute("StatusDuration", 5)
                    
                    WeaponSystem:applyDamage(player, hitPlayer, fakeWeapon, hitPos)
                    fakeWeapon:Destroy()
                end
            end
            
            -- Stick arrow in place
            projectile.Anchored = true
            projectile.Position = rayResult.Position
            Debris:AddItem(projectile, 10)
            
            weaponSystemRemote:FireAllClients("PROJECTILE_HIT", rayResult.Position, hitPlayer ~= nil and "player" or "environment")
        end
    end)
    
    -- Cleanup after max time
    Debris:AddItem(projectile, maxRange / speed + 5)
    
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
    
    -- Apply damage via PlayerStats
    local psSuccess, PlayerStats = pcall(function()
        return require(script.Parent.PlayerStats)
    end)
    
    if psSuccess and PlayerStats then
        PlayerStats:applyDamage(target, damage, weapon:GetAttribute("WeaponId") or "Unknown")
    else
        -- Fallback: directly damage humanoid
        local humanoid = target.Character and target.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:TakeDamage(damage)
        end
    end
    
    -- Apply status effect
    if statusEffect and math.random() < statusChance then
        if psSuccess and PlayerStats then
            PlayerStats:addStatusEffect(target, statusEffect, statusDuration, 1)
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
