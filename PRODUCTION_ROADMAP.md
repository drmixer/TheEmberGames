# The Ember Games: Road to Production

You have transitioned from **Alpha** to **Beta Candidate**. The core loops, map tech, combat, and monetization logic are in place. To launch a successful Roblox game, follow this checklist.

## 1. Monetization Configuration
The `ShopService.lua` is coded but needs real IDs from the Roblox Website.
- [ ] **Create Developer Products** on the Roblox Creator Dashboard:
    - 100 Embers (Cheap tier)
    - 500 Embers (Medium tier)
    - 1200 Embers (Best Value)
- [ ] **Update `ShopService.lua`**: Copy the specific Product IDs into the `PRODUCT_IDS` table.
- [ ] **Create GamePasses** (Optional): Faster XP, VIP Status.

## 2. Asset Pipeline (The Visuals)
Currently, `TerrainGenerator` uses `Instance.new("Part")` for trees and rocks. This is "Prototype Art".
- [ ] **Import Meshes**: Find or make low-poly nature assets (Trees, Rocks, Bushes).
- [ ] **Update `TerrainGenerator.lua`**: Change the `createTree` / `createRock` functions to clone these Meshes instead of creating Parts.
    ```lua
    -- Example change in TerrainGenerator:
    local treeClone = ReplicatedStorage.Assets.Trees.PineTree:Clone()
    treeClone.Parent = workspace.Decorations
    ```

## 3. Data Safety
`DataManager.lua` saves to `EmberGames_PlayerData_v1`.
- [ ] **Enable API Access**: In Roblox Studio Settings -> Security, enable "Enable Studio Access to API Services".
- [ ] **Version Control**: If you change the save structure fundamentally, increment the `v1` in the DataStore name to `v2`.

## 4. Visuals & Environment
- [ ] **Lighting Technology**: In Studio, select the **Lighting** service and set `Technology` to **Future** (Cinema quality) or **ShadowMap** (Performance balance). Scripts cannot verify this setting.
- [ ] **Terrain Detail**: If the map looks too blocky, open `TerrainGenerator.lua` and reduce `RESOLUTION` from 4 to 2 (costs performance).

## 5. Engagement & Retention
- [ ] **Populate Battle Pass**: Edit `ShopService.lua` configuration to add real rewards.
- [ ] **Analytics**: Implement `PlayFab` or `GameAnalytics`.

## 6. Marketing Preparation
- [ ] **Icon & Thumbnail**: High-quality GFX render of characters fighting.
- [ ] **Trailer**: Record gameplay with the new `LightingService` atmosphere (Shift+P in Studio for freecam).
- [ ] **Community**: Start a Discord server.

## 7. Deployment
- [ ] **Performance Test**: Join with mobile devices.
- [ ] **Production Publish**: File -> Publish to Roblox.

---

### Critical Code Paths to Review
1. **Purchase Logic**: `src/server/ShopService.lua` (Check `processRobuxPurchase`)
2. **Data Saving**: `src/server/DataManager.lua` (Check `savePlayerData`)
3. **Combat Validation**: `src/server/WeaponSystem.lua`.

**Good Luck, Tribute!**
