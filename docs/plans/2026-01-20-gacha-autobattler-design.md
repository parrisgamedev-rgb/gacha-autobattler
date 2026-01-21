# Gacha Auto-Battler Design Document

## Core Concept

**Working Title:** TBD (Anime Cyberpunk Gacha Auto-Battler)

**Elevator Pitch:** A turn-based gacha RPG where battles play out on a 3x3 grid. Players contest squares through unit duels - first to control three in a row wins. Collect characters, build teams around elemental matchups, and outplay opponents through positioning and ability reads.

**Target Platform:** Windows standalone (Godot 4.x), with future ports to Android/iOS

**Core Pillars:**
- **Collection & team building** - Pull for characters, build teams that cover elemental matchups
- **Strategic depth** - Win through reads, positioning, and ability choices, not just raw power

**Theme:** Anime cyberpunk - augmented humans, androids, and hackers wielding traditional elemental powers (fire, water, nature, dark, light) in a neon-soaked futuristic world. Elements remain visually traditional (fire looks like fire) for instant readability.

---

## Core Gameplay Loop

### Match Setup
- Each player brings 5 units into a match
- Battles take place on a 3x3 grid
- Win condition: Control 3 squares in a row (horizontal, vertical, or diagonal)

### Turn Structure
- Each turn, players get 2 actions
- Actions can be:
  - Place a unit on an empty square
  - Move an existing unit to a different square, then place a new unit on the vacated square
- Both players act simultaneously, selecting their actions secretly

### Contesting Squares
- When both players place on the same empty square: Direct duel, winner claims it
- When a player moves into an opponent's controlled square: Challenge declared, duel resolves next round
- Defender options when challenged: Change ability (with matchup knowledge) OR retreat (lose the square, save the unit)

### Duel Resolution
- Each player selects one ability for their unit
- Element advantages apply (Fire > Nature > Water > Fire, Dark ↔ Light)
- Abilities resolve, winner takes/keeps the square
- Losing unit goes on 1-turn cooldown before it can be used again

---

## Units & Abilities

### Star Rarity System
- **3★** - Base common units, pulled at 3 stars
- **4★** - Base rare units, pulled at 4 stars
- **5★** - Base epic units, pulled at 5 stars
- **6★** - Max evolution, any unit can reach with farmable materials

### Star Evolution
- Evolving increases base stats and raises level cap
- Materials farmed from story campaign
- Allows players to invest in favorite units regardless of base rarity

### Design Philosophy
Versatility-based rarity. Higher base star units have access to stronger/more versatile abilities, but invested lower star units can compete through element advantage and smart play.

### Ability System
- Every unit has 3 abilities
- Mix of active and passive varies by unit (e.g., 3 active, 2 active + 1 passive, 1 active + 2 passives)
- Actives: Chosen each duel
- Passives: Trigger automatically in specific situations

### Rarity Ability Pools
- **3★ abilities:** Straightforward effects (deal damage, boost defense)
- **4★ abilities:** More conditional power or added utility
- **5★ abilities:** Can affect multiple squares, stronger effects, unique mechanics

### Elements
- Fire, Water, Nature (triangle: Fire > Nature > Water > Fire)
- Dark, Light (strong against each other)

---

## Duplicate & Imprint System

### Imprint System (from duplicates)
- Pulling a duplicate unit unlocks imprint bonuses
- 5 duplicate copies to fully max an imprint (6 total including original)
- Each imprint level unlocks a combat stat boost

### Imprint Stats
- Attack, Defense, HP, or Speed
- Modest percentages per level (e.g., 2-4% per imprint)
- Fully maxed imprint provides meaningful but not game-breaking boost (~10-15%)

### Imprint Modes
- **Team imprint** - Smaller stat boost applies to all allies
- **Self imprint** - Larger stat boost applies only to that unit
- Player chooses which mode before entering a match

### Separate from Star Evolution
- Star evolution = raised through farmable materials, increases stats + level cap
- Imprints = unlocked through duplicates, provides bonus stat boosts
- Both systems stack, rewarding long-term investment

---

## Equipment System

### Gear Slots
- Each unit has gear slots (weapon, armor, accessory, etc.)
- Each piece provides stat boosts

### Set Bonuses
- Gear belongs to sets (e.g., "Attack Set", "Defense Set", "Speed Set")
- Equipping 2+ pieces from the same set grants a bonus effect
- Creates meaningful choices: Break a set for stronger individual piece, or keep set bonus?

### No Substats (for MVP)
- Gear has main stats only, no random secondary stats
- Reduces RNG grind for proof of concept
- Architecture supports adding substats later as endgame content

### Gear Acquisition (MVP)
- All materials farmed from story stages
- Architecture supports adding dedicated dungeons later

---

## PvE Content

### Story Campaign
- Linear progression through chapters/stages
- Narrative set in anime cyberpunk world
- Enemies get progressively harder
- First-time clear rewards include pull currency

### Stage Structure
- Each stage is a battle on the 3x3 grid against AI-controlled enemies
- AI has a set team composition and behavior patterns
- Difficulty increases through enemy stats, better AI, and tighter element matchups

