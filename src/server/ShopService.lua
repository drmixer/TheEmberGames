-- ModuleScript: ShopService.lua (Server)
-- Handles premium cosmetic purchases with Robux

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local ShopService = {}
ShopService.datastoreEnabled = false

-- DataStore reference (wrapped in pcall for Studio testing)
local ShopDataStore
local success, err = pcall(function()
    ShopDataStore = DataStoreService:GetDataStore("EmberGames_Shop_v1")
end)

if success then
    ShopService.datastoreEnabled = true
else
    warn("[ShopService] DataStore not available (Studio mode)")
end

-- Shop items (would be configured in production)
local SHOP_ITEMS = {
    -- Premium currency bundle (Embers)
    currency = {
        { id = "embers_100", name = "100 Embers", embers = 100, robux = 49, gamePassId = nil },
        { id = "embers_500", name = "550 Embers", embers = 550, robux = 199, gamePassId = nil },
        { id = "embers_1000", name = "1200 Embers", embers = 1200, robux = 399, gamePassId = nil },
        { id = "embers_5000", name = "6500 Embers", embers = 6500, robux = 1699, gamePassId = nil },
    },
    
    -- Featured items (rotating)
    featured = {
        { id = "trail_phoenix", name = "Phoenix Trail", type = "trail", embers = 500, rarity = "Legendary" },
        { id = "pose_champion", name = "Champion Pose", type = "pose", embers = 300, rarity = "Epic" },
    },
    
    -- Daily items
    daily = {
        { id = "trail_ice_sale", name = "Frozen Path", type = "trail", embers = 150, originalEmbers = 250, rarity = "Rare" },
        { id = "outfit_career", name = "Career Tribute", type = "outfit", embers = 200, originalEmbers = 350, rarity = "Rare" },
    },
    
    -- Weekly items
    weekly = {
        { id = "bundle_starter", name = "Starter Bundle", type = "bundle", embers = 800, originalEmbers = 1500, items = {"trail_ember", "pose_salute", "outfit_default"} },
    },
    
    -- Battle Pass
    battlePass = {
        { id = "battlepass_season1", name = "Season 1 Battle Pass", embers = 950, robuxAlt = 950 },
    },
}

-- Player shop data cache
local playerShopData = {}

-- Load player shop data
function ShopService:loadPlayerData(player)
    -- If DataStore not available, use defaults
    if not ShopService.datastoreEnabled or not ShopDataStore then
        playerShopData[player.UserId] = {
            embers = 0,
            purchaseHistory = {},
            hasBattlePass = false,
        }
        return playerShopData[player.UserId]
    end
    
    local key = "Shop_" .. player.UserId
    
    local success, data = pcall(function()
        return ShopDataStore:GetAsync(key)
    end)
    
    if success and data then
        playerShopData[player.UserId] = data
    else
        playerShopData[player.UserId] = {
            embers = 0,
            purchaseHistory = {},
            hasBattlePass = false,
        }
    end
    
    return playerShopData[player.UserId]
end

-- Save player shop data
function ShopService:savePlayerData(player)
    if not ShopService.datastoreEnabled or not ShopDataStore then return end
    
    local data = playerShopData[player.UserId]
    if not data then return end
    
    local key = "Shop_" .. player.UserId
    
    local success, err = pcall(function()
        ShopDataStore:SetAsync(key, data)
    end)
    
    if not success then
        warn("[ShopService] Failed to save: " .. tostring(err))
    end
end

-- Get player's ember balance
function ShopService:getEmberBalance(player)
    local data = playerShopData[player.UserId]
    return data and data.embers or 0
end

-- Add embers to player
function ShopService:addEmbers(player, amount)
    local data = playerShopData[player.UserId]
    if not data then return end
    
    data.embers = data.embers + amount
    
    local shopRemote = ReplicatedStorage:FindFirstChild("ShopRemote")
    if shopRemote then
        shopRemote:FireClient(player, "BALANCE_UPDATE", {embers = data.embers})
    end
    
    ShopService:savePlayerData(player)
