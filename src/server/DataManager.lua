-- ModuleScript: DataManager.lua (Server)
-- Handles saving and loading player data using Roblox DataStore
-- Manages season progress, unlocks, settings, and statistics

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = {}
DataManager.playerData = {}
DataManager.autoSaveInterval = 300 -- 5 minutes

-- DataStore references
local PlayerDataStore = DataStoreService:GetDataStore("EmberGames_PlayerData_v1")
local StatsDataStore = DataStoreService:GetDataStore("EmberGames_Stats_v1")

-- Default data schema
local DEFAULT_DATA = {
    -- Season progress
    season = {
        currentSeason = 1,
        tier = 0,
        xp = 0,
        totalXPEarned = 0,
    },
    
    -- Unlocked rewards
    unlocks = {
        trails = {"ember"}, -- Start with ember trail
        poses = {"triumphant", "salute"}, -- Start with basic poses
        outfits = {"default"},
        titles = {},
        banners = {},
        emotes = {"wave", "cheer"},
    },
    
    -- Equipped cosmetics
    equipped = {
        trail = "ember",
        pose = "triumphant",
        outfit = "default",
        title = "",
        banner = "",
    },
    
    -- Statistics
    stats = {
        matchesPlayed = 0,
        wins = 0,
        kills = 0,
        deaths = 0,
        totalSurvivalTime = 0,
        highestKillGame = 0,
        longestSurvival = 0,
        distanceTraveled = 0,
        itemsCrafted = 0,
        alliancesFormed = 0,
        betrayals = 0,
    },
    
    -- Challenge progress
    challenges = {
        daily = {},
        weekly = {},
        lastDailyReset = 0,
        lastWeeklyReset = 0,
    },
    
    -- Settings
    settings = {
        masterVolume = 0.8,
        musicVolume = 0.5,
        sfxVolume = 0.8,
        ambientVolume = 0.6,
        particleEffects = true,
        shadows = true,
        mouseSensitivity = 0.5,
        invertY = false,
        autoPickup = true,
        damageNumbers = true,
        screenShake = 0.7,
    },
    
    -- Tutorial completion
    tutorial = {
        completed = false,
        stepsCompleted = {},
    },
    
    -- Metadata
    firstJoin = 0,
    lastJoin = 0,
    playTime = 0,
    dataVersion = 1,
}

-- Deep copy table
local function deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Merge saved data with defaults (handles schema updates)
local function mergeWithDefaults(savedData)
    local merged = deepCopy(DEFAULT_DATA)
    
    local function mergeTable(default, saved)
        for key, value in pairs(saved) do
            if type(value) == "table" and type(default[key]) == "table" then
                mergeTable(default[key], value)
                default[key] = default[key] -- Keep merged result
            else
                default[key] = value
            end
        end
    end
    
    if savedData then
        mergeTable(merged, savedData)
    end
    
    return merged
end

-- Load player data
function DataManager:loadPlayerData(player)
    local userId = player.UserId
    local key = "Player_" .. userId
    
    local success, data = pcall(function()
        return PlayerDataStore:GetAsync(key)
    end)
    
    if success then
        if data then
            -- Merge with defaults to handle schema updates
            DataManager.playerData[userId] = mergeWithDefaults(data)
            print("[DataManager] Loaded data for " .. player.Name)
        else
            -- New player, use defaults
            DataManager.playerData[userId] = deepCopy(DEFAULT_DATA)
            DataManager.playerData[userId].firstJoin = os.time()
            print("[DataManager] Created new data for " .. player.Name)
        end
        DataManager.playerData[userId].lastJoin = os.time()
    else
        warn("[DataManager] Failed to load data for " .. player.Name .. ": " .. tostring(data))
        DataManager.playerData[userId] = deepCopy(DEFAULT_DATA)
    end
    
    return DataManager.playerData[userId]
end

-- Save player data
function DataManager:savePlayerData(player)
    local userId = player.UserId
    local data = DataManager.playerData[userId]
    
    if not data then
        warn("[DataManager] No data to save for " .. player.Name)
        return false
    end
    
    local key = "Player_" .. userId
    
    local success, err = pcall(function()
        PlayerDataStore:SetAsync(key, data)
    end)
    
    if success then
        print("[DataManager] Saved data for " .. player.Name)
        return true
    else
        warn("[DataManager] Failed to save data for " .. player.Name .. ": " .. tostring(err))
        return false
    end
end

-- Get player data
function DataManager:getData(player)
    return DataManager.playerData[player.UserId]
end

