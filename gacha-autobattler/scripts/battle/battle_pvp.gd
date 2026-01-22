extends "res://scripts/battle/battle.gd"
## PvP Battle extension
## Handles networked multiplayer with RPC for action synchronization

# PvP state
var is_pvp_mode: bool = false
var local_player_id: int = 1  # 1 for host, 2 for client
var opponent_ready: bool = false
var local_ready: bool = false
var waiting_for_opponent: bool = false

# Store opponent's pending actions (received from network)
var opponent_pending_actions: Dictionary = {}

func _ready():
	super._ready()

	# Check if we're in PvP mode
	is_pvp_mode = PlayerData.pvp_mode
	if is_pvp_mode:
		local_player_id = NetworkManager.get_local_player_id()
		_setup_pvp_mode()
		print("PvP Battle started - Local player: ", local_player_id)

		# Connect disconnect signal
		NetworkManager.player_disconnected.connect(_on_opponent_disconnected)

func _setup_pvp_mode():
	# In PvP, both players are "player 1" from their perspective
	# Host plays as player 1, client plays as player 2
	# But locally, each player sees themselves on the left (player side)

	if local_player_id == 2:
		# Client needs to swap perspective - their units are still "player" but
		# they need to load the opponent's team as enemy
		# For now, both players just use their own selected team
		pass

func _load_units():
	# Load player units from selected team
	var team_entries = PlayerData.get_selected_team_units()

	if team_entries.is_empty():
		print("No team selected!")
		await get_tree().create_timer(0.1).timeout
		_show_no_units_message()
		return

	for unit_entry in team_entries:
		var unit_data = unit_entry.unit_data as UnitData
		var imprint_level = unit_entry.imprint_level as int
		var unit = UnitInstance.new(unit_data, 1 + imprint_level)
		player_units.append(unit)

	if is_pvp_mode:
		# In PvP, enemy team will be received from opponent
		# For now, generate placeholder until opponent sends their team
		_generate_enemy_team()
	else:
		_generate_enemy_team()

func _on_end_turn_pressed():
	if current_phase != GamePhase.PLAYER_TURN:
		return

	if is_pvp_mode:
		_pvp_end_turn()
	else:
		super._on_end_turn_pressed()

func _pvp_end_turn():
	# Clear any editing state
	pending_edit_unit = null
	selected_unit = null
	moving_unit = null
	moving_from = {}
	_update_ability_panel()

	print("=== Local Player Ending Turn ===")

	# Package our actions
	var actions = _package_local_actions()

	# Mark ourselves as ready
	local_ready = true
	waiting_for_opponent = true

	# Send actions to the host (or process if we are the host)
	if NetworkManager.is_host():
		# Host stores their own actions and waits for client
		opponent_pending_actions["host"] = actions
		_check_both_ready()
	else:
		# Client sends actions to host
		_send_actions_to_host.rpc_id(1, actions)
		_set_waiting_state()

func _package_local_actions() -> Dictionary:
	var actions = {
		"placements": [],
		"moves": []
	}

	# Package placements
	for placement in player_pending_placements:
		var unit = placement.unit as UnitInstance
		actions.placements.append({
			"unit_index": player_units.find(unit),
			"row": placement.row,
			"col": placement.col,
			"ability": unit.selected_ability_index
		})

	# Package moves
	for move in player_pending_moves:
		var unit = move.unit as UnitInstance
		actions.moves.append({
			"unit_index": player_units.find(unit),
			"from_row": move.from_row,
			"from_col": move.from_col,
			"to_row": move.to_row,
			"to_col": move.to_col
		})

	return actions

func _set_waiting_state():
	current_phase = GamePhase.ENEMY_TURN  # Reuse for "waiting" state
	if phase_label:
		phase_label.text = "WAITING FOR OPPONENT..."
	_update_ui()

@rpc("any_peer", "reliable")
func _send_actions_to_host(actions: Dictionary):
	# Host receives actions from client
	if not NetworkManager.is_host():
		return

	var sender_id = multiplayer.get_remote_sender_id()
	print("Host received actions from peer ", sender_id)

	opponent_pending_actions["client"] = actions
	_check_both_ready()

