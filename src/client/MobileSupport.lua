-- ModuleScript: MobileSupport.lua
-- Mobile support for The Ember Games
-- Handles touch input and UI adjustments for mobile devices

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

local MobileSupport = {}
MobileSupport.isMobile = false
MobileSupport.mobileControls = nil

-- Initialize mobile support
function MobileSupport:init()
    print("MobileSupport initialized")
    
    -- Detect if playing on mobile (use TouchEnabled as GetPlatform is restricted)
    MobileSupport.isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    
    if MobileSupport.isMobile then
        print("Mobile device detected - optimizing for touch input")
        MobileSupport:setupMobileUI()
    else
        print("Non-mobile device detected - keeping standard UI")
    end
end

-- Setup mobile-optimized UI
function MobileSupport:setupMobileUI()
    -- Enable default mobile controls
    StarterGui:SetCore("TouchControlsEnabled", true)
    StarterGui:SetCore("VREnabled", false) -- Ensure VR is off for mobile
    
    print("Mobile UI optimized - default Roblox mobile controls enabled")
    
    -- Create custom mobile controls for important actions
    MobileSupport:createMobileControls()
end

-- Create mobile-specific control buttons
function MobileSupport:createMobileControls()
    local PlayerGui = Player:WaitForChild("PlayerGui")
    
    -- Create a screen GUI for mobile controls
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "MobileControls"
    mobileGui.Parent = PlayerGui
    
    -- Create a frame for bottom controls
    local bottomControls = Instance.new("Frame")
    bottomControls.Name = "BottomControls"
    bottomControls.Size = UDim2.new(1, 0, 0, 120)
    bottomControls.Position = UDim2.new(0, 0, 1, -120)
    bottomControls.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bottomControls.BackgroundTransparency = 0.7
    bottomControls.BorderSizePixel = 0
    bottomControls.Parent = mobileGui
    
    -- Inventory Button
    local inventoryBtn = Instance.new("TextButton")
    inventoryBtn.Name = "InventoryButton"
    inventoryBtn.Size = UDim2.new(0, 80, 0, 50)
    inventoryBtn.Position = UDim2.new(0, 20, 0, 10)
    inventoryBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 150)
    inventoryBtn.BorderColor3 = Color3.fromRGB(100, 100, 200)
    inventoryBtn.Text = "INV"
    inventoryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    inventoryBtn.Font = Enum.Font.GothamBold
    inventoryBtn.TextScaled = true
    inventoryBtn.Parent = bottomControls
    
    inventoryBtn.MouseButton1Click:Connect(function()
        local inventoryGui = PlayerGui:FindFirstChild("InventoryInterface")
        if inventoryGui then
            local frame = inventoryGui:FindFirstChild("InventoryFrame")
            if frame then
                frame.Visible = not frame.Visible
            end
        end
    end)
    
    -- Crafting Button
    local craftingBtn = inventoryBtn:Clone()
    craftingBtn.Name = "CraftingButton"
    craftingBtn.Position = UDim2.new(0, 110, 0, 10)
    craftingBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    craftingBtn.BorderColor3 = Color3.fromRGB(200, 100, 100)
    craftingBtn.Text = "CRAFT"
    craftingBtn.Parent = bottomControls
    
    craftingBtn.MouseButton1Click:Connect(function()
        local craftingGui = PlayerGui:FindFirstChild("CraftingInterface")
        if craftingGui then
            local frame = craftingGui:FindFirstChild("CraftingFrame")
            if frame then
                frame.Visible = not frame.Visible
            end
        end
    end)
    
    -- Emotes Button
    local emotesBtn = inventoryBtn:Clone()
    emotesBtn.Name = "EmotesButton"
    emotesBtn.Position = UDim2.new(0, 200, 0, 10)
    emotesBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    emotesBtn.BorderColor3 = Color3.fromRGB(100, 200, 100)
    emotesBtn.Text = "EMOTE"
    emotesBtn.Parent = bottomControls
    
    emotesBtn.MouseButton1Click:Connect(function()
        local emoteGui = PlayerGui:FindFirstChild("EmoteWheel")
        if emoteGui then
            local frame = emoteGui:FindFirstChild("EmoteWheelFrame")
            if frame then
                frame.Visible = not frame.Visible
            end
        end
    end)
    
    -- Attack Button
    local attackBtn = inventoryBtn:Clone()
    attackBtn.Name = "AttackButton"
    attackBtn.Position = UDim2.new(1, -100, 0, 10)
    attackBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    attackBtn.BorderColor3 = Color3.fromRGB(255, 100, 100)
    attackBtn.Text = "ATTACK"
    attackBtn.Parent = bottomControls
    
    attackBtn.MouseButton1Click:Connect(function()
        -- Trigger attack via CombatGui
        local CombatGui = require(script.Parent.CombatGui)
        if CombatGui then
            CombatGui:meleeAttack()
        end
    end)
    
    -- Health/Hunger/Thirst display for mobile
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "MobileStatsFrame"
    statsFrame.Size = UDim2.new(0, 200, 0, 100)
    statsFrame.Position = UDim2.new(1, -220, 0, 20)
    statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statsFrame.BackgroundTransparency = 0.7
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = mobileGui
    
    -- Health, Hunger, Thirst labels
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(1, 0, 0, 30)
    healthLabel.Position = UDim2.new(0, 0, 0, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "HEALTH: --"
    healthLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextScaled = true
    healthLabel.Parent = statsFrame
    
    local hungerLabel = healthLabel:Clone()
    hungerLabel.Name = "HungerLabel"
    hungerLabel.Position = UDim2.new(0, 0, 0, 35)
    hungerLabel.Text = "HUNGER: --"
    hungerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    hungerLabel.Parent = statsFrame
    
    local thirstLabel = healthLabel:Clone()
    thirstLabel.Name = "ThirstLabel"
    thirstLabel.Position = UDim2.new(0, 0, 0, 70)
    thirstLabel.Text = "THIRST: --"
    thirstLabel.TextColor3 = Color3.fromRGB(50, 150, 255)
    thirstLabel.Parent = statsFrame
    
    -- Connect to stats updates to update mobile UI
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StatsRemoteEvent = ReplicatedStorage:WaitForChild("StatsRemoteEvent", 10)
    
    if StatsRemoteEvent then
        StatsRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "STAT_UPDATE" then
                local statName, newValue = args[1], args[2]
                
                if statName == "health" then
                    healthLabel.Text = "HEALTH: " .. math.floor(newValue)
                elseif statName == "hunger" then
                    hungerLabel.Text = "HUNGER: " .. math.floor(newValue)
                elseif statName == "thirst" then
                    thirstLabel.Text = "THIRST: " .. math.floor(newValue)
                end
            elseif eventType == "INITIAL_STATS" then
                local stats = args[1]
                if stats then
                    healthLabel.Text = "HEALTH: " .. math.floor(stats.health or 100)
                    hungerLabel.Text = "HUNGER: " .. math.floor(stats.hunger or 100)
                    thirstLabel.Text = "THIRST: " .. math.floor(stats.thirst or 100)
                end
            end
        end)
    else
        warn("[MobileSupport] StatsRemoteEvent not found - mobile stats display may not work")
    end
    
    print("Mobile controls created")
end

-- Initialize MobileSupport when the module is loaded
MobileSupport:init()

return MobileSupport