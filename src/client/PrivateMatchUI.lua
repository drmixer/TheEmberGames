-- LocalScript: PrivateMatchUI.lua
-- UI for creating and joining private matches

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local PrivateMatchUI = {}
PrivateMatchUI.isVisible = false
PrivateMatchUI.inLobby = false
PrivateMatchUI.isHost = false
PrivateMatchUI.lobbyCode = nil

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    PANEL_COLOR = Color3.fromRGB(30, 30, 45),
}

local function createPlayerRow(parent, playerData, yPos)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 40)
    row.Position = UDim2.new(0, 5, 0, yPos)
    row.BackgroundColor3 = CONFIG.PANEL_COLOR
    row.BorderSizePixel = 0
    row.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = row
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = (playerData.isHost and "👑 " or "") .. playerData.name
    nameLabel.TextColor3 = playerData.isHost and CONFIG.ACCENT_COLOR or Color3.fromRGB(200, 200, 200)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row
    
    local readyLabel = Instance.new("TextLabel")
    readyLabel.Size = UDim2.new(0, 80, 1, 0)
    readyLabel.Position = UDim2.new(1, -90, 0, 0)
    readyLabel.BackgroundTransparency = 1
    readyLabel.Text = playerData.isReady and "✅ Ready" or "⏳ Waiting"
    readyLabel.TextColor3 = playerData.isReady and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(150, 150, 150)
    readyLabel.TextSize = 12
    readyLabel.Font = Enum.Font.Gotham
    readyLabel.Parent = row
    
    return row
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PrivateMatchUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    -- Main panel
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 500, 0, 500)
    panel.Position = UDim2.new(0.5, -250, 0.5, -250)
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
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎮 PRIVATE MATCH"
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
        PrivateMatchUI:hide()
    end)
    
    -- Main menu (shown when not in lobby)
    local mainMenu = Instance.new("Frame")
    mainMenu.Name = "MainMenu"
    mainMenu.Size = UDim2.new(1, -40, 1, -70)
    mainMenu.Position = UDim2.new(0, 20, 0, 60)
    mainMenu.BackgroundTransparency = 1
    mainMenu.Parent = panel
    
    local createBtn = Instance.new("TextButton")
    createBtn.Size = UDim2.new(1, 0, 0, 60)
    createBtn.Position = UDim2.new(0, 0, 0, 50)
    createBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
    createBtn.BorderSizePixel = 0
    createBtn.Text = "➕ CREATE PRIVATE MATCH"
    createBtn.TextColor3 = Color3.new(1,1,1)
    createBtn.TextSize = 18
    createBtn.Font = Enum.Font.GothamBold
    createBtn.Parent = mainMenu
    
    local createCorner = Instance.new("UICorner")
    createCorner.CornerRadius = UDim.new(0, 10)
    createCorner.Parent = createBtn
    
    local joinLabel = Instance.new("TextLabel")
    joinLabel.Size = UDim2.new(1, 0, 0, 30)
    joinLabel.Position = UDim2.new(0, 0, 0, 140)
    joinLabel.BackgroundTransparency = 1
    joinLabel.Text = "— OR JOIN WITH CODE —"
    joinLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    joinLabel.TextSize = 14
    joinLabel.Font = Enum.Font.Gotham
    joinLabel.Parent = mainMenu
    
    local codeInput = Instance.new("TextBox")
    codeInput.Name = "CodeInput"
    codeInput.Size = UDim2.new(0.6, 0, 0, 50)
    codeInput.Position = UDim2.new(0, 0, 0, 180)
    codeInput.BackgroundColor3 = CONFIG.PANEL_COLOR
    codeInput.BorderSizePixel = 0
    codeInput.Text = ""
    codeInput.PlaceholderText = "Enter Code..."
    codeInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    codeInput.TextColor3 = Color3.new(1,1,1)
    codeInput.TextSize = 20
    codeInput.Font = Enum.Font.GothamBold
    codeInput.ClearTextOnFocus = false
    codeInput.Parent = mainMenu
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = codeInput
    
    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(0.35, 0, 0, 50)
    joinBtn.Position = UDim2.new(0.65, 0, 0, 180)
    joinBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 120)
    joinBtn.BorderSizePixel = 0
    joinBtn.Text = "JOIN"
    joinBtn.TextColor3 = Color3.new(1,1,1)
    joinBtn.TextSize = 16
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.Parent = mainMenu
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 8)
    joinCorner.Parent = joinBtn
    
    -- Lobby view (shown when in lobby)
    local lobbyView = Instance.new("Frame")
    lobbyView.Name = "LobbyView"
    lobbyView.Size = UDim2.new(1, -20, 1, -60)
    lobbyView.Position = UDim2.new(0, 10, 0, 55)
    lobbyView.BackgroundTransparency = 1
    lobbyView.Visible = false
    lobbyView.Parent = panel
    
    local codeDisplay = Instance.new("Frame")
    codeDisplay.Size = UDim2.new(1, 0, 0, 45)
    codeDisplay.BackgroundColor3 = CONFIG.PANEL_COLOR
    codeDisplay.BorderSizePixel = 0
    codeDisplay.Parent = lobbyView
    
    local codeDisplayCorner = Instance.new("UICorner")
    codeDisplayCorner.CornerRadius = UDim.new(0, 8)
    codeDisplayCorner.Parent = codeDisplay
    
    local codeLabel = Instance.new("TextLabel")
    codeLabel.Name = "CodeLabel"
    codeLabel.Size = UDim2.new(0.7, 0, 1, 0)
    codeLabel.BackgroundTransparency = 1
    codeLabel.Text = "Code: XXXXXX"
    codeLabel.TextColor3 = CONFIG.ACCENT_COLOR
    codeLabel.TextSize = 20
    codeLabel.Font = Enum.Font.GothamBold
    codeLabel.Parent = codeDisplay
    
    -- Player list
    local playerList = Instance.new("ScrollingFrame")
    playerList.Name = "PlayerList"
    playerList.Size = UDim2.new(0.55, 0, 0, 280)
    playerList.Position = UDim2.new(0, 0, 0, 55)
    playerList.BackgroundTransparency = 1
    playerList.ScrollBarThickness = 4
    playerList.Parent = lobbyView
    
    -- Settings panel (right side)
    local settingsPanel = Instance.new("Frame")
    settingsPanel.Name = "SettingsPanel"
    settingsPanel.Size = UDim2.new(0.42, 0, 0, 280)
    settingsPanel.Position = UDim2.new(0.58, 0, 0, 55)
    settingsPanel.BackgroundColor3 = CONFIG.PANEL_COLOR
    settingsPanel.BorderSizePixel = 0
    settingsPanel.Parent = lobbyView
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 8)
    settingsCorner.Parent = settingsPanel
    
    local settingsTitle = Instance.new("TextLabel")
    settingsTitle.Size = UDim2.new(1, 0, 0, 30)
    settingsTitle.BackgroundTransparency = 1
    settingsTitle.Text = "⚙️ Settings"
    settingsTitle.TextColor3 = CONFIG.ACCENT_COLOR
    settingsTitle.TextSize = 14
    settingsTitle.Font = Enum.Font.GothamBold
    settingsTitle.Parent = settingsPanel
    
    -- Action buttons
    local readyBtn = Instance.new("TextButton")
    readyBtn.Name = "ReadyBtn"
    readyBtn.Size = UDim2.new(0.48, 0, 0, 45)
    readyBtn.Position = UDim2.new(0, 0, 0, 345)
    readyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
    readyBtn.BorderSizePixel = 0
    readyBtn.Text = "✅ READY"
    readyBtn.TextColor3 = Color3.new(1,1,1)
    readyBtn.TextSize = 16
    readyBtn.Font = Enum.Font.GothamBold
    readyBtn.Parent = lobbyView
    
    local readyCorner = Instance.new("UICorner")
    readyCorner.CornerRadius = UDim.new(0, 8)
    readyCorner.Parent = readyBtn
    
    local leaveBtn = Instance.new("TextButton")
    leaveBtn.Size = UDim2.new(0.48, 0, 0, 45)
    leaveBtn.Position = UDim2.new(0.52, 0, 0, 345)
    leaveBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
    leaveBtn.BorderSizePixel = 0
    leaveBtn.Text = "🚪 LEAVE"
    leaveBtn.TextColor3 = Color3.new(1,1,1)
    leaveBtn.TextSize = 16
    leaveBtn.Font = Enum.Font.GothamBold
    leaveBtn.Parent = lobbyView
    
    local leaveCorner = Instance.new("UICorner")
    leaveCorner.CornerRadius = UDim.new(0, 8)
    leaveCorner.Parent = leaveBtn
    
    local startBtn = Instance.new("TextButton")
    startBtn.Name = "StartBtn"
    startBtn.Size = UDim2.new(1, 0, 0, 50)
    startBtn.Position = UDim2.new(0, 0, 0, 395)
    startBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
    startBtn.BorderSizePixel = 0
    startBtn.Text = "⚔️ START MATCH"
    startBtn.TextColor3 = Color3.new(0,0,0)
    startBtn.TextSize = 18
    startBtn.Font = Enum.Font.GothamBold
    startBtn.Visible = false
    startBtn.Parent = lobbyView
    
    local startCorner = Instance.new("UICorner")
    startCorner.CornerRadius = UDim.new(0, 8)
    startCorner.Parent = startBtn
    
    -- Store references
    PrivateMatchUI.screenGui = screenGui
    PrivateMatchUI.panel = panel
    PrivateMatchUI.mainMenu = mainMenu
    PrivateMatchUI.lobbyView = lobbyView
    PrivateMatchUI.codeInput = codeInput
    PrivateMatchUI.codeLabel = codeLabel
    PrivateMatchUI.playerList = playerList
    PrivateMatchUI.readyBtn = readyBtn
    PrivateMatchUI.startBtn = startBtn
    
    -- Button events
    createBtn.MouseButton1Click:Connect(function()
        PrivateMatchUI:createLobby()
    end)
    
    joinBtn.MouseButton1Click:Connect(function()
        local code = codeInput.Text
        if code and #code > 0 then
            PrivateMatchUI:joinLobby(code)
        end
    end)
    
    readyBtn.MouseButton1Click:Connect(function()
        PrivateMatchUI:toggleReady()
    end)
    
    leaveBtn.MouseButton1Click:Connect(function()
        PrivateMatchUI:leaveLobby()
    end)
    
    startBtn.MouseButton1Click:Connect(function()
        PrivateMatchUI:startMatch()
    end)
