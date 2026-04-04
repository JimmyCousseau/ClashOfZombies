extends Node3D
## Arbres et rochers autour de la zone de jeu (ambiance type village CoC).

@export var tree_count: int = 36
@export var inner_radius: float = 30.0
@export var outer_radius: float = 46.0


func _ready() -> void:
	if get_child_count() > 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in tree_count:
		var ang: float = rng.randf() * TAU
		var rad: float = rng.randf_range(inner_radius, outer_radius)
		var pos := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		add_child(_make_tree(rng, pos))
	for j in 14:
		var ang2: float = rng.randf() * TAU
		var rad2: float = rng.randf_range(inner_radius - 2.0, outer_radius + 2.0)
		add_child(_make_rock(rng, Vector3(cos(ang2) * rad2, 0.0, sin(ang2) * rad2)))


func _make_tree(rng: RandomNumberGenerator, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rng.randf() * TAU
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = rng.randf_range(0.18, 0.26)
	cyl.bottom_radius = cyl.top_radius + 0.06
	cyl.height = rng.randf_range(0.95, 1.35)
	trunk.mesh = cyl
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.36, 0.24, 0.12)
	trunk.material_override = mt
	trunk.position = Vector3(0, cyl.height * 0.5, 0)
	root.add_child(trunk)
	var leaf := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = rng.randf_range(0.7, 1.05)
	sp.height = sp.radius * 2.0
	leaf.mesh = sp
	var ml := StandardMaterial3D.new()
	ml.albedo_color = Color(0.16, 0.48 + rng.randf() * 0.08, 0.18)
	leaf.material_override = ml
	leaf.position = Vector3(rng.randf_range(-0.15, 0.15), cyl.height + sp.radius * 0.75, rng.randf_range(-0.15, 0.15))
	leaf.scale = Vector3(1.05, 0.75 + rng.randf() * 0.15, 1.05)
	root.add_child(leaf)
	return root


func _make_rock(rng: RandomNumberGenerator, pos: Vector3) -> Node3D:
	var r := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(
		rng.randf_range(0.55, 1.1),
		rng.randf_range(0.35, 0.65),
		rng.randf_range(0.55, 1.0)
	)
	r.mesh = box
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.48, 0.46, 0.44)
	r.material_override = m
	r.position = pos + Vector3(0, box.size.y * 0.45, 0)
	r.rotation_degrees = Vector3(rng.randf_range(-4, 4), rng.randf() * 360.0, rng.randf_range(-4, 4))
	var rock := Node3D.new()
	rock.add_child(r)
	return rock
