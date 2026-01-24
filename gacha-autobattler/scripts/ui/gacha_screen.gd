extends Control
## Gacha/Summon screen for pulling new units with cinematic animations

var CurrencyBarScene = preload("res://scenes/ui/currency_bar.tscn")

@onready var gems_label = $TopBar/GemsLabel
@onready var pity_label = $TopBar/PityLabel
@onready var single_pull_btn = $PullButtons/SinglePullButton
@onready var multi_pull_btn = $PullButtons/MultiPullButton
@onready var back_btn = $TopBar/BackButton
@onready var results_container = $ResultsPanel/ResultsContainer
@onready var results_panel = $ResultsPanel
@onready var continue_btn = $ResultsPanel/ContinueButton

# Animation nodes
@onready var summon_overlay = $SummonOverlay
@onready var summon_circle = $SummonOverlay/SummonCircle
@onready var inner_circle = $SummonOverlay/SummonCircle/InnerCircle
@onready var reveal_position = $SummonOverlay/RevealPosition
@onready var revealed_units_container = $SummonOverlay/RevealedUnitsContainer
@onready var flash_overlay = $SummonOverlay/FlashOverlay
@onready var skip_btn = $SkipButton

var UnitDisplayScene = preload("res://scenes/battle/unit_display.tscn")

# Animation state
var is_animating: bool = false
var skip_requested: bool = false
var pending_results: Array = []
var revealed_displays: Array = []  # Track revealed unit displays during animation

func _ready():
	# Add currency bar to top bar
	var currency_bar = CurrencyBarScene.instantiate()
	var top_bar = get_node_or_null("TopBar")
	if top_bar:
		top_bar.add_child(currency_bar)

	_apply_theme()
	_update_ui()

	single_pull_btn.pressed.connect(_on_single_pull)
	multi_pull_btn.pressed.connect(_on_multi_pull)
	back_btn.pressed.connect(_on_back)
	continue_btn.pressed.connect(_on_continue)
	skip_btn.pressed.connect(_on_skip_pressed)

	# Allow clicking anywhere on overlay to skip
	summon_overlay.gui_input.connect(_on_overlay_input)

	results_panel.visible = false
	summon_overlay.visible = false
	skip_btn.visible = false

func _unhandled_input(event: InputEvent):
	# Cheat: F1 adds 10000 gems
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		PlayerData.add_gems(10000)
		_update_ui()
		print("[CHEAT] Added 10000 gems from gacha screen")

func _update_ui():
	gems_label.text = str(PlayerData.gems) + " Gems"
	pity_label.text = "Pity: " + str(PlayerData.pity_counter) + "/" + str(PlayerData.HARD_PITY)

	single_pull_btn.disabled = not PlayerData.can_afford_single()
	multi_pull_btn.disabled = not PlayerData.can_afford_multi()

	# Update button text with costs
	single_pull_btn.text = "Single Pull\n" + str(PlayerData.SINGLE_PULL_COST) + " Gems"
	multi_pull_btn.text = "10x Pull\n" + str(PlayerData.MULTI_PULL_COST) + " Gems"

func _on_single_pull():
	AudioManager.play_ui_click()
	var unit_entry = PlayerData.do_single_pull()
	if not unit_entry.is_empty():
		_play_summon_animation([unit_entry])
	_update_ui()

func _on_multi_pull():
	AudioManager.play_ui_click()
	var unit_entries = PlayerData.do_multi_pull()
	if unit_entries.size() > 0:
		_play_summon_animation(unit_entries)
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
	AudioManager.play_ui_click()
	results_panel.visible = false
	single_pull_btn.visible = true
	multi_pull_btn.visible = true
	_update_ui()

func _on_back():
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")

# === SUMMON ANIMATION SYSTEM ===

func _on_skip_pressed():
	skip_requested = true

func _on_overlay_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and is_animating:
		skip_requested = true

