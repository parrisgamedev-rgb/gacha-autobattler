# Gear System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a gear system where units equip items for stat bonuses, with gear farming dungeons to obtain gear and enhancement materials.

**Architecture:** GearData resources define gear templates (like UnitData). PlayerData stores owned gear instances with levels. UnitInstance calculates stats including equipped gear. New dungeon mode reuses battle.gd with gear drops.

**Tech Stack:** Godot 4.5, GDScript, Resource-based data, JSON save/load

---

## Task 1: Create GearData Resource Class

**Files:**
- Create: `scripts/data/gear_data.gd`

**Step 1: Create the GearData resource class**

```gdscript
extends Resource
class_name GearData
## Data container for a gear template

enum GearType { WEAPON, ARMOR, ACCESSORY }
enum GearRarity { COMMON, RARE, EPIC, LEGENDARY }
enum StatType { HP, ATTACK, DEFENSE, SPEED }

# Identification
@export var gear_id: String = "gear_001"
@export var gear_name: String = "Iron Sword"
@export var gear_type: GearType = GearType.WEAPON
@export var rarity: GearRarity = GearRarity.COMMON

# Primary stat (only one stat per gear piece)
@export var stat_type: StatType = StatType.ATTACK
@export var is_percentage: bool = false  # false = flat, true = percentage
@export var base_value: float = 10.0  # Base stat value at +0

# Get max level based on rarity
func get_max_level() -> int:
	match rarity:
		GearRarity.COMMON: return 6
		GearRarity.RARE: return 9
		GearRarity.EPIC: return 12
		GearRarity.LEGENDARY: return 15
	return 6

# Get stat value at a specific level
func get_stat_at_level(level: int) -> float:
	# Linear scaling: value increases by ~150% from +0 to max level
	var max_level = get_max_level()
	var growth_per_level = base_value * 1.5 / max_level
	return base_value + (growth_per_level * level)

# Get enhancement cost for next level
func get_enhance_cost(current_level: int) -> Dictionary:
	var gold_per_level = 100
	var stones_per_level = 2
	match rarity:
		GearRarity.COMMON:
			gold_per_level = 100
			stones_per_level = 2
		GearRarity.RARE:
			gold_per_level = 200
			stones_per_level = 4
		GearRarity.EPIC:
			gold_per_level = 400
			stones_per_level = 8
		GearRarity.LEGENDARY:
			gold_per_level = 800
			stones_per_level = 15
	return {"gold": gold_per_level, "stones": stones_per_level}

# Get rarity color for UI
func get_rarity_color() -> Color:
	match rarity:
		GearRarity.COMMON: return Color(0.6, 0.6, 0.6)  # Gray
		GearRarity.RARE: return Color(0.3, 0.5, 1.0)  # Blue
		GearRarity.EPIC: return Color(0.7, 0.3, 0.9)  # Purple
		GearRarity.LEGENDARY: return Color(1.0, 0.8, 0.2)  # Gold
	return Color.WHITE

# Get type name for display
func get_type_name() -> String:
	match gear_type:
		GearType.WEAPON: return "Weapon"
		GearType.ARMOR: return "Armor"
		GearType.ACCESSORY: return "Accessory"
	return "Unknown"

# Get stat name for display
func get_stat_name() -> String:
	match stat_type:
		StatType.HP: return "HP"
		StatType.ATTACK: return "ATK"
		StatType.DEFENSE: return "DEF"
		StatType.SPEED: return "SPD"
	return "???"
```

**Step 2: Verify file created**

Run: Check that the file exists and has no syntax errors by opening Godot.

**Step 3: Commit**

```bash
git add scripts/data/gear_data.gd
git commit -m "feat: add GearData resource class for gear templates"
```

---

## Task 2: Create DungeonData Resource Class

**Files:**
- Create: `scripts/data/dungeon_data.gd`

**Step 1: Create the DungeonData resource class**

```gdscript
extends Resource
class_name DungeonData
## Data container for a gear dungeon

@export var dungeon_id: String = "power_sanctum"
@export var dungeon_name: String = "Power Sanctum"
@export var description: String = "Farm ATK gear here"

# What stat type of gear drops here
@export var drops_stat_type: GearData.StatType = GearData.StatType.ATTACK

# Enemy configuration (reuse unit pool)
@export var enemy_units: Array[UnitData] = []

# Difficulty tiers (Easy, Normal, Hard)
@export var tier_enemy_levels: Array[int] = [3, 6, 10]
@export var tier_names: Array[String] = ["Easy", "Normal", "Hard"]

# Drop rates per tier [Common%, Rare%, Epic%, Legendary%]
const TIER_DROP_RATES = [
	[0.70, 0.25, 0.05, 0.00],  # Easy
	[0.40, 0.40, 0.18, 0.02],  # Normal
	[0.10, 0.40, 0.40, 0.10]   # Hard
]

# Enhancement stone drops per tier [min, max]
const TIER_STONE_DROPS = [
	[3, 5],   # Easy
	[6, 10],  # Normal
	[12, 18]  # Hard
]

func get_drop_rates(tier: int) -> Array:
	if tier >= 0 and tier < TIER_DROP_RATES.size():
		return TIER_DROP_RATES[tier]
	return TIER_DROP_RATES[0]

func get_stone_drop_range(tier: int) -> Array:
	if tier >= 0 and tier < TIER_STONE_DROPS.size():
		return TIER_STONE_DROPS[tier]
	return TIER_STONE_DROPS[0]

func get_enemy_level(tier: int) -> int:
	if tier >= 0 and tier < tier_enemy_levels.size():
		return tier_enemy_levels[tier]
	return 1
```

**Step 2: Commit**

```bash
git add scripts/data/dungeon_data.gd
git commit -m "feat: add DungeonData resource class for gear dungeons"
```

---

## Task 3: Update PlayerData with Gear System

**Files:**
- Modify: `scripts/core/player_data.gd`

**Step 1: Add gear-related variables after line 11 (after level_materials)**

Add these variables:

```gdscript
var enhancement_stones: int = 50  # Starting stones for new players

# Owned gear: Array of gear instances
# Each entry: {instance_id: String, gear_data: GearData, level: int, equipped_to: String}
var owned_gear: Array = []
var next_gear_instance_id: int = 1

# Dungeon mode tracking
var current_dungeon = null  # DungeonData resource
var current_dungeon_tier: int = 0  # 0=Easy, 1=Normal, 2=Hard
```

**Step 2: Add gear path mapping in _build_unit_paths() area (around line 137)**

Add after `_build_unit_paths()`:

```gdscript
# Gear template paths for generating drops
var gear_templates: Dictionary = {}  # {stat_type: {rarity: [GearData]}}

func _load_gear_templates():
	# Initialize structure
	for stat in GearData.StatType.values():
		gear_templates[stat] = {}
		for rarity in GearData.GearRarity.values():
			gear_templates[stat][rarity] = []

	# Load all gear resources
	var gear_dir = "res://resources/gear/"
	var dir = DirAccess.open(gear_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var gear = load(gear_dir + file_name) as GearData
				if gear:
					gear_templates[gear.stat_type][gear.rarity].append(gear)
			file_name = dir.get_next()
		dir.list_dir_end()

	print("Loaded gear templates")
```

