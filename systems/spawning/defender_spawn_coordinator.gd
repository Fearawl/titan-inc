extends Node
class_name DefenderSpawnCoordinator

@export var registry_path: NodePath
@export var catalog_path: NodePath
@export var defender_scene: PackedScene
@export var spawn_origin := Vector2(1900.0, 420.0)
@export var max_alive := 8
@export var spawn_cooldown := 3.0

const HERO_ID := &"first_hero"
const DEFENSE_POSITIONS := [
	Vector2(520.0, 430.0),
	Vector2(700.0, 420.0),
	Vector2(1200.0, 300.0),
	Vector2(1200.0, 520.0),
	Vector2(1740.0, 292.0),
	Vector2(1850.0, 410.0),
	Vector2(1740.0, 525.0),
]

var _cooldown := 0.0
var _hero_spawned := false

@onready var registry: BattleRegistry = get_node_or_null(registry_path) as BattleRegistry
@onready var catalog: ContentCatalog = get_node_or_null(catalog_path) as ContentCatalog

func _process(delta: float) -> void:
	if registry == null or catalog == null or defender_scene == null:
		return
	for defender in registry.alive_defenders():
		defender.tick_movement(delta)
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
	var position: Vector2 = DEFENSE_POSITIONS[randi() % DEFENSE_POSITIONS.size()]
	unit.global_position = spawn_origin
	unit.configure_defender(defender_type, position)
	registry.register_defender(unit)
