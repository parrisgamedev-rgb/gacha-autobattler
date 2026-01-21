# v0.5 Auto-Battle & UI Overhaul Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add auto-battle with speed controls and overhaul all UI screens with a consistent design system.

**Architecture:** Create a UITheme autoload for design constants, implement auto-battle logic in battle.gd, then systematically update each screen's .tscn and .gd files to match the new design system.

**Tech Stack:** Godot 4.5, GDScript

---

## Task 1: Create UITheme Autoload

**Files:**
- Create: `scripts/core/ui_theme.gd`
- Modify: `project.godot` (add autoload)

**Step 1: Create the UITheme script**

Create `scripts/core/ui_theme.gd`:

```gdscript
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
```

**Step 2: Add autoload to project.godot**

Add to autoload section of `project.godot`:
```
[autoload]
UITheme="*res://scripts/core/ui_theme.gd"
```

**Step 3: Verify**

Run the game, open any screen - no errors should occur.

**Step 4: Commit**

```bash
git add scripts/core/ui_theme.gd project.godot
git commit -m "feat: add UITheme autoload with design system constants"
```

---

## Task 2: Add Auto-Battle and Speed Controls to Battle

**Files:**
- Modify: `scripts/battle/battle.gd`
- Modify: `scenes/battle/battle.tscn`

**Step 1: Add auto-battle variables and speed control to battle.gd**

Add these variables after line 38 (after `var actions_remaining`):

```gdscript
# Auto-battle settings
var auto_battle_enabled: bool = false
var battle_speed: float = 1.0  # 1.0 = normal, 0.5 = 2x, 0.25 = 3x
```

Add these @onready references after line 32 (after `var cheat_menu`):

```gdscript
@onready var auto_button = $UI/BottomBar/AutoButton
@onready var speed_1x_btn = $UI/BottomBar/Speed1xButton
@onready var speed_2x_btn = $UI/BottomBar/Speed2xButton
@onready var speed_3x_btn = $UI/BottomBar/Speed3xButton
```

**Step 2: Add button connections in _ready()**

Add after line 97 (after cheat_menu.setup):

```gdscript
	# Connect auto-battle controls
	if auto_button:
		auto_button.pressed.connect(_on_auto_toggle)
	if speed_1x_btn:
		speed_1x_btn.pressed.connect(_set_battle_speed.bind(1.0))
	if speed_2x_btn:
		speed_2x_btn.pressed.connect(_set_battle_speed.bind(0.5))
	if speed_3x_btn:
		speed_3x_btn.pressed.connect(_set_battle_speed.bind(0.25))
	_update_speed_buttons()
```

**Step 3: Add auto-battle and speed functions**

Add these functions at the end of battle.gd:

