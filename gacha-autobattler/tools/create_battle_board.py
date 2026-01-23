"""
Create battle board backgrounds using various tilesets.
Supports multiple themes: dungeon, forest, cloud/sky.
"""

from PIL import Image
import os
from pathlib import Path

# Paths
GAME_ROOT = Path(__file__).parent.parent
TILES_DIR = GAME_ROOT / "assets/board/tiles"
FOREST_DIR = GAME_ROOT / "assets/board/forest tileset"
CLOUD_DIR = GAME_ROOT / "assets/board/cloud_tileset"
OUTPUT_DIR = GAME_ROOT / "assets/board"
BOARDS_DIR = OUTPUT_DIR / "boards"

# Tile sizes
DUNGEON_TILE_SIZE = 32
FOREST_TILE_SIZE = 16

def extract_tile(img, col, row, tile_size=DUNGEON_TILE_SIZE):
    """Extract a single tile from the tileset."""
    x = col * tile_size
    y = row * tile_size
    return img.crop((x, y, x + tile_size, y + tile_size))

def create_battle_board():
    """Create the main battle board background."""

    # Load tilesets
    walls_floors = Image.open(TILES_DIR / "Dungeon_WallsAndFloors.png").convert("RGBA")
    decorations = Image.open(TILES_DIR / "DungeonDecorations.png").convert("RGBA")

    # Board dimensions (in tiles)
    # We want a larger arena with the 3x3 grid in the center
    board_width_tiles = 20
    board_height_tiles = 14

    # Create the board canvas
    board_width = board_width_tiles * DUNGEON_TILE_SIZE
    board_height = board_height_tiles * DUNGEON_TILE_SIZE
    board = Image.new("RGBA", (board_width, board_height), (0, 0, 0, 255))

    # Extract useful tiles from Dungeon_WallsAndFloors.png
    # Row 0: Stone floor variations
    stone_floor_1 = extract_tile(walls_floors, 0, 0)  # Main stone floor
    stone_floor_2 = extract_tile(walls_floors, 1, 0)  # Stone floor variant
    stone_floor_3 = extract_tile(walls_floors, 2, 0)  # Stone floor variant

    # Row 4-5: Brick/wall tiles (yellow/gold bricks)
    gold_brick = extract_tile(walls_floors, 0, 4)

    # Fill the entire board with stone floor first
    for y in range(board_height_tiles):
        for x in range(board_width_tiles):
            # Alternate floor tiles for variety
            if (x + y) % 3 == 0:
                tile = stone_floor_2
            elif (x + y) % 3 == 1:
                tile = stone_floor_3
            else:
                tile = stone_floor_1
            board.paste(tile, (x * DUNGEON_TILE_SIZE, y * DUNGEON_TILE_SIZE))

    # Add a border around the arena with gold bricks
    # Top and bottom borders
    for x in range(board_width_tiles):
        board.paste(gold_brick, (x * DUNGEON_TILE_SIZE, 0))
        board.paste(gold_brick, (x * DUNGEON_TILE_SIZE, (board_height_tiles - 1) * DUNGEON_TILE_SIZE))

    # Left and right borders
    for y in range(board_height_tiles):
        board.paste(gold_brick, (0, y * DUNGEON_TILE_SIZE))
        board.paste(gold_brick, ((board_width_tiles - 1) * DUNGEON_TILE_SIZE, y * DUNGEON_TILE_SIZE))

    # Scale up for the game (the game expects a larger board)
    final_width = 1920
    final_height = 1080
    board = board.resize((final_width, final_height), Image.NEAREST)

    # Save the board - both to legacy location and boards folder
    BOARDS_DIR.mkdir(exist_ok=True)
    output_path = OUTPUT_DIR / "dungeon_board.png"
    board.save(output_path)
    board.save(BOARDS_DIR / "chapter_2_board.png")  # Arena/Dungeon for Chapter 2
    print(f"Saved dungeon board to: {output_path}")

    return board


