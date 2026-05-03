@tool
extends Marker2D
class_name StructureMarker

@export var marker_id: StringName
@export var structure_type: StructureTypeResource
@export var size_override := Vector2.ZERO:
	set(value):
		size_override = value
		queue_redraw()
@export var debug_color := Color(0.55, 0.55, 0.55, 0.5):
	set(value):
		debug_color = value
		queue_redraw()

func runtime_id() -> StringName:
	if marker_id != &"":
		return marker_id
	if structure_type != null:
		return structure_type.id
	return StringName(name)

func authored_size() -> Vector2:
	if size_override != Vector2.ZERO:
		return size_override
	if structure_type != null:
		return structure_type.size
	return Vector2(48.0, 48.0)

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var size := authored_size()
	draw_rect(Rect2(-size * 0.5, size), debug_color, true)
	draw_rect(Rect2(-size * 0.5, size), Color(debug_color.r, debug_color.g, debug_color.b, 0.95), false, 2.0)
