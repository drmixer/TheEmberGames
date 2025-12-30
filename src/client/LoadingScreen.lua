-- LocalScript: LoadingScreen.lua
-- Creates a dramatic, cinematic loading screen for The Ember Games
-- Features animated logo, fire particles, and loading progress using Premium UITheme

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local UITheme = require(script.Parent:WaitForChild("UITheme"))

local LoadingScreen = {}
LoadingScreen.screenGui = nil
LoadingScreen.isLoading = true
LoadingScreen.loadProgress = 0

-- Configuration
local CONFIG = {
    FADE_OUT_TIME = 1.2,
    MIN_DISPLAY_TIME = 4, -- Give text time to be read
}

local function createEmberParticle(parent)
    -- Simplified version of MainMenu embers for performance/consistency
    local ember = Instance.new("Frame")
    local size = math.random(3, 7)
    ember.Size = UDim2.new(0, size, 0, size)
    
    local startX = math.random()
    ember.Position = UDim2.new(startX, 0, 1.1, 0)
    
    ember.BackgroundColor3 = UITheme.Colors.Gold
    ember.BorderSizePixel = 0
    ember.Rotation = math.random(0, 360)
    ember.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ember
    
    local duration = math.random(3, 6)
    local xDrift = math.random(-80, 80)
    local endRotation = math.random(-180, 180)
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local goal = {
        Position = UDim2.new(startX, xDrift, -0.1, 0),
        BackgroundTransparency = 1,
        Rotation = ember.Rotation + endRotation
    }
    
    local tween = TweenService:Create(ember, tweenInfo, goal)
    tween:Play()
    tween.Completed:Connect(function() ember:Destroy() end)
end

local function createLoadingScreen()
    if LoadingScreen.screenGui then LoadingScreen.screenGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LoadingScreen"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 1000 -- Absolute top
    screenGui.Parent = PlayerGui
    
    -- Main background with Theme color
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = UITheme.Colors.Background
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    -- Cinematic Vignette (Darkening edges)
    local vignette = Instance.new("ImageLabel")
    vignette.Size = UDim2.new(1, 0, 1, 0)
    vignette.BackgroundTransparency = 1
    vignette.Image = "rbxassetid://10842050222" -- Soft gradient
    vignette.ImageColor3 = Color3.new(0,0,0)
    vignette.ImageTransparency = 0.2
    vignette.Parent = background
    
    -- Particles Container
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "Particles"
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.Parent = background
    
    -- Center Logo Area
    local centerContainer = Instance.new("Frame")
    centerContainer.Size = UDim2.new(0, 600, 0, 200)
    centerContainer.Position = UDim2.new(0.5, 0, 0.4, 0)
    centerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    centerContainer.BackgroundTransparency = 1
    centerContainer.Parent = background
    
    local title = Instance.new("TextLabel")
    title.Text = "THE EMBER GAMES"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.Font = UITheme.Fonts.Title
    title.TextSize = 52
    title.TextColor3 = UITheme.Colors.Gold
    title.Parent = centerContainer
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Text = "MAY THE ODDS BE EVER IN YOUR FAVOR"
    subtitle.Size = UDim2.new(1, 0, 0, 30)
    subtitle.Position = UDim2.new(0, 0, 0, 65)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = UITheme.Fonts.Label
    subtitle.TextSize = 14
    subtitle.TextColor3 = UITheme.Colors.TextDim
    -- Note: LetterSpacing doesn't exist in Roblox, removed
    subtitle.Parent = centerContainer
    
    -- Loading Bar Section (Bottom)
    local progressContainer = Instance.new("Frame")
    progressContainer.Size = UDim2.new(0, 400, 0, 4)
    progressContainer.Position = UDim2.new(0.5, 0, 0.85, 0)
    progressContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    progressContainer.BackgroundColor3 = UITheme.Colors.SurfaceHighlight
    progressContainer.BorderSizePixel = 0
    progressContainer.Parent = background
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = progressContainer
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0) -- Start 0
    fill.BackgroundColor3 = UITheme.Colors.Gold
    fill.BorderSizePixel = 0
    fill.Parent = progressContainer
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    -- Glow only on the bar
    local glow = Instance.new("UIStroke")
    glow.Thickness = 2
    glow.Transparency = 0.5
    glow.Color = UITheme.Colors.Gold
    glow.Parent = fill
    
    -- Loading Text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "Status"
    statusText.Text = "PREPARING ARENA..."
    statusText.Size = UDim2.new(1, 0, 0, 20)
    statusText.Position = UDim2.new(0, 0, -6, 0) -- Above bar
    statusText.BackgroundTransparency = 1
    statusText.Font = UITheme.Fonts.Body
    statusText.TextSize = 14
    statusText.TextColor3 = UITheme.Colors.TextDim
    statusText.Parent = progressContainer

    -- Tip Text (Below bar)
    local tipText = Instance.new("TextLabel")
    tipText.Name = "Tip"
    tipText.Text = ""
    tipText.Size = UDim2.new(1, 0, 0, 20)
    tipText.Position = UDim2.new(0, 0, 4, 0) -- Below bar
    tipText.BackgroundTransparency = 1
    tipText.Font = UITheme.Fonts.Label
    tipText.TextSize = 14
    tipText.TextColor3 = UITheme.Colors.Text
    tipText.TextTransparency = 0.4
    tipText.Parent = progressContainer

    LoadingScreen.screenGui = screenGui
    LoadingScreen.background = background
    LoadingScreen.particleContainer = particleContainer
    LoadingScreen.centerContainer = centerContainer -- For logo
    LoadingScreen.fill = fill
    LoadingScreen.statusText = statusText
    LoadingScreen.tipText = tipText
    
    return screenGui
