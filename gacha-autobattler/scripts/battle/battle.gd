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
@onready var ability_panel = $UI/AbilityPanel
@onready var ability_buttons = [$UI/AbilityPanel/Ability1, $UI/AbilityPanel/Ability2, $UI/AbilityPanel/Ability3]
@onready var ability_desc = $UI/AbilityPanel/AbilityDesc
@onready var results_panel = $UI/ResultsPanel
@onready var result_title = $UI/ResultsPanel/ResultTitle
@onready var result_subtitle = $UI/ResultsPanel/ResultSubtitle
@onready var play_again_button = $UI/ResultsPanel/ButtonContainer/PlayAgainButton
@onready var main_menu_button = $UI/ResultsPanel/ButtonContainer/MainMenuButton
@onready var combat_announcement = $UI/CombatAnnouncement

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
var grid_field_effects: Array = []  # 2D array of field effects: [{field_data, duration, owner}] or empty array

# Unit management
var player_units: Array[UnitInstance] = []
var enemy_units: Array[UnitInstance] = []
var selected_unit: UnitInstance = null
var moving_unit: UnitInstance = null  # Unit being moved from grid
var moving_from: Dictionary = {}  # {row, col} of unit being moved

# Drag and drop state
var dragging_unit: UnitInstance = null
var dragging_from_grid: bool = false
var dragging_from_pos: Dictionary = {}  # {row, col} if from grid
var drag_preview: Node2D = null

# Roster display references (for click detection)
var roster_displays: Array = []

# Pending actions for simultaneous resolution
var player_pending_placements: Array = []  # [{unit, row, col}]
var player_pending_moves: Array = []  # [{unit, from_row, from_col, to_row, to_col}]
var enemy_pending_placements: Array = []

# Unit being edited (for changing ability after placement)
var pending_edit_unit: UnitInstance = null

# Preload scenes
var GridCellScene = preload("res://scenes/battle/grid_cell.tscn")
var UnitDisplayScene = preload("res://scenes/battle/unit_display.tscn")

func _ready():
	_create_grid()
	_load_units()
	_create_roster_displays()
	_update_ui()

	# Connect end turn button
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Connect ability buttons
	for i in range(ability_buttons.size()):
		var btn = ability_buttons[i]
		if btn:
			btn.pressed.connect(_on_ability_selected.bind(i))

	# Connect results panel buttons
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func _create_grid():
	grid_ownership = []
	grid_cells = []
	grid_units = []
	grid_unit_displays = []
	grid_field_effects = []

	var grid_total_size = (CELL_SIZE * GRID_SIZE) + (CELL_GAP * (GRID_SIZE - 1))
	var offset = -grid_total_size / 2

	for row in range(GRID_SIZE):
		var cell_row = []
		var ownership_row = []
		var unit_row = []
		var display_row = []
		var field_row = []

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
			field_row.append([])  # Empty array for field effects on this cell

		grid_cells.append(cell_row)
		grid_ownership.append(ownership_row)
		grid_units.append(unit_row)
		grid_unit_displays.append(display_row)
		grid_field_effects.append(field_row)

func _load_units():
	# Load player units from selected team (array of instance_ids)
	var team_entries = PlayerData.get_selected_team_units()

	if team_entries.is_empty():
		# No team selected - show message and return to menu
		print("No team selected!")
		await get_tree().create_timer(0.1).timeout
		_show_no_units_message()
		return

	# Create units from selected team
	for unit_entry in team_entries:
		var unit_data = unit_entry.unit_data as UnitData
		var imprint_level = unit_entry.imprint_level as int
		# Create unit with level 1 + imprint bonus
		var unit = UnitInstance.new(unit_data, 1 + imprint_level)
		player_units.append(unit)

	# Load enemy units (random from available pool)
	_generate_enemy_team()

func _generate_enemy_team():
	var all_unit_data: Array[UnitData] = []
	all_unit_data.append_array(PlayerData.unit_pool_3_star)
	all_unit_data.append_array(PlayerData.unit_pool_4_star)
	all_unit_data.append_array(PlayerData.unit_pool_5_star)

	if all_unit_data.is_empty():
		return

	# Create 5 random enemy units
	for i in range(5):
		var random_data = all_unit_data[randi() % all_unit_data.size()]
		var unit = UnitInstance.new(random_data, 2)
		enemy_units.append(unit)

