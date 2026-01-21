extends Node
## Singleton for managing player data (currency, owned units, pity)
## Add as autoload named "PlayerData"

# Currency
var gems: int = 999999  # Unlimited for testing

# Pity system
var pity_counter: int = 0
const SOFT_PITY_START: int = 50
const HARD_PITY: int = 100
const BASE_5_STAR_RATE: float = 0.02  # 2%
const BASE_4_STAR_RATE: float = 0.10  # 10%
# Remaining is 3-star: 88%

# Owned units: Array of individual unit instances
# Each entry: {instance_id: String, unit_data: UnitData, imprint_level: int}
var owned_units: Array = []
var next_instance_id: int = 1

# Selected team for battle (array of instance_ids)
var selected_team: Array = []

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
	var all_units: Array[UnitData] = []

	# Fire units
	all_units.append(load("res://resources/units/fire_warrior.tres") as UnitData)
	all_units.append(load("res://resources/units/fire_imp.tres") as UnitData)

	# Water units
	all_units.append(load("res://resources/units/water_mage.tres") as UnitData)
	all_units.append(load("res://resources/units/water_sprite.tres") as UnitData)

	# Nature units
	all_units.append(load("res://resources/units/nature_tank.tres") as UnitData)
	all_units.append(load("res://resources/units/nature_wisp.tres") as UnitData)

	# Light units
	all_units.append(load("res://resources/units/light_cleric.tres") as UnitData)
	all_units.append(load("res://resources/units/radiant_paladin.tres") as UnitData)

	# Dark units
	all_units.append(load("res://resources/units/shadow_scout.tres") as UnitData)
	all_units.append(load("res://resources/units/dark_knight.tres") as UnitData)

	# Sort into pools by star rating
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

func do_single_pull() -> Dictionary:
	if not can_afford_single():
		return {}

	gems -= SINGLE_PULL_COST
	var unit_data = _perform_pull()
	var unit_entry = _add_unit_to_collection(unit_data)
	return unit_entry

func do_multi_pull() -> Array:
	if not can_afford_multi():
		return []

	gems -= MULTI_PULL_COST
	var results: Array = []
	var got_4_star_or_higher = false

	for i in range(10):
		var unit_data: UnitData
		# Last pull guarantees 4-star or higher if none pulled yet
		if i == 9 and not got_4_star_or_higher:
			unit_data = _perform_guaranteed_4_star_pull()
		else:
			unit_data = _perform_pull()

		if unit_data.star_rating >= 4:
			got_4_star_or_higher = true

		var unit_entry = _add_unit_to_collection(unit_data)
		results.append(unit_entry)

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

func _add_unit_to_collection(unit_data: UnitData) -> Dictionary:
	if unit_data == null:
		return {}

	var unit_entry = {
		"instance_id": str(next_instance_id),
		"unit_data": unit_data,
		"imprint_level": 0
	}
	next_instance_id += 1
	owned_units.append(unit_entry)

	print("New unit: ", unit_data.unit_name, " (", unit_data.star_rating, "★) - ID: ", unit_entry.instance_id)
	return unit_entry

func get_owned_unit_list() -> Array:
	return owned_units

func get_unit_by_instance_id(instance_id: String) -> Dictionary:
	for unit in owned_units:
		if unit.instance_id == instance_id:
			return unit
	return {}

func get_selected_team_units() -> Array:
	var team = []
	for instance_id in selected_team:
		var unit = get_unit_by_instance_id(instance_id)
		if not unit.is_empty():
			team.append(unit)
	return team

func imprint_unit(target_instance_id: String, fodder_instance_id: String) -> bool:
	# Find target and fodder units
	var target_idx = -1
	var fodder_idx = -1

	for i in range(owned_units.size()):
		if owned_units[i].instance_id == target_instance_id:
			target_idx = i
		elif owned_units[i].instance_id == fodder_instance_id:
			fodder_idx = i

	if target_idx == -1 or fodder_idx == -1:
		return false

	var target = owned_units[target_idx]
	var fodder = owned_units[fodder_idx]

	# Must be same unit type
	if target.unit_data.unit_id != fodder.unit_data.unit_id:
		print("Cannot imprint different unit types!")
		return false

	# Max imprint level is 5
	if target.imprint_level >= 5:
		print("Unit already at max imprint!")
		return false

	# Increase imprint level and remove fodder
	owned_units[target_idx].imprint_level += 1
	owned_units.remove_at(fodder_idx)

	print("Imprinted ", target.unit_data.unit_name, " to level ", owned_units[target_idx].imprint_level)
	return true
