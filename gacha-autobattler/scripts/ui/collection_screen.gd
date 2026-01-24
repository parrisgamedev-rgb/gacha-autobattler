extends Control
## Collection screen for viewing owned units

var CurrencyBarScene = preload("res://scenes/ui/currency_bar.tscn")

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
@onready var close_detail_btn = $DetailPanel/ActionButtons/CloseButton

# Dynamic CP label for detail panel
var detail_cp_label: Label = null
@onready var imprint_btn = $DetailPanel/ActionButtons/ImprintButton
@onready var level_up_btn = $DetailPanel/ActionButtons/LevelUpButton
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

# Detail panel animated sprite
var detail_sprite: Sprite2D = null
var detail_ai_sprite: AnimatedSprite2D = null
var detail_sprite_container: Control = null
var idle_animation_tween: Tween = null

func _ready():
	# Add currency bar to top bar
	var currency_bar = CurrencyBarScene.instantiate()
	var top_bar = get_node_or_null("TopBar")
	if top_bar:
		top_bar.add_child(currency_bar)

	_apply_theme()
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
	_setup_detail_sprite()
	_update_currency_display()
	_populate_collection()

func _setup_detail_sprite():
	# Create container for the animated sprite in detail panel
	detail_sprite_container = Control.new()
	detail_sprite_container.custom_minimum_size = Vector2(200, 200)
	detail_sprite_container.position = Vector2(20, 40)
	detail_panel.add_child(detail_sprite_container)

	# Create the pixel art sprite (fallback)
	detail_sprite = Sprite2D.new()
	detail_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_sprite.position = Vector2(100, 100)
	detail_sprite.scale = Vector2(5, 5)  # Large display
	detail_sprite.visible = false
	detail_sprite_container.add_child(detail_sprite)

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
	card.custom_minimum_size = UITheme.UNIT_CARD_SIZE

	# Create styled card with rarity-colored border
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

	# Defer setup until the node is ready
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

	# Combat Power
	var cp = PlayerData.calculate_unit_cp(unit_entry)
	var cp_label = Label.new()
	cp_label.text = "CP: " + str(cp)
	cp_label.position = Vector2(0, 152)
	cp_label.size = Vector2(card_width, 20)
	cp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cp_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	cp_label.add_theme_color_override("font_color", UITheme.GOLD)
	card.add_child(cp_label)

	# XP bar
	var max_level = PlayerData.get_max_level(unit_data.star_rating)
	if unit_level < max_level:
		var xp = unit_entry.get("xp", 0)
		var xp_needed = PlayerData.get_xp_for_level(unit_level)
		var xp_ratio = float(xp) / float(xp_needed) if xp_needed > 0 else 0.0

		var xp_bg = ColorRect.new()
		xp_bg.position = Vector2(10, 175)
		xp_bg.size = Vector2(card_width - 20, 8)
		xp_bg.color = UITheme.BG_DARK
		card.add_child(xp_bg)

		var xp_fill = ColorRect.new()
		xp_fill.position = Vector2(10, 175)
		xp_fill.size = Vector2((card_width - 20) * xp_ratio, 8)
		xp_fill.color = UITheme.PRIMARY
		card.add_child(xp_fill)

		var xp_label = Label.new()
		xp_label.text = str(xp) + "/" + str(xp_needed)
		xp_label.position = Vector2(0, 185)
		xp_label.size = Vector2(card_width, 20)
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		xp_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
		xp_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
		card.add_child(xp_label)
	else:
		var max_label = Label.new()
		max_label.text = "MAX LEVEL"
		max_label.position = Vector2(0, 175)
		max_label.size = Vector2(card_width, 25)
		max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		max_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
		max_label.add_theme_color_override("font_color", UITheme.GOLD)
		card.add_child(max_label)

	# Make clickable
	var button = Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_unit_clicked.bind(unit_entry))
	card.add_child(button)

	return card

func _on_unit_clicked(unit_entry: Dictionary):
	AudioManager.play_ui_click()
	current_unit_entry = unit_entry
	var unit_data = unit_entry.unit_data as UnitData
	var imprint_level = unit_entry.get("imprint_level", 0) as int
	var unit_level = unit_entry.get("level", 1) as int
	var max_level = PlayerData.get_max_level(unit_data.star_rating)

	detail_panel.visible = true
	detail_name.text = unit_data.unit_name
	detail_stars.text = "★".repeat(unit_data.star_rating)
	detail_element.text = "Element: " + unit_data.element.capitalize()

	# Update and animate the detail sprite
	_update_detail_sprite(unit_data)

	# Show scaled stats based on level with stat icons
	var stats = PlayerData.get_unit_stats_at_level(unit_data, unit_level, imprint_level)
	detail_stats.text = "HP " + str(stats.max_hp) + "   ATK " + str(stats.attack) + "   DEF " + str(stats.defense) + "   SPD " + str(stats.speed)
	detail_copies.text = "Instance ID: " + unit_entry.instance_id

	# Show CP prominently
	var cp = PlayerData.calculate_unit_cp(unit_entry)
	_update_cp_label(cp)
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

