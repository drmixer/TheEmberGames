-- LocalScript: ShopUI.lua
-- Premium shop interface for cosmetic purchases

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ShopUI = {}
ShopUI.isVisible = false
ShopUI.currentTab = "featured"
ShopUI.emberBalance = 0
ShopUI.shopData = nil

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    PANEL_COLOR = Color3.fromRGB(30, 30, 45),
    EMBER_COLOR = Color3.fromRGB(255, 150, 50),
}

local RARITY_COLORS = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(50, 150, 255),
    Epic = Color3.fromRGB(150, 50, 200),
    Legendary = Color3.fromRGB(255, 180, 50),
}

local function createShopItem(parent, item, category)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 150, 0, 200)
    card.BackgroundColor3 = CONFIG.PANEL_COLOR
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = RARITY_COLORS[item.rarity] or CONFIG.ACCENT_COLOR
    stroke.Thickness = 2
    stroke.Parent = card
    
    -- Item icon area
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(1, -20, 0, 100)
    iconFrame.Position = UDim2.new(0, 10, 0, 10)
    iconFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = card
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = iconFrame
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = item.type == "trail" and "🔥" or (item.type == "pose" and "🏆" or (item.type == "outfit" and "👕" or "📦"))
    iconLabel.TextSize = 48
    iconLabel.Parent = iconFrame
    
    -- Rarity badge
    if item.rarity then
        local rarityBadge = Instance.new("TextLabel")
        rarityBadge.Size = UDim2.new(0, 70, 0, 18)
        rarityBadge.Position = UDim2.new(0.5, -35, 0, 85)
        rarityBadge.BackgroundColor3 = RARITY_COLORS[item.rarity]
        rarityBadge.BorderSizePixel = 0
        rarityBadge.Text = item.rarity:upper()
        rarityBadge.TextColor3 = Color3.new(1, 1, 1)
        rarityBadge.TextSize = 10
        rarityBadge.Font = Enum.Font.GothamBold
        rarityBadge.Parent = iconFrame
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = rarityBadge
    end
    
    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 35)
    nameLabel.Position = UDim2.new(0, 5, 0, 115)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextWrapped = true
    nameLabel.Parent = card
    
    -- Price
    local priceFrame = Instance.new("Frame")
    priceFrame.Size = UDim2.new(1, -20, 0, 25)
    priceFrame.Position = UDim2.new(0, 10, 0, 150)
    priceFrame.BackgroundTransparency = 1
    priceFrame.Parent = card
    
    if item.originalEmbers then
        local originalPrice = Instance.new("TextLabel")
        originalPrice.Size = UDim2.new(0.5, 0, 1, 0)
        originalPrice.BackgroundTransparency = 1
        originalPrice.Text = item.originalEmbers
        originalPrice.TextColor3 = Color3.fromRGB(100, 100, 100)
        originalPrice.TextSize = 12
        originalPrice.Font = Enum.Font.Gotham
        -- Strikethrough effect
        local strike = Instance.new("Frame")
        strike.Size = UDim2.new(0.8, 0, 0, 1)
        strike.Position = UDim2.new(0.1, 0, 0.5, 0)
        strike.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        strike.Parent = originalPrice
        originalPrice.Parent = priceFrame
    end
    
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = item.originalEmbers and UDim2.new(0.5, 0, 1, 0) or UDim2.new(1, 0, 1, 0)
    priceLabel.Position = item.originalEmbers and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "🔥 " .. item.embers
    priceLabel.TextColor3 = CONFIG.EMBER_COLOR
    priceLabel.TextSize = 14
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.Parent = priceFrame
    
    -- Buy button
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(1, -20, 0, 30)
    buyBtn.Position = UDim2.new(0, 10, 1, -40)
    buyBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
    buyBtn.BorderSizePixel = 0
    buyBtn.Text = "BUY"
    buyBtn.TextColor3 = Color3.new(0,0,0)
    buyBtn.TextSize = 14
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.Parent = card
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 6)
    buyCorner.Parent = buyBtn
    
    buyBtn.MouseButton1Click:Connect(function()
        ShopUI:purchaseItem(item.id, category)
    end)
    
    return card
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShopUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 700, 0, 500)
    panel.Position = UDim2.new(0.5, -350, 0.5, -250)
    panel.BackgroundColor3 = CONFIG.BG_COLOR
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.ACCENT_COLOR
    stroke.Thickness = 2
    stroke.Parent = panel
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 55)
    header.BackgroundColor3 = CONFIG.PANEL_COLOR
    header.BorderSizePixel = 0
    header.Parent = panel
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🛒 ITEM SHOP"
    title.TextColor3 = CONFIG.ACCENT_COLOR
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Ember balance
    local balanceFrame = Instance.new("Frame")
    balanceFrame.Size = UDim2.new(0, 150, 0, 35)
    balanceFrame.Position = UDim2.new(1, -250, 0.5, -17)
    balanceFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    balanceFrame.BorderSizePixel = 0
    balanceFrame.Parent = header
    
    local balanceCorner = Instance.new("UICorner")
    balanceCorner.CornerRadius = UDim.new(0, 8)
    balanceCorner.Parent = balanceFrame
    
    local balanceLabel = Instance.new("TextLabel")
    balanceLabel.Name = "BalanceLabel"
    balanceLabel.Size = UDim2.new(1, 0, 1, 0)
    balanceLabel.BackgroundTransparency = 1
    balanceLabel.Text = "🔥 0 Embers"
    balanceLabel.TextColor3 = CONFIG.EMBER_COLOR
    balanceLabel.TextSize = 16
    balanceLabel.Font = Enum.Font.GothamBold
    balanceLabel.Parent = balanceFrame
    
    -- Add embers button
    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0, 30, 0, 30)
    addBtn.Position = UDim2.new(1, -5, 0.5, -15)
    addBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    addBtn.BorderSizePixel = 0
    addBtn.Text = "+"
    addBtn.TextColor3 = Color3.new(1,1,1)
    addBtn.TextSize = 20
    addBtn.Font = Enum.Font.GothamBold
    addBtn.Parent = balanceFrame
    
    local addCorner = Instance.new("UICorner")
    addCorner.CornerRadius = UDim.new(0.5, 0)
    addCorner.Parent = addBtn
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -45, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        ShopUI:hide()
    end)
    
    -- Tab buttons
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -20, 0, 40)
    tabContainer.Position = UDim2.new(0, 10, 0, 60)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = panel
    
    local tabs = {
        { id = "featured", name = "⭐ Featured" },
        { id = "daily", name = "📅 Daily" },
        { id = "weekly", name = "📆 Weekly" },
        { id = "battlePass", name = "🏆 Battle Pass" },
    }
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.Parent = tabContainer
    
    for _, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tab.id
        tabBtn.Size = UDim2.new(0, 130, 0, 35)
        tabBtn.BackgroundColor3 = tab.id == ShopUI.currentTab and CONFIG.ACCENT_COLOR or CONFIG.PANEL_COLOR
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tab.name
        tabBtn.TextColor3 = tab.id == ShopUI.currentTab and Color3.new(0,0,0) or Color3.new(1,1,1)
        tabBtn.TextSize = 13
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 8)
        tabCorner.Parent = tabBtn
        
        tabBtn.MouseButton1Click:Connect(function()
            ShopUI.currentTab = tab.id
            ShopUI:refreshShop()
        end)
    end
    
    -- Items container
    local itemsContainer = Instance.new("ScrollingFrame")
    itemsContainer.Name = "Items"
    itemsContainer.Size = UDim2.new(1, -20, 1, -120)
    itemsContainer.Position = UDim2.new(0, 10, 0, 110)
    itemsContainer.BackgroundTransparency = 1
    itemsContainer.ScrollBarThickness = 6
    itemsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemsContainer.Parent = panel
    
    local itemsGrid = Instance.new("UIGridLayout")
    itemsGrid.CellSize = UDim2.new(0, 150, 0, 200)
    itemsGrid.CellPadding = UDim2.new(0, 15, 0, 15)
    itemsGrid.Parent = itemsContainer
    
    ShopUI.screenGui = screenGui
    ShopUI.panel = panel
    ShopUI.balanceLabel = balanceLabel
    ShopUI.tabContainer = tabContainer
    ShopUI.itemsContainer = itemsContainer
    
    addBtn.MouseButton1Click:Connect(function()
        ShopUI:showCurrencyPanel()
    end)
