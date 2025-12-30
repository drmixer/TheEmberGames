-- LocalScript: StormVisuals.lua
-- Visualizes the storm wall and safe zone
-- Creates a massive cylinder/dome that shrinks over time

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local StormVisuals = {}
StormVisuals.stormPart = nil
StormVisuals.currentPhase = 0
StormVisuals.currentRadius = 0
StormVisuals.targetRadius = 0
StormVisuals.isTransitioning = false
StormVisuals.colorCorrection = nil
StormVisuals.atmosphere = nil

-- Configuration
local STORM_COLOR = Color3.fromRGB(255, 50, 50)
local STORM_HEIGHT = 500
local ARENA_MAX_SIZE = 2048 -- Should match Config.ARENA_SIZE * 2 roughly

-- Create the storm wall visual
local function createStormWall()
    if StormVisuals.stormPart then return StormVisuals.stormPart end
    
    -- We use a massive hollow cylinder mesh or inverted sphere
    -- For simplicity and performance, we can use a giant cylinder with Transparency
    -- and maybe a forcefield material
    
    local stormPart = Instance.new("Part")
    stormPart.Name = "StormWall"
    stormPart.Size = Vector3.new(1, STORM_HEIGHT, 1) -- X/Z will be scaled
    stormPart.Anchored = true
    stormPart.CanCollide = false
    stormPart.CastShadow = false
    stormPart.Transparency = 0.4
    stormPart.Material = Enum.Material.ForceField -- Glowing effect
    stormPart.Color = STORM_COLOR
    stormPart.Position = Vector3.new(0, STORM_HEIGHT/2 - 50, 0)
    stormPart.Parent = workspace
    
    -- Add a cylinder mesh
    local mesh = Instance.new("CylinderMesh")
    mesh.Scale = Vector3.new(1, 1, 1) -- Will scale part instead
    mesh.Parent = stormPart
    
    -- Add visual texture if needed (Beam/Particle) could be added here
    
    StormVisuals.stormPart = stormPart
    return stormPart
end

-- Update storm effects based on player position
local function updateStormEffects()
    if not StormVisuals.stormPart then return end
    
    local char = Player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(StormVisuals.stormPart.Position.X, 0, StormVisuals.stormPart.Position.Z)).Magnitude
    local radius = StormVisuals.stormPart.Size.X / 2
    
    local inStorm = dist > radius
    
    -- Intense effects if in storm
    if inStorm then
        if not StormVisuals.colorCorrection then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "StormCC"
            cc.TintColor = Color3.fromRGB(255, 150, 150)
            cc.Saturation = -0.5
            cc.Contrast = 0.2
            cc.Parent = Lighting
            StormVisuals.colorCorrection = cc
        end
        
        -- Pulse effect
        local pulse = 0.5 + math.sin(tick() * 5) * 0.2
        StormVisuals.colorCorrection.TintColor = Color3.fromRGB(255, 150 + (pulse*50), 150)
    else
        if StormVisuals.colorCorrection then
            StormVisuals.colorCorrection:Destroy()
            StormVisuals.colorCorrection = nil
        end
    end
end

-- Initialize storm visuals
function StormVisuals:init()
    print("[StormVisuals] Initializing...")
    
    -- Create initial wall (hidden or huge)
    local wall = createStormWall()
    wall.Size = Vector3.new(ARENA_MAX_SIZE, STORM_HEIGHT, ARENA_MAX_SIZE)
    wall.Transparency = 1 -- Hidden initially
    
    -- Connect to events
    local eventsRemote = ReplicatedStorage:WaitForChild("EventsRemoteEvent", 10)
    if eventsRemote then
        eventsRemote.OnClientEvent:Connect(function(eventType, ...)
            local args = {...}
            
            if eventType == "STORM_PHASE_ACTIVE" then
                -- args: phase, radius, center, duration, startRadius
                local phase = args[1]
                local radius = args[2]
                local center = args[3]
                local duration = args[4] or 60 -- Default if missing
                local startRadius = args[5]
                
                StormVisuals:updateStorm(phase, radius, center, duration, startRadius)
                
            elseif eventType == "MATCH_START" then
                -- Reset
                if StormVisuals.stormPart then
                    StormVisuals.stormPart.Size = Vector3.new(ARENA_MAX_SIZE, STORM_HEIGHT, ARENA_MAX_SIZE)
                    StormVisuals.stormPart.Transparency = 1
                end
            end
        end)
    end
    
    -- Render loop for local effects
    RunService.RenderStepped:Connect(function()
        updateStormEffects()
    end)
