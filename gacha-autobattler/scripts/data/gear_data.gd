extends Resource
class_name GearData
## Data container for a gear template

enum GearType { WEAPON, ARMOR, ACCESSORY }
enum GearRarity { COMMON, RARE, EPIC, LEGENDARY }
enum StatType { HP, ATTACK, DEFENSE, SPEED }

# Identification
@export var gear_id: String = "gear_001"
@export var gear_name: String = "Iron Sword"
@export var gear_type: GearType = GearType.WEAPON
@export var rarity: GearRarity = GearRarity.COMMON

# Primary stat (only one stat per gear piece)
@export var stat_type: StatType = StatType.ATTACK
@export var is_percentage: bool = false  # false = flat, true = percentage
@export var base_value: float = 10.0  # Base stat value at +0

# Get max level based on rarity
func get_max_level() -> int:
	match rarity:
		GearRarity.COMMON: return 6
		GearRarity.RARE: return 9
		GearRarity.EPIC: return 12
		GearRarity.LEGENDARY: return 15
	return 6

# Get stat value at a specific level
func get_stat_at_level(level: int) -> float:
	# Linear scaling: value increases by ~150% from +0 to max level
	var max_level = get_max_level()
	var growth_per_level = base_value * 1.5 / max_level
	return base_value + (growth_per_level * level)

# Get enhancement cost for next level
func get_enhance_cost(current_level: int) -> Dictionary:
	var gold_per_level = 100
	var stones_per_level = 2
	match rarity:
		GearRarity.COMMON:
			gold_per_level = 100
			stones_per_level = 2
		GearRarity.RARE:
			gold_per_level = 200
			stones_per_level = 4
		GearRarity.EPIC:
			gold_per_level = 400
			stones_per_level = 8
		GearRarity.LEGENDARY:
			gold_per_level = 800
			stones_per_level = 15
	return {"gold": gold_per_level, "stones": stones_per_level}

# Get rarity color for UI
func get_rarity_color() -> Color:
	match rarity:
		GearRarity.COMMON: return Color(0.6, 0.6, 0.6)  # Gray
		GearRarity.RARE: return Color(0.3, 0.5, 1.0)  # Blue
		GearRarity.EPIC: return Color(0.7, 0.3, 0.9)  # Purple
		GearRarity.LEGENDARY: return Color(1.0, 0.8, 0.2)  # Gold
	return Color.WHITE

# Get type name for display
func get_type_name() -> String:
	match gear_type:
		GearType.WEAPON: return "Weapon"
		GearType.ARMOR: return "Armor"
		GearType.ACCESSORY: return "Accessory"
	return "Unknown"

# Get stat name for display
func get_stat_name() -> String:
	match stat_type:
		StatType.HP: return "HP"
		StatType.ATTACK: return "ATK"
		StatType.DEFENSE: return "DEF"
		StatType.SPEED: return "SPD"
	return "???"
