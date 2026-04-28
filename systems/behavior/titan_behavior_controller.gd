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

func _behavior_kind() -> int:
	if unit.titan_type == null or unit.titan_type.behavior_profile == null:
		return UnitBehaviorProfileResource.BehaviorKind.FIGHTER_PUSH
	return unit.titan_type.behavior_profile.behavior_kind

func _nearest_blocking_structure() -> DestructibleStructure:
	return TargetingService.nearest_structure_in_front(unit, registry.alive_structures())

func _nearest_melee_defender() -> DefenderUnit:
	return TargetingService.nearest_unit_in_radius(unit.global_position, unit.stats.attack_radius, registry.alive_defenders()) as DefenderUnit

func _tick_fighter(delta: float) -> void:
	var blocking_structure := _nearest_blocking_structure()
	if blocking_structure != null and unit.global_position.distance_to(blocking_structure.global_position) <= unit.stats.attack_radius:
		return
	# Fighter titans stop for melee defenders so CombatResolver can trade blows in place.
	if _nearest_melee_defender() != null:
		return
	_move_forward(delta)

func _tick_unstoppable(delta: float) -> void:
	var blocking_structure := _nearest_blocking_structure()
	if blocking_structure != null and unit.global_position.distance_to(blocking_structure.global_position) <= unit.stats.attack_radius:
		return
	# Unstoppable titans ignore melee attackers and only halt at blocking structures.
	_move_forward(delta)

func _tick_colossal(delta: float) -> void:
	var blocking_structure := _nearest_blocking_structure()
	if blocking_structure != null and unit.global_position.distance_to(blocking_structure.global_position) <= unit.stats.attack_radius:
		return
	_move_forward(delta)

func _move_forward(delta: float) -> void:
	_move_toward_x(delta, unit.target_x)

func _move_toward_x(delta: float, target_x_value: float) -> void:
	if unit.stats == null:
		return
	var distance := target_x_value - unit.global_position.x
	if absf(distance) < 4.0:
		_keep_inside_lane()
		return
	var direction := signf(distance)
	unit.global_position.x += direction * unit.stats.move_speed * delta
	_keep_inside_lane()

func _keep_inside_lane() -> void:
	if battle_lane != null:
		unit.global_position = battle_lane.clamp_to_lane_y(unit.global_position)
