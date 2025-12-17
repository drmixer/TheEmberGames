-- ModuleScript: PerformanceOptimizer.lua (Server)
-- Performance optimizations for 24-player matches
-- Handles LOD, network throttling, and object pooling

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local PerformanceOptimizer = {}
PerformanceOptimizer.enabled = true
PerformanceOptimizer.objectPools = {}
PerformanceOptimizer.updateThrottles = {}
PerformanceOptimizer.networkQueue = {}

-- ============ CONFIGURATION ============

local CONFIG = {
    -- Network optimization
    NETWORK_UPDATE_RATE = 1/20,          -- 20 updates per second max
    BATCH_REMOTE_EVENTS = true,           -- Batch multiple events together
    MAX_EVENTS_PER_BATCH = 10,           -- Max events in a single batch
    
    -- Object pooling
    POOL_PROJECTILES = true,
    MAX_PROJECTILES = 50,
    POOL_PARTICLES = true,
    MAX_PARTICLES = 100,
    
    -- LOD (Level of Detail)
    LOD_DISTANCE_NEAR = 100,
    LOD_DISTANCE_MED = 250,
    LOD_DISTANCE_FAR = 500,
    
    -- Update throttling
    STATS_UPDATE_RATE = 0.5,              -- Update stats every 0.5s instead of every frame
    HAZARD_CHECK_RATE = 0.25,             -- Check hazard collisions every 0.25s
    STORM_CHECK_RATE = 1.0,               -- Check storm damage every 1s
    
    -- Memory management
    CLEANUP_INTERVAL = 30,                -- Clean up debris every 30 seconds
    MAX_DEBRIS_ITEMS = 100,               -- Max debris items in world
}

-- ============ OBJECT POOLING ============

function PerformanceOptimizer:createPool(poolName, template, initialSize)
    if self.objectPools[poolName] then
        return self.objectPools[poolName]
    end
    
    local pool = {
        available = {},
        inUse = {},
        template = template,
        size = 0,
        maxSize = initialSize * 2,
    }
    
    -- Pre-create objects
    for i = 1, initialSize do
        local obj = template:Clone()
        obj.Parent = nil
        table.insert(pool.available, obj)
        pool.size = pool.size + 1
    end
    
    self.objectPools[poolName] = pool
    print("[PerformanceOptimizer] Created pool '" .. poolName .. "' with " .. initialSize .. " objects")
    
    return pool
end

function PerformanceOptimizer:getFromPool(poolName)
    local pool = self.objectPools[poolName]
    if not pool then
        warn("[PerformanceOptimizer] Pool not found: " .. poolName)
        return nil
    end
    
    local obj
    if #pool.available > 0 then
        obj = table.remove(pool.available)
    elseif pool.size < pool.maxSize then
        obj = pool.template:Clone()
        pool.size = pool.size + 1
    else
        -- Pool exhausted, reuse oldest in-use object
        obj = table.remove(pool.inUse, 1)
        if obj then
            obj.Parent = nil
        end
    end
    
    if obj then
        table.insert(pool.inUse, obj)
    end
    
    return obj
end

function PerformanceOptimizer:returnToPool(poolName, obj)
    local pool = self.objectPools[poolName]
    if not pool then return end
    
    -- Remove from in-use
    for i, v in ipairs(pool.inUse) do
        if v == obj then
            table.remove(pool.inUse, i)
            break
        end
    end
    
    -- Reset and return to available
    obj.Parent = nil
    table.insert(pool.available, obj)
end

-- ============ NETWORK OPTIMIZATION ============

-- Batched remote event firing
function PerformanceOptimizer:queueRemoteEvent(remote, player, ...)
    if not CONFIG.BATCH_REMOTE_EVENTS then
        remote:FireClient(player, ...)
        return
    end
    
    local key = tostring(remote) .. "_" .. tostring(player)
    if not self.networkQueue[key] then
        self.networkQueue[key] = {
            remote = remote,
            player = player,
            events = {},
        }
    end
    
    table.insert(self.networkQueue[key].events, {...})
    
    -- If queue is full, flush immediately
    if #self.networkQueue[key].events >= CONFIG.MAX_EVENTS_PER_BATCH then
        self:flushNetworkQueue(key)
    end
