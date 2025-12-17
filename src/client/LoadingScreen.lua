-- LocalScript: LoadingScreen.lua
-- Creates a dramatic, cinematic loading screen for The Ember Games
-- Features animated logo, fire particles, and loading progress

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local LoadingScreen = {}
LoadingScreen.screenGui = nil
LoadingScreen.isLoading = true
LoadingScreen.loadProgress = 0

-- Configuration
local CONFIG = {
    FADE_OUT_TIME = 1.5,
    MIN_DISPLAY_TIME = 3, -- Minimum seconds to show loading screen
    PARTICLE_COUNT = 20,
}

-- Create the loading screen UI
local function createLoadingScreen()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LoadingScreen"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999 -- Always on top
    screenGui.Parent = PlayerGui
    
    -- Main background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    -- Gradient overlay for depth
    local gradientOverlay = Instance.new("Frame")
    gradientOverlay.Name = "GradientOverlay"
    gradientOverlay.Size = UDim2.new(1, 0, 1, 0)
    gradientOverlay.BackgroundColor3 = Color3.fromRGB(20, 15, 10)
    gradientOverlay.BackgroundTransparency = 0.7
    gradientOverlay.BorderSizePixel = 0
    gradientOverlay.Parent = background
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 30, 10)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    gradient.Rotation = 90
    gradient.Parent = gradientOverlay
    
    -- Vignette effect
    local vignetteTop = Instance.new("Frame")
    vignetteTop.Name = "VignetteTop"
    vignetteTop.Size = UDim2.new(1, 0, 0.2, 0)
    vignetteTop.Position = UDim2.new(0, 0, 0, 0)
    vignetteTop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    vignetteTop.BorderSizePixel = 0
    vignetteTop.Parent = background
    
    local vignetteTopGradient = Instance.new("UIGradient")
    vignetteTopGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    vignetteTopGradient.Rotation = 90
    vignetteTopGradient.Parent = vignetteTop
    
    local vignetteBottom = vignetteTop:Clone()
    vignetteBottom.Name = "VignetteBottom"
    vignetteBottom.Position = UDim2.new(0, 0, 0.8, 0)
    vignetteBottom.FindFirstChild("UIGradient").Rotation = -90
    vignetteBottom.Parent = background
    
    -- Logo container
    local logoContainer = Instance.new("Frame")
    logoContainer.Name = "LogoContainer"
    logoContainer.Size = UDim2.new(0.5, 0, 0.4, 0)
    logoContainer.Position = UDim2.new(0.25, 0, 0.15, 0)
    logoContainer.BackgroundTransparency = 1
    logoContainer.Parent = background
    
    -- Main title - "THE EMBER GAMES"
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    titleLabel.Position = UDim2.new(0, 0, 0.1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "THE EMBER GAMES"
    titleLabel.TextColor3 = Color3.fromRGB(212, 175, 55) -- Gold
    titleLabel.TextStrokeColor3 = Color3.fromRGB(100, 60, 20)
    titleLabel.TextStrokeTransparency = 0
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    titleLabel.Parent = logoContainer
    
    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "SubtitleLabel"
    subtitleLabel.Size = UDim2.new(1, 0, 0.15, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.52, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "May the odds be ever in your favor"
    subtitleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    subtitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    subtitleLabel.TextStrokeTransparency = 0.5
    subtitleLabel.Font = Enum.Font.GothamMedium
    subtitleLabel.TextScaled = true
    subtitleLabel.Parent = logoContainer
    
    -- Mockingjay symbol (using text as placeholder)
    local symbolLabel = Instance.new("TextLabel")
    symbolLabel.Name = "SymbolLabel"
    symbolLabel.Size = UDim2.new(0.3, 0, 0.3, 0)
    symbolLabel.Position = UDim2.new(0.35, 0, 0.7, 0)
    symbolLabel.BackgroundTransparency = 1
    symbolLabel.Text = "🔥"
    symbolLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
    symbolLabel.Font = Enum.Font.GothamBold
    symbolLabel.TextScaled = true
    symbolLabel.Parent = logoContainer
    
    -- Loading bar container
    local loadingContainer = Instance.new("Frame")
    loadingContainer.Name = "LoadingContainer"
    loadingContainer.Size = UDim2.new(0.4, 0, 0.02, 0)
    loadingContainer.Position = UDim2.new(0.3, 0, 0.75, 0)
    loadingContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    loadingContainer.BorderSizePixel = 0
    loadingContainer.Parent = background
    
    local loadingCorner = Instance.new("UICorner")
    loadingCorner.CornerRadius = UDim.new(0.5, 0)
    loadingCorner.Parent = loadingContainer
    
    local loadingStroke = Instance.new("UIStroke")
    loadingStroke.Color = Color3.fromRGB(80, 60, 40)
    loadingStroke.Thickness = 1
    loadingStroke.Parent = loadingContainer
    
    -- Loading bar fill
    local loadingFill = Instance.new("Frame")
    loadingFill.Name = "Fill"
    loadingFill.Size = UDim2.new(0, 0, 1, 0)
    loadingFill.Position = UDim2.new(0, 0, 0, 0)
    loadingFill.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
    loadingFill.BorderSizePixel = 0
    loadingFill.Parent = loadingContainer
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0.5, 0)
    fillCorner.Parent = loadingFill
    
    -- Loading glow effect
    local loadingGlow = Instance.new("Frame")
    loadingGlow.Name = "Glow"
    loadingGlow.Size = UDim2.new(0.1, 0, 3, 0)
    loadingGlow.Position = UDim2.new(0, 0, -1, 0)
    loadingGlow.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
    loadingGlow.BackgroundTransparency = 0.5
    loadingGlow.BorderSizePixel = 0
    loadingGlow.Parent = loadingFill
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0.5, 0)
    glowCorner.Parent = loadingGlow
    
    -- Loading text
    local loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingText"
    loadingText.Size = UDim2.new(0.4, 0, 0.03, 0)
    loadingText.Position = UDim2.new(0.3, 0, 0.78, 0)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = "Preparing the Arena..."
    loadingText.TextColor3 = Color3.fromRGB(150, 150, 150)
    loadingText.Font = Enum.Font.Gotham
    loadingText.TextScaled = true
    loadingText.Parent = background
    
    -- Tip text at bottom
    local tipLabel = Instance.new("TextLabel")
    tipLabel.Name = "TipLabel"
    tipLabel.Size = UDim2.new(0.6, 0, 0.04, 0)
    tipLabel.Position = UDim2.new(0.2, 0, 0.9, 0)
    tipLabel.BackgroundTransparency = 1
    tipLabel.Text = ""
    tipLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    tipLabel.Font = Enum.Font.Gotham
    tipLabel.TextScaled = true
    tipLabel.Parent = background
    
    -- Create fire particle emitters (decorative)
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "ParticleContainer"
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.Parent = background
    
    -- Store references
    LoadingScreen.screenGui = screenGui
    LoadingScreen.background = background
    LoadingScreen.loadingFill = loadingFill
    LoadingScreen.loadingText = loadingText
    LoadingScreen.tipLabel = tipLabel
    LoadingScreen.titleLabel = titleLabel
    LoadingScreen.symbolLabel = symbolLabel
    LoadingScreen.particleContainer = particleContainer
    
    return screenGui