func _show_no_units_message():
	# Hide game UI and show message
	if results_panel:
		results_panel.visible = true
		result_title.text = "NO UNITS!"
		result_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
		result_subtitle.text = "Visit Summon to get units first."
		play_again_button.visible = false
		if end_turn_button:
			end_turn_button.visible = false

func _create_roster_displays():
	var y_offset = 0
	for i in range(player_units.size()):
		var unit = player_units[i]
		var display = UnitDisplayScene.instantiate()
		player_roster.add_child(display)
		display.position = Vector2(60, 60 + y_offset)
		display.setup(unit)
		display.scale = Vector2(0.7, 0.7)

		# Connect click and drag signals for player roster units
		display.unit_clicked.connect(_on_roster_unit_clicked)
		display.unit_drag_started.connect(_on_roster_drag_started)
		roster_displays.append(display)

		y_offset += 110

	y_offset = 0
	for unit in enemy_units:
		var display = UnitDisplayScene.instantiate()
		enemy_roster.add_child(display)
		display.position = Vector2(60, 60 + y_offset)
		display.setup(unit)
		display.scale = Vector2(0.7, 0.7)
		display.drag_enabled = false  # Enemies can't be dragged
		y_offset += 110

func _on_cell_clicked(row: int, col: int):
	if current_phase != GamePhase.PLAYER_TURN:
		print("Not your turn!")
		return

	var cell_unit = grid_units[row][col]

	# Check if clicking on a pending placement - select it for editing or cancel
	for i in range(player_pending_placements.size()):
		var pending = player_pending_placements[i]
		if pending.row == row and pending.col == col:
			if pending_edit_unit == pending.unit:
				# Already editing this unit - cancel the placement
				pending_edit_unit = null
				_cancel_pending_placement(i)
			else:
				# Select this pending unit for editing
				pending_edit_unit = pending.unit
				selected_unit = null
				moving_unit = null
				moving_from = {}
				_update_ability_panel()
				print("Editing pending: ", pending.unit.unit_data.unit_name)
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
		_update_ability_panel()
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

		# Can't move onto your own unit
		if cell_unit != null and cell_unit.owner == 1:
			print("Can't move onto your own unit!")
			return

		# Queue the move (to empty cell or enemy cell for challenge)
		_queue_move(moving_unit, moving_from.row, moving_from.col, row, col)
		moving_unit = null
		moving_from = {}
		return

	# If we have a selected unit from roster
	if selected_unit:
		# Check if there's already a pending placement here
		for pending in player_pending_placements:
			if pending.row == row and pending.col == col:
				print("Already have a pending placement there!")
				return

		# Allow placing on empty cells, enemy-occupied cells (challenge), or cells being vacated
		var cell_available = cell_unit == null or cell_unit.owner == 2 or _is_cell_being_vacated(row, col)
		if cell_available:
			_queue_placement(selected_unit, row, col)
			selected_unit = null
		else:
			print("Can't place on your own unit!")

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

	# Select this unit for ability editing
	selected_unit = null
	pending_edit_unit = unit
	_update_ability_panel()

	actions_remaining -= 1
	_update_ui()

	var ability_name = unit.unit_data.abilities[unit.selected_ability_index].ability_name if unit.unit_data.abilities.size() > 0 else "Strike"
	print("Queued ", unit.unit_data.unit_name, " (", ability_name, ") at (", row, ", ", col, ")")

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

	# Hide ability panel
	moving_unit = null
	moving_from = {}
	_update_ability_panel()

	actions_remaining -= 1
	_update_ui()

	var ability_name = unit.unit_data.abilities[unit.selected_ability_index].ability_name if unit.unit_data.abilities.size() > 0 else "Strike"
	print("Queued move: ", unit.unit_data.unit_name, " (", ability_name, ") from (", from_row, ",", from_col, ") to (", to_row, ",", to_col, ")")

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

	# Clear any editing state
	pending_edit_unit = null
	selected_unit = null
	moving_unit = null
	moving_from = {}
	_update_ability_panel()

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

		# Enemy picks a random ability
		if unit.unit_data.abilities.size() > 0:
			unit.selected_ability_index = randi() % unit.unit_data.abilities.size()

		enemy_pending_placements.append({
			"unit": unit,
			"row": cell.row,
			"col": cell.col
		})
		unit.place_on_grid(cell.row, cell.col)

		var ability_name = unit.unit_data.abilities[unit.selected_ability_index].ability_name if unit.unit_data.abilities.size() > 0 else "Strike"
		print("Enemy queued ", unit.unit_data.unit_name, " (", ability_name, ") at (", cell.row, ", ", cell.col, ")")

	await get_tree().create_timer(0.5).timeout

	_resolve_turn()

