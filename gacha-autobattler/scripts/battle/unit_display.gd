extends Node2D
## Visual representation of a unit on the battle grid

signal unit_clicked(unit_instance: UnitInstance, display: Node2D)
signal unit_drag_started(unit_instance: UnitInstance, display: Node2D)

var unit_instance: UnitInstance
var is_dragging: bool = false
var drag_enabled: bool = true  # Can be disabled for certain contexts

# Status effect icons
var status_icons: Array = []

# AI sprite support
var ai_sprite: AnimatedSprite2D = null
var uses_ai_sprite: bool = false
var is_enemy: bool = false

# Visual references
@onready var body = $Body
@onready var element_rings = [$ElementRing, $ElementRing2, $ElementRing3, $ElementRing4]
@onready var element_label = $ElementLabel
@onready var star_label = $StarLabel
@onready var name_label = $NameLabel
@onready var hp_bar = $HPBar
@onready var hp_fill = $HPBar/HPFill
@onready var hp_label = $HPBar/HPLabel
@onready var cooldown_overlay = $CooldownOverlay
@onready var click_area = $ClickArea

# Sprite-based HP bar components
var hp_bar_bg: TextureRect = null
var hp_bar_fill: TextureRect = null
var hp_bar_fg: TextureRect = null
var uses_sprite_hp_bar: bool = false

# Sprite-based star rating
var star_container: HBoxContainer = null
var uses_sprite_stars: bool = false

func _ready():
	if click_area:
		click_area.input_event.connect(_on_input_event)
	_setup_sprite_hp_bar()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Mouse pressed - check if this starts a drag or is a click
			if drag_enabled and unit_instance and unit_instance.can_act():
				is_dragging = true
				unit_drag_started.emit(unit_instance, self)
			elif unit_instance:
				# Can't drag (on cooldown or already placed), just click
				unit_clicked.emit(unit_instance, self)


func _setup_sprite_hp_bar():
	"""Initialize sprite-based HP bar using UISpriteLoader if available."""
	# Try to create sprite HP bar components
	var hp_components = UISpriteLoader.create_hp_bar(UISpriteLoader.BarColor.GREEN, "MinimalBar")

	if hp_components.is_empty():
		# No sprite HP bar available, use default ColorRect style
		uses_sprite_hp_bar = false
		return

	uses_sprite_hp_bar = true

	# Hide the original ColorRect HP bar elements
	if hp_bar:
		hp_bar.visible = false

	# Set up HP bar container position (same as original)
	var bar_pos = Vector2(-45, 68)
	var bar_size = Vector2(90, 10)

	# Create background
	if "background" in hp_components:
		hp_bar_bg = hp_components["background"]
		hp_bar_bg.position = bar_pos
		hp_bar_bg.size = bar_size
		hp_bar_bg.stretch_mode = TextureRect.STRETCH_SCALE
		hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hp_bar_bg)

	# Create fill (this will be masked/scaled based on HP)
	if "fill" in hp_components:
		hp_bar_fill = hp_components["fill"]
		hp_bar_fill.position = bar_pos
		hp_bar_fill.size = bar_size
		hp_bar_fill.stretch_mode = TextureRect.STRETCH_SCALE
		hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hp_bar_fill)

	# Create foreground (frame)
	if "foreground" in hp_components:
		hp_bar_fg = hp_components["foreground"]
		hp_bar_fg.position = bar_pos
		hp_bar_fg.size = bar_size
		hp_bar_fg.stretch_mode = TextureRect.STRETCH_SCALE
		hp_bar_fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hp_bar_fg)

	# Re-add the HP label on top
	if hp_label:
		# Move HP label to be a sibling, positioned above the sprite bar
		var label_pos = bar_pos + Vector2(0, -2)
		var new_label = Label.new()
		new_label.name = "SpriteHPLabel"
		new_label.position = label_pos
		new_label.size = Vector2(bar_size.x, 14)
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		new_label.add_theme_font_size_override("font_size", 10)
		new_label.add_theme_color_override("font_color", Color.WHITE)
		new_label.add_theme_color_override("font_outline_color", Color.BLACK)
		new_label.add_theme_constant_override("outline_size", 2)
		new_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(new_label)
		hp_label = new_label

