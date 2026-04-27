extends Resource
class_name UnitStatsResource

@export var max_hp := 10.0
@export var damage := 1.0
@export var attack_rate := 1.0
@export var move_speed := 40.0
@export var attack_radius := 24.0
@export var attack_range := 0.0

func duplicate_stats() -> UnitStatsResource:
	var copy := UnitStatsResource.new()
	copy.max_hp = max_hp
	copy.damage = damage
	copy.attack_rate = attack_rate
	copy.move_speed = move_speed
	copy.attack_radius = attack_radius
	copy.attack_range = attack_range
	return copy