func _is_cell_being_vacated(row: int, col: int) -> bool:
	# Check if there's a pending move FROM this cell
	for move in player_pending_moves:
		if move.from_row == row and move.from_col == col:
			return true
	return false

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

	# Process field effects for all units on the grid
	print("Processing field effects...")
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var unit = grid_units[row][col]
			if unit and unit.is_alive():
				var field_result = process_field_effects_for_unit(unit, row, col)
				if field_result.damage > 0:
					unit.take_damage(field_result.damage)
					# Show damage on display
					if grid_unit_displays[row][col]:
						grid_unit_displays[row][col].show_damage_number(field_result.damage, false)
						grid_unit_displays[row][col].update_hp_display()
				if field_result.healing > 0:
					unit.heal(field_result.healing)
					if grid_unit_displays[row][col]:
						grid_unit_displays[row][col].show_damage_number(field_result.healing, true)
						grid_unit_displays[row][col].update_hp_display()

	# Process field effect durations
	_process_all_field_durations()

	# Check win condition
	var winner = _check_win_condition()
	if winner > 0:
		current_phase = GamePhase.GAME_OVER
		_show_results(winner)
		return

	# Process cooldowns and status effects
	for unit in player_units + enemy_units:
		var effect_result = unit.process_turn_end()
		# Update display if unit is on grid and took damage/healing from status effects
		if unit.is_placed() and (effect_result.damage > 0 or effect_result.healing > 0):
			var display = grid_unit_displays[unit.grid_row][unit.grid_col]
			if display:
				display.update_hp_display()
				display.update_status_display()

	# Update roster displays after combat
	_update_roster_displays()

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

	# Get selected abilities (nullify if disrupted)
	var p_ability = null if p_unit.is_disrupted() else p_unit.get_selected_ability()
	var e_ability = null if e_unit.is_disrupted() else e_unit.get_selected_ability()

	if p_unit.is_disrupted():
		print("  ", p_unit.unit_data.unit_name, " is DISRUPTED - cannot use ability!")
	if e_unit.is_disrupted():
		print("  ", e_unit.unit_data.unit_name, " is DISRUPTED - cannot use ability!")

	var p_ability_name = p_ability.ability_name if p_ability else "Strike"
	var e_ability_name = e_ability.ability_name if e_ability else "Strike"

	print("DUEL at (", row, ", ", col, "): ", p_unit.unit_data.unit_name, " (", p_ability_name, ") vs ", e_unit.unit_data.unit_name, " (", e_ability_name, ")")

	# Show combat announcement
	var announcement = p_unit.unit_data.unit_name + " vs " + e_unit.unit_data.unit_name + "!"
	_show_combat_announcement(announcement, 0.8)

	# Put abilities on cooldown after use (only if not disrupted)
	if not p_unit.is_disrupted():
		p_unit.put_ability_on_cooldown(p_ability)
	if not e_unit.is_disrupted():
		e_unit.put_ability_on_cooldown(e_ability)

	# Calculate base damage
	var p_base_attack = p_unit.unit_data.attack
	var e_base_attack = e_unit.unit_data.attack
	var p_base_defense = p_unit.unit_data.defense
	var e_base_defense = e_unit.unit_data.defense

	# Get status effect modifiers
	var p_status_mods = p_unit.get_stat_modifiers_from_effects()
	var e_status_mods = e_unit.get_stat_modifiers_from_effects()

	# Get field effect modifiers
	var p_field_mods = get_field_stat_modifiers(row, col, 1)
	var e_field_mods = get_field_stat_modifiers(row, col, 2)

	# Apply ability modifiers
	var p_damage_mult = p_ability.damage_multiplier if p_ability else 1.0
	var e_damage_mult = e_ability.damage_multiplier if e_ability else 1.0
	var p_defense_mult = p_ability.defense_multiplier if p_ability else 1.0
	var e_defense_mult = e_ability.defense_multiplier if e_ability else 1.0
	var p_bonus_damage = p_ability.bonus_damage if p_ability else 0
	var e_bonus_damage = e_ability.bonus_damage if e_ability else 0
	var p_piercing = p_ability.piercing if p_ability else false
	var e_piercing = e_ability.piercing if e_ability else false
	var p_ignores_element = p_ability.ignores_element if p_ability else false
	var e_ignores_element = e_ability.ignores_element if e_ability else false
	var p_guaranteed_survive = p_ability.guaranteed_survive if p_ability else false
	var e_guaranteed_survive = e_ability.guaranteed_survive if e_ability else false
	var p_heal = p_ability.heal_amount if p_ability else 0
	var e_heal = e_ability.heal_amount if e_ability else 0

	# Calculate element multipliers
	var p_element_mult = 1.0 if p_ignores_element else p_unit.unit_data.get_element_multiplier(e_unit.unit_data.element)
	var e_element_mult = 1.0 if e_ignores_element else e_unit.unit_data.get_element_multiplier(p_unit.unit_data.element)

	# Calculate effective stats with all modifiers
	var p_effective_attack = int(p_base_attack * p_status_mods.attack * p_field_mods.attack)
	var e_effective_attack = int(e_base_attack * e_status_mods.attack * e_field_mods.attack)
	var p_effective_defense = int(p_base_defense * p_status_mods.defense * p_field_mods.defense)
	var e_effective_defense = int(e_base_defense * e_status_mods.defense * e_field_mods.defense)

	# Calculate final damage (apply ability multipliers and element)
	var p_attack_power = int(p_effective_attack * p_damage_mult * p_element_mult) + p_bonus_damage
	var e_attack_power = int(e_effective_attack * e_damage_mult * e_element_mult) + e_bonus_damage

	# Apply defense (unless piercing)
	var p_damage_taken = e_attack_power
	var e_damage_taken = p_attack_power

	if not e_piercing:
		p_damage_taken = max(1, e_attack_power - int(p_effective_defense * p_defense_mult))
	if not p_piercing:
		e_damage_taken = max(1, p_attack_power - int(e_effective_defense * e_defense_mult))

	# Apply shield absorption before damage
	p_damage_taken = p_unit.absorb_damage_with_shield(p_damage_taken)
	e_damage_taken = e_unit.absorb_damage_with_shield(e_damage_taken)

	print("  Player deals ", e_damage_taken, ", takes ", p_damage_taken)

	# Get display at this position for visual effects
	var display = grid_unit_displays[row][col]

	# Apply damage with visual feedback
	e_unit.take_damage(e_damage_taken)
	p_unit.take_damage(p_damage_taken)

	# Show damage numbers
	if display:
		display.show_damage_number(p_damage_taken, false)
		display.flash_color(Color(1, 0.5, 0.5), 0.3)
		display.update_hp_display()

	# Apply guaranteed survive
	if p_guaranteed_survive and p_unit.current_hp <= 0:
		p_unit.current_hp = 1
		print("  Player survives with Nature's Resilience!")
		if display:
			display.show_damage_number(1, true)  # Show survival
	if e_guaranteed_survive and e_unit.current_hp <= 0:
		e_unit.current_hp = 1
		print("  Enemy survives with ability!")

	# Apply healing after combat with visual feedback
	if p_heal > 0:
		p_unit.heal(p_heal)
		print("  Player heals for ", p_heal)
		if display:
			display.show_damage_number(p_heal, true)
			display.update_hp_display()
	if e_heal > 0:
		e_unit.heal(e_heal)
		print("  Enemy heals for ", e_heal)

	# Apply status effects from abilities
	if p_ability and p_ability.applies_status_effect:
		if p_ability.applies_to_self:
			p_unit.apply_status_effect(p_ability.applies_status_effect, 1)
		else:
			e_unit.apply_status_effect(p_ability.applies_status_effect, 1)
	if e_ability and e_ability.applies_status_effect:
		if e_ability.applies_to_self:
			e_unit.apply_status_effect(e_ability.applies_status_effect, 2)
		else:
			p_unit.apply_status_effect(e_ability.applies_status_effect, 2)

	# Apply field effects from abilities
	if p_ability and p_ability.applies_field_effect:
		apply_field_effect(row, col, p_ability.applies_field_effect, 1)
	if e_ability and e_ability.applies_field_effect:
		apply_field_effect(row, col, e_ability.applies_field_effect, 2)

	# Determine winner
	var winner_unit: UnitInstance = null
	var winner_owner: int = 0

	if p_unit.current_hp <= 0 and e_unit.current_hp <= 0:
		print("  Both units knocked out! Square remains empty.")
		p_unit.remove_from_grid()
		e_unit.remove_from_grid()
		p_unit.start_cooldown()
		e_unit.start_cooldown()
		if grid_unit_displays[row][col]:
			grid_unit_displays[row][col].queue_free()
			grid_unit_displays[row][col] = null
	elif p_unit.current_hp <= 0:
		print("  Enemy wins the duel!")
		winner_unit = e_unit
		winner_owner = 2
		p_unit.remove_from_grid()
		p_unit.start_cooldown()
	elif e_unit.current_hp <= 0:
		print("  Player wins the duel!")
		winner_unit = p_unit
		winner_owner = 1
		e_unit.remove_from_grid()
		e_unit.start_cooldown()
	else:
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

	# Connect drag signals for player units on the grid
	if owner == 1:
		display.unit_drag_started.connect(_on_grid_unit_drag_started.bind(row, col))
		display.unit_clicked.connect(_on_grid_unit_clicked.bind(row, col))
	else:
		display.drag_enabled = false  # Enemies can't be dragged

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
	# Handle mouse release for drag-and-drop globally
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if dragging_unit:
				_handle_drag_release()

	if current_phase != GamePhase.PLAYER_TURN:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				selected_unit = null
				moving_unit = null
				moving_from = {}
				pending_edit_unit = null
				_clear_drag_state()
				_update_ability_panel()
				_update_roster_selection()
				print("Deselected")
			KEY_ENTER, KEY_SPACE:
				_on_end_turn_pressed()

