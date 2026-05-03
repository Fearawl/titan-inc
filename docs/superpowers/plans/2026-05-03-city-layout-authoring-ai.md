# City Layout Authoring and Interception AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a manual Godot layout scene for important city objects and make titans/defenders react to obstacles and rear-line breakthroughs.

**Architecture:** Add a scene-authored layout layer under `world/layout` that stores placement in marker nodes while gameplay values remain in Godot `Resource` assets. `CityScene` reads the layout at runtime and configures structures, spawn points, lanes, and defense slots; behavior controllers keep combat decisions separate from actor presentation.

**Tech Stack:** Godot 4.6, GDScript, `.tscn` scenes, custom Godot `Resource`, existing autoload save/game services.

---

## File Structure

- Create `world/layout/city_layout.gd`: typed marker collector and duplicate-id validation for layout scenes.
- Create `world/layout/structure_marker.gd`: editor-visible marker for destructible structures.
- Create `world/layout/spawn_point_marker.gd`: editor-visible marker for titan, defender, and repair spawn origins.
- Create `world/layout/defense_point_marker.gd`: editor-visible marker that produces `DefenseSlotResource` runtime data.
- Create `world/layout/fantasy_city_layout.tscn`: first editable layout with lanes, structures, spawn markers, and defense points.
- Modify `world/city/city_scene.gd`: read the layout scene, configure lanes/spawners, spawn structures, and build defense slots from markers.
- Modify `world/city/city_scene.tscn`: instance `FantasyCityLayout` and wire `layout_path`.
- Modify `structures/destructible/destructible_structure.gd`: support stable runtime ids for save/load and per-instance size/position overrides.
- Modify `world/defense_positions/defense_slot_resource.gd`: add optional `vision_radius` and `rear_guard_radius`.
- Modify `systems/defense/defense_slot_coordinator.gd`: pass the new radii through slot payloads and guard duplicate ids.
- Modify `systems/spawning/defender_spawn_coordinator.gd`: remove hardcoded defense positions fallback preference when marker slots exist.
- Modify `systems/targeting/targeting_service.gd`: add blocking-structure search that accounts for structure size and lane overlap.
- Modify `systems/behavior/titan_behavior_controller.gd`: use blocking-structure interception instead of nearest center-only structure targeting.
- Modify `systems/behavior/defender_behavior_controller.gd`: add marker-authored vision/rear-guard pursuit rules.
- Modify `docs/architecture_context.md`, `docs/gdd.md`, and `docs/hotfixes.md`: record the package outcome and known limitations.

## Task 1: Layout Marker Scripts

**Files:**
- Create: `world/layout/city_layout.gd`
- Create: `world/layout/structure_marker.gd`
- Create: `world/layout/spawn_point_marker.gd`
- Create: `world/layout/defense_point_marker.gd`

- [ ] **Step 1: Create `StructureMarker`**

```gdscript
@tool
extends Marker2D
class_name StructureMarker

@export var marker_id: StringName
@export var structure_type: StructureTypeResource
@export var size_override := Vector2.ZERO
@export var debug_color := Color(0.55, 0.55, 0.55, 0.5)

func runtime_id() -> StringName:
	if marker_id != &"":
		return marker_id
	if structure_type != null:
		return structure_type.id
	return StringName(name)
```

- [ ] **Step 2: Create `SpawnPointMarker`**

```gdscript
@tool
extends Marker2D
class_name SpawnPointMarker

enum SpawnKind {
	TITAN,
	DEFENDER,
	REPAIR,
}

@export var spawn_kind := SpawnKind.TITAN
@export var marker_id: StringName
@export var debug_color := Color(0.2, 0.8, 0.2, 0.65)
```

- [ ] **Step 3: Create `DefensePointMarker`**

