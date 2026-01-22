extends Node2D
## Main battle scene controller
## Manages the 3x3 grid, turns, and battle flow

# Grid settings
const GRID_SIZE = 3
const CELL_SIZE = 170  # Base cell size (adjusted for new grid image)
const CELL_GAP = 115   # Gap between cells (spread out more)

# Perspective settings for 2.5D effect (disabled for flat AI grid)
const PERSPECTIVE_SCALE_TOP = 1.0      # Scale for top row (1.0 = no perspective)
const PERSPECTIVE_SCALE_BOTTOM = 1.0   # Scale for bottom row
const PERSPECTIVE_Y_SQUEEZE = 1.0      # Vertical compression (1.0 = none)
const PERSPECTIVE_Y_OFFSET = 0         # No offset needed
const MIDDLE_ROW_EXTRA_OFFSET = 50     # Push middle row down
const BOTTOM_ROW_EXTRA_OFFSET = 110    # Push bottom row down more
const ACTIONS_PER_TURN = 2
const MAX_TURNS = 50  # Turn limit to prevent infinite stalemates
const KNOCKOUTS_TO_WIN = 3  # Knock out this many enemy units to win

# AI Difficulty
enum AIDifficulty { EASY, MEDIUM, HARD }
var ai_difficulty: AIDifficulty = AIDifficulty.MEDIUM

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
@onready var cheat_menu = $CheatMenu
@onready var auto_button = $UI/BottomBar/AutoButton
@onready var speed_1x_btn = $UI/BottomBar/Speed1xButton
@onready var speed_2x_btn = $UI/BottomBar/Speed2xButton
@onready var speed_3x_btn = $UI/BottomBar/Speed3xButton

# Game state
enum GamePhase { PLAYER_TURN, ENEMY_TURN, RESOLVING, GAME_OVER }
var current_phase: GamePhase = GamePhase.PLAYER_TURN
var current_turn: int = 1
var actions_remaining: int = ACTIONS_PER_TURN

# Knockout tracking
var player_knockouts: int = 0  # Enemy units knocked out by player
var enemy_knockouts: int = 0   # Player units knocked out by enemy

# Auto-battle settings
var auto_battle_enabled: bool = false
var battle_speed: float = 1.0  # 1.0 = normal, 0.5 = 2x, 0.25 = 3x

# Grid state
var grid_cells: Array = []
var grid_ownership: Array = []  # 0 = empty, 1 = player only, 2 = enemy only, 3 = contested
var grid_player_units: Array = []  # 2D array of player UnitInstance or null
var grid_enemy_units: Array = []   # 2D array of enemy UnitInstance or null
var grid_player_displays: Array = []  # 2D array of player unit displays
var grid_enemy_displays: Array = []   # 2D array of enemy unit displays
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
var AbilityTooltipScene = preload("res://scenes/battle/ability_tooltip.tscn")

# Ability tooltip instance
var ability_tooltip: Control = null

func _ready():
	_create_grid()
	_load_units()
	_create_roster_displays()
	_update_ui()

	# Create ability tooltip
	ability_tooltip = AbilityTooltipScene.instantiate()
	$UI.add_child(ability_tooltip)
	ability_tooltip.ability_selected.connect(_on_tooltip_ability_selected)
	ability_tooltip.dismissed.connect(_on_tooltip_dismissed)

	# Hide old ability panel (keeping for fallback)
	if ability_panel:
		ability_panel.visible = false

	# Connect end turn button
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Connect ability buttons (legacy - keep for compatibility)
	for i in range(ability_buttons.size()):
		var btn = ability_buttons[i]
		if btn:
			btn.pressed.connect(_on_ability_selected.bind(i))

	# Connect results panel buttons
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

	# Setup cheat menu
	if cheat_menu:
		cheat_menu.setup(self)

	# Connect auto-battle controls
	if auto_button:
		auto_button.pressed.connect(_on_auto_toggle)
	if speed_1x_btn:
		speed_1x_btn.pressed.connect(_set_battle_speed.bind(1.0))
	if speed_2x_btn:
		speed_2x_btn.pressed.connect(_set_battle_speed.bind(0.5))
	if speed_3x_btn:
		speed_3x_btn.pressed.connect(_set_battle_speed.bind(0.25))
	_update_speed_buttons()
	_update_auto_button()

	# Apply theme styling
	_apply_battle_theme()

func _get_perspective_scale(row: int) -> float:
	# Interpolate scale based on row (0 = top/far, 2 = bottom/near)
	var t = float(row) / float(GRID_SIZE - 1)
	return lerp(PERSPECTIVE_SCALE_TOP, PERSPECTIVE_SCALE_BOTTOM, t)

func _get_cell_position(row: int, col: int) -> Vector2:
	# Calculate position with perspective
	var row_scale = _get_perspective_scale(row)

	# Base grid calculation
	var base_cell_size = CELL_SIZE * row_scale
	var base_gap = CELL_GAP * row_scale

	# X position (centered, scaled per row for perspective convergence)
	var row_width = (base_cell_size * GRID_SIZE) + (base_gap * (GRID_SIZE - 1))
	var x_offset = -row_width / 2
	var x = x_offset + (col * (base_cell_size + base_gap)) + base_cell_size / 2

	# Y position (compressed vertically for isometric look)
	var y_spacing = CELL_SIZE * PERSPECTIVE_Y_SQUEEZE
	var total_height = y_spacing * (GRID_SIZE - 1)
	var y = -total_height / 2 + (row * y_spacing) + PERSPECTIVE_Y_OFFSET

	# Add extra offset for middle and bottom rows
	if row == 1:
		y += MIDDLE_ROW_EXTRA_OFFSET
	elif row == GRID_SIZE - 1:
		y += BOTTOM_ROW_EXTRA_OFFSET

	return Vector2(x, y)

func _get_cell_size_for_row(row: int) -> float:
	return CELL_SIZE * _get_perspective_scale(row)

func _create_grid():
	grid_ownership = []
	grid_cells = []
	grid_player_units = []
	grid_enemy_units = []
	grid_player_displays = []
	grid_enemy_displays = []
	grid_field_effects = []

	for row in range(GRID_SIZE):
		var cell_row = []
		var ownership_row = []
		var player_unit_row = []
		var enemy_unit_row = []
		var player_display_row = []
		var enemy_display_row = []
		var field_row = []

		var row_scale = _get_perspective_scale(row)
		var cell_size_for_row = _get_cell_size_for_row(row)

		for col in range(GRID_SIZE):
			var cell = GridCellScene.instantiate()
			grid_container.add_child(cell)

			var pos = _get_cell_position(row, col)
			cell.position = pos
			cell.scale = Vector2(row_scale, row_scale)

			cell.setup(row, col, int(cell_size_for_row))
			cell.cell_clicked.connect(_on_cell_clicked)

			cell_row.append(cell)
			ownership_row.append(0)
			player_unit_row.append(null)
			enemy_unit_row.append(null)
			player_display_row.append(null)
			enemy_display_row.append(null)
			field_row.append([])  # Empty array for field effects on this cell

		grid_cells.append(cell_row)
		grid_ownership.append(ownership_row)
		grid_player_units.append(player_unit_row)
		grid_enemy_units.append(enemy_unit_row)
		grid_player_displays.append(player_display_row)
		grid_enemy_displays.append(enemy_display_row)
		grid_field_effects.append(field_row)

