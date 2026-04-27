# Titan Inc Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first technical foundation of `Titan Inc`: a Godot 4.6 project with data-driven resources, autoload state/save services, simple combat actors, destructible structures, spawners, resources, and a playable debug city scene.

**Architecture:** Use the approved hybrid data-driven modular approach. Content and balance live in custom `Resource` classes and generated `.tres` assets; runtime scenes display and execute behavior; autoloads own global state, save/load, and cross-system signals.

**Tech Stack:** Godot 4.6 stable, GDScript only, `.tres` custom resources, local JSON save in `user://savegame.json`, manual/debug smoke validation instead of automated headless core tests because the project explicitly does not require core autotests yet.

---

## Scope Note

The approved vertical-slice spec contains many systems. This plan covers only the first foundation package that produces working, testable software on its own:

- Godot project skeleton.
- Autoload services.
- Resource class model.
- Initial resource assets for the first city.
- Simple runtime city scene.
- Continuous titan and defender spawning with limits.
- HP, damage, destruction, drops, basic repair.
- Debug economy actions and save/load.
- Documentation updates.

Full UI, final art, final balancing for a 2-3 hour city, full meta-tree visuals, advanced pathfinding, and offline rewards are outside this package.

## Godot Command

Use this executable for validation commands on the current machine:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --version
```

Expected output starts with:

```text
4.6.stable
```

## File Map

Create or modify these files during the plan:

```text
project.godot

autoload/
  signal_bus.gd
  game_state.gd
  save_service.gd

core/
  economy/cost_resource.gd
  economy/economy_service.gd
  math/progression_formula_resource.gd
  stats/unit_stats_resource.gd
  combat/damage_profile_resource.gd
  economy/drop_table_resource.gd

content/
  titans/titan_type_resource.gd
  defenders/defender_type_resource.gd
  structures/structure_type_resource.gd
  zones/zone_resource.gd
  spawning/spawn_rule_resource.gd
  catalogs/content_catalog.gd

world/
  defense_positions/defense_position_resource.gd
  city/city_scene.tscn
  city/city_scene.gd

actors/
  common/damageable.gd
  common/combat_actor.gd
  titan/titan_unit.tscn
  titan/titan_unit.gd
  defender/defender_unit.tscn
  defender/defender_unit.gd
  repair_worker/repair_worker.tscn
  repair_worker/repair_worker.gd

structures/
  destructible/destructible_structure.tscn
  destructible/destructible_structure.gd

systems/
  combat/battle_registry.gd
  combat/combat_resolver.gd
  spawning/titan_spawn_coordinator.gd
  spawning/defender_spawn_coordinator.gd
  targeting/targeting_service.gd
  repair/repair_coordinator.gd
  camera/horizontal_camera_controller.gd

ui/
  debug/debug_hud.tscn
  debug/debug_hud.gd

tools/
  generate_initial_content.gd

docs/
  architecture_context.md
  hotfixes.md
  vertical_slice_spec.md
```

---

### Task 1: Create Godot Project Skeleton

**Files:**
- Create: `project.godot`
- Create folders listed in the File Map

- [ ] **Step 1: Create folders**

Run:

```powershell
New-Item -ItemType Directory -Force -Path `
  'autoload', `
  'core\economy', 'core\math', 'core\stats', 'core\combat', `
  'content\titans', 'content\defenders', 'content\structures', 'content\zones', 'content\spawning', 'content\catalogs', `
  'world\city', 'world\defense_positions', `
  'actors\common', 'actors\titan', 'actors\defender', 'actors\repair_worker', `
  'structures\destructible', `
  'systems\combat', 'systems\spawning', 'systems\targeting', 'systems\repair', 'systems\camera', `
  'ui\debug', `
  'tools' | Out-Null
```

Expected: command exits with code `0`.

- [ ] **Step 2: Create `project.godot`**

Write this exact file:

```ini
; Engine configuration file.
; It is best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.

config_version=5

[application]

config/name="Titan Inc"
run/main_scene="res://world/city/city_scene.tscn"
config/features=PackedStringArray("4.6", "GL Compatibility")

[autoload]

SignalBus="*res://autoload/signal_bus.gd"
GameState="*res://autoload/game_state.gd"
SaveService="*res://autoload/save_service.gd"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

- [ ] **Step 3: Validate Godot executable**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --version
```

Expected: output starts with `4.6.stable`.

- [ ] **Step 4: Commit**

Run:

```powershell
git add project.godot
git commit -m "chore: create Godot project skeleton"
```

Expected: commit succeeds.

---

### Task 2: Add Global Signal, State, and Save Services

**Files:**
- Create: `autoload/signal_bus.gd`
- Create: `autoload/game_state.gd`
- Create: `autoload/save_service.gd`

- [ ] **Step 1: Create `autoload/signal_bus.gd`**

```gdscript
extends Node

signal resource_changed(resource_id: StringName, new_amount: float)
signal resource_gained(resource_id: StringName, amount: float, world_position: Vector2)
signal structure_destroyed(structure_id: StringName, world_position: Vector2)
signal unit_defeated(unit_id: StringName, team: StringName, world_position: Vector2)
signal hero_defeated(hero_id: StringName)
signal zone_completed(zone_id: StringName)
signal prestige_unlocked()
signal prestige_completed()
signal save_loaded()
signal game_state_changed()
```

- [ ] **Step 2: Create `autoload/game_state.gd`**

