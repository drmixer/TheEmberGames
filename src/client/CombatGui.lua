-- LocalScript: CombatGui.lua
-- Combat interface and controls for The Ember Games
-- Handles weapon selection, combat controls, and combat feedback

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local WeaponRemoteEvent = ReplicatedStorage:WaitForChild("WeaponRemoteEvent")
local DamageRemoteEvent = ReplicatedStorage:WaitForChild("DamageRemoteEvent")

local CombatGui = {}
CombatGui.activeWeapon = nil
CombatGui.activeWeaponName = nil
CombatGui.playerInventory = {} 
CombatGui.combatEnabled = false
CombatGui.combatGui = nil
CombatGui.crosshair = nil
CombatGui.crosshairSpread = 0

-- CONSTANTS
local MAX_SPREAD = 40
local MIN_SPREAD = 6
local SPREAD_RECOVERY = 2
local MOVEMENT_SPREAD = 1.5

-- Create combat UI elements
local function createCombatUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CombatInterface"
    screenGui.Parent = PlayerGui
    screenGui.ResetOnSpawn = false
    
    -- 1. DYNAMIC CROSSHAIR
    local crosshairFrame = Instance.new("Frame")
    crosshairFrame.Name = "Crosshair"
    crosshairFrame.Size = UDim2.new(0, 100, 0, 100)
    crosshairFrame.Position = UDim2.new(0.5, -50, 0.5, -50)
    crosshairFrame.BackgroundTransparency = 1
    crosshairFrame.Parent = screenGui
    
    -- Create 4 parts of the crosshair (Top, Bottom, Left, Right)
    local function createPip(name)
        local pip = Instance.new("Frame")
        pip.Name = name
        pip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        pip.BorderSizePixel = 1
        pip.BorderColor3 = Color3.fromRGB(0, 0, 0)
        pip.Parent = crosshairFrame
        return pip
    end
    
    local top = createPip("Top")
    top.Size = UDim2.new(0, 2, 0, 6)
    top.Position = UDim2.new(0.5, -1, 0.5, -MIN_SPREAD - 6)
    
    local bottom = createPip("Bottom")
    bottom.Size = UDim2.new(0, 2, 0, 6)
    bottom.Position = UDim2.new(0.5, -1, 0.5, MIN_SPREAD)
    
    local left = createPip("Left")
    left.Size = UDim2.new(0, 6, 0, 2)
    left.Position = UDim2.new(0.5, -MIN_SPREAD - 6, 0.5, -1)
    
    local right = createPip("Right")
    right.Size = UDim2.new(0, 6, 0, 2)
    right.Position = UDim2.new(0.5, MIN_SPREAD, 0.5, -1)
    
    -- Center Dot
    local dot = createPip("Dot")
    dot.Size = UDim2.new(0, 2, 0, 2)
    dot.Position = UDim2.new(0.5, -1, 0.5, -1)
    dot.BackgroundTransparency = 0.3
    
    CombatGui.crosshair = crosshairFrame
    
    -- 2. CURRENT WEAPON & DURABILITY DISPLAY
    local weaponDisplay = Instance.new("Frame")
    weaponDisplay.Name = "WeaponDisplay"
    weaponDisplay.Size = UDim2.new(0, 220, 0, 70)
    weaponDisplay.Position = UDim2.new(0.5, -110, 1, -170) -- Moved UP to avoid hotbar overlap
    weaponDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    weaponDisplay.BackgroundTransparency = 0.2
    weaponDisplay.BorderSizePixel = 0
    weaponDisplay.Parent = screenGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = weaponDisplay
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(60, 60, 70)
    uiStroke.Thickness = 1.5
    uiStroke.Parent = weaponDisplay
    
    -- Weapon Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "WeaponName"
    nameLabel.Size = UDim2.new(1, -20, 0, 25)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "UNARMED"
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = weaponDisplay
    
    -- Durability Container
    local durabilityContainer = Instance.new("Frame")
    durabilityContainer.Name = "DurabilityContainer"
    durabilityContainer.Size = UDim2.new(1, -20, 0, 8)
    durabilityContainer.Position = UDim2.new(0, 10, 0, 45)
    durabilityContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    durabilityContainer.BorderSizePixel = 0
    durabilityContainer.Parent = weaponDisplay
    
    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(1, 0)
    dCorner.Parent = durabilityContainer
    
    -- The Bar itself
    local durabilityBar = Instance.new("Frame")
    durabilityBar.Name = "DurabilityBar"
    durabilityBar.Size = UDim2.new(1, 0, 1, 0)
    durabilityBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    durabilityBar.BorderSizePixel = 0
    durabilityBar.Parent = durabilityContainer
    
    local dbCorner = Instance.new("UICorner")
    dbCorner.CornerRadius = UDim.new(1, 0)
    dbCorner.Parent = durabilityBar
    
    -- Icons/Info Text
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, -20, 0, 15)
    infoLabel.Position = UDim2.new(0, 10, 0, 30)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Durability"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 10
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = weaponDisplay
    
    CombatGui.combatGui = screenGui
    
    return screenGui
