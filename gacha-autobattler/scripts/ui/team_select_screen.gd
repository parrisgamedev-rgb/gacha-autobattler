extends Control
## Team selection screen - choose 3-5 units for battle

var CurrencyBarScene = preload("res://scenes/ui/currency_bar.tscn")

const MIN_TEAM_SIZE = 3
const MAX_TEAM_SIZE = 5
const TEAM_SLOT_SIZE = Vector2(120, 140)

@onready var back_btn = $TopBarPanel/TopBar/BackButton
@onready var start_btn = $BottomBarPanel/BottomBar/StartButton
@onready var units_container = $AvailableUnitsSection/ScrollContainer/UnitsGrid
@onready var team_slots_container = $SelectedTeamSection/TeamSlotsContainer
@onready var team_count_label = $SelectedTeamSection/TeamLabel
@onready var instructions_label = $BottomBarPanel/BottomBar/InstructionsLabel
@onready var title_label = $TopBarPanel/TopBar/Title
@onready var stage_info_label = $TopBarPanel/TopBar/StageInfo
@onready var available_label = $AvailableUnitsSection/AvailableLabel
@onready var filter_dropdown = $AvailableUnitsSection/FilterDropdown
@onready var stage_info_panel = $StageInfoPanel

var UnitDisplayScene = preload("res://scenes/battle/unit_display.tscn")

var selected_instance_ids: Array[String] = []  # Array of instance_ids
var unit_cards: Dictionary = {}  # instance_id -> card node
var team_slot_nodes: Array = []  # Array of slot Panel nodes
var current_filter: int = 0  # 0 = All, 1 = 3-star, 2 = 4-star, 3 = 5-star

func _ready():
	# Add currency bar to top bar
	var currency_bar = CurrencyBarScene.instantiate()
	var top_bar = get_node_or_null("TopBarPanel/TopBar")
	if top_bar:
		top_bar.add_child(currency_bar)

	_apply_theme()
	back_btn.pressed.connect(_on_back)
	start_btn.pressed.connect(_on_start)
	_setup_filter_dropdown()
	_create_team_slots()
	_populate_units()
	_setup_mode_ui()
	_update_ui()

	# Create auto-select button
	var auto_btn = Button.new()
	auto_btn.name = "AutoSelectButton"
	auto_btn.text = "AUTO SELECT"
	auto_btn.custom_minimum_size = Vector2(150, 50)
	auto_btn.pressed.connect(_on_auto_select)
	UISpriteLoader.apply_button_style(auto_btn, UISpriteLoader.ButtonColor.GOLD, "ButtonA")
	auto_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	var bottom_bar = get_node_or_null("BottomBarPanel/BottomBar")
	if bottom_bar:
		bottom_bar.add_child(auto_btn)
		bottom_bar.move_child(auto_btn, 1)

func _apply_theme():
	# Background - use jungle theme image
	UISpriteLoader.apply_background_to_scene(self, UISpriteLoader.BackgroundTheme.JUNGLE, UISpriteLoader.BackgroundVariant.BRIGHT, 0.35)
	# Hide the old solid color background if it exists
	var bg = get_node_or_null("Background")
	if bg:
		bg.visible = false

	# Top bar panel
	var top_bar_panel = get_node_or_null("TopBarPanel")
	if top_bar_panel:
		top_bar_panel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM, UITheme.BG_LIGHT, 0))

	# Title
	if title_label:
		title_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Stage info in top bar
	if stage_info_label:
		stage_info_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		stage_info_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Back button with sprite styling (purple secondary)
	if back_btn:
		UISpriteLoader.apply_button_style(back_btn, UISpriteLoader.ButtonColor.PURPLE, "ButtonA")
		back_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Team section label
	if team_count_label:
		team_count_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		team_count_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Selected team section panel
	var team_section = get_node_or_null("SelectedTeamSection")
	if team_section and team_section is Panel:
		team_section.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM, UITheme.BG_LIGHT))

	# Available units label
	if available_label:
		available_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		available_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Filter dropdown styling
	_style_filter_dropdown()

	# Bottom bar panel
	var bottom_bar_panel = get_node_or_null("BottomBarPanel")
	if bottom_bar_panel:
		bottom_bar_panel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM, UITheme.BG_LIGHT, 0))

	# Instructions label
	if instructions_label:
		instructions_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		instructions_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Start button - primary style (blue)
	_style_primary_button(start_btn)

	# Stage info panel styling
	_style_stage_info_panel()

