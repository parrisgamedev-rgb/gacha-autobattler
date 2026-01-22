# Gacha Autobattler Content Editor

A desktop application for managing game content (units, abilities, gear, stages, dungeons, and assets).

## Requirements

- Python 3.10 or higher
- Windows 10/11

## Quick Start

### Option 1: Run directly (recommended for development)

1. Double-click `run.bat`
2. The editor will install dependencies automatically on first run

### Option 2: Build standalone executable

1. Double-click `build.bat`
2. Wait for the build to complete
3. Find `ContentEditor.exe` in the `dist/` folder

## Features

### Units
- Create, edit, and delete units
- Set name, element, star rating, and base stats
- Assign abilities from the abilities list
- Filter by element or search by name

### Abilities
- Create, edit, and delete abilities
- Configure damage/defense multipliers, healing, cooldowns
- Set special effects (piercing, counter, guaranteed survive)

### Gear
- Create, edit, and delete gear items
- Set gear type, rarity, and stat bonuses
- Configure flat or percentage bonuses

### Stages
- Create, edit, and delete campaign stages
- Configure enemy levels and rewards
- Set difficulty ratings

### Dungeons
- Create, edit, and delete gear dungeons
- Configure stat type drops

### Assets
- Import unit sprites (idle, attack, hurt animations)
- Import board backgrounds and overlays
- Browse existing assets

## File Locations

The editor reads and writes to:
- `resources/units/` - Unit definitions
- `resources/abilities/` - Ability definitions
- `resources/gear/` - Gear definitions
- `resources/stages/` - Stage definitions
- `resources/dungeons/` - Dungeon definitions
- `assets/units/ai_sprites/` - Unit sprite sheets
- `assets/board/` - Board images

## Workflow

1. Make changes in the editor
2. Click "Save" to write changes to `.tres` files
3. Changes take effect next time you run the game
4. Commit changes to git when ready to distribute

## Troubleshooting

**"Could not find game directory"**
- Make sure you're running the editor from within the `tools/content_editor/` folder

**"Missing dependencies"**
- Run `pip install -r requirements.txt`

**Changes not appearing in game**
- Make sure you saved your changes (click the Save button)
- Restart the Godot game to reload resources
