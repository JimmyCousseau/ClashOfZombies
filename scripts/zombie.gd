class_name Zombie
extends Unit

var _patrol_waypoints: Array[Vector3] = []
var _patrol_index: int = 0


func _ready() -> void:
	add_to_group("enemies")
	GameState.register_enemy()
	_build_zombie_visual()
	_create_health_bar()


func setup_zombie_patrol() -> void:
	var r: float = GameState.get_patrol_ring_radius()
	var n: int = 22
	_patrol_waypoints.clear()
	for i in n:
		var ang: float = TAU * float(i) / float(n)
		_patrol_waypoints.append(Vector3(cos(ang) * r, 0.0, sin(ang) * r))
	_patrol_index = randi() % maxi(1, _patrol_waypoints.size())
	move_speed = 2.0 + randf() * 0.75


func _physics_process(delta: float) -> void:
	_check_zombie_target()
	
	if _target_building:
		_attack_building(delta)
	elif _target_enemy:
		_move_to_target(delta, _target_enemy.global_position)
	else:
		_patrol(delta)


func _patrol(delta: float) -> void:
	if _patrol_waypoints.is_empty():
		velocity = Vector3.ZERO
		move_and_slide()
		global_position.y = 0.0
		return
	
	var target_pos: Vector3 = _patrol_waypoints[_patrol_index]
	_move_to_target(delta, target_pos)
	
	var dist: float = global_position.distance_to(target_pos)
	if dist < 1.0:
		_patrol_index = (_patrol_index + 1) % _patrol_waypoints.size()


func _move_to_target(delta: float, target_pos: Vector3) -> void:
	var flat: Vector3 = Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_t: Vector3 = flat - global_position
	velocity = to_t.normalized() * move_speed
	move_and_slide()
	global_position.y = 0.0


func _attack_building(delta: float) -> void:
	var dist: float = global_position.distance_to(_target_building.global_position)
	if dist > attack_range + 0.5:
		_move_to_target(delta, _target_building.global_position)
		return
	
	velocity = Vector3.ZERO
	move_and_slide()
	global_position.y = 0.0
	_attack_acc += delta
	if _attack_acc >= attack_cooldown:
		_attack_acc = 0.0
		_target_building.take_damage(attack_damage)


func _check_zombie_target() -> void:
	# Priority 1: Closest building (including door)
	var village: Node3D = get_tree().get_first_node_in_group("village")
	if village:
		var closest: VillageBuilding = null
		var closest_dist: float = 999.0
		for child in village.get_children():
			if child is VillageBuilding:
				var b := child as VillageBuilding
				var d: float = global_position.distance_to(b.global_position)
				if d < closest_dist:
					closest = b
					closest_dist = d
		
		if closest and closest_dist < 35.0:
			_target_building = closest
			_target_enemy = null
			return
	
	_target_building = null
	_target_enemy = null


