extends Control
## Main menu screen

@onready var start_button = $CenterContainer/VBoxContainer/StartButton

func _ready():
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.grab_focus()

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
