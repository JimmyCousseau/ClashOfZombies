extends Node
class_name HeroManager

## Gère le héros : spawn, déplacement, actions à la porte.

const HERO_SCENE    := preload("res://scenes/hero.tscn")
const HERO_START_MARKER_NAME := "HeroStart"

var _grid_map: VillageGridMap
var _grid_root: Node3D   # VillageGrid
var _hero: Node = null


func setup(grid_map: VillageGridMap, grid_root: Node3D) -> void:
	_grid_map = grid_map
	_grid_root = grid_root


func spawn() -> void:
	var allies: Node3D = _grid_root.get_tree().get_first_node_in_group("ally_units") as Node3D
	if allies == null:
		_grid_root.call_deferred("_spawn_hero_deferred")
		return
	_hero = HERO_SCENE.instantiate()
	allies.add_child(_hero)
	var marker := _grid_root.get_node_or_null(HERO_START_MARKER_NAME) as Node3D
	if marker:
		_hero.global_position = marker.global_position
		return
	var center := Vector2i(int(GameState.GRID_SIZE.x / 2.0), int(GameState.GRID_SIZE.y / 2.0))
	_hero.global_position = _grid_map.cell_to_world(center) + Vector3(1.0, 0.0, 2.0)


func is_valid() -> bool:
	return _hero != null and is_instance_valid(_hero)


func move_to(world_pos: Vector3) -> void:
	if not is_valid():
		return
	_hero.move_within_village(world_pos)


func send_on_exploration() -> void:
	if not is_valid():
		return
	_hero.send_on_exploration()


func execute_door_action() -> bool:
	var door: VillageBuilding = _grid_map.get_main_door()
	if door and door.is_destroyed:
		return door.rebuild_main_door()
	if not is_valid():
		return false
	if _hero.has_method("execute_primary_door_action"):
		return _hero.call("execute_primary_door_action")
	return false


func cycle_focus() -> String:
	if not is_valid():
		return "Bois"
	return _hero.cycle_exploration_focus()


func get_focus_label() -> String:
	if not is_valid():
		return "Bois"
	return _hero.get_exploration_focus_label()


func get_status_text() -> String:
	if not is_valid():
		return "Indisponible"
	return _hero.get_status_text()


func get_door_action_label() -> String:
	if not is_valid():
		return "Indisponible"
	if _hero.has_method("get_primary_door_action_label"):
		return _hero.call("get_primary_door_action_label")
	return "Action"


func can_execute_door_action() -> bool:
	if not is_valid():
		return false
	if _hero.has_method("can_execute_primary_door_action"):
		return _hero.call("can_execute_primary_door_action")
	return false
