# Battlefield Behavior Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the next playable behavior layer for `Titan Inc`: a central battle lane, randomized titan spawn, data-driven unit behavior profiles, defense slots, road-based defenders, archer projectiles, and colossal boulder siege behavior.

**Architecture:** Keep gameplay values in Godot `Resource` assets and keep actor scenes thin. Add focused controller/coordinator nodes for behavior, slots, lanes, and projectiles instead of growing large actor scripts. Preserve the existing foundation systems and continue to save only stable run/meta state, not transient projectiles or slot occupancy.

**Tech Stack:** Godot 4.6 stable, GDScript only, custom `.tres` resources, scene-owned coordinators, existing autoloads `SignalBus`, `GameState`, `SaveService`, and manual/headless Godot verification.

---

## Ground Rules

- Work in `C:\Users\user\.codex\worktrees\3d90\titan-inc` on branch `codex/foundation`.
- Do not touch or commit the existing dirty `project.godot` change unless the user explicitly approves it.
- Use `apply_patch` for manual edits.
- Keep files under 500 lines unless there is a clear reason.
- Add comments for non-obvious behavior rules, especially Godot lifecycle, lane geometry, slot assignment, and projectile collision.
- Run Godot validation after each task that changes scripts/scenes.
- Commit after each task with only the files owned by that task.

## Godot Command

Use this executable on the current machine:

```powershell
$Godot = 'C:\Users\user\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe'
```

Parse validation:

```powershell
& $Godot --headless --path . --editor --quit
```

Runtime smoke:

```powershell
& $Godot --headless --path . --quit-after 120
```

Content generation:

```powershell
& $Godot --headless --path . --editor --script tools/generate_initial_content.gd
```

`tools/generate_initial_content.gd` may print Godot shutdown RID/ObjectDB warnings after successful generation. Treat exit code `0` and `Initial Titan Inc content generated.` as success, then confirm `git status` and the generated content diff.

## Current Foundation

Relevant existing files:

```text
actors/common/combat_actor.gd
actors/titan/titan_unit.gd
actors/titan/titan_unit.tscn
actors/defender/defender_unit.gd
actors/defender/defender_unit.tscn
content/catalogs/content_catalog.gd
content/titans/titan_type_resource.gd
content/defenders/defender_type_resource.gd
content/structures/structure_type_resource.gd
core/stats/unit_stats_resource.gd
systems/combat/battle_registry.gd
systems/combat/combat_resolver.gd
systems/spawning/titan_spawn_coordinator.gd
systems/spawning/defender_spawn_coordinator.gd
systems/targeting/targeting_service.gd
world/city/city_scene.gd
world/city/city_scene.tscn
tools/generate_initial_content.gd
```

Existing movement is simple:

- `TitanSpawnCoordinator._process()` calls `titan.tick_movement(delta)`.
- `DefenderSpawnCoordinator._process()` calls `defender.tick_movement(delta)`.
- `CombatResolver` applies periodic AoE/direct attacks based on radius.

This package replaces that simple movement gradually with behavior controllers while keeping the game running after each task.

## Task Map

1. Battle lane and randomized titan spawn.
2. Behavior/profile resources and generated content assignments.
3. Titan behavior controller for fighter push and unstoppable push.
4. Defense slots, road lane, and slot coordinator.
5. Defender behavior controller for warriors and archers.
6. Arrow projectile.
7. Boulder projectile and colossal siege behavior.
8. Tower bonuses, fall damage, docs, and final verification.

---

### Task 1: Battle Lane And Randomized Titan Spawn

**Purpose:** Add an explicit battle lane node to the city scene and make titans spawn randomly inside the yellow central combat band confirmed by the user.

**Files:**
- Create: `world/battlefield/battle_lane.gd`
- Modify: `world/city/city_scene.tscn`
- Modify: `systems/spawning/titan_spawn_coordinator.gd`

- [ ] **Step 1: Create `world/battlefield/battle_lane.gd`**

Create a `Node2D` class with this public contract:

