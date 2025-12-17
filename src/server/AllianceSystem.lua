-- ModuleScript: AllianceSystem.lua (Server)
-- Manages player alliances and betrayal mechanics
-- Allows temporary alliances that can be broken at any time

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AllianceSystem = {}
AllianceSystem.alliances = {} -- { allianceId = { members = {}, createdAt, maxSize } }
AllianceSystem.playerAlliances = {} -- { playerId = allianceId }
AllianceSystem.pendingInvites = {} -- { playerId = { fromPlayerId, allianceId, timestamp } }
AllianceSystem.betrayalCooldowns = {} -- { playerId = timestamp }

-- Configuration
local CONFIG = {
    MAX_ALLIANCE_SIZE = 4,
    INVITE_TIMEOUT = 30, -- Seconds
    BETRAYAL_COOLDOWN = 60, -- Seconds before can join new alliance after betrayal
    ALLY_DAMAGE_REDUCTION = 0.9, -- 90% less damage to allies (but not zero!)
    SHARED_VISION_RANGE = 50, -- Studs to share enemy positions
    BETRAYAL_BONUS_DAMAGE = 1.25, -- 25% more damage on betrayal
}

-- Create RemoteEvent
local allianceRemote = Instance.new("RemoteEvent")
allianceRemote.Name = "AllianceRemoteEvent"
allianceRemote.Parent = ReplicatedStorage

-- Generate unique alliance ID
local function generateAllianceId()
    return "alliance_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
end

-- Get player's current alliance
function AllianceSystem:getPlayerAlliance(player)
    local playerId = player.UserId
    local allianceId = AllianceSystem.playerAlliances[playerId]
    if allianceId and AllianceSystem.alliances[allianceId] then
        return AllianceSystem.alliances[allianceId], allianceId
    end
    return nil, nil
end

-- Check if two players are allies
function AllianceSystem:areAllies(player1, player2)
    if player1 == player2 then return false end
    
    local alliance1 = AllianceSystem.playerAlliances[player1.UserId]
    local alliance2 = AllianceSystem.playerAlliances[player2.UserId]
    
    if alliance1 and alliance2 and alliance1 == alliance2 then
        return true
    end
    return false
end

-- Create a new alliance
function AllianceSystem:createAlliance(leaderPlayer)
    local playerId = leaderPlayer.UserId
    
    -- Check if already in alliance
    if AllianceSystem.playerAlliances[playerId] then
        return false, "Already in an alliance"
    end
    
    -- Check betrayal cooldown
    if AllianceSystem.betrayalCooldowns[playerId] then
        local remaining = AllianceSystem.betrayalCooldowns[playerId] - tick()
        if remaining > 0 then
            return false, "Cannot form alliances for " .. math.ceil(remaining) .. " seconds"
        end
    end
    
    local allianceId = generateAllianceId()
    
    AllianceSystem.alliances[allianceId] = {
        leader = playerId,
        members = { playerId },
        createdAt = tick(),
        maxSize = CONFIG.MAX_ALLIANCE_SIZE,
        name = leaderPlayer.Name .. "'s Alliance"
    }
    
    AllianceSystem.playerAlliances[playerId] = allianceId
    
    -- Notify leader
    allianceRemote:FireClient(leaderPlayer, "ALLIANCE_CREATED", {
        allianceId = allianceId,
        name = AllianceSystem.alliances[allianceId].name
    })
    
    print("[AllianceSystem] Alliance created: " .. allianceId .. " by " .. leaderPlayer.Name)
    return true, allianceId
end

-- Invite player to alliance
function AllianceSystem:invitePlayer(inviter, targetPlayer)
    local inviterId = inviter.UserId
    local targetId = targetPlayer.UserId
    
    -- Check if inviter is in an alliance
    local alliance, allianceId = AllianceSystem:getPlayerAlliance(inviter)
    if not alliance then
        return false, "You are not in an alliance"
    end
    
    -- Check if inviter is leader
    if alliance.leader ~= inviterId then
        return false, "Only the alliance leader can invite"
    end
    
    -- Check alliance size
    if #alliance.members >= alliance.maxSize then
        return false, "Alliance is full"
    end
    
    -- Check if target is already in an alliance
    if AllianceSystem.playerAlliances[targetId] then
        return false, targetPlayer.Name .. " is already in an alliance"
    end
    
    -- Check if target has pending invite
    if AllianceSystem.pendingInvites[targetId] then
        return false, targetPlayer.Name .. " already has a pending invite"
    end
    
    -- Check target's betrayal cooldown
    if AllianceSystem.betrayalCooldowns[targetId] then
        local remaining = AllianceSystem.betrayalCooldowns[targetId] - tick()
        if remaining > 0 then
            return false, targetPlayer.Name .. " cannot join alliances yet"
        end
    end
    
    -- Create invite
    AllianceSystem.pendingInvites[targetId] = {
        fromPlayerId = inviterId,
        fromPlayerName = inviter.Name,
        allianceId = allianceId,
        allianceName = alliance.name,
        timestamp = tick()
    }
    
    -- Notify target
    allianceRemote:FireClient(targetPlayer, "ALLIANCE_INVITE", {
        fromPlayerName = inviter.Name,
        allianceName = alliance.name,
        timeout = CONFIG.INVITE_TIMEOUT
    })
    
    -- Notify inviter
    allianceRemote:FireClient(inviter, "INVITE_SENT", {
        targetPlayerName = targetPlayer.Name
    })
    
    -- Auto-expire invite
    task.delay(CONFIG.INVITE_TIMEOUT, function()
        if AllianceSystem.pendingInvites[targetId] and 
           AllianceSystem.pendingInvites[targetId].allianceId == allianceId then
            AllianceSystem.pendingInvites[targetId] = nil
            allianceRemote:FireClient(targetPlayer, "INVITE_EXPIRED", {})
        end
    end)
    
    print("[AllianceSystem] " .. inviter.Name .. " invited " .. targetPlayer.Name)
    return true