func _update_cell_ownership(row: int, col: int):
	var has_player = grid_player_units[row][col] != null
	var has_enemy = grid_enemy_units[row][col] != null

	if has_player and has_enemy:
		grid_ownership[row][col] = 3  # Contested
	elif has_player:
		grid_ownership[row][col] = 1  # Player only
	elif has_enemy:
		grid_ownership[row][col] = 2  # Enemy only
	else:
		grid_ownership[row][col] = 0  # Empty

	grid_cells[row][col].set_ownership(grid_ownership[row][col])

func _get_unit_at_cell(row: int, col: int, owner: int) -> UnitInstance:
	if owner == 1:
		return grid_player_units[row][col]
	else:
		return grid_enemy_units[row][col]

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
		var unit_level = unit_entry.get("level", 1) as int
		var imprint_level = unit_entry.get("imprint_level", 0) as int
		var instance_id = unit_entry.get("instance_id", "") as String
		# Create unit with proper level, imprint, and gear reference
		var unit = UnitInstance.new(unit_data, 1, unit_level, imprint_level, instance_id)
		player_units.append(unit)

	# Load enemy units (random from available pool)
	_generate_enemy_team()

func _generate_enemy_team():
	# Check if in campaign mode
	if PlayerData.is_campaign_mode():
		_generate_campaign_enemies()
		return

	# Check if in dungeon mode
	if PlayerData.is_dungeon_mode():
		_generate_dungeon_enemies()
		return

	# Regular mode: random enemies
	var all_unit_data: Array[UnitData] = []
	all_unit_data.append_array(PlayerData.unit_pool_3_star)
	all_unit_data.append_array(PlayerData.unit_pool_4_star)
	all_unit_data.append_array(PlayerData.unit_pool_5_star)

	if all_unit_data.is_empty():
		return

	# Create 5 random enemy units (level 1, no imprint)
	for i in range(5):
		var random_data = all_unit_data[randi() % all_unit_data.size()]
		var unit = UnitInstance.new(random_data, 2, 1, 0)
		enemy_units.append(unit)

func _generate_campaign_enemies():
	var stage = PlayerData.current_stage
	if stage == null:
		print("Error: No stage data for campaign mode!")
		return

	print("Loading enemies for stage: ", stage.stage_id)

	# Create enemy units from stage configuration
	for enemy_data in stage.enemy_units:
		if enemy_data:
			# Create enemy with stage-appropriate level (owner=2, level=enemy_level, imprint=0)
			var unit = UnitInstance.new(enemy_data, 2, stage.enemy_level, 0)
			enemy_units.append(unit)
			print("  Added enemy: ", enemy_data.unit_name, " (Lv.", stage.enemy_level, ")")

	print("Total campaign enemies: ", enemy_units.size())

func _generate_dungeon_enemies():
	var dungeon = PlayerData.current_dungeon
	if dungeon == null:
		print("Error: No dungeon data!")
		return

	var tier = PlayerData.current_dungeon_tier
	var enemy_level = dungeon.get_enemy_level(tier)

	print("Loading enemies for dungeon: ", dungeon.dungeon_name, " (", dungeon.tier_names[tier], ")")

	# Use dungeon's enemy units if specified, otherwise random
	var enemy_pool = dungeon.enemy_units if dungeon.enemy_units.size() > 0 else []
	if enemy_pool.is_empty():
		enemy_pool.append_array(PlayerData.unit_pool_3_star)
		enemy_pool.append_array(PlayerData.unit_pool_4_star)

	# Create 3-5 enemies based on tier
	var enemy_count = 3 + tier
	for i in range(enemy_count):
		var enemy_data = enemy_pool[randi() % enemy_pool.size()]
		var unit = UnitInstance.new(enemy_data, 2, enemy_level, 0, "")
		enemy_units.append(unit)
		print("  Added enemy: ", enemy_data.unit_name, " (Lv.", enemy_level, ")")

	print("Total dungeon enemies: ", enemy_units.size())

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
		display.set_enemy(false)
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
		display.set_enemy(true)
		display.scale = Vector2(0.7, 0.7)
		display.drag_enabled = false  # Enemies can't be dragged
		y_offset += 110

func _on_cell_clicked(row: int, col: int):
	if current_phase != GamePhase.PLAYER_TURN:
		print("Not your turn!")
		return

	var player_unit = grid_player_units[row][col]

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
	if player_unit != null:
		# Select this unit for moving
		moving_unit = player_unit
		moving_from = {"row": row, "col": col}
		selected_unit = null  # Clear roster selection
		_update_ability_panel()
		print("Selected ", player_unit.unit_data.unit_name, " for moving")
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

		# Can't move onto your own unit (unless cell is being vacated)
		if player_unit != null and not _is_cell_being_vacated(row, col):
			print("Can't move onto your own unit!")
			return

		# Queue the move (can move to empty cell or enemy cell)
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

		# Can place on any cell that doesn't have your own unit (or is being vacated)
		var has_own_unit = player_unit != null and not _is_cell_being_vacated(row, col)
		if not has_own_unit:
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
	if grid_player_displays[from_row][from_col]:
		grid_player_displays[from_row][from_col].modulate = Color(1, 1, 1, 0.4)

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
	if grid_player_displays[row][col]:
		grid_player_displays[row][col].queue_free()
		grid_player_displays[row][col] = null

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
	if grid_player_displays[to_row][to_col]:
		grid_player_displays[to_row][to_col].queue_free()
		grid_player_displays[to_row][to_col] = null

	# Restore original position visual
	if grid_player_displays[from_row][from_col]:
		grid_player_displays[from_row][from_col].modulate = Color(1, 1, 1, 1)

	# Refund action
	actions_remaining += 1
	_update_ui()

	print("Cancelled move: ", unit.unit_data.unit_name)

func _show_placement_preview(unit: UnitInstance, row: int, col: int):
	var display = UnitDisplayScene.instantiate()
	grid_container.add_child(display)

	var pos = _get_cell_position(row, col)
	var row_scale = _get_perspective_scale(row)

	# Offset player units slightly left if there might be an enemy
	if grid_enemy_units[row][col] != null:
		pos.x -= 25 * row_scale

	display.position = pos
	display.scale = Vector2(0.7, 0.7) * row_scale
	display.setup(unit)
	display.set_enemy(false)
	display.modulate = Color(1, 1, 1, 0.7)  # Semi-transparent to show it's pending

	grid_player_displays[row][col] = display

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
	await get_tree().create_timer(get_scaled_time(0.5)).timeout

	_do_enemy_turn()

func _do_enemy_turn():
	print("Enemy is thinking... (Difficulty: ", AIDifficulty.keys()[ai_difficulty], ")")

	var available_cells = _get_cells_without_enemy()
	var available_units = enemy_units.filter(func(u): return u.can_act() and not u.is_placed())

	var ai_actions = min(ACTIONS_PER_TURN, min(available_cells.size(), available_units.size()))

	for i in range(ai_actions):
		if available_cells.is_empty() or available_units.is_empty():
			break

		var unit = available_units.pop_front()
		var cell = _select_cell_by_difficulty(available_cells)
		available_cells.erase(cell)

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

	await get_tree().create_timer(get_scaled_time(0.5)).timeout

	_resolve_turn()

