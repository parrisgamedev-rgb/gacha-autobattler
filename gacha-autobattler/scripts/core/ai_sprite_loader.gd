extends Node
## Loads and manages sprite sheets for units (heroes and monsters)

# Maps unit_id to sprite folder name
const SPRITE_MAPPINGS = {
	# PLAYABLE HEROES
	"fire_warrior_001": "fire_warrior",
	"ember_001": "ember",
	"water_mage_001": "water_mage",
	"coral_001": "coral",
	"nature_wisp_001": "nature_wisp",
	"nature_tank_001": "nature_tank",
	"radiant_paladin_001": "radiant_paladin",
	"spark_001": "spark",
	"shadow_scout_001": "shadow_scout",
	"dark_knight_001": "dark_knight",
	# v0.17 playable units
	"gravebane": "gravebane",
	"ursok": "ursok",
	"shade": "shade",
	"fenris": "fenris",
	"vance": "vance",

	# MONSTERS (enemy-only)
	"monster_goblin_001": "monster_goblin",
	"monster_gladiator_beast_001": "monster_gladiator_beast",
	"monster_minotaur_001": "monster_minotaur",
	"monster_wolf_001": "monster_wolf",
	"monster_arena_champion_001": "monster_arena_champion",
	"monster_slime_001": "monster_slime",
	"monster_skeleton_warrior_001": "monster_skeleton_warrior",
	"monster_harpy_001": "monster_harpy",
	"monster_chimera_001": "monster_chimera",
	"monster_gladiator_001": "monster_gladiator",
	# v0.17 monsters
	"monster_werewolf": "monster_werewolf",
	"monster_werebear": "monster_werebear",
	"monster_greatsword_skeleton": "monster_greatsword_skeleton",
	"monster_alpha_werewolf": "monster_werewolf",  # Uses same sprite as werewolf
}

# Cache loaded textures
var _texture_cache: Dictionary = {}
var _atlas_cache: Dictionary = {}

# Animation settings - Updated for new sprite pack (100x100 frames)
const FRAME_SIZE = 100
const IDLE_FRAME_COUNT = 6
const ATTACK_FRAME_COUNT = 6
const HURT_FRAME_COUNT = 4
const DEATH_FRAME_COUNT = 6
const IDLE_FPS = 8.0  # Frames per second for idle animation
const ATTACK_FPS = 10.0  # Frames per second for attack animation
const HURT_FPS = 8.0  # Frames per second for hurt animation
const DEATH_FPS = 8.0  # Frames per second for death animation


func has_ai_sprite(unit_id: String) -> bool:
	"""Check if a unit has AI sprites available."""
	if unit_id not in SPRITE_MAPPINGS:
		return false

	var folder = SPRITE_MAPPINGS[unit_id]
	var idle_path = "res://assets/sprites/%s/idle.png" % folder
	return ResourceLoader.exists(idle_path)


func get_sprite_folder(unit_id: String) -> String:
	"""Get the sprite folder name for a unit."""
	return SPRITE_MAPPINGS.get(unit_id, "")


func load_sprite_sheet(unit_id: String, animation: String = "idle") -> Texture2D:
	"""Load a sprite sheet texture for a unit."""
	var cache_key = "%s_%s" % [unit_id, animation]

	if cache_key in _texture_cache:
		return _texture_cache[cache_key]

	if unit_id not in SPRITE_MAPPINGS:
		return null

	var folder = SPRITE_MAPPINGS[unit_id]
	var path = "res://assets/sprites/%s/%s.png" % [folder, animation]

	if not ResourceLoader.exists(path):
		return null

	var texture = load(path) as Texture2D
	_texture_cache[cache_key] = texture
	return texture


func get_frame_texture(unit_id: String, animation: String, frame: int) -> AtlasTexture:
	"""Get a single frame from a sprite sheet as an AtlasTexture."""
	var cache_key = "%s_%s_%d" % [unit_id, animation, frame]

	if cache_key in _atlas_cache:
		return _atlas_cache[cache_key]

	var sheet = load_sprite_sheet(unit_id, animation)
	if not sheet:
		return null

	var atlas = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(frame * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)

	_atlas_cache[cache_key] = atlas
	return atlas


func get_frame_count_for_sheet(sheet: Texture2D) -> int:
	"""Detect frame count from sprite sheet width."""
	if not sheet:
		return 0
	return int(sheet.get_width() / FRAME_SIZE)


func get_frame_count(animation: String) -> int:
	"""Get the default number of frames for an animation type."""
	match animation:
		"idle":
			return IDLE_FRAME_COUNT
		"attack":
			return ATTACK_FRAME_COUNT
		"hurt":
			return HURT_FRAME_COUNT
		"death":
			return DEATH_FRAME_COUNT
		_:
			return IDLE_FRAME_COUNT


func get_all_frames(unit_id: String, animation: String = "idle") -> Array[AtlasTexture]:
	"""Get all frames for an animation."""
	var frames: Array[AtlasTexture] = []
	var sheet = load_sprite_sheet(unit_id, animation)
	var frame_count = get_frame_count_for_sheet(sheet)

	for i in range(frame_count):
		var frame = get_frame_texture(unit_id, animation, i)
		if frame:
			frames.append(frame)

	return frames


func create_animated_sprite(unit_id: String) -> AnimatedSprite2D:
	"""Create an AnimatedSprite2D with idle animation for a unit."""
	if not has_ai_sprite(unit_id):
		return null

	var sprite = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()

	# Add idle animation
	var idle_sheet = load_sprite_sheet(unit_id, "idle")
	var idle_frame_count = get_frame_count_for_sheet(idle_sheet)
	frames.add_animation("idle")
	frames.set_animation_speed("idle", IDLE_FPS)
	frames.set_animation_loop("idle", true)

	for i in range(idle_frame_count):
		var frame_texture = get_frame_texture(unit_id, "idle", i)
		if frame_texture:
			frames.add_frame("idle", frame_texture)

	# Add attack animation if available
	var attack_sheet = load_sprite_sheet(unit_id, "attack")
	if attack_sheet:
		var attack_frame_count = get_frame_count_for_sheet(attack_sheet)
		frames.add_animation("attack")
		frames.set_animation_speed("attack", ATTACK_FPS)
		frames.set_animation_loop("attack", false)

		for i in range(attack_frame_count):
			var frame_texture = get_frame_texture(unit_id, "attack", i)
			if frame_texture:
				frames.add_frame("attack", frame_texture)

	# Add hurt animation if available
	var hurt_sheet = load_sprite_sheet(unit_id, "hurt")
	if hurt_sheet:
		var hurt_frame_count = get_frame_count_for_sheet(hurt_sheet)
		frames.add_animation("hurt")
		frames.set_animation_speed("hurt", HURT_FPS)
		frames.set_animation_loop("hurt", false)

		for i in range(hurt_frame_count):
			var frame_texture = get_frame_texture(unit_id, "hurt", i)
			if frame_texture:
				frames.add_frame("hurt", frame_texture)

	# Add death animation if available
	var death_sheet = load_sprite_sheet(unit_id, "death")
	if death_sheet:
		var death_frame_count = get_frame_count_for_sheet(death_sheet)
		frames.add_animation("death")
		frames.set_animation_speed("death", DEATH_FPS)
		frames.set_animation_loop("death", false)

		for i in range(death_frame_count):
			var frame_texture = get_frame_texture(unit_id, "death", i)
			if frame_texture:
				frames.add_frame("death", frame_texture)

	sprite.sprite_frames = frames
	sprite.animation = "idle"
	sprite.play("idle")

	return sprite
