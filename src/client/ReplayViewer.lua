-- LocalScript: ReplayViewer.lua
-- Watch recordings of past matches with playback controls

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ReplayViewer = {}
ReplayViewer.isVisible = false
ReplayViewer.isPlaying = false
ReplayViewer.replayData = nil
ReplayViewer.currentTime = 0
ReplayViewer.playbackSpeed = 1
ReplayViewer.ghostPlayers = {}

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    PANEL_COLOR = Color3.fromRGB(30, 30, 45),
}

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ReplayViewer"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    -- Code entry panel
    local entryPanel = Instance.new("Frame")
    entryPanel.Name = "EntryPanel"
    entryPanel.Size = UDim2.new(0, 400, 0, 200)
    entryPanel.Position = UDim2.new(0.5, -200, 0.5, -100)
    entryPanel.BackgroundColor3 = CONFIG.BG_COLOR
    entryPanel.BorderSizePixel = 0
    entryPanel.Visible = false
    entryPanel.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = entryPanel
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.ACCENT_COLOR
    stroke.Thickness = 2
    stroke.Parent = entryPanel
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🎬 REPLAY VIEWER"
    title.TextColor3 = CONFIG.ACCENT_COLOR
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = entryPanel
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = entryPanel
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        ReplayViewer:hide()
    end)
    
    local codeInput = Instance.new("TextBox")
    codeInput.Name = "CodeInput"
    codeInput.Size = UDim2.new(0.7, 0, 0, 45)
    codeInput.Position = UDim2.new(0.05, 0, 0, 70)
    codeInput.BackgroundColor3 = CONFIG.PANEL_COLOR
    codeInput.BorderSizePixel = 0
    codeInput.Text = ""
    codeInput.PlaceholderText = "Enter Replay Code..."
    codeInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    codeInput.TextColor3 = Color3.new(1,1,1)
    codeInput.TextSize = 18
    codeInput.Font = Enum.Font.GothamBold
    codeInput.Parent = entryPanel
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = codeInput
    
    local loadBtn = Instance.new("TextButton")
    loadBtn.Size = UDim2.new(0.2, 0, 0, 45)
    loadBtn.Position = UDim2.new(0.77, 0, 0, 70)
    loadBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
    loadBtn.BorderSizePixel = 0
    loadBtn.Text = "LOAD"
    loadBtn.TextColor3 = Color3.new(0,0,0)
    loadBtn.TextSize = 14
    loadBtn.Font = Enum.Font.GothamBold
    loadBtn.Parent = entryPanel
    
    local loadCorner = Instance.new("UICorner")
    loadCorner.CornerRadius = UDim.new(0, 8)
    loadCorner.Parent = loadBtn
    
    local recentLabel = Instance.new("TextLabel")
    recentLabel.Size = UDim2.new(1, -20, 0, 60)
    recentLabel.Position = UDim2.new(0, 10, 0, 130)
    recentLabel.BackgroundTransparency = 1
    recentLabel.Text = "Recent replays are saved automatically after each match.\nYour last 5 matches are stored."
    recentLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    recentLabel.TextSize = 12
    recentLabel.Font = Enum.Font.Gotham
    recentLabel.TextWrapped = true
    recentLabel.Parent = entryPanel
    
    -- Playback controls (shown during replay)
    local controlBar = Instance.new("Frame")
    controlBar.Name = "ControlBar"
    controlBar.Size = UDim2.new(0, 600, 0, 80)
    controlBar.Position = UDim2.new(0.5, -300, 1, -100)
    controlBar.BackgroundColor3 = CONFIG.BG_COLOR
    controlBar.BackgroundTransparency = 0.2
    controlBar.BorderSizePixel = 0
    controlBar.Visible = false
    controlBar.Parent = screenGui
    
    local controlCorner = Instance.new("UICorner")
    controlCorner.CornerRadius = UDim.new(0, 10)
    controlCorner.Parent = controlBar
    
    -- Timeline
    local timeline = Instance.new("Frame")
    timeline.Size = UDim2.new(0.9, 0, 0, 8)
    timeline.Position = UDim2.new(0.05, 0, 0, 15)
    timeline.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    timeline.BorderSizePixel = 0
    timeline.Parent = controlBar
    
    local timelineCorner = Instance.new("UICorner")
    timelineCorner.CornerRadius = UDim.new(0.5, 0)
    timelineCorner.Parent = timeline
    
    local timelineProgress = Instance.new("Frame")
    timelineProgress.Name = "Progress"
    timelineProgress.Size = UDim2.new(0, 0, 1, 0)
    timelineProgress.BackgroundColor3 = CONFIG.ACCENT_COLOR
    timelineProgress.BorderSizePixel = 0
    timelineProgress.Parent = timeline
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0.5, 0)
    progressCorner.Parent = timelineProgress
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(0, 100, 0, 20)
    timeLabel.Position = UDim2.new(0.05, 0, 0, 25)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "0:00 / 0:00"
    timeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    timeLabel.TextSize = 12
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = controlBar
    
    -- Control buttons
    local playBtn = Instance.new("TextButton")
    playBtn.Name = "PlayBtn"
    playBtn.Size = UDim2.new(0, 50, 0, 35)
    playBtn.Position = UDim2.new(0.5, -75, 0, 40)
    playBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
    playBtn.BorderSizePixel = 0
    playBtn.Text = "▶️"
    playBtn.TextSize = 20
    playBtn.Parent = controlBar
    
    local playCorner = Instance.new("UICorner")
    playCorner.CornerRadius = UDim.new(0, 8)
    playCorner.Parent = playBtn
    
    local rewindBtn = Instance.new("TextButton")
    rewindBtn.Size = UDim2.new(0, 40, 0, 35)
    rewindBtn.Position = UDim2.new(0.5, -120, 0, 40)
    rewindBtn.BackgroundColor3 = CONFIG.PANEL_COLOR
    rewindBtn.BorderSizePixel = 0
    rewindBtn.Text = "⏪"
    rewindBtn.TextSize = 18
    rewindBtn.Parent = controlBar
    
    local rewindCorner = Instance.new("UICorner")
    rewindCorner.CornerRadius = UDim.new(0, 8)
    rewindCorner.Parent = rewindBtn
    
    local forwardBtn = Instance.new("TextButton")
    forwardBtn.Size = UDim2.new(0, 40, 0, 35)
    forwardBtn.Position = UDim2.new(0.5, -20, 0, 40)
    forwardBtn.BackgroundColor3 = CONFIG.PANEL_COLOR
    forwardBtn.BorderSizePixel = 0
    forwardBtn.Text = "⏩"
    forwardBtn.TextSize = 18
    forwardBtn.Parent = controlBar
    
    local forwardCorner = Instance.new("UICorner")
    forwardCorner.CornerRadius = UDim.new(0, 8)
    forwardCorner.Parent = forwardBtn
    
    local speedBtn = Instance.new("TextButton")
    speedBtn.Name = "SpeedBtn"
    speedBtn.Size = UDim2.new(0, 50, 0, 35)
    speedBtn.Position = UDim2.new(0.5, 30, 0, 40)
    speedBtn.BackgroundColor3 = CONFIG.PANEL_COLOR
    speedBtn.BorderSizePixel = 0
    speedBtn.Text = "1x"
    speedBtn.TextColor3 = CONFIG.ACCENT_COLOR
    speedBtn.TextSize = 14
    speedBtn.Font = Enum.Font.GothamBold
    speedBtn.Parent = controlBar
    
    local speedCorner = Instance.new("UICorner")
    speedCorner.CornerRadius = UDim.new(0, 8)
    speedCorner.Parent = speedBtn
    
    local exitBtn = Instance.new("TextButton")
    exitBtn.Size = UDim2.new(0, 80, 0, 35)
    exitBtn.Position = UDim2.new(1, -95, 0, 40)
    exitBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
    exitBtn.BorderSizePixel = 0
    exitBtn.Text = "EXIT"
    exitBtn.TextColor3 = Color3.new(1,1,1)
    exitBtn.TextSize = 14
    exitBtn.Font = Enum.Font.GothamBold
    exitBtn.Parent = controlBar
    
    local exitCorner = Instance.new("UICorner")
    exitCorner.CornerRadius = UDim.new(0, 8)
    exitCorner.Parent = exitBtn
    
    ReplayViewer.screenGui = screenGui
    ReplayViewer.entryPanel = entryPanel
    ReplayViewer.codeInput = codeInput
    ReplayViewer.controlBar = controlBar
    ReplayViewer.timelineProgress = timelineProgress
    ReplayViewer.timeLabel = timeLabel
    ReplayViewer.playBtn = playBtn
    ReplayViewer.speedBtn = speedBtn
    
    -- Button events
    loadBtn.MouseButton1Click:Connect(function()
        local code = codeInput.Text
        if code and #code > 0 then
            ReplayViewer:loadReplay(code:upper())
        end
    end)
    
    playBtn.MouseButton1Click:Connect(function()
        ReplayViewer:togglePlayback()
    end)
    
    rewindBtn.MouseButton1Click:Connect(function()
        ReplayViewer:seek(-10)
    end)
    
    forwardBtn.MouseButton1Click:Connect(function()
        ReplayViewer:seek(10)
    end)
    
    speedBtn.MouseButton1Click:Connect(function()
        ReplayViewer:cycleSpeed()
    end)
    
    exitBtn.MouseButton1Click:Connect(function()
        ReplayViewer:exitReplay()
    end)
