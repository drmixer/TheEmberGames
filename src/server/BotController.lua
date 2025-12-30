-- ModuleScript: BotController.lua
-- AI Bot system for The Ember Games
-- Spawns and controls bot tributes for solo play or player fill
-- IMPROVED: More natural behavior, less aggressive, visible attacks

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local BotController = {}
BotController.bots = {}
BotController.botCount = 0
BotController.maxBots = 23
BotController.isActive = false

-- Bot names for variety
local BOT_NAMES = {
    "Tribute_Alpha", "Tribute_Bravo", "Tribute_Charlie", "Tribute_Delta",
    "Tribute_Echo", "Tribute_Foxtrot", "Tribute_Golf", "Tribute_Hotel",
    "Tribute_India", "Tribute_Juliet", "Tribute_Kilo", "Tribute_Lima",
    "Tribute_Mike", "Tribute_November", "Tribute_Oscar", "Tribute_Papa",
    "Tribute_Quebec", "Tribute_Romeo", "Tribute_Sierra", "Tribute_Tango",
    "Tribute_Uniform", "Tribute_Victor", "Tribute_Whiskey", "Tribute_Xray",
    "Tribute_Yankee", "Tribute_Zulu", "District1_Bot", "District2_Bot",
    "Career_Hunter", "Career_Fighter", "Survivor_1", "Survivor_2"
}

-- Bot Outfits (Reliable Combat Sets)
local BOT_OUTFITS = {
    {shirt = "http://www.roblox.com/asset/?id=144076358", pants = "http://www.roblox.com/asset/?id=144076468"}, -- Green Camo
    {shirt = "http://www.roblox.com/asset/?id=606361074", pants = "http://www.roblox.com/asset/?id=606364287"}  -- Urban Camo
}

-- BALANCED Bot difficulty levels (more aggressive now)
local DIFFICULTY = {
    EASY = {
        reactionTime = 2.5,      -- React time
        accuracy = 0.3,          -- 30% hit chance
        aggressiveness = 0.3,    -- Will fight if close
        speed = 11,              -- Slow-ish movement
        attackCooldown = 3.0,    -- 3 seconds between attacks
        detectionRange = 25,     -- Notices nearby
    },
    MEDIUM = {
        reactionTime = 1.5,      -- Moderate reaction
        accuracy = 0.45,         -- 45% hit chance
        aggressiveness = 0.5,    -- Often attacks
        speed = 13,              -- Normal speed
        attackCooldown = 2.0,    -- 2 seconds between attacks
        detectionRange = 40,     -- Good awareness
    },
    HARD = {
        reactionTime = 0.8,      -- Fast reaction
        accuracy = 0.6,          -- 60% hit chance
        aggressiveness = 0.7,    -- Very aggressive
        speed = 15,              -- Fast
        attackCooldown = 1.5,    -- 1.5 seconds between attacks
        detectionRange = 55,     -- Great awareness
    }
}