```gdscript
# === AUTO-BATTLE SYSTEM ===

func _on_auto_toggle():
	auto_battle_enabled = not auto_battle_enabled
	_update_auto_button()

	if auto_battle_enabled and current_phase == GamePhase.PLAYER_TURN:
		_do_auto_turn()

func _update_auto_button():
	if not auto_button:
		return
	if auto_battle_enabled:
		auto_button.text = "AUTO: ON"
		auto_button.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
	else:
		auto_button.text = "AUTO: OFF"
		auto_button.add_theme_stylebox_override("normal", UITheme.create_button_style(Color.TRANSPARENT, UITheme.TEXT_SECONDARY))

func _set_battle_speed(speed: float):
	battle_speed = speed
	_update_speed_buttons()

func _update_speed_buttons():
	var buttons = [speed_1x_btn, speed_2x_btn, speed_3x_btn]
	var speeds = [1.0, 0.5, 0.25]

	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn:
			if speeds[i] == battle_speed:
				btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
				btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
			else:
				btn.add_theme_stylebox_override("normal", UITheme.create_button_style(Color.TRANSPARENT, UITheme.BG_LIGHT))
				btn.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

func _do_auto_turn():
	if current_phase != GamePhase.PLAYER_TURN or not auto_battle_enabled:
		return

	print("Auto-battle taking turn...")

	# Get available units and cells
	var available_cells = _get_cells_without_player()
	var available_units = player_units.filter(func(u): return u.can_act() and not u.is_placed())

	# Place units using AI logic
	var auto_actions = min(actions_remaining, min(available_cells.size(), available_units.size()))

	for i in range(auto_actions):
		if available_cells.is_empty() or available_units.is_empty():
			break

		# Pick best unit (highest attack)
		available_units.sort_custom(func(a, b): return a.get_attack() > b.get_attack())
		var unit = available_units.pop_front()

		# Pick best cell using same logic as enemy AI
		var cell = _select_cell_for_auto(available_cells)
		available_cells.erase(cell)

		# Select best ability (highest damage multiplier, or heal if low HP)
		_select_best_ability(unit)

		# Queue the placement
		_queue_placement(unit, cell.row, cell.col)

		await get_tree().create_timer(0.2 * battle_speed).timeout

	# End turn automatically
	await get_tree().create_timer(0.3 * battle_speed).timeout
	_on_end_turn_pressed()

func _get_cells_without_player() -> Array:
	var available = []
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if grid_player_units[row][col] == null:
				var is_pending = false
				for p in player_pending_placements:
					if p.row == row and p.col == col:
						is_pending = true
						break
				if not is_pending:
					available.append({"row": row, "col": col})
	return available

func _select_cell_for_auto(available_cells: Array) -> Dictionary:
	if available_cells.is_empty():
		return {}

	# Score cells - prefer cells that help win or block enemy
	var scored_cells = []
	for cell in available_cells:
		var score = _evaluate_cell_for_player(cell.row, cell.col)
		scored_cells.append({"cell": cell, "score": score})

	scored_cells.sort_custom(func(a, b): return a.score > b.score)
	return scored_cells[0].cell

func _evaluate_cell_for_player(row: int, col: int) -> int:
	var score = 0
	var lines = _get_lines_containing_cell(row, col)

	for line in lines:
		var counts = _count_line_ownership(line)

		# Can win: 2 player + 1 empty
		if counts.player == 2 and counts.empty == 1:
			score += 100

		# Block enemy: 2 enemy + 1 empty
		if counts.enemy == 2 and counts.empty == 1:
			score += 90

		# Build line: 1 player + 2 empty
		if counts.player == 1 and counts.empty == 2:
			score += 30

	# Positional bonus
	if row == 1 and col == 1:
		score += 20  # Center
	elif (row == 0 or row == 2) and (col == 0 or col == 2):
		score += 10  # Corner

	return score

func _select_best_ability(unit: UnitInstance):
	if unit.unit_data.abilities.is_empty():
		return

	var best_index = 0
	var best_score = -999

	for i in range(unit.unit_data.abilities.size()):
		if not unit.is_ability_available(i):
			continue

		var ability = unit.unit_data.abilities[i]
		var score = ability.damage_multiplier * 100

		# Bonus for healing if any player unit is low HP
		if ability.heal_amount > 0:
			for p_unit in player_units:
				if p_unit.is_alive() and p_unit.current_hp < p_unit.get_max_hp() * 0.5:
					score += 50
					break

		if score > best_score:
			best_score = score
			best_index = i

	unit.selected_ability_index = best_index

func get_scaled_time(base_time: float) -> float:
	return base_time * battle_speed
```

**Step 4: Update all create_timer calls to use scaled time**

Replace `create_timer(X)` with `create_timer(get_scaled_time(X))` in these locations:
- Line 529: `await get_tree().create_timer(0.5).timeout` → `await get_tree().create_timer(get_scaled_time(0.5)).timeout`
- Line 563: `await get_tree().create_timer(0.5).timeout` → `await get_tree().create_timer(get_scaled_time(0.5)).timeout`
- Line 1112: `await get_tree().create_timer(0.3).timeout` → `await get_tree().create_timer(get_scaled_time(0.3)).timeout`

**Step 5: Trigger auto-battle on new turn**

In `_resolve_turn()`, after line 823 (`current_phase = GamePhase.PLAYER_TURN`), add:

```gdscript
	# Trigger auto-battle if enabled
	if auto_battle_enabled:
		await get_tree().create_timer(get_scaled_time(0.3)).timeout
		_do_auto_turn()
```

**Step 6: Update battle.tscn with auto-battle controls**

Add BottomBar with controls to `scenes/battle/battle.tscn`. The UI node structure should include:

```
UI/
  BottomBar (HBoxContainer)
    AutoButton (Button) - text: "AUTO: OFF"
    SpeedContainer (HBoxContainer)
      Speed1xButton (Button) - text: "1x"
      Speed2xButton (Button) - text: "2x"
      Speed3xButton (Button) - text: "3x"
    Spacer (Control) - h_size_flags: expand
    EndTurnButton (moved here)
```

