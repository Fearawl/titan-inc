extends Node2D
class_name CombatActor

signal defeated(actor: CombatActor)

@export var team: StringName = &"neutral"
@export var actor_id: StringName
@export var display_color := Color.WHITE

var stats: UnitStatsResource
var damage_profile: DamageProfileResource
var drop_table: DropTableResource
# Transient modifier reset is owned by systems such as CursorBoostController,
# because actor-local _process order would race combat resolution.
var runtime_modifiers := UnitRuntimeModifiers.new()
var target_x := 0.0
var attack_cooldown := 0.0
var assigned_position := Vector2.ZERO

@onready var damageable: Damageable = $Damageable
@onready var body: ColorRect = $Body
@onready var hp_bar: ProgressBar = $HpBar

func _ready() -> void:
	_ensure_nodes()
	body.color = display_color
	damageable.hp_changed.connect(_on_hp_changed)
	damageable.died.connect(_on_died)
	_on_hp_changed(damageable.current_hp, damageable.max_hp)

func configure(id_value: StringName, stats_value: UnitStatsResource, damage_value: DamageProfileResource, drops_value: DropTableResource = null) -> void:
	actor_id = id_value
	stats = stats_value.duplicate_stats() if stats_value != null else UnitStatsResource.new()
	damage_profile = damage_value if damage_value != null else DamageProfileResource.new()
	drop_table = drops_value
	_ensure_nodes()
	body.color = display_color
	damageable.configure(stats.max_hp)
	_on_hp_changed(stats.max_hp, stats.max_hp)

func tick_movement(delta: float) -> void:
	if damageable == null or damageable.dead or stats == null:
		return
	var distance := target_x - global_position.x
	if absf(distance) < 4.0:
		return
	var direction := signf(distance)
	global_position.x += direction * stats.move_speed * delta

func can_attack() -> bool:
	return attack_cooldown <= 0.0 and stats != null and damageable != null and not damageable.dead

func consume_attack_cooldown() -> void:
	if stats == null:
		return
	attack_cooldown = 1.0 / maxf(stats.attack_rate, 0.01)

func effective_damage() -> float:
	if stats == null:
		return 0.0
	return runtime_modifiers.effective_damage(stats.damage)

func _process(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)

func _on_hp_changed(current_hp: float, new_max_hp: float) -> void:
	_ensure_nodes()
	if hp_bar == null:
		return
	hp_bar.max_value = new_max_hp
	hp_bar.value = current_hp

func _on_died(_source_id: StringName) -> void:
	visible = false
	defeated.emit(self)

func _ensure_nodes() -> void:
	if damageable == null:
		damageable = get_node_or_null("Damageable") as Damageable
	if body == null:
		body = get_node_or_null("Body") as ColorRect
	if hp_bar == null:
		hp_bar = get_node_or_null("HpBar") as ProgressBar
