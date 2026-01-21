extends Node
## Singleton for managing player data (currency, owned units, pity)
## Add as autoload named "PlayerData"

# Save file path
const SAVE_FILE_PATH = "user://save_data.json"

# Currencies
var gems: int = 1000  # Starting gems for new players
var gold: int = 5000  # Starting gold for leveling units
var level_materials: int = 100  # Starting materials for leveling units
var enhancement_stones: int = 50  # Starting stones for new players

# Owned gear: Array of gear instances
# Each entry: {instance_id: String, gear_data: GearData, level: int, equipped_to: String}
var owned_gear: Array = []
var next_gear_instance_id: int = 1

# Dungeon mode tracking
var current_dungeon = null  # DungeonData resource
var current_dungeon_tier: int = 0  # 0=Easy, 1=Normal, 2=Hard

# PvP mode flag (set by PvP lobby)
var pvp_mode: bool = false

# Campaign progress
var campaign_progress: Dictionary = {}  # {stage_id: {cleared: bool, stars: int}}
var current_stage_id: String = ""  # Set before entering battle
var current_stage = null  # The actual stage data (StageData resource)

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

# Leveling constants
const BASE_XP_PER_LEVEL: int = 100  # XP needed for level 2
const XP_GROWTH_RATE: float = 1.15  # Each level needs 15% more XP
const GOLD_PER_LEVEL: int = 50  # Base gold cost per level
const MATERIALS_PER_LEVEL: int = 2  # Base materials per level
const STAT_GROWTH_PER_LEVEL: float = 0.03  # 3% stat increase per level

# Available unit pool (loaded on ready)
var unit_pool_3_star: Array[UnitData] = []
var unit_pool_4_star: Array[UnitData] = []
var unit_pool_5_star: Array[UnitData] = []

# Unit paths for save/load (maps unit_id to resource path)
var unit_paths: Dictionary = {}

func _ready():
	_load_unit_pools()
	_build_unit_paths()
	_load_gear_templates()
	if not load_game():
		# No save file - give starter units to new players
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
	# Give player 3 starter units (one of each basic element)
	print("Giving starter units to new player...")

	var starter_paths = [
		"res://resources/units/fire_imp.tres",
		"res://resources/units/water_sprite.tres",
		"res://resources/units/nature_wisp.tres"
	]

	for path in starter_paths:
		var unit_data = load(path) as UnitData
		if unit_data:
			_add_unit_to_collection(unit_data)

	print("Starter units granted: Fire Imp, Water Sprite, Nature Wisp")
	save_game()

func _build_unit_paths():
	# Build a mapping of unit_id to resource path for save/load
	var unit_files = [
		"res://resources/units/fire_warrior.tres",
		"res://resources/units/fire_imp.tres",
		"res://resources/units/water_mage.tres",
		"res://resources/units/water_sprite.tres",
		"res://resources/units/nature_tank.tres",
		"res://resources/units/nature_wisp.tres",
		"res://resources/units/light_cleric.tres",
		"res://resources/units/radiant_paladin.tres",
		"res://resources/units/shadow_scout.tres",
		"res://resources/units/dark_knight.tres"
	]

	for path in unit_files:
		var unit_data = load(path) as UnitData
		if unit_data:
			unit_paths[unit_data.unit_id] = path

# Gear template paths for generating drops
var gear_templates: Dictionary = {}  # {stat_type: {rarity: [GearData]}}

