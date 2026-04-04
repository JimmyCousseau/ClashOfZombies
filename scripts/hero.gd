@tool
class_name Hero
extends Unit

signal focus_changed(focus_label: String)
signal status_changed(status_text: String)

enum HeroState {
	IN_VILLAGE,
	MOVING_TO_GATE,
	EXPLORING,
	RETURNING,
}

@export var exploration_duration_sec: float = 18.0
@export var return_duration_sec: float = 4.0
@export var idle_wander_min_sec: float = 3.5
@export var idle_wander_max_sec: float = 7.0

var exploration_focus: String = "wood"
var _state: HeroState = HeroState.IN_VILLAGE
var _has_move_target: bool = false
var _move_target: Vector3 = Vector3.ZERO
var _exploration_timer: float = 0.0
var _exploration_total_duration: float = 0.0
var _loot_scale: float = 1.0
var _base_collision_layer: int = 2
var _base_collision_mask: int = 1
var _idle_wander_timer: float = 0.0


func _ready() -> void:
	if _should_use_generated_visuals():
		_build_hero_visual()
	if Engine.is_editor_hint():
		return
	add_to_group("allies")
	add_to_group("hero")
	_base_collision_layer = collision_layer
	_base_collision_mask = collision_mask
	_create_health_bar()
	_reset_idle_wander_timer()
	_emit_focus_changed()
	_emit_status_changed()


func _physics_process(delta: float) -> void:
	match _state:
		HeroState.IN_VILLAGE:
			_process_village_move(delta)
		HeroState.MOVING_TO_GATE:
			var gate_entry: Vector3 = GameState.get_door_inside_entry()
			if global_position.distance_to(gate_entry) <= 0.45:
				_begin_exploration()
			else:
				_move_to_world(delta, gate_entry, 0.2)
		HeroState.EXPLORING:
			_exploration_timer -= delta
			if _exploration_timer <= 0.0:
				_finish_exploration()
		HeroState.RETURNING:
			_exploration_timer -= delta
			if _exploration_timer <= 0.0:
				_finish_exploration()


func move_within_village(target_pos: Vector3) -> bool:
	if _state != HeroState.IN_VILLAGE:
		return false
	if not GameState.is_inside_village(global_position):
		return false
	if not GameState.is_inside_village(target_pos):
		return false
	_move_target = target_pos
	_has_move_target = true
	_reset_idle_wander_timer()
	return true


func send_on_exploration() -> bool:
	if _state != HeroState.IN_VILLAGE:
		return false
	_has_move_target = false
	_clear_path()
	_state = HeroState.MOVING_TO_GATE
	_emit_status_changed()
	return true


func request_return() -> bool:
	match _state:
		HeroState.MOVING_TO_GATE:
			_state = HeroState.IN_VILLAGE
			_reset_idle_wander_timer()
			_emit_status_changed()
			return true
		HeroState.EXPLORING:
			var progress: float = 1.0
			if _exploration_total_duration > 0.0:
				progress = clampf(1.0 - (_exploration_timer / _exploration_total_duration), 0.0, 1.0)
			_loot_scale = lerpf(0.35, 1.0, progress)
			_state = HeroState.RETURNING
			_exploration_timer = mini(_exploration_timer, return_duration_sec)
			_emit_status_changed()
			return true
	return false


func cycle_exploration_focus() -> String:
	var index: int = GameState.EXPLORATION_FOCUS_ORDER.find(exploration_focus)
	if index < 0:
		index = 0
	exploration_focus = GameState.EXPLORATION_FOCUS_ORDER[(index + 1) % GameState.EXPLORATION_FOCUS_ORDER.size()]
	_emit_focus_changed()
	return get_exploration_focus_label()


func get_exploration_focus_label() -> String:
	match exploration_focus:
		"wood":
			return "Bois"
		"stone":
			return "Pierre"
		"iron":
			return "Fer"
		"food":
			return "Nourriture"
		"salvage":
			return "Fouille"
	return "Bois"


func get_status_text() -> String:
	match _state:
		HeroState.IN_VILLAGE:
			return "Au village"
		HeroState.MOVING_TO_GATE:
			return "Se rend a la porte"
		HeroState.EXPLORING:
			return "En exploration %s" % _format_time(_exploration_timer)
		HeroState.RETURNING:
			return "Revient au village %s" % _format_time(_exploration_timer)
	return "Indisponible"


func get_primary_door_action_label() -> String:
	match _state:
		HeroState.IN_VILLAGE:
			return "Envoyer dehors"
		HeroState.MOVING_TO_GATE:
			return "Annuler le depart"
		HeroState.EXPLORING:
			return "Rappeler"
		HeroState.RETURNING:
			return "Retour en cours"
	return "Action"


