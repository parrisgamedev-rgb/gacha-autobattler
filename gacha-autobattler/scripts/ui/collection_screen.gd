extends Control
## Collection screen for viewing owned units

@onready var back_btn = $TopBar/BackButton
@onready var units_container = $ScrollContainer/UnitsGrid
@onready var unit_count_label = $TopBar/UnitCountLabel
@onready var detail_panel = $DetailPanel
@onready var detail_name = $DetailPanel/DetailName
@onready var detail_stars = $DetailPanel/DetailStars
@onready var detail_element = $DetailPanel/DetailElement
@onready var detail_stats = $DetailPanel/DetailStats
@onready var detail_copies = $DetailPanel/DetailCopies
@onready var detail_imprint = $DetailPanel/DetailImprint
@onready var close_detail_btn = $DetailPanel/CloseButton
@onready var imprint_btn = $DetailPanel/ImprintButton
@onready var level_up_btn = $DetailPanel/LevelUpButton
@onready var max_level_btn = $DetailPanel/CheatButtons/MaxLevelButton
@onready var reset_level_btn = $DetailPanel/CheatButtons/ResetLevelButton
@onready var detail_level = $DetailPanel/DetailLevel
@onready var level_cost_label = $DetailPanel/LevelCostLabel
@onready var currency_label = $TopBar/CurrencyLabel
@onready var imprint_panel = $ImprintPanel
@onready var fodder_grid = $ImprintPanel/FodderScroll/FodderGrid
@onready var cancel_imprint_btn = $ImprintPanel/CancelImprintButton
@onready var confirm_panel = $ConfirmPanel
@onready var confirm_message = $ConfirmPanel/ConfirmMessage
@onready var confirm_btn = $ConfirmPanel/ButtonContainer/ConfirmButton
@onready var cancel_confirm_btn = $ConfirmPanel/ButtonContainer/CancelConfirmButton
@onready var gear_slots_container = $DetailPanel/GearSlotsContainer
@onready var gear_select_panel = $GearSelectPanel
@onready var gear_select_grid = $GearSelectPanel/ScrollContainer/GearGrid
@onready var cancel_gear_btn = $GearSelectPanel/CancelButton

var UnitDisplayScene = preload("res://scenes/battle/unit_display.tscn")

# Currently selected unit for viewing/imprinting
var current_unit_entry: Dictionary = {}
var pending_fodder_id: String = ""
var current_gear_slot: int = -1  # 0=weapon, 1=armor, 2=acc1, 3=acc2

func _ready():
	back_btn.pressed.connect(_on_back)
	close_detail_btn.pressed.connect(_on_close_detail)
	imprint_btn.pressed.connect(_on_imprint_pressed)
	if level_up_btn:
		level_up_btn.pressed.connect(_on_level_up_pressed)
	if max_level_btn:
		max_level_btn.pressed.connect(_on_max_level_pressed)
	if reset_level_btn:
		reset_level_btn.pressed.connect(_on_reset_level_pressed)
	cancel_imprint_btn.pressed.connect(_on_cancel_imprint)
	confirm_btn.pressed.connect(_on_confirm_imprint)
	cancel_confirm_btn.pressed.connect(_on_cancel_confirm)
	if cancel_gear_btn:
		cancel_gear_btn.pressed.connect(_on_cancel_gear_select)
	detail_panel.visible = false
	imprint_panel.visible = false
	confirm_panel.visible = false
	if gear_select_panel:
		gear_select_panel.visible = false
	_update_currency_display()
	_populate_collection()

func _populate_collection():
	# Clear existing
	for child in units_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	var owned = PlayerData.get_owned_unit_list()
	unit_count_label.text = "Units: " + str(owned.size())

	if owned.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No units yet!\nVisit the Summon screen to get units."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(400, 100)
		units_container.add_child(empty_label)
		return

	# Create a card for each owned unit
	for unit_entry in owned:
		var card = _create_unit_card(unit_entry)
		units_container.add_child(card)

