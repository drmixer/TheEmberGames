-- LocalScript: VictoryUI.lua
-- Handles victory sequence display, elimination announcements, and match end UI
-- Creates dramatic visual effects for winner announcement

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for MatchRemoteEvent to be created
local MatchRemoteEvent = ReplicatedStorage:WaitForChild("MatchRemoteEvent", 10)

local VictoryUI = {}
VictoryUI.screenGui = nil
VictoryUI.victoryFrame = nil
VictoryUI.eliminationFrame = nil

-- Sound configuration
local SOUND_IDS = {
    CANNON = "rbxassetid://1837108707",
    VICTORY_FANFARE = "rbxassetid://1837130432",
    COUNTDOWN_BEEP = "rbxassetid://138084957",
    FIREWORK = "rbxassetid://130788893",
}

-- Create main screen GUI for victory/elimination UI
local function createScreenGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VictoryUIScreen"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    return screenGui
end

-- Create elimination popup UI
local function createEliminationPopup()
    local frame = Instance.new("Frame")
    frame.Name = "EliminationPopup"
    frame.Size = UDim2.new(0.4, 0, 0.15, 0)
    frame.Position = UDim2.new(0.3, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = VictoryUI.screenGui
    
    -- Corner decoration
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    -- Cannon icon (represented as text for now)
    local cannonIcon = Instance.new("TextLabel")
    cannonIcon.Name = "CannonIcon"
    cannonIcon.Size = UDim2.new(0.15, 0, 0.8, 0)
    cannonIcon.Position = UDim2.new(0.02, 0, 0.1, 0)
    cannonIcon.BackgroundTransparency = 1
    cannonIcon.Text = "💀"
    cannonIcon.TextScaled = true
    cannonIcon.Font = Enum.Font.GothamBold
    cannonIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
    cannonIcon.Parent = frame
    
    -- Player name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PlayerName"
    nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0.18, 0, 0.1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "TRIBUTE FALLEN"
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = frame
    
    -- Remaining players label
    local remainingLabel = Instance.new("TextLabel")
    remainingLabel.Name = "RemainingPlayers"
    remainingLabel.Size = UDim2.new(0.6, 0, 0.35, 0)
    remainingLabel.Position = UDim2.new(0.18, 0, 0.55, 0)
    remainingLabel.BackgroundTransparency = 1
    remainingLabel.Text = "Tributes remaining: 23"
    remainingLabel.TextScaled = true
    remainingLabel.Font = Enum.Font.Gotham
    remainingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    remainingLabel.TextXAlignment = Enum.TextXAlignment.Left
    remainingLabel.Parent = frame
    
    return frame
end

-- Create victory screen UI
local function createVictoryScreen()
    local frame = Instance.new("Frame")
    frame.Name = "VictoryScreen"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = VictoryUI.screenGui
    
    -- Victory title
    local victoryTitle = Instance.new("TextLabel")
    victoryTitle.Name = "VictoryTitle"
    victoryTitle.Size = UDim2.new(0.8, 0, 0.15, 0)
    victoryTitle.Position = UDim2.new(0.1, 0, 0.1, 0)
    victoryTitle.BackgroundTransparency = 1
    victoryTitle.Text = "🏆 VICTORY 🏆"
    victoryTitle.TextScaled = true
    victoryTitle.Font = Enum.Font.GothamBold
    victoryTitle.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    victoryTitle.Parent = frame
    
    -- Winner name
    local winnerName = Instance.new("TextLabel")
    winnerName.Name = "WinnerName"
    winnerName.Size = UDim2.new(0.8, 0, 0.12, 0)
    winnerName.Position = UDim2.new(0.1, 0, 0.28, 0)
    winnerName.BackgroundTransparency = 1
    winnerName.Text = "WINNER_NAME"
    winnerName.TextScaled = true
    winnerName.Font = Enum.Font.GothamBold
    winnerName.TextColor3 = Color3.fromRGB(255, 255, 255)
    winnerName.Parent = frame
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(0.8, 0, 0.06, 0)
    subtitle.Position = UDim2.new(0.1, 0, 0.42, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "is the last tribute standing!"
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.Parent = frame
    
    -- Stats frame
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(0.5, 0, 0.25, 0)
    statsFrame.Position = UDim2.new(0.25, 0, 0.52, 0)
    statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    statsFrame.BackgroundTransparency = 0.5
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = frame
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 10)
    statsCorner.Parent = statsFrame
    
    -- Kills stat
    local killsLabel = Instance.new("TextLabel")
    killsLabel.Name = "KillsLabel"
    killsLabel.Size = UDim2.new(0.45, 0, 0.4, 0)
    killsLabel.Position = UDim2.new(0.025, 0, 0.1, 0)
    killsLabel.BackgroundTransparency = 1
    killsLabel.Text = "Eliminations: 0"
    killsLabel.TextScaled = true
    killsLabel.Font = Enum.Font.Gotham
    killsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    killsLabel.TextXAlignment = Enum.TextXAlignment.Left
    killsLabel.Parent = statsFrame
    
    -- Duration stat
    local durationLabel = Instance.new("TextLabel")
    durationLabel.Name = "DurationLabel"
    durationLabel.Size = UDim2.new(0.45, 0, 0.4, 0)
    durationLabel.Position = UDim2.new(0.525, 0, 0.1, 0)
    durationLabel.BackgroundTransparency = 1
    durationLabel.Text = "Match Time: 00:00"
    durationLabel.TextScaled = true
    durationLabel.Font = Enum.Font.Gotham
    durationLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    durationLabel.TextXAlignment = Enum.TextXAlignment.Left
    durationLabel.Parent = statsFrame
    
    -- Total players stat
    local totalPlayersLabel = Instance.new("TextLabel")
    totalPlayersLabel.Name = "TotalPlayersLabel"
    totalPlayersLabel.Size = UDim2.new(0.95, 0, 0.4, 0)
    totalPlayersLabel.Position = UDim2.new(0.025, 0, 0.55, 0)
    totalPlayersLabel.BackgroundTransparency = 1
    totalPlayersLabel.Text = "Total Tributes: 24"
    totalPlayersLabel.TextScaled = true
    totalPlayersLabel.Font = Enum.Font.Gotham
    totalPlayersLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    totalPlayersLabel.TextXAlignment = Enum.TextXAlignment.Left
    totalPlayersLabel.Parent = statsFrame
    
    -- Return to lobby text
    local returnText = Instance.new("TextLabel")
    returnText.Name = "ReturnText"
    returnText.Size = UDim2.new(0.8, 0, 0.06, 0)
    returnText.Position = UDim2.new(0.1, 0, 0.85, 0)
    returnText.BackgroundTransparency = 1
    returnText.Text = "Returning to lobby in 15 seconds..."
    returnText.TextScaled = true
    returnText.Font = Enum.Font.Gotham
    returnText.TextColor3 = Color3.fromRGB(150, 150, 150)
    returnText.Parent = frame
    
    return frame
end

-- Create countdown overlay UI (for final countdown before match)
local function createCountdownOverlay()
    local frame = Instance.new("Frame")
    frame.Name = "CountdownOverlay"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.7
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = VictoryUI.screenGui
    
    -- Large countdown number
    local countdownNumber = Instance.new("TextLabel")
    countdownNumber.Name = "CountdownNumber"
    countdownNumber.Size = UDim2.new(0.3, 0, 0.3, 0)
    countdownNumber.Position = UDim2.new(0.35, 0, 0.35, 0)
    countdownNumber.BackgroundTransparency = 1
    countdownNumber.Text = "60"
    countdownNumber.TextScaled = true
    countdownNumber.Font = Enum.Font.GothamBold
    countdownNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdownNumber.Parent = frame
    
    -- "Movement Locked" text
    local lockedText = Instance.new("TextLabel")
    lockedText.Name = "LockedText"
    lockedText.Size = UDim2.new(0.6, 0, 0.08, 0)
    lockedText.Position = UDim2.new(0.2, 0, 0.67, 0)
    lockedText.BackgroundTransparency = 1
    lockedText.Text = "MOVEMENT LOCKED - AWAIT THE GONG"
    lockedText.TextScaled = true
    lockedText.Font = Enum.Font.GothamBold
    lockedText.TextColor3 = Color3.fromRGB(255, 100, 100)
    lockedText.Parent = frame
    
    return frame
end

-- Play local sound
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

-- Show elimination popup
function VictoryUI:showEliminationPopup(data)
    if not VictoryUI.eliminationFrame then return end
    
    -- Update labels
    local nameLabel = VictoryUI.eliminationFrame:FindFirstChild("PlayerName")
    local remainingLabel = VictoryUI.eliminationFrame:FindFirstChild("RemainingPlayers")
    
    if nameLabel then
        nameLabel.Text = data.playerName .. " has fallen"
    end
    
    if remainingLabel then
        remainingLabel.Text = "Tributes remaining: " .. data.remainingPlayers
    end
    
    -- Play cannon sound effect
    playSound(SOUND_IDS.CANNON, 1)
    
    -- Show with animation
    VictoryUI.eliminationFrame.Visible = true
    VictoryUI.eliminationFrame.Position = UDim2.new(0.3, 0, -0.2, 0)
    
    local showTween = TweenService:Create(VictoryUI.eliminationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.3, 0, 0.05, 0)
    })
    showTween:Play()
    
    -- Hide after delay
    task.delay(4, function()
        local hideTween = TweenService:Create(VictoryUI.eliminationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.3, 0, -0.2, 0)
        })
        hideTween:Play()
        hideTween.Completed:Connect(function()
            VictoryUI.eliminationFrame.Visible = false
        end)
    end)
