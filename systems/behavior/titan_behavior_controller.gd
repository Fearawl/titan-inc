extends Node
class_name TitanBehaviorController

var unit: TitanUnit
var registry: BattleRegistry
var battle_lane: BattleLane
var projectile_root: Node2D
var boulder_scene: PackedScene
var _boulder_cooldown := 0.0
var _siege_melee_cooldown := 0.0

func configure(owner_unit: TitanUnit, battle_registry: BattleRegistry, lane: BattleLane) -> void:
	unit = owner_unit
	registry = battle_registry
	battle_lane = lane

func configure_projectiles(root: Node2D, boulder_projectile_scene: PackedScene) -> void:
	projectile_root = root
	boulder_scene = boulder_projectile_scene

func tick(delta: float) -> void:
	if unit == null or registry == null or unit.damageable == null or unit.damageable.dead or unit.stats == null:
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
	return TargetingService.nearest_blocking_structure_in_front(unit, registry.alive_structures())

func _nearest_melee_defender() -> DefenderUnit:
	var nearest: DefenderUnit = null
	var nearest_distance := INF
	var clamped_radius := maxf(unit.stats.attack_radius, 0.0)
	for defender in registry.alive_defenders():
		if not _is_melee_defender(defender):
			continue
		var distance := unit.global_position.distance_to(defender.global_position)
		if distance <= clamped_radius and distance < nearest_distance:
			nearest = defender
			nearest_distance = distance
	return nearest

func _is_melee_defender(defender: DefenderUnit) -> bool:
	if defender == null:
		return false
	if defender.defender_type != null and defender.defender_type.behavior_profile != null:
		return defender.defender_type.behavior_profile.behavior_kind == UnitBehaviorProfileResource.BehaviorKind.MELEE_DEFENDER
	if defender.stats == null:
		return false
	return defender.stats.attack_range <= 0.0

func _tick_fighter(delta: float) -> void:
	var blocking_structure := _nearest_blocking_structure()
	if blocking_structure != null and unit.global_position.distance_to(blocking_structure.global_position) <= unit.stats.attack_radius:
		return
	# Ranged defenders can shoot without body-blocking fighter titan movement.
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
	_boulder_cooldown = maxf(_boulder_cooldown - delta, 0.0)
	_siege_melee_cooldown = maxf(_siege_melee_cooldown - delta, 0.0)
	var blocking_structure := _nearest_blocking_structure()
	if blocking_structure != null and unit.global_position.distance_to(blocking_structure.global_position) <= unit.stats.attack_radius:
		if _siege_melee_cooldown <= 0.0:
			_perform_siege_melee(blocking_structure)
			_siege_melee_cooldown = _profile_siege_melee_cooldown()
		return
	if _boulder_cooldown <= 0.0 and _throw_boulder():
		_boulder_cooldown = _profile_boulder_cooldown()
		return
	_move_forward(delta)

func _perform_siege_melee(blocking_structure: DestructibleStructure) -> void:
	if unit == null or unit.damage_profile == null or unit.stats == null:
		return
	if blocking_structure != null:
		var structure_roll := unit.damage_profile.roll_damage(unit.effective_damage(), true)
		blocking_structure.apply_damage(float(structure_roll["amount"]), unit.actor_id, bool(structure_roll["is_critical"]))
	for defender in TargetingService.units_in_radius(unit.global_position, unit.stats.attack_radius, registry.alive_defenders()):
		var typed := defender as DefenderUnit
		if typed == null or typed.damageable == null:
			continue
		var unit_roll := unit.damage_profile.roll_damage(unit.effective_damage(), false)
		typed.damageable.apply_damage(float(unit_roll["amount"]), unit.actor_id, bool(unit_roll["is_critical"]))

func _throw_boulder() -> bool:
	if unit == null or projectile_root == null or boulder_scene == null:
		return false
	var profile := _colossal_projectile_profile()
	if profile == null or unit.stats == null:
		return false
	var projectile := boulder_scene.instantiate() as BoulderProjectile
	if projectile == null:
		return false
	projectile.registry = registry
	projectile.configure_to_position(unit, _boulder_target_position(profile), profile, unit.effective_damage() * profile.damage_multiplier)
	projectile_root.add_child(projectile)
	return true

func _boulder_target_position(profile: ProjectileProfileResource) -> Vector2:
	var target := _nearest_colossal_target_ahead(profile)
	if target != null:
		return target.global_position
	var range := maxf(unit.stats.attack_range + profile.roll_distance, 160.0)
	return unit.global_position + Vector2(range, 0.0)

func _nearest_colossal_target_ahead(profile: ProjectileProfileResource) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	var search_range := maxf(unit.stats.attack_range + profile.roll_distance, 0.0)
	for defender in registry.alive_defenders():
		if not _is_target_ahead(defender):
			continue
		var distance := unit.global_position.distance_to(defender.global_position)
		if distance <= search_range and distance < nearest_distance:
			nearest = defender
			nearest_distance = distance
	for structure in registry.alive_structures():
		if structure == null or structure.is_destroyed() or not _is_target_ahead(structure):
			continue
		var distance := unit.global_position.distance_to(structure.global_position)
		if distance <= search_range and distance < nearest_distance:
			nearest = structure
			nearest_distance = distance
	return nearest

func _is_target_ahead(target: Node2D) -> bool:
	return target != null and target.global_position.x >= unit.global_position.x - 8.0

func _behavior_profile() -> UnitBehaviorProfileResource:
	if unit == null or unit.titan_type == null:
		return null
	return unit.titan_type.behavior_profile

func _colossal_projectile_profile() -> ProjectileProfileResource:
	var behavior_profile := _behavior_profile()
	if behavior_profile == null:
		return null
	return behavior_profile.projectile_profile

func _profile_boulder_cooldown() -> float:
	var behavior_profile := _behavior_profile()
	if behavior_profile == null or behavior_profile.boulder_cooldown <= 0.0:
		return 10.0
	return behavior_profile.boulder_cooldown

func _profile_siege_melee_cooldown() -> float:
	var behavior_profile := _behavior_profile()
	if behavior_profile == null or behavior_profile.siege_melee_cooldown <= 0.0:
		return 5.0
	return behavior_profile.siege_melee_cooldown

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