end

-- Update Crosshair Spread
local function updateCrosshair()
    if not CombatGui.crosshair then return end
    
    local char = Player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    
    if not hrp or not humanoid then return end
    
    -- Calculate target spread based on movement
    local speed = hrp.Velocity.Magnitude
    local targetSpread = MIN_SPREAD
    
    if speed > 1 then
        targetSpread = MIN_SPREAD + (speed * MOVEMENT_SPREAD)
    end
    
    if humanoid.Jump then
        targetSpread = targetSpread + 20
    end
    
    -- Clamp
    targetSpread = math.clamp(targetSpread, MIN_SPREAD, MAX_SPREAD)
    
    -- Smoothly interpolate current spread
    CombatGui.crosshairSpread = CombatGui.crosshairSpread + (targetSpread - CombatGui.crosshairSpread) * 0.2
    
    -- Update Pips
    local spread = CombatGui.crosshairSpread
    
    CombatGui.crosshair.Top.Position = UDim2.new(0.5, -1, 0.5, -spread - 6)
    CombatGui.crosshair.Bottom.Position = UDim2.new(0.5, -1, 0.5, spread)
    CombatGui.crosshair.Left.Position = UDim2.new(0.5, -spread - 6, 0.5, -1)
    CombatGui.crosshair.Right.Position = UDim2.new(0.5, spread, 0.5, -1)
end

-- Select a weapon
function CombatGui:selectWeapon(slotNumber)
    if not CombatGui.combatEnabled then return end
    
    -- Logic: Equip the tool (Simplified for reliability)
    local character = Player.Character
    local backpack = Player:FindFirstChild("Backpack")
    
    -- Rely on what's actually held or in backpack mapping
    -- For visual update, we listen to ChildAdded/Removed on character mostly
    -- but here we can try to force equip if needed.
    
    -- (Keeping original logic minimal to avoid breaking existing inventory interactions)
end

-- Update UI when weapon changes
function CombatGui:updateWeaponDisplay(tool)
    if not CombatGui.combatGui then return end
    
    local display = CombatGui.combatGui:FindFirstChild("WeaponDisplay")
    if not display then return end
    
    if tool then
        CombatGui.activeWeaponName = tool.Name
        display.WeaponName.Text = string.upper(tool.Name)
        display.WeaponName.TextColor3 = Color3.fromRGB(255, 255, 255)
        display.Visible = true
        
        -- Reset bar to full (or read attribute if exists)
        local dur = tool:GetAttribute("Durability")
        local maxDur = tool:GetAttribute("MaxDurability") or 25 -- Fallback
        
        -- If no attribute, assume fresh
        if not dur then dur = maxDur end
        
        CombatGui:updateDurability(dur, maxDur)
    else
        CombatGui.activeWeaponName = nil
        display.WeaponName.Text = "UNARMED"
        display.WeaponName.TextColor3 = Color3.fromRGB(150, 150, 150)
        display.DurabilityContainer.DurabilityBar.Size = UDim2.new(0, 0, 1, 0)
        -- display.Visible = false -- Keep visible to show state
    end
end

-- Update Durability UI
function CombatGui:updateDurability(current, max)
    if not CombatGui.combatGui then return end
    
    local display = CombatGui.combatGui:FindFirstChild("WeaponDisplay")
    if display then
        local bar = display.DurabilityContainer.DurabilityBar
        local ratio = math.clamp(current / max, 0, 1)
        
        bar:TweenSize(UDim2.new(ratio, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        
        -- Color coding
        if ratio > 0.5 then
            bar.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green
        elseif ratio > 0.2 then
            bar.BackgroundColor3 = Color3.fromRGB(255, 200, 50) -- Yellow
        else
            bar.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red
        end
    end
end

-- Perform a melee attack
function CombatGui:meleeAttack()
    if not CombatGui.combatEnabled then return end
    
    -- Expand crosshair on attack
    CombatGui.crosshairSpread = CombatGui.crosshairSpread + 15
    
    if CombatGui.activeWeaponName then
         WeaponRemoteEvent:FireServer("SWING_WEAPON", CombatGui.activeWeaponName)
    end
end

-- Initialize combat system
function CombatGui:init()
    print("CombatGui initialized")
    
    -- Create UI
    createCombatUI()
    
    -- Enable combat once player is ready
    task.wait(1) 
    CombatGui.combatEnabled = true
    
    -- RunService for Crosshair
    RunService.RenderStepped:Connect(function()
        updateCrosshair()
    end)
    
    -- Monitor Character for equipped tools
    local function onCharacterAdded(char)
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                CombatGui:updateWeaponDisplay(child)
            end
        end)
        char.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then
                -- Check if we have another tool, else unarmed
                task.delay(0.1, function()
                    local newTool = char:FindFirstChildOfClass("Tool")
                    CombatGui:updateWeaponDisplay(newTool)
                end)
            end
        end)
        
        -- Check initial
        local tool = char:FindFirstChildOfClass("Tool")
        CombatGui:updateWeaponDisplay(tool)
    end
    
    if Player.Character then onCharacterAdded(Player.Character) end
    Player.CharacterAdded:Connect(onCharacterAdded)
    
    -- Connect to input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if CombatGui.combatEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
             CombatGui:meleeAttack()
        end
    end)
    
    -- Connect to damage events
    DamageRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
        local args = {...}
        
        if eventType == "PLAYER_DAMAGE" then
            local victimUserId, damage, isCritical = args[1], args[2], args[3]
            
            local victimPlayer = Players:GetPlayerByUserId(victimUserId)
            if victimPlayer then
                -- Visual feedback for damage
                if victimPlayer == Player then
                    -- Taken damage (Red vignette or Shake)
                    CombatGui:showDamageTaken()
                else
                    -- Dealt damage (Hitmarker)
                    CombatGui:showDamageDealt(damage, isCritical, victimPlayer)
                end
            end
        end
    end)
    
    -- Connect to weapon events
    WeaponRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
        local args = {...}
        
        if eventType == "WEAPON_BROKEN" then
             CombatGui:updateWeaponDisplay(nil) -- effectively unarmed
             
             -- Show "BROKEN" text
             if CombatGui.combatGui then
                local label = CombatGui.combatGui.WeaponDisplay.InfoLabel
                label.Text = "WEAPON BROKEN!"
                label.TextColor3 = Color3.fromRGB(255, 50, 50)
                task.delay(2, function() label.Text = "Durability" label.TextColor3 = Color3.fromRGB(150,150,150) end)
             end
             
        elseif eventType == "WEAPON_DURABILITY_UPDATE" then
            local weaponType, durability = args[1], args[2]
            local max = 25 -- Should ideally come from event
            CombatGui:updateDurability(durability, max)
        end
    end)
    
    print("CombatGui initialized and ready")
