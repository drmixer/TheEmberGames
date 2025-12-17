-- LocalScript: SettingsUI.lua
-- Player settings for audio, graphics, controls, and gameplay

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SettingsUI = {}
SettingsUI.isVisible = false

-- Default settings
local DEFAULT_SETTINGS = {
    masterVolume = 0.8,
    musicVolume = 0.5,
    sfxVolume = 0.8,
    ambientVolume = 0.6,
    graphicsQuality = "High",
    particleEffects = true,
    shadows = true,
    mouseSensitivity = 0.5,
    invertY = false,
    autoPickup = true,
    damageNumbers = true,
    screenShake = 0.7,
}

local currentSettings = {}
for k, v in pairs(DEFAULT_SETTINGS) do
    currentSettings[k] = v
end

local CONFIG = {
    ACCENT_COLOR = Color3.fromRGB(212, 175, 55),
    BG_COLOR = Color3.fromRGB(20, 20, 30),
    PANEL_COLOR = Color3.fromRGB(30, 30, 45),
}

-- Create slider
local function createSlider(parent, name, yPos, min, max, default, onChange)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.9, 0, 0, 40)
    container.Position = UDim2.new(0.05, 0, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0.55, 0, 0, 8)
    sliderBg.Position = UDim2.new(0.4, 0, 0.5, -4)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 4)
    sliderCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    local fillPct = (default - min) / (max - min)
    sliderFill.Size = UDim2.new(fillPct, 0, 1, 0)
    sliderFill.BackgroundColor3 = CONFIG.ACCENT_COLOR
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = sliderFill
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.05, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.95, 0, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(math.floor(default * 100)) .. "%"
    valueLabel.TextColor3 = CONFIG.ACCENT_COLOR
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Parent = container
    
    -- Slider interaction
    local dragging = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relX = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
            relX = math.clamp(relX, 0, 1)
            sliderFill.Size = UDim2.new(relX, 0, 1, 0)
            local value = min + (max - min) * relX
            valueLabel.Text = tostring(math.floor(value * 100)) .. "%"
            if onChange then onChange(value) end
        end
    end)
    
    return container
end

