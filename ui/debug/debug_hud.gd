extends CanvasLayer
class_name DebugHud

@onready var label: Label = $Panel/Label

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

func _ready() -> void:
	SignalBus.game_state_changed.connect(_refresh)
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_accept"):
		GameState.add_currency(&"meat", 100.0)
		GameState.add_currency(&"stone", 100.0)
		GameState.add_currency(&"metal", 25.0)
	elif event is InputEventKey and event.keycode == KEY_F5:
		SaveService.save_game()
	elif event is InputEventKey and event.keycode == KEY_F9:
		SaveService.load_game()
		# Debug reload can change run-upgrade levels after titans have already spawned.
		UpgradeService.apply_titan_run_upgrades_to_alive(_registry(), _catalog())
	elif event is InputEventKey and TITAN_LIMIT_KEYS.has(event.keycode):
		_buy_army_limit(TITAN_LIMIT_KEYS[event.keycode])
	elif event is InputEventKey and STAT_UPGRADE_KEYS.has(event.keycode):
		_buy_stat_upgrade(STAT_UPGRADE_KEYS[event.keycode])

func _buy_army_limit(titan_id: StringName) -> void:
	var current_limit := GameState.get_army_limit(titan_id)
	if current_limit >= 100:
		return
	var catalog := _catalog()
	if catalog == null:
		return
	var titan := catalog.get_titan(titan_id)
	if titan == null:
		return
	var cost := titan.get_purchase_cost(current_limit)
	if not GameState.pay(cost):
		return
	GameState.increase_army_limit(titan_id, 1)
	SaveService.save_game()

func _buy_stat_upgrade(upgrade_id: StringName) -> void:
	var catalog := _catalog()
	if catalog == null:
		return
	var upgrade := catalog.get_stat_upgrade(upgrade_id)
	if upgrade == null:
		return
	if UpgradeService.purchase_run_upgrade(upgrade, _registry(), catalog):
		SaveService.save_game()

func _catalog() -> ContentCatalog:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("ContentCatalog") as ContentCatalog

func _registry() -> BattleRegistry:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("BattleRegistry") as BattleRegistry

func _refresh() -> void:
	if label == null:
		return
	var lines: Array[String] = [
		"Resources: meat %.0f  stone %.0f  metal %.0f  hearts %.0f" % [
			GameState.get_currency(&"meat"),
			GameState.get_currency(&"stone"),
			GameState.get_currency(&"metal"),
			GameState.get_currency(&"hero_heart"),
		],
		"Limits: small %d  runner %d  basic %d  armored %d  colossal %d" % [
			GameState.get_army_limit(&"small_titan"),
			GameState.get_army_limit(&"runner_titan"),
			GameState.get_army_limit(&"basic_titan"),
			GameState.get_army_limit(&"armored_titan"),
			GameState.get_army_limit(&"colossal_titan"),
		],
		"Upgrades: dmg %d  atk %d  spd %d  radius %d" % [
			GameState.get_upgrade_level(&"titan_damage_global"),
			GameState.get_upgrade_level(&"titan_attack_rate_global"),
			GameState.get_upgrade_level(&"titan_move_speed_global"),
			GameState.get_upgrade_level(&"titan_attack_radius_global"),
		],
		"Enter: resources  1-5: limits  6-9: stat upgrades  F5/F9: save/load",
	]
	label.text = "\n".join(lines)
