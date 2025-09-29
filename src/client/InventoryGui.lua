-- LocalScript: InventoryGui.lua
-- Inventory interface for The Ember Games
-- Provides UI for managing player items and resources

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local InventoryRemoteEvent = ReplicatedStorage:WaitForChild("InventoryRemoteEvent")

local InventoryGui = {}
InventoryGui.inventoryGui = nil
InventoryGui.isVisible = false
InventoryGui.playerInventory = {
    slots = {},
    maxSize = 20,
    activeSlot = 1
}

-- Create inventory UI
local function createInventoryUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryInterface"
    screenGui.Parent = PlayerGui
    
    -- Main Inventory Frame
    local inventoryFrame = Instance.new("Frame")
    inventoryFrame.Name = "InventoryFrame"
    inventoryFrame.Size = UDim2.new(0, 700, 0, 500)
    inventoryFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    inventoryFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    inventoryFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    inventoryFrame.Visible = false
    inventoryFrame.Parent = screenGui
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "INVENTORY"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    titleLabel.Parent = inventoryFrame
    
    -- Inventory Grid
    local inventoryGrid = Instance.new("Frame")
    inventoryGrid.Name = "InventoryGrid"
    inventoryGrid.Size = UDim2.new(1, -20, 1, -70)
    inventoryGrid.Position = UDim2.new(0, 10, 0, 50)
    inventoryGrid.BackgroundTransparency = 1
    inventoryGrid.Parent = inventoryFrame
    
    -- Create 4x5 grid of slots (20 total)
    local slotSize = 80
    local slotPadding = 10
    
    for row = 0, 3 do
        for col = 0, 4 do
            local slotIndex = row * 5 + col + 1
            
            local slotFrame = Instance.new("TextButton")
            slotFrame.Name = "Slot" .. slotIndex
            slotFrame.Size = UDim2.new(0, slotSize, 0, slotSize)
            slotFrame.Position = UDim2.new(0, col * (slotSize + slotPadding), 0, row * (slotSize + slotPadding))
            slotFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            slotFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
            slotFrame.Text = ""
            slotFrame.Parent = inventoryGrid
            
            -- Item Icon/Display
            local itemDisplay = Instance.new("ImageLabel")
            itemDisplay.Name = "ItemDisplay"
            itemDisplay.Size = UDim2.new(0, 50, 0, 50)
            itemDisplay.Position = UDim2.new(0, 15, 0, 5)
            itemDisplay.BackgroundTransparency = 1
            itemDisplay.Image = "" -- Would be set based on item
            itemDisplay.Parent = slotFrame
            
            -- Item Count
            local itemCount = Instance.new("TextLabel")
            itemCount.Name = "ItemCount"
            itemCount.Size = UDim2.new(0, 25, 0, 20)
            itemCount.Position = UDim2.new(1, -30, 1, -25)
            itemCount.BackgroundTransparency = 1
            itemCount.Text = ""
            itemCount.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemCount.Font = Enum.Font.GothamBold
            itemCount.TextScaled = true
            itemCount.Parent = slotFrame
            
            -- Slot number indicator
            local slotNumber = Instance.new("TextLabel")
            slotNumber.Name = "SlotNumber"
            slotNumber.Size = UDim2.new(0, 20, 0, 15)
            slotNumber.Position = UDim2.new(0, 5, 0, 5)
            slotNumber.BackgroundTransparency = 1
            slotNumber.Text = tostring(slotIndex)
            slotNumber.TextColor3 = Color3.fromRGB(150, 150, 150)
            slotNumber.Font = Enum.Font.GothamBold
            slotNumber.TextScaled = true
            slotNumber.Parent = slotFrame
            
            -- Connect slot click for item usage
            slotFrame.MouseButton1Click:Connect(function()
                InventoryGui:useItem(slotIndex)
            end)
            
            -- Connect drag and drop
            slotFrame.MouseButton1Down:Connect(function()
                InventoryGui:startDrag(slotIndex)
            end)
        end
    end
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 60, 0, 30)
    closeButton.Position = UDim2.new(1, -70, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    closeButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "CLOSE"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextScaled = true
    closeButton.Parent = inventoryFrame
    
    -- Quick Access Bar (for hotbar)
    local quickAccessFrame = Instance.new("Frame")
    quickAccessFrame.Name = "QuickAccessFrame"
    quickAccessFrame.Size = UDim2.new(0, 350, 0, 60)
    quickAccessFrame.Position = UDim2.new(0.5, -175, 1, -100)
    quickAccessFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    quickAccessFrame.BackgroundTransparency = 0.7
    quickAccessFrame.BorderSizePixel = 0
    quickAccessFrame.Parent = screenGui
    
    -- Create 6 quick access slots (1-6)
    for i = 1, 6 do
        local slot = Instance.new("TextButton")
        slot.Name = "QuickSlot" .. i
        slot.Size = UDim2.new(0, 50, 0, 50)
        slot.Position = UDim2.new(0, (i-1)*60 + 5, 0, 5)
        slot.BackgroundColor3 = i == InventoryGui.playerInventory.activeSlot and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(50, 50, 50)
        slot.BorderColor3 = Color3.fromRGB(100, 100, 100)
        slot.Text = i
        slot.TextColor3 = Color3.fromRGB(255, 255, 255)
        slot.Font = Enum.Font.GothamBold
        slot.TextScaled = true
        slot.Parent = quickAccessFrame
        
        -- Connect quick slot
        slot.MouseButton1Click:Connect(function()
            InventoryGui:selectQuickSlot(i)
        end)
    end
    
    -- Store references
    InventoryGui.inventoryGui = screenGui
    
    return screenGui
end

-- Show inventory interface
function InventoryGui:showInventory()
    if InventoryGui.inventoryGui then
        InventoryGui.inventoryGui.InventoryFrame.Visible = true
        InventoryGui.isVisible = true
        
        -- Request full inventory update
        InventoryRemoteEvent:FireServer("REQUEST_INVENTORY")
    end
end

-- Hide inventory interface
function InventoryGui:hideInventory()
    if InventoryGui.inventoryGui then
        InventoryGui.inventoryGui.InventoryFrame.Visible = false
        InventoryGui.isVisible = false
    end
end

-- Toggle inventory interface
function InventoryGui:toggleInventory()
    if InventoryGui.isVisible then
        InventoryGui:hideInventory()
    else
        InventoryGui:showInventory()
    end
end

-- Select a quick access slot
function InventoryGui:selectQuickSlot(slotNumber)
    if not InventoryGui.inventoryGui then return end
    
    -- Update active slot visually
    for i = 1, 6 do
        local slot = InventoryGui.inventoryGui.QuickAccessFrame:FindFirstChild("QuickSlot" .. i)
        if slot then
            slot.BackgroundColor3 = i == slotNumber and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(50, 50, 50)
        end
    end
    
    -- Update internal state
    InventoryGui.playerInventory.activeSlot = slotNumber
    
    print("Selected quick slot: " .. slotNumber)
end

-- Use item from slot
function InventoryGui:useItem(slotIndex)
    if InventoryGui.playerInventory.slots[slotIndex] and InventoryGui.playerInventory.slots[slotIndex].name then
        local itemName = InventoryGui.playerInventory.slots[slotIndex].name
        print("Using item: " .. itemName .. " from slot " .. slotIndex)
        
        -- Request server to use item
        InventoryRemoteEvent:FireServer("USE_ITEM", itemName)
    end
end

-- Update inventory UI with new item data
function InventoryGui:updateInventoryUI()
    if not InventoryGui.inventoryGui then return end
    
    local inventoryGrid = InventoryGui.inventoryGui.InventoryFrame.InventoryGrid
    
    for slotIndex = 1, 20 do
        local slotFrame = inventoryGrid:FindFirstChild("Slot" .. slotIndex)
        if slotFrame then
            local itemDisplay = slotFrame:FindFirstChild("ItemDisplay")
            local itemCount = slotFrame:FindFirstChild("ItemCount")
            
            if InventoryGui.playerInventory.slots[slotIndex] then
                local slotData = InventoryGui.playerInventory.slots[slotIndex]
                
                if slotData.name then
                    -- This would be linked to actual item icons in a full implementation
                    itemDisplay.Image = "" -- Placeholder
                    itemDisplay.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                    
                    if slotData.amount > 1 then
                        itemCount.Text = tostring(slotData.amount)
                        itemCount.Visible = true
                    else
                        itemCount.Visible = false
                    end
                else
                    itemDisplay.Image = ""
                    itemDisplay.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    itemCount.Visible = false
                end
            else
                itemDisplay.Image = ""
                itemDisplay.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                itemCount.Visible = false
            end
        end
    end
end

-- Start drag operation for item movement
function InventoryGui:startDrag(slotIndex)
    print("Starting drag from slot: " .. slotIndex)
    -- In a full implementation, this would handle drag and drop between slots
end

-- Initialize InventoryGui
function InventoryGui:init()
    print("InventoryGui initialized")
    
    -- Create UI
    createInventoryUI()
    
    -- Connect close button
    if InventoryGui.inventoryGui then
        local closeButton = InventoryGui.inventoryGui.InventoryFrame.CloseButton
        closeButton.MouseButton1Click:Connect(function()
            InventoryGui:hideInventory()
        end)
    end
    
    -- Setup keyboard input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Toggle inventory with 'Tab' key
        if input.KeyCode == Enum.KeyCode.Tab then
            InventoryGui:toggleInventory()
        end
        
        -- Quick slots 1-6
        if input.KeyCode == Enum.KeyCode.One then
            InventoryGui:selectQuickSlot(1)
        elseif input.KeyCode == Enum.KeyCode.Two then
            InventoryGui:selectQuickSlot(2)
        elseif input.KeyCode == Enum.KeyCode.Three then
            InventoryGui:selectQuickSlot(3)
        elseif input.KeyCode == Enum.KeyCode.Four then
            InventoryGui:selectQuickSlot(4)
        elseif input.KeyCode == Enum.KeyCode.Five then
            InventoryGui:selectQuickSlot(5)
        elseif input.KeyCode == Enum.KeyCode.Six then
            InventoryGui:selectQuickSlot(6)
        end
    end)
    
    -- Connect to inventory events
    InventoryRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
        local args = {...}
        
        if eventType == "ITEM_ADDED" then
            local itemName, amount, slotIndex = args[1], args[2], args[3]
            print("Item added: " .. itemName .. " x" .. amount .. " in slot " .. slotIndex)
            
            -- Update internal inventory
            if not InventoryGui.playerInventory.slots[slotIndex] then
                InventoryGui.playerInventory.slots[slotIndex] = {name = itemName, amount = 0, metadata = {}}
            end
            InventoryGui.playerInventory.slots[slotIndex].name = itemName
            InventoryGui.playerInventory.slots[slotIndex].amount = InventoryGui.playerInventory.slots[slotIndex].amount + amount
            
            -- Update UI
            InventoryGui:updateInventoryUI()
        elseif eventType == "ITEM_REMOVED" then
            local itemName, amount, slotIndex = args[1], args[2], args[3]
            print("Item removed: " .. itemName .. " x" .. amount .. " from slot " .. slotIndex)
            
            -- Update internal inventory
            if InventoryGui.playerInventory.slots[slotIndex] and InventoryGui.playerInventory.slots[slotIndex].name == itemName then
                InventoryGui.playerInventory.slots[slotIndex].amount = math.max(0, InventoryGui.playerInventory.slots[slotIndex].amount - amount)
                
                if InventoryGui.playerInventory.slots[slotIndex].amount <= 0 then
                    InventoryGui.playerInventory.slots[slotIndex] = {name = nil, amount = 0, metadata = {}}
                end
            end
            
            -- Update UI
            InventoryGui:updateInventoryUI()
        elseif eventType == "ITEM_USED" then
            local itemName, slotIndex = args[1], args[2]
            print("Item used: " .. itemName .. " from slot " .. slotIndex)
            
            -- Update internal inventory
            if InventoryGui.playerInventory.slots[slotIndex] and InventoryGui.playerInventory.slots[slotIndex].name == itemName then
                InventoryGui.playerInventory.slots[slotIndex].amount = math.max(0, InventoryGui.playerInventory.slots[slotIndex].amount - 1)
                
                if InventoryGui.playerInventory.slots[slotIndex].amount <= 0 then
                    InventoryGui.playerInventory.slots[slotIndex] = {name = nil, amount = 0, metadata = {}}
                end
            end
            
            -- Update UI
            InventoryGui:updateInventoryUI()
        elseif eventType == "INVENTORY_FULL" then
            local itemName, amount = args[1], args[2]
            print("Inventory full! Could not add: " .. itemName .. " x" .. amount)
            -- Show error to player in UI
        elseif eventType == "FULL_INVENTORY_UPDATE" then
            local inventoryData = args[1]
            InventoryGui.playerInventory = inventoryData
            InventoryGui:updateInventoryUI()
            print("Received full inventory update")
        elseif eventType == "SLOTS_SWAPPED" then
            local fromSlot, toSlot = args[1], args[2]
            local fromData, toData = args[3], args[4]
            
            InventoryGui.playerInventory.slots[fromSlot] = fromData
            InventoryGui.playerInventory.slots[toSlot] = toData
            
            InventoryGui:updateInventoryUI()
            print("Swapped slots " .. fromSlot .. " and " .. toSlot)
        end
    end)
    
    print("InventoryGui initialized and connected to events")
end

-- Initialize the InventoryGui when the module is loaded
InventoryGui:init()

return InventoryGui