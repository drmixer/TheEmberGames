-- ModuleScript: SimpleBots.lua
-- SIMPLE, WORKING bot AI for The Ember Games
-- Clean implementation with predictable behavior

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local SimpleBots = {}
SimpleBots.bots = {}
SimpleBots.isActive = false

-- Configuration
local CONFIG = {
    MAX_BOTS = 23,
    SPAWN_RADIUS = 50,       -- studs from center
    DETECTION_RANGE = 30,    -- studs to notice player
    ATTACK_RANGE = 5,        -- studs to attack
    WALK_SPEED = 12,
    ATTACK_DAMAGE = 15,
    ATTACK_COOLDOWN = 1.5,   -- seconds
    HEALTH = 100,
    UPDATE_INTERVAL = 0.5,   -- seconds between AI updates
}

-- Bot names
local BOT_NAMES = {
    "Tribute_Alpha", "Tribute_Bravo", "Tribute_Charlie", "Tribute_Delta",
    "Tribute_Echo", "Tribute_Foxtrot", "Tribute_Golf", "Tribute_Hotel",
    "Career_Rex", "Career_Max", "Career_Jade", "Career_Storm",
    "District_1", "District_2", "District_3", "District_4",
    "Survivor_1", "Survivor_2", "Survivor_3", "Survivor_4"
}

-- District colors
local DISTRICT_COLORS = {
    Color3.fromRGB(212, 175, 55),  -- D1 Gold
    Color3.fromRGB(128, 128, 128), -- D2 Gray
    Color3.fromRGB(139, 69, 19),   -- D3 Brown
    Color3.fromRGB(0, 191, 255),   -- D4 Blue
    Color3.fromRGB(255, 165, 0),   -- D5 Orange
    Color3.fromRGB(50, 50, 50),    -- D6 Dark
    Color3.fromRGB(34, 139, 34),   -- D7 Green
    Color3.fromRGB(255, 255, 255), -- D8 White
    Color3.fromRGB(255, 215, 0),   -- D9 Yellow
    Color3.fromRGB(64, 64, 64),    -- D10 Charcoal
    Color3.fromRGB(139, 119, 101), -- D11 Tan
    Color3.fromRGB(105, 105, 105), -- D12 Gray
}

