-- LocalScript: AdminPanel.lua (Client)
-- Admin panel for testing and balance adjustment
-- Provides UI controls for game testing during development

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AdminPanel = {}
AdminPanel.isOpen = false
AdminPanel.isAdmin = false
AdminPanel.gui = nil

-- Wait for testing remote
local testingRemote = ReplicatedStorage:WaitForChild("TestingRemote", 10)

-- ============ UI CREATION ============

local function createAdminPanel()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AdminPanel"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 100
    screenGui.Parent = playerGui
    
    -- Main panel (hidden by default)
    local mainPanel = Instance.new("Frame")
    mainPanel.Name = "MainPanel"
    mainPanel.Size = UDim2.new(0, 400, 0, 600)
    mainPanel.Position = UDim2.new(0, 20, 0.5, -300)
    mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainPanel.BackgroundTransparency = 0.1
    mainPanel.BorderSizePixel = 0
    mainPanel.Visible = false
    mainPanel.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainPanel
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 100, 50)
    stroke.Thickness = 2
    stroke.Parent = mainPanel
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    header.BorderSizePixel = 0
    header.Parent = mainPanel
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Fix corner overlap
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0.5, 0)
    headerFix.Position = UDim2.new(0, 0, 0.5, 0)
    headerFix.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔥 ADMIN PANEL"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -45, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        AdminPanel:toggle()
    end)
    
    -- Scrolling content area
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "Content"
    scrollFrame.Size = UDim2.new(1, -20, 1, -70)
    scrollFrame.Position = UDim2.new(0, 10, 0, 60)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 50)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 1200)
    scrollFrame.Parent = mainPanel
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = scrollFrame
    
    -- ============ SECTIONS ============
    
    local function createSection(name, layoutOrder)
        local section = Instance.new("Frame")
        section.Name = name
        section.Size = UDim2.new(1, -10, 0, 40)
        section.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        section.BorderSizePixel = 0
        section.LayoutOrder = layoutOrder
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.Parent = scrollFrame
        
        local sectionCorner = Instance.new("UICorner")
        sectionCorner.CornerRadius = UDim.new(0, 8)
        sectionCorner.Parent = section
        
        local sectionTitle = Instance.new("TextLabel")
        sectionTitle.Name = "Title"
        sectionTitle.Size = UDim2.new(1, -20, 0, 30)
        sectionTitle.Position = UDim2.new(0, 10, 0, 5)
        sectionTitle.BackgroundTransparency = 1
        sectionTitle.Text = name
        sectionTitle.TextColor3 = Color3.fromRGB(255, 150, 100)
        sectionTitle.TextSize = 16
        sectionTitle.Font = Enum.Font.GothamBold
        sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        sectionTitle.Parent = section
        
        local sectionContent = Instance.new("Frame")
        sectionContent.Name = "Content"
        sectionContent.Size = UDim2.new(1, -20, 0, 0)
        sectionContent.Position = UDim2.new(0, 10, 0, 35)
        sectionContent.BackgroundTransparency = 1
        sectionContent.AutomaticSize = Enum.AutomaticSize.Y
        sectionContent.Parent = section
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 5)
        contentLayout.Parent = sectionContent
        
        return sectionContent
    end
    
    local function createButton(parent, text, callback, layoutOrder)
        local button = Instance.new("TextButton")
        button.Name = text
        button.Size = UDim2.new(1, 0, 0, 35)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        button.Font = Enum.Font.Gotham
        button.LayoutOrder = layoutOrder or 0
        button.Parent = parent
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = button
        
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(255, 100, 50)
            }):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            }):Play()
        end)
        
        button.MouseButton1Click:Connect(callback)
        
        return button
    end
    
    local function createLabel(parent, text, layoutOrder)
        local label = Instance.new("TextLabel")
        label.Name = text
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(180, 180, 180)
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.LayoutOrder = layoutOrder or 0
        label.Parent = parent
        
        return label
    end
    
    -- ============ PLAYER SECTION ============
    
    local playerSection = createSection("👤 Player Controls", 1)
    
    createButton(playerSection, "🩹 Full Heal (Health/Hunger/Thirst)", function()
        if testingRemote then
            testingRemote:FireServer("HEAL")
        end
    end, 1)
    
    createButton(playerSection, "⚔️ Give All Weapons", function()
        if testingRemote then
            testingRemote:FireServer("GIVE_WEAPONS")
        end
    end, 2)
    
    createButton(playerSection, "📍 Teleport to Center", function()
        if testingRemote then
            testingRemote:FireServer("TELEPORT", Vector3.new(0, 10, 0))
        end
    end, 3)
    
    -- ============ MATCH SECTION ============
    
    local matchSection = createSection("🎮 Match Controls", 2)
    
    createButton(matchSection, "▶️ Force Start Match", function()
        if testingRemote then
            testingRemote:FireServer("FORCE_START")
        end
    end, 1)
    
    createButton(matchSection, "⏹️ Force End Match", function()
        if testingRemote then
            testingRemote:FireServer("FORCE_END", player)
        end
    end, 2)
    
    createButton(matchSection, "📦 Spawn Supply Drop", function()
        if testingRemote then
            testingRemote:FireServer("SPAWN_DROP")
        end
    end, 3)
    
    -- ============ STORM SECTION ============
    
    local stormSection = createSection("🌪️ Storm Controls", 3)
    
    for phase = 1, 7 do
        createButton(stormSection, "Skip to Phase " .. phase, function()
            if testingRemote then
                testingRemote:FireServer("SKIP_STORM", phase)
            end
        end, phase)
    end
    
    -- ============ HAZARDS SECTION ============
    
    local hazardSection = createSection("⚠️ Hazard Events", 4)
    
    createButton(hazardSection, "🌊 Trigger Flood", function()
        if testingRemote then
            testingRemote:FireServer("TRIGGER_HAZARD", "FLOOD")
        end
    end, 1)
    
    createButton(hazardSection, "🔥 Trigger Wildfire", function()
        if testingRemote then
            testingRemote:FireServer("TRIGGER_HAZARD", "WILDFIRE")
        end
    end, 2)
    
    createButton(hazardSection, "☠️ Trigger Poison Fog", function()
        if testingRemote then
            testingRemote:FireServer("TRIGGER_HAZARD", "POISON_FOG")
        end
    end, 3)
    
    -- ============ TESTING SECTION ============
    
    local testingSection = createSection("🧪 Testing Tools", 5)
    
    createButton(testingSection, "🤖 Spawn 24 Bots (Full Game)", function()
        if testingRemote then
            testingRemote:FireServer("SPAWN_BOTS")
        end
    end, 1)
    
    createButton(testingSection, "❌ Remove All Bots", function()
        if testingRemote then
            testingRemote:FireServer("REMOVE_BOTS")
        end
    end, 2)
    
    createButton(testingSection, "📊 Run Balance Test", function()
        if testingRemote then
            testingRemote:FireServer("RUN_BALANCE_TEST")
        end
    end, 3)
    
    createButton(testingSection, "🎯 Run Multiplayer Test (24p)", function()
        if testingRemote then
            testingRemote:FireServer("RUN_MULTIPLAYER_TEST", 24)
        end
    end, 4)
    
    createButton(testingSection, "📈 Performance Report", function()
        if testingRemote then
            testingRemote:FireServer("PERFORMANCE_REPORT")
        end
    end, 5)
    
    -- ============ INFO SECTION ============
    
    local infoSection = createSection("ℹ️ Info", 6)
    
    local fpsLabel = createLabel(infoSection, "FPS: --", 1)
    fpsLabel.Name = "FPSLabel"
    
    local playerCountLabel = createLabel(infoSection, "Players: --", 2)
    playerCountLabel.Name = "PlayerCountLabel"
    
    local pingLabel = createLabel(infoSection, "Ping: --ms", 3)
    pingLabel.Name = "PingLabel"
    
    -- Update info labels
    RunService.Heartbeat:Connect(function(dt)
        local fps = math.floor(1 / dt)
        fpsLabel.Text = "FPS: " .. fps
        playerCountLabel.Text = "Players: " .. #Players:GetPlayers()
        
        -- Get ping
        local ping = player:GetNetworkPing() * 1000
        pingLabel.Text = "Ping: " .. math.floor(ping) .. "ms"
    end)
    
    -- ============ TOGGLE BUTTON ============
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 60, 0, 60)
    toggleButton.Position = UDim2.new(0, 20, 0.5, -30)
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "🔧"
    toggleButton.TextSize = 30
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = screenGui
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 30)
    toggleCorner.Parent = toggleButton
    
    toggleButton.MouseButton1Click:Connect(function()
        AdminPanel:toggle()
    end)
    
    AdminPanel.gui = screenGui
    AdminPanel.mainPanel = mainPanel
    AdminPanel.toggleButton = toggleButton
    
    return screenGui
