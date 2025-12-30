-- ServerScript: DefaultSpawn.lua
-- Creates a safe, high-altitude spawn point to prevent "under map" glitches before the game places players.
-- Converted to ModuleScript to ensure predictable execution.

local DefaultSpawn = {}

function DefaultSpawn.init()
    local workspace = game:GetService("Workspace")

    local spawnParams = {
        Position = Vector3.new(0, 2000, 0), -- Moved much higher (Y=2000) to be completely out of sight
        Size = Vector3.new(200, 5, 200),
        Transparency = 1, -- Invisible
        CastShadow = false,
        Anchored = true,
        CanCollide = true,
        Name = "LobbySpawn"
    }

    -- Remove existing
    local existingSpawn = workspace:FindFirstChild("LobbySpawn")
    if existingSpawn then
        existingSpawn:Destroy()
    end

    local spawnLoc = Instance.new("SpawnLocation")
    spawnLoc.Name = "LobbySpawn"
    spawnLoc.Position = spawnParams.Position
    spawnLoc.Size = spawnParams.Size
    spawnLoc.Transparency = spawnParams.Transparency
    spawnLoc.CastShadow = spawnParams.CastShadow
    spawnLoc.Anchored = spawnParams.Anchored
    spawnLoc.CanCollide = spawnParams.CanCollide
    spawnLoc.Neutral = true
    spawnLoc.Enabled = true
    spawnLoc.TopSurface = Enum.SurfaceType.Smooth
    spawnLoc.BottomSurface = Enum.SurfaceType.Smooth
    spawnLoc.Parent = workspace

    -- Aggressive Decal Removal
    local function clean(child)
        if child:IsA("Decal") or child:IsA("Texture") then
            -- Use defer to ensure it's destroyed even if added next frame
            task.defer(function()
                if child.Parent then child:Destroy() end
            end)
        end
    end
    
    spawnLoc.ChildAdded:Connect(clean)
    for _, child in pairs(spawnLoc:GetChildren()) do clean(child) end

    -- Disable other spawns
    for _, child in pairs(workspace:GetDescendants()) do
        if child:IsA("SpawnLocation") and child ~= spawnLoc then
            child.Enabled = false
        end
    end

    print("[DefaultSpawn] Created safe holding spawn at " .. tostring(spawnParams.Position))
end

return DefaultSpawn
