-- LocalScript: CraftingGui.lua
-- Crafting interface for The Ember Games
-- Provides UI for crafting recipes and resource management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for remotes
local CraftRemoteFunction = ReplicatedStorage:WaitForChild("CraftRemoteFunction", 10)
local CraftRemoteEvent = ReplicatedStorage:WaitForChild("CraftRemoteEvent", 10)

local CraftingGui = {}
CraftingGui.craftingGui = nil
CraftingGui.isVisible = false
CraftingGui.playerInventory = {}
CraftingGui.currentCategory = "WEAPONS"
CraftingGui.isCrafting = false
CraftingGui.craftProgress = 0
CraftingGui.recipes = {}
CraftingGui.categories = {}

-- Category Icons
local CATEGORY_ICONS = {
    WEAPONS = "⚔️",
    AMMO = "🎯",
    TRAPS = "🪤",
    SURVIVAL = "🏕️",
    TOOLS = "🔧"
}

-- Rarity Colors
local RARITY_COLORS = {
    common = Color3.fromRGB(150, 150, 150),
    uncommon = Color3.fromRGB(50, 200, 50),
    rare = Color3.fromRGB(50, 100, 255),
    epic = Color3.fromRGB(200, 50, 200),
    legendary = Color3.fromRGB(255, 165, 0)
}

