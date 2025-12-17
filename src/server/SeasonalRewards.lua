-- ModuleScript: SeasonalRewards.lua (Server)
-- Manages seasonal rewards, challenges, and progression
-- Tracks player progress across matches and awards cosmetic rewards

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local SeasonalRewards = {}
SeasonalRewards.playerProgress = {} -- In-memory cache

-- Configuration
local CONFIG = {
    CURRENT_SEASON = 1,
    SEASON_NAME = "Season of the Mockingjay",
    SEASON_END_DATE = "2025-03-01", -- Example end date
    MAX_TIER = 50,
    XP_PER_TIER = 1000,
    
    -- XP rewards for actions
    XP_REWARDS = {
        MATCH_PLAYED = 50,
        KILL = 100,
        ASSIST = 50,
        SURVIVAL_PER_MINUTE = 10,
        TOP_10 = 150,
        TOP_5 = 250,
        VICTORY = 500,
        DAILY_FIRST_MATCH = 100,
        CHALLENGE_COMPLETE = 200,
    }
}

-- Season tier rewards (what you unlock at each tier)
local TIER_REWARDS = {
    [1] = { type = "trail", id = "ember", name = "Ember Trail" },
    [3] = { type = "title", id = "tribute", name = "Title: Tribute" },
    [5] = { type = "xp_boost", id = "boost_10", name = "10% XP Boost (1 day)" },
    [7] = { type = "emote", id = "salute_gold", name = "Golden Salute Emote" },
    [10] = { type = "trail", id = "golden", name = "Victor's Gold Trail" },
    [12] = { type = "title", id = "survivor", name = "Title: Survivor" },
    [15] = { type = "banner", id = "flames", name = "Flames Banner" },
    [18] = { type = "pose", id = "defiant", name = "Defiant Victory Pose" },
    [20] = { type = "trail", id = "ice", name = "Frozen Path Trail" },
    [22] = { type = "xp_boost", id = "boost_25", name = "25% XP Boost (3 days)" },
    [25] = { type = "outfit", id = "career_tribute", name = "Career Tribute Outfit" },
    [28] = { type = "title", id = "career", name = "Title: Career" },
    [30] = { type = "trail", id = "mockingjay", name = "Mockingjay Feathers Trail" },
    [33] = { type = "banner", id = "mockingjay", name = "Mockingjay Banner" },
    [35] = { type = "pose", id = "mockingjay", name = "Mockingjay Victory Pose" },
    [38] = { type = "emote", id = "whistle_special", name = "Special Whistle Emote" },
    [40] = { type = "trail", id = "nightlock", name = "Nightlock Poison Trail" },
    [42] = { type = "title", id = "victor", name = "Title: Victor" },
    [45] = { type = "outfit", id = "gamemaker", name = "Gamemaker Outfit" },
    [48] = { type = "xp_boost", id = "boost_50", name = "50% XP Boost (7 days)" },
    [50] = { type = "legendary", id = "flames_legendary", name = "Girl on Fire Legendary Set" },
}

-- Daily/Weekly challenges
local CHALLENGE_TEMPLATES = {
    -- Daily challenges
    daily = {
        { id = "daily_play", description = "Play 3 matches", target = 3, xp = 150 },
        { id = "daily_kill", description = "Eliminate 5 tributes", target = 5, xp = 200 },
        { id = "daily_survive", description = "Survive for 10 minutes total", target = 600, xp = 175 },
        { id = "daily_loot", description = "Pick up 20 items", target = 20, xp = 125 },
        { id = "daily_craft", description = "Craft 5 items", target = 5, xp = 150 },
        { id = "daily_top5", description = "Reach top 5", target = 1, xp = 200 },
    },
    
    -- Weekly challenges
    weekly = {
        { id = "weekly_wins", description = "Win 3 matches", target = 3, xp = 500 },
        { id = "weekly_kills", description = "Eliminate 25 tributes", target = 25, xp = 600 },
        { id = "weekly_play", description = "Play 15 matches", target = 15, xp = 400 },
        { id = "weekly_alliance", description = "Win a match with an alliance", target = 1, xp = 450 },
        { id = "weekly_melee", description = "Get 10 melee eliminations", target = 10, xp = 350 },
        { id = "weekly_ranged", description = "Get 10 ranged eliminations", target = 10, xp = 350 },
    }
}

-- Create RemoteEvent
local seasonRemote = Instance.new("RemoteEvent")
seasonRemote.Name = "SeasonalRemoteEvent"
seasonRemote.Parent = ReplicatedStorage

-- Initialize player data
local function initializePlayerData(player)
    local playerId = player.UserId
    
    SeasonalRewards.playerProgress[playerId] = {
        season = CONFIG.CURRENT_SEASON,
        xp = 0,
        tier = 0,
        unlockedRewards = {},
        challenges = {
            daily = {},
            weekly = {},
            lastDailyReset = 0,
            lastWeeklyReset = 0,
        },
        stats = {
            matchesPlayed = 0,
            kills = 0,
            wins = 0,
            totalSurvivalTime = 0,
        }
    }
    
    -- Assign daily challenges
    SeasonalRewards:assignDailyChallenges(player)
    SeasonalRewards:assignWeeklyChallenges(player)
    
    return SeasonalRewards.playerProgress[playerId]
