# Gacha Autobattler - Project Guide

## Overview
A 3v3 grid-based gacha autobattler built in Godot 4.5. Players collect units through a gacha system, level them up, equip gear, and battle through campaign stages and dungeons.

## Tech Stack
- **Engine:** Godot 4.5 (GL Compatibility renderer)
- **Language:** GDScript
- **Resolution:** 1920x1080, viewport stretch mode
- **Entry Point:** `res://scenes/ui/main_menu.tscn`

## Project Structure
```
gacha-autobattler/
├── assets/               # Art and audio
│   ├── audio/            # Music and SFX
│   ├── board/            # Battle grid backgrounds
│   └── sprites/          # Character animations (100x100 pixel art)
├── scripts/
│   ├── core/             # Singletons and managers
│   ├── autoload/         # Global autoload managers
│   ├── battle/           # Combat system logic
│   ├── data/             # Resource class definitions
│   └── ui/               # Screen controllers
├── scenes/
│   ├── battle/           # Combat scenes
│   └── ui/               # UI screens
├── resources/            # Game data (.tres files)
│   ├── abilities/
│   ├── units/
│   ├── stages/
│   ├── gear/
│   └── achievements/
└── docs/                 # Design documents
```

## Autoload Managers (Global Singletons)
| Manager | Purpose |
|---------|---------|
| `PlayerData` | Save/load, currency, unit collection, leveling, gear |
| `AchievementManager` | Achievement tracking and unlocking |
| `AudioManager` | Music, SFX, volume control |
| `UITheme` | Design system constants (colors, spacing, fonts) |
| `AISpriteLoader` | Character sprite loading |
| `BoardAssetLoader` | Battle board backgrounds |
| `UISpriteLoader` | UI element sprites |
| `SceneTransition` | Scene change animations |
| `TutorialManager` | Tutorial state tracking |
| `NetworkManager` | PvP networking (placeholder) |

## Core Data Resources
All game content is defined as Godot Resources (.tres files):

- **UnitData** - Character template (stats, element, abilities, star rating)
- **AbilityData** - Active/passive abilities with damage, effects, cooldowns
- **GearData** - Equipment with stat bonuses (weapon, armor, accessory)
- **StageData** - Campaign levels with enemy config and rewards
- **DungeonData** - Gear farming levels with difficulty tiers
- **StatusEffectData** - Buffs/debuffs (Overheat, Corrupted, Shielded, etc.)
- **AchievementData** - Achievement definitions with requirements and rewards

## Game Mechanics

### Elements
Fire > Nature > Water > Fire (triangle), Dark <-> Light (mutual advantage)
- Advantage: 1.3x damage
- Disadvantage: 0.7x damage

### Gacha System
- Single pull: 100 gems
- 10x pull: 900 gems (guaranteed 4-star+ on last)
- Rates: 2% 5-star, 10% 4-star, 88% 3-star
- Soft pity at 50 pulls, hard pity at 100 pulls

### Battle System
- 3v3 grid-based, turn-based (max 25 turns)
- 3 actions per turn: place or move units
- Simultaneous resolution phase with duels
- Damage: (attack * ability_mult - defense) * element_mult

### Progression
- Unit level cap: star_rating * 10
- Imprinting: Combine duplicate units (up to 5 levels)
- Gear enhancement: +0 to +6/9/12/15 based on rarity

## Coding Conventions

### File Naming
- Scripts: `snake_case.gd`
- Scenes: `snake_case.tscn`
- Resources: `snake_case.tres`

### Code Style
```gdscript
extends Resource
class_name MyData

## Docstring describing the class

@export var property_name: Type = default_value

const UPPER_CASE_CONSTANT = value

signal my_signal(param)

func my_function() -> ReturnType:
    var local_var = value
    pass
```

### UI Patterns
- Use `UITheme` constants for colors and spacing
- Connect button signals for interactions
- Use `AudioManager.play_ui_click()` on all button presses
- `@onready var` for node references

### Save System
- JSON serialization to `user://save_data.json`
- Version tracking for migrations (currently v5)
- `PlayerData` handles all persistence

## Adding New Content

### New Unit
1. Create `UnitData` resource in `resources/units/`
2. Set stats, element, star rating
3. Create/assign abilities from `resources/abilities/`
4. Add to unit pool in `PlayerData._load_unit_pools()`

### New Ability
1. Create `AbilityData` resource in `resources/abilities/`
2. Configure type (ACTIVE/PASSIVE), multipliers, effects
3. Assign to unit's ability array

### New Stage
1. Create `StageData` resource in `resources/stages/chapter_N/`
2. Configure enemies, difficulty, rewards
3. Stage unlocks automatically based on ID progression

### New Achievement
1. Create `AchievementData` resource in `resources/achievements/`
2. Set category, requirement type, target value, reward
3. Auto-checks trigger on relevant events

## Development/Testing
- **F1 in gacha screen:** Add 10000 gems
- **Cheat menu in battle:** F keys for various cheats
- **Collection screen:** Max level/reset buttons for testing
- Battle has auto-battle toggle and speed controls (1x/2x/3x)

## Current Content
- 20 playable units across 3 star ratings
- 3 chapters (15 stages total)
- 5 dungeons for gear farming
- 8+ achievements
- Status effects: Overheat, Corrupted, Disrupted, Shielded, Overclocked, Bleeding, Weakened
