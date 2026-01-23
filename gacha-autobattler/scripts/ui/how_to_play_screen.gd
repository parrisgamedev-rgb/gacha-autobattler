extends Control
## How to Play screen with tabbed help content

# Tab buttons
@onready var combat_tab = $VBoxContainer/TabBar/CombatTab
@onready var progression_tab = $VBoxContainer/TabBar/ProgressionTab
@onready var elements_tab = $VBoxContainer/TabBar/ElementsTab

# Content container
@onready var content_scroll = $VBoxContainer/ContentPanel/ScrollContainer
@onready var content_label = $VBoxContainer/ContentPanel/ScrollContainer/ContentLabel

# Back button
@onready var back_button = $VBoxContainer/Header/BackButton

# Current active tab
var current_tab: String = "combat"

# Content for each tab
const COMBAT_CONTENT = """[b]BATTLE BASICS[/b]

• 3x3 grid battlefield
• You have [color=#4a9eff]3 actions[/color] per turn (place unit, move unit, or use ability)
• After your turn, combat resolves automatically based on unit speed

[b]VICTORY CONDITIONS[/b]

• Win by eliminating [color=#4a9eff]ALL[/color] enemy units
• If turn limit (25) is reached:
  - 1st tiebreaker: Control a line (row, column, or diagonal)
  - 2nd tiebreaker: Team with higher HP percentage wins

[b]IN BATTLE[/b]

• Drag units from your team bar onto the grid
• Click a placed unit to see their abilities
• Use [color=#4a9eff]Auto-Battle[/color] to let AI play for you
• Speed buttons (1x/2x/3x) control animation speed
"""

const PROGRESSION_CONTENT = """[b]UNIT LEVELS[/b]

• Units gain XP from winning battles
• Manually level up in Collection screen using Gold + Materials
• Max level depends on star rating:
  - 3-star: Level 30
  - 4-star: Level 40
  - 5-star: Level 50
• Stats increase [color=#4a9eff]3% per level[/color]

[b]GEAR SYSTEM[/b]

• Equip gear in 4 slots: Weapon, Armor, Accessory 1, Accessory 2
• Gear drops from [color=#4a9eff]Dungeons[/color] (each dungeon focuses on one stat)
• Enhance gear using Gold + Enhancement Stones
• Rarities: Common, Rare, Epic, Legendary

[b]CURRENCIES[/b]

• [color=#ffd700]Gold[/color]: Level units, enhance gear
• [color=#90EE90]Materials[/color]: Level units
• [color=#DDA0DD]Enhancement Stones[/color]: Enhance gear (from dungeons)
• [color=#4a9eff]Gems[/color]: Summon new units
"""

const ELEMENTS_CONTENT = """[b]FIVE ELEMENTS[/b]

• [color=#ff6b6b]Fire[/color], [color=#4a9eff]Water[/color], [color=#7bed9f]Nature[/color], [color=#fff68f]Light[/color], [color=#9b59b6]Dark[/color]

[b]ADVANTAGE TRIANGLE[/b]

    [color=#ff6b6b]Fire[/color]
     /  \\
    /    \\
[color=#7bed9f]Nature[/color]---[color=#4a9eff]Water[/color]

• [color=#ff6b6b]Fire[/color] beats [color=#7bed9f]Nature[/color]
• [color=#7bed9f]Nature[/color] beats [color=#4a9eff]Water[/color]
• [color=#4a9eff]Water[/color] beats [color=#ff6b6b]Fire[/color]

[b]LIGHT & DARK[/b]

• [color=#fff68f]Light[/color] and [color=#9b59b6]Dark[/color] are strong against each other
• Neither has advantage vs Fire/Water/Nature

[b]IN BATTLE[/b]

• Attacks deal [color=#7bed9f]bonus damage[/color] against disadvantaged elements
• Attacks deal [color=#ff6b6b]reduced damage[/color] against advantaged elements
• Neutral matchups deal normal damage
"""


func _ready():
	_apply_theme()
	_connect_signals()
	_show_tab("combat")


func _apply_theme():
	# Background
	if has_node("Background"):
		$Background.color = UITheme.BG_DARK

	# Header styling
	if has_node("VBoxContainer/Header/TitleLabel"):
		var title = $VBoxContainer/Header/TitleLabel
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Back button styling
	if back_button:
		back_button.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_MEDIUM, UITheme.BG_LIGHT))
		back_button.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT))
		back_button.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.BG_MEDIUM.darkened(0.1)))
		back_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		back_button.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Tab button styling
	_style_tab_buttons()

	# Content panel styling
	if has_node("VBoxContainer/ContentPanel"):
		var panel = $VBoxContainer/ContentPanel
		var style = StyleBoxFlat.new()
		style.bg_color = UITheme.BG_MEDIUM
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.content_margin_left = UITheme.SPACING_LG
		style.content_margin_right = UITheme.SPACING_LG
		style.content_margin_top = UITheme.SPACING_LG
		style.content_margin_bottom = UITheme.SPACING_LG
		panel.add_theme_stylebox_override("panel", style)

	# Content label styling
	if content_label:
		content_label.add_theme_font_size_override("normal_font_size", UITheme.FONT_BODY)
		content_label.add_theme_font_size_override("bold_font_size", UITheme.FONT_BODY + 2)
		content_label.add_theme_color_override("default_color", UITheme.TEXT_PRIMARY)


func _style_tab_buttons():
	var tabs = [combat_tab, progression_tab, elements_tab]
	for tab in tabs:
		if tab:
			tab.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
			tab.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
			tab.custom_minimum_size = Vector2(120, 40)
	_update_tab_styles()


func _update_tab_styles():
	var tabs = {"combat": combat_tab, "progression": progression_tab, "elements": elements_tab}
	for tab_name in tabs:
		var tab = tabs[tab_name]
		if not tab:
			continue
		if tab_name == current_tab:
			# Active tab style
			tab.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
			tab.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.PRIMARY.lightened(0.1)))
			tab.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.PRIMARY.darkened(0.1)))
		else:
			# Inactive tab style
			tab.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_MEDIUM, UITheme.BG_LIGHT))
			tab.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT))
			tab.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.BG_MEDIUM.darkened(0.1)))


func _connect_signals():
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if combat_tab:
		combat_tab.pressed.connect(_on_combat_tab_pressed)
	if progression_tab:
		progression_tab.pressed.connect(_on_progression_tab_pressed)
	if elements_tab:
		elements_tab.pressed.connect(_on_elements_tab_pressed)


func _show_tab(tab_name: String):
	current_tab = tab_name
	_update_tab_styles()

	# Reset scroll position
	if content_scroll:
		content_scroll.scroll_vertical = 0

	# Update content
	if content_label:
		match tab_name:
			"combat":
				content_label.text = COMBAT_CONTENT
			"progression":
				content_label.text = PROGRESSION_CONTENT
			"elements":
				content_label.text = ELEMENTS_CONTENT


func _on_back_pressed():
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")


func _on_combat_tab_pressed():
	AudioManager.play_ui_click()
	_show_tab("combat")


func _on_progression_tab_pressed():
	AudioManager.play_ui_click()
	_show_tab("progression")


func _on_elements_tab_pressed():
	AudioManager.play_ui_click()
	_show_tab("elements")
