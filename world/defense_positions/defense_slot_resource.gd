extends Resource
class_name DefenseSlotResource

enum SlotType {
	MELEE_FRONT,
	RANGED_GROUND,
	TOWER_GARRISON,
	AMBUSH,
	FALLBACK,
}

@export var id: StringName
@export var slot_type := SlotType.MELEE_FRONT
@export var capacity := 1
@export var position := Vector2.ZERO
@export var range_multiplier := 1.0
@export var leash_radius := 220.0
@export var vision_radius := 260.0
@export var rear_guard_radius := 360.0
@export var allowed_defender_tags: Array[StringName] = []
@export var anchor_structure_id: StringName