end

-- Accept alliance invite
function AllianceSystem:acceptInvite(player)
    local playerId = player.UserId
    local invite = AllianceSystem.pendingInvites[playerId]
    
    if not invite then
        return false, "No pending invite"
    end
    
    local alliance = AllianceSystem.alliances[invite.allianceId]
    if not alliance then
        AllianceSystem.pendingInvites[playerId] = nil
        return false, "Alliance no longer exists"
    end
    
    -- Check alliance size
    if #alliance.members >= alliance.maxSize then
        AllianceSystem.pendingInvites[playerId] = nil
        return false, "Alliance is full"
    end
    
    -- Add to alliance
    table.insert(alliance.members, playerId)
    AllianceSystem.playerAlliances[playerId] = invite.allianceId
    AllianceSystem.pendingInvites[playerId] = nil
    
    -- Notify all alliance members
    for _, memberId in ipairs(alliance.members) do
        local memberPlayer = Players:GetPlayerByUserId(memberId)
        if memberPlayer then
            allianceRemote:FireClient(memberPlayer, "ALLIANCE_MEMBER_JOINED", {
                playerName = player.Name,
                allianceName = alliance.name,
                memberCount = #alliance.members
            })
        end
    end
    
    print("[AllianceSystem] " .. player.Name .. " joined alliance: " .. invite.allianceId)
    return true
end

-- Decline alliance invite
function AllianceSystem:declineInvite(player)
    local playerId = player.UserId
    local invite = AllianceSystem.pendingInvites[playerId]
    
    if not invite then
        return false, "No pending invite"
    end
    
    -- Notify inviter
    local inviterPlayer = Players:GetPlayerByUserId(invite.fromPlayerId)
    if inviterPlayer then
        allianceRemote:FireClient(inviterPlayer, "INVITE_DECLINED", {
            playerName = player.Name
        })
    end
    
    AllianceSystem.pendingInvites[playerId] = nil
    return true
end

-- Leave alliance voluntarily
function AllianceSystem:leaveAlliance(player)
    local playerId = player.UserId
    local alliance, allianceId = AllianceSystem:getPlayerAlliance(player)
    
    if not alliance then
        return false, "Not in an alliance"
    end
    
    -- Remove from members
    for i, memberId in ipairs(alliance.members) do
        if memberId == playerId then
            table.remove(alliance.members, i)
            break
        end
    end
    
    AllianceSystem.playerAlliances[playerId] = nil
    
    -- If was leader, transfer or disband
    if alliance.leader == playerId then
        if #alliance.members > 0 then
            -- Transfer leadership
            alliance.leader = alliance.members[1]
            local newLeader = Players:GetPlayerByUserId(alliance.leader)
            if newLeader then
                alliance.name = newLeader.Name .. "'s Alliance"
            end
        else
            -- Disband alliance
            AllianceSystem.alliances[allianceId] = nil
            print("[AllianceSystem] Alliance disbanded: " .. allianceId)
            return true
        end
    end
    
    -- Notify remaining members
    for _, memberId in ipairs(alliance.members) do
        local memberPlayer = Players:GetPlayerByUserId(memberId)
        if memberPlayer then
            allianceRemote:FireClient(memberPlayer, "ALLIANCE_MEMBER_LEFT", {
                playerName = player.Name,
                memberCount = #alliance.members
            })
        end
    end
    
    -- Notify player
    allianceRemote:FireClient(player, "LEFT_ALLIANCE", {
        allianceName = alliance.name
    })
    
    print("[AllianceSystem] " .. player.Name .. " left alliance: " .. allianceId)
    return true
end

