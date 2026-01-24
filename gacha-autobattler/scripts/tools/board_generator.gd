extends Node2D

const BOARD_WIDTH = 1200
const BOARD_HEIGHT = 1120
const TILE_SIZE = 16
const OUTPUT_PATH = "res://assets/board/boards/"

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
	themes["forest"] = {
		"base_texture": "res://assets/board/forest tileset/grass.png",
		"base_color": Color(0.486, 0.678, 0.227),  # Grass green
		"decorations": [
			"res://assets/board/forest tileset/decor_bush1.png",
			"res://assets/board/forest tileset/decor_bush2.png",
			"res://assets/board/forest tileset/decor_bush3.png",
			"res://assets/board/forest tileset/decor_grass1.png",
			"res://assets/board/forest tileset/decor_grass2.png",
			"res://assets/board/forest tileset/decor_mushroom1.png",
			"res://assets/board/forest tileset/decor_mushroom2.png",
			"res://assets/board/forest tileset/decor_stone1.png",
			"res://assets/board/forest tileset/decor_stone2.png",
		],
		"decoration_density": 40,
		"border_color": Color(0.2, 0.4, 0.1),  # Darker green
	}

	themes["dungeon"] = {
		"base_texture": "res://assets/board/Tiles/Dungeon_WallsAndFloors.png",
		"base_color": Color(0.3, 0.35, 0.3),  # Stone gray
		"decorations": [],  # Empty for now
		"decoration_density": 20,
		"border_color": Color(0.15, 0.15, 0.2),  # Dark wall
	}

	themes["dark_forest"] = {
		"base_texture": "res://assets/board/forest tileset/grass_dark.png",
		"base_color": Color(0.3, 0.45, 0.2),  # Darker grass
		"decorations": [
			"res://assets/board/forest tileset/decor_bush1_purple.png",
			"res://assets/board/forest tileset/decor_bush2_purple.png",
			"res://assets/board/forest tileset/decor_bush3_purple.png",
			"res://assets/board/forest tileset/decor_mushroom1.png",
			"res://assets/board/forest tileset/decor_mushroom2.png",
			"res://assets/board/forest tileset/decor_stone1.png",
		],
		"decoration_density": 50,
		"border_color": Color(0.1, 0.2, 0.1),  # Very dark green
	}

func _clear_board():
	for child in board_root.get_children():
		child.queue_free()
	await get_tree().process_frame


func _fill_base_terrain(theme: Dictionary):
	# Create colored background as base
	var bg = ColorRect.new()
	bg.color = theme["base_color"]
	bg.size = Vector2(BOARD_WIDTH, BOARD_HEIGHT)
	board_root.add_child(bg)

	# Add subtle darker region at top for depth
	var top_shade = ColorRect.new()
	top_shade.color = theme["border_color"]
	top_shade.color.a = 0.3
	top_shade.size = Vector2(BOARD_WIDTH, 200)
	top_shade.position = Vector2(0, 0)
	board_root.add_child(top_shade)


func _add_borders(theme: Dictionary):
	# Top border (thicker, represents tree line / wall)
	var top_border = ColorRect.new()
	top_border.color = theme["border_color"]
	top_border.size = Vector2(BOARD_WIDTH, 180)
	top_border.position = Vector2(0, 0)
	board_root.add_child(top_border)

	# Left border
	var left_border = ColorRect.new()
	left_border.color = theme["border_color"]
	left_border.size = Vector2(120, BOARD_HEIGHT)
	left_border.position = Vector2(0, 0)
	board_root.add_child(left_border)

	# Right border
	var right_border = ColorRect.new()
	right_border.color = theme["border_color"]
	right_border.size = Vector2(120, BOARD_HEIGHT)
	right_border.position = Vector2(BOARD_WIDTH - 120, 0)
	board_root.add_child(right_border)


func _add_border_gradient(theme: Dictionary):
	# Create softer transition from border to play area
	var gradient_color = theme["border_color"]
	gradient_color.a = 0.4

	# Top gradient (below top border)
	var top_grad = ColorRect.new()
	top_grad.color = gradient_color
	top_grad.size = Vector2(BOARD_WIDTH, 80)
	top_grad.position = Vector2(0, 180)
	board_root.add_child(top_grad)

	# Left gradient
	var left_grad = ColorRect.new()
	left_grad.color = gradient_color
	left_grad.size = Vector2(60, BOARD_HEIGHT)
	left_grad.position = Vector2(120, 0)
	board_root.add_child(left_grad)

	# Right gradient
	var right_grad = ColorRect.new()
	right_grad.color = gradient_color
	right_grad.size = Vector2(60, BOARD_HEIGHT)
	right_grad.position = Vector2(BOARD_WIDTH - 180, 0)
	board_root.add_child(right_grad)


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

	for i in attempts:
		if placed_positions.size() >= count:
			break

		var pos = Vector2(
			rng.randf_range(100, BOARD_WIDTH - 100),
			rng.randf_range(200, BOARD_HEIGHT - 50)
		)

		# Reduce chance of placement in center safe zone (80% skip)
		if CENTER_SAFE_ZONE.has_point(pos):
			if rng.randf() > 0.2:
				continue

		# Check minimum distance from other decorations
		var too_close = false
		for placed in placed_positions:
			if pos.distance_to(placed) < 50:
				too_close = true
				break

		if too_close:
			continue

		# Place decoration
		var sprite = Sprite2D.new()
		sprite.texture = decorations[rng.randi() % decorations.size()]
		sprite.position = pos
		sprite.scale = Vector2(3.0, 3.0)  # Scale up pixel art
		board_root.add_child(sprite)
		placed_positions.append(pos)


func _capture_board() -> Image:
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

	var theme_names = ["forest", "dungeon", "dark_forest"]
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
