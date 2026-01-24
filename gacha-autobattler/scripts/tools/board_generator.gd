extends Node2D

const BOARD_WIDTH = 1200
const BOARD_HEIGHT = 1120
const TILE_SIZE = 16
const TILE_SCALE = 3  # Scale up 16px tiles to be visible
const SCALED_TILE = TILE_SIZE * TILE_SCALE  # 48px per tile
const OUTPUT_PATH = "res://assets/board/boards/"

# Kenney Tiny Dungeon tile paths
const KENNEY_PATH = "res://assets/kenney_tiny-dungeon/Tiles/"

# Safe zone where decorations are sparse (center play area)
const CENTER_SAFE_ZONE = Rect2(300, 260, 600, 600)

@onready var capture_viewport: SubViewport = $CaptureViewport
@onready var board_root: Node2D = $CaptureViewport/BoardRoot
@onready var status_label: Label = $UI/StatusLabel

var themes: Dictionary = {}

func _ready():
	_init_themes()
	$UI/GenerateButton.pressed.connect(_on_generate_pressed)

func _init_themes():
	# Kenney Tiny Dungeon tiles (by index)
	# Floor tiles: 48-51 (stone floor variations)
	# Wall tiles: 0-23 (various wall configurations)
	# Props: 70 (chest), 73 (barrel), 74 (crate), 84-87 (items), etc.

	themes["dungeon"] = {
		"floor_tiles": [
			KENNEY_PATH + "tile_0048.png",  # Plain floor
			KENNEY_PATH + "tile_0049.png",  # Floor variation
			KENNEY_PATH + "tile_0050.png",  # Floor variation
			KENNEY_PATH + "tile_0051.png",  # Floor variation
		],
		"wall_tiles": [
			KENNEY_PATH + "tile_0024.png",  # Stone wall
			KENNEY_PATH + "tile_0025.png",  # Stone wall variation
		],
		"wall_top_tiles": [
			KENNEY_PATH + "tile_0012.png",  # Wall top
			KENNEY_PATH + "tile_0013.png",  # Wall top variation
		],
		"decorations": [
			KENNEY_PATH + "tile_0073.png",  # Barrel
			KENNEY_PATH + "tile_0074.png",  # Crate
			KENNEY_PATH + "tile_0070.png",  # Chest
			KENNEY_PATH + "tile_0061.png",  # Table
			KENNEY_PATH + "tile_0058.png",  # Chair
			KENNEY_PATH + "tile_0075.png",  # Pot
		],
		"decoration_density": 25,
		"bg_color": Color(0.15, 0.12, 0.1),  # Dark background behind walls
	}

	# Dark dungeon variant
	themes["dark_dungeon"] = {
		"floor_tiles": [
			KENNEY_PATH + "tile_0048.png",
			KENNEY_PATH + "tile_0049.png",
		],
		"wall_tiles": [
			KENNEY_PATH + "tile_0036.png",  # Different wall style
			KENNEY_PATH + "tile_0037.png",
		],
		"wall_top_tiles": [
			KENNEY_PATH + "tile_0012.png",
			KENNEY_PATH + "tile_0013.png",
		],
		"decorations": [
			KENNEY_PATH + "tile_0073.png",  # Barrel
			KENNEY_PATH + "tile_0070.png",  # Chest
			KENNEY_PATH + "tile_0057.png",  # Skull/bones
		],
		"decoration_density": 15,
		"bg_color": Color(0.1, 0.08, 0.08),
	}

	# Arena variant (more open)
	themes["arena"] = {
		"floor_tiles": [
			KENNEY_PATH + "tile_0048.png",
			KENNEY_PATH + "tile_0049.png",
			KENNEY_PATH + "tile_0050.png",
			KENNEY_PATH + "tile_0051.png",
		],
		"wall_tiles": [
			KENNEY_PATH + "tile_0024.png",
			KENNEY_PATH + "tile_0025.png",
		],
		"wall_top_tiles": [
			KENNEY_PATH + "tile_0000.png",  # Top edge
			KENNEY_PATH + "tile_0001.png",
		],
		"decorations": [
			KENNEY_PATH + "tile_0073.png",  # Barrel
			KENNEY_PATH + "tile_0074.png",  # Crate
		],
		"decoration_density": 10,
		"bg_color": Color(0.12, 0.1, 0.08),
	}

func _clear_board():
	for child in board_root.get_children():
		child.queue_free()
	await get_tree().process_frame