func _update_cp_label(cp: int):
	# Create CP label if it doesn't exist
	if not detail_cp_label:
		detail_cp_label = Label.new()
		detail_cp_label.name = "DetailCPLabel"
		# Position below stars (stars is at y=60-90, so CP at y=90)
		detail_cp_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		detail_cp_label.offset_top = 88
		detail_cp_label.offset_bottom = 118
		detail_cp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_cp_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		detail_cp_label.add_theme_color_override("font_color", UITheme.GOLD)
		detail_panel.add_child(detail_cp_label)

	detail_cp_label.text = "CP: " + str(cp)

func _on_close_detail():
	AudioManager.play_ui_click()
	detail_panel.visible = false
	current_unit_entry = {}
	_stop_idle_animation()

func _on_back():
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")

func _update_detail_sprite(unit_data: UnitData):
	if not detail_sprite_container:
		return

	# Clean up existing AI sprite if any
	if detail_ai_sprite:
		detail_ai_sprite.queue_free()
		detail_ai_sprite = null

	# Check if unit has AI sprites
	if UnitSpriteLoader.has_ai_sprite(unit_data.unit_id):
		# Use AI sprite
		detail_sprite.visible = false
		detail_ai_sprite = UnitSpriteLoader.create_animated_sprite(unit_data.unit_id)
		if detail_ai_sprite:
			detail_ai_sprite.position = Vector2(100, 100)
			detail_ai_sprite.scale = Vector2(4.0, 4.0)  # Larger scale for detail view
			detail_sprite_container.add_child(detail_ai_sprite)
			detail_ai_sprite.play("idle")
			# No need for tween animation - AI sprite has its own idle
			_stop_idle_animation()
			return

	# Fall back to pixel art
	if detail_sprite:
		detail_sprite.visible = true
		detail_sprite.texture = PixelArtGenerator.generate_unit_texture(unit_data)
		# Start idle animation for pixel art
		_start_idle_animation()