func setup(instance: UnitInstance):
	unit_instance = instance

	if unit_instance and unit_instance.unit_data:
		var data = unit_instance.unit_data

		# Set name
		name_label.text = data.unit_name

		# Set stars (try sprite-based first)
		_setup_star_display(data.star_rating)

		# Set element color on ring
		var element_color = data.get_element_color()
		for ring in element_rings:
			ring.color = element_color

		# Set element indicator
		if element_label:
			element_label.text = _get_element_letter(data.element)
			element_label.add_theme_color_override("font_color", element_color)

		# Check for AI sprite first, fall back to procedural pixel art
		_setup_sprite(data)

		# Update HP bar
		update_hp_display()

		# Update cooldown
		update_cooldown_display()


func _setup_star_display(rating: int):
	"""Set up star rating display - sprite-based or text fallback."""
	# Try to create sprite-based stars
	var sprite_stars = UISpriteLoader.create_star_display(rating, rating, UISpriteLoader.StarColor.GOLD)

	if sprite_stars:
		uses_sprite_stars = true

		# Hide text star label
		if star_label:
			star_label.visible = false

		# Clean up old star container if exists
		if star_container:
			star_container.queue_free()

		# Position the star container where the text label was
		star_container = sprite_stars
		star_container.position = Vector2(-50 + (100 - sprite_stars.get_minimum_size().x) / 2, 48)
		star_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(star_container)
	else:
		# Fall back to text stars
		uses_sprite_stars = false
		if star_label:
			star_label.visible = true
			star_label.text = "★".repeat(rating)

func update_hp_display():
	if not unit_instance or not unit_instance.unit_data:
		return

	var hp_percent = float(unit_instance.current_hp) / float(unit_instance.max_hp)

	# Update HP text
	if hp_label:
		hp_label.text = str(unit_instance.current_hp) + "/" + str(unit_instance.max_hp)

	if uses_sprite_hp_bar:
		# Update sprite-based HP bar
		if hp_bar_fill:
			# Scale the fill width based on HP percentage
			hp_bar_fill.size.x = 90.0 * hp_percent

			# Change fill color/modulate based on HP
			if hp_percent > 0.5:
				hp_bar_fill.modulate = Color(1.0, 1.0, 1.0)  # Normal (green)
			elif hp_percent > 0.25:
				hp_bar_fill.modulate = Color(1.2, 1.0, 0.4)  # Yellow tint
			else:
				hp_bar_fill.modulate = Color(1.2, 0.4, 0.4)  # Red tint
	else:
		# Update ColorRect-based HP bar (fallback)
		if hp_fill:
			hp_fill.offset_right = 90.0 * hp_percent

			# Change color based on HP
			if hp_percent > 0.5:
				hp_fill.color = Color(0.2, 0.8, 0.2)  # Green
			elif hp_percent > 0.25:
				hp_fill.color = Color(0.8, 0.8, 0.2)  # Yellow
			else:
				hp_fill.color = Color(0.8, 0.2, 0.2)  # Red

func show_damage_number(amount: int, is_heal: bool = false):
	var label = Label.new()
	label.text = str(amount) if is_heal else "-" + str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Play appropriate sound
	if is_heal:
		AudioManager.play_heal_sound()
	else:
		AudioManager.play_attack_hit()

	# Style the label
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)

	if is_heal:
		label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))  # Green for heal
		label.text = "+" + str(amount)
	else:
		label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))  # Red for damage

	# Position above the unit
	label.position = Vector2(-30, -80)
	add_child(label)

	# Animate floating up and fading out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)

func flash_color(color: Color, duration: float = 0.2):
	var original_modulate = modulate
	modulate = color
	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, duration)

