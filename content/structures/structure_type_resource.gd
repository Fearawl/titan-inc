extends Resource
class_name StructureTypeResource

@export var id: StringName
@export var display_name := ""
@export var scene: PackedScene
@export var max_hp := 100.0
@export var blocks_movement := true
@export var repairable := true
@export var objective_priority := 0
@export var drop_table: DropTableResource
@export var collapse_damage: DamageProfileResource
@export var garrison_slots := 0
@export var position := Vector2.ZERO
@export var size := Vector2(64.0, 64.0)
