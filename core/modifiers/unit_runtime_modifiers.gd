extends RefCounted
class_name UnitRuntimeModifiers

var cursor_damage_multiplier := 1.0

func reset_transient() -> void:
	cursor_damage_multiplier = 1.0

func apply_cursor_damage_multiplier(multiplier: float) -> void:
	cursor_damage_multiplier *= maxf(multiplier, 0.0)

func effective_damage(base_damage: float) -> float:
	return maxf(base_damage, 0.0) * cursor_damage_multiplier
