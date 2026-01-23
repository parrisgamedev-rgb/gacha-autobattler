extends Node
## Global audio manager - handles all game audio
## Add as autoload named "AudioManager"

# Audio buses
const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"

# Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

# Music players (two for crossfading)
var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var active_music_player: AudioStreamPlayer
var current_music_path: String = ""

# SFX pool for concurrent sounds
var sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 8

# Preloaded sound effects (loaded on demand, cached)
var sfx_cache: Dictionary = {}

# Sound effect paths
const SFX_PATHS = {
	# UI Sounds
	"ui_click": "res://assets/audio/sfx/ui_click.ogg",
	"ui_hover": "res://assets/audio/sfx/ui_click.ogg",  # Fallback to click
	"ui_back": "res://assets/audio/sfx/ui_click.ogg",   # Fallback to click
	"ui_confirm": "res://assets/audio/sfx/ui_click.ogg", # Fallback to click

	# Battle Sounds
	"attack_hit": "res://assets/audio/sfx/attack_hit.ogg",
	"attack_miss": "res://assets/audio/sfx/attack_hit.ogg",  # Fallback
	"attack_crit": "res://assets/audio/sfx/attack_hit.ogg",  # Fallback
	"ability_fire": "res://assets/audio/sfx/attack_hit.ogg", # Fallback
	"ability_water": "res://assets/audio/sfx/attack_hit.ogg", # Fallback
	"ability_nature": "res://assets/audio/sfx/attack_hit.ogg", # Fallback
	"ability_light": "res://assets/audio/sfx/attack_hit.ogg", # Fallback
	"ability_dark": "res://assets/audio/sfx/attack_hit.ogg", # Fallback
	"ability_heal": "res://assets/audio/sfx/heal.ogg",
	"ability_buff": "res://assets/audio/sfx/heal.ogg",   # Fallback to heal
	"ability_debuff": "res://assets/audio/sfx/attack_hit.ogg", # Fallback
	"unit_death": "res://assets/audio/sfx/unit_death.ogg",
	"unit_place": "res://assets/audio/sfx/unit_place.ogg",

	# Victory/Defeat
	"victory_fanfare": "res://assets/audio/sfx/victory_fanfare.ogg",
	"defeat_sound": "res://assets/audio/sfx/defeat.ogg",

	# Gacha Sounds
	"summon_buildup": "res://assets/audio/sfx/summon_buildup.ogg",
	"summon_reveal_3star": "res://assets/audio/sfx/summon_reveal_3star.ogg",
	"summon_reveal_4star": "res://assets/audio/sfx/summon_reveal_4star.ogg",
	"summon_reveal_5star": "res://assets/audio/sfx/summon_reveal_5star.ogg",
}

# Music paths
const MUSIC_PATHS = {
	"menu": "res://assets/audio/music/menu_theme.wav",
	"battle": "res://assets/audio/music/battle_theme.mp3",
	"victory": "res://assets/audio/music/victory_theme.mp3",
	"defeat": "res://assets/audio/music/defeat_theme.mp3",
}

# Settings save path
const AUDIO_SETTINGS_PATH = "user://audio_settings.json"


func _ready():
	# Set up audio buses if they don't exist
	_setup_audio_buses()

	# Create music players
	_create_music_players()

	# Create SFX pool
	_create_sfx_pool()

	# Load saved settings
	load_settings()

	# Apply initial volumes
	_apply_volumes()


func _setup_audio_buses():
	# Check if buses exist, create if not
	# Note: In production, create these in Project Settings > Audio > Buses
	if AudioServer.get_bus_index(BUS_MUSIC) == -1:
		var music_bus_idx = AudioServer.bus_count
		AudioServer.add_bus(music_bus_idx)
		AudioServer.set_bus_name(music_bus_idx, BUS_MUSIC)
		AudioServer.set_bus_send(music_bus_idx, BUS_MASTER)

	if AudioServer.get_bus_index(BUS_SFX) == -1:
		var sfx_bus_idx = AudioServer.bus_count
		AudioServer.add_bus(sfx_bus_idx)
		AudioServer.set_bus_name(sfx_bus_idx, BUS_SFX)
		AudioServer.set_bus_send(sfx_bus_idx, BUS_MASTER)


func _create_music_players():
	music_player_a = AudioStreamPlayer.new()
	music_player_a.name = "MusicPlayerA"
	music_player_a.bus = BUS_MUSIC
	add_child(music_player_a)

	music_player_b = AudioStreamPlayer.new()
	music_player_b.name = "MusicPlayerB"
	music_player_b.bus = BUS_MUSIC
	add_child(music_player_b)

	active_music_player = music_player_a


func _create_sfx_pool():
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_" + str(i)
		player.bus = BUS_SFX
		add_child(player)
		sfx_pool.append(player)


func _apply_volumes():
	# Convert linear (0-1) to dB (-80 to 0)
	var master_db = linear_to_db(master_volume) if master_volume > 0 else -80
	var music_db = linear_to_db(music_volume) if music_volume > 0 else -80
	var sfx_db = linear_to_db(sfx_volume) if sfx_volume > 0 else -80

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), master_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), music_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), sfx_db)


# === PUBLIC API ===