-- Create crafting UI
local function createCraftingUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CraftingInterface"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Dark overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.Visible = false
    overlay.Parent = screenGui
    
    -- Main Crafting Frame
    local craftingFrame = Instance.new("Frame")
    craftingFrame.Name = "CraftingFrame"
    craftingFrame.Size = UDim2.new(0, 700, 0, 500)
    craftingFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    craftingFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    craftingFrame.BorderSizePixel = 0
    craftingFrame.Visible = false
    craftingFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = craftingFrame
    
    -- Main stroke
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(80, 80, 90)
    mainStroke.Thickness = 2
    mainStroke.Parent = craftingFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = craftingFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔨 CRAFTING BENCH"
    titleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 22
    titleLabel.Parent = titleBar
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 35, 0, 35)
    closeButton.Position = UDim2.new(1, -42, 0, 7)
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Category Tabs
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Name = "CategoryFrame"
    categoryFrame.Size = UDim2.new(1, -20, 0, 40)
    categoryFrame.Position = UDim2.new(0, 10, 0, 55)
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.Parent = craftingFrame
    
    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.FillDirection = Enum.FillDirection.Horizontal
    categoryLayout.Padding = UDim.new(0, 5)
    categoryLayout.Parent = categoryFrame
    
    -- Recipe List Container
    local recipeListFrame = Instance.new("ScrollingFrame")
    recipeListFrame.Name = "RecipeListFrame"
    recipeListFrame.Size = UDim2.new(0.55, -15, 1, -110)
    recipeListFrame.Position = UDim2.new(0, 10, 0, 100)
    recipeListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    recipeListFrame.BorderSizePixel = 0
    recipeListFrame.ScrollBarThickness = 6
    recipeListFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    recipeListFrame.Parent = craftingFrame
    
    local recipeCorner = Instance.new("UICorner")
    recipeCorner.CornerRadius = UDim.new(0, 8)
    recipeCorner.Parent = recipeListFrame
    
    local recipeLayout = Instance.new("UIListLayout")
    recipeLayout.Padding = UDim.new(0, 5)
    recipeLayout.Parent = recipeListFrame
    
    local recipePadding = Instance.new("UIPadding")
    recipePadding.PaddingTop = UDim.new(0, 5)
    recipePadding.PaddingLeft = UDim.new(0, 5)
    recipePadding.PaddingRight = UDim.new(0, 5)
    recipePadding.Parent = recipeListFrame
    
    -- Details Panel
    local detailsFrame = Instance.new("Frame")
    detailsFrame.Name = "DetailsFrame"
    detailsFrame.Size = UDim2.new(0.45, -15, 1, -110)
    detailsFrame.Position = UDim2.new(0.55, 5, 0, 100)
    detailsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    detailsFrame.BorderSizePixel = 0
    detailsFrame.Parent = craftingFrame
    
    local detailsCorner = Instance.new("UICorner")
    detailsCorner.CornerRadius = UDim.new(0, 8)
    detailsCorner.Parent = detailsFrame
    
    -- Details content
    local detailsTitle = Instance.new("TextLabel")
    detailsTitle.Name = "DetailsTitle"
    detailsTitle.Size = UDim2.new(1, -20, 0, 30)
    detailsTitle.Position = UDim2.new(0, 10, 0, 10)
    detailsTitle.BackgroundTransparency = 1
    detailsTitle.Text = "Select a recipe"
    detailsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    detailsTitle.TextXAlignment = Enum.TextXAlignment.Left
    detailsTitle.Font = Enum.Font.GothamBold
    detailsTitle.TextSize = 18
    detailsTitle.Parent = detailsFrame
    
    local detailsDesc = Instance.new("TextLabel")
    detailsDesc.Name = "DetailsDesc"
    detailsDesc.Size = UDim2.new(1, -20, 0, 40)
    detailsDesc.Position = UDim2.new(0, 10, 0, 45)
    detailsDesc.BackgroundTransparency = 1
    detailsDesc.Text = ""
    detailsDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
    detailsDesc.TextXAlignment = Enum.TextXAlignment.Left
    detailsDesc.TextWrapped = true
    detailsDesc.Font = Enum.Font.Gotham
    detailsDesc.TextSize = 14
    detailsDesc.Parent = detailsFrame
    
    local ingredientsTitle = Instance.new("TextLabel")
    ingredientsTitle.Name = "IngredientsTitle"
    ingredientsTitle.Size = UDim2.new(1, -20, 0, 25)
    ingredientsTitle.Position = UDim2.new(0, 10, 0, 95)
    ingredientsTitle.BackgroundTransparency = 1
    ingredientsTitle.Text = "INGREDIENTS:"
    ingredientsTitle.TextColor3 = Color3.fromRGB(200, 200, 100)
    ingredientsTitle.TextXAlignment = Enum.TextXAlignment.Left
    ingredientsTitle.Font = Enum.Font.GothamBold
    ingredientsTitle.TextSize = 12
    ingredientsTitle.Parent = detailsFrame
    
    -- Replacing TextList with ScrollingFrame Container
    local ingredientsContainer = Instance.new("ScrollingFrame")
    ingredientsContainer.Name = "IngredientsContainer"
    ingredientsContainer.Size = UDim2.new(1, -20, 0, 100)
    ingredientsContainer.Position = UDim2.new(0, 10, 0, 125)
    ingredientsContainer.BackgroundTransparency = 1
    ingredientsContainer.BorderSizePixel = 0
    ingredientsContainer.Parent = detailsFrame
    
    local icLayout = Instance.new("UIListLayout")
    icLayout.Padding = UDim.new(0, 5)
    icLayout.Parent = ingredientsContainer
    
    local resultLabel = Instance.new("TextLabel")
    resultLabel.Name = "ResultLabel"
    resultLabel.Size = UDim2.new(1, -20, 0, 25)
    resultLabel.Position = UDim2.new(0, 10, 0, 210)
    resultLabel.BackgroundTransparency = 1
    resultLabel.Text = ""
    resultLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    resultLabel.TextXAlignment = Enum.TextXAlignment.Left
    resultLabel.Font = Enum.Font.GothamBold
    resultLabel.TextSize = 14
    resultLabel.Parent = detailsFrame
    
    -- Craft Progress Bar
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = UDim2.new(1, -20, 0, 20)
    progressFrame.Position = UDim2.new(0, 10, 1, -80)
    progressFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    progressFrame.BorderSizePixel = 0
    progressFrame.Visible = false
    progressFrame.Parent = detailsFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 5)
    progressCorner.Parent = progressFrame
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressFrame
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 5)
    progressFillCorner.Parent = progressFill
    
    -- Craft Button
    local craftButton = Instance.new("TextButton")
    craftButton.Name = "CraftButton"
    craftButton.Size = UDim2.new(1, -20, 0, 45)
    craftButton.Position = UDim2.new(0, 10, 1, -55)
    craftButton.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
    craftButton.Text = "🔨 CRAFT"
    craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    craftButton.Font = Enum.Font.GothamBold
    craftButton.TextSize = 18
    craftButton.Parent = detailsFrame
    
    local craftCorner = Instance.new("UICorner")
    craftCorner.CornerRadius = UDim.new(0, 8)
    craftCorner.Parent = craftButton
    
    -- Store references
    CraftingGui.craftingGui = screenGui
    CraftingGui.selectedRecipe = nil
    
    return screenGui
end

