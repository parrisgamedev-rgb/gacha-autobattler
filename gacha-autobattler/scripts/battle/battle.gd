extends Node2D
## Main battle scene controller
## Manages the 3x3 grid, turns, and battle flow

# Grid settings
const GRID_SIZE = 3
const CELL_SIZE = 150
const CELL_GAP = 10
const ACTIONS_PER_TURN = 2

# References
@onready var grid_container = $GridContainer
@onready var turn_label = $UI/TurnLabel
@onready var phase_label = $UI/PhaseLabel
@onready var actions_label = $UI/ActionsLabel
@onready var player_roster = $UI/PlayerRoster
@onready var enemy_roster = $UI/EnemyRoster
@onready var end_turn_button = $UI/EndTurnButton

# Game state
enum GamePhase { PLAYER_TURN, ENEMY_TURN, RESOLVING, GAME_OVER }
var current_phase: GamePhase = GamePhase.PLAYER_TURN
var current_turn: int = 1
var actions_remaining: int = ACTIONS_PER_TURN

# Grid state
var grid_cells: Array = []
var grid_ownership: Array = []  # 0 = empty, 1 = player, 2 = enemy
var grid_units: Array = []  # UnitInstance or null
var grid_unit_displays: Array = []

# Unit management
var player_units: Array[UnitInstance] = []
var enemy_units: Array[UnitInstance] = []
var selected_unit: UnitInstance = null
var moving_unit: UnitInstance = null  # Unit being moved from grid
var moving_from: Dictionary = {}  # {row, col} of unit being moved

# Pending actions for simultaneous resolution
var player_pending_placements: Array = []  # [{unit, row, col}]
var player_pending_moves: Array = []  # [{unit, from_row, from_col, to_row, to_col}]
var enemy_pending_placements: Array = []

# Preload scenes
var GridCellScene = preload("res://scenes/battle/grid_cell.tscn")
var UnitDisplayScene = preload("res://scenes/battle/unit_display.tscn")

func _ready():
	_create_grid()
	_load_test_units()
	_create_roster_displays()
	_update_ui()

	# Connect end turn button
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

func _create_grid():
	grid_ownership = []
	grid_cells = []
	grid_units = []
	grid_unit_displays = []

	var grid_total_size = (CELL_SIZE * GRID_SIZE) + (CELL_GAP * (GRID_SIZE - 1))
	var offset = -grid_total_size / 2

	for row in range(GRID_SIZE):
		var cell_row = []
		var ownership_row = []
		var unit_row = []
		var display_row = []

		for col in range(GRID_SIZE):
			var cell = GridCellScene.instantiate()
			grid_container.add_child(cell)

			var x = offset + (col * (CELL_SIZE + CELL_GAP)) + CELL_SIZE / 2
			var y = offset + (row * (CELL_SIZE + CELL_GAP)) + CELL_SIZE / 2
			cell.position = Vector2(x, y)

			cell.setup(row, col, CELL_SIZE)
			cell.cell_clicked.connect(_on_cell_clicked)

			cell_row.append(cell)
			ownership_row.append(0)
			unit_row.append(null)
			display_row.append(null)

		grid_cells.append(cell_row)
		grid_ownership.append(ownership_row)
		grid_units.append(unit_row)
		grid_unit_displays.append(display_row)

func _load_test_units():
	var fire_data = load("res://resources/units/fire_warrior.tres") as UnitData
	var water_data = load("res://resources/units/water_mage.tres") as UnitData
	var nature_data = load("res://resources/units/nature_tank.tres") as UnitData

	# Create 5 player units (as per design)
	if fire_data:
		player_units.append(UnitInstance.new(fire_data, 1))
	if water_data:
		player_units.append(UnitInstance.new(water_data, 1))
	if nature_data:
		player_units.append(UnitInstance.new(nature_data, 1))
	if fire_data:
		var unit = UnitInstance.new(fire_data, 1)
		unit.unit_data = fire_data.duplicate()
		unit.unit_data.unit_name = "Blaze"
		player_units.append(unit)
	if water_data:
		var unit = UnitInstance.new(water_data, 1)
		unit.unit_data = water_data.duplicate()
		unit.unit_data.unit_name = "Tide"
		player_units.append(unit)

	# Create 5 enemy units
	if fire_data:
		enemy_units.append(UnitInstance.new(fire_data, 2))
	if water_data:
		enemy_units.append(UnitInstance.new(water_data, 2))
	if nature_data:
		enemy_units.append(UnitInstance.new(nature_data, 2))
	if fire_data:
		var unit = UnitInstance.new(fire_data, 2)
		unit.unit_data = fire_data.duplicate()
		unit.unit_data.unit_name = "Ember"
		enemy_units.append(unit)
	if water_data:
		var unit = UnitInstance.new(water_data, 2)
		unit.unit_data = water_data.duplicate()
		unit.unit_data.unit_name = "Wave"
		enemy_units.append(unit)

