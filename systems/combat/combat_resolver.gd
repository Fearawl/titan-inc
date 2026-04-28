extends Node
class_name CombatResolver

@export var registry_path: NodePath

@onready var registry: BattleRegistry = get_node_or_null(registry_path) as BattleRegistry

func _process(_delta: float) -> void:
	if registry == null:
		return
	_resolve_titan_attacks()
	_resolve_defender_attacks()

func _resolve_titan_attacks() -> void:
	for titan in registry.alive_titans():
		if not titan.can_attack():
			continue
		var hit_anything := false
		for defender in TargetingService.units_in_radius(titan.global_position, titan.stats.attack_radius, registry.alive_defenders()):
			var roll := titan.damage_profile.roll_damage(titan.stats.damage, false)
			defender.damageable.apply_damage(float(roll["amount"]), titan.actor_id)
			hit_anything = true
		var target_structure := TargetingService.nearest_structure_in_front(titan, registry.alive_structures())
		if target_structure != null and titan.global_position.distance_to(target_structure.global_position) <= titan.stats.attack_radius:
			var roll := titan.damage_profile.roll_damage(titan.stats.damage, true)
			target_structure.apply_damage(float(roll["amount"]), titan.actor_id)
			hit_anything = true
		if hit_anything:
			titan.consume_attack_cooldown()

func _resolve_defender_attacks() -> void:
	for defender in registry.alive_defenders():
		if not defender.can_attack():
			continue
		if _is_ranged_archer(defender):
			continue
		var attack_range := defender.stats.attack_radius + defender.stats.attack_range
		if defender.behavior_controller != null:
			attack_range = defender.behavior_controller.effective_attack_range()
		var targets := TargetingService.units_in_radius(defender.global_position, attack_range, registry.alive_titans())
		if targets.is_empty():
			continue
		var target: TitanUnit = targets[0] as TitanUnit
		if target == null:
			continue
		var roll := defender.damage_profile.roll_damage(defender.stats.damage, false)
		target.damageable.apply_damage(float(roll["amount"]), defender.actor_id)
		defender.consume_attack_cooldown()

func _is_ranged_archer(defender: DefenderUnit) -> bool:
	return defender.defender_type != null \
		and defender.defender_type.behavior_profile != null \
		and defender.defender_type.behavior_profile.behavior_kind == UnitBehaviorProfileResource.BehaviorKind.RANGED_ARCHER
