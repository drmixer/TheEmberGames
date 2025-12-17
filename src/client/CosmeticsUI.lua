-- LocalScript: CosmeticsUI.lua
-- Interface for selecting and equipping unlocked cosmetics

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local CosmeticsUI = {}
CosmeticsUI.isVisible = false
CosmeticsUI.currentTab = "trails"
CosmeticsUI.equipped = { trail = "ember", pose = "triumphant", outfit = "default" }

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    PANEL_COLOR = Color3.fromRGB(30, 30, 45),
    LOCKED_COLOR = Color3.fromRGB(50, 50, 60),
    EQUIPPED_COLOR = Color3.fromRGB(50, 100, 50),
}

local RARITY_COLORS = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(50, 150, 255),
    Epic = Color3.fromRGB(150, 50, 200),
    Legendary = Color3.fromRGB(255, 180, 50),
}

-- Cosmetics data
local COSMETICS = {
    trails = {
        { id = "ember", name = "Ember Trail", icon = "🔥", rarity = "Common", unlocked = true },
        { id = "golden", name = "Victor's Gold", icon = "✨", rarity = "Rare", unlocked = false },
        { id = "mockingjay", name = "Mockingjay Feathers", icon = "🪶", rarity = "Epic", unlocked = false },
        { id = "nightlock", name = "Nightlock Poison", icon = "☠️", rarity = "Legendary", unlocked = false },
        { id = "ice", name = "Frozen Path", icon = "❄️", rarity = "Rare", unlocked = false },
        { id = "rainbow", name = "Capitol Spectacle", icon = "🌈", rarity = "Legendary", unlocked = false },
    },
    poses = {
        { id = "triumphant", name = "Triumphant Victor", icon = "🏆", rarity = "Common", unlocked = true },
        { id = "salute", name = "Tribute's Salute", icon = "✊", rarity = "Common", unlocked = true },
        { id = "defiant", name = "Defiant Champion", icon = "⚡", rarity = "Rare", unlocked = false },
        { id = "humble", name = "Humble Survivor", icon = "🙏", rarity = "Rare", unlocked = false },
        { id = "mockingjay", name = "Mockingjay's Call", icon = "🐦", rarity = "Epic", unlocked = false },
        { id = "fire", name = "Girl on Fire", icon = "🔥", rarity = "Legendary", unlocked = false },
    },
    outfits = {
        { id = "default", name = "Arena Standard", icon = "👕", rarity = "Common", unlocked = true },
        { id = "career", name = "Career Tribute", icon = "⚔️", rarity = "Rare", unlocked = false },
        { id = "gamemaker", name = "Gamemaker", icon = "🎭", rarity = "Epic", unlocked = false },
        { id = "victor", name = "Victor's Garb", icon = "👑", rarity = "Legendary", unlocked = false },
    },
}

