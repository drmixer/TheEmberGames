-- LocalScript: AllianceUI.lua
-- Client-side UI for managing alliances
-- Shows alliance status, member list, and invite system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for remote event
local AllianceRemoteEvent = ReplicatedStorage:WaitForChild("AllianceRemoteEvent", 10)

local AllianceUI = {}
AllianceUI.screenGui = nil
AllianceUI.mainFrame = nil
AllianceUI.isVisible = false
AllianceUI.currentAlliance = nil
AllianceUI.pendingInvite = nil

-- Configuration
local CONFIG = {
    PANEL_SIZE = UDim2.new(0, 320, 0, 400),
    TOGGLE_KEY = Enum.KeyCode.P, -- Press P to toggle
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55), -- Gold
    BG_COLOR = Color3.fromRGB(25, 25, 35),
}

-- Play sound
local function playSound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.Parent = PlayerGui
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

-- Create the main UI
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AllianceUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Main panel
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainPanel"
    mainFrame.Size = CONFIG.PANEL_SIZE
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
    mainFrame.BackgroundColor3 = CONFIG.BG_COLOR
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.ACCENT_COLOR
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Fix bottom corners of header
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 15)
    headerFix.Position = UDim2.new(0, 0, 1, -15)
    headerFix.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
    titleLabel.Position = UDim2.new(0.1, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⚔️ ALLIANCES"
    titleLabel.TextColor3 = CONFIG.ACCENT_COLOR
    titleLabel.TextSize = 22
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = header
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        AllianceUI:hide()
    end)
    
    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -60)
    content.Position = UDim2.new(0, 10, 0, 55)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    -- Status section
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, 0, 0, 60)
    statusFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = content
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 1, 0)
    statusLabel.Position = UDim2.new(0, 10, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Not in an alliance"
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    statusLabel.TextSize = 16
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = statusFrame
    
    -- Members list
    local membersFrame = Instance.new("ScrollingFrame")
    membersFrame.Name = "MembersList"
    membersFrame.Size = UDim2.new(1, 0, 0, 150)
    membersFrame.Position = UDim2.new(0, 0, 0, 70)
    membersFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    membersFrame.BorderSizePixel = 0
    membersFrame.ScrollBarThickness = 4
    membersFrame.ScrollBarImageColor3 = CONFIG.ACCENT_COLOR
    membersFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    membersFrame.Parent = content
    
    local membersCorner = Instance.new("UICorner")
    membersCorner.CornerRadius = UDim.new(0, 8)
    membersCorner.Parent = membersFrame
    
    local membersLayout = Instance.new("UIListLayout")
    membersLayout.Padding = UDim.new(0, 5)
    membersLayout.Parent = membersFrame
    
    local membersPadding = Instance.new("UIPadding")
    membersPadding.PaddingTop = UDim.new(0, 8)
    membersPadding.PaddingBottom = UDim.new(0, 8)
    membersPadding.PaddingLeft = UDim.new(0, 8)
    membersPadding.PaddingRight = UDim.new(0, 8)
    membersPadding.Parent = membersFrame
    
    -- Action buttons container
    local actionsFrame = Instance.new("Frame")
    actionsFrame.Name = "ActionsFrame"
    actionsFrame.Size = UDim2.new(1, 0, 0, 100)
    actionsFrame.Position = UDim2.new(0, 0, 0, 230)
    actionsFrame.BackgroundTransparency = 1
    actionsFrame.Parent = content
    
    -- Create Alliance button
    local createBtn = Instance.new("TextButton")
    createBtn.Name = "CreateButton"
    createBtn.Size = UDim2.new(1, 0, 0, 40)
    createBtn.Position = UDim2.new(0, 0, 0, 0)
    createBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
    createBtn.BorderSizePixel = 0
    createBtn.Text = "🏛️ Create Alliance"
    createBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    createBtn.TextSize = 16
    createBtn.Font = Enum.Font.GothamBold
    createBtn.Parent = actionsFrame
    
    local createBtnCorner = Instance.new("UICorner")
    createBtnCorner.CornerRadius = UDim.new(0, 8)
    createBtnCorner.Parent = createBtn
    
    createBtn.MouseButton1Click:Connect(function()
        if AllianceRemoteEvent then
            AllianceRemoteEvent:FireServer("CREATE_ALLIANCE")
        end
    end)
    
    -- Leave Alliance button (hidden by default)
    local leaveBtn = Instance.new("TextButton")
    leaveBtn.Name = "LeaveButton"
    leaveBtn.Size = UDim2.new(1, 0, 0, 40)
    leaveBtn.Position = UDim2.new(0, 0, 0, 50)
    leaveBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    leaveBtn.BorderSizePixel = 0
    leaveBtn.Text = "🚪 Leave Alliance"
    leaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    leaveBtn.TextSize = 16
    leaveBtn.Font = Enum.Font.GothamBold
    leaveBtn.Visible = false
    leaveBtn.Parent = actionsFrame
    
    local leaveBtnCorner = Instance.new("UICorner")
    leaveBtnCorner.CornerRadius = UDim.new(0, 8)
    leaveBtnCorner.Parent = leaveBtn
    
    leaveBtn.MouseButton1Click:Connect(function()
        if AllianceRemoteEvent then
            AllianceRemoteEvent:FireServer("LEAVE_ALLIANCE")
        end
    end)
    
    -- Invite player section
    local inviteFrame = Instance.new("Frame")
    inviteFrame.Name = "InviteFrame"
    inviteFrame.Size = UDim2.new(1, 0, 0, 40)
    inviteFrame.Position = UDim2.new(0, 0, 1, -50)
    inviteFrame.BackgroundTransparency = 1
    inviteFrame.Visible = false
    inviteFrame.Parent = content
    
    local inviteInput = Instance.new("TextBox")
    inviteInput.Name = "InviteInput"
    inviteInput.Size = UDim2.new(0.65, 0, 1, 0)
    inviteInput.Position = UDim2.new(0, 0, 0, 0)
    inviteInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    inviteInput.BorderSizePixel = 0
    inviteInput.Text = ""
    inviteInput.PlaceholderText = "Player name..."
    inviteInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    inviteInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    inviteInput.TextSize = 14
    inviteInput.Font = Enum.Font.Gotham
    inviteInput.Parent = inviteFrame
    
    local inviteInputCorner = Instance.new("UICorner")
    inviteInputCorner.CornerRadius = UDim.new(0, 6)
    inviteInputCorner.Parent = inviteInput
    
    local inviteBtn = Instance.new("TextButton")
    inviteBtn.Name = "InviteButton"
    inviteBtn.Size = UDim2.new(0.33, 0, 1, 0)
    inviteBtn.Position = UDim2.new(0.67, 0, 0, 0)
    inviteBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    inviteBtn.BorderSizePixel = 0
    inviteBtn.Text = "Invite"
    inviteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    inviteBtn.TextSize = 14
    inviteBtn.Font = Enum.Font.GothamBold
    inviteBtn.Parent = inviteFrame
    
    local inviteBtnCorner = Instance.new("UICorner")
    inviteBtnCorner.CornerRadius = UDim.new(0, 6)
    inviteBtnCorner.Parent = inviteBtn
    
    inviteBtn.MouseButton1Click:Connect(function()
        local targetName = inviteInput.Text
        if targetName and targetName ~= "" then
            if AllianceRemoteEvent then
                AllianceRemoteEvent:FireServer("INVITE_PLAYER", targetName)
            end
            inviteInput.Text = ""
        end
    end)
    
    -- Store references
    AllianceUI.screenGui = screenGui
    AllianceUI.mainFrame = mainFrame
    AllianceUI.statusLabel = statusLabel
    AllianceUI.membersFrame = membersFrame
    AllianceUI.createBtn = createBtn
    AllianceUI.leaveBtn = leaveBtn
    AllianceUI.inviteFrame = inviteFrame
    
    return screenGui
end

-- Create invite popup
local function createInvitePopup()
    local popup = Instance.new("Frame")
    popup.Name = "InvitePopup"
    popup.Size = UDim2.new(0, 300, 0, 120)
    popup.Position = UDim2.new(0.5, -150, 0, -150) -- Start off-screen
    popup.BackgroundColor3 = CONFIG.BG_COLOR
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.Parent = AllianceUI.screenGui
    
    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, 10)
    popupCorner.Parent = popup
    
    local popupStroke = Instance.new("UIStroke")
    popupStroke.Color = CONFIG.ACCENT_COLOR
    popupStroke.Thickness = 2
    popupStroke.Parent = popup
    
    local popupTitle = Instance.new("TextLabel")
    popupTitle.Name = "Title"
    popupTitle.Size = UDim2.new(1, -20, 0, 30)
    popupTitle.Position = UDim2.new(0, 10, 0, 10)
    popupTitle.BackgroundTransparency = 1
    popupTitle.Text = "⚔️ Alliance Invite"
    popupTitle.TextColor3 = CONFIG.ACCENT_COLOR
    popupTitle.TextSize = 18
    popupTitle.Font = Enum.Font.GothamBold
    popupTitle.TextXAlignment = Enum.TextXAlignment.Left
    popupTitle.Parent = popup
    
    local popupMessage = Instance.new("TextLabel")
    popupMessage.Name = "Message"
    popupMessage.Size = UDim2.new(1, -20, 0, 30)
    popupMessage.Position = UDim2.new(0, 10, 0, 40)
    popupMessage.BackgroundTransparency = 1
    popupMessage.Text = ""
    popupMessage.TextColor3 = Color3.fromRGB(200, 200, 200)
    popupMessage.TextSize = 14
    popupMessage.Font = Enum.Font.Gotham
    popupMessage.TextXAlignment = Enum.TextXAlignment.Left
    popupMessage.TextWrapped = true
    popupMessage.Parent = popup
    
    local acceptBtn = Instance.new("TextButton")
    acceptBtn.Name = "AcceptButton"
    acceptBtn.Size = UDim2.new(0.45, 0, 0, 30)
    acceptBtn.Position = UDim2.new(0.025, 0, 1, -40)
    acceptBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    acceptBtn.BorderSizePixel = 0
    acceptBtn.Text = "Accept"
    acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    acceptBtn.TextSize = 14
    acceptBtn.Font = Enum.Font.GothamBold
    acceptBtn.Parent = popup
    
    local acceptBtnCorner = Instance.new("UICorner")
    acceptBtnCorner.CornerRadius = UDim.new(0, 6)
    acceptBtnCorner.Parent = acceptBtn
    
    local declineBtn = Instance.new("TextButton")
    declineBtn.Name = "DeclineButton"
    declineBtn.Size = UDim2.new(0.45, 0, 0, 30)
    declineBtn.Position = UDim2.new(0.525, 0, 1, -40)
    declineBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    declineBtn.BorderSizePixel = 0
    declineBtn.Text = "Decline"
    declineBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    declineBtn.TextSize = 14
    declineBtn.Font = Enum.Font.GothamBold
    declineBtn.Parent = popup
    
    local declineBtnCorner = Instance.new("UICorner")
    declineBtnCorner.CornerRadius = UDim.new(0, 6)
    declineBtnCorner.Parent = declineBtn
    
    acceptBtn.MouseButton1Click:Connect(function()
        if AllianceRemoteEvent then
            AllianceRemoteEvent:FireServer("ACCEPT_INVITE")
        end
        AllianceUI:hideInvitePopup()
    end)
    
    declineBtn.MouseButton1Click:Connect(function()
        if AllianceRemoteEvent then
            AllianceRemoteEvent:FireServer("DECLINE_INVITE")
        end
        AllianceUI:hideInvitePopup()
    end)
    
    AllianceUI.invitePopup = popup
    AllianceUI.invitePopupMessage = popupMessage
    
    return popup
