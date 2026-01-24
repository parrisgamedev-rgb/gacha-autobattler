# Battle Board Redesign

## Overview

Redesign the battle board system so grid cells and the board feel like one cohesive piece of art rather than separate layers. Replace pre-generated background images with runtime-assembled tiles.

## Problem

Current implementation has:
- Pre-generated board background images (1200x1120px PNGs)
- Grid cells as a separate layer placed on top
- Visual disconnect - cells don't match board style
- Two different tileset styles that clash

## Solution

Hybrid approach: Runtime-placed grid tiles + wall framing + props, all from the same tileset.

## Design

### Board Structure

```
████████████████████████████████████
██ W   W   W   W   W   W   W   W ██
██ W   W   W   W   W   W   W   W ██   W = Wall tile (2 rows thick)
██ W   W [B]         [C] W   W ██   F = Floor tile (grid cell)
██ W   W     ┌───┬───┬───┐ W   W ██   [B] = Barrel prop
██ W   W [T] │ F │ F │ F │     W ██   [C] = Chest prop
██ W   W     ├───┼───┼───┤     W ██   [T] = Table prop
██ W   W     │ F │ F │ F │ [B] W ██
██ W   W     ├───┼───┼───┤     W ██
██ W   W     │ F │ F │ F │     W ██
██ W   W [C] └───┴───┴───┘ [B] W ██
██ W   W         [T]         W ██
██ W   W   W   W   W   W   W   W ██
██ W   W   W   W   W   W   W   W ██
████████████████████████████████████
```

### Layers (bottom to top)

1. **Background** - Dark ColorRect (void beyond outer walls)
2. **Outer wall tiles** - 2 rows of wall tiles forming room boundary
3. **Floor tiles** - 9 tiles in 3x3 grid (the gameplay area)
4. **Props** - Decorative sprites along inner wall edges
5. **Grid cells** - Invisible Area2D hitboxes for interaction + overlays

### Tile Sizing

- Kenney Tiny Dungeon tiles: 16px base
- Scale factor: 5x
- Resulting tile size: 80px
- Grid cell size: 80px (down from current 90px)

**Layout math (1024x768 viewport):**
- Grid: 3 cells × 80px = 240px
- Walls: 2 tiles × 80px × 2 sides = 320px
- Total board width: 560px
- Horizontal margin: (1024 - 560) / 2 = 232px each side

### Theme Variations

**Chapter 1 - Dungeon:**
- Floor: Light stone (tile_0048, 0049)
- Walls: Gray brick (tile_0024/0025 faces, tile_0012/0013 tops)
- Props: Barrels, crates, chests, tables

**Chapter 2 - Dark Dungeon:**
- Floor: Stone tiles with darker tint (modulate)
- Walls: Darker variant (tile_0036, 0037)
- Props: Barrels, chests, skulls - sparser, more ominous

**Chapter 3 - Arena:**
- Floor: Warmer stone (tile_0050, 0051)
- Walls: Standard dungeon walls
- Props: Barrels, crates positioned for arena feel

### Board Variants

Each chapter has 3 boards (e.g., dungeon_1, dungeon_2, dungeon_3).

Variation comes from:
- Which props appear (randomized from theme pool)
- Prop positions (randomized from valid spots)
- Prop density (sparse → medium → dense)

Structure and tiles stay consistent within a theme.

### Props Placement

**Valid positions:**
- 4 corner spots (inside wall frame)
- 4 mid-wall spots (top, bottom, left, right)

**Rules:**
- 4-8 props per board
- Never overlap grid cells
- Purely decorative (no collision/gameplay impact)

### Grid Cell Changes

Current GridCell has:
- Background TextureRect (tile texture)
- Border Panel
- OwnerIndicator ColorRect
- HoverEffect TextureRect
- CollisionShape2D

New GridCell (interaction-only):
- CollisionShape2D (click detection)
- HoverEffect (semi-transparent overlay)
- OwnerIndicator (colored overlay for player/enemy/contested)

Floor tiles are separate Sprite2D nodes placed by BoardBuilder, not part of GridCell.

### File Changes

**Modified:**
- `battle.gd` - New grid constants (CELL_SIZE=80), calls BoardBuilder
- `battle.tscn` - Remove GameBoard TextureRect, adjust GridContainer position
- `grid_cell.tscn` - Remove Background texture, simplify to interaction-only
- `grid_cell.gd` - Remove tile texture handling

**New:**
- `scripts/battle/board_builder.gd` - Assembles tiles at runtime

**Possibly removed:**
- `scripts/tools/board_generator.gd` - No longer needed for pre-generated images
- `assets/board/boards/*.png` - Pre-generated boards replaced by runtime assembly

## Future Work (Phase 2)

**Bench Integration:**
- Integrate unit rosters (benches) into the dungeon room layout
- Make them appear as alcoves or side chambers
- Currently staying as UI panels until board is solid

## Implementation Notes

- Create feature branch before starting
- Kenney tiles are at `res://assets/kenney_tiny-dungeon/Tiles/`
- Wall tiles need proper top/face handling for depth
- Test each theme after implementation
