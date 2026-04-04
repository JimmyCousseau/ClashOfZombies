class_name Unit
extends CharacterBody3D

enum Allegiance { PLAYER, ENEMY }

@export var allegiance: Allegiance = Allegiance.ENEMY
@export var use_generated_visuals: bool = false
@export var move_speed: float = 4.5
@export var attack_range: float = 0.0
@export var attack_damage: int = 18
@export var attack_cooldown: float = 0.85

var hp: int = 90
var max_hp: int = 90
var _target_enemy: Unit = null
var _target_building: VillageBuilding = null
var _attack_acc: float = 0.0
var _path: Array[Vector3] = []
var _path_index: int = 0
var _path_refresh_timer: float = 0.0
var _path_goal: Vector3 = Vector3.ZERO
var _path_stop_distance: float = -1.0
var _has_path_goal: bool = false
var _path_blocked: bool = false

@onready var mesh_root: Node3D = $MeshRoot

var _health_bar_container: Node3D = null
var _health_bar_bg: MeshInstance3D = null
var _health_bar_fill: MeshInstance3D = null


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	_update_health_bar()
	if hp <= 0:
		_on_death()


func _create_health_bar() -> void:
	_health_bar_container = Node3D.new()
	_health_bar_container.position = Vector3(0, 1.2, 0)
	add_child(_health_bar_container)
	
	var bg := MeshInstance3D.new()
	var bg_box := BoxMesh.new()
	bg_box.size = Vector3(0.8, 0.15, 0.05)
	bg.mesh = bg_box
	bg.material_override = _mat(Color(0.1, 0.1, 0.1, 0.7))
	_health_bar_container.add_child(bg)
	_health_bar_bg = bg
	
	var fill := MeshInstance3D.new()
	var fill_box := BoxMesh.new()
	fill_box.size = Vector3(0.8, 0.15, 0.06)
	fill.mesh = fill_box
	fill.material_override = _mat(Color(0.2, 0.8, 0.2, 0.9))
	_health_bar_container.add_child(fill)
	_health_bar_fill = fill
	
	_update_health_bar()


func _update_health_bar() -> void:
	if _health_bar_fill == null:
		return
	var ratio: float = float(hp) / float(max_hp)
	ratio = clampf(ratio, 0.0, 1.0)
	_health_bar_fill.scale.x = ratio
	_health_bar_fill.position.x = (1.0 - ratio) * -0.4


func _mat(c: Color, roughness: float = 0.8, metallic: float = 0.05) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = roughness
	m.metallic = metallic
	return m


func _should_use_generated_visuals() -> bool:
	return use_generated_visuals or mesh_root == null or mesh_root.get_child_count() == 0


func _pick_target() -> void:
	pass


func _move_to_world(delta: float, target_pos: Vector3, stop_distance: float = 0.0) -> void:
	if global_position.distance_to(target_pos) <= stop_distance:
		_stop_motion()
		_clear_path()
		return
	_path_refresh_timer -= delta
	var goal_changed: bool = not _has_path_goal or _path_goal.distance_to(target_pos) > 1.25
	var stop_changed: bool = absf(_path_stop_distance - stop_distance) > 0.1
	if goal_changed or stop_changed or _path_refresh_timer <= 0.0 or _path_index >= _path.size():
		_rebuild_path(target_pos, stop_distance)
	if _path_blocked:
		_stop_motion()
		return
	var waypoint: Vector3 = target_pos
	if _path_index < _path.size():
		waypoint = _path[_path_index]
		if global_position.distance_to(waypoint) <= 0.45:
			_path_index += 1
			if _path_index < _path.size():
				waypoint = _path[_path_index]
			else:
				waypoint = target_pos
	var flat: Vector3 = Vector3(waypoint.x, global_position.y, waypoint.z)
	var to_t: Vector3 = flat - global_position
	if to_t.length_squared() <= 0.0001:
		_stop_motion()
		return
	velocity = to_t.normalized() * move_speed
	move_and_slide()
	global_position.y = 0.0


func _rebuild_path(target_pos: Vector3, stop_distance: float) -> void:
	_path_goal = target_pos
	_path_stop_distance = stop_distance
	_has_path_goal = true
	_path_refresh_timer = 0.35
	_path = GameState.find_path(global_position, target_pos, stop_distance)
	_path_index = 0
	_path_blocked = _path.is_empty() and global_position.distance_to(target_pos) > stop_distance + 0.35


func _stop_motion() -> void:
	velocity = Vector3.ZERO
	move_and_slide()
	global_position.y = 0.0


func _clear_path() -> void:
	_path.clear()
	_path_index = 0
	_path_goal = Vector3.ZERO
	_path_stop_distance = -1.0
	_has_path_goal = false
	_path_blocked = false


func _on_death() -> void:
	queue_free()
