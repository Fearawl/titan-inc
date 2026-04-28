extends Resource
class_name ProjectileProfileResource

enum ProjectileKind {
	ARROW,
	BOULDER,
}

@export var id: StringName
@export var projectile_kind := ProjectileKind.ARROW
@export var speed := 260.0
@export var arc_height := 80.0
@export var damage_multiplier := 1.0
@export var impact_radius := 18.0
@export var roll_distance := 0.0
@export var lifetime := 4.0