func _load_tile(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _place_tile(texture: Texture2D, pos: Vector2, scale_factor: float = TILE_SCALE):
	if not texture:
		return
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.centered = false
	sprite.position = pos
	board_root.add_child(sprite)


func _fill_base_terrain(theme: Dictionary):
	# Dark background first
	var bg = ColorRect.new()
	bg.color = theme["bg_color"]
	bg.size = Vector2(BOARD_WIDTH, BOARD_HEIGHT)
	board_root.add_child(bg)

	# Load floor tiles
	var floor_textures: Array[Texture2D] = []
	for path in theme["floor_tiles"]:
		var tex = _load_tile(path)
		if tex:
			floor_textures.append(tex)

	if floor_textures.is_empty():
		return

	# Calculate grid dimensions
	var cols = ceili(float(BOARD_WIDTH) / SCALED_TILE) + 1
	var rows = ceili(float(BOARD_HEIGHT) / SCALED_TILE) + 1

	# Tile the floor (leave border area for walls)
	var border_tiles = 2  # 2 tiles for wall border
	for row in range(border_tiles, rows):
		for col in range(border_tiles, cols - border_tiles):
			var tex = floor_textures[randi() % floor_textures.size()]
			var pos = Vector2(col * SCALED_TILE, row * SCALED_TILE)
			_place_tile(tex, pos)


func _add_borders(theme: Dictionary):
	# Load wall tiles
	var wall_textures: Array[Texture2D] = []
	for path in theme["wall_tiles"]:
		var tex = _load_tile(path)
		if tex:
			wall_textures.append(tex)

	var wall_top_textures: Array[Texture2D] = []
	for path in theme["wall_top_tiles"]:
		var tex = _load_tile(path)
		if tex:
			wall_top_textures.append(tex)

	if wall_textures.is_empty():
		return

	var cols = ceili(float(BOARD_WIDTH) / SCALED_TILE) + 1
	var rows = ceili(float(BOARD_HEIGHT) / SCALED_TILE) + 1

	# Top wall (2 rows)
	for row in range(2):
		for col in range(cols):
			var tex = wall_textures[randi() % wall_textures.size()]
			if row == 1 and not wall_top_textures.is_empty():
				tex = wall_top_textures[randi() % wall_top_textures.size()]
			_place_tile(tex, Vector2(col * SCALED_TILE, row * SCALED_TILE))

	# Left wall
	for row in range(2, rows):
		for col in range(2):
			var tex = wall_textures[randi() % wall_textures.size()]
			_place_tile(tex, Vector2(col * SCALED_TILE, row * SCALED_TILE))

	# Right wall
	for row in range(2, rows):
		for col in range(cols - 2, cols):
			var tex = wall_textures[randi() % wall_textures.size()]
			_place_tile(tex, Vector2(col * SCALED_TILE, row * SCALED_TILE))


func _add_border_gradient(theme: Dictionary):
	# Not needed with tile-based approach - walls provide natural border
	pass


func _load_decorations(paths: Array) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in paths:
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex:
				textures.append(tex)
	return textures


func _scatter_decorations(theme: Dictionary, rng: RandomNumberGenerator):
	var decorations = _load_decorations(theme["decorations"])
	if decorations.is_empty():
		return

	var placed_positions: Array[Vector2] = []
	var count = theme["decoration_density"]
	var attempts = count * 3  # Allow extra attempts for failed placements

	# Define play area bounds (inside the wall borders)
	var min_x = SCALED_TILE * 3  # After left wall
	var max_x = BOARD_WIDTH - SCALED_TILE * 3  # Before right wall
	var min_y = SCALED_TILE * 3  # After top wall
	var max_y = BOARD_HEIGHT - SCALED_TILE  # Near bottom

	for i in attempts:
		if placed_positions.size() >= count:
			break

		var pos = Vector2(
			rng.randf_range(min_x, max_x),
			rng.randf_range(min_y, max_y)
		)

		# Reduce chance of placement in center safe zone (70% skip)
		if CENTER_SAFE_ZONE.has_point(pos):
			if rng.randf() > 0.3:
				continue

		# Check minimum distance from other decorations
		var too_close = false
		for placed in placed_positions:
			if pos.distance_to(placed) < SCALED_TILE * 1.5:
				too_close = true
				break

		if too_close:
			continue

		# Place decoration
		var sprite = Sprite2D.new()
		sprite.texture = decorations[rng.randi() % decorations.size()]
		sprite.position = pos
		sprite.scale = Vector2(TILE_SCALE, TILE_SCALE)
		sprite.centered = false
		board_root.add_child(sprite)
		placed_positions.append(pos)


func _capture_board() -> Image:
	# Wait for rendering to complete
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image = capture_viewport.get_texture().get_image()
	return image


func _save_board(image: Image, filename: String):
	var path = OUTPUT_PATH + filename
	var error = image.save_png(path)
	if error != OK:
		push_error("Failed to save board: " + path + " Error: " + str(error))
	else:
		print("Saved: " + path)


func generate_board(theme_name: String, variation: int) -> void:
	if not theme_name in themes:
		push_error("Unknown theme: " + theme_name)
		return

	var theme = themes[theme_name]
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme_name) + variation  # Deterministic per variation

	await _clear_board()

	_fill_base_terrain(theme)
	_add_borders(theme)
	_add_border_gradient(theme)
	_scatter_decorations(theme, rng)

	await get_tree().process_frame

	var image = await _capture_board()
	var filename = "%s_%d.png" % [theme_name, variation]
	_save_board(image, filename)