```gdscript
@tool
extends Marker2D
class_name DefensePointMarker

@export var slot_id: StringName
@export var slot_type := DefenseSlotResource.SlotType.MELEE_FRONT
@export var capacity := 1
@export var range_multiplier := 1.0
@export var leash_radius := 220.0
@export var vision_radius := 260.0
@export var rear_guard_radius := 360.0
@export var allowed_defender_tags: Array[StringName] = []
@export var anchor_structure_marker_id: StringName
@export var debug_color := Color(0.2, 0.45, 1.0, 0.65)

func to_slot_resource(anchor_structure_id: StringName = &"") -> DefenseSlotResource:
	var slot := DefenseSlotResource.new()
	slot.id = slot_id if slot_id != &"" else StringName(name)
	slot.slot_type = slot_type
	slot.capacity = capacity
	slot.position = global_position
	slot.range_multiplier = range_multiplier
	slot.leash_radius = leash_radius
	slot.vision_radius = vision_radius
	slot.rear_guard_radius = rear_guard_radius
	slot.allowed_defender_tags = allowed_defender_tags.duplicate()
	slot.anchor_structure_id = anchor_structure_id
	return slot
```

- [ ] **Step 4: Create `CityLayout` collector**

```gdscript
@tool
extends Node2D
class_name CityLayout

@export var battle_lane_path: NodePath
@export var road_lane_path: NodePath

func structure_markers() -> Array[StructureMarker]:
	return _collect_markers(StructureMarker)

func spawn_markers() -> Array[SpawnPointMarker]:
	return _collect_markers(SpawnPointMarker)

func defense_point_markers() -> Array[DefensePointMarker]:
	return _collect_markers(DefensePointMarker)

func battle_lane() -> BattleLane:
	return get_node_or_null(battle_lane_path) as BattleLane

func road_lane() -> RoadLane:
	return get_node_or_null(road_lane_path) as RoadLane

func _collect_markers(marker_script: Variant) -> Array:
	var result := []
	_collect_markers_recursive(self, marker_script, result)
	return result

func _collect_markers_recursive(node: Node, marker_script: Variant, result: Array) -> void:
	for child in node.get_children():
		if is_instance_of(child, marker_script):
			result.append(child)
		_collect_markers_recursive(child, marker_script, result)
```

- [ ] **Step 5: Verify parser**

Run:

```powershell
& 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe' --headless --path 'E:\= TITAN-INC\titan-inc' --editor --quit
```

Expected: editor starts and exits without GDScript parse errors.

- [ ] **Step 6: Commit**

```powershell
git add world/layout
git commit -m "feat: add city layout marker scripts"
```

## Task 2: Fantasy Layout Scene

**Files:**
- Create: `world/layout/fantasy_city_layout.tscn`

- [ ] **Step 1: Create first editable layout scene**

Scene contents:

```text
FantasyCityLayout (Node2D, CityLayout)
  BattleLane (Node2D, BattleLane)
  RoadLane (Node2D, RoadLane)
  Structures (Node2D)
    SuburbHouse (StructureMarker)
    WoodenFence (StructureMarker)
    OuterTowerLeft (StructureMarker)
    OuterTowerRight (StructureMarker)
    WallTowerLeft (StructureMarker)
    WallGate (StructureMarker)
    WallTowerRight (StructureMarker)
  Spawns (Node2D)
    TitanSpawn (SpawnPointMarker: TITAN)
    DefenderSpawn (SpawnPointMarker: DEFENDER)
    RepairSpawn (SpawnPointMarker: REPAIR)
  DefensePoints (Node2D)
    WoodenFenceMelee (DefensePointMarker)
    OuterTowerMelee (DefensePointMarker)
    OuterTowerLeftGarrison (DefensePointMarker)
    OuterTowerRightGarrison (DefensePointMarker)
    WallGateMelee (DefensePointMarker)
    WallTowerLeftGarrison (DefensePointMarker)
    WallTowerRightGarrison (DefensePointMarker)
    SuburbAmbushA (DefensePointMarker)
```

Use existing resource references:

```text
res://content/structures/suburb_house.tres
res://content/structures/wooden_fence.tres
res://content/structures/outer_tower_left.tres
res://content/structures/outer_tower_right.tres
res://content/structures/wall_tower_left.tres
res://content/structures/wall_gate.tres
res://content/structures/wall_tower_right.tres
```

- [ ] **Step 2: Verify scene load**

Run:

```powershell
& 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe' --headless --path 'E:\= TITAN-INC\titan-inc' --quit --scene 'res://world/layout/fantasy_city_layout.tscn'
```

Expected: scene loads without missing resource or script errors.

- [ ] **Step 3: Commit**

