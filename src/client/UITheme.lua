local TweenService = game:GetService("TweenService")

-- Import AudioController for UI Sounds
local AudioController = require(script.Parent:WaitForChild("AudioController"))

local UITheme = {}

-- Color Palette
UITheme.Colors = {
    -- Primary Backgrounds (Dark, warm, gritty)
    Background = Color3.fromRGB(15, 10, 10),
    Surface = Color3.fromRGB(28, 20, 20),
    SurfaceHighlight = Color3.fromRGB(45, 30, 30),
    
    -- Accents (Phoenix Fire)
    Gold = Color3.fromRGB(255, 140, 0), -- Deep Orange/Gold
    GoldDim = Color3.fromRGB(184, 80, 11), -- Burnt Orange
    GoldHighlight = Color3.fromRGB(255, 180, 50), -- Bright Fire
    
    -- Functional Colors
    Success = Color3.fromRGB(46, 204, 113),
    Danger = Color3.fromRGB(220, 20, 60), -- Crimson
    Text = Color3.fromRGB(255, 245, 240), -- Warm White
    TextDim = Color3.fromRGB(160, 140, 140), -- Warm Gray
    
    -- Rarity Colors
    Common = Color3.fromRGB(180, 180, 180),
    Uncommon = Color3.fromRGB(46, 204, 113),
    Rare = Color3.fromRGB(52, 152, 219),
    Epic = Color3.fromRGB(155, 89, 182),
    Legendary = Color3.fromRGB(255, 140, 0), -- Phoenix Orange
}

-- Typography
UITheme.Fonts = {
    Title = Enum.Font.GothamBlack,
    Header = Enum.Font.GothamBold,
    Body = Enum.Font.GothamMedium,
    Label = Enum.Font.Gotham,
}

-- Common Element Constants
UITheme.CornerRadius = UDim.new(0, 8)
UITheme.Padding = UDim.new(0, 12)

-- Helper to apply "Glassmorphism" look
function UITheme.applyGlass(frame, transparency)
    frame.BackgroundColor3 = UITheme.Colors.Surface
    frame.BackgroundTransparency = transparency or 0.3
    frame.BorderSizePixel = 0
    
    -- Add subtle stroke
    local stroke = frame:FindFirstChild("GlassStroke") or Instance.new("UIStroke")
    stroke.Name = "GlassStroke"
    stroke.Color = UITheme.Colors.Gold
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.Parent = frame
    
    -- Add corner if needed
    local corner = frame:FindFirstChild("GlassCorner") or Instance.new("UICorner")
    corner.Name = "GlassCorner"
    corner.CornerRadius = UITheme.CornerRadius
    corner.Parent = frame
end

-- Animated Button Creator
function UITheme.createButton(props)
    local button = Instance.new("TextButton")
    button.Size = props.Size or UDim2.new(0, 200, 0, 50)
    button.Position = props.Position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = UITheme.Colors.Surface
    button.Text = ""
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UITheme.CornerRadius
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = UITheme.Colors.GoldDim
    stroke.Transparency = 0.5
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = props.Text or "Button"
    label.TextColor3 = UITheme.Colors.Text
    label.Font = UITheme.Fonts.Header
    label.TextSize = 18
    label.Parent = button
    
    local originalSize = props.Size or UDim2.new(0, 200, 0, 50)
    local originalPos = props.Position or UDim2.new(0, 0, 0, 0)
    
    -- Animations
    button.MouseEnter:Connect(function()
        AudioController:playUISound("UI_HOVER")
        
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = UITheme.Colors.SurfaceHighlight}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0, Color = UITheme.Colors.Gold}):Play()
        TweenService:Create(button, TweenInfo.new(0.1), {Size = originalSize + UDim2.new(0, 4, 0, 4), Position = originalPos - UDim2.new(0, 2, 0, 2)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = UITheme.Colors.Surface}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.5, Color = UITheme.Colors.GoldDim}):Play()
        TweenService:Create(button, TweenInfo.new(0.2), {Size = originalSize, Position = originalPos}):Play()
    end)
    
    button.MouseButton1Click:Connect(function()
        AudioController:playUISound("UI_CLICK")
        
        -- Click pulse
        local ripple = Instance.new("Frame")
        ripple.BackgroundColor3 = UITheme.Colors.Gold
        ripple.BackgroundTransparency = 0.6
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.Parent = button
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple
        
        local tween = TweenService:Create(ripple, TweenInfo.new(0.4), {Size = UDim2.new(1.5, 0, 2.5, 0), BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Connect(function() ripple:Destroy() end)
        
        if props.OnClick then props.OnClick() end
    end)
    
    return button
end

return UITheme
