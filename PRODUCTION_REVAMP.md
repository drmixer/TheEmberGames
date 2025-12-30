# The Ember Games - Production Revamp Plan

## 🚨 Status Check
**Current State:** "Wide as an ocean, deep as a puddle."
- We have files for *everything* (Ranked, Replays, Seasons, Parties).
- But the *core game* (hitting people with sticks on a map) is fragile and visually basic.
- High memory usage (~3GB) indicates leaks or poor optimization (likely the Terrain Generator).
- Visuals are "programmer art" (block trees, stick weapons).

**The Goal:** A production-quality "Vertical Slice". We need ONE fun, stable match before we add Battle Passes.

---

## 📅 Phase 1: Core Foundation (The Vertical Slice)
*Objective: A stable, performant round loop with satisfying combat.*

### 1.1 Fix the Map (Critical)
The current `TerrainGenerator` uses `FillBlock` 125,000 times. This is slow and looks blocky.
- [ ] **Action:** Replace procedural generation with a **Static Map Loader** or a heavily optimized `WriteVoxels` generator.
- [ ] **Action:** Create "Pre-fab" models for trees/rocks using MeshParts instead of simple Parts (looks 10x better).

### 1.2 Combat "Juice"
Attacking works now, but feels flat.
- [ ] **Action:** Add **Hitstop** (tiny freeze when hitting) to give weight.
- [ ] **Action:** Add **Blood/Spark Particles** on hit.
- [ ] **Action:** Replace 403-Error sounds with working generic Roblox sounds.
- [ ] **Action:** Add a functional **Ranged Weapon** (Bow) to vary gameplay.

### 1.3 Game Loop Stability
Ensure the game cycles endlessly without crashing.
- [ ] **Action:** Stress test the `MatchService` -> `LobbyService` cycle.
- [ ] **Action:** Verify cleanup (ensure map/items are deleted after rounds).

---

## 🎨 Phase 2: Visual Overhaul
*Objective: Make it look "Premium".*

### 2.1 Lighting & Atmosphere
- [ ] **Action:** Configure `Lighting` service with Atmosphere, SunRays, and ColorCorrection (warmer, movie-like tone).
- [ ] **Action:** Add "Spectating" visuals (vignette, blur).

### 2.2 UI Polish
The UI code exists but needs to match the game state.
- [ ] **Action:** Ensure `InventoryGui` actually shows what you are holding.
- [ ] **Action:** Clean up the HUD (Health/Stamina bars).

---

## 🛠 Phase 3: The "Extras" (Re-enabling)
*Do not touch these until Phase 1 & 2 are perfect.*
- Ranked Mode
- Replay System
- Cosmetics Shop
- Battle Pass

---

## 📝 Immediate Next Steps
1. **Disable `TerrainGenerator` debug loop**: Stop it from churning memory.
2. **Import Assets**: We need valid IDs for:
   - Sword Swing Sound
   - Sword Hit Sound
   - Bow Fire Sound
   - Footsteps
   - Tree Model (Mesh)
   - Rock Model (Mesh)

**Ready to start? Let's tackle 1.1: Fix the Map.**
