-- LocalScript: SpectatorMode.lua
-- Spectator mode for eliminated players in The Ember Games
-- Allows eliminated players to observe remaining tributes and the continuing match

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local StatsRemoteEvent = ReplicatedStorage:WaitForChild("StatsRemoteEvent", 10)
local ArenaRemoteEvent = ReplicatedStorage:WaitForChild("ArenaRemoteEvent", 10)

local SpectatorMode = {}
SpectatorMode.isActive = false
SpectatorMode.spectatorGui = nil
SpectatorMode.currentTarget = nil
SpectatorMode.playerList = {}
SpectatorMode.eliminated = false

-- Create spectator UI
local function createSpectatorUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SpectatorInterface"
    screenGui.Parent = PlayerGui
    
    -- Spectator Frame
    local spectatorFrame = Instance.new("Frame")
    spectatorFrame.Name = "SpectatorFrame"
    spectatorFrame.Size = UDim2.new(0, 350, 0, 500)
    spectatorFrame.Position = UDim2.new(0, 20, 0.5, -250)
    spectatorFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    spectatorFrame.BackgroundTransparency = 0.5
    spectatorFrame.BorderSizePixel = 0
    spectatorFrame.Visible = false
    spectatorFrame.Parent = screenGui
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "SPECTATOR MODE"
    titleLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    titleLabel.Parent = spectatorFrame
    
    -- Instructions
    local instructionsLabel = Instance.new("TextLabel")
    instructionsLabel.Name = "InstructionsLabel"
    instructionsLabel.Size = UDim2.new(1, -20, 0, 80)
    instructionsLabel.Position = UDim2.new(0, 10, 0, 50)
    instructionsLabel.BackgroundTransparency = 1
    instructionsLabel.Text = "Use arrow keys to follow tributes\nPress 'R' to return to lobby\nPress 'ESC' to toggle UI"
    instructionsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    instructionsLabel.Font = Enum.Font.Gotham
    instructionsLabel.TextScaled = true
    instructionsLabel.TextWrapped = true
    instructionsLabel.Parent = spectatorFrame
    
    -- Player List Frame
    local playerListFrame = Instance.new("ScrollingFrame")
    playerListFrame.Name = "PlayerListFrame"
    playerListFrame.Size = UDim2.new(1, -20, 1, -160)
    playerListFrame.Position = UDim2.new(0, 10, 0, 140)
    playerListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    playerListFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    playerListFrame.ScrollBarThickness = 8
    playerListFrame.Parent = spectatorFrame
    
    -- Active Tribute Counter
    local tributeCounter = Instance.new("TextLabel")
    tributeCounter.Name = "TributeCounter"
    tributeCounter.Size = UDim2.new(1, -20, 0, 30)
    tributeCounter.Position = UDim2.new(0, 10, 1, -40)
    tributeCounter.BackgroundTransparency = 1
    tributeCounter.Text = "Active Tributes: 0"
    tributeCounter.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    tributeCounter.Font = Enum.Font.GothamBold
    tributeCounter.TextScaled = true
    tributeCounter.Parent = spectatorFrame
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 30)
    closeButton.Position = UDim2.new(1, -50, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    closeButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextScaled = true
    closeButton.Parent = spectatorFrame
    
    -- Store references
    SpectatorMode.spectatorGui = screenGui
    
    return screenGui
end

-- Enable spectator mode
function SpectatorMode:enable()
    if SpectatorMode.isActive then return end
    
    SpectatorMode.isActive = true
    SpectatorMode.eliminated = true
    
    print(Player.Name .. " is now spectating")
    
    -- Show UI
    if SpectatorMode.spectatorGui then
        SpectatorMode.spectatorGui.SpectatorFrame.Visible = true
    end
    
    -- Set camera to spectator mode
    Camera.CameraType = Enum.CameraType.Track
    
    -- Update player list
    SpectatorMode:updatePlayerList()
end

-- Disable spectator mode
function SpectatorMode:disable()
    if not SpectatorMode.isActive then return end
    
    SpectatorMode.isActive = false
    
    -- Hide UI
    if SpectatorMode.spectatorGui then
        SpectatorMode.spectatorGui.SpectatorFrame.Visible = false
    end
    
    -- Reset camera
    Camera.CameraType = Enum.CameraType.Custom
    
    print(Player.Name .. " has left spectator mode")
end

-- Update player list UI
function SpectatorMode:updatePlayerList()
    if not SpectatorMode.spectatorGui then return end
    
    local playerListFrame = SpectatorMode.spectatorGui.SpectatorFrame.PlayerListFrame
    
    -- Clear existing list
    for _, child in pairs(playerListFrame:GetChildren()) do
        if child.Name:sub(1, 6) == "Player" then
            child:Destroy()
        end
    end
    
    -- Update each player in the list
    local yPosition = 0
    for userId, playerData in pairs(SpectatorMode.playerList) do
        local player = Players:GetPlayerByUserId(userId)
        if player and player.Parent then  -- Only if player is still in the game
            local playerFrame = Instance.new("TextButton")
            playerFrame.Name = "Player" .. userId
            playerFrame.Size = UDim2.new(1, -10, 0, 40)
            playerFrame.Position = UDim2.new(0, 5, 0, yPosition)
            playerFrame.BackgroundColor3 = (SpectatorMode.currentTarget and SpectatorMode.currentTarget.UserId == userId) 
                and Color3.fromRGB(100, 50, 50) or Color3.fromRGB(50, 50, 50)
            playerFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
            playerFrame.Text = player.Name .. " (D" .. (playerData.district or "??") .. ")"
            playerFrame.TextColor3 = playerData.eliminated and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 255, 255)
            playerFrame.Font = Enum.Font.Gotham
            playerFrame.TextScaled = true
            playerFrame.Parent = playerListFrame
            
            -- Connect to follow player
            playerFrame.MouseButton1Click:Connect(function()
                SpectatorMode:followPlayer(player)
            end)
            
            yPosition = yPosition + 45
        end
    end
    
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    
    -- Update tribute counter
    local activeTributes = 0
    for userId, playerData in pairs(SpectatorMode.playerList) do
        local player = Players:GetPlayerByUserId(userId)
        if player and player.Parent and not playerData.eliminated then
            activeTributes = activeTributes + 1
        end
    end
    
    local tributeCounter = SpectatorMode.spectatorGui.SpectatorFrame:FindFirstChild("TributeCounter")
    if tributeCounter then
        tributeCounter.Text = "Active Tributes: " .. activeTributes
    end
