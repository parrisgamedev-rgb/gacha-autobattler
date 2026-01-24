extends Node
class_name BoardBuilder
## Assembles battle boards at runtime from tiles
## Creates floor tiles, walls, and props as a cohesive scene

const TILE_SIZE = 16
const TILE_SCALE = 5
const SCALED_TILE = TILE_SIZE * TILE_SCALE  # 80px

const GRID_SIZE = 3
const WALL_THICKNESS = 2  # tiles

# Kenney Tiny Dungeon tile paths
const KENNEY_PATH = "res://assets/kenney_tiny-dungeon/Tiles/"

# Theme definitions
const THEMES = {
	"dungeon": {
		"floor_tiles": ["tile_0048.png", "tile_0049.png"],
		"wall_face": ["tile_0024.png", "tile_0025.png"],
		"wall_top": ["tile_0012.png", "tile_0013.png"],
		"props": ["tile_0073.png", "tile_0074.png", "tile_0070.png", "tile_0061.png"],
		"prop_count": [5, 8],
		"tint": Color(1, 1, 1, 1),
	},
	"dark_dungeon": {
		"floor_tiles": ["tile_0048.png", "tile_0049.png"],
		"wall_face": ["tile_0036.png", "tile_0037.png"],
		"wall_top": ["tile_0012.png", "tile_0013.png"],
		"props": ["tile_0073.png", "tile_0070.png", "tile_0057.png"],
		"prop_count": [3, 5],
		"tint": Color(0.7, 0.7, 0.8, 1),
	},
	"arena": {
		"floor_tiles": ["tile_0050.png", "tile_0051.png"],
		"wall_face": ["tile_0024.png", "tile_0025.png"],
		"wall_top": ["tile_0000.png", "tile_0001.png"],
		"props": ["tile_0073.png", "tile_0074.png", "tile_0070.png"],
		"prop_count": [4, 6],
		"tint": Color(1, 0.95, 0.9, 1),
	}
}

# Loaded textures cache
var _texture_cache: Dictionary = {}

# Board container nodes
var board_root: Node2D
var floor_container: Node2D
var wall_container: Node2D
var prop_container: Node2D


func build_board(parent: Node2D, theme_name: String, center_position: Vector2) -> Dictionary:
	"""Build a complete board and return references to key nodes."""

	var theme = THEMES.get(theme_name, THEMES["dungeon"])

	# Create container hierarchy
	board_root = Node2D.new()
	board_root.name = "BoardRoot"
	parent.add_child(board_root)

	wall_container = Node2D.new()
	wall_container.name = "Walls"
	board_root.add_child(wall_container)

	floor_container = Node2D.new()
	floor_container.name = "Floor"
	board_root.add_child(floor_container)

	prop_container = Node2D.new()
	prop_container.name = "Props"
	board_root.add_child(prop_container)

	# Calculate board dimensions
	var grid_pixels = GRID_SIZE * SCALED_TILE
	var total_size = grid_pixels + (WALL_THICKNESS * 2 * SCALED_TILE)

	# Board top-left corner (so grid center aligns with center_position)
	var board_origin = center_position - Vector2(total_size / 2.0, total_size / 2.0)

	# Build layers
	_build_walls(theme, board_origin, total_size)
	_build_floor(theme, board_origin, center_position)
	_build_props(theme, board_origin, total_size)

	return {
		"root": board_root,
		"floor": floor_container,
		"walls": wall_container,
		"props": prop_container,
		"grid_origin": board_origin + Vector2(WALL_THICKNESS * SCALED_TILE, WALL_THICKNESS * SCALED_TILE),
		"cell_size": SCALED_TILE,
	}


func _build_floor(theme: Dictionary, board_origin: Vector2, center_position: Vector2) -> void:
	"""Build the 3x3 grid of floor tiles."""

	var floor_tile_path = KENNEY_PATH + theme["floor_tiles"][0]
	var floor_texture = _load_texture(floor_tile_path)

	var grid_start = board_origin + Vector2(WALL_THICKNESS * SCALED_TILE, WALL_THICKNESS * SCALED_TILE)

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var tile = Sprite2D.new()
			tile.texture = floor_texture
			tile.scale = Vector2(TILE_SCALE, TILE_SCALE)
			tile.centered = false
			tile.position = grid_start + Vector2(col * SCALED_TILE, row * SCALED_TILE)
			tile.modulate = theme["tint"]
			floor_container.add_child(tile)