func _build_zombie_visual() -> void:
	for c in mesh_root.get_children():
		c.free()
	mesh_root.position = Vector3(0, 0, 0)
	mesh_root.rotation = Vector3.ZERO
	## Style proche des zombies CoC : peau verte, haillons violets, bras tendus, yeux qui brillent.
	var skin := Color(0.42, 0.58, 0.38)
	var skin_dark := Color(0.28, 0.4, 0.26)
	var rags := Color(0.42, 0.22, 0.62)
	var rags_dark := Color(0.22, 0.1, 0.32)
	var bone := Color(0.75, 0.7, 0.62)
	# Torse voûté
	var torso := MeshInstance3D.new()
	var tbox := BoxMesh.new()
	tbox.size = Vector3(0.46, 0.5, 0.34)
	torso.mesh = tbox
	torso.material_override = _mat(rags)
	torso.position = Vector3(0, 0.38, 0)
	torso.rotation_degrees = Vector3(12, 0, 0)
	mesh_root.add_child(torso)
	# Haillons / lambeaux
	var rag1 := MeshInstance3D.new()
	var r1 := BoxMesh.new()
	r1.size = Vector3(0.25, 0.35, 0.08)
	rag1.mesh = r1
	rag1.material_override = _mat(rags_dark)
	rag1.position = Vector3(0.18, 0.22, 0.14)
	rag1.rotation_degrees = Vector3(0, 0, -18)
	mesh_root.add_child(rag1)
	var rag2 := MeshInstance3D.new()
	var r2 := BoxMesh.new()
	r2.size = r1.size
	rag2.mesh = r2
	rag2.material_override = _mat(rags)
	rag2.position = Vector3(-0.2, 0.28, -0.12)
	rag2.rotation_degrees = Vector3(8, 0, 22)
	mesh_root.add_child(rag2)
	# Tête gonflée style cartoon
	var head := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.26
	sp.height = 0.52
	head.mesh = sp
	head.material_override = _mat(skin)
	head.position = Vector3(0, 0.88, 0.05)
	mesh_root.add_child(head)
	# Mâchoire / joue
	var jaw := MeshInstance3D.new()
	var jbox := BoxMesh.new()
	jbox.size = Vector3(0.32, 0.12, 0.22)
	jaw.mesh = jbox
	jaw.material_override = _mat(skin_dark)
	jaw.position = Vector3(0, 0.72, 0.18)
	mesh_root.add_child(jaw)
	# Yeux brillants (élexir)
	var eye_l := MeshInstance3D.new()
	var es := SphereMesh.new()
	es.radius = 0.06
	es.height = 0.12
	eye_l.mesh = es
	var em := StandardMaterial3D.new()
	em.albedo_color = Color(0.55, 0.95, 0.85)
	em.emission_enabled = true
	em.emission = Color(0.35, 0.85, 0.75)
	em.emission_energy_multiplier = 1.8
	eye_l.material_override = em
	eye_l.position = Vector3(-0.1, 0.92, 0.22)
	mesh_root.add_child(eye_l)
	var eye_r := MeshInstance3D.new()
	var es2 := SphereMesh.new()
	es2.radius = es.radius
	es2.height = es.height
	eye_r.mesh = es2
	eye_r.material_override = em
	eye_r.position = Vector3(0.1, 0.92, 0.22)
	mesh_root.add_child(eye_r)
	# Bras tendus (style zombie)
	var arm_l := MeshInstance3D.new()
	var abox := BoxMesh.new()
	abox.size = Vector3(0.14, 0.14, 0.52)
	arm_l.mesh = abox
	arm_l.material_override = _mat(skin_dark)
	arm_l.position = Vector3(-0.38, 0.52, 0.35)
	arm_l.rotation_degrees = Vector3(-55, 0, -12)
	mesh_root.add_child(arm_l)
	var arm_r := MeshInstance3D.new()
	var abox2 := BoxMesh.new()
	abox2.size = abox.size
	arm_r.mesh = abox2
	arm_r.material_override = _mat(skin)
	arm_r.position = Vector3(0.4, 0.5, 0.32)
	arm_r.rotation_degrees = Vector3(-52, 0, 10)
	mesh_root.add_child(arm_r)
	# Mains / griffes
	var claw := MeshInstance3D.new()
	var cbox := BoxMesh.new()
	cbox.size = Vector3(0.18, 0.08, 0.12)
	claw.mesh = cbox
	claw.material_override = _mat(bone)
	claw.position = Vector3(-0.52, 0.48, 0.58)
	claw.rotation_degrees = Vector3(10, 0, -20)
	mesh_root.add_child(claw)
	var claw2 := MeshInstance3D.new()
	var cbox2 := BoxMesh.new()
	cbox2.size = cbox.size
	claw2.mesh = cbox2
	claw2.material_override = _mat(bone)
	claw2.position = Vector3(0.54, 0.46, 0.56)
	claw2.rotation_degrees = Vector3(8, 0, 18)
	mesh_root.add_child(claw2)


func _exit_tree() -> void:
	GameState.unregister_enemy()
