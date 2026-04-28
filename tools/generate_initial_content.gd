@tool
extends SceneTree

const TitanTypeResourceScript := preload("res://content/titans/titan_type_resource.gd")
const DefenderTypeResourceScript := preload("res://content/defenders/defender_type_resource.gd")
const StructureTypeResourceScript := preload("res://content/structures/structure_type_resource.gd")
const ZoneResourceScript := preload("res://content/zones/zone_resource.gd")
const DefenseSlotResourceScript := preload("res://world/defense_positions/defense_slot_resource.gd")
const UnitBehaviorProfileResource := preload("res://content/behaviors/unit_behavior_profile_resource.gd")
const ProjectileProfileResource := preload("res://content/projectiles/projectile_profile_resource.gd")

const PROJECTILE_ARROW := 0
const PROJECTILE_BOULDER := 1
const BEHAVIOR_FIGHTER_PUSH := 0
const BEHAVIOR_UNSTOPPABLE_PUSH := 1
const BEHAVIOR_SIEGE_COLOSSAL := 2
const BEHAVIOR_MELEE_DEFENDER := 3
const BEHAVIOR_RANGED_ARCHER := 4

var _failure_count := 0

func _init() -> void:
	if not _prepare_output_directories():
		_finish()
		return
	_save_projectiles()
	_save_behaviors()
	_save_titans()
	_save_defenders()
	_save_structures()
	_save_defense_slots()
	_save_zones()
	_finish()

func _prepare_output_directories() -> bool:
	for path in [
		"res://content/titans",
		"res://content/defenders",
		"res://content/behaviors",
		"res://content/projectiles",
		"res://content/structures",
		"res://content/defense_slots",
		"res://content/zones",
	]:
		var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
		if err != OK:
			_record_failure("Cannot create directory %s: %s" % [path, err])
			continue
		_clean_tres_files(path)
	return _failure_count == 0

