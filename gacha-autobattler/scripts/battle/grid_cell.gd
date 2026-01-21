extends Area2D
## A single cell in the 3x3 battle grid
## Handles click detection and visual state

signal cell_clicked(row: int, col: int)

# Cell position in grid
var grid_row: int = 0
var grid_col: int = 0

# Cell state
var ownership: int = 0  # 0 = empty, 1 = player, 2 = enemy
var is_hovered: bool = false

# Visual references
@onready var background = $Background
@onready var owner_indicator = $OwnerIndicator
@onready var hover_effect = $HoverEffect
@onready var collision_shape = $CollisionShape2D

# Colors for ownership
const PLAYER_COLOR = Color(0.2, 0.6, 1.0, 0.6)  # Blue
const ENEMY_COLOR = Color(1.0, 0.3, 0.3, 0.6)   # Red
const EMPTY_COLOR = Color(0.2, 0.2, 0.25, 1.0)  # Dark gray

func _ready():
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func setup(row: int, col: int, size: int):
	grid_row = row
	grid_col = col

	# Create collision shape based on cell size
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size, size)
	collision_shape.shape = shape

	# Resize visual elements
	var half_size = size / 2.0
	var border_width = 5.0

	background.offset_left = -half_size
	background.offset_top = -half_size
	background.offset_right = half_size
	background.offset_bottom = half_size

	# Update border positions
	$Border.offset_left = -half_size
	$Border.offset_top = -half_size
	$Border.offset_right = half_size
	$Border.offset_bottom = -half_size + border_width

	$Border2.offset_left = -half_size
	$Border2.offset_top = half_size - border_width
	$Border2.offset_right = half_size
	$Border2.offset_bottom = half_size

	$Border3.offset_left = -half_size
	$Border3.offset_top = -half_size
	$Border3.offset_right = -half_size + border_width
	$Border3.offset_bottom = half_size

	$Border4.offset_left = half_size - border_width
	$Border4.offset_top = -half_size
	$Border4.offset_right = half_size
	$Border4.offset_bottom = half_size

	# Owner indicator (slightly smaller than cell)
	var indicator_margin = 15.0
	owner_indicator.offset_left = -half_size + indicator_margin
	owner_indicator.offset_top = -half_size + indicator_margin
	owner_indicator.offset_right = half_size - indicator_margin
	owner_indicator.offset_bottom = half_size - indicator_margin

	# Hover effect (full cell size)
	hover_effect.offset_left = -half_size
	hover_effect.offset_top = -half_size
	hover_effect.offset_right = half_size
	hover_effect.offset_bottom = half_size

func set_ownership(new_owner: int):
	ownership = new_owner

	match ownership:
		0:  # Empty
			owner_indicator.visible = false
			background.color = EMPTY_COLOR
		1:  # Player
			owner_indicator.visible = true
			owner_indicator.color = PLAYER_COLOR
		2:  # Enemy
			owner_indicator.visible = true
			owner_indicator.color = ENEMY_COLOR

func _on_mouse_entered():
	is_hovered = true
	hover_effect.visible = true

func _on_mouse_exited():
	is_hovered = false
	hover_effect.visible = false

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cell_clicked.emit(grid_row, grid_col)
