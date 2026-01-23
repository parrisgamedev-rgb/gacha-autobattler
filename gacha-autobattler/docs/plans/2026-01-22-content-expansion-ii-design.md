# v0.17 Content Expansion II Design

## Overview

Add Chapter 3 campaign (Dark Forest theme) with 5 new stages and a boss fight, plus 5 new playable units to reach better element balance.

## Design Decisions

- **Chapter Theme:** Dark Forest - corrupted woodland with werewolves and undead
- **Unit Balance:** Focus on filling Dark and Nature element gaps
- **New Units in Gacha:** All 5 new units added to summon pool
- **Boss Reward:** Gravebane (5★ Dark) as first-clear reward for 3-5

---

## Chapter 3: Dark Forest

### Stage Progression

| Stage | Name | Enemies | Difficulty | Gem Reward |
|-------|------|---------|------------|------------|
| 3-1 | Forest Edge | 2 Wolves, 1 Werewolf | 6 | 150 |
| 3-2 | Howling Woods | 2 Werewolves, 1 Skeleton | 7 | 175 |
| 3-3 | Bone Hollow | 2 Skeleton Warriors, 1 Werebear | 8 | 200 |
| 3-4 | The Dark Grove | 1 Werewolf, 1 Werebear, 1 Greatsword Skeleton | 9 | 225 |
| 3-5 | Alpha's Den | Alpha Werewolf (Boss), 2 Werewolves | 10 | 300 |

### Stage Details

**3-1 Forest Edge**
- Story Intro: "The forest grows darker as you venture deeper. Strange howls echo through the trees..."
- Story Outro: "The first beasts fall, but their calls have alerted others deeper within."
- Enemy Level: 12
- Rewards: 150 gems, 300 gold, 15 materials, 60 XP

**3-2 Howling Woods**
- Story Intro: "The pack has found you. Werewolves emerge from the shadows, hungry for blood."
- Story Outro: "The howling fades, but bones crunch underfoot. Something worse lurks ahead."
- Enemy Level: 14
- Rewards: 175 gems, 350 gold, 18 materials, 70 XP

**3-3 Bone Hollow**
- Story Intro: "A clearing filled with bones. The dead do not rest here - they rise to fight."
- Story Outro: "The undead crumble, but a massive shape lumbers between the trees..."
- Enemy Level: 16
- Rewards: 200 gems, 400 gold, 20 materials, 80 XP

**3-4 The Dark Grove**
- Story Intro: "The heart of corruption. Beasts and undead fight together under a dark power."
- Story Outro: "Only the Alpha remains. Its den lies just ahead."
- Enemy Level: 18
- Rewards: 225 gems, 450 gold, 22 materials, 90 XP

**3-5 Alpha's Den (Boss)**
- Story Intro: "The Alpha Werewolf towers before you, flanked by its pack. This is the ultimate test!"
- Story Outro: "The Alpha falls! The dark curse lifts from the forest. Gravebane, freed from corruption, joins your cause!"
- Enemy Level: 20
- Rewards: 300 gems, 600 gold, 30 materials, 120 XP
- First Clear Unit: Gravebane (5★ Dark)

---

## New Playable Units (5)

### Gravebane (Dark 5★)
- **Sprite:** Greatsword Skeleton
- **Role:** Heavy damage dealer
- **Stats:** HP 130, ATK 35, DEF 12, SPD 8
- **Abilities:**
  - Basic Attack
  - Soul Cleave (high damage + heal 30% of damage dealt, 3 turn cooldown)
  - Death's Embrace (AoE dark damage to all enemies, 4 turn cooldown)
- **Lore:** A fallen knight risen by dark magic, now seeking redemption.

### Ursok (Nature 4★)
- **Sprite:** Werebear
- **Role:** Bruiser/Off-tank
- **Stats:** HP 150, ATK 24, DEF 16, SPD 7
- **Abilities:**
  - Basic Attack
  - Maul (damage + reduce target DEF 20% for 2 turns, 3 turn cooldown)
  - Roar (buff self ATK 30% + taunt for 1 turn, 3 turn cooldown)
- **Lore:** A guardian of the wild who embraces his beast form.

### Shade (Dark 3★)
- **Sprite:** Skeleton Archer
- **Role:** Debuffer/Ranged
- **Stats:** HP 80, ATK 22, DEF 8, SPD 14
- **Abilities:**
  - Basic Attack
  - Cursed Arrow (damage + reduce target SPD 25% for 2 turns, 2 turn cooldown)
  - Shadow Shot (piercing damage, ignores 50% DEF, 3 turn cooldown)
- **Lore:** An undead archer whose arrows carry ancient curses.

### Fenris (Nature 3★)
- **Sprite:** Werewolf
- **Role:** Fast attacker
- **Stats:** HP 90, ATK 24, DEF 10, SPD 16
- **Abilities:**
  - Basic Attack
  - Pack Tactics (damage + buff random ally SPD 20% for 2 turns, 2 turn cooldown)
  - Savage Bite (high single-target damage, 3 turn cooldown)
- **Lore:** A werewolf who fights alongside heroes, not against them.

