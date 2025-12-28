-- LocalScript: WeaponController.lua
-- Client-side weapon input handling and animations
-- Handles attack input, aim, and weapon UI
-- UPGRADED: Camera Shake, Hit Markers, Dynamic Crosshair

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()

-- Wait for remote event
local WeaponSystemRemote = ReplicatedStorage:WaitForChild("WeaponSystemRemote", 10)

local WeaponController = {}
WeaponController.currentWeapon = nil
WeaponController.isCharging = false
WeaponController.chargeStartTime = 0
WeaponController.attackCooldown = 0
WeaponController.screenGui = nil
WeaponController.crosshair = nil
WeaponController.durabilityBar = nil

-- Configuration
local CONFIG = {
    MAX_CHARGE_TIME = 1.5, -- seconds
    CROSSHAIR_NORMAL_SIZE = UDim2.new(0, 30, 0, 30),
    CROSSHAIR_CHARGING_SIZE = UDim2.new(0, 50, 0, 50),
    SHAKE_INTENSITY = 0.5
}

-- Animation IDs
local ANIMATION_IDS = {
    SWING_OVERHEAD = "rbxassetid://5104343315", -- Sword swing
    SWING_SIDE = "rbxassetid://5104343157", -- Side slash
    THRUST = "rbxassetid://5104342815", -- Spear thrust
    DRAW_BOW = "rbxassetid://5104345142", -- Draw bow
    THROW = "rbxassetid://5104345348", -- Throw item
}

-- Sound IDs
local SOUND_IDS = {
    SWING_WHOOSH = "rbxassetid://6241709963",
    BOW_DRAW = "rbxassetid://6230981039",
    BOW_RELEASE = "rbxassetid://6230980816",
    THROW_WHOOSH = "rbxassetid://6241709963", 
    HIT_MARKER = "rbxassetid://1347767351", -- Distinct tick
}

-- ============ UI CREATION ============

local function createWeaponUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WeaponUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Crosshair container
    local crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = CONFIG.CROSSHAIR_NORMAL_SIZE
    crosshair.Position = UDim2.new(0.5, -15, 0.5, -15)
    crosshair.BackgroundTransparency = 1
    crosshair.Visible = false
    crosshair.Parent = screenGui
    
    -- Dynamic Lines
    local function makeLine(name, pos, size)
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.BackgroundColor3 = Color3.new(1,1,1)
        frame.BorderSizePixel = 0
        frame.Position = pos
        frame.Size = size
        frame.Parent = crosshair
        return frame
    end
    
    makeLine("Top", UDim2.new(0.5,-1, 0,0), UDim2.new(0,2,0.3,0))
    makeLine("Bottom", UDim2.new(0.5,-1, 0.7,0), UDim2.new(0,2,0.3,0))
    makeLine("Left", UDim2.new(0,0, 0.5,-1), UDim2.new(0.3,0, 0,2))
    makeLine("Right", UDim2.new(0.7,0, 0.5,-1), UDim2.new(0.3,0, 0,2))
    
    -- Center Dot
    local centerDot = Instance.new("Frame")
    centerDot.Size = UDim2.new(0, 4, 0, 4)
    centerDot.Position = UDim2.new(0.5, -2, 0.5, -2)
    centerDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    centerDot.BorderSizePixel = 0
    centerDot.Parent = crosshair
    Instance.new("UICorner", centerDot).CornerRadius = UDim.new(1,0)
    
    -- Charge Indicator
    local chargeFrame = Instance.new("Frame")
    chargeFrame.Name = "ChargeIndicator"
    chargeFrame.Size = UDim2.new(0, 150, 0, 6)
    chargeFrame.Position = UDim2.new(0.5, -75, 0.65, 0)
    chargeFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    chargeFrame.BackgroundTransparency = 0.5
    chargeFrame.BorderSizePixel = 0
    chargeFrame.Visible = false
    chargeFrame.Parent = screenGui
    Instance.new("UICorner", chargeFrame).CornerRadius = UDim.new(1,0)
    
    local chargeFill = Instance.new("Frame")
    chargeFill.Name = "Fill"
    chargeFill.Size = UDim2.new(0, 0, 1, 0)
    chargeFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    chargeFill.BorderSizePixel = 0
    chargeFill.Parent = chargeFrame
    Instance.new("UICorner", chargeFill).CornerRadius = UDim.new(1,0)
    
    WeaponController.screenGui = screenGui
    WeaponController.crosshair = crosshair
    WeaponController.chargeIndicator = chargeFrame
    
    return screenGui
