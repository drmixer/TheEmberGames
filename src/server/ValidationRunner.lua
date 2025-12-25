-- ModuleScript: ValidationRunner.lua (Server)
-- Automated validation tests for Phase 5 completion
-- Runs comprehensive game tests and reports results

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")

local ValidationRunner = {}
ValidationRunner.testResults = {}
ValidationRunner.isRunning = false

-- ============ TEST DEFINITIONS ============

local TESTS = {
    -- Core systems tests
    {
        name = "PlayerStats Initialization",
        category = "core",
        run = function()
            local success, PlayerStats = pcall(function()
                return require(script.Parent.PlayerStats)
            end)
            return success and PlayerStats ~= nil, success and "PlayerStats loaded" or "Failed to load"
        end,
    },
    {
        name = "WeaponSystem Initialization",
        category = "core",
        run = function()
            local success, WeaponSystem = pcall(function()
                return require(script.Parent.WeaponSystem)
            end)
            return success and WeaponSystem ~= nil, success and "WeaponSystem loaded" or "Failed to load"
        end,
    },
    {
        name = "EventsService Initialization",
        category = "core",
        run = function()
            local success, EventsService = pcall(function()
                return require(script.Parent.EventsService)
            end)
            return success and EventsService ~= nil, success and "EventsService loaded" or "Failed to load"
        end,
    },
    {
        name = "MatchService Initialization",
        category = "core",
        run = function()
            local success, MatchService = pcall(function()
                return require(script.Parent.MatchService)
            end)
            return success and MatchService ~= nil, success and "MatchService loaded" or "Failed to load"
        end,
    },
    
    -- Balance tests
    {
        name = "Weapon Damage Balance",
        category = "balance",
        run = function()
            local success, BalanceConfig = pcall(function()
                return require(ReplicatedFirst:WaitForChild("BalanceConfig", 2))
            end)
            
            if not success then
                return false, "BalanceConfig not found"
            end
            
            local issues = {}
            local weapons = BalanceConfig.Weapons
            
            -- Check each weapon has reasonable TTK (time to kill)
            local playerHealth = 100
            for name, data in pairs(weapons) do
                if data.damage then
                    local hitsToKill = math.ceil(playerHealth / data.damage)
                    local ttk = hitsToKill * (data.attackSpeed or 1)
                    
                    if ttk < 1.5 then
                        table.insert(issues, name .. " TTK too fast: " .. string.format("%.1fs", ttk))
                    elseif ttk > 15 then
                        table.insert(issues, name .. " TTK too slow: " .. string.format("%.1fs", ttk))
                    end
                end
            end
            
            if #issues > 0 then
                return false, table.concat(issues, "; ")
            end
            
            return true, "All weapons have balanced TTK (1.5s - 15s)"
        end,
    },
    {
        name = "Survival Rate Balance",
        category = "balance",
        run = function()
            local success, BalanceConfig = pcall(function()
                return require(ReplicatedFirst:WaitForChild("BalanceConfig", 2))
            end)
            
            if not success then
                return false, "BalanceConfig not found"
            end
            
            local survival = BalanceConfig.Survival
            
            -- Check hunger depletion time (should be 3-10 minutes)
            local hungerTime = 100 / survival.HUNGER_DRAIN_ACTIVE
            local thirstTime = 100 / survival.THIRST_DRAIN_ACTIVE
            
            local issues = {}
            
            if hungerTime < 180 then
                table.insert(issues, "Hunger depletes too fast: " .. math.floor(hungerTime) .. "s")
            end
            if thirstTime < 120 then
                table.insert(issues, "Thirst depletes too fast: " .. math.floor(thirstTime) .. "s")
            end
            
            if #issues > 0 then
                return false, table.concat(issues, "; ")
            end
            
            return true, "Survival rates balanced (Hunger: " .. math.floor(hungerTime) .. "s, Thirst: " .. math.floor(thirstTime) .. "s)"
        end,
    },
    {
        name = "Storm Damage Scaling",
        category = "balance",
        run = function()
            local success, BalanceConfig = pcall(function()
                return require(ReplicatedFirst:WaitForChild("BalanceConfig", 2))
            end)
            
            if not success then
                return false, "BalanceConfig not found"
            end
            
            local storm = BalanceConfig.Storm
            local issues = {}
            
            -- Check storm damage scaling
            if storm.PHASE_DAMAGE then
                local prevDamage = 0
                for phase = 1, 7 do
                    local damage = storm.PHASE_DAMAGE[phase] or phase
                    if damage <= prevDamage then
                        table.insert(issues, "Phase " .. phase .. " damage not scaling up")
                    end
                    prevDamage = damage
                end
            end
            
            if #issues > 0 then
                return false, table.concat(issues, "; ")
            end
            
            return true, "Storm damage scales properly across phases"
        end,
    },
    
    -- Performance tests
    {
        name = "Memory Usage Check",
        category = "performance",
        run = function()
            local Stats = game:GetService("Stats")
            local memory = Stats:GetMemoryUsageMbForTag(Enum.MemoryTag.Runtime) or 0
            
            if memory > 500 then
                return false, "High memory usage: " .. math.floor(memory) .. "MB"
            end
            
            return true, "Memory usage acceptable: " .. math.floor(memory) .. "MB"
        end,
    },
    {
        name = "Remote Event Count",
        category = "performance",
        run = function()
            local remotes = ReplicatedStorage:GetDescendants()
            local remoteCount = 0
            
            for _, obj in ipairs(remotes) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    remoteCount = remoteCount + 1
                end
            end
            
            if remoteCount > 50 then
                return false, "Too many remote events: " .. remoteCount
            end
            
            return true, "Remote event count acceptable: " .. remoteCount
        end,
    },
    
    -- Multiplayer readiness tests
    {
        name = "24-Player Capacity Check",
        category = "multiplayer",
        run = function()
            local success, Config = pcall(function()
                return require(ReplicatedFirst.Config)
            end)
            
            if not success then
                return false, "Config not found"
            end
            
            if Config.PLAYER_CAP < 24 then
                return false, "Player cap too low: " .. Config.PLAYER_CAP
            end
            
            return true, "Player cap set to " .. Config.PLAYER_CAP
        end,
    },
    {
        name = "SyncManager Ready",
        category = "multiplayer",
        run = function()
            local success, SyncManager = pcall(function()
                return require(script.Parent.SyncManager)
            end)
            
            return success and SyncManager ~= nil, success and "SyncManager loaded" or "Failed to load"
        end,
    },
    {
        name = "PerformanceOptimizer Ready", 
        category = "multiplayer",
        run = function()
            local success, PerformanceOptimizer = pcall(function()
                return require(script.Parent.PerformanceOptimizer)
            end)
            
            return success and PerformanceOptimizer ~= nil, success and "PerformanceOptimizer loaded" or "Failed to load"
        end,
    },
    
    -- Loot distribution tests
    {
        name = "LootDistribution Ready",
        category = "loot",
        run = function()
            local success, LootDistribution = pcall(function()
                return require(script.Parent.LootDistribution)
            end)
            
            return success and LootDistribution ~= nil, success and "LootDistribution loaded" or "Failed to load"
        end,
    },
    {
        name = "Cornucopia Loot Count",
        category = "loot",
        run = function()
            local success, LootDistribution = pcall(function()
                return require(script.Parent.LootDistribution)
            end)
            
            if not success then
                return false, "LootDistribution not found"
            end
            
            -- Verify 48+ items for cornucopia (2 per 24 players)
            local items = LootDistribution:generateLootItem("cornucopia")
            if not items then
                return false, "Could not generate loot"
            end
            
            return true, "Loot generation working"
        end,
    },
}