```gdscript
extends Node2D
class_name BattleLane

@export var lane_rect := Rect2(Vector2(0.0, 230.0), Vector2(2300.0, 230.0))
@export var titan_spawn_x := 80.0
@export var titan_spawn_x_variance := 24.0
@export var debug_visible := true
@export var debug_color := Color(0.1, 0.9, 0.9, 0.35)

func random_titan_spawn_position() -> Vector2:
	var x := titan_spawn_x + randf_range(-titan_spawn_x_variance, titan_spawn_x_variance)
	var y := randf_range(lane_rect.position.y, lane_rect.position.y + lane_rect.size.y)
	return Vector2(x, y)

func clamp_to_lane_y(position: Vector2) -> Vector2:
	return Vector2(position.x, clampf(position.y, lane_rect.position.y, lane_rect.position.y + lane_rect.size.y))

func _draw() -> void:
	if not debug_visible:
		return
	draw_rect(lane_rect, debug_color, false, 2.0)
```

Comment above `random_titan_spawn_position()` that the lane is the user-approved yellow combat band from the reference screenshot.

- [ ] **Step 2: Add `BattleLane` to `world/city/city_scene.tscn`**

Add an `ext_resource` for `res://world/battlefield/battle_lane.gd`.

Add a root child:

```text
[node name="BattleLane" type="Node2D" parent="."]
script = ExtResource("...")
lane_rect = Rect2(0, 230, 2300, 230)
titan_spawn_x = 80.0
titan_spawn_x_variance = 30.0
debug_visible = true
```

Keep the lane y-range aligned with the screenshot: middle third of the 720p viewport.

- [ ] **Step 3: Modify `systems/spawning/titan_spawn_coordinator.gd`**

Add:

```gdscript
@export var battle_lane_path: NodePath
@onready var battle_lane: BattleLane = get_node_or_null(battle_lane_path) as BattleLane
```

Replace the current spawn position:

```gdscript
unit.global_position = spawn_origin + Vector2(0.0, randf_range(-28.0, 28.0))
```

with:

```gdscript
unit.global_position = _next_spawn_position()
```

Add:

```gdscript
func _next_spawn_position() -> Vector2:
	if battle_lane != null:
		return battle_lane.random_titan_spawn_position()
	return spawn_origin + Vector2(randf_range(-24.0, 24.0), randf_range(-28.0, 28.0))
```

- [ ] **Step 4: Wire the node path in `city_scene.tscn`**

Set:

```text
battle_lane_path = NodePath("../BattleLane")
```

on `TitanSpawnCoordinator`.

- [ ] **Step 5: Validate**

Run:

```powershell
& $Godot --headless --path . --editor --quit
& $Godot --headless --path . --quit-after 120
git diff --check -- world/battlefield/battle_lane.gd world/city/city_scene.tscn systems/spawning/titan_spawn_coordinator.gd
git status --short --branch
```

Expected:

- Godot commands exit `0`.
- No `git diff --check` output.
- `project.godot` may still be dirty from the existing user/editor change; do not stage it.

- [ ] **Step 6: Commit**

```powershell
git add world/battlefield/battle_lane.gd world/city/city_scene.tscn systems/spawning/titan_spawn_coordinator.gd
git commit -m "feat: add battle lane titan spawning"
```

---

### Task 2: Behavior Profile Resources And Generated Assignments

**Purpose:** Add data resources that describe unit behavior, projectile parameters, and assign them to generated titan/defender content.

**Files:**
- Create: `content/behaviors/unit_behavior_profile_resource.gd`
- Create: `content/projectiles/projectile_profile_resource.gd`
- Modify: `content/titans/titan_type_resource.gd`
- Modify: `content/defenders/defender_type_resource.gd`
- Modify: `content/catalogs/content_catalog.gd`
- Modify: `tools/generate_initial_content.gd`
- Generated: `content/behaviors/*.tres`
- Generated: `content/projectiles/*.tres`
- Generated: `content/titans/*.tres`
- Generated: `content/defenders/*.tres`

- [ ] **Step 1: Add `UnitBehaviorProfileResource`**

Required exported fields:

