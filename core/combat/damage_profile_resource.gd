extends Resource
class_name DamageProfileResource

@export var damage_type: StringName = &"physical"
@export var is_aoe := true
@export var critical_chance := 0.05
@export var critical_multiplier := 2.0
@export var structure_multiplier := 1.0
@export var unit_multiplier := 1.0

func roll_damage(base_damage: float, target_is_structure: bool) -> Dictionary:
	var multiplier := structure_multiplier if target_is_structure else unit_multiplier
	var critical := randf() < critical_chance
	var total := base_damage * multiplier
	if critical:
		total *= critical_multiplier
	return {
		"amount": total,
		"is_critical": critical,
		"damage_type": damage_type,
	}
