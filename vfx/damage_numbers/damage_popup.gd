extends Node2D
class_name DamagePopup

const NORMAL_LIFETIME := 0.75
const CRITICAL_LIFETIME := 0.62
const NORMAL_RISE_SPEED := 86.0
const CRITICAL_RISE_SPEED := 172.0

@onready var label: Label = $Label

var _lifetime := NORMAL_LIFETIME
var _rise_speed := NORMAL_RISE_SPEED
var _elapsed := 0.0

func configure(amount: float, is_critical: bool) -> void:
	_lifetime = CRITICAL_LIFETIME if is_critical else NORMAL_LIFETIME
	_rise_speed = CRITICAL_RISE_SPEED if is_critical else NORMAL_RISE_SPEED
	scale = Vector2(2.0, 2.0) if is_critical else Vector2.ONE
	if label == null:
		label = get_node_or_null("Label") as Label
	if label != null:
		label.text = _format_amount(amount)
		label.modulate = Color(1.0, 0.82, 0.18, 1.0) if is_critical else Color(1.0, 1.0, 1.0, 1.0)

func _process(delta: float) -> void:
	_elapsed += delta
	position.y -= _rise_speed * delta
	var t := clampf(_elapsed / maxf(_lifetime, 0.01), 0.0, 1.0)
	var fade := 1.0 - t
	modulate.a = fade
	if t >= 1.0:
		queue_free()

func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(roundi(amount))
	return "%.1f" % amount