func _create_unit_card(unit_entry: Dictionary) -> Control:
	var unit_data = unit_entry.unit_data as UnitData
	var imprint_level = unit_entry.get("imprint_level", 0) as int
	var unit_level = unit_entry.get("level", 1) as int
	var instance_id = unit_entry.instance_id as String

	var card = Panel.new()
	card.custom_minimum_size = Vector2(180, 220)

	# Background color based on rarity
	var style = StyleBoxFlat.new()
	match unit_data.star_rating:
		5:
			style.bg_color = Color(0.3, 0.25, 0.1, 1)  # Gold
		4:
			style.bg_color = Color(0.25, 0.15, 0.3, 1)  # Purple
		_:
			style.bg_color = Color(0.15, 0.15, 0.2, 1)  # Default
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)

	# Unit display
	var display_container = Control.new()
	display_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	display_container.custom_minimum_size = Vector2(180, 120)
	card.add_child(display_container)

	var display = UnitDisplayScene.instantiate()
	display_container.add_child(display)
	display.position = Vector2(90, 60)
	display.scale = Vector2(0.5, 0.5)
	display.drag_enabled = false

	# Defer setup until the node is ready
	var instance = UnitInstance.new(unit_data, 1, unit_level, imprint_level)
	display.call_deferred("setup", instance)

	# Level label (top left)
	var level_label = Label.new()
	level_label.text = "Lv." + str(unit_level)
	level_label.position = Vector2(8, 5)
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	card.add_child(level_label)

	# Imprint level (top right if > 0)
	if imprint_level > 0:
		var imprint_label = Label.new()
		imprint_label.text = "+" + str(imprint_level)
		imprint_label.position = Vector2(145, 5)
		imprint_label.add_theme_font_size_override("font_size", 16)
		imprint_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		card.add_child(imprint_label)

	# Name label
	var name_label = Label.new()
	name_label.text = unit_data.unit_name
	name_label.position = Vector2(0, 130)
	name_label.size = Vector2(180, 25)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	card.add_child(name_label)

	# Stars label
	var stars_label = Label.new()
	stars_label.text = "★".repeat(unit_data.star_rating)
	stars_label.position = Vector2(0, 155)
	stars_label.size = Vector2(180, 20)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	stars_label.add_theme_font_size_override("font_size", 14)
	card.add_child(stars_label)

	# XP bar
	var max_level = PlayerData.get_max_level(unit_data.star_rating)
	if unit_level < max_level:
		var xp = unit_entry.get("xp", 0)
		var xp_needed = PlayerData.get_xp_for_level(unit_level)
		var xp_ratio = float(xp) / float(xp_needed) if xp_needed > 0 else 0.0

		var xp_bg = ColorRect.new()
		xp_bg.position = Vector2(10, 180)
		xp_bg.size = Vector2(160, 8)
		xp_bg.color = Color(0.2, 0.2, 0.25, 1)
		card.add_child(xp_bg)

		var xp_fill = ColorRect.new()
		xp_fill.position = Vector2(10, 180)
		xp_fill.size = Vector2(160 * xp_ratio, 8)
		xp_fill.color = Color(0.3, 0.7, 1.0, 1)
		card.add_child(xp_fill)

		var xp_label = Label.new()
		xp_label.text = str(xp) + "/" + str(xp_needed)
		xp_label.position = Vector2(0, 190)
		xp_label.size = Vector2(180, 20)
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		xp_label.add_theme_font_size_override("font_size", 10)
		xp_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		card.add_child(xp_label)
	else:
		var max_label = Label.new()
		max_label.text = "MAX LEVEL"
		max_label.position = Vector2(0, 180)
		max_label.size = Vector2(180, 25)
		max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		max_label.add_theme_font_size_override("font_size", 12)
		max_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		card.add_child(max_label)

	# Make clickable
	var button = Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_unit_clicked.bind(unit_entry))
	card.add_child(button)

	return card

