-- ModuleScript: BotController.lua
-- AI Bot system for The Ember Games
-- Spawns and controls bot tributes for solo play or player fill

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local BotController = {}
BotController.bots = {}
BotController.botCount = 0
BotController.maxBots = 23 -- Max bots to fill a 24 player game
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

-- Bot difficulty levels
local DIFFICULTY = {
    EASY = {
        reactionTime = 1.5,
        accuracy = 0.3,
        aggressiveness = 0.3,
        speed = 12,
    },
    MEDIUM = {
        reactionTime = 0.8,
        accuracy = 0.5,
        aggressiveness = 0.5,
        speed = 14,
    },
    HARD = {
        reactionTime = 0.4,
        accuracy = 0.7,
        aggressiveness = 0.7,
        speed = 16,
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
    torso.Color = Color3.fromRGB(math.random(100, 200), math.random(100, 200), math.random(100, 200))
    torso.CanCollide = true
    torso.Parent = character
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.Shape = Enum.PartType.Ball
    head.Color = Color3.fromRGB(255, 204, 153) -- Skin color
    head.CanCollide = false
    head.Parent = character
    
    -- Create face
    local face = Instance.new("Decal")
    face.Name = "face"
    face.Texture = "rbxasset://textures/face.png"
    face.Parent = head
    
    -- Left Arm
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Color = Color3.fromRGB(255, 204, 153)
    leftArm.CanCollide = false
    leftArm.Parent = character
    
    -- Right Arm
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Color = Color3.fromRGB(255, 204, 153)
    rightArm.CanCollide = false
    rightArm.Parent = character
    
    -- Left Leg
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.Color = Color3.fromRGB(100, 100, 100)
    leftLeg.CanCollide = false
    leftLeg.Parent = character
    
    -- Right Leg
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.Color = Color3.fromRGB(100, 100, 100)
    rightLeg.CanCollide = false
    rightLeg.Parent = character
    
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
    
    -- Set primary part
    character.PrimaryPart = hrp
    
    -- Bot tag
    local botTag = Instance.new("BoolValue")
    botTag.Name = "IsBot"
    botTag.Value = true
    botTag.Parent = character
    
    -- District tag
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
    local difficultyData = difficulty or DIFFICULTY.MEDIUM
    
    local botData = {
        id = botId,
        name = botName,
        district = district or math.random(1, 12),
        difficulty = difficultyData,
        state = "idle", -- idle, roaming, hunting, fleeing, looting
        target = nil,
        health = 100,
        isAlive = true,
        character = nil,
        lastAction = tick(),
        inventory = {},
    }
    
    -- Create character
    local character = createBotCharacter(botData)
    botData.character = character
    
    -- Spawn at random position in arena
    local arenaSize = Config.ARENA_SIZE / 2
    local spawnPos = Vector3.new(
        math.random(-arenaSize * 0.8, arenaSize * 0.8),
        50, -- High up to fall onto terrain
        math.random(-arenaSize * 0.8, arenaSize * 0.8)
    )
    character:SetPrimaryPartCFrame(CFrame.new(spawnPos))
    character.Parent = workspace
    
    BotController.bots[botId] = botData
    
    print("[BotController] Created bot: " .. botName .. " (District " .. botData.district .. ")")
    
    -- Start bot AI
    BotController:startBotAI(botData)
    
    return botData
end

-- Start bot AI behavior
function BotController:startBotAI(botData)
    task.spawn(function()
        while botData.isAlive and botData.character and botData.character.Parent do
            local humanoid = botData.character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                BotController:eliminateBot(botData)
                break
            end
            
            -- Update bot behavior based on state
            BotController:updateBotBehavior(botData)
            
            -- Wait based on reaction time
            task.wait(botData.difficulty.reactionTime)
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
    
    -- Find nearest player or bot
    local nearestTarget, nearestDistance = BotController:findNearestTarget(botData)
    
    -- Decide what to do based on state and situation
    if nearestTarget and nearestDistance < 30 then
        -- Close to a target
        if botData.state ~= "hunting" and math.random() < botData.difficulty.aggressiveness then
            botData.state = "hunting"
            botData.target = nearestTarget
        end
    else
        -- No nearby targets, roam
        if botData.state ~= "roaming" or tick() - botData.lastAction > 5 then
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
        -- Idle - occasionally start roaming
        if math.random() < 0.3 then
            botData.state = "roaming"
        end
    end
end

-- Find nearest target (player or other bot)
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
    
    if distance < 5 then
        -- Close enough to attack
        BotController:attackTarget(botData, target)
    else
        -- Move towards target
        humanoid:MoveTo(targetHrp.Position)
    end
end

-- Attack a target
function BotController:attackTarget(botData, target)
    local targetHumanoid = target:FindFirstChild("Humanoid")
    if not targetHumanoid or targetHumanoid.Health <= 0 then
        botData.target = nil
        botData.state = "roaming"
        return
    end
    
    -- Check accuracy - roll to see if we hit
    if math.random() < botData.difficulty.accuracy then
        local damage = math.random(8, 15)
        targetHumanoid:TakeDamage(damage)
        
        -- Notify of damage (for kill feed, etc.)
        local statsRemote = ReplicatedStorage:FindFirstChild("StatsRemoteEvent")
        if statsRemote then
            local targetPlayer = Players:GetPlayerFromCharacter(target)
            if targetPlayer then
                statsRemote:FireClient(targetPlayer, "STAT_UPDATE", "health", targetHumanoid.Health, targetHumanoid.Health + damage)
            end
        end
        
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
    
    -- Pick a random destination
    local arenaSize = Config.ARENA_SIZE / 2
    local destination = Vector3.new(
        math.random(-arenaSize * 0.7, arenaSize * 0.7),
        hrp.Position.Y,
        math.random(-arenaSize * 0.7, arenaSize * 0.7)
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
            local fleeDestination = hrp.Position + fleeDirection * 50
            humanoid:MoveTo(fleeDestination)
        end
    end
    
    -- After fleeing, reset state
    task.delay(3, function()
        if botData.isAlive then
            botData.state = "roaming"
            botData.target = nil
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
        task.delay(3, function()
            if botData.character and botData.character.Parent then
                botData.character:Destroy()
            end
        end)
    end
    
    -- Notify match service
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        local remaining = BotController:getAliveCount() + #Players:GetPlayers()
        matchRemote:FireAllClients("TRIBUTE_ELIMINATED", {
            name = botData.name,
            remaining = remaining
        })
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
    
    -- Mix of difficulties
    for i = 1, botsNeeded do
        local difficulty
        local roll = math.random()
        if roll < 0.3 then
            difficulty = DIFFICULTY.EASY
        elseif roll < 0.7 then
            difficulty = DIFFICULTY.MEDIUM
        else
            difficulty = DIFFICULTY.HARD
        end
        
        local district = ((i - 1) % 12) + 1
        BotController:createBot(district, difficulty)
        
        task.wait(0.1) -- Stagger spawns
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
    
    -- Connect to match events
    local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemoteEvent", 10)
    if lobbyRemote then
        -- When match starts, fill with bots if needed
        -- This is handled by LobbyService calling fillWithBots
    end
    
    print("[BotController] Initialized!")
end

return BotController
