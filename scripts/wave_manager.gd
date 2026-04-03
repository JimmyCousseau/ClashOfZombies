extends Node3D
## Vagues de zombies : patrouille hors du village (sans attaque).

const ZOMBIE_SCENE := preload("res://scenes/zombie.tscn")

@export var interval_sec: float = 14.0
@export var base_count: int = 2
@export var first_wave_delay: float = 8.0

var _wave: int = 0
var _time_to_next: float = 0.0
var _wave_active: bool = false


func _ready() -> void:
	_time_to_next = first_wave_delay
	add_to_group("wave_manager")
	GameState.game_over.connect(_on_game_over)


func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	
	if _wave_active:
		if GameState.enemies_alive <= 0:
			_wave_active = false
			_time_to_next = interval_sec
		return
	
	_time_to_next -= delta
	if _time_to_next > 0.0:
		return
	_spawn_wave()


func _on_game_over() -> void:
	GameState.is_paused = true


func _spawn_wave() -> void:
	_wave += 1
	_wave_active = true
	_time_to_next = 0.0
	GameState.wave_started.emit(_wave)
	var n: int = base_count + _wave
	var door_pos: Vector3 = GameState.get_door_position()
	var door_forward: Vector3 = GameState.get_door_forward()
	for i in n:
		var u: Zombie = ZOMBIE_SCENE.instantiate()
		u.allegiance = Unit.Allegiance.ENEMY
		u.hp = 55 + _wave * 5
		u.max_hp = u.hp
		add_child(u)
		# Spawn in front of door with some spread perpendicular to forward direction
		var right: Vector3 = door_forward.cross(Vector3.UP).normalized()
		var spread_dist: float = randf_range(-3.0, 3.0)
		var forward_dist: float = randf_range(5.0, 8.0)
		var offset: Vector3 = right * spread_dist + door_forward * forward_dist
		u.global_position = door_pos + offset
		u.setup_zombie_patrol()


func get_time_to_next() -> float:
	if _wave_active:
		return 0.0
	return maxf(0.0, _time_to_next)
