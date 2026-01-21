extends Control
## Gacha/Summon screen for pulling new units

@onready var gems_label = $TopBar/GemsLabel
@onready var pity_label = $TopBar/PityLabel
@onready var single_pull_btn = $PullButtons/SinglePullButton
@onready var multi_pull_btn = $PullButtons/MultiPullButton
@onready var back_btn = $TopBar/BackButton
@onready var results_container = $ResultsPanel/ResultsContainer
@onready var results_panel = $ResultsPanel
@onready var continue_btn = $ResultsPanel/ContinueButton

var UnitDisplayScene = preload("res://scenes/battle/unit_display.tscn")

func _ready():
	_update_ui()

	single_pull_btn.pressed.connect(_on_single_pull)
	multi_pull_btn.pressed.connect(_on_multi_pull)
	back_btn.pressed.connect(_on_back)
	continue_btn.pressed.connect(_on_continue)

	results_panel.visible = false

func _update_ui():
	gems_label.text = str(PlayerData.gems) + " Gems"
	pity_label.text = "Pity: " + str(PlayerData.pity_counter) + "/" + str(PlayerData.HARD_PITY)

	single_pull_btn.disabled = not PlayerData.can_afford_single()
	multi_pull_btn.disabled = not PlayerData.can_afford_multi()

	# Update button text with costs
	single_pull_btn.text = "Single Pull\n" + str(PlayerData.SINGLE_PULL_COST) + " Gems"
	multi_pull_btn.text = "10x Pull\n" + str(PlayerData.MULTI_PULL_COST) + " Gems"

func _on_single_pull():
	var unit_entry = PlayerData.do_single_pull()
	if not unit_entry.is_empty():
		_show_results([unit_entry])
	_update_ui()

func _on_multi_pull():
	var unit_entries = PlayerData.do_multi_pull()
	if unit_entries.size() > 0:
		_show_results(unit_entries)
	_update_ui()

func _show_results(unit_entries: Array):
	# Clear previous results
	for child in results_container.get_children():
		child.queue_free()

	# Show results panel
	results_panel.visible = true

	# Hide pull buttons while showing results
	single_pull_btn.visible = false
	multi_pull_btn.visible = false

	# Create displays for pulled units
	await get_tree().process_frame

	# Calculate spacing for units
	var unit_count = unit_entries.size()
	var unit_width = 120  # Approximate width per unit at scale 0.6
	var total_width = results_container.size.x
	var start_x = (total_width - (unit_count * unit_width)) / 2 + unit_width / 2
	var y_pos = results_container.size.y / 2

	for i in range(unit_entries.size()):
		var unit_entry = unit_entries[i]
		var unit_data = unit_entry.unit_data as UnitData
		var display = UnitDisplayScene.instantiate()
		results_container.add_child(display)

		# Position manually since UnitDisplay is Node2D
		display.position = Vector2(start_x + i * unit_width, y_pos)

		# Create a temporary UnitInstance for the display
		var instance = UnitInstance.new(unit_data, 1)
		display.setup(instance)
		display.scale = Vector2(0.6, 0.6)
		display.drag_enabled = false

		# Color the display based on rarity
		match unit_data.star_rating:
			5:
				display.modulate = Color(1.0, 0.9, 0.5)  # Gold tint
			4:
				display.modulate = Color(0.8, 0.5, 1.0)  # Purple tint
			_:
				display.modulate = Color(1.0, 1.0, 1.0)  # Normal

func _on_continue():
	results_panel.visible = false
	single_pull_btn.visible = true
	multi_pull_btn.visible = true
	_update_ui()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
