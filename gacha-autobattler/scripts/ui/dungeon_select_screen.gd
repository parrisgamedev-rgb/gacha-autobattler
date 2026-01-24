extends Control
## Dungeon selection screen for gear farming with new design system

var CurrencyBarScene = preload("res://scenes/ui/currency_bar.tscn")

@onready var back_btn = $TopBar/BackButton
@onready var dungeons_container = $DungeonsGrid
@onready var dungeon_info_panel = $DungeonInfoPanel
@onready var dungeon_name_label = $DungeonInfoPanel/VBox/DungeonNameLabel
@onready var enemy_level_label = $DungeonInfoPanel/VBox/EnemyLevelLabel
@onready var rewards_label = $DungeonInfoPanel/VBox/RewardsLabel
@onready var difficulty_container = $DungeonInfoPanel/VBox/DifficultyContainer
@onready var start_button = $DungeonInfoPanel/VBox/StartButton
@onready var stones_label = $TopBar/CurrencyContainer/StonesLabel

# Loaded dungeons
var dungeons: Array = []
var selected_dungeon = null
var selected_tier: int = 0

func _ready():
	# Add currency bar to top bar
	var currency_bar = CurrencyBarScene.instantiate()
	var top_bar = get_node_or_null("TopBar")
	if top_bar:
		top_bar.add_child(currency_bar)

	back_btn.pressed.connect(_on_back)
	start_button.pressed.connect(_on_start_dungeon)

	# Connect difficulty buttons
	var easy_btn = difficulty_container.get_node_or_null("EasyButton")
	var normal_btn = difficulty_container.get_node_or_null("NormalButton")
	var hard_btn = difficulty_container.get_node_or_null("HardButton")
	if easy_btn: easy_btn.pressed.connect(_on_difficulty_selected.bind(0))
	if normal_btn: normal_btn.pressed.connect(_on_difficulty_selected.bind(1))
	if hard_btn: hard_btn.pressed.connect(_on_difficulty_selected.bind(2))

	# Hide info panel initially
	dungeon_info_panel.visible = false

	_load_all_dungeons()
	_apply_theme()
	_build_dungeon_ui()
	_update_stones_display()

func _apply_theme():
	# Apply themed background
	UISpriteLoader.apply_background_to_scene(self, UISpriteLoader.BackgroundTheme.RUINS, UISpriteLoader.BackgroundVariant.PALE, 0.4)
	# Hide the old solid color background if it exists
	var bg = get_node_or_null("Background")
	if bg:
		bg.visible = false

	# Top bar - use sprite panel
	var top_bar = get_node_or_null("TopBar")
	if top_bar and top_bar is Panel:
		UISpriteLoader.apply_panel_style(top_bar, UISpriteLoader.PanelColor.BLACK, "Panel")

	# Title
	var title = get_node_or_null("TopBar/Title")
	if title:
		title.text = "DUNGEONS"
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Back button - use sprite button
	if back_btn:
		UISpriteLoader.apply_button_style(back_btn, UISpriteLoader.ButtonColor.PURPLE, "ButtonA")

	# Difficulty section label
	var diff_label = get_node_or_null("DungeonInfoPanel/VBox/DifficultyLabel")
	if diff_label:
		diff_label.text = "SELECT DIFFICULTY"
		diff_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		diff_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Info panel - use sprite panel
	if dungeon_info_panel and dungeon_info_panel is Panel:
		UISpriteLoader.apply_panel_style(dungeon_info_panel, UISpriteLoader.PanelColor.BLUE, "Panel")

	# Currency display
	_style_currency_display()

	# Style info panel labels
	_style_info_panel()