**Step 7: Verify**

Run a quick battle:
1. Click AUTO button - should toggle ON/OFF
2. When ON, player units place automatically
3. Click speed buttons - should highlight active speed
4. At 3x speed, battles resolve noticeably faster

**Step 8: Commit**

```bash
git add scripts/battle/battle.gd scenes/battle/battle.tscn
git commit -m "feat: add auto-battle with AI placement and 1x/2x/3x speed controls"
```

---

## Task 3: Overhaul Main Menu UI

**Files:**
- Modify: `scripts/ui/main_menu.gd`
- Modify: `scenes/ui/main_menu.tscn`

**Step 1: Update main_menu.tscn structure**

Restructure the scene to match design:
```
MainMenu (Control)
  Background (ColorRect) - color: BG_DARK, full_rect
  VBoxContainer (centered)
    TitleLabel - "GACHA AUTOBATTLER", 32px, bold
    VersionLabel - "v0.5", 14px, muted
    Spacer (32px)
    PrimaryButtons (VBoxContainer, 16px gap)
      CampaignButton - full width, primary style
      DungeonsButton - full width, primary style
      QuickBattleButton - full width, primary style
    Spacer (24px)
    SecondaryButtons (GridContainer, 2 columns, 16px gap)
      SummonButton
      CollectionButton
      GearButton
      PvPButton
  CurrencyBar (HBoxContainer, bottom, 32px margin)
    GoldLabel
    MaterialsLabel
    GemsLabel
    StonesLabel
```

**Step 2: Update main_menu.gd to apply theme**

Add `_apply_theme()` function called from `_ready()`:

```gdscript
func _apply_theme():
	# Background
	var bg = $Background
	if bg:
		bg.color = UITheme.BG_DARK

	# Title
	var title = $VBoxContainer/TitleLabel
	if title:
		title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
		title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Version
	var version = $VBoxContainer/VersionLabel
	if version:
		version.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		version.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Primary buttons
	for btn_name in ["CampaignButton", "DungeonsButton", "QuickBattleButton"]:
		var btn = get_node_or_null("VBoxContainer/PrimaryButtons/" + btn_name)
		if btn:
			_style_primary_button(btn)

	# Secondary buttons
	for btn_name in ["SummonButton", "CollectionButton", "GearButton", "PvPButton"]:
		var btn = get_node_or_null("VBoxContainer/SecondaryButtons/" + btn_name)
		if btn:
			_style_secondary_button(btn)

func _style_primary_button(btn: Button):
	btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
	btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.PRIMARY.lightened(0.1)))
	btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.PRIMARY.darkened(0.1)))
	btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	btn.custom_minimum_size = Vector2(300, 50)

func _style_secondary_button(btn: Button):
	btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_MEDIUM, UITheme.BG_LIGHT))
	btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT))
	btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.BG_MEDIUM.darkened(0.1)))
	btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	btn.custom_minimum_size = Vector2(140, 50)
```

**Step 3: Update currency bar styling**

```gdscript
func _update_currency_display():
	var currencies = [
		{"node": "GoldLabel", "icon": "G", "value": PlayerData.gold, "color": UITheme.GOLD},
		{"node": "MaterialsLabel", "icon": "M", "value": PlayerData.level_materials, "color": UITheme.TEXT_SECONDARY},
		{"node": "GemsLabel", "icon": "D", "value": PlayerData.gems, "color": UITheme.PRIMARY},
		{"node": "StonesLabel", "icon": "S", "value": PlayerData.enhancement_stones, "color": UITheme.SECONDARY}
	]

	for currency in currencies:
		var label = $CurrencyBar.get_node_or_null(currency.node)
		if label:
			label.text = currency.icon + " " + str(currency.value)
			label.add_theme_color_override("font_color", currency.color)
			label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
```

**Step 4: Verify**

Run game - main menu should have:
- Dark navy background
- Centered title with version below
- Blue primary buttons (Campaign, Dungeons, Quick Battle)
- Slate secondary buttons in 2x2 grid
- Currency bar at bottom with colored values

**Step 5: Commit**

```bash
git add scripts/ui/main_menu.gd scenes/ui/main_menu.tscn
git commit -m "feat: overhaul main menu UI with new design system"
```

---

## Task 4: Overhaul Battle Screen UI

**Files:**
- Modify: `scripts/battle/battle.gd`
- Modify: `scenes/battle/battle.tscn`

