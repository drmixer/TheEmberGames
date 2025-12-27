-- LocalScript: StarterGui.lua
-- Main GUI system for The Ember Games
-- Handles lobby interface, tribute selection, and main game screens

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local LobbyRemoteEvent = ReplicatedStorage:WaitForChild("LobbyRemoteEvent", 10)
local ArenaRemoteEvent = ReplicatedStorage:WaitForChild("ArenaRemoteEvent", 10)

local StarterGui = {}

-- UI Elements
StarterGui.mainScreenGui = nil
StarterGui.lobbyFrame = nil
StarterGui.tributeDisplay = nil
StarterGui.countdownFrame = nil
StarterGui.gameHud = nil

-- Player data
StarterGui.playerDistrict = nil
StarterGui.playerTributeId = nil
StarterGui.gameState = "Lobby" -- Lobby, Countdown, InGame, Spectator

-- Create the main UI structure
local function createMainUI()
    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EmberGamesMainMenu"
    screenGui.Parent = PlayerGui
    
    -- Lobby Frame
    local lobbyFrame = Instance.new("Frame")
    lobbyFrame.Name = "LobbyFrame"
    lobbyFrame.Size = UDim2.new(0, 500, 0, 400)
    lobbyFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    lobbyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    lobbyFrame.BorderSizePixel = 0
    lobbyFrame.Parent = screenGui
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 60)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "THE EMBER GAMES"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    titleLabel.Parent = lobbyFrame
    
    -- Tribute Assignment Section
    local tributeSection = Instance.new("Frame")
    tributeSection.Name = "TributeSection"
    tributeSection.Size = UDim2.new(1, -20, 0, 80)
    tributeSection.Position = UDim2.new(0, 10, 0, 80)
    tributeSection.BackgroundTransparency = 1
    tributeSection.Parent = lobbyFrame
    
    local districtLabel = Instance.new("TextLabel")
    districtLabel.Name = "DistrictLabel"
    districtLabel.Size = UDim2.new(1, 0, 0, 30)
    districtLabel.Position = UDim2.new(0, 0, 0, 0)
    districtLabel.BackgroundTransparency = 1
    districtLabel.Text = "District Assignment: Waiting..."
    districtLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    districtLabel.Font = Enum.Font.Gotham
    districtLabel.TextScaled = true
    districtLabel.Parent = tributeSection
    
    local tributeStatusLabel = Instance.new("TextLabel") 
    tributeStatusLabel.Name = "TributeStatusLabel"
    tributeStatusLabel.Size = UDim2.new(1, 0, 0, 30)
    tributeStatusLabel.Position = UDim2.new(0, 0, 0, 40)
    tributeStatusLabel.BackgroundTransparency = 1
    tributeStatusLabel.Text = "Tribute Status: Pending Assignment"
    tributeStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    tributeStatusLabel.Font = Enum.Font.Gotham
    tributeStatusLabel.TextScaled = true
    tributeStatusLabel.Parent = tributeSection
    
    -- Player count display
    local playerCountFrame = Instance.new("Frame")
    playerCountFrame.Name = "PlayerCountFrame"
    playerCountFrame.Size = UDim2.new(1, -20, 0, 40)
    playerCountFrame.Position = UDim2.new(0, 10, 0, 170)
    playerCountFrame.BackgroundTransparency = 1
    playerCountFrame.Parent = lobbyFrame
    
    local playerCountLabel = Instance.new("TextLabel")
    playerCountLabel.Name = "PlayerCountLabel"
    playerCountLabel.Size = UDim2.new(1, 0, 1, 0)
    playerCountLabel.BackgroundTransparency = 1
    playerCountLabel.Text = "Tributes Ready: 0/12 Minimum"
    playerCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerCountLabel.Font = Enum.Font.Gotham
    playerCountLabel.TextScaled = true
    playerCountLabel.Parent = playerCountFrame
    
    -- Countdown Frame (initially hidden)
    local countdownFrame = Instance.new("Frame")
    countdownFrame.Name = "CountdownFrame"
    countdownFrame.Size = UDim2.new(0, 400, 0, 300)
    countdownFrame.Position = UDim2.new(0.5, -200, 0.3, -150)
    countdownFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    countdownFrame.BackgroundTransparency = 0.3
    countdownFrame.BorderSizePixel = 0
    countdownFrame.Visible = false
    countdownFrame.Parent = screenGui
    
    local countdownTitle = Instance.new("TextLabel")
    countdownTitle.Name = "CountdownTitle"
    countdownTitle.Size = UDim2.new(1, 0, 0, 50)
    countdownTitle.Position = UDim2.new(0, 0, 0, 20)
    countdownTitle.BackgroundTransparency = 1
    countdownTitle.Text = "THE GAMES BEGIN"
    countdownTitle.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    countdownTitle.Font = Enum.Font.GothamBold
    countdownTitle.TextScaled = true
    countdownTitle.Parent = countdownFrame
    
    local countdownNumber = Instance.new("TextLabel")
    countdownNumber.Name = "CountdownNumber"
    countdownNumber.Size = UDim2.new(1, 0, 0, 100)
    countdownNumber.Position = UDim2.new(0, 0, 0, 100)
    countdownNumber.BackgroundTransparency = 1
    countdownNumber.Text = "60"
    countdownNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdownNumber.Font = Enum.Font.GothamBold
    countdownNumber.TextScaled = true
    countdownNumber.Parent = countdownFrame
    
    local countdownSubtitle = Instance.new("TextLabel")
    countdownSubtitle.Name = "CountdownSubtitle"
    countdownSubtitle.Size = UDim2.new(1, 0, 0, 40)
    countdownSubtitle.Position = UDim2.new(0, 0, 0, 220)
    countdownSubtitle.BackgroundTransparency = 1
    countdownSubtitle.Text = "Prepare for Tribute Assignment"
    countdownSubtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    countdownSubtitle.Font = Enum.Font.Gotham
    countdownSubtitle.TextScaled = true
    countdownSubtitle.Parent = countdownFrame
    
    -- Tribute Display (for arena entry)
    local tributeDisplayFrame = Instance.new("Frame")
    tributeDisplayFrame.Name = "TributeDisplayFrame"
    tributeDisplayFrame.Size = UDim2.new(0, 600, 0, 200)
    tributeDisplayFrame.Position = UDim2.new(0.5, -300, 0, 50)
    tributeDisplayFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    tributeDisplayFrame.BackgroundTransparency = 0.5
    tributeDisplayFrame.BorderSizePixel = 0
    tributeDisplayFrame.Visible = false
    tributeDisplayFrame.Parent = screenGui
    
    local tributeTitle = Instance.new("TextLabel")
    tributeTitle.Name = "TributeTitle"
    tributeTitle.Size = UDim2.new(1, 0, 0, 50)
    tributeTitle.Position = UDim2.new(0, 0, 0, 20)
    tributeTitle.BackgroundTransparency = 1
    tributeTitle.Text = "TRIBUTE " .. (StarterGui.playerDistrict or "??") .. " - " .. Player.Name
    tributeTitle.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    tributeTitle.Font = Enum.Font.GothamBold
    tributeTitle.TextScaled = true
    tributeTitle.Parent = tributeDisplayFrame
    
    local tributeMessage = Instance.new("TextLabel")
    tributeMessage.Name = "TributeMessage"
    tributeMessage.Size = UDim2.new(1, 0, 0, 60)
    tributeMessage.Position = UDim2.new(0, 0, 0, 90)
    tributeMessage.BackgroundTransparency = 1
    tributeMessage.Text = "You are about to enter the arena.\nYour survival depends on your wits."
    tributeMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
    tributeMessage.Font = Enum.Font.Gotham
    tributeMessage.TextScaled = true
    tributeMessage.TextWrapped = true
    tributeMessage.Parent = tributeDisplayFrame
    
    -- Store references
    StarterGui.mainScreenGui = screenGui
    StarterGui.lobbyFrame = lobbyFrame
    StarterGui.countdownFrame = countdownFrame
    StarterGui.tributeDisplay = tributeDisplayFrame
    
    return screenGui
