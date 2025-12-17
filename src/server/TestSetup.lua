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
    local ReplicatedFirst = game:GetService("ReplicatedFirst")
    local Config = require(ReplicatedFirst.Config)
    Config.PLAYER_MIN = 1  -- Allow single player for testing
    
    print("Test mode enabled - single player allowed")
    
    -- Also automatically start when first player joins (for single player testing)
    Players.PlayerAdded:Connect(function(player)
        task.wait(3) -- Wait for player to load in
        
        if next(LobbyService.lobbyPlayers) == nil then
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
            task.wait(5)
            LobbyService:startMatchCountdown()
        end
    end)
    
    print("Test setup complete - game will auto-start with 1 player for MVP testing")
end

-- Return the module (don't auto-run setupForTesting here, it's called by ServerMain)
return TestSetup