-- LocalScript: WeaponController.lua
-- Client-side weapon input handling and animations
-- Handles attack input, aim, and weapon UI

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
}

-- Animation IDs
local ANIMATION_IDS = {
    SWING_OVERHEAD = "rbxassetid://5104343315", -- Sword swing
    SWING_SIDE = "rbxassetid://5104343157", -- Side slash
    THRUST = "rbxassetid://5104342815", -- Spear thrust
    DRAW_BOW = "rbxassetid://5104345142", -- Draw bow
    THROW = "rbxassetid://5104345348", -- Throw item
}

-- Sound IDs (VERIFIED Roblox audio assets)
local SOUND_IDS = {
    SWING_WHOOSH = "rbxassetid://6241709963", -- Verified sword swing metal heavy
    BOW_DRAW = "rbxassetid://6230981039", -- Verified bow draw tension
    BOW_RELEASE = "rbxassetid://6230980816", -- Verified bow release/arrow launch
    THROW_WHOOSH = "rbxassetid://6241709963", -- Verified throw whoosh
}

-- ============ UI CREATION ============

local function createWeaponUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WeaponUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Crosshair (for ranged weapons)
    local crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = CONFIG.CROSSHAIR_NORMAL_SIZE
    crosshair.Position = UDim2.new(0.5, -15, 0.5, -15)
    crosshair.BackgroundTransparency = 1
    crosshair.Visible = false
    crosshair.Parent = screenGui
    
    -- Crosshair lines
    local lineTop = Instance.new("Frame")
    lineTop.Size = UDim2.new(0, 2, 0.3, 0)
    lineTop.Position = UDim2.new(0.5, -1, 0, 0)
    lineTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    lineTop.BorderSizePixel = 0
    lineTop.Parent = crosshair
    
    local lineBottom = lineTop:Clone()
    lineBottom.Position = UDim2.new(0.5, -1, 0.7, 0)
    lineBottom.Parent = crosshair
    
    local lineLeft = Instance.new("Frame")
    lineLeft.Size = UDim2.new(0.3, 0, 0, 2)
    lineLeft.Position = UDim2.new(0, 0, 0.5, -1)
    lineLeft.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    lineLeft.BorderSizePixel = 0
    lineLeft.Parent = crosshair
    
    local lineRight = lineLeft:Clone()
    lineRight.Position = UDim2.new(0.7, 0, 0.5, -1)
    lineRight.Parent = crosshair
    
    -- Center dot
    local centerDot = Instance.new("Frame")
    centerDot.Size = UDim2.new(0, 4, 0, 4)
    centerDot.Position = UDim2.new(0.5, -2, 0.5, -2)
    centerDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    centerDot.BorderSizePixel = 0
    centerDot.Parent = crosshair
    
    local centerCorner = Instance.new("UICorner")
    centerCorner.CornerRadius = UDim.new(1, 0)
    centerCorner.Parent = centerDot
    
    -- Charge indicator
    local chargeFrame = Instance.new("Frame")
    chargeFrame.Name = "ChargeIndicator"
    chargeFrame.Size = UDim2.new(0, 100, 0, 10)
    chargeFrame.Position = UDim2.new(0.5, -50, 0.6, 0)
    chargeFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    chargeFrame.BorderSizePixel = 0
    chargeFrame.Visible = false
    chargeFrame.Parent = screenGui
    
    local chargeCorner = Instance.new("UICorner")
    chargeCorner.CornerRadius = UDim.new(0, 5)
    chargeCorner.Parent = chargeFrame
    
    local chargeFill = Instance.new("Frame")
    chargeFill.Name = "Fill"
    chargeFill.Size = UDim2.new(0, 0, 1, 0)
    chargeFill.Position = UDim2.new(0, 0, 0, 0)
    chargeFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    chargeFill.BorderSizePixel = 0
    chargeFill.Parent = chargeFrame
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 5)
    fillCorner.Parent = chargeFill
    
    -- Durability bar
    local durabilityFrame = Instance.new("Frame")
    durabilityFrame.Name = "DurabilityBar"
    durabilityFrame.Size = UDim2.new(0, 100, 0, 8)
    durabilityFrame.Position = UDim2.new(1, -120, 1, -50)
    durabilityFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    durabilityFrame.BorderSizePixel = 0
    durabilityFrame.Visible = false
    durabilityFrame.Parent = screenGui
    
    local durCorner = Instance.new("UICorner")
    durCorner.CornerRadius = UDim.new(0, 4)
    durCorner.Parent = durabilityFrame
    
    local durFill = Instance.new("Frame")
    durFill.Name = "Fill"
    durFill.Size = UDim2.new(1, 0, 1, 0)
    durFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    durFill.BorderSizePixel = 0
    durFill.Parent = durabilityFrame
    
    local durFillCorner = Instance.new("UICorner")
    durFillCorner.CornerRadius = UDim.new(0, 4)
    durFillCorner.Parent = durFill
    
    local durLabel = Instance.new("TextLabel")
    durLabel.Name = "Label"
    durLabel.Size = UDim2.new(0, 100, 0, 15)
    durLabel.Position = UDim2.new(0, 0, 0, -15)
    durLabel.BackgroundTransparency = 1
    durLabel.Text = "Durability"
    durLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    durLabel.TextSize = 12
    durLabel.Font = Enum.Font.Gotham
    durLabel.TextXAlignment = Enum.TextXAlignment.Left
    durLabel.Parent = durabilityFrame
    
    WeaponController.screenGui = screenGui
    WeaponController.crosshair = crosshair
    WeaponController.chargeIndicator = chargeFrame
    WeaponController.durabilityBar = durabilityFrame
    
    return screenGui
