extends Control
## Gear inventory management screen

var CurrencyBarScene = preload("res://scenes/ui/currency_bar.tscn")

@onready var back_btn = $TopBar/HBox/BackButton
@onready var currency_label = $TopBar/HBox/CurrencyLabel
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
	# Add currency bar to top bar
	var currency_bar = CurrencyBarScene.instantiate()
	var top_bar = get_node_or_null("TopBar/HBox")
	if top_bar:
		top_bar.add_child(currency_bar)

	back_btn.pressed.connect(_on_back)
	enhance_btn.pressed.connect(_on_enhance)
	close_btn.pressed.connect(_on_close_detail)

	filter_all_btn.pressed.connect(_set_filter.bind(-1))
	filter_weapon_btn.pressed.connect(_set_filter.bind(0))
	filter_armor_btn.pressed.connect(_set_filter.bind(1))
	filter_accessory_btn.pressed.connect(_set_filter.bind(2))

	detail_panel.visible = false

	_apply_theme()
	_update_currency_display()
	_build_gear_grid()

func _set_filter(filter_type: int):
	AudioManager.play_ui_click()
	current_filter = filter_type
	_build_gear_grid()
	_update_filter_tab_styles()

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
	card.custom_minimum_size = Vector2(130, 170)

	# Use sprite-based panel styling based on rarity
	var panel_color = _get_panel_color_for_rarity(template.rarity)
	UISpriteLoader.apply_panel_style(card, panel_color, "Card")

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", UITheme.SPACING_XS)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", UITheme.SPACING_SM)
	margin.add_theme_constant_override("margin_right", UITheme.SPACING_SM)
	margin.add_theme_constant_override("margin_top", UITheme.SPACING_SM)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACING_SM)
	margin.add_child(vbox)
	card.add_child(margin)

	# Star rating for rarity at the top
	var star_display = UISpriteLoader.create_star_display(template.rarity + 1, 5, UISpriteLoader.StarColor.GOLD)
	if star_display:
		star_display.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(star_display)

	# Gear name
	var name_label = Label.new()
	name_label.text = template.gear_name
	name_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	name_label.add_theme_color_override("font_color", template.get_rarity_color())
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 1)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	# Type icon + text
	var type_label = Label.new()
	var type_icon = _get_gear_type_icon(template.gear_type)
	type_label.text = type_icon + " " + template.get_type_name()
	type_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	vbox.add_child(type_label)

	# Stat value with color coding
	var stat_value = template.get_stat_at_level(gear_entry.level)
	var stat_text = template.get_stat_name() + ": "
	if template.is_percentage:
		stat_text += "+" + str(snapped(stat_value, 0.1)) + "%"
	else:
		stat_text += "+" + str(int(stat_value))
	var stat_label = Label.new()
	stat_label.text = stat_text
	stat_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.add_theme_color_override("font_color", UITheme.SUCCESS)
	stat_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stat_label.add_theme_constant_override("outline_size", 1)
	vbox.add_child(stat_label)

	# Level display
	var level_label = Label.new()
	level_label.text = "+" + str(gear_entry.level) + "/" + str(template.get_max_level())
	level_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	level_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_label)

	# Equipped status with gold styling
	var equipped_unit = PlayerData.get_gear_equipped_unit(gear_entry.instance_id)
	if equipped_unit != "":
		var eq_label = Label.new()
		eq_label.text = "EQUIPPED"
		eq_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
		eq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		eq_label.add_theme_color_override("font_color", UITheme.GOLD)
		eq_label.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.0))
		eq_label.add_theme_constant_override("outline_size", 1)
		vbox.add_child(eq_label)

	# Make it clickable
	var btn = Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0)  # Invisible but clickable
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_on_gear_selected.bind(gear_entry.instance_id))
	card.add_child(btn)

	return card


func _get_panel_color_for_rarity(rarity: int) -> int:
	"""Get the panel color based on gear rarity."""
	match rarity:
		0:  # Common
			return UISpriteLoader.PanelColor.WHITE
		1:  # Uncommon
			return UISpriteLoader.PanelColor.BLUE
		2:  # Rare
			return UISpriteLoader.PanelColor.PURPLE
		3:  # Epic
			return UISpriteLoader.PanelColor.GOLD
		_:
			return UISpriteLoader.PanelColor.WHITE