def create_forest_board():
    """Create a forest-themed battle board for Chapter 1."""

    # Load forest tiles - use the 3x3 simplified versions for cleaner tiling
    grass_3x3 = Image.open(FOREST_DIR / "grass_3x3.png").convert("RGBA")
    grass_dark_3x3 = Image.open(FOREST_DIR / "grass_dark_3x3.png").convert("RGBA")

    # Load decorations for border
    tree1 = Image.open(FOREST_DIR / "tree1.png").convert("RGBA")
    tree2 = Image.open(FOREST_DIR / "tree2.png").convert("RGBA")
    bush1 = Image.open(FOREST_DIR / "decor_bush1.png").convert("RGBA")
    bush2 = Image.open(FOREST_DIR / "decor_bush2.png").convert("RGBA")

    # grass_3x3 is 144x48 - that's 3 tiles of 48x48
    GRASS_TILE = 48

    def extract_grass_tile(img, index):
        """Extract a 48x48 tile from the 3x3 grass sheet."""
        x = index * GRASS_TILE
        return img.crop((x, 0, x + GRASS_TILE, GRASS_TILE))

    # Get the three grass variants
    grass_tiles = [extract_grass_tile(grass_3x3, i) for i in range(3)]
    grass_dark_tiles = [extract_grass_tile(grass_dark_3x3, i) for i in range(3)]

    # Board dimensions (using 48x48 tiles)
    board_width = 1200
    board_height = 750

    # Create base board with dark green background
    board = Image.new("RGBA", (board_width, board_height), (25, 40, 20, 255))

    # Fill with grass tiles - mix light and dark for natural look
    import random
    random.seed(42)  # Consistent generation

    tiles_x = board_width // GRASS_TILE + 1
    tiles_y = board_height // GRASS_TILE + 1

    for y in range(tiles_y):
        for x in range(tiles_x):
            # Mostly light grass, some dark patches
            if random.random() < 0.25:
                tile = random.choice(grass_dark_tiles)
            else:
                tile = random.choice(grass_tiles)
            board.paste(tile, (x * GRASS_TILE, y * GRASS_TILE))

    # Add trees around the border
    tree_positions = []

    # Top edge trees
    for x in range(0, board_width, 80):
        tree_positions.append((x + random.randint(-10, 10), random.randint(-20, 30)))

    # Bottom edge trees
    for x in range(0, board_width, 80):
        tree_positions.append((x + random.randint(-10, 10), board_height - 100 + random.randint(-10, 20)))

    # Left edge trees
    for y in range(100, board_height - 100, 100):
        tree_positions.append((random.randint(-20, 40), y + random.randint(-20, 20)))

    # Right edge trees
    for y in range(100, board_height - 100, 100):
        tree_positions.append((board_width - 80 + random.randint(-20, 20), y + random.randint(-20, 20)))

    # Draw trees
    trees = [tree1, tree2]
    for px, py in tree_positions:
        tree = random.choice(trees)
        # Scale tree up a bit
        scaled_tree = tree.resize((tree.width * 3, tree.height * 3), Image.NEAREST)
        board.paste(scaled_tree, (px, py), scaled_tree)

    # Add some bushes in front of trees
    for px, py in tree_positions[::2]:
        bush = random.choice([bush1, bush2])
        scaled_bush = bush.resize((bush.width * 2, bush.height * 2), Image.NEAREST)
        board.paste(scaled_bush, (px + 20, py + 60), scaled_bush)

    # Scale to game resolution
    board = board.resize((1920, 1080), Image.NEAREST)

    # Save
    BOARDS_DIR.mkdir(exist_ok=True)
    board.save(BOARDS_DIR / "chapter_1_board.png")
    print(f"Saved forest board to: {BOARDS_DIR / 'chapter_1_board.png'}")

    return board