**Step 3: Add call to _load_gear_templates() in _ready() after _build_unit_paths()**

```gdscript
func _ready():
	_load_unit_pools()
	_build_unit_paths()
	_load_gear_templates()  # Add this line
	if not load_game():
		_give_starter_units()
```

**Step 4: Add gear management functions after the leveling system section (around line 520)**

```gdscript
# --- Gear System ---

func add_gear_to_inventory(gear_data: GearData) -> Dictionary:
	if gear_data == null:
		return {}

	var gear_entry = {
		"instance_id": "g" + str(next_gear_instance_id),
		"gear_data": gear_data,
		"level": 0,
		"equipped_to": ""  # Empty = not equipped
	}
	next_gear_instance_id += 1
	owned_gear.append(gear_entry)

	print("New gear: ", gear_data.gear_name, " (", GearData.GearRarity.keys()[gear_data.rarity], ")")
	return gear_entry

func get_gear_by_instance_id(instance_id: String) -> Dictionary:
	for gear in owned_gear:
		if gear.instance_id == instance_id:
			return gear
	return {}

func get_equipped_gear(unit_instance_id: String) -> Array:
	var equipped = []
	for gear in owned_gear:
		if gear.equipped_to == unit_instance_id:
			equipped.append(gear)
	return equipped

func get_unequipped_gear() -> Array:
	var unequipped = []
	for gear in owned_gear:
		if gear.equipped_to == "":
			unequipped.append(gear)
	return unequipped

func equip_gear(gear_instance_id: String, unit_instance_id: String) -> bool:
	var gear = get_gear_by_instance_id(gear_instance_id)
	var unit = get_unit_by_instance_id(unit_instance_id)

	if gear.is_empty() or unit.is_empty():
		return false

	var gear_data = gear.gear_data as GearData

	# Check if unit already has gear in this slot
	var equipped = get_equipped_gear(unit_instance_id)
	for eq in equipped:
		var eq_data = eq.gear_data as GearData
		# Weapons go in weapon slot, armor in armor, accessories can stack (2 max)
		if gear_data.gear_type == eq_data.gear_type:
			if gear_data.gear_type != GearData.GearType.ACCESSORY:
				print("Slot already occupied!")
				return false
			else:
				# Count accessories
				var acc_count = 0
				for e in equipped:
					if (e.gear_data as GearData).gear_type == GearData.GearType.ACCESSORY:
						acc_count += 1
				if acc_count >= 2:
					print("Max accessories equipped!")
					return false

	# Unequip from previous owner if any
	if gear.equipped_to != "":
		unequip_gear(gear_instance_id)

	# Equip to new owner
	for i in range(owned_gear.size()):
		if owned_gear[i].instance_id == gear_instance_id:
			owned_gear[i].equipped_to = unit_instance_id
			print("Equipped ", gear_data.gear_name, " to ", unit.unit_data.unit_name)
			save_game()
			return true

	return false

func unequip_gear(gear_instance_id: String) -> bool:
	for i in range(owned_gear.size()):
		if owned_gear[i].instance_id == gear_instance_id:
			owned_gear[i].equipped_to = ""
			print("Unequipped ", (owned_gear[i].gear_data as GearData).gear_name)
			save_game()
			return true
	return false

func can_enhance_gear(gear_instance_id: String) -> Dictionary:
	var gear = get_gear_by_instance_id(gear_instance_id)
	if gear.is_empty():
		return {"can_enhance": false, "reason": "Gear not found"}

	var gear_data = gear.gear_data as GearData
	var current_level = gear.level
	var max_level = gear_data.get_max_level()

	if current_level >= max_level:
		return {"can_enhance": false, "reason": "Already at max level"}

	var cost = gear_data.get_enhance_cost(current_level)

	if gold < cost.gold:
		return {"can_enhance": false, "reason": "Not enough gold", "cost": cost}
	if enhancement_stones < cost.stones:
		return {"can_enhance": false, "reason": "Not enough stones", "cost": cost}

	return {"can_enhance": true, "cost": cost}

func enhance_gear(gear_instance_id: String) -> bool:
	var check = can_enhance_gear(gear_instance_id)
	if not check.can_enhance:
		print("Cannot enhance: ", check.reason)
		return false

	for i in range(owned_gear.size()):
		if owned_gear[i].instance_id == gear_instance_id:
			var cost = check.cost
			gold -= cost.gold
			enhancement_stones -= cost.stones
			owned_gear[i].level += 1

			var gear_data = owned_gear[i].gear_data as GearData
			print("Enhanced ", gear_data.gear_name, " to +", owned_gear[i].level)
			save_game()
			return true

	return false

func add_enhancement_stones(amount: int):
	enhancement_stones += amount
	print("+", amount, " Enhancement Stones (Total: ", enhancement_stones, ")")

# Calculate gear stat bonuses for a unit
func get_gear_bonuses(unit_instance_id: String) -> Dictionary:
	var bonuses = {
		"flat_hp": 0, "flat_attack": 0, "flat_defense": 0, "flat_speed": 0,
		"percent_hp": 0.0, "percent_attack": 0.0, "percent_defense": 0.0, "percent_speed": 0.0
	}

	var equipped = get_equipped_gear(unit_instance_id)
	for gear in equipped:
		var gear_data = gear.gear_data as GearData
		var stat_value = gear_data.get_stat_at_level(gear.level)

		var stat_key = ""
		match gear_data.stat_type:
			GearData.StatType.HP: stat_key = "hp"
			GearData.StatType.ATTACK: stat_key = "attack"
			GearData.StatType.DEFENSE: stat_key = "defense"
			GearData.StatType.SPEED: stat_key = "speed"

		if gear_data.is_percentage:
			bonuses["percent_" + stat_key] += stat_value / 100.0  # Convert to decimal
		else:
			bonuses["flat_" + stat_key] += int(stat_value)

	return bonuses

# --- Dungeon Mode ---

func is_dungeon_mode() -> bool:
	return current_dungeon != null

func start_dungeon(dungeon, tier: int):
	current_dungeon = dungeon
	current_dungeon_tier = tier
	pvp_mode = false
	current_stage_id = ""
	current_stage = null
	print("Starting dungeon: ", dungeon.dungeon_name, " (", dungeon.tier_names[tier], ")")

func end_dungeon():
	current_dungeon = null
	current_dungeon_tier = 0

func generate_gear_drop() -> GearData:
	if current_dungeon == null:
		return null

	var dungeon = current_dungeon
	var rates = dungeon.get_drop_rates(current_dungeon_tier)
	var stat_type = dungeon.drops_stat_type

	# Roll for rarity
	var roll = randf()
	var cumulative = 0.0
	var rarity = GearData.GearRarity.COMMON

	for i in range(rates.size()):
		cumulative += rates[i]
		if roll < cumulative:
			rarity = i
			break

	# Get gear from templates
	if gear_templates.has(stat_type) and gear_templates[stat_type].has(rarity):
		var templates = gear_templates[stat_type][rarity]
		if templates.size() > 0:
			return templates[randi() % templates.size()]

	return null

func generate_stone_drop() -> int:
	if current_dungeon == null:
		return 0

	var range_arr = current_dungeon.get_stone_drop_range(current_dungeon_tier)
	return randi_range(range_arr[0], range_arr[1])
```

