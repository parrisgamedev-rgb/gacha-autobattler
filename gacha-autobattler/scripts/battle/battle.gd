extends Node2D
## Main battle scene controller
## Manages the 3x3 grid and turn flow

# Grid settings
const GRID_SIZE = 3
const CELL_SIZE = 150
const CELL_GAP = 10

# References
@onready var grid_container = $GridContainer
@onready var turn_label = $UI/TurnLabel
@onready var phase_label = $UI/PhaseLabel
@onready var player_roster = $UI/PlayerRoster
@onready var enemy_roster = $UI/EnemyRoster

# Game state
var current_turn: int = 1
var grid_cells: Array = []  # 2D array of cell references
var grid_ownership: Array = []  # 2D array: 0 = empty, 1 = player, 2 = enemy
var grid_units: Array = []  # 2D array: UnitInstance or null

# Unit management
var player_units: Array[UnitInstance] = []
var enemy_units: Array[UnitInstance] = []
var selected_unit: UnitInstance = null

# Preload scenes
var GridCellScene = preload("res://scenes/battle/grid_cell.tscn")
var UnitDisplayScene = preload("res://scenes/battle/unit_display.tscn")

# Unit display references on grid
var grid_unit_displays: Array = []  # 2D array of UnitDisplay nodes

func _ready():
	_create_grid()
	_load_test_units()
	_create_roster_displays()
	_update_ui()

func _create_grid():
	# Initialize arrays
	grid_ownership = []
	grid_cells = []
	grid_units = []
	grid_unit_displays = []

	# Calculate offset to center the grid
	var grid_total_size = (CELL_SIZE * GRID_SIZE) + (CELL_GAP * (GRID_SIZE - 1))
	var offset = -grid_total_size / 2

	for row in range(GRID_SIZE):
		var cell_row = []
		var ownership_row = []
		var unit_row = []
		var display_row = []

		for col in range(GRID_SIZE):
			# Create cell instance
			var cell = GridCellScene.instantiate()
			grid_container.add_child(cell)

			# Position the cell
			var x = offset + (col * (CELL_SIZE + CELL_GAP)) + CELL_SIZE / 2
			var y = offset + (row * (CELL_SIZE + CELL_GAP)) + CELL_SIZE / 2
			cell.position = Vector2(x, y)

			# Initialize cell
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
	# Load sample units for testing
	var fire_data = load("res://resources/units/fire_warrior.tres") as UnitData
	var water_data = load("res://resources/units/water_mage.tres") as UnitData
	var nature_data = load("res://resources/units/nature_tank.tres") as UnitData

	# Create player units
	if fire_data:
		var unit = UnitInstance.new(fire_data, 1)
		player_units.append(unit)

	if water_data:
		var unit = UnitInstance.new(water_data, 1)
		player_units.append(unit)

	if nature_data:
		var unit = UnitInstance.new(nature_data, 1)
		player_units.append(unit)

	# Create enemy units (same units for testing)
	if fire_data:
		var unit = UnitInstance.new(fire_data, 2)
		enemy_units.append(unit)

	if water_data:
		var unit = UnitInstance.new(water_data, 2)
		enemy_units.append(unit)

func _create_roster_displays():
	# Create unit displays in the roster panels
	var y_offset = 0
	for unit in player_units:
		var display = UnitDisplayScene.instantiate()
		player_roster.add_child(display)
		display.position = Vector2(60, 60 + y_offset)
		display.setup(unit)
		display.scale = Vector2(0.8, 0.8)

		# Make clickable (we'll add this functionality)
		y_offset += 130

	y_offset = 0
	for unit in enemy_units:
		var display = UnitDisplayScene.instantiate()
		enemy_roster.add_child(display)
		display.position = Vector2(60, 60 + y_offset)
		display.setup(unit)
		display.scale = Vector2(0.8, 0.8)
		y_offset += 130

func _on_cell_clicked(row: int, col: int):
	print("Cell clicked: row ", row, ", col ", col)

	# If we have a selected unit and the cell is empty, place it
	if selected_unit and grid_units[row][col] == null:
		_place_unit_on_grid(selected_unit, row, col)
		selected_unit = null
		_update_roster_selection()
	# If cell has a unit, select it (for future: moving units)
	elif grid_units[row][col] != null:
		print("Cell has unit: ", grid_units[row][col].unit_data.unit_name)

func _place_unit_on_grid(unit: UnitInstance, row: int, col: int):
	# Update unit position
	unit.place_on_grid(row, col)

	# Update grid state
	grid_units[row][col] = unit
	grid_ownership[row][col] = unit.owner
	grid_cells[row][col].set_ownership(unit.owner)

	# Create visual display
	var display = UnitDisplayScene.instantiate()
	grid_container.add_child(display)

	# Position at cell
	var grid_total_size = (CELL_SIZE * GRID_SIZE) + (CELL_GAP * (GRID_SIZE - 1))
	var offset = -grid_total_size / 2
	var x = offset + (col * (CELL_SIZE + CELL_GAP)) + CELL_SIZE / 2
	var y = offset + (row * (CELL_SIZE + CELL_GAP)) + CELL_SIZE / 2
	display.position = Vector2(x, y)
	display.scale = Vector2(0.7, 0.7)
	display.setup(unit)

	grid_unit_displays[row][col] = display

	# Check win condition
	var winner = _check_win_condition()
	if winner > 0:
		phase_label.text = "Winner: " + ("Player" if winner == 1 else "Enemy")
		print("Winner: ", "Player" if winner == 1 else "Enemy")

func _check_win_condition() -> int:
	# Check rows
	for row in range(GRID_SIZE):
		if _check_line(grid_ownership[row][0], grid_ownership[row][1], grid_ownership[row][2]):
			return grid_ownership[row][0]

	# Check columns
	for col in range(GRID_SIZE):
		if _check_line(grid_ownership[0][col], grid_ownership[1][col], grid_ownership[2][col]):
			return grid_ownership[0][col]

	# Check diagonals
	if _check_line(grid_ownership[0][0], grid_ownership[1][1], grid_ownership[2][2]):
		return grid_ownership[0][0]
	if _check_line(grid_ownership[0][2], grid_ownership[1][1], grid_ownership[2][0]):
		return grid_ownership[0][2]

	return 0

func _check_line(a: int, b: int, c: int) -> bool:
	return a != 0 and a == b and b == c

func _update_ui():
	turn_label.text = "Turn: " + str(current_turn)
	phase_label.text = "Phase: Placement"

func _update_roster_selection():
	# Update visual selection state in roster
	pass

func _input(event):
	# Number keys to select units from roster
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if player_units.size() > 0:
					_select_unit(player_units[0])
			KEY_2:
				if player_units.size() > 1:
					_select_unit(player_units[1])
			KEY_3:
				if player_units.size() > 2:
					_select_unit(player_units[2])
			KEY_4:
				if player_units.size() > 3:
					_select_unit(player_units[3])
			KEY_5:
				if player_units.size() > 4:
					_select_unit(player_units[4])
			KEY_ESCAPE:
				selected_unit = null
				_update_roster_selection()
				print("Deselected unit")

func _select_unit(unit: UnitInstance):
	if unit.can_act() and not unit.is_placed():
		selected_unit = unit
		print("Selected unit: ", unit.unit_data.unit_name)
	else:
		if unit.is_placed():
			print("Unit already placed on grid")
		elif not unit.can_act():
			print("Unit cannot act (on cooldown)")
