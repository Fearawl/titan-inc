extends Node
class_name DebugHotkeys

@export var catalog_path: NodePath
@export var registry_path: NodePath

const TITAN_LIMIT_KEYS := {
	KEY_1: &"small_titan",
	KEY_2: &"runner_titan",
	KEY_3: &"basic_titan",
	KEY_4: &"armored_titan",
	KEY_5: &"colossal_titan",
}

const STAT_UPGRADE_KEYS := {
	KEY_6: &"titan_damage_global",
	KEY_7: &"titan_attack_rate_global",
	KEY_8: &"titan_move_speed_global",
	KEY_9: &"titan_attack_radius_global",
}

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_accept"):
		HudPurchaseHelpers.grant_debug_resources()
	elif event is InputEventKey and event.keycode == KEY_F5:
		SaveService.save_game()
	elif event is InputEventKey and event.keycode == KEY_F9:
		SaveService.load_game()
		UpgradeService.apply_titan_run_upgrades_to_alive(_registry(), _catalog())
	elif event is InputEventKey and TITAN_LIMIT_KEYS.has(event.keycode):
		HudPurchaseHelpers.buy_army_limit(TITAN_LIMIT_KEYS[event.keycode], _catalog())
	elif event is InputEventKey and STAT_UPGRADE_KEYS.has(event.keycode):
		HudPurchaseHelpers.buy_stat_upgrade(STAT_UPGRADE_KEYS[event.keycode], _catalog(), _registry())

func _catalog() -> ContentCatalog:
	return get_node_or_null(catalog_path) as ContentCatalog

func _registry() -> BattleRegistry:
	return get_node_or_null(registry_path) as BattleRegistry

