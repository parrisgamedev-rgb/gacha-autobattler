extends Node
## Singleton for managing player data (currency, owned units, pity)
## Add as autoload named "PlayerData"

# Currency
var gems: int = 1000  # Starting gems for testing

# Pity system
var pity_counter: int = 0
const SOFT_PITY_START: int = 50
const HARD_PITY: int = 100
const BASE_5_STAR_RATE: float = 0.02  # 2%
const BASE_4_STAR_RATE: float = 0.10  # 10%
# Remaining is 3-star: 88%

# Owned units: Dictionary of unit_id -> {data: UnitData, copies: int}
var owned_units: Dictionary = {}

# Cost per pull
const SINGLE_PULL_COST: int = 100
const MULTI_PULL_COST: int = 900  # 10 pulls for price of 9

# Available unit pool (loaded on ready)
var unit_pool_3_star: Array[UnitData] = []
var unit_pool_4_star: Array[UnitData] = []
var unit_pool_5_star: Array[UnitData] = []

func _ready():
	_load_unit_pools()
	_give_starter_units()

func _load_unit_pools():
	# Load all available units and sort by rarity
	var fire_warrior = load("res://resources/units/fire_warrior.tres") as UnitData
	var water_mage = load("res://resources/units/water_mage.tres") as UnitData
	var nature_tank = load("res://resources/units/nature_tank.tres") as UnitData

	# Sort into pools by star rating
	var all_units = [fire_warrior, water_mage, nature_tank]
	for unit in all_units:
		if unit:
			match unit.star_rating:
				3:
					unit_pool_3_star.append(unit)
				4:
					unit_pool_4_star.append(unit)
				5:
					unit_pool_5_star.append(unit)

	print("Loaded unit pools - 3★: ", unit_pool_3_star.size(), ", 4★: ", unit_pool_4_star.size(), ", 5★: ", unit_pool_5_star.size())

func _give_starter_units():
	# Give player some starter units
	pass  # For now, start with empty collection

func can_afford_single() -> bool:
	return gems >= SINGLE_PULL_COST

func can_afford_multi() -> bool:
	return gems >= MULTI_PULL_COST

func do_single_pull() -> UnitData:
	if not can_afford_single():
		return null

	gems -= SINGLE_PULL_COST
	var unit = _perform_pull()
	_add_unit_to_collection(unit)
	return unit

func do_multi_pull() -> Array[UnitData]:
	if not can_afford_multi():
		return []

	gems -= MULTI_PULL_COST
	var results: Array[UnitData] = []
	var got_4_star_or_higher = false

	for i in range(10):
		var unit: UnitData
		# Last pull guarantees 4-star or higher if none pulled yet
		if i == 9 and not got_4_star_or_higher:
			unit = _perform_guaranteed_4_star_pull()
		else:
			unit = _perform_pull()

		if unit.star_rating >= 4:
			got_4_star_or_higher = true

		_add_unit_to_collection(unit)
		results.append(unit)

	return results

func _perform_pull() -> UnitData:
	pity_counter += 1

	# Calculate 5-star rate with pity
	var five_star_rate = BASE_5_STAR_RATE
	if pity_counter >= SOFT_PITY_START:
		# Increase rate by 5% per pull after soft pity
		five_star_rate += (pity_counter - SOFT_PITY_START + 1) * 0.05

	# Hard pity guarantee
	if pity_counter >= HARD_PITY:
		pity_counter = 0
		return _get_random_from_pool(unit_pool_5_star)

	# Roll for rarity
	var roll = randf()

	if roll < five_star_rate:
		pity_counter = 0  # Reset pity on 5-star
		return _get_random_from_pool(unit_pool_5_star)
	elif roll < five_star_rate + BASE_4_STAR_RATE:
		return _get_random_from_pool(unit_pool_4_star)
	else:
		return _get_random_from_pool(unit_pool_3_star)

func _perform_guaranteed_4_star_pull() -> UnitData:
	pity_counter += 1

	# Calculate 5-star rate with pity (same as normal)
	var five_star_rate = BASE_5_STAR_RATE
	if pity_counter >= SOFT_PITY_START:
		five_star_rate += (pity_counter - SOFT_PITY_START + 1) * 0.05

	# Hard pity guarantee
	if pity_counter >= HARD_PITY:
		pity_counter = 0
		return _get_random_from_pool(unit_pool_5_star)

	# Roll between 4-star and 5-star only
	# Adjusted rates: 5-star keeps its rate, rest goes to 4-star
	var roll = randf()
	var adjusted_5_star_rate = five_star_rate / (five_star_rate + BASE_4_STAR_RATE)

	if roll < adjusted_5_star_rate:
		pity_counter = 0
		return _get_random_from_pool(unit_pool_5_star)
	else:
		return _get_random_from_pool(unit_pool_4_star)

func _get_random_from_pool(pool: Array[UnitData]) -> UnitData:
	if pool.is_empty():
		# Fallback if pool is empty - shouldn't happen in production
		push_warning("Empty unit pool, using fallback")
		if not unit_pool_3_star.is_empty():
			return unit_pool_3_star[randi() % unit_pool_3_star.size()]
		return null
	return pool[randi() % pool.size()]

func _add_unit_to_collection(unit: UnitData):
	if unit == null:
		return

	var unit_id = unit.unit_id
	if owned_units.has(unit_id):
		owned_units[unit_id].copies += 1
		print("Got duplicate ", unit.unit_name, "! Total copies: ", owned_units[unit_id].copies)
	else:
		owned_units[unit_id] = {
			"data": unit,
			"copies": 1
		}
		print("New unit: ", unit.unit_name, " (", unit.star_rating, "★)")

func get_owned_unit_list() -> Array:
	var result = []
	for unit_id in owned_units:
		result.append(owned_units[unit_id])
	return result

func get_unit_copies(unit_id: String) -> int:
	if owned_units.has(unit_id):
		return owned_units[unit_id].copies
	return 0

func get_imprint_level(unit_id: String) -> int:
	# 5 copies to max imprint (levels 0-4)
	var copies = get_unit_copies(unit_id)
	return min(copies - 1, 4) if copies > 0 else 0