```gdscript
extends Resource
class_name UnitBehaviorProfileResource

enum BehaviorKind {
	FIGHTER_PUSH,
	UNSTOPPABLE_PUSH,
	SIEGE_COLOSSAL,
	MELEE_DEFENDER,
	RANGED_ARCHER,
}

@export var id: StringName
@export var behavior_kind := BehaviorKind.FIGHTER_PUSH
@export var melee_stop_on_attacker := false
@export var ignores_incoming_melee := false
@export var moving_aoe_interval := 0.8
@export var boulder_cooldown := 10.0
@export var siege_melee_cooldown := 5.0
@export var vision_range := 160.0
@export var leash_radius := 220.0
@export var tower_range_multiplier := 2.0
@export var projectile_profile: ProjectileProfileResource
```

- [ ] **Step 2: Add `ProjectileProfileResource`**

Required exported fields:

```gdscript
extends Resource
class_name ProjectileProfileResource

enum ProjectileKind {
	ARROW,
	BOULDER,
}

@export var id: StringName
@export var projectile_kind := ProjectileKind.ARROW
@export var speed := 260.0
@export var arc_height := 80.0
@export var damage_multiplier := 1.0
@export var impact_radius := 18.0
@export var roll_distance := 0.0
@export var lifetime := 4.0
```

- [ ] **Step 3: Reference behavior profiles from unit resources**

In `TitanTypeResource`, add:

```gdscript
@export var behavior_profile: UnitBehaviorProfileResource
```

In `DefenderTypeResource`, add:

```gdscript
@export var behavior_profile: UnitBehaviorProfileResource
```

- [ ] **Step 4: Teach `ContentCatalog` to load behavior and projectile resources**

Add dictionaries:

```gdscript
var behavior_profiles: Dictionary = {}
var projectile_profiles: Dictionary = {}
```

Add load calls in `load_all()` for:

```text
res://content/behaviors
res://content/projectiles
```

Use the same exact-script/type filtering pattern already used for titans, defenders, structures, and zones.

- [ ] **Step 5: Extend `tools/generate_initial_content.gd`**

Preload the new scripts, clean the new directories, save projectile profiles before behavior profiles, save behavior profiles before titans/defenders, and assign:

```text
small_titan       -> fighter_push
basic_titan       -> fighter_push
runner_titan      -> unstoppable_push
armored_titan     -> unstoppable_push
colossal_titan    -> siege_colossal
peasant           -> melee_defender
warrior           -> melee_defender
knight            -> melee_defender
rider             -> melee_defender
first_hero        -> melee_defender
archer            -> ranged_archer
crossbowman       -> ranged_archer
```

Create projectile profiles:

```text
arrow_projectile: kind ARROW, speed 280, arc_height 70, impact_radius 12, lifetime 3
boulder_projectile: kind BOULDER, speed 180, arc_height 150, impact_radius 48, roll_distance 220, lifetime 6
```

- [ ] **Step 6: Generate content and validate**

Run:

```powershell
& $Godot --headless --path . --editor --script tools/generate_initial_content.gd
& $Godot --headless --path . --editor --quit
git diff --check -- content tools
```

Expected:

- Generator exits `0`.
- New `.tres` files exist in `content/behaviors` and `content/projectiles`.
- Existing titan/defender `.tres` files reference behavior profiles.

- [ ] **Step 7: Commit**

```powershell
git add content tools
git commit -m "feat: add unit behavior profiles"
```

---

### Task 3: Titan Behavior Controller

**Purpose:** Move titan movement decisions out of the spawn coordinator and implement fighter/unstoppable behavior.

**Files:**
- Create: `systems/behavior/titan_behavior_controller.gd`
- Modify: `actors/titan/titan_unit.gd`
- Modify: `actors/titan/titan_unit.tscn`
- Modify: `systems/spawning/titan_spawn_coordinator.gd`
- Modify: `systems/combat/combat_resolver.gd`
- Modify: `systems/targeting/targeting_service.gd`

- [ ] **Step 1: Create `TitanBehaviorController`**

The controller owns movement and contact decisions for one titan.

Required public API:

```gdscript
extends Node
class_name TitanBehaviorController

var unit: TitanUnit
var registry: BattleRegistry
var battle_lane: BattleLane

func configure(owner_unit: TitanUnit, battle_registry: BattleRegistry, lane: BattleLane) -> void:
	unit = owner_unit
	registry = battle_registry
	battle_lane = lane

func tick(delta: float) -> void:
	if unit == null or registry == null or unit.damageable == null or unit.damageable.dead:
		return
	match _behavior_kind():
		UnitBehaviorProfileResource.BehaviorKind.UNSTOPPABLE_PUSH:
			_tick_unstoppable(delta)
		UnitBehaviorProfileResource.BehaviorKind.SIEGE_COLOSSAL:
			_tick_colossal(delta)
		_:
			_tick_fighter(delta)
```