func _play_summon_animation(unit_entries: Array):
	is_animating = true
	skip_requested = false
	pending_results = unit_entries
	revealed_displays.clear()

	# Clear any previous revealed units from overlay
	for child in revealed_units_container.get_children():
		child.queue_free()

	# Hide pull buttons
	single_pull_btn.visible = false
	multi_pull_btn.visible = false

	# Show overlay and skip button
	summon_overlay.visible = true
	summon_overlay.modulate.a = 0
	skip_btn.visible = true

	# Reset summon circle
	summon_circle.scale = Vector2(0.5, 0.5)
	summon_circle.modulate.a = 0
	_set_circle_color(UITheme.RARITY_3_STAR)

	# Transition in (0.3s) - not skippable
	var tween = create_tween()
	tween.tween_property(summon_overlay, "modulate:a", 1.0, 0.3)
	await tween.finished

	# Reveal each unit
	for i in range(unit_entries.size()):
		if skip_requested:
			break
		await _reveal_unit(unit_entries[i], i, unit_entries.size())

	# Show final results
	_show_final_results()
	is_animating = false

func _reveal_unit(unit_entry: Dictionary, index: int, total_count: int):
	var unit_data = unit_entry.unit_data as UnitData
	var rarity = unit_data.star_rating

	# Buildup - circle appears and pulses
	await _animate_circle_buildup(rarity)
	if skip_requested:
		return

	# Rarity flash
	await _animate_rarity_flash(rarity)
	if skip_requested:
		return

	# 5-star special pause
	if rarity == 5:
		await _animate_five_star_special()
		if skip_requested:
			return

	# Unit reveal
	await _animate_unit_reveal(unit_entry, index, total_count)

func _animate_circle_buildup(rarity: int):
	# Play buildup sound
	AudioManager.play_summon_buildup()

	# Set circle color based on rarity
	var rarity_color = _get_rarity_circle_color(rarity)
	_set_circle_color(rarity_color)

	# Animate circle appearing and pulsing
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(summon_circle, "modulate:a", 1.0, 0.2)
	tween.tween_property(summon_circle, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Pulse effect
	tween.chain().tween_property(summon_circle, "scale", Vector2(1.1, 1.1), 0.15)
	tween.tween_property(summon_circle, "scale", Vector2(1.0, 1.0), 0.15)

	await _wait_or_skip(0.5)

func _animate_rarity_flash(rarity: int):
	var rarity_color = _get_rarity_circle_color(rarity)

	# Brief bright flash of the circle
	var tween = create_tween()
	tween.tween_property(summon_circle, "modulate", Color(2, 2, 2, 1), 0.1)
	tween.tween_property(summon_circle, "modulate", Color(1, 1, 1, 1), 0.1)

	await _wait_or_skip(0.2)

func _animate_five_star_special():
	# Screen flash for 5-star
	flash_overlay.visible = true
	flash_overlay.color = Color(1, 0.9, 0.5, 0)  # Golden tint

	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.6, 0.15)
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.35)

	# Extra circle pulse
	var circle_tween = create_tween()
	circle_tween.tween_property(summon_circle, "scale", Vector2(1.3, 1.3), 0.2)
	circle_tween.tween_property(summon_circle, "scale", Vector2(1.0, 1.0), 0.3)

	await _wait_or_skip(0.5)
	flash_overlay.visible = false