def create_cloud_board():
    """Create a cloud/sky-themed battle board for future chapters."""

    # Load cloud tileset
    cloud_tiles = Image.open(CLOUD_DIR / "cloud_tileset.png").convert("RGBA")
    bg_sky = Image.open(CLOUD_DIR / "bg_bluesky.png").convert("RGBA")

    # Cloud tiles appear to be 16x16
    def extract_cloud_tile(img, col, row, size=16):
        x = col * size
        y = row * size
        return img.crop((x, y, x + size, y + size))

    # Extract cloud platform tiles (examine tileset for good ones)
    # Top row usually has platform tops
    cloud_top = extract_cloud_tile(cloud_tiles, 1, 1)
    cloud_mid = extract_cloud_tile(cloud_tiles, 1, 2)
    cloud_fill = extract_cloud_tile(cloud_tiles, 2, 2)

    # Board dimensions
    board_width = 1920
    board_height = 1080

    # Create sky background by tiling
    board = Image.new("RGBA", (board_width, board_height), (135, 206, 235, 255))

    # Tile the sky background
    sky_w, sky_h = bg_sky.size
    for y in range(0, board_height, sky_h):
        for x in range(0, board_width, sky_w):
            board.paste(bg_sky, (x, y))

    # Add cloud platforms in the arena area
    cloud_tile_size = 16
    arena_left = 400
    arena_top = 200
    arena_width = 35
    arena_height = 20

    for y in range(arena_height):
        for x in range(arena_width):
            px = arena_left + x * cloud_tile_size
            py = arena_top + y * cloud_tile_size
            if y == 0:
                board.paste(cloud_top, (px, py), cloud_top)
            elif y == arena_height - 1:
                board.paste(cloud_mid, (px, py), cloud_mid)
            else:
                board.paste(cloud_fill, (px, py), cloud_fill)

    # Scale with nearest neighbor to keep pixel art crisp
    # (already at target resolution)

    # Save
    BOARDS_DIR.mkdir(exist_ok=True)
    board.save(BOARDS_DIR / "chapter_3_board.png")
    print(f"Saved cloud board to: {BOARDS_DIR / 'chapter_3_board.png'}")

    return board


def create_grid_cell_tile():
    """Create grid cell tiles for each theme."""

    CELLS_DIR = OUTPUT_DIR / "cells"
    CELLS_DIR.mkdir(exist_ok=True)

    # === DUNGEON CELL ===
    walls_floors = Image.open(TILES_DIR / "Dungeon_WallsAndFloors.png").convert("RGBA")
    base_tile = extract_tile(walls_floors, 0, 0)

    cell_size_tiles = 4
    cell = Image.new("RGBA", (cell_size_tiles * DUNGEON_TILE_SIZE, cell_size_tiles * DUNGEON_TILE_SIZE), (0, 0, 0, 0))

    for y in range(cell_size_tiles):
        for x in range(cell_size_tiles):
            cell.paste(base_tile, (x * DUNGEON_TILE_SIZE, y * DUNGEON_TILE_SIZE))

    # Add border
    add_cell_border(cell, (80, 70, 60, 255))
    cell = cell.resize((150, 150), Image.NEAREST)

    # Save dungeon cell
    cell.save(OUTPUT_DIR / "grid_cell_tile.png")  # Legacy location
    cell.save(CELLS_DIR / "chapter_2_cell.png")
    print(f"Saved dungeon grid cell")

    # === FOREST CELL ===
    grass_3x3 = Image.open(FOREST_DIR / "grass_3x3.png").convert("RGBA")

    # Extract a 48x48 grass tile
    grass_tile = grass_3x3.crop((0, 0, 48, 48))

    # Create cell from grass (3x3 of 48px tiles = 144x144)
    forest_cell = Image.new("RGBA", (144, 144), (30, 50, 25, 255))

    for y in range(3):
        for x in range(3):
            forest_cell.paste(grass_tile, (x * 48, y * 48))

    # Add natural wood/earth border
    add_cell_border(forest_cell, (60, 45, 30, 255))
    forest_cell = forest_cell.resize((150, 150), Image.NEAREST)
    forest_cell.save(CELLS_DIR / "chapter_1_cell.png")
    print(f"Saved forest grid cell")

    # === CLOUD CELL ===
    cloud_tiles = Image.open(CLOUD_DIR / "cloud_tileset.png").convert("RGBA")

    def extract_cloud_tile(img, col, row, size=16):
        x = col * size
        y = row * size
        return img.crop((x, y, x + size, y + size))

    cloud_tile = extract_cloud_tile(cloud_tiles, 2, 2)

    cloud_cell_tiles = 8
    cloud_cell = Image.new("RGBA", (cloud_cell_tiles * 16, cloud_cell_tiles * 16), (200, 220, 255, 255))

    for y in range(cloud_cell_tiles):
        for x in range(cloud_cell_tiles):
            cloud_cell.paste(cloud_tile, (x * 16, y * 16), cloud_tile)

    add_cell_border(cloud_cell, (180, 200, 255, 255))
    cloud_cell = cloud_cell.resize((150, 150), Image.NEAREST)
    cloud_cell.save(CELLS_DIR / "chapter_3_cell.png")
    print(f"Saved cloud grid cell")

    return cell


