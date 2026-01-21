extends Resource
class_name UnitData
## Data container for a unit's stats and info

# Basic info
@export var unit_name: String = "Unit"
@export var unit_id: String = "unit_001"
@export var star_rating: int = 3  # 3, 4, or 5 star base

# Element: fire, water, nature, dark, light
@export var element: String = "fire"

# Base stats
@export var max_hp: int = 100
@export var attack: int = 20
@export var defense: int = 10
@export var speed: int = 10

# Abilities (3 abilities per unit)
@export var abilities: Array[AbilityData] = []

# Visual
@export var portrait_color: Color = Color.WHITE  # Placeholder until we have art

# Get element color for UI display
func get_element_color() -> Color:
	match element:
		"fire":
			return Color(1.0, 0.4, 0.2)  # Orange-red
		"water":
			return Color(0.2, 0.6, 1.0)  # Blue
		"nature":
			return Color(0.3, 0.8, 0.3)  # Green
		"dark":
			return Color(0.5, 0.2, 0.7)  # Purple
		"light":
			return Color(1.0, 0.95, 0.5)  # Yellow
		_:
			return Color.WHITE

# Get element advantage: returns 1.0 (neutral), 1.3 (advantage), 0.7 (disadvantage)
func get_element_multiplier(defender_element: String) -> float:
	# Fire > Nature > Water > Fire
	# Dark <-> Light (mutual advantage)

	match element:
		"fire":
			if defender_element == "nature":
				return 1.3
			elif defender_element == "water":
				return 0.7
		"water":
			if defender_element == "fire":
				return 1.3
			elif defender_element == "nature":
				return 0.7
		"nature":
			if defender_element == "water":
				return 1.3
			elif defender_element == "fire":
				return 0.7
		"dark":
			if defender_element == "light":
				return 1.3
		"light":
			if defender_element == "dark":
				return 1.3

	return 1.0
