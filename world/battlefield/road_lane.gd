extends Node2D
class_name RoadLane

@export var road_y := 420.0
@export var min_x := 0.0
@export var max_x := 2300.0

# Simple MVP road model until full battlefield pathfinding is introduced.
func point_at_x(x: float) -> Vector2:
	return Vector2(clampf(x, min_x, max_x), road_y)
