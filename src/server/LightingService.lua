-- ServerScript: LightingService.lua
-- Manages premium lighting, atmosphere, and time cycles for The Ember Games
-- Implements "Cinematic" visual style with Volumetric Lighting

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LightingService = {}
LightingService.currentTime = 0
LightingService.isCycling = false

-- Premium Lighting Presets (Hunger Games Aesthetic)
local PRESETS = {
    MORNING = {
        ClockTime = 6.5, -- Golden sunrise
        Brightness = 2,
        ColorShift_Bottom = Color3.fromRGB(200, 150, 100),
        ColorShift_Top = Color3.fromRGB(255, 240, 200),
        Ambient = Color3.fromRGB(70, 70, 70),
        OutdoorAmbient = Color3.fromRGB(100, 100, 100),
        ShadowSoftness = 0.2,
        Atmosphere = {
            Density = 0.35,
            Offset = 0.25,
            Color = Color3.fromRGB(198, 169, 142),
            Decay = Color3.fromRGB(104, 76, 52),
            Glare = 0.3,
            Haze = 0.4
        }
    },
    NOON = {
        ClockTime = 14, -- High harsh sun
        Brightness = 3,
        ColorShift_Bottom = Color3.fromRGB(255, 255, 255),
        ColorShift_Top = Color3.fromRGB(255, 255, 255),
        Ambient = Color3.fromRGB(120, 120, 120),
        OutdoorAmbient = Color3.fromRGB(150, 150, 150),
        ShadowSoftness = 0.1, -- Sharp shadows
        Atmosphere = {
            Density = 0.25,
            Offset = 0,
            Color = Color3.fromRGB(199, 219, 229),
            Decay = Color3.fromRGB(106, 112, 125),
            Glare = 0.8,
            Haze = 0.2
        }
    },
    NIGHT = {
        ClockTime = 0, -- Dead of night
        Brightness = 0.5, -- Dim but visible (moonlight)
        ColorShift_Bottom = Color3.fromRGB(10, 10, 20),
        ColorShift_Top = Color3.fromRGB(20, 20, 40),
        Ambient = Color3.fromRGB(20, 20, 30),
        OutdoorAmbient = Color3.fromRGB(30, 30, 50),
        ShadowSoftness = 1, -- Very soft shadows
        Atmosphere = {
            Density = 0.45,
            Offset = 0.1,
            Color = Color3.fromRGB(45, 50, 70),
            Decay = Color3.fromRGB(10, 10, 20),
            Glare = 0,
            Haze = 0.5
        }
    }
}

-- Ensure all necessary lighting objects exist
local function setupLightingObjects()
    -- Atmosphere
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmo.Parent = Lighting
    
    -- Sky
    local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
    sky.SkyboxBk = "rbxassetid://6444884337" -- Premium Skybox (placeholder ID, using standard realistic sky if needed)
    sky.SkyboxDn = "rbxassetid://6444884785"
    sky.SkyboxFt = "rbxassetid://6444884337"
    sky.SkyboxLf = "rbxassetid://6444884337"
    sky.SkyboxRt = "rbxassetid://6444884337"
    sky.SkyboxUp = "rbxassetid://6444884785"
    sky.SunTextureId = "rbxassetid://6196665106" -- Realistic Sun
    sky.Parent = Lighting
    
    -- Bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
    bloom.Intensity = 0.4
    bloom.Size = 24
    bloom.Threshold = 0.8
    bloom.Parent = Lighting
    
    -- SunRays
    local sun = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
    sun.Intensity = 0.25
    sun.Spread = 0.8
    sun.Parent = Lighting
    
    -- ColorCorrection (Cinematic Grading)
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
    cc.Saturation = 0.1 -- Desaturated slightly for grit
    cc.Contrast = 0.2 -- Higher contrast
    cc.Brightness = 0.05
    cc.Parent = Lighting
    
    -- DepthOfField (Subtle)
    local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect")
    dof.FarIntensity = 0.1
    dof.FocusDistance = 100
    dof.InFocusRadius = 50
    dof.NearIntensity = 0
    dof.Parent = Lighting
end

function LightingService:TransitionTo(timeOfDay, duration)
    local preset = PRESETS[timeOfDay] or PRESETS.NOON
    local info = TweenInfo.new(duration or 5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Tween Lighting Properties
    TweenService:Create(Lighting, info, {
        ClockTime = preset.ClockTime,
        Brightness = preset.Brightness,
        ColorShift_Bottom = preset.ColorShift_Bottom,
        ColorShift_Top = preset.ColorShift_Top,
        Ambient = preset.Ambient,
        OutdoorAmbient = preset.OutdoorAmbient,
        ShadowSoftness = preset.ShadowSoftness
    }):Play()
    
    -- Tween Atmosphere
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo and preset.Atmosphere then
        TweenService:Create(atmo, info, preset.Atmosphere):Play()
    end
end

-- Setup realistic water
local function setupWater()
    if Workspace.Terrain then
        Workspace.Terrain.WaterWaveSize = 0.4
        Workspace.Terrain.WaterWaveSpeed = 15
        Workspace.Terrain.WaterReflectance = 0.8
        Workspace.Terrain.WaterTransparency = 0.9
        Workspace.Terrain.WaterColor = Color3.fromRGB(50, 100, 120) -- Teal/Blue
    end
end

function LightingService:startDayCycle()
    if LightingService.isCycling then return end
    LightingService.isCycling = true
    
    -- Day cycle loop (Slow rotation)
    -- In a real game, this might verify with MatchService time
    task.spawn(function()
        while LightingService.isCycling do
            local dt = task.wait(1)
            -- Advance time slowly (1 in-game minute per real second)
            Lighting.ClockTime = Lighting.ClockTime + (0.01)
        end
    end)
end

function LightingService.init()
    print("[LightingService] Initializing Premium Lighting...")
    
    -- Set Technology
    -- Note: Scripts cannot change Technology at runtime, but we assume "Future" is set in Studio.
    -- If not, lighting will just look like ShadowMap, which is acceptable.
    
    setupLightingObjects()
    setupWater()
    
    -- Start at Morning
    LightingService:TransitionTo("MORNING", 0)
    
    -- We can expose this service so MatchService can trigger nightfall
    _G.LightingService = LightingService
    
    print("[LightingService] Ready")
end

return LightingService