func _style_primary_button(btn: Button):
	if not btn:
		return

	# Use sprite-based button style (blue primary)
	UISpriteLoader.apply_button_style(btn, UISpriteLoader.ButtonColor.BLUE, "ButtonA")
	btn.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
	btn.add_theme_color_override("font_disabled_color", UITheme.TEXT_DISABLED)

func _style_stage_info_panel():
	if not stage_info_panel:
		return

	# Use sprite-based panel style
	UISpriteLoader.apply_panel_style(stage_info_panel, UISpriteLoader.PanelColor.BLUE, "Panel")

	var panel_bg = get_node_or_null("StageInfoPanel/PanelBg")
	if panel_bg:
		panel_bg.color = UITheme.BG_MEDIUM

	var header_label = get_node_or_null("StageInfoPanel/VBox/HeaderLabel")
	if header_label:
		header_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		header_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	var stage_label = get_node_or_null("StageInfoPanel/VBox/StageLabel")
	if stage_label:
		stage_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		stage_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	var difficulty_label = get_node_or_null("StageInfoPanel/VBox/DifficultyLabel")
	if difficulty_label:
		difficulty_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		difficulty_label.add_theme_color_override("font_color", UITheme.GOLD)

	var enemies_label = get_node_or_null("StageInfoPanel/VBox/EnemiesLabel")
	if enemies_label:
		enemies_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		enemies_label.add_theme_color_override("font_color", UITheme.DANGER)

	var rewards_label = get_node_or_null("StageInfoPanel/VBox/RewardsLabel")
	if rewards_label:
		rewards_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		rewards_label.add_theme_color_override("font_color", UITheme.SUCCESS)

func _setup_filter_dropdown():
	if not filter_dropdown:
		return

	# Add filter options
	filter_dropdown.clear()
	filter_dropdown.add_item("All", 0)
	filter_dropdown.add_item("3★", 1)
	filter_dropdown.add_item("4★", 2)
	filter_dropdown.add_item("5★", 3)
	filter_dropdown.selected = 0

	# Connect the selection signal
	filter_dropdown.item_selected.connect(_on_filter_changed)

func _style_filter_dropdown():
	if not filter_dropdown:
		return

	# Style the dropdown using UITheme colors
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = UITheme.BG_LIGHT
	normal_style.border_color = UITheme.TEXT_DISABLED
	normal_style.border_width_left = 1
	normal_style.border_width_right = 1
	normal_style.border_width_top = 1
	normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left = UITheme.BUTTON_RADIUS
	normal_style.corner_radius_top_right = UITheme.BUTTON_RADIUS
	normal_style.corner_radius_bottom_left = UITheme.BUTTON_RADIUS
	normal_style.corner_radius_bottom_right = UITheme.BUTTON_RADIUS
	normal_style.content_margin_left = UITheme.SPACING_SM
	normal_style.content_margin_right = UITheme.SPACING_SM
	normal_style.content_margin_top = UITheme.SPACING_XS
	normal_style.content_margin_bottom = UITheme.SPACING_XS

	var hover_style = normal_style.duplicate()
	hover_style.border_color = UITheme.PRIMARY

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = UITheme.BG_MEDIUM

	filter_dropdown.add_theme_stylebox_override("normal", normal_style)
	filter_dropdown.add_theme_stylebox_override("hover", hover_style)
	filter_dropdown.add_theme_stylebox_override("pressed", pressed_style)
	filter_dropdown.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	filter_dropdown.add_theme_color_override("font_hover_color", UITheme.TEXT_PRIMARY)
	filter_dropdown.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

func _on_filter_changed(index: int):
	AudioManager.play_ui_click()
	current_filter = index
	_populate_units()

func _create_team_slots():
	# Clear existing slots
	team_slot_nodes.clear()
	if team_slots_container:
		for child in team_slots_container.get_children():
			child.queue_free()

	# Create 5 empty slots
	for i in range(MAX_TEAM_SIZE):
		var slot = _create_empty_slot(i)
		team_slots_container.add_child(slot)
		team_slot_nodes.append(slot)

