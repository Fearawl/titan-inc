extends RefCounted
class_name UpgradeService

static func get_upgrade_level(upgrade_id: StringName) -> int:
	return GameState.get_upgrade_level(upgrade_id)

static func can_purchase_run_upgrade(upgrade: StatUpgradeResource) -> bool:
	if upgrade == null:
		return false
	var current_level := get_upgrade_level(upgrade.id)
	if current_level >= maxi(upgrade.max_level, 0):
		return false
	return GameState.can_pay(upgrade.get_purchase_cost(current_level))

static func purchase_run_upgrade(upgrade: StatUpgradeResource, registry: BattleRegistry, catalog: ContentCatalog) -> bool:
	if registry == null or catalog == null:
		return false
	if not can_purchase_run_upgrade(upgrade):
		return false
	var current_level := get_upgrade_level(upgrade.id)
	if not GameState.pay(upgrade.get_purchase_cost(current_level)):
		return false
	GameState.increase_upgrade_level(upgrade.id, 1, upgrade.max_level)
	apply_titan_run_upgrades_to_alive(registry, catalog)
	return true

static func apply_titan_run_upgrades(unit: TitanUnit, catalog: ContentCatalog) -> void:
	if unit == null or catalog == null or unit.titan_type == null or unit.titan_type.base_stats == null:
		return
	if unit.damageable != null and unit.damageable.dead:
		return
	var previous_hp_ratio := 1.0
	if unit.damageable != null and unit.damageable.max_hp > 0.0:
		previous_hp_ratio = clampf(unit.damageable.current_hp / unit.damageable.max_hp, 0.0, 1.0)
	unit.stats = unit.titan_type.base_stats.duplicate_stats()
	for upgrade in catalog.stat_upgrades.values():
		var stat_upgrade := upgrade as StatUpgradeResource
		if stat_upgrade == null or not stat_upgrade.applies_to_titan(unit.titan_type):
			continue
		stat_upgrade.apply_to_stats(unit.stats, get_upgrade_level(stat_upgrade.id))
	if unit.damageable != null:
		unit.damageable.max_hp = maxf(unit.stats.max_hp, 1.0)
		unit.damageable.set_current_hp(unit.damageable.max_hp * previous_hp_ratio)

static func apply_titan_run_upgrades_to_alive(registry: BattleRegistry, catalog: ContentCatalog) -> void:
	if registry == null or catalog == null:
		return
	for unit in registry.alive_titans():
		apply_titan_run_upgrades(unit, catalog)
