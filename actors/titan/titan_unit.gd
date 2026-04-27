extends CombatActor
class_name TitanUnit

var titan_type: TitanTypeResource

func configure_titan(type: TitanTypeResource, spawn_target_x: float) -> void:
	titan_type = type
	team = &"titans"
	display_color = Color(0.8, 0.28, 0.18)
	target_x = spawn_target_x
	configure(type.id, type.base_stats, type.damage_profile, null)
