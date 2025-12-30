-- LocalScript: ConsumableController.lua
-- Automatically handles logic for edible tools (Apple, Bread, etc.)
-- defined in BalanceConfig. This allows any Tool with a matching name to be eatable.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Player = Players.LocalPlayer
local Config = require(ReplicatedFirst:WaitForChild("Config"))
local BalanceConfig = require(ReplicatedFirst:WaitForChild("BalanceConfig"))

local ConsumableController = {}
local activeConnections = {}

-- Sound constants
local EAT_SOUND_ID = "rbxassetid://160212768"
local DRINK_SOUND_ID = "rbxassetid://4765792476"

local statsRemote = ReplicatedStorage:WaitForChild("StatsRemoteEvent")

-- Handle when a tool is equipped
local function onToolEquipped(tool)
    -- Check if this tool is a consumable
    local itemName = tool.Name
    local itemData = BalanceConfig.Consumables and BalanceConfig.Consumables[itemName]
    
    if not itemData then return end
    
    print("[ConsumableController] Equipped edible item: " .. itemName)
    
    -- Disconnect previous if exists (shouldn't happen on new equip instance but safe)
    if activeConnections[tool] then
        activeConnections[tool]:Disconnect()
    end
    
    -- Listen for activation (click)
    activeConnections[tool] = tool.Activated:Connect(function()
        if not tool.Parent then return end -- Safety
        
        -- Debounce locally
        if tool:GetAttribute("IsConsuming") then return end
        tool:SetAttribute("IsConsuming", true)
        
        -- Play sound
        local sound = Instance.new("Sound")
        sound.SoundId = itemData.sound or EAT_SOUND_ID
        sound.Volume = 1
        sound.Parent = tool.Handle or tool:FindFirstChildWhichIsA("BasePart") or Player.Character.Head
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
        
        -- Play Animation (generic hold up)
        local animator = Player.Character:FindFirstChild("Humanoid"):FindFirstChild("Animator")
        if animator then
            -- Create a simple animation on the fly or load id
            -- For MVP, we just play sound and wait duration
        end
        
        -- Send request to server
        statsRemote:FireServer("CONSUME_ITEM", itemName)
        
        -- Wait for duration then destroy locally (server should verify, but this gives instant feedback)
        -- In a robust system, server would remove item.
        task.wait(itemData.duration or 1)
        
        tool:Destroy()
        activeConnections[tool] = nil
    end)
end

local function onToolUnequipped(tool)
    if activeConnections[tool] then
        activeConnections[tool]:Disconnect()
        activeConnections[tool] = nil
    end
end

-- Monitor backpack and character
local function setupCharacter(char)
    -- Listen for tools being equipped (ChildAdded to Character)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            onToolEquipped(child)
        end
    end)
    
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            onToolUnequipped(child)
        end
    end)
end

function ConsumableController.init()
    print("[ConsumableController] Initialized")
    
    Player.CharacterAdded:Connect(setupCharacter)
    if Player.Character then
        setupCharacter(Player.Character)
    end
end

ConsumableController.init()
return ConsumableController