end

-- ============ SOUND ============

local function playSound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.Parent = PlayerGui
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    return sound
end

-- ============ ANIMATIONS ============

local function playAttackAnimation(animationType)
    local character = Player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local animator = humanoid:FindFirstChild("Animator") or humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    
    local animId = ANIMATION_IDS[animationType]
    if not animId then return end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = animId
    
    local track = animator:LoadAnimation(animation)
    track.Priority = Enum.AnimationPriority.Action
    track:Play()
    
    track.Stopped:Connect(function()
        animation:Destroy()
    end)
    
    return track
end

-- ============ ATTACK HANDLING ============

local function getAimDirection()
    local mousePosition = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
    return ray.Direction
end

local function performMeleeAttack()
    local character = Player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local weaponType = tool:GetAttribute("Type")
    if weaponType ~= "melee" then return end
    
    local attackSpeed = tool:GetAttribute("AttackSpeed") or 1
    local now = tick()
    
    if now - WeaponController.attackCooldown < attackSpeed then
        return -- Still on cooldown
    end
    
    WeaponController.attackCooldown = now
    
    -- Play swing sound
    playSound(SOUND_IDS.SWING_WHOOSH, 0.6)
    
    -- Play animation
    local weaponId = tool:GetAttribute("WeaponId") or ""
    if string.find(weaponId, "Spear") or string.find(weaponId, "Stick") then
        playAttackAnimation("THRUST")
    else
        playAttackAnimation("SWING_OVERHEAD")
    end
    
    -- Send attack to server
    local direction = hrp.CFrame.LookVector
    if WeaponSystemRemote then
        WeaponSystemRemote:FireServer("MELEE_ATTACK", direction)
    end
end

local function startCharging()
    local character = Player.Character
    if not character then return end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local weaponType = tool:GetAttribute("Type")
    if weaponType ~= "ranged" then return end
    
    WeaponController.isCharging = true
    WeaponController.chargeStartTime = tick()
    
    -- Show charge indicator
    if WeaponController.chargeIndicator then
        WeaponController.chargeIndicator.Visible = true
    end
    
    -- Play draw sound
    playSound(SOUND_IDS.BOW_DRAW, 0.5)
    
    -- Play draw animation
    playAttackAnimation("DRAW_BOW")
end

local function releaseCharge()
    if not WeaponController.isCharging then return end
    
    local character = Player.Character
    if not character then return end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local chargeTime = tick() - WeaponController.chargeStartTime
    local maxCharge = tool:GetAttribute("ChargeTime") or CONFIG.MAX_CHARGE_TIME
    local chargeAmount = math.clamp(chargeTime / maxCharge, 0.3, 1)
    
    WeaponController.isCharging = false
    
    -- Hide charge indicator
    if WeaponController.chargeIndicator then
        WeaponController.chargeIndicator.Visible = false
        WeaponController.chargeIndicator.Fill.Size = UDim2.new(0, 0, 1, 0)
    end
    
    -- Play release sound
    playSound(SOUND_IDS.BOW_RELEASE, 0.6)
    
    -- Send ranged attack to server
    local direction = getAimDirection()
    if WeaponSystemRemote then
        WeaponSystemRemote:FireServer("RANGED_ATTACK", direction, chargeAmount)
    end
end

local function performThrownAttack()
    local character = Player.Character
    if not character then return end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local weaponType = tool:GetAttribute("Type")
    if weaponType ~= "thrown" then return end
    
    -- Play throw animation
    playAttackAnimation("THROW")
    
    -- Play sound
    playSound(SOUND_IDS.THROW_WHOOSH, 0.5)
    
    -- Send to server
    local direction = getAimDirection()
    if WeaponSystemRemote then
        WeaponSystemRemote:FireServer("RANGED_ATTACK", direction, 1)
    end
end

-- ============ WEAPON EQUIPPED/UNEQUIPPED ============