func _create_roster_displays():
	var y_offset = 0
	for i in range(player_units.size()):
		var unit = player_units[i]
		var display = UnitDisplayScene.instantiate()
		player_roster.add_child(display)
		display.position = Vector2(60, 60 + y_offset)
		display.setup(unit)
		display.scale = Vector2(0.7, 0.7)
		y_offset += 110

	y_offset = 0
	for unit in enemy_units:
		var display = UnitDisplayScene.instantiate()
		enemy_roster.add_child(display)
		display.position = Vector2(60, 60 + y_offset)
		display.setup(unit)
		display.scale = Vector2(0.7, 0.7)
		y_offset += 110

func _on_cell_clicked(row: int, col: int):
	if current_phase != GamePhase.PLAYER_TURN:
		print("Not your turn!")
		return

	var cell_unit = grid_units[row][col]

	# Check if clicking on a pending placement to cancel it
	for i in range(player_pending_placements.size()):
		var pending = player_pending_placements[i]
		if pending.row == row and pending.col == col:
			_cancel_pending_placement(i)
			return

	# Check if clicking on a pending move to cancel it
	for i in range(player_pending_moves.size()):
		var pending = player_pending_moves[i]
		if pending.to_row == row and pending.to_col == col:
			_cancel_pending_move(i)
			return

	if actions_remaining <= 0:
		print("No actions remaining! Press End Turn.")
		return

	# Check if clicking on own unit to select for moving
	if cell_unit != null and cell_unit.owner == 1:
		# Select this unit for moving
		moving_unit = cell_unit
		moving_from = {"row": row, "col": col}
		selected_unit = null  # Clear roster selection
		print("Selected ", cell_unit.unit_data.unit_name, " for moving")
		return

	# If we have a unit selected for moving
	if moving_unit != null:
		# Check if target is different from origin
		if row == moving_from.row and col == moving_from.col:
			print("Can't move to same square!")
			return

		# Check if there's already a pending action here
		for pending in player_pending_placements:
			if pending.row == row and pending.col == col:
				print("Already have a pending placement there!")
				return

		# Queue the move
		_queue_move(moving_unit, moving_from.row, moving_from.col, row, col)
		moving_unit = null
		moving_from = {}
		return

	# If we have a selected unit from roster and the cell is empty
	if selected_unit and cell_unit == null:
		# Check if there's already a pending placement here
		for pending in player_pending_placements:
			if pending.row == row and pending.col == col:
				print("Already have a pending placement there!")
				return

		_queue_placement(selected_unit, row, col)
		selected_unit = null
	elif cell_unit != null and cell_unit.owner == 2:
		print("Enemy cell - select a unit to challenge it!")

func _queue_placement(unit: UnitInstance, row: int, col: int):
	# Add to pending placements
	player_pending_placements.append({
		"unit": unit,
		"row": row,
		"col": col
	})

	# Mark unit as pending (not available for selection)
	unit.place_on_grid(row, col)

	# Show preview on grid
	_show_placement_preview(unit, row, col)

	actions_remaining -= 1
	_update_ui()

	print("Queued ", unit.unit_data.unit_name, " at (", row, ", ", col, ")")

func _queue_move(unit: UnitInstance, from_row: int, from_col: int, to_row: int, to_col: int):
	# Add to pending moves
	player_pending_moves.append({
		"unit": unit,
		"from_row": from_row,
		"from_col": from_col,
		"to_row": to_row,
		"to_col": to_col
	})

	# Update visual - make original position semi-transparent
	if grid_unit_displays[from_row][from_col]:
		grid_unit_displays[from_row][from_col].modulate = Color(1, 1, 1, 0.4)

	# Show preview at destination
	_show_placement_preview(unit, to_row, to_col)

	# The original square is now vacated - mark it as available
	# (we'll handle this in resolution)

	actions_remaining -= 1
	_update_ui()

	print("Queued move: ", unit.unit_data.unit_name, " from (", from_row, ",", from_col, ") to (", to_row, ",", to_col, ")")

