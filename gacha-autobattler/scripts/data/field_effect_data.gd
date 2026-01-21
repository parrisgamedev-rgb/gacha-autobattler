extends Resource
class_name FieldEffectData
## Data container for field effects applied to grid cells

enum FieldType { SUPPRESSION, REPAIR, THERMAL, BOOST }

@export var field_id: String = ""
@export var field_name: String = ""
@export var field_type: FieldType = FieldType.SUPPRESSION
@export var description: String = ""
@export var base_duration: int = 3

# Target filtering
@export var affects_enemies: bool = true
@export var affects_allies: bool = false

# Stat modifiers (applied during combat)
@export var attack_modifier: float = 1.0   # 0.8 = -20%, 1.2 = +20%
@export var defense_modifier: float = 1.0

# Per-turn effects
@export var damage_per_turn: int = 0
@export var heal_per_turn: int = 0

# Visual
@export var field_color: Color = Color(1.0, 0.3, 0.3, 0.3)
@export var icon_symbol: String = "▼"
