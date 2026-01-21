extends Node2D
## Visual representation of a unit on the battle grid

var unit_instance: UnitInstance

# Visual references
@onready var body = $Body
@onready var element_rings = [$ElementRing, $ElementRing2, $ElementRing3, $ElementRing4]
@onready var star_label = $StarLabel
@onready var name_label = $NameLabel
@onready var hp_bar = $HPBar
@onready var hp_fill = $HPBar/HPFill
@onready var cooldown_overlay = $CooldownOverlay

func setup(instance: UnitInstance):
	unit_instance = instance

	if unit_instance and unit_instance.unit_data:
		var data = unit_instance.unit_data

		# Set name
		name_label.text = data.unit_name

		# Set stars
		star_label.text = "★".repeat(data.star_rating)

		# Set element color on ring
		var element_color = data.get_element_color()
		for ring in element_rings:
			ring.color = element_color

		# Set body color (placeholder - would be portrait later)
		body.color = data.portrait_color

		# Update HP bar
		update_hp_display()

		# Update cooldown
		update_cooldown_display()

func update_hp_display():
	if unit_instance and unit_instance.unit_data:
		var hp_percent = float(unit_instance.current_hp) / float(unit_instance.unit_data.max_hp)
		hp_fill.offset_right = 90.0 * hp_percent

		# Change color based on HP
		if hp_percent > 0.5:
			hp_fill.color = Color(0.2, 0.8, 0.2)  # Green
		elif hp_percent > 0.25:
			hp_fill.color = Color(0.8, 0.8, 0.2)  # Yellow
		else:
			hp_fill.color = Color(0.8, 0.2, 0.2)  # Red

func update_cooldown_display():
	if unit_instance:
		cooldown_overlay.visible = unit_instance.is_on_cooldown

func set_selected(selected: bool):
	# Visual feedback when unit is selected
	if selected:
		modulate = Color(1.2, 1.2, 1.2)  # Brighten
	else:
		modulate = Color(1.0, 1.0, 1.0)  # Normal