func _check_both_ready():
	# Only host checks this
	if not NetworkManager.is_host():
		return

	if opponent_pending_actions.has("host") and opponent_pending_actions.has("client"):
		print("Both players ready - resolving turn")

		# Build resolution data
		var resolution = _resolve_pvp_turn()

		# Broadcast resolution to client
		_broadcast_resolution.rpc(resolution)

		# Apply resolution locally
		_apply_resolution(resolution)

@rpc("authority", "call_remote", "reliable")
func _broadcast_resolution(resolution: Dictionary):
	# Client receives resolution from host
	print("Received turn resolution from host")
	_apply_resolution(resolution)

func _resolve_pvp_turn() -> Dictionary:
	# Host resolves the turn based on both players' actions
	var resolution = {
		"turn": current_turn,
		"host_placements": opponent_pending_actions.get("host", {}).get("placements", []),
		"host_moves": opponent_pending_actions.get("host", {}).get("moves", []),
		"client_placements": opponent_pending_actions.get("client", {}).get("placements", []),
		"client_moves": opponent_pending_actions.get("client", {}).get("moves", []),
		"duels": [],
		"grid_ownership": [],
		"winner": 0
	}

	return resolution

func _apply_resolution(resolution: Dictionary):
	print("=== Applying Turn Resolution ===")

	# Clear pending actions
	opponent_pending_actions.clear()
	local_ready = false
	opponent_ready = false
	waiting_for_opponent = false

	# Apply host's actions as player (for host) or enemy (for client)
	# Apply client's actions as enemy (for host) or player (for client)

	if NetworkManager.is_host():
		# Host: their placements are player, client's are enemy
		_apply_player_actions(resolution.host_placements, resolution.host_moves)
		_apply_enemy_actions_from_network(resolution.client_placements, resolution.client_moves)
	else:
		# Client: client's placements are player, host's are enemy
		_apply_player_actions(resolution.client_placements, resolution.client_moves)
		_apply_enemy_actions_from_network(resolution.host_placements, resolution.host_moves)

	# Now resolve combat (reuse existing logic)
	await _resolve_turn_combat()

func _apply_player_actions(placements: Array, moves: Array):
	# Clear existing pending actions first
	player_pending_placements.clear()
	player_pending_moves.clear()

	# Apply placements
	for p in placements:
		if p.unit_index >= 0 and p.unit_index < player_units.size():
			var unit = player_units[p.unit_index]
			unit.selected_ability_index = p.ability
			unit.place_on_grid(p.row, p.col)
			player_pending_placements.append({
				"unit": unit,
				"row": p.row,
				"col": p.col
			})

	# Apply moves
	for m in moves:
		if m.unit_index >= 0 and m.unit_index < player_units.size():
			var unit = player_units[m.unit_index]
			player_pending_moves.append({
				"unit": unit,
				"from_row": m.from_row,
				"from_col": m.from_col,
				"to_row": m.to_row,
				"to_col": m.to_col
			})

func _apply_enemy_actions_from_network(placements: Array, moves: Array):
	# Apply opponent's actions as enemy
	enemy_pending_placements.clear()

	for p in placements:
		if p.unit_index >= 0 and p.unit_index < enemy_units.size():
			var unit = enemy_units[p.unit_index]
			unit.selected_ability_index = p.get("ability", 0)
			unit.place_on_grid(p.row, p.col)
			enemy_pending_placements.append({
				"unit": unit,
				"row": p.row,
				"col": p.col
			})

	# Note: Enemy moves would need similar handling but simplified for now

