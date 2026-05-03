extends RefCounted
class_name TargetingService

static func nearest_structure_in_front(unit: CombatActor, structures: Array[DestructibleStructure]) -> DestructibleStructure:
	if not is_instance_valid(unit):
		return null
	var best: DestructibleStructure = null
	var best_distance := INF
	for structure in structures:
		if not is_instance_valid(structure) or structure.is_destroyed():
			continue
		if structure.global_position.x < unit.global_position.x - 8.0:
			continue
		var distance := unit.global_position.distance_to(structure.global_position)
		if distance < best_distance:
			best = structure
			best_distance = distance
	return best

static func nearest_blocking_structure_in_front(unit: CombatActor, structures: Array[DestructibleStructure], vertical_padding := 24.0) -> DestructibleStructure:
	if not is_instance_valid(unit):
		return null
	var best: DestructibleStructure = null
	var best_x_distance := INF
	for structure in structures:
		if not _is_blocking_structure_candidate(unit, structure, vertical_padding):
			continue
		var half_size := structure.current_size() * 0.5
		var x_distance := maxf(structure.global_position.x - half_size.x - unit.global_position.x, 0.0)
		if x_distance < best_x_distance:
			best = structure
			best_x_distance = x_distance
	return best

static func _is_blocking_structure_candidate(unit: CombatActor, structure: DestructibleStructure, vertical_padding: float) -> bool:
	if not is_instance_valid(structure) or structure.is_destroyed() or structure.structure_type == null:
		return false
	if not structure.structure_type.blocks_movement:
		return false
	var half_size := structure.current_size() * 0.5
	if structure.global_position.x + half_size.x < unit.global_position.x - 8.0:
		return false
	var vertical_delta := absf(structure.global_position.y - unit.global_position.y)
	return vertical_delta <= half_size.y + maxf(vertical_padding, 0.0)

static func units_in_radius(origin: Vector2, radius: float, units: Array) -> Array:
	var result := []
	var clamped_radius := maxf(radius, 0.0)
	for unit in units:
		if not is_instance_valid(unit):
			continue
		if not unit is CombatActor:
			continue
		if unit.damageable == null or unit.damageable.dead:
			continue
		if origin.distance_to(unit.global_position) <= clamped_radius:
			result.append(unit)
	return result

static func nearest_unit_in_radius(origin: Vector2, radius: float, units: Array) -> CombatActor:
	var nearest: CombatActor = null
	var nearest_distance := INF
	var clamped_radius := maxf(radius, 0.0)
	for unit in units:
		if not is_instance_valid(unit):
			continue
		if not unit is CombatActor:
			continue
		if unit.damageable == null or unit.damageable.dead:
			continue
		var distance := origin.distance_to(unit.global_position)
		if distance <= clamped_radius and distance < nearest_distance:
			nearest = unit
			nearest_distance = distance
	return nearest
