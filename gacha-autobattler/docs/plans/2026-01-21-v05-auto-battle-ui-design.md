# v0.5 Design: Auto-Battle & UI Overhaul

## Overview

Add auto-battle with speed controls and overhaul all UI screens with a consistent design system.

---

## Part 1: Auto-Battle System

### Controls
- **Auto Toggle**: Button showing "AUTO: OFF" or "AUTO: ON"
  - OFF: Gray outline, transparent background
  - ON: Blue (#4a9eff) filled background
- **Speed Buttons**: Radio-style group [1x] [2x] [3x]
  - Only one active at a time
  - Active button highlighted in blue
  - 1x = normal, 2x = half delays, 3x = quarter delays

### Placement in Battle UI
```
┌─────────────────────────────────────────────────────────┐
│  [AUTO: OFF]   [1x] [2x] [3x]              [END TURN]   │
└─────────────────────────────────────────────────────────┘
```
Bottom bar, auto/speed on left, End Turn on right.

### Auto-Battle AI Behavior
- Uses same cell evaluation logic as enemy AI
- Picks highest-rated available unit from roster
- Selects ability with highest damage multiplier (or heal if any unit low HP)
- Automatically ends turn when actions exhausted

### Speed Implementation
- Global `battle_speed` multiplier: 1.0 (1x), 0.5 (2x), 0.25 (3x)
- Applied to all `create_timer()` calls
- Applied to tween durations
- Combat announcements shortened at higher speeds

---

## Part 2: Design System

### Color Palette

**Backgrounds:**
- `bg_dark`: #1a1a2e (deep navy) - main background
- `bg_medium`: #252542 (slate) - panels, cards
- `bg_light`: #2d2d4a (lighter slate) - hover states

**Accents:**
- `primary`: #4a9eff (bright blue) - main buttons, highlights
- `secondary`: #7c5cff (purple) - secondary actions
- `success`: #4ade80 (green) - victory, healing, positive
- `danger`: #f87171 (red) - defeat, damage, warnings
- `gold`: #fbbf24 (amber) - currency, stars, premium

**Rarity:**
- 3-star: #9ca3af (gray)
- 4-star: #a78bfa (purple)
- 5-star: #fbbf24 (gold)

**Text:**
- `text_primary`: #ffffff (white)
- `text_secondary`: #94a3b8 (muted)
- `text_disabled`: #4b5563 (dark gray)

### Typography

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| title_large | 32px | Bold, uppercase | Screen titles |
| title_medium | 24px | Bold | Section headers |
| title_small | 18px | Bold | Card titles |
| body | 16px | Regular | Descriptions, stats |
| caption | 14px | Medium | Labels, secondary |
| small | 12px | Regular | Tooltips, minor |

### Spacing Scale

- `xs`: 4px - tight gaps
- `sm`: 8px - related items
- `md`: 16px - section padding
- `lg`: 24px - major breaks
- `xl`: 32px - screen margins

### Components

**Buttons:**
- Primary: Blue bg, white text, 8px radius, 12/24px padding
- Secondary: Transparent bg, blue border, blue text
- Danger: Red bg for destructive actions
- Icon: 40x40px square, transparent bg

**Panels:**
- Card: bg_medium, 8px radius, 2px border, 12px padding
- Modal: bg_dark, 12px radius, drop shadow, overlay
- Tooltip: bg_light, 4px radius, small text

**Unit Cards:**
- Size: 160x200px
- Rarity border glow (3px)
- Hover: 1.02x scale, brighter border

**Stat Bars:**
- HP: Green fill, 8px height, rounded
- XP: Blue fill, 4px height

---

## Part 3: Screen Layouts

### Screen Structure (All Screens)
```
┌─────────────────────────────────────────┐
│  TOP BAR (64px)                         │
│  [Back]  SCREEN TITLE      [Currency]   │
├─────────────────────────────────────────┤
│  CONTENT AREA                           │
│  (xl margins, lg spacing)               │
├─────────────────────────────────────────┤
│  BOTTOM BAR (optional, 80px)            │
│  [Primary Action]                       │
└─────────────────────────────────────────┘
```

### Main Menu
- Centered vertical layout
- Primary buttons full-width: Campaign, Dungeons, Quick Battle
- Secondary 2x2 grid: Summon, Collection, Gear, PvP
- Currency bar at bottom

### Battle Screen
- Top bar: Turn, phase, actions
- Left: Player roster (vertical)
- Center: 3x3 grid
- Right: Enemy roster (vertical)
- Ability panel: Horizontal, shows cooldowns
- Bottom: Auto/speed controls + End Turn

### Collection Screen
- Left panel: Scrollable unit grid (4 columns)
- Right panel: Selected unit details
  - Stats with labels
  - Gear slots (2x2)
  - Level Up / Abilities buttons
- Filter/sort dropdowns

### Gear Inventory
- Filter tabs: All, Weapon, Armor, Accessory
- Left: Gear grid (5 columns)
- Right: Selected gear details
  - Enhancement progress bar
  - Cost display
  - Enhance / Unequip buttons

### Dungeon Select
- 2x2 dungeon grid (each shows stat type)
- Difficulty selection below: Easy, Normal, Hard
- Shows enemy level per difficulty

### Campaign Select
- Chapter header
- Horizontal stage progression (1-5)
- Locked stages show lock icon
- Stage info panel with Start button

### Team Select
- Top: Selected team row (5 slots, empty shows +)
- Middle: Available units grid
- Bottom: Stage info + Start Battle button

---

## Implementation Notes

- All screens should use consistent top bar with currency display
- Use Godot theme resources for reusable styles
- Consider creating a UITheme autoload for color/size constants
- Battle speed affects: timers, tweens, animation_speed
- Auto-battle toggle persists until manually turned off
