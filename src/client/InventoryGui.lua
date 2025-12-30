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
InventoryGui.hotbarMapping = {} -- [VisualSlotIndex (1-6)] = InventorySlotIndex (1-20)

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
    
    -- Use mapping to get real inventory index
    local realIndex = InventoryGui.hotbarMapping[slotNumber]
    
    -- If mapped to a real slot, select it
    if realIndex then
         InventoryGui.playerInventory.activeSlot = realIndex
         InventoryGui:useItem(realIndex)
    else
         -- Empty visual slot selected
         InventoryGui.playerInventory.activeSlot = -1
    end
    
    -- Visual update (Highlighting the VISUAL slot)
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
        
        -- Check if it is an equippable tool first
        local player = Players.LocalPlayer
        if player then
             local backpack = player:FindFirstChild("Backpack")
             local character = player.Character
             
             if backpack and character then
                 local humanoid = character:FindFirstChild("Humanoid")
                 
                 -- Is it in Backpack? Equip it.
                 local tool = backpack:FindFirstChild(slotData.name)
                 if tool and humanoid then
                     humanoid:EquipTool(tool)
                     return -- Done, it was a weapon
                 end
                 
                 -- Is it already equipped?
                 local equipped = character:FindFirstChild(slotData.name)
                 if equipped then
                     -- Already holding it, nothing to do
                     return 
                 end
                 
                 -- If not a tool, it might be a consumable handled by server
             end
        end
        
        -- Fallback to server use (for consumables like Food/Meds)
        InventoryRemoteEvent:FireServer("USE_ITEM", slotData.name)
    end
end

