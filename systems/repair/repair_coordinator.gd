extends Node
class_name RepairCoordinator

@export var registry_path: NodePath
@export var repair_worker_scene: PackedScene
@export var spawn_origin := Vector2(1960.0, 430.0)
@export var max_workers := 3
@export var cooldown := 8.0

var _cooldown := 0.0

@onready var registry: BattleRegistry = get_node_or_null(registry_path) as BattleRegistry

func _process(delta: float) -> void:
	if registry == null or repair_worker_scene == null:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0 or registry.alive_repair_workers().size() >= max_workers:
		return
	var target := _find_damaged_structure()
	if target == null:
		return
	_spawn_worker(target)
	_cooldown = cooldown

func _find_damaged_structure() -> DestructibleStructure:
	for structure in registry.alive_structures():
		if structure.structure_type == null or not structure.structure_type.repairable:
			continue
		if _already_has_worker(structure):
			continue
		if structure.damageable != null and structure.damageable.current_hp < structure.damageable.max_hp:
			return structure
	return null

func _already_has_worker(structure: DestructibleStructure) -> bool:
	for worker in registry.alive_repair_workers():
		if worker.target_structure == structure:
			return true
	return false

func _spawn_worker(target: DestructibleStructure) -> void:
	var worker := repair_worker_scene.instantiate() as RepairWorker
	if worker == null:
		return
	add_child(worker)
	worker.global_position = spawn_origin
	worker.configure_worker(target)
	registry.register_repair_worker(worker)
