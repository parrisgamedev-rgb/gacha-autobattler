extends Resource
class_name DungeonData
## Data container for a gear dungeon

@export var dungeon_id: String = "power_sanctum"
@export var dungeon_name: String = "Power Sanctum"
@export var description: String = "Farm ATK gear here"

# What stat type of gear drops here
@export var drops_stat_type: GearData.StatType = GearData.StatType.ATTACK

# Enemy configuration (reuse unit pool)
@export var enemy_units: Array[UnitData] = []

# Difficulty tiers (Easy, Normal, Hard)
@export var tier_enemy_levels: Array[int] = [3, 6, 10]
@export var tier_names: Array[String] = ["Easy", "Normal", "Hard"]

# Drop rates per tier [Common%, Rare%, Epic%, Legendary%]
const TIER_DROP_RATES = [
	[0.70, 0.25, 0.05, 0.00],  # Easy
	[0.40, 0.40, 0.18, 0.02],  # Normal
	[0.10, 0.40, 0.40, 0.10]   # Hard
]

# Enhancement stone drops per tier [min, max]
const TIER_STONE_DROPS = [
	[3, 5],   # Easy
	[6, 10],  # Normal
	[12, 18]  # Hard
]

func get_drop_rates(tier: int) -> Array:
	if tier >= 0 and tier < TIER_DROP_RATES.size():
		return TIER_DROP_RATES[tier]
	return TIER_DROP_RATES[0]

func get_stone_drop_range(tier: int) -> Array:
	if tier >= 0 and tier < TIER_STONE_DROPS.size():
		return TIER_STONE_DROPS[tier]
	return TIER_STONE_DROPS[0]

func get_enemy_level(tier: int) -> int:
	if tier >= 0 and tier < tier_enemy_levels.size():
		return tier_enemy_levels[tier]
	return 1
