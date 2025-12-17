-- init.client.luau
-- Main entry point for The Ember Games client
-- This file bootstraps all client scripts

print("The Ember Games client initializing...")

-- Wait for player and character to be ready
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Wait for the player's GUI to be ready
Player:WaitForChild("PlayerGui")

-- Load client modules one at a time with error handling
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

-- Phase 6: Loading screen (load first for immediate visual)
safeRequire("LoadingScreen")

-- Load core UI
safeRequire("UIController")
safeRequire("StarterGui")
safeRequire("VictoryUI")
safeRequire("CombatFeedback")
safeRequire("CountdownUI")
safeRequire("WeaponEffects")
safeRequire("AudioController")

-- Load Phase 3: Immersion modules
safeRequire("NightSkyTributes")
safeRequire("SupplyDropVisuals")
safeRequire("HazardVisuals")

-- Load Phase 4: Weapons & Combat
safeRequire("WeaponController")

-- Load other client modules
safeRequire("EmoteController")
safeRequire("CraftingGui")
safeRequire("CombatGui")
safeRequire("InventoryGui")
safeRequire("SpectatorMode")
safeRequire("ControllerSupport")
safeRequire("MobileSupport")

-- Phase 5: Testing & Admin tools
safeRequire("AdminPanel")

-- Phase 6: Polish & Cosmetics
safeRequire("TrailEffects")
safeRequire("VictoryPoses")
safeRequire("AllianceUI")
safeRequire("SeasonalUI")

-- Phase 7: Essential Polish (POLISHPLAN.md)
safeRequire("MatchHUD")
safeRequire("KillFeed")
safeRequire("Compass")
safeRequire("NotificationManager")

-- Phase 7: Core Experience
safeRequire("MainMenuUI")
safeRequire("SettingsUI")
safeRequire("CosmeticsUI")

-- Phase 7: Critical Infrastructure
safeRequire("Minimap")
safeRequire("TutorialUI")

-- Phase 7: Social Features
safeRequire("PingSystem")
safeRequire("LeaderboardUI")

-- Phase 7: Advanced Features
safeRequire("PartyUI")
safeRequire("PrivateMatchUI")
safeRequire("RankedUI")

-- Phase 7: Stretch Goals
safeRequire("ReplayViewer")
safeRequire("ShopUI")

print("[Client] The Ember Games client started successfully!")
print("[Client] Keys: F8=Admin, G=Emotes, P=Alliances, B=BattlePass, C=Customize, M=Map")
print("[Client] More: L=Leaderboard, T=Party, J=PrivateMatch, Shift+R=Ranked, Y=Replay, O=Shop")