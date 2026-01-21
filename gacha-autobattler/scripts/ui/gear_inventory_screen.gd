extends Control
## Gear inventory management screen

@onready var back_btn = $TopBar/BackButton
@onready var currency_label = $TopBar/CurrencyLabel
@onready var gear_grid = $ScrollContainer/GearGrid
@onready var detail_panel = $DetailPanel
@onready var gear_name_label = $DetailPanel/VBox/GearNameLabel
@onready var gear_type_label = $DetailPanel/VBox/GearTypeLabel
@onready var gear_stat_label = $DetailPanel/VBox/GearStatLabel
@onready var gear_level_label = $DetailPanel/VBox/GearLevelLabel
@onready var enhance_cost_label = $DetailPanel/VBox/EnhanceCostLabel
@onready var equipped_label = $DetailPanel/VBox/EquippedLabel
@onready var enhance_btn = $DetailPanel/VBox/ButtonContainer/EnhanceButton
@onready var close_btn = $DetailPanel/VBox/ButtonContainer/CloseButton

# Filter controls
@onready var filter_all_btn = $FilterBar/AllButton
@onready var filter_weapon_btn = $FilterBar/WeaponButton
@onready var filter_armor_btn = $FilterBar/ArmorButton
@onready var filter_accessory_btn = $FilterBar/AccessoryButton

var selected_gear_instance_id: String = ""
var current_filter: int = -1  # -1 = all, 0 = weapon, 1 = armor, 2 = accessory

func _ready():
	back_btn.pressed.connect(_on_back)
	enhance_btn.pressed.connect(_on_enhance)
	close_btn.pressed.connect(_on_close_detail)

	filter_all_btn.pressed.connect(_set_filter.bind(-1))
	filter_weapon_btn.pressed.connect(_set_filter.bind(0))
	filter_armor_btn.pressed.connect(_set_filter.bind(1))
	filter_accessory_btn.pressed.connect(_set_filter.bind(2))

	detail_panel.visible = false

	_update_currency_display()
	_build_gear_grid()

func _set_filter(filter_type: int):
	current_filter = filter_type
	_build_gear_grid()

	# Update button states
	filter_all_btn.disabled = (filter_type == -1)
	filter_weapon_btn.disabled = (filter_type == 0)
	filter_armor_btn.disabled = (filter_type == 1)
	filter_accessory_btn.disabled = (filter_type == 2)

func _build_gear_grid():
	# Clear existing
	for child in gear_grid.get_children():
		child.queue_free()

	await get_tree().process_frame

	# Get all gear
	var all_gear = PlayerData.owned_gear

	# Filter if needed
	var filtered_gear = []
	for gear_entry in all_gear:
		if current_filter == -1:
			filtered_gear.append(gear_entry)
		else:
			var gear_data = gear_entry.gear_data as GearData
			if gear_data and gear_data.gear_type == current_filter:
				filtered_gear.append(gear_entry)

	# Sort by rarity (highest first), then level
	filtered_gear.sort_custom(func(a, b):
		var gear_a = a.gear_data as GearData
		var gear_b = b.gear_data as GearData
		if gear_a and gear_b:
			if gear_a.rarity != gear_b.rarity:
				return gear_a.rarity > gear_b.rarity
			return a.level > b.level
		return false
	)

	# Build cards
	for gear_entry in filtered_gear:
		var card = _create_gear_card(gear_entry)
		gear_grid.add_child(card)