func _cancel_pending_placement(index: int):
	var pending = player_pending_placements[index]
	var unit = pending.unit
	var row = pending.row
	var col = pending.col

	# Remove from pending list
	player_pending_placements.remove_at(index)

	# Reset unit state
	unit.remove_from_grid()

	# Remove visual preview
	if grid_unit_displays[row][col]:
		grid_unit_displays[row][col].queue_free()
		grid_unit_displays[row][col] = null

	# Refund action
	actions_remaining += 1
	_update_ui()

	print("Cancelled placement: ", unit.unit_data.unit_name)

func _cancel_pending_move(index: int):
	var pending = player_pending_moves[index]
	var unit = pending.unit
	var from_row = pending.from_row
	var from_col = pending.from_col
	var to_row = pending.to_row
	var to_col = pending.to_col

	# Remove from pending list
	player_pending_moves.remove_at(index)

	# Remove destination preview
	if grid_unit_displays[to_row][to_col]:
		grid_unit_displays[to_row][to_col].queue_free()
		grid_unit_displays[to_row][to_col] = null

	# Restore original position visual
	if grid_unit_displays[from_row][from_col]:
		grid_unit_displays[from_row][from_col].modulate = Color(1, 1, 1, 1)

	# Refund action
	actions_remaining += 1
	_update_ui()

	print("Cancelled move: ", unit.unit_data.unit_name)

func _show_placement_preview(unit: UnitInstance, row: int, col: int):
	var display = UnitDisplayScene.instantiate()
	grid_container.add_child(display)

	var grid_total_size = (CELL_SIZE * GRID_SIZE) + (CELL_GAP * (GRID_SIZE - 1))
	var offset = -grid_total_size / 2
	var x = offset + (col * (CELL_SIZE + CELL_GAP)) + CELL_SIZE / 2
	var y = offset + (row * (CELL_SIZE + CELL_GAP)) + CELL_SIZE / 2
	display.position = Vector2(x, y)
	display.scale = Vector2(0.7, 0.7)
	display.setup(unit)
	display.modulate = Color(1, 1, 1, 0.7)  # Semi-transparent to show it's pending

	grid_unit_displays[row][col] = display

func _on_end_turn_pressed():
	if current_phase != GamePhase.PLAYER_TURN:
		return

	print("=== End of Player Turn ===")

	# Enemy takes their turn
	current_phase = GamePhase.ENEMY_TURN
	_update_ui()

	# Simple delay before enemy acts
	await get_tree().create_timer(0.5).timeout

	_do_enemy_turn()

func _do_enemy_turn():
	print("Enemy is thinking...")

	# Simple AI: place up to 2 units on random empty cells
	var empty_cells = _get_empty_cells()
	var available_units = enemy_units.filter(func(u): return u.can_act() and not u.is_placed())

	var ai_actions = min(ACTIONS_PER_TURN, min(empty_cells.size(), available_units.size()))

	for i in range(ai_actions):
		if empty_cells.is_empty() or available_units.is_empty():
			break

		var unit = available_units.pop_front()
		var cell_idx = randi() % empty_cells.size()
		var cell = empty_cells[cell_idx]
		empty_cells.remove_at(cell_idx)

		enemy_pending_placements.append({
			"unit": unit,
			"row": cell.row,
			"col": cell.col
		})
		unit.place_on_grid(cell.row, cell.col)

		print("Enemy queued ", unit.unit_data.unit_name, " at (", cell.row, ", ", cell.col, ")")

	await get_tree().create_timer(0.5).timeout

	_resolve_turn()

func _get_empty_cells() -> Array:
	var empty = []
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if grid_units[row][col] == null:
				# Also check pending placements
				var is_pending = false
				for p in player_pending_placements:
					if p.row == row and p.col == col:
						is_pending = true
						break
				if not is_pending:
					empty.append({"row": row, "col": col})
	return empty

