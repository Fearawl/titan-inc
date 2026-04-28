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
var projectile_root: Node2D
var arrow_scene: PackedScene

const DEFAULT_LEASH_RADIUS := 220.0

func configure(owner_unit: DefenderUnit, battle_registry: BattleRegistry, lane: RoadLane, slot_payload: Dictionary) -> void:
	unit = owner_unit
	registry = battle_registry
	road_lane = lane
	if slot_payload.has("id"):
		assigned_slot_id = slot_payload["id"]
	var has_slot_position := false
	if slot_payload.has("position"):
		assigned_slot_position = slot_payload["position"]
		has_slot_position = true
	else:
		assigned_slot_position = unit.assigned_position if unit != null else Vector2.ZERO
	if slot_payload.has("range_multiplier"):
		range_multiplier = float(slot_payload["range_multiplier"])
	if slot_payload.has("leash_radius"):
		leash_radius = float(slot_payload["leash_radius"])
	if not has_slot_position and assigned_slot_position == Vector2.ZERO and unit != null:
		assigned_slot_position = unit.assigned_position

func configure_projectiles(root: Node2D, arrow_projectile_scene: PackedScene) -> void:
	projectile_root = root
	arrow_scene = arrow_projectile_scene

func clear_slot_assignment() -> void:
	assigned_slot_id = &""
	range_multiplier = 1.0
	leash_radius = DEFAULT_LEASH_RADIUS
	current_target = null
	var fallback_position := unit.global_position if unit != null else Vector2.ZERO
	# MVP fallback: fallen tower defenders rejoin ground behavior on the road lane.
	if road_lane != null and unit != null:
		fallback_position = road_lane.point_at_x(unit.global_position.x)
	assigned_slot_position = fallback_position
	if unit != null:
		unit.assigned_position = fallback_position
		unit.target_x = fallback_position.x

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
	current_target = _nearest_titan_in_attack_range()
	if current_target != null:
		if unit.can_attack() and _fire_arrow(current_target):
			# Task 6 moves ranged defender damage ownership from CombatResolver to the projectile scene.
			unit.consume_attack_cooldown()
		return
	_move_to_slot(delta)

func _fire_arrow(target: TitanUnit) -> bool:
	if unit == null or target == null or projectile_root == null or arrow_scene == null:
		return false
	if unit.defender_type == null or unit.defender_type.behavior_profile == null:
		return false
	var projectile_profile := unit.defender_type.behavior_profile.projectile_profile
	if projectile_profile == null or unit.damage_profile == null or unit.stats == null:
		return false
	var projectile := arrow_scene.instantiate() as Projectile
	if projectile == null:
		return false
	var roll := unit.damage_profile.roll_damage(unit.stats.damage, false)
	projectile.registry = registry
	projectile.configure(unit, target, projectile_profile, float(roll["amount"]))
	projectile_root.add_child(projectile)
	return true

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