func _style_currency_display():
	var currency_container = get_node_or_null("TopBar/CurrencyContainer")
	if currency_container and currency_container is Panel:
		var style = StyleBoxFlat.new()
		style.bg_color = UITheme.BG_LIGHT
		style.corner_radius_top_left = UITheme.BUTTON_RADIUS
		style.corner_radius_top_right = UITheme.BUTTON_RADIUS
		style.corner_radius_bottom_left = UITheme.BUTTON_RADIUS
		style.corner_radius_bottom_right = UITheme.BUTTON_RADIUS
		style.content_margin_left = UITheme.SPACING_MD
		style.content_margin_right = UITheme.SPACING_MD
		style.content_margin_top = UITheme.SPACING_SM
		style.content_margin_bottom = UITheme.SPACING_SM
		currency_container.add_theme_stylebox_override("panel", style)

	if stones_label:
		stones_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		stones_label.add_theme_color_override("font_color", UITheme.GOLD)

func _style_info_panel():
	if not dungeon_info_panel:
		return

	# Info title
	var info_title = dungeon_info_panel.get_node_or_null("VBox/InfoTitle")
	if info_title:
		info_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		info_title.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Dungeon name in info
	if dungeon_name_label:
		dungeon_name_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		dungeon_name_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Enemy level
	if enemy_level_label:
		enemy_level_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		enemy_level_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Rewards label
	if rewards_label:
		rewards_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		rewards_label.add_theme_color_override("font_color", UITheme.GOLD)

	# Difficulty label
	var diff_label = dungeon_info_panel.get_node_or_null("VBox/DifficultyLabel")
	if diff_label:
		diff_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		diff_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Start button - use sprite button
	if start_button:
		UISpriteLoader.apply_button_style(start_button, UISpriteLoader.ButtonColor.BLUE, "ButtonA")

func _style_difficulty_buttons():
	if not difficulty_container:
		return

	var buttons = []
	var easy_btn = difficulty_container.get_node_or_null("EasyButton")
	var normal_btn = difficulty_container.get_node_or_null("NormalButton")
	var hard_btn = difficulty_container.get_node_or_null("HardButton")

	if easy_btn: buttons.append({"btn": easy_btn, "tier": 0})
	if normal_btn: buttons.append({"btn": normal_btn, "tier": 1})
	if hard_btn: buttons.append({"btn": hard_btn, "tier": 2})

	for item in buttons:
		var btn = item.btn
		# Use sprite-based buttons for difficulty selection
		if selected_tier == item.tier:
			UISpriteLoader.apply_button_style(btn, UISpriteLoader.ButtonColor.GOLD, "ButtonA")
		else:
			UISpriteLoader.apply_button_style(btn, UISpriteLoader.ButtonColor.WHITE, "ButtonA")

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

	# Build card for each dungeon
	for dungeon in dungeons:
		var dungeon_card = _create_dungeon_card(dungeon)
		dungeons_container.add_child(dungeon_card)

func _get_stat_color(stat_type: int) -> Color:
	match stat_type:
		GearData.StatType.ATTACK: return UITheme.DANGER  # Red for ATK
		GearData.StatType.DEFENSE: return UITheme.PRIMARY  # Blue for DEF
		GearData.StatType.HP: return UITheme.SUCCESS  # Green for HP
		GearData.StatType.SPEED: return UITheme.SECONDARY  # Purple for SPD
	return UITheme.TEXT_SECONDARY

func _get_stat_name(stat_type: int) -> String:
	match stat_type:
		GearData.StatType.ATTACK: return "ATK"
		GearData.StatType.DEFENSE: return "DEF"
		GearData.StatType.HP: return "HP"
		GearData.StatType.SPEED: return "SPD"
	return "???"