-- Update specific data field
function DataManager:updateData(player, path, value)
    local data = DataManager.playerData[player.UserId]
    if not data then return false end
    
    local parts = string.split(path, ".")
    local current = data
    
    for i = 1, #parts - 1 do
        current = current[parts[i]]
        if not current then return false end
    end
    
    current[parts[#parts]] = value
    return true
end

-- Increment stat
function DataManager:incrementStat(player, statName, amount)
    local data = DataManager.playerData[player.UserId]
    if not data or not data.stats then return end
    
    amount = amount or 1
    data.stats[statName] = (data.stats[statName] or 0) + amount
end

-- Add unlock
function DataManager:addUnlock(player, category, itemId)
    local data = DataManager.playerData[player.UserId]
    if not data or not data.unlocks[category] then return false end
    
    -- Check if already unlocked
    for _, id in ipairs(data.unlocks[category]) do
        if id == itemId then return false end
    end
    
    table.insert(data.unlocks[category], itemId)
    return true
end

-- Check if item is unlocked
function DataManager:isUnlocked(player, category, itemId)
    local data = DataManager.playerData[player.UserId]
    if not data or not data.unlocks[category] then return false end
    
    for _, id in ipairs(data.unlocks[category]) do
        if id == itemId then return true end
    end
    return false
end

-- Equip cosmetic
function DataManager:equipCosmetic(player, category, itemId)
    local data = DataManager.playerData[player.UserId]
    if not data then return false end
    
    -- Verify it's unlocked
    if not DataManager:isUnlocked(player, category .. "s", itemId) then
        return false
    end
    
    data.equipped[category] = itemId
    return true
end

-- Add XP
function DataManager:addXP(player, amount)
    local data = DataManager.playerData[player.UserId]
    if not data then return end
    
    data.season.xp = data.season.xp + amount
    data.season.totalXPEarned = data.season.totalXPEarned + amount
    
    -- Check for tier up (1000 XP per tier)
    local xpPerTier = 1000
    while data.season.xp >= xpPerTier and data.season.tier < 50 do
        data.season.xp = data.season.xp - xpPerTier
        data.season.tier = data.season.tier + 1
        
        -- Trigger tier up event
        local dataRemote = ReplicatedStorage:FindFirstChild("DataRemote")
        if dataRemote then
            dataRemote:FireClient(player, "TIER_UP", {
                tier = data.season.tier
            })
        end
    end
end

-- Initialize DataManager
function DataManager.init()
    print("[DataManager] Initializing...")
    
    -- Create remote event
    local dataRemote = Instance.new("RemoteEvent")
    dataRemote.Name = "DataRemote"
    dataRemote.Parent = ReplicatedStorage
    
    -- Handle client requests
    dataRemote.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}
        
        if action == "GET_DATA" then
            local data = DataManager:getData(player)
            if data then
                dataRemote:FireClient(player, "DATA_LOADED", data)
            end
            
        elseif action == "UPDATE_SETTINGS" then
            local settings = args[1]
            if settings then
                local data = DataManager:getData(player)
                if data then
                    for key, value in pairs(settings) do
                        data.settings[key] = value
                    end
                end
            end
            
        elseif action == "EQUIP_COSMETIC" then
            local category, itemId = args[1], args[2]
            DataManager:equipCosmetic(player, category, itemId)
        end
    end)
    
    -- Load data when player joins
    Players.PlayerAdded:Connect(function(player)
        DataManager:loadPlayerData(player)
        
        -- Send data to client
        task.delay(1, function()
            local data = DataManager:getData(player)
            if data then
                dataRemote:FireClient(player, "DATA_LOADED", data)
            end
        end)
    end)
    
    -- Save data when player leaves
    Players.PlayerRemoving:Connect(function(player)
        DataManager:savePlayerData(player)
        DataManager.playerData[player.UserId] = nil
    end)
    
    -- Auto-save loop
    task.spawn(function()
        while true do
            task.wait(DataManager.autoSaveInterval)
            for _, player in ipairs(Players:GetPlayers()) do
                DataManager:savePlayerData(player)
            end
            print("[DataManager] Auto-saved all player data")
        end
    end)
    
    -- Save all on server shutdown
    game:BindToClose(function()
        print("[DataManager] Server shutting down, saving all data...")
        for _, player in ipairs(Players:GetPlayers()) do
            DataManager:savePlayerData(player)
        end
    end)
    
    -- Load data for existing players (studio testing)
    for _, player in ipairs(Players:GetPlayers()) do
        DataManager:loadPlayerData(player)
    end
    
    print("[DataManager] Initialized successfully!")
end

return DataManager
