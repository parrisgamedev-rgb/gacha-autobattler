extends Node
## Loads and applies sprite-based UI assets to game elements

# Base path for UI sprites
const UI_PATH = "res://assets/board/Sprites/"

# Color themes available
enum ButtonColor { BLACK, BLUE, GOLD, ORANGE, PURPLE, RED, WHITE }
enum PanelColor { BLACK, BLUE, GOLD, PAPER, PHOTO, PURPLE, RED, WHITE, WOOD }
enum BarColor { BLUE, GREEN, ORANGE, PURPLE, RED, WHITE }
enum StarColor { BLUE, GOLD, PURPLE, RED }
enum BannerColor { BLACK, BLUE, GOLD, GREEN, PURPLE, RED, WHITE }
enum TooltipColor { BLACK, BLUE, BROWN, GOLD, ORANGE, PURPLE, RED, WHITE }
enum FormColor { BLACK, BLUE, ORANGE, PURPLE, RED, WHITE }
enum HeartColor { BLUE, PURPLE, RED }
enum BackgroundTheme { RUINS, CASTLE, JUNGLE, GRAVEYARD }
enum BackgroundVariant { BRIGHT, PALE }

# Cached textures
var _button_textures: Dictionary = {}
var _panel_textures: Dictionary = {}
var _bar_textures: Dictionary = {}
var _star_textures: Dictionary = {}
var _banner_textures: Dictionary = {}
var _tooltip_textures: Dictionary = {}
var _form_textures: Dictionary = {}
var _selector_textures: Dictionary = {}
var _portrait_textures: Dictionary = {}
var _heart_textures: Dictionary = {}
var _background_textures: Dictionary = {}


func _ready():
	_preload_common_assets()


func _preload_common_assets():
	"""Preload commonly used UI assets."""
	# Preload gold stars (most common)
	_load_star_textures(StarColor.GOLD)
	# Preload blue buttons (primary)
	_load_button_textures(ButtonColor.BLUE, "ButtonA")
	# Preload blue panels
	_load_panel_textures(PanelColor.BLUE, "Panel")


func _color_to_string(color, color_type: String) -> String:
	"""Convert color enum to folder name string."""
	match color_type:
		"button":
			match color:
				ButtonColor.BLACK: return "Black"
				ButtonColor.BLUE: return "Blue"
				ButtonColor.GOLD: return "Gold"
				ButtonColor.ORANGE: return "Orange"
				ButtonColor.PURPLE: return "Purple"
				ButtonColor.RED: return "Red"
				ButtonColor.WHITE: return "White"
		"panel":
			match color:
				PanelColor.BLACK: return "Black"
				PanelColor.BLUE: return "Blue"
				PanelColor.GOLD: return "Gold"
				PanelColor.PAPER: return "Paper"
				PanelColor.PHOTO: return "Photo"
				PanelColor.PURPLE: return "Purple"
				PanelColor.RED: return "Red"
				PanelColor.WHITE: return "White"
				PanelColor.WOOD: return "Wood"
		"bar":
			match color:
				BarColor.BLUE: return "Blue"
				BarColor.GREEN: return "Green"
				BarColor.ORANGE: return "Orange"
				BarColor.PURPLE: return "Purple"
				BarColor.RED: return "Red"
				BarColor.WHITE: return "White"
		"star":
			match color:
				StarColor.BLUE: return "Blue"
				StarColor.GOLD: return "Gold"
				StarColor.PURPLE: return "Purple"
				StarColor.RED: return "Red"
		"banner":
			match color:
				BannerColor.BLACK: return "Black"
				BannerColor.BLUE: return "Blue"
				BannerColor.GOLD: return "Gold"
				BannerColor.GREEN: return "Green"
				BannerColor.PURPLE: return "Purple"
				BannerColor.RED: return "Red"
				BannerColor.WHITE: return "White"
		"tooltip":
			match color:
				TooltipColor.BLACK: return "Black"
				TooltipColor.BLUE: return "Blue"
				TooltipColor.BROWN: return "Brown"
				TooltipColor.GOLD: return "Gold"
				TooltipColor.ORANGE: return "Orange"
				TooltipColor.PURPLE: return "Purple"
				TooltipColor.RED: return "Red"
				TooltipColor.WHITE: return "White"
		"form":
			match color:
				FormColor.BLACK: return "Black"
				FormColor.BLUE: return "Blue"
				FormColor.ORANGE: return "Orange"
				FormColor.PURPLE: return "Purple"
				FormColor.RED: return "Red"
				FormColor.WHITE: return "White"
		"heart":
			match color:
				HeartColor.BLUE: return "Blue"
				HeartColor.PURPLE: return "Purple"
				HeartColor.RED: return "Red"
	return "Blue"