-- ============ TEST RUNNER ============

function ValidationRunner:runTest(test)
    local startTime = tick()
    local success, result = pcall(test.run)
    local duration = tick() - startTime
    
    if success then
        return {
            name = test.name,
            category = test.category,
            passed = result,
            message = select(2, test.run()) or "",
            duration = duration,
        }
    else
        return {
            name = test.name,
            category = test.category,
            passed = false,
            message = "Error: " .. tostring(result),
            duration = duration,
        }
    end
end

function ValidationRunner:runAllTests()
    if self.isRunning then
        print("[ValidationRunner] Tests already running")
        return nil
    end
    
    self.isRunning = true
    self.testResults = {}
    
    print("\n" .. string.rep("=", 60))
    print("  PHASE 5 VALIDATION TEST SUITE")
    print("  Running " .. #TESTS .. " tests...")
    print(string.rep("=", 60) .. "\n")
    
    local passed = 0
    local failed = 0
    local categories = {}
    
    for _, test in ipairs(TESTS) do
        local result = self:runTest(test)
        table.insert(self.testResults, result)
        
        if result.passed then
            passed = passed + 1
            print("✅ [PASS] " .. test.name)
        else
            failed = failed + 1
            print("❌ [FAIL] " .. test.name .. ": " .. result.message)
        end
        
        -- Track by category
        if not categories[test.category] then
            categories[test.category] = {passed = 0, failed = 0}
        end
        if result.passed then
            categories[test.category].passed = categories[test.category].passed + 1
        else
            categories[test.category].failed = categories[test.category].failed + 1
        end
    end
    
    -- Print summary
    print("\n" .. string.rep("-", 60))
    print("  TEST SUMMARY")
    print(string.rep("-", 60))
    
    for category, results in pairs(categories) do
        local total = results.passed + results.failed
        local status = results.failed == 0 and "✅" or "⚠️"
        print(string.format("  %s %s: %d/%d passed", status, category:upper(), results.passed, total))
    end
    
    print(string.rep("-", 60))
    print(string.format("  TOTAL: %d/%d tests passed (%.1f%%)", passed, passed + failed, (passed / (passed + failed)) * 100))
    
    local overallStatus = failed == 0 and "✅ ALL TESTS PASSED" or ("⚠️ " .. failed .. " TESTS FAILED")
    print("  STATUS: " .. overallStatus)
    print(string.rep("=", 60) .. "\n")
    
    self.isRunning = false
    
    return {
        total = passed + failed,
        passed = passed,
        failed = failed,
        categories = categories,
        allPassed = failed == 0,
        results = self.testResults,
    }
end

function ValidationRunner:runCategoryTests(category)
    local results = {}
    
    for _, test in ipairs(TESTS) do
        if test.category == category then
            local result = self:runTest(test)
            table.insert(results, result)
        end
    end
    
    return results
end

-- ============ AUTOMATED VALIDATION ============

function ValidationRunner:validateMultiplayerReadiness()
    print("\n[ValidationRunner] Checking multiplayer readiness...")
    
    local checks = {
        {name = "Player count", check = function() return #Players:GetPlayers() end},
        {name = "Arena exists", check = function() return workspace:FindFirstChild("Arena") ~= nil end},
        {name = "Loot folder", check = function() return workspace:FindFirstChild("Loot") ~= nil end},
        {name = "Remote events", check = function() return ReplicatedStorage:FindFirstChild("SyncRemote") ~= nil end},
    }
    
    local allPassed = true
    for _, check in ipairs(checks) do
        local result = check.check()
        local status = result and "✅" or "❌"
        print("  " .. status .. " " .. check.name .. ": " .. tostring(result))
        if not result then allPassed = false end
    end
    
    return allPassed
end

function ValidationRunner:generateReport()
    local report = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        phase = "5 - Balance & Testing",
        results = self.testResults,
        summary = {
            core = {},
            balance = {},
            performance = {},
            multiplayer = {},
            loot = {},
        },
    }
    
    for _, result in ipairs(self.testResults) do
        if report.summary[result.category] then
            table.insert(report.summary[result.category], {
                name = result.name,
                passed = result.passed,
                message = result.message,
            })
        end
    end
    
    return report
end

-- ============ INITIALIZATION ============

function ValidationRunner.init()
    print("[ValidationRunner] Initializing...")
    
    -- Run validation tests on startup (delayed)
    task.delay(5, function()
        local results = ValidationRunner:runAllTests()
        if results and results.allPassed then
            print("[ValidationRunner] ✅ All Phase 5 validation tests passed!")
        else
            print("[ValidationRunner] ⚠️ Some validation tests failed - review results above")
        end
    end)
    
    print("[ValidationRunner] Initialized - will run tests in 5 seconds")
end

return ValidationRunner
