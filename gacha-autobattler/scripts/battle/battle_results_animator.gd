extends Node
class_name BattleResultsAnimator
## Handles animated victory and defeat sequences with sprite-based UI

signal animation_complete

# References set by battle.gd
var results_panel: Panel
var result_title: Label
var result_subtitle: Label
var button_container: HBoxContainer
var battle_speed: float = 1.0

# Overlay nodes (created dynamically or referenced)
var screen_flash: ColorRect
var dim_overlay: ColorRect
var confetti_emitter: CPUParticles2D

# Sprite-based UI elements
var banner_rect: NinePatchRect = null
var star_container: HBoxContainer = null
var ui_styled: bool = false

# Animation state
var is_animating: bool = false
var skip_requested: bool = false

# Colors
const VICTORY_GREEN = Color(0.3, 0.9, 0.3)
const VICTORY_GOLD = Color(1.0, 0.85, 0.3)
const DEFEAT_RED = Color(0.9, 0.3, 0.3)
const DEFEAT_DARK = Color(0.4, 0.3, 0.3)


func _ready():
	# Create overlay nodes if they don't exist
	_create_overlay_nodes()


func _create_overlay_nodes():
	# Screen flash overlay (white, initially invisible)
	screen_flash = ColorRect.new()
	screen_flash.name = "ScreenFlash"
	screen_flash.color = Color(1, 1, 1, 0)
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_flash.position = Vector2.ZERO
	screen_flash.size = Vector2(1920, 1080)
	screen_flash.z_index = 50
	screen_flash.visible = true

	# Dim overlay (dark, initially invisible - alpha is 0)
	dim_overlay = ColorRect.new()
	dim_overlay.name = "DimOverlay"
	dim_overlay.color = Color(0, 0, 0, 0)
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_overlay.position = Vector2.ZERO
	dim_overlay.size = Vector2(1920, 1080)
	dim_overlay.z_index = 49
	dim_overlay.visible = true


func setup(ui_layer: CanvasLayer, panel: Panel, title: Label, subtitle: Label, buttons: HBoxContainer):
	"""Initialize references from battle scene"""
	results_panel = panel
	result_title = title
	result_subtitle = subtitle
	button_container = buttons

	# Add overlays to UI layer
	if screen_flash.get_parent():
		screen_flash.get_parent().remove_child(screen_flash)
	if dim_overlay.get_parent():
		dim_overlay.get_parent().remove_child(dim_overlay)

	ui_layer.add_child(dim_overlay)
	ui_layer.add_child(screen_flash)

	# Ensure overlays start invisible
	screen_flash.color = Color(1, 1, 1, 0)
	dim_overlay.color = Color(0, 0, 0, 0)

	# Create confetti emitter
	_create_confetti_emitter(ui_layer)

	# Ensure panel starts hidden
	results_panel.visible = false
	results_panel.modulate.a = 1.0
	results_panel.scale = Vector2.ONE

	# Apply sprite-based UI styling
	_apply_sprite_ui_styling()


func _create_confetti_emitter(parent: Node):
	"""Create the confetti particle system"""
	confetti_emitter = CPUParticles2D.new()
	confetti_emitter.name = "ConfettiEmitter"
	confetti_emitter.emitting = false
	confetti_emitter.amount = 100
	confetti_emitter.lifetime = 3.0
	confetti_emitter.one_shot = true
	confetti_emitter.explosiveness = 0.8
	confetti_emitter.position = Vector2(960, -50)  # Top center

	# Emission shape - spread across top of screen
	confetti_emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti_emitter.emission_rect_extents = Vector2(500, 10)

	# Movement
	confetti_emitter.direction = Vector2(0, 1)  # Fall down
	confetti_emitter.spread = 30.0
	confetti_emitter.gravity = Vector2(0, 200)
	confetti_emitter.initial_velocity_min = 100
	confetti_emitter.initial_velocity_max = 300

	# Appearance
	confetti_emitter.scale_amount_min = 3.0
	confetti_emitter.scale_amount_max = 6.0
	confetti_emitter.color = Color(1, 0.85, 0.3)  # Gold base

	# Color variation for confetti
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.85, 0.3))  # Gold
	gradient.set_color(1, Color(1.0, 0.85, 0.3))
	confetti_emitter.color_ramp = gradient

	# Random colors
	confetti_emitter.color_initial_ramp = _create_confetti_colors()

	# Rotation
	confetti_emitter.angular_velocity_min = -180
	confetti_emitter.angular_velocity_max = 180

	confetti_emitter.z_index = 100
	parent.add_child(confetti_emitter)