end

function ReplayViewer:loadReplay(code)
    local replayRemote = ReplicatedStorage:FindFirstChild("ReplayRemote")
    if replayRemote then
        replayRemote:FireServer("LOAD_REPLAY", {code = code})
    end
end

function ReplayViewer:startPlayback(data)
    ReplayViewer.replayData = data
    ReplayViewer.currentTime = 0
    ReplayViewer.isPlaying = true
    
    ReplayViewer.entryPanel.Visible = false
    ReplayViewer.controlBar.Visible = true
    
    -- Start playback loop
    task.spawn(function()
        while ReplayViewer.replayData and ReplayViewer.isPlaying do
            ReplayViewer.currentTime = ReplayViewer.currentTime + (0.03 * ReplayViewer.playbackSpeed)
            
            if ReplayViewer.currentTime >= ReplayViewer.replayData.d then
                ReplayViewer.isPlaying = false
                ReplayViewer.playBtn.Text = "▶️"
            end
            
            ReplayViewer:updatePlayback()
            task.wait(0.03)
        end
    end)
end

function ReplayViewer:updatePlayback()
    if not ReplayViewer.replayData then return end
    
    local duration = ReplayViewer.replayData.d
    local progress = math.clamp(ReplayViewer.currentTime / duration, 0, 1)
    
    ReplayViewer.timelineProgress.Size = UDim2.new(progress, 0, 1, 0)
    
    local currentMin = math.floor(ReplayViewer.currentTime / 60)
    local currentSec = math.floor(ReplayViewer.currentTime % 60)
    local totalMin = math.floor(duration / 60)
    local totalSec = math.floor(duration % 60)
    
    ReplayViewer.timeLabel.Text = string.format("%d:%02d / %d:%02d", currentMin, currentSec, totalMin, totalSec)
