extends Node
## UITheme - Design system constants for consistent UI
## Add as autoload named "UITheme"

# === COLORS ===

# Backgrounds
const BG_DARK = Color("#1a1a2e")
const BG_MEDIUM = Color("#252542")
const BG_LIGHT = Color("#2d2d4a")

# Accents
const PRIMARY = Color("#4a9eff")
const SECONDARY = Color("#7c5cff")
const SUCCESS = Color("#4ade80")
const DANGER = Color("#f87171")
const GOLD = Color("#fbbf24")

# Rarity
const RARITY_3_STAR = Color("#9ca3af")
const RARITY_4_STAR = Color("#a78bfa")
const RARITY_5_STAR = Color("#fbbf24")

# Text
const TEXT_PRIMARY = Color("#ffffff")
const TEXT_SECONDARY = Color("#94a3b8")
const TEXT_DISABLED = Color("#4b5563")

# === FONT SIZES ===
const FONT_TITLE_LARGE = 32
const FONT_TITLE_MEDIUM = 24
const FONT_TITLE_SMALL = 18
const FONT_BODY = 16
const FONT_CAPTION = 14
const FONT_SMALL = 12

# === SPACING ===
const SPACING_XS = 4
const SPACING_SM = 8
const SPACING_MD = 16
const SPACING_LG = 24
const SPACING_XL = 32

# === COMPONENT SIZES ===
const BUTTON_RADIUS = 8
const CARD_RADIUS = 8
const MODAL_RADIUS = 12
const UNIT_CARD_SIZE = Vector2(160, 200)
const TOP_BAR_HEIGHT = 64
const BOTTOM_BAR_HEIGHT = 80

# === HELPER FUNCTIONS ===

func get_rarity_color(star_rating: int) -> Color:
	match star_rating:
		5: return RARITY_5_STAR
		4: return RARITY_4_STAR
		_: return RARITY_3_STAR

func create_panel_style(bg_color: Color = BG_MEDIUM, border_color: Color = BG_LIGHT, radius: int = CARD_RADIUS) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = SPACING_MD
	style.content_margin_right = SPACING_MD
	style.content_margin_top = SPACING_MD
	style.content_margin_bottom = SPACING_MD
	return style

func create_button_style(bg_color: Color, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2 if border_color != Color.TRANSPARENT else 0
	style.border_width_right = 2 if border_color != Color.TRANSPARENT else 0
	style.border_width_top = 2 if border_color != Color.TRANSPARENT else 0
	style.border_width_bottom = 2 if border_color != Color.TRANSPARENT else 0
	style.corner_radius_top_left = BUTTON_RADIUS
	style.corner_radius_top_right = BUTTON_RADIUS
	style.corner_radius_bottom_left = BUTTON_RADIUS
	style.corner_radius_bottom_right = BUTTON_RADIUS
	style.content_margin_left = SPACING_LG
	style.content_margin_right = SPACING_LG
	style.content_margin_top = SPACING_MD
	style.content_margin_bottom = SPACING_MD
	return style