func _start_idle_animation():
	_stop_idle_animation()

	if not detail_sprite:
		return

	# Create looping idle animation - gentle bobbing
	idle_animation_tween = create_tween()
	idle_animation_tween.set_loops()

	var base_y = detail_sprite.position.y

	# Bob up and down
	idle_animation_tween.tween_property(detail_sprite, "position:y", base_y - 4, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	idle_animation_tween.tween_property(detail_sprite, "position:y", base_y + 2, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	idle_animation_tween.tween_property(detail_sprite, "position:y", base_y, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _stop_idle_animation():
	if idle_animation_tween:
		idle_animation_tween.kill()
		idle_animation_tween = null

	# Reset sprite position
	if detail_sprite:
		detail_sprite.position.y = 100

func _has_fodder_available(unit_entry: Dictionary) -> bool:
	var unit_data = unit_entry.unit_data as UnitData
	var instance_id = unit_entry.instance_id as String

	for other in PlayerData.get_owned_unit_list():
		if other.instance_id != instance_id and other.unit_data.unit_id == unit_data.unit_id:
			return true
	return false

func _on_imprint_pressed():
	AudioManager.play_ui_click()
	if current_unit_entry.is_empty():
		return

	# Show fodder selection panel
	_populate_fodder_grid()
	imprint_panel.visible = true
	detail_panel.visible = false

func _on_cancel_imprint():
	AudioManager.play_ui_click()
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
	display.position = Vector2(60, 55)
	display.scale = Vector2(0.5, 0.5)
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
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_fodder_selected.bind(instance_id))
	card.add_child(button)

	return card

func _on_fodder_selected(fodder_instance_id: String):
	AudioManager.play_ui_click()
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
	AudioManager.play_ui_click()
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
	AudioManager.play_ui_click()
	confirm_panel.visible = false
	pending_fodder_id = ""
	imprint_panel.visible = true

func _on_level_up_pressed():
	AudioManager.play_ui_click()
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
		currency_label.text = str(PlayerData.gold) + " G  |  " + str(PlayerData.level_materials) + " M  |  " + str(PlayerData.enhancement_stones) + " S  |  " + str(PlayerData.gems) + " D"
		currency_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		currency_label.add_theme_color_override("font_color", UITheme.GOLD)

# --- Cheat Functions ---

func _on_max_level_pressed():
	AudioManager.play_ui_click()
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
	AudioManager.play_ui_click()
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

	# Slot names with type icons for better visual clarity
	var slot_icons = ["[W]", "[A]", "[+]", "[+]"]  # Weapon, Armor, Accessory
	var slot_names = ["Weapon", "Armor", "Acc 1", "Acc 2"]
	var slot_keys = ["weapon", "armor", "accessory_1", "accessory_2"]

	for i in range(4):
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(120, 50)

		var gear_id = equipped_gear.get(slot_keys[i], "")
		var icon = slot_icons[i]
		if gear_id != "":
			var gear_entry = PlayerData.get_gear_by_instance_id(gear_id)
			if not gear_entry.is_empty():
				var template = PlayerData.get_gear_template(gear_entry.gear_id)
				if template:
					slot_btn.text = icon + " " + template.gear_name + "\n+" + str(gear_entry.get("level", 0))
					slot_btn.modulate = template.get_rarity_color()
				else:
					slot_btn.text = icon + " " + slot_names[i] + "\n[Unknown]"
			else:
				slot_btn.text = icon + " " + slot_names[i] + "\n[Empty]"
		else:
			slot_btn.text = icon + " " + slot_names[i] + "\n[Empty]"

		slot_btn.pressed.connect(_on_gear_slot_clicked.bind(i))
		gear_slots_container.add_child(slot_btn)

func _on_gear_slot_clicked(slot_index: int):
	AudioManager.play_ui_click()
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
		var gear_data = gear_entry.gear_data as GearData
		if not gear_data:
			continue
		var template = gear_data
		if template and template.gear_type == slot_type:
			var gear_btn = _create_gear_select_button(gear_entry)
			gear_select_grid.add_child(gear_btn)

func _create_gear_select_button(gear_entry: Dictionary) -> Button:
	var template = gear_entry.gear_data as GearData

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
	AudioManager.play_ui_click()
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

	# Rebuild grid to update CP on cards
	_populate_collection()

func _on_cancel_gear_select():
	AudioManager.play_ui_click()
	if gear_select_panel:
		gear_select_panel.visible = false
	detail_panel.visible = true
	current_gear_slot = -1

# === THEME FUNCTIONS ===

func _apply_theme():
	# Background - use ruins theme image
	UISpriteLoader.apply_background_to_scene(self, UISpriteLoader.BackgroundTheme.RUINS, UISpriteLoader.BackgroundVariant.BRIGHT, 0.4)
	# Hide the old solid color background if it exists
	var bg = get_node_or_null("Background")
	if bg:
		bg.visible = false

	# Top bar
	var top_bar = get_node_or_null("TopBar")
	if top_bar:
		# Style top bar background
		var top_style = StyleBoxFlat.new()
		top_style.bg_color = UITheme.BG_MEDIUM
		top_style.border_color = UITheme.BG_LIGHT
		top_style.border_width_bottom = 2
		top_style.content_margin_left = UITheme.SPACING_MD
		top_style.content_margin_right = UITheme.SPACING_MD
		top_style.content_margin_top = UITheme.SPACING_SM
		top_style.content_margin_bottom = UITheme.SPACING_SM
		# Create a Panel as parent for TopBar if needed

	# Title
	var title = get_node_or_null("TopBar/Title")
	if title:
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Back button with sprite styling
	var back_btn_node = get_node_or_null("TopBar/BackButton")
	if back_btn_node:
		UISpriteLoader.apply_button_style(back_btn_node, UISpriteLoader.ButtonColor.PURPLE, "ButtonA")
		back_btn_node.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Unit count label
	var count_label = get_node_or_null("TopBar/UnitCountLabel")
	if count_label:
		count_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		count_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Style detail panel with sprite styling
	if detail_panel and detail_panel is Panel:
		UISpriteLoader.apply_panel_style(detail_panel, UISpriteLoader.PanelColor.BLUE, "Panel")

	# Detail panel background
	var detail_bg = get_node_or_null("DetailPanel/DetailBackground")
	if detail_bg:
		detail_bg.color = UITheme.BG_MEDIUM

	# Style labels in detail panel
	_style_detail_panel_labels()

	# Style action buttons
	_style_action_buttons()

	# Style imprint panel
	_style_imprint_panel()

	# Style confirm panel
	_style_confirm_panel()

	# Style gear select panel
	_style_gear_select_panel()

func _style_detail_panel_labels():
	if not detail_panel:
		return

	# Unit name label
	if detail_name:
		detail_name.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		detail_name.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Stars label
	if detail_stars:
		detail_stars.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		detail_stars.add_theme_color_override("font_color", UITheme.GOLD)

	# Element label
	if detail_element:
		detail_element.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Stats label
	if detail_stats:
		detail_stats.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		detail_stats.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Copies label
	if detail_copies:
		detail_copies.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		detail_copies.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Imprint label
	if detail_imprint:
		detail_imprint.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		detail_imprint.add_theme_color_override("font_color", UITheme.SUCCESS)

	# Level label
	if detail_level:
		detail_level.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		detail_level.add_theme_color_override("font_color", UITheme.PRIMARY)

	# Level cost label
	if level_cost_label:
		level_cost_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)

	# Gear label
	var gear_label = get_node_or_null("DetailPanel/GearLabel")
	if gear_label:
		gear_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		gear_label.add_theme_color_override("font_color", UITheme.GOLD)

func _style_action_buttons():
	# Level up button (blue primary)
	if level_up_btn:
		UISpriteLoader.apply_button_style(level_up_btn, UISpriteLoader.ButtonColor.BLUE, "ButtonA")
		level_up_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		level_up_btn.add_theme_color_override("font_disabled_color", UITheme.TEXT_DISABLED)

	# Imprint button (purple secondary)
	if imprint_btn:
		UISpriteLoader.apply_button_style(imprint_btn, UISpriteLoader.ButtonColor.PURPLE, "ButtonA")
		imprint_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		imprint_btn.add_theme_color_override("font_disabled_color", UITheme.TEXT_DISABLED)

	# Close button (white/light)
	if close_detail_btn:
		UISpriteLoader.apply_button_style(close_detail_btn, UISpriteLoader.ButtonColor.WHITE, "ButtonA")
		close_detail_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Cheat buttons (red danger)
	if max_level_btn:
		UISpriteLoader.apply_button_style(max_level_btn, UISpriteLoader.ButtonColor.RED, "ButtonA")
		max_level_btn.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)

	if reset_level_btn:
		UISpriteLoader.apply_button_style(reset_level_btn, UISpriteLoader.ButtonColor.RED, "ButtonA")
		reset_level_btn.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)

	# Cheat label
	var cheat_label = get_node_or_null("DetailPanel/CheatButtons/CheatLabel")
	if cheat_label:
		cheat_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
		cheat_label.add_theme_color_override("font_color", UITheme.DANGER.darkened(0.3))