**Step 1: Update battle.tscn layout**

Restructure UI elements:
```
UI (CanvasLayer)
  TopBar (Panel, 64px height, top anchored)
    TurnLabel (left)
    PhaseLabel (center)
    ActionsLabel (right)
  PlayerRoster (Panel, left side, vertical)
  EnemyRoster (Panel, right side, vertical)
  AbilityPanel (Panel, below grid, horizontal)
    Ability1, Ability2, Ability3 (Buttons)
    AbilityDesc (Label)
  BottomBar (Panel, 80px height, bottom)
    AutoButton
    SpeedContainer
    EndTurnButton
  ResultsPanel (centered modal)
  CombatAnnouncement (centered label)
```

**Step 2: Apply theme to battle UI in _ready()**

Add `_apply_battle_theme()` function:

```gdscript
func _apply_battle_theme():
	# Top bar
	var top_bar = $UI/TopBar
	if top_bar:
		top_bar.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))

	if turn_label:
		turn_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		turn_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	if phase_label:
		phase_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
		phase_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	if actions_label:
		actions_label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		actions_label.add_theme_color_override("font_color", UITheme.PRIMARY)

	# Rosters
	if player_roster:
		player_roster.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_DARK.lightened(0.05)))
	if enemy_roster:
		enemy_roster.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_DARK.lightened(0.05)))

	# Ability panel
	if ability_panel:
		ability_panel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))

	for btn in ability_buttons:
		if btn:
			_style_ability_button(btn)

	if ability_desc:
		ability_desc.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
		ability_desc.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# End turn button
	if end_turn_button:
		_style_primary_button(end_turn_button)

	# Results panel
	if results_panel:
		results_panel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_DARK, UITheme.PRIMARY, UITheme.MODAL_RADIUS))

func _style_ability_button(btn: Button):
	btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_LIGHT))
	btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.BG_LIGHT.lightened(0.1)))
	btn.add_theme_stylebox_override("disabled", UITheme.create_button_style(UITheme.BG_DARK))
	btn.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	btn.add_theme_color_override("font_disabled_color", UITheme.TEXT_DISABLED)

func _style_primary_button(btn: Button):
	btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
	btn.add_theme_stylebox_override("hover", UITheme.create_button_style(UITheme.PRIMARY.lightened(0.1)))
	btn.add_theme_stylebox_override("pressed", UITheme.create_button_style(UITheme.PRIMARY.darkened(0.1)))
	btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
```

**Step 3: Update grid cell colors**

In `scripts/battle/grid_cell.gd`, update ownership colors to use UITheme:

```gdscript
func set_ownership(owner: int):
	ownership = owner
	match owner:
		0: background.color = UITheme.BG_MEDIUM  # Empty
		1: background.color = UITheme.PRIMARY.darkened(0.5)  # Player
		2: background.color = UITheme.DANGER.darkened(0.5)  # Enemy
		3: background.color = UITheme.SECONDARY.darkened(0.5)  # Contested
```

**Step 4: Verify**

Run a battle:
- Top bar has turn/phase/actions
- Rosters styled with dark panels
- Ability buttons styled consistently
- Auto/speed controls in bottom bar
- Grid cells use theme colors

**Step 5: Commit**

```bash
git add scripts/battle/battle.gd scenes/battle/battle.tscn scripts/battle/grid_cell.gd
git commit -m "feat: overhaul battle screen UI with new design system"
```

---

## Task 5: Overhaul Collection Screen UI

**Files:**
- Modify: `scripts/ui/collection_screen.gd`
- Modify: `scenes/ui/collection_screen.tscn`

**Step 1: Update collection_screen.tscn layout**

```
CollectionScreen (Control)
  Background (ColorRect) - BG_DARK
  TopBar (Panel, 64px)
    BackButton (left)
    Title "COLLECTION" (center)
    CurrencyDisplay (right)
  HSplitContainer
    LeftPanel (ScrollContainer + GridContainer for unit cards)
      FilterBar (top)
      UnitsGrid (4 columns)
    RightPanel (Panel - unit details)
      UnitNameLabel
      StarsLabel
      LevelBar
      StatsGrid (HP, ATK, DEF, SPD with labels)
      GearSlotsContainer (2x2)
      ButtonContainer (LevelUpButton, AbilitiesButton)
```

**Step 2: Add _apply_theme() to collection_screen.gd**