end

-- Update lobby UI based on game state
local function updateLobbyUI(status)
    if not StarterGui.lobbyFrame then return end
    
    -- Update player count display
    local playerCountLabel = StarterGui.lobbyFrame:FindFirstChild("PlayerCountFrame"):FindFirstChild("PlayerCountLabel")
    if playerCountLabel then
        playerCountLabel.Text = string.format("Tributes Ready: %d/%d", status.playerCount or 0, status.minPlayers or 12)
    end
    
    -- Update game state UI
    StarterGui.gameState = status.gameState or "Lobby"
    
    if StarterGui.gameState == "Lobby" then
        StarterGui.lobbyFrame.Visible = true
        StarterGui.countdownFrame.Visible = false
        StarterGui.tributeDisplay.Visible = false
    elseif StarterGui.gameState == "Countdown" then
        StarterGui.lobbyFrame.Visible = false
        StarterGui.countdownFrame.Visible = true
        StarterGui.tributeDisplay.Visible = false
    elseif StarterGui.gameState == "ArenaEntry" then
        StarterGui.lobbyFrame.Visible = false
        StarterGui.countdownFrame.Visible = false
        StarterGui.tributeDisplay.Visible = true
    end
end

-- Handle district assignment
local function assignDistrict(districtNumber)
    StarterGui.playerDistrict = districtNumber
    
    if StarterGui.lobbyFrame then
        local districtLabel = StarterGui.lobbyFrame:FindFirstChild("TributeSection"):FindFirstChild("DistrictLabel")
        if districtLabel then
            districtLabel.Text = "District Assignment: " .. districtNumber
        end
        
        local tributeStatusLabel = StarterGui.lobbyFrame:FindFirstChild("TributeSection"):FindFirstChild("TributeStatusLabel")
        if tributeStatusLabel then
            tributeStatusLabel.Text = "Tribute Status: Assigned to District " .. districtNumber
        end
    end
    
    if StarterGui.tributeDisplay then
        local tributeTitle = StarterGui.tributeDisplay:FindFirstChild("TributeTitle")
        if tributeTitle then
            tributeTitle.Text = "TRIBUTE " .. districtNumber .. " - " .. Player.Name
        end
    end