func _style_imprint_panel():
	if not imprint_panel:
		return

	# Use sprite panel (purple for imprint)
	UISpriteLoader.apply_panel_style(imprint_panel, UISpriteLoader.PanelColor.PURPLE, "Panel")

	var imprint_bg = get_node_or_null("ImprintPanel/ImprintBackground")
	if imprint_bg:
		imprint_bg.color = UITheme.BG_MEDIUM

	var imprint_title = get_node_or_null("ImprintPanel/ImprintTitle")
	if imprint_title:
		imprint_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		imprint_title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	var imprint_info = get_node_or_null("ImprintPanel/ImprintInfo")
	if imprint_info:
		imprint_info.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		imprint_info.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	if cancel_imprint_btn:
		UISpriteLoader.apply_button_style(cancel_imprint_btn, UISpriteLoader.ButtonColor.WHITE, "ButtonA")
		cancel_imprint_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

func _style_confirm_panel():
	if not confirm_panel:
		return

	# Use sprite panel (red for danger/confirm)
	UISpriteLoader.apply_panel_style(confirm_panel, UISpriteLoader.PanelColor.RED, "Panel")

	var confirm_bg = get_node_or_null("ConfirmPanel/ConfirmBackground")
	if confirm_bg:
		confirm_bg.color = UITheme.BG_MEDIUM

	var confirm_title = get_node_or_null("ConfirmPanel/ConfirmTitle")
	if confirm_title:
		confirm_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		confirm_title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	if confirm_message:
		confirm_message.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		confirm_message.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	var warning_label = get_node_or_null("ConfirmPanel/WarningLabel")
	if warning_label:
		warning_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		warning_label.add_theme_color_override("font_color", UITheme.DANGER)

	if confirm_btn:
		UISpriteLoader.apply_button_style(confirm_btn, UISpriteLoader.ButtonColor.RED, "ButtonA")
		confirm_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	if cancel_confirm_btn:
		UISpriteLoader.apply_button_style(cancel_confirm_btn, UISpriteLoader.ButtonColor.WHITE, "ButtonA")
		cancel_confirm_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

func _style_gear_select_panel():
	if not gear_select_panel:
		return

	# Use sprite panel (gold for gear)
	UISpriteLoader.apply_panel_style(gear_select_panel, UISpriteLoader.PanelColor.GOLD, "Panel")

	var gear_bg = get_node_or_null("GearSelectPanel/GearSelectBackground")
	if gear_bg:
		gear_bg.color = UITheme.BG_MEDIUM

	var gear_title = get_node_or_null("GearSelectPanel/GearSelectTitle")
	if gear_title:
		gear_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		gear_title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	if cancel_gear_btn:
		UISpriteLoader.apply_button_style(cancel_gear_btn, UISpriteLoader.ButtonColor.WHITE, "ButtonA")
		cancel_gear_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