-- Betray alliance (attack an ally)
function AllianceSystem:processBetrayalAttack(attacker, victim, baseDamage)
    if not AllianceSystem:areAllies(attacker, victim) then
        return baseDamage, false -- Not allies, normal damage
    end
    
    local attackerId = attacker.UserId
    
    -- First attack on ally is a betrayal
    local isBetrayalStrike = true
    
    -- Apply betrayal bonus
    local finalDamage = baseDamage * CONFIG.BETRAYAL_BONUS_DAMAGE
    
    -- Remove attacker from alliance
    local alliance, allianceId = AllianceSystem:getPlayerAlliance(attacker)
    if alliance then
        -- Remove from members
        for i, memberId in ipairs(alliance.members) do
            if memberId == attackerId then
                table.remove(alliance.members, i)
                break
            end
        end
        
        AllianceSystem.playerAlliances[attackerId] = nil
        
        -- Set betrayal cooldown
        AllianceSystem.betrayalCooldowns[attackerId] = tick() + CONFIG.BETRAYAL_COOLDOWN
        
        -- Notify everyone
        for _, memberId in ipairs(alliance.members) do
            local memberPlayer = Players:GetPlayerByUserId(memberId)
            if memberPlayer then
                allianceRemote:FireClient(memberPlayer, "ALLIANCE_BETRAYAL", {
                    traitorName = attacker.Name,
                    victimName = victim.Name
                })
            end
        end
        
        -- Notify attacker
        allianceRemote:FireClient(attacker, "YOU_BETRAYED", {
            allianceName = alliance.name,
            cooldown = CONFIG.BETRAYAL_COOLDOWN
        })
        
        -- If attacker was leader, transfer
        if alliance.leader == attackerId then
            if #alliance.members > 0 then
                alliance.leader = alliance.members[1]
            else
                AllianceSystem.alliances[allianceId] = nil
            end
        end
        
        print("[AllianceSystem] BETRAYAL! " .. attacker.Name .. " attacked ally " .. victim.Name)
    end
    
    return finalDamage, true
end

-- Process damage between players (call from CombatController)
function AllianceSystem:processDamage(attacker, victim, baseDamage)
    -- Check if allies
    if AllianceSystem:areAllies(attacker, victim) then
        -- Reduce damage significantly (but allow betrayal)
        local reducedDamage = baseDamage * (1 - CONFIG.ALLY_DAMAGE_REDUCTION)
        return reducedDamage, false
    end
    
    return baseDamage, false
end

-- Get alliance info for UI
function AllianceSystem:getAllianceInfo(player)
    local alliance, allianceId = AllianceSystem:getPlayerAlliance(player)
    if not alliance then
        return nil
    end
    
    local memberNames = {}
    for _, memberId in ipairs(alliance.members) do
        local memberPlayer = Players:GetPlayerByUserId(memberId)
        if memberPlayer then
            table.insert(memberNames, {
                name = memberPlayer.Name,
                isLeader = (memberId == alliance.leader),
                userId = memberId
            })
        end
    end
    
    return {
        id = allianceId,
        name = alliance.name,
        members = memberNames,
        memberCount = #alliance.members,
        maxSize = alliance.maxSize,
        isLeader = (player.UserId == alliance.leader)
    }
end

-- Cleanup when player leaves
local function onPlayerRemoving(player)
    local playerId = player.UserId
    
    -- Remove from alliance if in one
    AllianceSystem:leaveAlliance(player)
    
    -- Clean up pending invites
    AllianceSystem.pendingInvites[playerId] = nil
    
    -- Clean up cooldowns
    AllianceSystem.betrayalCooldowns[playerId] = nil
end

-- Handle remote events
local function handleRemoteEvent(player, action, ...)
    local args = {...}
    
    if action == "CREATE_ALLIANCE" then
        local success, result = AllianceSystem:createAlliance(player)
        allianceRemote:FireClient(player, "CREATE_RESULT", { success = success, message = result })
        
    elseif action == "INVITE_PLAYER" then
        local targetPlayerName = args[1]
        local targetPlayer = Players:FindFirstChild(targetPlayerName)
        if targetPlayer then
            local success, message = AllianceSystem:invitePlayer(player, targetPlayer)
            if not success then
                allianceRemote:FireClient(player, "INVITE_FAILED", { message = message })
            end
        else
            allianceRemote:FireClient(player, "INVITE_FAILED", { message = "Player not found" })
        end
        
    elseif action == "ACCEPT_INVITE" then
        local success, message = AllianceSystem:acceptInvite(player)
        allianceRemote:FireClient(player, "ACCEPT_RESULT", { success = success, message = message })
        
    elseif action == "DECLINE_INVITE" then
        AllianceSystem:declineInvite(player)
        
    elseif action == "LEAVE_ALLIANCE" then
        local success, message = AllianceSystem:leaveAlliance(player)
        allianceRemote:FireClient(player, "LEAVE_RESULT", { success = success, message = message })
        
    elseif action == "GET_ALLIANCE_INFO" then
        local info = AllianceSystem:getAllianceInfo(player)
        allianceRemote:FireClient(player, "ALLIANCE_INFO", info)
    end
end

-- Initialize AllianceSystem
function AllianceSystem.init()
    print("[AllianceSystem] Initializing...")
    
    -- Connect events
    allianceRemote.OnServerEvent:Connect(handleRemoteEvent)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
    
    -- Reset all alliances on match start
    local matchRemote = ReplicatedStorage:FindFirstChild("MatchRemoteEvent")
    if matchRemote then
        -- Could connect to MATCH_STARTED to reset alliances
    end
    
    print("[AllianceSystem] Initialized")
end

return AllianceSystem
