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

# Game state
var current_turn: int = 1
var grid_cells: Array = []  # 2D array of cell references
var grid_ownership: Array = []  # 2D array: 0 = empty, 1 = player, 2 = enemy

# Preload the grid cell scene
var GridCellScene = preload("res://scenes/battle/grid_cell.tscn")

func _ready():
	_create_grid()
	_update_ui()

func _create_grid():
	# Initialize the ownership array
	grid_ownership = []
	grid_cells = []

	# Calculate offset to center the grid
	var grid_total_size = (CELL_SIZE * GRID_SIZE) + (CELL_GAP * (GRID_SIZE - 1))
	var offset = -grid_total_size / 2

	for row in range(GRID_SIZE):
		var cell_row = []
		var ownership_row = []

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
			ownership_row.append(0)  # 0 = empty

		grid_cells.append(cell_row)
		grid_ownership.append(ownership_row)

func _on_cell_clicked(row: int, col: int):
	print("Cell clicked: row ", row, ", col ", col)

	# For now, just toggle ownership to test
	var current = grid_ownership[row][col]
	var new_ownership = (current + 1) % 3  # Cycle: 0 -> 1 -> 2 -> 0
	grid_ownership[row][col] = new_ownership
	grid_cells[row][col].set_ownership(new_ownership)

	# Check for win condition
	var winner = _check_win_condition()
	if winner > 0:
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

	return 0  # No winner yet

func _check_line(a: int, b: int, c: int) -> bool:
	return a != 0 and a == b and b == c

func _update_ui():
	turn_label.text = "Turn: " + str(current_turn)
	phase_label.text = "Phase: Placement"
