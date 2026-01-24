extends Area2D
## A single cell in the 3x3 battle grid
## Handles click detection and visual overlays (hover, ownership)
## Floor tiles are rendered separately by BoardBuilder

signal cell_clicked(row: int, col: int)

# Cell position in grid
var grid_row: int = 0
var grid_col: int = 0
var cell_size: int = 80

# Cell state
var ownership: int = 0  # 0 = empty, 1 = player, 2 = enemy, 3 = contested
var is_hovered: bool = false
var current_field_effect: String = ""

# Visual overlays (created dynamically)
var hover_overlay: ColorRect = null
var owner_overlay: ColorRect = null

# Field effect visuals
var active_effect_node: Node2D = null
var field_tween: Tween = null

# Ownership colors (disabled - all transparent)
const OWNER_COLORS = {
	0: Color(0, 0, 0, 0),  # Empty
	1: Color(0, 0, 0, 0),  # Player
	2: Color(0, 0, 0, 0),  # Enemy
	3: Color(0, 0, 0, 0),  # Contested
}

func _ready():
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)


func setup(row: int, col: int, size: int):
	grid_row = row
	grid_col = col
	cell_size = size

	var half_size = size / 2.0

	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size, size)
	collision_shape.shape = shape
	add_child(collision_shape)

	# Create ownership overlay
	owner_overlay = ColorRect.new()
	owner_overlay.size = Vector2(size, size)
	owner_overlay.position = Vector2(-half_size, -half_size)
	owner_overlay.color = OWNER_COLORS[0]
	owner_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(owner_overlay)

	# Create hover overlay
	hover_overlay = ColorRect.new()
	hover_overlay.size = Vector2(size, size)
	hover_overlay.position = Vector2(-half_size, -half_size)
	hover_overlay.color = Color(1, 1, 1, 0.25)
	hover_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_overlay.visible = false
	add_child(hover_overlay)


func set_ownership(new_owner: int):
	ownership = new_owner
	if owner_overlay:
		var target_color = OWNER_COLORS.get(new_owner, OWNER_COLORS[0])
		# Animate color change
		var tween = create_tween()
		tween.tween_property(owner_overlay, "color", target_color, 0.2)


func set_contested(is_contested: bool):
	"""Set the cell as contested (both player and enemy present)."""
	if is_contested:
		set_ownership(3)


func clear_ownership():
	"""Clear the ownership overlay."""
	set_ownership(0)


func _on_mouse_entered():
	is_hovered = true
	if hover_overlay:
		hover_overlay.visible = true


func _on_mouse_exited():
	is_hovered = false
	if hover_overlay:
		hover_overlay.visible = false


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

	current_field_effect = field_data.field_name

	# Create particle effects
	active_effect_node = _create_effect_for_type(field_data.field_type, field_data.field_color)
	if active_effect_node:
		add_child(active_effect_node)


func _create_effect_for_type(field_type: FieldEffectData.FieldType, color: Color) -> Node2D:
	var effect_container = Node2D.new()
	var half_size = cell_size / 2.0

	match field_type:
		FieldEffectData.FieldType.THERMAL:
			effect_container.add_child(_create_fire_particles(half_size))
		FieldEffectData.FieldType.REPAIR:
			effect_container.add_child(_create_heal_particles(half_size))
		FieldEffectData.FieldType.SUPPRESSION:
			effect_container.add_child(_create_suppression_particles(half_size, color))
		FieldEffectData.FieldType.BOOST:
			effect_container.add_child(_create_boost_particles(half_size))
		_:
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

	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.8, 0.2, 0.8))
	gradient.set_color(1, Color(1.0, 0.3, 0.0, 0.0))
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

	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.3, 1.0, 0.5, 0.9))
	gradient.set_color(1, Color(0.5, 1.0, 0.7, 0.0))
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

	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.85, 0.3, 0.9))
	gradient.set_color(1, Color(1.0, 0.95, 0.6, 0.0))
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

	if field_tween:
		field_tween.kill()
		field_tween = null

	if active_effect_node:
		active_effect_node.queue_free()
		active_effect_node = null