func play_entry_animation(from_direction: String = "bottom"):
	# Play place sound
	AudioManager.play_unit_place()

	# Store final position and scale
	var final_position = position
	var final_scale = scale

	# Start off-screen or scaled down based on direction
	match from_direction:
		"bottom":
			position = final_position + Vector2(0, 150)
			modulate.a = 0.0
		"top":
			position = final_position + Vector2(0, -150)
			modulate.a = 0.0
		"left":
			position = final_position + Vector2(-150, 0)
			modulate.a = 0.0
		"right":
			position = final_position + Vector2(150, 0)
			modulate.a = 0.0
		"scale":
			scale = Vector2.ZERO
			modulate.a = 0.0
		_:
			position = final_position + Vector2(0, 100)
			modulate.a = 0.0

	# Create entry animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Animate position/scale
	if from_direction == "scale":
		tween.tween_property(self, "scale", final_scale, 0.4)
	else:
		tween.tween_property(self, "position", final_position, 0.35).set_trans(Tween.TRANS_QUAD)

	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

	# Add a subtle bounce at the end
	tween.chain().tween_property(self, "scale", final_scale * 1.1, 0.1).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", final_scale, 0.1).set_trans(Tween.TRANS_QUAD)

func play_exit_animation(callback: Callable = Callable()):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)

	# Scale down and fade out
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)

	if callback.is_valid():
		tween.chain().tween_callback(callback)

func update_cooldown_display():
	if unit_instance:
		cooldown_overlay.visible = unit_instance.is_on_cooldown

func set_selected(selected: bool):
	# Visual feedback when unit is selected
	if selected:
		modulate = Color(1.2, 1.2, 1.2)  # Brighten
	else:
		modulate = Color(1.0, 1.0, 1.0)  # Normal

func _setup_sprite(data: UnitData):
	"""Set up the unit sprite - AI sprite if available, otherwise procedural."""
	# Clean up existing AI sprite if any
	if ai_sprite:
		ai_sprite.queue_free()
		ai_sprite = null
		uses_ai_sprite = false

	# Check if this unit has an AI sprite
	if UnitSpriteLoader.has_ai_sprite(data.unit_id):
		ai_sprite = UnitSpriteLoader.create_animated_sprite(data.unit_id)
		if ai_sprite:
			uses_ai_sprite = true
			body.visible = false
			ai_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ai_sprite.scale = Vector2(2.0, 2.0)  # Scale up 100px sprites for better visibility
			add_child(ai_sprite)
			ai_sprite.play("idle")
			return

	# Fall back to procedural pixel art
	uses_ai_sprite = false
	body.visible = true
	body.texture = PixelArtGenerator.generate_unit_texture(data)


func play_attack_animation():
	"""Play attack animation if using AI sprites."""
	if uses_ai_sprite and ai_sprite and ai_sprite.sprite_frames.has_animation("attack"):
		ai_sprite.play("attack")
		# Return to idle when done
		if not ai_sprite.animation_finished.is_connected(_on_animation_finished):
			ai_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func play_attack_lunge(battle_speed: float = 1.0) -> void:
	"""Play attack lunge animation - unit moves toward target and back."""
	var original_pos = position
	var lunge_distance = 40.0  # How far to lunge

	# Direction: player units lunge right (+x), enemy units lunge left (-x)
	var lunge_direction = Vector2(-1, 0) if is_enemy else Vector2(1, 0)
	var target_pos = original_pos + (lunge_direction * lunge_distance)

	# Calculate times based on battle speed
	var lunge_time = 0.15 / battle_speed
	var hold_time = 0.05 / battle_speed
	var return_time = 0.12 / battle_speed

	# Play attack sprite animation
	play_attack_animation()

	# Lunge forward
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position", target_pos, lunge_time)
	await tween.finished

	# Brief hold at lunge position
	await get_tree().create_timer(hold_time).timeout

	# Return to original position
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_OUT)
	return_tween.set_trans(Tween.TRANS_QUAD)
	return_tween.tween_property(self, "position", original_pos, return_time)
	await return_tween.finished


