extends Node
class_name ContentCatalog

const TitanTypeResourceScript := preload("res://content/titans/titan_type_resource.gd")
const DefenderTypeResourceScript := preload("res://content/defenders/defender_type_resource.gd")
const StructureTypeResourceScript := preload("res://content/structures/structure_type_resource.gd")
const ZoneResourceScript := preload("res://content/zones/zone_resource.gd")
const DefenseSlotResourceScript := preload("res://world/defense_positions/defense_slot_resource.gd")
const UnitBehaviorProfileResource := preload("res://content/behaviors/unit_behavior_profile_resource.gd")
const ProjectileProfileResource := preload("res://content/projectiles/projectile_profile_resource.gd")
const CursorBoostProfileResourceScript := preload("res://content/player/cursor_boost_profile_resource.gd")
const StatUpgradeResourceScript := preload("res://content/upgrades/stat_upgrade_resource.gd")

var titan_types: Dictionary = {}
var defender_types: Dictionary = {}
var structure_types: Dictionary = {}
var zones: Dictionary = {}
var defense_slots: Dictionary = {}
var behavior_profiles: Dictionary = {}
var projectile_profiles: Dictionary = {}
var cursor_boost_profiles: Dictionary = {}
var stat_upgrades: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	titan_types = _load_resources("res://content/titans", TitanTypeResourceScript)
	defender_types = _load_resources("res://content/defenders", DefenderTypeResourceScript)
	structure_types = _load_resources("res://content/structures", StructureTypeResourceScript)
	zones = _load_resources("res://content/zones", ZoneResourceScript)
	defense_slots = _load_resources("res://content/defense_slots", DefenseSlotResourceScript)
	behavior_profiles = _load_resources("res://content/behaviors", UnitBehaviorProfileResource)
	projectile_profiles = _load_resources("res://content/projectiles", ProjectileProfileResource)
	cursor_boost_profiles = _load_resources("res://content/player", CursorBoostProfileResourceScript)
	stat_upgrades = _load_resources("res://content/upgrades", StatUpgradeResourceScript)

func get_titan(id: StringName) -> TitanTypeResource:
	return titan_types.get(id) as TitanTypeResource

func get_defender(id: StringName) -> DefenderTypeResource:
	return defender_types.get(id) as DefenderTypeResource

func get_zone(id: StringName) -> ZoneResource:
	return zones.get(id) as ZoneResource

func get_defense_slot(id: StringName) -> DefenseSlotResource:
	return defense_slots.get(id) as DefenseSlotResource

func get_behavior_profile(id: StringName) -> UnitBehaviorProfileResource:
	return behavior_profiles.get(id) as UnitBehaviorProfileResource

func get_projectile_profile(id: StringName) -> ProjectileProfileResource:
	return projectile_profiles.get(id) as ProjectileProfileResource

func get_cursor_boost_profile(id: StringName) -> CursorBoostProfileResource:
	return cursor_boost_profiles.get(id) as CursorBoostProfileResource

func get_stat_upgrade(id: StringName) -> StatUpgradeResource:
	return stat_upgrades.get(id) as StatUpgradeResource

func _load_resources(path: String, expected_script: Script) -> Dictionary:
	var result := {}
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var resource := load(path.path_join(file_name))
		if resource == null or resource.get_script() != expected_script:
			continue
		var resource_id = resource.get("id")
		if resource_id != null:
			result[StringName(str(resource_id))] = resource
	return result
