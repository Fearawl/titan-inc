extends Node
class_name ContentCatalog

var titan_types: Dictionary = {}
var defender_types: Dictionary = {}
var structure_types: Dictionary = {}
var zones: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	titan_types = _load_resources("res://content/titans")
	defender_types = _load_resources("res://content/defenders")
	structure_types = _load_resources("res://content/structures")
	zones = _load_resources("res://content/zones")

func get_titan(id: StringName) -> TitanTypeResource:
	return titan_types.get(id) as TitanTypeResource

func get_defender(id: StringName) -> DefenderTypeResource:
	return defender_types.get(id) as DefenderTypeResource

func get_zone(id: StringName) -> ZoneResource:
	return zones.get(id) as ZoneResource

func _load_resources(path: String) -> Dictionary:
	var result := {}
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var resource := load(path.path_join(file_name))
		if resource != null:
			var resource_id = resource.get("id")
			if resource_id != null:
				result[StringName(str(resource_id))] = resource
	return result