func _create_empty_slot(index: int) -> Panel:
	var slot = Panel.new()
	slot.custom_minimum_size = TEAM_SLOT_SIZE

	# Style as empty slot using sprite-based panel
	UISpriteLoader.apply_panel_style(slot, UISpriteLoader.PanelColor.WHITE, "Panel")
	slot.modulate = Color(0.7, 0.7, 0.75, 1.0)  # Slightly dimmed for empty state

	# Plus sign for empty slot
	var plus_label = Label.new()
	plus_label.name = "PlusLabel"
	plus_label.text = "+"
	plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	plus_label.add_theme_font_size_override("font_size", 48)
	plus_label.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)
	slot.add_child(plus_label)

	# Slot number label
	var slot_num = Label.new()
	slot_num.name = "SlotNum"
	slot_num.text = str(index + 1)
	slot_num.position = Vector2(8, 5)
	slot_num.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	slot_num.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)
	slot.add_child(slot_num)

	slot.set_meta("slot_index", index)
	slot.set_meta("instance_id", "")

	return slot

func _update_team_slot(slot: Panel, unit_entry: Dictionary):
	# Clear existing children except the button
	for child in slot.get_children():
		child.queue_free()

	var unit_data = unit_entry.unit_data as UnitData
	var instance_id = unit_entry.instance_id as String
	var imprint_level = unit_entry.get("imprint_level", 0) as int
	var unit_level = unit_entry.get("level", 1) as int

	# Use sprite-based panel style based on rarity
	var panel_color = UISpriteLoader.PanelColor.BLUE
	match unit_data.star_rating:
		3: panel_color = UISpriteLoader.PanelColor.BLUE
		4: panel_color = UISpriteLoader.PanelColor.PURPLE
		5: panel_color = UISpriteLoader.PanelColor.GOLD
	UISpriteLoader.apply_panel_style(slot, panel_color, "Panel")
	slot.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full brightness for filled slots

	# Unit display
	var display_container = Control.new()
	display_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	display_container.custom_minimum_size = Vector2(TEAM_SLOT_SIZE.x, 70)
	slot.add_child(display_container)

	var display = UnitDisplayScene.instantiate()
	display_container.add_child(display)
	display.position = Vector2(TEAM_SLOT_SIZE.x / 2, 45)
	display.scale = Vector2(0.45, 0.45)
	display.drag_enabled = false

	var instance = UnitInstance.new(unit_data, 1, unit_level, imprint_level)
	display.call_deferred("setup", instance)

	# Level label (top left)
	var level_label = Label.new()
	level_label.text = "Lv." + str(unit_level)
	level_label.position = Vector2(5, 3)
	level_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
	level_label.add_theme_color_override("font_color", UITheme.SUCCESS)
	slot.add_child(level_label)

	# Imprint level (top right if > 0)
	if imprint_level > 0:
		var imprint_label = Label.new()
		imprint_label.text = "+" + str(imprint_level)
		imprint_label.position = Vector2(TEAM_SLOT_SIZE.x - 25, 3)
		imprint_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
		imprint_label.add_theme_color_override("font_color", UITheme.SECONDARY)
		slot.add_child(imprint_label)

	# Name label
	var name_label = Label.new()
	name_label.text = unit_data.unit_name
	name_label.position = Vector2(0, 75)
	name_label.size = Vector2(TEAM_SLOT_SIZE.x, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	name_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	name_label.clip_text = true
	slot.add_child(name_label)

	# Stars label
	var stars_label = Label.new()
	stars_label.text = "★".repeat(unit_data.star_rating)
	stars_label.position = Vector2(0, 95)
	stars_label.size = Vector2(TEAM_SLOT_SIZE.x, 20)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
	stars_label.add_theme_color_override("font_color", UITheme.GOLD)
	slot.add_child(stars_label)

	# Remove button (X)
	var remove_btn = Button.new()
	remove_btn.text = "X"
	remove_btn.position = Vector2(TEAM_SLOT_SIZE.x - 28, TEAM_SLOT_SIZE.y - 28)
	remove_btn.custom_minimum_size = Vector2(24, 24)
	# Use compact style without large margins
	var remove_style = StyleBoxFlat.new()
	remove_style.bg_color = UITheme.DANGER.darkened(0.3)
	remove_style.corner_radius_top_left = 4
	remove_style.corner_radius_top_right = 4
	remove_style.corner_radius_bottom_left = 4
	remove_style.corner_radius_bottom_right = 4
	remove_style.content_margin_left = 4
	remove_style.content_margin_right = 4
	remove_style.content_margin_top = 2
	remove_style.content_margin_bottom = 2
	remove_btn.add_theme_stylebox_override("normal", remove_style)
	var remove_hover = remove_style.duplicate()
	remove_hover.bg_color = UITheme.DANGER
	remove_btn.add_theme_stylebox_override("hover", remove_hover)
	remove_btn.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
	remove_btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	remove_btn.pressed.connect(_on_slot_remove_clicked.bind(instance_id))
	slot.add_child(remove_btn)

	slot.set_meta("instance_id", instance_id)

func _reset_slot_to_empty(slot: Panel, index: int):
	# Clear all children
	for child in slot.get_children():
		child.queue_free()

	# Reset style to empty using sprite-based panel
	UISpriteLoader.apply_panel_style(slot, UISpriteLoader.PanelColor.WHITE, "Panel")
	slot.modulate = Color(0.7, 0.7, 0.75, 1.0)  # Slightly dimmed for empty state

	# Plus sign
	var plus_label = Label.new()
	plus_label.name = "PlusLabel"
	plus_label.text = "+"
	plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	plus_label.add_theme_font_size_override("font_size", 48)
	plus_label.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)
	slot.add_child(plus_label)

	# Slot number
	var slot_num = Label.new()
	slot_num.name = "SlotNum"
	slot_num.text = str(index + 1)
	slot_num.position = Vector2(8, 5)
	slot_num.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	slot_num.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)
	slot.add_child(slot_num)

	slot.set_meta("instance_id", "")