func _clean_tres_files(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		_record_failure("Cannot open directory %s for cleanup" % path)
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var err := dir.remove(file_name)
		if err != OK:
			_record_failure("Cannot remove stale resource %s: %s" % [path.path_join(file_name), err])

func _stats(hp: float, damage: float, rate: float, speed: float, radius: float, range_value := 0.0) -> UnitStatsResource:
	var stats := UnitStatsResource.new()
	stats.max_hp = hp
	stats.damage = damage
	stats.attack_rate = rate
	stats.move_speed = speed
	stats.attack_radius = radius
	stats.attack_range = range_value
	return stats

func _cost(amounts: Dictionary) -> CostResource:
	var cost := CostResource.new()
	cost.amounts = amounts
	return cost

func _formula() -> ProgressionFormulaResource:
	var formula := ProgressionFormulaResource.new()
	formula.mode = ProgressionFormulaResource.FormulaMode.MULTIPLY_PREVIOUS
	formula.factor = 2.0
	return formula

func _damage(structure_multiplier := 1.0, unit_multiplier := 1.0, crit_chance := 0.05) -> DamageProfileResource:
	var profile := DamageProfileResource.new()
	profile.structure_multiplier = structure_multiplier
	profile.unit_multiplier = unit_multiplier
	profile.critical_chance = crit_chance
	return profile

func _drops(amounts: Dictionary) -> DropTableResource:
	var drops := DropTableResource.new()
	drops.guaranteed = amounts
	return drops

func _string_names(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		result.append(StringName(str(value)))
	return result

func _zone_structures(paths: Array[String]) -> Array[StructureTypeResource]:
	var result: Array[StructureTypeResource] = []
	for path in paths:
		var structure := load(path) as StructureTypeResource
		if structure == null:
			_record_failure("Cannot load structure resource %s" % path)
			continue
		result.append(structure)
	return result

func _behavior_profile(id: StringName) -> Resource:
	var path := "res://content/behaviors/%s.tres" % String(id)
	var profile := load(path)
	if profile == null:
		_record_failure("Cannot load behavior profile resource %s" % path)
	return profile

func _projectile_profile(id: StringName) -> Resource:
	var path := "res://content/projectiles/%s.tres" % String(id)
	var profile := load(path)
	if profile == null:
		_record_failure("Cannot load projectile profile resource %s" % path)
	return profile

func _save(path: String, resource: Resource) -> void:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		_record_failure("Cannot save resource %s: %s" % [path, err])

func _record_failure(message: String) -> void:
	_failure_count += 1
	push_error(message)

func _finish() -> void:
	if _failure_count == 0:
		print("Initial Titan Inc content generated.")
		quit(0)
	else:
		push_error("Initial Titan Inc content generation failed with %d error(s)." % _failure_count)
		quit(1)

func _save_projectiles() -> void:
	var data := [
		[&"arrow_projectile", PROJECTILE_ARROW, 280.0, 70.0, 1.0, 12.0, 0.0, 3.0],
		[&"boulder_projectile", PROJECTILE_BOULDER, 180.0, 150.0, 1.0, 48.0, 220.0, 6.0],
	]
	for row in data:
		var projectile: Resource = ProjectileProfileResource.new()
		projectile.id = row[0]
		projectile.projectile_kind = row[1]
		projectile.speed = row[2]
		projectile.arc_height = row[3]
		projectile.damage_multiplier = row[4]
		projectile.impact_radius = row[5]
		projectile.roll_distance = row[6]
		projectile.lifetime = row[7]
		_save("res://content/projectiles/%s.tres" % String(projectile.id), projectile)

func _save_behaviors() -> void:
	var data := [
		[&"fighter_push", BEHAVIOR_FIGHTER_PUSH, true, false, 0.8, 10.0, 5.0, 120.0, 180.0, 2.0, &""],
		[&"unstoppable_push", BEHAVIOR_UNSTOPPABLE_PUSH, false, true, 0.7, 10.0, 5.0, 80.0, 120.0, 2.0, &""],
		[&"siege_colossal", BEHAVIOR_SIEGE_COLOSSAL, false, false, 1.0, 10.0, 5.0, 220.0, 180.0, 2.0, &"boulder_projectile"],
		[&"melee_defender", BEHAVIOR_MELEE_DEFENDER, false, false, 0.8, 10.0, 5.0, 170.0, 240.0, 2.0, &""],
		[&"ranged_archer", BEHAVIOR_RANGED_ARCHER, false, false, 0.8, 10.0, 5.0, 240.0, 180.0, 2.0, &"arrow_projectile"],
	]
	for row in data:
		var behavior: Resource = UnitBehaviorProfileResource.new()
		behavior.id = row[0]
		behavior.behavior_kind = row[1]
		behavior.melee_stop_on_attacker = row[2]
		behavior.ignores_incoming_melee = row[3]
		behavior.moving_aoe_interval = row[4]
		behavior.boulder_cooldown = row[5]
		behavior.siege_melee_cooldown = row[6]
		behavior.vision_range = row[7]
		behavior.leash_radius = row[8]
		behavior.tower_range_multiplier = row[9]
		if row[10] != &"":
			behavior.projectile_profile = _projectile_profile(row[10])
		_save("res://content/behaviors/%s.tres" % String(behavior.id), behavior)

func _save_titans() -> void:
	var data := [
		[&"small_titan", "Small Titan", 35.0, 3.0, 0.8, 42.0, 22.0, {"meat": 10.0}, [&"small"], &"fighter_push"],
		[&"runner_titan", "Runner Titan", 30.0, 5.0, 1.0, 75.0, 22.0, {"meat": 100.0}, [&"runner"], &"unstoppable_push"],
		[&"basic_titan", "Basic Titan", 70.0, 8.0, 0.9, 48.0, 26.0, {"meat": 250.0, "stone": 10.0}, [&"basic"], &"fighter_push"],
		[&"armored_titan", "Armored Titan", 180.0, 9.0, 0.7, 30.0, 28.0, {"meat": 1000.0, "metal": 10.0}, [&"armored"], &"unstoppable_push"],
		[&"colossal_titan", "Colossal Titan", 500.0, 45.0, 0.35, 18.0, 64.0, {"meat": 10000.0, "stone": 1000.0, "metal": 1000.0}, [&"colossal", &"siege"], &"siege_colossal"],
	]
	for row in data:
		var titan: Resource = TitanTypeResourceScript.new()
		titan.id = row[0]
		titan.display_name = row[1]
		titan.base_stats = _stats(row[2], row[3], row[4], row[5], row[6], 120.0 if titan.id == &"colossal_titan" else 0.0)
		titan.spawn_cooldown = 5.0
		titan.max_army_limit = 100
		titan.base_cost = _cost(row[7])
		titan.cost_formula = _formula()
		titan.damage_profile = _damage(1.25 if titan.id == &"colossal_titan" else 1.0, 1.0)
		titan.tags = _string_names(row[8])
		titan.behavior_profile = _behavior_profile(row[9])
		_save("res://content/titans/%s.tres" % String(titan.id), titan)

func _save_defenders() -> void:
	var data := [
		[&"peasant", "Peasant", 12.0, 1.0, 0.7, 38.0, [&"ground"], false, {"meat": 1.0}, false, &"melee_defender"],
		[&"archer", "Archer", 18.0, 2.5, 0.65, 35.0, [&"tower_top", &"wall_top"], true, {"meat": 2.0}, false, &"ranged_archer"],
		[&"warrior", "Warrior", 32.0, 4.0, 0.75, 35.0, [&"ground", &"gate_line"], false, {"meat": 4.0}, false, &"melee_defender"],
		[&"knight", "Knight", 75.0, 8.0, 0.55, 28.0, [&"gate_line", &"ground"], false, {"meat": 8.0, "metal": 2.0}, false, &"melee_defender"],
		[&"crossbowman", "Crossbowman", 26.0, 6.0, 0.45, 32.0, [&"wall_top", &"tower_top"], true, {"meat": 4.0, "metal": 1.0}, false, &"ranged_archer"],
		[&"rider", "Rider", 55.0, 7.0, 0.7, 62.0, [&"ground"], false, {"meat": 7.0, "metal": 1.0}, false, &"melee_defender"],
		[&"first_hero", "First Hero", 900.0, 24.0, 0.65, 32.0, [&"gate_line"], false, {"hero_heart": 1.0}, true, &"melee_defender"],
	]
	for row in data:
		var defender: Resource = DefenderTypeResourceScript.new()
		defender.id = row[0]
		defender.display_name = row[1]
		defender.base_stats = _stats(row[2], row[3], row[4], row[5], 20.0, 80.0 if row[7] else 0.0)
		defender.spawn_weight = 1.0
		defender.preferred_position_types = _string_names(row[6])
		defender.can_climb_tower = row[7]
		defender.formation_spacing = 18.0
		defender.damage_profile = _damage(0.8, 1.0)
		defender.drop_table = _drops(row[8])
		defender.is_hero = row[9]
		defender.behavior_profile = _behavior_profile(row[10])
		_save("res://content/defenders/%s.tres" % String(defender.id), defender)

func _save_structures() -> void:
	var data := [
		[&"suburb_house", "Suburb House", 120.0, true, true, 1, {"stone": 5.0}, 0, Vector2(450, 390), Vector2(60, 52)],
		[&"wooden_fence", "Wooden Fence", 45.0, true, true, 0, {"stone": 1.0}, 0, Vector2(650, 420), Vector2(90, 24)],
		[&"outer_tower_left", "Outer Tower Left", 550.0, true, true, 3, {"stone": 40.0, "metal": 5.0}, 4, Vector2(1200, 310), Vector2(72, 130)],
		[&"outer_tower_right", "Outer Tower Right", 550.0, true, true, 3, {"stone": 40.0, "metal": 5.0}, 4, Vector2(1200, 500), Vector2(72, 130)],
		[&"wall_gate", "Wall Gate", 1400.0, true, true, 5, {"stone": 140.0, "metal": 25.0}, 2, Vector2(1850, 405), Vector2(90, 150)],
		[&"wall_tower_left", "Wall Tower Left", 900.0, true, true, 6, {"stone": 90.0, "metal": 15.0}, 5, Vector2(1740, 300), Vector2(82, 150)],
		[&"wall_tower_right", "Wall Tower Right", 900.0, true, true, 6, {"stone": 90.0, "metal": 15.0}, 5, Vector2(1740, 510), Vector2(82, 150)],
	]
	for row in data:
		var structure: Resource = StructureTypeResourceScript.new()
		structure.id = row[0]
		structure.display_name = row[1]
		structure.max_hp = row[2]
		structure.blocks_movement = row[3]
		structure.repairable = row[4]
		structure.objective_priority = row[5]
		structure.drop_table = _drops(row[6])
		structure.collapse_damage = _damage(1.0, 1.0)
		structure.garrison_slots = row[7]
		structure.position = row[8]
		structure.size = row[9]
		_save("res://content/structures/%s.tres" % String(structure.id), structure)

func _save_defense_slots() -> void:
	var data := [
		[&"suburb_house_ambush_a", DefenseSlotResourceScript.SlotType.AMBUSH, 3, Vector2(430, 420), 1.0, 160.0, [&"ground"], &"suburb_house"],
		[&"wooden_fence_melee", DefenseSlotResourceScript.SlotType.MELEE_FRONT, 10, Vector2(610, 420), 1.0, 220.0, [&"ground", &"gate_line"], &"wooden_fence"],
		[&"outer_tower_left_garrison", DefenseSlotResourceScript.SlotType.TOWER_GARRISON, 10, Vector2(1200, 245), 2.0, 180.0, [&"tower_top", &"wall_top"], &"outer_tower_left"],
		[&"outer_tower_right_garrison", DefenseSlotResourceScript.SlotType.TOWER_GARRISON, 10, Vector2(1200, 430), 2.0, 180.0, [&"tower_top", &"wall_top"], &"outer_tower_right"],
		[&"outer_tower_melee", DefenseSlotResourceScript.SlotType.MELEE_FRONT, 10, Vector2(1135, 420), 1.0, 230.0, [&"ground", &"gate_line"], &"outer_tower_left"],
		[&"wall_gate_melee", DefenseSlotResourceScript.SlotType.MELEE_FRONT, 10, Vector2(1780, 420), 1.0, 260.0, [&"ground", &"gate_line"], &"wall_gate"],
		[&"wall_tower_left_garrison", DefenseSlotResourceScript.SlotType.TOWER_GARRISON, 10, Vector2(1740, 225), 2.0, 200.0, [&"tower_top", &"wall_top"], &"wall_tower_left"],
		[&"wall_tower_right_garrison", DefenseSlotResourceScript.SlotType.TOWER_GARRISON, 10, Vector2(1740, 435), 2.0, 200.0, [&"tower_top", &"wall_top"], &"wall_tower_right"],
	]
	for row in data:
		var slot: Resource = DefenseSlotResourceScript.new()
		slot.id = row[0]
		slot.slot_type = row[1]
		slot.capacity = row[2]
		slot.position = row[3]
		slot.range_multiplier = row[4]
		slot.leash_radius = row[5]
		slot.allowed_defender_tags = _string_names(row[6])
		slot.anchor_structure_id = row[7]
		_save("res://content/defense_slots/%s.tres" % String(slot.id), slot)

func _save_zones() -> void:
	var suburb: Resource = ZoneResourceScript.new()
	suburb.id = &"suburb"
	suburb.display_name = "Suburb"
	suburb.start_x = 0.0
	suburb.end_x = 900.0
	suburb.structures = _zone_structures([
		"res://content/structures/suburb_house.tres",
		"res://content/structures/wooden_fence.tres",
	])
	_save("res://content/zones/suburb.tres", suburb)

	var towers: Resource = ZoneResourceScript.new()
	towers.id = &"towers"
	towers.display_name = "Towers"
	towers.start_x = 900.0
	towers.end_x = 1500.0
	towers.structures = _zone_structures([
		"res://content/structures/outer_tower_left.tres",
		"res://content/structures/outer_tower_right.tres",
	])
	_save("res://content/zones/towers.tres", towers)

	var wall: Resource = ZoneResourceScript.new()
	wall.id = &"wall"
	wall.display_name = "Wall"
	wall.start_x = 1500.0
	wall.end_x = 2200.0
	wall.structures = _zone_structures([
		"res://content/structures/wall_tower_left.tres",
		"res://content/structures/wall_gate.tres",
		"res://content/structures/wall_tower_right.tres",
	])
	_save("res://content/zones/wall.tres", wall)
