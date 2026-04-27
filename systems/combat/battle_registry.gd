extends Node
class_name BattleRegistry

var titans: Array[TitanUnit] = []
var defenders: Array[DefenderUnit] = []
var repair_workers: Array[RepairWorker] = []
var structures: Array[DestructibleStructure] = []

func register_titan(unit: TitanUnit) -> void:
	if unit == null or titans.has(unit):
		return
	titans.append(unit)
	if not unit.defeated.is_connected(_on_titan_defeated):
		unit.defeated.connect(_on_titan_defeated)

func register_defender(unit: DefenderUnit) -> void:
	if unit == null or defenders.has(unit):
		return
	defenders.append(unit)
	if not unit.defeated.is_connected(_on_defender_defeated):
		unit.defeated.connect(_on_defender_defeated)

func register_repair_worker(unit: RepairWorker) -> void:
	if unit == null or repair_workers.has(unit):
		return
	repair_workers.append(unit)
	if not unit.defeated.is_connected(_on_repair_worker_defeated):
		unit.defeated.connect(_on_repair_worker_defeated)

func register_structure(structure: DestructibleStructure) -> void:
	if structure == null or structures.has(structure):
		return
	structures.append(structure)
	if not structure.destroyed.is_connected(_on_structure_destroyed):
		structure.destroyed.connect(_on_structure_destroyed)

func alive_titans() -> Array[TitanUnit]:
	var result: Array[TitanUnit] = []
	for unit in titans:
		if _is_alive_actor(unit):
			result.append(unit)
	return result

func alive_defenders() -> Array[DefenderUnit]:
	var result: Array[DefenderUnit] = []
	for unit in defenders:
		if _is_alive_actor(unit):
			result.append(unit)
	return result

func alive_repair_workers() -> Array[RepairWorker]:
	var result: Array[RepairWorker] = []
	for unit in repair_workers:
		if _is_alive_actor(unit):
			result.append(unit)
	return result

func alive_structures() -> Array[DestructibleStructure]:
	var result: Array[DestructibleStructure] = []
	for structure in structures:
		if is_instance_valid(structure) and not structure.is_destroyed():
			result.append(structure)
	return result

func _on_titan_defeated(unit: CombatActor) -> void:
	SignalBus.unit_defeated.emit(unit.actor_id, unit.team, unit.global_position)
	if unit is TitanUnit:
		titans.erase(unit)

func _on_defender_defeated(unit: CombatActor) -> void:
	if unit.drop_table != null:
		EconomyService.grant(unit.drop_table.roll_drops(), unit.global_position)
	if unit is DefenderUnit and unit.defender_type != null and unit.defender_type.is_hero:
		if not GameState.defeated_heroes.has(unit.defender_type.id):
			GameState.mark_hero_defeated(unit.defender_type.id)
	SignalBus.unit_defeated.emit(unit.actor_id, unit.team, unit.global_position)
	if unit is DefenderUnit:
		defenders.erase(unit)

func _on_repair_worker_defeated(unit: CombatActor) -> void:
	SignalBus.unit_defeated.emit(unit.actor_id, unit.team, unit.global_position)
	if unit is RepairWorker:
		repair_workers.erase(unit)

func _on_structure_destroyed(structure: DestructibleStructure) -> void:
	structures.erase(structure)

func _is_alive_actor(unit: CombatActor) -> bool:
	return is_instance_valid(unit) and unit.damageable != null and not unit.damageable.dead
