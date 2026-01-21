extends CanvasLayer
## Cheat menu for testing and debugging

signal difficulty_changed(difficulty: int)
signal reset_requested
signal instant_win_requested
signal instant_lose_requested

@onready var panel = $Panel
@onready var close_button = $Panel/VBox/Header/CloseButton
@onready var easy_button = $Panel/VBox/DifficultyButtons/EasyButton
@onready var medium_button = $Panel/VBox/DifficultyButtons/MediumButton
@onready var hard_button = $Panel/VBox/DifficultyButtons/HardButton
@onready var current_difficulty_label = $Panel/VBox/CurrentDifficulty
@onready var reset_button = $Panel/VBox/ResetButton
@onready var instant_win_button = $Panel/VBox/InstantWinButton
@onready var instant_lose_button = $Panel/VBox/InstantLoseButton
@onready var add_gems_button = $Panel/VBox/AddGemsButton
@onready var add_gold_button = $Panel/VBox/AddGoldButton

var battle_ref: Node = null

func _ready():
	visible = false

	close_button.pressed.connect(_on_close_pressed)
	easy_button.pressed.connect(_on_easy_pressed)
	medium_button.pressed.connect(_on_medium_pressed)
	hard_button.pressed.connect(_on_hard_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	instant_win_button.pressed.connect(_on_instant_win_pressed)
	instant_lose_button.pressed.connect(_on_instant_lose_pressed)
	add_gems_button.pressed.connect(_on_add_gems_pressed)
	add_gold_button.pressed.connect(_on_add_gold_pressed)

func setup(battle: Node):
	battle_ref = battle
	_update_difficulty_display()

func toggle():
	visible = not visible
	if visible:
		_update_difficulty_display()

func _update_difficulty_display():
	if battle_ref:
		var difficulty_names = ["EASY", "MEDIUM", "HARD"]
		var current = battle_ref.ai_difficulty
		current_difficulty_label.text = "Current: " + difficulty_names[current]

		# Update button highlights
		easy_button.modulate = Color(0.5, 1, 0.5) if current == 0 else Color(1, 1, 1)
		medium_button.modulate = Color(0.5, 1, 0.5) if current == 1 else Color(1, 1, 1)
		hard_button.modulate = Color(0.5, 1, 0.5) if current == 2 else Color(1, 1, 1)

func _on_close_pressed():
	visible = false

func _on_easy_pressed():
	if battle_ref:
		battle_ref.ai_difficulty = 0  # AIDifficulty.EASY
		_update_difficulty_display()
		print("[CHEAT] AI Difficulty set to EASY")

func _on_medium_pressed():
	if battle_ref:
		battle_ref.ai_difficulty = 1  # AIDifficulty.MEDIUM
		_update_difficulty_display()
		print("[CHEAT] AI Difficulty set to MEDIUM")

func _on_hard_pressed():
	if battle_ref:
		battle_ref.ai_difficulty = 2  # AIDifficulty.HARD
		_update_difficulty_display()
		print("[CHEAT] AI Difficulty set to HARD")

func _on_reset_pressed():
	print("[CHEAT] Resetting round...")
	get_tree().reload_current_scene()

func _on_instant_win_pressed():
	if battle_ref:
		print("[CHEAT] Instant win triggered")
		battle_ref._cheat_instant_win()

func _on_instant_lose_pressed():
	if battle_ref:
		print("[CHEAT] Instant lose triggered")
		battle_ref._cheat_instant_lose()

func _on_add_gems_pressed():
	PlayerData.add_gems(10000)
	print("[CHEAT] Added 10000 gems")

func _on_add_gold_pressed():
	PlayerData.add_gold(10000)
	print("[CHEAT] Added 10000 gold")