**Step 5: Update save_game() to include gear data (around line 531)**

Update the save_data dictionary to include:

```gdscript
func save_game():
	var save_data = {
		"version": 4,  # Updated for gear system
		"gems": gems,
		"gold": gold,
		"level_materials": level_materials,
		"enhancement_stones": enhancement_stones,
		"pity_counter": pity_counter,
		"next_instance_id": next_instance_id,
		"next_gear_instance_id": next_gear_instance_id,
		"campaign_progress": campaign_progress,
		"owned_units": _serialize_units(),
		"owned_gear": _serialize_gear()
	}
	# ... rest of save_game
```

**Step 6: Add gear serialization functions before save_game()**

```gdscript
func _serialize_gear() -> Array:
	var serialized = []
	for gear_entry in owned_gear:
		var gear_data = gear_entry.gear_data as GearData
		serialized.append({
			"instance_id": gear_entry.instance_id,
			"gear_id": gear_data.gear_id,
			"level": gear_entry.level,
			"equipped_to": gear_entry.equipped_to
		})
	return serialized

func _deserialize_gear(gear_data_array: Array) -> Array:
	var loaded_gear = []
	# We need to load gear by ID - for now, scan all gear resources
	var gear_by_id = {}
	var gear_dir = "res://resources/gear/"
	var dir = DirAccess.open(gear_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var gear = load(gear_dir + file_name) as GearData
				if gear:
					gear_by_id[gear.gear_id] = gear
			file_name = dir.get_next()
		dir.list_dir_end()

	for gear_save in gear_data_array:
		var gear_id = gear_save.get("gear_id", "")
		if gear_by_id.has(gear_id):
			loaded_gear.append({
				"instance_id": gear_save.get("instance_id", "g" + str(next_gear_instance_id)),
				"gear_data": gear_by_id[gear_id],
				"level": int(gear_save.get("level", 0)),
				"equipped_to": gear_save.get("equipped_to", "")
			})

	return loaded_gear
```

**Step 7: Update load_game() to load gear (around line 574)**

Add after loading owned_units:

```gdscript
	enhancement_stones = int(save_data.get("enhancement_stones", 50))
	next_gear_instance_id = int(save_data.get("next_gear_instance_id", 1))

	# Load owned gear
	var gear_data_array = save_data.get("owned_gear", [])
	owned_gear = _deserialize_gear(gear_data_array)
```

**Step 8: Commit**

```bash
git add scripts/core/player_data.gd
git commit -m "feat: add gear inventory and dungeon mode to PlayerData"
```

---

## Task 4: Update UnitInstance for Gear Stats

**Files:**
- Modify: `scripts/battle/unit_instance.gd`

**Step 1: Update _calculate_stats() to include gear bonuses (around line 77)**

Replace the `_calculate_stats()` function:

```gdscript
func _calculate_stats():
	if not unit_data:
		return

	# Calculate stat multiplier based on level and imprint
	var level_mult = 1.0 + (0.03 * (level - 1))
	var imprint_mult = 1.0 + (0.05 * imprint_level)
	var total_mult = level_mult * imprint_mult

	# Base stats with level/imprint multiplier
	var base_hp = int(unit_data.max_hp * total_mult)
	var base_attack = int(unit_data.attack * total_mult)
	var base_defense = int(unit_data.defense * total_mult)
	var base_speed = int(unit_data.speed * total_mult)

	# Apply gear bonuses if we have an instance_id to look up
	# Note: gear_instance_id must be set externally when creating from player data
	if gear_instance_id != "":
		var gear_bonuses = PlayerData.get_gear_bonuses(gear_instance_id)

		# Add flat bonuses first
		base_hp += gear_bonuses.flat_hp
		base_attack += gear_bonuses.flat_attack
		base_defense += gear_bonuses.flat_defense
		base_speed += gear_bonuses.flat_speed

		# Then apply percentage bonuses
		base_hp = int(base_hp * (1.0 + gear_bonuses.percent_hp))
		base_attack = int(base_attack * (1.0 + gear_bonuses.percent_attack))
		base_defense = int(base_defense * (1.0 + gear_bonuses.percent_defense))
		base_speed = int(base_speed * (1.0 + gear_bonuses.percent_speed))

	max_hp = base_hp
	attack = base_attack
	defense = base_defense
	speed = base_speed
```

**Step 2: Add gear_instance_id variable (after line 10)**

```gdscript
# Reference to player's unit instance for gear lookup
var gear_instance_id: String = ""
```

**Step 3: Update _init to accept gear_instance_id (around line 68)**

```gdscript
func _init(data: UnitData = null, unit_owner: int = 1, unit_level: int = 1, unit_imprint: int = 0, unit_gear_id: String = ""):
	if data:
		unit_data = data
		level = unit_level
		imprint_level = unit_imprint
		gear_instance_id = unit_gear_id
		_calculate_stats()
		current_hp = max_hp
	owner = unit_owner
```

**Step 4: Commit**

```bash
git add scripts/battle/unit_instance.gd
git commit -m "feat: add gear stat bonuses to UnitInstance"
```

---

## Task 5: Update Battle.gd to Pass Gear Instance ID

**Files:**
- Modify: `scripts/battle/battle.gd`

**Step 1: Update _load_units() to pass instance_id for gear lookup (around line 184)**

Change the unit creation line:

```gdscript
	# Create units from selected team
	for unit_entry in team_entries:
		var unit_data = unit_entry.unit_data as UnitData
		var unit_level = unit_entry.get("level", 1) as int
		var imprint_level = unit_entry.get("imprint_level", 0) as int
		var instance_id = unit_entry.get("instance_id", "") as String
		# Create unit with proper level, imprint, and gear reference
		var unit = UnitInstance.new(unit_data, 1, unit_level, imprint_level, instance_id)
		player_units.append(unit)
```

**Step 2: Update _generate_enemy_team() to check for dungeon mode (around line 195)**

```gdscript
func _generate_enemy_team():
	# Check if in campaign mode
	if PlayerData.is_campaign_mode():
		_generate_campaign_enemies()
		return

	# Check if in dungeon mode
	if PlayerData.is_dungeon_mode():
		_generate_dungeon_enemies()
		return

	# Regular mode: random enemies
	# ... existing code
```

**Step 3: Add _generate_dungeon_enemies() function after _generate_campaign_enemies()**

```gdscript
func _generate_dungeon_enemies():
	var dungeon = PlayerData.current_dungeon
	if dungeon == null:
		print("Error: No dungeon data!")
		return

	var tier = PlayerData.current_dungeon_tier
	var enemy_level = dungeon.get_enemy_level(tier)

	print("Loading enemies for dungeon: ", dungeon.dungeon_name, " (", dungeon.tier_names[tier], ")")

	# Use dungeon's enemy units if specified, otherwise random
	var enemy_pool = dungeon.enemy_units if dungeon.enemy_units.size() > 0 else []
	if enemy_pool.is_empty():
		enemy_pool.append_array(PlayerData.unit_pool_3_star)
		enemy_pool.append_array(PlayerData.unit_pool_4_star)

	# Create 3-5 enemies based on tier
	var enemy_count = 3 + tier
	for i in range(enemy_count):
		var enemy_data = enemy_pool[randi() % enemy_pool.size()]
		var unit = UnitInstance.new(enemy_data, 2, enemy_level, 0, "")
		enemy_units.append(unit)
		print("  Added enemy: ", enemy_data.unit_name, " (Lv.", enemy_level, ")")

	print("Total dungeon enemies: ", enemy_units.size())
```