end

-- Show invite popup
function AllianceUI:showInvitePopup(inviterName, allianceName)
    if not AllianceUI.invitePopup then return end
    
    AllianceUI.invitePopupMessage.Text = inviterName .. " invites you to join " .. allianceName
    AllianceUI.invitePopup.Visible = true
    
    -- Animate in
    AllianceUI.invitePopup.Position = UDim2.new(0.5, -150, 0, -150)
    TweenService:Create(AllianceUI.invitePopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -150, 0, 20)
    }):Play()
    
    playSound("rbxassetid://9046239626", 0.5)
end

-- Hide invite popup
function AllianceUI:hideInvitePopup()
    if not AllianceUI.invitePopup then return end
    
    TweenService:Create(AllianceUI.invitePopup, TweenInfo.new(0.2), {
        Position = UDim2.new(0.5, -150, 0, -150)
    }):Play()
    
    task.delay(0.2, function()
        AllianceUI.invitePopup.Visible = false
    end)
end

-- Update alliance display
function AllianceUI:updateDisplay(allianceInfo)
    AllianceUI.currentAlliance = allianceInfo
    
    if allianceInfo then
        -- In alliance
        AllianceUI.statusLabel.Text = "🏛️ " .. allianceInfo.name .. " (" .. allianceInfo.memberCount .. "/" .. allianceInfo.maxSize .. ")"
        AllianceUI.createBtn.Visible = false
        AllianceUI.leaveBtn.Visible = true
        AllianceUI.inviteFrame.Visible = allianceInfo.isLeader
        
        -- Update members list
        for _, child in pairs(AllianceUI.membersFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        for i, member in ipairs(allianceInfo.members) do
            local memberFrame = Instance.new("Frame")
            memberFrame.Name = "Member_" .. member.name
            memberFrame.Size = UDim2.new(1, 0, 0, 35)
            memberFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            memberFrame.BorderSizePixel = 0
            memberFrame.Parent = AllianceUI.membersFrame
            
            local memberCorner = Instance.new("UICorner")
            memberCorner.CornerRadius = UDim.new(0, 6)
            memberCorner.Parent = memberFrame
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = (member.isLeader and "👑 " or "⚔️ ") .. member.name
            nameLabel.TextColor3 = member.isLeader and CONFIG.ACCENT_COLOR or Color3.fromRGB(200, 200, 200)
            nameLabel.TextSize = 14
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = memberFrame
        end
        
        AllianceUI.membersFrame.CanvasSize = UDim2.new(0, 0, 0, #allianceInfo.members * 40)
    else
        -- Not in alliance
        AllianceUI.statusLabel.Text = "Not in an alliance\nPress P to open, create or join one!"
        AllianceUI.createBtn.Visible = true
        AllianceUI.leaveBtn.Visible = false
        AllianceUI.inviteFrame.Visible = false
        
        -- Clear members list
        for _, child in pairs(AllianceUI.membersFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
end

-- Show UI
function AllianceUI:show()
    if AllianceUI.mainFrame then
        AllianceUI.mainFrame.Visible = true
        AllianceUI.isVisible = true
        
        -- Request latest alliance info
        if AllianceRemoteEvent then
            AllianceRemoteEvent:FireServer("GET_ALLIANCE_INFO")
        end
        
        -- Animate in
        AllianceUI.mainFrame.Position = UDim2.new(0.5, -160, 0.6, -200)
        TweenService:Create(AllianceUI.mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -160, 0.5, -200)
        }):Play()
    end
end

-- Hide UI
function AllianceUI:hide()
    if AllianceUI.mainFrame then
        TweenService:Create(AllianceUI.mainFrame, TweenInfo.new(0.2), {
            Position = UDim2.new(0.5, -160, 0.6, -200)
        }):Play()
        
        task.delay(0.2, function()
            AllianceUI.mainFrame.Visible = false
            AllianceUI.isVisible = false
        end)
    end
end

-- Toggle UI
function AllianceUI:toggle()
    if AllianceUI.isVisible then
        AllianceUI:hide()
    else
        AllianceUI:show()
    end
end

-- Show notification
function AllianceUI:showNotification(message, color)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 50)
    notification.Position = UDim2.new(0.5, -150, 1, 0)
    notification.BackgroundColor3 = color or CONFIG.BG_COLOR
    notification.BorderSizePixel = 0
    notification.Parent = AllianceUI.screenGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notification
    
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = CONFIG.ACCENT_COLOR
    notifStroke.Thickness = 1
    notifStroke.Parent = notification
    
    local notifLabel = Instance.new("TextLabel")
    notifLabel.Size = UDim2.new(1, -20, 1, 0)
    notifLabel.Position = UDim2.new(0, 10, 0, 0)
    notifLabel.BackgroundTransparency = 1
    notifLabel.Text = message
    notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifLabel.TextSize = 14
    notifLabel.Font = Enum.Font.Gotham
    notifLabel.TextWrapped = true
    notifLabel.Parent = notification
    
    -- Animate in
    TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -150, 1, -70)
    }):Play()
    
    -- Animate out after delay
    task.delay(3, function()
        TweenService:Create(notification, TweenInfo.new(0.2), {
            Position = UDim2.new(0.5, -150, 1, 0)
        }):Play()
        task.delay(0.2, function()
            notification:Destroy()
        end)
    end)
