extends Control
## Main menu screen

@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var pvp_button = $CenterContainer/VBoxContainer/PvPButton
@onready var summon_button = $CenterContainer/VBoxContainer/SummonButton
@onready var collection_button = $CenterContainer/VBoxContainer/CollectionButton

func _ready():
	# Reset PvP mode when returning to main menu
	PlayerData.pvp_mode = false

	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.grab_focus()

	if pvp_button:
		pvp_button.pressed.connect(_on_pvp_pressed)

	if summon_button:
		summon_button.pressed.connect(_on_summon_pressed)

	if collection_button:
		collection_button.pressed.connect(_on_collection_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/team_select_screen.tscn")

func _on_pvp_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/pvp_lobby.tscn")

func _on_summon_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/gacha_screen.tscn")

func _on_collection_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/collection_screen.tscn")
