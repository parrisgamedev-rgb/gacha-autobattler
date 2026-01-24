extends Node
class_name BoardBuilder
## Loads a background image for the battle board
## Grid cells are invisible interaction areas on top

const TILE_SIZE = 16
const TILE_SCALE = 3
const SCALED_TILE = TILE_SIZE * TILE_SCALE  # 48px

const GRID_SIZE = 3

# Board background images by theme
const BOARD_IMAGES = {
	"dungeon": [
		"res://assets/board/boards/forest_1.png",
		"res://assets/board/boards/forest_2.png",
		"res://assets/board/boards/forest_3.png",
	],
	"dark_dungeon": [
		"res://assets/board/boards/dark_dungeon_1.png",
		"res://assets/board/boards/dark_dungeon_2.png",
		"res://assets/board/boards/dark_dungeon_3.png",
	],
	"arena": [
		"res://assets/board/boards/arena_1.png",
		"res://assets/board/boards/arena_2.png",
		"res://assets/board/boards/arena_3.png",
	]
}

# How big the board image should be displayed
const BOARD_DISPLAY_SIZE = Vector2(432, 432)  # 9 tiles * 48px

var board_root: Node2D


func build_board(parent: Node2D, theme_name: String, center_position: Vector2) -> Dictionary:
	"""Load a background image and position it centered on the grid."""

	# Create container
	board_root = Node2D.new()
	board_root.name = "BoardRoot"
	parent.add_child(board_root)

	# Pick a random board image for this theme
	var boards = BOARD_IMAGES.get(theme_name, BOARD_IMAGES["dungeon"])
	var board_path = boards[randi() % boards.size()]

	# Load and create the background sprite
	var texture = load(board_path)
	if texture:
		var background = Sprite2D.new()
		background.texture = texture
		background.centered = true
		background.position = Vector2.ZERO  # Centered on board_root

		# Scale to fit our display size
		var tex_size = texture.get_size()
		var scale_x = BOARD_DISPLAY_SIZE.x / tex_size.x
		var scale_y = BOARD_DISPLAY_SIZE.y / tex_size.y
		background.scale = Vector2(scale_x, scale_y)

		board_root.add_child(background)

	# Position the board root at center
	board_root.position = center_position

	# Grid origin is offset from center (grid is in the middle of the board)
	# The grid is 3x3 tiles, centered
	var grid_half_size = (GRID_SIZE * SCALED_TILE) / 2.0

	return {
		"root": board_root,
		"grid_origin": center_position - Vector2(grid_half_size, grid_half_size),
		"cell_size": SCALED_TILE,
	}


func clear_board() -> void:
	"""Remove all board elements."""
	if board_root and is_instance_valid(board_root):
		board_root.queue_free()
		board_root = null
