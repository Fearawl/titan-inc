@tool
extends Marker2D
class_name SpawnPointMarker

enum SpawnKind {
	TITAN,
	DEFENDER,
	REPAIR,
}

@export var spawn_kind := SpawnKind.TITAN
@export var marker_id: StringName
@export var debug_color := Color(0.2, 0.8, 0.2, 0.65):
	set(value):
		debug_color = value
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, 14.0, debug_color)
	draw_line(Vector2(-18.0, 0.0), Vector2(18.0, 0.0), Color.WHITE, 2.0)
	draw_line(Vector2(0.0, -18.0), Vector2(0.0, 18.0), Color.WHITE, 2.0)