func _select_cell_by_difficulty(available_cells: Array) -> Dictionary:
	if available_cells.is_empty():
		return {}

	# Score all available cells
	var scored_cells = []
	for cell in available_cells:
		var score = _evaluate_cell_priority(cell.row, cell.col)
		scored_cells.append({"cell": cell, "score": score})

	# Sort by score descending
	scored_cells.sort_custom(func(a, b): return a.score > b.score)

	var selected_cell: Dictionary

	match ai_difficulty:
		AIDifficulty.EASY:
			# 30% optimal, 70% random
			if randf() < 0.3:
				selected_cell = scored_cells[0].cell
			else:
				selected_cell = available_cells[randi() % available_cells.size()]

		AIDifficulty.MEDIUM:
			# 70% optimal, 30% random from top 3
			if randf() < 0.7:
				selected_cell = scored_cells[0].cell
			else:
				var top_count = min(3, scored_cells.size())
				selected_cell = scored_cells[randi() % top_count].cell

		AIDifficulty.HARD:
			# 95% optimal, always takes winning/blocking moves
			var top_score = scored_cells[0].score
			# Always take winning moves (100+) or blocking moves (90+)
			if top_score >= 90 or randf() < 0.95:
				selected_cell = scored_cells[0].cell
			else:
				var top_count = min(2, scored_cells.size())
				selected_cell = scored_cells[randi() % top_count].cell

	return selected_cell

func _is_cell_being_vacated(row: int, col: int) -> bool:
	# Check if there's a pending move FROM this cell
	for move in player_pending_moves:
		if move.from_row == row and move.from_col == col:
			return true
	return false

func _get_cells_without_enemy() -> Array:
	# Returns cells where enemy can place (no enemy unit already there)
	var available = []
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if grid_enemy_units[row][col] == null:
				# Also check pending enemy placements
				var is_pending = false
				for p in enemy_pending_placements:
					if p.row == row and p.col == col:
						is_pending = true
						break
				if not is_pending:
					available.append({"row": row, "col": col})
	return available

# --- AI Helper Functions ---

func _get_all_lines() -> Array:
	# Returns all 8 possible winning lines as arrays of cell coordinates
	var lines = []
	# Rows
	for row in range(GRID_SIZE):
		lines.append([{"row": row, "col": 0}, {"row": row, "col": 1}, {"row": row, "col": 2}])
	# Columns
	for col in range(GRID_SIZE):
		lines.append([{"row": 0, "col": col}, {"row": 1, "col": col}, {"row": 2, "col": col}])
	# Diagonals
	lines.append([{"row": 0, "col": 0}, {"row": 1, "col": 1}, {"row": 2, "col": 2}])
	lines.append([{"row": 0, "col": 2}, {"row": 1, "col": 1}, {"row": 2, "col": 0}])
	return lines

func _count_line_ownership(line: Array) -> Dictionary:
	# Counts ownership in a line: player (1), enemy (2), empty (0), contested (3)
	var counts = {"player": 0, "enemy": 0, "empty": 0, "contested": 0}
	for cell in line:
		var ownership = grid_ownership[cell.row][cell.col]
		match ownership:
			0: counts.empty += 1
			1: counts.player += 1
			2: counts.enemy += 1
			3: counts.contested += 1
	return counts

func _get_lines_containing_cell(row: int, col: int) -> Array:
	# Returns all lines that include the given cell
	var all_lines = _get_all_lines()
	var matching_lines = []
	for line in all_lines:
		for cell in line:
			if cell.row == row and cell.col == col:
				matching_lines.append(line)
				break
	return matching_lines

func _evaluate_cell_priority(row: int, col: int) -> int:
	# Scores a cell based on strategic value for the AI (enemy)
	var score = 0
	var lines = _get_lines_containing_cell(row, col)

	for line in lines:
		var counts = _count_line_ownership(line)

		# Can win: 2 enemy + 1 empty (this cell must be the empty one)
		if counts.enemy == 2 and counts.empty == 1:
			score += 100

		# Must block: 2 player + 1 empty
		if counts.player == 2 and counts.empty == 1:
			score += 90

		# Build threat: 1 enemy + 2 empty
		if counts.enemy == 1 and counts.empty == 2:
			score += 30

	# Positional bonuses
	if row == 1 and col == 1:
		score += 20  # Center
	elif (row == 0 or row == 2) and (col == 0 or col == 2):
		score += 10  # Corner
	else:
		score += 5   # Edge

	return score

func _resolve_turn():
	print("=== Resolving Turn ===")
	current_phase = GamePhase.RESOLVING
	_update_ui()

	# First, process player moves (vacate old squares)
	for move in player_pending_moves:
		var from_row = move.from_row
		var from_col = move.from_col

		# Clear the original position
		grid_player_units[from_row][from_col] = null

		# Remove old display
		if grid_player_displays[from_row][from_col]:
			grid_player_displays[from_row][from_col].queue_free()
			grid_player_displays[from_row][from_col] = null

		_update_cell_ownership(from_row, from_col)

		# Add move destination as a pending placement
		player_pending_placements.append({
			"unit": move.unit,
			"row": move.to_row,
			"col": move.to_col
		})

		print("Executed move: ", move.unit.unit_data.unit_name, " vacated (", from_row, ",", from_col, ")")

	# Place all player units from pending placements
	for placement in player_pending_placements:
		_confirm_placement(placement.unit, placement.row, placement.col, 1)

	# Place all enemy units from pending placements
	for placement in enemy_pending_placements:
		_confirm_placement(placement.unit, placement.row, placement.col, 2)

	# Clear pending actions
	player_pending_placements.clear()
	player_pending_moves.clear()
	enemy_pending_placements.clear()

	# Find ALL contested squares and resolve combat
	print("Resolving combat on contested squares...")
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var p_unit = grid_player_units[row][col]
			var e_unit = grid_enemy_units[row][col]
			if p_unit != null and e_unit != null and p_unit.is_alive() and e_unit.is_alive():
				await _resolve_duel(row, col, p_unit, e_unit)

	# Process field effects for all units on the grid
	print("Processing field effects...")
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			# Process for player unit
			var p_unit = grid_player_units[row][col]
			if p_unit and p_unit.is_alive():
				var field_result = process_field_effects_for_unit(p_unit, row, col)
				if field_result.damage > 0:
					p_unit.take_damage(field_result.damage)
					if grid_player_displays[row][col]:
						grid_player_displays[row][col].show_damage_number(field_result.damage, false)
						grid_player_displays[row][col].update_hp_display()
				if field_result.healing > 0:
					p_unit.heal(field_result.healing)
					if grid_player_displays[row][col]:
						grid_player_displays[row][col].show_damage_number(field_result.healing, true)
						grid_player_displays[row][col].update_hp_display()
				# Check if unit died from field effect
				if not p_unit.is_alive():
					_remove_unit_from_grid(p_unit, row, col)

			# Process for enemy unit
			var e_unit = grid_enemy_units[row][col]
			if e_unit and e_unit.is_alive():
				var field_result = process_field_effects_for_unit(e_unit, row, col)
				if field_result.damage > 0:
					e_unit.take_damage(field_result.damage)
					if grid_enemy_displays[row][col]:
						grid_enemy_displays[row][col].show_damage_number(field_result.damage, false)
						grid_enemy_displays[row][col].update_hp_display()
				if field_result.healing > 0:
					e_unit.heal(field_result.healing)
					if grid_enemy_displays[row][col]:
						grid_enemy_displays[row][col].show_damage_number(field_result.healing, true)
						grid_enemy_displays[row][col].update_hp_display()
				# Check if unit died from field effect
				if not e_unit.is_alive():
					_remove_unit_from_grid(e_unit, row, col)

	# Process field effect durations
	_process_all_field_durations()

	# Process cooldowns and status effects for all units
	for unit in player_units + enemy_units:
		var effect_result = unit.process_turn_end()
		# Update display if unit is on grid
		if unit.is_placed():
			var display = _get_display_for_unit(unit)
			if display:
				display.update_hp_display()
				display.update_status_display()
			# Check if unit died from status effect
			if not unit.is_alive():
				_remove_unit_from_grid(unit, unit.grid_row, unit.grid_col)

	# Check win condition
	var winner = _check_win_condition()
	if winner > 0:
		current_phase = GamePhase.GAME_OVER
		_show_results(winner)
		return

	# Update roster displays after combat
	_update_roster_displays()

	# Start next turn
	current_turn += 1
	actions_remaining = ACTIONS_PER_TURN
	current_phase = GamePhase.PLAYER_TURN
	_update_ui()

	print("=== Turn ", current_turn, " ===")

	if auto_battle_enabled:
		await get_tree().create_timer(get_scaled_time(0.3)).timeout
		_do_auto_turn()

