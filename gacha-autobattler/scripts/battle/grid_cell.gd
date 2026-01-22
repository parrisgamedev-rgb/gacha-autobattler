extends Area2D
## A single cell in the 3x3 battle grid
## Handles click detection only - background image provides visuals

signal cell_clicked(row: int, col: int)

# Cell position in grid
var grid_row: int = 0
var grid_col: int = 0
var cell_size: int = 150

# Cell state
var ownership: int = 0  # 0 = empty, 1 = player, 2 = enemy
var is_hovered: bool = false
var current_field_effect: String = ""

# Visual references
@onready var background = $Background
@onready var owner_indicator = $OwnerIndicator
@onready var hover_effect = $HoverEffect
@onready var collision_shape = $CollisionShape2D

# Field effect visuals - particle-based (fallback)
var active_effect_node: Node2D = null
var field_tween: Tween = null

# AI-generated overlay sprites
var ownership_overlay: Sprite2D = null
var field_effect_overlay: Sprite2D = null
var use_ai_board_assets: bool = false

func _ready():
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func setup(row: int, col: int, size: int):
	grid_row = row
	grid_col = col
	cell_size = size

	# Create collision shape based on cell size
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size, size)
	collision_shape.shape = shape

	var half_size = size / 2.0

	# Hide ALL visual elements - background image provides the grid visuals
	background.visible = false
	owner_indicator.visible = false
	$Border.visible = false
	$Border2.visible = false
	$Border3.visible = false
	$Border4.visible = false

	# Subtle hover effect - just a slight glow when mousing over
	hover_effect.offset_left = -half_size
	hover_effect.offset_top = -half_size
	hover_effect.offset_right = half_size
	hover_effect.offset_bottom = half_size
	hover_effect.color = Color(1.0, 1.0, 1.0, 0.1)
	hover_effect.visible = false

	# Setup AI board asset overlays if available
	_setup_ai_overlays(size)

func _setup_ai_overlays(size: int):
	"""Create overlay sprites for AI-generated board assets."""
	use_ai_board_assets = BoardAssetLoader.has_board_assets()

	if not use_ai_board_assets:
		return

	# Store cell size for dynamic scaling (assets have varying sizes)
	var target_size = size * 1.05  # Fill out the cell more

	# Create field effect overlay (rendered below ownership but above background)
	field_effect_overlay = Sprite2D.new()
	field_effect_overlay.z_index = 1
	field_effect_overlay.visible = false
	add_child(field_effect_overlay)

	# Create ownership overlay (rendered above field effect)
	ownership_overlay = Sprite2D.new()
	ownership_overlay.z_index = 2
	ownership_overlay.modulate.a = 0.85  # Slight transparency so field effects show through
	ownership_overlay.visible = false
	add_child(ownership_overlay)

	# Store target size for use when setting textures
	set_meta("overlay_target_size", target_size)

	print("GridCell [", grid_row, ",", grid_col, "]: Overlays created, target size = ", target_size)


func set_ownership(new_owner: int):
	ownership = new_owner

	# Update AI board overlay if available
	if use_ai_board_assets and ownership_overlay:
		var board_ownership: BoardAssetLoader.Ownership
		match new_owner:
			1:
				board_ownership = BoardAssetLoader.Ownership.PLAYER
			2:
				board_ownership = BoardAssetLoader.Ownership.ENEMY
			3:
				board_ownership = BoardAssetLoader.Ownership.CONTESTED
			_:
				board_ownership = BoardAssetLoader.Ownership.NONE

		var texture = BoardAssetLoader.get_ownership_texture(board_ownership)
		if texture:
			ownership_overlay.texture = texture
			# Scale based on actual texture size
			var target_size = get_meta("overlay_target_size", 180.0)
			var tex_size = texture.get_size().x  # Assume square
			var scale_factor = target_size / tex_size
			ownership_overlay.scale = Vector2(scale_factor, scale_factor)
			_fade_in_overlay(ownership_overlay)
		else:
			_fade_out_overlay(ownership_overlay)