end

-- Animated fire particles effect
local function createFireParticles()
    local particles = {}
    
    for i = 1, CONFIG.PARTICLE_COUNT do
        local particle = Instance.new("Frame")
        particle.Name = "Particle" .. i
        particle.Size = UDim2.new(0, math.random(3, 8), 0, math.random(3, 8))
        particle.Position = UDim2.new(math.random() * 0.8 + 0.1, 0, 1.1, 0) -- Start below screen
        particle.BackgroundColor3 = Color3.fromRGB(
            math.random(200, 255),
            math.random(100, 180),
            math.random(0, 50)
        )
        particle.BackgroundTransparency = math.random() * 0.5
        particle.BorderSizePixel = 0
        particle.Parent = LoadingScreen.particleContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        
        table.insert(particles, {
            frame = particle,
            speed = math.random(80, 150) / 100,
            drift = (math.random() - 0.5) * 0.002,
            startX = math.random() * 0.8 + 0.1
        })
    end
    
    -- Animate particles
    local connection
    connection = RunService.RenderStepped:Connect(function(dt)
        if not LoadingScreen.isLoading then
            for _, p in ipairs(particles) do
                if p.frame and p.frame.Parent then
                    p.frame:Destroy()
                end
            end
            connection:Disconnect()
            return
        end
        
        for _, p in ipairs(particles) do
            if p.frame and p.frame.Parent then
                local currentPos = p.frame.Position
                local newY = currentPos.Y.Scale - dt * p.speed * 0.3
                local newX = currentPos.X.Scale + p.drift
                
                if newY < -0.1 then
                    newY = 1.1
                    newX = math.random() * 0.8 + 0.1
                    p.frame.BackgroundTransparency = math.random() * 0.5
                end
                
                p.frame.Position = UDim2.new(newX, 0, newY, 0)
            end
        end
    end)
    
    return particles
