extends Node2D
class_name BattleLane

@export var lane_rect := Rect2(Vector2(0.0, 230.0), Vector2(2300.0, 230.0))
@export var titan_spawn_x := 80.0
@export var titan_spawn_x_variance := 24.0
@export var debug_visible := true
@export var debug_color := Color(0.1, 0.9, 0.9, 0.35)

# Uses the user-approved yellow combat band from the reference screenshot.
func random_titan_spawn_position() -> Vector2:
	var x := titan_spawn_x + randf_range(-titan_spawn_x_variance, titan_spawn_x_variance)
	var y := randf_range(lane_rect.position.y, lane_rect.position.y + lane_rect.size.y)
	return Vector2(x, y)

func clamp_to_lane_y(position: Vector2) -> Vector2:
	return Vector2(position.x, clampf(position.y, lane_rect.position.y, lane_rect.position.y + lane_rect.size.y))

func _draw() -> void:
	if not debug_visible:
		return
	draw_rect(lane_rect, debug_color, false, 2.0)
