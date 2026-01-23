extends Control
## Achievement gallery screen showing all achievements and progress

@onready var back_btn = $TopBar/HBox/BackButton
@onready var title_label = $TopBar/HBox/Title
@onready var filter_all_btn = $FilterBar/AllButton
@onready var filter_battle_btn = $FilterBar/BattleButton
@onready var filter_collection_btn = $FilterBar/CollectionButton
@onready var filter_progression_btn = $FilterBar/ProgressionButton
@onready var achievement_grid = $ScrollContainer/AchievementGrid
@onready var progress_label = $TopBar/HBox/ProgressLabel

var current_filter: int = -1  # -1 = all, 0 = battle, 1 = collection, 2 = progression


func _ready():
	back_btn.pressed.connect(_on_back)
	filter_all_btn.pressed.connect(_set_filter.bind(-1))
	filter_battle_btn.pressed.connect(_set_filter.bind(0))
	filter_collection_btn.pressed.connect(_set_filter.bind(1))
	filter_progression_btn.pressed.connect(_set_filter.bind(2))

	_apply_theme()
	_update_progress_display()
	_build_achievement_grid()


func _set_filter(filter_type: int):
	AudioManager.play_ui_click()
	current_filter = filter_type
	_build_achievement_grid()
	_update_filter_tab_styles()


func _build_achievement_grid():
	# Clear existing
	for child in achievement_grid.get_children():
		child.queue_free()

	await get_tree().process_frame

	# Get achievements
	var all_achievements = AchievementManager.get_all_achievements()

	# Filter if needed
	var filtered: Array[AchievementData] = []
	for achievement in all_achievements:
		if current_filter == -1:
			filtered.append(achievement)
		elif achievement.category == current_filter:
			filtered.append(achievement)

	# Sort: unlocked first, then by category
	filtered.sort_custom(func(a, b):
		var a_unlocked = AchievementManager.is_unlocked(a.id)
		var b_unlocked = AchievementManager.is_unlocked(b.id)
		if a_unlocked != b_unlocked:
			return a_unlocked  # Unlocked comes first
		return a.category < b.category
	)

	# Build cards
	for achievement in filtered:
		var card = _create_achievement_card(achievement)
		achievement_grid.add_child(card)


func _create_achievement_card(achievement: AchievementData) -> Control:
	var is_unlocked = AchievementManager.is_unlocked(achievement.id)
	var stats = AchievementManager.get_stats()

	var card = Panel.new()
	card.custom_minimum_size = Vector2(280, 120)

	# Apply panel style based on unlock status
	if is_unlocked:
		UISpriteLoader.apply_panel_style(card, UISpriteLoader.PanelColor.GOLD, "Panel")
	else:
		UISpriteLoader.apply_panel_style(card, UISpriteLoader.PanelColor.WHITE, "Panel")
		card.modulate = Color(0.6, 0.6, 0.65, 1.0)  # Darken locked cards

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", UITheme.SPACING_SM)
	margin.add_theme_constant_override("margin_right", UITheme.SPACING_SM)
	margin.add_theme_constant_override("margin_top", UITheme.SPACING_SM)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACING_SM)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SPACING_XS)
	margin.add_child(vbox)

	# Category tag
	var category_label = Label.new()
	category_label.text = achievement.get_category_name().to_upper()
	category_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
	category_label.add_theme_color_override("font_color", _get_category_color(achievement.category))
	vbox.add_child(category_label)

	# Achievement name
	var name_label = Label.new()
	name_label.text = achievement.achievement_name
	name_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", UITheme.GOLD)
	else:
		name_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 1)
	vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = achievement.description
	desc_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	desc_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Bottom row: reward or progress
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", UITheme.SPACING_SM)
	vbox.add_child(bottom_hbox)

	if is_unlocked:
		# Show completed status with reward
		var reward_label = Label.new()
		reward_label.text = "+" + str(achievement.gem_reward) + " Gems"
		reward_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		reward_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		bottom_hbox.add_child(reward_label)

		# Spacer
		var bottom_spacer = Control.new()
		bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom_hbox.add_child(bottom_spacer)

		# Checkmark
		var check_label = Label.new()
		check_label.text = "COMPLETE"
		check_label.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
		check_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		bottom_hbox.add_child(check_label)
	else:
		# Show progress
		var progress_text = achievement.get_progress_text(stats)
		var progress_label = Label.new()
		progress_label.text = progress_text
		progress_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		progress_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
		bottom_hbox.add_child(progress_label)

		# Spacer
		var bottom_spacer = Control.new()
		bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom_hbox.add_child(bottom_spacer)

		# Reward preview
		var reward_preview = Label.new()
		reward_preview.text = str(achievement.gem_reward) + " Gems"
		reward_preview.add_theme_font_size_override("font_size", UITheme.FONT_SMALL)
		reward_preview.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)
		bottom_hbox.add_child(reward_preview)

	return card


func _get_category_color(category: AchievementData.Category) -> Color:
	match category:
		AchievementData.Category.BATTLE:
			return Color(0.9, 0.4, 0.4)  # Red
		AchievementData.Category.COLLECTION:
			return Color(0.4, 0.7, 0.9)  # Blue
		AchievementData.Category.PROGRESSION:
			return Color(0.4, 0.9, 0.5)  # Green
	return UITheme.TEXT_SECONDARY


func _update_progress_display():
	var all_achievements = AchievementManager.get_all_achievements()
	var unlocked_count = 0
	for achievement in all_achievements:
		if AchievementManager.is_unlocked(achievement.id):
			unlocked_count += 1

	progress_label.text = str(unlocked_count) + "/" + str(all_achievements.size())
	progress_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	progress_label.add_theme_color_override("font_color", UITheme.GOLD)


func _on_back():
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")


func _apply_theme():
	# Background
	UISpriteLoader.apply_background_to_scene(self, UISpriteLoader.BackgroundTheme.CASTLE, UISpriteLoader.BackgroundVariant.PALE, 0.4)

	# Top bar
	var top_bar = get_node_or_null("TopBar")
	if top_bar and top_bar is Panel:
		top_bar.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))

	# Title
	if title_label:
		title_label.text = "ACHIEVEMENTS"
		title_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Back button
	if back_btn:
		UISpriteLoader.apply_button_style(back_btn, UISpriteLoader.ButtonColor.PURPLE, "ButtonA")
		back_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Style filter tabs
	_style_filter_tabs()
	_update_filter_tab_styles()


func _style_filter_tabs():
	var tabs = [filter_all_btn, filter_battle_btn, filter_collection_btn, filter_progression_btn]
	var tab_labels = ["ALL", "BATTLE", "COLLECTION", "PROGRESSION"]

	for i in range(tabs.size()):
		var tab = tabs[i]
		if tab:
			tab.text = tab_labels[i]
			tab.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)


func _update_filter_tab_styles():
	var tabs = [filter_all_btn, filter_battle_btn, filter_collection_btn, filter_progression_btn]
	var filter_values = [-1, 0, 1, 2]

	for i in range(tabs.size()):
		var tab = tabs[i]
		if tab:
			if current_filter == filter_values[i]:
				UISpriteLoader.apply_button_style(tab, UISpriteLoader.ButtonColor.GOLD, "ButtonA")
			else:
				UISpriteLoader.apply_button_style(tab, UISpriteLoader.ButtonColor.WHITE, "ButtonA")
