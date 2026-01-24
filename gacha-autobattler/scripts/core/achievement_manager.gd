extends Node
## Manages achievement tracking, checking, and notifications
## Add as autoload named "AchievementManager"

signal achievement_unlocked(achievement: AchievementData)

# All loaded achievements
var all_achievements: Array[AchievementData] = []

# Reference to popup (set when popup is instantiated)
var popup: Node = null
var popup_scene: PackedScene = null

# Queue for achievements to show (if multiple unlock at once)
var popup_queue: Array[AchievementData] = []
var is_showing_popup: bool = false


func _ready():
	_load_achievements()
	# Preload popup scene
	popup_scene = load("res://scenes/ui/achievement_popup.tscn")


func _load_achievements():
	"""Load all achievement resources explicitly (directory scanning fails in exports)."""
	var achievement_files := [
		"first_blood.tres",
		"warrior.tres",
		"veteran.tres",
		"speed_demon.tres",
		"collector.tres",
		"gear_up.tres",
		"chapter_1_clear.tres",
		"chapter_2_clear.tres",
		"chapter_3_clear.tres",
	]

	for file_name in achievement_files:
		var achievement = load("res://resources/achievements/" + file_name) as AchievementData
		if achievement:
			all_achievements.append(achievement)

	print("[AchievementManager] Loaded ", all_achievements.size(), " achievements")


func get_all_achievements() -> Array[AchievementData]:
	"""Get all achievements."""
	return all_achievements


func get_achievements_by_category(category: AchievementData.Category) -> Array[AchievementData]:
	"""Get achievements filtered by category."""
	var filtered: Array[AchievementData] = []
	for achievement in all_achievements:
		if achievement.category == category:
			filtered.append(achievement)
	return filtered


func is_unlocked(achievement_id: String) -> bool:
	"""Check if an achievement is unlocked."""
	return achievement_id in PlayerData.unlocked_achievements


func get_stats() -> Dictionary:
	"""Get current achievement stats from PlayerData."""
	return PlayerData.achievement_stats


# --- Trigger Methods (called from game code) ---

func on_battle_won(turn_count: int):
	"""Called when player wins a battle."""
	PlayerData.achievement_stats["battles_won"] += 1

	# Update fastest win if this was faster
	if turn_count < PlayerData.achievement_stats["fastest_win_turns"]:
		PlayerData.achievement_stats["fastest_win_turns"] = turn_count

	PlayerData.save_game()
	_check_achievements()


func on_unit_added():
	"""Called when player gains a new unit."""
	# Count unique units owned
	PlayerData.achievement_stats["units_owned"] = PlayerData.owned_units.size()
	PlayerData.save_game()
	_check_achievements()


func on_stage_cleared(stage_id: String):
	"""Called when player clears a campaign stage."""
	if stage_id not in PlayerData.achievement_stats["cleared_stages"]:
		PlayerData.achievement_stats["cleared_stages"].append(stage_id)
		PlayerData.save_game()
	_check_achievements()


func on_gear_enhanced(new_level: int):
	"""Called when player enhances gear."""
	if new_level > PlayerData.achievement_stats["max_gear_level"]:
		PlayerData.achievement_stats["max_gear_level"] = new_level
		PlayerData.save_game()
	_check_achievements()


# --- Internal Methods ---

func _check_achievements():
	"""Check all achievements and unlock any that are newly completed."""
	var stats = get_stats()

	for achievement in all_achievements:
		# Skip already unlocked
		if is_unlocked(achievement.id):
			continue

		# Check if complete
		if achievement.is_complete(stats):
			_unlock_achievement(achievement)


func _unlock_achievement(achievement: AchievementData):
	"""Unlock an achievement, grant reward, and show popup."""
	# Mark as unlocked
	PlayerData.unlocked_achievements.append(achievement.id)

	# Grant gem reward
	PlayerData.gems += achievement.gem_reward
	PlayerData.save_game()

	print("[Achievement] Unlocked: ", achievement.achievement_name, " (+", achievement.gem_reward, " gems)")

	# Emit signal
	achievement_unlocked.emit(achievement)

	# Queue popup
	_queue_popup(achievement)


func _queue_popup(achievement: AchievementData):
	"""Add achievement to popup queue and show if not already showing."""
	popup_queue.append(achievement)

	if not is_showing_popup:
		_show_next_popup()


func _show_next_popup():
	"""Show the next achievement popup in queue."""
	if popup_queue.is_empty():
		is_showing_popup = false
		return

	is_showing_popup = true
	var achievement = popup_queue.pop_front()

	# Create popup instance if needed
	if popup == null and popup_scene:
		popup = popup_scene.instantiate()
		get_tree().root.add_child(popup)
		popup.popup_dismissed.connect(_on_popup_dismissed)

	if popup:
		popup.show_achievement(achievement)


func _on_popup_dismissed():
	"""Called when popup is dismissed, show next in queue."""
	# Small delay before showing next
	await get_tree().create_timer(0.3).timeout
	_show_next_popup()


# --- Utility for retroactive unlocks ---

func check_retroactive_achievements():
	"""Check achievements based on existing progress (for players updating to new version)."""
	# Update units_owned count
	PlayerData.achievement_stats["units_owned"] = PlayerData.owned_units.size()

	# Update cleared_stages from campaign_progress
	for stage_id in PlayerData.campaign_progress.keys():
		if PlayerData.campaign_progress[stage_id].get("cleared", false):
			if stage_id not in PlayerData.achievement_stats["cleared_stages"]:
				PlayerData.achievement_stats["cleared_stages"].append(stage_id)

	# Update max_gear_level from owned gear
	for gear in PlayerData.owned_gear:
		var level = gear.get("level", 0)
		if level > PlayerData.achievement_stats["max_gear_level"]:
			PlayerData.achievement_stats["max_gear_level"] = level

	PlayerData.save_game()
	_check_achievements()
