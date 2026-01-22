extends Node
## Loads and manages board assets for dynamic game board states

# Ownership states
enum Ownership { NONE, PLAYER, ENEMY, CONTESTED }

# Field effect types (matching existing game effects)
enum FieldEffect { NONE, THERMAL, REPAIR, BOOST, SUPPRESSION }

# Asset paths
const BASE_PATH = "res://assets/board/"
const BASE_GRID_PATH = BASE_PATH + "base/grid.png"
const OWNERSHIP_PATH = BASE_PATH + "ownership/"
const FIELD_EFFECTS_PATH = BASE_PATH + "field_effects/"

# Cached textures
var _base_grid: Texture2D = null
var _ownership_textures: Dictionary = {}
var _field_effect_textures: Dictionary = {}


func _ready():
	_preload_assets()


func _preload_assets():
	"""Preload all board assets for quick access."""
	# Load base grid
	if ResourceLoader.exists(BASE_GRID_PATH):
		_base_grid = load(BASE_GRID_PATH)

	# Load ownership textures
	var ownership_files = {
		Ownership.PLAYER: "player.png",
		Ownership.ENEMY: "enemy.png",
		Ownership.CONTESTED: "contested.png"
	}

	for ownership in ownership_files:
		var path = OWNERSHIP_PATH + ownership_files[ownership]
		if ResourceLoader.exists(path):
			_ownership_textures[ownership] = load(path)

	# Load field effect textures
	var effect_files = {
		FieldEffect.THERMAL: "thermal.png",
		FieldEffect.REPAIR: "repair.png",
		FieldEffect.BOOST: "boost.png",
		FieldEffect.SUPPRESSION: "suppression.png"
	}

	for effect in effect_files:
		var path = FIELD_EFFECTS_PATH + effect_files[effect]
		if ResourceLoader.exists(path):
			_field_effect_textures[effect] = load(path)


func get_base_grid() -> Texture2D:
	"""Get the base grid texture."""
	return _base_grid


func get_ownership_texture(ownership: Ownership) -> Texture2D:
	"""Get the texture for an ownership state."""
	return _ownership_textures.get(ownership, null)


func get_field_effect_texture(effect: FieldEffect) -> Texture2D:
	"""Get the texture for a field effect."""
	return _field_effect_textures.get(effect, null)


func has_board_assets() -> bool:
	"""Check if board assets are available."""
	return _base_grid != null


func field_effect_from_string(effect_name: String) -> FieldEffect:
	"""Convert field effect string name to enum."""
	match effect_name.to_lower():
		"thermal", "thermal_field":
			return FieldEffect.THERMAL
		"repair", "repair_field":
			return FieldEffect.REPAIR
		"boost", "boost_field":
			return FieldEffect.BOOST
		"suppression", "suppression_field":
			return FieldEffect.SUPPRESSION
		_:
			return FieldEffect.NONE
