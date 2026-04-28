extends Node2D
class_name Projectile

var source_id: StringName
var team: StringName
var damage := 0.0
var is_critical := false
var profile: ProjectileProfileResource
var start_position := Vector2.ZERO
var target_position := Vector2.ZERO
var elapsed := 0.0
var _duration := 1.0
var _hit := false
var registry: BattleRegistry

func configure(source: CombatActor, target: CombatActor, projectile_profile: ProjectileProfileResource, damage_amount: float, critical := false) -> void:
	if is_instance_valid(target):
		configure_to_position(source, target.global_position, projectile_profile, damage_amount, critical)
	else:
		queue_free()

func configure_to_position(source: CombatActor, position: Vector2, projectile_profile: ProjectileProfileResource, damage_amount: float, critical := false) -> void:
	profile = projectile_profile
	damage = maxf(damage_amount, 0.0)
	is_critical = critical
	if source == null or profile == null:
		queue_free()
		return
	source_id = source.actor_id
	team = source.team
	start_position = source.global_position
	target_position = position
	global_position = start_position
	_configure_duration()

func _configure_duration() -> void:
	var distance := start_position.distance_to(target_position)
	_duration = maxf(distance / maxf(profile.speed, 0.01), 0.01)

func tick_projectile(delta: float, battle_registry: BattleRegistry) -> void:
	if _hit or profile == null:
		return
	registry = battle_registry
	elapsed += delta
	var t := clampf(elapsed / maxf(_duration, 0.01), 0.0, 1.0)
	global_position = start_position.lerp(target_position, t) + Vector2(0.0, -sin(t * PI) * profile.arc_height)
	if t >= 1.0:
		_hit = true
		_impact(registry)
		queue_free()

func _process(delta: float) -> void:
	tick_projectile(delta, registry)

func _impact(_battle_registry: BattleRegistry) -> void:
	pass
