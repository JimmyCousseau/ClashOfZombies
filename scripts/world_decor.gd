extends Node3D
## Arbres et rochers autour de la zone de jeu (ambiance type village CoC).

@export var decor_seed: int = 0
@export var village_clear_radius: float = 20.0
@export var clutter_outer_radius: float = 42.0
@export var forest_inner_radius: float = 46.0
@export var forest_outer_radius: float = 126.0
@export var clutter_tree_count: int = 48
@export var clutter_rock_count: int = 24
@export var clutter_grass_count: int = 120
@export var forest_ring_count: int = 5
@export var forest_tree_spacing: float = 7.2
@export var forest_rock_count: int = 42


func _ready() -> void:
	if has_node("GeneratedDecor"):
		return
	var generated := Node3D.new()
	generated.name = "GeneratedDecor"
	add_child(generated)
	var rng := RandomNumberGenerator.new()
	if decor_seed == 0:
		rng.randomize()
	else:
		rng.seed = decor_seed
	_populate_clutter(generated, rng)
	_populate_forest(generated, rng)


func _populate_clutter(parent: Node3D, rng: RandomNumberGenerator) -> void:
	for i in clutter_tree_count:
		parent.add_child(_make_tree(rng, _random_ring_position(rng, village_clear_radius, clutter_outer_radius), 0.95, 1.18))
	for i in clutter_rock_count:
		parent.add_child(_make_rock(rng, _random_ring_position(rng, village_clear_radius - 1.0, clutter_outer_radius + 4.0), 0.95, 1.35))
	for i in clutter_grass_count:
		parent.add_child(_make_grass_clump(rng, _random_ring_position(rng, village_clear_radius - 2.0, clutter_outer_radius + 1.5)))


func _populate_forest(parent: Node3D, rng: RandomNumberGenerator) -> void:
	var ring_total: int = maxi(1, forest_ring_count)
	for ring in ring_total:
		var t: float = 0.0 if ring_total == 1 else float(ring) / float(ring_total - 1)
		var radius: float = lerpf(forest_inner_radius, forest_outer_radius, t)
		var count: int = maxi(28, int(round(TAU * radius / maxf(4.6, forest_tree_spacing))))
		for i in count:
			var base_ang: float = TAU * float(i) / float(count)
			var ang: float = base_ang + rng.randf_range(-0.055, 0.055)
			var rad: float = radius + rng.randf_range(-3.2, 3.2)
			var pos := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
			parent.add_child(_make_tree(rng, pos, 1.08 + t * 0.16, 1.3 + t * 0.22))
	for i in forest_rock_count:
		parent.add_child(_make_rock(rng, _random_ring_position(rng, forest_inner_radius - 2.0, forest_outer_radius + 5.0), 1.1, 1.75))


func _random_ring_position(rng: RandomNumberGenerator, min_radius: float, max_radius: float) -> Vector3:
	var ang: float = rng.randf() * TAU
	var rad: float = rng.randf_range(min_radius, max_radius)
	return Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)


func _make_tree(rng: RandomNumberGenerator, pos: Vector3, trunk_scale: float = 1.0, crown_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rng.randf() * TAU
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = rng.randf_range(0.18, 0.26) * trunk_scale
	cyl.bottom_radius = cyl.top_radius + 0.06
	cyl.height = rng.randf_range(0.95, 1.35) * trunk_scale
	trunk.mesh = cyl
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.34 + rng.randf() * 0.05, 0.22 + rng.randf() * 0.03, 0.11)
	trunk.material_override = mt
	trunk.position = Vector3(0, cyl.height * 0.5, 0)
	root.add_child(trunk)
	var leaf := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = rng.randf_range(0.7, 1.05) * crown_scale
	sp.height = sp.radius * 2.0
	leaf.mesh = sp
	var ml := StandardMaterial3D.new()
	ml.albedo_color = Color(0.12 + rng.randf() * 0.06, 0.38 + rng.randf() * 0.16, 0.14 + rng.randf() * 0.06)
	leaf.material_override = ml
	leaf.position = Vector3(rng.randf_range(-0.15, 0.15), cyl.height + sp.radius * 0.75, rng.randf_range(-0.15, 0.15))
	leaf.scale = Vector3(1.05, 0.75 + rng.randf() * 0.15, 1.05)
	root.add_child(leaf)
	if rng.randf() < 0.38:
		var secondary_leaf := MeshInstance3D.new()
		var secondary_mesh := SphereMesh.new()
		secondary_mesh.radius = sp.radius * rng.randf_range(0.58, 0.76)
		secondary_mesh.height = secondary_mesh.radius * 2.0
		secondary_leaf.mesh = secondary_mesh
		var secondary_mat := StandardMaterial3D.new()
		secondary_mat.albedo_color = ml.albedo_color.darkened(rng.randf_range(0.02, 0.08))
		secondary_leaf.material_override = secondary_mat
		secondary_leaf.position = Vector3(
			rng.randf_range(-0.45, 0.45),
			cyl.height + sp.radius * rng.randf_range(0.75, 0.95),
			rng.randf_range(-0.45, 0.45)
		)
		secondary_leaf.scale = Vector3(1.0, 0.68 + rng.randf() * 0.16, 1.0)
		root.add_child(secondary_leaf)
	return root


func _make_grass_clump(rng: RandomNumberGenerator, pos: Vector3) -> Node3D:
	var grass := Node3D.new()
	grass.position = pos
	grass.rotation.y = rng.randf() * TAU
	var blade_count: int = 3 + rng.randi_range(0, 1)
	for i in blade_count:
		var blade := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(
			rng.randf_range(0.08, 0.14),
			rng.randf_range(0.38, 0.78),
			rng.randf_range(0.03, 0.05)
		)
		blade.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18 + rng.randf() * 0.05, 0.46 + rng.randf() * 0.16, 0.12 + rng.randf() * 0.04)
		blade.material_override = mat
		blade.position = Vector3(
			rng.randf_range(-0.16, 0.16),
			box.size.y * 0.5,
			rng.randf_range(-0.16, 0.16)
		)
		blade.rotation_degrees = Vector3(rng.randf_range(-12.0, 12.0), rng.randf() * 180.0, rng.randf_range(-20.0, 20.0))
		grass.add_child(blade)
	return grass


func _make_rock(rng: RandomNumberGenerator, pos: Vector3, min_scale: float = 1.0, max_scale: float = 1.0) -> Node3D:
	var r := MeshInstance3D.new()
	var box := BoxMesh.new()
	var scale_factor: float = rng.randf_range(min_scale, max_scale)
	box.size = Vector3(
		rng.randf_range(0.55, 1.1) * scale_factor,
		rng.randf_range(0.35, 0.65) * scale_factor,
		rng.randf_range(0.55, 1.0) * scale_factor
	)
	r.mesh = box
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.42 + rng.randf() * 0.08, 0.41 + rng.randf() * 0.06, 0.4 + rng.randf() * 0.06)
	r.material_override = m
	r.position = pos + Vector3(0, box.size.y * 0.45, 0)
	r.rotation_degrees = Vector3(rng.randf_range(-4, 4), rng.randf() * 360.0, rng.randf_range(-4, 4))
	var rock := Node3D.new()
	rock.add_child(r)
	return rock
