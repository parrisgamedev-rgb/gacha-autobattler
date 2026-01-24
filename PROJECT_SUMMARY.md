# Gacha Autobattler - Project Summary

## Overview

A 3v3 grid-based gacha autobattler proof of concept built in Godot 4.5. Players collect units through a gacha system, level them up, equip gear, and battle through campaign stages and dungeons.

**Development Period:** Proof of concept completed January 2026

**Tech Stack:**
- Engine: Godot 4.5 (GL Compatibility renderer)
- Language: GDScript
- Resolution: 1024x768 (4:3 aspect ratio)

## Core Features

### Battle System
- 3x3 grid-based tactical combat
- Turn-based placement phase (3 actions per turn)
- Simultaneous resolution phase with duels
- Maximum 25 turns to prevent stalemates
- Auto-battle and speed controls (1x/2x/3x)

### Gacha System
- Single pull: 100 gems
- 10x pull: 900 gems (guaranteed 4-star+ on last pull)
- Rates: 2% 5-star, 10% 4-star, 88% 3-star
- Soft pity at 50 pulls, hard pity at 100 pulls
- Duplicate units convert to imprint levels

### Unit System
- 20 playable units across 3 star ratings (3-5 stars)
- 5 elements: Fire, Water, Nature, Light, Dark
- Element advantages: Fire > Nature > Water > Fire, Light <-> Dark
- Level cap based on star rating (star_rating * 10)
- Imprint system (combine duplicates, up to 5 levels)
- Active and passive abilities

### Progression
- 3 campaign chapters with 5 stages each (15 total)
- 5 dungeons for gear farming
- Gear system with 3 slots (weapon, armor, accessory)
- Gear enhancement (+0 to +15 based on rarity)
- Achievement system with rewards

### Status Effects
- Overheat, Corrupted, Disrupted
- Shielded, Overclocked
- Bleeding, Weakened

## Architecture

### Project Structure
```
gacha-autobattler/
├── assets/           # Art, audio, board backgrounds
├── scripts/
│   ├── core/         # Singletons (PlayerData, AudioManager, etc.)
│   ├── autoload/     # Global managers
│   ├── battle/       # Combat system
│   ├── data/         # Resource class definitions
│   └── ui/           # Screen controllers
├── scenes/           # Godot scene files
├── resources/        # Game data (.tres files)
└── docs/plans/       # Design documents
```

### Key Singletons
- **PlayerData** - Save/load, currency, unit collection
- **AudioManager** - Music and SFX
- **UITheme** - Design system constants
- **CheatManager** - Debug tools (F12 to access)
- **BoardAssetLoader** - Battle board backgrounds

### Data-Driven Design
All game content defined as Godot Resources (.tres):
- UnitData, AbilityData, GearData
- StageData, DungeonData
- StatusEffectData, AchievementData

## What Went Well

1. **Core Loop** - The place-units-and-watch-them-fight loop is satisfying
2. **Gacha Mechanics** - Complete implementation with pity and duplicate handling
3. **Clean Architecture** - Good separation between data and logic
4. **Rapid Iteration** - Cheat menu made testing efficient
5. **Consistent UI** - UITheme singleton kept styling uniform

## Known Limitations

1. **Board Art** - Using pre-made backgrounds; some dungeon boards are corrupted
2. **Roster UI** - Benches are separate panels, not integrated into board
3. **PvP** - NetworkManager is a placeholder
4. **Balance** - Unit stats and abilities need tuning
5. **Content** - Limited unit variety for a full game

## Future Expansion Ideas

- Integrate roster/bench into the dungeon room visually
- Hand-crafted board art for each theme
- More units with unique abilities
- Guild/clan system
- Real-time PvP matchmaking
- Seasonal events and limited banners
- Story/narrative elements

## Development Tools

- **F12** - Global cheat menu (currency, units, progression)
- **Cheat Menu** - Add gems/gold, max units, clear all stages
- **Auto-battle** - Toggle in battle for hands-free testing

## Final Notes

This project demonstrates that a gacha autobattler can work well in Godot with GDScript. The resource-based data system makes adding content straightforward, and the singleton architecture keeps global state manageable.

The proof of concept validates the core mechanics. A full production version would need more content, polish, and likely a dedicated artist for cohesive visuals.

---

*Built with Godot 4.5 and Claude Code*
