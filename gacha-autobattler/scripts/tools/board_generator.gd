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
	pass  # Will define theme data in Task 2

func generate_all_boards():
	pass  # Will implement in Task 7

func _on_generate_pressed():
	generate_all_boards()
