-- ModuleScript: SimpleWeapons.lua
-- SIMPLE, WORKING weapon system for The Ember Games
-- Creates visible, equippable weapons

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SimpleWeapons = {}

-- Weapon definitions
local WEAPONS = {
    WoodenStick = {
        name = "Wooden Stick",
        damage = 15,
        range = 5,
        speed = 0.5,
        handle = {
            size = Vector3.new(0.4, 4, 0.4),
            color = Color3.fromRGB(139, 90, 43),
            material = Enum.Material.Wood
        }
    },
    
    Spear = {
        name = "Spear",
        damage = 25,
        range = 7,
        speed = 0.8,
        handle = {
            size = Vector3.new(0.3, 5, 0.3),
            color = Color3.fromRGB(120, 80, 40),
            material = Enum.Material.Wood
        },
        tip = {
            size = Vector3.new(0.2, 1, 0.4),
            color = Color3.fromRGB(80, 80, 80),
            material = Enum.Material.Metal
        }
    },
    
    Sword = {
        name = "Sword",
        damage = 30,
        range = 5,
        speed = 0.6,
        handle = {
            size = Vector3.new(0.3, 1.2, 0.3),
            color = Color3.fromRGB(100, 70, 40),
            material = Enum.Material.Wood
        },
        blade = {
            size = Vector3.new(0.15, 3, 0.6),
            color = Color3.fromRGB(180, 180, 190),
            material = Enum.Material.Metal
        }
    },
    
    Axe = {
        name = "Axe",
        damage = 35,
        range = 4,
        speed = 1.0,
        handle = {
            size = Vector3.new(0.3, 3.5, 0.3),
            color = Color3.fromRGB(100, 60, 30),
            material = Enum.Material.Wood
        },
        head = {
            size = Vector3.new(0.3, 1.5, 0.8),
            color = Color3.fromRGB(100, 100, 100),
            material = Enum.Material.Metal
        }
    }
}

