"""
Organize sprites from the Tiny RPG Character Asset Pack into the game's folder structure.
Maps sprites to game units (heroes and monsters).
"""

import shutil
import os
from pathlib import Path

# Base paths
GAME_ROOT = Path(__file__).parent.parent
SPRITE_PACK = GAME_ROOT / "assets/sprites/new_pack/Tiny RPG Character Asset Pack v1.03 -Full 20 Characters/Characters(100x100)"
SPRITES_OUTPUT = GAME_ROOT / "assets/sprites"

# Mapping: sprite_pack_folder -> (game_folder_name, is_monster)
SPRITE_MAPPING = {
    # PLAYABLE HEROES
    "Knight": ("fire_warrior", False),
    "Swordsman": ("ember", False),
    "Wizard": ("water_mage", False),
    "Priest": ("coral", False),
    "Archer": ("nature_wisp", False),
    "Armored Axeman": ("nature_tank", False),
    "Knight Templar": ("radiant_paladin", False),
    "Lancer": ("spark", False),
    "Skeleton": ("shadow_scout", False),
    "Armored Skeleton": ("dark_knight", False),

    # MONSTERS (enemy-only)
    "Orc": ("monster_goblin", True),
    "Elite Orc": ("monster_gladiator_beast", True),
    "Armored Orc": ("monster_minotaur", True),
    "Werewolf": ("monster_wolf", True),
    "Werebear": ("monster_arena_champion", True),
    "Slime": ("monster_slime", True),
    "Greatsword Skeleton": ("monster_skeleton_warrior", True),
    "Skeleton Archer": ("monster_harpy", True),
    "Orc rider": ("monster_chimera", True),
    "Soldier": ("monster_gladiator", True),
}

# Animation file mapping (source pattern -> output name)
ANIMATION_MAPPING = {
    "Idle": "idle",
    "Attack01": "attack",
    "Hurt": "hurt",
    "DEATH": "death",
    "Walk": "walk",
    "Attack02": "attack2",
}

def find_sprite_file(sprite_folder: Path, char_name: str, anim_type: str) -> Path:
    """Find the sprite file for a given character and animation."""
    # The structure is: Character/Character/Character-Animation.png
    inner_folder = sprite_folder / char_name
    if not inner_folder.exists():
        # Try without inner folder
        inner_folder = sprite_folder

    # Look for the animation file
    pattern = f"{char_name}-{anim_type}.png"
    for file in inner_folder.glob("*.png"):
        if file.name.lower() == pattern.lower():
            return file
        # Handle case variations
        if anim_type.lower() in file.name.lower() and not file.name.endswith(".import"):
            if "shadow" not in file.name.lower():  # Skip shadow sprites
                return file

    return None

def organize_sprites():
    """Copy and organize all sprites."""
    print(f"Source: {SPRITE_PACK}")
    print(f"Output: {SPRITES_OUTPUT}")
    print()

    for pack_folder, (game_name, is_monster) in SPRITE_MAPPING.items():
        print(f"Processing: {pack_folder} -> {game_name}")

        source_folder = SPRITE_PACK / pack_folder
        if not source_folder.exists():
            print(f"  WARNING: Source folder not found: {source_folder}")
            continue

        # Create output folder
        output_folder = SPRITES_OUTPUT / game_name
        output_folder.mkdir(parents=True, exist_ok=True)

        # Copy each animation
        for source_anim, output_anim in ANIMATION_MAPPING.items():
            # Find the source file
            sprite_file = find_sprite_file(source_folder, pack_folder, source_anim)

            if sprite_file and sprite_file.exists():
                output_file = output_folder / f"{output_anim}.png"
                shutil.copy2(sprite_file, output_file)
                print(f"  Copied: {source_anim} -> {output_anim}.png")
            else:
                # Try alternate naming
                inner = source_folder / pack_folder
                if inner.exists():
                    for f in inner.glob(f"*{source_anim}*.png"):
                        if not f.name.endswith(".import") and "shadow" not in f.name.lower():
                            output_file = output_folder / f"{output_anim}.png"
                            shutil.copy2(f, output_file)
                            print(f"  Copied: {f.name} -> {output_anim}.png")
                            break

        print()

    print("Done! Sprites organized.")

if __name__ == "__main__":
    organize_sprites()