end

function PrivateMatchUI:updateLobbyView(data)
    PrivateMatchUI.codeLabel.Text = "Code: " .. data.code
    PrivateMatchUI.isHost = data.isHost
    PrivateMatchUI.startBtn.Visible = data.isHost
    
    -- Clear and repopulate player list
    for _, child in pairs(PrivateMatchUI.playerList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local yPos = 0
    for _, player in ipairs(data.players) do
        createPlayerRow(PrivateMatchUI.playerList, player, yPos)
        yPos = yPos + 45
    end
    PrivateMatchUI.playerList.CanvasSize = UDim2.new(0, 0, 0, yPos)
    
    -- Enable/disable start button
    PrivateMatchUI.startBtn.BackgroundColor3 = data.canStart and CONFIG.ACCENT_COLOR or Color3.fromRGB(80, 80, 80)
end

function PrivateMatchUI:createLobby()
    local privateRemote = ReplicatedStorage:FindFirstChild("PrivateMatchRemote")
    if privateRemote then
        privateRemote:FireServer("CREATE", {})
    end
end

function PrivateMatchUI:joinLobby(code)
    local privateRemote = ReplicatedStorage:FindFirstChild("PrivateMatchRemote")
    if privateRemote then
        privateRemote:FireServer("JOIN", {code = code})
    end
end

function PrivateMatchUI:leaveLobby()
    local privateRemote = ReplicatedStorage:FindFirstChild("PrivateMatchRemote")
    if privateRemote then
        privateRemote:FireServer("LEAVE", {})
    end
    PrivateMatchUI.inLobby = false
    PrivateMatchUI.mainMenu.Visible = true
    PrivateMatchUI.lobbyView.Visible = false
end

function PrivateMatchUI:toggleReady()
    local privateRemote = ReplicatedStorage:FindFirstChild("PrivateMatchRemote")
    if privateRemote then
        privateRemote:FireServer("TOGGLE_READY", {})
    end
end

function PrivateMatchUI:startMatch()
    local privateRemote = ReplicatedStorage:FindFirstChild("PrivateMatchRemote")
    if privateRemote then
        privateRemote:FireServer("START", {})
    end
end

function PrivateMatchUI:show()
    if PrivateMatchUI.panel then
        PrivateMatchUI.panel.Visible = true
        PrivateMatchUI.isVisible = true
    end
end

function PrivateMatchUI:hide()
    if PrivateMatchUI.panel then
        PrivateMatchUI.panel.Visible = false
        PrivateMatchUI.isVisible = false
    end
end

function PrivateMatchUI:toggle()
    if PrivateMatchUI.isVisible then
        PrivateMatchUI:hide()
    else
        PrivateMatchUI:show()
    end
end

function PrivateMatchUI.init()
    print("[PrivateMatchUI] Initializing...")
    createUI()
    
    local privateRemote = ReplicatedStorage:FindFirstChild("PrivateMatchRemote")
    if privateRemote then
        privateRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "LOBBY_CREATED" or eventType == "LOBBY_UPDATE" then
                PrivateMatchUI.inLobby = true
                PrivateMatchUI.lobbyCode = data.code
                PrivateMatchUI.mainMenu.Visible = false
                PrivateMatchUI.lobbyView.Visible = true
                PrivateMatchUI:updateLobbyView(data)
            elseif eventType == "LEFT_LOBBY" then
                PrivateMatchUI.inLobby = false
                PrivateMatchUI.mainMenu.Visible = true
                PrivateMatchUI.lobbyView.Visible = false
            elseif eventType == "MATCH_STARTING" then
                PrivateMatchUI:hide()
            end
        end)
    end
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.J then
            PrivateMatchUI:toggle()
        end
    end)
    
    print("[PrivateMatchUI] Initialized! Press J to open")
end

PrivateMatchUI.init()
return PrivateMatchUI