def add_cell_border(cell, border_color):
    """Add a border to a cell image."""
    pixels = cell.load()
    width, height = cell.size

    for i in range(2):
        for x in range(width):
            pixels[x, i] = border_color
            pixels[x, height - 1 - i] = border_color
        for y in range(height):
            pixels[i, y] = border_color
            pixels[width - 1 - i, y] = border_color

def create_cell_highlight():
    """Create highlight overlays for grid cells."""

    size = 150

    # Player highlight (blue)
    player_highlight = Image.new("RGBA", (size, size), (50, 100, 200, 80))
    player_highlight.save(OUTPUT_DIR / "cell_highlight_player.png")

    # Enemy highlight (red)
    enemy_highlight = Image.new("RGBA", (size, size), (200, 50, 50, 80))
    enemy_highlight.save(OUTPUT_DIR / "cell_highlight_enemy.png")

    # Contested highlight (purple)
    contested_highlight = Image.new("RGBA", (size, size), (150, 50, 150, 80))
    contested_highlight.save(OUTPUT_DIR / "cell_highlight_contested.png")

    # Hover highlight (white)
    hover_highlight = Image.new("RGBA", (size, size), (255, 255, 255, 40))
    hover_highlight.save(OUTPUT_DIR / "cell_highlight_hover.png")

    print("Saved cell highlight textures")


def apply_color_tint(img, tint_color, intensity=0.5):
    """Apply a color tint to an image while preserving some detail."""
    # Convert to RGBA if needed
    img = img.convert("RGBA")

    # Create a tinted version
    r, g, b = tint_color
    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            pr, pg, pb, pa = pixels[x, y]
            # Blend original color with tint
            nr = int(pr * (1 - intensity) + r * intensity)
            ng = int(pg * (1 - intensity) + g * intensity)
            nb = int(pb * (1 - intensity) + b * intensity)
            pixels[x, y] = (nr, ng, nb, pa)

    return img


