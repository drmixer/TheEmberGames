-- ModuleScript: SimpleCombat.lua
-- A SIMPLE, WORKING combat system for The Ember Games
-- Based on proven Roblox combat patterns

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local SimpleCombat = {}
SimpleCombat.cooldowns = {} -- player -> lastAttack time

-- Configuration
local CONFIG = {
    MELEE_RANGE = 6,           -- studs
    MELEE_DAMAGE = 25,         -- base damage
    ATTACK_COOLDOWN = 0.5,     -- seconds
    KNOCKBACK_FORCE = 20,      -- studs
}

-- Create or get remote event
local function getRemote()
    local remote = ReplicatedStorage:FindFirstChild("CombatRemote")
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = "CombatRemote"
        remote.Parent = ReplicatedStorage
    end
    return remote
end

-- Check if player can attack
function SimpleCombat:canAttack(player)
    local lastAttack = self.cooldowns[player] or 0
    return (tick() - lastAttack) >= CONFIG.ATTACK_COOLDOWN
end

-- Find targets in front of player
function SimpleCombat:findTargetsInRange(attacker)
    local character = attacker.Character
    if not character then return {} end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    
    local targets = {}
    local attackOrigin = hrp.Position
    local attackDirection = hrp.CFrame.LookVector
    
    -- Check all potential targets
    for _, model in pairs(workspace:GetChildren()) do
        if model:IsA("Model") and model ~= character then
            local targetHrp = model:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = model:FindFirstChild("Humanoid")
            
            if targetHrp and targetHumanoid and targetHumanoid.Health > 0 then
                local toTarget = targetHrp.Position - attackOrigin
                local distance = toTarget.Magnitude
                
                -- Check distance and angle (120 degree cone in front)
                if distance <= CONFIG.MELEE_RANGE then
                    local angle = math.acos(math.clamp(toTarget.Unit:Dot(attackDirection), -1, 1))
                    if angle < math.rad(60) then -- 60 degrees each side = 120 total
                        table.insert(targets, {
                            model = model,
                            humanoid = targetHumanoid,
                            hrp = targetHrp,
                            distance = distance
                        })
                    end
                end
            end
        end
    end
    
    -- Sort by distance (hit closest first)
    table.sort(targets, function(a, b) return a.distance < b.distance end)
    
    return targets
end

-- Apply damage to a target
function SimpleCombat:damage(targetHumanoid, amount, attacker, targetModel)
    if not targetHumanoid or targetHumanoid.Health <= 0 then return false end
    
    -- Apply damage
    targetHumanoid:TakeDamage(amount)
    
    -- Apply knockback
    local targetHrp = targetModel:FindFirstChild("HumanoidRootPart")
    local attackerHrp = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
    
    if targetHrp and attackerHrp then
        local knockbackDir = (targetHrp.Position - attackerHrp.Position).Unit
        local knockback = Instance.new("BodyVelocity")
        knockback.MaxForce = Vector3.new(10000, 5000, 10000)
        knockback.Velocity = knockbackDir * CONFIG.KNOCKBACK_FORCE + Vector3.new(0, 10, 0)
        knockback.Parent = targetHrp
        Debris:AddItem(knockback, 0.2)
    end
    
    print("[SimpleCombat] " .. attacker.Name .. " dealt " .. amount .. " damage to " .. targetModel.Name)
    
    -- Check for kill
    if targetHumanoid.Health <= 0 then
        print("[SimpleCombat] " .. attacker.Name .. " KILLED " .. targetModel.Name .. "!")
        return true, true -- hit, killed
    end
    
    return true, false -- hit, not killed
end

-- Process melee attack from player
function SimpleCombat:meleeAttack(player)
    if not self:canAttack(player) then return end
    
    self.cooldowns[player] = tick()
    
    local targets = self:findTargetsInRange(player)
    local remote = getRemote()
    
    if #targets > 0 then
        -- Hit the closest target
        local target = targets[1]
        local didHit, didKill = self:damage(target.humanoid, CONFIG.MELEE_DAMAGE, player, target.model)
        
        -- Notify client of hit
        if didHit then
            remote:FireClient(player, "HIT", target.model.Name, CONFIG.MELEE_DAMAGE, didKill)
            
            -- Notify all clients for visual effects
            remote:FireAllClients("ATTACK_EFFECT", player.UserId, target.hrp.Position)
        end
    else
        -- Miss - just swing
        remote:FireClient(player, "MISS")
    end
end

-- Initialize
function SimpleCombat.init()
    print("[SimpleCombat] Initializing...")
    
    local remote = getRemote()
    
    -- Handle attack requests from clients
    remote.OnServerEvent:Connect(function(player, action, ...)
        if action == "ATTACK" then
            SimpleCombat:meleeAttack(player)
        end
    end)
    
    print("[SimpleCombat] Ready!")
end

return SimpleCombat
