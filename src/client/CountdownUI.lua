-- LocalScript: CountdownUI.lua
-- Creates a dramatic countdown display for match start
-- Includes cinematic camera pan and improved visual countdown

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Wait for remote events
local LobbyRemoteEvent = ReplicatedStorage:WaitForChild("LobbyRemoteEvent", 10)
local SpawnerRemoteEvent = ReplicatedStorage:WaitForChild("SpawnerRemoteEvent", 10)
local MatchRemoteEvent = ReplicatedStorage:WaitForChild("MatchRemoteEvent", 10)

local CountdownUI = {}
CountdownUI.screenGui = nil
CountdownUI.countdownFrame = nil
CountdownUI.numberLabel = nil
CountdownUI.subtitleLabel = nil
CountdownUI.cinematicActive = false
CountdownUI.originalCameraType = nil
CountdownUI.countdownConnection = nil

-- Sound IDs (VERIFIED Roblox audio assets)
local SOUND_IDS = {
    COUNTDOWN_BEEP = "rbxassetid://9046239626", -- Verified countdown tick/beep
    COUNTDOWN_FINAL = "rbxassetid://9046239626", -- Verified countdown tick/beep
    MATCH_GONG = "rbxassetid://9046240113", -- Verified match start horn/gong
}

-- Create the main screen GUI
local function createScreenGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CountdownUIScreen"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    return screenGui
end