func _get_display_for_unit(unit: UnitInstance) -> Node2D:
	if not unit.is_placed():
		return null
	if unit.owner == 1:
		return grid_player_displays[unit.grid_row][unit.grid_col]
	else:
		return grid_enemy_displays[unit.grid_row][unit.grid_col]

func _remove_unit_from_grid(unit: UnitInstance, row: int, col: int):
	if unit.owner == 1:
		grid_player_units[row][col] = null
		if grid_player_displays[row][col]:
			grid_player_displays[row][col].queue_free()
			grid_player_displays[row][col] = null
	else:
		grid_enemy_units[row][col] = null
		if grid_enemy_displays[row][col]:
			grid_enemy_displays[row][col].queue_free()
			grid_enemy_displays[row][col] = null

	unit.remove_from_grid()
	unit.start_cooldown()
	_update_cell_ownership(row, col)

	# Recenter the remaining unit if the square is no longer contested
	_recenter_remaining_unit(row, col)

	print("  ", unit.unit_data.unit_name, " removed from grid")

func _recenter_remaining_unit(row: int, col: int):
	# If only one unit remains on this square, recenter it
	var has_player = grid_player_units[row][col] != null
	var has_enemy = grid_enemy_units[row][col] != null
	var pos = _get_cell_position(row, col)

	if has_player and not has_enemy:
		# Only player unit remains - recenter it
		if grid_player_displays[row][col]:
			grid_player_displays[row][col].position = pos
	elif has_enemy and not has_player:
		# Only enemy unit remains - recenter it
		if grid_enemy_displays[row][col]:
			grid_enemy_displays[row][col].position = pos

