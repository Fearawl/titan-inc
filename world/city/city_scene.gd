extends Node2D

@export var destructible_scene: PackedScene

@onready var catalog: ContentCatalog = $ContentCatalog
@onready var registry: BattleRegistry = $BattleRegistry
@onready var structures_root: Node2D = $Structures

func _ready() -> void:
	SignalBus.save_loaded.connect(_on_save_loaded)
	SaveService.load_game()
	if catalog.titan_types.is_empty():
		catalog.load_all()
	_spawn_structures()

func _spawn_structures() -> void:
	if destructible_scene == null:
		return
	for zone_id in [&"suburb", &"towers", &"wall"]:
		var zone := catalog.get_zone(zone_id)
		if zone == null:
			continue
		for structure_type in zone.structures:
			_spawn_structure(structure_type)

func _spawn_structure(structure_type: StructureTypeResource) -> void:
	if structure_type == null:
		return
	var structure := destructible_scene.instantiate() as DestructibleStructure
	if structure == null:
		return
	structures_root.add_child(structure)
	structure.configure_structure(structure_type)
	registry.register_structure(structure)

func _on_save_loaded() -> void:
	for child in structures_root.get_children():
		var structure := child as DestructibleStructure
		if structure == null or structure.structure_type == null:
			continue
		if GameState.structure_hp.has(structure.structure_type.id):
			structure.restore_saved_hp(float(GameState.structure_hp[structure.structure_type.id]))
		registry.register_structure(structure)