func _handle_drag_release():
	# Find and restore the source display
	if dragging_from_grid:
		# Restore grid display
		var row = dragging_from_pos.row
		var col = dragging_from_pos.col
		if grid_unit_displays[row][col]:
			grid_unit_displays[row][col].modulate = Color(1, 1, 1, 1)
	else:
		# Restore roster display
		for display in roster_displays:
			if display.unit_instance == dragging_unit:
				display.modulate = Color(1, 1, 1, 1)
				display.is_dragging = false
				break

	# Check if dropped on a valid cell
	var drop_cell = _get_cell_at_mouse()
	if drop_cell:
		if dragging_from_grid:
			if drop_cell.row != dragging_from_pos.row or drop_cell.col != dragging_from_pos.col:
				_handle_drop_on_cell(drop_cell.row, drop_cell.col)
			else:
				print("Dropped on same cell - cancelled")
		else:
			_handle_drop_on_cell(drop_cell.row, drop_cell.col)
	else:
		print("Dropped outside grid - cancelled")

	# Clean up drag state
	_clear_drag_state()

func _on_ability_selected(index: int):
	var active_unit = _get_active_unit_for_ability()
	if active_unit and active_unit.unit_data.abilities.size() > index:
		# Check if ability is available (not on cooldown)
		if not active_unit.is_ability_available(index):
			print("Ability on cooldown!")
			return
		active_unit.selected_ability_index = index
		_update_ability_panel()
		print("Selected ability: ", active_unit.unit_data.abilities[index].ability_name)

