extends Node2D
class_name CursorBoostController

@export var registry_path: NodePath
@export var catalog_path: NodePath
@export var profile_id: StringName = &"cursor_boost_default"

var profile: CursorBoostProfileResource
var _cursor_world_position := Vector2.ZERO

@onready var registry: BattleRegistry = get_node_or_null(registry_path) as BattleRegistry
@onready var catalog: ContentCatalog = get_node_or_null(catalog_path) as ContentCatalog

func _ready() -> void:
	if catalog != null:
		profile = catalog.get_cursor_boost_profile(profile_id)
		if profile == null:
			catalog.load_all()
			profile = catalog.get_cursor_boost_profile(profile_id)
	queue_redraw()

func _process(_delta: float) -> void:
	_cursor_world_position = get_global_mouse_position()
	if registry == null:
		queue_redraw()
		return
	# Cursor boost owns this transient reset so node process order stays explicit:
	# it must run before combat systems that read effective damage this frame.
	for titan in registry.alive_titans():
		titan.runtime_modifiers.reset_transient()
		if profile == null:
			continue
		var radius := maxf(profile.radius, 0.0)
		if titan.global_position.distance_to(_cursor_world_position) <= radius:
			titan.runtime_modifiers.apply_cursor_damage_multiplier(profile.damage_multiplier)
	queue_redraw()

func _draw() -> void:
	if profile == null or not profile.debug_visible:
		return
	var local_cursor := to_local(_cursor_world_position)
	var radius := maxf(profile.radius, 0.0)
	draw_circle(local_cursor, radius, profile.fill_color)
	draw_arc(local_cursor, radius, 0.0, TAU, 64, profile.outline_color, 2.0)
