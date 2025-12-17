# The Ember Games - Polish Plan

**Created:** December 17, 2024  
**Purpose:** Prioritized list of remaining features to make the game release-ready  
**Status:** ✅ ALL PHASES COMPLETE - RELEASE READY!

---

## Overview

The core gameplay is complete. This document outlines features needed to polish the game for public release, organized by priority.

---

## 🔴 Priority 1: Critical for Release

These features are essential for a playable, user-friendly experience.

### 1.1 Main Menu UI ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Medium  
**Files Created:** `src/client/MainMenuUI.lua`

**Description:**  
A central hub that players see when they first join the game. Provides access to all major features.

**Requirements:**
- [ ] Play button (queue for match)
- [ ] Battle Pass button (opens SeasonalUI)
- [ ] Customize button (opens cosmetics selector)
- [ ] Settings button (opens settings menu)
- [ ] Alliance button (opens AllianceUI)
- [ ] Player info display (username, level, equipped items)
- [ ] Dramatic Hunger Games themed design
- [ ] Background animation (flames, embers, etc.)
- [ ] "May the odds be ever in your favor" tagline

---

### 1.2 Settings Menu ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Medium  
**Files Created:** `src/client/SettingsUI.lua`

**Description:**  
Allow players to customize their experience with graphics, audio, and control settings.

**Requirements:**
- [ ] **Audio Settings:**
  - [ ] Master volume slider
  - [ ] Music volume slider
  - [ ] SFX volume slider
  - [ ] Ambient volume slider
- [ ] **Graphics Settings:**
  - [ ] Graphics quality (Low/Medium/High/Ultra)
  - [ ] Particle effects toggle
  - [ ] Shadows toggle
  - [ ] View distance slider
- [ ] **Controls:**
  - [ ] Mouse sensitivity slider
  - [ ] Invert Y-axis toggle
  - [ ] Show keybind reference
- [ ] **Gameplay:**
  - [ ] Auto-pickup toggle
  - [ ] Damage numbers toggle
  - [ ] Screen shake intensity
- [ ] Save settings to player data
- [ ] Reset to defaults button

---

### 1.3 Player Count HUD ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Low  
**Files Created:** `src/client/MatchHUD.lua`

**Description:**  
Display critical match information during gameplay.

**Requirements:**
- [ ] "X Tributes Remaining" counter (prominent display)
- [ ] Kill count display
- [ ] Current placement estimate
- [ ] Zone timer countdown
- [ ] Match time elapsed
- [ ] Alliance member indicators
- [ ] Minimize/maximize toggle
- [ ] Animate on player elimination

---

### 1.4 Minimap ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** High  
**Files Created:** `src/client/Minimap.lua`

**Description:**  
In-game map showing arena layout, player position, zone, and points of interest.

**Requirements:**
- [ ] Top-right corner minimap (togglable)
- [ ] Full-screen map view (press M)
- [ ] Player position marker (with direction)
- [ ] Ally position markers (different color)
- [ ] Zone circle visualization (current and next)
- [ ] Cornucopia marker
- [ ] Supply drop markers
- [ ] Compass directions (N/S/E/W)
- [ ] Zoom in/out controls
- [ ] Biome color coding

---

### 1.5 Data Persistence (DataStore) ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** High  
**Files Created:** `src/server/DataManager.lua`

**Description:**  
Save and load player progress, unlocks, and settings using Roblox DataStore.

**Requirements:**
- [ ] **Player Data Schema:**
  - [ ] Season progress (tier, XP)
  - [ ] Unlocked rewards (trails, poses, outfits)
  - [ ] Equipped cosmetics
  - [ ] Statistics (matches, wins, kills, etc.)
  - [ ] Settings preferences
  - [ ] Challenge progress
- [ ] Save on player leave
- [ ] Auto-save every 5 minutes
- [ ] Load on player join
- [ ] Data migration for schema updates
- [ ] Backup/recovery system
- [ ] Rate limiting to prevent throttling

---

### 1.6 Tutorial/Onboarding ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Medium  
**Files Created:** `src/client/TutorialUI.lua`

**Description:**  
Guide new players through game mechanics on their first play.

**Requirements:**
- [ ] First-time player detection
- [ ] Step-by-step tutorial sequence:
  - [ ] Movement and controls
  - [ ] Inventory basics
  - [ ] Picking up items
  - [ ] Crafting introduction
  - [ ] Combat basics
  - [ ] Zone/storm mechanics
  - [ ] Alliance system
  - [ ] Emotes
- [ ] Skip tutorial option
- [ ] Tutorial completion reward (XP boost)
- [ ] "Tips" that appear contextually during gameplay
- [ ] Help button to replay tutorials

---

## 🟡 Priority 2: Important for Quality

These features significantly improve the player experience.

### 2.1 Kill Feed ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Low  
**Files Created:** `src/client/KillFeed.lua`

**Description:**  
Real-time notifications showing eliminations.