end

-- Initialize StarterGui
function StarterGui.init()
    print("StarterGui initialized")
    
    -- Create the main UI
    createMainUI()
    
    -- Hide by default (MainMenuUI is the main menu now)
    if StarterGui.mainScreenGui then
        StarterGui.mainScreenGui.Enabled = false
    end
    
    -- Connect to lobby events (if RemoteEvent exists)
    if LobbyRemoteEvent then
        LobbyRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "ASSIGN_DISTRICT" then
                local districtNumber = args[1]
                assignDistrict(districtNumber)
            elseif eventType == "COUNTDOWN_START" then
                -- Countdown is starting
                StarterGui.gameState = "Countdown"
                if StarterGui.countdownFrame then
                    StarterGui.countdownFrame.Visible = true
                    StarterGui.lobbyFrame.Visible = false
                    StarterGui.tributeDisplay.Visible = false
                end
            elseif eventType == "COUNTDOWN_UPDATE" then
                local timeLeft = args[1]
                if StarterGui.countdownFrame then
                    local countdownNumber = StarterGui.countdownFrame:FindFirstChild("CountdownNumber")
                    if countdownNumber then
                        countdownNumber.Text = tostring(math.ceil(timeLeft))
                        
                        -- Add dramatic effect as time gets low
                        if timeLeft <= 10 then
                            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            local tween = TweenService:Create(countdownNumber, tweenInfo, {
                                TextColor3 = Color3.fromRGB(255, 50, 50) -- Red
                            })
                            tween:Play()
                            countdownNumber.Font = Enum.Font.GothamBlack -- Set directly, don't tween
                        end
                    end
                end
            elseif eventType == "COUNTDOWN_CANCELLED" then
                StarterGui.gameState = "Lobby"
                if StarterGui.lobbyFrame then
                    StarterGui.lobbyFrame.Visible = true
                    StarterGui.countdownFrame.Visible = false
                end
            elseif eventType == "MATCH_STARTING" then
                StarterGui.gameState = "ArenaEntry"
                if StarterGui.tributeDisplay then
                    StarterGui.tributeDisplay.Visible = true
                    StarterGui.countdownFrame.Visible = false
                end
            elseif eventType == "LOBBY_STATUS" then
                local status = args[1]
                updateLobbyUI(status)
            end
        end)
    else
        warn("[StarterGui] LobbyRemoteEvent not found - lobby UI may not work")
    end
    
    -- Connect to arena events (if RemoteEvent exists)
    if ArenaRemoteEvent then
        ArenaRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            if eventType == "ARENA_INITIALIZED" then
                print("Arena initialized - game starting!")
                -- Hide all lobby UI, show game UI
                if StarterGui.mainScreenGui then
                    StarterGui.mainScreenGui.Enabled = false
                end
            end
        end)
    else
        warn("[StarterGui] ArenaRemoteEvent not found - arena events may not work")
    end
    
    print("StarterGui initialized and connected to events")
end

-- Initialize the StarterGui when the module is loaded
StarterGui.init()

return StarterGui