### Rewards
- First clear: Pull currency, one-time bonuses
- Repeatable: Evolution materials, gear materials
- Star ratings (e.g., 3-star clear for no units lost) for bonus rewards

### Difficulty Modes (future-ready)
- Normal mode available at launch
- Architecture supports Hard/Hell modes for same stages with better drops
- Can add dedicated dungeons (gear, events) using same stage system

### Content System Architecture
- Stages have a "type" field (story, dungeon, event, etc.)
- Drop tables configured per stage, not hardcoded
- Easy to add new content types without refactoring

---

## PvP Content

### Asynchronous PvP (Arena)
- Fight AI-controlled versions of other players' teams
- No waiting for opponents, play anytime
- Good for daily/casual play

### Real-time PvP (Competitive)
- Live matches against other players
- Both players act simultaneously each turn
- For ranked competitive and tournaments

### Ranking System
- **Visible league tiers** - Bronze → Silver → Gold → Platinum → Diamond, etc.
- **Hidden MMR** - Actual skill rating used for matchmaking
- Players see league progression, matchmaking stays fair behind the scenes

### Season Structure
- Seasons reset periodically
- Rewards based on peak rank achieved
- Pull currency, exclusive cosmetics, materials

### Private Matches (future-ready)
- Room codes for friend challenges
- Architecture supports custom lobbies and hosted tournaments later

---

## Gacha System

### Pull Currency
- Single currency for summoning
- Earnable through: PvE first clears, PvP rewards, achievements
- Purchasable with real money

### Banner Types
- **Permanent banner** - All units in pool, always available
- **Featured banners** - Rotating limited-time banners with boosted rates for specific units

### Rarity Rates
- 3★ - Most common
- 4★ - Uncommon
- 5★ - Rare (specific % TBD during balancing)

### Pity System
- **Soft pity at 50 pulls** - Rates start increasing
- **Hard pity at 100 pulls** - Guaranteed 5★
- Pity counter is per-banner

### Duplicate Handling
- Pulling a duplicate adds to that unit's imprint progress
- No "wasted" pulls - dupes always provide value

---

## Economy & Monetization

### No Stamina System
- Players can grind unlimited
- No artificial time gates on PvE content
- Player-friendly design

### Currencies
- **Pull currency** - For gacha summons (earnable + purchasable)
- **Gold/credits** - Basic currency for upgrades, gear crafting (earned through gameplay only)

### Monetization (Proof of Concept)
- **Cosmetics** - Character skins, visual effects, profile customization
- No gameplay-affecting purchases
- Shop hooks built in for future expansion

### Future Monetization Options (architecture supports)
- Battle pass with free/premium tracks
- Convenience features (auto-repeat, extra loadout slots)
- Cosmetic bundles

### Player-First Philosophy
- F2P players can earn everything gameplay-related
- Paying only accelerates collection or unlocks cosmetics
- No pay-to-win gear or exclusive powerful units

---

## Technical Overview

### Engine & Language
- **Engine:** Godot 4.x
- **Language:** GDScript (Python-like, beginner-friendly)

### Target Platforms
- **MVP:** Windows standalone
- **Future:** Android, iOS, Web

### Why Godot
- Scene files are text-based (can be written directly)
- GDScript is simple and readable
- Lighter weight than Unity
- Exports to all target platforms

### Architecture Priorities
- **Data-driven design** - Units, abilities, stages, gear defined in configuration, not hardcoded
- **Modular systems** - Gacha, combat, inventory, progression as separate systems
- **Extensible content system** - Easy to add new stages, units, abilities without code changes

### Networking (for PvP)
- Client-server architecture for real-time matches
- Server authoritative for competitive integrity
- Start with local/peer-to-peer testing, add dedicated servers later

### Save System
- Local saves for single-player progress
- Cloud save architecture for future cross-device play

---

## MVP Scope

### MVP Goal
Playable single-player prototype with core battle system

### MVP Includes
- 3x3 grid battle system with duel mechanics
- 5 units per team, 2 actions per turn
- Element system (Fire/Water/Nature triangle, Dark↔Light)
- 3 abilities per unit (active/passive mix)
- Star rarity system (3★/4★/5★, evolve to 6★)
- Basic AI opponent
- Simple battle UI

### MVP Excludes (add later)
- Full gacha with pity system
- Equipment/gear system
- Story campaign
- PvP (async and real-time)
- Imprint system
- Cosmetics shop

---

## Implementation Order

1. Godot installation and project setup
2. Basic 3x3 grid and unit placement
3. Turn system and duel resolution
4. Battle UI
5. Unit data and abilities
6. Single-player vs AI (playable prototype)
7. Gacha/summoning system
8. Equipment system
9. Story campaign structure
10. PvP networking

---

## Notes

- First-time Godot developer - implementation includes step-by-step guidance
- Placeholder art initially, real art later
- Architecture designed for extensibility (substats, dungeons, tournaments can be added later)
