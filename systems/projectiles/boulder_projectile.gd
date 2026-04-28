extends Projectile
class_name BoulderProjectile

enum BoulderState {
	FLYING,
	ROLLING,
	IMPACTED,
}

var state := BoulderState.FLYING
var _roll_start := Vector2.ZERO
var _roll_travel := 0.0
var _total_elapsed := 0.0
var _damaged_defenders := {}

func tick_projectile(delta: float, battle_registry: BattleRegistry) -> void:
	if state == BoulderState.IMPACTED or profile == null:
		return
	registry = battle_registry
	_total_elapsed += delta
	if _total_elapsed >= maxf(profile.lifetime, 0.01):
		_destroy()
		return
	match state:
		BoulderState.FLYING:
			_tick_flying(delta)
		BoulderState.ROLLING:
			_tick_rolling(delta)

func _tick_flying(delta: float) -> void:
	elapsed += delta
	var t := clampf(elapsed / maxf(_duration, 0.01), 0.0, 1.0)
	global_position = start_position.lerp(target_position, t) + Vector2(0.0, -sin(t * PI) * profile.arc_height)
	if t >= 1.0:
		global_position = target_position
		_roll_start = global_position
		_roll_travel = 0.0
		state = BoulderState.ROLLING
		_damage_rolling_defenders()
		_check_structure_collision()

func _tick_rolling(delta: float) -> void:
	var step := maxf(profile.speed, 0.0) * delta
	_roll_travel = minf(_roll_travel + step, maxf(profile.roll_distance, 0.0))
	global_position = _roll_start + Vector2(_roll_travel, 0.0)
	_damage_rolling_defenders()
	if _check_structure_collision():
		return
	if _roll_travel >= maxf(profile.roll_distance, 0.0):
		_destroy()

func _damage_rolling_defenders() -> void:
	if registry == null:
		return
	for defender in TargetingService.units_in_radius(global_position, profile.impact_radius, registry.alive_defenders()):
		var typed := defender as DefenderUnit
		if typed == null or typed.damageable == null:
			continue
		var key := typed.get_instance_id()
		if _damaged_defenders.has(key):
			continue
		typed.damageable.apply_damage(damage, source_id, is_critical)
		_damaged_defenders[key] = true

func _check_structure_collision() -> bool:
	var structure := _nearest_structure_in_front()
	if structure == null:
		return false
	if global_position.distance_to(structure.global_position) > profile.impact_radius:
		return false
	_impact_structure(structure)
	return true

func _nearest_structure_in_front() -> DestructibleStructure:
	if registry == null:
		return null
	var nearest: DestructibleStructure = null
	var nearest_x_distance := INF
	for structure in registry.alive_structures():
		if structure == null or structure.is_destroyed():
			continue
		var x_distance := structure.global_position.x - global_position.x
		if x_distance < -profile.impact_radius:
			continue
		if x_distance < nearest_x_distance:
			nearest = structure
			nearest_x_distance = x_distance
	return nearest

func _impact_structure(structure: DestructibleStructure) -> void:
	if structure != null:
		structure.apply_damage(damage, source_id, is_critical)
	_damage_impact_defenders()
	_destroy()

func _damage_impact_defenders() -> void:
	if registry == null:
		return
	for defender in TargetingService.units_in_radius(global_position, profile.impact_radius, registry.alive_defenders()):
		var typed := defender as DefenderUnit
		if typed == null or typed.damageable == null:
			continue
		var key := typed.get_instance_id()
		if _damaged_defenders.has(key):
			continue
		typed.damageable.apply_damage(damage, source_id, is_critical)
		_damaged_defenders[key] = true

func _destroy() -> void:
	state = BoulderState.IMPACTED
	_hit = true
	queue_free()
