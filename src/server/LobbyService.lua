-- ServerScript: LobbyService.lua
-- Handles lobby & match start flow
-- Manages player queueing, match preparation, and game start countdown

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)
local EventsService = require(script.Parent.EventsService)

local LobbyService = {}
LobbyService.lobbyPlayers = {}
LobbyService.gameState = "WaitingForPlayers" -- WaitingForPlayers, CountingDown, InProgress
LobbyService.countdownTime = 0
LobbyService.matchStartTime = 0
LobbyService.currentMatchId = 0

-- Helper function to count players in dictionary
local function countLobbyPlayers()
    local count = 0
    for _ in pairs(LobbyService.lobbyPlayers) do
        count = count + 1
    end
    return count
end

-- RemoteEvents for client communication
local lobbyRemoteEvent = Instance.new("RemoteEvent")
lobbyRemoteEvent.Name = "LobbyRemoteEvent"
lobbyRemoteEvent.Parent = ReplicatedStorage

-- Player tracking
local function addPlayerToLobby(player)
    if not LobbyService.lobbyPlayers[player] then
        local districtNum = (countLobbyPlayers() % 12) + 1 -- Cycle through districts 1-12
        
        LobbyService.lobbyPlayers[player] = {
            joinedTime = tick(),
            districtNumber = districtNum,
            ready = false
        }
        
        -- Assign district number visually
        lobbyRemoteEvent:FireClient(player, "ASSIGN_DISTRICT", districtNum)
        
        -- Apply district costume when character loads
        local function applyDistrictCostume()
            local success, DistrictCostumes = pcall(function()
                return require(script.Parent.DistrictCostumes)
            end)
            
            if success and DistrictCostumes then
                DistrictCostumes:applyDistrictCostume(player, districtNum)
            end
        end
        
        -- Apply costume now if character exists
        if player.Character then
            applyDistrictCostume()
        end
        
        -- Apply costume when character spawns/respawns
        player.CharacterAdded:Connect(function(character)
            task.wait(0.5) -- Wait for character to fully load
            applyDistrictCostume()
        end)
        
        print("[LobbyService] Player " .. player.Name .. " joined lobby as District " .. districtNum)
    end
end

local function removePlayerFromLobby(player)
    if LobbyService.lobbyPlayers[player] then
        LobbyService.lobbyPlayers[player] = nil
        print("Player " .. player.Name .. " left lobby")
        
        -- Check if match should be stopped
        if LobbyService.gameState ~= "WaitingForPlayers" and countLobbyPlayers() < Config.PLAYER_MIN then
            LobbyService:cancelMatch()
        end
    end
end

-- Start match countdown
function LobbyService:startMatchCountdown()
    if LobbyService.gameState ~= "WaitingForPlayers" then
        return
    end
    
    local playerCount = countLobbyPlayers()
    if playerCount < Config.PLAYER_MIN then
        print("Not enough players to start match. Need " .. Config.PLAYER_MIN .. ", have " .. playerCount)
        return
    end
    
    LobbyService.gameState = "Countdown"
    LobbyService.countdownTime = Config.LOBBY_TIME
    LobbyService.currentMatchId = LobbyService.currentMatchId + 1
    
    print("Starting match countdown: " .. LobbyService.countdownTime .. " seconds")
    
    -- Notify all players of countdown start
    lobbyRemoteEvent:FireAllClients("COUNTDOWN_START", LobbyService.countdownTime)
    
    -- Start countdown loop (proper 1-second intervals)
    task.spawn(function()
        while LobbyService.countdownTime > 0 and LobbyService.gameState == "Countdown" do
            task.wait(1)
            LobbyService.countdownTime = LobbyService.countdownTime - 1
            
            -- Broadcast remaining time
            lobbyRemoteEvent:FireAllClients("COUNTDOWN_UPDATE", LobbyService.countdownTime)
            print("[LobbyService] Countdown: " .. LobbyService.countdownTime)
        end
        
        -- Countdown finished, begin match
        if LobbyService.gameState == "Countdown" then
            LobbyService:beginMatch()
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
    
    local playerCount = countLobbyPlayers()
    print("[LobbyService] Match beginning with " .. playerCount .. " players")
    
    -- Fill remaining slots with bots (if enabled)
    if Config.BOTS_ENABLED then
        local success, BotController = pcall(function()
            return require(script.Parent.BotController)
        end)
        
        if success and BotController then
            local targetTributes = Config.PLAYER_CAP -- Fill to max capacity (24)
            if playerCount < targetTributes then
                print("[LobbyService] Filling " .. (targetTributes - playerCount) .. " empty slots with bots...")
                BotController:fillWithBots(targetTributes)
            end
        end
    end
    
    -- Notify all players match is starting
    lobbyRemoteEvent:FireAllClients("MATCH_STARTING", LobbyService.currentMatchId)
    
    -- Start the tribute countdown (players locked on platforms)
    local CharacterSpawner = require(script.Parent.CharacterSpawner)
    CharacterSpawner:startCountdown(Config.COUNTDOWN_TIME)
    
    -- Wait for countdown to finish, then release players
    task.spawn(function()
        task.wait(Config.COUNTDOWN_TIME)
        CharacterSpawner:endCountdown()
        
        -- Initialize match events (storm, supply drops, etc.)
        EventsService:initializeMatch()
    end)
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
    if LobbyService.gameState == "WaitingForPlayers" and countLobbyPlayers() >= Config.PLAYER_MIN then
        task.wait(2) -- Brief delay to allow more players to join
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
        if action == "QUEUE_FOR_MATCH" then
            -- Player wants to start/join a match
            print("[LobbyService] " .. player.Name .. " queued for match")
            
            -- If not already in countdown, start it
            if LobbyService.gameState == "WaitingForPlayers" then
                -- Mark player as ready
                if LobbyService.lobbyPlayers[player] then
                    LobbyService.lobbyPlayers[player].ready = true
                end
                
                -- Check if we can start
                if countLobbyPlayers() >= Config.PLAYER_MIN then
                    LobbyService:startMatchCountdown()
                else
                    lobbyRemoteEvent:FireClient(player, "LOBBY_STATUS", {
                        gameState = "WaitingForPlayers",
                        message = "Waiting for " .. (Config.PLAYER_MIN - countLobbyPlayers()) .. " more players..."
                    })
                end
            elseif LobbyService.gameState == "Countdown" then
                lobbyRemoteEvent:FireClient(player, "LOBBY_STATUS", {
                    gameState = "Countdown",
                    countdownTime = LobbyService.countdownTime,
                    message = "Match starting in " .. LobbyService.countdownTime .. " seconds!"
                })
            end
            
        elseif action == "PLAYER_READY" then
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
                
                if allReady and LobbyService.gameState == "WaitingForPlayers" and countLobbyPlayers() >= Config.PLAYER_MIN then
                    LobbyService:startMatchCountdown()
                end
            end
        elseif action == "REQUEST_STATUS" then
            -- Send current lobby status to client
            local status = {
                gameState = LobbyService.gameState,
                countdownTime = LobbyService.countdownTime,
                playerCount = countLobbyPlayers(),
                minPlayers = Config.PLAYER_MIN,
                matchId = LobbyService.currentMatchId
            }
            lobbyRemoteEvent:FireClient(player, "LOBBY_STATUS", status)
        end
    end)
    
    print("LobbyService initialized with " .. countLobbyPlayers() .. " players")
end

return LobbyService