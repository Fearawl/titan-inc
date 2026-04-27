extends Resource
class_name CostResource

@export var amounts: Dictionary = {}

func to_dictionary() -> Dictionary:
	var result := {}
	for key in amounts.keys():
		var amount := float(amounts[key])
		if amount > 0.0:
			result[StringName(str(key))] = amount
	return result

func multiplied(factor: float) -> Dictionary:
	var result := {}
	for key in amounts.keys():
		result[StringName(str(key))] = ceil(float(amounts[key]) * factor)
	return result
