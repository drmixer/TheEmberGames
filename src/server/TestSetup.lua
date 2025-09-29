-- ServerScript: TestSetup.lua
-- Testing setup for The Ember Games MVP
-- Helps configure game state for manual testing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LobbyService = require(script.Parent.LobbyService)
local ArenaService = require(script.Parent.ArenaService)
local EventsService = require(script.Parent.EventsService)

local TestSetup = {}

-- Setup function for testing
function TestSetup:setupForTesting()
    print("Setting up The Ember Games for testing...")
    
    -- Override lobby settings to allow testing with fewer players
    local Config = require(script.Parent.shared.Config)
    Config.PLAYER_MIN = 1  -- Allow single player for testing
    
    -- Add a command to manually start the game for testing
    print("Type /startgame in chat to begin the match immediately (for testing)")
    
    -- Listen for test commands
    Players.PlayerChatted:Connect(function(player, message)
        if string.lower(message) == "/startgame" then
            print(player.Name .. " triggered immediate game start for testing")
            
            -- Add player to lobby if not already there
            if not LobbyService.lobbyPlayers[player] then
                LobbyService.lobbyPlayers[player] = {
                    joinedTime = tick(),
                    districtNumber = 1,
                    ready = true
                }
            end
            
            -- Manually start match countdown
            LobbyService:startMatchCountdown()
        elseif string.lower(message) == "/testloot" then
            print(player.Name .. " triggered loot spawn for testing")
            
            -- Spawn some test loot in the arena
            ArenaService:spawnBiomeLoot()
        elseif string.lower(message) == "/teststorm" then
            print(player.Name .. " triggered storm phase 1 for testing")
            
            -- Start storm phase 1
            EventsService:activateStormPhase(1)
        end
    end)
    
    -- Also automatically start when first player joins (for single player testing)
    Players.PlayerAdded:Connect(function(player)
        wait(3) -- Wait for player to load in
        
        if #LobbyService.lobbyPlayers == 0 then
            -- First player, add them to lobby
            LobbyService.lobbyPlayers[player] = {
                joinedTime = tick(),
                districtNumber = 1,
                ready = true
            }
            
            -- Send district assignment
            local lobbyRemoteEvent = ReplicatedStorage:WaitForChild("LobbyRemoteEvent")
            lobbyRemoteEvent:FireClient(player, "ASSIGN_DISTRICT", 1)
            
            -- Manually start countdown after a delay for testing
            wait(5)
            LobbyService:startMatchCountdown()
        end
    end)
    
    print("Test setup complete - game will auto-start with 1 player for MVP testing")
end

-- Initialize test setup
TestSetup:setupForTesting()

print("TestSetup initialized - ready for MVP testing")

-- Return the module to make it a proper module
return TestSetup