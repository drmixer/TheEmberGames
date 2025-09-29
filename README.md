# The Ember Games

A Roblox survival PvP experience inspired by The Hunger Games, developed with Rojo and Roblox Studio.

## Project Structure

```
TheEmberGames/
├── docs/                    # Design documents and specifications
│   ├── arena_design.md
│   ├── survival_systems.md
│   ├── game_flow.md
│   ├── cinematic_immersion.md
│   ├── combat_system.md
│   └── thematic_design.md
├── src/                     # Source code
│   ├── client/              # Client-side scripts (UI, emotes, etc.)
│   │   ├── UIController.lua
│   │   └── EmoteController.lua
│   ├── server/              # Server-side scripts (services, logic)
│   │   ├── ServerMain.lua
│   │   ├── LobbyService.lua
│   │   ├── ArenaService.lua
│   │   ├── EventsService.lua
│   │   └── PlayerStats.lua
│   ├── shared/              # Shared modules (config, recipes)
│   │   ├── Config.lua
│   │   └── CraftingRecipes.lua
│   └── ReplicatedStorage/   # Replicated assets (RemoteEvents, etc.)
├── default.project.json     # Rojo configuration
├── PRD.md                   # Product Requirements Document
└── README.md                # This file
```

## Services Overview

### Server-Side
- **LobbyService**: Manages player queueing, match preparation, and game start countdown
- **ArenaService**: Handles arena setup, Cornucopia loot spawning, and biome management
- **EventsService**: Manages hazards, supply drops, storm logic, and environmental events
- **PlayerStats**: Tracks and updates player vital stats (health, hunger, thirst)
- **ServerMain**: Initializes all server services in the correct order

### Client-Side
- **UIController**: Manages HUD for health/hunger/thirst bars and status display
- **EmoteController**: Handles thematic emotes (Rue's whistle, Katniss salute, etc.)

## Core Systems

### Survival Mechanics
- Health, hunger, and thirst systems
- Crafting recipes for tools and survival items
- Biome-specific survival challenges
- Status effects (bleeding, poison, hypothermia)

### Game Flow
- Lobby and tribute assignment
- 60-second countdown before match begins
- 20-minute matches with dynamic events
- Storm system that shrinks the playable area
- Tribute elimination with cinematic effects

### Combat System
- Primitive weapons (spears, bows, knives)
- Environmental hazards (fire, drowning, falls)
- Status effects from combat
- Weapon durability system

### Thematic Elements
- Signature emotes with special effects
- District-based tribute assignments
- Cornucopia landmark with valuable loot
- Supply drops and environmental events
- Capitol-themed UI and audio design

## Installation & Setup

1. Clone this repository
2. Ensure you have Rojo installed
3. Run `rojo serve` in the project directory
4. Open Roblox Studio
5. Connect to the Rojo server
6. The game structure will sync automatically

## Development Notes

This project implements the design specifications from the PRD and detailed design documents in the `docs/` folder. All systems work together to create an authentic Hunger Games experience with:

- Cinematic immersion through visual, audio, and thematic elements
- Strategic survival gameplay with meaningful choices
- Dynamic environmental events that drive player interaction
- Thematic emotes that connect players to the source material
- Scalable architecture for future expansions

## Contributing

Please refer to the design documents in the `docs/` folder for any planned features or changes.