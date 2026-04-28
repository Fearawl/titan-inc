extends CombatActor
class_name DefenderUnit

var defender_type: DefenderTypeResource

@onready var behavior_controller: DefenderBehaviorController = $DefenderBehaviorController

func configure_defender(type: DefenderTypeResource, position: Vector2) -> void:
	defender_type = type
	team = &"defenders"
	display_color = Color(0.22, 0.42, 0.85)
	assigned_position = position
	target_x = position.x
	configure(type.id, type.base_stats, type.damage_profile, type.drop_table)

func configure_behavior(registry: BattleRegistry, road_lane: RoadLane, slot_payload: Dictionary) -> void:
	if behavior_controller != null:
		behavior_controller.configure(self, registry, road_lane, slot_payload)
