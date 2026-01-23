extends Node
## Tutorial Manager - Handles interactive tutorials and onboarding
## Add as autoload named "TutorialManager"

signal tutorial_step_shown(step_id: String)
signal tutorial_step_completed(step_id: String)
signal tutorial_completed(tutorial_id: String)
signal tutorial_skipped(tutorial_id: String)

# Tutorial state
var is_tutorial_active: bool = false
var current_tutorial: String = ""
var current_step: int = 0
var completed_tutorials: Array[String] = []

# Tutorial overlay references
var overlay: CanvasLayer = null
var dim_background: ColorRect = null
var highlight_rect: Control = null
var message_panel: Panel = null
var message_label: RichTextLabel = null
var continue_button: Button = null
var skip_button: Button = null

# Tutorial definitions
var tutorials: Dictionary = {}

# Settings path
const TUTORIAL_SAVE_PATH = "user://tutorial_progress.json"


func _ready():
	_load_progress()
	_define_tutorials()
	_create_overlay()


func _define_tutorials():
	"""Define all tutorial sequences."""

	# Main battle tutorial - shown on first Quick Battle
	tutorials["battle_basics"] = {
		"name": "Battle Basics",
		"steps": [
			{
				"id": "welcome",
				"message": "[b]Welcome to Grid Battler![/b]\n\nThis quick tutorial will teach you the basics.\n\nClick [b]Continue[/b] to start.",
				"highlight": null,
				"wait_for": "continue"
			},
			{
				"id": "place_unit",
				"message": "[b]Place Your Units[/b]\n\n[color=#4a9eff]Drag a unit[/color] from the bottom roster onto the 3x3 grid.\n\nYou have [color=#ffd700]3 actions[/color] per turn - place up to 3 units!",
				"highlight": "roster",
				"wait_for": "unit_placed"
			},
			{
				"id": "end_turn",
				"message": "[b]End Your Turn[/b]\n\nPlace more units if you want, then click [color=#4a9eff]End Turn[/color] to start combat!\n\nThe enemy will also place units, then battle begins.",
				"highlight": "end_turn",
				"wait_for": "turn_ended"
			},
			{
				"id": "complete",
				"message": "[b]Great Job![/b]\n\nYou've got the basics! Tips:\n\n- [color=#ff6b6b]Elements[/color] have advantages (Fire > Nature > Water > Fire)\n- Units have [color=#ffd700]Abilities[/color] with cooldowns\n- Try [color=#4a9eff]Auto-Battle[/color] and speed controls\n\nGood luck!",
				"highlight": null,
				"wait_for": "continue"
			}
		]
	}

	# Gacha tutorial - shown on first summon screen visit
	tutorials["gacha_basics"] = {
		"name": "Summoning Units",
		"steps": [
			{
				"id": "summon_intro",
				"message": "[b]Summoning[/b]\n\nThis is where you get new units for your team!\n\nSpend [color=#4a9eff]Gems[/color] to summon random units.",
				"highlight": null,
				"wait_for": "continue"
			},
			{
				"id": "rarity_intro",
				"message": "[b]Unit Rarity[/b]\n\n- [color=#888888]3-Star[/color]: Common units\n- [color=#9b59b6]4-Star[/color]: Rare units\n- [color=#ffd700]5-Star[/color]: Legendary units!\n\nHigher rarity = stronger stats!",
				"highlight": null,
				"wait_for": "continue"
			},
			{
				"id": "pull_buttons",
				"message": "[b]Summon Options[/b]\n\n- [b]Single Pull[/b]: 100 Gems for 1 unit\n- [b]Multi Pull[/b]: 900 Gems for 10 units (1 free!)\n\nTry summoning a unit!",
				"highlight": "summon_buttons",
				"wait_for": "continue"
			}
		]
	}


func _create_overlay():
	"""Create the tutorial overlay UI."""
	# Canvas layer to render above everything
	overlay = CanvasLayer.new()
	overlay.name = "TutorialOverlay"
	overlay.layer = 100
	overlay.visible = false
	add_child(overlay)

	# Dim background
	dim_background = ColorRect.new()
	dim_background.name = "DimBackground"
	dim_background.color = Color(0, 0, 0, 0.7)
	dim_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_background.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim_background)

	# Highlight cutout (we'll use a shader or multiple rects later)
	highlight_rect = Control.new()
	highlight_rect.name = "HighlightRect"
	highlight_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(highlight_rect)

	# Message panel
	message_panel = Panel.new()
	message_panel.name = "MessagePanel"
	message_panel.custom_minimum_size = Vector2(550, 280)
	overlay.add_child(message_panel)

	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	panel_style.border_color = Color(0.3, 0.5, 0.8)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	message_panel.add_theme_stylebox_override("panel", panel_style)

	# VBox for panel content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_child(vbox)
	message_panel.add_child(margin)

	# Message label
	message_label = RichTextLabel.new()
	message_label.name = "MessageLabel"
	message_label.bbcode_enabled = true
	message_label.fit_content = true
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_label.add_theme_font_size_override("normal_font_size", 18)
	message_label.add_theme_font_size_override("bold_font_size", 20)
	message_label.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(message_label)

	# Button container
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_END
	button_container.add_theme_constant_override("separation", 10)
	vbox.add_child(button_container)

	# Skip button
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "Skip Tutorial"
	skip_button.custom_minimum_size = Vector2(120, 40)
	skip_button.pressed.connect(_on_skip_pressed)
	_style_button(skip_button, Color(0.3, 0.3, 0.35))
	button_container.add_child(skip_button)

	# Continue button
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(120, 40)
	continue_button.pressed.connect(_on_continue_pressed)
	_style_button(continue_button, Color(0.2, 0.4, 0.7))
	button_container.add_child(continue_button)

	# Position panel at bottom center
	_position_message_panel()