func _on_slot_remove_clicked(instance_id: String):
	AudioManager.play_ui_click()
	if instance_id in selected_instance_ids:
		selected_instance_ids.erase(instance_id)
		# Update the card border back to rarity color and hide checkmark
		if unit_cards.has(instance_id):
			var card = unit_cards[instance_id]
			var unit_data = card.get_meta("unit_data") as UnitData
			var style = card.get_meta("style") as StyleBoxFlat
			if style and unit_data:
				style.border_color = UITheme.get_rarity_color(unit_data.star_rating)
				style.border_width_left = 3
				style.border_width_right = 3
				style.border_width_top = 3
				style.border_width_bottom = 3
			var check_mark = card.get_node_or_null("CheckMark")
			if check_mark:
				check_mark.visible = false
		_update_ui()

func _populate_units():
	# Clear existing
	for child in units_container.get_children():
		child.queue_free()

	unit_cards.clear()

	await get_tree().process_frame

	var owned = PlayerData.get_owned_unit_list()

	# Apply filter
	var filtered_units = _filter_units(owned)

	if filtered_units.is_empty():
		var empty_label = Label.new()
		if owned.is_empty():
			empty_label.text = "No units yet!\nVisit the Summon screen to get units."
		else:
			empty_label.text = "No units match the current filter."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(400, 100)
		empty_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
		empty_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		units_container.add_child(empty_label)
		return

	# Create a card for each filtered unit instance
	for unit_entry in filtered_units:
		var card = _create_unit_card(unit_entry)
		units_container.add_child(card)
		unit_cards[unit_entry.instance_id] = card

func _filter_units(units: Array) -> Array:
	if current_filter == 0:  # All
		return units

	var filtered: Array = []
	var target_star_rating = current_filter + 2  # 1 -> 3-star, 2 -> 4-star, 3 -> 5-star

	for unit_entry in units:
		var unit_data = unit_entry.unit_data as UnitData
		if unit_data and unit_data.star_rating == target_star_rating:
			filtered.append(unit_entry)

	return filtered

