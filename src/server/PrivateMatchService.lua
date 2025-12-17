-- ModuleScript: PrivateMatchService.lua (Server)
-- Manages custom private games with codes

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrivateMatchService = {}
PrivateMatchService.lobbies = {} -- code -> lobby data
PrivateMatchService.playerLobbies = {} -- userId -> code

local CONFIG = {
    MIN_PLAYERS = 2,
    MAX_PLAYERS = 24,
    DEFAULT_SETTINGS = {
        maxPlayers = 24,
        arenaVariant = "classic",
        gamemakerEvents = true,
        fillWithBots = false,
        friendlyFire = true,
        startingGear = "none",
        zoneSpeed = "normal",
    },
}

-- Generate lobby code
local function generateCode()
    local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    local code = ""
    for i = 1, 6 do
        local idx = math.random(1, #chars)
        code = code .. chars:sub(idx, idx)
    end
    return code
end

-- Broadcast lobby update
local function broadcastLobbyUpdate(code)
    local lobby = PrivateMatchService.lobbies[code]
    if not lobby then return end
    
    local privateRemote = ReplicatedStorage:FindFirstChild("PrivateMatchRemote")
    if not privateRemote then return end
    
    local playerList = {}
    for _, userId in ipairs(lobby.players) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            table.insert(playerList, {
                userId = userId,
                name = player.DisplayName,
                isHost = userId == lobby.host,
                isReady = lobby.readyPlayers[userId] or false
            })
        end
    end
    
    for _, userId in ipairs(lobby.players) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            privateRemote:FireClient(player, "LOBBY_UPDATE", {
                code = code,
                players = playerList,
                settings = lobby.settings,
                isHost = userId == lobby.host,
                canStart = PrivateMatchService:canStartMatch(code)
            })
        end
    end
end

-- Create private lobby
function PrivateMatchService:createLobby(player, password)
    -- Leave any existing lobby
    if PrivateMatchService.playerLobbies[player.UserId] then
        PrivateMatchService:leaveLobby(player)
    end
    
    local code = generateCode()
    while PrivateMatchService.lobbies[code] do
        code = generateCode()
    end
    
    PrivateMatchService.lobbies[code] = {
        host = player.UserId,
        players = {player.UserId},
        spectators = {},
        readyPlayers = {},
        settings = table.clone(CONFIG.DEFAULT_SETTINGS),
        password = password,
        createdAt = os.time(),
        status = "waiting" -- waiting, starting, ingame
    }
    
    PrivateMatchService.playerLobbies[player.UserId] = code
    
    print("[PrivateMatchService] " .. player.Name .. " created lobby: " .. code)
    
    local privateRemote = ReplicatedStorage:FindFirstChild("PrivateMatchRemote")
    if privateRemote then
        privateRemote:FireClient(player, "LOBBY_CREATED", {code = code})
    end
    
    broadcastLobbyUpdate(code)
    return code
end

-- Join lobby
function PrivateMatchService:joinLobby(player, code, password, asSpectator)
    code = string.upper(code)
    
    local lobby = PrivateMatchService.lobbies[code]
    if not lobby then
        return false, "Lobby not found"
    end
    
    if lobby.password and lobby.password ~= password then
        return false, "Invalid password"
    end
    
    if lobby.status ~= "waiting" then
        return false, "Match already in progress"
    end
    
    if not asSpectator and #lobby.players >= lobby.settings.maxPlayers then
        return false, "Lobby is full"
    end
    
    -- Leave current lobby first
    if PrivateMatchService.playerLobbies[player.UserId] then
        PrivateMatchService:leaveLobby(player)
    end
    
    if asSpectator then
        table.insert(lobby.spectators, player.UserId)
    else
        table.insert(lobby.players, player.UserId)
    end
    
    PrivateMatchService.playerLobbies[player.UserId] = code
    
    print("[PrivateMatchService] " .. player.Name .. " joined lobby: " .. code)
    
    broadcastLobbyUpdate(code)
    return true
end

-- Leave lobby
function PrivateMatchService:leaveLobby(player)
    local code = PrivateMatchService.playerLobbies[player.UserId]
    if not code then return end
    
    local lobby = PrivateMatchService.lobbies[code]
    if not lobby then return end
    
    -- Remove from players
    for i, userId in ipairs(lobby.players) do
        if userId == player.UserId then
            table.remove(lobby.players, i)
            break
        end
    end
    
    -- Remove from spectators
    for i, userId in ipairs(lobby.spectators) do
        if userId == player.UserId then
            table.remove(lobby.spectators, i)
            break
        end
    end
    
    lobby.readyPlayers[player.UserId] = nil
    PrivateMatchService.playerLobbies[player.UserId] = nil
    
    -- Notify player
    local privateRemote = ReplicatedStorage:FindFirstChild("PrivateMatchRemote")
    if privateRemote then
        privateRemote:FireClient(player, "LEFT_LOBBY", {})
    end
    
    -- If lobby is empty, delete it
    if #lobby.players == 0 and #lobby.spectators == 0 then
        PrivateMatchService.lobbies[code] = nil
        print("[PrivateMatchService] Lobby " .. code .. " disbanded")
    elseif lobby.host == player.UserId and #lobby.players > 0 then
        -- Transfer host
        lobby.host = lobby.players[1]
        broadcastLobbyUpdate(code)
    else
        broadcastLobbyUpdate(code)
    end
end

-- Update settings (host only)
function PrivateMatchService:updateSettings(player, settings)
    local code = PrivateMatchService.playerLobbies[player.UserId]
    if not code then return end
    
    local lobby = PrivateMatchService.lobbies[code]
    if not lobby or lobby.host ~= player.UserId then return end
    
    for key, value in pairs(settings) do
        if lobby.settings[key] ~= nil then
            lobby.settings[key] = value
        end
    end
    
    broadcastLobbyUpdate(code)
end

-- Toggle ready
function PrivateMatchService:toggleReady(player)
    local code = PrivateMatchService.playerLobbies[player.UserId]
    if not code then return end
    
    local lobby = PrivateMatchService.lobbies[code]
    if not lobby then return end
    
    lobby.readyPlayers[player.UserId] = not lobby.readyPlayers[player.UserId]
    
    broadcastLobbyUpdate(code)
end

-- Check if match can start
function PrivateMatchService:canStartMatch(code)
    local lobby = PrivateMatchService.lobbies[code]
    if not lobby then return false end
    
    if #lobby.players < CONFIG.MIN_PLAYERS then
        return false
    end
    
    -- Check all players ready (except host)
    for _, userId in ipairs(lobby.players) do
        if userId ~= lobby.host and not lobby.readyPlayers[userId] then
            return false
        end
    end
    
    return true
end

-- Start match (host only)
function PrivateMatchService:startMatch(player)
    local code = PrivateMatchService.playerLobbies[player.UserId]
    if not code then return false end
    
    local lobby = PrivateMatchService.lobbies[code]
    if not lobby or lobby.host ~= player.UserId then return false end
    
    if not PrivateMatchService:canStartMatch(code) then
        return false, "Not all players ready or not enough players"
    end
    
    lobby.status = "starting"
    
    -- Notify all players
    local privateRemote = ReplicatedStorage:FindFirstChild("PrivateMatchRemote")
    if privateRemote then
        for _, userId in ipairs(lobby.players) do
            local p = Players:GetPlayerByUserId(userId)
            if p then
                privateRemote:FireClient(p, "MATCH_STARTING", {
                    settings = lobby.settings
                })
            end
        end
    end
    
    -- Would trigger actual match creation here
    -- This would integrate with the main match system
    
    print("[PrivateMatchService] Starting private match: " .. code)
    return true
end

-- Initialize
function PrivateMatchService.init()
    print("[PrivateMatchService] Initializing...")
    
    local privateRemote = Instance.new("RemoteEvent")
    privateRemote.Name = "PrivateMatchRemote"
    privateRemote.Parent = ReplicatedStorage
    
    privateRemote.OnServerEvent:Connect(function(player, action, data)
        data = data or {}
        
        if action == "CREATE" then
            PrivateMatchService:createLobby(player, data.password)
        elseif action == "JOIN" then
            local success, err = PrivateMatchService:joinLobby(player, data.code, data.password, data.asSpectator)
            if not success then
                privateRemote:FireClient(player, "JOIN_ERROR", {error = err})
            end
        elseif action == "LEAVE" then
            PrivateMatchService:leaveLobby(player)
        elseif action == "UPDATE_SETTINGS" then
            PrivateMatchService:updateSettings(player, data)
        elseif action == "TOGGLE_READY" then
            PrivateMatchService:toggleReady(player)
        elseif action == "START" then
            local success, err = PrivateMatchService:startMatch(player)
            if not success then
                privateRemote:FireClient(player, "START_ERROR", {error = err})
            end
        end
    end)
    
    -- Clean up on player leave
    Players.PlayerRemoving:Connect(function(player)
        if PrivateMatchService.playerLobbies[player.UserId] then
            PrivateMatchService:leaveLobby(player)
        end
    end)
    
    print("[PrivateMatchService] Initialized!")
end

return PrivateMatchService
