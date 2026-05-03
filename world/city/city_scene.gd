extends Node2D

@export var destructible_scene: PackedScene
@export var layout_path: NodePath

@onready var catalog: ContentCatalog = $ContentCatalog
@onready var registry: BattleRegistry = $BattleRegistry
@onready var structures_root: Node2D = $Structures
@onready var defense_slot_coordinator: DefenseSlotCoordinator = $DefenseSlotCoordinator
@onready var titan_spawn_coordinator: TitanSpawnCoordinator = $TitanSpawnCoordinator
@onready var defender_spawn_coordinator: DefenderSpawnCoordinator = $DefenderSpawnCoordinator
@onready var repair_coordinator: RepairCoordinator = $RepairCoordinator
@onready var battle_lane: BattleLane = $BattleLane
@onready var road_lane: RoadLane = $RoadLane
@onready var layout: CityLayout = get_node_or_null(layout_path) as CityLayout

func _ready() -> void:
	SignalBus.save_loaded.connect(_on_save_loaded)
	SaveService.load_game()
	if catalog.titan_types.is_empty():
		catalog.load_all()
	_apply_layout_lanes()
	_apply_layout_spawn_points()
	_configure_defense_slots()
	_spawn_structures()
	if layout != null:
		layout.visible = false

func _configure_defense_slots() -> void:
	if defense_slot_coordinator == null:
		return
	var slots: Array[DefenseSlotResource] = []
	if layout != null:
		for marker in layout.defense_point_markers():
			slots.append(marker.to_slot_resource(layout.structure_runtime_id_for_marker(marker.anchor_structure_marker_id)))
	else:
		for slot in catalog.defense_slots.values():
			var typed := slot as DefenseSlotResource
			if typed != null:
				slots.append(typed)
	defense_slot_coordinator.configure(slots)

func _apply_layout_lanes() -> void:
	if layout == null:
		return
	var authored_battle_lane := layout.battle_lane()
	if authored_battle_lane != null and battle_lane != null:
		battle_lane.lane_rect = authored_battle_lane.lane_rect
		battle_lane.titan_spawn_x = authored_battle_lane.titan_spawn_x
		battle_lane.titan_spawn_x_variance = authored_battle_lane.titan_spawn_x_variance
	var authored_road_lane := layout.road_lane()
	if authored_road_lane != null and road_lane != null:
		road_lane.road_y = authored_road_lane.road_y
		road_lane.min_x = authored_road_lane.min_x
		road_lane.max_x = authored_road_lane.max_x

func _apply_layout_spawn_points() -> void:
	if layout == null:
		return
	for marker in layout.spawn_markers():
		match marker.spawn_kind:
			SpawnPointMarker.SpawnKind.TITAN:
				if titan_spawn_coordinator != null:
					titan_spawn_coordinator.spawn_origin = marker.global_position
				if battle_lane != null:
					battle_lane.titan_spawn_x = marker.global_position.x
			SpawnPointMarker.SpawnKind.DEFENDER:
				if defender_spawn_coordinator != null:
					defender_spawn_coordinator.spawn_origin = marker.global_position
			SpawnPointMarker.SpawnKind.REPAIR:
				if repair_coordinator != null:
					repair_coordinator.spawn_origin = marker.global_position

func _spawn_structures() -> void:
	if destructible_scene == null:
		return
	if layout != null and not layout.structure_markers().is_empty():
		for marker in layout.structure_markers():
			_spawn_structure_from_marker(marker)
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
	_spawn_structure_instance(structure_type, structure_type.position, structure_type.id, structure_type.size)

func _spawn_structure_from_marker(marker: StructureMarker) -> void:
	if marker == null:
		return
	if marker.structure_type == null:
		push_warning("Structure marker '%s' has no StructureTypeResource." % marker.name)
		return
	_spawn_structure_instance(marker.structure_type, marker.global_position, marker.runtime_id(), marker.authored_size())

func _spawn_structure_instance(structure_type: StructureTypeResource, world_position: Vector2, runtime_id: StringName, size: Vector2) -> void:
	var structure := destructible_scene.instantiate() as DestructibleStructure
	if structure == null:
		return
	structures_root.add_child(structure)
	structure.configure_structure(structure_type, world_position, runtime_id, size)
	registry.register_structure(structure)
	_connect_structure_destroyed_to_defense_slots(structure)

func _on_save_loaded() -> void:
	for child in structures_root.get_children():
		var structure := child as DestructibleStructure
		if structure == null or structure.structure_type == null:
			continue
		if GameState.structure_hp.has(structure.runtime_id):
			structure.restore_saved_hp(float(GameState.structure_hp[structure.runtime_id]))
		elif GameState.structure_hp.has(structure.structure_type.id):
			structure.restore_saved_hp(float(GameState.structure_hp[structure.structure_type.id]))
		registry.register_structure(structure)
		_connect_structure_destroyed_to_defense_slots(structure)

func _connect_structure_destroyed_to_defense_slots(structure: DestructibleStructure) -> void:
	if structure == null or defense_slot_coordinator == null:
		return
	var destroyed_handler := Callable(defense_slot_coordinator, "handle_structure_destroyed")
	if not structure.destroyed.is_connected(destroyed_handler):
		structure.destroyed.connect(destroyed_handler)