func _resolve_duel(row: int, col: int, p_unit: UnitInstance, e_unit: UnitInstance):
	# Get selected abilities (nullify if disrupted OR on cooldown)
	var p_ability = null
	var e_ability = null

	if not p_unit.is_disrupted() and p_unit.is_ability_available(p_unit.selected_ability_index):
		p_ability = p_unit.get_selected_ability()
	if not e_unit.is_disrupted() and e_unit.is_ability_available(e_unit.selected_ability_index):
		e_ability = e_unit.get_selected_ability()

	if p_unit.is_disrupted():
		print("  ", p_unit.unit_data.unit_name, " is DISRUPTED - cannot use ability!")
	elif not p_unit.is_ability_available(p_unit.selected_ability_index):
		print("  ", p_unit.unit_data.unit_name, " ability on COOLDOWN - using basic attack!")
	if e_unit.is_disrupted():
		print("  ", e_unit.unit_data.unit_name, " is DISRUPTED - cannot use ability!")
	elif not e_unit.is_ability_available(e_unit.selected_ability_index):
		print("  ", e_unit.unit_data.unit_name, " ability on COOLDOWN - using basic attack!")

	var p_ability_name = p_ability.ability_name if p_ability else "Strike"
	var e_ability_name = e_ability.ability_name if e_ability else "Strike"

	# Get speed for combat order
	var p_speed = p_unit.unit_data.speed
	var e_speed = e_unit.unit_data.speed

	print("DUEL at (", row, ", ", col, "): ", p_unit.unit_data.unit_name, " (SPD:", p_speed, ", ", p_ability_name, ") vs ", e_unit.unit_data.unit_name, " (SPD:", e_speed, ", ", e_ability_name, ")")

	# Show combat announcement
	var announcement = p_unit.unit_data.unit_name + " vs " + e_unit.unit_data.unit_name + "!"
	_show_combat_announcement(announcement, 0.8)

	# Put abilities on cooldown after use (only if not disrupted)
	if not p_unit.is_disrupted():
		p_unit.put_ability_on_cooldown(p_ability)
	if not e_unit.is_disrupted():
		e_unit.put_ability_on_cooldown(e_ability)

	# Calculate base stats
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

	# Get displays for visual effects
	var p_display = grid_player_displays[row][col]
	var e_display = grid_enemy_displays[row][col]

	# Speed-based combat resolution
	# Faster unit attacks first; if they kill the target, target doesn't retaliate
	# Speed ties = simultaneous damage
	if p_speed > e_speed:
		# Player attacks first
		print("  Player attacks first (faster)")
		if p_display:
			p_display.play_attack_animation()
		await get_tree().create_timer(get_scaled_time(0.4)).timeout
		e_unit.take_damage(e_damage_taken)
		if e_display:
			e_display.play_hurt_animation()
			e_display.show_damage_number(e_damage_taken, false)
			e_display.flash_color(Color(1, 0.5, 0.5), 0.3)
			e_display.update_hp_display()
		await get_tree().create_timer(get_scaled_time(0.3)).timeout

		# Apply guaranteed survive for enemy
		if e_guaranteed_survive and e_unit.current_hp <= 0:
			e_unit.current_hp = 1
			print("  Enemy survives with ability!")

		# Enemy retaliates only if still alive
		if e_unit.is_alive():
			if e_display:
				e_display.play_attack_animation()
			await get_tree().create_timer(get_scaled_time(0.4)).timeout
			p_unit.take_damage(p_damage_taken)
			if p_display:
				p_display.play_hurt_animation()
				p_display.show_damage_number(p_damage_taken, false)
				p_display.flash_color(Color(1, 0.5, 0.5), 0.3)
				p_display.update_hp_display()
			await get_tree().create_timer(get_scaled_time(0.3)).timeout

			# Apply guaranteed survive for player
			if p_guaranteed_survive and p_unit.current_hp <= 0:
				p_unit.current_hp = 1
				print("  Player survives with Nature's Resilience!")
		else:
			print("  Enemy defeated before retaliating!")

		print("  Player dealt ", e_damage_taken, ", took ", p_damage_taken if e_unit.is_alive() or not e_unit.is_alive() and p_unit.current_hp < p_unit.unit_data.max_hp else 0)

	elif e_speed > p_speed:
		# Enemy attacks first
		print("  Enemy attacks first (faster)")
		if e_display:
			e_display.play_attack_animation()
		await get_tree().create_timer(get_scaled_time(0.4)).timeout
		p_unit.take_damage(p_damage_taken)
		if p_display:
			p_display.play_hurt_animation()
			p_display.show_damage_number(p_damage_taken, false)
			p_display.flash_color(Color(1, 0.5, 0.5), 0.3)
			p_display.update_hp_display()
		await get_tree().create_timer(get_scaled_time(0.3)).timeout

		# Apply guaranteed survive for player
		if p_guaranteed_survive and p_unit.current_hp <= 0:
			p_unit.current_hp = 1
			print("  Player survives with Nature's Resilience!")

		# Player retaliates only if still alive
		if p_unit.is_alive():
			if p_display:
				p_display.play_attack_animation()
			await get_tree().create_timer(get_scaled_time(0.4)).timeout
			e_unit.take_damage(e_damage_taken)
			if e_display:
				e_display.play_hurt_animation()
				e_display.show_damage_number(e_damage_taken, false)
				e_display.flash_color(Color(1, 0.5, 0.5), 0.3)
				e_display.update_hp_display()
			await get_tree().create_timer(get_scaled_time(0.3)).timeout

			# Apply guaranteed survive for enemy
			if e_guaranteed_survive and e_unit.current_hp <= 0:
				e_unit.current_hp = 1
				print("  Enemy survives with ability!")
		else:
			print("  Player defeated before retaliating!")

		print("  Player dealt ", e_damage_taken if p_unit.is_alive() else 0, ", took ", p_damage_taken)

	else:
		# Speed tie - simultaneous damage
		print("  Speed tie - simultaneous attacks!")
		if p_display:
			p_display.play_attack_animation()
		if e_display:
			e_display.play_attack_animation()
		await get_tree().create_timer(get_scaled_time(0.4)).timeout
		e_unit.take_damage(e_damage_taken)
		p_unit.take_damage(p_damage_taken)

		if p_display:
			p_display.play_hurt_animation()
			p_display.show_damage_number(p_damage_taken, false)
			p_display.flash_color(Color(1, 0.5, 0.5), 0.3)
			p_display.update_hp_display()
		if e_display:
			e_display.play_hurt_animation()
			e_display.show_damage_number(e_damage_taken, false)
			e_display.flash_color(Color(1, 0.5, 0.5), 0.3)
			e_display.update_hp_display()
		await get_tree().create_timer(get_scaled_time(0.3)).timeout

		# Apply guaranteed survive
		if p_guaranteed_survive and p_unit.current_hp <= 0:
			p_unit.current_hp = 1
			print("  Player survives with Nature's Resilience!")
		if e_guaranteed_survive and e_unit.current_hp <= 0:
			e_unit.current_hp = 1
			print("  Enemy survives with ability!")

		print("  Player dealt ", e_damage_taken, ", took ", p_damage_taken)

	# Apply healing after combat with visual feedback
	if p_heal > 0 and p_unit.is_alive():
		p_unit.heal(p_heal)
		print("  Player heals for ", p_heal)
		if p_display:
			p_display.show_damage_number(p_heal, true)
			p_display.update_hp_display()
	if e_heal > 0 and e_unit.is_alive():
		e_unit.heal(e_heal)
		print("  Enemy heals for ", e_heal)
		if e_display:
			e_display.show_damage_number(e_heal, true)
			e_display.update_hp_display()

	# Apply status effects from abilities (only if attacker is alive)
	if p_ability and p_ability.applies_status_effect and p_unit.is_alive():
		if p_ability.applies_to_self:
			p_unit.apply_status_effect(p_ability.applies_status_effect, 1)
		elif e_unit.is_alive():
			e_unit.apply_status_effect(p_ability.applies_status_effect, 1)
	if e_ability and e_ability.applies_status_effect and e_unit.is_alive():
		if e_ability.applies_to_self:
			e_unit.apply_status_effect(e_ability.applies_status_effect, 2)
		elif p_unit.is_alive():
			p_unit.apply_status_effect(e_ability.applies_status_effect, 2)

	# Apply field effects from abilities (even if unit died - they created the field)
	if p_ability and p_ability.applies_field_effect:
		apply_field_effect(row, col, p_ability.applies_field_effect, 1)
	if e_ability and e_ability.applies_field_effect:
		apply_field_effect(row, col, e_ability.applies_field_effect, 2)

	# Handle knockouts - units only leave when HP = 0
	if not p_unit.is_alive():
		enemy_knockouts += 1
		print("  Player unit knocked out! (Enemy has ", enemy_knockouts, "/", KNOCKOUTS_TO_WIN, " knockouts)")
		_remove_unit_from_grid(p_unit, row, col)

	if not e_unit.is_alive():
		player_knockouts += 1
		print("  Enemy unit knocked out! (Player has ", player_knockouts, "/", KNOCKOUTS_TO_WIN, " knockouts)")
		_remove_unit_from_grid(e_unit, row, col)

	# Both units survive - they remain on the contested square
	if p_unit.is_alive() and e_unit.is_alive():
		print("  Both units survive - square remains contested!")

	# Update cell ownership
	_update_cell_ownership(row, col)

	# Update status displays
	if p_unit.is_alive() and p_display:
		p_display.update_status_display()
	if e_unit.is_alive() and e_display:
		e_display.update_status_display()

	await get_tree().create_timer(get_scaled_time(0.3)).timeout

func _confirm_placement(unit: UnitInstance, row: int, col: int, owner: int):
	# Place unit in the appropriate array
	if owner == 1:
		grid_player_units[row][col] = unit
	else:
		grid_enemy_units[row][col] = unit

	# Update ownership
	_update_cell_ownership(row, col)

	# Get the appropriate display array
	var display_array = grid_player_displays if owner == 1 else grid_enemy_displays

	# Update or create display
	if display_array[row][col]:
		display_array[row][col].queue_free()

	var display = UnitDisplayScene.instantiate()
	grid_container.add_child(display)

	# Calculate position with perspective
	var pos = _get_cell_position(row, col)
	var row_scale = _get_perspective_scale(row)

	# Offset units on contested squares so both are visible
	var is_contested = (owner == 1 and grid_enemy_units[row][col] != null) or (owner == 2 and grid_player_units[row][col] != null)
	if is_contested:
		if owner == 1:
			pos.x -= 25 * row_scale  # Player unit offset left
		else:
			pos.x += 25 * row_scale  # Enemy unit offset right

	display.position = pos
	display.scale = Vector2(0.7, 0.7) * row_scale
	display.setup(unit)
	display.set_enemy(owner == 2)
	display.modulate = Color(1, 1, 1, 1)  # Full opacity for confirmed

	# Connect drag signals for player units on the grid
	if owner == 1:
		display.unit_drag_started.connect(_on_grid_unit_drag_started.bind(row, col))
		display.unit_clicked.connect(_on_grid_unit_clicked.bind(row, col))
	else:
		display.drag_enabled = false  # Enemies can't be dragged

	display_array[row][col] = display

	# Play entry animation - player from bottom, enemy from top
	var entry_direction = "bottom" if owner == 1 else "top"
	display.play_entry_animation(entry_direction)

	# Reposition existing unit on contested squares
	if is_contested:
		_reposition_displays_for_contested(row, col)

