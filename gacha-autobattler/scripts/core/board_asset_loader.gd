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

# Current chapter (affects which themed assets to load)
var current_chapter: int = 0

# Cached textures (keyed by chapter)
var _base_grid: Texture2D = null
var _ownership_textures: Dictionary = {}  # {chapter: {Ownership: Texture2D}}
var _field_effect_textures: Dictionary = {}  # {chapter: {FieldEffect: Texture2D}}


func _ready():
	_preload_assets()


func set_chapter(chapter: int):
	"""Set the current chapter for themed assets."""
	current_chapter = chapter
	# Preload chapter-specific assets if not already loaded
	if chapter not in _ownership_textures:
		_load_chapter_assets(chapter)


func _preload_assets():
	"""Preload default board assets for quick access."""
	# Load base grid
	if ResourceLoader.exists(BASE_GRID_PATH):
		_base_grid = load(BASE_GRID_PATH)

	# Load default (chapter 0) assets
	_load_chapter_assets(0)


func _load_chapter_assets(chapter: int):
	"""Load assets for a specific chapter."""
	_ownership_textures[chapter] = {}
	_field_effect_textures[chapter] = {}

	# Determine path based on chapter
	var ownership_path = OWNERSHIP_PATH
	var effects_path = FIELD_EFFECTS_PATH

	if chapter > 0:
		ownership_path = OWNERSHIP_PATH + "chapter_%d/" % chapter
		effects_path = FIELD_EFFECTS_PATH + "chapter_%d/" % chapter

	# Load ownership textures
	var ownership_files = {
		Ownership.PLAYER: "player.png",
		Ownership.ENEMY: "enemy.png",
		Ownership.CONTESTED: "contested.png"
	}

	for ownership in ownership_files:
		var path = ownership_path + ownership_files[ownership]
		if ResourceLoader.exists(path):
			_ownership_textures[chapter][ownership] = load(path)
		elif chapter > 0:
			# Fall back to default
			var fallback = OWNERSHIP_PATH + ownership_files[ownership]
			if ResourceLoader.exists(fallback):
				_ownership_textures[chapter][ownership] = load(fallback)

	# Load field effect textures
	var effect_files = {
		FieldEffect.THERMAL: "thermal.png",
		FieldEffect.REPAIR: "repair.png",
		FieldEffect.BOOST: "boost.png",
		FieldEffect.SUPPRESSION: "suppression.png"
	}

	for effect in effect_files:
		var path = effects_path + effect_files[effect]
		if ResourceLoader.exists(path):
			_field_effect_textures[chapter][effect] = load(path)
		elif chapter > 0:
			# Fall back to default
			var fallback = FIELD_EFFECTS_PATH + effect_files[effect]
			if ResourceLoader.exists(fallback):
				_field_effect_textures[chapter][effect] = load(fallback)


func get_base_grid() -> Texture2D:
	"""Get the base grid texture."""
	return _base_grid


func get_ownership_texture(ownership: Ownership) -> Texture2D:
	"""Get the texture for an ownership state (chapter-aware)."""
	if current_chapter in _ownership_textures:
		var chapter_textures = _ownership_textures[current_chapter]
		if ownership in chapter_textures:
			return chapter_textures[ownership]

	# Fall back to default
	if 0 in _ownership_textures:
		return _ownership_textures[0].get(ownership, null)
	return null


func get_field_effect_texture(effect: FieldEffect) -> Texture2D:
	"""Get the texture for a field effect (chapter-aware)."""
	if current_chapter in _field_effect_textures:
		var chapter_textures = _field_effect_textures[current_chapter]
		if effect in chapter_textures:
			return chapter_textures[effect]

	# Fall back to default
	if 0 in _field_effect_textures:
		return _field_effect_textures[0].get(effect, null)
	return null


func has_board_assets() -> bool:
	"""Check if board assets are available."""
	# Check if we have ownership textures for current chapter or default
	if current_chapter in _ownership_textures and _ownership_textures[current_chapter].size() > 0:
		return true
	if 0 in _ownership_textures and _ownership_textures[0].size() > 0:
		return true
	return false


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