```powershell
git add world/layout/fantasy_city_layout.tscn
git commit -m "feat: add fantasy city layout scene"
```

## Task 3: Runtime Layout Integration

**Files:**
- Modify: `world/city/city_scene.gd`
- Modify: `world/city/city_scene.tscn`
- Modify: `structures/destructible/destructible_structure.gd`

- [ ] **Step 1: Add stable structure runtime id**

Add to `DestructibleStructure`:

```gdscript
var runtime_id: StringName

func configure_structure(type: StructureTypeResource, position_override := Vector2.INF, runtime_id_override: StringName = &"", size_override := Vector2.ZERO) -> void:
	structure_type = type
	runtime_id = runtime_id_override if runtime_id_override != &"" else type.id
	global_position = position_override if position_override != Vector2.INF else type.position
	_ensure_nodes()
	_apply_active_state()
	var body_size := size_override if size_override != Vector2.ZERO else type.size
	body.size = body_size
	body.position = -body_size * 0.5
	suppress_state_write = true
	damageable.configure(type.max_hp)
	var game_state: Variant = _game_state()
	if game_state != null:
		if game_state.structure_hp.has(runtime_id):
			damageable.set_current_hp(float(game_state.structure_hp[runtime_id]))
		elif game_state.structure_hp.has(type.id):
			damageable.set_current_hp(float(game_state.structure_hp[type.id]))
	if damageable.current_hp <= 0.0:
		_apply_destroyed_state()
	suppress_state_write = false
	_on_hp_changed(damageable.current_hp, damageable.max_hp)
```

Update HP writes to use `runtime_id`.

- [ ] **Step 2: Add layout wiring to `CityScene`**

Add:

```gdscript
@export var layout_path: NodePath
@onready var layout: CityLayout = get_node_or_null(layout_path) as CityLayout
@onready var titan_spawn_coordinator: TitanSpawnCoordinator = $TitanSpawnCoordinator
@onready var defender_spawn_coordinator: DefenderSpawnCoordinator = $DefenderSpawnCoordinator
@onready var repair_coordinator: RepairCoordinator = $RepairCoordinator
@onready var battle_lane: BattleLane = $BattleLane
@onready var road_lane: RoadLane = $RoadLane
```

Replace zone resource structure spawning with layout marker spawning when layout exists. Keep current zone resource spawning as fallback.

- [ ] **Step 3: Apply spawn markers**

In `CityScene._ready()`, before spawners tick:

```gdscript
func _apply_layout_spawn_points() -> void:
	if layout == null:
		return
	for marker in layout.spawn_markers():
		match marker.spawn_kind:
			SpawnPointMarker.SpawnKind.TITAN:
				titan_spawn_coordinator.spawn_origin = marker.global_position
				if battle_lane != null:
					battle_lane.titan_spawn_x = marker.global_position.x
			SpawnPointMarker.SpawnKind.DEFENDER:
				defender_spawn_coordinator.spawn_origin = marker.global_position
			SpawnPointMarker.SpawnKind.REPAIR:
				repair_coordinator.spawn_origin = marker.global_position
```

- [ ] **Step 4: Instance layout in `city_scene.tscn`**

Add ext_resource:

```text
[ext_resource type="PackedScene" path="res://world/layout/fantasy_city_layout.tscn" id="23_layout"]
```

Add node:

```text
[node name="FantasyCityLayout" parent="." instance=ExtResource("23_layout")]
```

Set:

```text
layout_path = NodePath("FantasyCityLayout")
```

- [ ] **Step 5: Verify runtime**

Run:

```powershell
& 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe' --headless --path 'E:\= TITAN-INC\titan-inc' --quit --scene 'res://world/city/city_scene.tscn'
```

Expected: city scene starts without runtime errors and logs no missing layout warnings for the default layout.

- [ ] **Step 6: Commit**

```powershell
git add world/city structures/destructible
git commit -m "feat: build city from layout markers"
```

## Task 4: Defense Slots From Markers

**Files:**
- Modify: `world/defense_positions/defense_slot_resource.gd`
- Modify: `systems/defense/defense_slot_coordinator.gd`
- Modify: `systems/spawning/defender_spawn_coordinator.gd`
- Modify: `world/city/city_scene.gd`