local function createCosmeticCard(item, category, parent)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 100, 0, 120)
    card.BackgroundColor3 = item.unlocked and CONFIG.PANEL_COLOR or CONFIG.LOCKED_COLOR
    card.BorderSizePixel = 0
    
    if CosmeticsUI.equipped[category:sub(1, -2)] == item.id then
        card.BackgroundColor3 = CONFIG.EQUIPPED_COLOR
    end
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = RARITY_COLORS[item.rarity] or CONFIG.ACCENT_COLOR
    stroke.Thickness = 2
    stroke.Transparency = item.unlocked and 0 or 0.7
    stroke.Parent = card
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 0, 50)
    icon.Position = UDim2.new(0, 0, 0, 10)
    icon.BackgroundTransparency = 1
    icon.Text = item.icon
    icon.TextSize = 36
    icon.Parent = card
    
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -6, 0, 30)
    name.Position = UDim2.new(0, 3, 0, 60)
    name.BackgroundTransparency = 1
    name.Text = item.name
    name.TextColor3 = Color3.fromRGB(220, 220, 220)
    name.TextSize = 11
    name.Font = Enum.Font.Gotham
    name.TextWrapped = true
    name.Parent = card
    
    local rarity = Instance.new("TextLabel")
    rarity.Size = UDim2.new(1, 0, 0, 15)
    rarity.Position = UDim2.new(0, 0, 0, 92)
    rarity.BackgroundTransparency = 1
    rarity.Text = item.rarity
    rarity.TextColor3 = RARITY_COLORS[item.rarity]
    rarity.TextSize = 10
    rarity.Font = Enum.Font.GothamBold
    rarity.Parent = card
    
    if not item.unlocked then
        local lock = Instance.new("TextLabel")
        lock.Size = UDim2.new(1, 0, 1, 0)
        lock.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        lock.BackgroundTransparency = 0.5
        lock.Text = "🔒"
        lock.TextSize = 30
        lock.Parent = card
        
        local lockCorner = Instance.new("UICorner")
        lockCorner.CornerRadius = UDim.new(0, 8)
        lockCorner.Parent = lock
    end
    
    -- Click to equip
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = card
    
    btn.MouseButton1Click:Connect(function()
        if item.unlocked then
            local catKey = category:sub(1, -2) -- "trails" -> "trail"
            CosmeticsUI.equipped[catKey] = item.id
            CosmeticsUI:refreshTab()
            
            -- Notify server
            local remote = ReplicatedStorage:FindFirstChild("CosmeticsRemote")
            if remote then
                remote:FireServer("EQUIP", catKey, item.id)
            end
        end
    end)
    
    card.Parent = parent
    return card
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CosmeticsUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 550, 0, 450)
    panel.Position = UDim2.new(0.5, -275, 0.5, -225)
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
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = CONFIG.PANEL_COLOR
    header.BorderSizePixel = 0
    header.Parent = panel
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "✨ CUSTOMIZE"
    title.TextColor3 = CONFIG.ACCENT_COLOR
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        CosmeticsUI:hide()
    end)
    
    -- Tabs
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 0, 40)
    tabContainer.Position = UDim2.new(0, 0, 0, 55)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = panel
    
    local tabs = {"trails", "poses", "outfits"}
    local tabLabels = {"🔥 Trails", "🏆 Poses", "👕 Outfits"}
    
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tab
        tabBtn.Size = UDim2.new(0.32, 0, 0, 35)
        tabBtn.Position = UDim2.new((i-1) * 0.33 + 0.01, 0, 0, 0)
        tabBtn.BackgroundColor3 = tab == CosmeticsUI.currentTab and CONFIG.ACCENT_COLOR or CONFIG.PANEL_COLOR
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tabLabels[i]
        tabBtn.TextColor3 = tab == CosmeticsUI.currentTab and Color3.new(0,0,0) or Color3.new(1,1,1)
        tabBtn.TextSize = 14
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tabBtn
        
        tabBtn.MouseButton1Click:Connect(function()
            CosmeticsUI.currentTab = tab
            CosmeticsUI:refreshTab()
        end)
    end
    
    -- Content grid
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -115)
    content.Position = UDim2.new(0, 10, 0, 105)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 6
    content.CanvasSize = UDim2.new(0, 0, 0, 300)
    content.Parent = panel
    
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 100, 0, 120)
    grid.CellPadding = UDim2.new(0, 10, 0, 10)
    grid.Parent = content
    
    CosmeticsUI.screenGui = screenGui
    CosmeticsUI.panel = panel
    CosmeticsUI.content = content
    CosmeticsUI.tabContainer = tabContainer
end

function CosmeticsUI:refreshTab()
    -- Clear content
    for _, child in pairs(CosmeticsUI.content:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    -- Update tab buttons
    for _, child in pairs(CosmeticsUI.tabContainer:GetChildren()) do
        if child:IsA("TextButton") then
            local isActive = child.Name == CosmeticsUI.currentTab
            TweenService:Create(child, TweenInfo.new(0.2), {
                BackgroundColor3 = isActive and CONFIG.ACCENT_COLOR or CONFIG.PANEL_COLOR
            }):Play()
            child.TextColor3 = isActive and Color3.new(0,0,0) or Color3.new(1,1,1)
        end
    end
    
    -- Populate content
    local items = COSMETICS[CosmeticsUI.currentTab] or {}
    for _, item in ipairs(items) do
        createCosmeticCard(item, CosmeticsUI.currentTab, CosmeticsUI.content)
    end
    
    local rows = math.ceil(#items / 5)
    CosmeticsUI.content.CanvasSize = UDim2.new(0, 0, 0, rows * 130)
end

function CosmeticsUI:show()
    if CosmeticsUI.panel then
        CosmeticsUI.panel.Visible = true
        CosmeticsUI.isVisible = true
        CosmeticsUI:refreshTab()
    end
end

function CosmeticsUI:hide()
    if CosmeticsUI.panel then
        CosmeticsUI.panel.Visible = false
        CosmeticsUI.isVisible = false
    end
end

function CosmeticsUI:toggle()
    if CosmeticsUI.isVisible then
        CosmeticsUI:hide()
    else
        CosmeticsUI:show()
    end
end

function CosmeticsUI.init()
    print("[CosmeticsUI] Initializing...")
    createUI()
    CosmeticsUI:refreshTab()
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.C then
            CosmeticsUI:toggle()
        end
    end)
    
    print("[CosmeticsUI] Initialized! Press C to open")
end

CosmeticsUI.init()
return CosmeticsUI
