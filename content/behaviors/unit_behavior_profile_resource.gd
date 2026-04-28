extends Resource
class_name UnitBehaviorProfileResource

const ProjectileProfileResource := preload("res://content/projectiles/projectile_profile_resource.gd")

enum BehaviorKind {
	FIGHTER_PUSH,
	UNSTOPPABLE_PUSH,
	SIEGE_COLOSSAL,
	MELEE_DEFENDER,
	RANGED_ARCHER,
}

# Data consumed by behavior controllers; runtime AI state lives on controller nodes.
@export var id: StringName
@export var behavior_kind := BehaviorKind.FIGHTER_PUSH
@export var melee_stop_on_attacker := false
@export var ignores_incoming_melee := false
@export var moving_aoe_interval := 0.8
@export var boulder_cooldown := 10.0
@export var siege_melee_cooldown := 5.0
@export var vision_range := 160.0
@export var leash_radius := 220.0
@export var tower_range_multiplier := 2.0
@export var projectile_profile: ProjectileProfileResource
