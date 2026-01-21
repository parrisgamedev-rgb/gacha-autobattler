extends Resource
class_name UnitInstance
## An instance of a unit in battle with current state

# Reference to base data
var unit_data: UnitData

# Level and imprint
var level: int = 1
var imprint_level: int = 0

# Reference to player's unit instance for gear lookup
var gear_instance_id: String = ""

# Scaled stats (calculated from level/imprint)
var max_hp: int = 100
var attack: int = 10
var defense: int = 10
var speed: int = 10

# Current battle state
var current_hp: int = 100
var is_on_cooldown: bool = false
var cooldown_turns_remaining: int = 0

# Status effects: Array of {effect_data: StatusEffectData, duration: int, shield_remaining: int, source_owner: int}
var active_status_effects: Array = []

# Position on grid (-1, -1 means not placed)
var grid_row: int = -1
var grid_col: int = -1

# Owner: 1 = player, 2 = enemy
var owner: int = 1

# Selected ability for next duel (index into unit_data.abilities)
var selected_ability_index: int = 0

# Per-ability cooldowns (ability_id -> turns remaining)
var ability_cooldowns: Dictionary = {}

func get_selected_ability() -> AbilityData:
	if unit_data and unit_data.abilities.size() > selected_ability_index:
		return unit_data.abilities[selected_ability_index]
	return null

func is_ability_available(ability_index: int) -> bool:
	if not unit_data or ability_index >= unit_data.abilities.size():
		return false
	var ability = unit_data.abilities[ability_index]
	return not ability_cooldowns.has(ability.ability_id) or ability_cooldowns[ability.ability_id] <= 0

func get_ability_cooldown(ability_index: int) -> int:
	if not unit_data or ability_index >= unit_data.abilities.size():
		return 0
	var ability = unit_data.abilities[ability_index]
	if ability_cooldowns.has(ability.ability_id):
		return ability_cooldowns[ability.ability_id]
	return 0

func put_ability_on_cooldown(ability: AbilityData):
	if ability and ability.cooldown > 0:
		ability_cooldowns[ability.ability_id] = ability.cooldown

func process_ability_cooldowns():
	for ability_id in ability_cooldowns.keys():
		ability_cooldowns[ability_id] -= 1
		if ability_cooldowns[ability_id] <= 0:
			ability_cooldowns.erase(ability_id)

func _init(data: UnitData = null, unit_owner: int = 1, unit_level: int = 1, unit_imprint: int = 0, unit_gear_id: String = ""):
	if data:
		unit_data = data
		level = unit_level
		imprint_level = unit_imprint
		gear_instance_id = unit_gear_id
		_calculate_stats()
		current_hp = max_hp
	owner = unit_owner

func _calculate_stats():
	if not unit_data:
		return

	# Calculate stat multiplier based on level and imprint
	var level_mult = 1.0 + (0.03 * (level - 1))
	var imprint_mult = 1.0 + (0.05 * imprint_level)
	var total_mult = level_mult * imprint_mult

	# Base stats with level/imprint multiplier
	var base_hp = int(unit_data.max_hp * total_mult)
	var base_attack = int(unit_data.attack * total_mult)
	var base_defense = int(unit_data.defense * total_mult)
	var base_speed = int(unit_data.speed * total_mult)

	# Apply gear bonuses if we have an instance_id to look up
	# Note: gear_instance_id must be set externally when creating from player data
	if gear_instance_id != "":
		var gear_bonuses = PlayerData.get_gear_bonuses(gear_instance_id)

		# Add flat bonuses first
		base_hp += gear_bonuses.flat_hp
		base_attack += gear_bonuses.flat_attack
		base_defense += gear_bonuses.flat_defense
		base_speed += gear_bonuses.flat_speed

		# Then apply percentage bonuses
		base_hp = int(base_hp * (1.0 + gear_bonuses.percent_hp))
		base_attack = int(base_attack * (1.0 + gear_bonuses.percent_attack))
		base_defense = int(base_defense * (1.0 + gear_bonuses.percent_defense))
		base_speed = int(base_speed * (1.0 + gear_bonuses.percent_speed))

	max_hp = base_hp
	attack = base_attack
	defense = base_defense
	speed = base_speed

func is_alive() -> bool:
	return current_hp > 0

func is_knocked_out() -> bool:
	return current_hp <= 0

func is_placed() -> bool:
	return grid_row >= 0 and grid_col >= 0

## Revive this unit with a percentage of max HP (0.0 to 1.0)
## Returns true if successfully revived, false if unit was already alive
func revive(hp_percent: float = 0.5) -> bool:
	if is_alive():
		return false  # Already alive, can't revive

	current_hp = int(max_hp * clamp(hp_percent, 0.1, 1.0))
	is_on_cooldown = false
	cooldown_turns_remaining = 0
	# Clear negative status effects on revive
	active_status_effects = active_status_effects.filter(func(e): return not e.effect_data.is_debuff if e.effect_data.has("is_debuff") else true)
	print(unit_data.unit_name, " revived with ", current_hp, "/", max_hp, " HP!")
	return true