-- Create a simple humanoid character model
local function createBotModel(name, district)
    local model = Instance.new("Model")
    model.Name = name
    
    -- Create humanoid first
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = CONFIG.HEALTH
    humanoid.Health = CONFIG.HEALTH
    humanoid.WalkSpeed = CONFIG.WALK_SPEED
    humanoid.Parent = model
    
    -- Get district color
    local color = DISTRICT_COLORS[district] or DISTRICT_COLORS[1]
    
    -- Create body parts (R6 style)
    local function createPart(name, size, position)
        local part = Instance.new("Part")
        part.Name = name
        part.Size = size
        part.Position = position
        part.BrickColor = BrickColor.new(color)
        part.Material = Enum.Material.SmoothPlastic
        part.CanCollide = true
        part.Parent = model
        return part
    end
    
    local torso = createPart("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
    local head = createPart("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.5, 0))
    local leftArm = createPart("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0))
    local rightArm = createPart("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0))
    local leftLeg = createPart("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0))
    local rightLeg = createPart("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0))
    
    -- Head is skin colored
    head.BrickColor = BrickColor.new("Light orange")
    
    -- Add face
    local face = Instance.new("Decal")
    face.Name = "face"
    face.Face = Enum.NormalId.Front
    face.Texture = "rbxasset://textures/face.png"
    face.Parent = head
    
    -- HumanoidRootPart
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Position = Vector3.new(0, 3, 0)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Parent = model
    
    -- Set primary part
    model.PrimaryPart = hrp
    
    -- Create joints (Motor6D)
    local function createJoint(name, part0, part1, c0, c1)
        local motor = Instance.new("Motor6D")
        motor.Name = name
        motor.Part0 = part0
        motor.Part1 = part1
        motor.C0 = c0
        motor.C1 = c1
        motor.Parent = part0
        return motor
    end
    
    createJoint("RootJoint", hrp, torso, CFrame.new(0, 0, 0), CFrame.new(0, 0, 0))
    createJoint("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    createJoint("Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
    createJoint("Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
    createJoint("Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
    createJoint("Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
    
    -- Create weapon (simple stick)
    local weapon = Instance.new("Part")
    weapon.Name = "Weapon"
    weapon.Size = Vector3.new(0.3, 3, 0.3)
    weapon.Color = Color3.fromRGB(139, 90, 43)
    weapon.Material = Enum.Material.Wood
    weapon.CanCollide = false
    weapon.Parent = model
    
    local weaponWeld = Instance.new("Weld")
    weaponWeld.Part0 = rightArm
    weaponWeld.Part1 = weapon
    weaponWeld.C0 = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
    weaponWeld.Parent = weapon
    
    -- Mark as bot
    local botTag = Instance.new("BoolValue")
    botTag.Name = "IsBot"
    botTag.Value = true
    botTag.Parent = model
    
    return model
end

-- Find nearest player target
local function findNearestPlayer(botPosition)
    local nearest = nil
    local nearestDistance = CONFIG.DETECTION_RANGE
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local distance = (player.Character.HumanoidRootPart.Position - botPosition).Magnitude
                if distance < nearestDistance then
                    nearest = player
                    nearestDistance = distance
                end
            end
        end
    end
    
    return nearest, nearestDistance
end

-- Bot behavior: wander randomly
local function wander(bot)
    local humanoid = bot.character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local hrp = bot.character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Random point nearby
    local angle = math.random() * math.pi * 2
    local distance = math.random(10, 25)
    local targetPos = hrp.Position + Vector3.new(
        math.cos(angle) * distance,
        0,
        math.sin(angle) * distance
    )
    
    humanoid:MoveTo(targetPos)
end

-- Bot behavior: chase target
local function chase(bot, target)
    local humanoid = bot.character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local targetHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return end
    
    humanoid:MoveTo(targetHrp.Position)
end

-- Bot behavior: attack target
local function attack(bot, target)
    local humanoid = bot.character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local now = tick()
    if now - bot.lastAttack < CONFIG.ATTACK_COOLDOWN then return end
    bot.lastAttack = now
    
    -- Deal damage
    local targetHumanoid = target.Character and target.Character:FindFirstChild("Humanoid")
    if targetHumanoid and targetHumanoid.Health > 0 then
        targetHumanoid:TakeDamage(CONFIG.ATTACK_DAMAGE)
        print("[SimpleBots] " .. bot.character.Name .. " attacked " .. target.Name .. " for " .. CONFIG.ATTACK_DAMAGE)
        
        -- Simple attack animation (swing arm)
        local rightArm = bot.character:FindFirstChild("Right Arm")
        if rightArm then
            local shoulder = bot.character.Torso:FindFirstChild("Right Shoulder")
            if shoulder then
                task.spawn(function()
                    local originalC0 = shoulder.C0
                    shoulder.C0 = originalC0 * CFrame.Angles(math.rad(-80), 0, 0)
                    task.wait(0.2)
                    shoulder.C0 = originalC0
                end)
            end
        end
    end
end

-- Update single bot AI
local function updateBot(bot)
    if not bot.character or not bot.character.Parent then return end
    
    local humanoid = bot.character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local hrp = bot.character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Find target
    local target, distance = findNearestPlayer(hrp.Position)
    
    if target then
        if distance <= CONFIG.ATTACK_RANGE then
            -- Attack
            attack(bot, target)
        else
            -- Chase
            chase(bot, target)
        end
    else
        -- Wander
        if math.random() < 0.3 then -- Don't wander every update
            wander(bot)
        end
    end
end

-- Spawn a single bot
function SimpleBots:spawnBot(district)
    district = district or math.random(1, 12)
    
    local name = BOT_NAMES[math.random(#BOT_NAMES)] .. "_" .. #self.bots + 1
    local model = createBotModel(name, district)
    
    -- Spawn position
    local angle = math.random() * math.pi * 2
    local spawnPos = Vector3.new(
        math.cos(angle) * CONFIG.SPAWN_RADIUS,
        20,
        math.sin(angle) * CONFIG.SPAWN_RADIUS
    )
    
    -- Raycast to find ground
    local result = workspace:Raycast(spawnPos, Vector3.new(0, -100, 0))
    if result then
        spawnPos = result.Position + Vector3.new(0, 5, 0)
    end
    
    model:SetPrimaryPartCFrame(CFrame.new(spawnPos))
    model.Parent = workspace
    
    local bot = {
        character = model,
        district = district,
        lastAttack = 0,
        lastUpdate = 0
    }
    
    table.insert(self.bots, bot)
    print("[SimpleBots] Spawned " .. name .. " (District " .. district .. ")")
    
    -- Handle death
    local humanoid = model:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            print("[SimpleBots] " .. name .. " was eliminated!")
            model:Destroy()
            
            for i, b in ipairs(self.bots) do
                if b == bot then
                    table.remove(self.bots, i)
                    break
                end
            end
        end)
    end
    
    return bot
end

-- Spawn multiple bots
function SimpleBots:spawnBots(count)
    count = math.min(count, CONFIG.MAX_BOTS)
    
    print("[SimpleBots] Spawning " .. count .. " bots...")
    
    for i = 1, count do
        local district = ((i - 1) % 12) + 1
        self:spawnBot(district)
        task.wait(0.1) -- Stagger spawns
    end
    
    self.isActive = true
    print("[SimpleBots] Spawned " .. count .. " bots!")
end

-- Main update loop
function SimpleBots:startAI()
    RunService.Heartbeat:Connect(function()
        if not self.isActive then return end
        
        local now = tick()
        
        for _, bot in ipairs(self.bots) do
            if now - bot.lastUpdate >= CONFIG.UPDATE_INTERVAL then
                bot.lastUpdate = now
                updateBot(bot)
            end
        end
    end)
end

-- Remove all bots
function SimpleBots:clear()
    for _, bot in ipairs(self.bots) do
        if bot.character then
            bot.character:Destroy()
        end
    end
    self.bots = {}
    self.isActive = false
    print("[SimpleBots] Cleared all bots")
end

-- Initialize
function SimpleBots.init()
    print("[SimpleBots] Initializing...")
    SimpleBots:startAI()
    print("[SimpleBots] Ready!")
end

return SimpleBots
