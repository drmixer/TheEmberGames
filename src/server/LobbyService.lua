-- ServerScript: LobbyService.lua
-- Handles lobby & match start flow
-- Manages player queueing, match preparation, and game start countdown

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.shared.Config)
local EventsService = require(script.Parent.server.EventsService)

local LobbyService = {}
LobbyService.lobbyPlayers = {}
LobbyService.gameState = "WaitingForPlayers" -- WaitingForPlayers, CountingDown, InProgress
LobbyService.countdownTime = 0
LobbyService.matchStartTime = 0
LobbyService.currentMatchId = 0

-- RemoteEvents for client communication
local lobbyRemoteEvent = Instance.new("RemoteEvent")
lobbyRemoteEvent.Name = "LobbyRemoteEvent"
lobbyRemoteEvent.Parent = ReplicatedStorage

-- Player tracking
local function addPlayerToLobby(player)
    if not LobbyService.lobbyPlayers[player] then
        LobbyService.lobbyPlayers[player] = {
            joinedTime = tick(),
            districtNumber = #LobbyService.lobbyPlayers + 1,
            ready = false
        }
        
        -- Assign district number visually
        lobbyRemoteEvent:FireClient(player, "ASSIGN_DISTRICT", LobbyService.lobbyPlayers[player].districtNumber)
        
        print("Player " .. player.Name .. " joined lobby as District " .. LobbyService.lobbyPlayers[player].districtNumber)
    end
end

local function removePlayerFromLobby(player)
    if LobbyService.lobbyPlayers[player] then
        LobbyService.lobbyPlayers[player] = nil
        print("Player " .. player.Name .. " left lobby")
        
        -- Check if match should be stopped
        if LobbyService.gameState ~= "WaitingForPlayers" and #LobbyService.lobbyPlayers < Config.PLAYER_MIN then
            LobbyService:cancelMatch()
        end
    end
end

-- Start match countdown
function LobbyService:startMatchCountdown()
    if LobbyService.gameState ~= "WaitingForPlayers" then
        return
    end
    
    if #LobbyService.lobbyPlayers < Config.PLAYER_MIN then
        print("Not enough players to start match. Need " .. Config.PLAYER_MIN .. ", have " .. #LobbyService.lobbyPlayers)
        return
    end
    
    LobbyService.gameState = "Countdown"
    LobbyService.countdownTime = Config.LOBBY_TIME
    LobbyService.currentMatchId = LobbyService.currentMatchId + 1
    
    print("Starting match countdown: " .. LobbyService.countdownTime .. " seconds")
    
    -- Notify all players of countdown start
    lobbyRemoteEvent:FireAllClients("COUNTDOWN_START", LobbyService.countdownTime)
    
    -- Start countdown loop
    local countdownConnection
    countdownConnection = RunService.Heartbeat:Connect(function()
        if LobbyService.countdownTime <= 0 then
            countdownConnection:Disconnect()
            LobbyService:beginMatch()
            return
        end
        
        LobbyService.countdownTime -= 1
        
        -- Broadcast remaining time every 5 seconds and last 10 seconds
        if LobbyService.countdownTime % 5 == 0 or LobbyService.countdownTime <= 10 then
            lobbyRemoteEvent:FireAllClients("COUNTDOWN_UPDATE", LobbyService.countdownTime)
        end
    end)
end

-- Begin the match
function LobbyService:beginMatch()
    if LobbyService.gameState ~= "Countdown" then
        return
    end
    
    LobbyService.gameState = "InProgress"
    LobbyService.matchStartTime = tick()
    
    print("Match beginning with " .. #LobbyService.lobbyPlayers .. " players")
    
    -- Notify all players match is starting
    lobbyRemoteEvent:FireAllClients("MATCH_STARTING", LobbyService.currentMatchId)
    
    -- Additional setup would happen here via other services
    EventsService:initializeMatch()
end

-- Cancel the current match
function LobbyService:cancelMatch()
    if LobbyService.gameState == "Countdown" then
        LobbyService.gameState = "WaitingForPlayers"
        LobbyService.countdownTime = 0
        
        print("Match countdown cancelled")
        lobbyRemoteEvent:FireAllClients("COUNTDOWN_CANCELLED")
    end
end

-- Player joined game
local function onPlayerAdded(player)
    addPlayerToLobby(player)
    
    -- Check if we have enough players to start countdown automatically
    if LobbyService.gameState == "WaitingForPlayers" and #LobbyService.lobbyPlayers >= Config.PLAYER_MIN then
        wait(2) -- Brief delay to allow more players to join
        LobbyService:startMatchCountdown()
    end
    
    -- Handle player leaving
    player.AncestryChanged:Connect(function()
        if not player.Parent then
            removePlayerFromLobby(player)
        end
    end)
end

-- Initialize lobby service
function LobbyService.init()
    print("LobbyService initialized")
    
    -- Connect player events
    Players.PlayerAdded:Connect(onPlayerAdded)
    
    -- Add existing players
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    
    -- Handle remote events from clients
    lobbyRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        if action == "PLAYER_READY" then
            if LobbyService.lobbyPlayers[player] then
                LobbyService.lobbyPlayers[player].ready = true
                print("Player " .. player.Name .. " is ready")
                
                -- Check if all players are ready to potentially speed up countdown
                local allReady = true
                for _, lobbyPlayer in pairs(LobbyService.lobbyPlayers) do
                    if not lobbyPlayer.ready then
                        allReady = false
                        break
                    end
                end
                
                if allReady and LobbyService.gameState == "WaitingForPlayers" and #LobbyService.lobbyPlayers >= Config.PLAYER_MIN then
                    LobbyService:startMatchCountdown()
                end
            end
        elseif action == "REQUEST_STATUS" then
            -- Send current lobby status to client
            local status = {
                gameState = LobbyService.gameState,
                countdownTime = LobbyService.countdownTime,
                playerCount = #LobbyService.lobbyPlayers,
                minPlayers = Config.PLAYER_MIN,
                matchId = LobbyService.currentMatchId
            }
            lobbyRemoteEvent:FireClient(player, "LOBBY_STATUS", status)
        end
    end)
    
    print("LobbyService initialized with " .. #LobbyService.lobbyPlayers .. " players")
end

return LobbyService