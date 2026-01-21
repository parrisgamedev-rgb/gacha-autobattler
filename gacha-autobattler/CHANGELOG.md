# Changelog

All notable changes to this project will be documented in this file.

## [0.5] - Auto-Battle & UI Overhaul

### Added
- **Auto-Battle System**
  - Toggle button to enable AI-controlled unit placement
  - AI uses strategic cell evaluation (same logic as enemy)
  - Automatically selects best abilities based on situation
  - Auto-ends turn when actions exhausted

- **Battle Speed Controls**
  - 1x, 2x, 3x speed options
  - Affects all timers, tweens, and animations
  - Speed persists during battle

- **UI Design System**
  - UITheme autoload with consistent colors, fonts, spacing
  - Dark navy backgrounds (#1a1a2e)
  - Blue primary accents (#4a9eff)
  - Standardized component styles

### Changed
- **Main Menu**: Centered layout, primary/secondary button hierarchy
- **Battle Screen**: Reorganized layout, auto/speed controls in bottom bar
- **Collection Screen**: Split view with unit grid and detail panel
- **Gear Inventory**: Tab-style filters, cleaner card layout
- **Dungeon Select**: 2x2 grid with color-coded stat types
- **Campaign Select**: Horizontal stage progression, locked/cleared states
- **Team Select**: Top team slots, available units below, filter dropdown
- **Gacha Screen**: Consistent styling with gold accents for results

---

## [0.4] - Gear System

### Added
- **Gear System**
  - Units can equip gear in 4 slots: Weapon, Armor, Accessory 1, Accessory 2
  - Gear provides flat or percentage bonuses to HP, ATK, DEF, or SPD
  - 4 rarity tiers: Common (gray), Rare (blue), Epic (purple), Legendary (gold)
  - Each rarity has different max enhancement levels: +6, +9, +12, +15
  - Gear stats scale with enhancement level

- **Gear Enhancement**
  - Level up gear using Gold and Enhancement Stones
  - Enhancement costs scale with gear rarity
  - View and enhance gear from the Gear Inventory screen

- **Gear Dungeons**
  - 4 dungeons, each dropping gear for a specific stat:
    - Power Sanctum (ATK gear)
    - Fortress Ruins (DEF gear)
    - Vitality Caves (HP gear)
    - Wind Temple (SPD gear)
  - 3 difficulty tiers: Easy, Normal, Hard
  - Higher difficulty = better gear drop rates + more Enhancement Stones
  - No stamina cost (unlimited runs for testing/early development)

- **New Currency**
  - Enhancement Stones: Used to enhance gear, dropped from dungeons
  - Starting amount: 50 stones

- **UI Changes**
  - Main menu: Added "DUNGEONS" and "GEAR" buttons
  - Collection screen: Units now show equipped gear, click gear slots to equip
  - Gear Inventory screen: View all gear, filter by type, enhance gear
  - Dungeon Select screen: Choose dungeon and difficulty tier
  - Currency display now shows Enhancement Stones

### Changed
- Battle system supports dungeon mode with randomized enemies
- Victory in dungeons grants gear drops and Enhancement Stones
- Unit stats now include gear bonuses in battle calculation

---

## [0.3] - Unit Level System

### Added
- **Unit Leveling**
  - Units now have levels (starting at 1)
  - Max level = star rating × 10 (3★=30, 4★=40, 5★=50)
  - Stats increase by 3% per level
  - Two ways to level up:
    - **Auto XP**: Units gain XP from winning battles
    - **Manual**: Spend gold + materials in Collection screen

- **New Currencies**
  - Gold: Earned from battles, used for leveling units
  - Level Materials: Earned from battles, used for leveling units
  - Starting resources: 5000 Gold, 100 Materials, 1000 Gems

- **Battle Rewards**
  - Victory now grants Gold, Materials, and XP to participating units
  - Quick Battle: 100 Gold, 3 Materials, 30 XP
  - Campaign stages have scaling rewards (100-350 Gold, 5-20 Materials, 30-80 XP)

- **Collection Screen Updates**
  - Currency display in top bar (Gold, Materials, Gems)
  - Unit cards show level and XP progress bar
  - Detail panel shows scaled stats based on level
  - "Level Up" button to manually level units
  - Level up cost displayed (Gold + Materials)

### Changed
- Unit stats now scale with level in battle
- Battle victory screen shows rewards earned
- Save file now stores gold, materials, and unit levels

---

## [0.2.1] - Save System & Starter Units

### Added
- **Save/Load System**
  - Game progress now persists across sessions
  - Saves: gems, owned units, campaign progress, pity counter
  - Auto-saves after summoning, clearing stages, and imprinting units
  - Save file location: `user://save_data.json`

- **Starter Units**
  - New players receive 3 starter units automatically:
    - Zipp (Fire Imp) - Fire element, 3-star
    - Marina (Water Sprite) - Water element, 3-star
    - Willow (Nature Wisp) - Nature element, 3-star
  - Players can now start the campaign immediately without summoning

### Changed
- Starting gems reduced from 999999 (debug) to 1000 (balanced)
- Game no longer resets progress when closed

---

## [0.2] - Story Campaign Update

### Added
- **Story Campaign System**
  - New Campaign button on main menu
  - Campaign select screen with chapter/stage selection
  - 5 stages in Chapter 1 with increasing difficulty
  - Stage-specific enemy configurations
  - First-clear gem rewards (50-200 gems per stage)
  - Unit reward for completing Chapter 1 (Fire Warrior "Kael")
  - Placeholder story text for intro/outro sequences

- **Campaign Progress Tracking**
  - Stage cleared status persists during session
  - Star ratings for cleared stages
  - Progressive stage unlocking (must clear previous stage)
  - First-clear bonus detection

- **StageData Resource System**
  - New resource type for defining campaign stages
  - Configurable enemy units, levels, difficulty, and rewards
  - Support for unit rewards on first clear

### Changed
- Main menu reorganized: Campaign > Quick Battle > PvP > Summon > Collection
- "START BATTLE" renamed to "QUICK BATTLE" for clarity
- Team select screen shows stage info when in campaign mode
- Battle results show campaign-specific rewards
- Back button returns to campaign select when in campaign mode

### Technical
- New files:
  - `scripts/data/stage_data.gd` - StageData resource class
  - `scripts/ui/campaign_select_screen.gd` - Campaign UI logic
  - `scenes/ui/campaign_select_screen.tscn` - Campaign UI scene
  - `resources/stages/chapter_1/*.tres` - Stage 1-1 through 1-5

- Modified files:
  - `scripts/core/player_data.gd` - Campaign progress tracking
  - `scripts/ui/main_menu.gd` - Campaign button handler
  - `scripts/ui/team_select_screen.gd` - Campaign mode support
  - `scripts/battle/battle.gd` - Campaign enemy loading, rewards

---

## [0.1] - Initial Release

### Added
- **Core Battle System**
  - 3x3 grid-based combat
  - Turn-based placement and movement
  - Simultaneous resolution phase
  - Speed-based combat order
  - Win condition: control a full line

- **Unit System**
  - 5 elements: Fire, Water, Nature, Light, Dark
  - Element advantage/disadvantage system
  - 3-star, 4-star, and 5-star units
  - 10 unique units across all elements
  - 3 abilities per unit with cooldowns

- **Gacha Summoning**
  - Single and multi-pull options
  - Pity system (soft pity at 50, hard pity at 100)
  - Guaranteed 4-star+ on 10th pull of multi
  - 2% base 5-star rate, 10% base 4-star rate

- **Collection System**
  - View owned units
  - Imprint system (merge duplicates for stats)
  - Unit details and ability information

- **PvP Multiplayer**
  - Room code system for private matches
  - Host/join functionality
  - Real-time battle synchronization

- **Status Effects**
  - Shielded, Corrupted, Disrupted, Overclocked, Overheat

- **Field Effects**
  - Suppression Field, Repair Field, Boost Field, Thermal Field

- **AI Opponent**
  - Three difficulty levels: Easy, Medium, Hard
  - Strategic cell evaluation for placements

- **Quality of Life**
  - Drag-and-drop unit placement
  - Ability selection panel
  - Combat announcements
  - HP bars and damage numbers
  - Cheat menu (F1) for testing