func _reposition_displays_for_contested(row: int, col: int):
	# Reposition both displays when a square becomes contested
	var pos = _get_cell_position(row, col)
	var row_scale = _get_perspective_scale(row)
	var offset_amount = 25 * row_scale

	if grid_player_displays[row][col]:
		grid_player_displays[row][col].position = Vector2(pos.x - offset_amount, pos.y)

	if grid_enemy_displays[row][col]:
		grid_enemy_displays[row][col].position = Vector2(pos.x + offset_amount, pos.y)

func _check_win_condition() -> int:
	# Check knockout victory first (knock out 3 enemy units)
	if player_knockouts >= KNOCKOUTS_TO_WIN:
		print("Player wins by knockout! (", player_knockouts, " enemies eliminated)")
		return 1
	if enemy_knockouts >= KNOCKOUTS_TO_WIN:
		print("Enemy wins by knockout! (", enemy_knockouts, " player units eliminated)")
		return 2

	# Check rows (3 in a row)
	for row in range(GRID_SIZE):
		var winner = _check_line(grid_ownership[row][0], grid_ownership[row][1], grid_ownership[row][2])
		if winner > 0:
			return winner

	# Check columns
	for col in range(GRID_SIZE):
		var winner = _check_line(grid_ownership[0][col], grid_ownership[1][col], grid_ownership[2][col])
		if winner > 0:
			return winner

	# Check diagonals
	var winner = _check_line(grid_ownership[0][0], grid_ownership[1][1], grid_ownership[2][2])
	if winner > 0:
		return winner
	winner = _check_line(grid_ownership[0][2], grid_ownership[1][1], grid_ownership[2][0])
	if winner > 0:
		return winner

	# Check turn limit - determine winner by HP percentage
	if current_turn >= MAX_TURNS:
		return _determine_winner_by_hp()

	return 0

func _determine_winner_by_hp() -> int:
	# Calculate total HP percentage for each team
	var player_hp_percent = _calculate_team_hp_percent(player_units)
	var enemy_hp_percent = _calculate_team_hp_percent(enemy_units)

	print("TURN LIMIT REACHED! Determining winner by HP%...")
	print("  Player team HP: ", snapped(player_hp_percent * 100, 0.1), "%")
	print("  Enemy team HP: ", snapped(enemy_hp_percent * 100, 0.1), "%")

	if player_hp_percent > enemy_hp_percent:
		print("  Player wins by HP advantage!")
		return 1
	elif enemy_hp_percent > player_hp_percent:
		print("  Enemy wins by HP advantage!")
		return 2
	else:
		# Tie goes to player (slight advantage for reaching the limit)
		print("  HP tied - Player wins by tiebreaker!")
		return 1

func _calculate_team_hp_percent(units: Array) -> float:
	var total_current_hp = 0.0
	var total_max_hp = 0.0

	for unit in units:
		if unit and unit.max_hp > 0:
			total_current_hp += unit.current_hp
			total_max_hp += unit.max_hp

	if total_max_hp <= 0:
		return 0.0

	return total_current_hp / total_max_hp

## Revive a knocked out unit with a percentage of max HP
## Call this from revive abilities. Adjusts knockout counter.
## Returns true if unit was successfully revived
func revive_unit(unit: UnitInstance, hp_percent: float = 0.5) -> bool:
	if not unit.is_knocked_out():
		return false

	# Revive the unit
	if not unit.revive(hp_percent):
		return false

	# Adjust knockout counter (unit is back in play)
	if unit.owner == 1:  # Player unit
		enemy_knockouts = max(0, enemy_knockouts - 1)
		print("Player unit revived! Enemy knockouts reduced to ", enemy_knockouts)
	else:  # Enemy unit
		player_knockouts = max(0, player_knockouts - 1)
		print("Enemy unit revived! Player knockouts reduced to ", player_knockouts)

	# Update roster displays
	_update_roster_displays()
	return true

## Get all knocked out units for a team (1 = player, 2 = enemy)
func get_knocked_out_units(team: int) -> Array:
	var units = player_units if team == 1 else enemy_units
	return units.filter(func(u): return u.is_knocked_out())

func _check_line(a: int, b: int, c: int) -> int:
	# Only sole occupancy counts (1 = player only, 2 = enemy only)
	# Contested squares (3) don't count as owned by either side
	if a == 1 and b == 1 and c == 1:
		return 1  # Player wins
	if a == 2 and b == 2 and c == 2:
		return 2  # Enemy wins
	return 0  # No winner

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

	# F1 toggles cheat menu (always available)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		if cheat_menu:
			cheat_menu.toggle()
		return

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
		# Restore grid display (player units only since enemies can't be dragged)
		var row = dragging_from_pos.row
		var col = dragging_from_pos.col
		if grid_player_displays[row][col]:
			grid_player_displays[row][col].modulate = Color(1, 1, 1, 1)
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

	if active_unit and ability_tooltip:
		# Get the unit's screen position
		var screen_pos = _get_unit_screen_position(active_unit)
		ability_tooltip.show_for_unit(active_unit, screen_pos)
	elif ability_tooltip:
		ability_tooltip.hide_tooltip()

func _get_unit_screen_position(unit: UnitInstance) -> Vector2:
	# Find where this unit is displayed
	if unit.is_placed():
		var row = unit.grid_row
		var col = unit.grid_col
		var cell_pos = _get_cell_position(row, col)
		# Convert from grid_container local to screen position
		return grid_container.global_position + cell_pos
	else:
		# Check pending placements
		for pending in player_pending_placements:
			if pending["unit"] == unit:
				var cell_pos = _get_cell_position(pending["row"], pending["col"])
				return grid_container.global_position + cell_pos
	# Fallback to center of screen
	return Vector2(960, 400)

func _on_tooltip_ability_selected(index: int):
	# Called when ability is selected via tooltip
	var active_unit = _get_active_unit_for_ability()
	if active_unit:
		print("Ability changed to: ", active_unit.unit_data.abilities[index].ability_name)