end

function ReplayViewer:togglePlayback()
    ReplayViewer.isPlaying = not ReplayViewer.isPlaying
    ReplayViewer.playBtn.Text = ReplayViewer.isPlaying and "⏸️" or "▶️"
    
    if ReplayViewer.isPlaying then
        ReplayViewer:startPlayback(ReplayViewer.replayData)
    end
end

function ReplayViewer:seek(seconds)
    if not ReplayViewer.replayData then return end
    
    ReplayViewer.currentTime = math.clamp(
        ReplayViewer.currentTime + seconds,
        0,
        ReplayViewer.replayData.d
    )
    ReplayViewer:updatePlayback()
end

function ReplayViewer:cycleSpeed()
    local speeds = {0.25, 0.5, 1, 2, 4}
    local currentIdx = 1
    
    for i, speed in ipairs(speeds) do
        if speed == ReplayViewer.playbackSpeed then
            currentIdx = i
            break
        end
    end
    
    currentIdx = (currentIdx % #speeds) + 1
    ReplayViewer.playbackSpeed = speeds[currentIdx]
    ReplayViewer.speedBtn.Text = ReplayViewer.playbackSpeed .. "x"
end

function ReplayViewer:exitReplay()
    ReplayViewer.isPlaying = false
    ReplayViewer.replayData = nil
    ReplayViewer.currentTime = 0
    
    ReplayViewer.controlBar.Visible = false
    ReplayViewer.entryPanel.Visible = true
    
    -- Clean up ghost players
    for _, ghost in pairs(ReplayViewer.ghostPlayers) do
        if ghost:IsA("Instance") then ghost:Destroy() end
    end
    ReplayViewer.ghostPlayers = {}
end

function ReplayViewer:show()
    if ReplayViewer.entryPanel then
        ReplayViewer.entryPanel.Visible = true
        ReplayViewer.isVisible = true
    end
end

function ReplayViewer:hide()
    ReplayViewer:exitReplay()
    ReplayViewer.entryPanel.Visible = false
    ReplayViewer.controlBar.Visible = false
    ReplayViewer.isVisible = false
end

function ReplayViewer:toggle()
    if ReplayViewer.isVisible then
        ReplayViewer:hide()
    else
        ReplayViewer:show()
    end
end

function ReplayViewer.init()
    print("[ReplayViewer] Initializing...")
    createUI()
    
    local replayRemote = ReplicatedStorage:FindFirstChild("ReplayRemote")
    if replayRemote then
        replayRemote.OnClientEvent:Connect(function(eventType, data)
            if eventType == "REPLAY_DATA" then
                ReplayViewer:startPlayback(data)
            elseif eventType == "REPLAY_ERROR" then
                warn("[ReplayViewer] " .. (data.error or "Unknown error"))
            end
        end)
    end
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Y then
            ReplayViewer:toggle()
        end
    end)
    
    print("[ReplayViewer] Initialized! Press Y to open")
end

ReplayViewer.init()
return ReplayViewer
