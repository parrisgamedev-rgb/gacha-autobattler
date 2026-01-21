# Gear System Design (v0.4)

## Overview

Add a gear system where units can equip items to boost their stats, and gear farming dungeons to obtain gear and enhancement materials.

---

## Gear Slots

Each unit has 4 gear slots:
- Weapon
- Armor
- Accessory 1
- Accessory 2

A piece of gear can only be equipped to one unit at a time. Unequipping is free and instant.

---

## Gear Rarity

| Rarity | Max Level | Color |
|--------|-----------|-------|
| Common | +6 | Gray |
| Rare | +9 | Blue |
| Epic | +12 | Purple |
| Legendary | +15 | Gold |

---

## Gear Stats

Gear provides either flat or percentage bonuses to one primary stat:
- HP (flat or %)
- Attack (flat or %)
- Defense (flat or %)
- Speed (flat or %)

### Stat Scaling Examples

**Flat ATK Weapon:**
| Rarity | Base | At Max Level |
|--------|------|--------------|
| Common | +8 | +20 (+6) |
| Rare | +15 | +42 (+9) |
| Epic | +25 | +85 (+12) |
| Legendary | +40 | +160 (+15) |

**Percentage ATK Weapon:**
| Rarity | Base | At Max Level |
|--------|------|--------------|
| Common | 2% | 5% (+6) |
| Rare | 3% | 8% (+9) |
| Epic | 5% | 14% (+12) |
| Legendary | 8% | 20% (+15) |

---

## Stat Calculation Order

1. Base stats from UnitData
2. Level multiplier (3% per level above 1)
3. Imprint multiplier (5% per imprint level)
4. Gear flat bonuses added
5. Gear percentage bonuses applied

---

## Gear Enhancement

Leveling gear costs Gold + Enhancement Stones:

| Rarity | Gold per Level | Stones per Level |
|--------|----------------|------------------|
| Common | 100 | 2 |
| Rare | 200 | 4 |
| Epic | 400 | 8 |
| Legendary | 800 | 15 |

---

## Gear Dungeons

Four dungeons, one per stat type:

| Dungeon | Drops |
|---------|-------|
| Power Sanctum | ATK gear |
| Fortress Ruins | DEF gear |
| Vitality Caves | HP gear |
| Wind Temple | SPD gear |

All dungeons also drop Enhancement Stones.

### Difficulty Tiers

| Tier | Enemy Level | Drop Rates | Stones |
|------|-------------|------------|--------|
| Easy | 3 | 70% Common, 25% Rare, 5% Epic | 3-5 |
| Normal | 6 | 40% Common, 40% Rare, 18% Epic, 2% Legendary | 6-10 |
| Hard | 10 | 10% Common, 40% Rare, 40% Epic, 10% Legendary | 12-18 |

No stamina cost - unlimited runs for early development/testing.

---

## New Currency

**Enhancement Stones** - Used to level up gear, dropped from gear dungeons.

Starting amount for new players: 50

---

## UI Changes

### Main Menu
- Add "DUNGEONS" button
- Add "GEAR" button

### Gear Inventory Screen
- Grid display of all owned gear
- Filter by: slot type, rarity, stat type
- Sort by: rarity, level, stat value
- Tap gear for detail popup with Enhance/Sell options

### Dungeon Select Screen
- Four dungeon buttons with icons
- Select dungeon shows 3 difficulty tiers
- Select tier goes to team select then battle
- Victory shows gear drops + stones earned

### Collection Screen Updates
- Unit detail panel shows 4 gear slots
- Click slot to equip/view gear
- Gear selection popup for equipping

---

## Files to Create

| File | Purpose |
|------|---------|
| `scripts/data/gear_data.gd` | GearData resource class |
| `scripts/ui/gear_inventory_screen.gd` | Gear inventory UI |
| `scenes/ui/gear_inventory_screen.tscn` | Gear inventory scene |
| `scripts/ui/dungeon_select_screen.gd` | Dungeon selection UI |
| `scenes/ui/dungeon_select_screen.tscn` | Dungeon selection scene |
| `resources/gear/*.tres` | Gear templates |
| `resources/dungeons/*.tres` | Dungeon definitions |

## Files to Modify

| File | Changes |
|------|---------|
| `scripts/core/player_data.gd` | Gear inventory, enhancement_stones, equip methods |
| `scripts/battle/unit_instance.gd` | Gear slots, gear stat calculation |
| `scripts/ui/collection_screen.gd` | Gear slot display and equip UI |
| `scenes/ui/collection_screen.tscn` | Gear slot nodes |
| `scripts/ui/main_menu.gd` | DUNGEONS and GEAR buttons |
| `scenes/ui/main_menu.tscn` | Button nodes |
| `scripts/battle/battle.gd` | Dungeon mode, gear drops |
| `CHANGELOG.md` | v0.4 documentation |

---

## Future Considerations (not in v0.4)

- Set bonuses (equip 2/4 of same set for bonus effects)
- Gear substats (random secondary stats)
- Stamina system for dungeon runs
- Gear selling for gold
- Auto-equip best gear feature