- [ ] **Step 1: Extend `DefenseSlotResource`**

Add:

```gdscript
@export var vision_radius := 260.0
@export var rear_guard_radius := 360.0
```

- [ ] **Step 2: Pass new fields through coordinator payload**

Update `_slot_payload(slot)`:

```gdscript
return {
	"id": slot.id,
	"position": slot.position,
	"range_multiplier": slot.range_multiplier,
	"leash_radius": slot.leash_radius,
	"vision_radius": slot.vision_radius,
	"rear_guard_radius": slot.rear_guard_radius,
}
```

- [ ] **Step 3: Build slots from layout markers**

In `CityScene._configure_defense_slots()`, prefer layout markers:

```gdscript
if layout != null:
	for marker in layout.defense_point_markers():
		var anchor_id := _structure_runtime_id_for_marker(marker.anchor_structure_marker_id)
		slots.append(marker.to_slot_resource(anchor_id))
else:
	for slot in catalog.defense_slots.values():
		var typed := slot as DefenseSlotResource
		if typed != null:
			slots.append(typed)
```

- [ ] **Step 4: Keep defender spawn fallback safe**

In `DefenderSpawnCoordinator`, when no slot is claimed, use `spawn_origin`/road fallback instead of choosing from hardcoded `DEFENSE_POSITIONS`.

```gdscript
var position: Vector2 = slot_payload["position"] if slot_payload.has("position") else spawn_origin
```

- [ ] **Step 5: Verify runtime**

Run city scene headless. Expected: no errors, defenders still spawn and move toward marker-authored slots.

- [ ] **Step 6: Commit**

```powershell
git add world/defense_positions systems/defense systems/spawning world/city
git commit -m "feat: drive defense slots from city layout"
```

## Task 5: Blocking Structure Targeting

**Files:**
- Modify: `systems/targeting/targeting_service.gd`
- Modify: `systems/behavior/titan_behavior_controller.gd`
- Modify: `systems/combat/combat_resolver.gd`

- [ ] **Step 1: Add bounds-aware structure helpers**

Add to `TargetingService`:

```gdscript
static func nearest_blocking_structure_in_front(unit: CombatActor, structures: Array[DestructibleStructure], vertical_padding := 24.0) -> DestructibleStructure:
	if not is_instance_valid(unit):
		return null
	var best: DestructibleStructure = null
	var best_x_distance := INF
	for structure in structures:
		if not _is_blocking_structure_candidate(unit, structure, vertical_padding):
			continue
		var x_distance := structure.global_position.x - unit.global_position.x
		if x_distance < best_x_distance:
			best = structure
			best_x_distance = x_distance
	return best

static func _is_blocking_structure_candidate(unit: CombatActor, structure: DestructibleStructure, vertical_padding: float) -> bool:
	if not is_instance_valid(structure) or structure.is_destroyed() or structure.structure_type == null:
		return false
	if not structure.structure_type.blocks_movement:
		return false
	var half_size := structure.current_size() * 0.5
	if structure.global_position.x + half_size.x < unit.global_position.x - 8.0:
		return false
	var vertical_delta := absf(structure.global_position.y - unit.global_position.y)
	return vertical_delta <= half_size.y + vertical_padding
```

Add `current_size()` to `DestructibleStructure`.

- [ ] **Step 2: Use new targeting in titan behavior**

Replace calls to `TargetingService.nearest_structure_in_front` in `TitanBehaviorController` with `nearest_blocking_structure_in_front`.

- [ ] **Step 3: Use new targeting in combat resolver**

For titan structure damage, use the same nearest blocking target first. Keep old `nearest_structure_in_front` as fallback for destructible targets that do not block movement.

- [ ] **Step 4: Verify behavior manually through headless run**

Run city scene for several seconds:

```powershell
& 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe' --headless --path 'E:\= TITAN-INC\titan-inc' --quit --scene 'res://world/city/city_scene.tscn'
```

Expected: no runtime errors. In editor/manual play, titans stop at structures whose vertical bounds overlap their lane.

- [ ] **Step 5: Commit**

```powershell
git add systems/targeting systems/behavior systems/combat structures/destructible
git commit -m "feat: make titans intercept blocking structures"
```