func set_contested(is_contested: bool):
	"""Set the cell as contested (both player and enemy present)."""
	if use_ai_board_assets and ownership_overlay and is_contested:
		var texture = BoardAssetLoader.get_ownership_texture(BoardAssetLoader.Ownership.CONTESTED)
		if texture:
			ownership_overlay.texture = texture
			_fade_in_overlay(ownership_overlay)


func _fade_in_overlay(overlay: Sprite2D):
	"""Fade in an overlay sprite."""
	if not overlay.visible:
		overlay.modulate.a = 0.0
		overlay.visible = true

	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.85, 0.3)


func _fade_out_overlay(overlay: Sprite2D):
	"""Fade out an overlay sprite."""
	if not overlay.visible:
		return

	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): overlay.visible = false)

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

	# Clear any existing effect
	clear_field_effect()

	# Try AI board assets first
	if use_ai_board_assets and field_effect_overlay:
		var effect_type = _field_type_to_board_effect(field_data.field_type)
		var texture = BoardAssetLoader.get_field_effect_texture(effect_type)

		if texture:
			current_field_effect = field_data.field_name
			field_effect_overlay.texture = texture
			_fade_in_field_effect()
			return

	# Fallback to particle effects
	active_effect_node = _create_effect_for_type(field_data.field_type, field_data.field_color)
	if active_effect_node:
		add_child(active_effect_node)


func _field_type_to_board_effect(field_type: FieldEffectData.FieldType) -> BoardAssetLoader.FieldEffect:
	"""Convert FieldEffectData type to BoardAssetLoader effect enum."""
	match field_type:
		FieldEffectData.FieldType.THERMAL:
			return BoardAssetLoader.FieldEffect.THERMAL
		FieldEffectData.FieldType.REPAIR:
			return BoardAssetLoader.FieldEffect.REPAIR
		FieldEffectData.FieldType.BOOST:
			return BoardAssetLoader.FieldEffect.BOOST
		FieldEffectData.FieldType.SUPPRESSION:
			return BoardAssetLoader.FieldEffect.SUPPRESSION
		_:
			return BoardAssetLoader.FieldEffect.NONE


func _fade_in_field_effect():
	"""Fade in the field effect overlay."""
	# Scale based on actual texture size
	if field_effect_overlay.texture:
		var target_size = get_meta("overlay_target_size", 180.0)
		var tex_size = field_effect_overlay.texture.get_size().x
		var scale_factor = target_size / tex_size
		field_effect_overlay.scale = Vector2(scale_factor, scale_factor)

	if not field_effect_overlay.visible:
		field_effect_overlay.modulate.a = 0.0
		field_effect_overlay.visible = true

	var tween = create_tween()
	tween.tween_property(field_effect_overlay, "modulate:a", 0.9, 0.4)

func _create_effect_for_type(field_type: FieldEffectData.FieldType, color: Color) -> Node2D:
	var effect_container = Node2D.new()
	var half_size = cell_size / 2.0

	match field_type:
		FieldEffectData.FieldType.THERMAL:
			# Fire effect - rising flames
			effect_container.add_child(_create_fire_particles(half_size))
		FieldEffectData.FieldType.REPAIR:
			# Healing effect - green sparkles rising
			effect_container.add_child(_create_heal_particles(half_size))
		FieldEffectData.FieldType.SUPPRESSION:
			# Suppression - dark energy swirling
			effect_container.add_child(_create_suppression_particles(half_size, color))
		FieldEffectData.FieldType.BOOST:
			# Boost - golden energy rising
			effect_container.add_child(_create_boost_particles(half_size))
		_:
			# Default - use color-based particles
			effect_container.add_child(_create_generic_particles(half_size, color))

	return effect_container