end

-- ============ SOUND & FX ============

local function playSound(soundId, volume, pitch)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.PlaybackSpeed = pitch or 1
    sound.Parent = PlayerGui
    sound:Play()
    Debris:AddItem(sound, 2)
    return sound
end

local function shakeCamera(intensity)
    local start = tick()
    local power = intensity or 0.5
    
    task.spawn(function()
        while tick() - start < 0.1 do
            local dx = (math.random() - 0.5) * power
            local dy = (math.random() - 0.5) * power
            Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(dy), math.rad(dx), 0)
            RunService.RenderStepped:Wait()
        end
    end)
end



local function showHitMarker(isCritical)
    local gui = WeaponController.screenGui
    if not gui then return end
    
    playSound(SOUND_IDS.HIT_MARKER, 1, isCritical and 1.2 or 1)
    
    local marker = Instance.new("ImageLabel")
    marker.Image = "rbxassetid://6253579174" -- Cross icon
    marker.BackgroundTransparency = 1
    marker.Size = UDim2.new(0, 40, 0, 40)
    marker.Position = UDim2.new(0.5, -20, 0.5, -20)
    marker.ImageColor3 = isCritical and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
    marker.Parent = gui
    
    TweenService:Create(marker, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 60, 0, 60),
        ImageTransparency = 1
    }):Play()
    Debris:AddItem(marker, 0.2)
end

-- Create a fake visual projectile for instant feedback
local function createVisualProjectile(tool, startPos, direction, speed)
    local projectile = Instance.new("Part")
    projectile.Name = "VisualProjectile"
    projectile.Size = Vector3.new(0.2, 0.2, 1.5)
    projectile.Color = Color3.fromRGB(100, 70, 40)
    projectile.Material = Enum.Material.Wood
    projectile.CanCollide = false
    projectile.Anchored = false -- Use body velocity
    projectile.CFrame = CFrame.lookAt(startPos, startPos + direction)
    projectile.Parent = workspace
    
    if tool:GetAttribute("WeaponId") == "Bow" then
        local tip = Instance.new("Part")
        tip.Size = Vector3.new(0.15, 0.3, 0.15)
        tip.Color = Color3.fromRGB(80, 80, 80)
        tip.CanCollide = false
        tip.Massless = true
        tip.Parent = projectile
        local weld = Instance.new("Weld", tip)
        weld.Part0 = projectile
        weld.Part1 = tip
        weld.C0 = CFrame.new(0, 0, -0.9)
    end
    
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = direction.Unit * speed
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = projectile
    
    -- Cleanup
    Debris:AddItem(projectile, 3)
    
    -- Fade out logic to avoid seeing double when server projectile arrives
    task.delay(0.1, function()
        -- In a real production game, we'd hide the SERVER projectile locally
        -- For now, we'll just let this one fade out quickly or handle hit visual
    end)
end

-- ============ ANIMATIONS ============

local function playAttackAnimation(animName)
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    local animId = ANIMATION_IDS[animName]
    if not animId then return end
    
    -- Try to play animation (may fail if asset unavailable)
    local success, track = pcall(function()
        local animator = hum:FindFirstChild("Animator") or Instance.new("Animator", hum)
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        return animator:LoadAnimation(anim)
    end)
    
    if success and track then
        track:Play()
        return track
    end
    
    -- Fallback: Simple arm swing using Motor6D
    -- This works even when animation fails
    local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    
    if torso and rightArm then
        local shoulder = torso:FindFirstChild("Right Shoulder") or torso:FindFirstChild("RightShoulder")
        if shoulder then
            local originalC0 = shoulder.C0
            -- Quick swing animation
            task.spawn(function()
                local swingDown = originalC0 * CFrame.Angles(math.rad(-80), 0, 0)
                shoulder.C0 = swingDown
                task.wait(0.15)
                shoulder.C0 = originalC0
            end)
        end
    end
    
    return nil