**Step 4: Update _show_results() to handle dungeon rewards (around line 1508)**

In the victory section, add dungeon handling after campaign handling:

```gdscript
			# Handle dungeon rewards
			elif PlayerData.is_dungeon_mode():
				var dungeon_rewards = _give_dungeon_rewards()

				var subtitle_text = "Dungeon Complete!\n"
				subtitle_text += "+" + str(dungeon_rewards.stones) + " Enhancement Stones\n"

				if dungeon_rewards.gear != null:
					var gear_data = dungeon_rewards.gear.gear_data as GearData
					subtitle_text += "\nGear Drop: " + gear_data.gear_name
					subtitle_text += " (" + GearData.GearRarity.keys()[gear_data.rarity] + ")"

				result_subtitle.text = subtitle_text
```

**Step 5: Add _give_dungeon_rewards() function after _give_battle_rewards()**

```gdscript
func _give_dungeon_rewards() -> Dictionary:
	var result = {"stones": 0, "gear": null}

	if not PlayerData.is_dungeon_mode():
		return result

	# Give enhancement stones
	var stones = PlayerData.generate_stone_drop()
	PlayerData.add_enhancement_stones(stones)
	result.stones = stones

	# Generate gear drop
	var gear_data = PlayerData.generate_gear_drop()
	if gear_data:
		var gear_entry = PlayerData.add_gear_to_inventory(gear_data)
		result.gear = gear_entry

	PlayerData.save_game()
	return result
```

**Step 6: Update _on_main_menu_pressed() to handle dungeon mode (around line 1604)**

```gdscript
func _on_main_menu_pressed():
	if PlayerData.is_campaign_mode():
		PlayerData.end_campaign_stage()
		get_tree().change_scene_to_file("res://scenes/ui/campaign_select_screen.tscn")
	elif PlayerData.is_dungeon_mode():
		PlayerData.end_dungeon()
		get_tree().change_scene_to_file("res://scenes/ui/dungeon_select_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
```

**Step 7: Commit**

```bash
git add scripts/battle/battle.gd
git commit -m "feat: add dungeon mode and gear drops to battle system"
```

---

## Task 6: Create Gear Resources

**Files:**
- Create: `resources/gear/` directory
- Create: Multiple .tres files for gear templates

**Step 1: Create gear directory**

```bash
mkdir -p resources/gear
```

**Step 2: Create gear template files**

Create 16 gear pieces (4 stat types × 4 rarities). Example for ATK gear:

`resources/gear/atk_weapon_common.tres`:
```
[gd_resource type="Resource" script_class="GearData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/gear_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
gear_id = "atk_weapon_common"
gear_name = "Iron Sword"
gear_type = 0
rarity = 0
stat_type = 1
is_percentage = false
base_value = 8.0
```

`resources/gear/atk_weapon_rare.tres`:
```
[gd_resource type="Resource" script_class="GearData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/gear_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
gear_id = "atk_weapon_rare"
gear_name = "Steel Blade"
gear_type = 0
rarity = 1
stat_type = 1
is_percentage = false
base_value = 15.0
```

`resources/gear/atk_weapon_epic.tres`:
```
[gd_resource type="Resource" script_class="GearData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/gear_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
gear_id = "atk_weapon_epic"
gear_name = "Crimson Edge"
gear_type = 0
rarity = 2
stat_type = 1
is_percentage = false
base_value = 25.0
```

`resources/gear/atk_weapon_legendary.tres`:
```
[gd_resource type="Resource" script_class="GearData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/gear_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
gear_id = "atk_weapon_legendary"
gear_name = "Dragonslayer"
gear_type = 0
rarity = 3
stat_type = 1
is_percentage = false
base_value = 40.0
```

Similar files for:
- DEF gear (Armor type): def_armor_common/rare/epic/legendary
- HP gear (Armor type): hp_armor_common/rare/epic/legendary
- SPD gear (Accessory type): spd_acc_common/rare/epic/legendary

Also create percentage variants:
- atk_acc_common/rare/epic/legendary (% ATK accessories)
- def_acc_common/rare/epic/legendary (% DEF accessories)
- hp_acc_common/rare/epic/legendary (% HP accessories)
- spd_weapon_common/rare/epic/legendary (% SPD weapons - swift weapons)

**Step 3: Commit**

```bash
git add resources/gear/
git commit -m "feat: add gear resource templates for all stat types and rarities"
```

---

## Task 7: Create Dungeon Resources

**Files:**
- Create: `resources/dungeons/` directory
- Create: 4 dungeon .tres files

**Step 1: Create dungeon directory**

```bash
mkdir -p resources/dungeons
```

**Step 2: Create dungeon files**

`resources/dungeons/power_sanctum.tres`:
```
[gd_resource type="Resource" script_class="DungeonData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/dungeon_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
dungeon_id = "power_sanctum"
dungeon_name = "Power Sanctum"
description = "A ancient temple where warriors trained. Drops ATK gear."
drops_stat_type = 1
enemy_units = []
tier_enemy_levels = [3, 6, 10]
tier_names = ["Easy", "Normal", "Hard"]
```

`resources/dungeons/fortress_ruins.tres`:
```
[gd_resource type="Resource" script_class="DungeonData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/dungeon_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
dungeon_id = "fortress_ruins"
dungeon_name = "Fortress Ruins"
description = "Crumbling walls still hold defensive secrets. Drops DEF gear."
drops_stat_type = 2
enemy_units = []
tier_enemy_levels = [3, 6, 10]
tier_names = ["Easy", "Normal", "Hard"]
```

`resources/dungeons/vitality_caves.tres`:
```
[gd_resource type="Resource" script_class="DungeonData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/dungeon_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
dungeon_id = "vitality_caves"
dungeon_name = "Vitality Caves"
description = "Life energy flows through these caverns. Drops HP gear."
drops_stat_type = 0
enemy_units = []
tier_enemy_levels = [3, 6, 10]
tier_names = ["Easy", "Normal", "Hard"]
```

`resources/dungeons/wind_temple.tres`:
```
[gd_resource type="Resource" script_class="DungeonData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/dungeon_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
dungeon_id = "wind_temple"
dungeon_name = "Wind Temple"
description = "Swift spirits guard this sacred place. Drops SPD gear."
drops_stat_type = 3
enemy_units = []
tier_enemy_levels = [3, 6, 10]
tier_names = ["Easy", "Normal", "Hard"]
```

**Step 3: Commit**

```bash
git add resources/dungeons/
git commit -m "feat: add dungeon resources for gear farming"
```

---

## Task 8: Create Dungeon Select Screen

**Files:**
- Create: `scripts/ui/dungeon_select_screen.gd`
- Create: `scenes/ui/dungeon_select_screen.tscn`

**Step 1: Create the script**

