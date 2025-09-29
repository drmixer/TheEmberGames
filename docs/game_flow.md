# Game Flow & Phases Design - The Ember Games

## Overview
The game flow recreates the tension and pacing of The Hunger Games films, with distinct phases that increase in intensity and danger. Each phase has specific objectives, environmental conditions, and strategic considerations that echo the cinematic experience of the movies.

## Match Structure

### Phase 1: The Reaping (Pre-Match Lobby) - 120 seconds
- **Setting**: Pre-game lobby with cinematic elements
- **Mechanics**:
  - Players enter as "tributes" and receive district numbers
  - Character customization with tribute outfits
  - Viewing of other tributes in lobby
  - Optional: Tribute parade animation
- **Audio/Visual**:
  - Orchestral score reminiscent of film openings
  - Tension-building music
  - Capitol-themed environment
- **Objectives**:
  - Players ready up for match
  - Understand basic controls and objectives
- **Movie Connection**: The anticipation and dread of the reaping scenes

### Phase 2: The Tribute Parade (Arena Entry) - 30 seconds
- **Setting**: Transport to arena in hovercraft-style sequence
- **Mechanics**:
  - Cinematic camera view during transport
  - Brief overview of arena layout
  - Players positioned at spawn points around Cornucopia
- **Audio/Visual**:
  - Dramatic orchestral music
  - Aerial view of the complete arena
  - Individual tribute spotlight moments
- **Movie Connection**: Echoes the arrival at the Cornucopia in the films

### Phase 3: The Countdown (Tribute Spots) - 60 seconds
- **Setting**: Players on individual platforms, looking toward Cornucopia
- **Mechanics**:
  - 60-second countdown with increasing tension music
  - Players cannot move but can observe the Cornucopia and other tributes
  - Camera shows all 24 tribute platforms (if full match)
- **Audio/Visual**:
  - Heartbeat sound building in intensity
  - Clock visual element
  - Close-up shots of tense tribute faces
- **Objectives**:
  - Players plan their opening strategy
  - Observe positioning of other players
- **Movie Connection**: The iconic countdown sequence from the films

### Phase 4: Bloodbath (Opening Phase) - 2-3 minutes
- **Setting**: Immediate chaos around the Cornucopia
- **Mechanics**:
  - Weapons and high-tier items available at Cornucopia center
  - Highest concentration of combat and eliminations
  - Players choose between risky Cornucopia loot or safer distant resources
- **Audio/Visual**:
  - Intense action music
  - Cannon sounds for each elimination
  - High-impact combat effects
- **Strategic Options**:
  - "Go for glory": Attempt to secure top-tier equipment
  - "Run and hide": Flee to distant biomes with minimal resources
  - "Scavenger": Collect items from Cornucopia edge
  - "Ambush": Hide near Cornucopia to attack others
- **Movie Connection**: The brutal opening sequence from the first film

### Phase 5: Early Game (Scattering) - 8-10 minutes
- **Setting**: Players dispersed throughout arena
- **Mechanics**:
  - Focus on resource gathering and basic survival
  - First alliances potentially forming
  - Players avoiding conflict to establish resources
- **Audio/Visual**:
  - More ambient survival music
  - Nature sounds of different biomes
  - Occasional distant combat sounds
- **Strategic Considerations**:
  - Secure basic crafting materials
  - Find water sources
  - Establish safe sleeping locations
  - Evaluate other players' capabilities
- **Movie Connection**: The period after the bloodbath when tributes scatter

### Phase 6: Mid Game (Alliances & Conflicts) - 5-7 minutes
- **Setting**: Entire arena with various tactical positions
- **Mechanics**:
  - First alliances solidify
  - Territory control becomes important
  - More complex combat encounters
  - Resource competition intensifies
- **Audio/Visual**:
  - Tension-building music during confrontations
  - Alliance communication sounds
  - Strategic movement audio
- **Strategic Options**:
  - Maintain alliance or plan betrayal
  - Control resource-rich biomes
  - Hunt specific tributes
  - Set up ambushes