```gdscript
extends Node

const SAVE_VERSION := 1
const RESOURCE_IDS: Array[StringName] = [&"meat", &"stone", &"metal", &"hero_heart"]
const STARTING_ARMY_LIMITS := {
	&"small_titan": 1,
	&"runner_titan": 0,
	&"basic_titan": 0,
	&"armored_titan": 0,
	&"colossal_titan": 0,
}

var currencies: Dictionary = {}
var army_limits: Dictionary = {}
var upgrade_levels: Dictionary = {}
var meta_upgrade_levels: Dictionary = {}
var structure_hp: Dictionary = {}
var defeated_heroes: Dictionary = {}
var current_city_id: StringName = &"fantasy_city_01"
var current_zone_id: StringName = &"suburb"
var prestige_available := false
var fullscreen := false

func _ready() -> void:
	reset_all()

func reset_all() -> void:
	_reset_currencies(false)
	army_limits = STARTING_ARMY_LIMITS.duplicate(true)
	upgrade_levels = {}
	meta_upgrade_levels = {}
	structure_hp = {}
	defeated_heroes = {}
	current_city_id = &"fantasy_city_01"
	current_zone_id = &"suburb"
	prestige_available = false
	fullscreen = false
	SignalBus.game_state_changed.emit()

func reset_run_for_prestige() -> void:
	_reset_currencies(true)
	army_limits = STARTING_ARMY_LIMITS.duplicate(true)
	upgrade_levels = {}
	structure_hp = {}
	defeated_heroes = {}
	current_city_id = &"fantasy_city_01"
	current_zone_id = &"suburb"
	prestige_available = false
	SignalBus.prestige_completed.emit()
	SignalBus.game_state_changed.emit()

func _reset_currencies(keep_hearts: bool) -> void:
	var saved_hearts := get_currency(&"hero_heart") if keep_hearts else 0.0
	currencies = {}
	for resource_id in RESOURCE_IDS:
		currencies[resource_id] = 0.0
	currencies[&"hero_heart"] = saved_hearts

func get_currency(resource_id: StringName) -> float:
	return float(currencies.get(resource_id, 0.0))

func add_currency(resource_id: StringName, amount: float, world_position := Vector2.ZERO) -> void:
	if amount <= 0.0:
		return
	currencies[resource_id] = get_currency(resource_id) + amount
	SignalBus.resource_gained.emit(resource_id, amount, world_position)
	SignalBus.resource_changed.emit(resource_id, get_currency(resource_id))
	SignalBus.game_state_changed.emit()

func can_pay(cost: Dictionary) -> bool:
	for resource_id in cost.keys():
		if get_currency(resource_id) < float(cost[resource_id]):
			return false
	return true

func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	for resource_id in cost.keys():
		currencies[resource_id] = get_currency(resource_id) - float(cost[resource_id])
		SignalBus.resource_changed.emit(resource_id, get_currency(resource_id))
	SignalBus.game_state_changed.emit()
	return true

func get_army_limit(titan_id: StringName) -> int:
	return int(army_limits.get(titan_id, 0))

func increase_army_limit(titan_id: StringName, amount := 1) -> void:
	army_limits[titan_id] = clampi(get_army_limit(titan_id) + amount, 0, 100)
	SignalBus.game_state_changed.emit()

func mark_hero_defeated(hero_id: StringName) -> void:
	defeated_heroes[hero_id] = true
	prestige_available = true
	SignalBus.hero_defeated.emit(hero_id)
	SignalBus.prestige_unlocked.emit()
	SignalBus.game_state_changed.emit()

func to_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"currencies": _stringify_keys(currencies),
		"army_limits": _stringify_keys(army_limits),
		"upgrade_levels": _stringify_keys(upgrade_levels),
		"meta_upgrade_levels": _stringify_keys(meta_upgrade_levels),
		"structure_hp": _stringify_keys(structure_hp),
		"defeated_heroes": _stringify_keys(defeated_heroes),
		"current_city_id": String(current_city_id),
		"current_zone_id": String(current_zone_id),
		"prestige_available": prestige_available,
		"fullscreen": fullscreen,
	}

func load_save_data(data: Dictionary) -> void:
	reset_all()
	currencies = _name_keys(data.get("currencies", currencies))
	army_limits = _name_keys(data.get("army_limits", army_limits))
	upgrade_levels = _name_keys(data.get("upgrade_levels", {}))
	meta_upgrade_levels = _name_keys(data.get("meta_upgrade_levels", {}))
	structure_hp = _name_keys(data.get("structure_hp", {}))
	defeated_heroes = _name_keys(data.get("defeated_heroes", {}))
	current_city_id = StringName(data.get("current_city_id", "fantasy_city_01"))
	current_zone_id = StringName(data.get("current_zone_id", "suburb"))
	prestige_available = bool(data.get("prestige_available", false))
	fullscreen = bool(data.get("fullscreen", false))
	SignalBus.save_loaded.emit()
	SignalBus.game_state_changed.emit()

func _stringify_keys(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source.keys():
		result[String(key)] = source[key]
	return result

func _name_keys(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source.keys():
		result[StringName(str(key))] = source[key]
	return result
```

- [ ] **Step 3: Create `autoload/save_service.gd`**

```gdscript
extends Node

const SAVE_PATH := "user://savegame.json"

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file for write: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(GameState.to_save_data(), "\t"))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open save file for read: %s" % SAVE_PATH)
		return false
	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file is not a dictionary: %s" % SAVE_PATH)
		return false
	GameState.load_save_data(parsed)
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
```

- [ ] **Step 4: Validate scripts load in Godot**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --headless --path . --editor --quit
```

Expected: Godot exits with code `0` and no script parse errors.

- [ ] **Step 5: Commit**

```powershell
git add autoload project.godot
git commit -m "feat: add game state and save services"
```

Expected: commit succeeds.

---

### Task 3: Add Core Resource Classes

**Files:**
- Create: `core/economy/cost_resource.gd`
- Create: `core/math/progression_formula_resource.gd`
- Create: `core/stats/unit_stats_resource.gd`
- Create: `core/combat/damage_profile_resource.gd`
- Create: `core/economy/drop_table_resource.gd`
- Create: `core/economy/economy_service.gd`

- [ ] **Step 1: Create `core/economy/cost_resource.gd`**

```gdscript
extends Resource
class_name CostResource

@export var amounts: Dictionary = {}

func to_dictionary() -> Dictionary:
	var result := {}
	for key in amounts.keys():
		var amount := float(amounts[key])
		if amount > 0.0:
			result[StringName(str(key))] = amount
	return result

func multiplied(factor: float) -> Dictionary:
	var result := {}
	for key in amounts.keys():
		result[StringName(str(key))] = ceil(float(amounts[key]) * factor)
	return result
```

- [ ] **Step 2: Create `core/math/progression_formula_resource.gd`**

```gdscript
extends Resource
class_name ProgressionFormulaResource

enum FormulaMode {
	MULTIPLY_PREVIOUS,
	ADD_TO_PREVIOUS,
	EXPLICIT_TABLE,
}

@export var mode := FormulaMode.MULTIPLY_PREVIOUS
@export var factor := 2.0
@export var addend := 1.0
@export var explicit_costs: Array[Dictionary] = []

func next_cost(previous_cost: Dictionary, purchase_count: int) -> Dictionary:
	if mode == FormulaMode.EXPLICIT_TABLE and purchase_count < explicit_costs.size():
		return _name_keys(explicit_costs[purchase_count])
	if mode == FormulaMode.ADD_TO_PREVIOUS:
		return _add(previous_cost, addend)
	return _multiply(previous_cost, factor)

func _multiply(cost: Dictionary, value: float) -> Dictionary:
	var result := {}
	for key in cost.keys():
		result[StringName(str(key))] = ceil(float(cost[key]) * value)
	return result

func _add(cost: Dictionary, value: float) -> Dictionary:
	var result := {}
	for key in cost.keys():
		result[StringName(str(key))] = ceil(float(cost[key]) + value)
	return result