end

-- Loading tips
local LOADING_TIPS = {
    "💡 Stay near water sources to keep your thirst manageable",
    "💡 The storm closes in every 5 minutes - don't get caught!",
    "💡 Craft weapons from sticks and stones found in the arena",
    "💡 Supply drops contain rare and powerful items",
    "💡 Watch the sky at night to see fallen tributes honored",
    "💡 Use the emote wheel (G) to communicate with others",
    "💡 Higher ground gives you a tactical advantage",
    "💡 Traps can be crafted to surprise your opponents",
    "💡 The Cornucopia has the best loot - but also the most danger",
    "💡 Different biomes have different resources and dangers",
    "💡 Listen for the cannon to know when a tribute falls",
    "💡 The final circle gets very small - prepare for close combat",
}

-- Cycle through loading tips
local function cycleTips()
    local tipIndex = 1
    
    while LoadingScreen.isLoading do
        if LoadingScreen.tipLabel then
            LoadingScreen.tipLabel.Text = LOADING_TIPS[tipIndex]
            
            -- Fade animation
            TweenService:Create(LoadingScreen.tipLabel, TweenInfo.new(0.5), {
                TextTransparency = 0
            }):Play()
            
            task.wait(3)
            
            TweenService:Create(LoadingScreen.tipLabel, TweenInfo.new(0.5), {
                TextTransparency = 1
            }):Play()
            
            task.wait(0.5)
            
            tipIndex = tipIndex % #LOADING_TIPS + 1
        else
            break
        end
    end
end

