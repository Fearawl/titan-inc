extends Resource
class_name ZoneResource

@export var id: StringName
@export var display_name := ""
@export var start_x := 0.0
@export var end_x := 1000.0
@export var structures: Array[StructureTypeResource] = []
@export var defender_spawn_rules: Array[SpawnRuleResource] = []
@export var defense_positions: Array[DefensePositionResource] = []
