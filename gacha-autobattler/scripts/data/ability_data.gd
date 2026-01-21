extends Resource
class_name AbilityData
## Data container for an ability

# Ability types
enum AbilityType { ACTIVE, PASSIVE }
enum TargetType { SELF, ENEMY, BOTH }

# Basic info
@export var ability_name: String = "Attack"
@export var ability_id: String = "basic_attack"
@export var description: String = "A basic attack."
@export var ability_type: AbilityType = AbilityType.ACTIVE

# For active abilities - what it does in combat
@export var damage_multiplier: float = 1.0  # Multiplier on unit's attack stat
@export var defense_multiplier: float = 1.0  # Multiplier on unit's defense during this duel
@export var heal_amount: int = 0  # Flat healing after duel
@export var bonus_damage: int = 0  # Flat bonus damage

# Special effects
@export var ignores_element: bool = false  # Ignores element advantage/disadvantage
@export var guaranteed_survive: bool = false  # Can't be knocked out this duel (survive with 1 HP)
@export var counter_attack: bool = false  # Deal damage back if hit
@export var piercing: bool = false  # Ignores defense

# Cooldown (0 = no cooldown, can use every turn)
@export var cooldown: int = 0  # Number of turns before ability can be used again

# Status and Field effects
@export var applies_status_effect: StatusEffectData = null
@export var applies_to_self: bool = false  # If true, effect applies to self instead of target
@export var applies_field_effect: FieldEffectData = null

# For passive abilities - when they trigger
@export var passive_trigger: String = ""  # "on_duel_start", "on_low_hp", "on_win", "on_lose"
@export var passive_hp_threshold: float = 0.3  # For "on_low_hp" trigger

# Visual
@export var icon_color: Color = Color.WHITE

func get_tooltip() -> String:
	var text = ability_name + "\n"
	text += description + "\n\n"

	if ability_type == AbilityType.ACTIVE:
		if damage_multiplier != 1.0:
			text += "Damage: " + str(int(damage_multiplier * 100)) + "%\n"
		if defense_multiplier != 1.0:
			text += "Defense: " + str(int(defense_multiplier * 100)) + "%\n"
		if bonus_damage > 0:
			text += "Bonus Damage: +" + str(bonus_damage) + "\n"
		if heal_amount > 0:
			text += "Heal: " + str(heal_amount) + " HP\n"
		if ignores_element:
			text += "Ignores element advantage\n"
		if guaranteed_survive:
			text += "Cannot be knocked out\n"
		if piercing:
			text += "Ignores enemy defense\n"
		if applies_status_effect:
			var target = "self" if applies_to_self else "target"
			text += "Applies " + applies_status_effect.effect_name + " to " + target + "\n"
		if applies_field_effect:
			text += "Creates " + applies_field_effect.field_name + "\n"
		if cooldown > 0:
			text += "Cooldown: " + str(cooldown) + " turn(s)\n"
	else:
		text += "[Passive]\n"
		text += "Triggers: " + passive_trigger + "\n"

	return text