func _on_tooltip_dismissed():
	# Clear editing state when tooltip is dismissed
	pending_edit_unit = null
	selected_unit = null
	moving_unit = null
	moving_from = {}

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
	drag_preview.set_enemy(false)
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
		var player_unit = grid_player_units[row][col]

		# Check pending placements
		for pending in player_pending_placements:
			if pending.row == row and pending.col == col:
				print("Already have a pending placement there!")
				return

		# Can't move onto own unit (unless being vacated)
		if player_unit != null and not _is_cell_being_vacated(row, col):
			print("Can't move onto your own unit!")
			return

		# Queue the move (can move to empty, enemy-only, or contested squares)
		_queue_move(dragging_unit, dragging_from_pos.row, dragging_from_pos.col, row, col)
	else:
		# Placing from roster
		var player_unit = grid_player_units[row][col]

		# Check pending placements
		for pending in player_pending_placements:
			if pending.row == row and pending.col == col:
				print("Already have a pending placement there!")
				return

		# Allow any cell that doesn't have your own unit (or is being vacated)
		var cell_available = player_unit == null or _is_cell_being_vacated(row, col)
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

		# Check victory type
		var ended_by_turn_limit = current_turn >= MAX_TURNS
		var ended_by_knockout = player_knockouts >= KNOCKOUTS_TO_WIN or enemy_knockouts >= KNOCKOUTS_TO_WIN

		if winner == 1:
			if ended_by_knockout:
				result_title.text = "KNOCKOUT!"
			elif ended_by_turn_limit:
				result_title.text = "TIME VICTORY!"
			else:
				result_title.text = "VICTORY!"
			result_title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))

			# Give battle rewards
			var battle_rewards = _give_battle_rewards()

			# Handle campaign rewards
			if PlayerData.is_campaign_mode():
				var stage = PlayerData.current_stage
				var rewards = PlayerData.give_stage_rewards(stage)
				PlayerData.clear_stage(stage.stage_id, 3)  # Default 3 stars

				var subtitle_text = "Stage Complete!\n"

				# Show gold and materials earned
				subtitle_text += "+" + str(battle_rewards.gold) + " Gold, +" + str(battle_rewards.materials) + " Materials\n"

				# Show XP earned
				if battle_rewards.xp > 0:
					subtitle_text += "+" + str(battle_rewards.xp) + " XP per unit\n"

				# Show level ups
				if battle_rewards.level_ups.size() > 0:
					subtitle_text += "Level Up: " + ", ".join(battle_rewards.level_ups) + "\n"

				if rewards.first_clear:
					subtitle_text += "\nFIRST CLEAR BONUS!\n"
					subtitle_text += "+" + str(rewards.gems) + " Gems"
					if rewards.unit != null:
						subtitle_text += "\nNew Unit: " + rewards.unit.unit_data.unit_name + "!"

				result_subtitle.text = subtitle_text
			# Handle dungeon rewards
			elif PlayerData.is_dungeon_mode():
				var dungeon_rewards = _give_dungeon_rewards()

				var subtitle_text = "Dungeon Complete!\n"
				subtitle_text += "+" + str(dungeon_rewards.stones) + " Enhancement Stones\n"

				if dungeon_rewards.gear != null:
					var gear_data = dungeon_rewards.gear.gear_data as GearData
					subtitle_text += "\nGear Drop: " + gear_data.gear_name
					subtitle_text += " (" + GearData.GearRarity.keys()[gear_data.rarity] + ")"

				result_subtitle.text = subtitle_text
			else:
				# Quick battle rewards
				var subtitle_text = ""
				if ended_by_knockout:
					subtitle_text = "Eliminated " + str(player_knockouts) + " enemies!\n"
				elif ended_by_turn_limit:
					subtitle_text = "Turn limit reached - you had more HP!\n"
				else:
					subtitle_text = "You won in " + str(current_turn) + " turns!\n"
				subtitle_text += "+" + str(battle_rewards.gold) + " Gold, +" + str(battle_rewards.materials) + " Materials"
				if battle_rewards.level_ups.size() > 0:
					subtitle_text += "\nLevel Up: " + ", ".join(battle_rewards.level_ups)
				result_subtitle.text = subtitle_text
		else:
			if ended_by_knockout:
				result_title.text = "KNOCKED OUT"
			elif ended_by_turn_limit:
				result_title.text = "TIME DEFEAT"
			else:
				result_title.text = "DEFEAT"
			result_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			if PlayerData.is_campaign_mode():
				result_subtitle.text = "Stage failed. Try again!"
			elif PlayerData.is_dungeon_mode():
				result_subtitle.text = "Dungeon failed. Try again!"
			elif ended_by_knockout:
				result_subtitle.text = "Lost " + str(enemy_knockouts) + " units!"
			elif ended_by_turn_limit:
				result_subtitle.text = "Turn limit reached. Enemy had more HP!"
			else:
				result_subtitle.text = "Better luck next time!"

		# Hide other UI elements
		if ability_panel:
			ability_panel.visible = false
		if end_turn_button:
			end_turn_button.visible = false

		print("Game Over! Winner: ", "Player" if winner == 1 else "Enemy")

func _give_battle_rewards() -> Dictionary:
	var result = {"gold": 0, "materials": 0, "xp": 0, "level_ups": []}

	# Calculate rewards based on mode
	var gold_reward = 100  # Base reward for quick battle
	var material_reward = 3
	var xp_reward = 30

	if PlayerData.is_campaign_mode():
		var stage = PlayerData.current_stage
		if stage:
			gold_reward = stage.gold_reward
			material_reward = stage.material_reward
			xp_reward = stage.xp_reward

	# Give currencies
	PlayerData.add_gold(gold_reward)
	PlayerData.add_materials(material_reward)
	result.gold = gold_reward
	result.materials = material_reward
	result.xp = xp_reward

	# Give XP to participating units
	for instance_id in PlayerData.selected_team:
		var xp_result = PlayerData.add_xp_to_unit(instance_id, xp_reward)
		if xp_result.leveled_up:
			var unit = PlayerData.get_unit_by_instance_id(instance_id)
			if not unit.is_empty():
				result.level_ups.append(unit.unit_data.unit_name)

	PlayerData.save_game()
	return result

func _give_dungeon_rewards() -> Dictionary:
	var result = {"stones": 0, "gear": null}

	if not PlayerData.is_dungeon_mode():
		return result

	# Give enhancement stones
	var stones = PlayerData.generate_stone_drop()
	PlayerData.add_enhancement_stones(stones)
	result.stones = stones

	# Generate gear drop
	var gear_data = PlayerData.generate_gear_drop()
	if gear_data:
		var gear_entry = PlayerData.add_gear_to_inventory(gear_data)
		result.gear = gear_entry

	PlayerData.save_game()
	return result

func _on_play_again_pressed():
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	if PlayerData.is_campaign_mode():
		PlayerData.end_campaign_stage()
		get_tree().change_scene_to_file("res://scenes/ui/campaign_select_screen.tscn")
	elif PlayerData.is_dungeon_mode():
		PlayerData.end_dungeon()
		get_tree().change_scene_to_file("res://scenes/ui/dungeon_select_screen.tscn")
	else:
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

# --- Cheat Functions ---

func _cheat_instant_win():
	# Force player to own a complete line
	for col in range(GRID_SIZE):
		grid_ownership[0][col] = 1  # Player owns top row
		grid_cells[0][col].set_ownership(1)
	current_phase = GamePhase.GAME_OVER
	_show_results(1)

func _cheat_instant_lose():
	# Force enemy to own a complete line
	for col in range(GRID_SIZE):
		grid_ownership[0][col] = 2  # Enemy owns top row
		grid_cells[0][col].set_ownership(2)
	current_phase = GamePhase.GAME_OVER
	_show_results(2)


func _cheat_fill_grid():
	# Fill all 9 cells with ownership for visual testing
	# Pattern: Player on left column, Enemy on right column, Contested in middle
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var owner_type: int
			if col == 0:
				owner_type = 1  # Player (left column)
			elif col == 2:
				owner_type = 2  # Enemy (right column)
			else:
				owner_type = 3  # Contested (middle column)

			grid_ownership[row][col] = owner_type
			grid_cells[row][col].set_ownership(owner_type)

	print("[CHEAT] Filled all cells - Left=Player, Middle=Contested, Right=Enemy")


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

# === AUTO-BATTLE SYSTEM ===

func _on_auto_toggle():
	auto_battle_enabled = not auto_battle_enabled
	_update_auto_button()
	if auto_battle_enabled and current_phase == GamePhase.PLAYER_TURN:
		_do_auto_turn()

