# Board Assets Guide

## Folder Structure
```
assets/board/
├── base/
│   └── grid.png          # Full 3x3 board (1024x1024)
├── ownership/
│   ├── player.png        # Blue hologram (512x512, transparent)
│   ├── enemy.png         # Red hologram (512x512, transparent)
│   └── contested.png     # Purple hologram (512x512, transparent)
├── field_effects/
│   ├── thermal.png       # Lava/fire effect (512x512, transparent)
│   ├── repair.png        # Green healing effect (512x512, transparent)
│   ├── boost.png         # Golden energy effect (512x512, transparent)
│   └── suppression.png   # Dark purple effect (512x512, transparent)
└── BOARD_GUIDE.md
```

## Layer Order (bottom to top)
1. Base grid (static)
2. Field effect overlay (per cell, optional)
3. Ownership hologram (per cell, optional)
4. Units (on top)

## Image Specs

### Base Grid
- Size: 1024x1024
- Format: PNG
- Style: Abstract minimal, dark gray geometric tiles
- Note: This replaces the current background image

### Ownership Holograms
- Size: 512x512 (scaled down in-game to ~100x100 per cell)
- Format: PNG with transparency
- Style: Glowing holographic emblems
- Colors: Blue (player), Red (enemy), Purple (contested)

### Field Effects
- Size: 512x512 (scaled down in-game)
- Format: PNG with transparency
- Style: Top-down textures that overlay on tiles
- Types: Thermal (lava), Repair (vines), Boost (gold), Suppression (shadow)
