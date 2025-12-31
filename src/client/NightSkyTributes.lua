-- LocalScript: NightSkyTributes.lua
-- Shows fallen tribute faces in the night sky
-- Displays eliminated players with their district numbers during "night" sequences

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for remote events
local MatchRemoteEvent = ReplicatedStorage:WaitForChild("MatchRemoteEvent", 10)

local NightSkyTributes = {}
NightSkyTributes.screenGui = nil
NightSkyTributes.fallenTributes = {}
NightSkyTributes.displayActive = false

-- Configuration
local CONFIG = {
    TRIBUTE_DISPLAY_TIME = 5, -- Seconds per tribute
    FADE_TIME = 1.5,
    TRIBUTE_SIZE = UDim2.new(0, 200, 0, 200),
    PROJECTION_HEIGHT = 0.15, -- Position from top of screen
}

-- Sound IDs (VERIFIED Roblox audio assets)
local SOUND_IDS = {
    ANTHEM = "rbxassetid://1845237632", -- Gloriana (Menu Music)
    CANNON = "rbxassetid://138081509", -- Distant Explosion with Echo
}

-- Create screen GUI
local function createScreenGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NightSkyTributesUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    return screenGui
end

-- Play sound
local function playSound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.8
    sound.Parent = PlayerGui
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    return sound
end

-- Create dark overlay for night effect
local function createNightOverlay()
    local overlay = Instance.new("Frame")
    overlay.Name = "NightOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 1
    overlay.Parent = NightSkyTributes.screenGui
    
    return overlay
end

-- Create tribute portrait frame
local function createTributeFrame()
    local container = Instance.new("Frame")
    container.Name = "TributeContainer"
    container.Size = UDim2.new(0.4, 0, 0.7, 0)
    container.Position = UDim2.new(0.3, 0, 0.05, 0)
    container.BackgroundTransparency = 1
    container.ZIndex = 10
    container.Parent = NightSkyTributes.screenGui
    
    -- Title - "THE FALLEN"
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "THE FALLEN"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextStrokeTransparency = 0
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    titleLabel.ZIndex = 11
    titleLabel.Parent = container
    
    -- Portrait frame
    local portraitFrame = Instance.new("Frame")
    portraitFrame.Name = "PortraitFrame"
    portraitFrame.Size = UDim2.new(0.5, 0, 0.55, 0)
    portraitFrame.Position = UDim2.new(0.25, 0, 0.15, 0)
    portraitFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    portraitFrame.BorderSizePixel = 0
    portraitFrame.ZIndex = 11
    portraitFrame.Parent = container
    
    -- Portrait corner
    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 10)
    pCorner.Parent = portraitFrame
    
    -- Golden border
    local pStroke = Instance.new("UIStroke")
    pStroke.Color = Color3.fromRGB(212, 175, 55)
    pStroke.Thickness = 4
    pStroke.Parent = portraitFrame
    
    -- Player avatar image
    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Name = "AvatarImage"
    avatarImage.Size = UDim2.new(0.9, 0, 0.9, 0)
    avatarImage.Position = UDim2.new(0.05, 0, 0.05, 0)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = ""
    avatarImage.ScaleType = Enum.ScaleType.Fit
    avatarImage.ZIndex = 12
    avatarImage.Parent = portraitFrame
    
    -- Avatar corner
    local aCorner = Instance.new("UICorner")
    aCorner.CornerRadius = UDim.new(0, 8)
    aCorner.Parent = avatarImage
    
    -- Player name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.08, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.72, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = ""
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.ZIndex = 11
    nameLabel.Parent = container
    
    -- District label
    local districtLabel = Instance.new("TextLabel")
    districtLabel.Name = "DistrictLabel"
    districtLabel.Size = UDim2.new(1, 0, 0.06, 0)
    districtLabel.Position = UDim2.new(0, 0, 0.81, 0)
    districtLabel.BackgroundTransparency = 1
    districtLabel.Text = ""
    districtLabel.TextColor3 = Color3.fromRGB(212, 175, 55)
    districtLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    districtLabel.TextStrokeTransparency = 0.3
    districtLabel.Font = Enum.Font.Gotham
    districtLabel.TextScaled = true
    districtLabel.ZIndex = 11
    districtLabel.Parent = container
    
    -- Placement/elimination info
    local placementLabel = Instance.new("TextLabel")
    placementLabel.Name = "PlacementLabel"
    placementLabel.Size = UDim2.new(1, 0, 0.05, 0)
    placementLabel.Position = UDim2.new(0, 0, 0.88, 0)
    placementLabel.BackgroundTransparency = 1
    placementLabel.Text = ""
    placementLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    placementLabel.Font = Enum.Font.Gotham
    placementLabel.TextScaled = true
    placementLabel.ZIndex = 11
    placementLabel.Parent = container
    
    return container