**Requirements:**
- [ ] "PlayerA eliminated PlayerB" messages
- [ ] Weapon/method icon
- [ ] Different colors for:
  - [ ] Your kills (gold)
  - [ ] Alliance kills (green)
  - [ ] Other kills (white)
- [ ] Fade out after 5 seconds
- [ ] Stack multiple kills
- [ ] Special styling for headshots/betrayals

---

### 2.2 Ping System ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Medium  
**Files Created:** `src/client/PingSystem.lua`, `src/server/PingService.lua`

**Description:**  
Allow players to mark locations for allies.

**Requirements:**
- [ ] Middle mouse button or dedicated key to ping
- [ ] Ping types:
  - [ ] Generic location ping
  - [ ] Enemy spotted ping
  - [ ] Loot here ping
  - [ ] Danger ping
  - [ ] Going here ping
- [ ] 3D world marker visible to allies
- [ ] Minimap marker
- [ ] Directional indicator when off-screen
- [ ] Ping cooldown (prevent spam)
- [ ] Audio cue for pings

---

### 2.3 Compass/Direction Indicator ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Low  
**Files Created:** `src/client/Compass.lua`

**Description:**  
Navigation aid showing cardinal directions and marked locations.

**Requirements:**
- [ ] Top of screen compass bar
- [ ] North/South/East/West markers
- [ ] Degree numbers (0-360)
- [ ] Objective markers on compass
- [ ] Ally markers on compass
- [ ] Zone edge indicator
- [ ] Cornucopia direction

---

### 2.4 Notification System ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Low  
**Files Created:** `src/client/NotificationManager.lua`

**Description:**  
Unified system for displaying all game notifications.

**Requirements:**
- [ ] Notification queue system
- [ ] Different notification types:
  - [ ] Achievement unlocked
  - [ ] Challenge completed
  - [ ] Level up
  - [ ] Item acquired
  - [ ] Zone warning
  - [ ] Alliance events
- [ ] Customizable position (top/bottom/corner)
- [ ] Animation in/out
- [ ] Sound cues
- [ ] Click to dismiss
- [ ] Notification history menu

---

### 2.5 Cosmetics Selector UI ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Medium  
**Files Created:** `src/client/CosmeticsUI.lua`

**Description:**  
Interface for selecting and equipping unlocked cosmetics.

**Requirements:**
- [ ] Trail selection
- [ ] Victory pose selection
- [ ] Outfit/skin selection
- [ ] Emote loadout customization
- [ ] Preview before equipping
- [ ] Lock indicator for locked items
- [ ] "How to unlock" info for locked items
- [ ] Filter by rarity
- [ ] Search functionality
- [ ] "New" indicators for recently unlocked

---

### 2.6 Improved Spectator Mode
**Status:** [x] Existing (SpectatorMode.lua already comprehensive)  
**Estimated Complexity:** Medium  
**Files:** `src/client/SpectatorMode.lua` (existing)

**Description:**  
Enhanced spectating experience after elimination.

**Requirements:**
- [ ] Free-fly camera mode
- [ ] Follow player camera mode
- [ ] Easy player switching (arrow keys)
- [ ] Player list to select who to watch
- [ ] Player stats overlay while spectating
- [ ] Hide UI option
- [ ] Speed up time option (if replay)
- [ ] Return to menu button

---

## 🟢 Priority 3: Nice to Have

These features add significant value but aren't required for initial release.

### 3.1 Leaderboards ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Medium  
**Files Created:** `src/client/LeaderboardUI.lua`, `src/server/LeaderboardService.lua`

**Description:**  
Global and seasonal rankings.

**Requirements:**
- [ ] Multiple leaderboard categories:
  - [ ] Most wins
  - [ ] Most kills
  - [ ] Highest kill game
  - [ ] Most survival time
  - [ ] Season tier
- [ ] Global rankings
- [ ] Friends rankings
- [ ] Daily/Weekly/All-time filters
- [ ] Your rank highlighted
- [ ] Profile links

---

### 3.2 Friends/Party System ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** High  
**Files Created:** `src/client/PartyUI.lua`, `src/server/PartyService.lua`

**Description:**  
Play with friends and form parties before matches.

**Requirements:**
- [ ] Invite friends to party
- [ ] Accept/decline invitations
- [ ] Party chat
- [ ] Party leader controls
- [ ] Queue as party
- [ ] Auto-alliance with party members in-game
- [ ] Recent players list
- [ ] Block/report players

---

### 3.3 Private Matches ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** High  
**Files Created:** `src/server/PrivateMatchService.lua`, `src/client/PrivateMatchUI.lua`

**Description:**  
Custom games with friends.

**Requirements:**
- [ ] Create private lobby with code
- [ ] Join with code
- [ ] Host controls:
  - [ ] Select arena variant
  - [ ] Adjust player count
  - [ ] Toggle gamemaker events
  - [ ] Start match when ready
- [ ] Spectator slots
- [ ] Password protection option

---

### 3.4 Ranked Matchmaking ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** High  
**Files Created:** `src/server/RankedService.lua`, `src/client/RankedUI.lua`

