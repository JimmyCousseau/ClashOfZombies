extends Node3D
## Vagues de zombies : patrouille hors du village (sans attaque).

const UNIT_SCENE := preload("res://scenes/unit.tscn")

@export var interval_sec: float = 14.0
@export var base_count: int = 2
@export var first_wave_delay: float = 8.0

var _wave: int = 0
var _time_to_next: float = 0.0


func _ready() -> void:
	_time_to_next = first_wave_delay
	GameState.game_over.connect(_on_game_over)


func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	_time_to_next -= delta
	if _time_to_next > 0.0:
		return
	_time_to_next = interval_sec
	_spawn_wave()


func _on_game_over() -> void:
	GameState.is_paused = true


func _spawn_wave() -> void:
	_wave += 1
	GameState.wave_started.emit(_wave)
	var n: int = base_count + _wave
	var r: float = GameState.get_patrol_ring_radius()
	for i in n:
		var ang: float = randf() * TAU
		var u: Unit = UNIT_SCENE.instantiate()
		u.allegiance = Unit.Allegiance.ENEMY
		u.hp = 55 + _wave * 5
		u.max_hp = u.hp
		add_child(u)
		u.global_position = Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		u.setup_zombie_patrol()
