extends Control
## Credits screen showing game credits and attributions

@onready var back_button = $CenterContainer/VBoxContainer/BackButton
@onready var scroll_container = $CenterContainer/VBoxContainer/CreditsPanel/ScrollContainer
@onready var credits_label = $CenterContainer/VBoxContainer/CreditsPanel/ScrollContainer/CreditsLabel


func _ready():
	_apply_theme()
	_setup_credits_text()

	if back_button:
		back_button.pressed.connect(_on_back_pressed)


func _apply_theme():
	# Background - use castle theme
	UISpriteLoader.apply_background_to_scene(self, UISpriteLoader.BackgroundTheme.CASTLE, UISpriteLoader.BackgroundVariant.PALE, 0.5)
	if has_node("Background"):
		$Background.visible = false

	# Title
	if has_node("CenterContainer/VBoxContainer/TitleLabel"):
		var title = $CenterContainer/VBoxContainer/TitleLabel
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Credits panel with sprite styling
	if has_node("CenterContainer/VBoxContainer/CreditsPanel"):
		var panel = $CenterContainer/VBoxContainer/CreditsPanel
		UISpriteLoader.apply_panel_style(panel, UISpriteLoader.PanelColor.BLUE, "Panel")

	# Credits text
	if credits_label:
		credits_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		credits_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Back button
	if back_button:
		UISpriteLoader.apply_button_style(back_button, UISpriteLoader.ButtonColor.BLUE, "ButtonA")
		back_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)


func _setup_credits_text():
	if not credits_label:
		return

	var credits_text = """[center][color=#FFD700][font_size=28]GRID BATTLER[/font_size][/color]
[i]A Gacha Auto-Battler[/i]

[color=#FFD700]- - - - - - - - - - - - - - -[/color]

[color=#4a9eff][font_size=20]CREATED BY[/font_size][/color]
dsParri

[color=#FFD700]- - - - - - - - - - - - - - -[/color]

[color=#4a9eff][font_size=20]DEVELOPMENT[/font_size][/color]
Built with Claude AI assistance

[color=#FFD700]- - - - - - - - - - - - - - -[/color]

[color=#4a9eff][font_size=20]ART ASSETS[/font_size][/color]
Character Sprites
[color=#94a3b8]Tiny RPG Character Asset Pack[/color]

UI Elements
[color=#94a3b8]Pixel Art UI Pack[/color]

Battleground Backgrounds
[color=#94a3b8]Fantasy Battlegrounds Pack[/color]

[color=#FFD700]- - - - - - - - - - - - - - -[/color]

[color=#4a9eff][font_size=20]AUDIO[/font_size][/color]
Sound Effects
[color=#94a3b8]Kenney.nl (CC0)[/color]

Music
[color=#94a3b8]OpenGameArt.org (CC0)[/color]

[color=#FFD700]- - - - - - - - - - - - - - -[/color]

[color=#4a9eff][font_size=20]ENGINE[/font_size][/color]
Made with Godot Engine 4.5

[color=#FFD700]- - - - - - - - - - - - - - -[/color]

[color=#4a9eff][font_size=20]SPECIAL THANKS[/font_size][/color]
The Godot Community
Anthropic

[color=#FFD700]- - - - - - - - - - - - - - -[/color]

[color=#94a3b8]v0.18[/color]
[color=#94a3b8]2026[/color][/center]"""

	credits_label.bbcode_enabled = true
	credits_label.text = credits_text


func _on_back_pressed():
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/settings_screen.tscn")