func _on_unit_clicked(unit_entry: Dictionary):
	current_unit_entry = unit_entry
	var unit_data = unit_entry.unit_data as UnitData
	var imprint_level = unit_entry.get("imprint_level", 0) as int
	var unit_level = unit_entry.get("level", 1) as int
	var max_level = PlayerData.get_max_level(unit_data.star_rating)

	detail_panel.visible = true
	detail_name.text = unit_data.unit_name
	detail_stars.text = "★".repeat(unit_data.star_rating)
	detail_element.text = "Element: " + unit_data.element.capitalize()

	# Show scaled stats based on level
	var stats = PlayerData.get_unit_stats_at_level(unit_data, unit_level, imprint_level)
	detail_stats.text = "HP: " + str(stats.max_hp) + "  ATK: " + str(stats.attack) + "  DEF: " + str(stats.defense) + "  SPD: " + str(stats.speed)
	detail_copies.text = "Instance ID: " + unit_entry.instance_id
	detail_imprint.text = "Imprint Level: " + str(imprint_level) + "/5"

	# Show level info
	if detail_level:
		detail_level.text = "Level: " + str(unit_level) + "/" + str(max_level)

	# Color element label
	var element_color = unit_data.get_element_color()
	detail_element.add_theme_color_override("font_color", element_color)

	# Update imprint button state
	var can_imprint = imprint_level < 5 and _has_fodder_available(unit_entry)
	imprint_btn.disabled = not can_imprint
	if imprint_level >= 5:
		imprint_btn.text = "MAX IMPRINT"
	elif not can_imprint:
		imprint_btn.text = "NO DUPLICATES"
	else:
		imprint_btn.text = "IMPRINT"

	# Update level up button state
	if level_up_btn and level_cost_label:
		var instance_id = unit_entry.instance_id as String
		var check = PlayerData.can_level_up(instance_id, 1)

		if unit_level >= max_level:
			level_up_btn.text = "MAX LEVEL"
			level_up_btn.disabled = true
			level_cost_label.text = ""
		elif check.can_level:
			level_up_btn.text = "LEVEL UP"
			level_up_btn.disabled = false
			level_cost_label.text = "Cost: " + str(check.cost.gold) + " Gold, " + str(check.cost.materials) + " Materials"
			level_cost_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		else:
			level_up_btn.text = "LEVEL UP"
			level_up_btn.disabled = true
			if check.has("cost"):
				level_cost_label.text = "Need: " + str(check.cost.gold) + " Gold, " + str(check.cost.materials) + " Materials"
				level_cost_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))

	# Update gear slots display
	_update_gear_slots()

func _on_close_detail():
	detail_panel.visible = false
	current_unit_entry = {}

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _has_fodder_available(unit_entry: Dictionary) -> bool:
	var unit_data = unit_entry.unit_data as UnitData
	var instance_id = unit_entry.instance_id as String

	for other in PlayerData.get_owned_unit_list():
		if other.instance_id != instance_id and other.unit_data.unit_id == unit_data.unit_id:
			return true
	return false

func _on_imprint_pressed():
	if current_unit_entry.is_empty():
		return

	# Show fodder selection panel
	_populate_fodder_grid()
	imprint_panel.visible = true
	detail_panel.visible = false

func _on_cancel_imprint():
	imprint_panel.visible = false
	detail_panel.visible = true

func _populate_fodder_grid():
	# Clear existing
	for child in fodder_grid.get_children():
		child.queue_free()

	await get_tree().process_frame

	var target_unit_data = current_unit_entry.unit_data as UnitData
	var target_instance_id = current_unit_entry.instance_id as String

	# Find all units of the same type (excluding the target)
	for unit_entry in PlayerData.get_owned_unit_list():
		if unit_entry.instance_id != target_instance_id and unit_entry.unit_data.unit_id == target_unit_data.unit_id:
			var card = _create_fodder_card(unit_entry)
			fodder_grid.add_child(card)

func _create_fodder_card(unit_entry: Dictionary) -> Control:
	var unit_data = unit_entry.unit_data as UnitData
	var imprint_level = unit_entry.imprint_level as int
	var instance_id = unit_entry.instance_id as String

	var card = Panel.new()
	card.custom_minimum_size = Vector2(120, 150)

	# Background style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.25, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", style)

	# Unit display
	var display_container = Control.new()
	display_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	display_container.custom_minimum_size = Vector2(120, 90)
	card.add_child(display_container)

	var display = UnitDisplayScene.instantiate()
	display_container.add_child(display)
	display.position = Vector2(60, 50)
	display.scale = Vector2(0.4, 0.4)
	display.drag_enabled = false

	var instance = UnitInstance.new(unit_data, 1)
	display.call_deferred("setup", instance)

	# Name label
	var name_label = Label.new()
	name_label.text = unit_data.unit_name
	name_label.position = Vector2(0, 95)
	name_label.size = Vector2(120, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	card.add_child(name_label)

	# Imprint level label
	if imprint_level > 0:
		var imprint_label = Label.new()
		imprint_label.text = "+" + str(imprint_level)
		imprint_label.position = Vector2(5, 5)
		imprint_label.add_theme_font_size_override("font_size", 14)
		imprint_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		card.add_child(imprint_label)

	# Instance ID label
	var id_label = Label.new()
	id_label.text = "#" + instance_id
	id_label.position = Vector2(0, 115)
	id_label.size = Vector2(120, 20)
	id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	id_label.add_theme_font_size_override("font_size", 10)
	id_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	card.add_child(id_label)

	# Make clickable
	var button = Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_fodder_selected.bind(instance_id))
	card.add_child(button)

	return card

