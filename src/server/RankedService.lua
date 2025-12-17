-- ModuleScript: RankedService.lua (Server)
-- Competitive matchmaking with skill-based ranking

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RankedService = {}

local RankDataStore = DataStoreService:GetDataStore("EmberGames_RankedData_v1")

-- Rank tiers
local RANK_TIERS = {
    { name = "Bronze", icon = "🥉", minMMR = 0, maxMMR = 999 },
    { name = "Silver", icon = "🥈", minMMR = 1000, maxMMR = 1499 },
    { name = "Gold", icon = "🥇", minMMR = 1500, maxMMR = 1999 },
    { name = "Platinum", icon = "💎", minMMR = 2000, maxMMR = 2499 },
    { name = "Diamond", icon = "💠", minMMR = 2500, maxMMR = 2999 },
    { name = "Champion", icon = "👑", minMMR = 3000, maxMMR = 9999 },
}

local CONFIG = {
    STARTING_MMR = 1200,
    PLACEMENT_GAMES = 10,
    MMR_K_FACTOR = 32,
    WIN_BONUS = 25,
    TOP_5_BONUS = 10,
    KILL_BONUS = 3,
    LOSS_PENALTY = -15,
    SEASON_LENGTH_DAYS = 30,
}

-- Player ranked data cache
local playerRanks = {}

-- Get rank tier from MMR
local function getRankFromMMR(mmr)
    for i = #RANK_TIERS, 1, -1 do
        if mmr >= RANK_TIERS[i].minMMR then
            return RANK_TIERS[i]
        end
    end
    return RANK_TIERS[1]
end

-- Calculate MMR change
local function calculateMMRChange(player, placement, kills, totalPlayers)
    local change = 0
    local data = playerRanks[player.UserId]
    if not data then return 0 end
    
    -- Placement-based MMR
    local placementPercentile = 1 - (placement / totalPlayers)
    
    if placement == 1 then
        change = change + CONFIG.WIN_BONUS
    elseif placement <= 5 then
        change = change + CONFIG.TOP_5_BONUS
    elseif placement > totalPlayers / 2 then
        change = change + CONFIG.LOSS_PENALTY
    end
    
    -- Kill bonus
    change = change + (kills * CONFIG.KILL_BONUS)
    
    -- Reduce gains at higher ranks
    local currentRank = getRankFromMMR(data.mmr)
    if currentRank.minMMR >= 2500 then
        change = math.floor(change * 0.7)
    elseif currentRank.minMMR >= 2000 then
        change = math.floor(change * 0.85)
    end
    
    return change
end

-- Load player ranked data
function RankedService:loadPlayerData(player)
    local key = "Ranked_" .. player.UserId
    
    local success, data = pcall(function()
        return RankDataStore:GetAsync(key)
    end)
    
    if success and data then
        playerRanks[player.UserId] = data
    else
        -- New player
        playerRanks[player.UserId] = {
            mmr = CONFIG.STARTING_MMR,
            gamesPlayed = 0,
            wins = 0,
            kills = 0,
            placementGamesLeft = CONFIG.PLACEMENT_GAMES,
            seasonWins = 0,
            seasonKills = 0,
            peakMMR = CONFIG.STARTING_MMR,
            lastSeason = 0,
        }
    end
    
    return playerRanks[player.UserId]
end

-- Save player ranked data
function RankedService:savePlayerData(player)
    local data = playerRanks[player.UserId]
    if not data then return end
    
    local key = "Ranked_" .. player.UserId
    
    local success, err = pcall(function()
        RankDataStore:SetAsync(key, data)
    end)
    
    if not success then
        warn("[RankedService] Failed to save data: " .. tostring(err))
    end
end

-- Get player's current rank info
function RankedService:getPlayerRank(player)
    local data = playerRanks[player.UserId]
    if not data then return nil end
    
    local rank = getRankFromMMR(data.mmr)
    
    return {
        mmr = data.mmr,
        rankName = rank.name,
        rankIcon = rank.icon,
        gamesPlayed = data.gamesPlayed,
        wins = data.wins,
        placementGamesLeft = data.placementGamesLeft,
        peakMMR = data.peakMMR,
        isPlacement = data.placementGamesLeft > 0,
        progressToNext = (data.mmr - rank.minMMR) / (rank.maxMMR - rank.minMMR + 1)
    }
end

-- Update rank after match
function RankedService:updateAfterMatch(player, placement, kills, totalPlayers)
    local data = playerRanks[player.UserId]
    if not data then return end
    
    -- Calculate MMR change
    local mmrChange = calculateMMRChange(player, placement, kills, totalPlayers)
    
    -- Apply change
    data.mmr = math.max(0, data.mmr + mmrChange)
    data.gamesPlayed = data.gamesPlayed + 1
    data.kills = data.kills + kills
    data.seasonKills = data.seasonKills + kills
    
    if placement == 1 then
        data.wins = data.wins + 1
        data.seasonWins = data.seasonWins + 1
    end
    
    if data.placementGamesLeft > 0 then
        data.placementGamesLeft = data.placementGamesLeft - 1
    end
    
    if data.mmr > data.peakMMR then
        data.peakMMR = data.mmr
    end
    
    -- Notify player
    local rankedRemote = ReplicatedStorage:FindFirstChild("RankedRemote")
    if rankedRemote then
        local rankInfo = RankedService:getPlayerRank(player)
        rankedRemote:FireClient(player, "MATCH_RESULT", {
            mmrChange = mmrChange,
            newMMR = data.mmr,
            placement = placement,
            kills = kills,
            rankInfo = rankInfo
        })
    end
    
    -- Save data
    RankedService:savePlayerData(player)
end

-- Queue player for ranked match
function RankedService:queueForRanked(player)
    local data = playerRanks[player.UserId]
    if not data then return false end
    
    -- Would integrate with matchmaking system
    -- For now, just confirm queue
    local rankedRemote = ReplicatedStorage:FindFirstChild("RankedRemote")
    if rankedRemote then
        rankedRemote:FireClient(player, "QUEUED", {
            mmr = data.mmr,
            estimatedWait = 30
        })
    end
    
    return true
end

-- Initialize
function RankedService.init()
    print("[RankedService] Initializing...")
    
    local rankedRemote = Instance.new("RemoteEvent")
    rankedRemote.Name = "RankedRemote"
    rankedRemote.Parent = ReplicatedStorage
    
    rankedRemote.OnServerEvent:Connect(function(player, action, data)
        if action == "GET_RANK" then
            local rankInfo = RankedService:getPlayerRank(player)
            rankedRemote:FireClient(player, "RANK_DATA", rankInfo)
        elseif action == "QUEUE" then
            RankedService:queueForRanked(player)
        end
    end)
    
    -- Load data when players join
    Players.PlayerAdded:Connect(function(player)
        RankedService:loadPlayerData(player)
    end)
    
    -- Save data when players leave
    Players.PlayerRemoving:Connect(function(player)
        RankedService:savePlayerData(player)
        playerRanks[player.UserId] = nil
    end)
    
    -- Load existing players
    for _, player in ipairs(Players:GetPlayers()) do
        RankedService:loadPlayerData(player)
    end
    
    print("[RankedService] Initialized!")
end

return RankedService
