# Player Survival Systems Design - The Ember Games

## Overview
Survival systems create meaningful choices and tension throughout matches. These systems require players to balance combat and survival priorities, forcing strategic decisions about risk vs. resource management. All systems are inspired by the survival elements shown in The Hunger Games movies.

## Core Stats

### Health System
- **Starting Value**: 100 HP
- **Regeneration**: 
  - Natural: 1 HP every 3 seconds when hunger > 50 and thirst > 50
  - Enhanced: 2 HP every 2 seconds when at campfire with food
- **Damage Types**:
  - Physical (weapons, falls, muttations)
  - Environmental (poison plants, extreme weather)
  - Status (bleeding from critical hits)
- **Debuffs**:
  - Bleeding: 2 HP every 2 seconds (applied by sharp weapons)
  - Poison: 3 HP every 1.5 seconds (from poison berries or plants)
  - Hypothermia: 1 HP every 5 seconds in snow biome without proper gear

### Hunger System
- **Starting Value**: 100 (Satiated)
- **Drain Rate**: 1 point every 45 seconds during activity, 60 seconds at rest
- **Stages**:
  - Satiated (100-75): Normal performance
  - Peckish (74-50): Slight stamina reduction
  - Hungry (49-25): Significant stamina reduction, movement speed -10%
  - Starving (24-1): Movement speed -25%, health regen stops, gradual health loss
- **Restoration**:
  - Berries: +10-15 points
  - Cooked meat: +25-30 points
  - Bread: +20-25 points
  - High-tier meals: +35-40 points

### Thirst System
- **Starting Value**: 100 (Hydrated)
- **Drain Rate**: 1 point every 30 seconds during activity, 45 seconds at rest
- **Stages**:
  - Hydrated (100-75): Normal performance
  - Thirsty (74-50): Gradual stamina loss
  - Dehydrated (49-25): Movement speed -10%, decreased jump height
  - Critical (24-1): Movement speed -25%, health regen stops, gradual health loss
- **Restoration**:
  - River water: +20-30 points (small sickness risk)
  - Purified water: +30-40 points (no side effects)
  - Fruit juices: +25-35 points + small hunger restoration

## Crafting System

### Basic Recipes (Available from start)
```
Wood + Wood + Stone = Basic Spear (damage: 25 HP)
Stone + Vine = Basic Knife (damage: 20 HP, bleed chance: 15%)
Wood + Vine = Torch (light source, camp building)
Plant + Plant = Healing Herb (health: +15 HP)
Plant + Plant + Plant = Poison Berries (damage: 15 HP to target, 5 HP to self if consumed)
```

### Advanced Recipes (Found in loot containers or supply drops)
```
Stick + String + Sharp Stone = Basic Bow (damage: 35 HP)
Arrow Head + Stick + Feather = Arrow (when used with bow)
Leather + Leather = Basic Armor (reduces all damage by 20%)
Rope + Trap Parts = Tripwire Trap (immobilizes player for 10s)
```

### Rare Recipes (Very rare finds in Cornucopia or special supply drops)
```
Explosive Powder + Timer = Fire Trap
Advanced Materials = High-tier Weapons
```

## Biome-Specific Survival Elements

### Forest Biome
- **Edible Berries**: Small hunger restoration, risk of poison variety
- **Medicinal Herbs**: Crafting ingredients for healing items
- **Wood Resources**: Primary building/crafting material
- **Hazards**: Potential muttations, limited visibility

### River Biome
- **Fresh Water**: Primary thirst restoration, no sickness risk
- **Fishing Opportunities**: Potential for food source (requires crafted fishing rod)
- **Drowning Risk**: In deeper areas without swimming skill
- **Natural Bridge Points**: Strategic locations to control

### Meadow Biome
- **Open Visibility**: Good for spotting threats/resources from afar
- **Wild Vegetables**: Moderate hunger restoration
- **Exposure**: Vulnerable to ranged attacks
- **Wind Effects**: May affect ranged weapon accuracy

### Swamp Biome
- **Poison Plants**: Risk of applying poison status effect
- **Medicinal Plants**: Higher chance of healing ingredients
- **Movement Impediment**: Reduced movement speed
- **Natural Remedies**: Potential antidotes for status effects

### Cliffs/Rocky Areas
- **Stone Resources**: Crafting material for weapons/tools
- **Fall Hazards**: Potential for environmental damage
- **Vantage Points**: Strategic advantage for surveillance
- **Cave Shelters**: Potential safe spots or resource caches

### Desert/Mesa
- **Heat Exposure**: Accelerated thirst drain
- **Unique Crafting Materials**: Special stones for advanced tools
- **Harsh Sun**: Slight accuracy reduction during midday
- **Oasis Spots**: Rare water sources that may be contested

### Mountain/Snow
- **Cold Exposure**: Potential for hypothermia without proper gear
- **Icy Movement**: Slipping hazards and reduced control
- **Insulation Materials**: Special items for cold protection
- **Harsh Weather**: Periodic blizzards limiting visibility

## Environmental Interactions

### Camp Building
- **Requirements**: Torch + 2 Wood + 1 Plant Fiber
- **Benefits**: Faster health/hunger restoration, safe rest area
- **Vulnerabilities**: Can be discovered and attacked by other players
- **Visibility**: Smoke from campfires can reveal location

### Fire Maintenance
- **Fuel Sources**: Wood, plant fibers
- **Duration**: 10 minutes per wood piece
- **Benefits**: Faster healing, hunger restoration, warmth in cold areas
- **Risks**: Reveals location, can spread to nearby flammable objects

## Status Effects & Recovery

### Temporary Effects
- **Adrenaline**: After combat (2 min): +15% movement speed, +10% damage
- **Exhaustion**: After sprinting (30s): -20% movement speed
- **Warmth**: Near fire in cold biome (5 min): Immunity to cold damage
- **Alert**: After detecting another player (10s): Minimap shows direction to threat

### Crafting & Healing Process
- **Time Requirements**: 5-15 seconds depending on complexity
- **Interruptible**: Cancelled if player takes damage
- **Concentration Required**: Cannot move while crafting/healing
- **Tool Requirements**: Some recipes require specific tools

## Audio/Visual Feedback

### UI Elements
- **Health**: Standard HP bar with color changes (green > yellow > red)
- **Hunger**: Stomach icon gradually emptying with associated debuff indicators
- **Thirst**: Water droplet icon with similar progression indicators
- **Status Effects**: Temporary icons for special conditions

### Environmental Audio
- **Body Sounds**: Breathing intensifies with low health/hunger
- **Stomach Growling**: At hungry and starving stages
- **Dry Mouth**: At thirsty and dehydrated stages
- **Footstep Changes**: Vary with health/stamina levels

## Connection to Movie Themes
- The struggle for basic survival resources mirrors tributes' challenges
- Crafting reflects the ingenuity shown by characters like Rue and Wiress
- Environmental hazards echo the arena modifications by Gamemakers
- Resource scarcity creates the same tension as seen in the films
- The need to make difficult choices between safety and necessities