end

-- Get player progress
function SeasonalRewards:getPlayerProgress(player)
    local playerId = player.UserId
    return SeasonalRewards.playerProgress[playerId] or initializePlayerData(player)
end

-- Calculate tier from XP
local function calculateTier(xp)
    return math.min(math.floor(xp / CONFIG.XP_PER_TIER), CONFIG.MAX_TIER)
end

-- Award XP to player
function SeasonalRewards:awardXP(player, amount, reason)
    local progress = SeasonalRewards:getPlayerProgress(player)
    if not progress then return end
    
    local previousTier = progress.tier
    progress.xp = progress.xp + amount
    progress.tier = calculateTier(progress.xp)
    
    -- Check for tier ups
    if progress.tier > previousTier then
        for tier = previousTier + 1, progress.tier do
            local reward = TIER_REWARDS[tier]
            if reward then
                SeasonalRewards:unlockReward(player, reward, tier)
            end
        end
    end
    
    -- Notify player
    seasonRemote:FireClient(player, "XP_AWARDED", {
        amount = amount,
        reason = reason,
        totalXP = progress.xp,
        tier = progress.tier,
        tierProgress = (progress.xp % CONFIG.XP_PER_TIER) / CONFIG.XP_PER_TIER
    })
    
    print("[SeasonalRewards] " .. player.Name .. " earned " .. amount .. " XP (" .. reason .. ")")
end

-- Unlock a reward
function SeasonalRewards:unlockReward(player, reward, tier)
    local progress = SeasonalRewards:getPlayerProgress(player)
    if not progress then return end
    
    table.insert(progress.unlockedRewards, {
        tier = tier,
        reward = reward,
        unlockedAt = tick()
    })
    
    -- Notify player
    seasonRemote:FireClient(player, "REWARD_UNLOCKED", {
        tier = tier,
        reward = reward
    })
    
    print("[SeasonalRewards] " .. player.Name .. " unlocked tier " .. tier .. ": " .. reward.name)
end