Implement helper methods:

- `_behavior_kind() -> int`
- `_nearest_blocking_structure() -> DestructibleStructure`
- `_nearest_melee_defender() -> DefenderUnit`
- `_move_forward(delta: float) -> void`
- `_move_toward_x(delta: float, target_x_value: float) -> void`
- `_keep_inside_lane() -> void`

For this task, `_tick_colossal()` may behave like slow fighter movement and leave boulder logic for Task 7. It must not crash when used by `colossal_titan`.

- [ ] **Step 2: Attach controller to titan scene**

Add a child node to `actors/titan/titan_unit.tscn`:

```text
[node name="TitanBehaviorController" type="Node" parent="."]
script = ExtResource("...")
```

Add an ext_resource for `systems/behavior/titan_behavior_controller.gd`.

- [ ] **Step 3: Modify `TitanUnit`**

Add:

```gdscript
@onready var behavior_controller: TitanBehaviorController = $TitanBehaviorController
```

Add:

```gdscript
func configure_behavior(registry: BattleRegistry, battle_lane: BattleLane) -> void:
	if behavior_controller != null:
		behavior_controller.configure(self, registry, battle_lane)
```

- [ ] **Step 4: Modify `TitanSpawnCoordinator`**

Stop calling `titan.tick_movement(delta)` directly. Instead:

```gdscript
for titan in registry.alive_titans():
	if titan.behavior_controller != null:
		titan.behavior_controller.tick(delta)
```

After spawning and configuring the titan:

```gdscript
unit.configure_behavior(registry, battle_lane)
```

- [ ] **Step 5: Adjust combat ownership**

Keep `CombatResolver` responsible for applying damage, but let behavior state influence movement. In this task, do not remove existing attack resolution. The controller should only choose movement/stop state; existing AoE attacks can continue to fire from `CombatResolver`.

Add targeted helper methods to `TargetingService` if needed:

```gdscript
static func nearest_unit_in_radius(origin: Vector2, radius: float, units: Array) -> CombatActor
```

- [ ] **Step 6: Validate**

Run:

```powershell
& $Godot --headless --path . --editor --quit
& $Godot --headless --path . --quit-after 120
git diff --check -- systems/behavior actors/titan systems/spawning systems/combat systems/targeting
```

Expected:

- Small/basic titans can stop when a defender is in melee range.
- Runner/armored titans keep moving unless near a blocking structure.
- Runtime smoke exits `0`.

- [ ] **Step 7: Commit**

```powershell
git add systems/behavior actors/titan systems/spawning systems/combat systems/targeting
git commit -m "feat: add titan behavior controller"
```

---

### Task 4: Defense Slots And Road Lane

**Purpose:** Create data and runtime systems for defender positions: melee fronts, ranged ground positions, tower garrisons, ambush slots, and a simple road lane.

**Files:**
- Create: `world/battlefield/road_lane.gd`
- Create: `world/defense_positions/defense_slot_resource.gd`
- Create: `systems/defense/defense_slot_coordinator.gd`
- Modify: `world/city/city_scene.tscn`
- Modify: `world/city/city_scene.gd`
- Modify: `systems/spawning/defender_spawn_coordinator.gd`
- Modify: `content/catalogs/content_catalog.gd`
- Modify: `tools/generate_initial_content.gd`

- [ ] **Step 1: Create `RoadLane`**

`RoadLane` should be a `Node2D` with:

```gdscript
@export var road_y := 420.0
@export var min_x := 0.0
@export var max_x := 2300.0

func point_at_x(x: float) -> Vector2:
	return Vector2(clampf(x, min_x, max_x), road_y)
```

- [ ] **Step 2: Create `DefenseSlotResource`**

Fields:

```gdscript
extends Resource
class_name DefenseSlotResource

enum SlotType {
	MELEE_FRONT,
	RANGED_GROUND,
	TOWER_GARRISON,
	AMBUSH,
	FALLBACK,
}

@export var id: StringName
@export var slot_type := SlotType.MELEE_FRONT
@export var capacity := 1
@export var position := Vector2.ZERO
@export var range_multiplier := 1.0
@export var leash_radius := 220.0
@export var allowed_defender_tags: Array[StringName] = []
@export var anchor_structure_id: StringName
```

- [ ] **Step 3: Create `DefenseSlotCoordinator`**

The coordinator keeps runtime occupancy without saving it.

Required methods:

```gdscript
func configure(slots: Array[DefenseSlotResource]) -> void
func claim_slot(defender_type: DefenderTypeResource) -> Dictionary
func release_slot(slot_id: StringName) -> void
func slot_position(slot_id: StringName) -> Vector2
func slot_range_multiplier(slot_id: StringName) -> float
func slot_leash_radius(slot_id: StringName) -> float
```

Return dictionaries should be small temporary payloads:

```gdscript
{"id": slot.id, "position": slot.position, "range_multiplier": slot.range_multiplier, "leash_radius": slot.leash_radius}
```

- [ ] **Step 4: Generate first city slots**

Extend `tools/generate_initial_content.gd` to create `content/defense_slots/*.tres`.

Create slots around current structures:

- `suburb_house_ambush_a`: `AMBUSH`, capacity 3, near `Vector2(430, 420)`.
- `wooden_fence_melee`: `MELEE_FRONT`, capacity 10, near `Vector2(610, 420)`.
- `outer_tower_left_garrison`: `TOWER_GARRISON`, capacity 10, near `Vector2(1200, 245)`.
- `outer_tower_right_garrison`: `TOWER_GARRISON`, capacity 10, near `Vector2(1200, 430)`.
- `outer_tower_melee`: `MELEE_FRONT`, capacity 10, near `Vector2(1135, 420)`.
- `wall_gate_melee`: `MELEE_FRONT`, capacity 10, near `Vector2(1780, 420)`.
- `wall_tower_left_garrison`: `TOWER_GARRISON`, capacity 10, near `Vector2(1740, 225)`.
- `wall_tower_right_garrison`: `TOWER_GARRISON`, capacity 10, near `Vector2(1740, 435)`.

- [ ] **Step 5: Wire coordinators in `city_scene.tscn`**

Add root children:

```text
RoadLane
DefenseSlotCoordinator
```

Set node paths on `DefenderSpawnCoordinator`:

```text
road_lane_path = NodePath("../RoadLane")
defense_slot_coordinator_path = NodePath("../DefenseSlotCoordinator")
```

- [ ] **Step 6: Modify defender spawning**

On spawn, claim a slot and configure the defender with slot data. Keep fallback to existing `DEFENSE_POSITIONS` if no slot is available.

- [ ] **Step 7: Validate and commit**

Run Godot parse/runtime and generator, then:

```powershell
git add world/battlefield world/defense_positions systems/defense systems/spawning content tools world/city
git commit -m "feat: add defense slots and road lane"
```

---

### Task 5: Defender Behavior Controller

**Purpose:** Move defender movement and engagement into a controller that supports road travel, slot holding, archer stop-and-shoot, warrior charge, and leash limits.

**Files:**
- Create: `systems/behavior/defender_behavior_controller.gd`
- Modify: `actors/defender/defender_unit.gd`
- Modify: `actors/defender/defender_unit.tscn`
- Modify: `systems/spawning/defender_spawn_coordinator.gd`
- Modify: `systems/combat/combat_resolver.gd`

- [ ] **Step 1: Create `DefenderBehaviorController`**

Required public API:

```gdscript
extends Node
class_name DefenderBehaviorController

var unit: DefenderUnit
var registry: BattleRegistry
var road_lane: RoadLane
var assigned_slot_id: StringName
var assigned_slot_position := Vector2.ZERO
var range_multiplier := 1.0
var leash_radius := 220.0

func configure(owner_unit: DefenderUnit, battle_registry: BattleRegistry, lane: RoadLane, slot_payload: Dictionary) -> void
func tick(delta: float) -> void
func effective_attack_range() -> float
```

`effective_attack_range()` returns `(unit.stats.attack_radius + unit.stats.attack_range) * range_multiplier`.

- [ ] **Step 2: Implement melee defender behavior**

