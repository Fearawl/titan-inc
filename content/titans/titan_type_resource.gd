extends Resource
class_name TitanTypeResource

const UnitBehaviorProfileResource := preload("res://content/behaviors/unit_behavior_profile_resource.gd")

@export var id: StringName
@export var display_name := ""
@export var scene: PackedScene
@export var base_stats: UnitStatsResource
@export var spawn_cooldown := 5.0
@export var max_army_limit := 100
@export var base_cost: CostResource
@export var cost_formula: ProgressionFormulaResource
@export var damage_profile: DamageProfileResource
@export var behavior_profile: UnitBehaviorProfileResource
@export var tags: Array[StringName] = []

func get_purchase_cost(current_limit: int) -> Dictionary:
	if base_cost == null:
		return {}
	var cost := base_cost.to_dictionary()
	if cost_formula == null:
		return cost
	var purchases_after_first := maxi(current_limit - 1, 0)
	for i in range(purchases_after_first):
		cost = cost_formula.next_cost(cost, i)
	return cost
