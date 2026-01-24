extends CanvasLayer
## Global cheat manager accessible from any screen
## Activate with F12 or hold F1 for 2 seconds

var cheat_panel: Panel = null
var f1_hold_time: float = 0.0
const F1_HOLD_THRESHOLD: float = 2.0


func _ready():
	layer = 100  # Always on top
	_create_cheat_panel()
	cheat_panel.visible = false


func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		toggle_panel()


func _process(delta):
	if Input.is_key_pressed(KEY_F1):
		f1_hold_time += delta
		if f1_hold_time >= F1_HOLD_THRESHOLD:
			toggle_panel()
			f1_hold_time = 0.0
	else:
		f1_hold_time = 0.0


func toggle_panel():
	cheat_panel.visible = not cheat_panel.visible


func _create_cheat_panel():
	# Create main panel
	cheat_panel = Panel.new()
	cheat_panel.name = "CheatPanel"
	cheat_panel.custom_minimum_size = Vector2(300, 400)
	cheat_panel.set_anchors_preset(Control.PRESET_CENTER)
	cheat_panel.size = Vector2(300, 400)
	cheat_panel.position = Vector2(-150, -200)  # Center offset

	# Apply panel style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = UITheme.BG_DARK
	panel_style.border_color = UITheme.PRIMARY
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = UITheme.MODAL_RADIUS
	panel_style.corner_radius_top_right = UITheme.MODAL_RADIUS
	panel_style.corner_radius_bottom_left = UITheme.MODAL_RADIUS
	panel_style.corner_radius_bottom_right = UITheme.MODAL_RADIUS
	cheat_panel.add_theme_stylebox_override("panel", panel_style)

	# Create VBox container for layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", UITheme.SPACING_SM)
	vbox.offset_left = UITheme.SPACING_MD
	vbox.offset_right = -UITheme.SPACING_MD
	vbox.offset_top = UITheme.SPACING_MD
	vbox.offset_bottom = -UITheme.SPACING_MD
	cheat_panel.add_child(vbox)

	# Title label
	var title = Label.new()
	title.text = "CHEAT MENU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
	title.add_theme_color_override("font_color", UITheme.GOLD)
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "(F12 or hold F1 to toggle)"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	subtitle.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	vbox.add_child(subtitle)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = UITheme.SPACING_SM
	vbox.add_child(spacer)

	# Create cheat buttons
	_create_cheat_button(vbox, "+10,000 Gems", _on_add_gems)
	_create_cheat_button(vbox, "+10,000 Gold", _on_add_gold)
	_create_cheat_button(vbox, "+100 Materials", _on_add_materials)
	_create_cheat_button(vbox, "+100 Stones", _on_add_stones)
	_create_cheat_button(vbox, "Max All Units", _on_max_all_units)
	_create_cheat_button(vbox, "Add 5-Star Unit", _on_add_5_star)
	_create_cheat_button(vbox, "Clear All Stages", _on_clear_all_stages)

	# Spacer before close
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	# Close button
	_create_cheat_button(vbox, "Close", _on_close, UITheme.DANGER)

	add_child(cheat_panel)


func _create_cheat_button(parent: Control, text: String, callback: Callable, color: Color = UITheme.PRIMARY):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 36

	# Normal style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color.darkened(0.3)
	normal_style.corner_radius_top_left = UITheme.BUTTON_RADIUS
	normal_style.corner_radius_top_right = UITheme.BUTTON_RADIUS
	normal_style.corner_radius_bottom_left = UITheme.BUTTON_RADIUS
	normal_style.corner_radius_bottom_right = UITheme.BUTTON_RADIUS
	button.add_theme_stylebox_override("normal", normal_style)

	# Hover style
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color
	button.add_theme_stylebox_override("hover", hover_style)

	# Pressed style
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.5)
	button.add_theme_stylebox_override("pressed", pressed_style)

	button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	button.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	button.pressed.connect(callback)
	parent.add_child(button)


# === Cheat Functions ===

func _on_add_gems():
	PlayerData.gems += 10000
	PlayerData.save_game()
	print("[CHEAT] Added 10,000 gems. Total: ", PlayerData.gems)


func _on_add_gold():
	PlayerData.gold += 10000
	PlayerData.save_game()
	print("[CHEAT] Added 10,000 gold. Total: ", PlayerData.gold)


func _on_add_materials():
	PlayerData.level_materials += 100
	PlayerData.save_game()
	print("[CHEAT] Added 100 materials. Total: ", PlayerData.level_materials)


func _on_add_stones():
	PlayerData.enhancement_stones += 100
	PlayerData.save_game()
	print("[CHEAT] Added 100 enhancement stones. Total: ", PlayerData.enhancement_stones)


func _on_max_all_units():
	for i in range(PlayerData.owned_units.size()):
		var unit_entry = PlayerData.owned_units[i]
		var unit_data = unit_entry.unit_data as UnitData
		var max_level = PlayerData.get_max_level(unit_data.star_rating)
		PlayerData.owned_units[i].level = max_level
		PlayerData.owned_units[i].imprint_level = 5
	PlayerData.save_game()
	print("[CHEAT] Maxed all ", PlayerData.owned_units.size(), " units to max level and imprint")


func _on_add_5_star():
	# Get a random 5-star unit from the pool
	if PlayerData.unit_pool_5_star.size() > 0:
		var random_unit = PlayerData.unit_pool_5_star[randi() % PlayerData.unit_pool_5_star.size()]
		PlayerData._add_unit_to_collection(random_unit)
		PlayerData.save_game()
		print("[CHEAT] Added 5-star unit: ", random_unit.unit_name)
	else:
		print("[CHEAT] No 5-star units available in pool")


func _on_clear_all_stages():
	# Clear all stages from 1-1 to 3-5 (assuming 3 chapters with 5 stages each)
	for chapter in range(1, 4):
		for stage in range(1, 6):
			var stage_id = str(chapter) + "-" + str(stage)
			PlayerData.campaign_progress[stage_id] = {"cleared": true, "stars": 3}
	PlayerData.save_game()
	print("[CHEAT] Cleared all campaign stages (1-1 through 3-5)")


func _on_close():
	cheat_panel.visible = false
