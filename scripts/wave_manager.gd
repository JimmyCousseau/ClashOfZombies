extends Node3D
## Attaques quotidiennes de zombies a 00:00 UTC.

const ZOMBIE_SCENE := preload("res://scenes/zombie.tscn")

@export var base_count: int = 2

var _wave_active: bool = false
var _current_wave: int = 0
var _first_attack_day_index: int = 0
var _last_attack_day_index: int = -1
var _next_attack_unix: int = 0


func _ready() -> void:
	add_to_group("wave_manager")
	GameState.game_over.connect(_on_game_over)
	_first_attack_day_index = GameState.get_current_utc_day_index() + 1
	_next_attack_unix = GameState.get_next_utc_midnight_unix()


func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	if _wave_active:
		if GameState.enemies_alive <= 0:
			_wave_active = false
		return
	var now_unix: int = int(Time.get_unix_time_from_system())
	if now_unix < _next_attack_unix:
		return
	var attack_day_index: int = int(_next_attack_unix / 86400.0)
	if attack_day_index != _last_attack_day_index:
		_spawn_wave_for_day(attack_day_index)
		_last_attack_day_index = attack_day_index
	_next_attack_unix = (attack_day_index + 1) * 86400
	while now_unix >= _next_attack_unix:
		_next_attack_unix += 86400


func _on_game_over() -> void:
	GameState.is_paused = true


func _spawn_wave_for_day(attack_day_index: int) -> void:
	var wave_index: int = maxi(1, attack_day_index - _first_attack_day_index + 1)
	_start_wave(wave_index, base_count + wave_index * 2)


func trigger_debug_next_wave() -> bool:
	if _wave_active:
		return false
	var wave_index: int = get_next_wave_index()
	_start_wave(wave_index, base_count + wave_index * 2)
	return true


func spawn_debug_reinforcements(count: int = 12) -> bool:
	if count <= 0:
		return false
	var wave_index: int = maxi(1, max(_current_wave, get_next_wave_index()))
	if not _wave_active:
		_wave_active = true
		_current_wave = wave_index
		GameState.wave_started.emit(_current_wave)
	_spawn_zombies(count, wave_index, 4.2, 8.2)
	return true


func clear_all_zombies() -> int:
	var cleared: int = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Zombie and is_instance_valid(enemy):
			enemy.queue_free()
			cleared += 1
	if cleared > 0:
		_wave_active = false
	return cleared


func get_time_to_next() -> float:
	if _wave_active:
		return 0.0
	return maxf(0.0, float(_next_attack_unix) - Time.get_unix_time_from_system())


func get_current_wave() -> int:
	return _current_wave


func get_next_wave_index() -> int:
	if _wave_active:
		return _current_wave
	var next_day_index: int = int(_next_attack_unix / 86400.0)
	return maxi(1, next_day_index - _first_attack_day_index + 1)


func _start_wave(wave_index: int, zombie_count: int) -> void:
	_current_wave = maxi(1, wave_index)
	_wave_active = true
	GameState.wave_started.emit(_current_wave)
	_spawn_zombies(zombie_count, _current_wave, 5.5, 10.0)


func _spawn_zombies(zombie_count: int, wave_index: int, extra_radius_min: float, extra_radius_max: float) -> void:
	for i in zombie_count:
		var zombie: Zombie = ZOMBIE_SCENE.instantiate()
		zombie.allegiance = Unit.Allegiance.ENEMY
		zombie.hp = 70 + wave_index * 10
		zombie.max_hp = zombie.hp
		add_child(zombie)
		var angle: float = randf() * TAU
		var radius: float = GameState.get_patrol_ring_radius() + randf_range(extra_radius_min, extra_radius_max)
		zombie.global_position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		zombie.setup_zombie_patrol()