end

-- Initialize
function AllianceUI.init()
    print("[AllianceUI] Initializing...")
    
    createUI()
    createInvitePopup()
    
    -- Handle keyboard input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONFIG.TOGGLE_KEY then
            AllianceUI:toggle()
        end
    end)
    
    -- Handle server events
    if AllianceRemoteEvent then
        AllianceRemoteEvent.OnClientEvent:Connect(function(eventType, data)
            if eventType == "ALLIANCE_INFO" then
                AllianceUI:updateDisplay(data)
                
            elseif eventType == "ALLIANCE_CREATED" then
                AllianceUI:showNotification("⚔️ Alliance created: " .. data.name, Color3.fromRGB(50, 100, 50))
                if AllianceRemoteEvent then
                    AllianceRemoteEvent:FireServer("GET_ALLIANCE_INFO")
                end
                
            elseif eventType == "ALLIANCE_INVITE" then
                AllianceUI:showInvitePopup(data.fromPlayerName, data.allianceName)
                
            elseif eventType == "INVITE_EXPIRED" then
                AllianceUI:hideInvitePopup()
                AllianceUI:showNotification("Alliance invite expired", Color3.fromRGB(100, 100, 100))
                
            elseif eventType == "ALLIANCE_MEMBER_JOINED" then
                AllianceUI:showNotification("⚔️ " .. data.playerName .. " joined the alliance!", Color3.fromRGB(50, 100, 50))
                if AllianceRemoteEvent then
                    AllianceRemoteEvent:FireServer("GET_ALLIANCE_INFO")
                end
                
            elseif eventType == "ALLIANCE_MEMBER_LEFT" then
                AllianceUI:showNotification("🚪 " .. data.playerName .. " left the alliance", Color3.fromRGB(100, 100, 50))
                if AllianceRemoteEvent then
                    AllianceRemoteEvent:FireServer("GET_ALLIANCE_INFO")
                end
                
            elseif eventType == "ALLIANCE_BETRAYAL" then
                AllianceUI:showNotification("⚠️ BETRAYAL! " .. data.traitorName .. " attacked " .. data.victimName .. "!", Color3.fromRGB(150, 50, 50))
                playSound("rbxassetid://5034047634", 0.6)
                if AllianceRemoteEvent then
                    AllianceRemoteEvent:FireServer("GET_ALLIANCE_INFO")
                end
                
            elseif eventType == "YOU_BETRAYED" then
                AllianceUI:showNotification("⚠️ You betrayed " .. data.allianceName .. "! Cooldown: " .. data.cooldown .. "s", Color3.fromRGB(150, 50, 50))
                AllianceUI:updateDisplay(nil)
                
            elseif eventType == "LEFT_ALLIANCE" then
                AllianceUI:showNotification("You left " .. data.allianceName, Color3.fromRGB(100, 100, 100))
                AllianceUI:updateDisplay(nil)
                
            elseif eventType == "INVITE_SENT" then
                AllianceUI:showNotification("Invite sent to " .. data.targetPlayerName, Color3.fromRGB(50, 100, 150))
                
            elseif eventType == "INVITE_FAILED" then
                AllianceUI:showNotification("❌ " .. data.message, Color3.fromRGB(150, 50, 50))
                
            elseif eventType == "INVITE_DECLINED" then
                AllianceUI:showNotification(data.playerName .. " declined your invite", Color3.fromRGB(100, 100, 100))
            end
        end)
    end
    
    print("[AllianceUI] Initialized - Press P to toggle")
end

-- Initialize when module loads
AllianceUI.init()

return AllianceUI
