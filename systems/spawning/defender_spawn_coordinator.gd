extends Node
class_name DefenderSpawnCoordinator

@export var registry_path: NodePath
@export var catalog_path: NodePath
@export var road_lane_path: NodePath
@export var defense_slot_coordinator_path: NodePath
@export var projectile_root_path: NodePath
@export var defender_scene: PackedScene
@export var arrow_projectile_scene: PackedScene
@export var spawn_origin := Vector2(1900.0, 420.0)
@export var max_alive := 8
@export var spawn_cooldown := 3.0

const HERO_ID := &"first_hero"
var _cooldown := 0.0
var _hero_spawned := false

@onready var registry: BattleRegistry = get_node_or_null(registry_path) as BattleRegistry
@onready var catalog: ContentCatalog = get_node_or_null(catalog_path) as ContentCatalog
@onready var road_lane: RoadLane = get_node_or_null(road_lane_path) as RoadLane
@onready var defense_slot_coordinator: DefenseSlotCoordinator = get_node_or_null(defense_slot_coordinator_path) as DefenseSlotCoordinator
@onready var projectile_root: Node2D = get_node_or_null(projectile_root_path) as Node2D

func _process(delta: float) -> void:
	if registry == null or catalog == null or defender_scene == null:
		return
	for defender in registry.alive_defenders():
		if defender.behavior_controller != null:
			defender.behavior_controller.tick(delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0 or registry.alive_defenders().size() >= max_alive:
		return
	var defender_type := _pick_defender_type()
	if defender_type == null:
		return
	_spawn_defender(defender_type)
	_cooldown = spawn_cooldown

func _pick_defender_type() -> DefenderTypeResource:
	var hero := catalog.get_defender(HERO_ID)
	if hero != null and not _hero_spawned and GameState.get_currency(&"meat") > 250.0 and not GameState.defeated_heroes.has(HERO_ID):
		_hero_spawned = true
		return hero
	var candidates: Array[DefenderTypeResource] = []
	for defender_type in catalog.defender_types.values():
		var typed := defender_type as DefenderTypeResource
		if typed != null and not typed.is_hero:
			candidates.append(typed)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]

func _spawn_defender(defender_type: DefenderTypeResource) -> void:
	var unit := defender_scene.instantiate() as DefenderUnit
	if unit == null:
		return
	add_child(unit)
	var slot_payload := {}
	if defense_slot_coordinator != null:
		slot_payload = defense_slot_coordinator.claim_slot(defender_type, unit)
	var position: Vector2 = slot_payload["position"] if slot_payload.has("position") else spawn_origin
	unit.global_position = road_lane.point_at_x(spawn_origin.x) if road_lane != null else spawn_origin
	unit.configure_defender(defender_type, position)
	unit.configure_behavior(registry, road_lane, slot_payload)
	unit.configure_projectiles(projectile_root, arrow_projectile_scene)
	if defense_slot_coordinator != null and slot_payload.has("id"):
		unit.defeated.connect(_on_defender_slot_released.bind(unit), CONNECT_ONE_SHOT)
		unit.tree_exiting.connect(_on_defender_tree_exiting.bind(unit), CONNECT_ONE_SHOT)
	registry.register_defender(unit)

func _on_defender_slot_released(_actor: CombatActor, unit: DefenderUnit) -> void:
	_release_claimed_slot(unit)

func _on_defender_tree_exiting(unit: DefenderUnit) -> void:
	_release_claimed_slot(unit)

func _release_claimed_slot(unit: DefenderUnit) -> void:
	if unit == null or defense_slot_coordinator == null:
		return
	defense_slot_coordinator.release_defender(unit)