func spawn_hit_particles(damage_amount: int = 0, is_crit: bool = false) -> void:
	"""Spawn impact particles at hit location."""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 12 if not is_crit else 20
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.position = Vector2.ZERO

	# Emission shape - small burst
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0

	# Movement - burst outward from hit
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity_min = 60
	particles.initial_velocity_max = 120

	# Appearance
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0

	# Color - red/orange for damage, yellow for crit
	var hit_color = Color(1.0, 0.8, 0.2) if is_crit else Color(1.0, 0.4, 0.2)
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, hit_color)
	color_ramp.set_color(1, Color(hit_color.r, hit_color.g, hit_color.b, 0))
	particles.color_ramp = color_ramp

	add_child(particles)

	# Auto-cleanup
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)


func spawn_ability_cast_effect(element: String, battle_speed: float = 1.0) -> void:
	"""Spawn element-colored aura/glow when using abilities."""
	# Get element color
	var element_color = Color(0.8, 0.8, 0.8)
	if unit_instance and unit_instance.unit_data:
		element_color = unit_instance.unit_data.get_element_color()
	else:
		# Fallback element colors
		match element.to_lower():
			"fire": element_color = Color(1.0, 0.4, 0.2)
			"water": element_color = Color(0.3, 0.6, 1.0)
			"nature": element_color = Color(0.3, 0.9, 0.4)
			"light": element_color = Color(1.0, 1.0, 0.6)
			"dark": element_color = Color(0.6, 0.3, 0.8)

	# Create aura glow effect
	var aura = ColorRect.new()
	aura.size = Vector2(100, 100)
	aura.position = Vector2(-50, -50)
	aura.color = Color(element_color.r, element_color.g, element_color.b, 0.0)
	aura.z_index = -1
	add_child(aura)

	# Animate aura pulse
	var duration = 0.3 / battle_speed
	var tween = create_tween()
	tween.tween_property(aura, "color:a", 0.4, duration * 0.3)
	tween.tween_property(aura, "color:a", 0.0, duration * 0.7)
	tween.tween_callback(aura.queue_free)

	# Also spawn rising particles
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 15
	particles.lifetime = 0.5 / battle_speed
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.position = Vector2.ZERO

	# Rising particle effect
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 25.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, -50)
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0

	# Element color gradient
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, element_color)
	color_ramp.set_color(1, Color(element_color.r, element_color.g, element_color.b, 0))
	particles.color_ramp = color_ramp

	add_child(particles)

	# Auto-cleanup
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)


func play_hurt_animation():
	"""Play hurt animation if using AI sprites."""
	if uses_ai_sprite and ai_sprite and ai_sprite.sprite_frames.has_animation("hurt"):
		ai_sprite.play("hurt")
		if not ai_sprite.animation_finished.is_connected(_on_animation_finished):
			ai_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func _on_animation_finished():
	"""Return to idle after attack/hurt animation."""
	if ai_sprite:
		ai_sprite.play("idle")


func play_knockout_animation(battle_speed: float = 1.0, callback: Callable = Callable()):
	"""Play dramatic knockout animation: red flash, shake, element particles, fade out."""
	# Play death sound
	AudioManager.play_unit_death()

	var original_pos = position

	# Get element color for particles
	var element_color = Color(0.8, 0.8, 0.8)  # Default gray
	if unit_instance and unit_instance.unit_data:
		element_color = unit_instance.unit_data.get_element_color()

	# Helper for speed-adjusted times
	var get_time = func(base_time: float) -> float:
		return base_time / battle_speed

	# Step 1: Red flash (0.15s)
	modulate = Color(1.5, 0.3, 0.3)
	await get_tree().create_timer(get_time.call(0.15)).timeout

	# Step 2: Death shake (0.3s, 5 oscillations)
	var shake_duration = get_time.call(0.3)
	var shake_count = 5
	var shake_time = shake_duration / shake_count
	var shake_amount = 8.0

	for i in range(shake_count):
		var offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount * 0.5, shake_amount * 0.5))
		position = original_pos + offset
		await get_tree().create_timer(shake_time).timeout
		shake_amount *= 0.7
	position = original_pos

	# Step 3: Spawn element particles
	_spawn_knockout_particles(element_color)

	# Step 4: Fade out (0.3s, scale to 0.8, opacity to 0)
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "scale", scale * 0.8, get_time.call(0.3)).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(self, "modulate:a", 0.0, get_time.call(0.3)).set_ease(Tween.EASE_IN)
	await fade_tween.finished

	# Call callback when done
	if callback.is_valid():
		callback.call()


