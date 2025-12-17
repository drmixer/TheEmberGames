-- ServerScript: MatchService.lua
-- Handles match lifecycle, victory detection, and game state transitions
-- Central coordination for match start, player tracking, and victory sequence

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)

local MatchService = {}
MatchService.activePlayers = {} -- Players still alive in the match
MatchService.eliminatedPlayers = {} -- Players eliminated during the match
MatchService.matchActive = false
MatchService.matchStartTime = 0
MatchService.winner = nil
MatchService.matchStats = {}

-- RemoteEvents for client communication
local matchRemoteEvent = Instance.new("RemoteEvent")
matchRemoteEvent.Name = "MatchRemoteEvent"
matchRemoteEvent.Parent = ReplicatedStorage

-- Sound IDs (Roblox asset IDs - using placeholder IDs, replace with actual sounds)
local SOUND_IDS = {
    CANNON = "rbxassetid://1837108707", -- Cannon boom sound
    MATCH_START_HORN = "rbxassetid://1836154285", -- Horn/gong for match start
    COUNTDOWN_BEEP = "rbxassetid://138084957", -- Beep for countdown
    COUNTDOWN_FINAL = "rbxassetid://138084957", -- Final countdown beep
    VICTORY_MUSIC = "rbxassetid://1837130432", -- Victory music/fanfare
    FIREWORK = "rbxassetid://130788893", -- Firework sound
}

-- Create a sound and play it
local function playSound(soundId, volume, parent)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 1
    sound.Parent = parent or workspace
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    return sound
end

-- Play cannon sound for elimination (heard by everyone)
function MatchService:playEliminationCannon()
    -- Play cannon sound globally
    playSound(SOUND_IDS.CANNON, 1.5, workspace)
    
    -- Notify all clients to play cannon effect
    matchRemoteEvent:FireAllClients("CANNON_FIRED")
end

-- Play countdown beep sounds
function MatchService:playCountdownBeep(secondsRemaining)
    if secondsRemaining <= 10 then
        local volume = secondsRemaining <= 3 and 1.5 or 1
        playSound(SOUND_IDS.COUNTDOWN_BEEP, volume, workspace)
        matchRemoteEvent:FireAllClients("COUNTDOWN_BEEP", secondsRemaining)
    end
end

-- Play match start horn/gong
function MatchService:playMatchStartHorn()
    playSound(SOUND_IDS.MATCH_START_HORN, 2, workspace)
    matchRemoteEvent:FireAllClients("MATCH_START_HORN")
end

-- Register a player as active in the match
function MatchService:registerPlayer(player)
    if not MatchService.activePlayers[player] then
        MatchService.activePlayers[player] = {
            joinTime = tick(),
            kills = 0,
            damageDealt = 0,
            damageTaken = 0,
            itemsCollected = 0
        }
        print("[MatchService] Registered player: " .. player.Name)
    end
end

-- Get count of active players
function MatchService:getActivePlayerCount()
    local count = 0
    for player, _ in pairs(MatchService.activePlayers) do
        if player and player.Parent then
            count = count + 1
        end
    end
    return count
end

-- Get list of active players as array
function MatchService:getActivePlayers()
    local players = {}
    for player, _ in pairs(MatchService.activePlayers) do
        if player and player.Parent then
            table.insert(players, player)
        end
    end
    return players
end

-- Eliminate a player from the match
function MatchService:eliminatePlayer(player, killer)
    if not MatchService.activePlayers[player] then
        return -- Player wasn't active
    end
    
    local playerStats = MatchService.activePlayers[player]
    local survivalTime = tick() - (MatchService.matchStartTime or playerStats.joinTime)
    
    -- Record elimination
    table.insert(MatchService.eliminatedPlayers, {
        player = player,
        name = player.Name,
        userId = player.UserId,
        survivalTime = survivalTime,
        kills = playerStats.kills,
        killedBy = killer and killer.Name or "Environment",
        eliminationTime = tick()
    })
    
    -- Update killer stats
    if killer and MatchService.activePlayers[killer] then
        MatchService.activePlayers[killer].kills = MatchService.activePlayers[killer].kills + 1
    end
    
    -- Remove from active players
    MatchService.activePlayers[player] = nil
    
    print("[MatchService] Player eliminated: " .. player.Name .. " (killed by: " .. (killer and killer.Name or "Environment") .. ")")
    
    -- Play cannon sound
    MatchService:playEliminationCannon()
    
    -- Notify all clients about elimination
    matchRemoteEvent:FireAllClients("PLAYER_ELIMINATED", {
        playerName = player.Name,
        playerId = player.UserId,
        killerName = killer and killer.Name or nil,
        remainingPlayers = MatchService:getActivePlayerCount(),
        placement = #MatchService.eliminatedPlayers + MatchService:getActivePlayerCount()
    })
    
    -- Put eliminated player in spectator mode
    matchRemoteEvent:FireClient(player, "ENTER_SPECTATOR_MODE", {
        placement = MatchService:getActivePlayerCount() + 1,
        survivalTime = survivalTime,
        kills = playerStats.kills
    })
    
    -- Check for victory condition
    MatchService:checkVictoryCondition()
end