-- Assign daily challenges
function SeasonalRewards:assignDailyChallenges(player)
    local progress = SeasonalRewards:getPlayerProgress(player)
    if not progress then return end
    
    -- Clear and assign 3 random daily challenges
    progress.challenges.daily = {}
    local availableChallenges = table.clone(CHALLENGE_TEMPLATES.daily)
    
    for i = 1, 3 do
        if #availableChallenges == 0 then break end
        local index = math.random(1, #availableChallenges)
        local challenge = availableChallenges[index]
        table.remove(availableChallenges, index)
        
        table.insert(progress.challenges.daily, {
            id = challenge.id,
            description = challenge.description,
            target = challenge.target,
            xp = challenge.xp,
            progress = 0,
            completed = false
        })
    end
    
    progress.challenges.lastDailyReset = os.time()
end

-- Assign weekly challenges
function SeasonalRewards:assignWeeklyChallenges(player)
    local progress = SeasonalRewards:getPlayerProgress(player)
    if not progress then return end
    
    -- Clear and assign 3 random weekly challenges
    progress.challenges.weekly = {}
    local availableChallenges = table.clone(CHALLENGE_TEMPLATES.weekly)
    
    for i = 1, 3 do
        if #availableChallenges == 0 then break end
        local index = math.random(1, #availableChallenges)
        local challenge = availableChallenges[index]
        table.remove(availableChallenges, index)
        
        table.insert(progress.challenges.weekly, {
            id = challenge.id,
            description = challenge.description,
            target = challenge.target,
            xp = challenge.xp,
            progress = 0,
            completed = false
        })
    end
    
    progress.challenges.lastWeeklyReset = os.time()
end

-- Update challenge progress
function SeasonalRewards:updateChallengeProgress(player, challengeType, amount)
    local progress = SeasonalRewards:getPlayerProgress(player)
    if not progress then return end
    
    -- Update daily challenges
    for _, challenge in ipairs(progress.challenges.daily) do
        if not challenge.completed and string.find(challenge.id, challengeType) then
            challenge.progress = challenge.progress + amount
            
            if challenge.progress >= challenge.target then
                challenge.completed = true
                SeasonalRewards:awardXP(player, challenge.xp, "Challenge: " .. challenge.description)
                
                seasonRemote:FireClient(player, "CHALLENGE_COMPLETED", {
                    type = "daily",
                    challenge = challenge
                })
            end
        end
    end
    
    -- Update weekly challenges
    for _, challenge in ipairs(progress.challenges.weekly) do
        if not challenge.completed and string.find(challenge.id, challengeType) then
            challenge.progress = challenge.progress + amount
            
            if challenge.progress >= challenge.target then
                challenge.completed = true
                SeasonalRewards:awardXP(player, challenge.xp, "Weekly: " .. challenge.description)
                
                seasonRemote:FireClient(player, "CHALLENGE_COMPLETED", {
                    type = "weekly",
                    challenge = challenge
                })
            end
        end
    end
end

-- Process match results
function SeasonalRewards:processMatchResults(player, matchData)
    local progress = SeasonalRewards:getPlayerProgress(player)
    if not progress then return end
    
    -- Update stats
    progress.stats.matchesPlayed = progress.stats.matchesPlayed + 1
    progress.stats.kills = progress.stats.kills + (matchData.kills or 0)
    progress.stats.totalSurvivalTime = progress.stats.totalSurvivalTime + (matchData.survivalTime or 0)
    
    -- Award XP for various achievements
    SeasonalRewards:awardXP(player, CONFIG.XP_REWARDS.MATCH_PLAYED, "Match Played")
    
    if matchData.kills and matchData.kills > 0 then
        SeasonalRewards:awardXP(player, CONFIG.XP_REWARDS.KILL * matchData.kills, matchData.kills .. " Eliminations")
    end
    
    if matchData.placement then
        if matchData.placement == 1 then
            progress.stats.wins = progress.stats.wins + 1
            SeasonalRewards:awardXP(player, CONFIG.XP_REWARDS.VICTORY, "Victory Royale!")
            SeasonalRewards:updateChallengeProgress(player, "wins", 1)
        elseif matchData.placement <= 5 then
            SeasonalRewards:awardXP(player, CONFIG.XP_REWARDS.TOP_5, "Top 5 Finish")
            SeasonalRewards:updateChallengeProgress(player, "top5", 1)
        elseif matchData.placement <= 10 then
            SeasonalRewards:awardXP(player, CONFIG.XP_REWARDS.TOP_10, "Top 10 Finish")
        end
    end
    
    -- Survival time XP
    local survivalMinutes = math.floor((matchData.survivalTime or 0) / 60)
    if survivalMinutes > 0 then
        SeasonalRewards:awardXP(player, CONFIG.XP_REWARDS.SURVIVAL_PER_MINUTE * survivalMinutes, survivalMinutes .. " Minutes Survived")
    end
    
    -- Update challenges
    SeasonalRewards:updateChallengeProgress(player, "play", 1)
    SeasonalRewards:updateChallengeProgress(player, "kill", matchData.kills or 0)
    SeasonalRewards:updateChallengeProgress(player, "survive", matchData.survivalTime or 0)
end

-- Get season info for UI
function SeasonalRewards:getSeasonInfo(player)
    local progress = SeasonalRewards:getPlayerProgress(player)
    
    return {
        seasonNumber = CONFIG.CURRENT_SEASON,
        seasonName = CONFIG.SEASON_NAME,
        seasonEndDate = CONFIG.SEASON_END_DATE,
        maxTier = CONFIG.MAX_TIER,
        xpPerTier = CONFIG.XP_PER_TIER,
        currentXP = progress.xp,
        currentTier = progress.tier,
        tierProgress = (progress.xp % CONFIG.XP_PER_TIER) / CONFIG.XP_PER_TIER,
        unlockedRewards = progress.unlockedRewards,
        challenges = progress.challenges,
        allTierRewards = TIER_REWARDS,
        stats = progress.stats
    }
end

-- Handle remote events
local function handleRemoteEvent(player, action, ...)
    local args = {...}
    
    if action == "GET_SEASON_INFO" then
        local info = SeasonalRewards:getSeasonInfo(player)
        seasonRemote:FireClient(player, "SEASON_INFO", info)
        
    elseif action == "GET_CHALLENGES" then
        local progress = SeasonalRewards:getPlayerProgress(player)
        seasonRemote:FireClient(player, "CHALLENGES", progress.challenges)
    end
end

-- Player join/leave handlers
local function onPlayerAdded(player)
    initializePlayerData(player)
    
    -- Send initial season info
    task.delay(2, function()
        local info = SeasonalRewards:getSeasonInfo(player)
        seasonRemote:FireClient(player, "SEASON_INFO", info)
    end)
end

local function onPlayerRemoving(player)
    -- Could save to DataStore here
    SeasonalRewards.playerProgress[player.UserId] = nil
end

-- Initialize SeasonalRewards
function SeasonalRewards.init()
    print("[SeasonalRewards] Initializing Season " .. CONFIG.CURRENT_SEASON .. ": " .. CONFIG.SEASON_NAME)
    
    -- Connect events
    seasonRemote.OnServerEvent:Connect(handleRemoteEvent)
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
    
    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    
    -- Connect to match events
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        -- Would connect to match end events here
    end
    
    print("[SeasonalRewards] Initialized with " .. tostring(#TIER_REWARDS) .. " tier rewards")
end

return SeasonalRewards