func can_act() -> bool:
	return is_alive() and not is_on_cooldown

func place_on_grid(row: int, col: int):
	grid_row = row
	grid_col = col

func remove_from_grid():
	grid_row = -1
	grid_col = -1

func start_cooldown():
	is_on_cooldown = true
	cooldown_turns_remaining = 1

func process_turn_end() -> Dictionary:
	if is_on_cooldown:
		cooldown_turns_remaining -= 1
		if cooldown_turns_remaining <= 0:
			is_on_cooldown = false
			cooldown_turns_remaining = 0
	# Process ability cooldowns
	process_ability_cooldowns()

	# Process status effects and return any damage/healing
	var effect_result = process_status_effects()

	# Apply status effect damage
	if effect_result.damage > 0:
		take_damage(effect_result.damage)

	# Apply status effect healing
	if effect_result.healing > 0:
		heal(effect_result.healing)

	return effect_result

func take_damage(amount: int):
	current_hp = max(0, current_hp - amount)

func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)

# --- Status Effect Methods ---

func apply_status_effect(effect_data: StatusEffectData, source_owner: int):
	if not effect_data:
		return

	# Check if we already have this effect
	for i in range(active_status_effects.size()):
		var existing = active_status_effects[i]
		if existing.effect_data.effect_id == effect_data.effect_id:
			if effect_data.refresh_on_reapply:
				# Refresh duration
				existing.duration = effect_data.base_duration
				# For shields, refresh the shield amount too
				if effect_data.shield_amount > 0:
					existing.shield_remaining = effect_data.shield_amount
				print("  Refreshed ", effect_data.effect_name, " on ", unit_data.unit_name)
			return

	# Apply new effect
	var new_effect = {
		"effect_data": effect_data,
		"duration": effect_data.base_duration,
		"shield_remaining": effect_data.shield_amount,
		"source_owner": source_owner
	}
	active_status_effects.append(new_effect)
	print("  Applied ", effect_data.effect_name, " to ", unit_data.unit_name, " for ", effect_data.base_duration, " turns")

func remove_status_effect(effect_id: String):
	for i in range(active_status_effects.size() - 1, -1, -1):
		if active_status_effects[i].effect_data.effect_id == effect_id:
			var removed = active_status_effects[i]
			active_status_effects.remove_at(i)
			print("  Removed ", removed.effect_data.effect_name, " from ", unit_data.unit_name)
			return

func has_status_effect(effect_type: StatusEffectData.EffectType) -> bool:
	for effect in active_status_effects:
		if effect.effect_data.effect_type == effect_type:
			return true
	return false

func is_disrupted() -> bool:
	for effect in active_status_effects:
		if effect.effect_data.prevents_abilities:
			return true
	return false

func get_stat_modifiers_from_effects() -> Dictionary:
	var mods = {"attack": 1.0, "defense": 1.0}

	for effect in active_status_effects:
		var data = effect.effect_data as StatusEffectData
		# Apply stat reductions (CORRUPTED)
		mods.attack *= data.attack_modifier
		mods.defense *= data.defense_modifier
		# Apply stat boosts (OVERCLOCKED)
		mods.attack *= data.attack_boost
		mods.defense *= data.defense_boost

	return mods

func absorb_damage_with_shield(incoming_damage: int) -> int:
	var remaining_damage = incoming_damage

	for effect in active_status_effects:
		if effect.shield_remaining > 0:
			var absorbed = min(effect.shield_remaining, remaining_damage)
			effect.shield_remaining -= absorbed
			remaining_damage -= absorbed
			print("  Shield absorbed ", absorbed, " damage (", effect.shield_remaining, " shield remaining)")

			# Remove shield effect if depleted
			if effect.shield_remaining <= 0:
				print("  Shield depleted!")

			if remaining_damage <= 0:
				break

	return max(0, remaining_damage)

func process_status_effects() -> Dictionary:
	var result = {"damage": 0, "healing": 0}
	var effects_to_remove = []

	for i in range(active_status_effects.size()):
		var effect = active_status_effects[i]
		var data = effect.effect_data as StatusEffectData

		# Apply DOT damage
		if data.damage_per_turn > 0:
			result.damage += data.damage_per_turn
			print("  ", unit_data.unit_name, " takes ", data.damage_per_turn, " ", data.effect_name, " damage")

		# Decrement duration
		effect.duration -= 1

		# Mark expired effects for removal (but not shields that still have remaining)
		if effect.duration <= 0:
			# For shields, only expire if duration is up (even if shield has remaining HP)
			effects_to_remove.append(i)
			print("  ", data.effect_name, " expired on ", unit_data.unit_name)

	# Remove expired effects (in reverse order to preserve indices)
	for i in range(effects_to_remove.size() - 1, -1, -1):
		active_status_effects.remove_at(effects_to_remove[i])

	return result

func clear_all_status_effects():
	active_status_effects.clear()
