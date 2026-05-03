extends SceneTree

const STRUCTURE_SCENE := preload("res://structures/destructible/destructible_structure.tscn")
const WOODEN_FENCE := preload("res://content/structures/wooden_fence.tres")
const CITY_LAYOUT_SCRIPT := preload("res://world/layout/city_layout.gd")
const STRUCTURE_MARKER_SCRIPT := preload("res://world/layout/structure_marker.gd")
const SPAWN_POINT_MARKER_SCRIPT := preload("res://world/layout/spawn_point_marker.gd")
const DEFENSE_POINT_MARKER_SCRIPT := preload("res://world/layout/defense_point_marker.gd")

var _failures: Array[String] = []

func _init() -> void:
	_test_layout_collects_nested_markers()
	_test_defense_point_marker_builds_slot_resource()
	_test_blocking_structure_targeting_uses_bounds_and_blocking_flag()
	if _failures.is_empty():
		print("PASS city layout authoring smoke tests")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _test_layout_collects_nested_markers() -> void:
	var layout = CITY_LAYOUT_SCRIPT.new()
	var structures_root := Node2D.new()
	var spawns_root := Node2D.new()
	layout.add_child(structures_root)
	layout.add_child(spawns_root)
	var structure_marker = STRUCTURE_MARKER_SCRIPT.new()
	structure_marker.marker_id = &"wooden_fence_a"
	structure_marker.structure_type = WOODEN_FENCE
	structures_root.add_child(structure_marker)
	var spawn_marker = SPAWN_POINT_MARKER_SCRIPT.new()
	spawn_marker.spawn_kind = 0
	spawns_root.add_child(spawn_marker)
	_expect_eq(layout.structure_markers().size(), 1, "CityLayout should collect nested structure markers.")
	_expect_eq(layout.spawn_markers().size(), 1, "CityLayout should collect nested spawn markers.")
	_expect_same(layout.structure_markers()[0], structure_marker, "Collected structure marker should be the authored marker.")
	layout.free()

func _test_defense_point_marker_builds_slot_resource() -> void:
	var marker = DEFENSE_POINT_MARKER_SCRIPT.new()
	marker.name = "GateMelee"
	marker.slot_id = &"gate_melee"
	marker.global_position = Vector2(640.0, 420.0)
	marker.capacity = 10
	marker.range_multiplier = 1.5
	marker.leash_radius = 280.0
	marker.vision_radius = 420.0
	marker.rear_guard_radius = 540.0
	var tags: Array[StringName] = [&"melee"]
	marker.allowed_defender_tags = tags
	var slot := marker.to_slot_resource(&"wall_gate")
	_expect_eq(slot.id, &"gate_melee", "Defense marker should preserve slot id.")
	_expect_eq(slot.position, marker.global_position, "Defense marker should use its global position.")
	_expect_eq(slot.capacity, 10, "Defense marker should preserve capacity.")
	_expect_eq(slot.vision_radius, 420.0, "Defense marker should export vision radius.")
	_expect_eq(slot.rear_guard_radius, 540.0, "Defense marker should export rear guard radius.")
	_expect_eq(slot.anchor_structure_id, &"wall_gate", "Defense marker should preserve anchor structure id.")
	marker.free()

func _test_blocking_structure_targeting_uses_bounds_and_blocking_flag() -> void:
	var titan := CombatActor.new()
	titan.global_position = Vector2(100.0, 300.0)
	var non_blocking := _make_structure(&"non_blocking", Vector2(130.0, 300.0), Vector2(90.0, 90.0), false)
	var off_lane := _make_structure(&"off_lane", Vector2(150.0, 540.0), Vector2(90.0, 90.0), true)
	var blocking := _make_structure(&"blocking", Vector2(190.0, 300.0), Vector2(90.0, 90.0), true)
	var structures: Array[DestructibleStructure] = [non_blocking, off_lane, blocking]
	var target := TargetingService.nearest_blocking_structure_in_front(titan, structures, 24.0)
	_expect_same(target, blocking, "Targeting should choose the nearest blocking structure intersecting the titan lane.")
	titan.free()
	for structure in structures:
		structure.free()

func _make_structure(id: StringName, position: Vector2, size: Vector2, blocks_movement: bool) -> DestructibleStructure:
	var structure_type := WOODEN_FENCE.duplicate(true) as StructureTypeResource
	structure_type.id = id
	structure_type.size = size
	structure_type.blocks_movement = blocks_movement
	var structure := STRUCTURE_SCENE.instantiate() as DestructibleStructure
	structure.configure_structure(structure_type, position, id, size)
	return structure

func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s Expected %s, got %s." % [message, str(expected), str(actual)])

func _expect_same(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s Expected same instance." % message)