func _animate_unit_reveal(unit_entry: Dictionary, index: int, total_count: int):
	var unit_data = unit_entry.unit_data as UnitData

	# Calculate final position in the revealed units row (bottom of overlay)
	var unit_width = 120
	var container_width = revealed_units_container.size.x
	var start_x = (container_width - (total_count * unit_width)) / 2 + unit_width / 2
	var final_pos = Vector2(start_x + index * unit_width, revealed_units_container.size.y / 2)

	# Create the unit display on the VISIBLE overlay container
	var display = UnitDisplayScene.instantiate()
	revealed_units_container.add_child(display)

	# Start at center of overlay (where the circle is), convert to container local coords
	var overlay_center = summon_overlay.size / 2
	var container_global_pos = revealed_units_container.global_position
	var overlay_global_center = summon_overlay.global_position + overlay_center
	var local_center = overlay_global_center - container_global_pos
	display.position = local_center
	display.scale = Vector2.ZERO

	# Setup the display
	var instance = UnitInstance.new(unit_data, 1)
	display.setup(instance)
	display.drag_enabled = false

	# Color based on rarity
	var rarity_color = UITheme.get_rarity_color(unit_data.star_rating)
	display.modulate = rarity_color.lightened(0.3)

	# Track this display
	revealed_displays.append(display)

	# Play reveal sound based on rarity
	AudioManager.play_summon_reveal(unit_data.star_rating)

	# Animate: scale up at center
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(display, "scale", Vector2(0.8, 0.8), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await _wait_or_skip(0.15)
	if skip_requested:
		# Snap to final position
		display.position = final_pos
		display.scale = Vector2(0.6, 0.6)
		return

	# Animate: move to final position in the row
	var move_tween = create_tween()
	move_tween.set_parallel(true)
	move_tween.tween_property(display, "position", final_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	move_tween.tween_property(display, "scale", Vector2(0.6, 0.6), 0.3)

	# Fade out circle for next unit
	var circle_tween = create_tween()
	circle_tween.tween_property(summon_circle, "modulate:a", 0.0, 0.2)
	circle_tween.tween_property(summon_circle, "scale", Vector2(0.5, 0.5), 0.1)

	await _wait_or_skip(0.3)

func _show_final_results():
	# Hide animation elements but keep overlay visible momentarily
	skip_btn.visible = false
	summon_circle.visible = false

	# Clear revealed units from overlay (they'll be recreated in results panel)
	for child in revealed_units_container.get_children():
		child.queue_free()
	revealed_displays.clear()

	# Clear any old results
	for child in results_container.get_children():
		child.queue_free()

	# Wait a frame for cleanup
	await get_tree().process_frame

	# Create all units in results panel
	var unit_count = pending_results.size()
	var unit_width = 120
	var total_width = results_container.size.x
	var start_x = (total_width - (unit_count * unit_width)) / 2 + unit_width / 2
	var y_pos = results_container.size.y / 2

	for i in range(pending_results.size()):
		var unit_entry = pending_results[i]
		var unit_data = unit_entry.unit_data as UnitData
		var display = UnitDisplayScene.instantiate()
		results_container.add_child(display)
		display.position = Vector2(start_x + i * unit_width, y_pos)
		var instance = UnitInstance.new(unit_data, 1)
		display.setup(instance)
		display.scale = Vector2(0.6, 0.6)
		display.drag_enabled = false
		var rarity_color = UITheme.get_rarity_color(unit_data.star_rating)
		display.modulate = rarity_color.lightened(0.3)

	# Hide overlay, show results panel
	summon_overlay.visible = false
	summon_circle.visible = true  # Reset for next time
	results_panel.visible = true

func _wait_or_skip(duration: float):
	var elapsed = 0.0
	while elapsed < duration and not skip_requested:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

func _get_rarity_circle_color(rarity: int) -> Color:
	match rarity:
		5:
			return UITheme.RARITY_5_STAR  # Gold
		4:
			return UITheme.RARITY_4_STAR  # Purple
		_:
			return UITheme.RARITY_3_STAR  # Gray/white

func _set_circle_color(color: Color):
	summon_circle.color = color.lightened(0.2)
	summon_circle.color.a = 0.8
	inner_circle.color = UITheme.BG_MEDIUM
	inner_circle.color.a = 0.9

# === THEME FUNCTIONS ===

func _apply_theme():
	# Background - use graveyard theme for mysterious summon vibes
	UISpriteLoader.apply_background_to_scene(self, UISpriteLoader.BackgroundTheme.GRAVEYARD, UISpriteLoader.BackgroundVariant.BRIGHT, 0.4)
	# Hide the old solid color background if it exists
	var bg = get_node_or_null("Background")
	if bg:
		bg.visible = false

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

	# Skip button
	_style_skip_button()

func _style_back_button(btn: Button):
	if not btn:
		return
	# Use sprite-based button (purple secondary)
	UISpriteLoader.apply_button_style(btn, UISpriteLoader.ButtonColor.PURPLE, "ButtonA")
	btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

func _style_primary_button(btn: Button):
	if not btn:
		return
	# Use sprite-based button (blue primary)
	UISpriteLoader.apply_button_style(btn, UISpriteLoader.ButtonColor.BLUE, "ButtonA")
	btn.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
	btn.add_theme_color_override("font_disabled_color", UITheme.TEXT_DISABLED)

func _style_banner():
	var banner = get_node_or_null("BannerImage")
	if banner:
		banner.color = UITheme.BG_MEDIUM

		# Add sprite banner decoration behind the title
		var banner_decoration = UISpriteLoader.create_banner(UISpriteLoader.BannerColor.GOLD, "TitleBanner")
		if banner_decoration:
			banner_decoration.name = "BannerDecoration"
			banner_decoration.set_anchors_preset(Control.PRESET_CENTER_TOP)
			banner_decoration.custom_minimum_size = Vector2(500, 80)
			banner_decoration.size = Vector2(500, 80)
			banner_decoration.position = Vector2(-250, 20)
			banner.add_child(banner_decoration)
			banner.move_child(banner_decoration, 0)  # Move to back

	var banner_title = get_node_or_null("BannerImage/BannerTitle")
	if banner_title:
		banner_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE + 10)
		banner_title.add_theme_color_override("font_color", UITheme.GOLD)
		banner_title.add_theme_color_override("font_outline_color", Color.BLACK)
		banner_title.add_theme_constant_override("outline_size", 3)

	var banner_subtitle = get_node_or_null("BannerImage/BannerSubtitle")
	if banner_subtitle:
		banner_subtitle.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		banner_subtitle.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	var rates_label = get_node_or_null("BannerImage/RatesLabel")
	if rates_label:
		rates_label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		rates_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

func _style_results_panel():
	# Use sprite-based gold panel for results
	if results_panel:
		UISpriteLoader.apply_panel_style(results_panel, UISpriteLoader.PanelColor.GOLD, "Panel")

	var results_bg = get_node_or_null("ResultsPanel/ResultsBackground")
	if results_bg:
		results_bg.color = UITheme.BG_MEDIUM

	var results_title = get_node_or_null("ResultsPanel/ResultsTitle")
	if results_title:
		results_title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		results_title.add_theme_color_override("font_color", UITheme.GOLD)

	# Continue button - gold themed sprite button
	if continue_btn:
		UISpriteLoader.apply_button_style(continue_btn, UISpriteLoader.ButtonColor.GOLD, "ButtonA")
		continue_btn.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)

