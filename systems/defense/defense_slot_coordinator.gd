extends Node
class_name DefenseSlotCoordinator

var _slots: Array[DefenseSlotResource] = []
var _slots_by_id: Dictionary = {}
var _slots_by_anchor_id: Dictionary = {}
# Occupancy is runtime-only and rebuilt from slot resources whenever the scene loads.
var _occupancy_by_id: Dictionary = {}
var _defender_slot_by_instance_id: Dictionary = {}
var _defender_by_instance_id: Dictionary = {}

# MVP tower collapse damage until structure collapse profiles are wired into unit damage.
@export var tower_fall_damage := 25.0

func configure(slots: Array[DefenseSlotResource]) -> void:
	_slots = slots.duplicate()
	_slots_by_id.clear()
	_slots_by_anchor_id.clear()
	_occupancy_by_id.clear()
	_defender_slot_by_instance_id.clear()
	_defender_by_instance_id.clear()
	for slot in _slots:
		if slot == null:
			continue
		_slots_by_id[slot.id] = slot
		_occupancy_by_id[slot.id] = 0
		if slot.anchor_structure_id != &"":
			if not _slots_by_anchor_id.has(slot.anchor_structure_id):
				_slots_by_anchor_id[slot.anchor_structure_id] = []
			_slots_by_anchor_id[slot.anchor_structure_id].append(slot.id)

func claim_slot(defender_type: DefenderTypeResource, defender: DefenderUnit = null) -> Dictionary:
	for slot in _slots:
		if slot == null or not _can_claim(slot, defender_type):
			continue
		_occupancy_by_id[slot.id] = int(_occupancy_by_id.get(slot.id, 0)) + 1
		_track_defender(defender, slot.id)
		return _slot_payload(slot)
	return {}

func release_slot(slot_id: StringName) -> void:
	_decrement_slot(slot_id)

func release_defender(defender: DefenderUnit) -> void:
	if defender == null:
		return
	var instance_id := defender.get_instance_id()
	if not _defender_slot_by_instance_id.has(instance_id):
		return
	_release_instance_id(instance_id)

func handle_structure_destroyed(structure: DestructibleStructure) -> void:
	if structure == null or structure.structure_type == null:
		return
	release_defenders_for_structure(structure.structure_type.id)

func release_defenders_for_structure(anchor_structure_id: StringName) -> void:
	var slot_ids: Array = _slots_by_anchor_id.get(anchor_structure_id, [])
	if slot_ids.is_empty():
		return
	var defender_instance_ids := _defender_slot_by_instance_id.keys()
	for instance_id in defender_instance_ids:
		var slot_id: StringName = _defender_slot_by_instance_id.get(instance_id, &"")
		if not slot_ids.has(slot_id):
			continue
		var defender := _defender_by_instance_id.get(instance_id) as DefenderUnit
		if is_instance_valid(defender):
			if defender.damageable != null and not defender.damageable.dead:
				defender.damageable.apply_damage(tower_fall_damage, &"tower_fall")
			if defender.behavior_controller != null:
				defender.behavior_controller.clear_slot_assignment()
		_release_instance_id(instance_id)

func _decrement_slot(slot_id: StringName) -> void:
	if not _occupancy_by_id.has(slot_id):
		return
	_occupancy_by_id[slot_id] = maxi(int(_occupancy_by_id[slot_id]) - 1, 0)

func slot_position(slot_id: StringName) -> Vector2:
	var slot := _slots_by_id.get(slot_id) as DefenseSlotResource
	return slot.position if slot != null else Vector2.ZERO

func slot_range_multiplier(slot_id: StringName) -> float:
	var slot := _slots_by_id.get(slot_id) as DefenseSlotResource
	return slot.range_multiplier if slot != null else 1.0

func slot_leash_radius(slot_id: StringName) -> float:
	var slot := _slots_by_id.get(slot_id) as DefenseSlotResource
	return slot.leash_radius if slot != null else 0.0

func _can_claim(slot: DefenseSlotResource, defender_type: DefenderTypeResource) -> bool:
	if int(_occupancy_by_id.get(slot.id, 0)) >= slot.capacity:
		return false
	if slot.allowed_defender_tags.is_empty():
		return true
	if defender_type == null:
		return false
	for tag in defender_type.preferred_position_types:
		if slot.allowed_defender_tags.has(tag):
			return true
	return false

func _slot_payload(slot: DefenseSlotResource) -> Dictionary:
	return {
		"id": slot.id,
		"position": slot.position,
		"range_multiplier": slot.range_multiplier,
		"leash_radius": slot.leash_radius,
	}

func _track_defender(defender: DefenderUnit, slot_id: StringName) -> void:
	if defender == null:
		return
	release_defender(defender)
	var instance_id := defender.get_instance_id()
	_defender_slot_by_instance_id[instance_id] = slot_id
	_defender_by_instance_id[instance_id] = defender

func _release_instance_id(instance_id: int) -> void:
	var slot_id: StringName = _defender_slot_by_instance_id.get(instance_id, &"")
	_defender_slot_by_instance_id.erase(instance_id)
	_defender_by_instance_id.erase(instance_id)
	_decrement_slot(slot_id)