```gdscript
extends Control
## Dungeon selection screen for gear farming

@onready var back_button = $TopBar/BackButton
@onready var stones_label = $TopBar/StonesLabel
@onready var dungeon_grid = $DungeonGrid
@onready var tier_panel = $TierPanel
@onready var tier_buttons_container = $TierPanel/TierButtons

var dungeons: Array = []
var selected_dungeon = null

var DungeonButtonScene = preload("res://scenes/ui/dungeon_button.tscn") if ResourceLoader.exists("res://scenes/ui/dungeon_button.tscn") else null

func _ready():
	_load_dungeons()
	_create_dungeon_buttons()
	_update_stones_display()

	tier_panel.visible = false

	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _load_dungeons():
	dungeons.clear()
	var dungeon_paths = [
		"res://resources/dungeons/power_sanctum.tres",
		"res://resources/dungeons/fortress_ruins.tres",
		"res://resources/dungeons/vitality_caves.tres",
		"res://resources/dungeons/wind_temple.tres"
	]

	for path in dungeon_paths:
		var dungeon = load(path)
		if dungeon:
			dungeons.append(dungeon)

func _create_dungeon_buttons():
	# Clear existing buttons
	for child in dungeon_grid.get_children():
		child.queue_free()

	for dungeon in dungeons:
		var button = Button.new()
		button.custom_minimum_size = Vector2(200, 120)
		button.text = dungeon.dungeon_name + "\n\n" + _get_stat_label(dungeon.drops_stat_type)
		button.pressed.connect(_on_dungeon_selected.bind(dungeon))
		dungeon_grid.add_child(button)

func _get_stat_label(stat_type: int) -> String:
	match stat_type:
		GearData.StatType.HP: return "Drops: HP Gear"
		GearData.StatType.ATTACK: return "Drops: ATK Gear"
		GearData.StatType.DEFENSE: return "Drops: DEF Gear"
		GearData.StatType.SPEED: return "Drops: SPD Gear"
	return "Drops: Gear"

func _update_stones_display():
	if stones_label:
		stones_label.text = str(PlayerData.enhancement_stones) + " Stones"

func _on_dungeon_selected(dungeon):
	selected_dungeon = dungeon
	_show_tier_selection()

func _show_tier_selection():
	tier_panel.visible = true

	# Clear existing tier buttons
	for child in tier_buttons_container.get_children():
		child.queue_free()

	# Create tier buttons
	for i in range(selected_dungeon.tier_names.size()):
		var tier_name = selected_dungeon.tier_names[i]
		var enemy_level = selected_dungeon.tier_enemy_levels[i]

		var button = Button.new()
		button.custom_minimum_size = Vector2(180, 60)
		button.text = tier_name + "\nEnemy Lv." + str(enemy_level)
		button.pressed.connect(_on_tier_selected.bind(i))
		tier_buttons_container.add_child(button)

	# Add cancel button
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(180, 50)
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_on_tier_cancel)
	tier_buttons_container.add_child(cancel_btn)

func _on_tier_selected(tier: int):
	PlayerData.start_dungeon(selected_dungeon, tier)
	get_tree().change_scene_to_file("res://scenes/ui/team_select_screen.tscn")

func _on_tier_cancel():
	tier_panel.visible = false
	selected_dungeon = null

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
```

**Step 2: Create the scene file**

`scenes/ui/dungeon_select_screen.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://dungeon_select_001"]

[ext_resource type="Script" path="res://scripts/ui/dungeon_select_screen.gd" id="1_script"]

[node name="DungeonSelectScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_script")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.08, 0.06, 0.12, 1)

[node name="TopBar" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 20.0
offset_top = 20.0
offset_right = -20.0
offset_bottom = 70.0
grow_horizontal = 2

[node name="BackButton" type="Button" parent="TopBar"]
custom_minimum_size = Vector2(120, 50)
layout_mode = 2
text = "< BACK"

[node name="Spacer" type="Control" parent="TopBar"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="TopBar"]
layout_mode = 2
theme_override_font_sizes/font_size = 32
text = "GEAR DUNGEONS"
vertical_alignment = 1

[node name="Spacer2" type="Control" parent="TopBar"]
layout_mode = 2
size_flags_horizontal = 3

[node name="StonesLabel" type="Label" parent="TopBar"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
theme_override_colors/font_color = Color(0.6, 0.8, 1, 1)
text = "0 Stones"
vertical_alignment = 1

[node name="DungeonGrid" type="GridContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -220.0
offset_top = -140.0
offset_right = 220.0
offset_bottom = 140.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/h_separation = 20
theme_override_constants/v_separation = 20
columns = 2

[node name="TierPanel" type="Panel" parent="."]
visible = false
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -150.0
offset_right = 150.0
offset_bottom = 150.0
grow_horizontal = 2
grow_vertical = 2

[node name="TierBackground" type="ColorRect" parent="TierPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.12, 0.1, 0.15, 1)

[node name="TierTitle" type="Label" parent="TierPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 10.0
offset_bottom = 40.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 20
text = "Select Difficulty"
horizontal_alignment = 1

[node name="TierButtons" type="VBoxContainer" parent="TierPanel"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -90.0
offset_top = -60.0
offset_right = 90.0
offset_bottom = 120.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 10
alignment = 1
```

**Step 3: Commit**

```bash
git add scripts/ui/dungeon_select_screen.gd scenes/ui/dungeon_select_screen.tscn
git commit -m "feat: add dungeon select screen for gear farming"
```

---

## Task 9: Create Gear Inventory Screen

**Files:**
- Create: `scripts/ui/gear_inventory_screen.gd`
- Create: `scenes/ui/gear_inventory_screen.tscn`

**Step 1: Create the script**

