extends Control
## Team selection screen - choose 3-5 units for battle

const MIN_TEAM_SIZE = 3
const MAX_TEAM_SIZE = 5

@onready var back_btn = $TopBar/BackButton
@onready var start_btn = $BottomBar/StartButton
@onready var units_container = $ScrollContainer/UnitsGrid
@onready var team_container = $TeamPanel/TeamContainer
@onready var team_count_label = $TeamPanel/TeamCountLabel
@onready var instructions_label = $BottomBar/InstructionsLabel

var UnitDisplayScene = preload("res://scenes/battle/unit_display.tscn")

var selected_instance_ids: Array[String] = []  # Array of instance_ids
var unit_cards: Dictionary = {}  # instance_id -> card node

func _ready():
	back_btn.pressed.connect(_on_back)
	start_btn.pressed.connect(_on_start)
	_populate_units()
	_update_ui()

func _populate_units():
	# Clear existing
	for child in units_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	var owned = PlayerData.get_owned_unit_list()

	if owned.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No units yet!\nVisit the Summon screen to get units."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(400, 100)
		units_container.add_child(empty_label)
		return

	# Create a card for each owned unit instance
	for unit_entry in owned:
		var card = _create_unit_card(unit_entry)
		units_container.add_child(card)
		unit_cards[unit_entry.instance_id] = card

func _create_unit_card(unit_entry: Dictionary) -> Control:
	var unit_data = unit_entry.unit_data as UnitData
	var instance_id = unit_entry.instance_id as String
	var imprint_level = unit_entry.imprint_level as int

	var card = Panel.new()
	card.custom_minimum_size = Vector2(160, 200)

	# Background style
	var style = StyleBoxFlat.new()
	match unit_data.star_rating:
		5:
			style.bg_color = Color(0.3, 0.25, 0.1, 1)
		4:
			style.bg_color = Color(0.25, 0.15, 0.3, 1)
		_:
			style.bg_color = Color(0.15, 0.15, 0.2, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.3, 0.3, 0.4, 1)
	card.add_theme_stylebox_override("panel", style)

	# Store reference to style for selection highlight
	card.set_meta("style", style)
	card.set_meta("instance_id", instance_id)
	card.set_meta("unit_data", unit_data)

	# Unit display
	var display_container = Control.new()
	display_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	display_container.custom_minimum_size = Vector2(160, 120)
	card.add_child(display_container)

	var display = UnitDisplayScene.instantiate()
	display_container.add_child(display)
	display.position = Vector2(80, 60)
	display.scale = Vector2(0.5, 0.5)
	display.drag_enabled = false

	var instance = UnitInstance.new(unit_data, 1)
	display.call_deferred("setup", instance)

	# Name label
	var name_label = Label.new()
	name_label.text = unit_data.unit_name
	name_label.position = Vector2(0, 130)
	name_label.size = Vector2(160, 25)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	card.add_child(name_label)

	# Stars label
	var stars_label = Label.new()
	stars_label.text = "★".repeat(unit_data.star_rating)
	stars_label.position = Vector2(0, 155)
	stars_label.size = Vector2(160, 25)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	card.add_child(stars_label)

	# Imprint level (if > 0)
	if imprint_level > 0:
		var imprint_label = Label.new()
		imprint_label.text = "+" + str(imprint_level)
		imprint_label.position = Vector2(10, 5)
		imprint_label.add_theme_font_size_override("font_size", 18)
		imprint_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		card.add_child(imprint_label)

	# Make clickable
	var button = Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_unit_clicked.bind(instance_id, card))
	card.add_child(button)

	return card

func _on_unit_clicked(instance_id: String, card: Panel):
	var style = card.get_meta("style") as StyleBoxFlat

	if instance_id in selected_instance_ids:
		# Deselect
		selected_instance_ids.erase(instance_id)
		style.border_color = Color(0.3, 0.3, 0.4, 1)
	else:
		# Select (if not at max)
		if selected_instance_ids.size() >= MAX_TEAM_SIZE:
			print("Team is full! Deselect a unit first.")
			return
		selected_instance_ids.append(instance_id)
		style.border_color = Color(0.3, 1.0, 0.3, 1)  # Green border

	_update_ui()

func _update_ui():
	# Update team count
	team_count_label.text = "Team: " + str(selected_instance_ids.size()) + "/" + str(MAX_TEAM_SIZE)

	# Update start button
	var can_start = selected_instance_ids.size() >= MIN_TEAM_SIZE
	start_btn.disabled = not can_start

	if selected_instance_ids.size() < MIN_TEAM_SIZE:
		instructions_label.text = "Select at least " + str(MIN_TEAM_SIZE) + " units"
	elif selected_instance_ids.size() >= MAX_TEAM_SIZE:
		instructions_label.text = "Team full! Ready to battle."
	else:
		instructions_label.text = "Select up to " + str(MAX_TEAM_SIZE) + " units"

	# Update team preview
	_update_team_preview()

func _update_team_preview():
	# Clear existing
	for child in team_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	# Add selected units with manual positioning
	var spacing = 100
	var start_x = 50

	for i in range(selected_instance_ids.size()):
		var instance_id = selected_instance_ids[i]
		var unit_entry = PlayerData.get_unit_by_instance_id(instance_id)
		if unit_entry.is_empty():
			continue
		var unit_data = unit_entry.unit_data as UnitData
		var display = UnitDisplayScene.instantiate()
		team_container.add_child(display)
		display.position = Vector2(start_x + i * spacing, 35)
		display.scale = Vector2(0.45, 0.45)
		display.drag_enabled = false

		var instance = UnitInstance.new(unit_data, 1)
		display.call_deferred("setup", instance)

func _on_start():
	if selected_instance_ids.size() < MIN_TEAM_SIZE:
		return

	# Store selected team instance IDs in PlayerData
	PlayerData.selected_team = selected_instance_ids.duplicate()

	# Go to battle
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