func _create_dungeon_card(dungeon) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(200, 180)

	var stat_color = _get_stat_color(dungeon.drops_stat_type)

	# Create card style with stat-colored border
	var style = StyleBoxFlat.new()
	style.bg_color = UITheme.BG_MEDIUM
	style.border_color = stat_color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = UITheme.CARD_RADIUS
	style.corner_radius_top_right = UITheme.CARD_RADIUS
	style.corner_radius_bottom_left = UITheme.CARD_RADIUS
	style.corner_radius_bottom_right = UITheme.CARD_RADIUS
	card.add_theme_stylebox_override("panel", style)

	# Card content container
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", UITheme.SPACING_MD)
	margin.add_theme_constant_override("margin_right", UITheme.SPACING_MD)
	margin.add_theme_constant_override("margin_top", UITheme.SPACING_MD)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACING_MD)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SPACING_SM)
	margin.add_child(vbox)

	# Dungeon name with stat color
	var name_label = Label.new()
	name_label.text = dungeon.dungeon_name
	name_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
	name_label.add_theme_color_override("font_color", stat_color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Stat type icon
	var stat_icon = Label.new()
	stat_icon.text = "[" + _get_stat_name(dungeon.drops_stat_type) + "]"
	stat_icon.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
	stat_icon.add_theme_color_override("font_color", stat_color)
	stat_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stat_icon)

	# Drops label
	var drops_label = Label.new()
	drops_label.text = "Drops: " + _get_stat_name(dungeon.drops_stat_type) + " Gear"
	drops_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	drops_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	drops_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(drops_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Select button
	var select_btn = Button.new()
	select_btn.text = "SELECT"
	select_btn.custom_minimum_size = Vector2(0, 40)
	select_btn.add_theme_stylebox_override("normal", UITheme.create_button_style(stat_color.darkened(0.3)))
	select_btn.add_theme_stylebox_override("hover", UITheme.create_button_style(stat_color.darkened(0.2)))
	select_btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(stat_color.darkened(0.4)))
	select_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	select_btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	select_btn.pressed.connect(_on_dungeon_selected.bind(dungeon))
	vbox.add_child(select_btn)

	return card

func _on_dungeon_selected(dungeon):
	AudioManager.play_ui_click()
	selected_dungeon = dungeon
	selected_tier = 0  # Reset to easy
	_update_dungeon_info_panel()
	_style_difficulty_buttons()

func _update_dungeon_info_panel():
	if selected_dungeon == null:
		dungeon_info_panel.visible = false
		return

	dungeon_info_panel.visible = true

	# Update name with stat color
	var stat_color = _get_stat_color(selected_dungeon.drops_stat_type)
	dungeon_name_label.text = selected_dungeon.dungeon_name
	dungeon_name_label.add_theme_color_override("font_color", stat_color)

	# Update enemy level based on selected tier
	var enemy_level = selected_dungeon.tier_enemy_levels[selected_tier]
	enemy_level_label.text = "Enemy Level: " + str(enemy_level)

	# Update rewards
	var stone_range = selected_dungeon.get_stone_drop_range(selected_tier)
	rewards_label.text = "Rewards: " + _get_stat_name(selected_dungeon.drops_stat_type) + " Gear + " + str(stone_range[0]) + "-" + str(stone_range[1]) + " Stones"

	# Update difficulty button labels if they exist
	_update_difficulty_button_labels()

func _update_difficulty_button_labels():
	if not difficulty_container or not selected_dungeon:
		return

	var easy_btn = difficulty_container.get_node_or_null("EasyButton")
	var normal_btn = difficulty_container.get_node_or_null("NormalButton")
	var hard_btn = difficulty_container.get_node_or_null("HardButton")

	if easy_btn and selected_dungeon.tier_names.size() > 0:
		easy_btn.text = selected_dungeon.tier_names[0]
	if normal_btn and selected_dungeon.tier_names.size() > 1:
		normal_btn.text = selected_dungeon.tier_names[1]
	if hard_btn and selected_dungeon.tier_names.size() > 2:
		hard_btn.text = selected_dungeon.tier_names[2]

func _on_difficulty_selected(tier: int):
	AudioManager.play_ui_click()
	selected_tier = tier
	_style_difficulty_buttons()
	_update_dungeon_info_panel()

func _on_start_dungeon():
	AudioManager.play_ui_click()
	if selected_dungeon == null:
		return

	# Start dungeon in PlayerData
	PlayerData.start_dungeon(selected_dungeon, selected_tier)

	# Go to team select
	SceneTransition.change_scene("res://scenes/ui/team_select_screen.tscn")

func _update_stones_display():
	if stones_label:
		stones_label.text = str(PlayerData.enhancement_stones) + " Stones"

func _on_back():
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")