# ============ BUTTONS ============

func _load_button_textures(color: ButtonColor, style: String) -> Dictionary:
	"""Load button textures for a specific color and style."""
	var key = "%s_%s" % [color, style]
	if key in _button_textures:
		return _button_textures[key]

	var color_str = _color_to_string(color, "button")
	var base_path = UI_PATH + "Buttons/%s/" % color_str

	var textures = {}
	var states = ["Unpressed", "Pressed", "Highlighted", "Press"]

	for state in states:
		var path = base_path + "%s_%s.png" % [style, state]
		if ResourceLoader.exists(path):
			textures[state.to_lower()] = load(path)

	_button_textures[key] = textures
	return textures


func apply_button_style(button: Button, color: ButtonColor = ButtonColor.BLUE, style: String = "ButtonA"):
	"""Apply sprite-based styling to a Button node."""
	var textures = _load_button_textures(color, style)

	if textures.is_empty():
		return

	# Create StyleBoxTexture for each state
	if "unpressed" in textures:
		var normal_style = StyleBoxTexture.new()
		normal_style.texture = textures["unpressed"]
		normal_style.texture_margin_left = 8
		normal_style.texture_margin_right = 8
		normal_style.texture_margin_top = 8
		normal_style.texture_margin_bottom = 8
		button.add_theme_stylebox_override("normal", normal_style)

	if "pressed" in textures:
		var pressed_style = StyleBoxTexture.new()
		pressed_style.texture = textures["pressed"]
		pressed_style.texture_margin_left = 8
		pressed_style.texture_margin_right = 8
		pressed_style.texture_margin_top = 8
		pressed_style.texture_margin_bottom = 8
		button.add_theme_stylebox_override("pressed", pressed_style)

	if "highlighted" in textures:
		var hover_style = StyleBoxTexture.new()
		hover_style.texture = textures["highlighted"]
		hover_style.texture_margin_left = 8
		hover_style.texture_margin_right = 8
		hover_style.texture_margin_top = 8
		hover_style.texture_margin_bottom = 8
		button.add_theme_stylebox_override("hover", hover_style)

	# Set text color for visibility
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 2)


# ============ PANELS ============

func _load_panel_textures(color: PanelColor, style: String) -> Dictionary:
	"""Load panel textures for a specific color and style."""
	var key = "%s_%s" % [color, style]
	if key in _panel_textures:
		return _panel_textures[key]

	var color_str = _color_to_string(color, "panel")
	var base_path = UI_PATH + "Panels/%s/" % color_str

	var textures = {}
	var path = base_path + "%s.png" % style
	if ResourceLoader.exists(path):
		textures["main"] = load(path)

	# Also try Inner variant
	var inner_path = base_path + "%sInner.png" % style
	if ResourceLoader.exists(inner_path):
		textures["inner"] = load(inner_path)

	_panel_textures[key] = textures
	return textures


func apply_panel_style(panel: Control, color: PanelColor = PanelColor.BLUE, style: String = "Panel"):
	"""Apply sprite-based styling to a Panel or PanelContainer node."""
	var textures = _load_panel_textures(color, style)

	if textures.is_empty() or "main" not in textures:
		return

	var panel_style = StyleBoxTexture.new()
	panel_style.texture = textures["main"]
	panel_style.texture_margin_left = 16
	panel_style.texture_margin_right = 16
	panel_style.texture_margin_top = 16
	panel_style.texture_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", panel_style)


func create_nine_patch_panel(color: PanelColor = PanelColor.BLUE, style: String = "Panel") -> NinePatchRect:
	"""Create a NinePatchRect with the panel texture."""
	var textures = _load_panel_textures(color, style)

	if textures.is_empty() or "main" not in textures:
		return null

	var nine_patch = NinePatchRect.new()
	nine_patch.texture = textures["main"]
	nine_patch.patch_margin_left = 16
	nine_patch.patch_margin_right = 16
	nine_patch.patch_margin_top = 16
	nine_patch.patch_margin_bottom = 16

	return nine_patch


# ============ VALUE BARS (HP/MP) ============

func _load_bar_textures(color: BarColor, style: String) -> Dictionary:
	"""Load value bar textures."""
	var key = "%s_%s" % [color, style]
	if key in _bar_textures:
		return _bar_textures[key]

	var color_str = _color_to_string(color, "bar")
	var base_path = UI_PATH + "ValueBars/%s/" % color_str

	var textures = {}
	var parts = ["Background", "Fill", "Foreground", "FollowFill"]

	for part in parts:
		var path = base_path + "%s%s.png" % [style, part]
		if ResourceLoader.exists(path):
			textures[part.to_lower()] = load(path)

	_bar_textures[key] = textures
	return textures


