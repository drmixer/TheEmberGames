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
CombatGui.playerInventory = {} -- Would be populated with real inventory system
CombatGui.combatEnabled = false
CombatGui.combatGui = nil

-- Create combat UI elements
local function createCombatUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CombatInterface"
    screenGui.Parent = PlayerGui
    
    -- Weapon Selection Bar
    local weaponBar = Instance.new("Frame")
    weaponBar.Name = "WeaponBar"
    weaponBar.Size = UDim2.new(0, 300, 0, 60)
    weaponBar.Position = UDim2.new(0.5, -150, 1, -100)
    weaponBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    weaponBar.BackgroundTransparency = 0.5
    weaponBar.BorderSizePixel = 0
    weaponBar.Parent = screenGui
    
    -- Weapon slots (1-6)
    for i = 1, 6 do
        local weaponSlot = Instance.new("TextButton")
        weaponSlot.Name = "WeaponSlot" .. i
        weaponSlot.Size = UDim2.new(0, 40, 0, 40)
        weaponSlot.Position = UDim2.new(0, (i-1)*50 + 10, 0, 10)
        weaponSlot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        weaponSlot.BorderColor3 = Color3.fromRGB(100, 100, 100)
        weaponSlot.Text = i
        weaponSlot.TextColor3 = Color3.fromRGB(255, 255, 255)
        weaponSlot.Font = Enum.Font.GothamBold
        weaponSlot.TextScaled = true
        weaponSlot.Parent = weaponBar
        
        -- Hover effect
        weaponSlot.MouseEnter:Connect(function()
            weaponSlot.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end)
        
        weaponSlot.MouseLeave:Connect(function()
            if CombatGui.activeWeapon ~= i then
                weaponSlot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            else
                weaponSlot.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Active color
            end
        end)
        
        -- Select weapon
        weaponSlot.MouseButton1Click:Connect(function()
            CombatGui:selectWeapon(i)
        end)
    end
    
    -- Current Weapon Display
    local currentWeaponFrame = Instance.new("Frame")
    currentWeaponFrame.Name = "CurrentWeaponFrame"
    currentWeaponFrame.Size = UDim2.new(0, 200, 0, 40)
    currentWeaponFrame.Position = UDim2.new(0.5, -100, 1, -170)
    currentWeaponFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    currentWeaponFrame.BackgroundTransparency = 0.5
    currentWeaponFrame.BorderSizePixel = 0
    currentWeaponFrame.Parent = screenGui
    
    local currentWeaponLabel = Instance.new("TextLabel")
    currentWeaponLabel.Name = "CurrentWeaponLabel"
    currentWeaponLabel.Size = UDim2.new(1, 0, 1, 0)
    currentWeaponLabel.BackgroundTransparency = 1
    currentWeaponLabel.Text = "No Weapon"
    currentWeaponLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    currentWeaponLabel.Font = Enum.Font.Gotham
    currentWeaponLabel.TextScaled = true
    currentWeaponLabel.Parent = currentWeaponFrame
    
    -- Durability Display
    local durabilityFrame = Instance.new("Frame")
    durabilityFrame.Name = "DurabilityFrame"
    durabilityFrame.Size = UDim2.new(0, 200, 0, 20)
    durabilityFrame.Position = UDim2.new(0.5, -100, 1, -220)
    durabilityFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    durabilityFrame.BorderSizePixel = 0
    durabilityFrame.Visible = false
    durabilityFrame.Parent = screenGui
    
    local durabilityBar = Instance.new("Frame")
    durabilityBar.Name = "DurabilityBar"
    durabilityBar.Size = UDim2.new(1, 0, 1, 0)
    durabilityBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    durabilityBar.BorderSizePixel = 0
    durabilityBar.Parent = durabilityFrame
    
    -- Store references
    CombatGui.combatGui = screenGui
    
    return screenGui
end

-- Select a weapon
function CombatGui:selectWeapon(slotNumber)
    if not CombatGui.combatEnabled then return end
    
    -- In a real implementation, this would check if the player has a weapon in this slot
    local weaponNames = {"Stick", "Spear", "Knife", "Bow", "Axe", "Machete"}
    local selectedWeapon = weaponNames[slotNumber]
    
    if selectedWeapon then
        CombatGui.activeWeapon = slotNumber
        CombatGui.activeWeaponName = selectedWeapon
        
        -- Update UI
        if CombatGui.combatGui then
            local currentWeaponLabel = CombatGui.combatGui:FindFirstChild("CurrentWeaponFrame"):FindFirstChild("CurrentWeaponLabel")
            if currentWeaponLabel then
                currentWeaponLabel.Text = selectedWeapon
            end
            
            -- Highlight selected slot
            for i = 1, 6 do
                local slot = CombatGui.combatGui.WeaponBar:FindFirstChild("WeaponSlot" .. i)
                if slot then
                    if i == slotNumber then
                        slot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                    else
                        slot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    end
                end
            end
        end
        
        print("Selected weapon: " .. selectedWeapon)
    end
end

-- Perform a melee attack
function CombatGui:meleeAttack()
    if not CombatGui.combatEnabled then return end
    if not CombatGui.activeWeaponName then
        print("No weapon selected")
        return
    end
    
    -- Check if weapon is melee
    local meleeWeapons = {"Stick", "Spear", "Knife", "Axe", "Machete", "Rock"}
    local isMelee = false
    
    for _, weapon in pairs(meleeWeapons) do
        if CombatGui.activeWeaponName == weapon then
            isMelee = true
            break
        end
    end
    
    if isMelee then
        -- Tell server to detect nearby targets
        WeaponRemoteEvent:FireServer("SWING_WEAPON", CombatGui.activeWeaponName)
    else
        -- Ranged attack would be handled differently
        print("Ranged attack with " .. CombatGui.activeWeaponName .. " not implemented in this demo")
    end
