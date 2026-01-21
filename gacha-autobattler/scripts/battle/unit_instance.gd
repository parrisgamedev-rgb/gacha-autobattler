extends Resource
class_name UnitInstance
## An instance of a unit in battle with current state

# Reference to base data
var unit_data: UnitData

# Current battle state
var current_hp: int = 100
var is_on_cooldown: bool = false
var cooldown_turns_remaining: int = 0

# Position on grid (-1, -1 means not placed)
var grid_row: int = -1
var grid_col: int = -1

# Owner: 1 = player, 2 = enemy
var owner: int = 1

# Selected ability for next duel (index into unit_data.abilities)
var selected_ability_index: int = 0

func get_selected_ability() -> AbilityData:
	if unit_data and unit_data.abilities.size() > selected_ability_index:
		return unit_data.abilities[selected_ability_index]
	return null

func _init(data: UnitData = null, unit_owner: int = 1):
	if data:
		unit_data = data
		current_hp = data.max_hp
	owner = unit_owner

func is_alive() -> bool:
	return current_hp > 0

func is_placed() -> bool:
	return grid_row >= 0 and grid_col >= 0

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

func process_turn_end():
	if is_on_cooldown:
		cooldown_turns_remaining -= 1
		if cooldown_turns_remaining <= 0:
			is_on_cooldown = false
			cooldown_turns_remaining = 0

func take_damage(amount: int):
	current_hp = max(0, current_hp - amount)

func heal(amount: int):
	if unit_data:
		current_hp = min(unit_data.max_hp, current_hp + amount)
