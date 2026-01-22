extends Node
class_name PixelArtGenerator
## Enhanced procedural pixel art generator with shading, outlines, and variation

const SPRITE_SIZE = 32  # 32x32 pixels

# Element color palettes: [primary, secondary, accent, skin_tone]
const ELEMENT_PALETTES = {
	"fire": [Color(0.9, 0.3, 0.1), Color(0.7, 0.2, 0.05), Color(1.0, 0.6, 0.1), Color(0.85, 0.65, 0.5)],
	"water": [Color(0.2, 0.5, 0.9), Color(0.1, 0.3, 0.7), Color(0.4, 0.8, 1.0), Color(0.7, 0.75, 0.85)],
	"nature": [Color(0.3, 0.7, 0.2), Color(0.2, 0.5, 0.1), Color(0.6, 0.9, 0.3), Color(0.7, 0.8, 0.6)],
	"dark": [Color(0.4, 0.2, 0.5), Color(0.25, 0.1, 0.35), Color(0.6, 0.3, 0.8), Color(0.6, 0.55, 0.65)],
	"light": [Color(0.95, 0.9, 0.5), Color(0.85, 0.75, 0.3), Color(1.0, 1.0, 0.8), Color(0.9, 0.8, 0.7)]
}

# Rarity colors for accents/glow
const RARITY_COLORS = {
	3: Color(0.7, 0.7, 0.7),  # Silver/gray
	4: Color(0.6, 0.3, 0.8),  # Purple
	5: Color(1.0, 0.85, 0.2)  # Gold
}

# Hair color options
const HAIR_COLORS = [
	Color(0.15, 0.1, 0.08),   # Black
	Color(0.4, 0.25, 0.15),   # Brown
	Color(0.85, 0.7, 0.4),    # Blonde
	Color(0.6, 0.3, 0.2),     # Auburn
	Color(0.5, 0.5, 0.55),    # Gray
	Color(0.9, 0.9, 0.85),    # White/Silver
]

# Class types determined from unit_id
enum UnitClass { WARRIOR, MAGE, CLERIC, KNIGHT, TANK, IMP, SPRITE, WISP, SCOUT, PALADIN, ARCHER, ASSASSIN, GENERIC }

# Animation frames
enum AnimFrame { IDLE, ATTACK, HURT, SPECIAL }

# Cache generated textures by unit_id
static var texture_cache: Dictionary = {}
static var anim_cache: Dictionary = {}  # Cache for animation frames

# === MAIN GENERATION FUNCTIONS ===

static func generate_unit_texture(unit_data: UnitData, frame: AnimFrame = AnimFrame.IDLE) -> ImageTexture:
	if unit_data == null:
		return _create_placeholder_texture()

	# Check cache first
	var cache_key = unit_data.unit_id + "_" + str(frame)
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]

	# Generate new texture
	var image = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Transparent background

	var palette = ELEMENT_PALETTES.get(unit_data.element, ELEMENT_PALETTES["fire"])
	var rarity_color = RARITY_COLORS.get(unit_data.star_rating, RARITY_COLORS[3])
	var unit_class = _determine_class(unit_data.unit_id)
	var seed_hash = _hash_string(unit_data.unit_id)

	# Draw character based on class
	match unit_class:
		UnitClass.WARRIOR:
			_draw_warrior_enhanced(image, palette, rarity_color, unit_data.star_rating, seed_hash, frame)
		UnitClass.MAGE:
			_draw_mage_enhanced(image, palette, rarity_color, unit_data.star_rating, seed_hash, frame)
		UnitClass.CLERIC:
			_draw_cleric_enhanced(image, palette, rarity_color, unit_data.star_rating, seed_hash, frame)
		UnitClass.KNIGHT, UnitClass.PALADIN:
			_draw_knight_enhanced(image, palette, rarity_color, unit_data.star_rating, seed_hash, frame)
		UnitClass.TANK:
			_draw_tank_enhanced(image, palette, rarity_color, unit_data.star_rating, seed_hash, frame)
		UnitClass.IMP:
			_draw_imp_enhanced(image, palette, rarity_color, unit_data.star_rating, seed_hash, frame)
		UnitClass.SPRITE, UnitClass.WISP:
			_draw_sprite_enhanced(image, palette, rarity_color, unit_data.star_rating, seed_hash, frame)
		UnitClass.SCOUT, UnitClass.ASSASSIN:
			_draw_scout_enhanced(image, palette, rarity_color, unit_data.star_rating, seed_hash, frame)
		UnitClass.ARCHER:
			_draw_archer_enhanced(image, palette, rarity_color, unit_data.star_rating, seed_hash, frame)
		_:
			_draw_generic_enhanced(image, palette, rarity_color, unit_data.star_rating, seed_hash, frame)

	# Add outline pass
	_add_outline(image, Color(0.08, 0.06, 0.1))

	# Add rarity glow for 5-star
	if unit_data.star_rating >= 5:
		_add_glow(image, rarity_color, 2)
	elif unit_data.star_rating >= 4:
		_add_subtle_glow(image, rarity_color)

	var texture = ImageTexture.create_from_image(image)
	texture_cache[cache_key] = texture
	return texture

