extends HBoxContainer
## Reusable currency display bar showing gems, gold, materials, stones

func _ready():
	# Ensure the bar has minimum size to be visible
	custom_minimum_size = Vector2(400, 30)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_ui()
	_update_display()
	print("[CurrencyBar] Created - visible:", visible, " size:", size, " parent:", get_parent().name if get_parent() else "none")

func _process(_delta):
	if visible:
		_update_display()

func _build_ui():
	# Style self
	add_theme_constant_override("separation", 20)

	# Create currency displays
	_add_currency_display("gems")
	_add_currency_display("gold")
	_add_currency_display("materials")
	_add_currency_display("stones")

func _add_currency_display(currency_name: String):
	var container = HBoxContainer.new()
	container.name = currency_name.capitalize() + "Container"
	container.add_theme_constant_override("separation", 4)
	container.custom_minimum_size = Vector2(80, 24)

	var icon_label = Label.new()
	icon_label.name = "Icon"
	icon_label.text = _get_currency_icon(currency_name)
	icon_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	icon_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	container.add_child(icon_label)

	var value_label = Label.new()
	value_label.name = "Value"
	value_label.text = "0"
	value_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	value_label.add_theme_color_override("font_color", UITheme.GOLD)
	container.add_child(value_label)

	add_child(container)

func _get_currency_icon(currency_name: String) -> String:
	match currency_name:
		"gems":
			return "[G]"
		"gold":
			return "[C]"
		"materials":
			return "[M]"
		"stones":
			return "[S]"
		_:
			return "[?]"

func _update_display():
	var gems_container = get_node_or_null("GemsContainer/Value")
	var gold_container = get_node_or_null("GoldContainer/Value")
	var materials_container = get_node_or_null("MaterialsContainer/Value")
	var stones_container = get_node_or_null("StonesContainer/Value")

	if gems_container:
		gems_container.text = str(PlayerData.gems)
	if gold_container:
		gold_container.text = str(PlayerData.gold)
	if materials_container:
		materials_container.text = str(PlayerData.level_materials)
	if stones_container:
		stones_container.text = str(PlayerData.enhancement_stones)