func _get_gear_type_icon(gear_type: int) -> String:
	"""Get an icon character for gear type."""
	match gear_type:
		0:  # Weapon
			return "[W]"
		1:  # Armor
			return "[A]"
		2:  # Accessory
			return "[R]"
		_:
			return "[?]"

func _on_gear_selected(instance_id: String):
	AudioManager.play_ui_click()
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
	AudioManager.play_ui_click()
	if selected_gear_instance_id == "":
		return

	var success = PlayerData.enhance_gear(selected_gear_instance_id)
	if success:
		_update_detail_panel()
		_update_currency_display()
		_build_gear_grid()

func _on_close_detail():
	AudioManager.play_ui_click()
	detail_panel.visible = false
	selected_gear_instance_id = ""

func _update_currency_display():
	currency_label.text = str(PlayerData.gold) + " Gold | " + str(PlayerData.enhancement_stones) + " Stones"
	currency_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	currency_label.add_theme_color_override("font_color", UITheme.GOLD)

func _on_back():
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")

func _apply_theme():
	# Background - use ruins theme for treasure hunting vibe
	UISpriteLoader.apply_background_to_scene(self, UISpriteLoader.BackgroundTheme.RUINS, UISpriteLoader.BackgroundVariant.PALE, 0.45)
	# Hide the old solid color background if it exists
	var bg = get_node_or_null("Background")
	if bg:
		bg.visible = false

	# Top bar
	var top_bar = get_node_or_null("TopBar")
	if top_bar and top_bar is Panel:
		top_bar.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))

	# Title
	var title = get_node_or_null("TopBar/HBox/Title")
	if title:
		title.text = "GEAR"
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Back button with sprite styling
	if back_btn:
		UISpriteLoader.apply_button_style(back_btn, UISpriteLoader.ButtonColor.PURPLE, "ButtonA")
		back_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Filter label
	var filter_label = get_node_or_null("FilterBar/FilterLabel")
	if filter_label:
		filter_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		filter_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Filter tabs
	_style_filter_tabs()
	_update_filter_tab_styles()

	# Detail panel with gold sprite panel (gear = treasure)
	if detail_panel and detail_panel is Panel:
		UISpriteLoader.apply_panel_style(detail_panel, UISpriteLoader.PanelColor.GOLD, "Panel")

	# Style detail panel content
	_style_detail_panel()

func _style_filter_tabs():
	var tabs = [filter_all_btn, filter_weapon_btn, filter_armor_btn, filter_accessory_btn]
	var tab_labels = ["ALL", "WEAPON", "ARMOR", "ACCESSORY"]

	for i in range(tabs.size()):
		var tab = tabs[i]
		if tab:
			tab.text = tab_labels[i]
			tab.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)

func _update_filter_tab_styles():
	var tabs = [filter_all_btn, filter_weapon_btn, filter_armor_btn, filter_accessory_btn]
	var filter_values = [-1, 0, 1, 2]

	for i in range(tabs.size()):
		var tab = tabs[i]
		if tab:
			if current_filter == filter_values[i]:
				# Active filter - gold sprite button
				UISpriteLoader.apply_button_style(tab, UISpriteLoader.ButtonColor.GOLD, "ButtonA")
			else:
				# Inactive filter - white sprite button
				UISpriteLoader.apply_button_style(tab, UISpriteLoader.ButtonColor.WHITE, "ButtonA")

func _style_detail_panel():
	# Gear name label
	if gear_name_label:
		gear_name_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)

	# Type label
	if gear_type_label:
		gear_type_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		gear_type_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Stat label
	if gear_stat_label:
		gear_stat_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		gear_stat_label.add_theme_color_override("font_color", UITheme.SUCCESS)

	# Level label
	if gear_level_label:
		gear_level_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		gear_level_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Cost label
	if enhance_cost_label:
		enhance_cost_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		enhance_cost_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Equipped label
	if equipped_label:
		equipped_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		equipped_label.add_theme_color_override("font_color", UITheme.GOLD)

	# Enhance button with sprite styling (blue primary)
	if enhance_btn:
		UISpriteLoader.apply_button_style(enhance_btn, UISpriteLoader.ButtonColor.BLUE, "ButtonA")
		enhance_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		enhance_btn.add_theme_color_override("font_disabled_color", UITheme.TEXT_DISABLED)

	# Close button with sprite styling (white/light)
	if close_btn:
		UISpriteLoader.apply_button_style(close_btn, UISpriteLoader.ButtonColor.WHITE, "ButtonA")
		close_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
