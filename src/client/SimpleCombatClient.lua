-- LocalScript: SimpleCombatClient.lua
-- Client-side combat controller with visual feedback
-- SIMPLE and WORKING

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local SimpleCombatClient = {}
SimpleCombatClient.attackCooldown = 0
SimpleCombatClient.attackSpeed = 0.4 -- seconds

-- Wait for remote
local function getRemote()
    return ReplicatedStorage:WaitForChild("CombatRemote", 10)
end

-- Camera shake effect
local function shakeCamera(intensity, duration)
    task.spawn(function()
        local startTime = tick()
        local originalCFrame = Camera.CFrame
        
        while tick() - startTime < duration do
            local offset = Vector3.new(
                (math.random() - 0.5) * intensity,
                (math.random() - 0.5) * intensity,
                0
            )
            Camera.CFrame = Camera.CFrame * CFrame.new(offset)
            task.wait()
        end
    end)
end

-- Create hit marker UI
local function showHitMarker(killed)
    local gui = Player:WaitForChild("PlayerGui")
    
    local marker = Instance.new("Frame")
    marker.Name = "HitMarker"
    marker.Size = UDim2.new(0, 50, 0, 50)
    marker.Position = UDim2.new(0.5, -25, 0.5, -25)
    marker.BackgroundTransparency = 1
    marker.Parent = gui
    
    -- Create X shape with lines
    local color = killed and Color3.new(1, 0.2, 0.2) or Color3.new(1, 1, 1)
    
    for i = 1, 2 do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 30, 0, 3)
        line.Position = UDim2.new(0.5, -15, 0.5, -1.5)
        line.BackgroundColor3 = color
        line.BorderSizePixel = 0
        line.Rotation = i == 1 and 45 or -45
        line.Parent = marker
    end
    
    -- Fade out
    task.delay(0.2, function()
        TweenService:Create(marker, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 80, 0, 80),
            Position = UDim2.new(0.5, -40, 0.5, -40)
        }):Play()
        
        for _, child in pairs(marker:GetChildren()) do
            TweenService:Create(child, TweenInfo.new(0.3), {
                BackgroundTransparency = 1
            }):Play()
        end
        
        task.delay(0.3, function()
            marker:Destroy()
        end)
    end)
end

-- Show damage number at position
local function showDamageNumber(position, damage, killed)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.Adornee = nil
    billboardGui.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(damage)
    label.TextColor3 = killed and Color3.new(1, 0.2, 0.2) or Color3.new(1, 0.9, 0.3)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.Parent = billboardGui
    
    -- Create attachment at world position
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.5, 0.5, 0.5)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = workspace
    
    billboardGui.Adornee = part
    billboardGui.Parent = part
    
    -- Animate upward and fade
    task.spawn(function()
        for i = 1, 20 do
            part.Position = part.Position + Vector3.new(0, 0.1, 0)
            label.TextTransparency = i / 20
            label.TextStrokeTransparency = 0.5 + (i / 40)
            task.wait(0.03)
        end
        part:Destroy()
    end)
end

-- Swing weapon visually
local function swingWeapon()
    local char = Player.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end
    
    -- Quick swing animation
    task.spawn(function()
        local originalCF = handle.CFrame
        
        -- Swing forward
        for i = 1, 5 do
            handle.CFrame = handle.CFrame * CFrame.Angles(math.rad(-12), 0, math.rad(4))
            task.wait(0.02)
        end
        
        -- Return
        for i = 1, 10 do
            handle.CFrame = handle.CFrame * CFrame.Angles(math.rad(6), 0, math.rad(-2))
            task.wait(0.02)
        end
    end)
end

-- Perform attack
function SimpleCombatClient:attack()
    local now = tick()
    if now - self.attackCooldown < self.attackSpeed then return end
    self.attackCooldown = now
    
    -- Visual feedback immediately (responsive feel)
    shakeCamera(0.3, 0.1)
    swingWeapon()
    
    -- Tell server we attacked
    local remote = getRemote()
    if remote then
        remote:FireServer("ATTACK")
    end
end

-- Initialize
function SimpleCombatClient.init()
    print("[SimpleCombatClient] Initializing...")
    
    -- Input handling
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Left mouse click = attack
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            SimpleCombatClient:attack()
        end
    end)
    
    -- Handle server responses
    local remote = getRemote()
    if remote then
        remote.OnClientEvent:Connect(function(action, ...)
            local args = {...}
            
            if action == "HIT" then
                local targetName = args[1]
                local damage = args[2]
                local killed = args[3]
                
                showHitMarker(killed)
                
                -- Find target position for damage number
                local target = workspace:FindFirstChild(targetName)
                if target and target:FindFirstChild("HumanoidRootPart") then
                    showDamageNumber(target.HumanoidRootPart.Position, damage, killed)
                end
                
                if killed then
                    print("[Combat] You killed " .. targetName .. "!")
                end
                
            elseif action == "MISS" then
                -- Could add miss sound here
                
            elseif action == "ATTACK_EFFECT" then
                -- Another player attacked - could show their swing
            end
        end)
    end
    
    print("[SimpleCombatClient] Ready! Left-click to attack.")
end

-- Auto-initialize
SimpleCombatClient.init()

return SimpleCombatClient
