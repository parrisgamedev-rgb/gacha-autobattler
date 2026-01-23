extends Resource
class_name AchievementData
## Data definition for an achievement

enum Category { BATTLE, COLLECTION, PROGRESSION }
enum RequirementType {
	BATTLES_WON,      # Win X battles
	UNITS_OWNED,      # Own X units
	STAGE_CLEARED,    # Clear specific stage (uses requirement_param)
	GEAR_ENHANCED,    # Enhance gear to +X
	TURNS_UNDER       # Win battle in under X turns
}

@export var id: String = ""
@export var achievement_name: String = ""
@export_multiline var description: String = ""
@export var category: Category = Category.BATTLE
@export var gem_reward: int = 50
@export var requirement_type: RequirementType = RequirementType.BATTLES_WON
@export var requirement_value: int = 1
@export var requirement_param: String = ""  # For stage IDs, etc.


func get_category_name() -> String:
	match category:
		Category.BATTLE:
			return "Battle"
		Category.COLLECTION:
			return "Collection"
		Category.PROGRESSION:
			return "Progression"
	return "Unknown"


func get_progress_text(stats: Dictionary) -> String:
	"""Get progress text like '5/10 battles' based on current stats."""
	var current = _get_current_progress(stats)
	var target = requirement_value

	match requirement_type:
		RequirementType.BATTLES_WON:
			return "%d/%d battles" % [current, target]
		RequirementType.UNITS_OWNED:
			return "%d/%d units" % [current, target]
		RequirementType.STAGE_CLEARED:
			if is_complete(stats):
				return "Cleared"
			return "Not cleared"
		RequirementType.GEAR_ENHANCED:
			return "+%d/+%d gear" % [current, target]
		RequirementType.TURNS_UNDER:
			if current >= 999:
				return "Best: --"
			return "Best: %d turns" % current
	return ""


func is_complete(stats: Dictionary) -> bool:
	"""Check if this achievement is complete based on stats."""
	var current = _get_current_progress(stats)

	match requirement_type:
		RequirementType.TURNS_UNDER:
			# For "under X turns", current must be LESS than requirement
			return current < requirement_value and current > 0
		_:
			# For all others, current must be >= requirement
			return current >= requirement_value


func _get_current_progress(stats: Dictionary) -> int:
	"""Get the current progress value from stats."""
	match requirement_type:
		RequirementType.BATTLES_WON:
			return stats.get("battles_won", 0)
		RequirementType.UNITS_OWNED:
			return stats.get("units_owned", 0)
		RequirementType.STAGE_CLEARED:
			# Check if specific stage is cleared
			var cleared_stages = stats.get("cleared_stages", [])
			if requirement_param in cleared_stages:
				return 1
			return 0
		RequirementType.GEAR_ENHANCED:
			return stats.get("max_gear_level", 0)
		RequirementType.TURNS_UNDER:
			return stats.get("fastest_win_turns", 999)
	return 0
