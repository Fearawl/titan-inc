extends RefCounted
class_name EconomyService

static func can_pay(cost: Dictionary) -> bool:
	return GameState.can_pay(cost)

static func pay(cost: Dictionary) -> bool:
	return GameState.pay(cost)

static func grant(drops: Dictionary, world_position := Vector2.ZERO) -> void:
	for resource_id in drops.keys():
		GameState.add_currency(StringName(str(resource_id)), float(drops[resource_id]), world_position)