func _create_unit_card(unit_entry: Dictionary) -> Control:
	var unit_data = unit_entry.unit_data as UnitData
	var instance_id = unit_entry.instance_id as String
	var imprint_level = unit_entry.get("imprint_level", 0) as int
	var unit_level = unit_entry.get("level", 1) as int

	var card = Panel.new()
	card.custom_minimum_size = UITheme.UNIT_CARD_SIZE

	# Create styled card with rarity-colored border (matching collection_screen)
	var style = StyleBoxFlat.new()
	style.bg_color = UITheme.BG_MEDIUM
	style.corner_radius_top_left = UITheme.CARD_RADIUS
	style.corner_radius_top_right = UITheme.CARD_RADIUS
	style.corner_radius_bottom_left = UITheme.CARD_RADIUS
	style.corner_radius_bottom_right = UITheme.CARD_RADIUS
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = UITheme.get_rarity_color(unit_data.star_rating)
	card.add_theme_stylebox_override("panel", style)

	# Store reference to style for selection highlight
	card.set_meta("style", style)
	card.set_meta("instance_id", instance_id)
	card.set_meta("unit_data", unit_data)

	# Card dimensions based on UNIT_CARD_SIZE
	var card_width = UITheme.UNIT_CARD_SIZE.x
	var card_height = UITheme.UNIT_CARD_SIZE.y

	# Unit display
	var display_container = Control.new()
	display_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	display_container.custom_minimum_size = Vector2(card_width, 100)
	card.add_child(display_container)

	var display = UnitDisplayScene.instantiate()
	display_container.add_child(display)
	display.position = Vector2(card_width / 2, 60)
	display.scale = Vector2(0.55, 0.55)
	display.drag_enabled = false

	var instance = UnitInstance.new(unit_data, 1, unit_level, imprint_level)
	display.call_deferred("setup", instance)

	# Level label (top left)
	var level_label = Label.new()
	level_label.text = "Lv." + str(unit_level)
	level_label.position = Vector2(8, 5)
	level_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	level_label.add_theme_color_override("font_color", UITheme.SUCCESS)
	card.add_child(level_label)

	# Imprint level (top right if > 0)
	if imprint_level > 0:
		var imprint_label = Label.new()
		imprint_label.text = "+" + str(imprint_level)
		imprint_label.position = Vector2(card_width - 30, 5)
		imprint_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		imprint_label.add_theme_color_override("font_color", UITheme.SECONDARY)
		card.add_child(imprint_label)

	# Name label
	var name_label = Label.new()
	name_label.text = unit_data.unit_name
	name_label.position = Vector2(0, 110)
	name_label.size = Vector2(card_width, 25)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
	name_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	card.add_child(name_label)

	# Stars label
	var stars_label = Label.new()
	stars_label.text = "★".repeat(unit_data.star_rating)
	stars_label.position = Vector2(0, 132)
	stars_label.size = Vector2(card_width, 20)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_color_override("font_color", UITheme.GOLD)
	stars_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	card.add_child(stars_label)

	# Element label
	var element_label = Label.new()
	element_label.text = unit_data.element.capitalize()
	element_label.position = Vector2(0, 155)
	element_label.size = Vector2(card_width, 20)
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	element_label.add_theme_color_override("font_color", unit_data.get_element_color())
	card.add_child(element_label)

	# Combat Power
	var cp = PlayerData.calculate_unit_cp(unit_entry)
	var cp_label = Label.new()
	cp_label.text = "CP: " + str(cp)
	cp_label.position = Vector2(0, 175)
	cp_label.size = Vector2(card_width, 20)
	cp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cp_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	cp_label.add_theme_color_override("font_color", UITheme.GOLD)
	card.add_child(cp_label)

	# Selection indicator (checkmark)
	var is_selected = instance_id in selected_instance_ids
	var check_label = Label.new()
	check_label.name = "CheckMark"
	check_label.text = "✓"
	check_label.position = Vector2(card_width - 30, card_height - 30)
	check_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
	check_label.add_theme_color_override("font_color", UITheme.SUCCESS)
	check_label.visible = is_selected
	card.add_child(check_label)

	# Update border style if already selected
	if is_selected:
		style.border_color = UITheme.SUCCESS.lightened(0.2)
		style.border_width_left = 5
		style.border_width_right = 5
		style.border_width_top = 5
		style.border_width_bottom = 5

	# Make clickable
	var button = Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_unit_clicked.bind(instance_id, card))
	card.add_child(button)

	return card

func _on_unit_clicked(instance_id: String, card: Panel):
	AudioManager.play_ui_click()
	var style = card.get_meta("style") as StyleBoxFlat
	var unit_data = card.get_meta("unit_data") as UnitData
	var check_mark = card.get_node_or_null("CheckMark")

	if instance_id in selected_instance_ids:
		# Deselect - restore rarity border
		selected_instance_ids.erase(instance_id)
		style.border_color = UITheme.get_rarity_color(unit_data.star_rating)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		if check_mark:
			check_mark.visible = false
	else:
		# Select (if not at max)
		if selected_instance_ids.size() >= MAX_TEAM_SIZE:
			print("Team is full! Deselect a unit first.")
			return
		selected_instance_ids.append(instance_id)
		# Use brighter SUCCESS color with increased border width for better visibility
		style.border_color = UITheme.SUCCESS.lightened(0.2)
		style.border_width_left = 5
		style.border_width_right = 5
		style.border_width_top = 5
		style.border_width_bottom = 5
		if check_mark:
			check_mark.visible = true

	_update_ui()