end

local TIPS = {
    "Stay near the Cornucopia for high-tier loot, but beware of early fights.",
    "Craft bandages using cloth found in residential zones.",
    "Form Alliances to survive longer, but remember: there can be only one winner.",
    "High ground offers a strategic advantage.",
    "Listen for the cannon blast signaling a fallen tribute.",
}

local function cycleTips()
    while LoadingScreen.isLoading and LoadingScreen.tipText do
        local tip = TIPS[math.random(1, #TIPS)]
        LoadingScreen.tipText.Text = tip
        
        -- Fade in
        TweenService:Create(LoadingScreen.tipText, TweenInfo.new(1), {TextTransparency = 0.2}):Play()
        task.wait(3.5)
        -- Fade out
        TweenService:Create(LoadingScreen.tipText, TweenInfo.new(1), {TextTransparency = 1}):Play()
        task.wait(1)
    end
end

function LoadingScreen:updateProgress(progress, status)
    if not LoadingScreen.fill then return end
    
    -- Smooth tween
    TweenService:Create(LoadingScreen.fill, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
        Size = UDim2.new(progress, 0, 1, 0)
    }):Play()
    
    if status and LoadingScreen.statusText then
        LoadingScreen.statusText.Text = string.upper(status)
    end
end

function LoadingScreen:hide()
    if not LoadingScreen.screenGui then return end
    
    LoadingScreen.isLoading = false
    LoadingScreen:updateProgress(1, "READY")
    
    task.wait(0.8)
    
    -- Cinematic Fade Out
    -- Fade out text elements
    local fadeInfo = TweenInfo.new(0.8)
    
    if LoadingScreen.centerContainer then
        for _, c in pairs(LoadingScreen.centerContainer:GetChildren()) do
            if c:IsA("TextLabel") then
                TweenService:Create(c, fadeInfo, {TextTransparency = 1}):Play()
            end
        end
    end
    
    -- 2. Fade Background
    TweenService:Create(LoadingScreen.background, TweenInfo.new(1.5), {BackgroundTransparency = 1}):Play()
    
    -- Cleanup
    task.delay(1.5, function()
        if LoadingScreen.screenGui then LoadingScreen.screenGui:Destroy() end
    end)
end

function LoadingScreen.init()
    print("[LoadingScreen] Initializing Premium Loader")
    createLoadingScreen()
    
    -- Start Tip Cycle
    task.spawn(cycleTips)
    
    -- Particle Loop
    task.spawn(function()
        while LoadingScreen.isLoading and LoadingScreen.screenGui and LoadingScreen.screenGui.Parent do
            createEmberParticle(LoadingScreen.particleContainer)
            task.wait(math.random(1,3)/10) -- fast ember generation
        end
    end)
    
    -- Mock Loading Process (Replace with real asset loading if needed)
    task.spawn(function()
        local steps = {
            {0.2, "Initializing Core Systems"},
            {0.4, "Generating Terrain"},
            {0.6, "Loading Assets"},
            {0.8, "Connecting to Server"},
            {0.95, "Finalizing..."}
        }
        
        for _, step in ipairs(steps) do
            if not LoadingScreen.isLoading then break end
            LoadingScreen:updateProgress(step[1], step[2])
            task.wait(math.random(5, 12)/10)
        end
        
        -- Keep screen up for Min Time
        task.wait(1)
        LoadingScreen:hide()
    end)
    
    -- MATCH TRANSITION HANDLING
    -- 1. Show Screen when Match Starts
    -- MATCH TRANSITION HANDLING
    -- 1. Show Screen when Match Starts
    task.spawn(function()
        local LobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemoteEvent", 30)
        if LobbyRemote then
            LobbyRemote.OnClientEvent:Connect(function(action, ...)
                if action == "MATCH_STARTING" then
                    -- Re-create and show screen
                    LoadingScreen.isLoading = true
                    createLoadingScreen()
                    LoadingScreen:updateProgress(0.2, "PREPARING ARENA...")
                    task.spawn(cycleTips)
                    
                    -- Fake progress while waiting
                    task.spawn(function()
                        local p = 0.2
                        while LoadingScreen.isLoading and p < 0.9 do
                            p = p + 0.05
                            LoadingScreen:updateProgress(p)
                            task.wait(0.5)
                        end
                    end)
                end
            end)
        end
    end)

    -- 2. Hide Screen when Player is Spawned (Camera Reset)
    task.spawn(function()
        local SpawnerRemote = ReplicatedStorage:WaitForChild("SpawnerRemoteEvent", 30)
        if SpawnerRemote then
            SpawnerRemote.OnClientEvent:Connect(function(action)
                if action == "RESET_CAMERA" then
                    -- Complete the bar and hide
                    LoadingScreen:updateProgress(1, "READY!")
                    task.wait(0.5)
                    LoadingScreen:hide()
                end
            end)
        end
    end)
end

LoadingScreen.init()
return LoadingScreen
