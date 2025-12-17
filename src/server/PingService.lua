-- ModuleScript: PingService.lua (Server)
-- Handles ping relay between allied players

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PingService = {}

-- Get player's alliance members
local function getAllyPlayers(player)
    local allies = {}
    
    local allianceRemote = ReplicatedStorage:FindFirstChild("AllianceRemote")
    if not allianceRemote then return allies end
    
    -- This would normally query AllianceSystem, simplified here
    -- In full implementation, inject AllianceSystem dependency
    
    return allies
end

function PingService.init()
    print("[PingService] Initializing...")
    
    local pingRemote = Instance.new("RemoteEvent")
    pingRemote.Name = "PingRemote"
    pingRemote.Parent = ReplicatedStorage
    
    pingRemote.OnServerEvent:Connect(function(player, action, data)
        if action == "PING" then
            -- Relay to alliance members
            -- For now, broadcast to all (in production, filter by alliance)
            for _, otherPlayer in ipairs(Players:GetPlayers()) do
                if otherPlayer ~= player then
                    pingRemote:FireClient(otherPlayer, "ALLY_PING", {
                        playerName = player.DisplayName,
                        position = data.position,
                        pingType = data.pingType
                    })
                end
            end
        end
    end)
    
    print("[PingService] Initialized!")
end

return PingService
