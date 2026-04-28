extends Node
class_name DefenderBehaviorController

var unit: DefenderUnit
var registry: BattleRegistry
var road_lane: RoadLane
var assigned_slot_id: StringName
var assigned_slot_position := Vector2.ZERO
var range_multiplier := 1.0
var leash_radius := 220.0
var current_target: TitanUnit

func configure(owner_unit: DefenderUnit, battle_registry: BattleRegistry, lane: RoadLane, slot_payload: Dictionary) -> void:
	unit = owner_unit
	registry = battle_registry
	road_lane = lane
	if slot_payload.has("id"):
		assigned_slot_id = slot_payload["id"]
	if slot_payload.has("position"):
		assigned_slot_position = slot_payload["position"]
	else:
		assigned_slot_position = unit.assigned_position if unit != null else Vector2.ZERO
	if slot_payload.has("range_multiplier"):
		range_multiplier = float(slot_payload["range_multiplier"])
	if slot_payload.has("leash_radius"):
		leash_radius = float(slot_payload["leash_radius"])
	if assigned_slot_position == Vector2.ZERO and unit != null:
		assigned_slot_position = unit.assigned_position

func tick(delta: float) -> void:
	if unit == null or registry == null or unit.damageable == null or unit.damageable.dead or unit.stats == null:
		return
	match _behavior_kind():
		UnitBehaviorProfileResource.BehaviorKind.RANGED_ARCHER:
			_tick_ranged_archer(delta)
		_:
			_tick_melee_defender(delta)

func effective_attack_range() -> float:
	if unit == null or unit.stats == null:
		return 0.0
	return (unit.stats.attack_radius + unit.stats.attack_range) * maxf(range_multiplier, 0.0)

func _behavior_kind() -> int:
	if unit != null and unit.defender_type != null and unit.defender_type.behavior_profile != null:
		return unit.defender_type.behavior_profile.behavior_kind
	if unit != null and unit.stats != null and unit.stats.attack_range > 0.0:
		return UnitBehaviorProfileResource.BehaviorKind.RANGED_ARCHER
	return UnitBehaviorProfileResource.BehaviorKind.MELEE_DEFENDER

func _vision_range() -> float:
	if unit != null and unit.defender_type != null and unit.defender_type.behavior_profile != null:
		return unit.defender_type.behavior_profile.vision_range
	return 160.0

func _tick_melee_defender(delta: float) -> void:
	if current_target != null and not _is_valid_titan(current_target):
		current_target = null
	if current_target != null and assigned_slot_position.distance_to(current_target.global_position) > leash_radius:
		current_target = null
	if current_target == null:
		current_target = _nearest_titan_in_vision_and_leash()
	if current_target == null:
		_move_to_slot(delta)
		return
	if unit.global_position.distance_to(current_target.global_position) <= unit.stats.attack_radius:
		return
	_move_toward(delta, current_target.global_position)

func _tick_ranged_archer(delta: float) -> void:
	if unit.global_position.distance_to(assigned_slot_position) > 4.0:
		current_target = null
		_move_to_slot(delta)
		return
	current_target = _nearest_titan_in_attack_range()

func _nearest_titan_in_vision_and_leash() -> TitanUnit:
	var nearest: TitanUnit = null
	var nearest_distance := INF
	var vision_range := maxf(_vision_range(), 0.0)
	var clamped_leash := maxf(leash_radius, 0.0)
	for titan in registry.alive_titans():
		var typed := titan as TitanUnit
		if not _is_valid_titan(typed):
			continue
		if unit.global_position.distance_to(typed.global_position) > vision_range:
			continue
		if assigned_slot_position.distance_to(typed.global_position) > clamped_leash:
			continue
		var distance := unit.global_position.distance_to(typed.global_position)
		if distance < nearest_distance:
			nearest = typed
			nearest_distance = distance
	return nearest

func _nearest_titan_in_attack_range() -> TitanUnit:
	var nearest: TitanUnit = null
	var nearest_distance := INF
	var attack_range := effective_attack_range()
	for titan in registry.alive_titans():
		var typed := titan as TitanUnit
		if not _is_valid_titan(typed):
			continue
		var distance := unit.global_position.distance_to(typed.global_position)
		if distance <= attack_range and distance < nearest_distance:
			nearest = typed
			nearest_distance = distance
	return nearest

func _is_valid_titan(titan: TitanUnit) -> bool:
	return is_instance_valid(titan) and titan.damageable != null and not titan.damageable.dead

func _move_to_slot(delta: float) -> void:
	if unit == null:
		return
	var target := assigned_slot_position
	# Simple road-lane movement for MVP defenders until full pathfinding exists.
	if road_lane != null and absf(unit.global_position.x - assigned_slot_position.x) > 4.0:
		target = road_lane.point_at_x(assigned_slot_position.x)
	_move_toward(delta, target)

func _move_toward(delta: float, target: Vector2) -> void:
	if unit == null or unit.stats == null:
		return
	var offset := target - unit.global_position
	var distance := offset.length()
	if distance <= 4.0:
		unit.global_position = target
		return
	var step := unit.stats.move_speed * delta
	if step >= distance:
		unit.global_position = target
		return
	unit.global_position += offset.normalized() * step
