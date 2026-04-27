extends Node
class_name ContentCatalog

const TitanTypeResourceScript := preload("res://content/titans/titan_type_resource.gd")
const DefenderTypeResourceScript := preload("res://content/defenders/defender_type_resource.gd")
const StructureTypeResourceScript := preload("res://content/structures/structure_type_resource.gd")
const ZoneResourceScript := preload("res://content/zones/zone_resource.gd")

var titan_types: Dictionary = {}
var defender_types: Dictionary = {}
var structure_types: Dictionary = {}
var zones: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	titan_types = _load_resources("res://content/titans", TitanTypeResourceScript)
	defender_types = _load_resources("res://content/defenders", DefenderTypeResourceScript)
	structure_types = _load_resources("res://content/structures", StructureTypeResourceScript)
	zones = _load_resources("res://content/zones", ZoneResourceScript)

func get_titan(id: StringName) -> TitanTypeResource:
	return titan_types.get(id) as TitanTypeResource

func get_defender(id: StringName) -> DefenderTypeResource:
	return defender_types.get(id) as DefenderTypeResource

func get_zone(id: StringName) -> ZoneResource:
	return zones.get(id) as ZoneResource

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
