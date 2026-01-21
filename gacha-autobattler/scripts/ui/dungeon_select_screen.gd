extends Control
## Dungeon selection screen for gear farming

@onready var back_btn = $TopBar/BackButton
@onready var dungeons_container = $ScrollContainer/DungeonsContainer
@onready var dungeon_info_panel = $DungeonInfoPanel
@onready var dungeon_name_label = $DungeonInfoPanel/VBox/DungeonNameLabel
@onready var dungeon_desc_label = $DungeonInfoPanel/VBox/DescriptionLabel
@onready var dungeon_drops_label = $DungeonInfoPanel/VBox/DropsLabel
@onready var tier_buttons_container = $DungeonInfoPanel/VBox/TierButtons
@onready var stones_label = $TopBar/StonesLabel

# Loaded dungeons
var dungeons: Array = []
var selected_dungeon = null

func _ready():
	back_btn.pressed.connect(_on_back)

	# Hide info panel initially
	dungeon_info_panel.visible = false

	_load_all_dungeons()
	_build_dungeon_ui()
	_update_stones_display()

func _load_all_dungeons():
	var dungeon_files = [
		"res://resources/dungeons/power_sanctum.tres",
		"res://resources/dungeons/fortress_ruins.tres",
		"res://resources/dungeons/vitality_caves.tres",
		"res://resources/dungeons/wind_temple.tres"
	]

	for path in dungeon_files:
		if ResourceLoader.exists(path):
			var dungeon = load(path)
			if dungeon:
				dungeons.append(dungeon)

	print("Loaded ", dungeons.size(), " dungeons")

func _build_dungeon_ui():
	# Clear existing
	for child in dungeons_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	# Build button for each dungeon
	for dungeon in dungeons:
		var dungeon_card = _create_dungeon_card(dungeon)
		dungeons_container.add_child(dungeon_card)

func _create_dungeon_card(dungeon) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(280, 200)

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = _get_dungeon_color(dungeon.drops_stat_type)
	card_style.corner_radius_top_left = 10
	card_style.corner_radius_top_right = 10
	card_style.corner_radius_bottom_left = 10
	card_style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", card_style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	margin.add_child(vbox)
	card.add_child(margin)

	# Dungeon name
	var name_label = Label.new()
	name_label.text = dungeon.dungeon_name
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Stat type icon
	var stat_label = Label.new()
	stat_label.text = _get_stat_icon(dungeon.drops_stat_type)
	stat_label.add_theme_font_size_override("font_size", 36)
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stat_label)

	# Drops description
	var drops_label = Label.new()
	drops_label.text = "Drops: " + _get_stat_name(dungeon.drops_stat_type) + " Gear"
	drops_label.add_theme_font_size_override("font_size", 16)
	drops_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drops_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
	vbox.add_child(drops_label)

	# Select button
	var select_btn = Button.new()
	select_btn.text = "SELECT"
	select_btn.custom_minimum_size = Vector2(0, 45)
	select_btn.pressed.connect(_on_dungeon_selected.bind(dungeon))
	vbox.add_child(select_btn)

	return card

func _get_dungeon_color(stat_type: int) -> Color:
	match stat_type:
		GearData.StatType.ATTACK: return Color(0.35, 0.15, 0.15, 1)  # Red tint
		GearData.StatType.DEFENSE: return Color(0.15, 0.2, 0.35, 1)  # Blue tint
		GearData.StatType.HP: return Color(0.15, 0.3, 0.15, 1)  # Green tint
		GearData.StatType.SPEED: return Color(0.3, 0.25, 0.15, 1)  # Yellow tint
	return Color(0.15, 0.15, 0.2, 1)

func _get_stat_icon(stat_type: int) -> String:
	match stat_type:
		GearData.StatType.ATTACK: return "[ATK]"
		GearData.StatType.DEFENSE: return "[DEF]"
		GearData.StatType.HP: return "[HP]"
		GearData.StatType.SPEED: return "[SPD]"
	return "???"

func _get_stat_name(stat_type: int) -> String:
	match stat_type:
		GearData.StatType.ATTACK: return "ATK"
		GearData.StatType.DEFENSE: return "DEF"
		GearData.StatType.HP: return "HP"
		GearData.StatType.SPEED: return "SPD"
	return "???"

func _on_dungeon_selected(dungeon):
	selected_dungeon = dungeon
	_update_dungeon_info_panel()

func _update_dungeon_info_panel():
	if selected_dungeon == null:
		dungeon_info_panel.visible = false
		return

	dungeon_info_panel.visible = true

	dungeon_name_label.text = selected_dungeon.dungeon_name
	dungeon_desc_label.text = selected_dungeon.description
	dungeon_drops_label.text = "Drops: " + _get_stat_name(selected_dungeon.drops_stat_type) + " gear + Enhancement Stones"

	# Clear and rebuild tier buttons
	for child in tier_buttons_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	for i in range(selected_dungeon.tier_names.size()):
		var tier_btn = _create_tier_button(i)
		tier_buttons_container.add_child(tier_btn)

func _create_tier_button(tier_index: int) -> Button:
	var tier_name = selected_dungeon.tier_names[tier_index]
	var enemy_level = selected_dungeon.tier_enemy_levels[tier_index]
	var stone_range = selected_dungeon.get_stone_drop_range(tier_index)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 60)
	btn.text = tier_name + " (Lv." + str(enemy_level) + ")\nStones: " + str(stone_range[0]) + "-" + str(stone_range[1])
	btn.pressed.connect(_on_tier_selected.bind(tier_index))

	# Color code difficulty
	match tier_index:
		0: btn.modulate = Color(0.7, 1.0, 0.7)  # Green - Easy
		1: btn.modulate = Color(1.0, 1.0, 0.7)  # Yellow - Normal
		2: btn.modulate = Color(1.0, 0.7, 0.7)  # Red - Hard

	return btn

func _on_tier_selected(tier_index: int):
	if selected_dungeon == null:
		return

	# Start dungeon in PlayerData
	PlayerData.start_dungeon(selected_dungeon, tier_index)

	# Go to team select
	get_tree().change_scene_to_file("res://scenes/ui/team_select_screen.tscn")

func _update_stones_display():
	stones_label.text = str(PlayerData.enhancement_stones) + " Stones"

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