end

-- Initialize combat system
function CombatGui:init()
    print("CombatGui initialized")
    
    -- Create UI
    createCombatUI()
    
    -- Enable combat once player is ready
    task.wait(2) -- Wait for other systems to initialize
    CombatGui.combatEnabled = true
    if CombatGui.combatGui then
        CombatGui.combatGui.Enabled = true
    end
    
    -- Connect to input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Number keys 1-6 to select weapons
        if CombatGui.combatEnabled then
            if input.KeyCode == Enum.KeyCode.One then
                CombatGui:selectWeapon(1)
            elseif input.KeyCode == Enum.KeyCode.Two then
                CombatGui:selectWeapon(2)
            elseif input.KeyCode == Enum.KeyCode.Three then
                CombatGui:selectWeapon(3)
            elseif input.KeyCode == Enum.KeyCode.Four then
                CombatGui:selectWeapon(4)
            elseif input.KeyCode == Enum.KeyCode.Five then
                CombatGui:selectWeapon(5)
            elseif input.KeyCode == Enum.KeyCode.Six then
                CombatGui:selectWeapon(6)
            elseif input.KeyCode == Enum.KeyCode.F then
                -- Primary attack key
                CombatGui:meleeAttack()
            end
        end
    end)
    
    -- Connect to damage events
    DamageRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
        local args = {...}
        
        if eventType == "PLAYER_DAMAGE" then
            local victimUserId, damage, isCritical = args[1], args[2], args[3]
            
            local victimPlayer = Players:GetPlayerByUserId(victimUserId)
            if victimPlayer then
                print(victimPlayer.Name .. " took " .. damage .. " damage" .. (isCritical and " (CRITICAL!)" or ""))
                
                -- Visual feedback for damage
                if victimPlayer == Player then
                    CombatGui:showDamageFeedback(damage, isCritical)
                end
            end
        end
    end)
    
    -- Connect to weapon events
    WeaponRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
        local args = {...}
        
        if eventType == "WEAPON_BROKEN" then
            local weaponType = args[1]
            print("Your " .. weaponType .. " has broken!")
            
            -- Visual feedback
            if CombatGui.combatGui then
                local currentWeaponLabel = CombatGui.combatGui:FindFirstChild("CurrentWeaponFrame"):FindFirstChild("CurrentWeaponLabel")
                if currentWeaponLabel then
                    currentWeaponLabel.Text = "BROKEN"
                    currentWeaponLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red
                end
            end
            
            -- Reset weapon selection
            CombatGui.activeWeapon = nil
            CombatGui.activeWeaponName = nil
        elseif eventType == "WEAPON_DURABILITY_UPDATE" then
            local weaponType, durability = args[1], args[2]
            
            print(weaponType .. " durability: " .. durability)
            
            -- Update durability UI if this is the current weapon
            if weaponType == CombatGui.activeWeaponName and CombatGui.combatGui then
                local durabilityFrame = CombatGui.combatGui:FindFirstChild("DurabilityFrame")
                local durabilityBar = durabilityFrame and durabilityFrame:FindFirstChild("DurabilityBar")
                
                if durabilityBar then
                    durabilityFrame.Visible = true
                    
                    -- Calculate durability ratio
                    local maxDurability = 25 -- This would be specific to each weapon type in full implementation
                    local ratio = durability / maxDurability
                    ratio = math.clamp(ratio, 0, 1)
                    
                    -- Update bar size and color
                    durabilityBar:TweenSize(UDim2.new(ratio, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
                    
                    -- Change color based on durability level
                    if ratio > 0.5 then
                        durabilityBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green
                    elseif ratio > 0.25 then
                        durabilityBar.BackgroundColor3 = Color3.fromRGB(255, 255, 100) -- Yellow
                    else
                        durabilityBar.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Red
                    end
                end
            end
        end
    end)
    
    print("CombatGui initialized and ready")
end

-- Show damage feedback to player
function CombatGui:showDamageFeedback(damage, isCritical)
    -- Create a damage indicator that briefly appears
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DamageIndicator"
    screenGui.Parent = PlayerGui
    
    local damageLabel = Instance.new("TextLabel")
    damageLabel.Size = UDim2.new(0, 200, 0, 50)
    damageLabel.Position = UDim2.new(0.5, -100, 0.5, -25)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = (isCritical and "CRITICAL! " or "") .. "-" .. damage
    damageLabel.TextColor3 = isCritical and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 200, 200)
    damageLabel.Font = Enum.Font.GothamBold
    damageLabel.TextScaled = true
    damageLabel.Parent = screenGui
    
    -- Animate the damage indicator
    local startSize = damageLabel.TextScaled and UDim2.new(0, 200, 0, 50) or damageLabel.Size
    local endSize = UDim2.new(0, 300, 0, 75)
    
    damageLabel.Size = endSize
    damageLabel.TextTransparency = 0
    
    -- Tween up and fade out
    local info = TweenInfo.new(
        1,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out,
        0,
        false,
        0
    )
    
    local tween = TweenService:Create(damageLabel, info, {
        Position = UDim2.new(0.5, -100, 0.3, -25),
        TextTransparency = 1
    })
    
    tween:Play()
    
    -- Clean up after animation
    tween.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

-- Initialize the CombatGui when the module is loaded
CombatGui:init()

return CombatGui