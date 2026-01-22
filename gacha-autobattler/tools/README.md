# Sprite Tools

## Setup

```bash
cd tools
pip install -r requirements.txt
```

## sprite_sheet_maker.py

Extracts frames from video/GIF and creates sprite sheets.

### Basic Usage

```bash
# Extract 3 frames from a GIF, create 128px sprite sheet
python sprite_sheet_maker.py idle.gif ../assets/sprites/kael/idle.png

# Extract from MP4 video
python sprite_sheet_maker.py kael_attack.mp4 ../assets/sprites/kael/attack.png
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `--frames`, `-f` | Number of frames to extract | 3 |
| `--size`, `-s` | Frame size in pixels | 128 |
| `--remove-bg`, `-r` | Remove white background | off |
| `--tolerance`, `-t` | BG removal tolerance (0-255) | 30 |
| `--vertical`, `-v` | Stack vertically | horizontal |
| `--preview`, `-p` | Also save individual frames | off |

### Examples

```bash
# 5 frames at 64px size
python sprite_sheet_maker.py attack.gif attack.png -f 5 -s 64

# Remove white background with high tolerance
python sprite_sheet_maker.py idle.mp4 idle.png -r -t 50

# Preview individual frames before committing
python sprite_sheet_maker.py hurt.gif hurt.png -p
```

### Workflow

1. Generate character image in Scenario.gg
2. Use Scenario's Animate feature (or Runway/Pika) to create short loop
3. Download as MP4 or GIF
4. Run this script to extract frames and create sprite sheet
5. Drop sprite sheet in `assets/sprites/kael/`