For `MELEE_DEFENDER`:

- travel along `RoadLane` toward assigned slot x;
- hold assigned slot when no titan is in vision;
- charge nearest titan within `vision_range`;
- do not chase farther than `leash_radius` from assigned slot;
- if a titan is left behind closer to the city side, return or retarget instead of continuing too far left.

- [ ] **Step 3: Implement archer behavior**

For `RANGED_ARCHER`:

- travel along road to the assigned slot;
- stop when a titan is inside effective range;
- face/target the closest titan;
- leave actual projectile firing to Task 6;
- expose `current_target: TitanUnit` for projectile firing.

- [ ] **Step 4: Attach to defender scene and coordinator**

Add `DefenderBehaviorController` child to `defender_unit.tscn`.

Add `configure_behavior()` to `DefenderUnit`.

Update `DefenderSpawnCoordinator._process()` to call controller `tick(delta)` instead of `tick_movement(delta)`.

- [ ] **Step 5: Update combat range for tower bonus**

Where direct defender damage still exists in `CombatResolver`, use `defender.behavior_controller.effective_attack_range()` when controller exists.

- [ ] **Step 6: Validate and commit**

Run Godot parse/runtime and commit:

```powershell
git add systems/behavior actors/defender systems/spawning systems/combat
git commit -m "feat: add defender behavior controller"
```

---

### Task 6: Arrow Projectile

**Purpose:** Replace direct archer damage with visible arcing projectile shots.

**Files:**
- Create: `systems/projectiles/projectile.gd`
- Create: `systems/projectiles/arrow_projectile.gd`
- Create: `systems/projectiles/arrow_projectile.tscn`
- Modify: `systems/combat/combat_resolver.gd`
- Modify: `systems/behavior/defender_behavior_controller.gd`
- Modify: `actors/defender/defender_unit.gd`

- [ ] **Step 1: Create base `Projectile`**

Required fields:

```gdscript
var source_id: StringName
var team: StringName
var damage := 0.0
var profile: ProjectileProfileResource
var start_position := Vector2.ZERO
var target_position := Vector2.ZERO
var elapsed := 0.0
```

Required methods:

```gdscript
func configure(source: CombatActor, target: CombatActor, projectile_profile: ProjectileProfileResource, damage_amount: float) -> void
func tick_projectile(delta: float, registry: BattleRegistry) -> void
```

Base movement interpolates from start to target and applies `arc_height` as vertical offset.

- [ ] **Step 2: Create `ArrowProjectile` scene**

Use `Area2D` root or `Node2D` root with a `ColorRect`/`Polygon2D` simple circular placeholder. Keep visuals minimal.

- [ ] **Step 3: Fire arrows from archer behavior**

When a ranged defender can attack and has `current_target`, instantiate `arrow_projectile.tscn`, configure it with archer damage, and add it to a `Projectiles` root in `city_scene.tscn`.

If a `Projectiles` node does not exist, add it in Task 6.

- [ ] **Step 4: Prevent duplicate direct archer damage**

Update `CombatResolver` so defenders with `RANGED_ARCHER` behavior do not apply direct instant damage. Melee defenders can keep direct attacks.

- [ ] **Step 5: Validate and commit**

Run Godot parse/runtime and commit:

```powershell
git add systems/projectiles systems/behavior systems/combat actors/defender world/city
git commit -m "feat: add archer projectile attacks"
```

---

### Task 7: Boulder Projectile And Colossal Siege

**Purpose:** Implement the colossal titan's 10-second boulder throw and 5-second close-range siege punches.

**Files:**
- Create: `systems/projectiles/boulder_projectile.gd`
- Create: `systems/projectiles/boulder_projectile.tscn`
- Modify: `systems/behavior/titan_behavior_controller.gd`
- Modify: `systems/combat/combat_resolver.gd`
- Modify: `systems/projectiles/projectile.gd`

- [ ] **Step 1: Create `BoulderProjectile`**

The boulder extends the base projectile but adds rolling and obstacle impact.

States:

```text
FLYING
ROLLING
IMPACTED
```

Rules:

- fly in an arc to the target ground point;
- after landing, roll right for `profile.roll_distance`;
- damage defenders touched during rolling;
- on collision with nearest structure in front, apply AoE damage and destroy the projectile;
- destroy itself after `profile.lifetime`.

