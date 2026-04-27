extends Resource
class_name DefenderTypeResource

@export var id: StringName
@export var display_name := ""
@export var scene: PackedScene
@export var base_stats: UnitStatsResource
@export var spawn_weight := 1.0
@export var preferred_position_types: Array[StringName] = [&"ground"]
@export var can_climb_tower := false
@export var formation_spacing := 18.0
@export var damage_profile: DamageProfileResource
@export var drop_table: DropTableResource
@export var is_hero := false