-- Create category tabs
local function createCategoryTabs()
    if not CraftingGui.craftingGui then return end
    
    local categoryFrame = CraftingGui.craftingGui.CraftingFrame.CategoryFrame
    
    -- Clear existing tabs
    for _, child in pairs(categoryFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for i, category in ipairs(CraftingGui.categories) do
        local tab = Instance.new("TextButton")
        tab.Name = category
        tab.Size = UDim2.new(0, 100, 1, 0)
        tab.BackgroundColor3 = category == CraftingGui.currentCategory and Color3.fromRGB(60, 60, 70) or Color3.fromRGB(35, 35, 40)
        tab.Text = (CATEGORY_ICONS[category] or "📦") .. " " .. category
        tab.TextColor3 = Color3.fromRGB(255, 255, 255)
        tab.Font = Enum.Font.GothamBold
        tab.TextSize = 12
        tab.LayoutOrder = i
        tab.Parent = categoryFrame
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tab
        
        tab.MouseButton1Click:Connect(function()
            CraftingGui.currentCategory = category
            createCategoryTabs() -- Refresh tab highlighting
            populateRecipeList()
        end)
    end
end

-- Check can craft
local function canCraftRecipe(recipeId)
    local recipeData = CraftingGui.recipes[recipeId]
    if not recipeData then return false end
    
    for _, ing in ipairs(recipeData.ingredients) do
        local count = CraftingGui.playerInventory[ing.itemName] or 0
        if count < ing.amount then
            return false
        end
    end
    return true
end

-- Populate recipe list
local function populateRecipeList()
    if not CraftingGui.craftingGui then return end
    
    local recipeListFrame = CraftingGui.craftingGui.CraftingFrame.RecipeListFrame
    
    -- Clear existing recipes
    for _, child in pairs(recipeListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Add recipes for current category
    local recipeCount = 0
    for recipeId, recipeData in pairs(CraftingGui.recipes) do
        if recipeData.category == CraftingGui.currentCategory then
            recipeCount = recipeCount + 1
            
            local canCraft = canCraftRecipe(recipeId)
            
            local recipeButton = Instance.new("TextButton")
            recipeButton.Name = recipeId
            recipeButton.Size = UDim2.new(1, -10, 0, 60)
            recipeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            recipeButton.Text = ""
            recipeButton.LayoutOrder = recipeCount
            recipeButton.Parent = recipeListFrame
            
            local recipeCorner = Instance.new("UICorner")
            recipeCorner.CornerRadius = UDim.new(0, 6)
            recipeCorner.Parent = recipeButton
            
            -- Can Craft Stroke
            if canCraft then
                local s = Instance.new("UIStroke")
                s.Color = Color3.fromRGB(50, 200, 50) -- Green
                s.Thickness = 2
                s.Parent = recipeButton
            end
            
            -- Recipe name
            local recipeTitle = Instance.new("TextLabel")
            recipeTitle.Size = UDim2.new(1, -10, 0, 25)
            recipeTitle.Position = UDim2.new(0, 10, 0, 5)
            recipeTitle.BackgroundTransparency = 1
            recipeTitle.Text = recipeData.name
            recipeTitle.TextColor3 = RARITY_COLORS[recipeData.rarity or "common"] or Color3.fromRGB(255, 255, 255)
            recipeTitle.TextXAlignment = Enum.TextXAlignment.Left
            recipeTitle.Font = Enum.Font.GothamBold
            recipeTitle.TextSize = 14
            recipeTitle.Parent = recipeButton
            
            -- Quick info
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, -10, 0, 20)
            infoLabel.Position = UDim2.new(0, 10, 0, 28)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = "Creates: " .. recipeData.result.amount .. "x " .. recipeData.result.itemName
            infoLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.Font = Enum.Font.Gotham
            infoLabel.TextSize = 12
            infoLabel.Parent = recipeButton
            
            -- Craft time
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Size = UDim2.new(0, 50, 0, 20)
            timeLabel.Position = UDim2.new(1, -55, 0, 5)
            timeLabel.BackgroundTransparency = 1
            timeLabel.Text = "⏱️ " .. (recipeData.craftTime or 3) .. "s"
            timeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            timeLabel.Font = Enum.Font.Gotham
            timeLabel.TextSize = 11
            timeLabel.Parent = recipeButton
            
            -- Hover effect
            recipeButton.MouseEnter:Connect(function()
                TweenService:Create(recipeButton, TweenInfo.new(0.1), {
                    BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                }):Play()
            end)
            
            recipeButton.MouseLeave:Connect(function()
                TweenService:Create(recipeButton, TweenInfo.new(0.1), {
                    BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                }):Play()
            end)
            
            -- Click to select
            recipeButton.MouseButton1Click:Connect(function()
                CraftingGui:selectRecipe(recipeId, recipeData)
            end)
        end
    end
    
    -- Update canvas size
    recipeListFrame.CanvasSize = UDim2.new(0, 0, 0, recipeCount * 65 + 10)
end

-- Select a recipe
function CraftingGui:selectRecipe(recipeId, recipeData)
    CraftingGui.selectedRecipe = recipeId
    
    local detailsFrame = CraftingGui.craftingGui.CraftingFrame.DetailsFrame
    
    -- Update title
    detailsFrame.DetailsTitle.Text = recipeData.name
    detailsFrame.DetailsTitle.TextColor3 = RARITY_COLORS[recipeData.rarity or "common"]
    
    -- Update description
    detailsFrame.DetailsDesc.Text = recipeData.description or "No description available."
    
    -- Update ingredients (Visual List)
    local container = detailsFrame.IngredientsContainer
    for _, c in pairs(container:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    
    for _, ingredient in ipairs(recipeData.ingredients) do
        local myCount = CraftingGui.playerInventory[ingredient.itemName] or 0
        local hasEnough = myCount >= ingredient.amount
        
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 25)
        row.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        row.BorderSizePixel = 0
        row.Parent = container
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = row
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -70, 1, 0)
        nameLabel.Position = UDim2.new(0, 5, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ingredient.itemName
        nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 12
        nameLabel.Parent = row
        
        local countLabel = Instance.new("TextLabel")
        countLabel.Size = UDim2.new(0, 60, 1, 0)
        countLabel.Position = UDim2.new(1, -65, 0, 0)
        countLabel.BackgroundTransparency = 1
        countLabel.Text = myCount .. "/" .. ingredient.amount
        countLabel.TextColor3 = hasEnough and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        countLabel.TextXAlignment = Enum.TextXAlignment.Right
        countLabel.Font = Enum.Font.GothamBold
        countLabel.TextSize = 12
        countLabel.Parent = row

        -- Tooltip
        row.MouseEnter:Connect(function()
             -- Show simple tooltip
             nameLabel.Text = ingredient.itemName .. " (Found in World)" -- Placeholder text
             row.BackgroundColor3 = Color3.fromRGB(50,50,50)
        end)
        row.MouseLeave:Connect(function()
            nameLabel.Text = ingredient.itemName
            row.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        end)
    end
    
    -- Update result
    detailsFrame.ResultLabel.Text = "➡️ Creates: " .. recipeData.result.amount .. "x " .. recipeData.result.itemName
    
    print("[CraftingGui] Selected: " .. recipeData.name)
end

-- Start crafting
function CraftingGui:startCraft()
    if not CraftingGui.selectedRecipe then
        print("[CraftingGui] No recipe selected")
        return
    end
    
    if CraftingGui.isCrafting then
        print("[CraftingGui] Already crafting")
        return
    end
    
    print("[CraftingGui] Starting craft: " .. CraftingGui.selectedRecipe)
    
    if CraftRemoteEvent then
        CraftRemoteEvent:FireServer("START_CRAFT", CraftingGui.selectedRecipe)
    end
end

-- Cancel crafting
function CraftingGui:cancelCraft()
    if CraftRemoteEvent then
        CraftRemoteEvent:FireServer("CANCEL_CRAFT")
    end
end

-- Show crafting interface
function CraftingGui:showCraftingInterface()
    if CraftingGui.craftingGui then
        CraftingGui.craftingGui.Overlay.Visible = true
        CraftingGui.craftingGui.CraftingFrame.Visible = true
        CraftingGui.isVisible = true
        
        -- Fetch latest recipes
        CraftingGui:fetchRecipes()
    end
end

-- Hide crafting interface
function CraftingGui:hideCraftingInterface()
    if CraftingGui.craftingGui then
        CraftingGui.craftingGui.Overlay.Visible = false
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

-- Fetch recipes from server
function CraftingGui:fetchRecipes()
    if CraftRemoteFunction then
        local recipes = CraftRemoteFunction:InvokeServer("GET_RECIPES")
        local categories = CraftRemoteFunction:InvokeServer("GET_CATEGORIES")
        local inventory = CraftRemoteFunction:InvokeServer("GET_INVENTORY") -- NEW: Fetch inventory
        
        if recipes then
            CraftingGui.recipes = recipes
        end
        
        if categories then
            CraftingGui.categories = categories
        end
        
        if inventory then
            CraftingGui.playerInventory = inventory
        end
        
        createCategoryTabs()
        populateRecipeList()
    end
end

-- Handle server events
local function onServerEvent(action, ...)
    local args = {...}
    
    if action == "CRAFT_STARTED" then
        local recipeId = args[1]
        local craftTime = args[2]
        
        CraftingGui.isCrafting = true
        
        local detailsFrame = CraftingGui.craftingGui.CraftingFrame.DetailsFrame
        detailsFrame.ProgressFrame.Visible = true
        detailsFrame.CraftButton.Text = "⏳ CRAFTING..."
        detailsFrame.CraftButton.BackgroundColor3 = Color3.fromRGB(100, 100, 50)
        
        -- Animate progress bar
        TweenService:Create(detailsFrame.ProgressFrame.Fill, TweenInfo.new(craftTime), {
            Size = UDim2.new(1, 0, 1, 0)
        }):Play()
        
    elseif action == "CRAFT_COMPLETE" then
        local recipeId = args[1]
        local itemName = args[2]
        local amount = args[3]
        
        CraftingGui.isCrafting = false
        
        local detailsFrame = CraftingGui.craftingGui.CraftingFrame.DetailsFrame
        detailsFrame.ProgressFrame.Visible = false
        detailsFrame.ProgressFrame.Fill.Size = UDim2.new(0, 0, 1, 0)
        detailsFrame.CraftButton.Text = "✅ CRAFTED!"
        detailsFrame.CraftButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        
        -- Reset button after delay
        task.delay(1.5, function()
            detailsFrame.CraftButton.Text = "🔨 CRAFT"
            detailsFrame.CraftButton.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
        end)
        
        print("[CraftingGui] Crafted " .. amount .. "x " .. itemName)
        
    elseif action == "CRAFT_CANCELLED" then
        CraftingGui.isCrafting = false
        
        local detailsFrame = CraftingGui.craftingGui.CraftingFrame.DetailsFrame
        detailsFrame.ProgressFrame.Visible = false
        detailsFrame.ProgressFrame.Fill.Size = UDim2.new(0, 0, 1, 0)
        detailsFrame.CraftButton.Text = "🔨 CRAFT"
        detailsFrame.CraftButton.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
        
    elseif action == "CRAFT_ERROR" then
        local errorMsg = args[1]
        
        local detailsFrame = CraftingGui.craftingGui.CraftingFrame.DetailsFrame
        detailsFrame.CraftButton.Text = "❌ " .. (errorMsg or "Error")
        detailsFrame.CraftButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        
        task.delay(2, function()
            detailsFrame.CraftButton.Text = "🔨 CRAFT"
            detailsFrame.CraftButton.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
        end)
    end
end

-- Initialize CraftingGui
function CraftingGui.init()
    print("[CraftingGui] Initializing...")
    
    -- Create the UI
    createCraftingUI()
    
    -- Connect close button
    if CraftingGui.craftingGui then
        local closeButton = CraftingGui.craftingGui.CraftingFrame.TitleBar.CloseButton
        closeButton.MouseButton1Click:Connect(function()
            CraftingGui:hideCraftingInterface()
        end)
        
        -- Connect craft button
        local craftButton = CraftingGui.craftingGui.CraftingFrame.DetailsFrame.CraftButton
        craftButton.MouseButton1Click:Connect(function()
            CraftingGui:startCraft()
        end)
        
        -- Click overlay to close
        CraftingGui.craftingGui.Overlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                CraftingGui:hideCraftingInterface()
            end
        end)
    end
    
    -- Connect server events
    if CraftRemoteEvent then
        CraftRemoteEvent.OnClientEvent:Connect(onServerEvent)
    end
    
    -- Setup keyboard input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Toggle crafting interface with 'C' key
        if input.KeyCode == Enum.KeyCode.C then
            CraftingGui:toggleCraftingInterface()
        end
        
        -- Escape to close
        if input.KeyCode == Enum.KeyCode.Escape and CraftingGui.isVisible then
            CraftingGui:hideCraftingInterface()
        end
    end)
    
    print("[CraftingGui] Initialized successfully")
end

-- Initialize the CraftingGui when the module is loaded
CraftingGui.init()

return CraftingGui