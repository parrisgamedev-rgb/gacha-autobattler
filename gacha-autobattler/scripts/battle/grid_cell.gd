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

# Field effect visuals (created dynamically)
var field_overlay: ColorRect = null
var field_icon: Label = null
var field_tween: Tween = null

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

func show_field_effect(field_data: FieldEffectData):
	if not field_data:
		clear_field_effect()
		return

	# Get cell size from background
	var half_size = 75.0  # Default, will be overridden by setup()
	if background:
		half_size = (background.offset_right - background.offset_left) / 2.0

	# Create or update overlay
	if not field_overlay:
		field_overlay = ColorRect.new()
		field_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		field_overlay.z_index = 1
		add_child(field_overlay)

	field_overlay.offset_left = -half_size + 5
	field_overlay.offset_top = -half_size + 5
	field_overlay.offset_right = half_size - 5
	field_overlay.offset_bottom = half_size - 5
	field_overlay.color = field_data.field_color
	field_overlay.visible = true

	# Create or update icon
	if not field_icon:
		field_icon = Label.new()
		field_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		field_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		field_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		field_icon.z_index = 2
		add_child(field_icon)

	field_icon.text = field_data.icon_symbol
	field_icon.add_theme_font_size_override("font_size", 32)
	field_icon.add_theme_color_override("font_color", Color(field_data.field_color.r, field_data.field_color.g, field_data.field_color.b, 0.8))
	field_icon.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	field_icon.add_theme_constant_override("outline_size", 2)
	field_icon.size = Vector2(half_size * 2, half_size * 2)
	field_icon.position = Vector2(-half_size, -half_size)
	field_icon.visible = true

	# Create pulsing animation for cyber feel
	if field_tween:
		field_tween.kill()

	field_tween = create_tween()
	field_tween.set_loops()  # Loop forever
	field_tween.tween_property(field_overlay, "modulate:a", 0.6, 0.8).set_ease(Tween.EASE_IN_OUT)
	field_tween.tween_property(field_overlay, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT)

func clear_field_effect():
	if field_tween:
		field_tween.kill()
		field_tween = null

	if field_overlay:
		field_overlay.visible = false

	if field_icon:
		field_icon.visible = false
