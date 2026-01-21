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

	_apply_theme()
	_load_all_stages()
	_build_chapter_ui()

func _apply_theme():
	# Background
	var bg = get_node_or_null("Background")
	if bg:
		bg.color = UITheme.BG_DARK

	# Top bar - style as panel
	var top_bar = get_node_or_null("TopBar")
	if top_bar:
		# Add a background panel to the top bar
		var top_bg = Panel.new()
		top_bg.name = "TopBarBg"
		top_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		top_bg.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))
		top_bar.add_child(top_bg)
		top_bar.move_child(top_bg, 0)

	# Title
	var title = get_node_or_null("TopBar/Title")
	if title:
		title.text = "CAMPAIGN"
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Back button
	var back_button = get_node_or_null("TopBar/BackButton")
	if back_button:
		back_button.add_theme_stylebox_override("normal", UITheme.create_button_style(Color.TRANSPARENT))
		back_button.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT))
		back_button.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.BG_DARK))
		back_button.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
		back_button.add_theme_color_override("font_hover_color", UITheme.TEXT_PRIMARY)

	# Stage info panel
	var info_panel = get_node_or_null("StageInfoPanel")
	if info_panel and info_panel is Panel:
		info_panel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))

	# Panel background
	var panel_bg = get_node_or_null("StageInfoPanel/PanelBg")
	if panel_bg:
		panel_bg.color = UITheme.BG_MEDIUM

	_style_info_panel()

func _style_info_panel():
	var info_panel = get_node_or_null("StageInfoPanel")
	if not info_panel:
		return

	# Info title
	var info_title = info_panel.get_node_or_null("VBox/InfoTitle")
	if info_title:
		info_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		info_title.add_theme_color_override("font_color", UITheme.GOLD)

	# Stage name
	var name_lbl = info_panel.get_node_or_null("VBox/StageNameLabel")
	if name_lbl:
		name_lbl.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		name_lbl.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Difficulty stars
	var diff_lbl = info_panel.get_node_or_null("VBox/DifficultyLabel")
	if diff_lbl:
		diff_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		diff_lbl.add_theme_color_override("font_color", UITheme.GOLD)

	# Rewards
	var reward_lbl = info_panel.get_node_or_null("VBox/RewardsLabel")
	if reward_lbl:
		reward_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		reward_lbl.add_theme_color_override("font_color", UITheme.PRIMARY)

	# Story title
	var story_title = info_panel.get_node_or_null("VBox/StoryTitle")
	if story_title:
		story_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		story_title.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Story label
	var story_lbl = info_panel.get_node_or_null("VBox/StoryLabel")
	if story_lbl:
		story_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		story_lbl.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Start button
	var start_btn = info_panel.get_node_or_null("VBox/StartStageButton")
	if start_btn:
		start_btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
		start_btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.PRIMARY.lightened(0.1)))
		start_btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.PRIMARY.darkened(0.1)))
		start_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		start_btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

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

	# Chapter header with gold styling
	var header = Panel.new()
	header.custom_minimum_size = Vector2(0, 60)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = UITheme.BG_MEDIUM
	header_style.corner_radius_top_left = UITheme.CARD_RADIUS
	header_style.corner_radius_top_right = UITheme.CARD_RADIUS
	header_style.border_color = UITheme.GOLD
	header_style.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", header_style)

	var header_label = Label.new()
	header_label.text = "CHAPTER " + str(chapter_num)
	header_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
	header_label.add_theme_color_override("font_color", UITheme.GOLD)
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(header_label)

	chapter_box.add_child(header)

	# Horizontal stage progression container
	var stages_hbox = HBoxContainer.new()
	stages_hbox.add_theme_constant_override("separation", UITheme.SPACING_MD)
	stages_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	for stage in stages:
		var stage_card = _create_stage_card(stage)
		stages_hbox.add_child(stage_card)

	# Wrap stage cards in a panel
	var stages_panel = Panel.new()
	stages_panel.custom_minimum_size = Vector2(0, 200)
	var stages_style = StyleBoxFlat.new()
	stages_style.bg_color = UITheme.BG_DARK
	stages_style.corner_radius_bottom_left = UITheme.CARD_RADIUS
	stages_style.corner_radius_bottom_right = UITheme.CARD_RADIUS
	stages_style.border_color = UITheme.BG_LIGHT
	stages_style.border_width_left = 2
	stages_style.border_width_right = 2
	stages_style.border_width_bottom = 2
	stages_panel.add_theme_stylebox_override("panel", stages_style)

	var stages_margin = MarginContainer.new()
	stages_margin.add_theme_constant_override("margin_left", UITheme.SPACING_LG)
	stages_margin.add_theme_constant_override("margin_right", UITheme.SPACING_LG)
	stages_margin.add_theme_constant_override("margin_top", UITheme.SPACING_LG)
	stages_margin.add_theme_constant_override("margin_bottom", UITheme.SPACING_LG)
	stages_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	stages_margin.add_child(stages_hbox)
	stages_panel.add_child(stages_margin)

	chapter_box.add_child(stages_panel)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, UITheme.SPACING_LG)
	chapter_box.add_child(spacer)

	return chapter_box

func _create_stage_card(stage) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(140, 160)

	var is_locked = not PlayerData.is_stage_unlocked(stage.stage_id)
	var is_cleared = PlayerData.is_stage_cleared(stage.stage_id)

	# Set colors based on state
	var bg_color = UITheme.BG_DARK if is_locked else UITheme.BG_MEDIUM
	var border_color = UITheme.TEXT_DISABLED if is_locked else (UITheme.SUCCESS if is_cleared else UITheme.BG_LIGHT)

	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = UITheme.CARD_RADIUS
	style.corner_radius_top_right = UITheme.CARD_RADIUS
	style.corner_radius_bottom_left = UITheme.CARD_RADIUS
	style.corner_radius_bottom_right = UITheme.CARD_RADIUS
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", UITheme.SPACING_SM)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Add margin container for padding
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", UITheme.SPACING_SM)
	margin.add_theme_constant_override("margin_right", UITheme.SPACING_SM)
	margin.add_theme_constant_override("margin_top", UITheme.SPACING_SM)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACING_SM)

	# Stage ID label
	var id_label = Label.new()
	id_label.text = stage.get_stage_display()
	id_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
	id_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY if not is_locked else UITheme.TEXT_DISABLED)
	id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(id_label)

	# Stage name
	var name_label = Label.new()
	name_label.text = stage.stage_name
	name_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	name_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY if not is_locked else UITheme.TEXT_DISABLED)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	# Difficulty stars
	var diff_label = Label.new()
	diff_label.text = stage.get_difficulty_stars()
	diff_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	diff_label.add_theme_color_override("font_color", UITheme.GOLD if not is_locked else UITheme.TEXT_DISABLED)
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(diff_label)

	# Status indicator (stars or lock)
	var status_label = Label.new()
	if is_locked:
		status_label.text = "LOCKED"
		status_label.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)
	elif is_cleared:
		var stars = PlayerData.get_stage_stars(stage.stage_id)
		status_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
		status_label.add_theme_color_override("font_color", UITheme.GOLD)
	else:
		status_label.text = "NEW"
		status_label.add_theme_color_override("font_color", UITheme.PRIMARY)
	status_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)

	margin.add_child(vbox)
	card.add_child(margin)

	# Make clickable (only if not locked)
	if not is_locked:
		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.modulate = Color(1, 1, 1, 0)
		btn.pressed.connect(_on_stage_selected.bind(stage))
		card.add_child(btn)

	return card

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