func _style_button(btn: Button, bg_color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = bg_color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.WHITE)


func _position_message_panel():
	"""Position the message panel at center of screen."""
	if not message_panel:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	message_panel.position = Vector2(
		(viewport_size.x - message_panel.custom_minimum_size.x) / 2,
		(viewport_size.y - message_panel.custom_minimum_size.y) / 2 - 50  # Centered, slightly above middle
	)


# === PUBLIC API ===

func start_tutorial(tutorial_id: String, force: bool = false) -> bool:
	"""Start a tutorial sequence."""
	if not tutorials.has(tutorial_id):
		push_warning("TutorialManager: Unknown tutorial: " + tutorial_id)
		return false

	# Skip if already completed (unless forced)
	if not force and tutorial_id in completed_tutorials:
		print("Tutorial already completed: " + tutorial_id)
		return false

	if is_tutorial_active:
		push_warning("TutorialManager: Tutorial already in progress")
		return false

	current_tutorial = tutorial_id
	current_step = 0
	is_tutorial_active = true

	_show_current_step()
	return true


func should_show_tutorial(tutorial_id: String) -> bool:
	"""Check if a tutorial should be shown (not yet completed)."""
	return tutorial_id not in completed_tutorials


func complete_step(expected_action: String = ""):
	"""Complete the current step and advance to next."""
	if not is_tutorial_active:
		return

	var tutorial = tutorials[current_tutorial]
	var step = tutorial.steps[current_step]

	# Check if this is the expected action
	if step.wait_for != "continue" and step.wait_for != expected_action:
		return

	tutorial_step_completed.emit(step.id)

	# Advance to next step
	current_step += 1

	if current_step >= tutorial.steps.size():
		_finish_tutorial()
	else:
		_show_current_step()


func skip_tutorial():
	"""Skip the current tutorial."""
	if not is_tutorial_active:
		return

	tutorial_skipped.emit(current_tutorial)
	_finish_tutorial()


func reset_tutorials():
	"""Reset all tutorial progress (for testing or settings)."""
	completed_tutorials.clear()
	_save_progress()


func is_active() -> bool:
	return is_tutorial_active


# === INTERNAL METHODS ===

func _show_current_step():
	"""Display the current tutorial step."""
	if not is_tutorial_active or current_tutorial.is_empty():
		return

	var tutorial = tutorials[current_tutorial]
	var step = tutorial.steps[current_step]

	# Update message
	message_label.text = step.message

	# Show/hide continue button based on wait_for
	var waits_for_action = (step.wait_for != "continue")
	continue_button.visible = not waits_for_action

	# Update button text for last step
	if current_step == tutorial.steps.size() - 1:
		continue_button.text = "Finish"
	else:
		continue_button.text = "Continue"

	# Position panel
	_position_message_panel()

	# Show overlay
	overlay.visible = true

	# Allow mouse input through when waiting for player actions
	if waits_for_action:
		# Let clicks pass through to the game
		dim_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim_background.color.a = 0.3  # Lighter dim so player can see the game
	else:
		# Block input when waiting for continue button
		dim_background.mouse_filter = Control.MOUSE_FILTER_STOP
		if step.highlight:
			dim_background.color.a = 0.5  # Lighter dim when highlighting
		else:
			dim_background.color.a = 0.7  # Darker when no highlight

	tutorial_step_shown.emit(step.id)


func _finish_tutorial():
	"""Complete and hide the tutorial."""
	if current_tutorial not in completed_tutorials:
		completed_tutorials.append(current_tutorial)
		_save_progress()

	tutorial_completed.emit(current_tutorial)

	# Reset state
	is_tutorial_active = false
	overlay.visible = false
	current_tutorial = ""
	current_step = 0


func _on_continue_pressed():
	AudioManager.play_ui_click()
	complete_step("continue")


func _on_skip_pressed():
	AudioManager.play_ui_click()
	skip_tutorial()


# === PERSISTENCE ===

func _save_progress():
	"""Save tutorial progress to file."""
	var data = {
		"completed_tutorials": completed_tutorials
	}

	var file = FileAccess.open(TUTORIAL_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func _load_progress():
	"""Load tutorial progress from file."""
	if not FileAccess.file_exists(TUTORIAL_SAVE_PATH):
		return

	var file = FileAccess.open(TUTORIAL_SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return

	var data = json.get_data()
	var loaded = data.get("completed_tutorials", [])
	completed_tutorials.clear()
	for t in loaded:
		completed_tutorials.append(t)
