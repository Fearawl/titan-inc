@tool
extends Node2D
class_name CityLayout

@export var battle_lane_path: NodePath
@export var road_lane_path: NodePath

func structure_markers() -> Array[StructureMarker]:
	var result: Array[StructureMarker] = []
	_collect_structure_markers(self, result)
	return result

func spawn_markers() -> Array[SpawnPointMarker]:
	var result: Array[SpawnPointMarker] = []
	_collect_spawn_markers(self, result)
	return result

func defense_point_markers() -> Array[DefensePointMarker]:
	var result: Array[DefensePointMarker] = []
	_collect_defense_point_markers(self, result)
	return result

func battle_lane() -> BattleLane:
	return get_node_or_null(battle_lane_path) as BattleLane

func road_lane() -> RoadLane:
	return get_node_or_null(road_lane_path) as RoadLane

func structure_runtime_id_for_marker(marker_id: StringName) -> StringName:
	if marker_id == &"":
		return &""
	for marker in structure_markers():
		if marker.marker_id == marker_id or StringName(marker.name) == marker_id:
			return marker.runtime_id()
	return &""

func _collect_structure_markers(node: Node, result: Array[StructureMarker]) -> void:
	for child in node.get_children():
		if child is StructureMarker:
			result.append(child)
		_collect_structure_markers(child, result)

func _collect_spawn_markers(node: Node, result: Array[SpawnPointMarker]) -> void:
	for child in node.get_children():
		if child is SpawnPointMarker:
			result.append(child)
		_collect_spawn_markers(child, result)

func _collect_defense_point_markers(node: Node, result: Array[DefensePointMarker]) -> void:
	for child in node.get_children():
		if child is DefensePointMarker:
			result.append(child)
		_collect_defense_point_markers(child, result)
