extends CanvasLayer
## Global scene transition handler - add as autoload
## Usage: SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")

signal transition_started
signal transition_midpoint  # Emitted when screen is fully black (scene changes here)
signal transition_finished

var overlay: ColorRect
var is_transitioning: bool = false

# Transition settings
var fade_color: Color = Color(0.02, 0.02, 0.04, 1)  # Match UITheme.BG_DARK
var fade_out_duration: float = 0.2
var fade_in_duration: float = 0.2


func _ready():
	# Ensure this layer is always on top
	layer = 100

	# Create the overlay
	overlay = ColorRect.new()
	overlay.name = "TransitionOverlay"
	overlay.color = Color(fade_color.r, fade_color.g, fade_color.b, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)


func change_scene(scene_path: String, custom_fade_out: float = -1, custom_fade_in: float = -1):
	"""Transition to a new scene with fade effect."""
	if is_transitioning:
		return

	is_transitioning = true
	transition_started.emit()

	var out_time = custom_fade_out if custom_fade_out >= 0 else fade_out_duration
	var in_time = custom_fade_in if custom_fade_in >= 0 else fade_in_duration

	# Block input during transition
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# Fade out
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, out_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.finished

	transition_midpoint.emit()

	# Change scene
	get_tree().change_scene_to_file(scene_path)

	# Wait a frame for the new scene to initialize
	await get_tree().process_frame

	# Fade in
	tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished

	# Restore input
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	is_transitioning = false
	transition_finished.emit()


func fade_out(duration: float = -1) -> void:
	"""Just fade to black without changing scene."""
	if is_transitioning:
		return

	is_transitioning = true
	var time = duration if duration >= 0 else fade_out_duration

	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.finished


func fade_in(duration: float = -1) -> void:
	"""Just fade in from black."""
	var time = duration if duration >= 0 else fade_in_duration

	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished

	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false


func set_fade_color(color: Color):
	"""Change the fade color."""
	fade_color = color
	if overlay:
		overlay.color = Color(color.r, color.g, color.b, overlay.color.a)