end

-- ============ ATTACK LOGIC ============

local function getAimDirection()
    local pos = UserInputService:GetMouseLocation()
    return Camera:ViewportPointToRay(pos.X, pos.Y).Direction
end

local function performMeleeAttack()
    local char = Player.Character
    if not char then 
        print("[WeaponController] No character!")
        return 
    end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        print("[WeaponController] No tool equipped!")
        return
    end
    
    if tool:GetAttribute("Type") ~= "melee" then
        print("[WeaponController] Tool is not melee type: " .. tostring(tool:GetAttribute("Type")))
        return
    end
    
    local now = tick()
    local attackSpeed = tool:GetAttribute("AttackSpeed") or 0.5
    if now - WeaponController.attackCooldown < attackSpeed then 
        return -- Still on cooldown, silent
    end
    WeaponController.attackCooldown = now
    
    print("[WeaponController] ATTACKING with " .. tool.Name)
    
    playSound(SOUND_IDS.SWING_WHOOSH, 0.8, math.random(90,110)/100)
    shakeCamera(0.5)
    
    -- Weapon swing animation using Tool Grip (actually works!)
    task.spawn(function()
        local originalGrip = tool.Grip
        
        -- Swing forward/down
        local swingGrip = originalGrip * CFrame.Angles(math.rad(-70), 0, math.rad(15))
        tool.Grip = swingGrip
        
        task.wait(0.08)
        
        -- Swing through
        local throughGrip = originalGrip * CFrame.Angles(math.rad(20), 0, math.rad(-10))
        tool.Grip = throughGrip
        
        task.wait(0.1)
        
        -- Return to original
        tool.Grip = originalGrip
    end)
    
    -- Skip broken animation (try it but don't rely on it)
    pcall(function()
        playAttackAnimation("SWING_OVERHEAD")
    end)
    
    -- Client-Side Hit Detection - SIMPLE SPHERE CHECK
    local range = tool:GetAttribute("Range") or 6
    local origin = char.HumanoidRootPart.Position
    local targetFound = nil
    local hitPos = origin
    local closestDist = range + 1
    
    -- Check ALL models in workspace that could be targets
    for _, model in pairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model ~= char then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
            
            if humanoid and hrp and humanoid.Health > 0 then
                local dist = (hrp.Position - origin).Magnitude
                
                -- Simple distance check - hit closest target within range
                if dist <= range and dist < closestDist then
                    closestDist = dist
                    targetFound = model
                    hitPos = hrp.Position
                end
            end
        end
    end
    
    -- Debug: show what we found
    if targetFound then
        print("[WeaponController] Found target: " .. targetFound.Name .. " at distance " .. string.format("%.1f", closestDist))
    else
        print("[WeaponController] No target in range " .. range .. " studs")
    end
    
    if targetFound then
        -- Show hit feedback
        local success, CombatFeedback = pcall(function()
            return require(script.Parent:WaitForChild("CombatFeedback", 1))
        end)
        if success and CombatFeedback then
            CombatFeedback:showHitMarker(false)
        end
        
        if WeaponSystemRemote then
            WeaponSystemRemote:FireServer("MELEE_HIT", targetFound, hitPos)
        end
        print("[WeaponController] Hit " .. (targetFound.Name or "target"))
    else
        -- Just Swing
        if WeaponSystemRemote then
            WeaponSystemRemote:FireServer("MELEE_SWING", Camera.CFrame.LookVector)
        end
    end
end

local function startCharging()
    local char = Player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool:GetAttribute("Type") ~= "ranged" then return end
    
    WeaponController.isCharging = true
    WeaponController.chargeStartTime = tick()
    
    if WeaponController.chargeIndicator then
        WeaponController.chargeIndicator.Visible = true
        WeaponController.chargeIndicator.Fill.Size = UDim2.new(0,0,1,0)
    end
    
    playSound(SOUND_IDS.BOW_DRAW, 0.6)
    playAttackAnimation("DRAW_BOW")
    
    -- Shrink Crosshair for focus
    if WeaponController.crosshair then
         TweenService:Create(WeaponController.crosshair, TweenInfo.new(1.0), {
             Size = UDim2.new(0, 10, 0, 10)
         }):Play()
    end
end

local function releaseCharge()
    if not WeaponController.isCharging then return end
    WeaponController.isCharging = false
    
    local char = Player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local maxTime = tool:GetAttribute("ChargeTime") or CONFIG.MAX_CHARGE_TIME
    local factor = math.clamp((tick() - WeaponController.chargeStartTime)/maxTime, 0.2, 1)
    
    if WeaponController.chargeIndicator then
        WeaponController.chargeIndicator.Visible = false
    end
    
    -- Reset Crosshair
    if WeaponController.crosshair then
         TweenService:Create(WeaponController.crosshair, TweenInfo.new(0.2), {
             Size = CONFIG.CROSSHAIR_NORMAL_SIZE
         }):Play()
    end
    
    playSound(SOUND_IDS.BOW_RELEASE, 0.8)
    shakeCamera(1.0 * factor) -- Bigger shake for fuller charge
    
    local dir = getAimDirection()
    
    -- Instant Visual Feedback
    local speed = tool:GetAttribute("ProjectileSpeed") or 100
    local origin = char.HumanoidRootPart.Position + Vector3.new(0, 2, 0) + dir * 2
    createVisualProjectile(tool, origin, dir, speed * factor)
    
    if WeaponSystemRemote then
        WeaponSystemRemote:FireServer("RANGED_ATTACK", dir, factor)
    end
end

-- ============ TOOL HANDLING ============

local function onEquip(tool)
    WeaponController.currentWeapon = tool
    local kind = tool:GetAttribute("Type")
    if WeaponController.crosshair then
        WeaponController.crosshair.Visible = (kind == "ranged" or kind == "thrown")
    end
end

local function onUnequip(tool)
    WeaponController.currentWeapon = nil
    WeaponController.isCharging = false
    if WeaponController.crosshair then
        WeaponController.crosshair.Visible = false
    end
    if WeaponController.chargeIndicator then
        WeaponController.chargeIndicator.Visible = false
    end
end

-- ============ INPUT & UPDATE ============

local function onInputBegan(input, gpe)
    if gpe then return end
    local char = Player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local kind = tool:GetAttribute("Type")
        if kind == "melee" then performMeleeAttack()
        elseif kind == "ranged" then startCharging()
        end
    end
end

local function onInputEnded(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and WeaponController.isCharging then
        releaseCharge()
    end
end

local function update()
    -- Charge UI Update
    if WeaponController.isCharging and WeaponController.chargeIndicator then
        local maxTime = CONFIG.MAX_CHARGE_TIME
        local p = math.clamp((tick() - WeaponController.chargeStartTime)/maxTime, 0, 1)
        WeaponController.chargeIndicator.Fill.Size = UDim2.new(p, 0, 1, 0)
        WeaponController.chargeIndicator.Fill.BackgroundColor3 = Color3.fromHSV(p * 0.3, 1, 1) -- Red to Green
    end
    
    -- Simple movement tilt for premium feel
    local char = Player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum and root then
            local velocity = root.Velocity
            local tiltZ = math.clamp(-root.CFrame.RightVector:Dot(velocity) * 0.05, -5, 5)
            -- Only apply to camera locally, Camera script normally handles this but we can inject a small roll
            Camera.CFrame = Camera.CFrame * CFrame.Angles(0, 0, math.rad(tiltZ * 0.1))
        end
    end
end

-- ============ NETWORKING ============

local function onServerEvent(action, ...)
    local args = {...}
    if action == "WEAPON_HIT" then
        local pos, type, dmg, crit = args[1], args[2], args[3], args[4]
        if type == "player" then
            showHitMarker(crit)
        end
    end
    -- Other events handled similarly...
end

function WeaponController.init()
    createWeaponUI()
    UserInputService.InputBegan:Connect(onInputBegan)
    UserInputService.InputEnded:Connect(onInputEnded)
    RunService.RenderStepped:Connect(update)
    
    if WeaponSystemRemote then
        WeaponSystemRemote.OnClientEvent:Connect(onServerEvent)
    end
    
    Player.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(c) if c:IsA("Tool") then onEquip(c) end end)
        char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then onUnequip(c) end end)
    end)
end

WeaponController.init()
return WeaponController
