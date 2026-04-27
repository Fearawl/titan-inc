extends CombatActor
class_name RepairWorker

signal work_completed(worker: RepairWorker)

var repair_per_second := 8.0
var target_structure: DestructibleStructure
var _completed := false

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
	if _completed:
		return
	if target_structure == null or target_structure.is_destroyed():
		_complete_work()
		return
	if absf(global_position.x - target_structure.global_position.x) > 12.0:
		tick_movement(delta)
	else:
		target_structure.repair(repair_per_second * delta)
		if target_structure.damageable.current_hp >= target_structure.damageable.max_hp:
			_complete_work()

func _complete_work() -> void:
	if _completed:
		return
	_completed = true
	work_completed.emit(self)
	target_structure = null
	queue_free()