function InventoryGui:updateInventoryUI()
    if not InventoryGui.inventoryGui then return end
    
    local function createWeaponPreview(weaponName)
        local model = Instance.new("Model")
        
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.5, 3, 0.5)
        handle.Anchored = true
        handle.CanCollide = false
        handle.Material = Enum.Material.Wood
        handle.Color = Color3.fromRGB(139, 90, 43)
        handle.Parent = model
        
        -- Simple customizations
        if string.find(weaponName, "Stick") then
            handle.Size = Vector3.new(0.3, 3.5, 0.3)
            -- Branch
            local b = Instance.new("Part")
            b.Size = Vector3.new(0.2, 1, 0.2)
            b.Color = handle.Color
            b.Material = handle.Material
            b.Anchored = true; b.CanCollide = false
            b.CFrame = handle.CFrame * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(45))
            b.Parent = model
        elseif string.find(weaponName, "Spear") then
             handle.Size = Vector3.new(0.2, 6, 0.2)
             local tip = Instance.new("Part")
             tip.Size = Vector3.new(0.3, 1, 0.3)
             tip.Color = Color3.fromRGB(150, 150, 150)
             tip.Material = Enum.Material.Metal
             tip.Anchored = true; tip.CanCollide = false
             tip.CFrame = handle.CFrame * CFrame.new(0, 3.5, 0)
             tip.Parent = model
        elseif string.find(weaponName, "Sword") or string.find(weaponName, "Machete") then
             handle.Size = Vector3.new(0.3, 1, 0.3)
             local blade = Instance.new("Part")
             blade.Size = Vector3.new(0.2, 3, 0.5)
             blade.Color = string.find(weaponName, "Ice") and Color3.fromRGB(180, 230, 255) or Color3.fromRGB(150, 150, 160)
             blade.Material = string.find(weaponName, "Ice") and Enum.Material.Ice or Enum.Material.Metal
             blade.Anchored = true; blade.CanCollide = false
             blade.CFrame = handle.CFrame * CFrame.new(0, 2, 0)
             blade.Parent = model
        elseif string.find(weaponName, "Axe") then
             handle.Size = Vector3.new(0.3, 3, 0.3)
             local head = Instance.new("Part")
             head.Size = Vector3.new(1.5, 1, 0.3)
             head.Color = Color3.fromRGB(100, 100, 100)
             head.Material = Enum.Material.Metal
             head.Anchored = true; head.CanCollide = false
             head.CFrame = handle.CFrame * CFrame.new(0, 1, 0)
             head.Parent = model
        elseif string.find(weaponName, "Bow") then
             handle.Size = Vector3.new(0.2, 4, 0.5)
             handle.Color = Color3.fromRGB(100, 70, 40)
             local stringP = Instance.new("Part")
             stringP.Size = Vector3.new(0.05, 4, 0.05)
             stringP.Color = Color3.new(1,1,1)
             stringP.Anchored = true; stringP.CanCollide = false
             stringP.CFrame = handle.CFrame * CFrame.new(0, 0, 0.5)
             stringP.Parent = model
        elseif string.find(weaponName, "Slingshot") and not string.find(weaponName, "Ammo") then
             -- Slingshot Y-Shape
             handle.Size = Vector3.new(0.3, 1.5, 0.3)
             local left = Instance.new("Part"); left.Size=Vector3.new(0.2,0.8,0.2); left.Color=handle.Color; left.Anchored=true; left.CanCollide=false; left.CFrame=handle.CFrame*CFrame.new(-0.3,0.8,0)*CFrame.Angles(0,0,math.rad(30)); left.Parent=model
             local right = Instance.new("Part"); right.Size=Vector3.new(0.2,0.8,0.2); right.Color=handle.Color; right.Anchored=true; right.CanCollide=false; right.CFrame=handle.CFrame*CFrame.new(0.3,0.8,0)*CFrame.Angles(0,0,math.rad(-30)); right.Parent=model
        elseif string.find(weaponName, "Knife") then
             -- Dagger/Knife shape
             handle.Size = Vector3.new(0.2, 0.8, 0.2)
             local blade = Instance.new("Part")
             blade.Size = Vector3.new(0.1, 1.2, 0.4)
             blade.Color = Color3.fromRGB(180, 180, 190)
             blade.Material = Enum.Material.Metal
             blade.Anchored = true; blade.CanCollide = false
             blade.CFrame = handle.CFrame * CFrame.new(0, 1, 0)
             blade.Parent = model
        elseif weaponName == "Arrow" then
             handle.Size = Vector3.new(0.1, 0.1, 2)
             handle.Color = Color3.fromRGB(139, 90, 43)
             local f1 = Instance.new("Part"); f1.Size=Vector3.new(0.3,0.3,0.05); f1.Color=Color3.new(1,1,1); f1.Anchored=true; f1.CanCollide=false; f1.CFrame=handle.CFrame*CFrame.new(0,0,0.9); f1.Parent=model
             local t1 = Instance.new("Part"); t1.Size=Vector3.new(0.2,0.2,0.4); t1.Color=Color3.new(0.5,0.5,0.5); t1.Anchored=true; t1.CanCollide=false; t1.CFrame=handle.CFrame*CFrame.new(0,0,-1); t1.Parent=model
        elseif weaponName == "SlingshotAmmo" or weaponName == "Rock" then
             handle.Size = Vector3.new(0.8, 0.8, 0.8)
             handle.Shape = Enum.PartType.Ball
             handle.Color = Color3.fromRGB(100, 100, 100)
             handle.Material = Enum.Material.Slate
        end
        
        return model
    end

    local updateSlotVisual = function(slot, data)
        -- Helper to render a slot given data
        local icon = slot:FindFirstChild("ItemDisplay")
        local count = slot:FindFirstChild("ItemCount")
        
        -- Cleanup previous viewport
        local oldVp = slot:FindFirstChild("ItemViewport")
        if oldVp then oldVp:Destroy() end

        if data and data.name then
            slot.Visible = true 
            
            -- Check for required ammo to overlay count
            local ammoCountDisplay = nil
            if data.name == "Bow" then
               for _, invSlot in pairs(InventoryGui.playerInventory.slots) do
                   if invSlot.name == "Arrow" then ammoCountDisplay = invSlot.amount; break end
               end
            elseif data.name == "Slingshot" then
               for _, invSlot in pairs(InventoryGui.playerInventory.slots) do
                   if invSlot.name == "SlingshotAmmo" or invSlot.name == "Rock" then ammoCountDisplay = invSlot.amount; break end
               end
            end
            
            -- Create ViewportFrame
            local vp = Instance.new("ViewportFrame")
            vp.Name = "ItemViewport"
            vp.Size = UDim2.new(0.9, 0, 0.9, 0)
            vp.Position = UDim2.new(0.05, 0, 0.05, 0)
            vp.BackgroundTransparency = 1
            vp.Parent = slot
            
            local camera = Instance.new("Camera")
            vp.CurrentCamera = camera
            camera.Parent = vp
            
            local model = createWeaponPreview(data.name)
            model.Parent = vp
            
            -- Setup Camera (Generic Fit)
            local cf, size = model:GetBoundingBox()
            local dist = size.Magnitude * 1.2
            camera.CFrame = CFrame.new(cf.Position + Vector3.new(dist * 0.5, dist * 0.2, dist), cf.Position)
            
            icon.Image = "" 
            icon.Visible = false 
            
            if ammoCountDisplay then
                count.Text = tostring(ammoCountDisplay)
                count.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
                count.Visible = true
            elseif data.amount > 1 then
                count.Text = tostring(data.amount)
                count.TextColor3 = UITheme.Colors.Text
                count.Visible = true
            else
                count.Visible = false
            end
        else
            icon.Image = ""
            icon.Visible = true
            count.Visible = false
            -- Reset visibility check external
        end
    end

    -- Update Main Grid (1-20) - Direct Mapping
    local grid = InventoryGui.inventoryGui:FindFirstChild("InventoryGrid", true)
    if grid then
        for i = 1, 20 do
             local slot = grid:FindFirstChild("Slot" .. i)
             if slot then
                  local data = InventoryGui.playerInventory.slots[i]
                  updateSlotVisual(slot, data)
                  slot.Visible = true -- Always show grid slots
             end
        end
    end
    
    -- Update Hotbar (1-6) - Smart Mapping
    local hotbar = InventoryGui.inventoryGui:FindFirstChild("Hotbar", true)
    if hotbar then
        -- Reset mapping
        InventoryGui.hotbarMapping = {}
        
        -- Find eligible items for hotbar
        local eligibleIndices = {}
        for i, slotData in ipairs(InventoryGui.playerInventory.slots) do
            if slotData.name then
                 -- Filter out ammo (using string matching for variants like PoisonArrow)
                 local name = slotData.name
                 local isAmmo = (string.find(name, "Arrow") or string.find(name, "Ammo") or name == "Rock")
                 if not isAmmo then
                      table.insert(eligibleIndices, i)
                 end
            end
        end
        
        -- Fill Hotbar Slots
        for i = 1, 6 do
             local slot = hotbar:FindFirstChild("QuickSlot" .. i)
             if slot then
                  local invIndex = eligibleIndices[i]
                  if invIndex then
                       -- Map it
                       InventoryGui.hotbarMapping[i] = invIndex
                       local data = InventoryGui.playerInventory.slots[invIndex]
                       updateSlotVisual(slot, data)
                       slot.Visible = true
                  else
                       -- Empty / Hidden
                       updateSlotVisual(slot, nil)
                       updateSlotVisual(slot, nil)
                       slot.Visible = true -- Show empty slots so player knows they exist
                  end
             end
        end
    end
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