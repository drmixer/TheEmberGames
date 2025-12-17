-- ModuleScript: PartyService.lua (Server)
-- Manages player parties for group queuing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local PartyService = {}
PartyService.parties = {} -- code -> party data
PartyService.playerParties = {} -- userId -> code

local MAX_PARTY_SIZE = 4

-- Generate random party code
local function generateCode()
    local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    local code = ""
    for i = 1, 6 do
        local idx = math.random(1, #chars)
        code = code .. chars:sub(idx, idx)
    end
    return code
end

-- Get party data for a player
local function getPartyForPlayer(player)
    local code = PartyService.playerParties[player.UserId]
    if code then
        return PartyService.parties[code], code
    end
    return nil, nil
end

-- Broadcast party update to all members
local function broadcastPartyUpdate(code)
    local party = PartyService.parties[code]
    if not party then return end
    
    local partyRemote = ReplicatedStorage:FindFirstChild("PartyRemote")
    if not partyRemote then return end
    
    local membersList = {}
    for _, memberId in ipairs(party.members) do
        local memberPlayer = Players:GetPlayerByUserId(memberId)
        if memberPlayer then
            table.insert(membersList, {
                userId = memberId,
                name = memberPlayer.DisplayName,
                isLeader = memberId == party.leader
            })
        end
    end
    
    for _, memberId in ipairs(party.members) do
        local memberPlayer = Players:GetPlayerByUserId(memberId)
        if memberPlayer then
            partyRemote:FireClient(memberPlayer, "PARTY_UPDATE", {
                code = code,
                members = membersList,
                isLeader = memberId == party.leader
            })
        end
    end
end

-- Create a new party
function PartyService:createParty(player)
    -- Check if already in party
    if PartyService.playerParties[player.UserId] then
        PartyService:leaveParty(player)
    end
    
    local code = generateCode()
    while PartyService.parties[code] do
        code = generateCode()
    end
    
    PartyService.parties[code] = {
        leader = player.UserId,
        members = {player.UserId},
        createdAt = os.time()
    }
    
    PartyService.playerParties[player.UserId] = code
    
    print("[PartyService] " .. player.Name .. " created party: " .. code)
    
    broadcastPartyUpdate(code)
    return code
end

-- Join a party
function PartyService:joinParty(player, code)
    code = string.upper(code)
    
    local party = PartyService.parties[code]
    if not party then
        warn("[PartyService] Party not found: " .. code)
        return false
    end
    
    if #party.members >= MAX_PARTY_SIZE then
        warn("[PartyService] Party is full")
        return false
    end
    
    -- Leave current party first
    if PartyService.playerParties[player.UserId] then
        PartyService:leaveParty(player)
    end
    
    table.insert(party.members, player.UserId)
    PartyService.playerParties[player.UserId] = code
    
    print("[PartyService] " .. player.Name .. " joined party: " .. code)
    
    broadcastPartyUpdate(code)
    return true
end

-- Leave party
function PartyService:leaveParty(player)
    local party, code = getPartyForPlayer(player)
    if not party then return end
    
    -- Remove from members
    for i, memberId in ipairs(party.members) do
        if memberId == player.UserId then
            table.remove(party.members, i)
            break
        end
    end
    
    PartyService.playerParties[player.UserId] = nil
    
    -- Notify player
    local partyRemote = ReplicatedStorage:FindFirstChild("PartyRemote")
    if partyRemote then
        partyRemote:FireClient(player, "PARTY_DISBANDED", {})
    end
    
    -- If party is empty or leader left, handle it
    if #party.members == 0 then
        PartyService.parties[code] = nil
        print("[PartyService] Party " .. code .. " disbanded (empty)")
    elseif party.leader == player.UserId then
        -- Transfer leadership
        party.leader = party.members[1]
        broadcastPartyUpdate(code)
        print("[PartyService] Leadership transferred in party " .. code)
    else
        broadcastPartyUpdate(code)
    end
    
    print("[PartyService] " .. player.Name .. " left party")
end

-- Kick a member (leader only)
function PartyService:kickMember(leader, targetUserId)
    local party, code = getPartyForPlayer(leader)
    if not party then return end
    
    if party.leader ~= leader.UserId then
        warn("[PartyService] Only leader can kick")
        return
    end
    
    for i, memberId in ipairs(party.members) do
        if memberId == targetUserId then
            table.remove(party.members, i)
            PartyService.playerParties[targetUserId] = nil
            
            -- Notify kicked player
            local targetPlayer = Players:GetPlayerByUserId(targetUserId)
            if targetPlayer then
                local partyRemote = ReplicatedStorage:FindFirstChild("PartyRemote")
                if partyRemote then
                    partyRemote:FireClient(targetPlayer, "PARTY_DISBANDED", {reason = "kicked"})
                end
            end
            
            broadcastPartyUpdate(code)
            print("[PartyService] Player " .. targetUserId .. " was kicked from party")
            return
        end
    end
end

-- Check if players are in same party
function PartyService:areInSameParty(player1, player2)
    local code1 = PartyService.playerParties[player1.UserId]
    local code2 = PartyService.playerParties[player2.UserId]
    return code1 and code1 == code2
end

-- Get party members for matchmaking
function PartyService:getPartyMembers(player)
    local party, code = getPartyForPlayer(player)
    if not party then return {player} end
    
    local members = {}
    for _, memberId in ipairs(party.members) do
        local memberPlayer = Players:GetPlayerByUserId(memberId)
        if memberPlayer then
            table.insert(members, memberPlayer)
        end
    end
    return members
end

-- Initialize
function PartyService.init()
    print("[PartyService] Initializing...")
    
    local partyRemote = Instance.new("RemoteEvent")
    partyRemote.Name = "PartyRemote"
    partyRemote.Parent = ReplicatedStorage
    
    partyRemote.OnServerEvent:Connect(function(player, action, data)
        if action == "CREATE" then
            PartyService:createParty(player)
        elseif action == "JOIN" then
            PartyService:joinParty(player, data)
        elseif action == "LEAVE" then
            PartyService:leaveParty(player)
        elseif action == "KICK" then
            PartyService:kickMember(player, data)
        elseif action == "QUEUE" then
            -- Queue party for match
            local members = PartyService:getPartyMembers(player)
            local lobbyRemote = ReplicatedStorage:FindFirstChild("LobbyRemoteEvent")
            if lobbyRemote then
                for _, member in ipairs(members) do
                    lobbyRemote:FireServer("QUEUE_FOR_MATCH")
                end
            end
        end
    end)
    
    -- Clean up when players leave
    Players.PlayerRemoving:Connect(function(player)
        if PartyService.playerParties[player.UserId] then
            PartyService:leaveParty(player)
        end
    end)
    
    print("[PartyService] Initialized!")
end

return PartyService