func _resolve_turn():
	print("=== Resolving Turn ===")
	current_phase = GamePhase.RESOLVING
	_update_ui()

	# First, process player moves (vacate old squares)
	for move in player_pending_moves:
		var from_row = move.from_row
		var from_col = move.from_col

		# Clear the original position
		grid_units[from_row][from_col] = null
		grid_ownership[from_row][from_col] = 0
		grid_cells[from_row][from_col].set_ownership(0)

		# Remove old display
		if grid_unit_displays[from_row][from_col]:
			grid_unit_displays[from_row][from_col].queue_free()
			grid_unit_displays[from_row][from_col] = null

		# Add move destination as a pending placement
		player_pending_placements.append({
			"unit": move.unit,
			"row": move.to_row,
			"col": move.to_col
		})

		print("Executed move: ", move.unit.unit_data.unit_name, " vacated (", from_row, ",", from_col, ")")

	# Check for contested squares (both players placed/moved to same cell)
	var contests = []
	for p_placement in player_pending_placements:
		for e_placement in enemy_pending_placements:
			if p_placement.row == e_placement.row and p_placement.col == e_placement.col:
				contests.append({
					"row": p_placement.row,
					"col": p_placement.col,
					"player_unit": p_placement.unit,
					"enemy_unit": e_placement.unit
				})

	# Also check if player moves into enemy-occupied square (challenge)
	for p_placement in player_pending_placements:
		var target_unit = grid_units[p_placement.row][p_placement.col]
		if target_unit != null and target_unit.owner == 2:
			# Player is challenging an enemy square
			contests.append({
				"row": p_placement.row,
				"col": p_placement.col,
				"player_unit": p_placement.unit,
				"enemy_unit": target_unit
			})

	# Resolve contests (duels)
	for contest in contests:
		await _resolve_duel(contest)

	# Place non-contested units
	for placement in player_pending_placements:
		var dominated = false
		for contest in contests:
			if contest.row == placement.row and contest.col == placement.col:
				dominated = true
				break
		if not dominated:
			_confirm_placement(placement.unit, placement.row, placement.col, 1)

	for placement in enemy_pending_placements:
		var contested = false
		for contest in contests:
			if contest.row == placement.row and contest.col == placement.col:
				contested = true
				break
		if not contested:
			_confirm_placement(placement.unit, placement.row, placement.col, 2)

	# Clear pending actions
	player_pending_placements.clear()
	player_pending_moves.clear()
	enemy_pending_placements.clear()

	# Check win condition
	var winner = _check_win_condition()
	if winner > 0:
		current_phase = GamePhase.GAME_OVER
		phase_label.text = "WINNER: " + ("PLAYER" if winner == 1 else "ENEMY")
		print("Game Over! Winner: ", "Player" if winner == 1 else "Enemy")
		return

	# Process cooldowns
	for unit in player_units + enemy_units:
		unit.process_turn_end()

	# Start next turn
	current_turn += 1
	actions_remaining = ACTIONS_PER_TURN
	current_phase = GamePhase.PLAYER_TURN
	_update_ui()

	print("=== Turn ", current_turn, " ===")

func _resolve_duel(contest: Dictionary):
	var p_unit = contest.player_unit as UnitInstance
	var e_unit = contest.enemy_unit as UnitInstance
	var row = contest.row
	var col = contest.col

	print("DUEL at (", row, ", ", col, "): ", p_unit.unit_data.unit_name, " vs ", e_unit.unit_data.unit_name)

	# Calculate damage with element advantage
	var p_multiplier = p_unit.unit_data.get_element_multiplier(e_unit.unit_data.element)
	var e_multiplier = e_unit.unit_data.get_element_multiplier(p_unit.unit_data.element)

	var p_damage = int(p_unit.unit_data.attack * p_multiplier)
	var e_damage = int(e_unit.unit_data.attack * e_multiplier)

	print("  Player deals ", p_damage, " (x", p_multiplier, "), Enemy deals ", e_damage, " (x", e_multiplier, ")")

	# Apply damage
	e_unit.take_damage(p_damage)
	p_unit.take_damage(e_damage)

	# Determine winner (who has more HP remaining, or who dealt killing blow)
	var winner_unit: UnitInstance = null
	var winner_owner: int = 0

	if p_unit.current_hp <= 0 and e_unit.current_hp <= 0:
		# Both died - no one gets the square
		print("  Both units knocked out! Square remains empty.")
		p_unit.remove_from_grid()
		e_unit.remove_from_grid()
		p_unit.start_cooldown()
		e_unit.start_cooldown()
		# Remove preview display
		if grid_unit_displays[row][col]:
			grid_unit_displays[row][col].queue_free()
			grid_unit_displays[row][col] = null
	elif p_unit.current_hp <= 0:
		# Enemy wins
		print("  Enemy wins the duel!")
		winner_unit = e_unit
		winner_owner = 2
		p_unit.remove_from_grid()
		p_unit.start_cooldown()
	elif e_unit.current_hp <= 0:
		# Player wins
		print("  Player wins the duel!")
		winner_unit = p_unit
		winner_owner = 1
		e_unit.remove_from_grid()
		e_unit.start_cooldown()
	else:
		# Both alive - higher HP wins
		if p_unit.current_hp >= e_unit.current_hp:
			print("  Player wins (more HP)!")
			winner_unit = p_unit
			winner_owner = 1
			e_unit.remove_from_grid()
			e_unit.start_cooldown()
		else:
			print("  Enemy wins (more HP)!")
			winner_unit = e_unit
			winner_owner = 2
			p_unit.remove_from_grid()
			p_unit.start_cooldown()

	# Place winner on grid
	if winner_unit:
		_confirm_placement(winner_unit, row, col, winner_owner)

	await get_tree().create_timer(0.3).timeout