static func _determine_class(unit_id: String) -> UnitClass:
	var id_lower = unit_id.to_lower()
	if "warrior" in id_lower:
		return UnitClass.WARRIOR
	elif "mage" in id_lower:
		return UnitClass.MAGE
	elif "cleric" in id_lower or "healer" in id_lower or "priest" in id_lower:
		return UnitClass.CLERIC
	elif "paladin" in id_lower:
		return UnitClass.PALADIN
	elif "knight" in id_lower:
		return UnitClass.KNIGHT
	elif "tank" in id_lower or "guardian" in id_lower:
		return UnitClass.TANK
	elif "imp" in id_lower or "demon" in id_lower:
		return UnitClass.IMP
	elif "sprite" in id_lower or "fairy" in id_lower:
		return UnitClass.SPRITE
	elif "wisp" in id_lower or "ghost" in id_lower or "spirit" in id_lower:
		return UnitClass.WISP
	elif "scout" in id_lower or "rogue" in id_lower:
		return UnitClass.SCOUT
	elif "assassin" in id_lower or "ninja" in id_lower:
		return UnitClass.ASSASSIN
	elif "archer" in id_lower or "ranger" in id_lower or "hunter" in id_lower:
		return UnitClass.ARCHER
	return UnitClass.GENERIC

static func _hash_string(s: String) -> int:
	var h = 0
	for c in s:
		h = (h * 31 + c.unicode_at(0)) % 2147483647
	return h

static func _create_placeholder_texture() -> ImageTexture:
	var image = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.5, 0.5, 0.5, 1))
	return ImageTexture.create_from_image(image)

# === COLOR UTILITIES ===

static func _shade(color: Color, amount: float = 0.3) -> Color:
	return color.darkened(amount)

static func _highlight(color: Color, amount: float = 0.25) -> Color:
	return color.lightened(amount)

static func _get_hair_color(seed_hash: int) -> Color:
	return HAIR_COLORS[seed_hash % HAIR_COLORS.size()]

static func _get_skin_variant(base_skin: Color, seed_hash: int) -> Color:
	var variants = [
		base_skin,
		base_skin.darkened(0.15),
		base_skin.lightened(0.1),
		Color(0.55, 0.4, 0.3),  # Tan
		Color(0.4, 0.28, 0.2),  # Dark
		Color(0.95, 0.85, 0.75),  # Pale
	]
	return variants[seed_hash % variants.size()]

# === DRAWING PRIMITIVES ===

static func _set_pixel(image: Image, x: int, y: int, color: Color):
	if x >= 0 and x < SPRITE_SIZE and y >= 0 and y < SPRITE_SIZE:
		if color.a > 0:
			image.set_pixel(x, y, color)

static func _get_pixel(image: Image, x: int, y: int) -> Color:
	if x >= 0 and x < SPRITE_SIZE and y >= 0 and y < SPRITE_SIZE:
		return image.get_pixel(x, y)
	return Color(0, 0, 0, 0)

static func _draw_rect_filled(image: Image, x: int, y: int, w: int, h: int, color: Color):
	for px in range(x, x + w):
		for py in range(y, y + h):
			_set_pixel(image, px, py, color)

static func _draw_rect_shaded(image: Image, x: int, y: int, w: int, h: int, base_color: Color, light_dir: Vector2 = Vector2(-1, -1)):
	# Draw with 3-tone shading
	var highlight = _highlight(base_color)
	var shadow = _shade(base_color)

	for px in range(x, x + w):
		for py in range(y, y + h):
			var local_x = px - x
			var local_y = py - y

			# Determine shading based on position
			var shade_factor = 0.0
			if light_dir.x < 0:
				shade_factor += float(local_x) / float(w) * 0.5
			else:
				shade_factor += (1.0 - float(local_x) / float(w)) * 0.5
			if light_dir.y < 0:
				shade_factor += float(local_y) / float(h) * 0.5
			else:
				shade_factor += (1.0 - float(local_y) / float(h)) * 0.5

			var final_color: Color
			if shade_factor < 0.3:
				final_color = highlight
			elif shade_factor > 0.7:
				final_color = shadow
			else:
				final_color = base_color

			_set_pixel(image, px, py, final_color)