end

-- Follow a specific player
function SpectatorMode:followPlayer(player)
    if not player or not player.Character then
        print("Cannot follow player - no character found")
        return
    end
    
    SpectatorMode.currentTarget = player
    Camera.CameraSubject = player.Character
    
    print("Now following: " .. player.Name)
    
    -- Update UI to show selected player
    SpectatorMode:updatePlayerList()
end

-- Cycle through players
function SpectatorMode:cyclePlayer(direction)
    local activePlayers = {}
    
    for userId, playerData in pairs(SpectatorMode.playerList) do
        local player = Players:GetPlayerByUserId(userId)
        if player and player.Parent and not playerData.eliminated then
            table.insert(activePlayers, player)
        end
    end
    
    if #activePlayers == 0 then return end
    
    -- Find current index
    local currentIndex = 0
    if SpectatorMode.currentTarget then
        for i, player in ipairs(activePlayers) do
            if player == SpectatorMode.currentTarget then
                currentIndex = i
                break
            end
        end
    end
    
    -- Calculate new index
    local newIndex
    if direction == "next" then
        newIndex = (currentIndex % #activePlayers) + 1
    else -- previous
        newIndex = ((currentIndex - 2 + #activePlayers) % #activePlayers) + 1
    end
    
    if activePlayers[newIndex] then
        SpectatorMode:followPlayer(activePlayers[newIndex])
    end
end

-- Initialize SpectatorMode
function SpectatorMode:init()
    print("SpectatorMode initialized")
    
    -- Create UI
    createSpectatorUI()
    
    -- Connect close button
    if SpectatorMode.spectatorGui then
        local closeButton = SpectatorMode.spectatorGui.SpectatorFrame.CloseButton
        closeButton.MouseButton1Click:Connect(function()
            SpectatorMode:disable()
        end)
    end
    
    -- Setup keyboard input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if SpectatorMode.isActive then
            -- Arrow keys to cycle players
            if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Right then
                SpectatorMode:cyclePlayer("next")
            elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.Left then
                SpectatorMode:cyclePlayer("prev")
            elseif input.KeyCode == Enum.KeyCode.R then
                -- Return to lobby (would require server logic in full implementation)
                print("Returning to lobby...")
                -- In a real game, this would send the player back to lobby
            elseif input.KeyCode == Enum.KeyCode.Escape then
                -- Toggle UI visibility
                local frame = SpectatorMode.spectatorGui.SpectatorFrame
                frame.Visible = not frame.Visible
            end
        end
    end)
    
    -- Connect to player events
    local function onPlayerAdded(player)
        SpectatorMode.playerList[player.UserId] = {
            district = 0,
            eliminated = false
        }
        SpectatorMode:updatePlayerList()
    end
    
    local function onPlayerRemoved(player)
        if SpectatorMode.playerList[player.UserId] then
            SpectatorMode.playerList[player.UserId] = nil
            if SpectatorMode.currentTarget == player then
                SpectatorMode.currentTarget = nil
            end
            SpectatorMode:updatePlayerList()
        end
    end
    
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoved)
    
    -- Add existing players
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    
    -- Connect to other game events (if RemoteEvents exist)
    if StatsRemoteEvent then
        StatsRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "PLAYER_ELIMINATED" then
                local eliminatedUserId, eliminatedName = args[1], args[2]
                
                if eliminatedUserId == Player.UserId then
                    -- This player was eliminated
                    task.wait(1) -- Wait a moment for the elimination to process
                    SpectatorMode:enable()
                else
                    -- Another player was eliminated
                    if SpectatorMode.playerList[eliminatedUserId] then
                        SpectatorMode.playerList[eliminatedUserId].eliminated = true
                        SpectatorMode:updatePlayerList()
                        
                        if SpectatorMode.currentTarget and SpectatorMode.currentTarget.UserId == eliminatedUserId then
                            SpectatorMode.currentTarget = nil
                            -- Automatically follow another player
                            SpectatorMode:cyclePlayer("next")
                        end
                    end
                    
                    print(eliminatedName .. " has been eliminated. Remaining: TBD")
                end
            end
        end)
    else
        warn("[SpectatorMode] StatsRemoteEvent not found - elimination detection may not work")
    end
    
    if ArenaRemoteEvent then
        ArenaRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            -- Handle arena events if needed
        end)
    end
    
    print("SpectatorMode initialized and connected to events")
end

-- Initialize the SpectatorMode when the module is loaded
SpectatorMode:init()

return SpectatorMode