-- Update loading progress
function LoadingScreen:updateProgress(progress, statusText)
    LoadingScreen.loadProgress = progress
    
    if LoadingScreen.loadingFill then
        TweenService:Create(LoadingScreen.loadingFill, TweenInfo.new(0.3), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
    end
    
    if statusText and LoadingScreen.loadingText then
        LoadingScreen.loadingText.Text = statusText
    end
end

-- Title shimmer animation
local function animateTitle()
    local shimmerTime = 0
    
    local connection
    connection = RunService.RenderStepped:Connect(function(dt)
        if not LoadingScreen.isLoading or not LoadingScreen.titleLabel then
            connection:Disconnect()
            return
        end
        
        shimmerTime = shimmerTime + dt
        
        -- Subtle color pulse
        local pulse = math.sin(shimmerTime * 2) * 0.1 + 0.9
        LoadingScreen.titleLabel.TextColor3 = Color3.fromRGB(
            math.floor(212 * pulse),
            math.floor(175 * pulse),
            math.floor(55 * pulse)
        )
        
        -- Symbol rotation/pulse
        if LoadingScreen.symbolLabel then
            local scale = 1 + math.sin(shimmerTime * 3) * 0.05
            LoadingScreen.symbolLabel.Size = UDim2.new(0.3 * scale, 0, 0.3 * scale, 0)
            LoadingScreen.symbolLabel.Position = UDim2.new(0.35 - (scale - 1) * 0.15, 0, 0.7 - (scale - 1) * 0.15, 0)
        end
    end)
end

-- Hide loading screen with fade animation
function LoadingScreen:hide()
    if not LoadingScreen.screenGui then return end
    
    LoadingScreen.isLoading = false
    
    -- Update final status
    LoadingScreen:updateProgress(1, "Welcome to the Arena!")
    
    task.wait(0.5)
    
    -- Fade out
    TweenService:Create(LoadingScreen.background, TweenInfo.new(CONFIG.FADE_OUT_TIME), {
        BackgroundTransparency = 1
    }):Play()
    
    -- Fade all children
    for _, child in pairs(LoadingScreen.background:GetDescendants()) do
        if child:IsA("Frame") then
            TweenService:Create(child, TweenInfo.new(CONFIG.FADE_OUT_TIME), {
                BackgroundTransparency = 1
            }):Play()
        elseif child:IsA("TextLabel") then
            TweenService:Create(child, TweenInfo.new(CONFIG.FADE_OUT_TIME), {
                TextTransparency = 1,
                TextStrokeTransparency = 1
            }):Play()
        elseif child:IsA("ImageLabel") then
            TweenService:Create(child, TweenInfo.new(CONFIG.FADE_OUT_TIME), {
                ImageTransparency = 1
            }):Play()
        end
    end
    
    task.delay(CONFIG.FADE_OUT_TIME + 0.5, function()
        if LoadingScreen.screenGui then
            LoadingScreen.screenGui:Destroy()
            LoadingScreen.screenGui = nil
        end
    end)
    
    print("[LoadingScreen] Loading screen hidden")
end

-- Preload game assets
local function preloadAssets()
    local assetsToLoad = {}
    
    -- Collect all sounds used in the game
    local soundIds = {
        "rbxassetid://6241709963", -- Sword swing
        "rbxassetid://5034047634", -- Cannon
        "rbxassetid://9046240113", -- Match gong
        "rbxassetid://9046239626", -- Countdown beep
        "rbxassetid://9044353224", -- Bird whistle
    }
    
    for _, id in ipairs(soundIds) do
        local sound = Instance.new("Sound")
        sound.SoundId = id
        table.insert(assetsToLoad, sound)
    end
    
    -- Preload with progress updates
    local totalAssets = #assetsToLoad
    local loadedAssets = 0
    
    for i, asset in ipairs(assetsToLoad) do
        ContentProvider:PreloadAsync({asset})
        loadedAssets = loadedAssets + 1
        
        local progress = loadedAssets / totalAssets
        LoadingScreen:updateProgress(progress * 0.8, "Loading assets... " .. math.floor(progress * 100) .. "%")
        
        task.wait(0.05) -- Small delay for visual effect
    end
    
    -- Cleanup temporary sounds
    for _, asset in ipairs(assetsToLoad) do
        if asset:IsA("Sound") then
            asset:Destroy()
        end
    end
    
    -- Final loading steps
    LoadingScreen:updateProgress(0.9, "Initializing systems...")
    task.wait(0.5)
    
    LoadingScreen:updateProgress(0.95, "Connecting to arena...")
    task.wait(0.5)
end

-- Initialize loading screen
function LoadingScreen.init()
    print("[LoadingScreen] Initializing...")
    
    createLoadingScreen()
    createFireParticles()
    
    -- Start animations
    task.spawn(cycleTips)
    task.spawn(animateTitle)
    
    -- Start asset preloading
    task.spawn(function()
        local startTime = tick()
        
        preloadAssets()
        
        -- Ensure minimum display time
        local elapsed = tick() - startTime
        if elapsed < CONFIG.MIN_DISPLAY_TIME then
            task.wait(CONFIG.MIN_DISPLAY_TIME - elapsed)
        end
        
        -- Check if player character is ready
        local character = Player.Character or Player.CharacterAdded:Wait()
        
        -- Hide loading screen
        LoadingScreen:hide()
    end)
    
    print("[LoadingScreen] Initialized")
end

-- Initialize when module loads
LoadingScreen.init()

return LoadingScreen