func _load_gear_templates():
	# Initialize structure
	for stat in GearData.StatType.values():
		gear_templates[stat] = {}
		for rarity in GearData.GearRarity.values():
			gear_templates[stat][rarity] = []

	# Load all gear resources
	var gear_dir = "res://resources/gear/"
	var dir = DirAccess.open(gear_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var gear = load(gear_dir + file_name) as GearData
				if gear:
					gear_templates[gear.stat_type][gear.rarity].append(gear)
			file_name = dir.get_next()
		dir.list_dir_end()

	print("Loaded gear templates")

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
	save_game()
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

	save_game()
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
		"imprint_level": 0,
		"level": 1,
		"xp": 0
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
	save_game()
	return true

# --- Campaign Progress Methods ---

func is_stage_cleared(stage_id: String) -> bool:
	if campaign_progress.has(stage_id):
		return campaign_progress[stage_id].cleared
	return false

func clear_stage(stage_id: String, stars: int = 3):
	if not campaign_progress.has(stage_id):
		campaign_progress[stage_id] = {"cleared": false, "stars": 0}

	campaign_progress[stage_id].cleared = true
	# Only update stars if new score is higher
	if stars > campaign_progress[stage_id].stars:
		campaign_progress[stage_id].stars = stars

	print("Stage ", stage_id, " cleared with ", stars, " stars!")
	save_game()

func get_stage_stars(stage_id: String) -> int:
	if campaign_progress.has(stage_id):
		return campaign_progress[stage_id].stars
	return 0

func is_stage_unlocked(stage_id: String) -> bool:
	# First stage is always unlocked
	if stage_id == "1-1":
		return true

	# Parse stage_id to get previous stage
	var parts = stage_id.split("-")
	if parts.size() != 2:
		return false

	var chapter = int(parts[0])
	var stage_num = int(parts[1])

	# Previous stage in same chapter
	if stage_num > 1:
		var prev_stage = str(chapter) + "-" + str(stage_num - 1)
		return is_stage_cleared(prev_stage)
	else:
		# First stage of new chapter - need to clear last stage of previous chapter
		if chapter > 1:
			var prev_stage = str(chapter - 1) + "-5"  # Assuming 5 stages per chapter
			return is_stage_cleared(prev_stage)

	return false

func give_stage_rewards(stage) -> Dictionary:
	var rewards = {"gems": 0, "unit": null, "first_clear": false}

	if stage == null:
		return rewards

	# Check if this is first clear
	var is_first_clear = not is_stage_cleared(stage.stage_id)
	rewards.first_clear = is_first_clear

	if is_first_clear:
		# Give gem reward
		gems += stage.gem_reward
		rewards.gems = stage.gem_reward
		print("First clear bonus: +", stage.gem_reward, " gems!")

		# Give unit reward if applicable
		if stage.first_clear_unit != null:
			var unit_entry = _add_unit_to_collection(stage.first_clear_unit)
			rewards.unit = unit_entry
			print("First clear unit reward: ", stage.first_clear_unit.unit_name, "!")

	return rewards

func is_campaign_mode() -> bool:
	return current_stage_id != "" and current_stage != null

func start_campaign_stage(stage):
	current_stage_id = stage.stage_id
	current_stage = stage
	pvp_mode = false
	print("Starting campaign stage: ", stage.stage_id, " - ", stage.stage_name)

func end_campaign_stage():
	current_stage_id = ""
	current_stage = null

# --- Unit Leveling System ---

func get_max_level(star_rating: int) -> int:
	# Max level = star rating * 10
	return star_rating * 10

func get_xp_for_level(level: int) -> int:
	# XP required to reach the next level
	return int(BASE_XP_PER_LEVEL * pow(XP_GROWTH_RATE, level - 1))

func get_total_xp_for_level(target_level: int) -> int:
	# Total XP needed to reach a specific level from level 1
	var total = 0
	for lvl in range(1, target_level):
		total += get_xp_for_level(lvl)
	return total

func get_level_up_cost(current_level: int, levels_to_gain: int) -> Dictionary:
	# Calculate gold and materials needed to level up
	var total_gold = 0
	var total_materials = 0
	for i in range(levels_to_gain):
		var lvl = current_level + i
		total_gold += GOLD_PER_LEVEL * lvl
		total_materials += MATERIALS_PER_LEVEL + int(lvl / 10)  # More materials at higher levels
	return {"gold": total_gold, "materials": total_materials}

func can_level_up(instance_id: String, levels: int = 1) -> Dictionary:
	# Check if player can afford to level up a unit
	var unit = get_unit_by_instance_id(instance_id)
	if unit.is_empty():
		return {"can_level": false, "reason": "Unit not found"}

	var unit_data = unit.unit_data as UnitData
	var current_level = unit.get("level", 1)
	var max_level = get_max_level(unit_data.star_rating)

	if current_level >= max_level:
		return {"can_level": false, "reason": "Already at max level"}

	var target_level = min(current_level + levels, max_level)
	var actual_levels = target_level - current_level

	var cost = get_level_up_cost(current_level, actual_levels)

	if gold < cost.gold:
		return {"can_level": false, "reason": "Not enough gold", "cost": cost}
	if level_materials < cost.materials:
		return {"can_level": false, "reason": "Not enough materials", "cost": cost}

	return {"can_level": true, "cost": cost, "levels": actual_levels, "target_level": target_level}

func level_up_unit(instance_id: String, levels: int = 1) -> bool:
	var check = can_level_up(instance_id, levels)
	if not check.can_level:
		print("Cannot level up: ", check.reason)
		return false

	# Find and update the unit
	for i in range(owned_units.size()):
		if owned_units[i].instance_id == instance_id:
			var cost = check.cost
			gold -= cost.gold
			level_materials -= cost.materials

			owned_units[i].level = check.target_level
			owned_units[i].xp = 0  # Reset XP after manual level up

			var unit_data = owned_units[i].unit_data as UnitData
			print("Leveled up ", unit_data.unit_name, " to level ", check.target_level)
			save_game()
			return true

	return false

func add_xp_to_unit(instance_id: String, xp_amount: int) -> Dictionary:
	# Add XP to a unit, handling level ups
	var result = {"leveled_up": false, "levels_gained": 0, "new_level": 0}

	for i in range(owned_units.size()):
		if owned_units[i].instance_id == instance_id:
			var unit_data = owned_units[i].unit_data as UnitData
			var current_level = owned_units[i].get("level", 1)
			var current_xp = owned_units[i].get("xp", 0)
			var max_level = get_max_level(unit_data.star_rating)

			if current_level >= max_level:
				result.new_level = current_level
				return result

			current_xp += xp_amount
			var levels_gained = 0

			# Check for level ups
			while current_level < max_level:
				var xp_needed = get_xp_for_level(current_level)
				if current_xp >= xp_needed:
					current_xp -= xp_needed
					current_level += 1
					levels_gained += 1
				else:
					break

			owned_units[i].level = current_level
			owned_units[i].xp = current_xp

			if levels_gained > 0:
				result.leveled_up = true
				result.levels_gained = levels_gained
				print(unit_data.unit_name, " gained ", levels_gained, " level(s)! Now level ", current_level)

			result.new_level = current_level
			return result

	return result

func get_unit_stats_at_level(unit_data: UnitData, level: int, imprint_level: int = 0) -> Dictionary:
	# Calculate stats for a unit at a specific level
	var level_mult = 1.0 + (STAT_GROWTH_PER_LEVEL * (level - 1))
	var imprint_mult = 1.0 + (0.05 * imprint_level)  # 5% per imprint level
	var total_mult = level_mult * imprint_mult

	return {
		"max_hp": int(unit_data.max_hp * total_mult),
		"attack": int(unit_data.attack * total_mult),
		"defense": int(unit_data.defense * total_mult),
		"speed": int(unit_data.speed * total_mult)
	}

func add_gold(amount: int):
	gold += amount
	print("+", amount, " gold (Total: ", gold, ")")

func add_materials(amount: int):
	level_materials += amount
	print("+", amount, " materials (Total: ", level_materials, ")")

# --- Gear System ---

func add_gear_to_inventory(gear_data: GearData) -> Dictionary:
	if gear_data == null:
		return {}

	var gear_entry = {
		"instance_id": "g" + str(next_gear_instance_id),
		"gear_data": gear_data,
		"level": 0,
		"equipped_to": ""  # Empty = not equipped
	}
	next_gear_instance_id += 1
	owned_gear.append(gear_entry)

	print("New gear: ", gear_data.gear_name, " (", GearData.GearRarity.keys()[gear_data.rarity], ")")
	return gear_entry

func get_gear_by_instance_id(instance_id: String) -> Dictionary:
	for gear in owned_gear:
		if gear.instance_id == instance_id:
			return gear
	return {}

func get_equipped_gear(unit_instance_id: String) -> Array:
	var equipped = []
	for gear in owned_gear:
		if gear.equipped_to == unit_instance_id:
			equipped.append(gear)
	return equipped

func get_unequipped_gear() -> Array:
	var unequipped = []
	for gear in owned_gear:
		if gear.equipped_to == "":
			unequipped.append(gear)
	return unequipped

func equip_gear(gear_instance_id: String, unit_instance_id: String) -> bool:
	var gear = get_gear_by_instance_id(gear_instance_id)
	var unit = get_unit_by_instance_id(unit_instance_id)

	if gear.is_empty() or unit.is_empty():
		return false

	var gear_data = gear.gear_data as GearData

	# Check if unit already has gear in this slot
	var equipped = get_equipped_gear(unit_instance_id)
	for eq in equipped:
		var eq_data = eq.gear_data as GearData
		# Weapons go in weapon slot, armor in armor, accessories can stack (2 max)
		if gear_data.gear_type == eq_data.gear_type:
			if gear_data.gear_type != GearData.GearType.ACCESSORY:
				print("Slot already occupied!")
				return false
			else:
				# Count accessories
				var acc_count = 0
				for e in equipped:
					if (e.gear_data as GearData).gear_type == GearData.GearType.ACCESSORY:
						acc_count += 1
				if acc_count >= 2:
					print("Max accessories equipped!")
					return false

	# Unequip from previous owner if any
	if gear.equipped_to != "":
		unequip_gear(gear_instance_id)

	# Equip to new owner
	for i in range(owned_gear.size()):
		if owned_gear[i].instance_id == gear_instance_id:
			owned_gear[i].equipped_to = unit_instance_id
			print("Equipped ", gear_data.gear_name, " to ", unit.unit_data.unit_name)
			save_game()
			return true

	return false

func unequip_gear(gear_instance_id: String) -> bool:
	for i in range(owned_gear.size()):
		if owned_gear[i].instance_id == gear_instance_id:
			owned_gear[i].equipped_to = ""
			print("Unequipped ", (owned_gear[i].gear_data as GearData).gear_name)
			save_game()
			return true
	return false

func can_enhance_gear(gear_instance_id: String) -> Dictionary:
	var gear = get_gear_by_instance_id(gear_instance_id)
	if gear.is_empty():
		return {"can_enhance": false, "reason": "Gear not found"}

	var gear_data = gear.gear_data as GearData
	var current_level = gear.level
	var max_level = gear_data.get_max_level()

	if current_level >= max_level:
		return {"can_enhance": false, "reason": "Already at max level"}

	var cost = gear_data.get_enhance_cost(current_level)

	if gold < cost.gold:
		return {"can_enhance": false, "reason": "Not enough gold", "cost": cost}
	if enhancement_stones < cost.stones:
		return {"can_enhance": false, "reason": "Not enough stones", "cost": cost}

	return {"can_enhance": true, "cost": cost}

func enhance_gear(gear_instance_id: String) -> bool:
	var check = can_enhance_gear(gear_instance_id)
	if not check.can_enhance:
		print("Cannot enhance: ", check.reason)
		return false

	for i in range(owned_gear.size()):
		if owned_gear[i].instance_id == gear_instance_id:
			var cost = check.cost
			gold -= cost.gold
			enhancement_stones -= cost.stones
			owned_gear[i].level += 1

			var gear_data = owned_gear[i].gear_data as GearData
			print("Enhanced ", gear_data.gear_name, " to +", owned_gear[i].level)
			save_game()
			return true

	return false

func add_enhancement_stones(amount: int):
	enhancement_stones += amount
	print("+", amount, " Enhancement Stones (Total: ", enhancement_stones, ")")

# Calculate gear stat bonuses for a unit
func get_gear_bonuses(unit_instance_id: String) -> Dictionary:
	var bonuses = {
		"flat_hp": 0, "flat_attack": 0, "flat_defense": 0, "flat_speed": 0,
		"percent_hp": 0.0, "percent_attack": 0.0, "percent_defense": 0.0, "percent_speed": 0.0
	}

	var equipped = get_equipped_gear(unit_instance_id)
	for gear in equipped:
		var gear_data = gear.gear_data as GearData
		var stat_value = gear_data.get_stat_at_level(gear.level)

		var stat_key = ""
		match gear_data.stat_type:
			GearData.StatType.HP: stat_key = "hp"
			GearData.StatType.ATTACK: stat_key = "attack"
			GearData.StatType.DEFENSE: stat_key = "defense"
			GearData.StatType.SPEED: stat_key = "speed"

		if gear_data.is_percentage:
			bonuses["percent_" + stat_key] += stat_value / 100.0  # Convert to decimal
		else:
			bonuses["flat_" + stat_key] += int(stat_value)

	return bonuses

# --- Dungeon Mode ---

func is_dungeon_mode() -> bool:
	return current_dungeon != null

func start_dungeon(dungeon, tier: int):
	current_dungeon = dungeon
	current_dungeon_tier = tier
	pvp_mode = false
	current_stage_id = ""
	current_stage = null
	print("Starting dungeon: ", dungeon.dungeon_name, " (", dungeon.tier_names[tier], ")")

func end_dungeon():
	current_dungeon = null
	current_dungeon_tier = 0

func generate_gear_drop() -> GearData:
	if current_dungeon == null:
		return null

	var dungeon = current_dungeon
	var rates = dungeon.get_drop_rates(current_dungeon_tier)
	var stat_type = dungeon.drops_stat_type

	# Roll for rarity
	var roll = randf()
	var cumulative = 0.0
	var rarity = GearData.GearRarity.COMMON

	for i in range(rates.size()):
		cumulative += rates[i]
		if roll < cumulative:
			rarity = i
			break

	# Get gear from templates
	if gear_templates.has(stat_type) and gear_templates[stat_type].has(rarity):
		var templates = gear_templates[stat_type][rarity]
		if templates.size() > 0:
			return templates[randi() % templates.size()]

	return null

func generate_stone_drop() -> int:
	if current_dungeon == null:
		return 0

	var range_arr = current_dungeon.get_stone_drop_range(current_dungeon_tier)
	return randi_range(range_arr[0], range_arr[1])

# --- Save/Load System ---

func _serialize_gear() -> Array:
	var serialized = []
	for gear_entry in owned_gear:
		var gear_data = gear_entry.gear_data as GearData
		serialized.append({
			"instance_id": gear_entry.instance_id,
			"gear_id": gear_data.gear_id,
			"level": gear_entry.level,
			"equipped_to": gear_entry.equipped_to
		})
	return serialized

func _deserialize_gear(gear_data_array: Array) -> Array:
	var loaded_gear = []
	# We need to load gear by ID - for now, scan all gear resources
	var gear_by_id = {}
	var gear_dir = "res://resources/gear/"
	var dir = DirAccess.open(gear_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var gear = load(gear_dir + file_name) as GearData
				if gear:
					gear_by_id[gear.gear_id] = gear
			file_name = dir.get_next()
		dir.list_dir_end()

	for gear_save in gear_data_array:
		var gear_id = gear_save.get("gear_id", "")
		if gear_by_id.has(gear_id):
			loaded_gear.append({
				"instance_id": gear_save.get("instance_id", "g" + str(next_gear_instance_id)),
				"gear_data": gear_by_id[gear_id],
				"level": int(gear_save.get("level", 0)),
				"equipped_to": gear_save.get("equipped_to", "")
			})

	return loaded_gear

func save_game():
	var save_data = {
		"version": 4,  # Updated for gear system
		"gems": gems,
		"gold": gold,
		"level_materials": level_materials,
		"enhancement_stones": enhancement_stones,
		"pity_counter": pity_counter,
		"next_instance_id": next_instance_id,
		"next_gear_instance_id": next_gear_instance_id,
		"campaign_progress": campaign_progress,
		"owned_units": _serialize_units(),
		"owned_gear": _serialize_gear()
	}

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game saved successfully!")
		return true
	else:
		push_error("Failed to save game!")
		return false

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found - starting fresh")
		return false

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open save file!")
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file!")
		return false

	var save_data = json.get_data()

	# Load data
	gems = int(save_data.get("gems", 1000))
	gold = int(save_data.get("gold", 5000))
	level_materials = int(save_data.get("level_materials", 100))
	enhancement_stones = int(save_data.get("enhancement_stones", 50))
	pity_counter = int(save_data.get("pity_counter", 0))
	next_instance_id = int(save_data.get("next_instance_id", 1))
	next_gear_instance_id = int(save_data.get("next_gear_instance_id", 1))
	campaign_progress = save_data.get("campaign_progress", {})

	# Load owned units
	var units_data = save_data.get("owned_units", [])
	owned_units = _deserialize_units(units_data)

	# Load owned gear
	var gear_data_array = save_data.get("owned_gear", [])
	owned_gear = _deserialize_gear(gear_data_array)

	print("Game loaded successfully! Gems: ", gems, ", Units: ", owned_units.size(), ", Gear: ", owned_gear.size())
	return true

func _serialize_units() -> Array:
	var serialized = []
	for unit_entry in owned_units:
		var unit_data = unit_entry.unit_data as UnitData
		serialized.append({
			"instance_id": unit_entry.instance_id,
			"unit_id": unit_data.unit_id,
			"imprint_level": unit_entry.imprint_level,
			"level": unit_entry.get("level", 1),
			"xp": unit_entry.get("xp", 0)
		})
	return serialized

func _deserialize_units(units_data: Array) -> Array:
	var loaded_units = []
	for unit_save in units_data:
		var unit_id = unit_save.get("unit_id", "")
		var unit_path = unit_paths.get(unit_id, "")

		if unit_path == "":
			push_warning("Unknown unit_id in save: " + unit_id)
			continue

		var unit_data = load(unit_path) as UnitData
		if unit_data:
			loaded_units.append({
				"instance_id": unit_save.get("instance_id", str(next_instance_id)),
				"unit_data": unit_data,
				"imprint_level": int(unit_save.get("imprint_level", 0)),
				"level": int(unit_save.get("level", 1)),
				"xp": int(unit_save.get("xp", 0))
			})

	return loaded_units

func delete_save():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("Save file deleted")
