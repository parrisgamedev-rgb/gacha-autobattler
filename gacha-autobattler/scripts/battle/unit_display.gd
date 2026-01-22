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

func _ready():
	if click_area:
		click_area.input_event.connect(_on_input_event)

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

func setup(instance: UnitInstance):
	unit_instance = instance

	if unit_instance and unit_instance.unit_data:
		var data = unit_instance.unit_data

		# Set name
		name_label.text = data.unit_name

		# Set stars
		star_label.text = "★".repeat(data.star_rating)

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

func update_hp_display():
	if unit_instance and unit_instance.unit_data:
		var hp_percent = float(unit_instance.current_hp) / float(unit_instance.unit_data.max_hp)
		hp_fill.offset_right = 90.0 * hp_percent

		# Update HP text
		if hp_label:
			hp_label.text = str(unit_instance.current_hp) + "/" + str(unit_instance.unit_data.max_hp)

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
	if AISpriteLoader.has_ai_sprite(data.unit_id):
		ai_sprite = AISpriteLoader.create_animated_sprite(data.unit_id)
		if ai_sprite:
			uses_ai_sprite = true
			body.visible = false
			ai_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ai_sprite.scale = Vector2(1, 1)  # AI sprites are already 128px
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