func _style_skip_button():
	if not skip_btn:
		return
	# Semi-transparent style for skip button
	var skip_style = StyleBoxFlat.new()
	skip_style.bg_color = Color(0, 0, 0, 0.5)
	skip_style.corner_radius_top_left = UITheme.BUTTON_RADIUS
	skip_style.corner_radius_top_right = UITheme.BUTTON_RADIUS
	skip_style.corner_radius_bottom_left = UITheme.BUTTON_RADIUS
	skip_style.corner_radius_bottom_right = UITheme.BUTTON_RADIUS
	skip_style.content_margin_left = UITheme.SPACING_MD
	skip_style.content_margin_right = UITheme.SPACING_MD
	skip_style.content_margin_top = UITheme.SPACING_SM
	skip_style.content_margin_bottom = UITheme.SPACING_SM

	var skip_hover = skip_style.duplicate()
	skip_hover.bg_color = Color(0.2, 0.2, 0.2, 0.7)

	skip_btn.add_theme_stylebox_override("normal", skip_style)
	skip_btn.add_theme_stylebox_override("hover", skip_hover)
	skip_btn.add_theme_stylebox_override("pressed", skip_style)
	skip_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	skip_btn.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	skip_btn.add_theme_color_override("font_hover_color", UITheme.TEXT_PRIMARY)