-- Create toggle
local function createToggle(parent, name, yPos, default, onChange)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.9, 0, 0, 35)
    container.Position = UDim2.new(0.05, 0, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 50, 0, 24)
    toggleBg.Position = UDim2.new(0.85, 0, 0.5, -12)
    toggleBg.BackgroundColor3 = default and CONFIG.ACCENT_COLOR or Color3.fromRGB(60, 60, 70)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = container
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0.5, 0)
    toggleCorner.Parent = toggleBg
    
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Size = UDim2.new(0, 20, 0, 20)
    toggleKnob.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleKnob.BorderSizePixel = 0
    toggleKnob.Parent = toggleBg
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0.5, 0)
    knobCorner.Parent = toggleKnob
    
    local isOn = default
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.Parent = toggleBg
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = isOn and CONFIG.ACCENT_COLOR or Color3.fromRGB(60, 60, 70)
        }):Play()
        TweenService:Create(toggleKnob, TweenInfo.new(0.2), {
            Position = isOn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        }):Play()
        if onChange then onChange(isOn) end
    end)
    
    return container
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SettingsUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    -- Main panel
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 500, 0, 550)
    panel.Position = UDim2.new(0.5, -250, 0.5, -275)
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
    title.Text = "⚙️ SETTINGS"
    title.TextColor3 = CONFIG.ACCENT_COLOR
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    -- Close button
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
        SettingsUI:hide()
    end)
    
    -- Content scroll
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -20, 1, -110)
    content.Position = UDim2.new(0, 10, 0, 55)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 6
    content.CanvasSize = UDim2.new(0, 0, 0, 650)
    content.Parent = panel
    
    -- Audio section
    local audioLabel = Instance.new("TextLabel")
    audioLabel.Size = UDim2.new(1, 0, 0, 30)
    audioLabel.BackgroundTransparency = 1
    audioLabel.Text = "🔊 AUDIO"
    audioLabel.TextColor3 = CONFIG.ACCENT_COLOR
    audioLabel.TextSize = 16
    audioLabel.Font = Enum.Font.GothamBold
    audioLabel.TextXAlignment = Enum.TextXAlignment.Left
    audioLabel.Parent = content
    
    createSlider(content, "Master Volume", 35, 0, 1, currentSettings.masterVolume, function(v)
        currentSettings.masterVolume = v
    end)
    createSlider(content, "Music Volume", 80, 0, 1, currentSettings.musicVolume, function(v)
        currentSettings.musicVolume = v
    end)
    createSlider(content, "SFX Volume", 125, 0, 1, currentSettings.sfxVolume, function(v)
        currentSettings.sfxVolume = v
    end)
    createSlider(content, "Ambient Volume", 170, 0, 1, currentSettings.ambientVolume, function(v)
        currentSettings.ambientVolume = v
    end)
    
    -- Graphics section
    local gfxLabel = Instance.new("TextLabel")
    gfxLabel.Size = UDim2.new(1, 0, 0, 30)
    gfxLabel.Position = UDim2.new(0, 0, 0, 230)
    gfxLabel.BackgroundTransparency = 1
    gfxLabel.Text = "🎮 GRAPHICS"
    gfxLabel.TextColor3 = CONFIG.ACCENT_COLOR
    gfxLabel.TextSize = 16
    gfxLabel.Font = Enum.Font.GothamBold
    gfxLabel.TextXAlignment = Enum.TextXAlignment.Left
    gfxLabel.Parent = content
    
    createToggle(content, "Particle Effects", 265, currentSettings.particleEffects, function(v)
        currentSettings.particleEffects = v
    end)
    createToggle(content, "Shadows", 305, currentSettings.shadows, function(v)
        currentSettings.shadows = v
        Lighting.GlobalShadows = v
    end)
    
    -- Controls section
    local ctrlLabel = Instance.new("TextLabel")
    ctrlLabel.Size = UDim2.new(1, 0, 0, 30)
    ctrlLabel.Position = UDim2.new(0, 0, 0, 360)
    ctrlLabel.BackgroundTransparency = 1
    ctrlLabel.Text = "🖱️ CONTROLS"
    ctrlLabel.TextColor3 = CONFIG.ACCENT_COLOR
    ctrlLabel.TextSize = 16
    ctrlLabel.Font = Enum.Font.GothamBold
    ctrlLabel.TextXAlignment = Enum.TextXAlignment.Left
    ctrlLabel.Parent = content
    
    createSlider(content, "Mouse Sensitivity", 395, 0.1, 1, currentSettings.mouseSensitivity, function(v)
        currentSettings.mouseSensitivity = v
    end)
    createToggle(content, "Invert Y-Axis", 440, currentSettings.invertY, function(v)
        currentSettings.invertY = v
    end)
    
    -- Gameplay section
    local gameLabel = Instance.new("TextLabel")
    gameLabel.Size = UDim2.new(1, 0, 0, 30)
    gameLabel.Position = UDim2.new(0, 0, 0, 490)
    gameLabel.BackgroundTransparency = 1
    gameLabel.Text = "🎯 GAMEPLAY"
    gameLabel.TextColor3 = CONFIG.ACCENT_COLOR
    gameLabel.TextSize = 16
    gameLabel.Font = Enum.Font.GothamBold
    gameLabel.TextXAlignment = Enum.TextXAlignment.Left
    gameLabel.Parent = content
    
    createToggle(content, "Auto-Pickup Items", 525, currentSettings.autoPickup, function(v)
        currentSettings.autoPickup = v
    end)
    createToggle(content, "Damage Numbers", 565, currentSettings.damageNumbers, function(v)
        currentSettings.damageNumbers = v
    end)
    createSlider(content, "Screen Shake", 605, 0, 1, currentSettings.screenShake, function(v)
        currentSettings.screenShake = v
    end)
    
    SettingsUI.screenGui = screenGui
    SettingsUI.panel = panel
end

function SettingsUI:show()
    if SettingsUI.panel then
        SettingsUI.panel.Visible = true
        SettingsUI.isVisible = true
    end
end

function SettingsUI:hide()
    if SettingsUI.panel then
        SettingsUI.panel.Visible = false
        SettingsUI.isVisible = false
    end
end

function SettingsUI:toggle()
    if SettingsUI.isVisible then
        SettingsUI:hide()
    else
        SettingsUI:show()
    end
end

function SettingsUI:getSetting(key)
    return currentSettings[key]
end

function SettingsUI.init()
    print("[SettingsUI] Initializing...")
    createUI()
    
    -- ESC key toggles
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Escape and SettingsUI.isVisible then
            SettingsUI:hide()
        end
    end)
    
    print("[SettingsUI] Initialized!")
end

SettingsUI.init()
return SettingsUI
