extends Projectile
class_name ArrowProjectile

func _impact(battle_registry: BattleRegistry) -> void:
	if battle_registry == null or profile == null:
		return
	var targets := TargetingService.units_in_radius(target_position, profile.impact_radius, battle_registry.alive_titans())
	if targets.is_empty():
		return
	var titan := targets[0] as TitanUnit
	if titan == null or titan.damageable == null:
		return
	titan.damageable.apply_damage(damage, source_id)