```gdscript
func _apply_theme():
	# Background
	$Background.color = UITheme.BG_DARK

	# Top bar
	$TopBar.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))
	$TopBar/Title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)
	$TopBar/Title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	# Back button
	var back_btn = $TopBar/BackButton
	back_btn.add_theme_stylebox_override("normal", UITheme.create_button_style(Color.TRANSPARENT))
	back_btn.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

	# Left panel
	$HSplitContainer/LeftPanel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_DARK.lightened(0.02)))

	# Right detail panel
	$HSplitContainer/RightPanel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))

	# Level up button
	_style_primary_button($HSplitContainer/RightPanel/ButtonContainer/LevelUpButton)
```

**Step 3: Update unit card styling in _create_unit_card()**

Update the card creation to use UITheme colors:

```gdscript
func _create_unit_card(unit_entry: Dictionary) -> Control:
	var unit_data = unit_entry.unit_data as UnitData
	var instance_id = unit_entry.instance_id as String

	var card = Panel.new()
	card.custom_minimum_size = UITheme.UNIT_CARD_SIZE

	var style = StyleBoxFlat.new()
	style.bg_color = UITheme.BG_MEDIUM
	style.corner_radius_top_left = UITheme.CARD_RADIUS
	style.corner_radius_top_right = UITheme.CARD_RADIUS
	style.corner_radius_bottom_left = UITheme.CARD_RADIUS
	style.corner_radius_bottom_right = UITheme.CARD_RADIUS
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = UITheme.get_rarity_color(unit_data.star_rating)
	card.add_theme_stylebox_override("panel", style)

	# ... rest of card setup with UITheme fonts/colors
```

**Step 4: Verify**

Open collection screen:
- Dark background, styled top bar with currency
- Unit cards have rarity-colored borders
- Selected unit shows in right panel with stats
- Gear slots visible
- Level Up button styled

**Step 5: Commit**

```bash
git add scripts/ui/collection_screen.gd scenes/ui/collection_screen.tscn
git commit -m "feat: overhaul collection screen UI with new design system"
```

---

## Task 6: Overhaul Gear Inventory Screen UI

**Files:**
- Modify: `scripts/ui/gear_inventory_screen.gd`
- Modify: `scenes/ui/gear_inventory_screen.tscn`

**Step 1: Update gear_inventory_screen.tscn layout**

```
GearInventoryScreen (Control)
  Background (ColorRect) - BG_DARK
  TopBar (Panel, 64px)
    BackButton
    Title "GEAR"
    CurrencyDisplay
  FilterBar (HBoxContainer)
    AllButton, WeaponButton, ArmorButton, AccessoryButton (tab-style)
    OwnedLabel (right aligned)
  HSplitContainer
    LeftPanel (ScrollContainer + GearGrid, 5 columns)
    RightPanel (detail panel)
      GearNameLabel
      GearTypeLabel
      GearStatLabel
      LevelProgressBar
      EnhanceCostLabel
      EquippedLabel
      ButtonContainer (EnhanceButton, UnequipButton)
```

**Step 2: Add _apply_theme() to gear_inventory_screen.gd**

```gdscript
func _apply_theme():
	$Background.color = UITheme.BG_DARK

	# Top bar
	$TopBar.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))
	$TopBar/Title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)

	# Filter tabs
	_style_filter_tabs()

	# Detail panel
	$HSplitContainer/RightPanel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))
	_style_primary_button($HSplitContainer/RightPanel/EnhanceButton)

func _style_filter_tabs():
	var tabs = [filter_all_btn, filter_weapon_btn, filter_armor_btn, filter_accessory_btn]
	for tab in tabs:
		if tab:
			tab.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_LIGHT))
			tab.add_theme_stylebox_override("disabled", UITheme.create_button_style(UITheme.PRIMARY))
			tab.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
```

**Step 3: Update gear card styling**

Update `_create_gear_card()` to use UITheme:

```gdscript
func _create_gear_card(gear_entry: Dictionary) -> Control:
	var template = gear_entry.gear_data as GearData

	var card = Panel.new()
	card.custom_minimum_size = Vector2(120, 150)

	var style = StyleBoxFlat.new()
	style.bg_color = UITheme.BG_MEDIUM
	style.corner_radius_top_left = UITheme.CARD_RADIUS
	style.corner_radius_top_right = UITheme.CARD_RADIUS
	style.corner_radius_bottom_left = UITheme.CARD_RADIUS
	style.corner_radius_bottom_right = UITheme.CARD_RADIUS
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = template.get_rarity_color()
	card.add_theme_stylebox_override("panel", style)

	# ... rest with UITheme fonts
```