func _confirm_placement(unit: UnitInstance, row: int, col: int, owner: int):
	grid_units[row][col] = unit
	grid_ownership[row][col] = owner
	grid_cells[row][col].set_ownership(owner)

	# Update or create display
	if grid_unit_displays[row][col]:
		grid_unit_displays[row][col].queue_free()

	var display = UnitDisplayScene.instantiate()
	grid_container.add_child(display)

	var grid_total_size = (CELL_SIZE * GRID_SIZE) + (CELL_GAP * (GRID_SIZE - 1))
	var offset = -grid_total_size / 2
	var x = offset + (col * (CELL_SIZE + CELL_GAP)) + CELL_SIZE / 2
	var y = offset + (row * (CELL_SIZE + CELL_GAP)) + CELL_SIZE / 2
	display.position = Vector2(x, y)
	display.scale = Vector2(0.7, 0.7)
	display.setup(unit)
	display.modulate = Color(1, 1, 1, 1)  # Full opacity for confirmed

	grid_unit_displays[row][col] = display

func _check_win_condition() -> int:
	for row in range(GRID_SIZE):
		if _check_line(grid_ownership[row][0], grid_ownership[row][1], grid_ownership[row][2]):
			return grid_ownership[row][0]

	for col in range(GRID_SIZE):
		if _check_line(grid_ownership[0][col], grid_ownership[1][col], grid_ownership[2][col]):
			return grid_ownership[0][col]

	if _check_line(grid_ownership[0][0], grid_ownership[1][1], grid_ownership[2][2]):
		return grid_ownership[0][0]
	if _check_line(grid_ownership[0][2], grid_ownership[1][1], grid_ownership[2][0]):
		return grid_ownership[0][2]

	return 0

func _check_line(a: int, b: int, c: int) -> bool:
	return a != 0 and a == b and b == c

func _update_ui():
	turn_label.text = "Turn: " + str(current_turn)

	match current_phase:
		GamePhase.PLAYER_TURN:
			phase_label.text = "YOUR TURN"
		GamePhase.ENEMY_TURN:
			phase_label.text = "ENEMY TURN"
		GamePhase.RESOLVING:
			phase_label.text = "RESOLVING..."
		GamePhase.GAME_OVER:
			pass  # Keep winner text

	if actions_label:
		actions_label.text = "Actions: " + str(actions_remaining) + "/" + str(ACTIONS_PER_TURN)

func _input(event):
	if current_phase != GamePhase.PLAYER_TURN:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_try_select_unit(0)
			KEY_2:
				_try_select_unit(1)
			KEY_3:
				_try_select_unit(2)
			KEY_4:
				_try_select_unit(3)
			KEY_5:
				_try_select_unit(4)
			KEY_ESCAPE:
				selected_unit = null
				moving_unit = null
				moving_from = {}
				print("Deselected")
			KEY_ENTER, KEY_SPACE:
				_on_end_turn_pressed()

func _try_select_unit(index: int):
	if index >= player_units.size():
		return

	var unit = player_units[index]
	if unit.can_act() and not unit.is_placed():
		selected_unit = unit
		print("Selected: ", unit.unit_data.unit_name)
	else:
		if unit.is_placed():
			print(unit.unit_data.unit_name, " is already on the grid")
		elif unit.is_on_cooldown:
			print(unit.unit_data.unit_name, " is on cooldown")