- [ ] **Step 2: Add colossal timers**

In `TitanBehaviorController`, track:

```gdscript
var _boulder_cooldown := 0.0
var _siege_melee_cooldown := 0.0
```

For `SIEGE_COLOSSAL`:

- if near blocking structure, stop and use siege melee every `siege_melee_cooldown`;
- otherwise move forward slowly and throw boulder every `boulder_cooldown`;
- throwing boulder briefly pauses movement for the current tick.

- [ ] **Step 3: Apply boulder damage**

Boulder uses `profile.damage_multiplier * unit.stats.damage` and applies:

- unit damage to defenders in impact/rolling radius;
- structure damage to the first blocking structure hit;
- AoE unit damage around impact.

- [ ] **Step 4: Validate and commit**

Run Godot parse/runtime and commit:

```powershell
git add systems/projectiles systems/behavior systems/combat
git commit -m "feat: add colossal boulder siege behavior"
```

---

### Task 8: Tower Bonuses, Fall Damage, Docs, Final Verification

**Purpose:** Finish tower-specific behavior, document implementation, and verify the whole package.

**Files:**
- Modify: `structures/destructible/destructible_structure.gd`
- Modify: `systems/defense/defense_slot_coordinator.gd`
- Modify: `systems/behavior/defender_behavior_controller.gd`
- Modify: `docs/architecture_context.md`
- Modify: `docs/vertical_slice_spec.md`
- Modify: `docs/hotfixes.md`

- [ ] **Step 1: Tower range bonus**

Ensure defenders assigned to `TOWER_GARRISON` slots receive `range_multiplier = 2.0` from the slot payload. The bonus must flow through `DefenderBehaviorController.effective_attack_range()`.

- [ ] **Step 2: Tower destruction releases/falls defenders**

When a tower structure is destroyed:

- find defenders assigned to slots anchored to that structure id;
- apply fall damage once;
- clear their slot assignment so they can fall back to ground behavior.

If direct anchor lookup is not available yet, implement this through `DefenseSlotCoordinator` by mapping `anchor_structure_id -> occupied defenders`.

- [ ] **Step 3: Documentation**

Update:

- `docs/architecture_context.md` with the implemented behavior package status.
- `docs/vertical_slice_spec.md` remaining work list.
- `docs/hotfixes.md` only if the implementation introduced a deliberate workaround or urgent behavior fix.

- [ ] **Step 4: Final verification**

Run:

```powershell
& $Godot --headless --path . --editor --quit
& $Godot --headless --path . --quit-after 120
& $Godot --headless --path . --editor --script tools/generate_initial_content.gd
git diff --check
git status --short --branch
```

Expected:

- Godot parse exits `0`.
- Runtime smoke exits `0`.
- Generator exits `0`.
- `git diff --check` is clean.
- Only intentionally uncommitted user/editor changes remain.

- [ ] **Step 5: Commit**

```powershell
git add structures systems docs content tools world actors
git commit -m "docs: update battlefield behavior status"
```

## Plan Self-Review

Spec coverage:

- Battle lane and randomized spawn are covered by Task 1.
- Behavior/profile resources are covered by Task 2.
- Fighter push, unstoppable push, and initial colossal behavior are covered by Task 3.
- Defense slots and road lane are covered by Task 4.
- Defender warrior/archer behavior is covered by Task 5.
- Arrow projectile is covered by Task 6.
- Boulder projectile and close-range colossal siege are covered by Task 7.
- Tower range bonus, fall damage, docs, and final verification are covered by Task 8.

Known scope boundaries:

- Final art and final UI are not included.
- Full 2-3 hour balance is not included.
- Complex grid/pathfinding is not included; road movement is a simple lane model.
- Runtime save does not persist projectiles or active slot occupancy.

Type consistency:

- `UnitBehaviorProfileResource` is referenced by both titan and defender resources.
- `ProjectileProfileResource` is referenced from behavior profiles.
- `BattleLane` is a scene node first; `BattleLaneResource` can be introduced when multiple city layouts require authored lane assets.
- `DefenseSlotResource` is authored content; `DefenseSlotCoordinator` owns temporary runtime occupancy.