-- Check if there's a winner
function MatchService:checkVictoryCondition()
    if not MatchService.matchActive then
        return
    end
    
    local activeCount = MatchService:getActivePlayerCount()
    
    if activeCount <= 1 then
        -- We have a winner (or no players left)
        local activePlayers = MatchService:getActivePlayers()
        local winner = activePlayers[1] -- May be nil if no one left
        
        MatchService:endMatch(winner)
    elseif activeCount == 2 then
        -- Final 2 notification
        local activePlayers = MatchService:getActivePlayers()
        matchRemoteEvent:FireAllClients("FINAL_TWO", {
            player1 = activePlayers[1] and activePlayers[1].Name,
            player2 = activePlayers[2] and activePlayers[2].Name
        })
    end
end

-- Start the match
function MatchService:startMatch()
    if MatchService.matchActive then
        return
    end
    
    MatchService.matchActive = true
    MatchService.matchStartTime = tick()
    MatchService.winner = nil
    MatchService.eliminatedPlayers = {}
    MatchService.matchStats = {}
    
    -- Register all current players
    for _, player in pairs(Players:GetPlayers()) do
        MatchService:registerPlayer(player)
    end
    
    print("[MatchService] Match started with " .. MatchService:getActivePlayerCount() .. " players")
    
    -- Play match start horn
    MatchService:playMatchStartHorn()
    
    -- Notify all clients
    matchRemoteEvent:FireAllClients("MATCH_STARTED", {
        startTime = MatchService.matchStartTime,
        playerCount = MatchService:getActivePlayerCount(),
        matchDuration = Config.MATCH_LENGTH
    })
end

-- End the match with a winner
function MatchService:endMatch(winner)
    if not MatchService.matchActive then
        return
    end
    
    MatchService.matchActive = false
    MatchService.winner = winner
    
    local matchDuration = tick() - MatchService.matchStartTime
    
    -- Calculate match stats
    MatchService.matchStats = {
        winner = winner and winner.Name or "No Winner",
        winnerKills = winner and MatchService.activePlayers[winner] and MatchService.activePlayers[winner].kills or 0,
        matchDuration = matchDuration,
        totalPlayers = #MatchService.eliminatedPlayers + (winner and 1 or 0),
        eliminations = MatchService.eliminatedPlayers
    }
    
    print("[MatchService] Match ended! Winner: " .. (winner and winner.Name or "No one"))
    
    -- Trigger victory sequence
    MatchService:triggerVictorySequence(winner)
end

-- Victory sequence with celebrations
function MatchService:triggerVictorySequence(winner)
    -- Play victory music
    local victoryMusic = playSound(SOUND_IDS.VICTORY_MUSIC, 1, workspace)
    
    -- Notify all clients to show victory UI
    matchRemoteEvent:FireAllClients("VICTORY_SEQUENCE", {
        winner = winner and winner.Name or nil,
        winnerId = winner and winner.UserId or nil,
        kills = MatchService.matchStats.winnerKills,
        matchDuration = MatchService.matchStats.matchDuration,
        totalPlayers = MatchService.matchStats.totalPlayers
    })
    
    -- Create visual effects at winner's position
    if winner and winner.Character then
        local humanoidRootPart = winner.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            MatchService:createVictoryEffects(humanoidRootPart.Position)
        end
    end
    
    -- Schedule return to lobby after celebration
    task.delay(15, function()
        MatchService:returnToLobby()
    end)
end

-- Create firework/celebration effects
function MatchService:createVictoryEffects(position)
    -- Create firework particles around the winner
    for i = 1, 5 do
        task.delay(i * 0.5, function()
            -- Notify clients to create firework at position
            local offsetX = math.random(-20, 20)
            local offsetZ = math.random(-20, 20)
            local fireworkPos = position + Vector3.new(offsetX, 30, offsetZ)
            
            playSound(SOUND_IDS.FIREWORK, 0.8, workspace)
            matchRemoteEvent:FireAllClients("FIREWORK_EFFECT", fireworkPos)
        end)
    end
end

-- Return all players to lobby
function MatchService:returnToLobby()
    print("[MatchService] Returning all players to lobby...")
    
    -- Reset match state
    MatchService.activePlayers = {}
    MatchService.eliminatedPlayers = {}
    MatchService.winner = nil
    
    -- Notify all clients to return to lobby
    matchRemoteEvent:FireAllClients("RETURN_TO_LOBBY")
    
    -- Respawn all players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            -- Respawn player at lobby spawn
            player:LoadCharacter()
        end)
    end
    
    -- Notify LobbyService to start waiting for new match
    local LobbyService = require(script.Parent.LobbyService)
    LobbyService.gameState = "WaitingForPlayers"
end

-- Handle player leaving during match
local function onPlayerRemoving(player)
    if MatchService.activePlayers[player] then
        MatchService:eliminatePlayer(player, nil)
    end
end

-- Initialize MatchService
function MatchService.init()
    print("[MatchService] Initializing...")
    
    -- Connect to player removal
    Players.PlayerRemoving:Connect(onPlayerRemoving)
    
    -- Handle remote events from clients
    matchRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}
        
        if action == "REQUEST_MATCH_STATUS" then
            matchRemoteEvent:FireClient(player, "MATCH_STATUS", {
                active = MatchService.matchActive,
                startTime = MatchService.matchStartTime,
                remainingPlayers = MatchService:getActivePlayerCount(),
                isPlayerActive = MatchService.activePlayers[player] ~= nil
            })
        elseif action == "RECORD_KILL" then
            -- Record a kill for the player (called after combat system confirms kill)
            local victimId = args[1]
            local victim = Players:GetPlayerByUserId(victimId)
            if victim then
                MatchService:eliminatePlayer(victim, player)
            end
        end
    end)
    
    print("[MatchService] Initialized successfully")
end

return MatchService
