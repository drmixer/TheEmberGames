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

-- Animation IDs (Using standard R15 anims where possible)
local ANIMATION_IDS = {
    SWING_OVERHEAD = "rbxassetid://522635514", -- Generic slash
    SWING_SIDE = "rbxassetid://522635514", 
    THRUST = "rbxassetid://522638767", -- Generic poke
    DRAW_BOW = "rbxassetid://507765644", 
    THROW = "rbxassetid://507765644",
}

-- Sound IDs (Using Classic Roblox Sounds - Guaranteed to work)
local SOUND_IDS = {
    SWING_WHOOSH = "rbxassetid://12222216", -- Classic Sword Slash
    BOW_DRAW = "rbxassetid://12222216", -- Reuse slash for now (better than 403)
    BOW_RELEASE = "rbxassetid://12222200", -- Classic Bow Fire
    THROW_WHOOSH = "rbxassetid://12222216", 
    HIT_MARKER = "rbxassetid://12222084", -- Classic Hit
    HIT_FLESH = "rbxassetid://12222152", -- Punch sound
    HIT_CRIT = "rbxassetid://4612377140", -- High impact
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
    if not Camera then return end
    local start = tick()
    local power = intensity or 0.5
    
    task.spawn(function()
        while tick() - start < 0.2 do
            local alpha = 1 - ((tick() - start) / 0.2)
            local currentPower = power * alpha
            
            local dx = (math.random() - 0.5) * currentPower
            local dy = (math.random() - 0.5) * currentPower
            local dz = (math.random() - 0.5) * currentPower * 0.5 -- Add some roll
            
            Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(dy), math.rad(dx), math.rad(dz))
            RunService.RenderStepped:Wait()
        end
    end)
end

-- ============ VISUALS & MARKERS ============

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

local function createVisualProjectile(tool, startPos, direction, speed)
    local projectile = Instance.new("Part")
    projectile.Name = "VisualProjectile"
    projectile.CanCollide = false
    projectile.Anchored = false 
    projectile.CFrame = CFrame.lookAt(startPos, startPos + direction)
    projectile.Parent = workspace
    
    local ammoType = tool:GetAttribute("AmmoType")
    
    if ammoType == "rock" then
        projectile.Size = Vector3.new(0.5, 0.5, 0.5)
        projectile.Color = Color3.fromRGB(80, 80, 80)
        projectile.Material = Enum.Material.Slate
        projectile.Shape = Enum.PartType.Ball
    else
        -- Default Arrow
        projectile.Size = Vector3.new(0.2, 0.2, 1.5)
        projectile.Color = Color3.fromRGB(100, 70, 40)
        projectile.Material = Enum.Material.Wood
        
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
    end
    
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = direction.Unit * speed
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = projectile
    Debris:AddItem(projectile, 3)
end

-- ============ POSE & ANIMATION HELPERS ============

local IDLE_C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.rad(90), math.rad(15)) 
local AIM_C0 = CFrame.new(1, 0.6, 0) * CFrame.Angles(0, math.rad(90), math.rad(90)) 

local function findRightShoulder(char)
    if not char then return nil end
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local arm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    
    if torso then
        local motor = torso:FindFirstChild("RightShoulder") or torso:FindFirstChild("Right Shoulder")
        if motor then return motor end
    end
    
    if arm then
        local motor = arm:FindFirstChild("RightShoulder") or arm:FindFirstChild("Right Shoulder")
        if motor then return motor end
    end
    return nil
end

local idleConnection
local function playIdlePose(tool)
    local char = Player.Character or tool.Parent
    if not char then return end
    
    local rightShoulder = findRightShoulder(char)
    if rightShoulder then
        -- Fix "Bike Pose" 
        local animate = char:FindFirstChild("Animate")
        if animate and animate:FindFirstChild("toolnone") then
             local toolNone = animate.toolnone:FindFirstChild("ToolNoneAnim")
             if toolNone then toolNone.AnimationId = "rbxassetid://0" end
        end
        
        if idleConnection then idleConnection:Disconnect() end
        
        idleConnection = RunService.RenderStepped:Connect(function()
            if not tool.Parent or tool.Parent ~= char then -- Safety check
                 if idleConnection then idleConnection:Disconnect() end
                 return
            end
            
            if WeaponController.actionState == "Attacking" then
                -- Do nothing
            elseif WeaponController.actionState == "Charging" then
                 rightShoulder.C0 = rightShoulder.C0:Lerp(AIM_C0, 0.2)
            else
                rightShoulder.C0 = rightShoulder.C0:Lerp(IDLE_C0, 0.1)
            end
        end)
    end
