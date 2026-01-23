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
@onready var delete_save_button = $CenterContainer/VBoxContainer/DataSection/DeleteSaveButton
@onready var credits_button = $CenterContainer/VBoxContainer/CreditsSection/CreditsButton

# Confirmation dialog
var delete_confirm_dialog: ConfirmationDialog = null


func _ready():
	_apply_theme()
	_setup_sliders()
	_connect_signals()


func _apply_theme():
	# Background - use castle theme with pale variant for settings/official feel
	UISpriteLoader.apply_background_to_scene(self, UISpriteLoader.BackgroundTheme.CASTLE, UISpriteLoader.BackgroundVariant.PALE, 0.5)
	# Hide the old solid color background if it exists
	if has_node("Background"):
		$Background.visible = false

	# Title
	if has_node("CenterContainer/VBoxContainer/TitleLabel"):
		var title = $CenterContainer/VBoxContainer/TitleLabel
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Settings panel with sprite styling
	if has_node("CenterContainer/VBoxContainer/SettingsPanel"):
		var panel = $CenterContainer/VBoxContainer/SettingsPanel
		UISpriteLoader.apply_panel_style(panel, UISpriteLoader.PanelColor.BLUE, "Panel")

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

	# Reset tutorial button with sprite styling
	if reset_tutorial_button:
		UISpriteLoader.apply_button_style(reset_tutorial_button, UISpriteLoader.ButtonColor.PURPLE, "ButtonA")
		reset_tutorial_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Data section label
	var data_label = get_node_or_null("CenterContainer/VBoxContainer/DataSection/DataLabel")
	if data_label:
		data_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		data_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Delete save button - danger styling (red)
	if delete_save_button:
		UISpriteLoader.apply_button_style(delete_save_button, UISpriteLoader.ButtonColor.RED, "ButtonA")
		delete_save_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Credits section label
	var credits_label = get_node_or_null("CenterContainer/VBoxContainer/CreditsSection/CreditsLabel")
	if credits_label:
		credits_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		credits_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Credits button
	if credits_button:
		UISpriteLoader.apply_button_style(credits_button, UISpriteLoader.ButtonColor.GOLD, "ButtonA")
		credits_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Back button
	if back_button:
		UISpriteLoader.apply_button_style(back_button, UISpriteLoader.ButtonColor.BLUE, "ButtonA")
		back_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)


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

	if delete_save_button:
		delete_save_button.pressed.connect(_on_delete_save_pressed)

	if credits_button:
		credits_button.pressed.connect(_on_credits_pressed)

	_create_delete_confirm_dialog()


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


func _create_delete_confirm_dialog():
	delete_confirm_dialog = ConfirmationDialog.new()
	delete_confirm_dialog.title = "Delete Save Data?"
	delete_confirm_dialog.dialog_text = "Are you sure you want to delete ALL save data?\n\nThis will reset:\n- All owned units\n- Currency (gems, gold, materials)\n- Campaign progress\n- Gear and equipment\n\nThis cannot be undone!"
	delete_confirm_dialog.ok_button_text = "Delete Everything"
	delete_confirm_dialog.cancel_button_text = "Cancel"
	delete_confirm_dialog.confirmed.connect(_on_delete_save_confirmed)
	add_child(delete_confirm_dialog)


func _on_delete_save_pressed():
	AudioManager.play_ui_click()
	if delete_confirm_dialog:
		delete_confirm_dialog.popup_centered()


func _on_delete_save_confirmed():
	AudioManager.play_ui_click()
	# Delete the save file
	var save_path = "user://save_data.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	# Also reset tutorial data
	TutorialManager.reset_tutorials()

	# Show feedback and restart game
	if delete_save_button:
		delete_save_button.text = "Restarting..."
		delete_save_button.disabled = true

	await get_tree().create_timer(1.0).timeout

	# Restart the game to apply fresh state
	get_tree().quit()


func _on_credits_pressed():
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/credits_screen.tscn")


func _on_back_pressed():
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")