```gdscript
extends Control
## Gear inventory and management screen

@onready var back_button = $TopBar/BackButton
@onready var stones_label = $TopBar/StonesLabel
@onready var gold_label = $TopBar/GoldLabel
@onready var gear_grid = $ScrollContainer/GearGrid
@onready var detail_panel = $DetailPanel
@onready var detail_name = $DetailPanel/DetailName
@onready var detail_type = $DetailPanel/DetailType
@onready var detail_stat = $DetailPanel/DetailStat
@onready var detail_level = $DetailPanel/DetailLevel
@onready var detail_equipped = $DetailPanel/DetailEquipped
@onready var enhance_button = $DetailPanel/EnhanceButton
@onready var enhance_cost = $DetailPanel/EnhanceCost
@onready var close_button = $DetailPanel/CloseButton

var selected_gear_id: String = ""

func _ready():
	_update_currency_display()
	_populate_gear_grid()
	detail_panel.visible = false

	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if enhance_button:
		enhance_button.pressed.connect(_on_enhance_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_detail)

func _update_currency_display():
	if stones_label:
		stones_label.text = str(PlayerData.enhancement_stones) + " Stones"
	if gold_label:
		gold_label.text = str(PlayerData.gold) + " Gold"

func _populate_gear_grid():
	# Clear existing
	for child in gear_grid.get_children():
		child.queue_free()

	var all_gear = PlayerData.owned_gear

	if all_gear.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No gear owned.\nFarm dungeons to get gear!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gear_grid.add_child(empty_label)
		return

	# Sort by rarity (highest first), then by level
	all_gear.sort_custom(func(a, b):
		var a_data = a.gear_data as GearData
		var b_data = b.gear_data as GearData
		if a_data.rarity != b_data.rarity:
			return a_data.rarity > b_data.rarity
		return a.level > b.level
	)

	for gear_entry in all_gear:
		var button = _create_gear_button(gear_entry)
		gear_grid.add_child(button)

func _create_gear_button(gear_entry: Dictionary) -> Button:
	var gear_data = gear_entry.gear_data as GearData
	var button = Button.new()
	button.custom_minimum_size = Vector2(140, 80)

	var text = gear_data.gear_name + "\n"
	text += "+" + str(gear_entry.level) + " "
	text += gear_data.get_stat_name()
	if gear_entry.equipped_to != "":
		text += "\n[Equipped]"

	button.text = text
	button.add_theme_color_override("font_color", gear_data.get_rarity_color())
	button.pressed.connect(_on_gear_selected.bind(gear_entry.instance_id))

	return button

func _on_gear_selected(instance_id: String):
	selected_gear_id = instance_id
	_show_gear_detail()

func _show_gear_detail():
	var gear = PlayerData.get_gear_by_instance_id(selected_gear_id)
	if gear.is_empty():
		return

	var gear_data = gear.gear_data as GearData

	detail_panel.visible = true
	detail_name.text = gear_data.gear_name
	detail_name.add_theme_color_override("font_color", gear_data.get_rarity_color())

	detail_type.text = gear_data.get_type_name() + " - " + GearData.GearRarity.keys()[gear_data.rarity]

	var current_stat = gear_data.get_stat_at_level(gear.level)
	var stat_text = gear_data.get_stat_name() + ": "
	if gear_data.is_percentage:
		stat_text += "+" + str(snapped(current_stat, 0.1)) + "%"
	else:
		stat_text += "+" + str(int(current_stat))
	detail_stat.text = stat_text

	detail_level.text = "Level: +" + str(gear.level) + " / +" + str(gear_data.get_max_level())

	if gear.equipped_to != "":
		var unit = PlayerData.get_unit_by_instance_id(gear.equipped_to)
		if not unit.is_empty():
			detail_equipped.text = "Equipped to: " + unit.unit_data.unit_name
		else:
			detail_equipped.text = "Equipped"
	else:
		detail_equipped.text = "Not equipped"

	# Update enhance button
	var check = PlayerData.can_enhance_gear(selected_gear_id)
	if gear.level >= gear_data.get_max_level():
		enhance_button.disabled = true
		enhance_button.text = "MAX LEVEL"
		enhance_cost.text = ""
	elif check.can_enhance:
		enhance_button.disabled = false
		enhance_button.text = "ENHANCE"
		enhance_cost.text = "Cost: " + str(check.cost.gold) + " Gold, " + str(check.cost.stones) + " Stones"
	else:
		enhance_button.disabled = true
		enhance_button.text = "ENHANCE"
		enhance_cost.text = check.reason

func _on_enhance_pressed():
	if PlayerData.enhance_gear(selected_gear_id):
		_update_currency_display()
		_populate_gear_grid()
		_show_gear_detail()

func _on_close_detail():
	detail_panel.visible = false
	selected_gear_id = ""

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
```

**Step 2: Create the scene file**

`scenes/ui/gear_inventory_screen.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://gear_inventory_001"]

[ext_resource type="Script" path="res://scripts/ui/gear_inventory_screen.gd" id="1_script"]

[node name="GearInventoryScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_script")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.06, 0.06, 0.1, 1)

[node name="TopBar" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 20.0
offset_top = 20.0
offset_right = -20.0
offset_bottom = 70.0
grow_horizontal = 2

[node name="BackButton" type="Button" parent="TopBar"]
custom_minimum_size = Vector2(120, 50)
layout_mode = 2
text = "< BACK"

[node name="Spacer" type="Control" parent="TopBar"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="TopBar"]
layout_mode = 2
theme_override_font_sizes/font_size = 32
text = "GEAR"
vertical_alignment = 1

[node name="Spacer2" type="Control" parent="TopBar"]
layout_mode = 2
size_flags_horizontal = 3

[node name="GoldLabel" type="Label" parent="TopBar"]
layout_mode = 2
theme_override_font_sizes/font_size = 16
theme_override_colors/font_color = Color(1, 0.85, 0.3, 1)
text = "0 Gold"
vertical_alignment = 1

[node name="Spacer3" type="Control" parent="TopBar"]
custom_minimum_size = Vector2(20, 0)
layout_mode = 2

[node name="StonesLabel" type="Label" parent="TopBar"]
layout_mode = 2
theme_override_font_sizes/font_size = 16
theme_override_colors/font_color = Color(0.6, 0.8, 1, 1)
text = "0 Stones"
vertical_alignment = 1

[node name="ScrollContainer" type="ScrollContainer" parent="."]
layout_mode = 1
anchors_preset = -1
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 20.0
offset_top = 90.0
offset_right = -20.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 2

[node name="GearGrid" type="GridContainer" parent="ScrollContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/h_separation = 15
theme_override_constants/v_separation = 15
columns = 7

[node name="DetailPanel" type="Panel" parent="."]
visible = false
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -180.0
offset_right = 200.0
offset_bottom = 180.0
grow_horizontal = 2
grow_vertical = 2

[node name="DetailBackground" type="ColorRect" parent="DetailPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.1, 0.1, 0.15, 1)

[node name="DetailName" type="Label" parent="DetailPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 20.0
offset_bottom = 55.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 28
text = "Gear Name"
horizontal_alignment = 1

[node name="DetailType" type="Label" parent="DetailPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 60.0
offset_bottom = 85.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 16
text = "Weapon - Legendary"
horizontal_alignment = 1

[node name="DetailStat" type="Label" parent="DetailPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 100.0
offset_bottom = 130.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 20
text = "ATK: +40"
horizontal_alignment = 1

[node name="DetailLevel" type="Label" parent="DetailPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 140.0
offset_bottom = 170.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 18
text = "Level: +0 / +15"
horizontal_alignment = 1

[node name="DetailEquipped" type="Label" parent="DetailPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 180.0
offset_bottom = 210.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 16
theme_override_colors/font_color = Color(0.7, 0.7, 0.8, 1)
text = "Not equipped"
horizontal_alignment = 1

[node name="EnhanceCost" type="Label" parent="DetailPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 230.0
offset_bottom = 255.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 14
theme_override_colors/font_color = Color(0.7, 0.7, 0.8, 1)
text = "Cost: 100 Gold, 2 Stones"
horizontal_alignment = 1

[node name="EnhanceButton" type="Button" parent="DetailPanel"]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 20.0
offset_top = -100.0
offset_right = -120.0
offset_bottom = -60.0
grow_horizontal = 2
grow_vertical = 0
text = "ENHANCE"

[node name="CloseButton" type="Button" parent="DetailPanel"]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 120.0
offset_top = -100.0
offset_right = -20.0
offset_bottom = -60.0
grow_horizontal = 2
grow_vertical = 0
text = "CLOSE"
```

**Step 3: Commit**