func _create_fire_particles(half_size: float) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()

	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(half_size * 0.7, 5, 1)
	material.direction = Vector3(0, -1, 0)
	material.spread = 15.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 3.0
	material.scale_max = 8.0

	# Fire color gradient
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.8, 0.2, 0.8))  # Yellow core
	gradient.set_color(1, Color(1.0, 0.3, 0.0, 0.0))  # Red fade out
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	material.color_ramp = gradient_tex

	particles.process_material = material
	particles.amount = 25
	particles.lifetime = 0.8
	particles.visibility_rect = Rect2(-half_size, -half_size * 2, half_size * 2, half_size * 2)

	return particles

func _create_heal_particles(half_size: float) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()

	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(half_size * 0.6, half_size * 0.6, 1)
	material.direction = Vector3(0, -1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3(0, -10, 0)
	material.scale_min = 2.0
	material.scale_max = 5.0

	# Healing green gradient
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.3, 1.0, 0.5, 0.9))  # Bright green
	gradient.set_color(1, Color(0.5, 1.0, 0.7, 0.0))  # Fade out
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	material.color_ramp = gradient_tex

	particles.process_material = material
	particles.amount = 15
	particles.lifetime = 1.2
	particles.visibility_rect = Rect2(-half_size, -half_size * 2, half_size * 2, half_size * 2)

	return particles

func _create_suppression_particles(half_size: float, color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()

	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_axis = Vector3(0, 0, 1)
	material.emission_ring_radius = half_size * 0.5
	material.emission_ring_inner_radius = half_size * 0.2
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.angular_velocity_min = -90.0
	material.angular_velocity_max = 90.0
	material.gravity = Vector3(0, 0, 0)
	material.scale_min = 2.0
	material.scale_max = 4.0

	# Dark swirling gradient
	var gradient = Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.7))
	gradient.set_color(1, Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.0))
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	material.color_ramp = gradient_tex

	particles.process_material = material
	particles.amount = 20
	particles.lifetime = 1.5
	particles.visibility_rect = Rect2(-half_size, -half_size, half_size * 2, half_size * 2)

	return particles

func _create_boost_particles(half_size: float) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()

	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(half_size * 0.5, half_size * 0.5, 1)
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 25.0
	material.initial_velocity_max = 50.0
	material.gravity = Vector3(0, -15, 0)
	material.scale_min = 2.0
	material.scale_max = 6.0

	# Golden boost gradient
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.85, 0.3, 0.9))  # Gold
	gradient.set_color(1, Color(1.0, 0.95, 0.6, 0.0))  # Fade
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	material.color_ramp = gradient_tex

	particles.process_material = material
	particles.amount = 18
	particles.lifetime = 1.0
	particles.visibility_rect = Rect2(-half_size, -half_size * 2, half_size * 2, half_size * 2)

	return particles

func _create_generic_particles(half_size: float, color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()

	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(half_size * 0.5, half_size * 0.5, 1)
	material.direction = Vector3(0, -1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 15.0
	material.initial_velocity_max = 35.0
	material.gravity = Vector3(0, -5, 0)
	material.scale_min = 2.0
	material.scale_max = 5.0

	var gradient = Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.8))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	material.color_ramp = gradient_tex

	particles.process_material = material
	particles.amount = 15
	particles.lifetime = 1.0
	particles.visibility_rect = Rect2(-half_size, -half_size * 2, half_size * 2, half_size * 2)

	return particles

func clear_field_effect():
	current_field_effect = ""

	# Clear AI overlay
	if field_effect_overlay and field_effect_overlay.visible:
		var tween = create_tween()
		tween.tween_property(field_effect_overlay, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): field_effect_overlay.visible = false)

	# Clear particle fallback
	if field_tween:
		field_tween.kill()
		field_tween = null

	if active_effect_node:
		active_effect_node.queue_free()
		active_effect_node = null


func clear_ownership():
	"""Clear the ownership overlay."""
	ownership = 0
	if ownership_overlay and ownership_overlay.visible:
		_fade_out_overlay(ownership_overlay)
