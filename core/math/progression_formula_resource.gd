extends Resource
class_name ProgressionFormulaResource

enum FormulaMode {
	MULTIPLY_PREVIOUS,
	ADD_TO_PREVIOUS,
	EXPLICIT_TABLE,
}

@export var mode := FormulaMode.MULTIPLY_PREVIOUS
@export var factor := 2.0
@export var addend := 1.0
@export var explicit_costs: Array[Dictionary] = []

func next_cost(previous_cost: Dictionary, purchase_count: int) -> Dictionary:
	if mode == FormulaMode.EXPLICIT_TABLE and purchase_count >= 0 and purchase_count < explicit_costs.size():
		return _name_keys(explicit_costs[purchase_count])
	if mode == FormulaMode.ADD_TO_PREVIOUS:
		return _add(previous_cost, addend)
	return _multiply(previous_cost, factor)

func _multiply(cost: Dictionary, value: float) -> Dictionary:
	var result := {}
	for key in cost.keys():
		var amount: float = ceil(float(cost[key]) * value)
		if amount > 0.0:
			result[StringName(str(key))] = amount
	return result

func _add(cost: Dictionary, value: float) -> Dictionary:
	var result := {}
	for key in cost.keys():
		var amount: float = ceil(float(cost[key]) + value)
		if amount > 0.0:
			result[StringName(str(key))] = amount
	return result

func _name_keys(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source.keys():
		var amount := float(source[key])
		if amount > 0.0:
			result[StringName(str(key))] = amount
	return result
