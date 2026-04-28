extends Node
class_name TitanSpawnCoordinator

@export var registry_path: NodePath
@export var catalog_path: NodePath
@export var battle_lane_path: NodePath
@export var titan_scene: PackedScene
@export var spawn_origin := Vector2(80.0, 420.0)
@export var target_x := 2200.0

var _cooldowns: Dictionary = {}

@onready var registry: BattleRegistry = get_node_or_null(registry_path) as BattleRegistry
@onready var catalog: ContentCatalog = get_node_or_null(catalog_path) as ContentCatalog
@onready var battle_lane: BattleLane = get_node_or_null(battle_lane_path) as BattleLane

func _process(delta: float) -> void:
	if registry == null or catalog == null or titan_scene == null:
		return
	for titan in registry.alive_titans():
		if titan.behavior_controller != null:
			titan.behavior_controller.tick(delta)
		else:
			titan.tick_movement(delta)
	_tick_cooldowns(delta)
	for titan_type in catalog.titan_types.values():
		_try_spawn_titan(titan_type as TitanTypeResource)

func _tick_cooldowns(delta: float) -> void:
	for titan_id in _cooldowns.keys():
		_cooldowns[titan_id] = maxf(float(_cooldowns[titan_id]) - delta, 0.0)

func _try_spawn_titan(titan_type: TitanTypeResource) -> void:
	if titan_type == null:
		return
	var limit := GameState.get_army_limit(titan_type.id)
	if limit <= 0 or _alive_count(titan_type.id) >= limit:
		return
	if float(_cooldowns.get(titan_type.id, 0.0)) > 0.0:
		return
	var unit := titan_scene.instantiate() as TitanUnit
	if unit == null:
		return
	add_child(unit)
	unit.global_position = _next_spawn_position()
	unit.configure_titan(titan_type, target_x)
	unit.configure_behavior(registry, battle_lane)
	registry.register_titan(unit)
	_cooldowns[titan_type.id] = maxf(titan_type.spawn_cooldown, 0.05)

func _next_spawn_position() -> Vector2:
	if battle_lane != null:
		return battle_lane.random_titan_spawn_position()
	return spawn_origin + Vector2(randf_range(-24.0, 24.0), randf_range(-28.0, 28.0))

func _alive_count(titan_id: StringName) -> int:
	var count := 0
	for titan in registry.alive_titans():
		if titan.titan_type != null and titan.titan_type.id == titan_id:
			count += 1
	return count