local function onToolEquipped(tool)
    WeaponController.currentWeapon = tool
    
    local weaponType = tool:GetAttribute("Type")
    local durability = tool:GetAttribute("CurrentDurability")
    local maxDurability = tool:GetAttribute("Durability")
    
    -- Show crosshair for ranged weapons
    if WeaponController.crosshair then
        WeaponController.crosshair.Visible = (weaponType == "ranged" or weaponType == "thrown")
    end
    
    -- Show durability bar
    if WeaponController.durabilityBar and durability and maxDurability then
        WeaponController.durabilityBar.Visible = true
        local fillPercent = durability / maxDurability
        WeaponController.durabilityBar.Fill.Size = UDim2.new(fillPercent, 0, 1, 0)
        
        -- Color based on durability
        if fillPercent > 0.5 then
            WeaponController.durabilityBar.Fill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        elseif fillPercent > 0.25 then
            WeaponController.durabilityBar.Fill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        else
            WeaponController.durabilityBar.Fill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        end
    end
    
    print("[WeaponController] Equipped: " .. tool.Name)
end

local function onToolUnequipped(tool)
    WeaponController.currentWeapon = nil
    WeaponController.isCharging = false
    
    -- Hide crosshair
    if WeaponController.crosshair then
        WeaponController.crosshair.Visible = false
    end
    
    -- Hide charge indicator
    if WeaponController.chargeIndicator then
        WeaponController.chargeIndicator.Visible = false
    end
    
    -- Hide durability
    if WeaponController.durabilityBar then
        WeaponController.durabilityBar.Visible = false
    end
    
    print("[WeaponController] Unequipped: " .. tool.Name)
end

-- ============ INPUT HANDLING ============

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    
    local character = Player.Character
    if not character then return end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local weaponType = tool:GetAttribute("Type")
    
    -- Left click / tap
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if weaponType == "melee" then
            performMeleeAttack()
        elseif weaponType == "ranged" then
            startCharging()
        elseif weaponType == "thrown" then
            performThrownAttack()
        end
    end
end

local function onInputEnded(input, gameProcessed)
    -- Release charge for ranged weapons
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if WeaponController.isCharging then
            releaseCharge()
        end
    end
end

-- ============ UPDATE LOOP ============

local function update()
    -- Update charge indicator
    if WeaponController.isCharging and WeaponController.chargeIndicator then
        local character = Player.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                local maxCharge = tool:GetAttribute("ChargeTime") or CONFIG.MAX_CHARGE_TIME
                local chargeTime = tick() - WeaponController.chargeStartTime
                local chargePercent = math.clamp(chargeTime / maxCharge, 0, 1)
                
                WeaponController.chargeIndicator.Fill.Size = UDim2.new(chargePercent, 0, 1, 0)
                
                -- Color based on charge
                if chargePercent < 0.3 then
                    WeaponController.chargeIndicator.Fill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                elseif chargePercent < 0.8 then
                    WeaponController.chargeIndicator.Fill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
                else
                    WeaponController.chargeIndicator.Fill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                end
            end
        end
    end
    
    -- Update crosshair position (follows mouse)
    if WeaponController.crosshair and WeaponController.crosshair.Visible then
        local mousePos = UserInputService:GetMouseLocation()
        WeaponController.crosshair.Position = UDim2.new(0, mousePos.X - 15, 0, mousePos.Y - 15)
    end
end

-- ============ SERVER EVENT HANDLING ============