func _spawn_knockout_particles(element_color: Color):
	"""Create particle burst for knockout effect."""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 25
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.position = Vector2.ZERO

	# Emission shape - small burst from center
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 15.0

	# Movement - burst outward
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 150)
	particles.initial_velocity_min = 80
	particles.initial_velocity_max = 180

	# Appearance
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0

	# Color gradient - element color fading out
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, element_color)
	color_ramp.set_color(1, Color(element_color.r, element_color.g, element_color.b, 0))
	particles.color_ramp = color_ramp

	# Add variation with lighter/darker shades
	var initial_ramp = Gradient.new()
	initial_ramp.offsets = [0.0, 0.5, 1.0]
	initial_ramp.colors = [
		element_color.lightened(0.3),
		element_color,
		element_color.darkened(0.2)
	]
	particles.color_initial_ramp = initial_ramp

	# Add to scene (parent to ensure it stays visible after unit fades)
	var parent = get_parent()
	if parent:
		parent.add_child(particles)
		particles.global_position = global_position
	else:
		add_child(particles)

	# Auto-cleanup after particles finish
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)


func set_enemy(enemy: bool):
	"""Set whether this unit is an enemy (affects sprite facing direction)."""
	is_enemy = enemy
	_update_sprite_facing()


func _update_sprite_facing():
	"""Update sprite flip based on ownership. Player faces right, enemy faces left."""
	# Player units face right (no flip), enemy units face left (flip)
	var should_flip = is_enemy

	if uses_ai_sprite and ai_sprite:
		ai_sprite.flip_h = should_flip
	else:
		body.flip_h = should_flip


func _get_element_letter(element: String) -> String:
	match element:
		"fire": return "F"
		"water": return "W"
		"nature": return "N"
		"light": return "L"
		"dark": return "D"
		_: return "?"

func update_status_display():
	# Clear existing status icons
	for icon in status_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	status_icons.clear()

	if not unit_instance:
		return

	# Create icons for each active status effect
	var x_offset = -40
	for effect in unit_instance.active_status_effects:
		var data = effect.effect_data as StatusEffectData

		# Create container for icon + duration
		var container = Control.new()
		container.position = Vector2(x_offset, -90)
		add_child(container)

		# Create background panel (cyber feel)
		var bg = ColorRect.new()
		bg.size = Vector2(24, 24)
		bg.position = Vector2(-12, -12)
		bg.color = Color(0.1, 0.1, 0.15, 0.9)
		container.add_child(bg)

		# Create icon label
		var icon_label = Label.new()
		icon_label.text = data.icon_symbol
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.size = Vector2(24, 24)
		icon_label.position = Vector2(-12, -14)
		icon_label.add_theme_font_size_override("font_size", 14)
		icon_label.add_theme_color_override("font_color", data.icon_color)
		container.add_child(icon_label)

		# Create duration label
		var duration_label = Label.new()
		duration_label.text = str(effect.duration)
		duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		duration_label.size = Vector2(24, 16)
		duration_label.position = Vector2(-12, 6)
		duration_label.add_theme_font_size_override("font_size", 10)
		duration_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		container.add_child(duration_label)

		# Add glow effect for cyber feel
		var glow = ColorRect.new()
		glow.size = Vector2(28, 28)
		glow.position = Vector2(-14, -14)
		glow.color = Color(data.icon_color.r, data.icon_color.g, data.icon_color.b, 0.2)
		glow.z_index = -1
		container.add_child(glow)

		status_icons.append(container)
		x_offset += 28
