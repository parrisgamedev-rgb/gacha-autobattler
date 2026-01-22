extends Node
## Loads and manages AI-generated sprite sheets for units

# Maps unit_id to sprite folder name
const SPRITE_MAPPINGS = {
	"fire_warrior_001": "kael",
	# Add more mappings as sprites are created
}

# Cache loaded textures
var _texture_cache: Dictionary = {}
var _atlas_cache: Dictionary = {}

# Animation settings
const FRAME_SIZE = 128
const FRAME_COUNT = 3
const IDLE_FPS = 4.0  # Frames per second for idle animation


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


func get_all_frames(unit_id: String, animation: String = "idle") -> Array[AtlasTexture]:
	"""Get all frames for an animation."""
	var frames: Array[AtlasTexture] = []

	for i in range(FRAME_COUNT):
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
	frames.add_animation("idle")
	frames.set_animation_speed("idle", IDLE_FPS)
	frames.set_animation_loop("idle", true)

	for i in range(FRAME_COUNT):
		var frame_texture = get_frame_texture(unit_id, "idle", i)
		if frame_texture:
			frames.add_frame("idle", frame_texture)

	# Add attack animation if available
	if load_sprite_sheet(unit_id, "attack"):
		frames.add_animation("attack")
		frames.set_animation_speed("attack", 8.0)  # Faster for attack
		frames.set_animation_loop("attack", false)

		for i in range(FRAME_COUNT):
			var frame_texture = get_frame_texture(unit_id, "attack", i)
			if frame_texture:
				frames.add_frame("attack", frame_texture)

	# Add hurt animation if available
	if load_sprite_sheet(unit_id, "hurt"):
		frames.add_animation("hurt")
		frames.set_animation_speed("hurt", 6.0)
		frames.set_animation_loop("hurt", false)

		for i in range(FRAME_COUNT):
			var frame_texture = get_frame_texture(unit_id, "hurt", i)
			if frame_texture:
				frames.add_frame("hurt", frame_texture)

	sprite.sprite_frames = frames
	sprite.animation = "idle"
	sprite.play("idle")

	return sprite
