extends Resource
class_name SpawnRuleResource

@export var id: StringName
@export var spawn_cooldown := 5.0
@export var max_alive := 10
@export var allowed_types: Array[Resource] = []
