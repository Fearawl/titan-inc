extends Control
class_name TitanShopPanel

const PORTRAITS := {
	&"small_titan": "res://assets/ui/generated/v2/portraits/titans/small_titan_portrait_v2.png",
	&"runner_titan": "res://assets/ui/generated/v2/portraits/titans/runner_titan_portrait_v2.png",
	&"basic_titan": "res://assets/ui/generated/v2/portraits/titans/basic_titan_portrait_v2.png",
	&"armored_titan": "res://assets/ui/generated/v2/portraits/titans/armored_titan_portrait_v2.png",
	&"colossal_titan": "res://assets/ui/generated/v2/portraits/titans/colossal_titan_portrait_v2.png",
}

const BUTTON_STYLES := {
	"normal": "res://assets/ui/generated/v2/frames/row_button_normal_v2.png",
	"hover": "res://assets/ui/generated/v2/frames/row_button_hover_v2.png",
	"pressed": "res://assets/ui/generated/v2/frames/row_button_pressed_v2.png",
	"disabled": "res://assets/ui/generated/v2/frames/row_button_disabled_v2.png",
}

@onready var list_root: VBoxContainer = $Frame/MarginContainer/VBoxContainer/List

var _catalog: ContentCatalog
var _ready_done := false
var _buttons := {}
var _limit_labels := {}
var _cost_labels := {}

func _ready() -> void:
	_ready_done = true
	if _catalog == null:
		_catalog = _resolve_catalog()
	_build_rows()
	if not SignalBus.game_state_changed.is_connected(_refresh):
		SignalBus.game_state_changed.connect(_refresh)
	_refresh()

func _exit_tree() -> void:
	if SignalBus.game_state_changed.is_connected(_refresh):
		SignalBus.game_state_changed.disconnect(_refresh)

func configure(catalog: ContentCatalog) -> void:
	_catalog = catalog
	if _ready_done:
		_build_rows()
		_refresh()

func _build_rows() -> void:
	for child in list_root.get_children():
		child.queue_free()
	_buttons.clear()
	_limit_labels.clear()
	_cost_labels.clear()

	for titan_id in HudPurchaseHelpers.TITAN_ORDER:
		var titan := _catalog.get_titan(titan_id) if _catalog != null else null
		var button := _create_row_button(titan_id)
		list_root.add_child(button)

		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		button.add_child(row)
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10.0
		row.offset_top = 8.0
		row.offset_right = -10.0
		row.offset_bottom = -8.0

		var portrait := TextureRect.new()
		portrait.texture = load(str(PORTRAITS[titan_id]))
		portrait.custom_minimum_size = Vector2(56.0, 56.0)
		portrait.expand_mode = 1
		portrait.stretch_mode = 5
		row.add_child(portrait)

		var text_column := VBoxContainer.new()
		text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_column.add_theme_constant_override("separation", 0)
		row.add_child(text_column)

		var title := Label.new()
		title.text = titan.display_name if titan != null else String(titan_id).capitalize()
		title.add_theme_color_override("font_color", Color.WHITE)
		title.add_theme_font_size_override("font_size", 15)
		text_column.add_child(title)

		var limit_label := Label.new()
		limit_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.86))
		limit_label.add_theme_font_size_override("font_size", 12)
		text_column.add_child(limit_label)

		var cost_label := Label.new()
		cost_label.add_theme_color_override("font_color", Color(0.96, 0.80, 0.38))
		cost_label.add_theme_font_size_override("font_size", 12)
		text_column.add_child(cost_label)

		_buttons[titan_id] = button
		_limit_labels[titan_id] = limit_label
		_cost_labels[titan_id] = cost_label

func _create_row_button(titan_id: StringName) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(256.0, 76.0)
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.set_meta("titan_id", titan_id)
	for state in BUTTON_STYLES.keys():
		button.add_theme_stylebox_override(state, _make_button_style(str(BUTTON_STYLES[state])))
	button.pressed.connect(_on_buy_pressed.bind(button))
	return button

func _make_button_style(texture_path: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(texture_path)
	style.texture_margin_left = 12.0
	style.texture_margin_top = 12.0
	style.texture_margin_right = 12.0
	style.texture_margin_bottom = 12.0
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style

func _on_buy_pressed(button: Button) -> void:
	var titan_id := StringName(str(button.get_meta("titan_id", "")))
	if HudPurchaseHelpers.buy_army_limit(titan_id, _catalog):
		_refresh()

func _refresh() -> void:
	if _catalog == null:
		return
	for titan_id in HudPurchaseHelpers.TITAN_ORDER:
		var titan := _catalog.get_titan(titan_id)
		if titan == null:
			continue
		var current_limit := GameState.get_army_limit(titan_id)
		var cost := titan.get_purchase_cost(current_limit)
		var button := _buttons.get(titan_id) as Button
		if button != null:
			button.disabled = current_limit >= titan.max_army_limit or not GameState.can_pay(cost)
		var limit_label := _limit_labels.get(titan_id) as Label
		if limit_label != null:
			limit_label.text = "Limit %d/%d" % [current_limit, titan.max_army_limit]
		var cost_label := _cost_labels.get(titan_id) as Label
		if cost_label != null:
			cost_label.text = "Next: %s" % HudPurchaseHelpers.format_cost(cost)

func _resolve_catalog() -> ContentCatalog:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("ContentCatalog") as ContentCatalog
