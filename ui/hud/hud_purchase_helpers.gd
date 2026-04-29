extends RefCounted
class_name HudPurchaseHelpers

const RESOURCE_ORDER := [&"meat", &"stone", &"metal", &"hero_heart"]
const TITAN_ORDER := [&"small_titan", &"runner_titan", &"basic_titan", &"armored_titan", &"colossal_titan"]
const UPGRADE_ORDER := [
	&"titan_damage_global",
	&"titan_attack_rate_global",
	&"titan_move_speed_global",
	&"titan_attack_radius_global",
]

const RESOURCE_LABELS := {
	&"meat": "Meat",
	&"stone": "Stone",
	&"metal": "Metal",
	&"hero_heart": "Hearts",
}

static func format_amount(value: float) -> String:
	var rounded := int(round(value))
	if rounded >= 1000000:
		return "%.1fM" % [float(rounded) / 1000000.0]
	if rounded >= 1000:
		return "%.1fK" % [float(rounded) / 1000.0]
	return str(rounded)

static func format_cost(cost: Dictionary) -> String:
	if cost.is_empty():
		return "Free"
	var parts: Array[String] = []
	var used := {}
	for resource_id in RESOURCE_ORDER:
		if cost.has(resource_id):
			parts.append("%s %s" % [format_amount(float(cost[resource_id])), _resource_label(resource_id)])
			used[resource_id] = true
	for key in cost.keys():
		var resource_id := StringName(str(key))
		if used.has(resource_id):
			continue
		parts.append("%s %s" % [format_amount(float(cost[key])), _resource_label(resource_id)])
	return " / ".join(parts)

static func buy_army_limit(titan_id: StringName, catalog: ContentCatalog) -> bool:
	if catalog == null:
		return false
	var titan := catalog.get_titan(titan_id)
	if titan == null:
		return false
	var current_limit := GameState.get_army_limit(titan_id)
	if current_limit >= titan.max_army_limit:
		return false
	var cost := titan.get_purchase_cost(current_limit)
	if not GameState.pay(cost):
		return false
	GameState.increase_army_limit(titan_id, 1)
	SaveService.save_game()
	return true

static func buy_stat_upgrade(upgrade_id: StringName, catalog: ContentCatalog, registry: BattleRegistry) -> bool:
	if catalog == null:
		return false
	var upgrade := catalog.get_stat_upgrade(upgrade_id)
	if upgrade == null:
		return false
	if not UpgradeService.purchase_run_upgrade(upgrade, registry, catalog):
		return false
	SaveService.save_game()
	return true

static func grant_debug_resources() -> void:
	GameState.add_currency(&"meat", 100.0)
	GameState.add_currency(&"stone", 100.0)
	GameState.add_currency(&"metal", 25.0)

static func _resource_label(resource_id: StringName) -> String:
	return str(RESOURCE_LABELS.get(resource_id, String(resource_id).capitalize()))

