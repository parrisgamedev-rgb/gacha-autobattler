# AI Sprite Sheet Guide

## Folder Structure
```
assets/sprites/
├── kael/           # Fire Warrior - first test unit
│   ├── idle.png    # Idle animation frames (3 frames, horizontal strip)
│   ├── attack.png  # Attack animation frames (3 frames)
│   └── hurt.png    # Hurt/damage animation (3 frames)
├── shared/         # Shared assets (effects, UI elements)
└── SPRITE_GUIDE.md
```

## Sprite Sheet Format
- **Frame size**: 128x128 pixels per frame (will be scaled in Godot)
- **Layout**: Horizontal strip (frames side by side)
- **Frame count**: 3 frames per animation
- **Total size**: 384x128 pixels per sprite sheet
- **Background**: Transparent (PNG with alpha)

## Animation Frames

### Idle (3 frames)
1. Neutral stance
2. Slight breathing motion (chest up)
3. Return to neutral

### Attack (3 frames)
1. Wind-up pose
2. Strike/swing motion
3. Follow-through

### Hurt (3 frames)
1. Impact reaction
2. Recoil
3. Recovery

## Art Style Reference
- Semi-realistic anime (Fire Emblem Heroes style)
- Clean linework with cel shading
- Vibrant colors matching element (Fire = red/orange palette)
