extends Resource
class_name StageData
## Data container for a campaign stage

# Stage identification
@export var stage_id: String = "1-1"  # "1-1", "1-2", etc.
@export var stage_name: String = "The Beginning"
@export var chapter: int = 1
@export var stage_number: int = 1  # Within chapter

# Story text (placeholder for now)
@export_multiline var story_intro: String = "A new challenge awaits..."
@export_multiline var story_outro: String = "Victory! The path ahead grows clearer."

# Enemy configuration
@export var enemy_units: Array[UnitData] = []
@export var enemy_level: int = 1  # Affects enemy stats

# Difficulty display (1-5 stars)
@export var difficulty: int = 1

# Rewards
@export var gem_reward: int = 50  # Gems earned on first clear
@export var gold_reward: int = 100  # Gold earned on victory
@export var material_reward: int = 5  # Materials earned on victory
@export var xp_reward: int = 50  # XP for participating units on victory
@export var first_clear_unit: UnitData = null  # Optional unit reward on first clear

# Get display string for difficulty stars
func get_difficulty_stars() -> String:
	return "★".repeat(difficulty) + "☆".repeat(5 - difficulty)

# Get formatted stage number for display
func get_stage_display() -> String:
	return str(chapter) + "-" + str(stage_number)
