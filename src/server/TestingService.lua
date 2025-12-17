-- ModuleScript: TestingService.lua (Server)
-- Comprehensive testing utilities for The Ember Games
-- Provides tools for multiplayer validation, balance testing, and performance monitoring

local Players = game:GetService(\"Players\")
local ReplicatedStorage = game:GetService(\"ReplicatedStorage\")
local RunService = game:GetService(\"RunService\")
local Stats = game:GetService(\"Stats\")

local ReplicatedFirst = game:GetService(\"ReplicatedFirst\")

local TestingService = {}
TestingService.debugMode = false
TestingService.performanceLog = {}
TestingService.testResults = {}
TestingService.bots = {}

-- Create remote event for testing commands
local testingRemote = Instance.new(\"RemoteEvent\")
testingRemote.Name = \"TestingRemote\"
testingRemote.Parent = ReplicatedStorage

-- Admin player IDs (for production, set real admin IDs)
local ADMIN_IDS = {
    -- Add admin user IDs here
}

-- ============ ADMIN VERIFICATION ============

function TestingService:isAdmin(player)
    -- In debug mode, everyone is admin
    if TestingService.debugMode then
        return true
    end
    
    for _, adminId in ipairs(ADMIN_IDS) do
        if player.UserId == adminId then
            return true
        end
    end
    
    return false
end

-- ============ DEBUG MODE CONTROLS ============

function TestingService:enableDebugMode()
    TestingService.debugMode = true
    print("[TestingService] Debug mode ENABLED - all players have admin access")
    testingRemote:FireAllClients(\"DEBUG_MODE\", true)
end

function TestingService:disableDebugMode()
    TestingService.debugMode = false
    print("[TestingService] Debug mode DISABLED")
    testingRemote:FireAllClients(\"DEBUG_MODE\", false)
end

-- ============ PLAYER MANIPULATION ============

function TestingService:setPlayerHealth(player, health)
    local success, PlayerStats = pcall(function()
        return require(script.Parent.PlayerStats)
    end)
    
    if success and PlayerStats then
        PlayerStats:updateStat(player, \"health\", health, false)
        print(\"[TestingService] Set \" .. player.Name .. \" health to \" .. health)
    end
end

function TestingService:setPlayerHunger(player, hunger)
    local success, PlayerStats = pcall(function()
        return require(script.Parent.PlayerStats)
    end)
    
    if success and PlayerStats then
        PlayerStats:updateStat(player, \"hunger\", hunger, false)
        print(\"[TestingService] Set \" .. player.Name .. \" hunger to \" .. hunger)
    end
end

function TestingService:setPlayerThirst(player, thirst)
    local success, PlayerStats = pcall(function()
        return require(script.Parent.PlayerStats)
    end)
    
    if success and PlayerStats then
        PlayerStats:updateStat(player, \"thirst\", thirst, false)
        print(\"[TestingService] Set \" .. player.Name .. \" thirst to \" .. thirst)
    end
end

function TestingService:healPlayer(player)
    TestingService:setPlayerHealth(player, 100)
    TestingService:setPlayerHunger(player, 100)
    TestingService:setPlayerThirst(player, 100)
    print(\"[TestingService] Fully healed \" .. player.Name)
end

function TestingService:giveAllWeapons(player)
    local success, WeaponSystem = pcall(function()
        return require(script.Parent.WeaponSystem)
    end)
    
    if success and WeaponSystem then
        local weapons = {\"WoodenStick\", \"SharpStick\", \"StoneKnife\", \"HandmadeAxe\", \"Machete\", \"Slingshot\", \"Bow\", \"ThrowingKnife\"}
        for _, weaponId in ipairs(weapons) do
            WeaponSystem:giveWeapon(player, weaponId)
        end
        print(\"[TestingService] Gave all weapons to \" .. player.Name)
    end
end

function TestingService:teleportPlayer(player, position)
    if player.Character then
        local hrp = player.Character:FindFirstChild(\"HumanoidRootPart\")
        if hrp then
            hrp.CFrame = CFrame.new(position)
            print(\"[TestingService] Teleported \" .. player.Name .. \" to \" .. tostring(position))
        end
    end
end

function TestingService:teleportToPlayer(player, targetPlayer)
    if player.Character and targetPlayer.Character then
        local targetHrp = targetPlayer.Character:FindFirstChild(\"HumanoidRootPart\")
        if targetHrp then
            TestingService:teleportPlayer(player, targetHrp.Position + Vector3.new(5, 0, 0))
        end
    end
end

-- ============ MATCH CONTROL ============

function TestingService:forceStartMatch()
    local success, LobbyService = pcall(function()
        return require(script.Parent.LobbyService)
    end)
    
    if success and LobbyService then
        LobbyService:startMatch()
        print(\"[TestingService] Force started match\")
    end
end

function TestingService:forceEndMatch(winner)
    local success, MatchService = pcall(function()
        return require(script.Parent.MatchService)
    end)
    
    if success and MatchService then
        MatchService:endMatch(winner)
        print(\"[TestingService] Force ended match\")
    end
end

function TestingService:skipToStormPhase(phase)
    local success, EventsService = pcall(function()
        return require(script.Parent.EventsService)
    end)
    
    if success and EventsService then
        EventsService:activateStormPhase(phase)
        print(\"[TestingService] Skipped to storm phase \" .. phase)
    end
end

function TestingService:spawnSupplyDrop()
    local success, EventsService = pcall(function()
        return require(script.Parent.EventsService)
    end)
    
    if success and EventsService then
        EventsService.supplyDropActive = false -- Force allow
        EventsService:deploySupplyDrop()
        print(\"[TestingService] Spawned supply drop\")
    end
end

function TestingService:triggerHazard(hazardType)
    local success, EventsService = pcall(function()
        return require(script.Parent.EventsService)
    end)
    
    if success and EventsService then
        EventsService:activateHazardEvent(hazardType)
        print(\"[TestingService] Triggered hazard: \" .. hazardType)
    end
end

-- ============ BOT SPAWNING (for testing) ============

function TestingService:spawnTestBot(name, district)
    -- Create a fake player-like object for testing
    local bot = {
        Name = name or (\"TestBot_\" .. #TestingService.bots + 1),
        UserId = -100 - #TestingService.bots,
        District = district or math.random(1, 12),
        isBot = true,
        Character = nil,
    }
    
    -- Create bot character
    local character = Instance.new(\"Model\")
    character.Name = bot.Name
    
    local humanoid = Instance.new(\"Humanoid\")
    humanoid.Parent = character
    
    local hrp = Instance.new(\"Part\")
    hrp.Name = \"HumanoidRootPart\"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Transparency = 0.5
    hrp.Color = Color3.fromRGB(255, 100, 100)
    hrp.Anchored = true
    hrp.CanCollide = false
    hrp.Position = Vector3.new(math.random(-200, 200), 10, math.random(-200, 200))
    hrp.Parent = character
    
    local head = Instance.new(\"Part\")
    head.Name = \"Head\"
    head.Size = Vector3.new(2, 1, 1)
    head.Position = hrp.Position + Vector3.new(0, 1.5, 0)
    head.Anchored = true
    head.CanCollide = false
    head.Parent = character
    
    character.PrimaryPart = hrp
    character.Parent = workspace
    
    bot.Character = character
    
    table.insert(TestingService.bots, bot)
    
    print(\"[TestingService] Spawned test bot: \" .. bot.Name .. \" (District \" .. bot.District .. \")\")
    
    return bot
end

function TestingService:removeAllBots()
    for _, bot in ipairs(TestingService.bots) do
        if bot.Character then
            bot.Character:Destroy()
        end
    end
    TestingService.bots = {}
    print(\"[TestingService] Removed all test bots\")
end

function TestingService:spawnFullGame()
    -- Spawn enough bots for a full game (24 players)
    local currentPlayers = #Players:GetPlayers()
    local botsNeeded = 24 - currentPlayers - #TestingService.bots
    
    for i = 1, botsNeeded do
        TestingService:spawnTestBot(nil, ((i - 1) % 12) + 1)
    end
    
    print(\"[TestingService] Spawned \" .. botsNeeded .. \" bots for full game simulation\")
end

-- ============ PERFORMANCE MONITORING ============

function TestingService:startPerformanceMonitoring()
    if TestingService.performanceConnection then
        return
    end
    
    TestingService.performanceLog = {}
    
    TestingService.performanceConnection = RunService.Heartbeat:Connect(function(dt)
        local entry = {
            time = tick(),
            fps = 1 / dt,
            playerCount = #Players:GetPlayers() + #TestingService.bots,
            memory = Stats:GetMemoryUsageMbForTag(Enum.MemoryTag.Runtime),
            heartbeatTime = dt * 1000, -- ms
        }
        
        table.insert(TestingService.performanceLog, entry)
        
        -- Keep only last 60 seconds
        while #TestingService.performanceLog > 600 do
            table.remove(TestingService.performanceLog, 1)
        end
    end)
    
    print(\"[TestingService] Started performance monitoring\")
end

function TestingService:stopPerformanceMonitoring()
    if TestingService.performanceConnection then
        TestingService.performanceConnection:Disconnect()
        TestingService.performanceConnection = nil
        print(\"[TestingService] Stopped performance monitoring\")
    end
end

function TestingService:getPerformanceReport()
    if #TestingService.performanceLog == 0 then
        return {error = \"No performance data collected\"}
    end
    
    local totalFps = 0
    local minFps = math.huge
    local maxFps = 0
    local totalHeartbeat = 0
    local maxMemory = 0
    
    for _, entry in ipairs(TestingService.performanceLog) do
        totalFps = totalFps + entry.fps
        minFps = math.min(minFps, entry.fps)
        maxFps = math.max(maxFps, entry.fps)
        totalHeartbeat = totalHeartbeat + entry.heartbeatTime
        maxMemory = math.max(maxMemory, entry.memory or 0)
    end
    
    local avgFps = totalFps / #TestingService.performanceLog
    local avgHeartbeat = totalHeartbeat / #TestingService.performanceLog
    
    local report = {
        samples = #TestingService.performanceLog,
        avgFps = math.floor(avgFps * 10) / 10,
        minFps = math.floor(minFps * 10) / 10,
        maxFps = math.floor(maxFps * 10) / 10,
        avgHeartbeat = math.floor(avgHeartbeat * 100) / 100,
        maxMemory = math.floor(maxMemory * 10) / 10,
        status = avgFps >= 55 and \"EXCELLENT\" or (avgFps >= 45 and \"GOOD\" or (avgFps >= 30 and \"ACCEPTABLE\" or \"POOR\")),
    }
    
    print(\"[TestingService] Performance Report:\")
    print(\"  Samples: \" .. report.samples)
    print(\"  Avg FPS: \" .. report.avgFps .. \" (\" .. report.status .. \")\")
    print(\"  Min FPS: \" .. report.minFps)
    print(\"  Max FPS: \" .. report.maxFps)
    print(\"  Avg Heartbeat: \" .. report.avgHeartbeat .. \"ms\")
    print(\"  Max Memory: \" .. report.maxMemory .. \"MB\")
    
    return report
end

-- ============ AUTOMATED TESTS ============

function TestingService:runBalanceTest()
    print(\"[TestingService] Running balance test...\")
    
    local results = {
        timestamp = os.date(\"%Y-%m-%d %H:%M:%S\"),
        tests = {}
    }
    
    -- Test 1: Weapon damage vs player health
    local success, BalanceConfig = pcall(function()
        return require(game:GetService(\"ReplicatedStorage\"):WaitForChild(\"shared\"):WaitForChild(\"BalanceConfig\"))
    end)
    
    if success then
        -- Calculate time-to-kill for each weapon
        local playerHealth = 100
        for weaponName, weaponData in pairs(BalanceConfig.Weapons) do
            if weaponData.damage then
                local hitsToKill = math.ceil(playerHealth / weaponData.damage)
                local timeToKill = hitsToKill * (weaponData.attackSpeed or 1)
                
                table.insert(results.tests, {
                    name = weaponName .. \" TTK\",
                    value = timeToKill,
                    unit = \"seconds\",
                    status = timeToKill >= 2 and timeToKill <= 10 and \"PASS\" or \"REVIEW\",
                })
            end
        end
        
        -- Test survival rates
        local hungerDrain = BalanceConfig.Survival.HUNGER_DRAIN_ACTIVE
        local thirstDrain = BalanceConfig.Survival.THIRST_DRAIN_ACTIVE
        
        table.insert(results.tests, {
            name = \"Hunger Depletion Time\",
            value = 100 / hungerDrain,
            unit = \"seconds\",
            status = (100 / hungerDrain) >= 180 and \"PASS\" or \"TOO_FAST\",
        })
        
        table.insert(results.tests, {
            name = \"Thirst Depletion Time\",
            value = 100 / thirstDrain,
            unit = \"seconds\",
            status = (100 / thirstDrain) >= 120 and \"PASS\" or \"TOO_FAST\",
        })
    end
    
    -- Print results
    print(\"\\n=== BALANCE TEST RESULTS ===\")
    for _, test in ipairs(results.tests) do
        print(string.format(\"  [%s] %s: %.2f %s\", test.status, test.name, test.value, test.unit))
    end
    print(\"===========================\\n\")
    
    TestingService.testResults[\"balance\"] = results
    return results
end

function TestingService:runMultiplayerTest(playerCount)
    print(\"[TestingService] Running multiplayer test with \" .. playerCount .. \" players...\")
    
    -- Spawn bots to reach target player count
    TestingService:removeAllBots()
    local currentPlayers = #Players:GetPlayers()
    local botsNeeded = playerCount - currentPlayers
    
    for i = 1, botsNeeded do
        TestingService:spawnTestBot()
        task.wait(0.1)
    end
    
    -- Start performance monitoring
    TestingService:startPerformanceMonitoring()
    
    -- Wait for 10 seconds of gameplay
    task.wait(10)
    
    -- Get performance report
    local perfReport = TestingService:getPerformanceReport()
    
    -- Stop monitoring
    TestingService:stopPerformanceMonitoring()
    
    local results = {
        playerCount = playerCount,
        actualPlayers = #Players:GetPlayers() + #TestingService.bots,
        performance = perfReport,
        status = perfReport.status,
    }
    
    TestingService.testResults[\"multiplayer_\" .. playerCount] = results
    
    print(\"[TestingService] Multiplayer test complete: \" .. results.status)
    return results
end

-- ============ INITIALIZATION ============

function TestingService.init()
    print(\"[TestingService] Initializing...\")
    
    -- Enable debug mode by default during development
    TestingService:enableDebugMode()
    
    -- Handle remote events from admin clients
    testingRemote.OnServerEvent:Connect(function(player, action, ...)
        if not TestingService:isAdmin(player) then
            warn(\"[TestingService] Unauthorized access attempt by \" .. player.Name)
            return
        end
        
        local args = {...}
        
        if action == \"HEAL\" then
            TestingService:healPlayer(args[1] or player)
        elseif action == \"GIVE_WEAPONS\" then
            TestingService:giveAllWeapons(args[1] or player)
        elseif action == \"TELEPORT\" then
            TestingService:teleportPlayer(player, args[1])
        elseif action == \"FORCE_START\" then
            TestingService:forceStartMatch()
        elseif action == \"FORCE_END\" then
            TestingService:forceEndMatch(args[1])
        elseif action == \"SKIP_STORM\" then
            TestingService:skipToStormPhase(args[1])
        elseif action == \"SPAWN_DROP\" then
            TestingService:spawnSupplyDrop()
        elseif action == \"TRIGGER_HAZARD\" then
            TestingService:triggerHazard(args[1])
        elseif action == \"SPAWN_BOTS\" then
            TestingService:spawnFullGame()
        elseif action == \"REMOVE_BOTS\" then
            TestingService:removeAllBots()
        elseif action == \"RUN_BALANCE_TEST\" then
            TestingService:runBalanceTest()
        elseif action == \"RUN_MULTIPLAYER_TEST\" then
            TestingService:runMultiplayerTest(args[1] or 24)
        elseif action == \"PERFORMANCE_REPORT\" then
            TestingService:getPerformanceReport()
        end
    end)
    
    print(\"[TestingService] Initialized successfully\")
end

return TestingService