end

function ShopUI:refreshShop()
    -- Clear items
    for _, child in pairs(ShopUI.itemsContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    -- Update tab buttons
    for _, child in pairs(ShopUI.tabContainer:GetChildren()) do
        if child:IsA("TextButton") then
            local isActive = child.Name == ShopUI.currentTab
            TweenService:Create(child, TweenInfo.new(0.15), {
                BackgroundColor3 = isActive and CONFIG.ACCENT_COLOR or CONFIG.PANEL_COLOR
            }):Play()
            child.TextColor3 = isActive and Color3.new(0,0,0) or Color3.new(1,1,1)
        end
    end
    
    -- Add items
    if ShopUI.shopData and ShopUI.shopData.shop then
        local items = ShopUI.shopData.shop[ShopUI.currentTab] or {}
        for _, item in ipairs(items) do
            createShopItem(ShopUI.itemsContainer, item, ShopUI.currentTab)
        end
        
        local rows = math.ceil(#items / 4)
        ShopUI.itemsContainer.CanvasSize = UDim2.new(0, 0, 0, rows * 215)
    end
    
    -- Update balance
    ShopUI.balanceLabel.Text = "🔥 " .. ShopUI.emberBalance .. " Embers"
end

function ShopUI:purchaseItem(itemId, category)
    local shopRemote = ReplicatedStorage:FindFirstChild("ShopRemote")
    if shopRemote then
        shopRemote:FireServer("PURCHASE", {itemId = itemId, category = category})
    end
end

function ShopUI:showCurrencyPanel()
    -- Would show currency purchase options
    print("[ShopUI] Opening currency purchase...")
end

function ShopUI:show()
    if ShopUI.panel then
        ShopUI.panel.Visible = true
        ShopUI.isVisible = true
        
        -- Request shop data
        local shopRemote = ReplicatedStorage:FindFirstChild("ShopRemote")
        if shopRemote then
            shopRemote:FireServer("GET_SHOP")
        end
    end
end

function ShopUI:hide()
    if ShopUI.panel then
        ShopUI.panel.Visible = false
        ShopUI.isVisible = false
    end
end

function ShopUI:toggle()
    if ShopUI.isVisible then
        ShopUI:hide()
    else
        ShopUI:show()
    end
end

function ShopUI.init()
    print("[ShopUI] Initializing...")
    createUI()
    
    local shopRemote = ReplicatedStorage:FindFirstChild("ShopRemote")
    if shopRemote then
        shopRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "SHOP_DATA" then
                ShopUI.shopData = data
                ShopUI.emberBalance = data.embers or 0
                ShopUI:refreshShop()
            elseif eventType == "BALANCE_UPDATE" then
                ShopUI.emberBalance = data.embers or 0
                ShopUI.balanceLabel.Text = "🔥 " .. ShopUI.emberBalance .. " Embers"
            elseif eventType == "PURCHASE_SUCCESS" then
                ShopUI.emberBalance = data.embers or ShopUI.emberBalance
                ShopUI.balanceLabel.Text = "🔥 " .. ShopUI.emberBalance .. " Embers"
            elseif eventType == "PURCHASE_FAILED" then
                warn("[ShopUI] Purchase failed: " .. (data.error or "Unknown"))
            end
        end)
    end
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.O then
            ShopUI:toggle()
        end
    end)
    
    print("[ShopUI] Initialized! Press O to open shop")
end

ShopUI.init()
return ShopUI
