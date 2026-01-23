extends CanvasLayer
## Achievement unlock notification popup

signal popup_dismissed

const AUTO_DISMISS_TIME: float = 3.0

@onready var overlay = $Overlay
@onready var panel = $Panel
@onready var banner = $Panel/VBox/Banner
@onready var star_container = $Panel/VBox/StarContainer
@onready var name_label = $Panel/VBox/NameLabel
@onready var desc_label = $Panel/VBox/DescLabel
@onready var reward_label = $Panel/VBox/RewardLabel

var auto_dismiss_timer: Timer = null
var current_achievement: AchievementData = null


func _ready():
	visible = false
	layer = 100  # Always on top

	# Create auto-dismiss timer
	auto_dismiss_timer = Timer.new()
	auto_dismiss_timer.one_shot = true
	auto_dismiss_timer.timeout.connect(_on_auto_dismiss)
	add_child(auto_dismiss_timer)

	# Connect overlay click
	overlay.gui_input.connect(_on_overlay_input)

	_apply_styling()


func _apply_styling():
	"""Apply sprite-based UI styling."""
	# Gold panel background
	UISpriteLoader.apply_panel_style(panel, UISpriteLoader.PanelColor.GOLD, "Panel")

	# Banner styling
	var banner_texture = UISpriteLoader.get_banner_texture(UISpriteLoader.BannerColor.GOLD, "TitleBanner")
	if banner_texture and banner is NinePatchRect:
		banner.texture = banner_texture

	# Name label styling
	name_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
	name_label.add_theme_color_override("font_color", UITheme.GOLD)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 2)

	# Description styling
	desc_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	desc_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Reward styling
	reward_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
	reward_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))  # Green for reward
	reward_label.add_theme_color_override("font_outline_color", Color.BLACK)
	reward_label.add_theme_constant_override("outline_size", 1)


func show_achievement(achievement: AchievementData):
	"""Display the achievement popup."""
	current_achievement = achievement

	# Set content
	name_label.text = achievement.achievement_name
	desc_label.text = achievement.description
	reward_label.text = "+" + str(achievement.gem_reward) + " Gems"

	# Create stars
	_setup_stars()

	# Play sound
	if AudioManager:
		AudioManager.play_ui_confirm()

	# Show with animation
	visible = true
	_animate_in()

	# Start auto-dismiss timer
	auto_dismiss_timer.start(AUTO_DISMISS_TIME)


func _setup_stars():
	"""Set up the star display."""
	# Clear existing stars
	for child in star_container.get_children():
		child.queue_free()

	# Add 3 gold stars
	var stars = UISpriteLoader.create_star_display(3, 3, UISpriteLoader.StarColor.GOLD)
	if stars:
		# Reparent children to our container
		var star_children = []
		for child in stars.get_children():
			star_children.append(child)
		for child in star_children:
			stars.remove_child(child)
			child.custom_minimum_size = Vector2(32, 32)
			star_container.add_child(child)
		stars.queue_free()


func _animate_in():
	"""Animate popup appearing."""
	panel.modulate.a = 0
	panel.scale = Vector2(0.8, 0.8)
	overlay.modulate.a = 0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 0.6, 0.2)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_out():
	"""Animate popup disappearing."""
	auto_dismiss_timer.stop()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.2)

	await tween.finished
	visible = false
	popup_dismissed.emit()


func _on_overlay_input(event: InputEvent):
	"""Handle click/tap on overlay to dismiss."""
	if event is InputEventMouseButton and event.pressed:
		_animate_out()


func _on_auto_dismiss():
	"""Auto-dismiss after timeout."""
	if visible:
		_animate_out()
