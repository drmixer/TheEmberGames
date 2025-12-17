-- ModuleScript: SyncManager.lua (Server)
-- Handles client-server synchronization for multiplayer matches
-- Ensures all players see consistent game state

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SyncManager = {}
SyncManager.gameState = {}
SyncManager.playerStates = {}
SyncManager.syncQueue = {}
SyncManager.lastSyncTime = 0

-- ============ CONFIGURATION ============

local CONFIG = {
    -- Sync rates
    FULL_SYNC_INTERVAL = 5.0,        -- Full state sync every 5 seconds
    DELTA_SYNC_INTERVAL = 0.1,       -- Delta updates every 100ms
    PRIORITY_SYNC_DELAY = 0.05,      -- High priority updates within 50ms
    
    -- Validation
    MAX_POSITION_DESYNC = 5,         -- Max allowed position difference in studs
    MAX_HEALTH_DESYNC = 5,           -- Max health desync before correction
    
    -- Conflict resolution
    SERVER_AUTHORITATIVE = true,     -- Server always wins conflicts
    RECONCILE_ON_DESYNC = true,      -- Force reconcile on detected desync
}

-- Create remote events
local syncRemote = Instance.new("RemoteEvent")
syncRemote.Name = "SyncRemote"
syncRemote.Parent = ReplicatedStorage

local syncFunction = Instance.new("RemoteFunction")
syncFunction.Name = "SyncFunction"
syncFunction.Parent = ReplicatedStorage

-- ============ GAME STATE MANAGEMENT ============

function SyncManager:initializeGameState()
    self.gameState = {
        matchPhase = "lobby", -- lobby, countdown, active, ended
        matchStartTime = 0,
        stormPhase = 0,
        stormRadius = 512,
        stormCenter = Vector3.new(0, 0, 0),
        eliminatedPlayers = {},
        remainingPlayers = 0,
        supplyDrops = {},
        activeHazards = {},
        timestamp = tick(),
    }
end

function SyncManager:updateGameState(key, value)
    self.gameState[key] = value
    self.gameState.timestamp = tick()
    
    -- Queue for sync
    self:queueSync("game", key, value, "normal")
end

function SyncManager:getGameState()
    return self.gameState
end

-- ============ PLAYER STATE MANAGEMENT ============

function SyncManager:initializePlayerState(player)
    self.playerStates[player.UserId] = {
        health = 100,
        hunger = 100,
        thirst = 100,
        position = Vector3.new(0, 0, 0),
        equippedWeapon = nil,
        statusEffects = {},
        kills = 0,
        isAlive = true,
        lastUpdate = tick(),
    }
end

function SyncManager:updatePlayerState(player, key, value)
    if not self.playerStates[player.UserId] then
        self:initializePlayerState(player)
    end
    
    self.playerStates[player.UserId][key] = value
    self.playerStates[player.UserId].lastUpdate = tick()
    
    -- Determine sync priority
    local priority = "normal"
    if key == "health" or key == "isAlive" then
        priority = "high"
    elseif key == "position" then
        priority = "low"
    end
    
    self:queueSync("player", {playerId = player.UserId, key = key, value = value}, value, priority)
end

function SyncManager:getPlayerState(player)
    return self.playerStates[player.UserId]
end

-- ============ SYNC QUEUE ============

function SyncManager:queueSync(category, key, value, priority)
    local syncItem = {
        category = category,
        key = key,
        value = value,
        priority = priority,
        timestamp = tick(),
    }
    
    -- Insert by priority
    if priority == "high" then
        table.insert(self.syncQueue, 1, syncItem)
    else
        table.insert(self.syncQueue, syncItem)
    end
end

