extends Resource
class_name StatUpgradeResource

enum TargetStat {
	DAMAGE,
	ATTACK_RATE,
	MOVE_SPEED,
	ATTACK_RADIUS,
}

enum Scope {
	ALL_TITANS,
	TITAN_TYPE,
}

const MIN_ATTACK_RATE := 0.01

@export var id: StringName
@export var display_name := ""
@export var target_stat := TargetStat.DAMAGE
@export var scope := Scope.ALL_TITANS
@export var titan_type_id: StringName
@export var max_level := 100
@export var additive_per_level := 0.0
@export var multiplier_per_level := 0.0
@export var base_cost: CostResource
@export var cost_formula: ProgressionFormulaResource

func applies_to_titan(titan_type: TitanTypeResource) -> bool:
	if titan_type == null:
		return false
	if scope == Scope.ALL_TITANS:
		return true
	return titan_type.id == titan_type_id

func get_purchase_cost(current_level: int) -> Dictionary:
	if base_cost == null:
		return {}
	var cost := base_cost.to_dictionary()
	if cost_formula == null:
		return cost
	for i in range(maxi(current_level, 0)):
		cost = cost_formula.next_cost(cost, i)
	return cost

func apply_to_stats(stats: UnitStatsResource, level: int) -> void:
	if stats == null:
		return
	var applied_level := clampi(level, 0, maxi(max_level, 0))
	if applied_level <= 0:
		return
	match target_stat:
		TargetStat.DAMAGE:
			stats.damage = _modified_stat(stats.damage, applied_level)
		TargetStat.ATTACK_RATE:
			stats.attack_rate = maxf(_modified_stat(stats.attack_rate, applied_level), MIN_ATTACK_RATE)
		TargetStat.MOVE_SPEED:
			stats.move_speed = _modified_stat(stats.move_speed, applied_level)
		TargetStat.ATTACK_RADIUS:
			stats.attack_radius = _modified_stat(stats.attack_radius, applied_level)

func _modified_stat(value: float, level: int) -> float:
	var modified := value * maxf(1.0 + multiplier_per_level * float(level), 0.0)
	modified += additive_per_level * float(level)
	return maxf(modified, 0.0)