-- Create a weapon tool
function SimpleWeapons:createWeapon(weaponId)
    local weaponDef = WEAPONS[weaponId]
    if not weaponDef then
        warn("[SimpleWeapons] Unknown weapon: " .. tostring(weaponId))
        return nil
    end
    
    -- Create Tool
    local tool = Instance.new("Tool")
    tool.Name = weaponDef.name
    tool.RequiresHandle = true
    tool.CanBeDropped = true
    tool.Grip = CFrame.new(0, -1.5, 0) * CFrame.Angles(0, 0, math.rad(90))
    
    -- Set attributes
    tool:SetAttribute("WeaponId", weaponId)
    tool:SetAttribute("Damage", weaponDef.damage)
    tool:SetAttribute("Range", weaponDef.range)
    tool:SetAttribute("AttackSpeed", weaponDef.speed)
    tool:SetAttribute("Type", "melee")
    
    -- Create Handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = weaponDef.handle.size
    handle.Color = weaponDef.handle.color
    handle.Material = weaponDef.handle.material
    handle.CanCollide = false
    handle.Parent = tool
    
    -- PROCEDURAL BLADE/HEAD/BRANCH CONSTRUCTION
    if weaponId == "WoodenStick" then
        handle.Size = Vector3.new(0.25, 3.8, 0.25)
        handle.Material = Enum.Material.Wood
        handle.Shape = Enum.PartType.Cylinder
        handle.CFrame = handle.CFrame * CFrame.Angles(0, 0, math.rad(90))
        
        -- Make it look like a natural branch
        local mainBranch = Instance.new("Part")
        mainBranch.Name = "Branch"
        mainBranch.Size = Vector3.new(0.15, 1.2, 0.15) 
        mainBranch.Color = handle.Color
        mainBranch.Material = handle.Material
        mainBranch.CanCollide = false
        mainBranch.Parent = tool
        local w1 = Instance.new("Weld", mainBranch)
        w1.Part0 = handle
        w1.Part1 = mainBranch
        w1.C0 = CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(35))
        
        local smallBranch = Instance.new("Part")
        smallBranch.Name = "Branch2"
        smallBranch.Size = Vector3.new(0.1, 0.6, 0.1)
        smallBranch.Color = handle.Color
        smallBranch.Material = handle.Material
        smallBranch.CanCollide = false
        smallBranch.Parent = tool
        local w2 = Instance.new("Weld", smallBranch)
        w2.Part0 = handle
        w2.Part1 = smallBranch
        w2.C0 = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, math.rad(90), math.rad(-25))
    end
    
    -- Add blade/tip/head if defined (Legacy data-driven)
    if weaponDef.blade then
        local blade = Instance.new("Part")
        blade.Name = "Blade"
        blade.Size = weaponDef.blade.size
        blade.Color = weaponDef.blade.color
        blade.Material = weaponDef.blade.material
        blade.CanCollide = false
        blade.Parent = tool
        
        local weld = Instance.new("Weld")
        weld.Part0 = handle
        weld.Part1 = blade
        weld.C0 = CFrame.new(0, weaponDef.handle.size.Y/2 + weaponDef.blade.size.Y/2, 0)
        weld.Parent = blade
    end
    
    if weaponDef.tip then
        local tip = Instance.new("Part")
        tip.Name = "Tip"
        tip.Size = weaponDef.tip.size
        tip.Color = weaponDef.tip.color
        tip.Material = weaponDef.tip.material
        tip.CanCollide = false
        tip.Parent = tool
        
        -- Make it triangular
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Wedge
        mesh.Parent = tip
        
        local weld = Instance.new("Weld")
        weld.Part0 = handle
        weld.Part1 = tip
        weld.C0 = CFrame.new(0, weaponDef.handle.size.Y/2 + weaponDef.tip.size.Y/2, 0) * CFrame.Angles(0, 0, math.rad(90))
        weld.Parent = tip
    end
    
    if weaponDef.head then
        local head = Instance.new("Part")
        head.Name = "Head"
        head.Size = weaponDef.head.size
        head.Color = weaponDef.head.color
        head.Material = weaponDef.head.material
        head.CanCollide = false
        head.Parent = tool
        
        local weld = Instance.new("Weld")
        weld.Part0 = handle
        weld.Part1 = head
        weld.C0 = CFrame.new(0, weaponDef.handle.size.Y/2 - 0.3, 0.3)
        weld.Parent = head
    end
    
    print("[SimpleWeapons] Created weapon: " .. weaponDef.name)
    return tool
end

-- Give weapon to player
function SimpleWeapons:giveWeapon(player, weaponId)
    local weapon = self:createWeapon(weaponId)
    if not weapon then return nil end
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        weapon.Parent = backpack
        print("[SimpleWeapons] Gave " .. weapon.Name .. " to " .. player.Name)
    end
    
    return weapon
end

-- Equip weapon to player
function SimpleWeapons:equipWeapon(player, weaponId)
    local weapon = self:giveWeapon(player, weaponId)
    if not weapon then return nil end
    
    -- Wait for backpack and equip
    task.wait(0.2)
    
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local backpack = player:FindFirstChild("Backpack")
    
    if humanoid and backpack then
        local tool = backpack:FindFirstChild(weapon.Name)
        if tool then
            humanoid:EquipTool(tool)
            print("[SimpleWeapons] Equipped " .. tool.Name .. " to " .. player.Name)
        end
    end
    
    return weapon
end

-- List available weapons
function SimpleWeapons:getWeaponList()
    local list = {}
    for id, def in pairs(WEAPONS) do
        table.insert(list, {
            id = id,
            name = def.name,
            damage = def.damage,
            range = def.range
        })
    end
    return list
end

-- Initialize
function SimpleWeapons.init()
    print("[SimpleWeapons] Initializing...")
    
    local weaponCount = 0
    for _ in pairs(WEAPONS) do weaponCount = weaponCount + 1 end
    
    print("[SimpleWeapons] Ready with " .. weaponCount .. " weapons!")
end

return SimpleWeapons