function SyncManager:processSyncQueue()
    if #self.syncQueue == 0 then return end
    
    local batchSize = math.min(20, #self.syncQueue)
    local batch = {}
    
    for i = 1, batchSize do
        table.insert(batch, table.remove(self.syncQueue, 1))
    end
    
    -- Send batch to all clients
    self:broadcastSync(batch)
end

function SyncManager:broadcastSync(data)
    for _, player in pairs(Players:GetPlayers()) do
        syncRemote:FireClient(player, "SYNC_BATCH", data)
    end
end

-- ============ FULL STATE SYNC ============

function SyncManager:sendFullSync(player)
    local fullState = {
        gameState = self.gameState,
        playerStates = {},
    }
    
    -- Include all player states (sanitized)
    for userId, state in pairs(self.playerStates) do
        fullState.playerStates[userId] = {
            health = state.health,
            isAlive = state.isAlive,
            position = state.position,
            equippedWeapon = state.equippedWeapon,
            kills = state.kills,
        }
    end
    
    syncRemote:FireClient(player, "FULL_SYNC", fullState)
end

function SyncManager:broadcastFullSync()
    for _, player in pairs(Players:GetPlayers()) do
        self:sendFullSync(player)
    end
end

-- ============ DESYNC DETECTION ============

function SyncManager:checkPlayerDesync(player, clientState)
    local serverState = self.playerStates[player.UserId]
    if not serverState then return false end
    
    local issues = {}
    
    -- Check position desync
    if clientState.position and serverState.position then
        local posDiff = (clientState.position - serverState.position).Magnitude
        if posDiff > CONFIG.MAX_POSITION_DESYNC then
            table.insert(issues, {type = "position", diff = posDiff})
        end
    end
    
    -- Check health desync
    if clientState.health and serverState.health then
        local healthDiff = math.abs(clientState.health - serverState.health)
        if healthDiff > CONFIG.MAX_HEALTH_DESYNC then
            table.insert(issues, {type = "health", diff = healthDiff})
        end
    end
    
    if #issues > 0 then
        print("[SyncManager] Desync detected for " .. player.Name .. ":")
        for _, issue in ipairs(issues) do
            print("  - " .. issue.type .. ": " .. issue.diff)
        end
        
        if CONFIG.RECONCILE_ON_DESYNC then
            self:reconcilePlayer(player)
        end
        
        return true
    end
    
    return false
end

function SyncManager:reconcilePlayer(player)
    local serverState = self.playerStates[player.UserId]
    if not serverState then return end
    
    -- Send authoritative state to client
    syncRemote:FireClient(player, "RECONCILE", serverState)
    print("[SyncManager] Reconciled state for " .. player.Name)
end

-- ============ EVENT SYNCHRONIZATION ============

-- Sync elimination event
function SyncManager:syncElimination(eliminatedPlayer, killerPlayer)
    local data = {
        eliminatedId = eliminatedPlayer.UserId,
        eliminatedName = eliminatedPlayer.Name,
        killerId = killerPlayer and killerPlayer.UserId or nil,
        killerName = killerPlayer and killerPlayer.Name or nil,
        timestamp = tick(),
    }
    
    -- Update game state
    table.insert(self.gameState.eliminatedPlayers, eliminatedPlayer.UserId)
    self.gameState.remainingPlayers = self.gameState.remainingPlayers - 1
    
    -- Update player state
    if self.playerStates[eliminatedPlayer.UserId] then
        self.playerStates[eliminatedPlayer.UserId].isAlive = false
    end
    
    -- Broadcast immediately (high priority)
    for _, player in pairs(Players:GetPlayers()) do
        syncRemote:FireClient(player, "ELIMINATION", data)
    end
end

-- Sync storm phase
function SyncManager:syncStormPhase(phase, radius, center)
    self.gameState.stormPhase = phase
    self.gameState.stormRadius = radius
    self.gameState.stormCenter = center
    
    for _, player in pairs(Players:GetPlayers()) do
        syncRemote:FireClient(player, "STORM_UPDATE", {
            phase = phase,
            radius = radius,
            center = center,
        })
    end
end

-- Sync supply drop
function SyncManager:syncSupplyDrop(dropId, position, state)
    local dropData = {
        id = dropId,
        position = position,
        state = state, -- "falling", "landed", "opened", "expired"
        timestamp = tick(),
    }
    
    self.gameState.supplyDrops[dropId] = dropData
    
    for _, player in pairs(Players:GetPlayers()) do
        syncRemote:FireClient(player, "SUPPLY_DROP", dropData)
    end
end

-- Sync hazard event
function SyncManager:syncHazardEvent(hazardType, position, radius, duration, state)
    local hazardData = {
        type = hazardType,
        position = position,
        radius = radius,
        duration = duration,
        state = state, -- "starting", "active", "ending"
        startTime = tick(),
    }
    
    table.insert(self.gameState.activeHazards, hazardData)
    
    for _, player in pairs(Players:GetPlayers()) do
        syncRemote:FireClient(player, "HAZARD_EVENT", hazardData)
    end
end

-- ============ MATCH STATE SYNC ============

function SyncManager:syncMatchStart(startTime)
    self.gameState.matchPhase = "countdown"
    self.gameState.matchStartTime = startTime
    
    for _, player in pairs(Players:GetPlayers()) do
        syncRemote:FireClient(player, "MATCH_START", {startTime = startTime})
    end
end

function SyncManager:syncMatchActive()
    self.gameState.matchPhase = "active"
    self.gameState.remainingPlayers = #Players:GetPlayers()
    
    for _, player in pairs(Players:GetPlayers()) do
        syncRemote:FireClient(player, "MATCH_ACTIVE", {})
    end
end

function SyncManager:syncMatchEnd(winner)
    self.gameState.matchPhase = "ended"
    
    local winnerData = winner and {
        id = winner.UserId,
        name = winner.Name,
        kills = self.playerStates[winner.UserId] and self.playerStates[winner.UserId].kills or 0,
    } or nil
    
    for _, player in pairs(Players:GetPlayers()) do
        syncRemote:FireClient(player, "MATCH_END", {winner = winnerData})
    end
end

-- ============ CLIENT REQUEST HANDLING ============

local function handleSyncRequest(player, action, data)
    if action == "REQUEST_FULL_SYNC" then
        SyncManager:sendFullSync(player)
        return true
    elseif action == "REPORT_STATE" then
        -- Client reporting its state for desync check
        SyncManager:checkPlayerDesync(player, data)
        return true
    elseif action == "REQUEST_TIME" then
        return tick()
    elseif action == "GET_GAME_STATE" then
        return SyncManager.gameState
    end
    
    return false
end

-- ============ INITIALIZATION ============

function SyncManager.init()
    print("[SyncManager] Initializing...")
    
    SyncManager:initializeGameState()
    
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        SyncManager:initializePlayerState(player)
        -- Send full sync to new player after a short delay
        task.delay(1, function()
            SyncManager:sendFullSync(player)
        end)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        -- Keep state for a bit for late joiners to see elimination
        task.delay(30, function()
            SyncManager.playerStates[player.UserId] = nil
        end)
    end)
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        SyncManager:initializePlayerState(player)
    end
    
    -- Handle sync function requests
    syncFunction.OnServerInvoke = handleSyncRequest
    
    -- Handle sync remote events from clients
    syncRemote.OnServerEvent:Connect(function(player, action, data)
        handleSyncRequest(player, action, data)
    end)
    
    -- Sync loop
    RunService.Heartbeat:Connect(function()
        -- Process sync queue
        SyncManager:processSyncQueue()
    end)
    
    -- Periodic full sync
    task.spawn(function()
        while true do
            task.wait(CONFIG.FULL_SYNC_INTERVAL)
            SyncManager:broadcastFullSync()
        end
    end)
    
    print("[SyncManager] Initialized - multiplayer sync active")
end

return SyncManager
