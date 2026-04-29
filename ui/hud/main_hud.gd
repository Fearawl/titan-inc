extends CanvasLayer
class_name MainHud

@export var catalog_path: NodePath
@export var registry_path: NodePath

@onready var titan_shop_panel: TitanShopPanel = $Root/TitanShopPanel
@onready var stat_upgrade_panel: StatUpgradePanel = $Root/StatUpgradePanel

func _ready() -> void:
	var catalog := get_node_or_null(catalog_path) as ContentCatalog
	var registry := get_node_or_null(registry_path) as BattleRegistry
	titan_shop_panel.configure(catalog)
	stat_upgrade_panel.configure(catalog, registry)