def create_ownership_overlays():
    """Create tile-based ownership overlays for each chapter theme."""

    size = 150

    # Create chapter-specific directories
    for chapter in [1, 2, 3]:
        chapter_dir = OUTPUT_DIR / "ownership" / f"chapter_{chapter}"
        chapter_dir.mkdir(parents=True, exist_ok=True)

    # Also keep default for quick battle
    default_dir = OUTPUT_DIR / "ownership"
    default_dir.mkdir(exist_ok=True)

    # === CHAPTER 2 / DEFAULT (Dungeon) ===
    walls_floors = Image.open(TILES_DIR / "Dungeon_WallsAndFloors.png").convert("RGBA")
    dungeon_tile = extract_tile(walls_floors, 1, 0)

    def create_dungeon_overlay(tint_color):
        cell_size_tiles = 4
        overlay = Image.new("RGBA", (cell_size_tiles * DUNGEON_TILE_SIZE, cell_size_tiles * DUNGEON_TILE_SIZE), (0, 0, 0, 255))
        for y in range(cell_size_tiles):
            for x in range(cell_size_tiles):
                overlay.paste(dungeon_tile, (x * DUNGEON_TILE_SIZE, y * DUNGEON_TILE_SIZE))
        overlay = apply_color_tint(overlay, tint_color, 0.5)
        make_opaque_with_border(overlay, tint_color)
        return overlay.resize((size, size), Image.NEAREST)

    # Dungeon overlays
    for name, color in [("player", (60, 120, 220)), ("enemy", (200, 60, 60)), ("contested", (160, 60, 180))]:
        overlay = create_dungeon_overlay(color)
        overlay.save(default_dir / f"{name}.png")
        overlay.save(OUTPUT_DIR / "ownership" / "chapter_2" / f"{name}.png")
    print("Saved dungeon ownership overlays (chapter 2 / default)")

    # === CHAPTER 1 (Forest) ===
    grass_3x3 = Image.open(FOREST_DIR / "grass_3x3.png").convert("RGBA")
    grass_tile = grass_3x3.crop((0, 0, 48, 48))

    def create_forest_overlay(tint_color):
        overlay = Image.new("RGBA", (144, 144), (30, 50, 25, 255))
        for y in range(3):
            for x in range(3):
                overlay.paste(grass_tile, (x * 48, y * 48))
        overlay = apply_color_tint(overlay, tint_color, 0.5)
        make_opaque_with_border(overlay, tint_color)
        return overlay.resize((size, size), Image.NEAREST)

    for name, color in [("player", (60, 150, 120)), ("enemy", (180, 80, 60)), ("contested", (140, 100, 160))]:
        overlay = create_forest_overlay(color)
        overlay.save(OUTPUT_DIR / "ownership" / "chapter_1" / f"{name}.png")
    print("Saved forest ownership overlays (chapter 1)")

    # === CHAPTER 3 (Cloud) ===
    cloud_tiles = Image.open(CLOUD_DIR / "cloud_tileset.png").convert("RGBA")
    cloud_tile = cloud_tiles.crop((32, 32, 48, 48))

    def create_cloud_overlay(tint_color):
        overlay = Image.new("RGBA", (128, 128), (200, 220, 255, 255))
        for y in range(8):
            for x in range(8):
                overlay.paste(cloud_tile, (x * 16, y * 16), cloud_tile)
        overlay = apply_color_tint(overlay, tint_color, 0.4)
        make_opaque_with_border(overlay, tint_color)
        return overlay.resize((size, size), Image.NEAREST)

    for name, color in [("player", (100, 150, 255)), ("enemy", (255, 120, 120)), ("contested", (200, 140, 255))]:
        overlay = create_cloud_overlay(color)
        overlay.save(OUTPUT_DIR / "ownership" / "chapter_3" / f"{name}.png")
    print("Saved cloud ownership overlays (chapter 3)")


def make_opaque_with_border(img, tint_color):
    """Make image fully opaque and add colored border."""
    pixels = img.load()
    width, height = img.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            pixels[x, y] = (r, g, b, 255)

    border = (min(tint_color[0] + 80, 255), min(tint_color[1] + 80, 255), min(tint_color[2] + 80, 255), 255)
    for i in range(3):
        for bx in range(width):
            pixels[bx, i] = border
            pixels[bx, height - 1 - i] = border
        for by in range(height):
            pixels[i, by] = border
            pixels[width - 1 - i, by] = border