**Step 4: Verify**

Open gear inventory:
- Filter tabs work and highlight active
- Gear cards have rarity borders
- Detail panel shows enhancement info
- Enhance button styled

**Step 5: Commit**

```bash
git add scripts/ui/gear_inventory_screen.gd scenes/ui/gear_inventory_screen.tscn
git commit -m "feat: overhaul gear inventory UI with new design system"
```

---

## Task 7: Overhaul Dungeon Select Screen UI

**Files:**
- Modify: `scripts/ui/dungeon_select_screen.gd`
- Modify: `scenes/ui/dungeon_select_screen.tscn`

**Step 1: Update dungeon_select_screen.tscn layout**

```
DungeonSelectScreen (Control)
  Background - BG_DARK
  TopBar (64px)
    BackButton, Title "DUNGEONS", CurrencyDisplay
  DungeonsContainer (GridContainer, 2x2, centered)
    PowerSanctumCard, FortressRuinsCard, VitalityCavesCard, WindTempleCard
  DifficultySection (VBoxContainer)
    DifficultyLabel "SELECT DIFFICULTY"
    DifficultyButtons (HBoxContainer)
      EasyButton, NormalButton, HardButton
  SelectedDungeonInfo (Panel, bottom)
```

**Step 2: Add _apply_theme() and update dungeon cards**

```gdscript
func _apply_theme():
	$Background.color = UITheme.BG_DARK
	$TopBar.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))
	$TopBar/Title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)

	$DifficultySection/DifficultyLabel.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
	$DifficultySection/DifficultyLabel.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

func _create_dungeon_card(dungeon) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(200, 180)

	# Color based on stat type
	var stat_color = UITheme.PRIMARY
	match dungeon.drops_stat_type:
		GearData.StatType.ATTACK: stat_color = UITheme.DANGER
		GearData.StatType.DEFENSE: stat_color = UITheme.PRIMARY
		GearData.StatType.HP: stat_color = UITheme.SUCCESS
		GearData.StatType.SPEED: stat_color = UITheme.SECONDARY

	var style = UITheme.create_panel_style(UITheme.BG_MEDIUM, stat_color)
	card.add_theme_stylebox_override("panel", style)

	# ... add dungeon name, icon, drop type label
```

**Step 3: Style difficulty buttons**

```gdscript
func _style_difficulty_buttons():
	var difficulties = [
		{"btn": $DifficultySection/DifficultyButtons/EasyButton, "tier": 0},
		{"btn": $DifficultySection/DifficultyButtons/NormalButton, "tier": 1},
		{"btn": $DifficultySection/DifficultyButtons/HardButton, "tier": 2}
	]

	for diff in difficulties:
		var btn = diff.btn
		if current_dungeon_tier == diff.tier:
			btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.PRIMARY))
		else:
			btn.add_theme_stylebox_override("normal", UITheme.create_button_style(UITheme.BG_LIGHT))
```

**Step 4: Verify**

Open dungeon select:
- 2x2 grid of dungeon cards with stat-colored borders
- Difficulty buttons highlight selected tier
- Currency display in top bar

**Step 5: Commit**

```bash
git add scripts/ui/dungeon_select_screen.gd scenes/ui/dungeon_select_screen.tscn
git commit -m "feat: overhaul dungeon select UI with new design system"
```

---

## Task 8: Overhaul Campaign Select Screen UI

**Files:**
- Modify: `scripts/ui/campaign_select_screen.gd`
- Modify: `scenes/ui/campaign_select_screen.tscn`

**Step 1: Update campaign_select_screen.tscn layout**

```
CampaignSelectScreen (Control)
  Background - BG_DARK
  TopBar (64px)
  ChapterHeader (Label) "CHAPTER 1: The Beginning"
  StagesContainer (HBoxContainer, horizontal scroll)
    Stage1Card, Stage2Card, Stage3Card, Stage4Card, Stage5Card
  StageInfoPanel (bottom panel)
    StageNameLabel
    DifficultyLabel
    EnemyInfoLabel
    RewardLabel
    StartButton
```

**Step 2: Add _apply_theme() and stage card styling**