end

function PerformanceOptimizer:flushNetworkQueue(key)
    local queue = self.networkQueue[key]
    if not queue or #queue.events == 0 then return end
    
    -- Send batched events
    queue.remote:FireClient(queue.player, "BATCH", queue.events)
    queue.events = {}
end

function PerformanceOptimizer:flushAllQueues()
    for key in pairs(self.networkQueue) do
        self:flushNetworkQueue(key)
    end
end

-- ============ UPDATE THROTTLING ============

function PerformanceOptimizer:shouldUpdate(key, rate)
    local now = tick()
    local lastUpdate = self.updateThrottles[key] or 0
    
    if now - lastUpdate >= rate then
        self.updateThrottles[key] = now
        return true
    end
    
    return false
end

-- Throttled stats update
function PerformanceOptimizer:throttledStatsUpdate(callback)
    if self:shouldUpdate("stats", CONFIG.STATS_UPDATE_RATE) then
        callback()
    end
end

-- Throttled hazard check
function PerformanceOptimizer:throttledHazardCheck(callback)
    if self:shouldUpdate("hazard", CONFIG.HAZARD_CHECK_RATE) then
        callback()
    end
end

-- Throttled storm check
function PerformanceOptimizer:throttledStormCheck(callback)
    if self:shouldUpdate("storm", CONFIG.STORM_CHECK_RATE) then
        callback()
    end
end

-- ============ LOD MANAGEMENT ============

function PerformanceOptimizer:updateLOD(object, viewerPosition)
    if not object or not object.Parent then return end
    
    local objectPos = object:IsA("Model") and object:GetPivot().Position or object.Position
    local distance = (objectPos - viewerPosition).Magnitude
    
    -- Adjust object detail based on distance
    if distance <= CONFIG.LOD_DISTANCE_NEAR then
        -- Full detail
        self:setObjectDetail(object, "high")
    elseif distance <= CONFIG.LOD_DISTANCE_MED then
        -- Medium detail
        self:setObjectDetail(object, "medium")
    elseif distance <= CONFIG.LOD_DISTANCE_FAR then
        -- Low detail
        self:setObjectDetail(object, "low")
    else
        -- Minimal/hidden
        self:setObjectDetail(object, "minimal")
    end
end

function PerformanceOptimizer:setObjectDetail(object, level)
    -- Apply LOD settings to object
    local transparency = 0
    local canCollide = true
    
    if level == "minimal" then
        transparency = 0.8
        canCollide = false
    elseif level == "low" then
        transparency = 0.3
    elseif level == "medium" then
        transparency = 0.1
    end
    
    if object:IsA("BasePart") then
        -- Don't change transparency for important objects
        if not object:GetAttribute("ImportantObject") then
            -- Apply settings
        end
    end
end

-- ============ MEMORY CLEANUP ============

function PerformanceOptimizer:cleanupDebris()
    local debrisFolder = workspace:FindFirstChild("Debris")
    if not debrisFolder then return end
    
    local children = debrisFolder:GetChildren()
    local count = #children
    
    if count > CONFIG.MAX_DEBRIS_ITEMS then
        -- Remove oldest items
        local toRemove = count - CONFIG.MAX_DEBRIS_ITEMS
        for i = 1, toRemove do
            if children[i] then
                children[i]:Destroy()
            end
        end
        print("[PerformanceOptimizer] Cleaned up " .. toRemove .. " debris items")
    end
end

function PerformanceOptimizer:cleanupDisconnectedPlayers()
    -- Clean up any player-related objects for disconnected players
    local validPlayers = {}
    for _, player in pairs(Players:GetPlayers()) do
        validPlayers[player.UserId] = true
    end
    
    -- Clean up player-specific data in other services
    -- This would be called by services that maintain player state