end

-- Flash screen red for player's own elimination
function VictoryUI:flashRedScreen()
    local flashFrame = Instance.new("Frame")
    flashFrame.Name = "DeathFlash"
    flashFrame.Size = UDim2.new(1, 0, 1, 0)
    flashFrame.Position = UDim2.new(0, 0, 0, 0)
    flashFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    flashFrame.BackgroundTransparency = 0
    flashFrame.BorderSizePixel = 0
    flashFrame.ZIndex = 100
    flashFrame.Parent = VictoryUI.screenGui
    
    -- Fade out
    local fadeOut = TweenService:Create(flashFrame, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    })
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        flashFrame:Destroy()
    end)
end

-- Format time as MM:SS
local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

-- Show victory sequence
function VictoryUI:showVictorySequence(data)
    if not VictoryUI.victoryFrame then return end
    
    local isLocalPlayerWinner = data.winnerId == Player.UserId
    
    -- Update victory screen content
    local winnerName = VictoryUI.victoryFrame:FindFirstChild("WinnerName")
    local killsLabel = VictoryUI.victoryFrame:FindFirstChild("StatsFrame") and VictoryUI.victoryFrame.StatsFrame:FindFirstChild("KillsLabel")
    local durationLabel = VictoryUI.victoryFrame:FindFirstChild("StatsFrame") and VictoryUI.victoryFrame.StatsFrame:FindFirstChild("DurationLabel")
    local totalPlayersLabel = VictoryUI.victoryFrame:FindFirstChild("StatsFrame") and VictoryUI.victoryFrame.StatsFrame:FindFirstChild("TotalPlayersLabel")
    local victoryTitle = VictoryUI.victoryFrame:FindFirstChild("VictoryTitle")
    
    if winnerName then
        winnerName.Text = data.winner or "Unknown Victor"
    end
    
    if killsLabel then
        killsLabel.Text = "Eliminations: " .. (data.kills or 0)
    end
    
    if durationLabel then
        durationLabel.Text = "Match Time: " .. formatTime(data.matchDuration or 0)
    end
    
    if totalPlayersLabel then
        totalPlayersLabel.Text = "Total Tributes: " .. (data.totalPlayers or 24)
    end
    
    if victoryTitle then
        if isLocalPlayerWinner then
            victoryTitle.Text = "🏆 YOU ARE THE VICTOR! 🏆"
            victoryTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
        else
            victoryTitle.Text = "🏆 VICTORY 🏆"
            victoryTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
    
    -- Play victory sound
    playSound(SOUND_IDS.VICTORY_FANFARE, 1)
    
    -- Show with fade in
    VictoryUI.victoryFrame.BackgroundTransparency = 1
    VictoryUI.victoryFrame.Visible = true
    
    local fadeIn = TweenService:Create(VictoryUI.victoryFrame, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.2
    })
    fadeIn:Play()
    
    -- Fade in all children
    for _, child in pairs(VictoryUI.victoryFrame:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("Frame") then
            local originalTransparency = child.BackgroundTransparency
            if child:IsA("TextLabel") then
                child.TextTransparency = 1
                local textFade = TweenService:Create(child, TweenInfo.new(1, Enum.EasingStyle.Quad), {
                    TextTransparency = 0
                })
                textFade:Play()
            end
        end
    end
end

-- Create firework particle effect
function VictoryUI:createFireworkEffect(position)
    -- Create visual firework in world space
    playSound(SOUND_IDS.FIREWORK, 0.6)
    
    -- Create a simple part for the firework
    local firework = Instance.new("Part")
    firework.Name = "Firework"
    firework.Size = Vector3.new(1, 1, 1)
    firework.Position = position
    firework.Anchored = true
    firework.CanCollide = false
    firework.Transparency = 1
    firework.Parent = workspace
    
    -- Add particle effect
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 255))
    })
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(1, 0)
    })
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    particles.Lifetime = NumberRange.new(1, 2)
    particles.Speed = NumberRange.new(20, 40)
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Rate = 100
    particles.RotSpeed = NumberRange.new(-100, 100)
    particles.Parent = firework
    
    -- Burst particles then destroy
    task.delay(0.2, function()
        particles.Enabled = false
    end)
    
    Debris:AddItem(firework, 3)
