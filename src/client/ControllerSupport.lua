-- ModuleScript: ControllerSupport.lua
-- Controller support for The Ember Games
-- Handles gamepad input and UI adjustments for controllers

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local ControllerSupport = {}
ControllerSupport.isUsingController = false
ControllerSupport.activeBindings = {}

-- Controller button mapping
local ControllerButtons = {
    A = Enum.KeyCode.ButtonA,
    B = Enum.KeyCode.ButtonB,
    X = Enum.KeyCode.ButtonX,
    Y = Enum.KeyCode.ButtonY,
    LB = Enum.KeyCode.ButtonL1,
    RB = Enum.KeyCode.ButtonR1,
    LT = Enum.KeyCode.ButtonL2,
    RT = Enum.KeyCode.ButtonR2,
    LeftStick = Enum.KeyCode.ButtonL3,
    RightStick = Enum.KeyCode.ButtonR3,
    DPadUp = Enum.KeyCode.DPadUp,
    DPadDown = Enum.KeyCode.DPadDown,
    DPadLeft = Enum.KeyCode.DPadLeft,
    DPadRight = Enum.KeyCode.DPadRight,
    Start = Enum.KeyCode.ButtonStart,
    Select = Enum.KeyCode.ButtonSelect
}

-- Initialize controller support
function ControllerSupport:init()
    print("ControllerSupport initialized")
    
    -- Detect if player is using a controller
    UserInputService.LastInputTypeChanged:Connect(function()
        ControllerSupport:checkInputType()
    end)
    
    ControllerSupport:checkInputType()
    
    -- Setup controller-specific bindings
    ControllerSupport:setupControllerBindings()
    
    print("Controller support initialized")
end

-- Check input type and adjust UI accordingly
function ControllerSupport:checkInputType()
    local inputType = UserInputService:GetLastInputType()
    
    if inputType == Enum.UserInputType.Gamepad1 or 
       inputType == Enum.UserInputType.Gamepad2 or 
       inputType == Enum.UserInputType.Gamepad3 or 
       inputType == Enum.UserInputType.Gamepad4 then
        ControllerSupport.isUsingController = true
        ControllerSupport:applyControllerUI()
        print("Controller detected - adjusting UI")
    else
        ControllerSupport.isUsingController = false
        ControllerSupport:applyKeyboardUI()
        print("Keyboard/Mouse detected - adjusting UI")
    end
end

-- Apply controller-friendly UI adjustments
function ControllerSupport:applyControllerUI()
    -- Show on-screen prompts/instructions for controller users
    ControllerSupport:showControllerPrompts()
end

-- Apply keyboard/mouse UI adjustments
function ControllerSupport:applyKeyboardUI()
    -- Hide controller prompts
    ControllerSupport:hideControllerPrompts()
end

-- Show controller prompts
function ControllerSupport:showControllerPrompts()
    -- This would create temporary UI elements showing current controls
    -- For MVP, we'll just log what's available
    print("Controller mode active:")
    print("- Left Stick: Move")
    print("- Right Stick: Look")
    print("- A: Jump")
    print("- X: Interact/Craft")
    print("- Y: Use Item")
    print("- B: Cancel/Close")
    print("- LB/RB: Cycle Weapons")
    print("- LT/RT: Aim/Shoot (if ranged weapons implemented)")
    print("- Start: Pause Menu")
    print("- D-Pad: Quick Menu Access")
end

-- Hide controller prompts
function ControllerSupport:hideControllerPrompts()
    -- Hide any controller-specific UI elements
end

-- Setup controller-specific action bindings
function ControllerSupport:setupControllerBindings()
    -- Bind actions that would work well on controller
    
    -- Movement is handled by Roblox automatically
    
    -- Jump
    ContextActionService:BindAction("ControllerJump", 
        function(actionName, inputState, inputObject)
            -- Jump is handled by Roblox character movement
        end, 
        false, Enum.KeyCode.ButtonA)
    
    -- Use item (mapped to Y button)
    ContextActionService:BindAction("ControllerUseItem", 
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                -- In a full implementation, this would use the current item
                -- For now, we'll just trigger a generic "use" action
                print("Controller: Use item action")
            end
        end, 
        false, ControllerButtons.Y)
    
    -- Inventory toggle (mapped to X button)
    ContextActionService:BindAction("ControllerInventory", 
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                -- Toggle inventory UI
                local PlayerGui = Player:WaitForChild("PlayerGui")
                local inventoryGui = PlayerGui:FindFirstChild("InventoryInterface")
                if inventoryGui then
                    local frame = inventoryGui:FindFirstChild("InventoryFrame")
                    if frame then
                        frame.Visible = not frame.Visible
                    end
                end
            end
        end, 
        false, ControllerButtons.X)
    
    -- Crafting toggle (mapped to RB)
    ContextActionService:BindAction("ControllerCrafting", 
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                -- Toggle crafting UI
                local PlayerGui = Player:WaitForChild("PlayerGui")
                local craftingGui = PlayerGui:FindFirstChild("CraftingInterface")
                if craftingGui then
                    local frame = craftingGui:FindFirstChild("CraftingFrame")
                    if frame then
                        frame.Visible = not frame.Visible
                    end
                end
            end
        end, 
        false, ControllerButtons.RB)
    
    -- Cycle weapons (mapped to D-Pad)
    ContextActionService:BindAction("ControllerNextWeapon", 
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                -- In a full implementation, this would cycle forward through weapons
                print("Controller: Next weapon")
            end
        end, 
        false, ControllerButtons.DPadRight)
    
    ContextActionService:BindAction("ControllerPrevWeapon", 
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                -- In a full implementation, this would cycle backward through weapons
                print("Controller: Previous weapon")
            end
        end, 
        false, ControllerButtons.DPadLeft)
    
    -- Toggle Emotes (mapped to LB)
    ContextActionService:BindAction("ControllerEmotes", 
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                -- Toggle emote wheel
                local PlayerGui = Player:WaitForChild("PlayerGui")
                local emoteGui = PlayerGui:FindFirstChild("EmoteWheel")
                if emoteGui then
                    local frame = emoteGui:FindFirstChild("EmoteWheelFrame")
                    if frame then
                        frame.Visible = not frame.Visible
                    end
                end
            end
        end, 
        false, ControllerButtons.LB)
    
    print("Controller bindings set up")
end

-- Cleanup function for when the module is destroyed
function ControllerSupport:cleanup()
    -- Unbind all actions
    for actionName, _ in pairs(ControllerSupport.activeBindings) do
        ContextActionService:UnbindAction(actionName)
    end
end

-- Initialize ControllerSupport when the module is loaded
ControllerSupport:init()

return ControllerSupport