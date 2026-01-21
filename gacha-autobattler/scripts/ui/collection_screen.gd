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
@onready var imprint_panel = $ImprintPanel
@onready var fodder_grid = $ImprintPanel/FodderScroll/FodderGrid
@onready var cancel_imprint_btn = $ImprintPanel/CancelImprintButton
@onready var confirm_panel = $ConfirmPanel
@onready var confirm_message = $ConfirmPanel/ConfirmMessage
@onready var confirm_btn = $ConfirmPanel/ButtonContainer/ConfirmButton
@onready var cancel_confirm_btn = $ConfirmPanel/ButtonContainer/CancelConfirmButton

var UnitDisplayScene = preload("res://scenes/battle/unit_display.tscn")

# Currently selected unit for viewing/imprinting
var current_unit_entry: Dictionary = {}
var pending_fodder_id: String = ""

func _ready():
	back_btn.pressed.connect(_on_back)
	close_detail_btn.pressed.connect(_on_close_detail)
	imprint_btn.pressed.connect(_on_imprint_pressed)
	cancel_imprint_btn.pressed.connect(_on_cancel_imprint)
	confirm_btn.pressed.connect(_on_confirm_imprint)
	cancel_confirm_btn.pressed.connect(_on_cancel_confirm)
	detail_panel.visible = false
	imprint_panel.visible = false
	confirm_panel.visible = false
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
	var imprint_level = unit_entry.imprint_level as int
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
	display_container.custom_minimum_size = Vector2(180, 140)
	card.add_child(display_container)

	var display = UnitDisplayScene.instantiate()
	display_container.add_child(display)
	display.position = Vector2(90, 70)
	display.scale = Vector2(0.55, 0.55)
	display.drag_enabled = false

	# Defer setup until the node is ready
	var instance = UnitInstance.new(unit_data, 1)
	display.call_deferred("setup", instance)

	# Instance ID label (small, for debugging/identification)
	var id_label = Label.new()
	id_label.text = "#" + instance_id
	id_label.position = Vector2(140, 5)
	id_label.add_theme_font_size_override("font_size", 14)
	id_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	card.add_child(id_label)

	# Imprint level
	if imprint_level > 0:
		var imprint_label = Label.new()
		imprint_label.text = "+" + str(imprint_level)
		imprint_label.position = Vector2(10, 5)
		imprint_label.add_theme_font_size_override("font_size", 18)
		imprint_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		card.add_child(imprint_label)

	# Name label
	var name_label = Label.new()
	name_label.text = unit_data.unit_name
	name_label.position = Vector2(0, 150)
	name_label.size = Vector2(180, 30)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	card.add_child(name_label)

	# Stars label
	var stars_label = Label.new()
	stars_label.text = "★".repeat(unit_data.star_rating)
	stars_label.position = Vector2(0, 175)
	stars_label.size = Vector2(180, 25)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	card.add_child(stars_label)

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
	var imprint_level = unit_entry.imprint_level as int

	detail_panel.visible = true
	detail_name.text = unit_data.unit_name
	detail_stars.text = "★".repeat(unit_data.star_rating)
	detail_element.text = "Element: " + unit_data.element.capitalize()
	detail_stats.text = "HP: " + str(unit_data.max_hp) + "  ATK: " + str(unit_data.attack) + "  DEF: " + str(unit_data.defense) + "  SPD: " + str(unit_data.speed)
	detail_copies.text = "Instance ID: " + unit_entry.instance_id
	detail_imprint.text = "Imprint Level: " + str(imprint_level) + "/5"

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