end

-- Show countdown overlay
function VictoryUI:showCountdownOverlay(seconds)
    local overlay = VictoryUI.screenGui:FindFirstChild("CountdownOverlay")
    if not overlay then return end
    
    overlay.Visible = true
    
    local countdownNumber = overlay:FindFirstChild("CountdownNumber")
    if countdownNumber then
        countdownNumber.Text = tostring(seconds)
        
        -- Pulse animation for last 10 seconds
        if seconds <= 10 then
            playSound(SOUND_IDS.COUNTDOWN_BEEP, seconds <= 3 and 1.5 or 1)
            
            countdownNumber.TextColor3 = seconds <= 3 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 200, 100)
            
            -- Scale pulse
            local originalSize = countdownNumber.Size
            countdownNumber.Size = UDim2.new(0.4, 0, 0.4, 0)
            local shrink = TweenService:Create(countdownNumber, TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
                Size = originalSize
            })
            shrink:Play()
        end
    end
end

-- Hide countdown overlay
function VictoryUI:hideCountdownOverlay()
    local overlay = VictoryUI.screenGui:FindFirstChild("CountdownOverlay")
    if overlay then
        overlay.Visible = false
    end
end

-- Enter spectator mode UI
function VictoryUI:showSpectatorUI(data)
    -- Create spectator UI overlay
    local spectatorFrame = Instance.new("Frame")
    spectatorFrame.Name = "SpectatorUI"
    spectatorFrame.Size = UDim2.new(0.3, 0, 0.08, 0)
    spectatorFrame.Position = UDim2.new(0.35, 0, 0.02, 0)
    spectatorFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    spectatorFrame.BackgroundTransparency = 0.3
    spectatorFrame.BorderSizePixel = 0
    spectatorFrame.Parent = VictoryUI.screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = spectatorFrame
    
    local spectatorText = Instance.new("TextLabel")
    spectatorText.Size = UDim2.new(1, 0, 0.5, 0)
    spectatorText.Position = UDim2.new(0, 0, 0.1, 0)
    spectatorText.BackgroundTransparency = 1
    spectatorText.Text = "📸 SPECTATOR MODE"
    spectatorText.TextScaled = true
    spectatorText.Font = Enum.Font.GothamBold
    spectatorText.TextColor3 = Color3.fromRGB(255, 255, 255)
    spectatorText.Parent = spectatorFrame
    
    local placementText = Instance.new("TextLabel")
    placementText.Size = UDim2.new(1, 0, 0.35, 0)
    placementText.Position = UDim2.new(0, 0, 0.55, 0)
    placementText.BackgroundTransparency = 1
    placementText.Text = "Placement: #" .. (data.placement or "?") .. " | Kills: " .. (data.kills or 0)
    placementText.TextScaled = true
    placementText.Font = Enum.Font.Gotham
    placementText.TextColor3 = Color3.fromRGB(200, 200, 200)
    placementText.Parent = spectatorFrame
    
    -- Flash red screen for elimination
    VictoryUI:flashRedScreen()
