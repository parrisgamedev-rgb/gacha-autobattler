extends Control
## Main menu screen

@onready var campaign_button = $CenterContainer/VBoxContainer/CampaignButton
@onready var dungeons_button = $CenterContainer/VBoxContainer/DungeonsButton
@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var pvp_button = $CenterContainer/VBoxContainer/PvPButton
@onready var summon_button = $CenterContainer/VBoxContainer/SummonButton
@onready var gear_button = $CenterContainer/VBoxContainer/GearButton
@onready var collection_button = $CenterContainer/VBoxContainer/CollectionButton

func _ready():
	# Reset PvP mode and campaign mode when returning to main menu
	PlayerData.pvp_mode = false
	PlayerData.end_campaign_stage()
	PlayerData.end_dungeon()

	if campaign_button:
		campaign_button.pressed.connect(_on_campaign_pressed)
		campaign_button.grab_focus()

	if dungeons_button:
		dungeons_button.pressed.connect(_on_dungeons_pressed)

	if start_button:
		start_button.pressed.connect(_on_start_pressed)

	if pvp_button:
		pvp_button.pressed.connect(_on_pvp_pressed)

	if summon_button:
		summon_button.pressed.connect(_on_summon_pressed)

	if gear_button:
		gear_button.pressed.connect(_on_gear_pressed)

	if collection_button:
		collection_button.pressed.connect(_on_collection_pressed)

func _on_campaign_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/campaign_select_screen.tscn")

func _on_dungeons_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/dungeon_select_screen.tscn")

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/team_select_screen.tscn")

func _on_pvp_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/pvp_lobby.tscn")

func _on_summon_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/gacha_screen.tscn")

func _on_gear_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/gear_inventory_screen.tscn")

func _on_collection_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/collection_screen.tscn")