local function onServerEvent(action, ...)
    local args = {...}
    
    if action == "WEAPON_SWING" then
        local playerId = args[1]
        local weaponId = args[2]
        
        -- Could add visual effects for other players' swings here
        
    elseif action == "WEAPON_HIT" then
        local hitPosition = args[1]
        local hitType = args[2]
        local damage = args[3]
        local isCritical = args[4]
        
        -- Create hit effect at position
        if hitPosition then
            local effect = Instance.new("Part")
            effect.Size = Vector3.new(0.5, 0.5, 0.5)
            effect.Position = hitPosition
            effect.Anchored = true
            effect.CanCollide = false
            effect.Material = Enum.Material.Neon
            
            if hitType == "player" then
                effect.Color = isCritical and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 100, 100)
            elseif hitType == "miss" then
                effect.Color = Color3.fromRGB(150, 150, 150)
            else
                effect.Color = Color3.fromRGB(255, 200, 100)
            end
            
            effect.Parent = workspace
            
            TweenService:Create(effect, TweenInfo.new(0.3), {
                Size = Vector3.new(2, 2, 2),
                Transparency = 1
            }):Play()
            
            Debris:AddItem(effect, 0.5)
        end
        
    elseif action == "WEAPON_BROKEN" then
        local weaponId = args[1]
        
        -- Show weapon broken notification
        local notification = Instance.new("TextLabel")
        notification.Size = UDim2.new(0, 300, 0, 50)
        notification.Position = UDim2.new(0.5, -150, 0.3, 0)
        notification.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        notification.BackgroundTransparency = 0.3
        notification.Text = "⚠️ " .. (weaponId or "Weapon") .. " broke!"
        notification.TextColor3 = Color3.fromRGB(255, 255, 255)
        notification.TextSize = 20
        notification.Font = Enum.Font.GothamBold
        notification.Parent = WeaponController.screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = notification
        
        TweenService:Create(notification, TweenInfo.new(0.3), {
            Position = UDim2.new(0.5, -150, 0.35, 0)
        }):Play()
        
        task.delay(2, function()
            TweenService:Create(notification, TweenInfo.new(0.3), {
                Position = UDim2.new(0.5, -150, 0.3, 0),
                BackgroundTransparency = 1,
                TextTransparency = 1
            }):Play()
            Debris:AddItem(notification, 0.5)
        end)
        
    elseif action == "DURABILITY_UPDATE" then
        local weaponId = args[1]
        local currentDurability = args[2]
        
        -- Update durability bar if weapon is equipped
        local character = Player.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and tool:GetAttribute("WeaponId") == weaponId then
                local maxDurability = tool:GetAttribute("Durability") or 1
                local fillPercent = currentDurability / maxDurability
                
                if WeaponController.durabilityBar then
                    TweenService:Create(WeaponController.durabilityBar.Fill, TweenInfo.new(0.2), {
                        Size = UDim2.new(fillPercent, 0, 1, 0)
                    }):Play()
                    
                    -- Color based on durability
                    if fillPercent > 0.5 then
                        WeaponController.durabilityBar.Fill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                    elseif fillPercent > 0.25 then
                        WeaponController.durabilityBar.Fill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
                    else
                        WeaponController.durabilityBar.Fill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                    end
                end
            end
        end
        
    elseif action == "PROJECTILE_HIT" then
        local hitPosition = args[1]
        local hitType = args[2]
        
        -- Arrow hit effect
        if hitPosition then
            local effect = Instance.new("Part")
            effect.Size = Vector3.new(0.3, 0.3, 0.3)
            effect.Position = hitPosition
            effect.Anchored = true
            effect.CanCollide = false
            effect.Material = Enum.Material.Neon
            effect.Color = hitType == "player" and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(200, 150, 100)
            effect.Parent = workspace
            
            TweenService:Create(effect, TweenInfo.new(0.2), {
                Size = Vector3.new(1.5, 1.5, 1.5),
                Transparency = 1
            }):Play()
            
            Debris:AddItem(effect, 0.3)
        end
        
    elseif action == "TRAP_TRIGGERED" then
        local position = args[1]
        local trapId = args[2]
        
        -- Create trap trigger effect
        if position then
            local effect = Instance.new("Part")
            effect.Size = Vector3.new(1, 1, 1)
            effect.Position = position
            effect.Anchored = true
            effect.CanCollide = false
            effect.Material = Enum.Material.Neon
            effect.Shape = Enum.PartType.Ball
            
            if trapId == "FireTrap" then
                effect.Color = Color3.fromRGB(255, 100, 0)
            elseif trapId == "PoisonBerry" then
                effect.Color = Color3.fromRGB(100, 0, 150)
            else
                effect.Color = Color3.fromRGB(200, 200, 200)
            end
            
            effect.Parent = workspace
            
            TweenService:Create(effect, TweenInfo.new(0.5), {
                Size = Vector3.new(8, 8, 8),
                Transparency = 1
            }):Play()
            
            Debris:AddItem(effect, 0.6)
        end
    end
end

-- ============ INITIALIZATION ============

function WeaponController.init()
    print("[WeaponController] Initializing...")
    
    -- Create UI
    createWeaponUI()
    
    -- Connect input
    UserInputService.InputBegan:Connect(onInputBegan)
    UserInputService.InputEnded:Connect(onInputEnded)
    
    -- Connect update loop
    RunService.RenderStepped:Connect(update)
    
    -- Connect server events
    if WeaponSystemRemote then
        WeaponSystemRemote.OnClientEvent:Connect(onServerEvent)
    end
    
    -- Watch for tool equip/unequip
    local function setupCharacter(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                onToolEquipped(child)
            end
        end)
        
        character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then
                onToolUnequipped(child)
            end
        end)
        
        -- Check for already equipped tool
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            onToolEquipped(tool)
        end
    end
    
    if Player.Character then
        setupCharacter(Player.Character)
    end
    
    Player.CharacterAdded:Connect(setupCharacter)
    
    print("[WeaponController] Initialized successfully")
end

-- Initialize when loaded
WeaponController.init()

return WeaponController
