extends Control
## Floating ability selector tooltip that appears near units

signal ability_selected(index: int)
signal dismissed()

@onready var backdrop = $Backdrop
@onready var panel = $Panel
@onready var title_label = $Panel/VBox/Title
@onready var ability_buttons = [$Panel/VBox/ButtonContainer/Ability1, $Panel/VBox/ButtonContainer/Ability2, $Panel/VBox/ButtonContainer/Ability3]
@onready var description_label = $Panel/VBox/Description
@onready var arrow = $Arrow

var current_unit: UnitInstance = null
var target_position: Vector2 = Vector2.ZERO

func _ready():
	# Connect button signals
	for i in range(ability_buttons.size()):
		var btn = ability_buttons[i]
		if btn:
			btn.pressed.connect(_on_ability_pressed.bind(i))

	# Connect backdrop click to dismiss
	if backdrop:
		backdrop.gui_input.connect(_on_backdrop_input)

	# Start hidden
	visible = false

	# Apply theme
	_apply_theme()

func _on_backdrop_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_dismiss()

func _apply_theme():
	if panel and panel is Panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
		style.border_color = Color(0.4, 0.4, 0.5, 1)
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", style)

	if arrow:
		arrow.color = Color(0.12, 0.12, 0.18, 0.95)

	if title_label:
		title_label.add_theme_font_size_override("font_size", 14)
		title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))

	if description_label:
		description_label.add_theme_font_size_override("font_size", 11)
		description_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))

func show_for_unit(unit: UnitInstance, screen_pos: Vector2):
	current_unit = unit
	target_position = screen_pos

	if not unit:
		hide_tooltip()
		return

	# Position tooltip above the unit
	position = Vector2(screen_pos.x, screen_pos.y - 160)

	# Keep tooltip on screen
	var viewport_size = get_viewport_rect().size
	if position.x < 150:
		position.x = 150
	elif position.x > viewport_size.x - 150:
		position.x = viewport_size.x - 150

	if position.y < 10:
		# Show below unit instead - arrow at top pointing up
		position.y = screen_pos.y + 60
		arrow.position.y = 0
		arrow.rotation_degrees = 180  # Flip arrow to point up
	else:
		# Show above unit - arrow at bottom pointing down
		arrow.position.y = 140
		arrow.rotation_degrees = 0  # Arrow points down (default)

	# Update arrow X to point at unit
	arrow.position.x = screen_pos.x - position.x

	# Update abilities display
	_update_abilities()

	# Show with animation
	visible = true
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func hide_tooltip():
	if visible:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		tween.tween_callback(func(): visible = false)
	current_unit = null

func _dismiss():
	hide_tooltip()
	dismissed.emit()

func _update_abilities():
	if not current_unit:
		return

	for i in range(ability_buttons.size()):
		var btn = ability_buttons[i]
		if btn and current_unit.unit_data.abilities.size() > i:
			var ability = current_unit.unit_data.abilities[i]
			var cd = current_unit.get_ability_cooldown(i)

			# Set button text - show full name, add cooldown if needed
			if cd > 0:
				btn.text = ability.ability_name + "\n[" + str(cd) + "]"
				btn.disabled = true
				btn.modulate = Color(0.5, 0.5, 0.5)
			else:
				btn.text = ability.ability_name
				btn.disabled = false
				if i == current_unit.selected_ability_index:
					btn.modulate = Color(1, 1, 0.6)  # Yellow highlight
				else:
					btn.modulate = Color(1, 1, 1)
			btn.visible = true

			# Style the button
			btn.add_theme_font_size_override("font_size", 11)
		elif btn:
			btn.visible = false

	# Update description
	if description_label and current_unit.unit_data.abilities.size() > current_unit.selected_ability_index:
		var ability = current_unit.unit_data.abilities[current_unit.selected_ability_index]
		description_label.text = ability.description

func _on_ability_pressed(index: int):
	if current_unit and index < current_unit.unit_data.abilities.size():
		if current_unit.get_ability_cooldown(index) == 0:
			current_unit.selected_ability_index = index
			ability_selected.emit(index)
			_update_abilities()
