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


func generate_all_boards():
	pass  # Will implement in Task 7

func _on_generate_pressed():
	generate_all_boards()
