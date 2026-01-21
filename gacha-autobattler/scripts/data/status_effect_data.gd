extends Resource
class_name StatusEffectData
## Data container for status effects applied to units

enum EffectType { OVERHEAT, CORRUPTED, DISRUPTED, SHIELDED, OVERCLOCKED }

@export var effect_id: String = ""
@export var effect_name: String = ""
@export var effect_type: EffectType = EffectType.OVERHEAT
@export var description: String = ""
@export var base_duration: int = 2

# OVERHEAT - Damage over time
@export var damage_per_turn: int = 0

# CORRUPTED - Stat reduction
@export var attack_modifier: float = 1.0   # 0.7 = -30%
@export var defense_modifier: float = 1.0  # 0.7 = -30%

# DISRUPTED - Ability lockout
@export var prevents_abilities: bool = false

# SHIELDED - Damage absorption
@export var shield_amount: int = 0

# OVERCLOCKED - Stat boost
@export var attack_boost: float = 1.0   # 1.3 = +30%
@export var defense_boost: float = 1.0  # 1.3 = +30%

# Visual
@export var icon_color: Color = Color.RED
@export var icon_symbol: String = "!"

# Behavior
@export var refresh_on_reapply: bool = true