def create_field_effect_overlays():
    """Create tile-based field effect overlays for each chapter theme."""

    size = 150
    effect_colors = {
        "thermal": (255, 100, 30),
        "repair": (50, 200, 80),
        "boost": (255, 200, 60),
        "suppression": (80, 40, 120)
    }

    # Create chapter-specific directories
    for chapter in [1, 2, 3]:
        chapter_dir = OUTPUT_DIR / "field_effects" / f"chapter_{chapter}"
        chapter_dir.mkdir(parents=True, exist_ok=True)

    # Default directory
    default_dir = OUTPUT_DIR / "field_effects"
    default_dir.mkdir(exist_ok=True)

    # === CHAPTER 2 / DEFAULT (Dungeon) ===
    walls_floors = Image.open(TILES_DIR / "Dungeon_WallsAndFloors.png").convert("RGBA")
    dungeon_tile = extract_tile(walls_floors, 2, 0)

    def create_dungeon_effect(tint_color):
        cell_size_tiles = 4
        overlay = Image.new("RGBA", (cell_size_tiles * DUNGEON_TILE_SIZE, cell_size_tiles * DUNGEON_TILE_SIZE), (0, 0, 0, 255))
        for y in range(cell_size_tiles):
            for x in range(cell_size_tiles):
                overlay.paste(dungeon_tile, (x * DUNGEON_TILE_SIZE, y * DUNGEON_TILE_SIZE))
        overlay = apply_color_tint(overlay, tint_color, 0.6)
        make_opaque_with_border(overlay, tint_color)
        return overlay.resize((size, size), Image.NEAREST)

    for name, color in effect_colors.items():
        overlay = create_dungeon_effect(color)
        overlay.save(default_dir / f"{name}.png")
        overlay.save(OUTPUT_DIR / "field_effects" / "chapter_2" / f"{name}.png")
    print("Saved dungeon field effect overlays (chapter 2 / default)")

    # === CHAPTER 1 (Forest) ===
    grass_3x3 = Image.open(FOREST_DIR / "grass_3x3.png").convert("RGBA")
    grass_tile = grass_3x3.crop((48, 0, 96, 48))  # Use different grass variant

    def create_forest_effect(tint_color):
        overlay = Image.new("RGBA", (144, 144), (30, 50, 25, 255))
        for y in range(3):
            for x in range(3):
                overlay.paste(grass_tile, (x * 48, y * 48))
        overlay = apply_color_tint(overlay, tint_color, 0.55)
        make_opaque_with_border(overlay, tint_color)
        return overlay.resize((size, size), Image.NEAREST)

    for name, color in effect_colors.items():
        overlay = create_forest_effect(color)
        overlay.save(OUTPUT_DIR / "field_effects" / "chapter_1" / f"{name}.png")
    print("Saved forest field effect overlays (chapter 1)")

    # === CHAPTER 3 (Cloud) ===
    cloud_tiles = Image.open(CLOUD_DIR / "cloud_tileset.png").convert("RGBA")
    cloud_tile = cloud_tiles.crop((48, 32, 64, 48))

    def create_cloud_effect(tint_color):
        overlay = Image.new("RGBA", (128, 128), (200, 220, 255, 255))
        for y in range(8):
            for x in range(8):
                overlay.paste(cloud_tile, (x * 16, y * 16), cloud_tile)
        overlay = apply_color_tint(overlay, tint_color, 0.5)
        make_opaque_with_border(overlay, tint_color)
        return overlay.resize((size, size), Image.NEAREST)

    for name, color in effect_colors.items():
        overlay = create_cloud_effect(color)
        overlay.save(OUTPUT_DIR / "field_effects" / "chapter_3" / f"{name}.png")
    print("Saved cloud field effect overlays (chapter 3)")


if __name__ == "__main__":
    print("Creating battle board assets...")
    print("\n=== Creating Boards ===")
    create_battle_board()  # Dungeon/Arena for Chapter 2
    create_forest_board()  # Forest for Chapter 1
    create_cloud_board()   # Cloud/Sky for Chapter 3+

    print("\n=== Creating Grid Cells ===")
    create_grid_cell_tile()

    print("\n=== Creating Overlays ===")
    create_cell_highlight()
    create_ownership_overlays()
    create_field_effect_overlays()
    print("\nDone!")