func _update_auto_button():
	if not auto_button:
		return
	if auto_battle_enabled:
		auto_button.text = "AUTO: ON"
	else:
		auto_button.text = "AUTO: OFF"

func _set_battle_speed(speed: float):
	battle_speed = speed
	_update_speed_buttons()

func _update_speed_buttons():
	if speed_1x_btn:
		speed_1x_btn.button_pressed = (battle_speed == 1.0)
	if speed_2x_btn:
		speed_2x_btn.button_pressed = (battle_speed == 0.5)
	if speed_3x_btn:
		speed_3x_btn.button_pressed = (battle_speed == 0.25)

func get_scaled_time(base_time: float) -> float:
	return base_time * battle_speed

func _do_auto_turn():
	if current_phase != GamePhase.PLAYER_TURN or not auto_battle_enabled:
		return

	print("Auto-battle taking turn...")

	var available_cells = _get_cells_without_player()
	var available_units = player_units.filter(func(u): return u.can_act() and not u.is_placed())

	var auto_actions = mini(actions_remaining, mini(available_cells.size(), available_units.size()))

	for i in range(auto_actions):
		if available_cells.is_empty() or available_units.is_empty():
			break

		available_units.sort_custom(func(a, b): return a.attack > b.attack)
		var unit = available_units.pop_front()

		var cell = _select_cell_for_auto(available_cells)
		available_cells.erase(cell)

		_select_best_ability(unit)
		_queue_placement(unit, cell.row, cell.col)

		await get_tree().create_timer(0.2 * battle_speed).timeout

	await get_tree().create_timer(0.3 * battle_speed).timeout
	_on_end_turn_pressed()

func _get_cells_without_player() -> Array:
	var available = []
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if grid_player_units[row][col] == null:
				var is_pending = false
				for p in player_pending_placements:
					if p.row == row and p.col == col:
						is_pending = true
						break
				if not is_pending:
					available.append({"row": row, "col": col})
	return available

func _select_cell_for_auto(available_cells: Array) -> Dictionary:
	if available_cells.is_empty():
		return {}

	var scored_cells = []
	for cell in available_cells:
		var score = _evaluate_cell_for_player(cell.row, cell.col)
		scored_cells.append({"cell": cell, "score": score})

	scored_cells.sort_custom(func(a, b): return a.score > b.score)
	return scored_cells[0].cell

func _evaluate_cell_for_player(row: int, col: int) -> int:
	var score = 0
	var lines = _get_lines_containing_cell(row, col)

	for line in lines:
		var counts = _count_line_ownership(line)
		if counts.player == 2 and counts.empty == 1:
			score += 100
		if counts.enemy == 2 and counts.empty == 1:
			score += 90
		if counts.player == 1 and counts.empty == 2:
			score += 30

	if row == 1 and col == 1:
		score += 20
	elif (row == 0 or row == 2) and (col == 0 or col == 2):
		score += 10

	return score

func _select_best_ability(unit: UnitInstance):
	if unit.unit_data.abilities.is_empty():
		return

	var best_index = 0
	var best_score = -999

	for i in range(unit.unit_data.abilities.size()):
		if not unit.is_ability_available(i):
			continue

		var ability = unit.unit_data.abilities[i]
		var score = ability.damage_multiplier * 100

		if ability.heal_amount > 0:
			for p_unit in player_units:
				if p_unit.is_alive() and p_unit.current_hp < p_unit.max_hp * 0.5:
					score += 50
					break

		if score > best_score:
			best_score = score
			best_index = i

	unit.selected_ability_index = best_index

func _apply_battle_theme():
	# Apply background color to main scene
	var bg = get_node_or_null("Background")
	if bg and bg is ColorRect:
		bg.color = UITheme.BG_DARK

	# Top bar styling
	if turn_label:
		turn_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		turn_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	if phase_label:
		phase_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		phase_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	if actions_label:
		actions_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		actions_label.add_theme_color_override("font_color", UITheme.PRIMARY)

	# Player roster panel
	var player_roster_bg = get_node_or_null("UI/PlayerRosterBG")
	if player_roster_bg and player_roster_bg is ColorRect:
		player_roster_bg.color = UITheme.BG_DARK.lightened(0.05)

	var player_roster_label = get_node_or_null("UI/PlayerRosterLabel")
	if player_roster_label:
		player_roster_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		player_roster_label.add_theme_color_override("font_color", UITheme.PRIMARY)

	# Enemy roster panel
	var enemy_roster_bg = get_node_or_null("UI/EnemyRosterBG")
	if enemy_roster_bg and enemy_roster_bg is ColorRect:
		enemy_roster_bg.color = UITheme.BG_DARK.lightened(0.05)

	var enemy_roster_label = get_node_or_null("UI/EnemyRosterLabel")
	if enemy_roster_label:
		enemy_roster_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		enemy_roster_label.add_theme_color_override("font_color", UITheme.DANGER)

	# Ability panel
	if ability_panel and ability_panel is Panel:
		ability_panel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))

	var ability_label = get_node_or_null("UI/AbilityPanel/AbilityLabel")
	if ability_label:
		ability_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		ability_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Style ability buttons
	for btn in ability_buttons:
		if btn:
			btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_LIGHT))
			btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT.lightened(0.1)))
			btn.add_theme_stylebox_override("disabled", UITheme.create_button_style(UITheme.BG_DARK))
			btn.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
			btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
			btn.add_theme_color_override("font_disabled_color", UITheme.TEXT_DISABLED)

	if ability_desc:
		ability_desc.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		ability_desc.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# End turn button
	if end_turn_button:
		end_turn_button.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
		end_turn_button.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.PRIMARY.lightened(0.1)))
		end_turn_button.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.PRIMARY.darkened(0.1)))
		end_turn_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		end_turn_button.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Auto-battle and speed buttons
	if auto_button:
		auto_button.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_LIGHT))
		auto_button.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT.lightened(0.1)))
		auto_button.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.SECONDARY))
		auto_button.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		auto_button.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	for speed_btn in [speed_1x_btn, speed_2x_btn, speed_3x_btn]:
		if speed_btn:
			speed_btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_LIGHT))
			speed_btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT.lightened(0.1)))
			speed_btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.SECONDARY))
			speed_btn.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
			speed_btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Results panel
	if results_panel and results_panel is Panel:
		results_panel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_DARK, UITheme.PRIMARY, UITheme.MODAL_RADIUS))

	var results_bg = get_node_or_null("UI/ResultsPanel/ResultsBackground")
	if results_bg and results_bg is ColorRect:
		results_bg.color = UITheme.BG_DARK

	if result_title:
		result_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)

	if result_subtitle:
		result_subtitle.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		result_subtitle.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Style results buttons
	if play_again_button:
		play_again_button.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
		play_again_button.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.PRIMARY.lightened(0.1)))
		play_again_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		play_again_button.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	if main_menu_button:
		main_menu_button.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_LIGHT))
		main_menu_button.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT.lightened(0.1)))
		main_menu_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		main_menu_button.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Combat announcement
	if combat_announcement:
		combat_announcement.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		combat_announcement.add_theme_color_override("font_color", UITheme.GOLD)

	# Instructions label
	var instructions = get_node_or_null("UI/Instructions")
	if instructions:
		instructions.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		instructions.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)