func _get_active_unit_for_ability() -> UnitInstance:
	# Check for pending unit being edited first
	if pending_edit_unit:
		return pending_edit_unit
	if selected_unit:
		return selected_unit
	if moving_unit:
		return moving_unit
	return null

func _update_ability_panel():
	var active_unit = _get_active_unit_for_ability()

	if active_unit and ability_panel:
		ability_panel.visible = true

		# Update button labels and highlight selected
		for i in range(ability_buttons.size()):
			var btn = ability_buttons[i]
			if btn and active_unit.unit_data.abilities.size() > i:
				var ability = active_unit.unit_data.abilities[i]
				var cd = active_unit.get_ability_cooldown(i)

				# Show cooldown on button if on cooldown
				if cd > 0:
					btn.text = ability.ability_name + " (" + str(cd) + ")"
					btn.disabled = true
					btn.modulate = Color(0.5, 0.5, 0.5)
				else:
					btn.text = ability.ability_name
					btn.disabled = false
					# Highlight selected ability
					if i == active_unit.selected_ability_index:
						btn.modulate = Color(1, 1, 0.5)  # Yellow tint
					else:
						btn.modulate = Color(1, 1, 1)
			elif btn:
				btn.text = "---"
				btn.disabled = true
				btn.modulate = Color(0.5, 0.5, 0.5)

		# Update description
		if ability_desc and active_unit.unit_data.abilities.size() > active_unit.selected_ability_index:
			var ability = active_unit.unit_data.abilities[active_unit.selected_ability_index]
			var cd_text = ""
			if ability.cooldown > 0:
				cd_text = " [CD: " + str(ability.cooldown) + "]"
			ability_desc.text = ability.description + cd_text
	elif ability_panel:
		ability_panel.visible = false

