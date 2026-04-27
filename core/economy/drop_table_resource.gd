extends Resource
class_name DropTableResource

@export var guaranteed: Dictionary = {}

func roll_drops() -> Dictionary:
	var result := {}
	for key in guaranteed.keys():
		var amount := float(guaranteed[key])
		if amount > 0.0:
			result[StringName(str(key))] = amount
	return result