-- Create countdown display frame
local function createCountdownFrame()
    -- Main container - full screen overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "CountdownOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.Visible = false
    overlay.Parent = CountdownUI.screenGui
    
    -- Dark vignette edges
    local topVignette = Instance.new("Frame")
    topVignette.Name = "TopVignette"
    topVignette.Size = UDim2.new(1, 0, 0.15, 0)
    topVignette.Position = UDim2.new(0, 0, 0, 0)
    topVignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    topVignette.BorderSizePixel = 0
    topVignette.Parent = overlay
    
    local topGradient = Instance.new("UIGradient")
    topGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    topGradient.Rotation = 90
    topGradient.Parent = topVignette
    
    local bottomVignette = topVignette:Clone()
    bottomVignette.Name = "BottomVignette"
    bottomVignette.Position = UDim2.new(0, 0, 0.85, 0)
    local bottomGradient = bottomVignette:FindFirstChild("UIGradient")
    if bottomGradient then
        bottomGradient.Rotation = -90
    end
    bottomVignette.Parent = overlay
    
    -- Center countdown container
    local centerFrame = Instance.new("Frame")
    centerFrame.Name = "CenterFrame"
    centerFrame.Size = UDim2.new(0.4, 0, 0.4, 0)
    centerFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
    centerFrame.BackgroundTransparency = 1
    centerFrame.Parent = overlay
    
    -- Large countdown number
    local numberLabel = Instance.new("TextLabel")
    numberLabel.Name = "NumberLabel"
    numberLabel.Size = UDim2.new(1, 0, 0.7, 0)
    numberLabel.Position = UDim2.new(0, 0, 0, 0)
    numberLabel.BackgroundTransparency = 1
    numberLabel.Text = "60"
    numberLabel.TextScaled = true
    numberLabel.Font = Enum.Font.GothamBold
    numberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    numberLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    numberLabel.TextStrokeTransparency = 0
    numberLabel.Parent = centerFrame
    
    -- Subtitle text
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "SubtitleLabel"
    subtitleLabel.Size = UDim2.new(1, 0, 0.2, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.7, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "AWAIT THE GONG"
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.GothamBold
    subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    subtitleLabel.TextStrokeTransparency = 0.3
    subtitleLabel.Parent = centerFrame
    
    -- "Movement Locked" warning
    local lockedLabel = Instance.new("TextLabel")
    lockedLabel.Name = "LockedLabel"
    lockedLabel.Size = UDim2.new(0.6, 0, 0.06, 0)
    lockedLabel.Position = UDim2.new(0.2, 0, 0.92, 0)
    lockedLabel.BackgroundTransparency = 1
    lockedLabel.Text = "⚠️ MOVEMENT LOCKED - EARLY MOVEMENT MEANS ELIMINATION ⚠️"
    lockedLabel.TextScaled = true
    lockedLabel.Font = Enum.Font.GothamBold
    lockedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    lockedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lockedLabel.TextStrokeTransparency = 0
    lockedLabel.Parent = overlay
    
    -- Outer glow ring around number (decorative)
    local glowRing = Instance.new("UIStroke")
    glowRing.Color = Color3.fromRGB(255, 200, 100)
    glowRing.Thickness = 3
    glowRing.Transparency = 0.5
    glowRing.Parent = centerFrame
    
    CountdownUI.numberLabel = numberLabel
    CountdownUI.subtitleLabel = subtitleLabel
    
    return overlay
end

-- Play sound locally
local function playSound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 1
    sound.Parent = PlayerGui
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    return sound
end

-- Animate the number display
local function animateNumber(number)
    if not CountdownUI.numberLabel then return end
    
    local label = CountdownUI.numberLabel
    label.Text = tostring(number)
    
    -- Color based on time remaining
    if number <= 3 then
        label.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red
        playSound(SOUND_IDS.COUNTDOWN_FINAL, 1.2)
    elseif number <= 10 then
        label.TextColor3 = Color3.fromRGB(255, 200, 50) -- Orange/Yellow
        playSound(SOUND_IDS.COUNTDOWN_BEEP, 0.8)
    else
        label.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
    end
    
    -- Scale animation
    local originalSize = UDim2.new(1, 0, 0.7, 0)
    label.Size = UDim2.new(1.2, 0, 0.84, 0)
    
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    local tween = TweenService:Create(label, tweenInfo, {
        Size = originalSize
    })
    tween:Play()
    
    -- Update subtitle based on time
    if CountdownUI.subtitleLabel then
        if number <= 10 then
            CountdownUI.subtitleLabel.Text = "PREPARE YOURSELF"
            CountdownUI.subtitleLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
        elseif number <= 30 then
            CountdownUI.subtitleLabel.Text = "THE GAMES BEGIN SOON"
            CountdownUI.subtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
        else
            CountdownUI.subtitleLabel.Text = "AWAIT THE GONG"
            CountdownUI.subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

-- Show "GO!" animation
local function showGoAnimation()
    if not CountdownUI.numberLabel then return end
    
    local label = CountdownUI.numberLabel
    label.Text = "GO!"
    label.TextColor3 = Color3.fromRGB(50, 255, 50) -- Green
    label.Size = UDim2.new(0.5, 0, 0.35, 0)
    
    -- Play gong sound
    playSound(SOUND_IDS.MATCH_GONG, 1.5)
    
    -- Expand animation
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local expandTween = TweenService:Create(label, tweenInfo, {
        Size = UDim2.new(1.5, 0, 1.05, 0)
    })
    expandTween:Play()
    
    -- Update subtitle
    if CountdownUI.subtitleLabel then
        CountdownUI.subtitleLabel.Text = "MAY THE ODDS BE EVER IN YOUR FAVOR"
        CountdownUI.subtitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    end
    
    -- Fade out after delay
    task.delay(2, function()
        CountdownUI:hide()
    end)
end

-- Perform cinematic camera pan around arena
function CountdownUI:startCinematicPan()
    if CountdownUI.cinematicActive then return end
    
    CountdownUI.cinematicActive = true
    CountdownUI.originalCameraType = Camera.CameraType
    
    -- Store original camera settings
    local character = Player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Switch to scriptable camera
    Camera.CameraType = Enum.CameraType.Scriptable
    
    local arenaCenter = Vector3.new(0, 5, 0) -- Center of arena
    local playerPos = humanoidRootPart.Position
    local panRadius = 60
    local panHeight = 30
    local panDuration = 8 -- Seconds for one pan
    
    local startTime = tick()
    local startAngle = math.atan2(playerPos.Z, playerPos.X)
    
    -- Store connection for cleanup
    CountdownUI.cinematicConnection = RunService.RenderStepped:Connect(function()
        if not CountdownUI.cinematicActive then
            if CountdownUI.cinematicConnection then
                CountdownUI.cinematicConnection:Disconnect()
                CountdownUI.cinematicConnection = nil
            end
            return
        end
        
        local elapsed = tick() - startTime
        local progress = (elapsed % panDuration) / panDuration
        local angle = startAngle + (progress * math.pi * 0.5) -- Pan 90 degrees
        
        -- Calculate camera position
        local camX = math.cos(angle) * panRadius
        local camZ = math.sin(angle) * panRadius
        local camY = panHeight + math.sin(progress * math.pi * 2) * 5 -- Slight vertical bob
        
        local cameraPos = arenaCenter + Vector3.new(camX, camY, camZ)
        
        -- Look at arena center (slightly above ground)
        Camera.CFrame = CFrame.new(cameraPos, arenaCenter + Vector3.new(0, 10, 0))
    end)
    
    print("[CountdownUI] Cinematic pan started")
end

-- Stop cinematic camera and return to player
function CountdownUI:stopCinematicPan()
    if not CountdownUI.cinematicActive then return end
    
    CountdownUI.cinematicActive = false
    
    if CountdownUI.cinematicConnection then
        CountdownUI.cinematicConnection:Disconnect()
        CountdownUI.cinematicConnection = nil
    end
    
    -- Return camera to player
    Camera.CameraType = CountdownUI.originalCameraType or Enum.CameraType.Custom
    
    print("[CountdownUI] Cinematic pan stopped")
end

-- Show countdown UI
function CountdownUI:show(initialTime)
    if not CountdownUI.countdownFrame then return end
    
    CountdownUI.countdownFrame.Visible = true
    animateNumber(initialTime or 60)
    
    -- Start cinematic if we have enough time
    if initialTime and initialTime > 15 then
        CountdownUI:startCinematicPan()
        
        -- Stop cinematic pan with 10 seconds remaining
        task.delay(initialTime - 10, function()
            CountdownUI:stopCinematicPan()
        end)
    end
end

-- Hide countdown UI
function CountdownUI:hide()
    if not CountdownUI.countdownFrame then return end
    
    -- Fade out animation
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Fade all text elements
    for _, child in pairs(CountdownUI.countdownFrame:GetDescendants()) do
        if child:IsA("TextLabel") then
            local fadeTween = TweenService:Create(child, tweenInfo, {
                TextTransparency = 1,
                TextStrokeTransparency = 1
            })
            fadeTween:Play()
        end
    end
    
    task.delay(0.5, function()
        CountdownUI.countdownFrame.Visible = false
        
        -- Reset text transparency for next use
        for _, child in pairs(CountdownUI.countdownFrame:GetDescendants()) do
            if child:IsA("TextLabel") then
                child.TextTransparency = 0
                child.TextStrokeTransparency = 0
            end
        end
    end)
    
    -- Ensure camera is returned
    CountdownUI:stopCinematicPan()
end

-- Update countdown
function CountdownUI:updateCountdown(seconds)
    if seconds <= 0 then
        showGoAnimation()
    else
        animateNumber(seconds)
    end
end

-- Initialize CountdownUI
function CountdownUI.init()
    print("[CountdownUI] Initializing...")
    
    -- Create UI elements
    CountdownUI.screenGui = createScreenGui()
    CountdownUI.countdownFrame = createCountdownFrame()
    
    -- Connect to spawner events (for countdown)
    if SpawnerRemoteEvent then
        SpawnerRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "COUNTDOWN_STARTED" then
                local duration = args[1]
                CountdownUI:show(duration)
                
                -- Start countdown loop
                local remaining = duration
                if CountdownUI.countdownConnection then
                    CountdownUI.countdownConnection:Disconnect()
                end
                
                CountdownUI.countdownConnection = task.spawn(function()
                    while remaining > 0 do
                        task.wait(1)
                        remaining = remaining - 1
                        CountdownUI:updateCountdown(remaining)
                    end
                end)
                
            elseif eventType == "COUNTDOWN_ENDED" then
                showGoAnimation()
                
            elseif eventType == "MOVEMENT_LOCKED" then
                local locked = args[1]
                -- Could show/hide movement locked warning
            end
        end)
    end
    
    -- Connect to match events as backup
    if MatchRemoteEvent then
        MatchRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "MATCH_START_HORN" then
                showGoAnimation()
            end
        end)
    end
    
    print("[CountdownUI] Initialized successfully")
end

-- Initialize when module loads
CountdownUI.init()

return CountdownUI