end

-- Purchase with embers
function ShopService:purchaseWithEmbers(player, itemId, category)
    local data = playerShopData[player.UserId]
    if not data then return false, "No data" end
    
    -- Find item
    local item = nil
    for _, shopItem in ipairs(SHOP_ITEMS[category] or {}) do
        if shopItem.id == itemId then
            item = shopItem
            break
        end
    end
    
    if not item then return false, "Item not found" end
    
    local cost = item.embers
    if data.embers < cost then
        return false, "Not enough embers"
    end
    
    -- Deduct embers
    data.embers = data.embers - cost
    
    -- Record purchase
    table.insert(data.purchaseHistory, {
        itemId = itemId,
        cost = cost,
        timestamp = os.time()
    })
    
    -- Grant item (would integrate with DataManager)
    local dataRemote = ReplicatedStorage:FindFirstChild("DataRemote")
    if dataRemote then
        dataRemote:FireClient(player, "ITEM_GRANTED", {
            itemId = itemId,
            type = item.type,
            name = item.name
        })
    end
    
    -- Handle battle pass
    if category == "battlePass" then
        data.hasBattlePass = true
    end
    
    ShopService:savePlayerData(player)
    
    local shopRemote = ReplicatedStorage:FindFirstChild("ShopRemote")
    if shopRemote then
        shopRemote:FireClient(player, "PURCHASE_SUCCESS", {
            itemId = itemId,
            embers = data.embers
        })
    end
    
    return true
end

-- Get current shop items
function ShopService:getCurrentShop()
    return {
        featured = SHOP_ITEMS.featured,
        daily = SHOP_ITEMS.daily,
        weekly = SHOP_ITEMS.weekly,
        battlePass = SHOP_ITEMS.battlePass,
    }
end

-- Process Robux purchase (developer product)
function ShopService:processRobuxPurchase(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
    
    local productId = receiptInfo.ProductId
    
    -- Find matching currency bundle
    for _, bundle in ipairs(SHOP_ITEMS.currency) do
        -- In production, each bundle would have a unique ProductId
        -- For now, just add based on receipt
    end
    
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Initialize
function ShopService.init()
    print("[ShopService] Initializing...")
    
    local shopRemote = Instance.new("RemoteEvent")
    shopRemote.Name = "ShopRemote"
    shopRemote.Parent = ReplicatedStorage
    
    shopRemote.OnServerEvent:Connect(function(player, action, data)
        data = data or {}
        
        if action == "GET_SHOP" then
            local shopData = ShopService:getCurrentShop()
            local balance = ShopService:getEmberBalance(player)
            shopRemote:FireClient(player, "SHOP_DATA", {
                shop = shopData,
                embers = balance,
                hasBattlePass = playerShopData[player.UserId] and playerShopData[player.UserId].hasBattlePass or false
            })
        elseif action == "PURCHASE" then
            local success, err = ShopService:purchaseWithEmbers(player, data.itemId, data.category)
            if not success then
                shopRemote:FireClient(player, "PURCHASE_FAILED", {error = err})
            end
        elseif action == "GET_BALANCE" then
            local balance = ShopService:getEmberBalance(player)
            shopRemote:FireClient(player, "BALANCE_UPDATE", {embers = balance})
        end
    end)
    
    -- Load data when players join
    Players.PlayerAdded:Connect(function(player)
        ShopService:loadPlayerData(player)
    end)
    
    -- Save on leave
    Players.PlayerRemoving:Connect(function(player)
        ShopService:savePlayerData(player)
        playerShopData[player.UserId] = nil
    end)
    
    -- Load existing players
    for _, player in ipairs(Players:GetPlayers()) do
        ShopService:loadPlayerData(player)
    end
    
    -- Setup Marketplace callback
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        return ShopService:processRobuxPurchase(receiptInfo)
    end
    
    print("[ShopService] Initialized!")
end

return ShopService