func _update_ui():
	# Update team count label
	team_count_label.text = "YOUR TEAM (" + str(selected_instance_ids.size()) + "/" + str(MAX_TEAM_SIZE) + ")"

	# Update start button
	var can_start = selected_instance_ids.size() >= MIN_TEAM_SIZE
	start_btn.disabled = not can_start

	if selected_instance_ids.size() < MIN_TEAM_SIZE:
		instructions_label.text = "Select at least " + str(MIN_TEAM_SIZE) + " units to start"
	elif selected_instance_ids.size() >= MAX_TEAM_SIZE:
		instructions_label.text = "Team full! Ready to battle."
	else:
		instructions_label.text = "Select up to " + str(MAX_TEAM_SIZE) + " units, then start!"

	# Update team preview slots
	_update_team_preview()

func _update_team_preview():
	# Update each team slot
	for i in range(MAX_TEAM_SIZE):
		var slot = team_slot_nodes[i]
		if i < selected_instance_ids.size():
			var instance_id = selected_instance_ids[i]
			var unit_entry = PlayerData.get_unit_by_instance_id(instance_id)
			if not unit_entry.is_empty():
				_update_team_slot(slot, unit_entry)
			else:
				_reset_slot_to_empty(slot, i)
		else:
			_reset_slot_to_empty(slot, i)

func _on_start():
	AudioManager.play_ui_click()
	if selected_instance_ids.size() < MIN_TEAM_SIZE:
		return

	# Store selected team instance IDs in PlayerData
	PlayerData.selected_team = selected_instance_ids.duplicate()

	# Go to appropriate battle scene
	if PlayerData.pvp_mode:
		SceneTransition.change_scene("res://scenes/battle/battle_pvp.tscn")
	else:
		SceneTransition.change_scene("res://scenes/battle/battle.tscn")

func _on_back():
	AudioManager.play_ui_click()
	if PlayerData.is_campaign_mode():
		PlayerData.end_campaign_stage()
		SceneTransition.change_scene("res://scenes/ui/campaign_select_screen.tscn")
	elif PlayerData.is_dungeon_mode():
		PlayerData.end_dungeon()
		SceneTransition.change_scene("res://scenes/ui/dungeon_select_screen.tscn")
	else:
		SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")

func _on_auto_select():
	AudioManager.play_ui_click()

	# Get all owned units with their CP
	var owned = PlayerData.get_owned_unit_list()
	if owned.is_empty():
		return

	# Calculate CP for each unit and create sortable array
	var units_with_cp: Array = []
	for unit_entry in owned:
		var cp = PlayerData.calculate_unit_cp(unit_entry)
		units_with_cp.append({"entry": unit_entry, "cp": cp})

	# Sort by CP descending
	units_with_cp.sort_custom(func(a, b): return a.cp > b.cp)

	# Clear current selection
	selected_instance_ids.clear()

	# Reset all card visuals
	for inst_id in unit_cards:
		var card = unit_cards[inst_id]
		var unit_data = card.get_meta("unit_data") as UnitData
		var style = card.get_meta("style") as StyleBoxFlat
		if style and unit_data:
			style.border_color = UITheme.get_rarity_color(unit_data.star_rating)
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
		var check_mark = card.get_node_or_null("CheckMark")
		if check_mark:
			check_mark.visible = false

	# Select top MAX_TEAM_SIZE units
	var to_select = mini(MAX_TEAM_SIZE, units_with_cp.size())
	for i in range(to_select):
		var unit_entry = units_with_cp[i].entry
		var inst_id = unit_entry.instance_id
		selected_instance_ids.append(inst_id)

		# Update card visual if visible
		if unit_cards.has(inst_id):
			var card = unit_cards[inst_id]
			var style = card.get_meta("style") as StyleBoxFlat
			if style:
				style.border_color = UITheme.SUCCESS.lightened(0.2)
				style.border_width_left = 5
				style.border_width_right = 5
				style.border_width_top = 5
				style.border_width_bottom = 5
			var check_mark = card.get_node_or_null("CheckMark")
			if check_mark:
				check_mark.visible = true

	_update_ui()