func _create_gear_card(gear_entry: Dictionary) -> Control:
	var template = gear_entry.gear_data as GearData
	if not template:
		var placeholder = Control.new()
		return placeholder

	var card = Panel.new()
	card.custom_minimum_size = Vector2(150, 180)

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = template.get_rarity_color().darkened(0.5)
	card_style.border_width_left = 3
	card_style.border_width_right = 3
	card_style.border_width_top = 3
	card_style.border_width_bottom = 3
	card_style.border_color = template.get_rarity_color()
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", card_style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(vbox)
	card.add_child(margin)

	# Gear name
	var name_label = Label.new()
	name_label.text = template.gear_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	# Type
	var type_label = Label.new()
	type_label.text = template.get_type_name()
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(type_label)

	# Stat value
	var stat_value = template.get_stat_at_level(gear_entry.level)
	var stat_text = template.get_stat_name() + ": "
	if template.is_percentage:
		stat_text += "+" + str(snapped(stat_value, 0.1)) + "%"
	else:
		stat_text += "+" + str(int(stat_value))
	var stat_label = Label.new()
	stat_label.text = stat_text
	stat_label.add_theme_font_size_override("font_size", 16)
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	vbox.add_child(stat_label)

	# Level
	var level_label = Label.new()
	level_label.text = "+" + str(gear_entry.level) + "/" + str(template.get_max_level())
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_label)

	# Equipped status
	var equipped_unit = PlayerData.get_gear_equipped_unit(gear_entry.instance_id)
	if equipped_unit != "":
		var eq_label = Label.new()
		eq_label.text = "[EQUIPPED]"
		eq_label.add_theme_font_size_override("font_size", 12)
		eq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		eq_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		vbox.add_child(eq_label)

	# Make it clickable
	var btn = Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0)  # Invisible but clickable
	btn.pressed.connect(_on_gear_selected.bind(gear_entry.instance_id))
	card.add_child(btn)

	return card

func _on_gear_selected(instance_id: String):
	selected_gear_instance_id = instance_id
	_update_detail_panel()

func _update_detail_panel():
	if selected_gear_instance_id == "":
		detail_panel.visible = false
		return

	var gear_entry = PlayerData.get_gear_by_instance_id(selected_gear_instance_id)
	if gear_entry.is_empty():
		detail_panel.visible = false
		return

	var template = PlayerData.get_gear_template(gear_entry.gear_id)
	if not template:
		detail_panel.visible = false
		return

	detail_panel.visible = true

	# Update labels
	gear_name_label.text = template.gear_name
	gear_name_label.add_theme_color_override("font_color", template.get_rarity_color())

	gear_type_label.text = template.get_type_name()

	var stat_value = template.get_stat_at_level(gear_entry.level)
	var stat_text = template.get_stat_name() + ": "
	if template.is_percentage:
		stat_text += "+" + str(snapped(stat_value, 0.1)) + "%"
	else:
		stat_text += "+" + str(int(stat_value))
	gear_stat_label.text = stat_text

	gear_level_label.text = "Level: +" + str(gear_entry.level) + "/" + str(template.get_max_level())

	# Enhance cost
	var can_enhance = PlayerData.can_enhance_gear(selected_gear_instance_id)
	if gear_entry.level >= template.get_max_level():
		enhance_cost_label.text = "MAX LEVEL"
		enhance_btn.disabled = true
	else:
		var cost = template.get_enhance_cost(gear_entry.level)
		enhance_cost_label.text = "Cost: " + str(cost.gold) + " Gold, " + str(cost.stones) + " Stones"
		enhance_btn.disabled = not can_enhance

	# Equipped status
	var equipped_unit = PlayerData.get_gear_equipped_unit(gear_entry.instance_id)
	if equipped_unit != "":
		var unit_data = PlayerData.get_owned_unit(equipped_unit)
		if unit_data:
			equipped_label.text = "Equipped: " + unit_data.unit_data.unit_name
		else:
			equipped_label.text = "Equipped: Unknown"
		equipped_label.visible = true
	else:
		equipped_label.visible = false

func _on_enhance():
	if selected_gear_instance_id == "":
		return

	var success = PlayerData.enhance_gear(selected_gear_instance_id)
	if success:
		_update_detail_panel()
		_update_currency_display()
		_build_gear_grid()

func _on_close_detail():
	detail_panel.visible = false
	selected_gear_instance_id = ""

func _update_currency_display():
	currency_label.text = str(PlayerData.gold) + " Gold | " + str(PlayerData.enhancement_stones) + " Stones"

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