end

local function stopIdlePose()
    if idleConnection then 
        idleConnection:Disconnect() 
        idleConnection = nil
    end
    WeaponController.actionState = "Idle"
end

local function getAimDirection()
    local pos = UserInputService:GetMouseLocation()
    return Camera:ViewportPointToRay(pos.X, pos.Y).Direction
end

-- Lazy load CombatFeedback & WeaponEffects
local CombatFeedback
local WeaponEffects
task.spawn(function()
    CombatFeedback = require(script.Parent:WaitForChild("CombatFeedback"))
    WeaponEffects = require(script.Parent:WaitForChild("WeaponEffects"))
end)

local function performMeleeAttack()
    local char = Player.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool:GetAttribute("Type") ~= "melee" then return end
    
    local now = tick()
    local attackSpeed = tool:GetAttribute("AttackSpeed") or 0.5
    if now - WeaponController.attackCooldown < attackSpeed then return end
    WeaponController.attackCooldown = now
    
    -- Visuals
    playSound(SOUND_IDS.SWING_WHOOSH, 0.8, math.random(90,110)/100)
    shakeCamera(0.2) -- Light shake on swing
    
    -- BLOCK IDLE, START ATTACK
    WeaponController.actionState = "Attacking"
    
    local shoulder = findRightShoulder(char)
    if shoulder then
        -- Base position to animate from (use current C0 for smoothness)
        local baseC0 = IDLE_C0
            
        -- Windup (Back - Fast)
        local windupC0 = baseC0 * CFrame.Angles(0, 0, math.rad(60))
        local t1 = TweenService:Create(shoulder, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {C0 = windupC0})
        t1:Play()
        t1.Completed:Wait()
        
        -- Swing (Impact - Explosive)
        local swingC0 = baseC0 * CFrame.Angles(0, 0, math.rad(-90)) * CFrame.Angles(math.rad(60), 0, 0)
        local t2 = TweenService:Create(shoulder, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {C0 = swingC0})
        t2:Play()
        
        -- Hit Detection logic happens mid-swing
        -- We wait a tiny bit to match the visual "hit frame"
        task.wait(0.05)
        
        local range = tool:GetAttribute("Range") or 6
        local origin = char.HumanoidRootPart.Position
        local overlapParams = OverlapParams.new()
        overlapParams.FilterDescendantsInstances = {char}
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local parts = workspace:GetPartBoundsInRadius(origin, range, overlapParams)
        local hitConfirm = false
        
        for _, part in ipairs(parts) do
            local model = part.Parent
            if model:IsA("Accessory") then model = model.Parent end
            if model and model:IsA("Model") and model ~= char then
                    local hum = model:FindFirstChild("Humanoid")
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and hrp then
                        local toTarget = hrp.Position - origin
                        -- Dot product check: Must be in front of player
                        if toTarget.Unit:Dot(char.HumanoidRootPart.CFrame.LookVector) > 0.3 then
                            -- HIT CONFIRMED
                            hitConfirm = true
                            
                            -- 1. Meaty Sound Feedback (Instance)
                            playSound(SOUND_IDS.HIT_FLESH, 1, math.random(90, 110)/100)
                            
                            -- 2. Visual Blood (Local Immediate)
                            if WeaponEffects then
                                WeaponEffects:createBloodEffect(hrp.Position)
                            end
                            
                            -- 3. Server Event
                            if WeaponSystemRemote then
                                WeaponSystemRemote:FireServer("MELEE_HIT", model, hrp.Position)
                            end
                            
                            -- 4. Client Feedback (Markers)
                            if CombatFeedback then
                                CombatFeedback:showHitMarker(false) 
                            end
                            
                            -- 5. GAME JUICE: Hit Stop & Heavy Shake
                            shakeCamera(0.6) -- Heavy shake on impact
                            
                            -- Freeze the tween/shoulder momentarily to simulate "drag" or impact weight
                            if t2 then t2:Pause() end
                            task.wait(0.12) -- HIT STOP DURATION (The "Freeze")
                            if t2 then t2:Play() end
                            
                            break -- Hit one target per swing (or remove to hit multiple)
                        end
                    end
            end
        end
        
        if not hitConfirm and WeaponSystemRemote then
                WeaponSystemRemote:FireServer("MELEE_SWING", Camera.CFrame.LookVector)
        end
        
        t2.Completed:Wait()
        
        -- Recover (Return to idle - Smooth)
        local t3 = TweenService:Create(shoulder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = IDLE_C0})
        t3:Play()
        t3.Completed:Wait()

    end
    
    -- UNBLOCK IDLE
    WeaponController.actionState = "Idle"