func play_sfx(sound_name: String, volume_scale: float = 1.0, pitch_scale: float = 1.0):
	"""Play a sound effect by name."""
	if not SFX_PATHS.has(sound_name):
		push_warning("AudioManager: Unknown SFX: " + sound_name)
		return

	var stream = _get_cached_sfx(sound_name)
	if stream == null:
		return

	# Find available player in pool
	var player = _get_available_sfx_player()
	if player == null:
		push_warning("AudioManager: SFX pool exhausted")
		return

	player.stream = stream
	player.volume_db = linear_to_db(volume_scale)
	player.pitch_scale = pitch_scale
	player.play()


func play_sfx_positional(sound_name: String, position: Vector2, volume_scale: float = 1.0):
	"""Play a sound effect - position parameter for future 2D audio support."""
	# For now, just play normally (can add AudioStreamPlayer2D later)
	play_sfx(sound_name, volume_scale)


func play_music(music_name: String, fade_duration: float = 1.0, loop: bool = true):
	"""Play background music with optional crossfade."""
	if not MUSIC_PATHS.has(music_name):
		push_warning("AudioManager: Unknown music: " + music_name)
		return

	var path = MUSIC_PATHS[music_name]

	# Don't restart if already playing
	if current_music_path == path and active_music_player.playing:
		return

	# Load music stream
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: Music file not found: " + path)
		return

	var stream = load(path)
	if stream == null:
		return

	current_music_path = path

	# Get the inactive player
	var new_player = music_player_b if active_music_player == music_player_a else music_player_a
	var old_player = active_music_player

	# Set up new player
	new_player.stream = stream
	new_player.volume_db = -80  # Start silent
	new_player.play()

	# Crossfade
	if fade_duration > 0 and old_player.playing:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(old_player, "volume_db", -80, fade_duration)
		tween.tween_property(new_player, "volume_db", 0, fade_duration)
		tween.chain().tween_callback(old_player.stop)
	else:
		old_player.stop()
		new_player.volume_db = 0

	active_music_player = new_player

	# Handle looping
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = loop


func stop_music(fade_duration: float = 1.0):
	"""Stop current music with optional fade out."""
	if not active_music_player.playing:
		return

	current_music_path = ""

	if fade_duration > 0:
		var tween = create_tween()
		tween.tween_property(active_music_player, "volume_db", -80, fade_duration)
		tween.chain().tween_callback(active_music_player.stop)
	else:
		active_music_player.stop()


func pause_music():
	"""Pause current music."""
	active_music_player.stream_paused = true


func resume_music():
	"""Resume paused music."""
	active_music_player.stream_paused = false


func set_master_volume(value: float):
	"""Set master volume (0.0 to 1.0)."""
	master_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()


func set_music_volume(value: float):
	"""Set music volume (0.0 to 1.0)."""
	music_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()


func set_sfx_volume(value: float):
	"""Set SFX volume (0.0 to 1.0)."""
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()


func get_master_volume() -> float:
	return master_volume


func get_music_volume() -> float:
	return music_volume


func get_sfx_volume() -> float:
	return sfx_volume


# === HELPER FUNCTIONS ===

func _get_cached_sfx(sound_name: String) -> AudioStream:
	"""Get or load a sound effect."""
	if sfx_cache.has(sound_name):
		return sfx_cache[sound_name]

	var path = SFX_PATHS[sound_name]
	if not ResourceLoader.exists(path):
		# File doesn't exist yet (placeholder) - silently fail
		return null

	var stream = load(path)
	if stream:
		sfx_cache[sound_name] = stream
	return stream


func _get_available_sfx_player() -> AudioStreamPlayer:
	"""Get an available player from the pool."""
	for player in sfx_pool:
		if not player.playing:
			return player
	# All busy - return the first one (will cut off oldest sound)
	return sfx_pool[0]


# === SETTINGS PERSISTENCE ===

func save_settings():
	"""Save audio settings to file."""
	var settings = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}

	var file = FileAccess.open(AUDIO_SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))
		file.close()


func load_settings():
	"""Load audio settings from file."""
	if not FileAccess.file_exists(AUDIO_SETTINGS_PATH):
		return

	var file = FileAccess.open(AUDIO_SETTINGS_PATH, FileAccess.READ)
	if not file:
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return

	var settings = json.get_data()

	master_volume = settings.get("master_volume", 1.0)
	music_volume = settings.get("music_volume", 0.8)
	sfx_volume = settings.get("sfx_volume", 1.0)


# === CONVENIENCE FUNCTIONS ===

func play_ui_click():
	play_sfx("ui_click")


func play_ui_hover():
	play_sfx("ui_hover", 0.5)


func play_ui_back():
	play_sfx("ui_back")


func play_ui_confirm():
	play_sfx("ui_confirm")


func play_attack_hit(is_crit: bool = false):
	if is_crit:
		play_sfx("attack_crit")
	else:
		play_sfx("attack_hit")


func play_ability_sound(element: String):
	var sound_name = "ability_" + element.to_lower()
	if SFX_PATHS.has(sound_name):
		play_sfx(sound_name)
	else:
		play_sfx("attack_hit")


func play_heal_sound():
	play_sfx("ability_heal")


func play_unit_death():
	play_sfx("unit_death")


func play_unit_place():
	play_sfx("unit_place")


func play_victory():
	play_sfx("victory_fanfare")


func play_defeat():
	play_sfx("defeat_sound")


func play_summon_buildup():
	play_sfx("summon_buildup")


func play_summon_reveal(star_rating: int):
	match star_rating:
		5:
			play_sfx("summon_reveal_5star")
		4:
			play_sfx("summon_reveal_4star")
		_:
			play_sfx("summon_reveal_3star")
