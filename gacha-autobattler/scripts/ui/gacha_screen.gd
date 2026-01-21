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
	_apply_theme()
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

		# Color the display based on rarity using UITheme colors
		var rarity_color = UITheme.get_rarity_color(unit_data.star_rating)
		display.modulate = rarity_color.lightened(0.3)

func _on_continue():
	results_panel.visible = false
	single_pull_btn.visible = true
	multi_pull_btn.visible = true
	_update_ui()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# === THEME FUNCTIONS ===

func _apply_theme():
	# Background
	var bg = get_node_or_null("Background")
	if bg:
		bg.color = UITheme.BG_DARK

	# Top bar panel styling
	var top_bar = get_node_or_null("TopBar")
	if top_bar:
		# The TopBar is HBoxContainer, we need to add a Panel parent or style it via script
		pass

	# Title (add a title label to TopBar if needed)
	var title = get_node_or_null("TopBar/Title")
	if title:
		title.text = "SUMMON"
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Back button - transparent with muted text
	_style_back_button(back_btn)

	# Pity label
	if pity_label:
		pity_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		pity_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Gem icon
	var gem_icon = get_node_or_null("TopBar/GemIcon")
	if gem_icon:
		gem_icon.color = UITheme.PRIMARY

	# Gems label
	if gems_label:
		gems_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		gems_label.add_theme_color_override("font_color", UITheme.PRIMARY)

	# Banner styling
	_style_banner()

	# Summon buttons - styled as primary buttons
	_style_primary_button(single_pull_btn)
	_style_primary_button(multi_pull_btn)

	# Results panel with gold border for gacha excitement
	_style_results_panel()

func _style_back_button(btn: Button):
	if not btn:
		return
	btn.add_theme_stylebox_override("normal", UITheme.create_button_style(Color.TRANSPARENT))
	btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT))
	btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.BG_DARK))
	btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	btn.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	btn.add_theme_color_override("font_hover_color", UITheme.TEXT_PRIMARY)

func _style_primary_button(btn: Button):
	if not btn:
		return
	btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
	btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.PRIMARY.lightened(0.15)))
	btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.PRIMARY.darkened(0.15)))
	btn.add_theme_stylebox_override("disabled", UITheme.create_button_style(UITheme.BG_DARK))
	btn.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
	btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	btn.add_theme_color_override("font_disabled_color", UITheme.TEXT_DISABLED)

func _style_banner():
	var banner = get_node_or_null("BannerImage")
	if banner:
		banner.color = UITheme.BG_MEDIUM

	var banner_title = get_node_or_null("BannerImage/BannerTitle")
	if banner_title:
		banner_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE + 10)
		banner_title.add_theme_color_override("font_color", UITheme.GOLD)

	var banner_subtitle = get_node_or_null("BannerImage/BannerSubtitle")
	if banner_subtitle:
		banner_subtitle.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		banner_subtitle.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	var rates_label = get_node_or_null("BannerImage/RatesLabel")
	if rates_label:
		rates_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		rates_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

func _style_results_panel():
	if results_panel:
		results_panel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM, UITheme.GOLD, UITheme.MODAL_RADIUS))

	var results_bg = get_node_or_null("ResultsPanel/ResultsBackground")
	if results_bg:
		results_bg.color = UITheme.BG_MEDIUM

	var results_title = get_node_or_null("ResultsPanel/ResultsTitle")
	if results_title:
		results_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		results_title.add_theme_color_override("font_color", UITheme.GOLD)

	# Continue button - gold themed for excitement
	if continue_btn:
		continue_btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.GOLD))
		continue_btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.GOLD.lightened(0.15)))
		continue_btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.GOLD.darkened(0.15)))
		continue_btn.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		continue_btn.add_theme_color_override("font_color", UITheme.BG_DARK)
