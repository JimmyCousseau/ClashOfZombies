@tool
class_name Barbarian
extends Unit

@export var idle_wander_min_sec: float = 2.0
@export var idle_wander_max_sec: float = 5.0
@export var patrol_radius: float = 6.0

var source_barracks_id: int = 0
var _guard_home: Vector3 = Vector3.ZERO
var _idle_wander_timer: float = 0.0
var _wander_target: Vector3 = Vector3.ZERO
var _has_wander_target: bool = false
var _animation_player: AnimationPlayer
var _is_moving: bool = false


func _ready() -> void:
	if _should_use_generated_visuals():
		_build_barbarian_visual()
	if Engine.is_editor_hint():
		return
	_animation_player = $AnimationPlayer
	add_to_group("allies")
	_pick_target()
	_create_health_bar()
	if _guard_home == Vector3.ZERO:
		_guard_home = global_position
	_reset_idle_wander_timer()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target_enemy):
		_pick_target()
	if _target_enemy == null or not is_instance_valid(_target_enemy):
		_patrol_outside(delta)
		_update_animation(delta)
		return

	var tp: Vector3 = _target_enemy.global_position
	var dist: float = global_position.distance_to(tp)

	if dist <= attack_range:
		_stop_motion()
		_clear_path()
		_is_moving = false
		_attack_acc += delta
		if _attack_acc >= attack_cooldown:
			_attack_acc = 0.0
			_target_enemy.take_damage(attack_damage)
	else:
		_is_moving = true
		_move_to_world(delta, tp, attack_range)
	
	_update_animation(delta)


func configure_barracks_guard(barracks_id: int, guard_home: Vector3) -> void:
	source_barracks_id = barracks_id
	set_guard_home(guard_home)


func set_guard_home(guard_home: Vector3) -> void:
	_guard_home = Vector3(guard_home.x, 0.0, guard_home.z)
	_has_wander_target = false
	_reset_idle_wander_timer()


func _patrol_outside(delta: float) -> void:
	if _has_wander_target:
		if global_position.distance_to(_wander_target) <= 0.45:
			_has_wander_target = false
			_clear_path()
			_stop_motion()
			_is_moving = false
			_reset_idle_wander_timer()
			return
		_is_moving = true
		_move_to_world(delta, _wander_target, 0.15)
		return
	_stop_motion()
	_is_moving = false
	_idle_wander_timer -= delta
	if _idle_wander_timer <= 0.0:
		_pick_wander_target()


func _pick_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	_target_enemy = null
	var closest: float = 999.0
	for e in enemies:
		if is_instance_valid(e):
			var d: float = global_position.distance_to(e.global_position)
			if d < closest:
				closest = d
				_target_enemy = e


func _reset_idle_wander_timer() -> void:
	_idle_wander_timer = randf_range(idle_wander_min_sec, idle_wander_max_sec)


func _pick_wander_target() -> void:
	for i in 10:
		var offset := Vector3(randf_range(-patrol_radius, patrol_radius), 0.0, randf_range(-patrol_radius, patrol_radius))
		var candidate := _guard_home + offset
		if GameState.is_inside_village(candidate):
			candidate = GameState.get_outside_spawn_from_origin(candidate)
		_wander_target = candidate
		_has_wander_target = true
		return
	_reset_idle_wander_timer()


func _build_barbarian_visual() -> void:
	for c in mesh_root.get_children():
		c.free()
	mesh_root.position = Vector3.ZERO
	mesh_root.rotation = Vector3.ZERO
	var body_c := Color(0.22, 0.28, 0.3)
	var trim_c := Color(0.16, 0.18, 0.16)
	var skin := Color(0.72, 0.6, 0.48)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.42, 0.55, 0.32)
	body.mesh = box
	body.material_override = _mat(body_c)
	body.position = Vector3(0, 0.35, 0)
	mesh_root.add_child(body)
	var head := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.22
	sp.height = 0.44
	head.mesh = sp
	head.material_override = _mat(skin)
	head.position = Vector3(0, 0.78, 0)
	mesh_root.add_child(head)
	var band := MeshInstance3D.new()
	var band_m := BoxMesh.new()
	band_m.size = Vector3(0.48, 0.12, 0.38)
	band.mesh = band_m
	band.material_override = _mat(trim_c)
	band.position = Vector3(0, 0.88, 0)
	mesh_root.add_child(band)
	var left_arm := MeshInstance3D.new()
	var arm_box := BoxMesh.new()
	arm_box.size = Vector3(0.1, 0.38, 0.1)
	left_arm.mesh = arm_box
	left_arm.material_override = _mat(body_c)
	left_arm.position = Vector3(-0.24, 0.32, 0)
	left_arm.name = "LeftArm"
	mesh_root.add_child(left_arm)
	var right_arm := MeshInstance3D.new()
	var arm_box2 := BoxMesh.new()
	arm_box2.size = Vector3(0.1, 0.38, 0.1)
	right_arm.mesh = arm_box2
	right_arm.material_override = _mat(body_c)
	right_arm.position = Vector3(0.32, 0.45, 0.02)
	right_arm.name = "RightArm"
	mesh_root.add_child(right_arm)


func _update_animation(delta: float) -> void:
	_update_arm_state()


func _update_arm_state() -> void:
	if not _animation_player:
		return
	
	if _is_moving:
		if _animation_player.has_animation("arm_swing_moving") and _animation_player.current_animation != "arm_swing_moving":
			_animation_player.play("arm_swing_moving")
	else:
		if _animation_player.has_animation("arm_idle") and _animation_player.current_animation != "arm_idle":
			_animation_player.play("arm_idle")