-- Create a bot character model
local function createBotCharacter(botData)
    local character = Instance.new("Model")
    character.Name = botData.name
    
    -- Create humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.WalkSpeed = botData.difficulty.speed
    humanoid.Parent = character
    
    -- Create body parts
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Anchored = false
    hrp.Parent = character
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Color = Color3.fromRGB(80, 80, 80) -- Dark shirt
    torso.CanCollide = true
    torso.Parent = character
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.Shape = Enum.PartType.Ball
    head.Color = Color3.fromRGB(255, 204, 153)
    head.CanCollide = false
    head.Parent = character
    
    local face = Instance.new("Decal")
    face.Name = "face"
    face.Texture = "rbxasset://textures/face.png"
    face.Parent = head
    
    -- Arms
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Color = Color3.fromRGB(255, 204, 153)
    leftArm.CanCollide = false
    leftArm.Parent = character
    
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Color = Color3.fromRGB(255, 204, 153)
    rightArm.CanCollide = false
    rightArm.Parent = character
    
    -- Legs
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.Color = Color3.fromRGB(40, 40, 40) -- Black pants
    leftLeg.CanCollide = false
    leftLeg.Parent = character
    
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.Color = Color3.fromRGB(40, 40, 40) -- Black pants
    rightLeg.CanCollide = false
    rightLeg.Parent = character
    
    -- Add Tactical Vest (Procedural)
    local vest = Instance.new("Part")
    vest.Name = "Vest"
    vest.Size = Vector3.new(2.1, 1.2, 1.1) -- Chest protection
    vest.Color = Color3.fromRGB(50, 60, 50) -- Dark Olive
    vest.Material = Enum.Material.Fabric
    vest.CanCollide = false
    vest.Parent = character
    
    local vestWeld = Instance.new("Weld")
    vestWeld.Part0 = torso
    vestWeld.Part1 = vest
    vestWeld.C0 = CFrame.new(0, 0.4, 0) -- Upper chest
    vestWeld.Parent = vest
    
    -- Add Knee Pads
    local padColor = Color3.fromRGB(20, 20, 20)
    
    local leftPad = Instance.new("Part")
    leftPad.Size = Vector3.new(1.1, 0.5, 1.1)
    leftPad.Color = padColor
    leftPad.CanCollide = false
    leftPad.Parent = character
    local lpWeld = Instance.new("Weld")
    lpWeld.Part0 = leftLeg
    lpWeld.Part1 = leftPad
    lpWeld.C0 = CFrame.new(0, -0.2, 0) -- Knee height
    lpWeld.Parent = leftPad
    
    local rightPad = Instance.new("Part")
    rightPad.Size = Vector3.new(1.1, 0.5, 1.1)
    rightPad.Color = padColor
    rightPad.CanCollide = false
    rightPad.Parent = character
    local rpWeld = Instance.new("Weld")
    rpWeld.Part0 = rightLeg
    rpWeld.Part1 = rightPad
    rpWeld.C0 = CFrame.new(0, -0.2, 0)
    rpWeld.Parent = rightPad
    
    -- Simple weapon visual
    local weapon = Instance.new("Part")
    weapon.Name = "Weapon"
    weapon.Size = Vector3.new(0.3, 3, 0.3)
    weapon.Color = Color3.fromRGB(139, 90, 43) -- Wood color
    weapon.Material = Enum.Material.Wood
    weapon.CanCollide = false
    weapon.Parent = character
    
    -- Welds
    local function createMotor(name, part0, part1, c0, c1)
        local motor = Instance.new("Motor6D")
        motor.Name = name
        motor.Part0 = part0
        motor.Part1 = part1
        motor.C0 = c0 or CFrame.new()
        motor.C1 = c1 or CFrame.new()
        motor.Parent = part0
        return motor
    end
    
    createMotor("RootJoint", hrp, torso, CFrame.new(0, 0, 0))
    createMotor("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    createMotor("Left Shoulder", torso, leftArm, CFrame.new(-1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
    createMotor("Right Shoulder", torso, rightArm, CFrame.new(1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
    createMotor("Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
    createMotor("Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
    
    -- Attach weapon to right arm
    local weaponWeld = Instance.new("Weld")
    weaponWeld.Part0 = rightArm
    weaponWeld.Part1 = weapon
    weaponWeld.C0 = CFrame.new(0, -1.5, 0)
    weaponWeld.Parent = rightArm
    
    character.PrimaryPart = hrp
    
    -- Tags
    local botTag = Instance.new("BoolValue")
    botTag.Name = "IsBot"
    botTag.Value = true
    botTag.Parent = character
    
    local districtTag = Instance.new("IntValue")
    districtTag.Name = "District"
    districtTag.Value = botData.district
    districtTag.Parent = character
    
    return character
end

-- Create a new bot
function BotController:createBot(district, difficulty)
    local botId = BotController.botCount + 1
    BotController.botCount = botId
    
    local botName = BOT_NAMES[math.random(1, #BOT_NAMES)] .. "_" .. botId
    local difficultyData = difficulty or DIFFICULTY.EASY -- Default to EASY now
    
    local botData = {
        id = botId,
        name = botName,
        district = district or math.random(1, 12),
        difficulty = difficultyData,
        state = "idle",
        target = nil,
        health = 100,
        isAlive = true,
        character = nil,
        lastAction = tick(),
        lastAttack = 0, -- Track attack cooldown
        inventory = {},
    }
    
    local character = createBotCharacter(botData)
    botData.character = character
    
    local character = createBotCharacter(botData)
    botData.character = character
    
    -- Spawn on platform (starting after real players)
    local platformIndex = #Players:GetPlayers() + botId -- Offset by player count
    if platformIndex > 24 then platformIndex = 24 end -- Cap safe index
    
    local platformName = "Platform_" .. platformIndex
    local platformsFolder = workspace:FindFirstChild("SpawnPlatforms")
    local platform = platformsFolder and platformsFolder:FindFirstChild(platformName)
    
    local spawnPos
    if platform then
        -- Check if platform has an "OriginalCFrame" (meaning it is tracked by Spawner)
        local origCF = platform:GetAttribute("OriginalCFrame")
        if origCF then
            -- We want to spawn on the *lowered* state (Original - 25 studs)
            -- Only use OriginalCFrame as reference, calculate lowered position manually to be safe
            local loweredPos = origCF.Position - Vector3.new(0, 25, 0)
            spawnPos = loweredPos + Vector3.new(0, 5, 0) -- On top of lowered platform
        else
            -- Platform exists but hasn't been prepared yet (unlikely if loop order is correct, but safe fallback)
            -- Just put them underground to match
             spawnPos = platform.Position - Vector3.new(0, 20, 0) -- Guessing lowered state
        end
    else
        -- Fallback circle
        local angle = (platformIndex/24) * math.pi * 2
        local x = math.cos(angle) * 45
        local z = math.sin(angle) * 45
        spawnPos = Vector3.new(x, -20, z) -- Underground
    end
    
    character:SetPrimaryPartCFrame(CFrame.new(spawnPos, Vector3.new(0, spawnPos.Y, 0))) -- Look at center
    
    -- Freeze initially (Anchored)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = true end
    
    -- Tag bot for CharacterSpawner to find
    character:SetAttribute("PlatformIndex", platformIndex)
    
    character.Parent = workspace
    
    BotController.bots[botId] = botData
    
    print("[BotController] Created bot: " .. botName .. " (District " .. botData.district .. ")")
    
    BotController:startBotAI(botData)
    
    return botData
end

-- Start bot AI behavior
function BotController:startBotAI(botData)
    task.spawn(function()
        -- Initial delay - bots don't act immediately
        task.wait(math.random(3, 8))
        
        while botData.isAlive and botData.character and botData.character.Parent do
            local humanoid = botData.character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                BotController:eliminateBot(botData)
                break
            end
            
            BotController:updateBotBehavior(botData)
            
            -- Wait based on reaction time (slower = more natural)
            task.wait(botData.difficulty.reactionTime + math.random() * 0.5)
        end
    end)
end

-- Update bot behavior
function BotController:updateBotBehavior(botData)
    local character = botData.character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end
    
    -- Low health? Consider fleeing
    if humanoid.Health < 30 and math.random() < 0.6 then
        botData.state = "fleeing"
        BotController:flee(botData)
        return
    end
    
    -- Find nearest target
    local nearestTarget, nearestDistance = BotController:findNearestTarget(botData)
    
    -- Only detect targets within detection range
    local detectionRange = botData.difficulty.detectionRange
    
    if nearestTarget and nearestDistance < detectionRange then
        -- Target in range - maybe hunt?
        if botData.state ~= "hunting" and math.random() < botData.difficulty.aggressiveness then
            botData.state = "hunting"
            botData.target = nearestTarget
        elseif botData.state == "hunting" then
            -- Continue hunting
            botData.target = nearestTarget
        end
    else
        -- No target in range, roam
        if botData.state ~= "roaming" or tick() - botData.lastAction > 8 then
            botData.state = "roaming"
            botData.lastAction = tick()
        end
    end
    
    -- Execute behavior
    if botData.state == "hunting" and botData.target then
        BotController:huntTarget(botData)
    elseif botData.state == "roaming" then
        BotController:roamAround(botData)
    elseif botData.state == "fleeing" then
        BotController:flee(botData)
    else
        -- Idle - sometimes start roaming
        if math.random() < 0.2 then
            botData.state = "roaming"
        end
    end
end

-- Release bots (start of match)
function BotController:unfreezeBots()
    print("[BotController] Releasing bots!")
    for _, bot in pairs(BotController.bots) do
        if bot.character then
            local hrp = bot.character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
            
            -- Also set lastAction to now so they don't instant-react
            bot.lastAction = tick()
        end
    end
end

-- Find nearest target
function BotController:findNearestTarget(botData)
    local myHrp = botData.character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil, math.huge end
    
    local nearestTarget = nil
    local nearestDistance = math.huge
    
    -- Check real players
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = player.Character:FindFirstChild("Humanoid")
            
            if targetHrp and targetHumanoid and targetHumanoid.Health > 0 then
                local distance = (targetHrp.Position - myHrp.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestTarget = player.Character
                end
            end
        end
    end
    
    -- Check other bots
    for id, otherBot in pairs(BotController.bots) do
        if otherBot.id ~= botData.id and otherBot.isAlive and otherBot.character then
            local targetHrp = otherBot.character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = otherBot.character:FindFirstChild("Humanoid")
            
            if targetHrp and targetHumanoid and targetHumanoid.Health > 0 then
                local distance = (targetHrp.Position - myHrp.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestTarget = otherBot.character
                end
            end
        end
    end
    
    return nearestTarget, nearestDistance
end

-- Hunt a target
function BotController:huntTarget(botData)
    local humanoid = botData.character:FindFirstChild("Humanoid")
    local myHrp = botData.character:FindFirstChild("HumanoidRootPart")
    local target = botData.target
    
    if not humanoid or not myHrp or not target then
        botData.state = "roaming"
        return
    end
    
    local targetHrp = target:FindFirstChild("HumanoidRootPart")
    if not targetHrp then
        botData.target = nil
        botData.state = "roaming"
        return
    end
    
    local distance = (targetHrp.Position - myHrp.Position).Magnitude
    
    -- Attack range is 5 studs
    if distance < 5 then
        -- Check attack cooldown
        local now = tick()
        if now - botData.lastAttack >= botData.difficulty.attackCooldown then
            BotController:attackTarget(botData, target)
            botData.lastAttack = now
        end
    elseif distance < 50 then
        -- Chase target (but not too fast)
        humanoid:MoveTo(targetHrp.Position)
    else
        -- Lost target, go back to roaming
        botData.target = nil
        botData.state = "roaming"
    end
end

-- Attack a target with visual feedback
function BotController:attackTarget(botData, target)
    local targetHumanoid = target:FindFirstChild("Humanoid")
    if not targetHumanoid or targetHumanoid.Health <= 0 then
        botData.target = nil
        botData.state = "roaming"
        return
    end
    
    -- Visual attack animation (swing weapon)
    local rightArm = botData.character:FindFirstChild("Right Arm")
    if rightArm then
        local shoulder = rightArm:FindFirstChild("Right Shoulder") or botData.character.Torso:FindFirstChild("Right Shoulder")
        if shoulder then
            -- Quick swing animation
            task.spawn(function()
                local original = shoulder.C0
                local swingCFrame = original * CFrame.Angles(math.rad(-90), 0, 0)
                shoulder.C0 = swingCFrame
                task.wait(0.3)
                shoulder.C0 = original
            end)
        end
    end
    
    -- Check accuracy - roll to see if we hit
    if math.random() < botData.difficulty.accuracy then
        local damage = math.random(5, 10) -- Reduced damage (was 8-15)
        targetHumanoid:TakeDamage(damage)
        
        -- Check if we killed the target
        if targetHumanoid.Health <= 0 then
            print("[BotController] " .. botData.name .. " eliminated " .. target.Name)
            botData.target = nil
            botData.state = "roaming"
            
            -- If target was a bot, mark it as eliminated
            for id, otherBot in pairs(BotController.bots) do
                if otherBot.character == target then
                    BotController:eliminateBot(otherBot)
                    break
                end
            end
        end
    end
end

-- Roam around the arena
function BotController:roamAround(botData)
    local humanoid = botData.character:FindFirstChild("Humanoid")
    local hrp = botData.character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    -- Pick a nearby random destination (not too far)
    local destination = hrp.Position + Vector3.new(
        math.random(-50, 50),
        0,
        math.random(-50, 50)
    )
    
    humanoid:MoveTo(destination)
    botData.lastAction = tick()
end

-- Flee from danger
function BotController:flee(botData)
    local humanoid = botData.character:FindFirstChild("Humanoid")
    local hrp = botData.character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    -- Run in opposite direction of threat
    if botData.target then
        local targetHrp = botData.target:FindFirstChild("HumanoidRootPart")
        if targetHrp then
            local fleeDirection = (hrp.Position - targetHrp.Position).Unit
            local fleeDestination = hrp.Position + fleeDirection * 80
            humanoid:MoveTo(fleeDestination)
            humanoid.WalkSpeed = botData.difficulty.speed + 4 -- Sprint away
        end
    else
        -- Random flee if no specific target
        local fleeDestination = hrp.Position + Vector3.new(math.random(-60, 60), 0, math.random(-60, 60))
        humanoid:MoveTo(fleeDestination)
    end
    
    -- After fleeing, reset state
    task.delay(5, function()
        if botData.isAlive then
            botData.state = "roaming"
            botData.target = nil
            local hum = botData.character and botData.character:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = botData.difficulty.speed
            end
        end
    end)
end

-- Eliminate a bot
function BotController:eliminateBot(botData)
    if not botData.isAlive then return end
    
    botData.isAlive = false
    botData.state = "eliminated"
    
    print("[BotController] Bot eliminated: " .. botData.name)
    
    -- Destroy character after delay
    if botData.character then
        task.delay(5, function()
            if botData.character and botData.character.Parent then
                botData.character:Destroy()
            end
        end)
    end
    
    -- Notify match service
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        -- We calculate remaining including players, but this event is just a visual feed update usually
        -- The REAL logic handles victory below
        local remaining = BotController:getAliveCount() + #Players:GetPlayers()
        matchRemote:FireAllClients("TRIBUTE_ELIMINATED", {
            name = botData.name,
            remaining = remaining
        })
    end
    
    -- IMPORTANT: Tell MatchService to check for win condition!
    local MatchService = require(script.Parent.MatchService)
    if MatchService then
        MatchService:checkVictoryCondition()
    end
end

-- Get count of alive bots
function BotController:getAliveCount()
    local count = 0
    for _, bot in pairs(BotController.bots) do
        if bot.isAlive then
            count = count + 1
        end
    end
    return count
end

-- Fill empty player slots with bots
function BotController:fillWithBots(targetCount)
    local currentPlayers = #Players:GetPlayers()
    local botsNeeded = targetCount - currentPlayers
    
    if botsNeeded <= 0 then
        print("[BotController] No bots needed, have " .. currentPlayers .. " players")
        return
    end
    
    botsNeeded = math.min(botsNeeded, BotController.maxBots)
    
    print("[BotController] Spawning " .. botsNeeded .. " bots to fill match...")
    
    -- Mostly EASY bots now for better gameplay
    for i = 1, botsNeeded do
        local difficulty
        local roll = math.random()
        if roll < 0.6 then
            difficulty = DIFFICULTY.EASY  -- 60% easy
        elseif roll < 0.9 then
            difficulty = DIFFICULTY.MEDIUM -- 30% medium
        else
            difficulty = DIFFICULTY.HARD  -- 10% hard
        end
        
        local district = ((i - 1) % 12) + 1
        BotController:createBot(district, difficulty)
        
        task.wait(0.2) -- Stagger spawns more
    end
    
    BotController.isActive = true
    print("[BotController] Spawned " .. botsNeeded .. " bots!")
end

-- Remove all bots
function BotController:removeAllBots()
    for id, bot in pairs(BotController.bots) do
        bot.isAlive = false
        if bot.character and bot.character.Parent then
            bot.character:Destroy()
        end
    end
    
    BotController.bots = {}
    BotController.botCount = 0
    BotController.isActive = false
    
    print("[BotController] All bots removed")
end

-- Initialize
function BotController.init()
    print("[BotController] Initializing...")
    print("[BotController] Initialized!")
end

return BotController
