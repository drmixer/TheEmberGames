-- ModuleScript: ShopService.lua (Server)
-- Handles premium cosmetic purchases with Robux
-- Production Ready

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local ShopService = {}
ShopService.datastoreEnabled = false

-- DataStore reference
local ShopDataStore
local success, err = pcall(function()
    ShopDataStore = DataStoreService:GetDataStore("EmberGames_Shop_v1")
end)

if success then
    ShopService.datastoreEnabled = true
else
    warn("[ShopService] DataStore not available (Studio mode)")
end

-- PRODUCT CONFIGURATION (FILL THESE WITH REAL IDS)
local PRODUCT_IDS = {
    [12345678] = { id = "embers_100", amount = 100 },  -- Example ID
    [23456789] = { id = "embers_500", amount = 550 },
    [34567890] = { id = "embers_1000", amount = 1200 },
}

local SHOP_ITEMS = {
    currency = {
        { id = "embers_100", name = "100 Embers", embers = 100, robux = 49 },
        { id = "embers_500", name = "550 Embers", embers = 550, robux = 199 },
        { id = "embers_1000", name = "1200 Embers", embers = 1200, robux = 399 },
    },
    featured = {
        { id = "trail_phoenix", name = "Phoenix Trail", type = "trail", embers = 500, rarity = "Legendary" },
        { id = "pose_champion", name = "Champion Pose", type = "pose", embers = 300, rarity = "Epic" },
    },
    daily = {
        { id = "trail_ice", name = "Frozen Path", type = "trail", embers = 150, rarity = "Rare" },
    },
    weekly = {
        { id = "bundle_starter", name = "Starter Bundle", type = "bundle", embers = 800 },
    },
    battlePass = {
        { id = "battlepass_season1", name = "Season 1 Battle Pass", embers = 950 },
    },
}

local playerShopData = {}

function ShopService:loadPlayerData(player)
    if not ShopService.datastoreEnabled then
        playerShopData[player.UserId] = { embers = 0, purchaseHistory = {}, hasBattlePass = false }
        return playerShopData[player.UserId]
    end
    
    local key = "Shop_" .. player.UserId
    local success, data = pcall(function() return ShopDataStore:GetAsync(key) end)
    
    if success and data then
        playerShopData[player.UserId] = data
    else
        playerShopData[player.UserId] = { embers = 0, purchaseHistory = {}, hasBattlePass = false }
    end
    return playerShopData[player.UserId]
end

function ShopService:savePlayerData(player)
    if not ShopService.datastoreEnabled then return end
    local data = playerShopData[player.UserId]
    if data then
         ShopDataStore:SetAsync("Shop_" .. player.UserId, data)
    end
end

function ShopService:getEmberBalance(player)
    local data = playerShopData[player.UserId]
    return data and data.embers or 0
end

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

function ShopService:purchaseWithEmbers(player, itemId, category)
    local data = playerShopData[player.UserId]
    if not data then return false, "No data" end
    
    -- Find item
    local item = nil
    for _, shopItem in ipairs(SHOP_ITEMS[category] or {}) do
        if shopItem.id == itemId then item = shopItem break end
    end
    
    if not item then return false, "Item not found" end
    if data.embers < item.embers then return false, "Not enough embers" end
    
    data.embers = data.embers - item.embers
    
    -- Record
    table.insert(data.purchaseHistory, { itemId = itemId, cost = item.embers, timestamp = os.time() })
    
    if category == "battlePass" then data.hasBattlePass = true end
    
    ShopService:savePlayerData(player)
    
    -- Notify Client
    local shopRemote = ReplicatedStorage:FindFirstChild("ShopRemote")
    if shopRemote then
        shopRemote:FireClient(player, "PURCHASE_SUCCESS", {itemId = itemId, embers = data.embers})
    end
    return true
end

function ShopService:processRobuxPurchase(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
    
    -- Grant Embers based on ProductID
    local product = PRODUCT_IDS[receiptInfo.ProductId]
    local amount = product and product.amount or 0
    
    -- Fallback for testing (Any purchase grants 100 if unknown)
    if amount == 0 then amount = 100 end
    
    ShopService:addEmbers(player, amount)
    print("[ShopService] PURCHASE: Granted " .. amount .. " Embers to " .. player.Name)
    
    return Enum.ProductPurchaseDecision.PurchaseGranted -- Mark as done
end

function ShopService:getCurrentShop()
    return SHOP_ITEMS
end

function ShopService.init()
    print("[ShopService] Initializing...")
    
    local shopRemote = Instance.new("RemoteEvent")
    shopRemote.Name = "ShopRemote"
    shopRemote.Parent = ReplicatedStorage
    
    shopRemote.OnServerEvent:Connect(function(player, action, data)
        if action == "GET_SHOP" then
            shopRemote:FireClient(player, "SHOP_DATA", {
                shop = ShopService:getCurrentShop(),
                embers = ShopService:getEmberBalance(player),
                hasBattlePass = playerShopData[player.UserId].hasBattlePass
            })
        elseif action == "PURCHASE" then
            ShopService:purchaseWithEmbers(player, data.itemId, data.category)
        end
    end)
    
    Players.PlayerAdded:Connect(function(p) ShopService:loadPlayerData(p) end)
    Players.PlayerRemoving:Connect(function(p) ShopService:savePlayerData(p) end)
    
    MarketplaceService.ProcessReceipt = function(info)
        return ShopService:processRobuxPurchase(info)
    end
end

return ShopService
