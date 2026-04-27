extends Resource
class_name DamageProfileResource

@export var damage_type: StringName = &"physical"
@export var is_aoe := true
@export var critical_chance := 0.05
@export var critical_multiplier := 2.0
@export var structure_multiplier := 1.0
@export var unit_multiplier := 1.0

func roll_damage(base_damage: float, target_is_structure: bool) -> Dictionary:
	var multiplier := maxf(structure_multiplier if target_is_structure else unit_multiplier, 0.0)
	var critical := randf() < clampf(critical_chance, 0.0, 1.0)
	var total := maxf(base_damage * multiplier, 0.0)
	if critical:
		total *= maxf(critical_multiplier, 0.0)
	return {
		"amount": maxf(total, 0.0),
		"is_critical": critical,
		"damage_type": damage_type,
	}
