extends Control
## Main menu screen with new design system

# Primary buttons
@onready var campaign_button = $CenterContainer/VBoxContainer/PrimaryButtons/CampaignButton
@onready var dungeons_button = $CenterContainer/VBoxContainer/PrimaryButtons/DungeonsButton
@onready var quick_battle_button = $CenterContainer/VBoxContainer/PrimaryButtons/QuickBattleButton

# Secondary buttons
@onready var summon_button = $CenterContainer/VBoxContainer/SecondaryButtons/SummonButton
@onready var collection_button = $CenterContainer/VBoxContainer/SecondaryButtons/CollectionButton
@onready var gear_button = $CenterContainer/VBoxContainer/SecondaryButtons/GearButton
@onready var pvp_button = $CenterContainer/VBoxContainer/SecondaryButtons/PvPButton
@onready var how_to_play_button = $CenterContainer/VBoxContainer/SecondaryButtons/HowToPlayButton

# Currency labels
@onready var gold_label = $CurrencyBar/GoldLabel
@onready var materials_label = $CurrencyBar/MaterialsLabel
@onready var gems_label = $CurrencyBar/GemsLabel
@onready var stones_label = $CurrencyBar/StonesLabel

func _ready():
	# Reset PvP mode and campaign mode when returning to main menu
	PlayerData.pvp_mode = false
	PlayerData.end_campaign_stage()
	PlayerData.end_dungeon()

	# Apply theme styling
	_apply_theme()

	# Connect primary button signals
	if campaign_button:
		campaign_button.pressed.connect(_on_campaign_pressed)
		campaign_button.grab_focus()

	if dungeons_button:
		dungeons_button.pressed.connect(_on_dungeons_pressed)

	if quick_battle_button:
		quick_battle_button.pressed.connect(_on_quick_battle_pressed)

	# Connect secondary button signals
	if summon_button:
		summon_button.pressed.connect(_on_summon_pressed)

	if collection_button:
		collection_button.pressed.connect(_on_collection_pressed)

	if gear_button:
		gear_button.pressed.connect(_on_gear_pressed)

	if pvp_button:
		pvp_button.pressed.connect(_on_pvp_pressed)

	if how_to_play_button:
		how_to_play_button.pressed.connect(_on_how_to_play_pressed)

	# Update currency display
	_update_currency_display()

	# Connect to PlayerData currency changes if available
	if PlayerData.has_signal("currency_changed"):
		PlayerData.currency_changed.connect(_update_currency_display)


func _apply_theme():
	# Background
	if has_node("Background"):
		$Background.color = UITheme.BG_DARK

	# Title styling
	if has_node("CenterContainer/VBoxContainer/TitleLabel"):
		var title = $CenterContainer/VBoxContainer/TitleLabel
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Version label
	if has_node("CenterContainer/VBoxContainer/VersionLabel"):
		var version = $CenterContainer/VBoxContainer/VersionLabel
		version.text = "v0.5"
		version.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		version.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
		version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Style primary buttons
	_style_primary_buttons()

	# Style secondary buttons
	_style_secondary_buttons()

	# Style currency bar
	_style_currency_bar()


func _style_primary_buttons():
	var primary_names = ["CampaignButton", "DungeonsButton", "QuickBattleButton"]
	for btn_name in primary_names:
		var path = "CenterContainer/VBoxContainer/PrimaryButtons/" + btn_name
		if has_node(path):
			var btn = get_node(path)
			btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
			btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.PRIMARY.lightened(0.1)))
			btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.PRIMARY.darkened(0.1)))
			btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
			btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
			btn.custom_minimum_size = Vector2(300, 50)


func _style_secondary_buttons():
	var secondary_names = ["SummonButton", "CollectionButton", "GearButton", "PvPButton", "HowToPlayButton"]
	for btn_name in secondary_names:
		var path = "CenterContainer/VBoxContainer/SecondaryButtons/" + btn_name
		if has_node(path):
			var btn = get_node(path)
			btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_MEDIUM, UITheme.BG_LIGHT))
			btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT))
			btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.BG_MEDIUM.darkened(0.1)))
			btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
			btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
			btn.custom_minimum_size = Vector2(145, 50)


func _style_currency_bar():
	if not has_node("CurrencyBar"):
		return
	var bar = $CurrencyBar
	# Position at bottom
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -50
	bar.offset_bottom = -UITheme.SPACING_MD
	bar.offset_left = UITheme.SPACING_XL
	bar.offset_right = -UITheme.SPACING_XL

	# Style currency labels
	var currency_labels = [gold_label, materials_label, gems_label, stones_label]
	for label in currency_labels:
		if label:
			label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
			label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Apply specific colors
	if gold_label:
		gold_label.add_theme_color_override("font_color", UITheme.GOLD)
	if gems_label:
		gems_label.add_theme_color_override("font_color", UITheme.PRIMARY)
	if stones_label:
		stones_label.add_theme_color_override("font_color", UITheme.SECONDARY)


func _update_currency_display():
	if gold_label and PlayerData.has_method("get_gold"):
		gold_label.text = "Gold: %d" % PlayerData.get_gold()
	elif gold_label:
		gold_label.text = "Gold: %d" % PlayerData.gold if "gold" in PlayerData else "Gold: 0"

	if materials_label:
		materials_label.text = "Materials: %d" % PlayerData.materials if "materials" in PlayerData else "Materials: 0"

	if gems_label:
		gems_label.text = "Gems: %d" % PlayerData.gems if "gems" in PlayerData else "Gems: 0"

	if stones_label:
		stones_label.text = "Stones: %d" % PlayerData.summon_stones if "summon_stones" in PlayerData else "Stones: 0"


func _on_campaign_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/campaign_select_screen.tscn")


func _on_dungeons_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/dungeon_select_screen.tscn")


func _on_quick_battle_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/team_select_screen.tscn")


func _on_pvp_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/pvp_lobby.tscn")


func _on_summon_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/gacha_screen.tscn")


func _on_gear_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/gear_inventory_screen.tscn")


func _on_collection_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/collection_screen.tscn")


func _on_how_to_play_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/how_to_play_screen.tscn")