```bash
git add scripts/ui/gear_inventory_screen.gd scenes/ui/gear_inventory_screen.tscn
git commit -m "feat: add gear inventory screen with enhancement"
```

---

## Task 10: Update Main Menu

**Files:**
- Modify: `scripts/ui/main_menu.gd`
- Modify: `scenes/ui/main_menu.tscn`

**Step 1: Add button references in main_menu.gd (around line 7)**

```gdscript
@onready var dungeons_button = $CenterContainer/VBoxContainer/DungeonsButton
@onready var gear_button = $CenterContainer/VBoxContainer/GearButton
```

**Step 2: Connect buttons in _ready() (around line 29)**

```gdscript
	if dungeons_button:
		dungeons_button.pressed.connect(_on_dungeons_pressed)

	if gear_button:
		gear_button.pressed.connect(_on_gear_pressed)
```

**Step 3: Add button handler functions**

```gdscript
func _on_dungeons_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/dungeon_select_screen.tscn")

func _on_gear_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/gear_inventory_screen.tscn")
```

**Step 4: Update main_menu.tscn to add buttons**

Add these nodes to the VBoxContainer (after PvPButton, before SummonButton):

```
[node name="DungeonsButton" type="Button" parent="CenterContainer/VBoxContainer"]
custom_minimum_size = Vector2(200, 50)
layout_mode = 2
text = "DUNGEONS"

[node name="GearButton" type="Button" parent="CenterContainer/VBoxContainer"]
custom_minimum_size = Vector2(200, 50)
layout_mode = 2
text = "GEAR"
```

**Step 5: Commit**

```bash
git add scripts/ui/main_menu.gd scenes/ui/main_menu.tscn
git commit -m "feat: add DUNGEONS and GEAR buttons to main menu"
```

---

## Task 11: Update Collection Screen for Gear Equipping

**Files:**
- Modify: `scripts/ui/collection_screen.gd`
- Modify: `scenes/ui/collection_screen.tscn`

**Step 1: Add gear slot references in collection_screen.gd**

Add after other @onready vars:

```gdscript
@onready var gear_slots_container = $DetailPanel/GearSlots
@onready var gear_select_panel = $GearSelectPanel
@onready var gear_select_grid = $GearSelectPanel/GearSelectGrid
@onready var gear_cancel_button = $GearSelectPanel/CancelButton

var editing_gear_slot: int = -1  # -1 = none, 0 = weapon, 1 = armor, 2 = acc1, 3 = acc2
```

**Step 2: Add gear display update in _show_unit_detail()**

After updating other detail fields, add:

```gdscript
	# Update gear slots display
	_update_gear_slots_display()
```

**Step 3: Add gear slot functions**

```gdscript
func _update_gear_slots_display():
	if not gear_slots_container or selected_unit_id == "":
		return

	# Clear existing slot buttons
	for child in gear_slots_container.get_children():
		child.queue_free()

	var equipped = PlayerData.get_equipped_gear(selected_unit_id)
	var slot_names = ["Weapon", "Armor", "Accessory 1", "Accessory 2"]
	var slot_types = [GearData.GearType.WEAPON, GearData.GearType.ARMOR, GearData.GearType.ACCESSORY, GearData.GearType.ACCESSORY]

	for i in range(4):
		var button = Button.new()
		button.custom_minimum_size = Vector2(120, 40)

		# Find equipped gear for this slot
		var found_gear = null
		var acc_index = 0
		for gear in equipped:
			var gear_data = gear.gear_data as GearData
			if gear_data.gear_type == slot_types[i]:
				if slot_types[i] == GearData.GearType.ACCESSORY:
					if (i == 2 and acc_index == 0) or (i == 3 and acc_index == 1):
						found_gear = gear
						break
					acc_index += 1
				else:
					found_gear = gear
					break

		if found_gear:
			var gear_data = found_gear.gear_data as GearData
			button.text = gear_data.gear_name + "\n+" + str(found_gear.level)
			button.add_theme_color_override("font_color", gear_data.get_rarity_color())
		else:
			button.text = slot_names[i] + "\n[Empty]"

		button.pressed.connect(_on_gear_slot_clicked.bind(i))
		gear_slots_container.add_child(button)

func _on_gear_slot_clicked(slot_index: int):
	editing_gear_slot = slot_index
	_show_gear_select_panel()

func _show_gear_select_panel():
	if not gear_select_panel:
		return

	gear_select_panel.visible = true

	# Clear existing
	for child in gear_select_grid.get_children():
		child.queue_free()

	# Get slot type
	var slot_types = [GearData.GearType.WEAPON, GearData.GearType.ARMOR, GearData.GearType.ACCESSORY, GearData.GearType.ACCESSORY]
	var target_type = slot_types[editing_gear_slot]

	# Show unequipped gear of this type
	var unequipped = PlayerData.get_unequipped_gear()
	var matching = unequipped.filter(func(g): return (g.gear_data as GearData).gear_type == target_type)

	# Add "Unequip" option if slot has gear
	var current_equipped = PlayerData.get_equipped_gear(selected_unit_id)
	for gear in current_equipped:
		var gear_data = gear.gear_data as GearData
		if gear_data.gear_type == target_type:
			var unequip_btn = Button.new()
			unequip_btn.custom_minimum_size = Vector2(120, 60)
			unequip_btn.text = "Unequip\nCurrent"
			unequip_btn.pressed.connect(_on_unequip_gear.bind(gear.instance_id))
			gear_select_grid.add_child(unequip_btn)
			break

	for gear in matching:
		var gear_data = gear.gear_data as GearData
		var button = Button.new()
		button.custom_minimum_size = Vector2(120, 60)
		button.text = gear_data.gear_name + "\n+" + str(gear.level) + " " + gear_data.get_stat_name()
		button.add_theme_color_override("font_color", gear_data.get_rarity_color())
		button.pressed.connect(_on_equip_gear.bind(gear.instance_id))
		gear_select_grid.add_child(button)

	if matching.is_empty() and current_equipped.is_empty():
		var label = Label.new()
		label.text = "No gear available"
		gear_select_grid.add_child(label)

func _on_equip_gear(gear_instance_id: String):
	PlayerData.equip_gear(gear_instance_id, selected_unit_id)
	gear_select_panel.visible = false
	editing_gear_slot = -1
	_update_gear_slots_display()
	_update_detail_stats()

func _on_unequip_gear(gear_instance_id: String):
	PlayerData.unequip_gear(gear_instance_id)
	gear_select_panel.visible = false
	editing_gear_slot = -1
	_update_gear_slots_display()
	_update_detail_stats()

func _update_detail_stats():
	# Recalculate and display stats with gear
	if selected_unit_id == "":
		return

	var unit = PlayerData.get_unit_by_instance_id(selected_unit_id)
	if unit.is_empty():
		return

	var unit_data = unit.unit_data as UnitData
	var level = unit.get("level", 1)
	var imprint = unit.get("imprint_level", 0)

	# Get base stats with level/imprint
	var base_stats = PlayerData.get_unit_stats_at_level(unit_data, level, imprint)

	# Get gear bonuses
	var gear_bonuses = PlayerData.get_gear_bonuses(selected_unit_id)

	# Apply gear
	var final_hp = base_stats.max_hp + gear_bonuses.flat_hp
	final_hp = int(final_hp * (1.0 + gear_bonuses.percent_hp))
	var final_atk = base_stats.attack + gear_bonuses.flat_attack
	final_atk = int(final_atk * (1.0 + gear_bonuses.percent_attack))
	var final_def = base_stats.defense + gear_bonuses.flat_defense
	final_def = int(final_def * (1.0 + gear_bonuses.percent_defense))
	var final_spd = base_stats.speed + gear_bonuses.flat_speed
	final_spd = int(final_spd * (1.0 + gear_bonuses.percent_speed))

	if detail_stats:
		detail_stats.text = "HP: " + str(final_hp) + "  ATK: " + str(final_atk) + "  DEF: " + str(final_def) + "  SPD: " + str(final_spd)
```

