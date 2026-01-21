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

var UnitDisplayScene = preload("res://scenes/battle/unit_display.tscn")

func _ready():
	back_btn.pressed.connect(_on_back)
	close_detail_btn.pressed.connect(_on_close_detail)
	detail_panel.visible = false
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
	for unit_info in owned:
		var card = _create_unit_card(unit_info.data, unit_info.copies)
		units_container.add_child(card)

func _create_unit_card(unit_data: UnitData, copies: int) -> Control:
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

	# Copies label
	var copies_label = Label.new()
	copies_label.text = "x" + str(copies)
	copies_label.position = Vector2(140, 5)
	copies_label.add_theme_font_size_override("font_size", 18)
	copies_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
	card.add_child(copies_label)

	# Imprint level
	var imprint = PlayerData.get_imprint_level(unit_data.unit_id)
	if imprint > 0:
		var imprint_label = Label.new()
		imprint_label.text = "+" + str(imprint)
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
	button.pressed.connect(_on_unit_clicked.bind(unit_data, copies))
	card.add_child(button)

	return card

func _on_unit_clicked(unit_data: UnitData, copies: int):
	detail_panel.visible = true
	detail_name.text = unit_data.unit_name
	detail_stars.text = "★".repeat(unit_data.star_rating)
	detail_element.text = "Element: " + unit_data.element.capitalize()
	detail_stats.text = "HP: " + str(unit_data.max_hp) + "  ATK: " + str(unit_data.attack) + "  DEF: " + str(unit_data.defense) + "  SPD: " + str(unit_data.speed)
	detail_copies.text = "Copies: " + str(copies) + "/6"

	var imprint = PlayerData.get_imprint_level(unit_data.unit_id)
	detail_imprint.text = "Imprint Level: " + str(imprint) + "/5"

	# Color element label
	var element_color = unit_data.get_element_color()
	detail_element.add_theme_color_override("font_color", element_color)

func _on_close_detail():
	detail_panel.visible = false

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
