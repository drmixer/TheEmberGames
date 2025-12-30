-- init.client.luau
-- Main entry point for The Ember Games client
-- This file bootstraps all client scripts
-- Updated to include MovementController

print("The Ember Games client initializing...")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

Player:WaitForChild("PlayerGui")

-- Disable Default Roblox UI
pcall(function()
    game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) -- We have our own HUD
end)

local function safeRequire(moduleName)
    local success, result = pcall(function()
        return require(script[moduleName])
    end)
    if success then
        print("Loaded: " .. moduleName)
        return result
    else
        warn("Failed to load " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

safeRequire("LoadingScreen")
safeRequire("UIController")
safeRequire("StarterGui")
safeRequire("VictoryUI")
safeRequire("CombatFeedback")
safeRequire("CountdownUI")
safeRequire("WeaponEffects")
safeRequire("AudioController")
safeRequire("NightSkyTributes")
safeRequire("SupplyDropVisuals")
safeRequire("HazardVisuals")
safeRequire("StormVisuals")

-- Combat & Movement
safeRequire("WeaponController")
safeRequire("MovementController")
safeRequire("InteractionController")

safeRequire("EmoteController")
safeRequire("CraftingGui")
safeRequire("CombatGui")
safeRequire("InventoryGui")
safeRequire("SpectatorMode")
safeRequire("ControllerSupport")
safeRequire("MobileSupport")
safeRequire("AdminPanel")
safeRequire("TrailEffects")
safeRequire("VictoryPoses")
safeRequire("AllianceUI")
safeRequire("SeasonalUI")
safeRequire("MatchHUD")
safeRequire("KillFeed")
safeRequire("Compass")
safeRequire("NotificationManager")
safeRequire("MainMenuUI")
safeRequire("SettingsUI")
safeRequire("CosmeticsUI")
safeRequire("Minimap")
safeRequire("TutorialUI")
safeRequire("TributeIntro")
safeRequire("PingSystem")
safeRequire("LeaderboardUI")
safeRequire("PartyUI")
safeRequire("PrivateMatchUI")
safeRequire("RankedUI")
safeRequire("ReplayViewer")
safeRequire("ShopUI")
safeRequire("StatusHUD")
safeRequire("ConsumableController")

print("[Client] The Ember Games client started successfully!")
print("[Client] Keys: Shift=Sprint, C=Crouch, F8=Admin, G=Emotes")