end

-- ============ FRAME BUDGET MANAGEMENT ============

local frameBudget = {
    targetFPS = 60,
    maxFrameTime = 1/60,
    currentLoad = 0,
}

function PerformanceOptimizer:startFrameTimer()
    frameBudget.frameStart = tick()
end

function PerformanceOptimizer:checkFrameBudget()
    local elapsed = tick() - (frameBudget.frameStart or tick())
    return elapsed < frameBudget.maxFrameTime * 0.8 -- Leave 20% buffer
end

function PerformanceOptimizer:endFrameTimer()
    local elapsed = tick() - (frameBudget.frameStart or tick())
    frameBudget.currentLoad = elapsed / frameBudget.maxFrameTime
end

function PerformanceOptimizer:getFrameLoad()
    return frameBudget.currentLoad
end

-- ============ SPATIAL PARTITIONING ============

-- Simple spatial hash for collision checks
local spatialGrid = {}
local GRID_SIZE = 50

function PerformanceOptimizer:positionToGridKey(position)
    local x = math.floor(position.X / GRID_SIZE)
    local z = math.floor(position.Z / GRID_SIZE)
    return x .. "_" .. z
end

function PerformanceOptimizer:registerInGrid(object, position)
    local key = self:positionToGridKey(position)
    if not spatialGrid[key] then
        spatialGrid[key] = {}
    end
    spatialGrid[key][object] = true
end

function PerformanceOptimizer:removeFromGrid(object, position)
    local key = self:positionToGridKey(position)
    if spatialGrid[key] then
        spatialGrid[key][object] = nil
    end
end

function PerformanceOptimizer:getNearbyObjects(position, radius)
    local nearby = {}
    local cellRadius = math.ceil(radius / GRID_SIZE)
    local centerKey = self:positionToGridKey(position)
    local cx = math.floor(position.X / GRID_SIZE)
    local cz = math.floor(position.Z / GRID_SIZE)
    
    for dx = -cellRadius, cellRadius do
        for dz = -cellRadius, cellRadius do
            local key = (cx + dx) .. "_" .. (cz + dz)
            if spatialGrid[key] then
                for obj in pairs(spatialGrid[key]) do
                    table.insert(nearby, obj)
                end
            end
        end
    end
    
    return nearby
end

-- ============ INITIALIZATION ============

function PerformanceOptimizer.init()
    print("[PerformanceOptimizer] Initializing...")
    
    -- Create debris folder
    local debrisFolder = workspace:FindFirstChild("Debris")
    if not debrisFolder then
        debrisFolder = Instance.new("Folder")
        debrisFolder.Name = "Debris"
        debrisFolder.Parent = workspace
    end
    
    -- Create projectile template for pooling
    if CONFIG.POOL_PROJECTILES then
        local projectileTemplate = Instance.new("Part")
        projectileTemplate.Name = "PooledProjectile"
        projectileTemplate.Size = Vector3.new(0.2, 0.2, 1.5)
        projectileTemplate.Color = Color3.fromRGB(100, 70, 40)
        projectileTemplate.Material = Enum.Material.Wood
        projectileTemplate.CanCollide = false
        projectileTemplate.Anchored = false
        
        PerformanceOptimizer:createPool("projectiles", projectileTemplate, CONFIG.MAX_PROJECTILES)
    end
    
    -- Network batch flush loop
    RunService.Heartbeat:Connect(function()
        if PerformanceOptimizer:shouldUpdate("networkFlush", CONFIG.NETWORK_UPDATE_RATE) then
            PerformanceOptimizer:flushAllQueues()
        end
    end)
    
    -- Cleanup loop
    task.spawn(function()
        while true do
            task.wait(CONFIG.CLEANUP_INTERVAL)
            PerformanceOptimizer:cleanupDebris()
            PerformanceOptimizer:cleanupDisconnectedPlayers()
        end
    end)
    
    print("[PerformanceOptimizer] Initialized - 24-player optimization active")
end

return PerformanceOptimizer
