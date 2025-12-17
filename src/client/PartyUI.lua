-- LocalScript: PartyUI.lua
-- Friends and party system for playing together
-- Create/join parties before matches

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SocialService = game:GetService("SocialService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local PartyUI = {}
PartyUI.isVisible = false
PartyUI.partyMembers = {}
PartyUI.isLeader = false
PartyUI.partyCode = nil
PartyUI.invites = {}

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    PANEL_COLOR = Color3.fromRGB(30, 30, 45),
    MAX_PARTY_SIZE = 4,
}

local function createPlayerCard(parent, playerData, yPos, isLeader)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 50)
    card.Position = UDim2.new(0, 5, 0, yPos)
    card.BackgroundColor3 = CONFIG.PANEL_COLOR
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    -- Avatar placeholder
    local avatar = Instance.new("Frame")
    avatar.Size = UDim2.new(0, 40, 0, 40)
    avatar.Position = UDim2.new(0, 5, 0.5, -20)
    avatar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    avatar.BorderSizePixel = 0
    avatar.Parent = card
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0.5, 0)
    avatarCorner.Parent = avatar
    
    local avatarIcon = Instance.new("TextLabel")
    avatarIcon.Size = UDim2.new(1, 0, 1, 0)
    avatarIcon.BackgroundTransparency = 1
    avatarIcon.Text = "👤"
    avatarIcon.TextSize = 24
    avatarIcon.Parent = avatar
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.5, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 55, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerData.name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.5, 0, 0, 15)
    statusLabel.Position = UDim2.new(0, 55, 0, 28)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = playerData.isLeader and "👑 Party Leader" or "Member"
    statusLabel.TextColor3 = playerData.isLeader and CONFIG.ACCENT_COLOR or Color3.fromRGB(150, 150, 150)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = card
    
    -- Kick button (only for leader, not self)
    if isLeader and not playerData.isLeader then
        local kickBtn = Instance.new("TextButton")
        kickBtn.Size = UDim2.new(0, 30, 0, 30)
        kickBtn.Position = UDim2.new(1, -40, 0.5, -15)
        kickBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
        kickBtn.BorderSizePixel = 0
        kickBtn.Text = "✕"
        kickBtn.TextColor3 = Color3.new(1,1,1)
        kickBtn.TextSize = 14
        kickBtn.Parent = card
        
        local kickCorner = Instance.new("UICorner")
        kickCorner.CornerRadius = UDim.new(0, 6)
        kickCorner.Parent = kickBtn
        
        kickBtn.MouseButton1Click:Connect(function()
            local partyRemote = ReplicatedStorage:FindFirstChild("PartyRemote")
            if partyRemote then
                partyRemote:FireServer("KICK", playerData.userId)
            end
        end)
    end
    
    return card
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PartyUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 350, 0, 450)
    panel.Position = UDim2.new(0.5, -175, 0.5, -225)
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
    title.Text = "👥 PARTY"
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
        PartyUI:hide()
    end)
    
    -- Party code display
    local codeFrame = Instance.new("Frame")
    codeFrame.Size = UDim2.new(1, -20, 0, 50)
    codeFrame.Position = UDim2.new(0, 10, 0, 55)
    codeFrame.BackgroundColor3 = CONFIG.PANEL_COLOR
    codeFrame.BorderSizePixel = 0
    codeFrame.Parent = panel
    
    local codeCorner = Instance.new("UICorner")
    codeCorner.CornerRadius = UDim.new(0, 8)
    codeCorner.Parent = codeFrame
    
    local codeLabel = Instance.new("TextLabel")
    codeLabel.Name = "CodeLabel"
    codeLabel.Size = UDim2.new(0.6, 0, 1, 0)
    codeLabel.BackgroundTransparency = 1
    codeLabel.Text = "No Party"
    codeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    codeLabel.TextSize = 16
    codeLabel.Font = Enum.Font.GothamBold
    codeLabel.Parent = codeFrame
    
    local copyBtn = Instance.new("TextButton")
    copyBtn.Name = "CopyBtn"
    copyBtn.Size = UDim2.new(0, 80, 0, 30)
    copyBtn.Position = UDim2.new(1, -90, 0.5, -15)
    copyBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
    copyBtn.BorderSizePixel = 0
    copyBtn.Text = "📋 Copy"
    copyBtn.TextColor3 = Color3.new(0,0,0)
    copyBtn.TextSize = 12
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.Visible = false
    copyBtn.Parent = codeFrame
    
    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 6)
    copyCorner.Parent = copyBtn
    
    -- Members list
    local membersList = Instance.new("ScrollingFrame")
    membersList.Name = "MembersList"
    membersList.Size = UDim2.new(1, -20, 0, 180)
    membersList.Position = UDim2.new(0, 10, 0, 115)
    membersList.BackgroundTransparency = 1
    membersList.ScrollBarThickness = 4
    membersList.CanvasSize = UDim2.new(0, 0, 0, 0)
    membersList.Parent = panel
    
    -- Action buttons
    local createBtn = Instance.new("TextButton")
    createBtn.Name = "CreateBtn"
    createBtn.Size = UDim2.new(0.45, 0, 0, 40)
    createBtn.Position = UDim2.new(0.025, 0, 0, 305)
    createBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
    createBtn.BorderSizePixel = 0
    createBtn.Text = "➕ Create Party"
    createBtn.TextColor3 = Color3.new(1,1,1)
    createBtn.TextSize = 14
    createBtn.Font = Enum.Font.GothamBold
    createBtn.Parent = panel
    
    local createCorner = Instance.new("UICorner")
    createCorner.CornerRadius = UDim.new(0, 8)
    createCorner.Parent = createBtn
    
    local joinBtn = Instance.new("TextButton")
    joinBtn.Name = "JoinBtn"
    joinBtn.Size = UDim2.new(0.45, 0, 0, 40)
    joinBtn.Position = UDim2.new(0.525, 0, 0, 305)
    joinBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 120)
    joinBtn.BorderSizePixel = 0
    joinBtn.Text = "🔗 Join Party"
    joinBtn.TextColor3 = Color3.new(1,1,1)
    joinBtn.TextSize = 14
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.Parent = panel
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 8)
    joinCorner.Parent = joinBtn
    
    -- Leave button
    local leaveBtn = Instance.new("TextButton")
    leaveBtn.Name = "LeaveBtn"
    leaveBtn.Size = UDim2.new(0.95, 0, 0, 35)
    leaveBtn.Position = UDim2.new(0.025, 0, 0, 355)
    leaveBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
    leaveBtn.BorderSizePixel = 0
    leaveBtn.Text = "🚪 Leave Party"
    leaveBtn.TextColor3 = Color3.new(1,1,1)
    leaveBtn.TextSize = 13
    leaveBtn.Font = Enum.Font.Gotham
    leaveBtn.Visible = false
    leaveBtn.Parent = panel
    
    local leaveCorner = Instance.new("UICorner")
    leaveCorner.CornerRadius = UDim.new(0, 6)
    leaveCorner.Parent = leaveBtn
    
    -- Queue button
    local queueBtn = Instance.new("TextButton")
    queueBtn.Name = "QueueBtn"
    queueBtn.Size = UDim2.new(0.95, 0, 0, 45)
    queueBtn.Position = UDim2.new(0.025, 0, 0, 395)
    queueBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
    queueBtn.BorderSizePixel = 0
    queueBtn.Text = "⚔️ QUEUE AS PARTY"
    queueBtn.TextColor3 = Color3.new(0,0,0)
    queueBtn.TextSize = 16
    queueBtn.Font = Enum.Font.GothamBold
    queueBtn.Visible = false
    queueBtn.Parent = panel
    
    local queueCorner = Instance.new("UICorner")
    queueCorner.CornerRadius = UDim.new(0, 8)
    queueCorner.Parent = queueBtn
    
    -- Store references
    PartyUI.screenGui = screenGui
    PartyUI.panel = panel
    PartyUI.codeLabel = codeLabel
    PartyUI.copyBtn = copyBtn
    PartyUI.membersList = membersList
    PartyUI.createBtn = createBtn
    PartyUI.joinBtn = joinBtn
    PartyUI.leaveBtn = leaveBtn
    PartyUI.queueBtn = queueBtn
    
    -- Button events
    createBtn.MouseButton1Click:Connect(function()
        PartyUI:createParty()
    end)
    
    joinBtn.MouseButton1Click:Connect(function()
        PartyUI:showJoinPrompt()
    end)
    
    leaveBtn.MouseButton1Click:Connect(function()
        PartyUI:leaveParty()
    end)
    
    queueBtn.MouseButton1Click:Connect(function()
        PartyUI:queueAsParty()
    end)