end

-- Update storm wall dimensions
function StormVisuals:updateStorm(phase, targetRadius, center, duration, startRadius)
    if not StormVisuals.stormPart then createStormWall() end
    
    local wall = StormVisuals.stormPart
    local currentSize = wall.Size.X
    local targetSize = targetRadius * 2
    
    -- If startRadius is provided (from server), snap to it immediately to sync with damage logic
    if startRadius then
        local startSize = startRadius * 2
        wall.Size = Vector3.new(startSize, STORM_HEIGHT, startSize)
        currentSize = startSize
    end
    
    print(string.format("[StormVisuals] Phase %d: Shrinking from %d to %d over %d seconds", phase, currentSize, targetSize, duration))
    
    -- Make visible if hidden
    if wall.Transparency > 0.5 then
        TweenService:Create(wall, TweenInfo.new(2), {Transparency = 0.4}):Play()
    end
    
    -- Tween size
    -- We want to shrink SLOWLY over the duration of the phase to the target size
    -- Wait, does 'radius' mean the radius OF this phase, or the radius of the NEXT phase?
    -- Usually "Phase 1" has a defined radius. If we are entering Phase 1, we should shrink TO that radius.
    -- If the storm is "Closing", it shrinks. If it's "Holding", it stays.
    -- The current EventsService implementation just sets the NEW radius instantly in logic.
    -- To make it smooth, we should tween to that radius over the DURATION of the phase?
    -- No, usually:
    -- Phase Starts -> Zone is marked.
    -- Storm Shrinks -> Over shrinking duration.
    -- Storm Holds -> For hold duration.
    -- Since EventsService is simple (Phase N starts -> wait -> Phase N+1 starts), 
    -- and 'activateStormPhase' sets the CURRENT radius for damage immediately...
    -- It implies the storm jumps? No, that would be unfair.
    -- Let's assume the passed radius is the TARGET radius for this phase.
    -- AND we should shrink to it.
    
    -- However, EventsService 'startStormDamage' checks against `radius` immediately. 
    -- This means if we tweet visually, players might be damaged before the wall hits them visually if logic is instant.
    -- But since damage radius comes from 'calculateStormPosition(phase)', it's the target.
    -- THIS IS A BUG IN SERVER LOGIC: It applies damage based on the *new active* radius instantly?
    -- No, `startStormDamage` uses the `radius` passed to it.
    -- Players outside that radius take damage.
    -- If `radius` is the new smaller radius, then all players in the "safe" zone of the previous phase but outside the new one 
    -- will instantly take damage.
    -- This is BAD. The storm needs to SHRINK.
    
    -- I will fix the SERVER logic to handle shrinking radius over time, but for now let's assume valid data.
    -- Visuals: Tween to target size over duration.
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local goal = {Size = Vector3.new(targetSize, STORM_HEIGHT, targetSize)}
    
    TweenService:Create(wall, tweenInfo, goal):Play()
    
    -- Also move center if needed (currently always 0,0,0)
    if center then
        TweenService:Create(wall, tweenInfo, {Position = Vector3.new(center.X, STORM_HEIGHT/2 - 50, center.Z)}):Play()
    end
end

-- Auto init
StormVisuals:init()

return StormVisuals
