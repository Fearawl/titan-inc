extends Node2D
class_name ResourceFlyout

const LIFETIME := 0.8

@onready var label: Label = $Label
@onready var icon: ColorRect = $Icon

var _resource_id: StringName
var _amount := 0.0
var _start_position := Vector2.ZERO
var _target_position := Vector2.ZERO
var _elapsed := 0.0

func configure(resource_id: StringName, amount: float, target_world_position: Vector2) -> void:
	_resource_id = resource_id
	_amount = amount
	_start_position = global_position
	_target_position = target_world_position
	_elapsed = 0.0
	var color := _resource_color(resource_id)
	if label == null:
		label = get_node_or_null("Label") as Label
	if icon == null:
		icon = get_node_or_null("Icon") as ColorRect
	if label != null:
		label.text = "+%s %s" % [_format_amount(amount), String(resource_id)]
		label.modulate = color
	if icon != null:
		icon.color = color

func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 2.0)
	global_position = _start_position.lerp(_target_position, eased)
	global_position.y -= sin(t * PI) * 24.0
	modulate.a = 1.0 - t
	if t >= 1.0:
		queue_free()

func _resource_color(resource_id: StringName) -> Color:
	match resource_id:
		&"meat":
			return Color(0.9, 0.24, 0.22, 1.0)
		&"stone":
			return Color(0.64, 0.68, 0.72, 1.0)
		&"metal":
			return Color(0.62, 0.82, 0.95, 1.0)
		&"hero_heart":
			return Color(1.0, 0.2, 0.62, 1.0)
		_:
			return Color(1.0, 0.92, 0.36, 1.0)

func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(roundi(amount))
	return "%.1f" % amount
