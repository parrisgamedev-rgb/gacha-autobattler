extends Control
## PvP Lobby screen for hosting/joining multiplayer games using room codes

@onready var host_button = $CenterContainer/VBoxContainer/HostButton
@onready var room_code_container = $CenterContainer/VBoxContainer/RoomCodeContainer
@onready var room_code_display = $CenterContainer/VBoxContainer/RoomCodeContainer/RoomCodeDisplay
@onready var copy_button = $CenterContainer/VBoxContainer/RoomCodeContainer/CopyButton
@onready var room_code_input = $CenterContainer/VBoxContainer/JoinContainer/RoomCodeInput
@onready var join_button = $CenterContainer/VBoxContainer/JoinContainer/JoinButton
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel
@onready var start_battle_button = $CenterContainer/VBoxContainer/StartBattleButton
@onready var back_button = $CenterContainer/VBoxContainer/BackButton
@onready var disconnect_button = $CenterContainer/VBoxContainer/DisconnectButton
@onready var or_label = $CenterContainer/VBoxContainer/OrLabel
@onready var join_container = $CenterContainer/VBoxContainer/JoinContainer

func _ready():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_battle_button.pressed.connect(_on_start_battle_pressed)
	back_button.pressed.connect(_on_back_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	copy_button.pressed.connect(_on_copy_pressed)

	# Auto-format room code input
	room_code_input.text_changed.connect(_on_room_code_text_changed)

	# Connect network signals
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.server_started.connect(_on_server_started)

	_update_ui_state()

func _on_host_pressed():
	AudioManager.play_ui_click()
	var error = NetworkManager.host_game()
	if error != OK:
		status_label.text = "Failed to start server!"
		status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	else:
		room_code_display.text = NetworkManager.get_room_code()
	_update_ui_state()

func _on_copy_pressed():
	AudioManager.play_ui_click()
	DisplayServer.clipboard_set(NetworkManager.get_room_code())
	copy_button.text = "COPIED!"
	# Reset button text after a short delay
	await get_tree().create_timer(1.5).timeout
	copy_button.text = "COPY CODE"

func _on_join_pressed():
	AudioManager.play_ui_click()
	var code = room_code_input.text.strip_edges()
	if code.is_empty():
		status_label.text = "Please enter a room code"
		status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		return

	status_label.text = "Connecting..."
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	var error = NetworkManager.join_with_code(code)
	if error != OK:
		status_label.text = "Invalid room code!"
		status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	_update_ui_state()

func _on_room_code_text_changed(new_text: String):
	# Auto-format: add dashes for XXXX-XXXX-XXXX format
	var clean = new_text.replace("-", "").to_upper()
	var formatted = ""
	for i in range(clean.length()):
		if i == 4 or i == 8:
			formatted += "-"
		formatted += clean[i]
	if formatted != new_text and clean.length() > 0:
		room_code_input.text = formatted
		room_code_input.caret_column = formatted.length()

func _on_start_battle_pressed():
	AudioManager.play_ui_click()
	if NetworkManager.is_host() and NetworkManager.has_opponent():
		# Host starts the battle - notify client via RPC
		_start_pvp_battle.rpc()
		_start_pvp_battle()

@rpc("authority", "call_remote", "reliable")
func _start_pvp_battle():
	# Change to team select, then battle with PvP mode
	PlayerData.pvp_mode = true
	SceneTransition.change_scene("res://scenes/ui/team_select_screen.tscn")

func _on_back_pressed():
	AudioManager.play_ui_click()
	NetworkManager.disconnect_from_game()
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")

func _on_disconnect_pressed():
	AudioManager.play_ui_click()
	NetworkManager.disconnect_from_game()
	_update_ui_state()

func _on_player_connected(_id: int):
	status_label.text = "Opponent connected!"
	status_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	_update_ui_state()

func _on_player_disconnected(_id: int):
	status_label.text = "Opponent disconnected"
	status_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	_update_ui_state()

func _on_connection_failed():
	status_label.text = "Connection failed! Check the room code"
	status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	_update_ui_state()

func _on_connection_succeeded():
	status_label.text = "Connected! Waiting for host to start..."
	status_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	_update_ui_state()

func _on_server_started():
	status_label.text = "Waiting for opponent..."
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.3))
	_update_ui_state()

func _update_ui_state():
	var connected = NetworkManager.is_connected_to_game()
	var is_host = NetworkManager.is_host()
	var has_opponent = NetworkManager.has_opponent()

	# Host button only when not connected
	host_button.visible = not connected

	# Room code display when hosting
	room_code_container.visible = is_host

	# Join controls only when not connected
	or_label.visible = not connected
	join_container.visible = not connected

	# Disconnect button when connected
	disconnect_button.visible = connected

	# Start battle only for host when opponent is connected
	start_battle_button.visible = is_host and has_opponent

	# Back button always visible
	back_button.visible = true