end

-- ============ PANEL CONTROLS ============

function AdminPanel:toggle()
    AdminPanel.isOpen = not AdminPanel.isOpen
    
    if AdminPanel.mainPanel then
        AdminPanel.mainPanel.Visible = AdminPanel.isOpen
    end
    
    if AdminPanel.toggleButton then
        AdminPanel.toggleButton.Visible = not AdminPanel.isOpen
    end
end

function AdminPanel:open()
    AdminPanel.isOpen = true
    if AdminPanel.mainPanel then
        AdminPanel.mainPanel.Visible = true
    end
    if AdminPanel.toggleButton then
        AdminPanel.toggleButton.Visible = false
    end
end

function AdminPanel:close()
    AdminPanel.isOpen = false
    if AdminPanel.mainPanel then
        AdminPanel.mainPanel.Visible = false
    end
    if AdminPanel.toggleButton then
        AdminPanel.toggleButton.Visible = true
    end
end

-- ============ INITIALIZATION ============

function AdminPanel.init()
    print("[AdminPanel] Initializing...")
    
    -- Create the admin panel UI
    createAdminPanel()
    
    -- Listen for debug mode toggle
    if testingRemote then
        testingRemote.OnClientEvent:Connect(function(action, value)
            if action == "DEBUG_MODE" then
                AdminPanel.isAdmin = value
                if AdminPanel.gui then
                    AdminPanel.gui.Enabled = value
                end
                print("[AdminPanel] Admin access: " .. tostring(value))
            end
        end)
    end
    
    -- Keyboard shortcut: F8 to toggle admin panel
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F8 then
            AdminPanel:toggle()
        end
    end)
    
    print("[AdminPanel] Initialized - Press F8 to toggle")
end

return AdminPanel