func create_hp_bar(color: BarColor = BarColor.GREEN, style: String = "MinimalBar") -> Dictionary:
	"""Create HP bar components. Returns dict with background, fill, and foreground TextureRects."""
	var textures = _load_bar_textures(color, style)

	var result = {}

	if "background" in textures:
		var bg = TextureRect.new()
		bg.texture = textures["background"]
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		result["background"] = bg

	if "fill" in textures:
		var fill = TextureRect.new()
		fill.texture = textures["fill"]
		fill.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		result["fill"] = fill

	if "foreground" in textures:
		var fg = TextureRect.new()
		fg.texture = textures["foreground"]
		fg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		result["foreground"] = fg

	return result


# ============ STARS ============

func _load_star_textures(color: StarColor) -> Dictionary:
	"""Load star textures."""
	if color in _star_textures:
		return _star_textures[color]

	var color_str = _color_to_string(color, "star")
	var base_path = UI_PATH + "Stars/%s/" % color_str

	var textures = {}

	var full_path = base_path + "Star_Full.png"
	if ResourceLoader.exists(full_path):
		textures["full"] = load(full_path)

	var empty_path = base_path + "Star_Empty.png"
	if ResourceLoader.exists(empty_path):
		textures["empty"] = load(empty_path)

	var activate_path = base_path + "Star_Activate.png"
	if ResourceLoader.exists(activate_path):
		textures["activate"] = load(activate_path)

	_star_textures[color] = textures
	return textures


func get_star_texture(filled: bool, color: StarColor = StarColor.GOLD) -> Texture2D:
	"""Get a star texture (filled or empty)."""
	var textures = _load_star_textures(color)
	if filled and "full" in textures:
		return textures["full"]
	elif not filled and "empty" in textures:
		return textures["empty"]
	return null


func create_star_display(rating: int, max_stars: int = 5, color: StarColor = StarColor.GOLD) -> HBoxContainer:
	"""Create an HBoxContainer with star rating display."""
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var textures = _load_star_textures(color)

	for i in range(max_stars):
		var star = TextureRect.new()
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(16, 16)

		if i < rating and "full" in textures:
			star.texture = textures["full"]
		elif "empty" in textures:
			star.texture = textures["empty"]

		container.add_child(star)

	return container


# ============ BANNERS ============

func _load_banner_texture(color: BannerColor, style: String) -> Texture2D:
	"""Load a banner texture."""
	var key = "%s_%s" % [color, style]
	if key in _banner_textures:
		return _banner_textures[key]

	var color_str = _color_to_string(color, "banner")
	var path = UI_PATH + "Banners/%s/%s.png" % [color_str, style]

	if ResourceLoader.exists(path):
		_banner_textures[key] = load(path)
		return _banner_textures[key]
	return null


func create_banner(color: BannerColor = BannerColor.GOLD, style: String = "TitleBanner") -> NinePatchRect:
	"""Create a NinePatchRect banner."""
	var texture = _load_banner_texture(color, style)
	if not texture:
		return null

	var banner = NinePatchRect.new()
	banner.texture = texture
	banner.patch_margin_left = 32
	banner.patch_margin_right = 32
	banner.patch_margin_top = 16
	banner.patch_margin_bottom = 16

	return banner


func get_banner_texture(color: BannerColor = BannerColor.GOLD, style: String = "TitleBanner") -> Texture2D:
	"""Get a banner texture directly."""
	return _load_banner_texture(color, style)


# ============ TOOLTIPS / SPEECH BUBBLES ============

func _load_tooltip_texture(color: TooltipColor, style: String) -> Texture2D:
	"""Load a tooltip/speech texture."""
	var key = "%s_%s" % [color, style]
	if key in _tooltip_textures:
		return _tooltip_textures[key]

	var color_str = _color_to_string(color, "tooltip")
	var path = UI_PATH + "Tooltips/%s/%s.png" % [color_str, style]

	if ResourceLoader.exists(path):
		_tooltip_textures[key] = load(path)
		return _tooltip_textures[key]
	return null


func create_tooltip(color: TooltipColor = TooltipColor.BLUE, style: String = "Tooltip") -> NinePatchRect:
	"""Create a tooltip NinePatchRect."""
	var texture = _load_tooltip_texture(color, style)
	if not texture:
		return null

	var tooltip = NinePatchRect.new()
	tooltip.texture = texture
	tooltip.patch_margin_left = 16
	tooltip.patch_margin_right = 16
	tooltip.patch_margin_top = 16
	tooltip.patch_margin_bottom = 16

	return tooltip


