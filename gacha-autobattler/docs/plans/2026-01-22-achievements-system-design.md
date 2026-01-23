# v0.16 Achievements System Design

## Overview

Add an achievements system that gives players goals to work toward and rewards for milestones. Achievements unlock automatically, grant gem rewards immediately, and display a celebratory popup notification.

## Design Decisions

- **Tracking**: Simple cumulative counters (battles_won, units_owned, etc.)
- **Rewards**: Auto-claimed when achievement unlocks
- **Notifications**: Appear anywhere, immediately when triggered
- **UI Assets**: Use existing UISpriteLoader assets (gold panels, banners, stars)

---

## Data Architecture

### AchievementData Resource

New resource type at `res://scripts/data/achievement_data.gd`:

```gdscript
extends Resource
class_name AchievementData

enum Category { BATTLE, COLLECTION, PROGRESSION }
enum RequirementType {
    BATTLES_WON,      # Win X battles
    UNITS_OWNED,      # Own X units
    STAGE_CLEARED,    # Clear specific stage (uses requirement_param)
    GEAR_ENHANCED,    # Enhance gear to +X
    TURNS_UNDER       # Win battle in under X turns
}

@export var id: String
@export var name: String
@export var description: String
@export var category: Category
@export var gem_reward: int
@export var requirement_type: RequirementType
@export var requirement_value: int
@export var requirement_param: String = ""  # For stage IDs, etc.
```

### PlayerData Additions

Add to `player_data.gd`:

```gdscript
# Achievement tracking
var achievement_stats: Dictionary = {
    "battles_won": 0,
    "units_owned": 0,
    "max_gear_level": 0,
    "fastest_win_turns": 999
}
var unlocked_achievements: Array = []  # Array of achievement IDs
```

Update `save_game()` and `load_game()` to persist these.

---

## AchievementManager Autoload

New singleton at `res://scripts/core/achievement_manager.gd`:

### Responsibilities
- Load all achievement definitions on startup
- Provide trigger methods called at key moments
- Check if achievements should unlock
- Grant rewards and show popup

### Trigger Methods

```gdscript
func on_battle_won(turn_count: int)
    # Increment battles_won
    # Update fastest_win_turns if lower
    # Check battle achievements

func on_unit_added()
    # Update units_owned count
    # Check collection achievements

func on_stage_cleared(stage_id: String)
    # Check progression achievements

func on_gear_enhanced(new_level: int)
    # Update max_gear_level if higher
    # Check gear achievements
```

### Integration Points

| Event | Where to Call | Method |
|-------|---------------|--------|
| Battle victory | `battle.gd` or `battle_results_animator.gd` | `on_battle_won(turn_count)` |
| Unit gained | `player_data.gd._add_unit_to_collection()` | `on_unit_added()` |
| Stage cleared | `player_data.gd.clear_stage()` | `on_stage_cleared(stage_id)` |
| Gear enhanced | `player_data.gd.enhance_gear()` | `on_gear_enhanced(level)` |

---

## Achievement Popup

### Scene Structure

`res://scenes/ui/achievement_popup.tscn` as CanvasLayer (layer 100):

```
AchievementPopup (CanvasLayer)
├── Overlay (ColorRect) - Dark semi-transparent, click to dismiss
└── Panel (NinePatchRect) - Gold panel, centered
    ├── Banner (NinePatchRect) - Gold TitleBanner with "ACHIEVEMENT"
    ├── Stars (HBoxContainer) - 3 gold stars
    ├── NameLabel (Label) - Achievement name
    ├── DescLabel (Label) - Description
    └── RewardLabel (Label) - "+50 Gems"
```

### Behavior
- Appears centered on screen with overlay
- Auto-dismisses after 3 seconds OR tap anywhere
- Queue multiple achievements, show one at a time
- Play celebration sound via AudioManager

### Assets Used
- `UISpriteLoader.PanelColor.GOLD` with "Panel" style
- `UISpriteLoader.BannerColor.GOLD` with "TitleBanner" style
- `UISpriteLoader.create_star_display(3, 3, StarColor.GOLD)`

---

## Achievement Gallery Screen

### Access
- New "ACHIEVEMENTS" button on main menu

### Scene Structure

`res://scenes/ui/achievement_gallery.tscn`:

```
AchievementGallery (Control)
├── Background - UISpriteLoader background
├── TopBar (Panel)
│   ├── BackButton
│   └── Title "ACHIEVEMENTS"
├── FilterBar (HBoxContainer)
│   ├── AllButton
│   ├── BattleButton
│   ├── CollectionButton
│   └── ProgressionButton
└── ScrollContainer
    └── AchievementGrid (GridContainer)
        └── [Achievement cards...]
```

### Achievement Card Design

Each card is a Panel (130x120):

**Unlocked State:**
- Gold panel background
- Name in gold/white text
- Description in secondary text
- "✓ 50 Gems" with checkmark (bright green text)

**Locked State:**
- White panel at 0.5 modulate (darkened)
- Name in gray text
- Description in secondary text
- Progress text: "5/10 battles" in white

---

## Achievements List (v0.16)

| ID | Name | Category | Type | Value | Param | Reward |
|----|------|----------|------|-------|-------|--------|
| first_blood | First Blood | BATTLE | BATTLES_WON | 1 | - | 50 |
| warrior | Warrior | BATTLE | BATTLES_WON | 10 | - | 100 |
| veteran | Veteran | BATTLE | BATTLES_WON | 50 | - | 250 |
| speed_demon | Speed Demon | BATTLE | TURNS_UNDER | 10 | - | 75 |
| collector | Collector | COLLECTION | UNITS_OWNED | 10 | - | 100 |
| gear_up | Gear Up | COLLECTION | GEAR_ENHANCED | 6 | - | 50 |
| chapter_1_clear | Chapter 1 Clear | PROGRESSION | STAGE_CLEARED | 1 | 1-5 | 200 |
| chapter_2_clear | Chapter 2 Clear | PROGRESSION | STAGE_CLEARED | 1 | 2-5 | 300 |

Total possible gems from achievements: 1,125

---

## Implementation Order

1. **AchievementData resource** - Define the data structure
2. **Achievement .tres files** - Create the 8 achievement resources
3. **PlayerData additions** - Add stats tracking and save/load
4. **AchievementManager autoload** - Core logic and trigger methods
5. **AchievementPopup scene** - Notification UI
6. **Integration hooks** - Add trigger calls to existing code
7. **AchievementGallery scene** - Gallery screen
8. **Main menu button** - Add access to gallery
9. **Testing** - Verify all achievements trigger correctly

---

## Files to Create

- `scripts/data/achievement_data.gd` - Resource class
- `scripts/core/achievement_manager.gd` - Autoload singleton
- `scenes/ui/achievement_popup.tscn` - Popup scene
- `scenes/ui/achievement_popup.gd` - Popup script
- `scenes/ui/achievement_gallery.tscn` - Gallery scene
- `scenes/ui/achievement_gallery.gd` - Gallery script
- `resources/achievements/` - Directory for .tres files

## Files to Modify

- `scripts/core/player_data.gd` - Add stats tracking, save/load
- `project.godot` - Add AchievementManager autoload
- `scenes/ui/main_menu.tscn` - Add achievements button
- `scripts/battle/battle.gd` or results animator - Add victory hook