end

local function startCharging()
    local char = Player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    local kind = tool and tool:GetAttribute("Type")
    if not tool or (kind ~= "ranged" and kind ~= "thrown") then return end
    
    WeaponController.isCharging = true
    WeaponController.chargeStartTime = tick()
    WeaponController.actionState = "Charging" -- Lifts Arm
    
    if WeaponController.chargeIndicator then
        WeaponController.chargeIndicator.Visible = true
        WeaponController.chargeIndicator.Fill.Size = UDim2.new(0,0,1,0)
    end
    
    -- Client-side Ammo Check (Generic for all ranged weapons with AmmoType)
    local ammoType = tool:GetAttribute("AmmoType")
    if ammoType then
        -- Correctly locate the InventoryGui module (Sibling of this script)
        local InventoryGuiModule = script.Parent:WaitForChild("InventoryGui", 5)
        
        if InventoryGuiModule then
            local success, InvGui = pcall(function() return require(InventoryGuiModule) end)
            if success and InvGui then
                -- Check for ammo
                local hasAmmo = false
                local ammoName = ammoType
                print("[WeaponController] Checking ammo: " .. tostring(ammoName) .. " for " .. tool.Name)
                
                if InvGui.playerInventory then
                    for _, item in pairs(InvGui.playerInventory.slots) do
                        -- InventoryGui uses lowercase 'name' and 'amount'
                        if item.name == ammoName and item.amount > 0 then
                            hasAmmo = true
                            print("[WeaponController] Found ammo: " .. tostring(item.amount))
                            break
                        end
                    end
                else
                    warn("[WeaponController] PlayerInventory is nil!")
                end
                
                if not hasAmmo then
                    print("[WeaponController] No ammo found!") 
                    -- Play empty click sound
                    local sound = Instance.new("Sound")
                    sound.SoundId = "rbxassetid://131070686" -- Click sound
                    sound.Volume = 0.5
                    sound.Parent = char.Head
                    sound.PlayOnRemove = true
                    sound:Destroy()
                    
                    -- Cancel charge
                    WeaponController.isCharging = false
                    WeaponController.actionState = "Idle"
                    if WeaponController.chargeIndicator then
                        WeaponController.chargeIndicator.Visible = false
                    end
                    return
                end
            else
                warn("[WeaponController] Failed to require InventoryGui")
            end
        else
            warn("[WeaponController] Condition check: InventoryGui module not found")
        end
    end

    playSound(SOUND_IDS.BOW_DRAW, 0.6)
    
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
    WeaponController.actionState = "Idle" -- Return to Idle
    
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
    shakeCamera(1.0 * factor) 
    
    local dir = getAimDirection()
    
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
    pcall(function()
        playIdlePose(tool)
    end)
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
    stopIdlePose()
end

-- ============ INPUT & UPDATE ============

local function onInputBegan(input, gpe)
    -- DEBUG INPUT
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- print("[WeaponController] Click! GPE:", gpe) -- Uncomment to spam logs
    end

    -- Allow clicking even if GPE is true (Ui underneath), unless it's a specific UI that SHOULD block
    -- For now, we trust our crosshair logic.
    -- if gpe then return end  <-- DISABLED GPE CHECK FOR WEAPONS
    
    local char = Player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local kind = tool:GetAttribute("Type")
        print("[WeaponController] Input: " .. tool.Name .. " Type: " .. tostring(kind))
        if kind == "melee" then performMeleeAttack()
        elseif kind == "ranged" or kind == "thrown" then startCharging()
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
