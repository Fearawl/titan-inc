extends Camera2D
class_name HorizontalCameraController

@export var pan_speed := 650.0
@export var min_x := 0.0
@export var max_x := 2300.0

var _dragging := false

func _ready() -> void:
	enabled = true
	make_current()
	_clamp_x()

func _process(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction += 1.0
	global_position.x += direction * pan_speed * delta
	_clamp_x()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		global_position.x -= event.relative.x / maxf(zoom.x, 0.001)
		_clamp_x()

func _clamp_x() -> void:
	global_position.x = clampf(global_position.x, min_x, max_x)
