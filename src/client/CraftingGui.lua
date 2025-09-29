-- LocalScript: CraftingGui.lua
-- Crafting interface for The Ember Games
-- Provides UI for crafting recipes and resource management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local CraftRemoteFunction = ReplicatedStorage:WaitForChild("CraftRemoteFunction")

local CraftingGui = {}
CraftingGui.craftingGui = nil
CraftingGui.isVisible = false
CraftingGui.playerInventory = {}

-- Create crafting UI
local function createCraftingUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CraftingInterface"
    screenGui.Parent = PlayerGui
    
    -- Crafting Frame
    local craftingFrame = Instance.new("Frame")
    craftingFrame.Name = "CraftingFrame"
    craftingFrame.Size = UDim2.new(0, 600, 0, 500)
    craftingFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    craftingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    craftingFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    craftingFrame.Visible = false
    craftingFrame.Parent = screenGui
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "CRAFTING BENCH"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    titleLabel.Parent = craftingFrame
    
    -- Recipe List Container
    local recipeListFrame = Instance.new("ScrollingFrame")
    recipeListFrame.Name = "RecipeListFrame"
    recipeListFrame.Size = UDim2.new(0.6, -10, 1, -70)
    recipeListFrame.Position = UDim2.new(0, 5, 0, 55)
    recipeListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    recipeListFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
    recipeListFrame.ScrollBarThickness = 8
    recipeListFrame.Parent = craftingFrame
    
    -- Inventory Display
    local inventoryFrame = Instance.new("Frame")
    inventoryFrame.Name = "InventoryFrame"
    inventoryFrame.Size = UDim2.new(0.4, -10, 1, -70)
    inventoryFrame.Position = UDim2.new(0.6, 5, 0, 55)
    inventoryFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    inventoryFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
    inventoryFrame.Parent = craftingFrame
    
    local invTitle = Instance.new("TextLabel")
    invTitle.Name = "InvTitle"
    invTitle.Size = UDim2.new(1, 0, 0, 30)
    invTitle.Position = UDim2.new(0, 0, 0, 0)
    invTitle.BackgroundTransparency = 1
    invTitle.Text = "INVENTORY"
    invTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    invTitle.Font = Enum.Font.Gotham
    invTitle.TextScaled = true
    invTitle.Parent = inventoryFrame
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 30)
    closeButton.Position = UDim2.new(1, -45, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    closeButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextScaled = true
    closeButton.Parent = craftingFrame
    
    -- Store references
    CraftingGui.craftingGui = screenGui
    
    return screenGui
end

-- Populate recipe list
local function populateRecipeList()
    if not CraftingGui.craftingGui then return end
    
    local recipeListFrame = CraftingGui.craftingGui.CraftingFrame.RecipeListFrame
    
    -- Clear existing recipes
    for _, child in pairs(recipeListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add recipes
    local recipeY = 0
    local recipes = require(script.Parent.shared.CraftingRecipes).recipes
    
    for recipeName, recipeData in pairs(recipes) do
        local recipeButton = Instance.new("TextButton")
        recipeButton.Name = recipeName
        recipeButton.Size = UDim2.new(1, -10, 0, 80)
        recipeButton.Position = UDim2.new(0, 5, 0, recipeY)
        recipeY = recipeY + 85
        recipeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        recipeButton.BorderColor3 = Color3.fromRGB(80, 80, 80)
        recipeButton.Text = ""
        recipeButton.Parent = recipeListFrame
        
        -- Recipe name
        local recipeTitle = Instance.new("TextLabel")
        recipeTitle.Name = "RecipeTitle"
        recipeTitle.Size = UDim2.new(1, 0, 0, 20)
        recipeTitle.Position = UDim2.new(0, 5, 0, 5)
        recipeTitle.BackgroundTransparency = 1
        recipeTitle.Text = recipeData.name
        recipeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        recipeTitle.Font = Enum.Font.GothamBold
        recipeTitle.TextScaled = true
        recipeTitle.Parent = recipeButton
        
        -- Ingredients list
        local ingredientsLabel = Instance.new("TextLabel")
        ingredientsLabel.Name = "IngredientsLabel"
        ingredientsLabel.Size = UDim2.new(1, 0, 0, 30)
        ingredientsLabel.Position = UDim2.new(0, 5, 0, 25)
        ingredientsLabel.BackgroundTransparency = 1
        ingredientsLabel.Text = "Ingredients: "
        ingredientsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        ingredientsLabel.Font = Enum.Font.Gotham
        ingredientsLabel.TextScaled = true
        ingredientsLabel.TextWrapped = true
        ingredientsLabel.Parent = recipeButton
        
        local ingText = ""
        for i, ingredient in ipairs(recipeData.ingredients) do
            ingText = ingText .. ingredient.itemName .. " x" .. ingredient.amount
            if i < #recipeData.ingredients then
                ingText = ingText .. ", "
            end
        end
        ingredientsLabel.Text = "Ingredients: " .. ingText
        
        -- Result
        local resultLabel = Instance.new("TextLabel")
        resultLabel.Name = "ResultLabel"
        resultLabel.Size = UDim2.new(1, 0, 0, 20)
        resultLabel.Position = UDim2.new(0, 5, 0, 55)
        resultLabel.BackgroundTransparency = 1
        resultLabel.Text = "Creates: " .. recipeData.result.itemName .. " x" .. recipeData.result.amount
        resultLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
        resultLabel.Font = Enum.Font.Gotham
        resultLabel.TextScaled = true
        resultLabel.Parent = recipeButton
        
        -- Craft button
        local craftButton = Instance.new("TextButton")
        craftButton.Name = "CraftButton"
        craftButton.Size = UDim2.new(0, 80, 0, 25)
        craftButton.Position = UDim2.new(1, -85, 0, 5)
        craftButton.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
        craftButton.BorderColor3 = Color3.fromRGB(100, 200, 100)
        craftButton.Text = "CRAFT"
        craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        craftButton.Font = Enum.Font.GothamBold
        craftButton.TextScaled = true
        craftButton.Parent = recipeButton
        
        -- Connect craft button
        craftButton.MouseButton1Click:Connect(function()
            CraftingGui:attemptCraft(recipeName)
        end)
    end
    
    recipeListFrame.CanvasSize = UDim2.new(0, 0, 0, recipeY)
end

-- Show crafting interface
function CraftingGui:showCraftingInterface()
    if CraftingGui.craftingGui then
        CraftingGui.craftingGui.CraftingFrame.Visible = true
        CraftingGui.isVisible = true
        populateRecipeList() -- Refresh recipe list
    end
end

-- Hide crafting interface
function CraftingGui:hideCraftingInterface()
    if CraftingGui.craftingGui then
        CraftingGui.craftingGui.CraftingFrame.Visible = false
        CraftingGui.isVisible = false
    end
end

-- Toggle crafting interface
function CraftingGui:toggleCraftingInterface()
    if CraftingGui.isVisible then
        CraftingGui:hideCraftingInterface()
    else
        CraftingGui:showCraftingInterface()
    end
end

-- Attempt to craft an item
function CraftingGui:attemptCraft(recipeName)
    -- Call server to attempt crafting
    local success, message = CraftRemoteFunction:InvokeServer(recipeName)
    
    if success then
        print("Successfully crafted: " .. recipeName)
        -- In a real implementation, this would update the player's inventory
        -- and play crafting completion effects
    else
        print("Failed to craft: " .. message)
        -- Show error message to player
    end
end

-- Initialize CraftingGui
function CraftingGui.init()
    print("CraftingGui initialized")
    
    -- Create the UI
    createCraftingUI()
    
    -- Connect close button
    if CraftingGui.craftingGui then
        local closeButton = CraftingGui.craftingGui.CraftingFrame.CloseButton
        closeButton.MouseButton1Click:Connect(function()
            CraftingGui:hideCraftingInterface()
        end)
    end
    
    -- Setup keyboard input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Toggle crafting interface with 'C' key
        if input.KeyCode == Enum.KeyCode.C then
            CraftingGui:toggleCraftingInterface()
        end
    end)
    
    print("CraftingGui initialized and connected to events")
end

-- Initialize the CraftingGui when the module is loaded
CraftingGui.init()

return CraftingGui