func create_speech_bubble(color: TooltipColor = TooltipColor.BLUE, style: String = "SpeechBubble") -> NinePatchRect:
	"""Create a speech bubble NinePatchRect."""
	return create_tooltip(color, style)


func get_tooltip_texture(color: TooltipColor = TooltipColor.BLUE, style: String = "Tooltip") -> Texture2D:
	"""Get a tooltip texture directly."""
	return _load_tooltip_texture(color, style)


# ============ FORM ELEMENTS ============

func _load_form_texture(color: FormColor, element: String) -> Texture2D:
	"""Load a form element texture."""
	var key = "%s_%s" % [color, element]
	if key in _form_textures:
		return _form_textures[key]

	var color_str = _color_to_string(color, "form")
	var path = UI_PATH + "FormElements/%s/%s.png" % [color_str, element]

	if ResourceLoader.exists(path):
		_form_textures[key] = load(path)
		return _form_textures[key]
	return null


func get_toggle_textures(color: FormColor = FormColor.BLUE) -> Dictionary:
	"""Get toggle on/off textures."""
	return {
		"on": _load_form_texture(color, "ToggleOn"),
		"off": _load_form_texture(color, "ToggleOff"),
		"indeterminate": _load_form_texture(color, "ToggleIndeterminate")
	}


func get_switch_textures(color: FormColor = FormColor.BLUE) -> Dictionary:
	"""Get switch on/off textures."""
	return {
		"on": _load_form_texture(color, "SwitchOn"),
		"off": _load_form_texture(color, "SwitchOff"),
		"indeterminate": _load_form_texture(color, "SwitchIndeterminate")
	}


func get_checkbox_textures(color: FormColor = FormColor.BLUE) -> Dictionary:
	"""Get checkbox textures."""
	return {
		"checked": _load_form_texture(color, "CheckboxCheckeed"),
		"unchecked": _load_form_texture(color, "CheckboxUnchecked"),
		"outline": _load_form_texture(color, "CheckboxOutline"),
		"indeterminate": _load_form_texture(color, "CheckboxIndeterminate")
	}


func get_slider_textures(color: FormColor = FormColor.BLUE) -> Dictionary:
	"""Get slider textures."""
	return {
		"background": _load_form_texture(color, "SliderRoundedBackground"),
		"fill": _load_form_texture(color, "SliderRoundedFill"),
		"foreground": _load_form_texture(color, "SliderRoundedForeground"),
		"handle": _load_form_texture(color, "SliderHandle"),
		"handle_highlighted": _load_form_texture(color, "SliderHandleHighlighted")
	}


func get_dropdown_textures(color: FormColor = FormColor.BLUE) -> Dictionary:
	"""Get dropdown textures."""
	return {
		"normal": _load_form_texture(color, "Dropdown"),
		"highlighted": _load_form_texture(color, "DropdownHighlighted")
	}


# ============ SELECTORS ============

func _load_selector_texture(style: String) -> Texture2D:
	"""Load a selector texture."""
	if style in _selector_textures:
		return _selector_textures[style]

	var path = UI_PATH + "Selectors/%s.png" % style

	if ResourceLoader.exists(path):
		_selector_textures[style] = load(path)
		return _selector_textures[style]
	return null


func get_selector_textures(style: String = "Square") -> Dictionary:
	"""Get selector hover/select textures."""
	return {
		"hover": _load_selector_texture("%s_Hover" % style),
		"select": _load_selector_texture("%s_Select" % style)
	}


func create_selector_sprite(style: String = "Square", is_selected: bool = false) -> TextureRect:
	"""Create a selector TextureRect."""
	var textures = get_selector_textures(style)
	var key = "select" if is_selected else "hover"

	if key not in textures or textures[key] == null:
		return null

	var sprite = TextureRect.new()
	sprite.texture = textures[key]
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return sprite


# ============ PORTRAITS ============

func _load_portrait_texture(style: String) -> Texture2D:
	"""Load a portrait frame texture."""
	if style in _portrait_textures:
		return _portrait_textures[style]

	var path = UI_PATH + "Portraits/%s.png" % style

	if ResourceLoader.exists(path):
		_portrait_textures[style] = load(path)
		return _portrait_textures[style]
	return null


func get_portrait_frame(is_enemy: bool = false, size: String = "Medium") -> Texture2D:
	"""Get a portrait frame texture."""
	var prefix = "Enemy" if is_enemy else "Player"
	return _load_portrait_texture("%s%s" % [prefix, size])