func _try_select_unit(index: int):
	if index >= player_units.size():
		return

	var unit = player_units[index]
	if unit.can_act() and not unit.is_placed():
		selected_unit = unit
		moving_unit = null
		moving_from = {}
		_update_ability_panel()
		print("Selected: ", unit.unit_data.unit_name)
	else:
		if unit.is_placed():
			print(unit.unit_data.unit_name, " is already on the grid")
		elif unit.is_on_cooldown:
			print(unit.unit_data.unit_name, " is on cooldown")

# --- Roster Click and Drag Handlers ---

func _on_roster_unit_clicked(unit: UnitInstance, _display: Node2D):
	if current_phase != GamePhase.PLAYER_TURN:
		print("Not your turn!")
		return

	if unit.can_act() and not unit.is_placed():
		selected_unit = unit
		moving_unit = null
		moving_from = {}
		pending_edit_unit = null
		_update_ability_panel()
		_update_roster_selection()
		print("Selected: ", unit.unit_data.unit_name)
	else:
		if unit.is_placed():
			print(unit.unit_data.unit_name, " is already on the grid")
		elif unit.is_on_cooldown:
			print(unit.unit_data.unit_name, " is on cooldown")

func _on_roster_drag_started(unit: UnitInstance, display: Node2D):
	if current_phase != GamePhase.PLAYER_TURN:
		return

	if actions_remaining <= 0:
		print("No actions remaining!")
		return

	if unit.can_act() and not unit.is_placed():
		dragging_unit = unit
		dragging_from_grid = false
		dragging_from_pos = {}

		# Create drag preview
		_create_drag_preview(unit)

		# Dim the source display
		display.modulate = Color(1, 1, 1, 0.4)

		selected_unit = unit
		pending_edit_unit = null  # Clear any pending edit
		_update_ability_panel()
		print("Dragging: ", unit.unit_data.unit_name)

func _on_grid_unit_clicked(unit: UnitInstance, _display: Node2D, row: int, col: int):
	if current_phase != GamePhase.PLAYER_TURN:
		print("Not your turn!")
		return

	if unit.owner == 1:
		# Select this unit for moving
		moving_unit = unit
		moving_from = {"row": row, "col": col}
		selected_unit = null
		_update_ability_panel()
		_update_roster_selection()
		print("Selected ", unit.unit_data.unit_name, " for moving (click grid to move)")

