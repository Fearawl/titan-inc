extends Resource
class_name DefensePositionResource

@export var id: StringName
@export var position_type: StringName = &"ground"
@export var world_position := Vector2.ZERO
@export var capacity := 4
@export var linked_structure_id: StringName = &""
