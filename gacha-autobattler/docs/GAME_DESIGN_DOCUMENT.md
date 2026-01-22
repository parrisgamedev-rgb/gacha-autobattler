# Grid Battler - Game Design Document

**Version:** 0.11
**Last Updated:** January 2026
**Genre:** Gacha Auto-Battler
**Platform:** Windows (PC)
**Engine:** Godot 4.5

---

## Table of Contents

1. [Game Overview](#game-overview)
2. [Core Gameplay Loop](#core-gameplay-loop)
3. [Battle System](#battle-system)
4. [Unit System](#unit-system)
5. [Ability System](#ability-system)
6. [Progression Systems](#progression-systems)
7. [Economy](#economy)
8. [Game Modes](#game-modes)
9. [Gacha System](#gacha-system)
10. [UI/UX](#uiux)
11. [Content Reference](#content-reference)
12. [Roadmap](#roadmap)

---

## Game Overview

### Elevator Pitch
Grid Battler is a gacha auto-battler where players collect units, build teams, and battle on a 3x3 tactical grid. Combine elemental advantages, strategic positioning, and powerful abilities to defeat enemies in turn-based combat.

### Core Pillars
- **Collect:** Summon and collect units with the gacha system
- **Build:** Create powerful teams with synergistic abilities and gear
- **Battle:** Engage in tactical 3x3 grid combat with simultaneous resolution
- **Progress:** Level units, enhance gear, and advance through campaigns

### Target Audience
- Fans of gacha games (Genshin Impact, Summoners War, Epic Seven)
- Strategy/tactics game enthusiasts
- Players who enjoy collection and progression systems

---

## Core Gameplay Loop

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   SUMMON ──► COLLECT ──► BUILD TEAM ──► BATTLE         │
│      │                                    │             │
│      │                                    ▼             │
│      │                              EARN REWARDS        │
│      │                                    │             │
│      │         ┌──────────────────────────┤             │
│      │         │                          │             │
│      │         ▼                          ▼             │
│      │    LEVEL UNITS              ENHANCE GEAR         │
│      │         │                          │             │
│      └─────────┴──────────────────────────┘             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

1. **Summon** units using Gems
2. **Collect** and manage your unit roster
3. **Build** teams of up to 5 units
4. **Battle** in Campaign, Dungeons, Quick Battle, or PvP
5. **Earn** Gold, Materials, Enhancement Stones, and Gear
6. **Upgrade** units (leveling) and gear (enhancement)
7. **Repeat** with stronger teams

---

## Battle System

### Grid Layout
- **3x3 grid** shared by both players
- Each cell can hold one unit from each side (contested squares)
- Units are placed during the **Placement Phase**

### Turn Structure

**1. Placement Phase (Player Turn)**
- Player has **3 actions per turn**
- Actions: Place a unit, move a unit, or end turn early
- Units can only be placed in empty cells or cells without friendly units

**2. Resolution Phase (Automatic)**
- All contested cells (cells with both player and enemy units) resolve simultaneously
- Combat order within each cell determined by unit Speed stat
- Faster unit attacks first

**3. Enemy Phase**
- AI performs its 3 actions
- Same rules as player phase

### Combat Resolution
When two units occupy the same cell:

1. **Speed Check:** Faster unit attacks first
2. **Damage Calculation:**
   ```
   Base Damage = Attacker ATK × Ability Multiplier
   Element Modifier = 1.0 / 1.3 (advantage) / 0.7 (disadvantage)
   Final Damage = (Base Damage × Element Modifier) - Defender DEF
   ```
3. **Minimum Damage:** 1 (attacks always deal at least 1 damage)
4. **Simultaneous:** Both units attack in speed order, then effects resolve

### Victory Conditions

**Primary: Knockout Victory**
- Eliminate ALL enemy units to win immediately

**Secondary: Turn Limit (25 turns)**
If turn limit reached, tiebreakers apply:
1. **Line Control:** Control a full row, column, or diagonal (tic-tac-toe style)
2. **HP Percentage:** Team with higher total HP% remaining wins

### Element System

```
       FIRE
      /    \
     /      \
  NATURE ── WATER

  LIGHT ◄──► DARK
```

| Attacker | Strong Against | Weak Against |
|----------|----------------|--------------|
| Fire     | Nature (+30%)  | Water (-30%) |
| Water    | Fire (+30%)    | Nature (-30%)|
| Nature   | Water (+30%)   | Fire (-30%)  |
| Light    | Dark (+30%)    | -            |
| Dark     | Light (+30%)   | -            |

*Light and Dark have mutual advantage against each other.*

---

## Unit System

### Unit Attributes

| Attribute | Description |
|-----------|-------------|
| **Name**  | Display name (e.g., "Kael") |
| **Element** | Fire, Water, Nature, Light, or Dark |
| **Star Rating** | 3★, 4★, or 5★ (determines max level and base stats) |
| **HP** | Health points - unit dies at 0 |
| **ATK** | Attack power - determines damage dealt |
| **DEF** | Defense - reduces incoming damage |
| **SPD** | Speed - determines attack order in combat |

### Star Ratings

| Rating | Max Level | Drop Rate | Stat Multiplier |
|--------|-----------|-----------|-----------------|
| 3★     | 30        | 88%       | 1.0x base       |
| 4★     | 40        | 10%       | ~1.15x base     |
| 5★     | 50        | 2%        | ~1.3x base      |

### Stat Scaling
- **Per Level:** +3% to all stats
- **Per Imprint:** +5% to all stats (max 5 imprints = +25%)

---

## Ability System

Each unit has **3 abilities**. One is used per combat resolution.

### Ability Properties

| Property | Description |
|----------|-------------|
| **Damage Multiplier** | Multiplier on ATK stat (e.g., 1.5x = 150% ATK) |
| **Defense Multiplier** | Multiplier on DEF during this duel |
| **Heal Amount** | Flat HP restored after duel |
| **Bonus Damage** | Flat damage added |
| **Cooldown** | Turns before ability can be used again |

### Special Effects

| Effect | Description |
|--------|-------------|
| **Ignores Element** | No element advantage/disadvantage |
| **Guaranteed Survive** | Cannot be knocked out (survive with 1 HP) |
| **Counter Attack** | Deal damage back when hit |
| **Piercing** | Ignores enemy DEF |

### Status Effects

| Status | Effect |
|--------|--------|
| **Overheat** | Damage over time each turn |
| **Corrupted** | Reduced ATK and/or DEF |
| **Disrupted** | Cannot use abilities |
| **Shielded** | Absorbs damage |
| **Overclocked** | Increased ATK and/or DEF |

### Field Effects
Applied to grid cells, affecting units standing on them:

| Field | Effect |
|-------|--------|
| **Thermal** | Deals damage per turn |
| **Repair** | Heals per turn |
| **Boost** | Increases stats |
| **Suppression** | Reduces stats |

---

## Progression Systems

### Unit Leveling

**Methods:**
1. **Battle XP:** Units gain XP from winning battles
2. **Manual Level:** Spend Gold + Materials in Collection screen

**Costs:**
- Gold per level: 50 × current level
- Materials per level: 2 + (level ÷ 10)

**XP Curve:**
- Base XP for level 2: 100
- Growth rate: 15% more XP per level

### Imprinting
- Merge duplicate units to increase stats
- Max imprint level: 5
- Bonus per imprint: +5% all stats

### Gear System

**Slots (4 per unit):**
- Weapon
- Armor
- Accessory 1
- Accessory 2

**Gear Rarities:**

| Rarity | Color | Max Level | Enhance Cost |
|--------|-------|-----------|--------------|
| Common | Gray | +6 | 100g / 2 stones |
| Rare | Blue | +9 | 200g / 4 stones |
| Epic | Purple | +12 | 400g / 8 stones |
| Legendary | Gold | +15 | 800g / 15 stones |

**Stat Types:** HP, ATK, DEF, or SPD (flat or percentage)

---

## Economy

### Currencies

| Currency | Earn From | Used For |
|----------|-----------|----------|
| **Gems** | First-clear bonuses, achievements | Gacha summons |
| **Gold** | All battles | Unit leveling, gear enhancement |
| **Materials** | All battles | Unit leveling |
| **Enhancement Stones** | Dungeons | Gear enhancement |

### Starting Resources (New Player)
- Gems: 10,000
- Gold: 5,000
- Materials: 100
- Enhancement Stones: 50

### Battle Rewards

| Mode | Gold | Materials | XP |
|------|------|-----------|-----|
| Quick Battle | 100 | 3 | 30 |
| Campaign 1-1 | 100 | 5 | 30 |
| Campaign 1-5 | 350 | 20 | 80 |
| Dungeons | Varies | - | 30 |

---

## Game Modes

### Campaign
- Story-based progression through chapters
- 5 stages per chapter (currently 1 chapter)
- Progressive difficulty with fixed enemy teams
- First-clear gem rewards (50-200 gems)
- Unit rewards for chapter completion

### Quick Battle
- Instant battle against random AI team
- Good for grinding Gold/Materials
- No stamina cost

### Dungeons
Four dungeons, each dropping gear for a specific stat:

| Dungeon | Drops | Tiers |
|---------|-------|-------|
| Power Sanctum | ATK gear | Easy, Normal, Hard |
| Fortress Ruins | DEF gear | Easy, Normal, Hard |
| Vitality Caves | HP gear | Easy, Normal, Hard |
| Wind Temple | SPD gear | Easy, Normal, Hard |

Higher tiers = better rarity drops + more Enhancement Stones

### PvP
- Real-time multiplayer via room codes
- Host/join private matches
- Same battle rules as PvE

---

## Gacha System

### Pull Costs
- Single Pull: 100 Gems
- Multi Pull (10x): 900 Gems (10% discount)

### Rates

| Rarity | Base Rate |
|--------|-----------|
| 5★ | 2% |
| 4★ | 10% |
| 3★ | 88% |

### Pity System
- **Soft Pity:** Starts at pull 50, +5% rate increase per pull
- **Hard Pity:** Guaranteed 5★ at pull 100
- **Multi Guarantee:** 10th pull of multi is 4★ or better

### Summon Animation
- Cinematic pull animation with dramatic buildup
- Rarity-based effects (gold burst for 5★, purple for 4★)
- Skip button available

---

## UI/UX

### Screens

| Screen | Purpose |
|--------|---------|
| **Main Menu** | Hub for all game modes |
| **Campaign Select** | Choose story stages |
| **Dungeon Select** | Choose gear farming dungeons |
| **Team Select** | Build team before battle |
| **Battle** | Core gameplay |
| **Collection** | View/manage units |
| **Gear Inventory** | View/enhance gear |
| **Gacha** | Summon new units |
| **How to Play** | Tutorial/help text |

### Visual Style
- Dark theme (navy background #1a1a2e)
- Blue primary accents (#4a9eff)
- Gold for premium/rare elements
- Purple for epic elements

### Battle UI Elements
- HP bars with numeric display
- Floating damage numbers
- Ability tooltips
- Turn/phase indicators
- Auto-battle toggle
- Speed controls (1x/2x/3x)

### Transitions
- Fade-to-black between all screens (0.4s total)
- Victory/defeat animations with confetti/effects
- Unit knockout animations (flash, shake, particles)

---

## Content Reference

### Units (10 Total)

| Name | Element | Stars | HP | ATK | DEF | SPD | Abilities |
|------|---------|-------|-----|-----|-----|-----|-----------|
| Kael | Fire | 3★ | 100 | 25 | 10 | 12 | Strike, Power Strike, Flame Burst |
| Zipp | Fire | 3★ | 70 | 32 | 5 | 14 | Strike, Power Strike, Inferno |
| Marina | Water | 3★ | 95 | 20 | 10 | 13 | Strike, Guard, Water Splash |
| Nerissa | Water | 4★ | 85 | 30 | 8 | 14 | Strike, Guard, Tidal Shield |
| Willow | Nature | 3★ | 100 | 20 | 12 | 10 | Strike, Guard, Vine Wrap |
| Thorne | Nature | 5★ | 150 | 18 | 20 | 8 | Strike, Guard, Nature's Resilience |
| Clara | Light | 3★ | 90 | 18 | 12 | 11 | Strike, Guard, Holy Light |
| Aldric | Light | 5★ | 140 | 28 | 18 | 10 | Strike, Guard, Radiant Smite |
| Nyx | Dark | 3★ | 75 | 28 | 6 | 16 | Strike, Quick Strike, Life Drain |
| Darius | Dark | 4★ | 120 | 24 | 16 | 9 | Strike, Counter Stance, Life Drain |

**Distribution:** 6× 3★, 2× 4★, 2× 5★

### Starter Units
New players receive:
- Zipp (Fire Imp) - 3★
- Marina (Water Sprite) - 3★
- Willow (Nature Wisp) - 3★

### Campaign Stages (Chapter 1)

| Stage | Name | Enemies | Gem Reward |
|-------|------|---------|------------|
| 1-1 | Forest Path | 3 enemies | 50 |
| 1-2 | Dark Woods | 3 enemies | 75 |
| 1-3 | Ancient Ruins | 4 enemies | 100 |
| 1-4 | Shadow Gate | 4 enemies | 150 |
| 1-5 | Boss: Grove Guardian | 5 enemies | 200 + Kael |

---

## Roadmap

### Current Version: 0.11

### v0.12 - Audio Foundation
- [ ] Sound effects (attacks, abilities, UI clicks, victory/defeat)
- [ ] Background music (menu theme, battle theme)
- [ ] Settings menu with volume sliders

### v0.13 - Combat Polish
- [ ] Attack animations (unit lunges toward target)
- [ ] Hit impact effects (screen shake, particles)
- [ ] Ability cast effects (element-colored auras)

### v0.14 - Tutorial & Onboarding
- [ ] Interactive tutorial for first-time players
- [ ] Guided first battle with prompts
- [ ] Explains gacha, team building, gear basics

### v0.15 - Content Expansion I
- [ ] Chapter 2 campaign (5 new stages)
- [ ] 5 new units (15 total)

### v0.16 - Retention Systems
- [ ] Daily login rewards calendar
- [ ] Achievements system with gem rewards

### v0.17 - Content Expansion II
- [ ] Chapter 3 campaign (5 new stages, 15 total)
- [ ] 5 new units (20 total)

### v0.18 - Pre-Release Polish
- [ ] Bug fixes and balance pass
- [ ] Credits screen
- [ ] Final UI polish

### v1.0 - Release
- [ ] Final testing
- [ ] Release builds for distribution

---

## Technical Notes

### Save System
- Location: `user://save_data.json`
- Auto-saves after: summoning, stage clears, imprinting, leveling, gear changes
- Stores: currencies, owned units, campaign progress, pity counter, gear

### Autoloads (Singletons)
- `PlayerData` - Player state and progression
- `UITheme` - Visual styling constants
- `AISpriteLoader` - Unit sprite management
- `BoardAssetLoader` - Battle board textures
- `SceneTransition` - Screen fade transitions
- `NetworkManager` - PvP multiplayer

### AI Opponent
- Three difficulty levels: Easy, Medium, Hard
- Uses strategic cell evaluation for placements
- Considers element advantages and positioning

---

*Document generated for Grid Battler v0.11*