func _setup_mode_ui():
	# Show/hide mode-specific UI
	if PlayerData.is_campaign_mode():
		var stage = PlayerData.current_stage
		if stage and title_label:
			title_label.text = "STAGE " + stage.get_stage_display()

		if stage_info_label:
			stage_info_label.text = stage.stage_name if stage else ""
			stage_info_label.visible = true

		if start_btn:
			start_btn.text = "START STAGE"

		# Show stage info panel
		if stage_info_panel:
			stage_info_panel.visible = true
			_update_stage_info_panel(stage)
	elif PlayerData.is_dungeon_mode():
		var dungeon = PlayerData.current_dungeon
		var tier = PlayerData.current_dungeon_tier
		if dungeon and title_label:
			var tier_name = dungeon.tier_names[tier] if tier < dungeon.tier_names.size() else "Unknown"
			title_label.text = dungeon.dungeon_name

		if stage_info_label:
			var tier_name = dungeon.tier_names[tier] if dungeon and tier < dungeon.tier_names.size() else ""
			stage_info_label.text = tier_name
			stage_info_label.visible = true

		if start_btn:
			start_btn.text = "START DUNGEON"

		# Show dungeon info panel
		if stage_info_panel:
			stage_info_panel.visible = true
			_update_dungeon_info_panel(dungeon, tier)
	else:
		if title_label:
			title_label.text = "SELECT YOUR TEAM"
		if stage_info_label:
			stage_info_label.visible = false
		if start_btn:
			start_btn.text = "START BATTLE"
		if stage_info_panel:
			stage_info_panel.visible = false

func _update_stage_info_panel(stage):
	if stage == null or stage_info_panel == null:
		return

	var stage_label = stage_info_panel.get_node_or_null("VBox/StageLabel")
	var difficulty_label = stage_info_panel.get_node_or_null("VBox/DifficultyLabel")
	var rewards_label = stage_info_panel.get_node_or_null("VBox/RewardsLabel")
	var enemies_label = stage_info_panel.get_node_or_null("VBox/EnemiesLabel")

	if stage_label:
		stage_label.text = stage.get_stage_display() + " - " + stage.stage_name

	if difficulty_label:
		difficulty_label.text = "Difficulty: " + stage.get_difficulty_stars()

	if rewards_label:
		var is_first_clear = not PlayerData.is_stage_cleared(stage.stage_id)
		if is_first_clear:
			var reward_text = str(stage.gem_reward) + " Gems"
			if stage.first_clear_unit:
				reward_text += " + " + stage.first_clear_unit.unit_name
			rewards_label.text = "First Clear: " + reward_text
		else:
			rewards_label.text = "Already Cleared"

	if enemies_label:
		enemies_label.text = "Enemies: " + str(stage.enemy_units.size()) + " units (Lv." + str(stage.enemy_level) + ")"

func _update_dungeon_info_panel(dungeon, tier: int):
	if dungeon == null or stage_info_panel == null:
		return

	var stage_label = stage_info_panel.get_node_or_null("VBox/StageLabel")
	var difficulty_label = stage_info_panel.get_node_or_null("VBox/DifficultyLabel")
	var rewards_label = stage_info_panel.get_node_or_null("VBox/RewardsLabel")
	var enemies_label = stage_info_panel.get_node_or_null("VBox/EnemiesLabel")

	var tier_name = dungeon.tier_names[tier] if tier < dungeon.tier_names.size() else "Unknown"
	var enemy_level = dungeon.get_enemy_level(tier)
	var stone_range = dungeon.get_stone_drop_range(tier)

	if stage_label:
		stage_label.text = dungeon.dungeon_name + " - " + tier_name

	if difficulty_label:
		var stat_name = ""
		match dungeon.drops_stat_type:
			GearData.StatType.ATTACK: stat_name = "ATK"
			GearData.StatType.DEFENSE: stat_name = "DEF"
			GearData.StatType.HP: stat_name = "HP"
			GearData.StatType.SPEED: stat_name = "SPD"
		difficulty_label.text = "Drops: " + stat_name + " Gear"

	if rewards_label:
		rewards_label.text = "Stones: " + str(stone_range[0]) + "-" + str(stone_range[1])

	if enemies_label:
		enemies_label.text = "Enemies: Lv." + str(enemy_level)
