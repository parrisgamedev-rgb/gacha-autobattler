extends Control
## Settings screen with audio controls

# UI References
@onready var master_slider = $CenterContainer/VBoxContainer/SettingsPanel/VBoxContainer/MasterVolume/Slider
@onready var master_value = $CenterContainer/VBoxContainer/SettingsPanel/VBoxContainer/MasterVolume/Value
@onready var music_slider = $CenterContainer/VBoxContainer/SettingsPanel/VBoxContainer/MusicVolume/Slider
@onready var music_value = $CenterContainer/VBoxContainer/SettingsPanel/VBoxContainer/MusicVolume/Value
@onready var sfx_slider = $CenterContainer/VBoxContainer/SettingsPanel/VBoxContainer/SFXVolume/Slider
@onready var sfx_value = $CenterContainer/VBoxContainer/SettingsPanel/VBoxContainer/SFXVolume/Value
@onready var back_button = $CenterContainer/VBoxContainer/BackButton
@onready var reset_tutorial_button = $CenterContainer/VBoxContainer/TutorialSection/ResetTutorialButton


func _ready():
	_apply_theme()
	_setup_sliders()
	_connect_signals()


func _apply_theme():
	# Background
	if has_node("Background"):
		$Background.color = UITheme.BG_DARK

	# Title
	if has_node("CenterContainer/VBoxContainer/TitleLabel"):
		var title = $CenterContainer/VBoxContainer/TitleLabel
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Settings panel
	if has_node("CenterContainer/VBoxContainer/SettingsPanel"):
		var panel = $CenterContainer/VBoxContainer/SettingsPanel
		var style = StyleBoxFlat.new()
		style.bg_color = UITheme.BG_MEDIUM
		style.corner_radius_top_left = UITheme.CARD_RADIUS
		style.corner_radius_top_right = UITheme.CARD_RADIUS
		style.corner_radius_bottom_left = UITheme.CARD_RADIUS
		style.corner_radius_bottom_right = UITheme.CARD_RADIUS
		style.content_margin_left = UITheme.SPACING_LG
		style.content_margin_right = UITheme.SPACING_LG
		style.content_margin_top = UITheme.SPACING_LG
		style.content_margin_bottom = UITheme.SPACING_LG
		panel.add_theme_stylebox_override("panel", style)

	# Section labels
	for label_name in ["AudioLabel"]:
		var path = "CenterContainer/VBoxContainer/SettingsPanel/VBoxContainer/" + label_name
		if has_node(path):
			var label = get_node(path)
			label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
			label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Volume labels
	for volume_name in ["MasterVolume", "MusicVolume", "SFXVolume"]:
		var path = "CenterContainer/VBoxContainer/SettingsPanel/VBoxContainer/" + volume_name + "/Label"
		if has_node(path):
			var label = get_node(path)
			label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
			label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Value labels
	for volume_name in ["MasterVolume", "MusicVolume", "SFXVolume"]:
		var path = "CenterContainer/VBoxContainer/SettingsPanel/VBoxContainer/" + volume_name + "/Value"
		if has_node(path):
			var label = get_node(path)
			label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
			label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Tutorial section label
	var tutorial_label = get_node_or_null("CenterContainer/VBoxContainer/TutorialSection/TutorialLabel")
	if tutorial_label:
		tutorial_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		tutorial_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Reset tutorial button
	if reset_tutorial_button:
		reset_tutorial_button.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_LIGHT))
		reset_tutorial_button.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT.lightened(0.1)))
		reset_tutorial_button.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.BG_MEDIUM))
		reset_tutorial_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		reset_tutorial_button.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Back button
	if back_button:
		back_button.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_MEDIUM, UITheme.BG_LIGHT))
		back_button.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT))
		back_button.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.BG_MEDIUM.darkened(0.1)))
		back_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		back_button.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)


func _setup_sliders():
	# Load current values from AudioManager
	if master_slider:
		master_slider.min_value = 0
		master_slider.max_value = 100
		master_slider.step = 1
		master_slider.value = AudioManager.get_master_volume() * 100
		_update_value_label(master_value, master_slider.value)

	if music_slider:
		music_slider.min_value = 0
		music_slider.max_value = 100
		music_slider.step = 1
		music_slider.value = AudioManager.get_music_volume() * 100
		_update_value_label(music_value, music_slider.value)

	if sfx_slider:
		sfx_slider.min_value = 0
		sfx_slider.max_value = 100
		sfx_slider.step = 1
		sfx_slider.value = AudioManager.get_sfx_volume() * 100
		_update_value_label(sfx_value, sfx_slider.value)


func _connect_signals():
	if master_slider:
		master_slider.value_changed.connect(_on_master_changed)

	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)

	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
		sfx_slider.drag_ended.connect(_on_sfx_drag_ended)

	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	if reset_tutorial_button:
		reset_tutorial_button.pressed.connect(_on_reset_tutorial_pressed)


func _update_value_label(label: Label, value: float):
	if label:
		label.text = str(int(value)) + "%"


func _on_master_changed(value: float):
	AudioManager.set_master_volume(value / 100.0)
	_update_value_label(master_value, value)


func _on_music_changed(value: float):
	AudioManager.set_music_volume(value / 100.0)
	_update_value_label(music_value, value)


func _on_sfx_changed(value: float):
	AudioManager.set_sfx_volume(value / 100.0)
	_update_value_label(sfx_value, value)


func _on_sfx_drag_ended(_value_changed: bool):
	# Play a test sound when user finishes adjusting SFX slider
	AudioManager.play_ui_click()


func _on_reset_tutorial_pressed():
	AudioManager.play_ui_click()
	TutorialManager.reset_tutorials()
	# Update button to show feedback
	if reset_tutorial_button:
		reset_tutorial_button.text = "Tutorials Reset!"
		reset_tutorial_button.disabled = true
		await get_tree().create_timer(1.5).timeout
		reset_tutorial_button.text = "Reset Tutorials"
		reset_tutorial_button.disabled = false


func _on_back_pressed():
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")
