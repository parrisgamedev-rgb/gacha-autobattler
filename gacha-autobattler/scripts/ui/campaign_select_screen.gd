extends Control
## Campaign stage selection screen

@onready var back_btn = $TopBar/BackButton
@onready var chapter_container = $ScrollContainer/ChapterContainer
@onready var stage_info_panel = $StageInfoPanel
@onready var stage_name_label = $StageInfoPanel/VBox/StageNameLabel
@onready var stage_difficulty_label = $StageInfoPanel/VBox/DifficultyLabel
@onready var stage_rewards_label = $StageInfoPanel/VBox/RewardsLabel
@onready var stage_story_label = $StageInfoPanel/VBox/StoryLabel
@onready var start_stage_btn = $StageInfoPanel/VBox/StartStageButton

# All loaded stages organized by chapter
var stages_by_chapter: Dictionary = {}  # {chapter_num: [stage resources]}
var selected_stage = null

func _ready():
	back_btn.pressed.connect(_on_back)
	start_stage_btn.pressed.connect(_on_start_stage)

	# Hide info panel initially
	stage_info_panel.visible = false

	_load_all_stages()
	_build_chapter_ui()

func _load_all_stages():
	# Load all stage resources from chapter folders
	var chapter_path = "res://resources/stages/chapter_1/"
	var stage_files = [
		"stage_1_1.tres",
		"stage_1_2.tres",
		"stage_1_3.tres",
		"stage_1_4.tres",
		"stage_1_5.tres"
	]

	for file_name in stage_files:
		var full_path = chapter_path + file_name
		if ResourceLoader.exists(full_path):
			var stage = load(full_path)
			if stage:
				var chapter = stage.chapter
				if not stages_by_chapter.has(chapter):
					stages_by_chapter[chapter] = []
				stages_by_chapter[chapter].append(stage)

	# Sort stages within each chapter
	for chapter in stages_by_chapter:
		stages_by_chapter[chapter].sort_custom(func(a, b): return a.stage_number < b.stage_number)

	print("Loaded ", stages_by_chapter.size(), " chapter(s)")

func _build_chapter_ui():
	# Clear existing
	for child in chapter_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	# Build UI for each chapter
	var chapters = stages_by_chapter.keys()
	chapters.sort()

	for chapter_num in chapters:
		var chapter_panel = _create_chapter_panel(chapter_num)
		chapter_container.add_child(chapter_panel)

func _create_chapter_panel(chapter_num: int) -> Control:
	var stages = stages_by_chapter[chapter_num]

	# Main chapter container
	var chapter_box = VBoxContainer.new()
	chapter_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Chapter header
	var header = Panel.new()
	header.custom_minimum_size = Vector2(0, 60)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.15, 0.15, 0.25, 1)
	header_style.corner_radius_top_left = 8
	header_style.corner_radius_top_right = 8
	header.add_theme_stylebox_override("panel", header_style)

	var header_label = Label.new()
	header_label.text = "CHAPTER " + str(chapter_num)
	header_label.add_theme_font_size_override("font_size", 28)
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(header_label)

	chapter_box.add_child(header)

	# Stages grid
	var stages_grid = GridContainer.new()
	stages_grid.columns = 5
	stages_grid.add_theme_constant_override("h_separation", 15)
	stages_grid.add_theme_constant_override("v_separation", 15)

	for stage in stages:
		var stage_btn = _create_stage_button(stage)
		stages_grid.add_child(stage_btn)

	# Wrap grid in a panel
	var stages_panel = Panel.new()
	stages_panel.custom_minimum_size = Vector2(0, 180)
	var stages_style = StyleBoxFlat.new()
	stages_style.bg_color = Color(0.1, 0.1, 0.15, 1)
	stages_style.corner_radius_bottom_left = 8
	stages_style.corner_radius_bottom_right = 8
	stages_panel.add_theme_stylebox_override("panel", stages_style)

	var stages_margin = MarginContainer.new()
	stages_margin.add_theme_constant_override("margin_left", 20)
	stages_margin.add_theme_constant_override("margin_right", 20)
	stages_margin.add_theme_constant_override("margin_top", 20)
	stages_margin.add_theme_constant_override("margin_bottom", 20)
	stages_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	stages_margin.add_child(stages_grid)
	stages_panel.add_child(stages_margin)

	chapter_box.add_child(stages_panel)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	chapter_box.add_child(spacer)

	return chapter_box

func _create_stage_button(stage) -> Control:
	var is_unlocked = PlayerData.is_stage_unlocked(stage.stage_id)
	var is_cleared = PlayerData.is_stage_cleared(stage.stage_id)
	var stars = PlayerData.get_stage_stars(stage.stage_id)

	var btn_container = VBoxContainer.new()
	btn_container.custom_minimum_size = Vector2(140, 130)

	# Stage button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(140, 80)
	btn.disabled = not is_unlocked

	# Button text
	var btn_text = stage.get_stage_display() + "\n" + stage.stage_name
	btn.text = btn_text

	# Style based on state
	if not is_unlocked:
		btn.modulate = Color(0.5, 0.5, 0.5, 1)
	elif is_cleared:
		btn.modulate = Color(0.7, 1.0, 0.7, 1)

	btn.pressed.connect(_on_stage_selected.bind(stage))
	btn_container.add_child(btn)

	# Difficulty stars
	var diff_label = Label.new()
	diff_label.text = stage.get_difficulty_stars()
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	diff_label.add_theme_font_size_override("font_size", 14)
	btn_container.add_child(diff_label)

	# Clear status / stars earned
	var status_label = Label.new()
	if is_cleared:
		status_label.text = "CLEARED " + "★".repeat(stars)
		status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	elif is_unlocked:
		status_label.text = "NEW"
		status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5))
	else:
		status_label.text = "LOCKED"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	btn_container.add_child(status_label)

	return btn_container

func _on_stage_selected(stage):
	selected_stage = stage
	_update_stage_info_panel()

func _update_stage_info_panel():
	if selected_stage == null:
		stage_info_panel.visible = false
		return

	stage_info_panel.visible = true

	var is_first_clear = not PlayerData.is_stage_cleared(selected_stage.stage_id)

	stage_name_label.text = selected_stage.get_stage_display() + " - " + selected_stage.stage_name
	stage_difficulty_label.text = "Difficulty: " + selected_stage.get_difficulty_stars()

	# Rewards text
	var rewards_text = "Rewards: "
	if is_first_clear:
		rewards_text += str(selected_stage.gem_reward) + " Gems"
		if selected_stage.first_clear_unit != null:
			rewards_text += " + " + selected_stage.first_clear_unit.unit_name + " (Unit)"
	else:
		rewards_text += "Already Cleared"
	stage_rewards_label.text = rewards_text

	# Story intro
	stage_story_label.text = selected_stage.story_intro

	# Button text
	if is_first_clear:
		start_stage_btn.text = "START STAGE"
	else:
		start_stage_btn.text = "REPLAY STAGE"

func _on_start_stage():
	if selected_stage == null:
		return

	# Set the current stage in PlayerData
	PlayerData.start_campaign_stage(selected_stage)

	# Go to team select screen
	get_tree().change_scene_to_file("res://scenes/ui/team_select_screen.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