### Vance (Fire 4★)
- **Sprite:** Lancer
- **Role:** Mixed damage/Pierce
- **Stats:** HP 110, ATK 28, DEF 14, SPD 11
- **Abilities:**
  - Basic Attack
  - Burning Thrust (fire damage + ignores 30% DEF, 2 turn cooldown)
  - Inferno Charge (high damage dash attack, 3 turn cooldown)
- **Lore:** A dragon knight whose lance burns with eternal flame.

---

## New Monster Units (4)

| Monster | HP | ATK | DEF | SPD | Sprite |
|---------|-----|-----|-----|-----|--------|
| Werewolf | 85 | 22 | 8 | 14 | Werewolf |
| Werebear | 130 | 20 | 14 | 6 | Werebear |
| Greatsword Skeleton | 100 | 26 | 10 | 8 | Greatsword Skeleton |
| Alpha Werewolf | 200 | 28 | 12 | 12 | Werewolf (boss) |

### Monster Abilities

**Werewolf:**
- Basic Attack
- Feral Bite (damage + bleed 5 damage/turn for 2 turns, 2 turn cooldown)

**Werebear:**
- Basic Attack
- Crushing Swipe (high damage + 30% stun chance, 3 turn cooldown)

**Greatsword Skeleton:**
- Basic Attack
- Cleave (AoE damage to 2 enemies, 3 turn cooldown)

**Alpha Werewolf (Boss):**
- Basic Attack
- Feral Bite (damage + bleed)
- Alpha Howl (buff all ally ATK 25% for 2 turns, 3 turn cooldown)

---

## New Abilities Summary

### Playable Unit Abilities (10)

| Ability | Type | Effect | Cooldown |
|---------|------|--------|----------|
| Soul Cleave | Damage | High damage + heal 30% of damage | 3 |
| Death's Embrace | AoE | Dark damage to all enemies | 4 |
| Maul | Debuff | Damage + DEF down 20% (2 turns) | 3 |
| Roar | Buff | Self ATK +30% + taunt (1 turn) | 3 |
| Cursed Arrow | Debuff | Damage + SPD down 25% (2 turns) | 2 |
| Shadow Shot | Damage | Piercing (ignores 50% DEF) | 3 |
| Pack Tactics | Support | Damage + ally SPD +20% (2 turns) | 2 |
| Savage Bite | Damage | High single-target damage | 3 |
| Burning Thrust | Damage | Fire damage + ignores 30% DEF | 2 |
| Inferno Charge | Damage | High damage dash attack | 3 |

### Monster Abilities (4)

| Ability | Effect | Cooldown |
|---------|--------|----------|
| Feral Bite | Damage + bleed (5/turn, 2 turns) | 2 |
| Crushing Swipe | High damage + 30% stun | 3 |
| Cleave | AoE damage to 2 enemies | 3 |
| Alpha Howl | Buff all allies ATK +25% (2 turns) | 3 |

---

## Implementation Order

1. **Extract sprites** from new_pack for new units and monsters
2. **Create new abilities** (14 total)
3. **Create new monster units** (4)
4. **Create new playable units** (5)
5. **Create Chapter 3 stages** (5)
6. **Update PlayerData** to add new units to gacha pools
7. **Update campaign screen** to show Chapter 3
8. **Add Chapter 3 Clear achievement** (already exists from v0.16 prep)
9. **Test all stages and units**

---

## Files to Create

### Sprites (extract from new_pack)
- `assets/sprites/gravebane/` (Greatsword Skeleton)
- `assets/sprites/ursok/` (Werebear)
- `assets/sprites/shade/` (Skeleton Archer)
- `assets/sprites/fenris/` (Werewolf)
- `assets/sprites/vance/` (Lancer)
- `assets/sprites/monster_werewolf/`
- `assets/sprites/monster_werebear/`
- `assets/sprites/monster_greatsword_skeleton/`

### Abilities
- `resources/abilities/soul_cleave.tres`
- `resources/abilities/deaths_embrace.tres`
- `resources/abilities/maul.tres`
- `resources/abilities/roar.tres`
- `resources/abilities/cursed_arrow.tres`
- `resources/abilities/shadow_shot.tres`
- `resources/abilities/pack_tactics.tres`
- `resources/abilities/savage_bite.tres`
- `resources/abilities/burning_thrust.tres`
- `resources/abilities/inferno_charge.tres`
- `resources/abilities/feral_bite.tres`
- `resources/abilities/crushing_swipe.tres`
- `resources/abilities/cleave.tres`
- `resources/abilities/alpha_howl.tres`

### Units
- `resources/units/gravebane.tres`
- `resources/units/ursok.tres`
- `resources/units/shade.tres`
- `resources/units/fenris.tres`
- `resources/units/vance.tres`
- `resources/units/monsters/werewolf.tres`
- `resources/units/monsters/werebear.tres`
- `resources/units/monsters/greatsword_skeleton.tres`
- `resources/units/monsters/alpha_werewolf.tres`

### Stages
- `resources/stages/chapter_3/stage_3_1.tres`
- `resources/stages/chapter_3/stage_3_2.tres`
- `resources/stages/chapter_3/stage_3_3.tres`
- `resources/stages/chapter_3/stage_3_4.tres`
- `resources/stages/chapter_3/stage_3_5.tres`

## Files to Modify

- `scripts/core/player_data.gd` - Add new units to gacha pools
- `scripts/ui/campaign_select_screen.gd` - Add Chapter 3 display
