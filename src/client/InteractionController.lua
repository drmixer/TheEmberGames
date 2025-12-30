-- ModuleScript: InteractionController.lua (Client)
-- Handles client-side interactions and ProximityPrompt customizations
-- Ensures premium feel for interactions

local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local InteractionController = {}

local function onPromptShown(prompt, inputType)
    if prompt.Style == Enum.ProximityPromptStyle.Default then 
        return 
    end
    -- Custom UI logic would go here
end

local function onPromptHidden(prompt)
    -- Custom UI hide logic
end

local function onPromptTriggered(prompt, player)
    if player == Players.LocalPlayer then
        -- Play local feedback sound or effect
        print("[InteractionController] Interacted with: " .. (prompt.ObjectText or prompt.ActionText))
    end
end

function InteractionController:init()
    print("InteractionController initialized")
    
    -- Global Prompt Events
    ProximityPromptService.PromptShown:Connect(onPromptShown)
    ProximityPromptService.PromptHidden:Connect(onPromptHidden)
    ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
    
    -- Listen for Loot Pickups from server (Feedback)
    local lootRemote = ReplicatedStorage:FindFirstChild("LootRemote")
    if lootRemote then
        lootRemote.OnClientEvent:Connect(function(action, itemData)
            if action == "PICKUP" and itemData then
                -- Could show flying item animation here
                print("Picked up: " .. itemData.id)
            elseif action == "INVENTORY_FULL" then
                -- Show warning
                print("Inventory Full!")
            end
        end)
    end
end

return InteractionController
