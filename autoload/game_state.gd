extends Node

const SAVE_VERSION := 1
const RESOURCE_IDS: Array[StringName] = [&"meat", &"stone", &"metal", &"hero_heart"]
const STARTING_ARMY_LIMITS := {
	&"small_titan": 1,
	&"runner_titan": 0,
	&"basic_titan": 0,
	&"armored_titan": 0,
	&"colossal_titan": 0,
}

var currencies: Dictionary = {}
var army_limits: Dictionary = {}
var upgrade_levels: Dictionary = {}
var meta_upgrade_levels: Dictionary = {}
var structure_hp: Dictionary = {}
var defeated_heroes: Dictionary = {}
var current_city_id: StringName = &"fantasy_city_01"
var current_zone_id: StringName = &"suburb"
var prestige_available := false
var fullscreen := false

func _ready() -> void:
	reset_all()

func reset_all(emit_changed := true) -> void:
	_reset_currencies(false)
	army_limits = STARTING_ARMY_LIMITS.duplicate(true)
	upgrade_levels = {}
	meta_upgrade_levels = {}
	structure_hp = {}
	defeated_heroes = {}
	current_city_id = &"fantasy_city_01"
	current_zone_id = &"suburb"
	prestige_available = false
	fullscreen = false
	if emit_changed:
		SignalBus.game_state_changed.emit()

func reset_run_for_prestige() -> void:
	_reset_currencies(true)
	army_limits = STARTING_ARMY_LIMITS.duplicate(true)
	upgrade_levels = {}
	structure_hp = {}
	defeated_heroes = {}
	current_city_id = &"fantasy_city_01"
	current_zone_id = &"suburb"
	prestige_available = false
	SignalBus.prestige_completed.emit()
	SignalBus.game_state_changed.emit()

func _reset_currencies(keep_hearts: bool) -> void:
	var saved_hearts := get_currency(&"hero_heart") if keep_hearts else 0.0
	currencies = {}
	for resource_id in RESOURCE_IDS:
		currencies[resource_id] = 0.0
	currencies[&"hero_heart"] = saved_hearts

func get_currency(resource_id: StringName) -> float:
	return float(currencies.get(resource_id, 0.0))

func add_currency(resource_id: StringName, amount: float, world_position := Vector2.ZERO) -> void:
	if amount <= 0.0:
		return
	currencies[resource_id] = get_currency(resource_id) + amount
	SignalBus.resource_gained.emit(resource_id, amount, world_position)
	SignalBus.resource_changed.emit(resource_id, get_currency(resource_id))
	SignalBus.game_state_changed.emit()

func can_pay(cost: Dictionary) -> bool:
	for resource_id in cost.keys():
		if get_currency(resource_id) < float(cost[resource_id]):
			return false
	return true

func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	for resource_id in cost.keys():
		currencies[resource_id] = get_currency(resource_id) - float(cost[resource_id])
		SignalBus.resource_changed.emit(resource_id, get_currency(resource_id))
	SignalBus.game_state_changed.emit()
	return true

func get_army_limit(titan_id: StringName) -> int:
	return int(army_limits.get(titan_id, 0))

func increase_army_limit(titan_id: StringName, amount := 1) -> void:
	army_limits[titan_id] = clampi(get_army_limit(titan_id) + amount, 0, 100)
	SignalBus.game_state_changed.emit()

func mark_hero_defeated(hero_id: StringName) -> void:
	defeated_heroes[hero_id] = true
	prestige_available = true
	SignalBus.hero_defeated.emit(hero_id)
	SignalBus.prestige_unlocked.emit()
	SignalBus.game_state_changed.emit()

func to_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"currencies": _stringify_keys(currencies),
		"army_limits": _stringify_keys(army_limits),
		"upgrade_levels": _stringify_keys(upgrade_levels),
		"meta_upgrade_levels": _stringify_keys(meta_upgrade_levels),
		"structure_hp": _stringify_keys(structure_hp),
		"defeated_heroes": _stringify_keys(defeated_heroes),
		"current_city_id": String(current_city_id),
		"current_zone_id": String(current_zone_id),
		"prestige_available": prestige_available,
		"fullscreen": fullscreen,
	}

func load_save_data(data: Dictionary) -> void:
	var save_version := int(data.get("save_version", 0))
	var migrated_data := _migrate_save_data(data, save_version)
	reset_all(false)
	currencies = _name_keys(migrated_data.get("currencies", currencies))
	army_limits = _name_keys(migrated_data.get("army_limits", army_limits))
	upgrade_levels = _name_keys(migrated_data.get("upgrade_levels", {}))
	meta_upgrade_levels = _name_keys(migrated_data.get("meta_upgrade_levels", {}))
	structure_hp = _name_keys(migrated_data.get("structure_hp", {}))
	defeated_heroes = _name_keys(migrated_data.get("defeated_heroes", {}))
	current_city_id = StringName(migrated_data.get("current_city_id", "fantasy_city_01"))
	current_zone_id = StringName(migrated_data.get("current_zone_id", "suburb"))
	prestige_available = bool(migrated_data.get("prestige_available", false))
	fullscreen = bool(migrated_data.get("fullscreen", false))
	SignalBus.save_loaded.emit()
	SignalBus.game_state_changed.emit()

func _migrate_save_data(data: Dictionary, save_version: int) -> Dictionary:
	if save_version >= SAVE_VERSION:
		return data
	return data

func _stringify_keys(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source.keys():
		result[String(key)] = source[key]
	return result

func _name_keys(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source.keys():
		result[StringName(str(key))] = source[key]
	return result