func _create_confetti_colors() -> Gradient:
	"""Create a gradient for random confetti colors"""
	var gradient = Gradient.new()
	gradient.offsets = [0.0, 0.25, 0.5, 0.75, 1.0]
	gradient.colors = [
		Color(1.0, 0.85, 0.3),   # Gold
		Color(0.3, 0.9, 0.5),    # Green
		Color(0.4, 0.7, 1.0),    # Blue
		Color(1.0, 0.5, 0.5),    # Red/Pink
		Color(0.9, 0.6, 1.0),    # Purple
	]
	return gradient


func _apply_sprite_ui_styling():
	"""Apply sprite-based UI assets to the results panel."""
	if ui_styled:
		return
	ui_styled = true

	# Style the buttons with sprite buttons
	_style_result_buttons()


func _style_result_buttons():
	"""Apply sprite styling to result buttons."""
	if not button_container:
		return

	for child in button_container.get_children():
		if child is Button:
			# Play Again gets gold, Main Menu gets blue
			if "PlayAgain" in child.name or "Again" in child.name:
				UISpriteLoader.apply_button_style(child, UISpriteLoader.ButtonColor.GOLD, "ButtonA")
			else:
				UISpriteLoader.apply_button_style(child, UISpriteLoader.ButtonColor.BLUE, "ButtonA")


func _setup_victory_ui():
	"""Set up victory-specific UI elements (gold panel, banner, stars)."""
	# Apply gold panel style
	if results_panel:
		UISpriteLoader.apply_panel_style(results_panel, UISpriteLoader.PanelColor.GOLD, "Panel")

	# Create star display for victory (3 stars)
	_create_victory_stars(3)


func _setup_defeat_ui():
	"""Set up defeat-specific UI elements (red panel)."""
	# Apply red panel style
	if results_panel:
		UISpriteLoader.apply_panel_style(results_panel, UISpriteLoader.PanelColor.RED, "Panel")

	# Remove stars if they exist
	if star_container and is_instance_valid(star_container):
		star_container.queue_free()
		star_container = null


func _create_victory_stars(rating: int):
	"""Create animated star display for victory."""
	# Remove existing stars
	if star_container and is_instance_valid(star_container):
		star_container.queue_free()

	# Create new star display
	star_container = UISpriteLoader.create_star_display(rating, 3, UISpriteLoader.StarColor.GOLD)
	if star_container and results_panel:
		# Position stars above the title
		star_container.position = Vector2(
			(results_panel.size.x - star_container.get_minimum_size().x) / 2,
			20
		)
		star_container.modulate.a = 0  # Start invisible for animation
		results_panel.add_child(star_container)


