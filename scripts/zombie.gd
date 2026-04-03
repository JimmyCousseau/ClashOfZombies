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
	mesh_root.position = Vector3.ZERO
	
	# Zombie body - taller and more menacing
	var mat_zombie := _mat(Color(0.32, 0.54, 0.29, 1.0), 0.8, 0.05)
	var body_box := BoxMesh.new()
	body_box.size = Vector3(0.8, 1.6, 0.6)
	var body := MeshInstance3D.new()
	body.mesh = body_box
	body.material_override = mat_zombie
	body.position = Vector3(0.0, 0.8, 0.0)
	mesh_root.add_child(body)
	
	# Zombie head - with skin tone
	var head_box := BoxMesh.new()
	head_box.size = Vector3(0.5, 0.5, 0.5)
	var head := MeshInstance3D.new()
	head.mesh = head_box
	head.material_override = _mat(Color(0.55, 0.45, 0.38, 1.0), 0.85, 0.02)
	head.position = Vector3(0.0, 1.65, 0.0)
	mesh_root.add_child(head)
	
	# Zombie left arm
	var arm_left := BoxMesh.new()
	arm_left.size = Vector3(0.3, 0.8, 0.3)
	var armL := MeshInstance3D.new()
	armL.mesh = arm_left
	armL.material_override = mat_zombie
	armL.position = Vector3(-0.62, 0.95, 0.0)
	armL.rotation_degrees = Vector3(5, 0, -8)
	mesh_root.add_child(armL)
	
	# Zombie right arm
	var armR := MeshInstance3D.new()
	var arm_right := BoxMesh.new()
	arm_right.size = Vector3(0.3, 0.8, 0.3)
	armR.mesh = arm_right
	armR.material_override = mat_zombie
	armR.position = Vector3(0.62, 0.95, 0.0)
	armR.rotation_degrees = Vector3(-5, 0, 8)
	mesh_root.add_child(armR)
	
	# Zombie left leg
	var leg_left := BoxMesh.new()
	leg_left.size = Vector3(0.35, 0.85, 0.35)
	var legL := MeshInstance3D.new()
	legL.mesh = leg_left
	legL.material_override = mat_zombie
	legL.position = Vector3(-0.3, 0.25, 0.0)
	mesh_root.add_child(legL)
	
	# Zombie right leg
	var legR := MeshInstance3D.new()
	var leg_right := BoxMesh.new()
	leg_right.size = Vector3(0.35, 0.85, 0.35)
	legR.mesh = leg_right
	legR.material_override = mat_zombie
	legR.position = Vector3(0.3, 0.25, 0.0)
	mesh_root.add_child(legR)
	
	# Zombie claws left
	var cbox := BoxMesh.new()
	cbox.size = Vector3(0.12, 0.3, 0.05)
	var claw1 := MeshInstance3D.new()
	var bone := Color(0.65, 0.59, 0.5, 1.0)
	claw1.mesh = cbox
	claw1.material_override = _mat(bone)
	claw1.position = Vector3(-0.54, 0.46, -0.56)
	claw1.rotation_degrees = Vector3(8, 0, -18)
	mesh_root.add_child(claw1)
	
	# Zombie claws right
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
