extends StaticBody2D
class_name DestructibleStructure

signal destroyed(structure: DestructibleStructure)

var structure_type: StructureTypeResource
var suppress_state_write := false

@onready var damageable: Damageable = $Damageable
@onready var body: ColorRect = $Body
@onready var hp_bar: ProgressBar = $HpBar

func _ready() -> void:
	_ensure_nodes()
	damageable.hp_changed.connect(_on_hp_changed)
	damageable.died.connect(_on_died)
	_on_hp_changed(damageable.current_hp, damageable.max_hp)

func configure_structure(type: StructureTypeResource) -> void:
	structure_type = type
	global_position = type.position
	_ensure_nodes()
	_apply_active_state()
	body.size = type.size
	body.position = -type.size * 0.5
	suppress_state_write = true
	damageable.configure(type.max_hp)
	var game_state: Variant = _game_state()
	if game_state != null and game_state.structure_hp.has(type.id):
		damageable.set_current_hp(float(game_state.structure_hp[type.id]))
	if damageable.current_hp <= 0.0:
		_apply_destroyed_state()
	suppress_state_write = false
	_on_hp_changed(damageable.current_hp, damageable.max_hp)

func apply_damage(amount: float, source_id: StringName = &"") -> void:
	damageable.apply_damage(amount, source_id)

func repair(amount: float) -> void:
	if structure_type != null and structure_type.repairable:
		damageable.repair(amount)

func is_destroyed() -> bool:
	return damageable.dead

func restore_saved_hp(value: float) -> void:
	_ensure_nodes()
	suppress_state_write = true
	damageable.set_current_hp(value, false)
	if damageable.current_hp <= 0.0:
		_apply_destroyed_state()
	else:
		_apply_active_state()
	suppress_state_write = false
	_on_hp_changed(damageable.current_hp, damageable.max_hp)

func _on_hp_changed(current_hp: float, new_max_hp: float) -> void:
	_ensure_nodes()
	if hp_bar != null:
		hp_bar.max_value = new_max_hp
		hp_bar.value = current_hp
	var game_state: Variant = _game_state()
	if not suppress_state_write and structure_type != null and game_state != null:
		game_state.structure_hp[structure_type.id] = current_hp

func _on_died(_source_id: StringName) -> void:
	_apply_destroyed_state()
	var game_state: Variant = _game_state()
	if structure_type != null:
		if game_state != null:
			game_state.structure_hp[structure_type.id] = 0.0
		if structure_type.drop_table != null:
			var economy_service: Variant = load("res://core/economy/economy_service.gd")
			if economy_service != null:
				economy_service.grant(structure_type.drop_table.roll_drops(), global_position)
		var signal_bus: Variant = _signal_bus()
		if signal_bus != null:
			signal_bus.structure_destroyed.emit(structure_type.id, global_position)
	destroyed.emit(self)

func _apply_destroyed_state() -> void:
	visible = false
	collision_layer = 0
	collision_mask = 0

func _apply_active_state() -> void:
	visible = true
	collision_layer = 1
	collision_mask = 1

func _ensure_nodes() -> void:
	if damageable == null:
		damageable = get_node_or_null("Damageable") as Damageable
	if body == null:
		body = get_node_or_null("Body") as ColorRect
	if hp_bar == null:
		hp_bar = get_node_or_null("HpBar") as ProgressBar

func _game_state() -> Variant:
	return get_node_or_null("/root/GameState")

func _signal_bus() -> Variant:
	return get_node_or_null("/root/SignalBus")
