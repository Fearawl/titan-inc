extends Node

signal resource_changed(resource_id: StringName, new_amount: float)
signal resource_gained(resource_id: StringName, amount: float, world_position: Vector2)
signal structure_destroyed(structure_id: StringName, world_position: Vector2)
signal unit_defeated(unit_id: StringName, team: StringName, world_position: Vector2)
signal hero_defeated(hero_id: StringName)
signal zone_completed(zone_id: StringName)
signal prestige_unlocked()
signal prestige_completed()
signal save_loaded()
signal game_state_changed()