end

function PartyUI:updateUI()
    -- Clear members list
    for _, child in pairs(PartyUI.membersList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    if PartyUI.partyCode then
        PartyUI.codeLabel.Text = "Code: " .. PartyUI.partyCode
        PartyUI.codeLabel.TextColor3 = CONFIG.ACCENT_COLOR
        PartyUI.copyBtn.Visible = true
        PartyUI.createBtn.Visible = false
        PartyUI.joinBtn.Visible = false
        PartyUI.leaveBtn.Visible = true
        PartyUI.queueBtn.Visible = PartyUI.isLeader
        
        -- Show members
        local yPos = 0
        for _, member in ipairs(PartyUI.partyMembers) do
            createPlayerCard(PartyUI.membersList, member, yPos, PartyUI.isLeader)
            yPos = yPos + 55
        end
        PartyUI.membersList.CanvasSize = UDim2.new(0, 0, 0, yPos)
    else
        PartyUI.codeLabel.Text = "No Party"
        PartyUI.codeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        PartyUI.copyBtn.Visible = false
        PartyUI.createBtn.Visible = true
        PartyUI.joinBtn.Visible = true
        PartyUI.leaveBtn.Visible = false
        PartyUI.queueBtn.Visible = false
    end
end

function PartyUI:createParty()
    local partyRemote = ReplicatedStorage:FindFirstChild("PartyRemote")
    if partyRemote then
        partyRemote:FireServer("CREATE")
    end
end

function PartyUI:joinParty(code)
    local partyRemote = ReplicatedStorage:FindFirstChild("PartyRemote")
    if partyRemote then
        partyRemote:FireServer("JOIN", code)
    end
end

function PartyUI:leaveParty()
    local partyRemote = ReplicatedStorage:FindFirstChild("PartyRemote")
    if partyRemote then
        partyRemote:FireServer("LEAVE")
    end
    PartyUI.partyCode = nil
    PartyUI.partyMembers = {}
    PartyUI.isLeader = false
    PartyUI:updateUI()
end

function PartyUI:queueAsParty()
    local partyRemote = ReplicatedStorage:FindFirstChild("PartyRemote")
    if partyRemote then
        partyRemote:FireServer("QUEUE")
    end
end

function PartyUI:showJoinPrompt()
    -- Simple text input for party code
    print("[PartyUI] Enter party code in chat: /join CODE")
end

function PartyUI:show()
    if PartyUI.panel then
        PartyUI.panel.Visible = true
        PartyUI.isVisible = true
        PartyUI:updateUI()
    end
end

function PartyUI:hide()
    if PartyUI.panel then
        PartyUI.panel.Visible = false
        PartyUI.isVisible = false
    end
end

function PartyUI:toggle()
    if PartyUI.isVisible then
        PartyUI:hide()
    else
        PartyUI:show()
    end
end

function PartyUI.init()
    print("[PartyUI] Initializing...")
    createUI()
    
    -- Create remote if needed
    local partyRemote = ReplicatedStorage:FindFirstChild("PartyRemote")
    if partyRemote then
        partyRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "PARTY_UPDATE" then
                PartyUI.partyCode = data.code
                PartyUI.partyMembers = data.members
                PartyUI.isLeader = data.isLeader
                PartyUI:updateUI()
            elseif eventType == "PARTY_DISBANDED" then
                PartyUI.partyCode = nil
                PartyUI.partyMembers = {}
                PartyUI.isLeader = false
                PartyUI:updateUI()
            end
        end)
    end
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.T then
            PartyUI:toggle()
        end
    end)
    
    print("[PartyUI] Initialized! Press T to open")
end

PartyUI.init()
return PartyUI
