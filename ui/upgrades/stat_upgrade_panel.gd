extends Control
class_name StatUpgradePanel

const ICONS := {
	&"titan_damage_global": "res://assets/ui/generated/transparent/icons/upgrades/damage_icon_v1.png",
	&"titan_attack_rate_global": "res://assets/ui/generated/transparent/icons/upgrades/attack_speed_icon_v1.png",
	&"titan_move_speed_global": "res://assets/ui/generated/transparent/icons/upgrades/movement_speed_icon_v1.png",
	&"titan_attack_radius_global": "res://assets/ui/generated/transparent/icons/upgrades/destruction_radius_icon_v1.png",
}

const BUTTON_STYLES := {
	"normal": "res://assets/ui/generated/transparent/buttons/button_normal_v1.png",
	"hover": "res://assets/ui/generated/transparent/buttons/button_hover_v1.png",
	"pressed": "res://assets/ui/generated/transparent/buttons/button_pressed_v1.png",
	"disabled": "res://assets/ui/generated/transparent/buttons/button_disabled_v1.png",
}

@onready var list_root: VBoxContainer = $Frame/MarginContainer/VBoxContainer/List

var _catalog: ContentCatalog
var _registry: BattleRegistry
var _ready_done := false
var _buttons := {}
var _level_labels := {}
var _cost_labels := {}

func _ready() -> void:
	_ready_done = true
	if _catalog == null:
		_catalog = _resolve_catalog()
	if _registry == null:
		_registry = _resolve_registry()
	_build_rows()
	if not SignalBus.game_state_changed.is_connected(_refresh):
		SignalBus.game_state_changed.connect(_refresh)
	_refresh()

func _exit_tree() -> void:
	if SignalBus.game_state_changed.is_connected(_refresh):
		SignalBus.game_state_changed.disconnect(_refresh)

func configure(catalog: ContentCatalog, registry: BattleRegistry) -> void:
	_catalog = catalog
	_registry = registry
	if _ready_done:
		_build_rows()
		_refresh()

func _build_rows() -> void:
	for child in list_root.get_children():
		child.queue_free()
	_buttons.clear()
	_level_labels.clear()
	_cost_labels.clear()

	for upgrade_id in HudPurchaseHelpers.UPGRADE_ORDER:
		var upgrade := _catalog.get_stat_upgrade(upgrade_id) if _catalog != null else null
		var button := _create_row_button(upgrade_id)
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

		var icon := TextureRect.new()
		icon.texture = load(str(ICONS[upgrade_id]))
		icon.custom_minimum_size = Vector2(52.0, 52.0)
		icon.expand_mode = 1
		icon.stretch_mode = 5
		row.add_child(icon)

		var text_column := VBoxContainer.new()
		text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_column.add_theme_constant_override("separation", 0)
		row.add_child(text_column)

		var title := Label.new()
		title.text = upgrade.display_name if upgrade != null else String(upgrade_id).capitalize()
		title.add_theme_color_override("font_color", Color.WHITE)
		title.add_theme_font_size_override("font_size", 14)
		text_column.add_child(title)

		var level_label := Label.new()
		level_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.86))
		level_label.add_theme_font_size_override("font_size", 12)
		text_column.add_child(level_label)

		var cost_label := Label.new()
		cost_label.add_theme_color_override("font_color", Color(0.96, 0.80, 0.38))
		cost_label.add_theme_font_size_override("font_size", 12)
		text_column.add_child(cost_label)

		_buttons[upgrade_id] = button
		_level_labels[upgrade_id] = level_label
		_cost_labels[upgrade_id] = cost_label

func _create_row_button(upgrade_id: StringName) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(276.0, 76.0)
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.set_meta("upgrade_id", upgrade_id)
	for state in BUTTON_STYLES.keys():
		button.add_theme_stylebox_override(state, _make_button_style(str(BUTTON_STYLES[state])))
	button.pressed.connect(_on_buy_pressed.bind(button))
	return button

func _make_button_style(texture_path: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(texture_path)
	style.texture_margin_left = 28.0
	style.texture_margin_top = 28.0
	style.texture_margin_right = 28.0
	style.texture_margin_bottom = 28.0
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style

func _on_buy_pressed(button: Button) -> void:
	var upgrade_id := StringName(str(button.get_meta("upgrade_id", "")))
	if HudPurchaseHelpers.buy_stat_upgrade(upgrade_id, _catalog, _registry):
		_refresh()

func _refresh() -> void:
	if _catalog == null:
		return
	for upgrade_id in HudPurchaseHelpers.UPGRADE_ORDER:
		var upgrade := _catalog.get_stat_upgrade(upgrade_id)
		if upgrade == null:
			continue
		var level := GameState.get_upgrade_level(upgrade_id)
		var cost := upgrade.get_purchase_cost(level)
		var button := _buttons.get(upgrade_id) as Button
		if button != null:
			button.disabled = level >= upgrade.max_level or not GameState.can_pay(cost)
		var level_label := _level_labels.get(upgrade_id) as Label
		if level_label != null:
			level_label.text = "Level %d/%d" % [level, upgrade.max_level]
		var cost_label := _cost_labels.get(upgrade_id) as Label
		if cost_label != null:
			cost_label.text = "Next: %s" % HudPurchaseHelpers.format_cost(cost)

func _resolve_catalog() -> ContentCatalog:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("ContentCatalog") as ContentCatalog

func _resolve_registry() -> BattleRegistry:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("BattleRegistry") as BattleRegistry

