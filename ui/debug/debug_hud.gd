extends CanvasLayer
class_name DebugHud

@onready var label: Label = $Panel/Label

func _ready() -> void:
	SignalBus.game_state_changed.connect(_refresh)
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_accept"):
		GameState.add_currency(&"meat", 100.0)
		GameState.add_currency(&"stone", 100.0)
		GameState.add_currency(&"metal", 25.0)
	elif event is InputEventKey and event.keycode == KEY_F5:
		SaveService.save_game()
	elif event is InputEventKey and event.keycode == KEY_F9:
		SaveService.load_game()

func _refresh() -> void:
	if label == null:
		return
	var lines: Array[String] = [
		"Resources: meat %.0f  stone %.0f  metal %.0f  hearts %.0f" % [
			GameState.get_currency(&"meat"),
			GameState.get_currency(&"stone"),
			GameState.get_currency(&"metal"),
			GameState.get_currency(&"hero_heart"),
		],
		"Limits: small %d  runner %d  basic %d  armored %d  colossal %d" % [
			GameState.get_army_limit(&"small_titan"),
			GameState.get_army_limit(&"runner_titan"),
			GameState.get_army_limit(&"basic_titan"),
			GameState.get_army_limit(&"armored_titan"),
			GameState.get_army_limit(&"colossal_titan"),
		],
	]
	label.text = "\n".join(lines)
