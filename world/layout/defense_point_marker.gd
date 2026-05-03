@tool
extends Marker2D
class_name DefensePointMarker

@export var slot_id: StringName
@export var slot_type := DefenseSlotResource.SlotType.MELEE_FRONT
@export var capacity := 1
@export var range_multiplier := 1.0
@export var leash_radius := 220.0
@export var vision_radius := 260.0
@export var rear_guard_radius := 360.0
@export var allowed_defender_tags: Array[StringName] = []
@export var anchor_structure_marker_id: StringName
@export var debug_color := Color(0.2, 0.45, 1.0, 0.65):
	set(value):
		debug_color = value
		queue_redraw()

func to_slot_resource(anchor_structure_id: StringName = &"") -> DefenseSlotResource:
	var slot := DefenseSlotResource.new()
	slot.id = slot_id if slot_id != &"" else StringName(name)
	slot.slot_type = slot_type
	slot.capacity = maxi(capacity, 1)
	slot.position = global_position
	slot.range_multiplier = maxf(range_multiplier, 0.0)
	slot.leash_radius = maxf(leash_radius, 0.0)
	slot.vision_radius = maxf(vision_radius, 0.0)
	slot.rear_guard_radius = maxf(rear_guard_radius, 0.0)
	slot.allowed_defender_tags = allowed_defender_tags.duplicate()
	slot.anchor_structure_id = anchor_structure_id
	return slot

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, 10.0, debug_color)
	draw_circle(Vector2.ZERO, 18.0, Color(debug_color.r, debug_color.g, debug_color.b, 0.25))
	draw_line(Vector2(-16.0, -16.0), Vector2(16.0, 16.0), Color.WHITE, 2.0)
	draw_line(Vector2(-16.0, 16.0), Vector2(16.0, -16.0), Color.WHITE, 2.0)
