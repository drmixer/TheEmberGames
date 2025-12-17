-- ModuleScript: LeaderboardService.lua (Server)
-- Manages global leaderboards using OrderedDataStore

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardService = {}

-- DataStore references
local leaderboards = {
    wins = DataStoreService:GetOrderedDataStore("Leaderboard_Wins"),
    kills = DataStoreService:GetOrderedDataStore("Leaderboard_Kills"),
    tier = DataStoreService:GetOrderedDataStore("Leaderboard_Tier"),
}

-- Cache for leaderboard data
local cache = {}
local CACHE_DURATION = 60 -- Refresh every 60 seconds

-- Update player's score on a leaderboard
function LeaderboardService:updateScore(userId, category, value)
    local datastore = leaderboards[category]
    if not datastore then return end
    
    local success, err = pcall(function()
        datastore:SetAsync(tostring(userId), value)
    end)
    
    if not success then
        warn("[LeaderboardService] Failed to update " .. category .. ": " .. tostring(err))
    end
end

-- Get top entries for a category
function LeaderboardService:getTopEntries(category, count)
    count = count or 10
    
    -- Check cache
    local cacheKey = category .. "_" .. count
    if cache[cacheKey] and cache[cacheKey].expiry > os.time() then
        return cache[cacheKey].data
    end
    
    local datastore = leaderboards[category]
    if not datastore then return {} end
    
    local success, pages = pcall(function()
        return datastore:GetSortedAsync(false, count)
    end)
    
    if not success then
        warn("[LeaderboardService] Failed to get leaderboard: " .. tostring(pages))
        return {}
    end
    
    local entries = {}
    local currentPage = pages:GetCurrentPage()
    
    for rank, entry in ipairs(currentPage) do
        local userId = tonumber(entry.key)
        local name = "Unknown"
        
        -- Try to get player name
        local nameSuccess, playerName = pcall(function()
            return Players:GetNameFromUserIdAsync(userId)
        end)
        
        if nameSuccess then
            name = playerName
        end
        
        table.insert(entries, {
            rank = rank,
            userId = userId,
            name = name,
            value = entry.value
        })
    end
    
    -- Cache the result
    cache[cacheKey] = {
        data = entries,
        expiry = os.time() + CACHE_DURATION
    }
    
    return entries
end

-- Get player's rank in a category
function LeaderboardService:getPlayerRank(userId, category)
    local datastore = leaderboards[category]
    if not datastore then return nil end
    
    local success, rank = pcall(function()
        return datastore:GetRankAsync(tostring(userId))
    end)
    
    if success then
        return rank
    end
    return nil
end

-- Initialize
function LeaderboardService.init()
    print("[LeaderboardService] Initializing...")
    
    local leaderboardRemote = Instance.new("RemoteEvent")
    leaderboardRemote.Name = "LeaderboardRemote"
    leaderboardRemote.Parent = ReplicatedStorage
    
    leaderboardRemote.OnServerEvent:Connect(function(player, action, data)
        if action == "GET_LEADERBOARD" then
            local entries = LeaderboardService:getTopEntries(data.category, 50)
            local playerRank = LeaderboardService:getPlayerRank(player.UserId, data.category)
            
            leaderboardRemote:FireClient(player, "LEADERBOARD_DATA", {
                category = data.category,
                entries = entries,
                yourRank = playerRank
            })
        end
    end)
    
    -- Update leaderboards when players complete matches
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        matchRemote.OnServerEvent:Connect(function(player, action, data)
            if action == "MATCH_STATS_UPDATE" then
                if data.wins then
                    LeaderboardService:updateScore(player.UserId, "wins", data.wins)
                end
                if data.kills then
                    LeaderboardService:updateScore(player.UserId, "kills", data.kills)
                end
                if data.tier then
                    LeaderboardService:updateScore(player.UserId, "tier", data.tier)
                end
            end
        end)
    end
    
    print("[LeaderboardService] Initialized!")
end

return LeaderboardService