## Task 6: Defender Detection and Rear Guard

**Files:**
- Modify: `systems/behavior/defender_behavior_controller.gd`

- [ ] **Step 1: Store marker-authored radii**

Add:

```gdscript
var vision_radius := 260.0
var rear_guard_radius := 360.0
```

Read from slot payload:

```gdscript
if slot_payload.has("vision_radius"):
	vision_radius = float(slot_payload["vision_radius"])
if slot_payload.has("rear_guard_radius"):
	rear_guard_radius = float(slot_payload["rear_guard_radius"])
```

- [ ] **Step 2: Replace target search with threat-aware search**

Use:

```gdscript
func _nearest_titan_threatening_slot() -> TitanUnit:
	var nearest: TitanUnit = null
	var nearest_distance := INF
	for titan in registry.alive_titans():
		var typed := titan as TitanUnit
		if not _is_valid_titan(typed):
			continue
		if not _is_titan_visible_or_rear_threat(typed):
			continue
		var distance := unit.global_position.distance_to(typed.global_position)
		if distance < nearest_distance:
			nearest = typed
			nearest_distance = distance
	return nearest

func _is_titan_visible_or_rear_threat(titan: TitanUnit) -> bool:
	var distance_to_unit := unit.global_position.distance_to(titan.global_position)
	if distance_to_unit <= maxf(vision_radius, _vision_range()):
		return true
	var titan_is_behind_slot := titan.global_position.x < assigned_slot_position.x
	var distance_to_slot := assigned_slot_position.distance_to(titan.global_position)
	return titan_is_behind_slot and distance_to_slot <= rear_guard_radius
```

- [ ] **Step 3: Keep leash from becoming passive**

When current target is behind the slot and within `rear_guard_radius`, do not clear it only because it exceeds normal `leash_radius`.

- [ ] **Step 4: Verify behavior**

Expected in manual play: defenders acquire titans earlier, chase titans that pass behind the marker, and return to assigned position after target death/loss.

- [ ] **Step 5: Commit**

```powershell
git add systems/behavior/defender_behavior_controller.gd
git commit -m "feat: make defenders guard authored positions"
```

## Task 7: Documentation and Verification

**Files:**
- Modify: `docs/architecture_context.md`
- Modify: `docs/gdd.md`
- Modify: `docs/hotfixes.md`

- [ ] **Step 1: Update architecture context**

Add a status section:

```markdown
## City Layout Authoring and Interception AI Status - 2026-05-03

Implemented:

- `FantasyCityLayout` provides scene-authored placement for structures, spawn points, lanes, and defense points.
- `CityScene` builds the runtime city from layout markers while keeping gameplay values in Resource assets.
- Structure HP uses stable layout runtime ids with fallback support for older `structure_type.id` saves.
- Titans now look for blocking destructible structures ahead using structure bounds.
- Defenders use marker-authored vision and rear-guard radii to pursue titans that threaten assigned points.

Current MVP limits:

- This is not a custom editor plugin; markers are regular Godot scene nodes.
- Full pathfinding, final tower climb animation, and final art remain future work.
```

- [ ] **Step 2: Update GDD and hotfixes**

Record that the first city can be manually authored through a layout scene, and note any compatibility fixes around structure HP ids.

- [ ] **Step 3: Run verification**

Run:

```powershell
git diff --check
& 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe' --headless --path 'E:\= TITAN-INC\titan-inc' --editor --quit
& 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe' --headless --path 'E:\= TITAN-INC\titan-inc' --quit --scene 'res://world/city/city_scene.tscn'
```

Expected:

- `git diff --check` prints nothing.
- Godot editor exits without parse errors.
- City scene exits without runtime errors.

- [ ] **Step 4: Commit final docs**

```powershell
git add docs
git commit -m "docs: update layout authoring context"
```

## Self-Review

- Spec coverage: marker scripts, editable layout scene, runtime city wiring, spawn points, defense slots, structure save ids, titan interception, defender pursuit, documentation, and verification are covered.
- Placeholder scan: no open-ended placeholder work or unspecified implementation steps are used.
- Type consistency: marker class names, slot fields, coordinator payload keys, and behavior-controller variables are consistent across tasks.
