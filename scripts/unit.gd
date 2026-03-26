class_name Unit
extends CharacterBody3D

enum Allegiance { PLAYER, ENEMY }

@export var allegiance: Allegiance = Allegiance.ENEMY
@export var move_speed: float = 4.5
@export var attack_range: float = 2.2
@export var attack_damage: int = 18
@export var attack_cooldown: float = 0.85

var hp: int = 90
var max_hp: int = 90
var _target_enemy: Unit = null
var _target_building: VillageBuilding = null
var _attack_acc: float = 0.0

var _patrol_waypoints: Array[Vector3] = []
var _patrol_index: int = 0

@onready var mesh_root: Node3D = $MeshRoot


func _ready() -> void:
	if allegiance == Allegiance.ENEMY:
		add_to_group("enemies")
		GameState.register_enemy()
		_build_zombie_visual()
	else:
		add_to_group("allies")
		_build_barbarian_visual()
		_pick_target()


func setup_zombie_patrol() -> void:
	var r: float = GameState.get_patrol_ring_radius()
	var n: int = 22
	_patrol_waypoints.clear()
	for i in n:
		var ang: float = TAU * float(i) / float(n)
		_patrol_waypoints.append(Vector3(cos(ang) * r, 0.0, sin(ang) * r))
	_patrol_index = randi() % maxi(1, _patrol_waypoints.size())
	move_speed = 2.0 + randf() * 0.75


func _mat(c: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = roughness
	return m


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


func _physics_process(delta: float) -> void:
	if allegiance == Allegiance.PLAYER:
		_physics_player(delta)
	else:
		_physics_zombie_patrol(delta)


func _physics_zombie_patrol(delta: float) -> void:
	if _patrol_waypoints.is_empty():
		velocity = Vector3.ZERO
		move_and_slide()
		global_position.y = 0.0
		return
	var target: Vector3 = _patrol_waypoints[_patrol_index]
	var flat: Vector3 = Vector3(target.x, global_position.y, target.z)
	var to_t: Vector3 = flat - global_position
	var dist: float = to_t.length()
	if dist < 1.05:
		_patrol_index = (_patrol_index + 1) % _patrol_waypoints.size()
	else:
		velocity = to_t.normalized() * move_speed
		move_and_slide()
	global_position.y = 0.0
	if mesh_root:
		mesh_root.rotation_degrees.z = sin(Time.get_ticks_msec() * 0.007) * 5.0


func _physics_player(delta: float) -> void:
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
	_target_building = null
	_target_enemy = null
	var best: Unit = null
	var best_d2: float = 1e12
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Unit
		if e == null or not is_instance_valid(e):
			continue
		var d2: float = global_position.distance_squared_to(e.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = e
	_target_enemy = best


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	if hp <= 0:
		if allegiance == Allegiance.ENEMY:
			GameState.unregister_enemy()
		queue_free()
