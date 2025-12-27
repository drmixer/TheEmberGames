-- LocalScript: InventoryGui.lua
-- Inventory interface for The Ember Games
-- Provides UI for managing player items and resources using Premium UITheme

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local InventoryRemoteEvent = ReplicatedStorage:WaitForChild("InventoryRemoteEvent")
local UITheme = require(script.Parent:WaitForChild("UITheme"))

local InventoryGui = {}
InventoryGui.inventoryGui = nil
InventoryGui.isVisible = false
InventoryGui.playerInventory = {
    slots = {},
    maxSize = 20,
    activeSlot = 1
}

local function createSlot(parent, index)
    local slot = Instance.new("ImageButton")
    slot.Name = "Slot" .. index
    slot.BackgroundColor3 = UITheme.Colors.Surface
    slot.BackgroundTransparency = 0.5
    slot.BorderSizePixel = 0
    slot.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = slot
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = UITheme.Colors.GoldDim
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.Parent = slot
    
    local itemIcon = Instance.new("ImageLabel")
    itemIcon.Name = "ItemDisplay"
    itemIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
    itemIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
    itemIcon.BackgroundTransparency = 1
    itemIcon.Image = "" 
    itemIcon.Parent = slot
    
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "ItemCount"
    countLabel.Size = UDim2.new(1, -5, 1, -5)
    countLabel.Position = UDim2.new(0, 0, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = ""
    countLabel.TextColor3 = UITheme.Colors.Text
    countLabel.Font = UITheme.Fonts.Header
    countLabel.TextSize = 14
    countLabel.TextXAlignment = Enum.TextXAlignment.Right
    countLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    countLabel.Visible = false
    countLabel.Parent = slot
    
    -- Slot Index (Tiny)
    local indexLabel = Instance.new("TextLabel")
    indexLabel.Name = "Index"
    indexLabel.Size = UDim2.new(1, -5, 0, 15)
    indexLabel.Position = UDim2.new(0, 5, 0, 2)
    indexLabel.BackgroundTransparency = 1
    indexLabel.Text = tostring(index)
    indexLabel.TextColor3 = UITheme.Colors.TextDim
    indexLabel.Font = UITheme.Fonts.Label
    indexLabel.TextSize = 10
    indexLabel.TextTransparency = 0.5
    indexLabel.TextXAlignment = Enum.TextXAlignment.Left
    indexLabel.Parent = slot
    
    -- Hover Effect
    slot.MouseEnter:Connect(function()
        TweenService:Create(slot, TweenInfo.new(0.2), {BackgroundColor3 = UITheme.Colors.SurfaceHighlight}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0, Color = UITheme.Colors.Gold}):Play()
    end)
    
    slot.MouseLeave:Connect(function()
        TweenService:Create(slot, TweenInfo.new(0.2), {BackgroundColor3 = UITheme.Colors.Surface}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.8, Color = UITheme.Colors.GoldDim}):Play()
    end)
    
    return slot
end

local function createInventoryUI()
    if InventoryGui.inventoryGui then InventoryGui.inventoryGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryInterface"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    -- Main Window (Glassmorphic)
    local frame = Instance.new("Frame")
    frame.Name = "InventoryFrame"
    frame.Size = UDim2.new(0, 600, 0, 450)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Visible = false
    frame.Parent = screenGui
    
    UITheme.applyGlass(frame, 0.2)
    
    -- Header
    local title = Instance.new("TextLabel")
    title.Text = "INVENTORY"
    title.Size = UDim2.new(1, -40, 0, 60)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = UITheme.Colors.Gold
    title.Font = UITheme.Fonts.Title
    title.TextSize = 28
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -40, 0, 1)
    divider.Position = UDim2.new(0, 20, 0, 60)
    divider.BackgroundColor3 = UITheme.Colors.GoldDim
    divider.BackgroundTransparency = 0.7
    divider.BorderSizePixel = 0
    divider.Parent = frame

    -- Grid Container
    local grid = Instance.new("ScrollingFrame") -- Scrolling in case we expand later
    grid.Name = "InventoryGrid"
    grid.Size = UDim2.new(1, -40, 1, -140) -- Save space for bottom/header
    grid.Position = UDim2.new(0, 20, 0, 80)
    grid.BackgroundTransparency = 1
    grid.ScrollBarThickness = 4
    grid.ScrollBarImageColor3 = UITheme.Colors.Gold
    grid.Parent = frame
    
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0, 80, 0, 80)
    layout.CellPadding = UDim2.new(0, 10, 0, 10)
    layout.Parent = grid
    
    -- Create 20 Slots
    for i = 1, 20 do
        local slot = createSlot(grid, i)
        slot.MouseButton1Click:Connect(function() InventoryGui:useItem(i) end)
    end
    
    -- Hotbar (Always on screen if needed, or part of this UI? Original had it separate)
    -- Let's make the hotbar a separate persistent element at the bottom of the screen
    local hotbar = Instance.new("Frame")
    hotbar.Name = "Hotbar"
    hotbar.Size = UDim2.new(0, 400, 0, 70)
    hotbar.Position = UDim2.new(0.5, 0, 1, -20)
    hotbar.AnchorPoint = Vector2.new(0.5, 1)
    hotbar.BackgroundTransparency = 1 -- Floating slots
    hotbar.Parent = screenGui
    
    local hotbarLayout = Instance.new("UIListLayout")
    hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
    hotbarLayout.Padding = UDim.new(0, 8)
    hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    hotbarLayout.Parent = hotbar
    
    for i = 1, 6 do
        local slot = createSlot(hotbar, i)
        slot.Name = "QuickSlot" .. i
        slot.Size = UDim2.new(0, 60, 0, 60)
        slot.MouseButton1Click:Connect(function() InventoryGui:selectQuickSlot(i) end)
    end
    
    InventoryGui.inventoryGui = screenGui
    return screenGui