end

-- Get player avatar headshot URL
local function getAvatarUrl(userId)
    -- Handle Bots (UserId <= 0)
    if not userId or userId <= 0 then
        return "rbxassetid://10070559186" -- Clean Silhouette Icon
    end

    local success, result = pcall(function()
        return Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)
    
    if success then
        return result
    else
        return ""
    end
end

-- Display a single tribute
local function displayTribute(tributeData, tributeFrame)
    task.wait(1) -- Delay for pacing and audio sync
    local avatarImage = tributeFrame:FindFirstChild("PortraitFrame"):FindFirstChild("AvatarImage")
    local nameLabel = tributeFrame:FindFirstChild("NameLabel")
    local districtLabel = tributeFrame:FindFirstChild("DistrictLabel")
    local placementLabel = tributeFrame:FindFirstChild("PlacementLabel")
    
    -- Set data
    local avatarUrl = getAvatarUrl(tributeData.userId)
    if avatarImage then
        avatarImage.Image = avatarUrl
    end
    
    if nameLabel then
        nameLabel.Text = tributeData.name or "Unknown Tribute"
    end
    
    if districtLabel then
        districtLabel.Text = "District " .. tostring(tributeData.district or "?")
    end
    
    if placementLabel then
        local placement = tributeData.placement or "?"
        local suffix = "th"
        if placement == 1 then suffix = "st"
        elseif placement == 2 then suffix = "nd"
        elseif placement == 3 then suffix = "rd"
        end
        placementLabel.Text = "Placed " .. placement .. suffix
    end
    
    -- Fade in
    tributeFrame.Visible = true
    for _, child in pairs(tributeFrame:GetDescendants()) do
        if child:IsA("TextLabel") then
            child.TextTransparency = 1
        elseif child:IsA("ImageLabel") then
            child.ImageTransparency = 1
        elseif child:IsA("Frame") then
            child.BackgroundTransparency = 1
        end
    end
    
    -- Play cannon sound
    playSound(SOUND_IDS.CANNON, 0.7)
    
    -- Animate in
    local fadeInInfo = TweenInfo.new(CONFIG.FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    for _, child in pairs(tributeFrame:GetDescendants()) do
        if child:IsA("TextLabel") then
            TweenService:Create(child, fadeInInfo, {TextTransparency = 0}):Play()
        elseif child:IsA("ImageLabel") then
            TweenService:Create(child, fadeInInfo, {ImageTransparency = 0}):Play()
        elseif child:IsA("Frame") and child.Name == "PortraitFrame" then
            TweenService:Create(child, fadeInInfo, {BackgroundTransparency = 0}):Play()
        end
    end
end

-- Fade out tribute display
local function fadeOutTribute(tributeFrame)
    local fadeOutInfo = TweenInfo.new(CONFIG.FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    
    for _, child in pairs(tributeFrame:GetDescendants()) do
        if child:IsA("TextLabel") then
            TweenService:Create(child, fadeOutInfo, {TextTransparency = 1}):Play()
        elseif child:IsA("ImageLabel") then
            TweenService:Create(child, fadeOutInfo, {ImageTransparency = 1}):Play()
        elseif child:IsA("Frame") and child.Name == "PortraitFrame" then
            TweenService:Create(child, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        end
    end
    
    task.delay(CONFIG.FADE_TIME, function()
        tributeFrame.Visible = false
    end)
end

-- Start the night sky tribute sequence
function NightSkyTributes:startTributeSequence(tributes)
    if NightSkyTributes.displayActive then return end
    if not tributes or #tributes == 0 then return end
    
    print("[NightSkyTributes] Starting tribute sequence for " .. #tributes .. " fallen tributes")
    
    NightSkyTributes.displayActive = true
    
    -- Create night overlay
    local nightOverlay = createNightOverlay()
    
    -- Fade to night
    TweenService:Create(nightOverlay, TweenInfo.new(2), {
        BackgroundTransparency = 0.7
    }):Play()
    
    -- Darken lighting
    local originalBrightness = Lighting.Brightness
    local originalAmbient = Lighting.Ambient
    TweenService:Create(Lighting, TweenInfo.new(2), {
        Brightness = 0.3,
        Ambient = Color3.fromRGB(30, 40, 60)
    }):Play()
    
    task.wait(2.5)
    
    -- Play anthem music
    local anthemSound = playSound(SOUND_IDS.ANTHEM, 0.4)
    
    -- Create tribute display frame
    local tributeFrame = createTributeFrame()
    
    -- Display each tribute
    for i, tribute in ipairs(tributes) do
        displayTribute(tribute, tributeFrame)
        task.wait(CONFIG.TRIBUTE_DISPLAY_TIME)
        
        if i < #tributes then
            fadeOutTribute(tributeFrame)
            task.wait(CONFIG.FADE_TIME + 0.5)
        end
    end
    
    -- Final fade out
    fadeOutTribute(tributeFrame)
    task.wait(CONFIG.FADE_TIME)
    
    -- Fade back to day
    TweenService:Create(nightOverlay, TweenInfo.new(2), {
        BackgroundTransparency = 1
    }):Play()
    
    TweenService:Create(Lighting, TweenInfo.new(2), {
        Brightness = originalBrightness,
        Ambient = originalAmbient
    }):Play()
    
    task.wait(2)
    
    -- Cleanup
    if anthemSound then
        anthemSound:Stop()
    end
    nightOverlay:Destroy()
    tributeFrame:Destroy()
    
    NightSkyTributes.displayActive = false
    
    print("[NightSkyTributes] Tribute sequence complete")
end

-- Add a fallen tribute to the list
function NightSkyTributes:addFallenTribute(tributeData)
    table.insert(NightSkyTributes.fallenTributes, tributeData)
    print("[NightSkyTributes] Added fallen tribute: " .. (tributeData.name or "Unknown"))
end

-- Clear fallen tributes list
function NightSkyTributes:clearFallenTributes()
    NightSkyTributes.fallenTributes = {}
end

-- Initialize
function NightSkyTributes.init()
    print("[NightSkyTributes] Initializing...")
    
    NightSkyTributes.screenGui = createScreenGui()
    
    -- Connect to match events
    if MatchRemoteEvent then
        MatchRemoteEvent.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "TRIBUTE_ELIMINATED" then
                -- Store eliminated tribute data
                local tributeData = args[1]
                if tributeData then
                    NightSkyTributes:addFallenTribute(tributeData)
                end
                
            elseif eventType == "NIGHT_SKY_SEQUENCE" then
                -- Server triggered the night sky sequence
                local tributes = args[1]
                if tributes then
                    NightSkyTributes:startTributeSequence(tributes)
                else
                    -- Use locally stored tributes
                    NightSkyTributes:startTributeSequence(NightSkyTributes.fallenTributes)
                    NightSkyTributes:clearFallenTributes()
                end
                
            elseif eventType == "MATCH_ENDED" then
                -- Clear tributes on match end
                NightSkyTributes:clearFallenTributes()
            end
        end)
    end
    
    print("[NightSkyTributes] Initialized successfully")
end

-- Initialize when loaded
NightSkyTributes.init()

return NightSkyTributes
