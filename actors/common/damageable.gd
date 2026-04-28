extends Node
class_name Damageable

signal hp_changed(current_hp: float, max_hp: float)
signal damage_taken(amount: float, source_id: StringName, is_critical: bool)
signal died(source_id: StringName)

@export var max_hp := 10.0
@export var current_hp := 10.0
@export var dead := false

func configure(value: float) -> void:
	max_hp = maxf(value, 1.0)
	current_hp = max_hp
	dead = false
	hp_changed.emit(current_hp, max_hp)

func apply_damage(amount: float, source_id: StringName = &"", is_critical: bool = false) -> void:
	if dead or amount <= 0.0:
		return
	var previous_hp := current_hp
	current_hp = maxf(current_hp - amount, 0.0)
	hp_changed.emit(current_hp, max_hp)
	var applied_damage := previous_hp - current_hp
	if applied_damage > 0.0:
		damage_taken.emit(applied_damage, source_id, is_critical)
	if current_hp <= 0.0:
		dead = true
		died.emit(source_id)

func repair(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	current_hp = minf(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)

func set_current_hp(value: float, emit_death := false) -> void:
	var was_dead := dead
	current_hp = clampf(value, 0.0, max_hp)
	dead = current_hp <= 0.0
	hp_changed.emit(current_hp, max_hp)
	if dead and not was_dead and emit_death:
		died.emit(&"save_state")
