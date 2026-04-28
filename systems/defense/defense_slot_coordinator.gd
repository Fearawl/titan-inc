extends Node
class_name DefenseSlotCoordinator

var _slots: Array[DefenseSlotResource] = []
var _slots_by_id: Dictionary = {}
# Occupancy is runtime-only and rebuilt from slot resources whenever the scene loads.
var _occupancy_by_id: Dictionary = {}

func configure(slots: Array[DefenseSlotResource]) -> void:
	_slots = slots.duplicate()
	_slots_by_id.clear()
	_occupancy_by_id.clear()
	for slot in _slots:
		if slot == null:
			continue
		_slots_by_id[slot.id] = slot
		_occupancy_by_id[slot.id] = 0

func claim_slot(defender_type: DefenderTypeResource) -> Dictionary:
	for slot in _slots:
		if slot == null or not _can_claim(slot, defender_type):
			continue
		_occupancy_by_id[slot.id] = int(_occupancy_by_id.get(slot.id, 0)) + 1
		return _slot_payload(slot)
	return {}

func release_slot(slot_id: StringName) -> void:
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