- **Movie Connection**: Mid-film alliances and conflicts (Foxface, Glimmer, Marvel, etc.)

### Phase 7: Late Game (Storm Approaches) - 3-5 minutes
- **Setting**: Shrinking playable area with increasing danger
- **Mechanics**:
  - First storm phase begins (shrinks play area by 50%)
  - Increased encounter rates
  - Desperation for resources and positioning
- **Audio/Visual**:
  - Dramatic storm music
  - Visual effects of storm approaching
  - Environmental hazard audio
- **Strategic Changes**:
  - Forced movement toward center
  - Abandoned supplies become attractive targets
  - Alliances under extreme pressure
  - High-stakes risk/reward decisions
- **Movie Connection**: The force field wall approach from the first film

### Phase 8: End Game (Final Confrontation) - 2-4 minutes
- **Setting**: Small central area around Cornucopia
- **Mechanics**:
  - 4-6 players remaining in close proximity
  - High-intensity elimination-style gameplay
  - Final strategic positioning
- **Audio/Visual**:
  - Climactic orchestral music
  - Intense combat audio
  - Cinematic camera angles
- **Player Experiences**:
  - Victor: The final moments before victory
  - Fallen: Spectator mode with emotional weight
  - Almost-victor: Last-second elimination with regret
- **Movie Connection**: The final confrontation scenes from the films

### Phase 9: Victory (Conclusion) - 1-2 minutes
- **Setting**: Cinematic victory sequence
- **Mechanics**:
  - Solo victory or alliance victory ceremony
  - Tribute spotlight and celebration
  - Stats and accomplishments review
- **Audio/Visual**:
  - Triumphant victory music
  - Fireworks and celebration effects
  - Tribute projection in night sky (like in films)
- **Movie Connection**: The iconic victory scenes with the winner and their district partner

## Dynamic Events Throughout Match

### Gamemaker Interventions
- **Timing**: Randomly triggered during Mid Game and Late Game phases
- **Types**:
  - Flood Phase: Water rises in lower-lying areas
  - Fire Phase: Wildfire moves across biomes
  - Fog Phase: Toxic fog forces movement
  - Muttation Phase: NPC hazards spawn in specific areas
  - Supply Drop: High-value loot drops in dangerous locations

### Environmental Hazards
- **Storm Phases**: 7 total phases, each shrinking the playable area
  - Phase 1: Warning period (no damage, forces movement)
  - Phase 2: Minor damage (2 HP/second) for being outside safe zone
  - Phase 3: Moderate damage (5 HP/second)
  - Phase 4: Heavy damage (10 HP/second)
  - Phase 5: Severe damage (20 HP/second)
  - Phase 6: Extreme damage (35 HP/second)
  - Phase 7: Instant elimination if outside safe zone

### Special Events
- **Tribute Eliminations**: 
  - Cannon sound effect for each elimination
  - Tribute face appears in night sky (after 2+ eliminations)
  - Audio/visual notification to all players
- **Supply Drops**:
  - Hovercraft sound effects
  - Parachute delivery
  - High-value items in contested locations

## Player Experience Tracking

### Emotional Arc
1. Anticipation (Pre-Match)
2. Terror (Countdown)
3. Chaos (Bloodbath)
4. Relief/Fear (Early Game)
5. Tension (Mid Game)
6. Desperation (Late Game)
7. Intensity (End Game)
8. Resolution (Victory)

### Pacing Considerations
- **Tension Rhythm**: Build-tension-release cycle throughout each phase
- **Combat Spacing**: Prevent constant action; allow for survival and strategy
- **Safe Moments**: Brief respites between intense periods
- **Escalation**: Consistent ratcheting of tension toward climax

## Connection to Movie Themes
- The countdown tension mirrors the films' suspenseful moments
- Alliance dynamics reflect relationships from the movies
- Survival elements echo Katniss's forest survival skills
- The storm/arena shrinking recreates the film's environmental hazards
- Victory themes connect to the emotional journeys in the films
- The overall pacing matches the cinematic rhythm of the movies
- Tribute spotlighting reflects the character focus of the films
- The emotional weight of death and survival is emphasized