func _resolve_turn_combat():
	# This is the core resolution logic, reused from parent
	print("=== Resolving Combat ===")
	current_phase = GamePhase.RESOLVING
	_update_ui()

	# Process player moves
	for move in player_pending_moves:
		var from_row = move.from_row
		var from_col = move.from_col

		grid_player_units[from_row][from_col] = null
		if grid_player_displays[from_row][from_col]:
			grid_player_displays[from_row][from_col].queue_free()
			grid_player_displays[from_row][from_col] = null

		_update_cell_ownership(from_row, from_col)

		player_pending_placements.append({
			"unit": move.unit,
			"row": move.to_row,
			"col": move.to_col
		})

	# Place all player units
	for placement in player_pending_placements:
		_confirm_placement(placement.unit, placement.row, placement.col, 1)

	# Place all enemy units
	for placement in enemy_pending_placements:
		_confirm_placement(placement.unit, placement.row, placement.col, 2)

	# Clear pending
	player_pending_placements.clear()
	player_pending_moves.clear()
	enemy_pending_placements.clear()

	# Resolve duels
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var p_unit = grid_player_units[row][col]
			var e_unit = grid_enemy_units[row][col]
			if p_unit != null and e_unit != null and p_unit.is_alive() and e_unit.is_alive():
				await _resolve_duel(row, col, p_unit, e_unit)

	# Process field effects
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var p_unit = grid_player_units[row][col]
			if p_unit and p_unit.is_alive():
				var field_result = process_field_effects_for_unit(p_unit, row, col)
				if field_result.damage > 0:
					p_unit.take_damage(field_result.damage)
				if field_result.healing > 0:
					p_unit.heal(field_result.healing)
				if not p_unit.is_alive():
					_remove_unit_from_grid(p_unit, row, col)

			var e_unit = grid_enemy_units[row][col]
			if e_unit and e_unit.is_alive():
				var field_result = process_field_effects_for_unit(e_unit, row, col)
				if field_result.damage > 0:
					e_unit.take_damage(field_result.damage)
				if field_result.healing > 0:
					e_unit.heal(field_result.healing)
				if not e_unit.is_alive():
					_remove_unit_from_grid(e_unit, row, col)

	_process_all_field_durations()

	# Process status effects
	for unit in player_units + enemy_units:
		unit.process_turn_end()
		if unit.is_placed() and not unit.is_alive():
			_remove_unit_from_grid(unit, unit.grid_row, unit.grid_col)

	# Check win condition
	var winner = _check_win_condition()
	if winner > 0:
		current_phase = GamePhase.GAME_OVER
		_show_pvp_results(winner)
		return

	_update_roster_displays()

	# Start next turn
	current_turn += 1
	actions_remaining = ACTIONS_PER_TURN
	current_phase = GamePhase.PLAYER_TURN
	_update_ui()

	print("=== Turn ", current_turn, " ===")

func _show_pvp_results(winner: int):
	if results_panel:
		results_panel.visible = true

		# In PvP, winner 1 = player (local), winner 2 = enemy (opponent)
		if winner == 1:
			result_title.text = "VICTORY!"
			result_title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			result_subtitle.text = "You defeated your opponent!"
		else:
			result_title.text = "DEFEAT"
			result_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			result_subtitle.text = "Your opponent won!"

		if ability_panel:
			ability_panel.visible = false
		if end_turn_button:
			end_turn_button.visible = false

func _on_opponent_disconnected(_id: int):
	if is_pvp_mode and current_phase != GamePhase.GAME_OVER:
		# Opponent disconnected - they forfeit
		print("Opponent disconnected!")
		current_phase = GamePhase.GAME_OVER

		if results_panel:
			results_panel.visible = true
			result_title.text = "OPPONENT LEFT"
			result_title.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
			result_subtitle.text = "Your opponent disconnected"

			if ability_panel:
				ability_panel.visible = false
			if end_turn_button:
				end_turn_button.visible = false

func _on_main_menu_pressed():
	# Disconnect from network when leaving
	if is_pvp_mode:
		NetworkManager.disconnect_from_game()
		PlayerData.pvp_mode = false
	super._on_main_menu_pressed()

func _on_play_again_pressed():
	if is_pvp_mode:
		# In PvP, go back to lobby instead of restarting
		NetworkManager.disconnect_from_game()
		PlayerData.pvp_mode = false
		SceneTransition.change_scene("res://scenes/ui/pvp_lobby.tscn")
	else:
		super._on_play_again_pressed()