func _on_fodder_selected(fodder_instance_id: String):
	# Store the fodder ID and show confirmation dialog
	pending_fodder_id = fodder_instance_id

	var target_data = current_unit_entry.unit_data as UnitData
	var fodder_entry = PlayerData.get_unit_by_instance_id(fodder_instance_id)
	var fodder_imprint = fodder_entry.imprint_level as int

	var fodder_info = target_data.unit_name + " #" + fodder_instance_id
	if fodder_imprint > 0:
		fodder_info += " (+" + str(fodder_imprint) + ")"

	var target_info = target_data.unit_name + " #" + current_unit_entry.instance_id
	var target_imprint = current_unit_entry.imprint_level as int
	var new_imprint = target_imprint + 1

	confirm_message.text = "Sacrifice " + fodder_info + "\nto imprint " + target_info + "?\n(Will become +" + str(new_imprint) + ")"

	imprint_panel.visible = false
	confirm_panel.visible = true

func _on_confirm_imprint():
	var target_instance_id = current_unit_entry.instance_id as String

	# Perform the imprint
	var success = PlayerData.imprint_unit(target_instance_id, pending_fodder_id)

	if success:
		print("Imprint successful!")
		# Refresh the collection
		confirm_panel.visible = false
		pending_fodder_id = ""
		_populate_collection()

		# Update current unit entry from PlayerData (it was modified)
		current_unit_entry = PlayerData.get_unit_by_instance_id(target_instance_id)

		# Re-show detail panel with updated info
		if not current_unit_entry.is_empty():
			_on_unit_clicked(current_unit_entry)
	else:
		print("Imprint failed!")
		confirm_panel.visible = false
		pending_fodder_id = ""
		detail_panel.visible = true

func _on_cancel_confirm():
	confirm_panel.visible = false
	pending_fodder_id = ""
	imprint_panel.visible = true

func _on_level_up_pressed():
	if current_unit_entry.is_empty():
		return

	var instance_id = current_unit_entry.instance_id as String
	var success = PlayerData.level_up_unit(instance_id, 1)

	if success:
		# Refresh the display
		_update_currency_display()
		_populate_collection()

		# Re-fetch the unit entry (it was modified)
		current_unit_entry = PlayerData.get_unit_by_instance_id(instance_id)

		# Re-show detail panel with updated info
		if not current_unit_entry.is_empty():
			_on_unit_clicked(current_unit_entry)

func _update_currency_display():
	if currency_label:
		currency_label.text = str(PlayerData.gold) + " Gold  |  " + str(PlayerData.level_materials) + " Materials  |  " + str(PlayerData.enhancement_stones) + " Stones  |  " + str(PlayerData.gems) + " Gems"

# --- Cheat Functions ---

func _on_max_level_pressed():
	if current_unit_entry.is_empty():
		return

	var instance_id = current_unit_entry.instance_id as String
	var unit_data = current_unit_entry.unit_data as UnitData
	var max_level = PlayerData.get_max_level(unit_data.star_rating)

	# Find and update the unit directly
	for i in range(PlayerData.owned_units.size()):
		if PlayerData.owned_units[i].instance_id == instance_id:
			PlayerData.owned_units[i].level = max_level
			PlayerData.owned_units[i].xp = 0
			print("[CHEAT] ", unit_data.unit_name, " set to max level ", max_level)
			break

	PlayerData.save_game()

	# Refresh display
	_populate_collection()
	current_unit_entry = PlayerData.get_unit_by_instance_id(instance_id)
	if not current_unit_entry.is_empty():
		_on_unit_clicked(current_unit_entry)

func _on_reset_level_pressed():
	if current_unit_entry.is_empty():
		return

	var instance_id = current_unit_entry.instance_id as String
	var unit_data = current_unit_entry.unit_data as UnitData

	# Find and update the unit directly
	for i in range(PlayerData.owned_units.size()):
		if PlayerData.owned_units[i].instance_id == instance_id:
			PlayerData.owned_units[i].level = 1
			PlayerData.owned_units[i].xp = 0
			print("[CHEAT] ", unit_data.unit_name, " reset to level 1")
			break

	PlayerData.save_game()

	# Refresh display
	_populate_collection()
	current_unit_entry = PlayerData.get_unit_by_instance_id(instance_id)
	if not current_unit_entry.is_empty():
		_on_unit_clicked(current_unit_entry)