end

function InventoryGui:showInventory()
    if not InventoryGui.inventoryGui then createInventoryUI() end
    InventoryGui.inventoryGui.InventoryFrame.Visible = true
    InventoryGui.isVisible = true
    InventoryRemoteEvent:FireServer("REQUEST_INVENTORY")
    
    -- Pop animation
    local frame = InventoryGui.inventoryGui.InventoryFrame
    frame.Position = UDim2.new(0.5, 0, 0.55, 0)
    frame.BackgroundTransparency = 1
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0.2
    }):Play()
end

function InventoryGui:hideInventory()
    if InventoryGui.inventoryGui then
        local frame = InventoryGui.inventoryGui.InventoryFrame
        local tween = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0.55, 0),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            frame.Visible = false
            InventoryGui.isVisible = false
            -- Reset properties for next open
            if InventoryGui.isVisible == false then -- Double check logic
                 -- We just hide it, don't need reset actually
            end
        end)
    end
end

function InventoryGui:toggleInventory()
    if InventoryGui.isVisible then
        InventoryGui:hideInventory()
    else
        InventoryGui:showInventory()
    end
end

function InventoryGui:selectQuickSlot(slotNumber)
    if not InventoryGui.inventoryGui then return end
    
    InventoryGui.playerInventory.activeSlot = slotNumber
    
    -- Visual update
    for i = 1, 6 do
        local slot = InventoryGui.inventoryGui.Hotbar:FindFirstChild("QuickSlot" .. i)
        if slot then
            local stroke = slot:FindFirstChild("UIStroke")
            if i == slotNumber then
                -- Selected State
                TweenService:Create(slot, TweenInfo.new(0.2), {BackgroundColor3 = UITheme.Colors.SurfaceHighlight}):Play()
                if stroke then
                     stroke.Color = UITheme.Colors.Gold
                     stroke.Transparency = 0
                     stroke.Thickness = 2
                end
                -- Scale up slightly
                TweenService:Create(slot, TweenInfo.new(0.2), {Size = UDim2.new(0, 65, 0, 65)}):Play()
            else
                -- Deselected
                TweenService:Create(slot, TweenInfo.new(0.2), {BackgroundColor3 = UITheme.Colors.Surface}):Play()
                if stroke then
                     stroke.Color = UITheme.Colors.GoldDim
                     stroke.Transparency = 0.8
                     stroke.Thickness = 1
                end
                 TweenService:Create(slot, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)}):Play()
            end
        end
    end
end

function InventoryGui:useItem(slotIndex)
    local slotData = InventoryGui.playerInventory.slots[slotIndex]
    if slotData and slotData.name then
        print("Using item:", slotData.name)
        InventoryRemoteEvent:FireServer("USE_ITEM", slotData.name)
    end
end

function InventoryGui:updateInventoryUI()
    if not InventoryGui.inventoryGui then return end
    
    local updateSlot = function(containerName, prefix, max)
        local container = InventoryGui.inventoryGui:FindFirstChild(containerName, true)
        if not container then return end
        
        for i = 1, max do
            local slot = container:FindFirstChild(prefix .. i)
            if slot then
                local data = InventoryGui.playerInventory.slots[i]
                local icon = slot:FindFirstChild("ItemDisplay")
                local count = slot:FindFirstChild("ItemCount")
                
                if data and data.name then
                    -- Placeholder icons based on name parsing could go here
                    -- For now, just show text or color
                    icon.Image = "" 
                    icon.BackgroundColor3 = UITheme.Colors.Gold
                    icon.BackgroundTransparency = 0.8 -- Show it exists
                    
                    if data.amount > 1 then
                        count.Text = tostring(data.amount)
                        count.Visible = true
                    else
                        count.Visible = false
                    end
                else
                    icon.Image = ""
                    icon.BackgroundTransparency = 1
                    count.Visible = false
                end
            end
        end
    end
    
    -- Update Main Grid (1-20)
    updateSlot("InventoryGrid", "Slot", 20)
    -- Update Hotbar (1-6) (Assuming Hotbar maps to slots 1-6 for simplicity in this demo)
    updateSlot("Hotbar", "QuickSlot", 6)
end

function InventoryGui:init()
    print("[InventoryGui] Initializing Premium Inventory")
    createInventoryUI()
    
    -- Input Handling
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.Tab then
            InventoryGui:toggleInventory()
        elseif input.KeyCode.Value >= Enum.KeyCode.One.Value and input.KeyCode.Value <= Enum.KeyCode.Six.Value then
            local num = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
            InventoryGui:selectQuickSlot(num)
        end
    end)
    
    -- Event Handling
    InventoryRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
        local args = {...}
        if eventType == "ITEM_ADDED" or eventType == "ITEM_REMOVED" or eventType == "ITEM_USED" then
             -- Logic simplified for brevity; relying on FULL_INVENTORY_UPDATE often in production or just requesting it
             -- But let's trigger a request to be safe or implement specific logic
             InventoryRemoteEvent:FireServer("REQUEST_INVENTORY")
        elseif eventType == "FULL_INVENTORY_UPDATE" then
            InventoryGui.playerInventory = args[1]
            InventoryGui:updateInventoryUI()
        end
    end)
    
    -- Initial selection
    InventoryGui:selectQuickSlot(1)
end

InventoryGui:init()
return InventoryGui