func _build_walls(theme: Dictionary, board_origin: Vector2, total_size: int) -> void:
	"""Build the wall frame around the grid."""

	var wall_face_path = KENNEY_PATH + theme["wall_face"][0]
	var wall_top_path = KENNEY_PATH + theme["wall_top"][0]
	var wall_face_texture = _load_texture(wall_face_path)
	var wall_top_texture = _load_texture(wall_top_path)

	var tiles_count = int(total_size / SCALED_TILE)

	# Build all wall positions
	for row in range(tiles_count):
		for col in range(tiles_count):
			# Check if this is a wall position (not in the center grid area)
			var is_wall = (
				row < WALL_THICKNESS or
				row >= tiles_count - WALL_THICKNESS or
				col < WALL_THICKNESS or
				col >= tiles_count - WALL_THICKNESS
			)

			if is_wall:
				var tile = Sprite2D.new()
				tile.centered = false
				tile.scale = Vector2(TILE_SCALE, TILE_SCALE)
				tile.position = board_origin + Vector2(col * SCALED_TILE, row * SCALED_TILE)
				tile.modulate = theme["tint"]

				# Use wall top for top rows, wall face for others
				if row < WALL_THICKNESS:
					tile.texture = wall_top_texture
				else:
					tile.texture = wall_face_texture

				wall_container.add_child(tile)


func _build_props(theme: Dictionary, board_origin: Vector2, total_size: int) -> void:
	"""Place props along the inner wall edges."""

	if theme["props"].is_empty():
		return

	var prop_count_range = theme["prop_count"]
	var num_props = randi_range(prop_count_range[0], prop_count_range[1])

	# Valid prop positions (inside the wall frame, outside the grid)
	# These are in tile coordinates relative to board_origin
	var inner_wall_start = WALL_THICKNESS
	var inner_wall_end = int(total_size / SCALED_TILE) - WALL_THICKNESS
	var grid_start = WALL_THICKNESS
	var grid_end = WALL_THICKNESS + GRID_SIZE

	var valid_positions: Array[Vector2] = []

	# Corners
	valid_positions.append(Vector2(inner_wall_start, inner_wall_start))  # Top-left
	valid_positions.append(Vector2(inner_wall_end - 1, inner_wall_start))  # Top-right
	valid_positions.append(Vector2(inner_wall_start, inner_wall_end - 1))  # Bottom-left
	valid_positions.append(Vector2(inner_wall_end - 1, inner_wall_end - 1))  # Bottom-right

	# Mid positions (if there's room between wall and grid)
	# Top edge middle
	valid_positions.append(Vector2(grid_start + 1, inner_wall_start))
	# Bottom edge middle
	valid_positions.append(Vector2(grid_start + 1, inner_wall_end - 1))
	# Left edge middle
	valid_positions.append(Vector2(inner_wall_start, grid_start + 1))
	# Right edge middle
	valid_positions.append(Vector2(inner_wall_end - 1, grid_start + 1))

	# Shuffle and pick positions
	valid_positions.shuffle()

	for i in range(min(num_props, valid_positions.size())):
		var prop_tile_name = theme["props"].pick_random()
		var prop_texture = _load_texture(KENNEY_PATH + prop_tile_name)

		var prop = Sprite2D.new()
		prop.texture = prop_texture
		prop.scale = Vector2(TILE_SCALE, TILE_SCALE)
		prop.centered = false
		prop.position = board_origin + valid_positions[i] * SCALED_TILE
		prop.modulate = theme["tint"]
		prop_container.add_child(prop)


func _load_texture(path: String) -> Texture2D:
	"""Load and cache a texture."""
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]


func clear_board() -> void:
	"""Remove all board elements."""
	if board_root and is_instance_valid(board_root):
		board_root.queue_free()
		board_root = null
		floor_container = null
		wall_container = null
		prop_container = null
	_texture_cache.clear()