static func _draw_circle_filled(image: Image, cx: int, cy: int, radius: int, color: Color):
	for x in range(cx - radius, cx + radius + 1):
		for y in range(cy - radius, cy + radius + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= radius * radius:
				_set_pixel(image, x, y, color)

static func _draw_circle_shaded(image: Image, cx: int, cy: int, radius: int, base_color: Color):
	var highlight = _highlight(base_color, 0.3)
	var shadow = _shade(base_color, 0.35)

	for x in range(cx - radius, cx + radius + 1):
		for y in range(cy - radius, cy + radius + 1):
			var dist_sq = (x - cx) * (x - cx) + (y - cy) * (y - cy)
			if dist_sq <= radius * radius:
				# Spherical shading - light from top-left
				var nx = float(x - cx) / float(radius)
				var ny = float(y - cy) / float(radius)
				var shade = -nx * 0.5 - ny * 0.5 + 0.5

				var final_color: Color
				if shade > 0.65:
					final_color = highlight
				elif shade < 0.35:
					final_color = shadow
				else:
					final_color = base_color

				_set_pixel(image, x, y, final_color)

static func _draw_ellipse_shaded(image: Image, cx: int, cy: int, rx: int, ry: int, base_color: Color):
	var highlight = _highlight(base_color, 0.3)
	var shadow = _shade(base_color, 0.35)

	for x in range(cx - rx, cx + rx + 1):
		for y in range(cy - ry, cy + ry + 1):
			var nx = float(x - cx) / float(rx)
			var ny = float(y - cy) / float(ry)
			if nx * nx + ny * ny <= 1.0:
				var shade = -nx * 0.5 - ny * 0.5 + 0.5
				var final_color: Color
				if shade > 0.65:
					final_color = highlight
				elif shade < 0.35:
					final_color = shadow
				else:
					final_color = base_color
				_set_pixel(image, x, y, final_color)

# === POST-PROCESSING ===

static func _add_outline(image: Image, outline_color: Color):
	# Create a copy to read from while writing
	var outline_pixels: Array = []

	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			var current = _get_pixel(image, x, y)
			if current.a < 0.5:
				# Check if any neighbor has content
				var has_neighbor = false
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var neighbor = _get_pixel(image, x + dx, y + dy)
						if neighbor.a > 0.5:
							has_neighbor = true
							break
					if has_neighbor:
						break
				if has_neighbor:
					outline_pixels.append(Vector2i(x, y))

	# Apply outline
	for pos in outline_pixels:
		_set_pixel(image, pos.x, pos.y, outline_color)

static func _add_glow(image: Image, glow_color: Color, radius: int = 2):
	var glow_pixels: Array = []

	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			var current = _get_pixel(image, x, y)
			if current.a < 0.1:
				# Check distance to nearest pixel
				var min_dist = radius + 1
				for dx in range(-radius, radius + 1):
					for dy in range(-radius, radius + 1):
						var neighbor = _get_pixel(image, x + dx, y + dy)
						if neighbor.a > 0.5:
							var dist = sqrt(dx * dx + dy * dy)
							if dist < min_dist:
								min_dist = dist
				if min_dist <= radius:
					var alpha = (1.0 - min_dist / float(radius)) * 0.6
					glow_pixels.append({"pos": Vector2i(x, y), "alpha": alpha})

	for glow in glow_pixels:
		var c = glow_color
		c.a = glow["alpha"]
		_set_pixel(image, glow["pos"].x, glow["pos"].y, c)

static func _add_subtle_glow(image: Image, glow_color: Color):
	# Single pixel glow around character
	var glow_pixels: Array = []

	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			var current = _get_pixel(image, x, y)
			if current.a < 0.1:
				var has_neighbor = false
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var neighbor = _get_pixel(image, x + dx, y + dy)
						if neighbor.a > 0.5:
							has_neighbor = true
							break
					if has_neighbor:
						break
				if has_neighbor:
					glow_pixels.append(Vector2i(x, y))

	for pos in glow_pixels:
		var existing = _get_pixel(image, pos.x, pos.y)
		if existing.a < 0.1:
			var c = glow_color
			c.a = 0.3
			_set_pixel(image, pos.x, pos.y, c)

# === BODY PART DRAWING ===

static func _draw_head(image: Image, cx: int, cy: int, skin: Color, hair_color: Color, seed_hash: int, show_face: bool = true):
	# Draw head with shading
	_draw_circle_shaded(image, cx, cy, 5, skin)

	# Hair style based on seed
	var hair_style = seed_hash % 6
	match hair_style:
		0:  # Short spiky
			_draw_rect_filled(image, cx - 5, cy - 5, 10, 4, hair_color)
			_set_pixel(image, cx - 3, cy - 6, hair_color)
			_set_pixel(image, cx, cy - 6, hair_color)
			_set_pixel(image, cx + 2, cy - 6, hair_color)
		1:  # Long
			_draw_rect_filled(image, cx - 5, cy - 5, 10, 5, hair_color)
			_draw_rect_filled(image, cx - 5, cy, 2, 5, hair_color)
			_draw_rect_filled(image, cx + 3, cy, 2, 5, hair_color)
		2:  # Bald/shaved (just highlights)
			_draw_rect_filled(image, cx - 4, cy - 5, 8, 2, _highlight(skin, 0.1))
		3:  # Mohawk
			_draw_rect_filled(image, cx - 1, cy - 7, 3, 4, hair_color)
			_draw_rect_filled(image, cx - 2, cy - 5, 5, 2, hair_color)
		4:  # Side part
			_draw_rect_filled(image, cx - 5, cy - 5, 10, 4, hair_color)
			_draw_rect_filled(image, cx + 2, cy - 4, 3, 2, _shade(hair_color))
		5:  # Ponytail
			_draw_rect_filled(image, cx - 5, cy - 5, 10, 4, hair_color)
			_draw_rect_filled(image, cx + 3, cy - 3, 3, 8, hair_color)

	if show_face:
		# Eyes
		_set_pixel(image, cx - 2, cy - 1, Color(0.1, 0.1, 0.15))
		_set_pixel(image, cx + 2, cy - 1, Color(0.1, 0.1, 0.15))
		# Eye highlights
		_set_pixel(image, cx - 2, cy - 2, Color(1, 1, 1, 0.8))
		_set_pixel(image, cx + 2, cy - 2, Color(1, 1, 1, 0.8))
		# Mouth
		_set_pixel(image, cx - 1, cy + 2, _shade(skin, 0.2))
		_set_pixel(image, cx, cy + 2, _shade(skin, 0.2))
		_set_pixel(image, cx + 1, cy + 2, _shade(skin, 0.2))

static func _draw_armored_head(image: Image, cx: int, cy: int, armor_color: Color, accent: Color, has_plume: bool = false):
	# Helmet base
	_draw_rect_shaded(image, cx - 5, cy - 5, 10, 10, armor_color)

	# Visor slit
	_draw_rect_filled(image, cx - 3, cy - 1, 6, 2, Color(0.05, 0.05, 0.1))

	# Eye glow through visor
	_set_pixel(image, cx - 2, cy - 1, Color(0.8, 0.9, 1.0, 0.8))
	_set_pixel(image, cx + 1, cy - 1, Color(0.8, 0.9, 1.0, 0.8))

	# Helmet crest/ridge
	_draw_rect_filled(image, cx - 1, cy - 6, 2, 2, _highlight(armor_color))

	if has_plume:
		_draw_rect_filled(image, cx - 1, cy - 9, 3, 4, accent)
		_set_pixel(image, cx, cy - 10, accent)

static func _draw_hooded_head(image: Image, cx: int, cy: int, skin: Color, hood_color: Color, show_lower_face: bool = true):
	# Hood
	_draw_rect_shaded(image, cx - 6, cy - 6, 12, 9, hood_color)
	_draw_rect_filled(image, cx - 5, cy - 7, 10, 2, hood_color)

	# Face in shadow
	_draw_circle_filled(image, cx, cy, 4, _shade(skin, 0.2))

	# Eyes gleaming from shadow
	_set_pixel(image, cx - 2, cy - 1, Color(0.9, 0.95, 1.0))
	_set_pixel(image, cx + 2, cy - 1, Color(0.9, 0.95, 1.0))

	if show_lower_face:
		# Lower face visible
		_draw_rect_filled(image, cx - 3, cy + 1, 6, 3, skin)

static func _draw_body_armored(image: Image, cx: int, cy: int, armor_color: Color, accent: Color):
	# Torso plate
	_draw_rect_shaded(image, cx - 6, cy, 12, 10, armor_color)

	# Chest emblem/detail
	_draw_rect_filled(image, cx - 2, cy + 2, 4, 4, accent)

	# Pauldrons
	_draw_rect_shaded(image, cx - 8, cy, 3, 4, armor_color)
	_draw_rect_shaded(image, cx + 5, cy, 3, 4, armor_color)

	# Belt
	_draw_rect_filled(image, cx - 5, cy + 8, 10, 2, _shade(armor_color, 0.4))

static func _draw_body_robed(image: Image, cx: int, cy: int, robe_color: Color, trim_color: Color):
	# Main robe
	_draw_rect_shaded(image, cx - 5, cy, 10, 14, robe_color)

	# Robe flare at bottom
	_draw_rect_shaded(image, cx - 7, cy + 10, 14, 5, robe_color)

	# Center trim
	_draw_rect_filled(image, cx - 1, cy + 1, 2, 12, trim_color)

	# Collar
	_draw_rect_filled(image, cx - 3, cy, 6, 2, trim_color)

static func _draw_arms(image: Image, cx: int, cy: int, arm_color: Color, hand_color: Color, pose: int = 0):
	match pose:
		0:  # Idle - arms at sides
			_draw_rect_shaded(image, cx - 10, cy + 2, 4, 8, arm_color)
			_draw_rect_shaded(image, cx + 6, cy + 2, 4, 8, arm_color)
			_draw_rect_filled(image, cx - 10, cy + 9, 3, 3, hand_color)
			_draw_rect_filled(image, cx + 7, cy + 9, 3, 3, hand_color)
		1:  # Arms raised (attack)
			_draw_rect_shaded(image, cx - 10, cy - 2, 4, 8, arm_color)
			_draw_rect_shaded(image, cx + 6, cy - 4, 4, 8, arm_color)
			_draw_rect_filled(image, cx - 10, cy - 3, 3, 3, hand_color)
			_draw_rect_filled(image, cx + 7, cy - 5, 3, 3, hand_color)
		2:  # One arm forward (casting)
			_draw_rect_shaded(image, cx - 10, cy + 2, 4, 8, arm_color)
			_draw_rect_shaded(image, cx + 6, cy, 8, 4, arm_color)
			_draw_rect_filled(image, cx - 10, cy + 9, 3, 3, hand_color)
			_draw_rect_filled(image, cx + 12, cy, 3, 3, hand_color)

static func _draw_legs(image: Image, cx: int, cy: int, leg_color: Color, boot_color: Color, stance: int = 0):
	match stance:
		0:  # Normal stance
			_draw_rect_shaded(image, cx - 4, cy, 4, 8, leg_color)
			_draw_rect_shaded(image, cx, cy, 4, 8, leg_color)
			_draw_rect_filled(image, cx - 5, cy + 7, 5, 3, boot_color)
			_draw_rect_filled(image, cx, cy + 7, 5, 3, boot_color)
		1:  # Wide stance
			_draw_rect_shaded(image, cx - 6, cy, 4, 8, leg_color)
			_draw_rect_shaded(image, cx + 2, cy, 4, 8, leg_color)
			_draw_rect_filled(image, cx - 7, cy + 7, 5, 3, boot_color)
			_draw_rect_filled(image, cx + 2, cy + 7, 5, 3, boot_color)

# === WEAPON DRAWING ===

static func _draw_sword(image: Image, x: int, y: int, blade_color: Color, hilt_color: Color, length: int = 12):
	# Blade
	_draw_rect_filled(image, x, y, 2, length, blade_color)
	_set_pixel(image, x, y, _highlight(blade_color))  # Tip highlight
	# Edge highlight
	for i in range(length):
		_set_pixel(image, x, y + i, _highlight(blade_color, 0.2))
	# Hilt
	_draw_rect_filled(image, x - 2, y + length, 6, 2, hilt_color)
	# Pommel
	_set_pixel(image, x, y + length + 2, hilt_color)
	_set_pixel(image, x + 1, y + length + 2, hilt_color)

static func _draw_staff(image: Image, x: int, y: int, wood_color: Color, orb_color: Color):
	# Shaft
	_draw_rect_filled(image, x, y + 4, 2, 16, wood_color)
	_draw_rect_filled(image, x, y + 4, 1, 16, _highlight(wood_color))  # Highlight
	# Orb
	_draw_circle_shaded(image, x + 1, y + 2, 3, orb_color)
	# Orb glow
	_set_pixel(image, x, y + 1, _highlight(orb_color, 0.5))

static func _draw_shield(image: Image, x: int, y: int, shield_color: Color, emblem_color: Color, size: int = 8):
	# Shield body
	_draw_rect_shaded(image, x, y, size, size + 2, shield_color)
	# Shield point at bottom
	_draw_rect_filled(image, x + 2, y + size + 2, size - 4, 2, shield_color)
	_set_pixel(image, x + size/2, y + size + 4, shield_color)
	# Emblem
	_draw_rect_filled(image, x + 2, y + 2, size - 4, size - 2, emblem_color)
	# Highlight
	_draw_rect_filled(image, x, y, 1, size, _highlight(shield_color, 0.3))

static func _draw_bow(image: Image, x: int, y: int, wood_color: Color):
	# Bow curve (simplified as pixels)
	_set_pixel(image, x + 2, y, wood_color)
	_set_pixel(image, x + 1, y + 1, wood_color)
	_set_pixel(image, x, y + 2, wood_color)
	_set_pixel(image, x, y + 3, wood_color)
	_set_pixel(image, x, y + 4, wood_color)
	_set_pixel(image, x, y + 5, wood_color)
	_set_pixel(image, x, y + 6, wood_color)
	_set_pixel(image, x + 1, y + 7, wood_color)
	_set_pixel(image, x + 2, y + 8, wood_color)
	# String
	var string_color = Color(0.8, 0.8, 0.7)
	for i in range(9):
		_set_pixel(image, x + 3, y + i, string_color)

static func _draw_daggers(image: Image, x1: int, y1: int, x2: int, y2: int, blade_color: Color):
	# Left dagger
	_draw_rect_filled(image, x1, y1, 2, 6, blade_color)
	_set_pixel(image, x1, y1, _highlight(blade_color))
	# Right dagger
	_draw_rect_filled(image, x2, y2, 2, 6, blade_color)
	_set_pixel(image, x2, y2, _highlight(blade_color))

# === ENHANCED CHARACTER TEMPLATES ===

static func _draw_warrior_enhanced(image: Image, palette: Array, rarity_color: Color, stars: int, seed_hash: int, frame: AnimFrame):
	var primary = palette[0]
	var secondary = palette[1]
	var accent = palette[2]
	var skin = _get_skin_variant(palette[3], seed_hash)
	var hair = _get_hair_color(seed_hash)

	var y_offset = 0
	if frame == AnimFrame.ATTACK:
		y_offset = -1
	elif frame == AnimFrame.HURT:
		y_offset = 1

	# Legs
	_draw_legs(image, 16, 22 + y_offset, secondary, _shade(secondary, 0.4), 1)

	# Body (armored)
	_draw_body_armored(image, 16, 12 + y_offset, primary, accent)

	# Arms
	var arm_pose = 0 if frame == AnimFrame.IDLE else 1
	_draw_arms(image, 16, 12 + y_offset, primary, skin, arm_pose)

	# Sword
	var sword_y = 6 if frame == AnimFrame.ATTACK else 10
	_draw_sword(image, 24, sword_y + y_offset, Color(0.75, 0.78, 0.82), Color(0.45, 0.35, 0.25), 14)

	# Head
	if stars >= 4:
		_draw_armored_head(image, 16, 7 + y_offset, primary, accent, stars >= 5)
	else:
		_draw_head(image, 16, 7 + y_offset, skin, hair, seed_hash)

static func _draw_mage_enhanced(image: Image, palette: Array, rarity_color: Color, stars: int, seed_hash: int, frame: AnimFrame):
	var primary = palette[0]
	var secondary = palette[1]
	var accent = palette[2]
	var skin = _get_skin_variant(palette[3], seed_hash)
	var hair = _get_hair_color(seed_hash)

	var y_offset = 0
	if frame == AnimFrame.ATTACK:
		y_offset = -1

	# Body (robed)
	_draw_body_robed(image, 16, 13 + y_offset, primary, secondary)

	# Arms - casting pose for attack
	var arm_pose = 2 if frame == AnimFrame.ATTACK else 0
	_draw_arms(image, 16, 13 + y_offset, primary, skin, arm_pose)

	# Staff
	_draw_staff(image, 4, 4 + y_offset, Color(0.5, 0.35, 0.2), accent)

	# Head with hood or hat
	if stars >= 4:
		_draw_hooded_head(image, 16, 8 + y_offset, skin, primary, true)
	else:
		_draw_head(image, 16, 8 + y_offset, skin, hair, seed_hash)
		# Wizard hat
		_draw_rect_filled(image, 11, 2 + y_offset, 10, 4, primary)
		_draw_rect_filled(image, 14, 0 + y_offset, 4, 3, primary)

	# Magic particles for casting
	if frame == AnimFrame.ATTACK or stars >= 4:
		_set_pixel(image, 20, 10 + y_offset, accent)
		_set_pixel(image, 22, 8 + y_offset, _highlight(accent))
		_set_pixel(image, 19, 6 + y_offset, accent)
		if frame == AnimFrame.ATTACK:
			_set_pixel(image, 24, 6 + y_offset, _highlight(accent))
			_set_pixel(image, 26, 9 + y_offset, accent)

static func _draw_cleric_enhanced(image: Image, palette: Array, rarity_color: Color, stars: int, seed_hash: int, frame: AnimFrame):
	var primary = palette[0]
	@warning_ignore("unused_variable")
	var secondary = palette[1]
	@warning_ignore("unused_variable")
	var accent = palette[2]
	var skin = _get_skin_variant(palette[3], seed_hash)
	var white = Color(0.95, 0.93, 0.88)

	var y_offset = 0
	if frame == AnimFrame.ATTACK:
		y_offset = -1

	# White robes with element trim
	_draw_body_robed(image, 16, 12 + y_offset, white, primary)

	# Arms
	_draw_arms(image, 16, 12 + y_offset, white, skin, 0)

	# Holy staff
	_draw_rect_filled(image, 25, 5 + y_offset, 2, 18, Color(0.85, 0.8, 0.5))
	# Cross on staff
	_draw_rect_filled(image, 23, 7 + y_offset, 6, 2, Color(0.85, 0.8, 0.5))

	# Head with hood
	_draw_hooded_head(image, 16, 7 + y_offset, skin, white, true)

	# Halo for 5-star
	if stars >= 5:
		_draw_circle_filled(image, 16, 1 + y_offset, 3, Color(1, 0.95, 0.6, 0.8))
		_draw_circle_filled(image, 16, 1 + y_offset, 1, Color(0, 0, 0, 0))

	# Healing particles
	if frame == AnimFrame.ATTACK:
		_set_pixel(image, 12, 15 + y_offset, Color(0.5, 1, 0.6, 0.9))
		_set_pixel(image, 20, 18 + y_offset, Color(0.5, 1, 0.6, 0.9))
		_set_pixel(image, 14, 20 + y_offset, Color(0.5, 1, 0.6, 0.9))

static func _draw_knight_enhanced(image: Image, palette: Array, rarity_color: Color, stars: int, seed_hash: int, frame: AnimFrame):
	var primary = palette[0]
	@warning_ignore("unused_variable")
	var secondary = palette[1]
	var accent = palette[2]
	var metal = Color(0.65, 0.65, 0.7)
	var dark_metal = Color(0.35, 0.35, 0.4)

	var y_offset = 0
	if frame == AnimFrame.ATTACK:
		y_offset = -1

	# Heavy armored legs
	_draw_legs(image, 16, 22 + y_offset, metal, dark_metal, 1)

	# Heavy plate body
	_draw_body_armored(image, 16, 12 + y_offset, metal, primary)

	# Armored arms
	_draw_arms(image, 16, 12 + y_offset, metal, metal, 0)

	# Shield
	_draw_shield(image, 2, 13 + y_offset, primary, accent, 7)

	# Sword
	_draw_sword(image, 26, 6 + y_offset, Color(0.8, 0.82, 0.85), Color(0.5, 0.4, 0.3), 15)

	# Great helm
	_draw_armored_head(image, 16, 7 + y_offset, metal, primary, stars >= 4)

static func _draw_tank_enhanced(image: Image, palette: Array, rarity_color: Color, stars: int, seed_hash: int, frame: AnimFrame):
	var primary = palette[0]
	var secondary = palette[1]
	var accent = palette[2]
	var skin = _get_skin_variant(palette[3], seed_hash)

	var y_offset = 0
	if frame == AnimFrame.HURT:
		y_offset = 1

	# Thick legs
	_draw_rect_shaded(image, 9, 22 + y_offset, 6, 9, secondary)
	_draw_rect_shaded(image, 17, 22 + y_offset, 6, 9, secondary)

	# Massive body
	_draw_rect_shaded(image, 6, 11 + y_offset, 20, 12, primary)
	_draw_rect_shaded(image, 9, 13 + y_offset, 14, 8, secondary)

	# Huge arms
	_draw_rect_shaded(image, 1, 11 + y_offset, 5, 12, primary)
	_draw_rect_shaded(image, 26, 11 + y_offset, 5, 12, primary)
	_draw_rect_filled(image, 0, 21 + y_offset, 4, 4, skin)
	_draw_rect_filled(image, 28, 21 + y_offset, 4, 4, skin)

	# Small head
	_draw_circle_shaded(image, 16, 7 + y_offset, 4, skin)
	_set_pixel(image, 14, 6 + y_offset, Color(0.15, 0.15, 0.2))
	_set_pixel(image, 18, 6 + y_offset, Color(0.15, 0.15, 0.2))

	# Helmet
	_draw_rect_shaded(image, 11, 2 + y_offset, 10, 5, primary)

	# Giant shield for high rarity
	if stars >= 4:
		_draw_shield(image, 0, 9 + y_offset, accent, primary, 6)

static func _draw_imp_enhanced(image: Image, palette: Array, rarity_color: Color, stars: int, seed_hash: int, frame: AnimFrame):
	var primary = palette[0]
	var secondary = palette[1]
	var accent = palette[2]
	var skin = primary.lerp(Color(0.85, 0.55, 0.55), 0.35)

	var y_offset = 0
	if frame == AnimFrame.ATTACK:
		y_offset = -2

	# Small body
	_draw_ellipse_shaded(image, 16, 20 + y_offset, 5, 6, skin)

	# Short legs
	_draw_rect_filled(image, 12, 25 + y_offset, 3, 5, skin)
	_draw_rect_filled(image, 17, 25 + y_offset, 3, 5, skin)

	# Thin arms
	_draw_rect_filled(image, 8, 18 + y_offset, 3, 6, skin)
	_draw_rect_filled(image, 21, 18 + y_offset, 3, 6, skin)

	# Big head
	_draw_circle_shaded(image, 16, 11 + y_offset, 7, skin)

	# Horns
	_draw_rect_filled(image, 8, 4 + y_offset, 2, 6, secondary)
	_draw_rect_filled(image, 22, 4 + y_offset, 2, 6, secondary)
	_set_pixel(image, 8, 3 + y_offset, _highlight(secondary))
	_set_pixel(image, 22, 3 + y_offset, _highlight(secondary))

	# Big mischievous eyes
	_draw_circle_filled(image, 13, 10 + y_offset, 2, Color.WHITE)
	_draw_circle_filled(image, 19, 10 + y_offset, 2, Color.WHITE)
	_set_pixel(image, 13, 10 + y_offset, accent)
	_set_pixel(image, 19, 10 + y_offset, accent)

	# Grin
	_draw_rect_filled(image, 12, 15 + y_offset, 8, 1, Color(0.15, 0.08, 0.08))
	_set_pixel(image, 11, 14 + y_offset, Color(0.15, 0.08, 0.08))
	_set_pixel(image, 20, 14 + y_offset, Color(0.15, 0.08, 0.08))

	# Tail
	_draw_rect_filled(image, 21, 21 + y_offset, 6, 2, skin)
	_draw_rect_filled(image, 26, 19 + y_offset, 2, 3, secondary)

	# Fire in hand for attack
	if frame == AnimFrame.ATTACK:
		_set_pixel(image, 7, 16 + y_offset, accent)
		_set_pixel(image, 6, 15 + y_offset, Color(1, 0.9, 0.3))
		_set_pixel(image, 8, 14 + y_offset, accent)

static func _draw_sprite_enhanced(image: Image, palette: Array, rarity_color: Color, stars: int, seed_hash: int, frame: AnimFrame):
	var primary = palette[0]
	var accent = palette[2]
	var glow = primary.lightened(0.45)
	var inner_glow = accent.lightened(0.3)

	var y_offset = 0
	if frame == AnimFrame.ATTACK:
		y_offset = -2

	# Ethereal body
	_draw_circle_shaded(image, 16, 15 + y_offset, 7, glow)
	_draw_circle_filled(image, 16, 14 + y_offset, 4, primary)
	_draw_circle_filled(image, 16, 13 + y_offset, 2, inner_glow)

	# Eyes
	_set_pixel(image, 14, 13 + y_offset, Color.WHITE)
	_set_pixel(image, 18, 13 + y_offset, Color.WHITE)

	# Wings
	var wing_color = glow
	wing_color.a = 0.75
	# Left wing
	_draw_ellipse_shaded(image, 7, 13 + y_offset, 4, 6, wing_color)
	# Right wing
	_draw_ellipse_shaded(image, 25, 13 + y_offset, 4, 6, wing_color)

	# Sparkles
	var sparkle_positions = [
		Vector2i(5, 7), Vector2i(27, 8), Vector2i(8, 22), Vector2i(24, 21),
		Vector2i(16, 5), Vector2i(3, 15), Vector2i(29, 14)
	]
	for i in range(sparkle_positions.size()):
		if (seed_hash + i) % 3 == 0 or stars >= 4:
			var sp = sparkle_positions[i]
			_set_pixel(image, sp.x, sp.y + y_offset, Color.WHITE)

	# Extra sparkles for attack
	if frame == AnimFrame.ATTACK:
		_set_pixel(image, 12, 8 + y_offset, accent)
		_set_pixel(image, 20, 9 + y_offset, accent)
		_set_pixel(image, 16, 6 + y_offset, _highlight(accent))

static func _draw_scout_enhanced(image: Image, palette: Array, rarity_color: Color, stars: int, seed_hash: int, frame: AnimFrame):
	var primary = palette[0]
	var secondary = palette[1]
	var accent = palette[2]
	var skin = _get_skin_variant(palette[3], seed_hash)
	var cloak = secondary.darkened(0.25)

	var y_offset = 0
	if frame == AnimFrame.ATTACK:
		y_offset = -1

	# Agile legs
	_draw_legs(image, 16, 22 + y_offset, secondary, _shade(secondary, 0.4), 0)

	# Slim body under cloak
	_draw_rect_shaded(image, 11, 13 + y_offset, 10, 10, secondary)

	# Cloak
	_draw_rect_shaded(image, 8, 11 + y_offset, 16, 14, cloak)
	# Cloak tattered edge
	_set_pixel(image, 7, 24 + y_offset, cloak)
	_set_pixel(image, 24, 23 + y_offset, cloak)

	# Arms under cloak
	_draw_rect_filled(image, 6, 14 + y_offset, 3, 7, cloak)
	_draw_rect_filled(image, 23, 14 + y_offset, 3, 7, cloak)
	_draw_rect_filled(image, 5, 19 + y_offset, 3, 3, skin)
	_draw_rect_filled(image, 24, 19 + y_offset, 3, 3, skin)

	# Daggers
	_draw_daggers(image, 3, 16 + y_offset, 27, 16 + y_offset, Color(0.72, 0.74, 0.78))

	# Hooded head
	_draw_hooded_head(image, 16, 7 + y_offset, skin, cloak, false)

	# Mask
	_draw_rect_filled(image, 12, 9 + y_offset, 8, 3, secondary)

static func _draw_archer_enhanced(image: Image, palette: Array, rarity_color: Color, stars: int, seed_hash: int, frame: AnimFrame):
	var primary = palette[0]
	var secondary = palette[1]
	var accent = palette[2]
	var skin = _get_skin_variant(palette[3], seed_hash)
	var hair = _get_hair_color(seed_hash)

	var y_offset = 0
	if frame == AnimFrame.ATTACK:
		y_offset = -1

	# Legs
	_draw_legs(image, 16, 22 + y_offset, secondary, _shade(secondary, 0.4), 0)

	# Light armor body
	_draw_rect_shaded(image, 11, 13 + y_offset, 10, 10, primary)
	_draw_rect_filled(image, 13, 14 + y_offset, 6, 8, secondary)

	# Arms
	_draw_arms(image, 16, 13 + y_offset, primary, skin, 0)

	# Bow
	_draw_bow(image, 3, 10 + y_offset, Color(0.5, 0.35, 0.2))

	# Quiver on back
	_draw_rect_filled(image, 22, 12 + y_offset, 3, 10, Color(0.45, 0.3, 0.18))
	_draw_rect_filled(image, 22, 10 + y_offset, 1, 3, Color(0.6, 0.6, 0.65))  # Arrow tips
	_draw_rect_filled(image, 24, 10 + y_offset, 1, 3, Color(0.6, 0.6, 0.65))

	# Head
	_draw_head(image, 16, 8 + y_offset, skin, hair, seed_hash)

	# Headband
	_draw_rect_filled(image, 10, 5 + y_offset, 12, 2, accent)

static func _draw_generic_enhanced(image: Image, palette: Array, rarity_color: Color, stars: int, seed_hash: int, frame: AnimFrame):
	var primary = palette[0]
	var secondary = palette[1]
	var accent = palette[2]
	var skin = _get_skin_variant(palette[3], seed_hash)
	var hair = _get_hair_color(seed_hash)

	var y_offset = 0
	if frame == AnimFrame.HURT:
		y_offset = 1

	# Legs
	_draw_legs(image, 16, 22 + y_offset, secondary, _shade(secondary, 0.4), 0)

	# Simple clothed body
	_draw_rect_shaded(image, 10, 13 + y_offset, 12, 10, primary)

	# Arms
	_draw_arms(image, 16, 13 + y_offset, primary, skin, 0)

	# Head
	_draw_head(image, 16, 8 + y_offset, skin, hair, seed_hash)

# Clear the cache (call when needed)
static func clear_cache():
	texture_cache.clear()
	anim_cache.clear()
