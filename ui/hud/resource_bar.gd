extends Control
class_name ResourceBar

const RESOURCE_ICONS := {
	&"meat": "res://assets/ui/generated/transparent/icons/resources/meat_icon_v1.png",
	&"stone": "res://assets/ui/generated/transparent/icons/resources/stone_icon_v1.png",
	&"metal": "res://assets/ui/generated/transparent/icons/resources/metal_icon_v1.png",
	&"hero_heart": "res://assets/ui/generated/transparent/icons/resources/hero_heart_icon_v1.png",
}

@onready var entries_root: HBoxContainer = $Frame/MarginContainer/HBoxContainer

var _value_labels := {}

func _ready() -> void:
	_build_entries()
	if not SignalBus.game_state_changed.is_connected(_refresh):
		SignalBus.game_state_changed.connect(_refresh)
	_refresh()

func _exit_tree() -> void:
	if SignalBus.game_state_changed.is_connected(_refresh):
		SignalBus.game_state_changed.disconnect(_refresh)

func _build_entries() -> void:
	for child in entries_root.get_children():
		child.queue_free()
	_value_labels.clear()
	for resource_id in HudPurchaseHelpers.RESOURCE_ORDER:
		var cell := HBoxContainer.new()
		cell.custom_minimum_size = Vector2(118.0, 42.0)
		cell.add_theme_constant_override("separation", 6)
		entries_root.add_child(cell)

		var icon := TextureRect.new()
		icon.texture = load(str(RESOURCE_ICONS[resource_id]))
		icon.custom_minimum_size = Vector2(34.0, 34.0)
		icon.expand_mode = 1
		icon.stretch_mode = 5
		cell.add_child(icon)

		var value_label := Label.new()
		value_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55))
		value_label.add_theme_font_size_override("font_size", 17)
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.add_child(value_label)
		_value_labels[resource_id] = value_label

func _refresh() -> void:
	for resource_id in HudPurchaseHelpers.RESOURCE_ORDER:
		var label := _value_labels.get(resource_id) as Label
		if label != null:
			label.text = HudPurchaseHelpers.format_amount(GameState.get_currency(resource_id))

