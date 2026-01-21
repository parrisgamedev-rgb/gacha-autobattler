extends Control
## Main menu screen

@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var summon_button = $CenterContainer/VBoxContainer/SummonButton

func _ready():
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.grab_focus()

	if summon_button:
		summon_button.pressed.connect(_on_summon_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func _on_summon_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/gacha_screen.tscn")