func _on_grid_unit_drag_started(unit: UnitInstance, display: Node2D, row: int, col: int):
	if current_phase != GamePhase.PLAYER_TURN:
		return

	if actions_remaining <= 0:
		print("No actions remaining!")
		return

	if unit.owner == 1:
		dragging_unit = unit
		dragging_from_grid = true
		dragging_from_pos = {"row": row, "col": col}

		# Create drag preview
		_create_drag_preview(unit)

		# Dim the source display
		display.modulate = Color(1, 1, 1, 0.4)

		moving_unit = unit
		moving_from = {"row": row, "col": col}
		_update_ability_panel()
		print("Dragging from grid: ", unit.unit_data.unit_name)

func _create_drag_preview(unit: UnitInstance):
	if drag_preview:
		drag_preview.queue_free()

	drag_preview = UnitDisplayScene.instantiate()
	add_child(drag_preview)
	drag_preview.setup(unit)
	drag_preview.scale = Vector2(0.6, 0.6)
	drag_preview.modulate = Color(1, 1, 1, 0.7)
	drag_preview.z_index = 100  # Draw on top
	drag_preview.drag_enabled = false  # Don't intercept input
	# Disable click area on preview
	if drag_preview.has_node("ClickArea"):
		drag_preview.get_node("ClickArea").input_pickable = false

func _clear_drag_state():
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

	dragging_unit = null
	dragging_from_grid = false
	dragging_from_pos = {}

func _get_cell_at_mouse() -> Dictionary:
	var mouse_pos = get_global_mouse_position()
	var grid_pos = grid_container.global_position

	var grid_total_size = (CELL_SIZE * GRID_SIZE) + (CELL_GAP * (GRID_SIZE - 1))
	var offset = -grid_total_size / 2

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var cell_x = grid_pos.x + offset + (col * (CELL_SIZE + CELL_GAP))
			var cell_y = grid_pos.y + offset + (row * (CELL_SIZE + CELL_GAP))

			if mouse_pos.x >= cell_x and mouse_pos.x < cell_x + CELL_SIZE:
				if mouse_pos.y >= cell_y and mouse_pos.y < cell_y + CELL_SIZE:
					return {"row": row, "col": col}

	return {}

func _handle_drop_on_cell(row: int, col: int):
	if dragging_from_grid:
		# Moving from grid
		var cell_unit = grid_units[row][col]

		# Check pending placements
		for pending in player_pending_placements:
			if pending.row == row and pending.col == col:
				print("Already have a pending placement there!")
				return

		# Can't move onto own unit
		if cell_unit != null and cell_unit.owner == 1:
			print("Can't move onto your own unit!")
			return

		# Queue the move
		_queue_move(dragging_unit, dragging_from_pos.row, dragging_from_pos.col, row, col)
	else:
		# Placing from roster
		var cell_unit = grid_units[row][col]

		# Check pending placements
		for pending in player_pending_placements:
			if pending.row == row and pending.col == col:
				print("Already have a pending placement there!")
				return

		# Allow empty, enemy cell, or cell being vacated
		var cell_available = cell_unit == null or cell_unit.owner == 2 or _is_cell_being_vacated(row, col)
		if cell_available:
			_queue_placement(dragging_unit, row, col)
		else:
			print("Can't place on your own unit!")

func _process(_delta: float):
	# Update drag preview position
	if drag_preview and dragging_unit:
		drag_preview.global_position = get_global_mouse_position()

func _update_roster_selection():
	# Update visual selection on roster
	for display in roster_displays:
		if display.unit_instance == selected_unit:
			display.set_selected(true)
		else:
			display.set_selected(false)

func _show_results(winner: int):
	if results_panel:
		results_panel.visible = true

		if winner == 1:
			result_title.text = "VICTORY!"
			result_title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			result_subtitle.text = "You won in " + str(current_turn) + " turns!"
		else:
			result_title.text = "DEFEAT"
			result_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			result_subtitle.text = "Better luck next time!"

		# Hide other UI elements
		if ability_panel:
			ability_panel.visible = false
		if end_turn_button:
			end_turn_button.visible = false

		print("Game Over! Winner: ", "Player" if winner == 1 else "Enemy")