# --- Gear Functions ---

func _update_gear_slots():
	if not gear_slots_container:
		return

	# Clear existing slot buttons
	for child in gear_slots_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	if current_unit_entry.is_empty():
		return

	var unit_instance_id = current_unit_entry.instance_id as String
	var equipped_gear = current_unit_entry.get("equipped_gear", {})

	var slot_names = ["Weapon", "Armor", "Acc 1", "Acc 2"]
	var slot_keys = ["weapon", "armor", "accessory_1", "accessory_2"]

	for i in range(4):
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(120, 50)

		var gear_id = equipped_gear.get(slot_keys[i], "")
		if gear_id != "":
			var gear_entry = PlayerData.get_gear_by_instance_id(gear_id)
			if not gear_entry.is_empty():
				var template = PlayerData.get_gear_template(gear_entry.gear_id)
				if template:
					slot_btn.text = slot_names[i] + "\n" + template.gear_name
					slot_btn.modulate = template.get_rarity_color()
				else:
					slot_btn.text = slot_names[i] + "\n[Unknown]"
			else:
				slot_btn.text = slot_names[i] + "\n[Empty]"
		else:
			slot_btn.text = slot_names[i] + "\n[Empty]"

		slot_btn.pressed.connect(_on_gear_slot_clicked.bind(i))
		gear_slots_container.add_child(slot_btn)

func _on_gear_slot_clicked(slot_index: int):
	current_gear_slot = slot_index
	_populate_gear_select_grid()
	if gear_select_panel:
		gear_select_panel.visible = true
		detail_panel.visible = false

func _populate_gear_select_grid():
	if not gear_select_grid:
		return

	# Clear existing
	for child in gear_select_grid.get_children():
		child.queue_free()

	await get_tree().process_frame

	# First add "Unequip" option
	var unequip_btn = Button.new()
	unequip_btn.text = "UNEQUIP"
	unequip_btn.custom_minimum_size = Vector2(140, 60)
	unequip_btn.pressed.connect(_on_gear_selected.bind(""))
	gear_select_grid.add_child(unequip_btn)

	# Get gear that can go in this slot
	var slot_type = -1
	match current_gear_slot:
		0: slot_type = GearData.GearType.WEAPON
		1: slot_type = GearData.GearType.ARMOR
		2, 3: slot_type = GearData.GearType.ACCESSORY

	# Get unequipped gear of the right type
	var available_gear = PlayerData.get_unequipped_gear()
	for gear_entry in available_gear:
		var template = PlayerData.get_gear_template(gear_entry.gear_id)
		if template and template.gear_type == slot_type:
			var gear_btn = _create_gear_select_button(gear_entry)
			gear_select_grid.add_child(gear_btn)

func _create_gear_select_button(gear_entry: Dictionary) -> Button:
	var template = PlayerData.get_gear_template(gear_entry.gear_id)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(140, 80)

	var stat_value = template.get_stat_at_level(gear_entry.level)
	var stat_text = template.get_stat_name() + ": "
	if template.is_percentage:
		stat_text += "+" + str(snapped(stat_value, 0.1)) + "%"
	else:
		stat_text += "+" + str(int(stat_value))

	btn.text = template.gear_name + "\n" + stat_text + "\n+" + str(gear_entry.level)
	btn.modulate = template.get_rarity_color().lightened(0.3)
	btn.pressed.connect(_on_gear_selected.bind(gear_entry.instance_id))

	return btn

func _on_gear_selected(gear_instance_id: String):
	if current_unit_entry.is_empty():
		return

	var unit_instance_id = current_unit_entry.instance_id as String
	var slot_keys = ["weapon", "armor", "accessory_1", "accessory_2"]
	var slot_key = slot_keys[current_gear_slot]

	if gear_instance_id == "":
		# Unequip
		PlayerData.unequip_gear(unit_instance_id, slot_key)
	else:
		# Equip
		PlayerData.equip_gear(unit_instance_id, gear_instance_id, slot_key)

	# Close gear select panel
	if gear_select_panel:
		gear_select_panel.visible = false
	current_gear_slot = -1

	# Refresh unit entry and display
	current_unit_entry = PlayerData.get_owned_unit(unit_instance_id)
	if not current_unit_entry.is_empty():
		_on_unit_clicked(current_unit_entry)

func _on_cancel_gear_select():
	if gear_select_panel:
		gear_select_panel.visible = false
	detail_panel.visible = true
	current_gear_slot = -1
