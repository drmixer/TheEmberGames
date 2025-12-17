-- ModuleScript: ReplayService.lua (Server)
-- Records match events for playback
-- Stores replay data for later viewing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

local ReplayService = {}

local ReplayDataStore = DataStoreService:GetDataStore("EmberGames_Replays_v1")

-- Active recording
local currentRecording = nil
local recordingStartTime = 0

local CONFIG = {
    MAX_REPLAY_DURATION = 1800, -- 30 minutes max
    POSITION_SAMPLE_RATE = 0.2, -- Every 200ms
    MAX_STORED_REPLAYS = 5,
}

-- Event types for replay
local EVENT_TYPES = {
    MATCH_START = 1,
    MATCH_END = 2,
    PLAYER_SPAWN = 3,
    PLAYER_DEATH = 4,
    PLAYER_MOVE = 5,
    ITEM_PICKUP = 6,
    ITEM_USE = 7,
    ATTACK = 8,
    ZONE_UPDATE = 9,
    SUPPLY_DROP = 10,
    GAMEMAKER_EVENT = 11,
    ALLIANCE_FORM = 12,
    ALLIANCE_BREAK = 13,
}

-- Generate replay code
local function generateReplayCode()
    local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    local code = "R-"
    for i = 1, 8 do
        local idx = math.random(1, #chars)
        code = code .. chars:sub(idx, idx)
    end
    return code
end

-- Start recording a match
function ReplayService:startRecording(matchId, arenaVariant)
    if currentRecording then
        warn("[ReplayService] Already recording!")
        return nil
    end
    
    local replayCode = generateReplayCode()
    recordingStartTime = tick()
    
    currentRecording = {
        code = replayCode,
        matchId = matchId,
        arenaVariant = arenaVariant,
        startTime = os.time(),
        duration = 0,
        events = {},
        players = {},
        positions = {}, -- Player positions over time
        winner = nil,
    }
    
    -- Record initial player list
    for _, player in ipairs(Players:GetPlayers()) do
        currentRecording.players[tostring(player.UserId)] = {
            name = player.DisplayName,
            userId = player.UserId,
        }
    end
    
    ReplayService:recordEvent(EVENT_TYPES.MATCH_START, {
        arenaVariant = arenaVariant,
        playerCount = #Players:GetPlayers()
    })
    
    -- Start position sampling
    task.spawn(function()
        while currentRecording do
            ReplayService:samplePositions()
            task.wait(CONFIG.POSITION_SAMPLE_RATE)
            
            -- Check max duration
            local elapsed = tick() - recordingStartTime
            if elapsed > CONFIG.MAX_REPLAY_DURATION then
                ReplayService:stopRecording(nil)
                break
            end
        end
    end)
    
    print("[ReplayService] Started recording: " .. replayCode)
    return replayCode
end

-- Record an event
function ReplayService:recordEvent(eventType, data)
    if not currentRecording then return end
    
    local elapsed = tick() - recordingStartTime
    
    table.insert(currentRecording.events, {
        t = elapsed, -- Time offset
        e = eventType, -- Event type
        d = data -- Event data
    })
end

-- Sample player positions
function ReplayService:samplePositions()
    if not currentRecording then return end
    
    local elapsed = tick() - recordingStartTime
    local snapshot = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                snapshot[tostring(player.UserId)] = {
                    p = {hrp.Position.X, hrp.Position.Y, hrp.Position.Z},
                    r = hrp.Orientation.Y
                }
            end
        end
    end
    
    if next(snapshot) then
        table.insert(currentRecording.positions, {
            t = elapsed,
            s = snapshot
        })
    end
end

-- Record player death
function ReplayService:recordDeath(victim, killer, weapon)
    ReplayService:recordEvent(EVENT_TYPES.PLAYER_DEATH, {
        victim = victim.UserId,
        killer = killer and killer.UserId or nil,
        weapon = weapon
    })
end

-- Record zone update
function ReplayService:recordZoneUpdate(center, radius, shrinking)
    ReplayService:recordEvent(EVENT_TYPES.ZONE_UPDATE, {
        center = {center.X, center.Y, center.Z},
        radius = radius,
        shrinking = shrinking
    })
end

-- Stop recording
function ReplayService:stopRecording(winner)
    if not currentRecording then return nil end
    
    currentRecording.duration = tick() - recordingStartTime
    currentRecording.winner = winner and winner.UserId or nil
    
    ReplayService:recordEvent(EVENT_TYPES.MATCH_END, {
        winner = currentRecording.winner,
        duration = currentRecording.duration
    })
    
    local replayData = currentRecording
    local code = replayData.code
    currentRecording = nil
    
    -- Save to DataStore
    task.spawn(function()
        ReplayService:saveReplay(replayData)
    end)
    
    print("[ReplayService] Stopped recording: " .. code)
    return code
end

-- Save replay to DataStore
function ReplayService:saveReplay(replayData)
    local code = replayData.code
    
    -- Compress event data (convert to smaller format)
    local compressed = {
        c = code,
        a = replayData.arenaVariant,
        s = replayData.startTime,
        d = replayData.duration,
        w = replayData.winner,
        p = replayData.players,
        e = replayData.events,
        pos = replayData.positions,
    }
    
    local success, err = pcall(function()
        ReplayDataStore:SetAsync("Replay_" .. code, compressed)
    end)
    
    if success then
        print("[ReplayService] Saved replay: " .. code)
    else
        warn("[ReplayService] Failed to save replay: " .. tostring(err))
    end
end

-- Load replay from DataStore
function ReplayService:loadReplay(code)
    local success, data = pcall(function()
        return ReplayDataStore:GetAsync("Replay_" .. code)
    end)
    
    if success and data then
        return data
    end
    return nil
end

-- Get match events for a specific time
function ReplayService:getEventsAtTime(replayData, time)
    local events = {}
    for _, event in ipairs(replayData.e) do
        if event.t <= time then
            table.insert(events, event)
        end
    end
    return events
end

-- Get player positions at a specific time
function ReplayService:getPositionsAtTime(replayData, time)
    local positions = {}
    
    -- Find the closest position snapshot
    local closestSnapshot = nil
    for _, snapshot in ipairs(replayData.pos) do
        if snapshot.t <= time then
            closestSnapshot = snapshot
        else
            break
        end
    end
    
    return closestSnapshot and closestSnapshot.s or {}
end

-- Initialize
function ReplayService.init()
    print("[ReplayService] Initializing...")
    
    local replayRemote = Instance.new("RemoteEvent")
    replayRemote.Name = "ReplayRemote"
    replayRemote.Parent = ReplicatedStorage
    
    replayRemote.OnServerEvent:Connect(function(player, action, data)
        if action == "LOAD_REPLAY" then
            local replayData = ReplayService:loadReplay(data.code)
            if replayData then
                replayRemote:FireClient(player, "REPLAY_DATA", replayData)
            else
                replayRemote:FireClient(player, "REPLAY_ERROR", {error = "Replay not found"})
            end
        end
    end)
    
    print("[ReplayService] Initialized!")
end

return ReplayService