func create_portrait_frame(is_enemy: bool = false, size: String = "Medium") -> TextureRect:
	"""Create a portrait frame TextureRect."""
	var texture = get_portrait_frame(is_enemy, size)
	if not texture:
		return null

	var frame = TextureRect.new()
	frame.texture = texture
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return frame


# ============ HEARTS ============

func _load_heart_textures(color: HeartColor) -> Dictionary:
	"""Load heart textures."""
	if color in _heart_textures:
		return _heart_textures[color]

	var color_str = _color_to_string(color, "heart")
	var base_path = UI_PATH + "Hearts/%s/" % color_str

	var textures = {}
	var states = ["Full", "Empty", "Half", "Quarter", "ThreeQuarter"]

	for state in states:
		var path = base_path + "Heart_%s.png" % state
		if ResourceLoader.exists(path):
			textures[state.to_lower()] = load(path)

	# Also try the All.png which might have all states
	var all_path = UI_PATH + "Hearts/All.png"
	if ResourceLoader.exists(all_path):
		textures["all"] = load(all_path)

	_heart_textures[color] = textures
	return textures


func get_heart_texture(state: String = "full", color: HeartColor = HeartColor.RED) -> Texture2D:
	"""Get a heart texture by state (full, empty, half, quarter, threequarter)."""
	var textures = _load_heart_textures(color)
	return textures.get(state.to_lower(), null)


func create_heart_display(current: int, max_hearts: int = 5, color: HeartColor = HeartColor.RED) -> HBoxContainer:
	"""Create a heart-based health display."""
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var textures = _load_heart_textures(color)

	for i in range(max_hearts):
		var heart = TextureRect.new()
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(20, 20)

		if i < current and "full" in textures:
			heart.texture = textures["full"]
		elif "empty" in textures:
			heart.texture = textures["empty"]

		container.add_child(heart)

	return container


# ============ BACKGROUNDS ============

const BACKGROUND_PATH = "res://assets/board/PNG/"

func _theme_to_folder(theme: BackgroundTheme) -> String:
	"""Convert background theme enum to folder name."""
	match theme:
		BackgroundTheme.RUINS: return "Battleground1"
		BackgroundTheme.CASTLE: return "Battleground2"
		BackgroundTheme.JUNGLE: return "Battleground3"
		BackgroundTheme.GRAVEYARD: return "Battleground4"
	return "Battleground1"


func _variant_to_folder(variant: BackgroundVariant) -> String:
	"""Convert background variant enum to folder name."""
	match variant:
		BackgroundVariant.BRIGHT: return "Bright"
		BackgroundVariant.PALE: return "Pale"
	return "Bright"


func _load_background_texture(theme: BackgroundTheme, variant: BackgroundVariant) -> Texture2D:
	"""Load the main background texture for a theme."""
	var key = "%s_%s" % [theme, variant]
	if key in _background_textures:
		return _background_textures[key]

	var theme_folder = _theme_to_folder(theme)
	var variant_folder = _variant_to_folder(variant)
	var path = BACKGROUND_PATH + "%s/%s/%s.png" % [theme_folder, variant_folder, theme_folder]

	if ResourceLoader.exists(path):
		_background_textures[key] = load(path)
		return _background_textures[key]
	return null


func get_background_texture(theme: BackgroundTheme, variant: BackgroundVariant = BackgroundVariant.BRIGHT) -> Texture2D:
	"""Get a background texture."""
	return _load_background_texture(theme, variant)


func create_background(theme: BackgroundTheme, variant: BackgroundVariant = BackgroundVariant.BRIGHT) -> TextureRect:
	"""Create a TextureRect with the background image, set up for full screen coverage."""
	var texture = _load_background_texture(theme, variant)
	if not texture:
		return null

	var bg = TextureRect.new()
	bg.name = "Background"
	bg.texture = texture
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return bg


func apply_background_to_scene(parent: Control, theme: BackgroundTheme, variant: BackgroundVariant = BackgroundVariant.BRIGHT, darken: float = 0.0) -> TextureRect:
	"""Add a background to a scene, optionally darkened for better UI readability."""
	# Remove existing background if present
	var existing = parent.get_node_or_null("Background")
	if existing:
		existing.queue_free()

	var bg = create_background(theme, variant)
	if not bg:
		return null

	# Apply darkening if requested (0.0 = no darken, 1.0 = fully black)
	if darken > 0.0:
		bg.modulate = Color(1.0 - darken, 1.0 - darken, 1.0 - darken, 1.0)

	# Add as first child so it's behind everything
	parent.add_child(bg)
	parent.move_child(bg, 0)

	return bg