**Step 4: Connect cancel button in _ready()**

```gdscript
	if gear_cancel_button:
		gear_cancel_button.pressed.connect(func(): gear_select_panel.visible = false)
```

**Step 5: Update collection_screen.tscn**

Add gear slots container in DetailPanel (after DetailImprint):

```
[node name="GearSlots" type="HBoxContainer" parent="DetailPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 10.0
offset_top = 340.0
offset_right = -10.0
offset_bottom = 390.0
grow_horizontal = 2
theme_override_constants/separation = 10
alignment = 1
```

Add gear select panel:

```
[node name="GearSelectPanel" type="Panel" parent="."]
visible = false
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -250.0
offset_top = -150.0
offset_right = 250.0
offset_bottom = 150.0
grow_horizontal = 2
grow_vertical = 2

[node name="GearSelectBackground" type="ColorRect" parent="GearSelectPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.1, 0.1, 0.15, 1)

[node name="GearSelectTitle" type="Label" parent="GearSelectPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 10.0
offset_bottom = 40.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 20
text = "Select Gear"
horizontal_alignment = 1

[node name="GearSelectGrid" type="GridContainer" parent="GearSelectPanel"]
layout_mode = 1
anchors_preset = -1
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 15.0
offset_top = 50.0
offset_right = -15.0
offset_bottom = -60.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/h_separation = 10
theme_override_constants/v_separation = 10
columns = 4

[node name="CancelButton" type="Button" parent="GearSelectPanel"]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 150.0
offset_top = -50.0
offset_right = -150.0
offset_bottom = -10.0
grow_horizontal = 2
grow_vertical = 0
text = "CANCEL"
```

**Step 6: Commit**

```bash
git add scripts/ui/collection_screen.gd scenes/ui/collection_screen.tscn
git commit -m "feat: add gear equipping to collection screen"
```

---

## Task 12: Update Team Select for Dungeon Mode

**Files:**
- Modify: `scripts/ui/team_select_screen.gd`

**Step 1: Update _setup_campaign_ui() to also handle dungeon mode**

Add dungeon mode handling:

```gdscript
func _setup_mode_ui():
	if PlayerData.is_campaign_mode():
		_setup_campaign_ui()
	elif PlayerData.is_dungeon_mode():
		_setup_dungeon_ui()

func _setup_dungeon_ui():
	# Show dungeon info
	if stage_info_panel:
		stage_info_panel.visible = true
	if stage_name_label:
		stage_name_label.text = PlayerData.current_dungeon.dungeon_name
	if stage_difficulty_label:
		var tier = PlayerData.current_dungeon_tier
		stage_difficulty_label.text = PlayerData.current_dungeon.tier_names[tier]
	if stage_rewards_label:
		stage_rewards_label.text = "Drops: Gear + Enhancement Stones"
```

**Step 2: Update _ready() to call _setup_mode_ui()**

Replace `_setup_campaign_ui()` call with `_setup_mode_ui()`.

**Step 3: Update _on_back_pressed() for dungeon mode**

```gdscript
func _on_back_pressed():
	if PlayerData.is_campaign_mode():
		PlayerData.end_campaign_stage()
		get_tree().change_scene_to_file("res://scenes/ui/campaign_select_screen.tscn")
	elif PlayerData.is_dungeon_mode():
		PlayerData.end_dungeon()
		get_tree().change_scene_to_file("res://scenes/ui/dungeon_select_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
```

**Step 4: Commit**

```bash
git add scripts/ui/team_select_screen.gd
git commit -m "feat: add dungeon mode support to team select screen"
```

---

## Task 13: Update Currency Display

**Files:**
- Modify: `scripts/ui/collection_screen.gd`

**Step 1: Update currency label to include enhancement stones**

In `_update_currency_display()`:

```gdscript
func _update_currency_display():
	if currency_label:
		currency_label.text = str(PlayerData.gold) + " Gold | " + str(PlayerData.level_materials) + " Materials | " + str(PlayerData.gems) + " Gems | " + str(PlayerData.enhancement_stones) + " Stones"
```

**Step 2: Commit**

```bash
git add scripts/ui/collection_screen.gd
git commit -m "feat: add enhancement stones to currency display"
```

---

## Task 14: Update CHANGELOG.md

**Files:**
- Modify: `CHANGELOG.md`

**Step 1: Add v0.4 section at the top**

```markdown
## [0.4] - Gear System

### Added
- **Gear System**
  - Units can equip gear for stat bonuses
  - 4 gear slots per unit: Weapon, Armor, Accessory 1, Accessory 2
  - 4 rarity tiers: Common (+6 max), Rare (+9), Epic (+12), Legendary (+15)
  - Gear provides flat or percentage stat bonuses (HP, ATK, DEF, SPD)
  - Gear can be enhanced with Gold + Enhancement Stones

- **Gear Dungeons**
  - 4 new dungeons for farming gear:
    - Power Sanctum (ATK gear)
    - Fortress Ruins (DEF gear)
    - Vitality Caves (HP gear)
    - Wind Temple (SPD gear)
  - 3 difficulty tiers: Easy, Normal, Hard
  - Higher tiers drop better rarity gear and more stones
  - No stamina cost (unlimited farming)

- **New Currency**
  - Enhancement Stones: Used to level up gear
  - Starting amount: 50 stones

- **UI Updates**
  - Main menu: DUNGEONS and GEAR buttons
  - Gear inventory screen with enhancement
  - Collection screen: Gear slot display and equipping
  - Dungeon select screen with tier selection

### Changed
- Unit stats now include gear bonuses in battle
- Save file updated to include gear data (version 4)

---
```

**Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: add v0.4 gear system to changelog"
```

---

## Task 15: Final Testing & Verification

**Step 1: Launch Godot and verify no parse errors**

**Step 2: Test gear system flow:**
1. Main menu → DUNGEONS → Select Power Sanctum → Easy → Team Select → Battle → Win
2. Verify gear drop and stone rewards shown
3. Main menu → GEAR → Verify gear appears in inventory
4. Enhance the gear
5. Main menu → COLLECTION → Select a unit → Equip the gear
6. Verify stats update with gear bonus
7. Start a battle and verify unit uses gear stats

**Step 3: Test save/load:**
1. Close and reopen game
2. Verify gear inventory persists
3. Verify equipped gear persists

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete gear system implementation (v0.4)"
```

---

Plan complete and saved to `docs/plans/2026-01-21-gear-system-implementation.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?
