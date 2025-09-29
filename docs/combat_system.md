# Combat System Design - The Ember Games

## Overview
The combat system emphasizes primitive weapons and survival tools as seen in The Hunger Games films, focusing on tactical positioning, resource management, and the psychological tension of life-or-death encounters. Combat should feel impactful and meaningful, with permanent consequences that reflect the lethal nature of the Games.

## Weapon Categories

### Melee Weapons
- **Wooden Stick** (Basic):
  - Damage: 15 HP
  - Attack Speed: Fast
  - Range: Short (5 studs)
  - Durability: 20 hits
  - Crafting: Wood + Wood (simple sharpening)
  - Usage: Early game self-defense, crafting tool

- **Sharp Stick/Spear** (Basic):
  - Damage: 25 HP
  - Attack Speed: Medium
  - Range: Medium (6-7 studs)
  - Durability: 15 hits
  - Crafting: Wood + Sharp Stone
  - Usage: Balanced early-to-mid game weapon

- **Stone Knife** (Basic):
  - Damage: 20 HP
  - Attack Speed: Fast
  - Range: Short (4 studs)
  - Durability: 25 hits
  - Bleed Chance: 15% (4 HP over 5 seconds)
  - Crafting: Stone + Vine
  - Usage: Close quarters, utility tool

- **Handmade Axe** (Advanced):
  - Damage: 35 HP
  - Attack Speed: Slow
  - Range: Medium (6 studs)
  - Durability: 12 hits
  - Crafting: Wood + Sharp Stone + Vine
  - Usage: High damage, resource gathering

- **Machete** (Rare):
  - Damage: 40 HP
  - Attack Speed: Medium
  - Range: Medium (6.5 studs)
  - Durability: 8 hits
  - Crafting: Found in supply drops/Cornucopia
  - Usage: Powerful but fragile

### Ranged Weapons
- **Slingshot** (Basic):
  - Damage: 18 HP
  - Reload Time: 2 seconds
  - Range: Short-Medium (20 studs effective)
  - Ammo: Stones (infinite craftable)
  - Crafting: Wood + Elastic Material
  - Usage: Safe distance, resource efficient

- **Bow & Crude Arrows** (Mid-Tier):
  - Damage: 30 HP
  - Reload Time: 3 seconds
  - Range: Medium-Long (35 studs effective)
  - Ammo: Arrows (craftable: stick + stone + feather)
  - Accuracy: Affected by movement and wind
  - Crafting: Wood + String + Arrow Materials
  - Usage: Precision strikes, resource management

- **Compound Bow** (Advanced):
  - Damage: 45 HP
  - Reload Time: 3.5 seconds
  - Range: Long (50 studs effective)
  - Ammo: Advanced Arrows
  - Accuracy: High, less affected by conditions
  - Crafting: Found in supply drops/Cornucopia
  - Usage: Sniper-style gameplay

- **Throwing Knives** (Specialty):
  - Damage: 25 HP
  - Reload Time: 1.5 seconds
  - Range: Medium (25 studs effective)
  - Ammo: Limited (crafted in sets)
  - Crafting: Stone + Wood + Vine
  - Usage: Surprise attacks, quick elimination

### Environmental & Trap Weapons
- **Fire Trap** (Advanced):
  - Damage: 30 HP initial + 5 HP over 10 seconds (burn)
  - Activation: Proximity or timed
  - Crafting: Explosive Material + Timer
  - Usage: Area denial, escape route protection

- **Tripwire Trap** (Mid-Tier):
  - Effect: Immobilizes target for 10 seconds
  - Setup Time: 8 seconds (interruptible)
  - Detection: Visible to nearby players
  - Crafting: String + Trigger Mechanism
  - Usage: Ambushes, escape delay

- **Poison Berries** (Utility):
  - Damage: 15 HP when consumed by target
  - Application: Lure/bait strategy
  - Crafting: Poison Plant + Container
  - Usage: Deceptive survival item

## Combat Mechanics

### Damage System
- **Hit Zones**: Not implemented (simplified for game feel)
- **Critical Hits**: 2x damage chance (10%) on precise attacks
- **Environmental Damage**: Falls, drowning, fire zones
- **Status Effects**:
  - Bleeding: 4 HP over 5 seconds (applied by sharp weapons)
  - Burning: 5 HP over 10 seconds (from fire traps)
  - Poison: 6 HP over 8 seconds (from berries/plants)

### Combat Timing
- **Attack Animation**: Clear windup and recovery
- **Block/Parry**: Defensive positioning during crafting/healing
- **Stamina Cost**: Sprinting and attacking drains stamina
- **Recovery Time**: Brief invincibility frames after dodge

### Ranged Combat Considerations
- **Aim Assist**: Minimal (5-10 degree adjustment for realism)
- **Bullet Drop**: Arrows affected by distance (beyond 30 studs)
- **Wind Effect**: Environmental factor affecting long-range accuracy
- **Moving Target Penalty**: Reduced accuracy against moving players

## Tactical Combat Elements

### Positional Combat
- **High Ground Advantage**: +10% damage when attacking from above
- **Cover System**: Trees, rocks, and structures provide protection
- **Flanking**: +15% damage when attacking from blind spot
- **Encirclement**: Disadvantage when surrounded by multiple enemies

### Environmental Combat
- **Biome Advantages**:
  - Forest: Camouflage and ambush opportunities
  - River: Water provides some fire effect reduction
  - Cliffs: High ground advantage but fall risk
  - Swamp: Reduced movement, harder to escape
  - Desert: Clear long-range visibility
  - Mountain: Harsh conditions but strategic positions

### Resource-Based Combat
- **Ammo Management**: Limited ranged ammunition creates tension
- **Weapon Durability**: Weapons break after extended use
- **Crafting in Combat**: Interruptible if damaged during creation
- **Resource Denial**: Depleting enemy resources as strategy

## Combat Feedback Systems

### Visual Combat Feedback
- **Hit Indicators**: Spark effects on successful hits
- **Damage Numbers**: Floating damage numbers above target
- **Status Icons**: Visual indicators for bleeding, burning, etc.
- **Blood Effects**: Minimal but impactful gore for immersion

### Audio Combat Feedback
- **Weapon Sounds**: Distinct sounds for each weapon type
- **Hit Impact**: Satisfying impact sounds
- **Critical Hits**: Special audio effect for major hits
- **Environmental Reverb**: Sounds affected by biome acoustics

### Haptic Feedback (if supported)
- **Weapon Recoil**: Different feedback for each weapon
- **Hit Confirmation**: Tactile response on successful attacks
- **Critical Hit Boost**: Enhanced feedback for major hits

## Connection to Movie Themes

### Survival Weaponry
- Weapons reflect the primitive, survival-focused nature of the films
- Resource crafting mirrors Katniss's resourcefulness
- Improvised weapons capture the desperate nature of the Games

### Emotional Weight
- Combat feels consequential with permanent elimination
- Weapon durability reflects the struggle of limited resources
- Environmental combat echoes the arena hazards from the films

### Tactical Depth
- Multiple approaches mirror the different tribute strategies in films
- Alliance vs. solo gameplay options reflect movie dynamics
- Environmental mastery parallels the skilled tributes in films

## Combat Balance Considerations

### Early Game Balance
- Basic weapons are accessible but limited
- Encourage exploration over direct confrontation
- Resource gathering is often safer than combat

### Late Game Balance
- High-tier weapons available but rare
- Skill becomes more important than equipment
- Environmental factors become more extreme

### Meta Game Balance
- No single "best" weapon - situational effectiveness
- Crafting vs. looting trade-offs
- Mobility vs. damage trade-offs