end

-- Shake screen
function CombatGui:shakeScreen(intensity, duration)
    local camera = workspace.CurrentCamera
    local startTime = tick()
    local originalOffset = CFrame.new()
    
    -- Basic decay shake
    task.spawn(function()
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local remaining = 1 - (elapsed / duration)
            local shakeRes = intensity * remaining
            
            local offset = Vector3.new(
                (math.random() - 0.5) * shakeRes,
                (math.random() - 0.5) * shakeRes,
                0
            ) * 0.1
            
            -- Apply offset (Note: This is a simple implementation. Ideally use a camera controller hook)
            -- For now, we manipulate coordinate frame directly if no other system fights it.
            -- A better way is creating a Shaker object or value.
            -- But keeping it simple for this codebase:
            
            camera.CFrame = camera.CFrame * CFrame.new(offset)
            
            RunService.RenderStepped:Wait()
        end
    end)
end

-- Show damage feedback to player
function CombatGui:showDamageDealt(damage, isCritical, victim)
    -- Hitmarker
    if CombatGui.crosshair then
        local marker = Instance.new("ImageLabel")
        marker.Size = UDim2.new(0, 30, 0, 30)
        marker.Position = UDim2.new(0.5, -15, 0.5, -15)
        marker.BackgroundTransparency = 1
        marker.Image = "rbxassetid://16447544391" -- Cross/X Icon
        marker.ImageColor3 = isCritical and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
        marker.Parent = CombatGui.combatGui
        
        -- Animation
        marker:TweenSize(UDim2.new(0, 10, 0, 10), "In", "Quad", 0.3)
        local t = TweenService:Create(marker, TweenInfo.new(0.3), {ImageTransparency = 1})
        t:Play()
        t.Completed:Connect(function() marker:Destroy() end)
    end
    
    -- Shake!
    local intensity = isCritical and 4 or 1.5
    CombatGui:shakeScreen(intensity, 0.2)
    
    -- Floating Number
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = victim.Character and victim.Character:FindFirstChild("Head")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(math.random(-1,1), 2, math.random(-1,1))
    billboard.AlwaysOnTop = true
    billboard.Parent = PlayerGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = tostring(math.floor(damage))
    label.TextColor3 = isCritical and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 200, 50)
    label.Font = Enum.Font.GothamBlack
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Parent = billboard
    
    -- Animate up
    local t = TweenService:Create(billboard, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {StudsOffset = billboard.StudsOffset + Vector3.new(0, 2, 0)})
    t:Play()
    
    local t2 = TweenService:Create(label, TweenInfo.new(1), {TextTransparency = 1, TextStrokeTransparency = 1})
    t2:Play()
    t2.Completed:Connect(function() billboard:Destroy() end)
end

function CombatGui:showDamageTaken()
    -- Big Shake
    CombatGui:shakeScreen(8, 0.4)
    
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1,0,1,0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    flash.BackgroundTransparency = 0.8
    flash.Parent = CombatGui.combatGui
    
    local t = TweenService:Create(flash, TweenInfo.new(0.5), {BackgroundTransparency = 1})
    t:Play()
    t.Completed:Connect(function() flash:Destroy() end)
end

-- Initialize the CombatGui when the module is loaded
CombatGui:init()

return CombatGui