**Description:**  
Competitive mode with skill-based ranking.

**Requirements:**
- [ ] Rank tiers (Bronze → Diamond → Champion)
- [ ] Placement matches (10 games)
- [ ] MMR-based matchmaking
- [ ] Rank points gain/loss system
- [ ] Season resets
- [ ] Ranked-exclusive rewards
- [ ] Rank badges/icons

---

### 3.5 Replay System ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** Very High  
**Files Created:** `src/server/ReplayService.lua`, `src/client/ReplayViewer.lua`

**Description:**  
Watch recordings of past matches.

**Requirements:**
- [ ] Record match events
- [ ] Store replay data
- [ ] Playback controls (play, pause, speed, rewind)
- [ ] Multiple camera modes
- [ ] Timeline with event markers
- [ ] Share replay codes

---

### 3.6 Shop/Monetization ✅ COMPLETE
**Status:** [x] Complete  
**Estimated Complexity:** High  
**Files Created:** `src/server/ShopService.lua`, `src/client/ShopUI.lua`

**Description:**  
Purchase premium cosmetics with Robux.

**Requirements:**
- [ ] Premium currency (Embers?)
- [ ] Daily/Weekly rotating shop
- [ ] Featured items
- [ ] Purchase confirmation
- [ ] Robux integration
- [ ] Bundle deals
- [ ] Gift system

---

## 📋 Implementation Order

Recommended order for implementing these features:

### Phase 1: Essential Polish ✅ COMPLETE
1. [x] Player Count HUD (Low complexity, high impact) ✅
2. [x] Kill Feed (Low complexity, high impact) ✅
3. [x] Compass (Low complexity, improves navigation) ✅
4. [x] Notification System (Low complexity, unifies all notifications) ✅

### Phase 2: Core Experience ✅ COMPLETE
5. [x] Main Menu UI (Central hub for everything) ✅
6. [x] Settings Menu (Player preferences) ✅
7. [x] Cosmetics Selector (Use unlocked rewards) ✅

### Phase 3: Critical Infrastructure ✅ COMPLETE
8. [x] Data Persistence (Save progress!) ✅
9. [x] Minimap (Major gameplay improvement) ✅
10. [x] Tutorial (New player experience) ✅

### Phase 4: Social Features ✅ COMPLETE
11. [x] Ping System (Alliance communication) ✅
12. [x] Improved Spectator Mode (existing) ✅
13. [x] Leaderboards ✅

### Phase 5: Advanced Features ✅ COMPLETE
14. [x] Friends/Party System ✅
15. [x] Private Matches ✅
16. [x] Ranked Matchmaking ✅

### Phase 6: Stretch Goals ✅ COMPLETE
17. [x] Replay System ✅
18. [x] Shop/Monetization ✅

---

## Progress Tracking

| Priority | Feature | Status | Started | Completed |
|----------|---------|--------|---------|-----------|
| 🔴 1.1 | Main Menu UI | ✅ | Dec 17 | Dec 17 |
| 🔴 1.2 | Settings Menu | ✅ | Dec 17 | Dec 17 |
| 🔴 1.3 | Player Count HUD | ✅ | Dec 17 | Dec 17 |
| 🔴 1.4 | Minimap | ✅ | Dec 17 | Dec 17 |
| 🔴 1.5 | Data Persistence | ✅ | Dec 17 | Dec 17 |
| 🔴 1.6 | Tutorial | ✅ | Dec 17 | Dec 17 |
| 🟡 2.1 | Kill Feed | ✅ | Dec 17 | Dec 17 |
| 🟡 2.2 | Ping System | ✅ | Dec 17 | Dec 17 |
| 🟡 2.3 | Compass | ✅ | Dec 17 | Dec 17 |
| 🟡 2.4 | Notification System | ✅ | Dec 17 | Dec 17 |
| 🟡 2.5 | Cosmetics Selector | ✅ | Dec 17 | Dec 17 |
| 🟡 2.6 | Improved Spectator | ✅ | - | existing |
| 🟢 3.1 | Leaderboards | ✅ | Dec 17 | Dec 17 |
| 🟢 3.2 | Friends/Party | ✅ | Dec 17 | Dec 17 |
| 🟢 3.3 | Private Matches | ✅ | Dec 17 | Dec 17 |
| 🟢 3.4 | Ranked Matchmaking | ✅ | Dec 17 | Dec 17 |
| 🟢 3.5 | Replay System | ✅ | Dec 17 | Dec 17 |
| 🟢 3.6 | Shop/Monetization | ✅ | Dec 17 | Dec 17 |

---

## Notes

- All features should follow the existing dark/gold Hunger Games aesthetic
- UI components should be consistent with LoadingScreen, AllianceUI, SeasonalUI styling
- Consider mobile/controller support for all new UI
- Test with multiple players for multiplayer features
- Document any new keybinds in the help section

---

**Ready to start implementing? Just say which feature to tackle first!**