end

-- Initialize VictoryUI
function VictoryUI.init()
    print("[VictoryUI] Initializing...")
    
    -- Create screen GUI and components
    VictoryUI.screenGui = createScreenGui()
    VictoryUI.eliminationFrame = createEliminationPopup()
    VictoryUI.victoryFrame = createVictoryScreen()
    createCountdownOverlay()
    
    -- Connect to match events
    if MatchRemoteEvent then
        MatchRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "PLAYER_ELIMINATED" then
                local data = args[1]
                VictoryUI:showEliminationPopup(data)
                
            elseif eventType == "CANNON_FIRED" then
                -- Just play cannon sound (server already handles the main sound)
                -- This is for additional client-side effects if needed
                
            elseif eventType == "VICTORY_SEQUENCE" then
                local data = args[1]
                VictoryUI:showVictorySequence(data)
                
            elseif eventType == "FIREWORK_EFFECT" then
                local position = args[1]
                VictoryUI:createFireworkEffect(position)
                
            elseif eventType == "ENTER_SPECTATOR_MODE" then
                local data = args[1]
                VictoryUI:showSpectatorUI(data)
                
            elseif eventType == "COUNTDOWN_BEEP" then
                local secondsRemaining = args[1]
                VictoryUI:showCountdownOverlay(secondsRemaining)
                
            elseif eventType == "MATCH_START_HORN" then
                VictoryUI:hideCountdownOverlay()
                
            elseif eventType == "RETURN_TO_LOBBY" then
                -- Clean up victory UI
                if VictoryUI.victoryFrame then
                    VictoryUI.victoryFrame.Visible = false
                end
                
                -- Clean up spectator UI
                local spectatorUI = VictoryUI.screenGui:FindFirstChild("SpectatorUI")
                if spectatorUI then
                    spectatorUI:Destroy()
                end
            end
        end)
    else
        warn("[VictoryUI] MatchRemoteEvent not found - victory UI won't work")
    end
    
    print("[VictoryUI] Initialized successfully")
end

-- Initialize when module loads
VictoryUI.init()

return VictoryUI
