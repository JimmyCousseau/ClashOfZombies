class_name Barbarian
extends Unit


func _ready() -> void:
	add_to_group("allies")
	_build_barbarian_visual()
	_pick_target()
	_create_health_bar()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target_enemy):
		_pick_target()
	if _target_enemy == null or not is_instance_valid(_target_enemy):
		velocity = Vector3.ZERO
		move_and_slide()
		global_position.y = 0.0
		return

	var tp: Vector3 = _target_enemy.global_position
	var flat: Vector3 = Vector3(tp.x, global_position.y, tp.z)
	var to_t: Vector3 = flat - global_position
	var dist: float = to_t.length()

	if dist <= attack_range:
		velocity = Vector3.ZERO
		move_and_slide()
		_attack_acc += delta
		if _attack_acc >= attack_cooldown:
			_attack_acc = 0.0
			_target_enemy.take_damage(attack_damage)
	else:
		velocity = to_t.normalized() * move_speed
		move_and_slide()
	global_position.y = 0.0


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


func _build_barbarian_visual() -> void:
	for c in mesh_root.get_children():
		c.free()
	mesh_root.position = Vector3.ZERO
	mesh_root.rotation = Vector3.ZERO
	var body_c := Color(0.2, 0.45, 0.82)
	var trim_c := Color(0.12, 0.22, 0.45)
	var skin := Color(0.92, 0.72, 0.55)
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
	var weapon := MeshInstance3D.new()
	var wbox := BoxMesh.new()
	wbox.size = Vector3(0.12, 0.55, 0.12)
	weapon.mesh = wbox
	weapon.material_override = _mat(Color(0.35, 0.35, 0.38), 0.45)
	weapon.position = Vector3(0.32, 0.45, 0.1)
	weapon.rotation_degrees = Vector3(8, 0, -15)
	mesh_root.add_child(weapon)