func generate_all_boards():
	status_label.text = "Generating boards..."

	var theme_names = ["dungeon", "dark_dungeon", "arena"]
	var variations = 3
	var total = theme_names.size() * variations
	var current = 0

	for theme_name in theme_names:
		for v in range(1, variations + 1):
			current += 1
			status_label.text = "Generating %s_%d... (%d/%d)" % [theme_name, v, current, total]
			await generate_board(theme_name, v)
			await get_tree().process_frame

	status_label.text = "Done! Generated %d boards." % total
	print("Board generation complete!")

func _on_generate_pressed():
	generate_all_boards()
	await get_tree().process_frame
	await generate_ownership_tiles()


func generate_ownership_tiles():
	"""Generate ownership tiles (player/enemy/contested) using Kenney floor tiles."""
	status_label.text = "Generating ownership tiles..."

	# Ownership tile settings
	const OWNERSHIP_SIZE = 170  # Match CELL_SIZE in battle.gd
	const OWNERSHIP_TILE_SCALE = 6  # Scale for ownership tiles
	const OWNERSHIP_SCALED = TILE_SIZE * OWNERSHIP_TILE_SCALE
	const OWNERSHIP_PATH = "res://assets/board/ownership/"

	# Color tints for each ownership type
	var ownership_colors = {
		"player": Color(0.4, 0.6, 1.0, 1.0),      # Blue tint
		"enemy": Color(1.0, 0.4, 0.4, 1.0),       # Red tint
		"contested": Color(0.8, 0.5, 0.9, 1.0),   # Purple tint
	}

	# Load floor tiles
	var floor_tiles: Array[Texture2D] = []
	for path in themes["dungeon"]["floor_tiles"]:
		var tex = _load_tile(path)
		if tex:
			floor_tiles.append(tex)

	if floor_tiles.is_empty():
		push_error("No floor tiles found for ownership generation")
		return

	# Resize viewport for ownership tiles
	capture_viewport.size = Vector2i(OWNERSHIP_SIZE, OWNERSHIP_SIZE)
	await get_tree().process_frame

	# Generate each ownership type
	for ownership_name in ownership_colors:
		await _clear_board()

		var tint = ownership_colors[ownership_name]
		var cols = ceili(float(OWNERSHIP_SIZE) / OWNERSHIP_SCALED) + 1
		var rows = ceili(float(OWNERSHIP_SIZE) / OWNERSHIP_SCALED) + 1

		# Fill with tinted floor tiles
		for row in range(rows):
			for col in range(cols):
				var tex = floor_tiles[randi() % floor_tiles.size()]
				var sprite = Sprite2D.new()
				sprite.texture = tex
				sprite.scale = Vector2(OWNERSHIP_TILE_SCALE, OWNERSHIP_TILE_SCALE)
				sprite.centered = false
				sprite.position = Vector2(col * OWNERSHIP_SCALED, row * OWNERSHIP_SCALED)
				sprite.modulate = tint
				board_root.add_child(sprite)

		# Add a subtle border
		var border = ColorRect.new()
		border.color = tint * 0.7
		border.color.a = 0.8
		border.size = Vector2(OWNERSHIP_SIZE, 4)
		border.position = Vector2(0, 0)
		board_root.add_child(border)

		var border_bottom = ColorRect.new()
		border_bottom.color = tint * 0.7
		border_bottom.color.a = 0.8
		border_bottom.size = Vector2(OWNERSHIP_SIZE, 4)
		border_bottom.position = Vector2(0, OWNERSHIP_SIZE - 4)
		board_root.add_child(border_bottom)

		var border_left = ColorRect.new()
		border_left.color = tint * 0.7
		border_left.color.a = 0.8
		border_left.size = Vector2(4, OWNERSHIP_SIZE)
		border_left.position = Vector2(0, 0)
		board_root.add_child(border_left)

		var border_right = ColorRect.new()
		border_right.color = tint * 0.7
		border_right.color.a = 0.8
		border_right.size = Vector2(4, OWNERSHIP_SIZE)
		border_right.position = Vector2(OWNERSHIP_SIZE - 4, 0)
		board_root.add_child(border_right)

		await get_tree().process_frame
		var image = await _capture_board()

		var save_path = OWNERSHIP_PATH + ownership_name + ".png"
		var error = image.save_png(save_path)
		if error != OK:
			push_error("Failed to save ownership tile: " + save_path)
		else:
			print("Saved: " + save_path)

	# Restore viewport size
	capture_viewport.size = Vector2i(BOARD_WIDTH, BOARD_HEIGHT)
	await get_tree().process_frame

	status_label.text = "Done! Generated boards and ownership tiles."
	print("Ownership tile generation complete!")