```gdscript
func _apply_theme():
	$Background.color = UITheme.BG_DARK
	$TopBar.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))

	$ChapterHeader.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
	$ChapterHeader.add_theme_color_override("font_color", UITheme.GOLD)

	$StageInfoPanel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))
	_style_primary_button($StageInfoPanel/StartButton)

func _create_stage_card(stage) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(140, 160)

	var is_locked = not PlayerData.is_stage_unlocked(stage.stage_id)
	var is_cleared = PlayerData.is_stage_cleared(stage.stage_id)

	var bg_color = UITheme.BG_DARK if is_locked else UITheme.BG_MEDIUM
	var border_color = UITheme.TEXT_DISABLED if is_locked else (UITheme.SUCCESS if is_cleared else UITheme.BG_LIGHT)

	var style = UITheme.create_panel_style(bg_color, border_color)
	card.add_theme_stylebox_override("panel", style)

	# Stage number
	var num_label = Label.new()
	num_label.text = stage.stage_id
	num_label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
	num_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY if not is_locked else UITheme.TEXT_DISABLED)

	# Stars or lock icon
	var status_label = Label.new()
	if is_locked:
		status_label.text = "LOCKED"
		status_label.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)
	elif is_cleared:
		var stars = PlayerData.get_stage_stars(stage.stage_id)
		status_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
		status_label.add_theme_color_override("font_color", UITheme.GOLD)

	# ... add to card
```

**Step 3: Verify**

Open campaign select:
- Chapter header in gold
- Horizontal stage cards
- Locked stages grayed out
- Cleared stages show stars
- Stage info panel at bottom

**Step 4: Commit**

```bash
git add scripts/ui/campaign_select_screen.gd scenes/ui/campaign_select_screen.tscn
git commit -m "feat: overhaul campaign select UI with new design system"
```

---

## Task 9: Overhaul Team Select Screen UI

**Files:**
- Modify: `scripts/ui/team_select_screen.gd`
- Modify: `scenes/ui/team_select_screen.tscn`

**Step 1: Update team_select_screen.tscn layout**

```
TeamSelectScreen (Control)
  Background - BG_DARK
  TopBar (64px)
    BackButton, Title, StageInfo (right)
  SelectedTeamSection
    Label "YOUR TEAM (0/5)"
    TeamSlots (HBoxContainer, 5 slots)
  AvailableUnitsSection
    Label "AVAILABLE UNITS"
    FilterDropdown
    UnitsGrid (ScrollContainer + GridContainer)
  BottomBar (80px)
    StageInfoSummary (left)
    StartButton (right)
```

**Step 2: Add _apply_theme() and slot styling**

```gdscript
func _apply_theme():
	$Background.color = UITheme.BG_DARK
	$TopBar.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))

	$SelectedTeamSection/Label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)
	$AvailableUnitsSection/Label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_SMALL)

	$BottomBar.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))
	_style_primary_button($BottomBar/StartButton)

	_create_team_slots()

func _create_team_slots():
	var slots_container = $SelectedTeamSection/TeamSlots
	for child in slots_container.get_children():
		child.queue_free()

	for i in range(5):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(120, 140)

		var style = UITheme.create_panel_style(UITheme.BG_DARK, UITheme.BG_LIGHT)
		slot.add_theme_stylebox_override("panel", style)

		var label = Label.new()
		if i < selected_instance_ids.size():
			# Show unit
			var unit = PlayerData.get_unit_by_instance_id(selected_instance_ids[i])
			label.text = unit.unit_data.unit_name if unit else "+"
		else:
			label.text = "+"
			label.add_theme_color_override("font_color", UITheme.TEXT_DISABLED)

		label.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_MEDIUM)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(label)

		slots_container.add_child(slot)
```

**Step 3: Verify**

Open team select (from campaign or dungeon):
- Top row shows 5 team slots (empty show +)
- Available units in scrollable grid below
- Stage/dungeon info at bottom
- Start button styled

**Step 4: Commit**

```bash
git add scripts/ui/team_select_screen.gd scenes/ui/team_select_screen.tscn
git commit -m "feat: overhaul team select UI with new design system"
```

---

## Task 10: Update Gacha/Summon Screen UI

**Files:**
- Modify: `scripts/ui/gacha_screen.gd`
- Modify: `scenes/ui/gacha_screen.tscn`

**Step 1: Apply theme to gacha screen**

