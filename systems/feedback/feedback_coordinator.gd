extends Node2D
class_name FeedbackCoordinator

@export var registry_path: NodePath
@export var camera_path: NodePath
@export var damage_popup_scene: PackedScene
@export var resource_flyout_scene: PackedScene

var registry: BattleRegistry
var camera: Camera2D
var _connected_damageables := {}
var _damageable_owner_by_id := {}

func _ready() -> void:
	# Run before default-priority combat systems so newly registered units are
	# wired for damage feedback before the next resolver tick.
	process_priority = -10
	registry = get_node_or_null(registry_path) as BattleRegistry
	camera = get_node_or_null(camera_path) as Camera2D
	var resource_callback := Callable(self, "_on_resource_gained")
	if not SignalBus.resource_gained.is_connected(resource_callback):
		SignalBus.resource_gained.connect(resource_callback)

func _process(_delta: float) -> void:
	if registry == null:
		return
	_prune_damageable_connections()
	_scan_damageables(registry.titans)
	_scan_damageables(registry.defenders)
	_scan_damageables(registry.repair_workers)
	_scan_damageables(registry.structures)

func _prune_damageable_connections() -> void:
	for key in _connected_damageables.keys():
		var owner := _damageable_owner_by_id.get(key) as Node2D
		if _is_active_tracked_owner(owner):
			continue
		_forget_damageable(key)

func _is_active_tracked_owner(owner: Node2D) -> bool:
	if not is_instance_valid(owner):
		return false
	var damageable := owner.get("damageable") as Damageable
	if damageable == null or not is_instance_valid(damageable):
		return false
	# Defeated actors and destroyed structures stay in the scene as hidden nodes
	# for now, so lifecycle cleanup must also watch Damageable state.
	return not damageable.dead

func _scan_damageables(nodes: Array) -> void:
	for node in nodes:
		var owner := node as Node2D
		if not is_instance_valid(owner):
			continue
		var damageable := owner.get("damageable") as Damageable
		if damageable == null or not is_instance_valid(damageable):
			continue
		_connect_damageable(owner, damageable)

func _connect_damageable(owner: Node2D, damageable: Damageable) -> void:
	var key := damageable.get_instance_id()
	if _connected_damageables.has(key):
		return
	# MVP scene-owned hookup: registry arrays are scanned until BattleRegistry grows
	# registration signals. Binding owner keeps the damage signal local and position-aware.
	damageable.damage_taken.connect(Callable(self, "_on_damage_taken").bind(owner))
	_connected_damageables[key] = true
	_damageable_owner_by_id[key] = owner
	if not owner.tree_exited.is_connected(Callable(self, "_on_tracked_owner_exited").bind(key)):
		owner.tree_exited.connect(Callable(self, "_on_tracked_owner_exited").bind(key))

func _on_tracked_owner_exited(key: int) -> void:
	_forget_damageable(key)

func _forget_damageable(key: int) -> void:
	var owner := _damageable_owner_by_id.get(key) as Node2D
	if is_instance_valid(owner):
		var damageable := owner.get("damageable") as Damageable
		var damage_callback := Callable(self, "_on_damage_taken").bind(owner)
		if damageable != null and is_instance_valid(damageable) and damageable.damage_taken.is_connected(damage_callback):
			damageable.damage_taken.disconnect(damage_callback)
		var exit_callback := Callable(self, "_on_tracked_owner_exited").bind(key)
		if owner.tree_exited.is_connected(exit_callback):
			owner.tree_exited.disconnect(exit_callback)
	_connected_damageables.erase(key)
	_damageable_owner_by_id.erase(key)

func _on_damage_taken(amount: float, _source_id: StringName, is_critical: bool, target: Node2D) -> void:
	if damage_popup_scene == null or target == null or not is_instance_valid(target):
		return
	var popup := damage_popup_scene.instantiate() as DamagePopup
	if popup == null:
		return
	add_child(popup)
	popup.global_position = target.global_position + Vector2(0.0, -32.0)
	popup.configure(amount, is_critical)

func _on_resource_gained(resource_id: StringName, amount: float, world_position: Vector2) -> void:
	if resource_flyout_scene == null:
		return
	var flyout := resource_flyout_scene.instantiate() as ResourceFlyout
	if flyout == null:
		return
	add_child(flyout)
	flyout.global_position = world_position
	flyout.configure(resource_id, amount, _resource_target_position(world_position))

func _resource_target_position(fallback_position: Vector2) -> Vector2:
	if camera == null or not is_instance_valid(camera):
		return fallback_position + Vector2(0.0, -90.0)
	var viewport_size := camera.get_viewport_rect().size
	var target_screen := Vector2(maxf(viewport_size.x - 220.0, 0.0), 42.0)
	return camera.get_screen_center_position() + (target_screen - viewport_size * 0.5) / camera.zoom