func _name_keys(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source.keys():
		result[StringName(str(key))] = source[key]
	return result
```

- [ ] **Step 3: Create `core/stats/unit_stats_resource.gd`**

```gdscript
extends Resource
class_name UnitStatsResource

@export var max_hp := 10.0
@export var damage := 1.0
@export var attack_rate := 1.0
@export var move_speed := 40.0
@export var attack_radius := 24.0
@export var attack_range := 0.0

func duplicate_stats() -> UnitStatsResource:
	var copy := UnitStatsResource.new()
	copy.max_hp = max_hp
	copy.damage = damage
	copy.attack_rate = attack_rate
	copy.move_speed = move_speed
	copy.attack_radius = attack_radius
	copy.attack_range = attack_range
	return copy
```

- [ ] **Step 4: Create `core/combat/damage_profile_resource.gd`**

```gdscript
extends Resource
class_name DamageProfileResource

@export var damage_type: StringName = &"physical"
@export var is_aoe := true
@export var critical_chance := 0.05
@export var critical_multiplier := 2.0
@export var structure_multiplier := 1.0
@export var unit_multiplier := 1.0

func roll_damage(base_damage: float, target_is_structure: bool) -> Dictionary:
	var multiplier := structure_multiplier if target_is_structure else unit_multiplier
	var critical := randf() < critical_chance
	var total := base_damage * multiplier
	if critical:
		total *= critical_multiplier
	return {
		"amount": total,
		"is_critical": critical,
		"damage_type": damage_type,
	}
```

- [ ] **Step 5: Create `core/economy/drop_table_resource.gd`**

```gdscript
extends Resource
class_name DropTableResource

@export var guaranteed: Dictionary = {}

func roll_drops() -> Dictionary:
	var result := {}
	for key in guaranteed.keys():
		var amount := float(guaranteed[key])
		if amount > 0.0:
			result[StringName(str(key))] = amount
	return result
```

- [ ] **Step 6: Create `core/economy/economy_service.gd`**

```gdscript
extends RefCounted
class_name EconomyService

static func can_pay(cost: Dictionary) -> bool:
	return GameState.can_pay(cost)

static func pay(cost: Dictionary) -> bool:
	return GameState.pay(cost)

static func grant(drops: Dictionary, world_position := Vector2.ZERO) -> void:
	for resource_id in drops.keys():
		GameState.add_currency(StringName(str(resource_id)), float(drops[resource_id]), world_position)
```

- [ ] **Step 7: Validate script parsing**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --headless --path . --editor --quit
```

Expected: Godot exits with code `0`.

- [ ] **Step 8: Commit**

```powershell
git add core
git commit -m "feat: add core resource primitives"
```

Expected: commit succeeds.

---

### Task 4: Add Content Resource Types and Initial Content Generator

**Files:**
- Create: `content/titans/titan_type_resource.gd`
- Create: `content/defenders/defender_type_resource.gd`
- Create: `content/structures/structure_type_resource.gd`
- Create: `content/zones/zone_resource.gd`
- Create: `content/spawning/spawn_rule_resource.gd`
- Create: `world/defense_positions/defense_position_resource.gd`
- Create: `content/catalogs/content_catalog.gd`
- Create: `tools/generate_initial_content.gd`
- Generated: `.tres` files in `content/`

- [ ] **Step 1: Create `content/titans/titan_type_resource.gd`**

```gdscript
extends Resource
class_name TitanTypeResource

@export var id: StringName
@export var display_name := ""
@export var scene: PackedScene
@export var base_stats: UnitStatsResource
@export var spawn_cooldown := 5.0
@export var max_army_limit := 100
@export var base_cost: CostResource
@export var cost_formula: ProgressionFormulaResource
@export var damage_profile: DamageProfileResource
@export var tags: Array[StringName] = []

func get_purchase_cost(current_limit: int) -> Dictionary:
	var cost := base_cost.to_dictionary()
	var purchases_after_first := maxi(current_limit - 1, 0)
	for i in range(purchases_after_first):
		cost = cost_formula.next_cost(cost, i)
	return cost
```

- [ ] **Step 2: Create `content/defenders/defender_type_resource.gd`**

```gdscript
extends Resource
class_name DefenderTypeResource

@export var id: StringName
@export var display_name := ""
@export var scene: PackedScene
@export var base_stats: UnitStatsResource
@export var spawn_weight := 1.0
@export var preferred_position_types: Array[StringName] = [&"ground"]
@export var can_climb_tower := false
@export var formation_spacing := 18.0
@export var damage_profile: DamageProfileResource
@export var drop_table: DropTableResource
@export var is_hero := false
```

- [ ] **Step 3: Create `content/structures/structure_type_resource.gd`**

```gdscript
extends Resource
class_name StructureTypeResource

@export var id: StringName
@export var display_name := ""
@export var scene: PackedScene
@export var max_hp := 100.0
@export var blocks_movement := true
@export var repairable := true
@export var objective_priority := 0
@export var drop_table: DropTableResource
@export var collapse_damage: DamageProfileResource
@export var garrison_slots := 0
@export var position := Vector2.ZERO
@export var size := Vector2(64.0, 64.0)
```

- [ ] **Step 4: Create zone, spawn, and defense-position resources**

Create `content/zones/zone_resource.gd`:

```gdscript
extends Resource
class_name ZoneResource

@export var id: StringName
@export var display_name := ""
@export var start_x := 0.0
@export var end_x := 1000.0
@export var structures: Array[StructureTypeResource] = []
@export var defender_spawn_rules: Array[SpawnRuleResource] = []
@export var defense_positions: Array[DefensePositionResource] = []
```

Create `content/spawning/spawn_rule_resource.gd`:

```gdscript
extends Resource
class_name SpawnRuleResource

@export var id: StringName
@export var spawn_cooldown := 5.0
@export var max_alive := 10
@export var allowed_types: Array[Resource] = []
```

Create `world/defense_positions/defense_position_resource.gd`:

```gdscript
extends Resource
class_name DefensePositionResource

@export var id: StringName
@export var position_type: StringName = &"ground"
@export var world_position := Vector2.ZERO
@export var capacity := 4
@export var linked_structure_id: StringName = &""
```

- [ ] **Step 5: Create `content/catalogs/content_catalog.gd`**

```gdscript
extends Node
class_name ContentCatalog

var titan_types: Dictionary = {}
var defender_types: Dictionary = {}
var structure_types: Dictionary = {}
var zones: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	titan_types = _load_resources("res://content/titans")
	defender_types = _load_resources("res://content/defenders")
	structure_types = _load_resources("res://content/structures")
	zones = _load_resources("res://content/zones")

func get_titan(id: StringName) -> TitanTypeResource:
	return titan_types.get(id) as TitanTypeResource

func get_defender(id: StringName) -> DefenderTypeResource:
	return defender_types.get(id) as DefenderTypeResource

func get_zone(id: StringName) -> ZoneResource:
	return zones.get(id) as ZoneResource

func _load_resources(path: String) -> Dictionary:
	var result := {}
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var resource := load(path.path_join(file_name))
		if resource != null:
			var resource_id = resource.get("id")
			if resource_id != null:
				result[StringName(str(resource_id))] = resource
	return result
```

- [ ] **Step 6: Create `tools/generate_initial_content.gd`**

Use an `EditorScript` to generate first-pass `.tres` assets with exact values from the spec. Include all five titans, six defenders plus hero, and three zones.

```gdscript
@tool
extends EditorScript

func _run() -> void:
	_save_titans()
	_save_defenders()
	_save_structures()
	_save_zones()
	print("Initial Titan Inc content generated.")

func _stats(hp: float, damage: float, rate: float, speed: float, radius: float, range_value := 0.0) -> UnitStatsResource:
	var stats := UnitStatsResource.new()
	stats.max_hp = hp
	stats.damage = damage
	stats.attack_rate = rate
	stats.move_speed = speed
	stats.attack_radius = radius
	stats.attack_range = range_value
	return stats

func _cost(amounts: Dictionary) -> CostResource:
	var cost := CostResource.new()
	cost.amounts = amounts
	return cost

func _formula() -> ProgressionFormulaResource:
	var formula := ProgressionFormulaResource.new()
	formula.mode = ProgressionFormulaResource.FormulaMode.MULTIPLY_PREVIOUS
	formula.factor = 2.0
	return formula

func _damage(structure_multiplier := 1.0, unit_multiplier := 1.0, crit_chance := 0.05) -> DamageProfileResource:
	var profile := DamageProfileResource.new()
	profile.structure_multiplier = structure_multiplier
	profile.unit_multiplier = unit_multiplier
	profile.critical_chance = crit_chance
	return profile

func _drops(amounts: Dictionary) -> DropTableResource:
	var drops := DropTableResource.new()
	drops.guaranteed = amounts
	return drops

func _save(path: String, resource: Resource) -> void:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Cannot save resource %s: %s" % [path, err])

func _save_titans() -> void:
	var data := [
		[&"small_titan", "Small Titan", 35.0, 3.0, 0.8, 42.0, 22.0, {"meat": 10.0}, [&"small"]],
		[&"runner_titan", "Runner Titan", 30.0, 5.0, 1.0, 75.0, 22.0, {"meat": 100.0}, [&"runner"]],
		[&"basic_titan", "Basic Titan", 70.0, 8.0, 0.9, 48.0, 26.0, {"meat": 250.0, "stone": 10.0}, [&"basic"]],
		[&"armored_titan", "Armored Titan", 180.0, 9.0, 0.7, 30.0, 28.0, {"meat": 1000.0, "metal": 10.0}, [&"armored"]],
		[&"colossal_titan", "Colossal Titan", 500.0, 45.0, 0.35, 18.0, 64.0, {"meat": 10000.0, "stone": 1000.0, "metal": 1000.0}, [&"colossal", &"siege"]],
	]
	for row in data:
		var titan := TitanTypeResource.new()
		titan.id = row[0]
		titan.display_name = row[1]
		titan.base_stats = _stats(row[2], row[3], row[4], row[5], row[6], 120.0 if titan.id == &"colossal_titan" else 0.0)
		titan.spawn_cooldown = 5.0
		titan.max_army_limit = 100
		titan.base_cost = _cost(row[7])
		titan.cost_formula = _formula()
		titan.damage_profile = _damage(1.25 if titan.id == &"colossal_titan" else 1.0, 1.0)
		titan.tags = row[8]
		_save("res://content/titans/%s.tres" % String(titan.id), titan)

func _save_defenders() -> void:
	var data := [
		[&"peasant", "Peasant", 12.0, 1.0, 0.7, 38.0, [&"ground"], false, {"meat": 1.0}, false],
		[&"archer", "Archer", 18.0, 2.5, 0.65, 35.0, [&"tower_top", &"wall_top"], true, {"meat": 2.0}, false],
		[&"warrior", "Warrior", 32.0, 4.0, 0.75, 35.0, [&"ground", &"gate_line"], false, {"meat": 4.0}, false],
		[&"knight", "Knight", 75.0, 8.0, 0.55, 28.0, [&"gate_line", &"ground"], false, {"meat": 8.0, "metal": 2.0}, false],
		[&"crossbowman", "Crossbowman", 26.0, 6.0, 0.45, 32.0, [&"wall_top", &"tower_top"], true, {"meat": 4.0, "metal": 1.0}, false],
		[&"rider", "Rider", 55.0, 7.0, 0.7, 62.0, [&"ground"], false, {"meat": 7.0, "metal": 1.0}, false],
		[&"first_hero", "First Hero", 900.0, 24.0, 0.65, 32.0, [&"gate_line"], false, {"hero_heart": 1.0}, true],
	]
	for row in data:
		var defender := DefenderTypeResource.new()
		defender.id = row[0]
		defender.display_name = row[1]
		defender.base_stats = _stats(row[2], row[3], row[4], row[5], 20.0, 80.0 if row[7] else 0.0)
		defender.spawn_weight = 1.0
		defender.preferred_position_types = row[6]
		defender.can_climb_tower = row[7]
		defender.formation_spacing = 18.0
		defender.damage_profile = _damage(0.8, 1.0)
		defender.drop_table = _drops(row[8])
		defender.is_hero = row[9]
		_save("res://content/defenders/%s.tres" % String(defender.id), defender)

func _save_structures() -> void:
	var data := [
		[&"suburb_house", "Suburb House", 120.0, true, true, 1, {"stone": 5.0}, 0, Vector2(450, 390), Vector2(60, 52)],
		[&"wooden_fence", "Wooden Fence", 45.0, true, true, 0, {"stone": 1.0}, 0, Vector2(650, 420), Vector2(90, 24)],
		[&"outer_tower_left", "Outer Tower Left", 550.0, true, true, 3, {"stone": 40.0, "metal": 5.0}, 4, Vector2(1200, 310), Vector2(72, 130)],
		[&"outer_tower_right", "Outer Tower Right", 550.0, true, true, 3, {"stone": 40.0, "metal": 5.0}, 4, Vector2(1200, 500), Vector2(72, 130)],
		[&"wall_gate", "Wall Gate", 1400.0, true, true, 5, {"stone": 140.0, "metal": 25.0}, 2, Vector2(1850, 405), Vector2(90, 150)],
		[&"wall_tower_left", "Wall Tower Left", 900.0, true, true, 6, {"stone": 90.0, "metal": 15.0}, 5, Vector2(1740, 300), Vector2(82, 150)],
		[&"wall_tower_right", "Wall Tower Right", 900.0, true, true, 6, {"stone": 90.0, "metal": 15.0}, 5, Vector2(1740, 510), Vector2(82, 150)],
	]
	for row in data:
		var structure := StructureTypeResource.new()
		structure.id = row[0]
		structure.display_name = row[1]
		structure.max_hp = row[2]
		structure.blocks_movement = row[3]
		structure.repairable = row[4]
		structure.objective_priority = row[5]
		structure.drop_table = _drops(row[6])
		structure.collapse_damage = _damage(1.0, 1.0)
		structure.garrison_slots = row[7]
		structure.position = row[8]
		structure.size = row[9]
		_save("res://content/structures/%s.tres" % String(structure.id), structure)

func _save_zones() -> void:
	var suburb := ZoneResource.new()
	suburb.id = &"suburb"
	suburb.display_name = "Suburb"
	suburb.start_x = 0.0
	suburb.end_x = 900.0
	suburb.structures = [
		load("res://content/structures/suburb_house.tres"),
		load("res://content/structures/wooden_fence.tres"),
	]
	_save("res://content/zones/suburb.tres", suburb)

	var towers := ZoneResource.new()
	towers.id = &"towers"
	towers.display_name = "Towers"
	towers.start_x = 900.0
	towers.end_x = 1500.0
	towers.structures = [
		load("res://content/structures/outer_tower_left.tres"),
		load("res://content/structures/outer_tower_right.tres"),
	]
	_save("res://content/zones/towers.tres", towers)

	var wall := ZoneResource.new()
	wall.id = &"wall"
	wall.display_name = "Wall"
	wall.start_x = 1500.0
	wall.end_x = 2200.0
	wall.structures = [
		load("res://content/structures/wall_tower_left.tres"),
		load("res://content/structures/wall_gate.tres"),
		load("res://content/structures/wall_tower_right.tres"),
	]
	_save("res://content/zones/wall.tres", wall)
```

- [ ] **Step 7: Generate content**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --headless --path . --editor --script tools/generate_initial_content.gd
```

Expected: output contains `Initial Titan Inc content generated.` and `.tres` files appear under `content/titans`, `content/defenders`, `content/structures`, and `content/zones`.

- [ ] **Step 8: Commit**

```powershell
git add content world/defense_positions tools
git commit -m "feat: add data-driven content resources"
```

Expected: commit succeeds.

---

### Task 5: Add Runtime Actors, Damageable Component, and Destructible Structures

**Files:**
- Create: `actors/common/damageable.gd`
- Create: `actors/common/combat_actor.gd`
- Create: `actors/titan/titan_unit.gd`
- Create: `actors/defender/defender_unit.gd`
- Create: `actors/repair_worker/repair_worker.gd`
- Create scenes: `actors/titan/titan_unit.tscn`, `actors/defender/defender_unit.tscn`, `actors/repair_worker/repair_worker.tscn`
- Create: `structures/destructible/destructible_structure.gd`
- Create: `structures/destructible/destructible_structure.tscn`

- [ ] **Step 1: Create `actors/common/damageable.gd`**

```gdscript
extends Node
class_name Damageable

signal hp_changed(current_hp: float, max_hp: float)
signal died(source_id: StringName)

@export var max_hp := 10.0
var current_hp := 10.0
var dead := false

func configure(value: float) -> void:
	max_hp = maxf(value, 1.0)
	current_hp = max_hp
	dead = false
	hp_changed.emit(current_hp, max_hp)

func apply_damage(amount: float, source_id: StringName = &"") -> void:
	if dead or amount <= 0.0:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		dead = true
		died.emit(source_id)

func repair(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	current_hp = minf(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)

func set_current_hp(value: float, emit_death := false) -> void:
	current_hp = clampf(value, 0.0, max_hp)
	dead = current_hp <= 0.0
	hp_changed.emit(current_hp, max_hp)
	if dead and emit_death:
		died.emit(&"save_state")
```

- [ ] **Step 2: Create `actors/common/combat_actor.gd`**

```gdscript
extends Node2D
class_name CombatActor

signal defeated(actor: CombatActor)

@export var team: StringName = &"neutral"
@export var actor_id: StringName
@export var display_color := Color.WHITE

var stats: UnitStatsResource
var damage_profile: DamageProfileResource
var drop_table: DropTableResource
var target_x := 0.0
var attack_cooldown := 0.0
var assigned_position := Vector2.ZERO

@onready var damageable: Damageable = $Damageable
@onready var body: ColorRect = $Body
@onready var hp_bar: ProgressBar = $HpBar

func _ready() -> void:
	body.color = display_color
	damageable.hp_changed.connect(_on_hp_changed)
	damageable.died.connect(_on_died)

func configure(id_value: StringName, stats_value: UnitStatsResource, damage_value: DamageProfileResource, drops_value: DropTableResource = null) -> void:
	actor_id = id_value
	stats = stats_value.duplicate_stats()
	damage_profile = damage_value
	drop_table = drops_value
	damageable.configure(stats.max_hp)
	_on_hp_changed(stats.max_hp, stats.max_hp)

func tick_movement(delta: float) -> void:
	if damageable.dead or stats == null:
		return
	var direction := signf(target_x - global_position.x)
	if absf(target_x - global_position.x) < 4.0:
		return
	global_position.x += direction * stats.move_speed * delta

func can_attack() -> bool:
	return attack_cooldown <= 0.0 and stats != null and not damageable.dead

func consume_attack_cooldown() -> void:
	attack_cooldown = 1.0 / maxf(stats.attack_rate, 0.01)

func _process(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)

func _on_hp_changed(current_hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

func _on_died(_source_id: StringName) -> void:
	visible = false
	defeated.emit(self)
```

- [ ] **Step 3: Create titan, defender, and repair scripts**

Create `actors/titan/titan_unit.gd`:

```gdscript
extends CombatActor
class_name TitanUnit

var titan_type: TitanTypeResource

func configure_titan(type: TitanTypeResource, spawn_target_x: float) -> void:
	titan_type = type
	team = &"titans"
	display_color = Color(0.8, 0.28, 0.18)
	target_x = spawn_target_x
	configure(type.id, type.base_stats, type.damage_profile, null)
```

Create `actors/defender/defender_unit.gd`:

```gdscript
extends CombatActor
class_name DefenderUnit

var defender_type: DefenderTypeResource

func configure_defender(type: DefenderTypeResource, position: Vector2) -> void:
	defender_type = type
	team = &"defenders"
	display_color = Color(0.22, 0.42, 0.85)
	assigned_position = position
	target_x = position.x
	configure(type.id, type.base_stats, type.damage_profile, type.drop_table)
```

Create `actors/repair_worker/repair_worker.gd`:

```gdscript
extends CombatActor
class_name RepairWorker

var repair_per_second := 8.0
var target_structure: DestructibleStructure

func configure_worker(target: DestructibleStructure) -> void:
	team = &"defenders"
	display_color = Color(0.95, 0.8, 0.25)
	target_structure = target
	target_x = target.global_position.x
	var worker_stats := UnitStatsResource.new()
	worker_stats.max_hp = 16.0
	worker_stats.damage = 0.0
	worker_stats.attack_rate = 1.0
	worker_stats.move_speed = 50.0
	worker_stats.attack_radius = 0.0
	configure(&"repair_worker", worker_stats, DamageProfileResource.new(), DropTableResource.new())

func _process(delta: float) -> void:
	super._process(delta)
	if target_structure == null or target_structure.is_destroyed():
		return
	if absf(global_position.x - target_structure.global_position.x) > 12.0:
		tick_movement(delta)
	else:
		target_structure.repair(repair_per_second * delta)
```

- [ ] **Step 4: Create simple actor scenes**

Create each actor scene with this node layout:

```text
Node2D root with script
  Damageable
  ColorRect Body
  ProgressBar HpBar
```

For `actors/titan/titan_unit.tscn`, root script is `res://actors/titan/titan_unit.gd`; `Body` size is `(18, 34)`; `HpBar` position is `(-12, -22)`, size `(24, 4)`.

For `actors/defender/defender_unit.tscn`, root script is `res://actors/defender/defender_unit.gd`; `Body` size is `(12, 20)`; `HpBar` position is `(-10, -16)`, size `(20, 4)`.

For `actors/repair_worker/repair_worker.tscn`, root script is `res://actors/repair_worker/repair_worker.gd`; `Body` size is `(10, 18)`; `HpBar` position is `(-10, -16)`, size `(20, 4)`.

- [ ] **Step 5: Create destructible structure script and scene**

Create `structures/destructible/destructible_structure.gd`:

```gdscript
extends StaticBody2D
class_name DestructibleStructure

signal destroyed(structure: DestructibleStructure)

var structure_type: StructureTypeResource

@onready var damageable: Damageable = $Damageable
@onready var body: ColorRect = $Body
@onready var hp_bar: ProgressBar = $HpBar

func _ready() -> void:
	damageable.hp_changed.connect(_on_hp_changed)
	damageable.died.connect(_on_died)

func configure_structure(type: StructureTypeResource) -> void:
	structure_type = type
	global_position = type.position
	body.size = type.size
	body.position = -type.size * 0.5
	damageable.configure(type.max_hp)
	if GameState.structure_hp.has(type.id):
		damageable.set_current_hp(float(GameState.structure_hp[type.id]))
	_on_hp_changed(damageable.current_hp, damageable.max_hp)

func apply_damage(amount: float, source_id: StringName = &"") -> void:
	damageable.apply_damage(amount, source_id)

func repair(amount: float) -> void:
	if structure_type != null and structure_type.repairable:
		damageable.repair(amount)

func is_destroyed() -> bool:
	return damageable.dead

func _on_hp_changed(current_hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	if structure_type != null:
		GameState.structure_hp[structure_type.id] = current_hp

func _on_died(_source_id: StringName) -> void:
	visible = false
	collision_layer = 0
	collision_mask = 0
	if structure_type != null:
		GameState.structure_hp[structure_type.id] = 0.0
		EconomyService.grant(structure_type.drop_table.roll_drops(), global_position)
		SignalBus.structure_destroyed.emit(structure_type.id, global_position)
	destroyed.emit(self)
```

Create `structures/destructible/destructible_structure.tscn` with:

```text
StaticBody2D root with script res://structures/destructible/destructible_structure.gd
  Damageable
  ColorRect Body
  ProgressBar HpBar
```

- [ ] **Step 6: Validate in Godot**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --headless --path . --editor --quit
```

Expected: exit code `0`.

- [ ] **Step 7: Commit**

```powershell
git add actors structures
git commit -m "feat: add combat actors and destructible structures"
```

Expected: commit succeeds.

---

### Task 6: Add Battle Registry and Combat Resolver

**Files:**
- Create: `systems/combat/battle_registry.gd`
- Create: `systems/combat/combat_resolver.gd`
- Create: `systems/targeting/targeting_service.gd`

- [ ] **Step 1: Create `systems/combat/battle_registry.gd`**

```gdscript
extends Node
class_name BattleRegistry

var titans: Array[TitanUnit] = []
var defenders: Array[DefenderUnit] = []
var repair_workers: Array[RepairWorker] = []
var structures: Array[DestructibleStructure] = []

func register_titan(unit: TitanUnit) -> void:
	titans.append(unit)
	unit.defeated.connect(_on_titan_defeated)

func register_defender(unit: DefenderUnit) -> void:
	defenders.append(unit)
	unit.defeated.connect(_on_defender_defeated)

func register_repair_worker(unit: RepairWorker) -> void:
	repair_workers.append(unit)
	unit.defeated.connect(_on_repair_worker_defeated)

func register_structure(structure: DestructibleStructure) -> void:
	structures.append(structure)
	structure.destroyed.connect(_on_structure_destroyed)

func alive_titans() -> Array[TitanUnit]:
	return titans.filter(func(unit: TitanUnit) -> bool: return is_instance_valid(unit) and not unit.damageable.dead)

func alive_defenders() -> Array[DefenderUnit]:
	return defenders.filter(func(unit: DefenderUnit) -> bool: return is_instance_valid(unit) and not unit.damageable.dead)

func alive_structures() -> Array[DestructibleStructure]:
	return structures.filter(func(item: DestructibleStructure) -> bool: return is_instance_valid(item) and not item.is_destroyed())

func alive_repair_workers() -> Array[RepairWorker]:
	return repair_workers.filter(func(unit: RepairWorker) -> bool: return is_instance_valid(unit) and not unit.damageable.dead)

func _on_titan_defeated(unit: CombatActor) -> void:
	SignalBus.unit_defeated.emit(unit.actor_id, unit.team, unit.global_position)

func _on_defender_defeated(unit: CombatActor) -> void:
	if unit.drop_table != null:
		EconomyService.grant(unit.drop_table.roll_drops(), unit.global_position)
	if unit is DefenderUnit and unit.defender_type != null and unit.defender_type.is_hero:
		GameState.add_currency(&"hero_heart", 1.0, unit.global_position)
		GameState.mark_hero_defeated(unit.defender_type.id)
	SignalBus.unit_defeated.emit(unit.actor_id, unit.team, unit.global_position)

func _on_repair_worker_defeated(unit: CombatActor) -> void:
	SignalBus.unit_defeated.emit(unit.actor_id, unit.team, unit.global_position)

func _on_structure_destroyed(_structure: DestructibleStructure) -> void:
	pass
```

- [ ] **Step 2: Create `systems/targeting/targeting_service.gd`**

```gdscript
extends RefCounted
class_name TargetingService

static func nearest_structure_in_front(unit: CombatActor, structures: Array[DestructibleStructure]) -> DestructibleStructure:
	var best: DestructibleStructure = null
	var best_distance := INF
	for structure in structures:
		if not is_instance_valid(structure) or structure.is_destroyed():
			continue
		if structure.global_position.x < unit.global_position.x - 8.0:
			continue
		var distance := unit.global_position.distance_to(structure.global_position)
		if distance < best_distance:
			best = structure
			best_distance = distance
	return best

static func units_in_radius(origin: Vector2, radius: float, units: Array) -> Array:
	var result := []
	for unit in units:
		if is_instance_valid(unit) and not unit.damageable.dead and origin.distance_to(unit.global_position) <= radius:
			result.append(unit)
	return result
```

- [ ] **Step 3: Create `systems/combat/combat_resolver.gd`**

```gdscript
extends Node
class_name CombatResolver

@export var registry_path: NodePath

@onready var registry: BattleRegistry = get_node(registry_path)

func _process(_delta: float) -> void:
	_resolve_titan_attacks()
	_resolve_defender_attacks()

func _resolve_titan_attacks() -> void:
	for titan in registry.alive_titans():
		if not titan.can_attack():
			continue
		var hit_anything := false
		for defender in TargetingService.units_in_radius(titan.global_position, titan.stats.attack_radius, registry.alive_defenders()):
			var roll := titan.damage_profile.roll_damage(titan.stats.damage, false)
			defender.damageable.apply_damage(roll.amount, titan.actor_id)
			hit_anything = true
		var target_structure := TargetingService.nearest_structure_in_front(titan, registry.alive_structures())
		if target_structure != null and titan.global_position.distance_to(target_structure.global_position) <= titan.stats.attack_radius:
			var roll := titan.damage_profile.roll_damage(titan.stats.damage, true)
			target_structure.apply_damage(roll.amount, titan.actor_id)
			hit_anything = true
		if hit_anything:
			titan.consume_attack_cooldown()

func _resolve_defender_attacks() -> void:
	for defender in registry.alive_defenders():
		if not defender.can_attack():
			continue
		var targets := TargetingService.units_in_radius(defender.global_position, defender.stats.attack_radius + defender.stats.attack_range, registry.alive_titans())
		if targets.is_empty():
			continue
		var target: TitanUnit = targets[0]
		var roll := defender.damage_profile.roll_damage(defender.stats.damage, false)
		target.damageable.apply_damage(roll.amount, defender.actor_id)
		defender.consume_attack_cooldown()
```

- [ ] **Step 4: Validate**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --headless --path . --editor --quit
```

Expected: exit code `0`.

- [ ] **Step 5: Commit**

```powershell
git add systems/combat systems/targeting
git commit -m "feat: add battle registry and combat resolver"
```

Expected: commit succeeds.

---

### Task 7: Add Spawning, Repair, Camera, Debug HUD, and City Scene

**Files:**
- Create: `systems/spawning/titan_spawn_coordinator.gd`
- Create: `systems/spawning/defender_spawn_coordinator.gd`
- Create: `systems/repair/repair_coordinator.gd`
- Create: `systems/camera/horizontal_camera_controller.gd`
- Create: `ui/debug/debug_hud.gd`
- Create: `ui/debug/debug_hud.tscn`
- Create: `world/city/city_scene.gd`
- Create: `world/city/city_scene.tscn`

- [ ] **Step 1: Create `systems/spawning/titan_spawn_coordinator.gd`**

```gdscript
extends Node
class_name TitanSpawnCoordinator

@export var registry_path: NodePath
@export var catalog_path: NodePath
@export var titan_scene: PackedScene
@export var spawn_origin := Vector2(80, 420)
@export var target_x := 2200.0

var timers: Dictionary = {}

@onready var registry: BattleRegistry = get_node(registry_path)
@onready var catalog: ContentCatalog = get_node(catalog_path)

func _process(delta: float) -> void:
	for titan_id in catalog.titan_types.keys():
		var limit := GameState.get_army_limit(titan_id)
		if limit <= 0:
			continue
		var alive := registry.alive_titans().filter(func(unit: TitanUnit) -> bool: return unit.actor_id == titan_id).size()
		if alive >= limit:
			continue
		timers[titan_id] = maxf(float(timers.get(titan_id, 0.0)) - delta, 0.0)
		if timers[titan_id] <= 0.0:
			_spawn_titan(catalog.get_titan(titan_id))

func _spawn_titan(type: TitanTypeResource) -> void:
	var unit: TitanUnit = titan_scene.instantiate()
	unit.global_position = spawn_origin + Vector2(randf_range(-20, 20), randf_range(-70, 70))
	unit.configure_titan(type, target_x)
	get_tree().current_scene.add_child(unit)
	registry.register_titan(unit)
	timers[type.id] = type.spawn_cooldown
```

- [ ] **Step 2: Create `systems/spawning/defender_spawn_coordinator.gd`**

```gdscript
extends Node
class_name DefenderSpawnCoordinator

@export var registry_path: NodePath
@export var catalog_path: NodePath
@export var defender_scene: PackedScene
@export var spawn_origin := Vector2(2250, 420)
@export var max_alive := 24
@export var spawn_cooldown := 2.5

var timer := 0.0
var defense_positions := [
	Vector2(900, 390),
	Vector2(1180, 320),
	Vector2(1180, 500),
	Vector2(1680, 380),
	Vector2(1780, 300),
	Vector2(1780, 510),
]

@onready var registry: BattleRegistry = get_node(registry_path)
@onready var catalog: ContentCatalog = get_node(catalog_path)

func _process(delta: float) -> void:
	if registry.alive_defenders().size() >= max_alive:
		return
	timer = maxf(timer - delta, 0.0)
	if timer > 0.0:
		return
	var defender_id := _pick_defender_id()
	_spawn_defender(catalog.get_defender(defender_id))
	timer = spawn_cooldown

func _pick_defender_id() -> StringName:
	var ids := catalog.defender_types.keys().filter(func(id: StringName) -> bool: return id != &"first_hero")
	if GameState.get_currency(&"meat") > 250.0 and not GameState.defeated_heroes.get(&"first_hero", false):
		return &"first_hero"
	return ids.pick_random()

func _spawn_defender(type: DefenderTypeResource) -> void:
	var unit: DefenderUnit = defender_scene.instantiate()
	var position: Vector2 = defense_positions.pick_random()
	unit.global_position = spawn_origin + Vector2(randf_range(-20, 20), randf_range(-80, 80))
	unit.configure_defender(type, position)
	get_tree().current_scene.add_child(unit)
	registry.register_defender(unit)
```

- [ ] **Step 3: Create `systems/repair/repair_coordinator.gd`**

```gdscript
extends Node
class_name RepairCoordinator

@export var registry_path: NodePath
@export var repair_worker_scene: PackedScene
@export var spawn_origin := Vector2(2250, 460)
@export var max_workers := 4
@export var spawn_cooldown := 8.0

var timer := 0.0

@onready var registry: BattleRegistry = get_node(registry_path)

func _process(delta: float) -> void:
	timer = maxf(timer - delta, 0.0)
	if timer > 0.0 or registry.alive_repair_workers().size() >= max_workers:
		return
	var target := _find_repair_target()
	if target == null:
		return
	var worker: RepairWorker = repair_worker_scene.instantiate()
	worker.global_position = spawn_origin + Vector2(randf_range(-20, 20), randf_range(-60, 60))
	worker.configure_worker(target)
	get_tree().current_scene.add_child(worker)
	registry.register_repair_worker(worker)
	timer = spawn_cooldown

func _find_repair_target() -> DestructibleStructure:
	for structure in registry.alive_structures():
		if structure.structure_type != null and structure.structure_type.repairable and structure.damageable.current_hp < structure.damageable.max_hp:
			return structure
	return null
```

- [ ] **Step 4: Create `systems/camera/horizontal_camera_controller.gd`**

```gdscript
extends Camera2D
class_name HorizontalCameraController

@export var pan_speed := 520.0
@export var min_x := 0.0
@export var max_x := 2200.0

var dragging := false
var last_mouse_position := Vector2.ZERO

func _process(delta: float) -> void:
	var input := 0.0
	if Input.is_key_pressed(KEY_A):
		input -= 1.0
	if Input.is_key_pressed(KEY_D):
		input += 1.0
	global_position.x = clampf(global_position.x + input * pan_speed * delta, min_x, max_x)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		dragging = event.pressed
		last_mouse_position = event.position
	if dragging and event is InputEventMouseMotion:
		global_position.x = clampf(global_position.x - event.relative.x, min_x, max_x)
```

- [ ] **Step 5: Create `ui/debug/debug_hud.gd`**

```gdscript
extends CanvasLayer
class_name DebugHud

@onready var label: Label = $Panel/Label

func _ready() -> void:
	SignalBus.game_state_changed.connect(_refresh)
	_refresh()

func _catalog() -> ContentCatalog:
	return get_tree().current_scene.get_node("ContentCatalog") as ContentCatalog

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		GameState.add_currency(&"meat", 100.0)
		GameState.add_currency(&"stone", 25.0)
		GameState.add_currency(&"metal", 10.0)
	if Input.is_key_pressed(KEY_F5):
		SaveService.save_game()
	if Input.is_key_pressed(KEY_F9):
		SaveService.load_game()
	_refresh()

func _refresh() -> void:
	label.text = "Meat: %s\nStone: %s\nMetal: %s\nHearts: %s\nSmall limit: %s\nRunner limit: %s\nBasic limit: %s\nArmored limit: %s\nColossal limit: %s\nEnter: grant debug resources\nF5: save\nF9: load" % [
		GameState.get_currency(&"meat"),
		GameState.get_currency(&"stone"),
		GameState.get_currency(&"metal"),
		GameState.get_currency(&"hero_heart"),
		GameState.get_army_limit(&"small_titan"),
		GameState.get_army_limit(&"runner_titan"),
		GameState.get_army_limit(&"basic_titan"),
		GameState.get_army_limit(&"armored_titan"),
		GameState.get_army_limit(&"colossal_titan"),
	]
```

Create `ui/debug/debug_hud.tscn`:

```text
CanvasLayer root with script res://ui/debug/debug_hud.gd
  Panel
    Label
```

- [ ] **Step 6: Create `world/city/city_scene.gd`**

```gdscript
extends Node2D

@onready var catalog: ContentCatalog = $ContentCatalog
@onready var registry: BattleRegistry = $BattleRegistry

func _ready() -> void:
	_spawn_structures()
	SaveService.load_game()

func _spawn_structures() -> void:
	await get_tree().process_frame
	var structure_scene: PackedScene = preload("res://structures/destructible/destructible_structure.tscn")
	for zone_id in [&"suburb", &"towers", &"wall"]:
		var zone := catalog.get_zone(zone_id)
		if zone == null:
			continue
		for structure_type in zone.structures:
			var structure: DestructibleStructure = structure_scene.instantiate()
			add_child(structure)
			structure.configure_structure(structure_type)
			registry.register_structure(structure)
```

- [ ] **Step 7: Create `world/city/city_scene.tscn`**

Create a scene with this node tree:

```text
Node2D CityScene with script res://world/city/city_scene.gd
  ContentCatalog with script res://content/catalogs/content_catalog.gd
  BattleRegistry with script res://systems/combat/battle_registry.gd
  CombatResolver with script res://systems/combat/combat_resolver.gd
  TitanSpawnCoordinator with script res://systems/spawning/titan_spawn_coordinator.gd
  DefenderSpawnCoordinator with script res://systems/spawning/defender_spawn_coordinator.gd
  RepairCoordinator with script res://systems/repair/repair_coordinator.gd
  Camera2D with script res://systems/camera/horizontal_camera_controller.gd
  DebugHud instance res://ui/debug/debug_hud.tscn
```

Set exported NodePaths:

```text
CombatResolver.registry_path = "../BattleRegistry"
TitanSpawnCoordinator.registry_path = "../BattleRegistry"
TitanSpawnCoordinator.catalog_path = "../ContentCatalog"
TitanSpawnCoordinator.titan_scene = res://actors/titan/titan_unit.tscn
DefenderSpawnCoordinator.registry_path = "../BattleRegistry"
DefenderSpawnCoordinator.catalog_path = "../ContentCatalog"
DefenderSpawnCoordinator.defender_scene = res://actors/defender/defender_unit.tscn
RepairCoordinator.registry_path = "../BattleRegistry"
RepairCoordinator.repair_worker_scene = res://actors/repair_worker/repair_worker.tscn
```

- [ ] **Step 8: Validate**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --headless --path . --editor --quit
```

Expected: exit code `0`.

- [ ] **Step 9: Manual smoke check**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --path .
```

Expected in the opened window:

- The debug HUD appears.
- At least one small titan spawns on the left.
- Defenders spawn from the right and move to positions.
- Structures are visible as simple rectangles.
- Pressing `Enter` grants debug resources.
- Pressing `F5` saves without an error in the console.
- Pressing `F9` loads without an error in the console.

- [ ] **Step 10: Commit**

```powershell
git add systems ui world actors structures
git commit -m "feat: add playable debug city scene"
```

Expected: commit succeeds.

---

### Task 8: Add Debug Army Limit Purchases

**Files:**
- Modify: `ui/debug/debug_hud.gd`
- Modify: `autoload/save_service.gd`

- [ ] **Step 1: Add purchase helpers to `ui/debug/debug_hud.gd`**

Replace `_process` with:

```gdscript
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		GameState.add_currency(&"meat", 100.0)
		GameState.add_currency(&"stone", 25.0)
		GameState.add_currency(&"metal", 10.0)
	if Input.is_key_pressed(KEY_1):
		_buy_limit(&"small_titan")
	if Input.is_key_pressed(KEY_2):
		_buy_limit(&"runner_titan")
	if Input.is_key_pressed(KEY_3):
		_buy_limit(&"basic_titan")
	if Input.is_key_pressed(KEY_4):
		_buy_limit(&"armored_titan")
	if Input.is_key_pressed(KEY_5):
		_buy_limit(&"colossal_titan")
	if Input.is_key_pressed(KEY_F5):
		SaveService.save_game()
	if Input.is_key_pressed(KEY_F9):
		SaveService.load_game()
	_refresh()

func _buy_limit(titan_id: StringName) -> void:
	if GameState.get_army_limit(titan_id) >= 100:
		return
	var current_limit := GameState.get_army_limit(titan_id)
	var titan := _catalog().get_titan(titan_id)
	if titan == null:
		return
	var cost := titan.get_purchase_cost(current_limit)
	if GameState.pay(cost):
		GameState.increase_army_limit(titan_id, 1)
		SaveService.save_game()
```

Update the last lines of `_refresh` text to include:

```gdscript
"Enter: grant debug resources\n1-5: buy titan limits\nF5: save\nF9: load"
```

- [ ] **Step 2: Validate purchase flow manually**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --path .
```

Expected:

- Press `Enter` until resources are available.
- Press `1`; small titan limit increases.
- Press `2`; runner titan limit increases if meat is at least 100.
- Press `F5`, close game, reopen, press `F9`; purchased limits are restored.

- [ ] **Step 3: Commit**

```powershell
git add ui/debug/debug_hud.gd autoload/save_service.gd
git commit -m "feat: add debug army limit purchases"
```

Expected: commit succeeds.

---

### Task 9: Update Documentation After Foundation Implementation

**Files:**
- Modify: `docs/architecture_context.md`
- Modify: `docs/vertical_slice_spec.md`
- Modify: `docs/hotfixes.md`

- [ ] **Step 1: Update architecture context**

Add a section near the top of `docs/architecture_context.md`:

```markdown
## Current Implementation Snapshot

The first foundation package now contains a Godot 4.6 project skeleton, autoload services, custom Resource classes, generated first-pass content resources, a debug city scene, basic spawning, HP/damage/destruction, resource drops, debug army-limit purchases, and JSON save/load.

The current visual layer uses simple rectangle actors and structures. These are temporary presentation assets; gameplay values still come from Resource data.
```

- [ ] **Step 2: Update vertical slice spec acceptance status**

Add a section at the end of `docs/vertical_slice_spec.md`:

```markdown
## Foundation Package Status

Implemented in the first technical package:

- Godot project startup.
- Autoload `SignalBus`, `GameState`, and `SaveService`.
- Custom Resource classes for core combat/economy/content data.
- Initial content resources for titans, defenders, structures, and zones.
- Debug city scene with simple visual actors.
- Continuous titan and defender spawning.
- HP, damage, destruction, drops, and basic repair workers.
- Debug resource granting and army-limit purchases.
- JSON save/load for core `GameState`.

Remaining vertical-slice work:

- Final UI/UX.
- Real pixel art and animation.
- Full balance pass for 2-3 hour first city pacing.
- Cursor boost visualization and meta-upgrade table.
- More complete tower climbing, formation, collapse debris, and zone completion polish.
```

- [ ] **Step 3: Add hotfix note only if an architectural shortcut was used**

If no shortcut was used, append this to `docs/hotfixes.md`:

```markdown
## 2026-04-27 - Foundation package

- Причина: первый технический пакет создан по утвержденной архитектуре.
- Изменение: hotfix-исправлений нет.
- Риск: отсутствует.
- Что нужно пересмотреть позже: файл остается журналом для будущих срочных исправлений.
```

- [ ] **Step 4: Commit docs**

```powershell
git add docs
git commit -m "docs: update foundation implementation context"
```

Expected: commit succeeds.

---

### Task 10: Final Verification for Foundation Package

**Files:**
- No file edits unless verification reveals a concrete issue.

- [ ] **Step 1: Run Godot parser validation**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --headless --path . --editor --quit
```

Expected: exit code `0`, no script parse errors.

- [ ] **Step 2: Run manual smoke validation**

Run:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
& $Godot --path .
```

Expected visible behavior:

- The project opens into `world/city/city_scene.tscn`.
- Debug HUD is visible.
- Small titan units spawn from the left.
- Defender units spawn from the right and move toward defense positions.
- Titans and defenders damage each other when in range.
- Structures lose HP and disappear when destroyed.
- Resources increase after unit death or structure destruction.
- Repair workers appear when a damaged repairable structure exists.
- `Enter` grants resources.
- `1-5` buy army limits when the player can pay the cost.
- `F5` saves and `F9` loads the state.
- Camera pans horizontally with `A/D` and RMB drag.

- [ ] **Step 3: Check git status**

Run:

```powershell
git status --short
```

Expected: no output.

- [ ] **Step 4: Report result**

Report:

- final commit hash;
- validation commands run;
- any known gaps against the full vertical-slice spec;
- next recommended implementation package.