func _animate_stars_reveal(duration: float):
	"""Animate stars appearing one by one."""
	if not star_container:
		return

	var stars = star_container.get_children()
	var delay_per_star = duration / max(stars.size(), 1)

	for i in range(stars.size()):
		if skip_requested:
			star_container.modulate.a = 1.0
			return

		var star = stars[i]
		star.scale = Vector2(0.5, 0.5)
		star.modulate.a = 0

		await get_tree().create_timer(delay_per_star * 0.5).timeout

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(star, "scale", Vector2(1.2, 1.2), delay_per_star * 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(star, "modulate:a", 1.0, delay_per_star * 0.2)
		await tween.finished

		# Settle to normal size
		var settle_tween = create_tween()
		settle_tween.tween_property(star, "scale", Vector2.ONE, delay_per_star * 0.2).set_ease(Tween.EASE_OUT)
		await settle_tween.finished

	# Make container fully visible
	star_container.modulate.a = 1.0


func set_battle_speed(speed: float):
	"""Update animation speed multiplier"""
	battle_speed = speed


func get_scaled_time(base_time: float) -> float:
	"""Get time adjusted for battle speed"""
	return base_time / battle_speed


func play_victory(title_text: String, subtitle_text: String):
	"""Play the victory animation sequence"""
	is_animating = true
	skip_requested = false

	# Set up victory UI styling (gold panel, stars)
	_setup_victory_ui()

	# Prepare panel content (hidden initially)
	result_title.text = title_text
	result_title.add_theme_color_override("font_color", VICTORY_GOLD)
	result_title.add_theme_color_override("font_outline_color", Color(0.4, 0.25, 0.0))
	result_title.add_theme_constant_override("outline_size", 3)
	result_subtitle.text = ""  # Will animate in
	button_container.modulate.a = 0
	results_panel.scale = Vector2(0.5, 0.5)
	results_panel.modulate.a = 0
	results_panel.pivot_offset = results_panel.size / 2

	# Start sequence
	await _victory_sequence(subtitle_text)

	is_animating = false
	animation_complete.emit()


func play_defeat(title_text: String, subtitle_text: String):
	"""Play the defeat animation sequence"""
	is_animating = true
	skip_requested = false

	# Set up defeat UI styling (red panel)
	_setup_defeat_ui()

	# Prepare panel content
	result_title.text = title_text
	result_title.add_theme_color_override("font_color", DEFEAT_RED)
	result_title.add_theme_color_override("font_outline_color", Color(0.3, 0.0, 0.0))
	result_title.add_theme_constant_override("outline_size", 3)
	result_subtitle.text = subtitle_text
	button_container.modulate.a = 0
	results_panel.position.y -= 50  # Start above final position
	results_panel.modulate.a = 0

	# Start sequence
	await _defeat_sequence()

	is_animating = false
	animation_complete.emit()


func _victory_sequence(subtitle_text: String):
	"""Execute victory animation sequence"""
	var original_panel_pos = results_panel.position

	# Step 1: Screen flash
	if not skip_requested:
		await _screen_flash(Color(1, 1, 1, 0.7), get_scaled_time(0.1))

	# Step 2: Dim background
	if not skip_requested:
		await _dim_background(Color(0, 0, 0, 0.5), get_scaled_time(0.3))

	# Step 3: Show panel with bounce
	results_panel.visible = true
	if not skip_requested:
		await _animate_panel_entrance_bounce(get_scaled_time(0.4))
	else:
		results_panel.scale = Vector2.ONE
		results_panel.modulate.a = 1.0

	# Step 4: Start confetti
	if confetti_emitter and not skip_requested:
		confetti_emitter.emitting = true

	# Step 5: Title pulse
	if not skip_requested:
		await _pulse_title(get_scaled_time(0.3))

	# Step 5.5: Animate victory stars
	if star_container and not skip_requested:
		await _animate_stars_reveal(get_scaled_time(0.6))
	elif star_container:
		star_container.modulate.a = 1.0

	# Step 6: Animate rewards text
	if not skip_requested:
		await _animate_rewards_text(subtitle_text, get_scaled_time(0.8))
	else:
		result_subtitle.text = subtitle_text

	# Step 7: Show buttons
	if not skip_requested:
		await _fade_in_buttons(get_scaled_time(0.2))
	else:
		button_container.modulate.a = 1.0


func _defeat_sequence():
	"""Execute defeat animation sequence"""
	var original_panel_pos = results_panel.position
	var stored_pos_y = original_panel_pos.y + 50  # Actual target position

	# Step 1: Screen shake
	if not skip_requested:
		await _screen_shake(get_scaled_time(0.3))

	# Step 2: Dim background with red tint
	if not skip_requested:
		await _dim_background(Color(0.1, 0, 0, 0.55), get_scaled_time(0.5))
	else:
		dim_overlay.color = Color(0.15, 0, 0, 0.8)

	# Step 3: Panel slides down
	results_panel.visible = true
	results_panel.position.y = stored_pos_y - 50
	if not skip_requested:
		await _animate_panel_slide_down(stored_pos_y, get_scaled_time(0.4))
	else:
		results_panel.position.y = stored_pos_y
		results_panel.modulate.a = 1.0

	# Step 4: Brief pause
	if not skip_requested:
		await get_tree().create_timer(get_scaled_time(0.5)).timeout

	# Step 5: Show buttons
	if not skip_requested:
		await _fade_in_buttons(get_scaled_time(0.2))
	else:
		button_container.modulate.a = 1.0


func _screen_flash(color: Color, duration: float):
	"""Quick white flash effect"""
	screen_flash.color = color

	var tween = create_tween()
	tween.tween_property(screen_flash, "color:a", 0.0, duration)
	await tween.finished


func _dim_background(color: Color, duration: float):
	"""Fade in dark overlay"""
	var tween = create_tween()
	tween.tween_property(dim_overlay, "color", color, duration)
	await tween.finished


func _animate_panel_entrance_bounce(duration: float):
	"""Panel scales up with bounce easing"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(results_panel, "scale", Vector2.ONE, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(results_panel, "modulate:a", 1.0, duration * 0.5)
	await tween.finished


func _animate_panel_slide_down(target_y: float, duration: float):
	"""Panel slides down from above"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(results_panel, "position:y", target_y, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(results_panel, "modulate:a", 1.0, duration * 0.7)
	await tween.finished


func _pulse_title(duration: float):
	"""Title does a quick scale pulse"""
	var original_scale = result_title.scale
	var tween = create_tween()
	tween.tween_property(result_title, "scale", Vector2(1.15, 1.15), duration * 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_title, "scale", Vector2.ONE, duration * 0.5).set_ease(Tween.EASE_IN)
	await tween.finished


func _animate_rewards_text(full_text: String, duration: float):
	"""Reveal rewards text character by character or line by line"""
	var lines = full_text.split("\n")
	var delay_per_line = duration / max(lines.size(), 1)

	result_subtitle.text = ""

	for i in range(lines.size()):
		if skip_requested:
			result_subtitle.text = full_text
			return

		if i > 0:
			result_subtitle.text += "\n"
		result_subtitle.text += lines[i]

		await get_tree().create_timer(delay_per_line).timeout


func _fade_in_buttons(duration: float):
	"""Fade in the button container"""
	var tween = create_tween()
	tween.tween_property(button_container, "modulate:a", 1.0, duration)
	await tween.finished


func _screen_shake(duration: float):
	"""Shake the screen briefly"""
	var ui_layer = results_panel.get_parent()
	if not ui_layer:
		return

	var original_offset = Vector2.ZERO
	var shake_amount = 8.0
	var shake_count = 6
	var shake_duration = duration / shake_count

	for i in range(shake_count):
		if skip_requested:
			break
		var offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		# Apply shake to UI elements (not the whole layer)
		var tween = create_tween()
		tween.tween_property(results_panel, "position", results_panel.position + offset, shake_duration * 0.5)
		tween.tween_property(results_panel, "position", results_panel.position, shake_duration * 0.5)
		await tween.finished
		shake_amount *= 0.7  # Decay


func skip_animation():
	"""Skip to the end of the current animation"""
	skip_requested = true


func reset():
	"""Reset all animation states"""
	is_animating = false
	skip_requested = false

	if screen_flash:
		screen_flash.color.a = 0
	if dim_overlay:
		dim_overlay.color.a = 0
	if confetti_emitter:
		confetti_emitter.emitting = false
	if results_panel:
		results_panel.visible = false
		results_panel.scale = Vector2.ONE
		results_panel.modulate.a = 1.0
	if button_container:
		button_container.modulate.a = 1.0
	if star_container and is_instance_valid(star_container):
		star_container.queue_free()
		star_container = null


func _input(event):
	"""Handle skip input during animations"""
	if is_animating and event is InputEventMouseButton:
		if event.pressed:
			skip_animation()