```gdscript
func _apply_theme():
	$Background.color = UITheme.BG_DARK
	$TopBar.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM))
	$TopBar/Title.text = "SUMMON"
	$TopBar/Title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE_LARGE)

	# Summon buttons
	_style_primary_button($SummonButtons/SinglePullButton)
	_style_primary_button($SummonButtons/MultiPullButton)

	# Results panel
	$ResultsPanel.add_theme_stylebox_override("panel", UITheme.create_panel_style(UITheme.BG_MEDIUM, UITheme.GOLD, UITheme.MODAL_RADIUS))
```

**Step 2: Verify**

Open summon screen:
- Consistent top bar
- Styled summon buttons
- Results panel matches design

**Step 3: Commit**

```bash
git add scripts/ui/gacha_screen.gd scenes/ui/gacha_screen.tscn
git commit -m "feat: overhaul gacha/summon screen UI with new design system"
```

---

## Task 11: Update CHANGELOG and Version

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `project.godot`

**Step 1: Update CHANGELOG.md**

Add v0.5 section at the top:

```markdown
## [0.5] - Auto-Battle & UI Overhaul

### Added
- **Auto-Battle System**
  - Toggle button to enable AI-controlled unit placement
  - AI uses strategic cell evaluation (same logic as enemy)
  - Automatically selects best abilities based on situation
  - Auto-ends turn when actions exhausted

- **Battle Speed Controls**
  - 1x, 2x, 3x speed options
  - Affects all timers, tweens, and animations
  - Speed persists during battle

- **UI Design System**
  - UITheme autoload with consistent colors, fonts, spacing
  - Dark navy backgrounds (#1a1a2e)
  - Blue primary accents (#4a9eff)
  - Standardized component styles

### Changed
- **Main Menu**: Centered layout, primary/secondary button hierarchy
- **Battle Screen**: Reorganized layout, auto/speed controls in bottom bar
- **Collection Screen**: Split view with unit grid and detail panel
- **Gear Inventory**: Tab-style filters, cleaner card layout
- **Dungeon Select**: 2x2 grid with color-coded stat types
- **Campaign Select**: Horizontal stage progression, locked/cleared states
- **Team Select**: Top team slots, available units below
- **Gacha Screen**: Consistent styling with other screens

---
```

**Step 2: Update version in project.godot**

Change version string to "0.5"

**Step 3: Update version label in main_menu.gd**

```gdscript
$VBoxContainer/VersionLabel.text = "v0.5"
```

**Step 4: Commit**

```bash
git add CHANGELOG.md project.godot scripts/ui/main_menu.gd
git commit -m "docs: update CHANGELOG and version to v0.5"
```

---

## Task 12: Final Testing & Polish

**Step 1: Full playthrough test**

Test each screen:
1. Main Menu - all buttons work, currency displays
2. Campaign - select stage, see info, start battle
3. Dungeon - select dungeon/difficulty, start battle
4. Battle - auto-battle works, speed controls work, win/lose
5. Collection - view units, equip gear, level up
6. Gear - filter, enhance, view equipped
7. Summon - single/multi pull, results display
8. Team Select - add/remove units, start battle

**Step 2: Fix any visual inconsistencies**

- Check all text is readable (contrast)
- Verify button hover/press states work
- Ensure panels have consistent padding
- Check currency displays update correctly

**Step 3: Final commit**

```bash
git add -A
git commit -m "fix: polish UI consistency and fix visual issues"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | UITheme autoload | ui_theme.gd, project.godot |
| 2 | Auto-battle + speed | battle.gd, battle.tscn |
| 3 | Main menu UI | main_menu.gd, main_menu.tscn |
| 4 | Battle screen UI | battle.gd, battle.tscn, grid_cell.gd |
| 5 | Collection screen UI | collection_screen.gd, collection_screen.tscn |
| 6 | Gear inventory UI | gear_inventory_screen.gd, gear_inventory_screen.tscn |
| 7 | Dungeon select UI | dungeon_select_screen.gd, dungeon_select_screen.tscn |
| 8 | Campaign select UI | campaign_select_screen.gd, campaign_select_screen.tscn |
| 9 | Team select UI | team_select_screen.gd, team_select_screen.tscn |
| 10 | Gacha screen UI | gacha_screen.gd, gacha_screen.tscn |
| 11 | Changelog + version | CHANGELOG.md, project.godot |
| 12 | Final testing | All files |

Total: 12 tasks, ~20 files modified/created