func can_execute_primary_door_action() -> bool:
	return _state != HeroState.RETURNING


func execute_primary_door_action() -> bool:
	match _state:
		HeroState.IN_VILLAGE:
			return send_on_exploration()
		HeroState.MOVING_TO_GATE, HeroState.EXPLORING:
			return request_return()
	return false


func is_available_in_village() -> bool:
	return _state == HeroState.IN_VILLAGE and GameState.is_inside_village(global_position)


func _process_village_move(delta: float) -> void:
	if not _has_move_target:
		_stop_motion()
		_idle_wander_timer -= delta
		if _idle_wander_timer <= 0.0:
			_pick_idle_destination()
		return
	if global_position.distance_to(_move_target) <= 0.35:
		_has_move_target = false
		_clear_path()
		_stop_motion()
		_reset_idle_wander_timer()
		return
	_move_to_world(delta, _move_target, 0.15)


func _begin_exploration() -> void:
	_state = HeroState.EXPLORING
	_exploration_total_duration = exploration_duration_sec + randf_range(-4.0, 6.0)
	_exploration_timer = _exploration_total_duration
	_loot_scale = 1.0
	_stop_motion()
	_clear_path()
	visible = false
	collision_layer = 0
	collision_mask = 0
	remove_from_group("allies")
	global_position = GameState.get_door_outside_entry()
	_emit_status_changed()


func _finish_exploration() -> void:
	var mission_day: int = 1
	var wave_manager: Node = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager and wave_manager.has_method("get_next_wave_index"):
		mission_day = maxi(1, int(wave_manager.call("get_next_wave_index")))
	GameState.resolve_exploration(exploration_focus, mission_day, _loot_scale)
	global_position = GameState.get_door_inside_entry()
	visible = true
	collision_layer = _base_collision_layer
	collision_mask = _base_collision_mask
	if not is_in_group("allies"):
		add_to_group("allies")
	_state = HeroState.IN_VILLAGE
	_reset_idle_wander_timer()
	_emit_status_changed()


func _emit_focus_changed() -> void:
	focus_changed.emit(get_exploration_focus_label())


func _emit_status_changed() -> void:
	status_changed.emit(get_status_text())


func _on_death() -> void:
	GameState.game_over.emit()
	queue_free()


func _build_hero_visual() -> void:
	for c in mesh_root.get_children():
		c.free()
	mesh_root.position = Vector3.ZERO
	mesh_root.rotation = Vector3.ZERO
	var jacket := _mat(Color(0.18, 0.24, 0.28))
	var pants := _mat(Color(0.16, 0.18, 0.14))
	var skin := _mat(Color(0.72, 0.6, 0.48))
	var bag := _mat(Color(0.32, 0.26, 0.18))
	var metal := _mat(Color(0.35, 0.38, 0.4), 0.4, 0.3)
	var torso := MeshInstance3D.new()
	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(0.46, 0.58, 0.28)
	torso.mesh = torso_mesh
	torso.material_override = jacket
	torso.position = Vector3(0, 0.4, 0)
	mesh_root.add_child(torso)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.material_override = skin
	head.position = Vector3(0, 0.84, 0)
	mesh_root.add_child(head)
	var backpack := MeshInstance3D.new()
	var backpack_mesh := BoxMesh.new()
	backpack_mesh.size = Vector3(0.32, 0.4, 0.16)
	backpack.mesh = backpack_mesh
	backpack.material_override = bag
	backpack.position = Vector3(0, 0.42, -0.2)
	mesh_root.add_child(backpack)
	var tool := MeshInstance3D.new()
	var tool_mesh := BoxMesh.new()
	tool_mesh.size = Vector3(0.1, 0.56, 0.1)
	tool.mesh = tool_mesh
	tool.material_override = metal
	tool.position = Vector3(0.28, 0.38, 0.06)
	tool.rotation_degrees = Vector3(0, 0, 18)
	mesh_root.add_child(tool)


func _reset_idle_wander_timer() -> void:
	_idle_wander_timer = randf_range(idle_wander_min_sec, idle_wander_max_sec)


func _pick_idle_destination() -> void:
	var inner: float = GameState.get_inner_half_extent() - 2.2
	for i in 8:
		var candidate := Vector3(randf_range(-inner, inner), 0.0, randf_range(-inner, inner))
		if not GameState.is_inside_village(candidate):
			continue
		_move_target = candidate
		_has_move_target = true
		return
	_reset_idle_wander_timer()


func _format_time(total_seconds: float) -> String:
	var sec: int = maxi(0, int(ceil(total_seconds)))
	var minutes: int = sec / 60
	var seconds: int = sec % 60
	return "%02d:%02d" % [minutes, seconds]