func _on_play_again_pressed():
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _show_combat_announcement(text: String, duration: float = 1.0):
	if combat_announcement:
		combat_announcement.text = text
		combat_announcement.visible = true
		combat_announcement.modulate = Color(1, 1, 1, 1)

		var tween = create_tween()
		tween.tween_interval(duration * 0.7)
		tween.tween_property(combat_announcement, "modulate:a", 0.0, duration * 0.3)
		tween.tween_callback(func(): combat_announcement.visible = false)

func _update_roster_displays():
	# Update all player roster displays to show current HP/cooldowns
	for display in roster_displays:
		if display and display.unit_instance:
			display.update_hp_display()
			display.update_cooldown_display()

# --- Field Effect Methods ---

func apply_field_effect(row: int, col: int, field_data: FieldEffectData, effect_owner: int):
	if not field_data:
		return

	# Check if this field effect already exists on this cell
	var cell_effects = grid_field_effects[row][col]
	for i in range(cell_effects.size()):
		var existing = cell_effects[i]
		if existing.field_data.field_id == field_data.field_id:
			# Refresh duration
			existing.duration = field_data.base_duration
			print("  Refreshed ", field_data.field_name, " at (", row, ",", col, ")")
			return

	# Add new field effect
	var new_effect = {
		"field_data": field_data,
		"duration": field_data.base_duration,
		"owner": effect_owner
	}
	cell_effects.append(new_effect)
	print("  Applied ", field_data.field_name, " at (", row, ",", col, ") for ", field_data.base_duration, " turns")

	# Update visual on the cell
	if grid_cells[row][col]:
		grid_cells[row][col].show_field_effect(field_data)

func get_field_stat_modifiers(row: int, col: int, unit_owner: int) -> Dictionary:
	var mods = {"attack": 1.0, "defense": 1.0}

	if row < 0 or col < 0 or row >= GRID_SIZE or col >= GRID_SIZE:
		return mods

	var cell_effects = grid_field_effects[row][col]
	for effect in cell_effects:
		var data = effect.field_data as FieldEffectData
		var effect_owner = effect.owner

		# Determine if this unit is affected
		var is_ally = (unit_owner == effect_owner)
		var should_affect = false

		if is_ally and data.affects_allies:
			should_affect = true
		elif not is_ally and data.affects_enemies:
			should_affect = true

		if should_affect:
			mods.attack *= data.attack_modifier
			mods.defense *= data.defense_modifier

	return mods

func process_field_effects_for_unit(unit: UnitInstance, row: int, col: int) -> Dictionary:
	var result = {"damage": 0, "healing": 0}

	if row < 0 or col < 0 or row >= GRID_SIZE or col >= GRID_SIZE:
		return result

	var cell_effects = grid_field_effects[row][col]
	for effect in cell_effects:
		var data = effect.field_data as FieldEffectData
		var effect_owner = effect.owner

		# Determine if this unit is affected
		var is_ally = (unit.owner == effect_owner)
		var should_affect = false

		if is_ally and data.affects_allies:
			should_affect = true
		elif not is_ally and data.affects_enemies:
			should_affect = true

		if should_affect:
			if data.damage_per_turn > 0:
				result.damage += data.damage_per_turn
				print("  ", unit.unit_data.unit_name, " takes ", data.damage_per_turn, " ", data.field_name, " damage")
			if data.heal_per_turn > 0:
				result.healing += data.heal_per_turn
				print("  ", unit.unit_data.unit_name, " heals ", data.heal_per_turn, " from ", data.field_name)

	return result

func _process_all_field_durations():
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var cell_effects = grid_field_effects[row][col]
			var effects_to_remove = []

			for i in range(cell_effects.size()):
				var effect = cell_effects[i]
				effect.duration -= 1

				if effect.duration <= 0:
					effects_to_remove.append(i)
					print("  ", effect.field_data.field_name, " expired at (", row, ",", col, ")")

			# Remove expired effects (in reverse order)
			for i in range(effects_to_remove.size() - 1, -1, -1):
				cell_effects.remove_at(effects_to_remove[i])

			# Update visual
			if grid_cells[row][col]:
				if cell_effects.is_empty():
					grid_cells[row][col].clear_field_effect()
				else:
					# Show the most recent field effect
					grid_cells[row][col].show_field_effect(cell_effects[-1].field_data)
