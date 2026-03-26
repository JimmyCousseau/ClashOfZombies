class_name VillageBuilding
extends StaticBody3D

enum BuildingType {
	TOWN_HALL,
	GOLD_MINE,
	ELIXIR_COLLECTOR,
	CANNON,
	BARRACKS,
	GOLD_STORAGE,
	ELIXIR_STORAGE,
	FARM,
}

@export var building_type: BuildingType = BuildingType.GOLD_MINE
var cell: Vector2i = Vector2i.ZERO
var max_hp: int = 200
var hp: int = 200

@onready var mesh_root: Node3D = $MeshRoot
@onready var label_3d: Label3D = $MeshRoot/Label3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	hp = _default_hp()
	max_hp = hp
	_apply_visual()
	if label_3d:
		label_3d.text = "%s\n%d" % [_type_name(), hp]
		label_3d.font_size = 52
		label_3d.modulate = Color(1, 0.95, 0.85)
		label_3d.outline_modulate = Color(0.1, 0.08, 0.05, 0.95)
		label_3d.pixel_size = 0.012


func _default_hp() -> int:
	match building_type:
		BuildingType.TOWN_HALL:
			return 800
		BuildingType.CANNON:
			return 350
		BuildingType.BARRACKS:
			return 400
		BuildingType.GOLD_STORAGE, BuildingType.ELIXIR_STORAGE:
			return 320
		BuildingType.FARM:
			return 220
		_:
			return 250


func _type_name() -> String:
	match building_type:
		BuildingType.TOWN_HALL:
			return "HDV"
		BuildingType.GOLD_MINE:
			return "Mine"
		BuildingType.ELIXIR_COLLECTOR:
			return "Élexir"
		BuildingType.CANNON:
			return "Canon"
		BuildingType.BARRACKS:
			return "Caserne"
		BuildingType.GOLD_STORAGE:
			return "Entrepôt"
		BuildingType.ELIXIR_STORAGE:
			return "Réservoir"
		BuildingType.FARM:
			return "Ferme"
	return "?"


func _mat(c: Color, roughness: float = 0.82, metallic: float = 0.04) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = roughness
	m.metallic = metallic
	return m


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


func _add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)


func _clear_parts() -> void:
	var ch: Array = mesh_root.get_children()
	for c in ch:
		if c != label_3d:
			c.free()


func _apply_visual() -> void:
	_clear_parts()
	mesh_root.position = Vector3.ZERO
	var top_y: float = 2.0
	match building_type:
		BuildingType.TOWN_HALL:
			top_y = _build_town_hall()
		BuildingType.GOLD_MINE:
			top_y = _build_gold_mine()
		BuildingType.ELIXIR_COLLECTOR:
			top_y = _build_elixir_collector()
		BuildingType.CANNON:
			top_y = _build_cannon()
		BuildingType.BARRACKS:
			top_y = _build_barracks()
		BuildingType.GOLD_STORAGE:
			top_y = _build_gold_storage()
		BuildingType.ELIXIR_STORAGE:
			top_y = _build_elixir_storage()
		BuildingType.FARM:
			top_y = _build_farm()
	if label_3d:
		label_3d.position = Vector3(0, top_y + 0.35, 0)
	_set_collision_for_type()


func _set_collision_for_type() -> void:
	var box := BoxShape3D.new()
	match building_type:
		BuildingType.TOWN_HALL:
			box.size = Vector3(3.0, 3.6, 3.0)
			collision_shape.position = Vector3(0, 1.75, 0)
		BuildingType.GOLD_MINE:
			box.size = Vector3(2.4, 2.4, 2.4)
			collision_shape.position = Vector3(0, 1.15, 0)
		BuildingType.ELIXIR_COLLECTOR:
			box.size = Vector3(2.3, 2.8, 2.3)
			collision_shape.position = Vector3(0, 1.35, 0)
		BuildingType.CANNON:
			box.size = Vector3(2.2, 1.6, 2.2)
			collision_shape.position = Vector3(0, 0.75, 0)
		BuildingType.BARRACKS:
			box.size = Vector3(3.2, 2.2, 2.2)
			collision_shape.position = Vector3(0, 1.05, 0)
		BuildingType.GOLD_STORAGE:
			box.size = Vector3(2.5, 2.3, 2.5)
			collision_shape.position = Vector3(0, 1.1, 0)
		BuildingType.ELIXIR_STORAGE:
			box.size = Vector3(2.5, 2.5, 2.5)
			collision_shape.position = Vector3(0, 1.2, 0)
		BuildingType.FARM:
			box.size = Vector3(2.8, 1.4, 2.8)
			collision_shape.position = Vector3(0, 0.65, 0)
	collision_shape.shape = box


func _build_town_hall() -> float:
	var stone := _mat(Color(0.72, 0.68, 0.58))
	var trim := _mat(Color(0.45, 0.52, 0.72))
	var roof := _mat(Color(0.82, 0.28, 0.18))
	var gold := _mat(Color(0.95, 0.78, 0.22), 0.5, 0.35)
	_add_box(mesh_root, Vector3(0, 0.2, 0), Vector3(2.8, 0.35, 2.8), stone)
	_add_box(mesh_root, Vector3(0, 1.05, 0), Vector3(2.35, 1.5, 2.35), stone)
	_add_box(mesh_root, Vector3(0, 1.95, 0), Vector3(2.55, 0.45, 2.55), roof)
	_add_box(mesh_root, Vector3(-0.75, 0.95, 1.22), Vector3(0.55, 0.85, 0.35), trim)
	_add_box(mesh_root, Vector3(0.75, 0.95, 1.22), Vector3(0.55, 0.85, 0.35), trim)
	_add_box(mesh_root, Vector3(0, 2.55, 0), Vector3(1.15, 1.1, 1.15), stone)
	_add_box(mesh_root, Vector3(0, 3.35, 0), Vector3(1.35, 0.35, 1.35), roof)
	_add_cylinder(mesh_root, Vector3(0, 3.75, 0), 0.12, 0.9, gold, Vector3(0, 0, 0))
	return 4.2


func _build_gold_mine() -> float:
	var wood := _mat(Color(0.48, 0.32, 0.18))
	var gold := _mat(Color(0.92, 0.75, 0.2), 0.45, 0.55)
	var dark := _mat(Color(0.28, 0.22, 0.14))
	_add_box(mesh_root, Vector3(0, 0.55, 0), Vector3(2.0, 1.05, 2.0), wood)
	_add_box(mesh_root, Vector3(0, 1.35, 0), Vector3(2.2, 0.45, 2.2), gold)
	_add_box(mesh_root, Vector3(0, 1.75, 0.95), Vector3(0.65, 0.35, 0.45), dark)
	_add_cylinder(mesh_root, Vector3(0.85, 1.15, -0.4), 0.35, 0.25, gold, Vector3(90, 0, 35))
	return 2.15


func _build_elixir_collector() -> float:
	var base := _mat(Color(0.32, 0.22, 0.42))
	var tank := _mat(Color(0.55, 0.22, 0.85), 0.35, 0.1)
	var glow := _mat(Color(0.75, 0.45, 0.95), 0.25, 0.15)
	var crystal := _mat(Color(0.55, 0.95, 0.85), 0.15, 0.4)
	_add_box(mesh_root, Vector3(0, 0.35, 0), Vector3(1.9, 0.65, 1.9), base)
	_add_cylinder(mesh_root, Vector3(0, 1.25, 0), 0.75, 1.35, tank)
	_add_cylinder(mesh_root, Vector3(0, 2.35, 0), 0.55, 0.85, glow)
	_add_cylinder(mesh_root, Vector3(0.35, 2.95, 0.2), 0.18, 0.95, crystal, Vector3(15, 0, 8))
	_add_cylinder(mesh_root, Vector3(-0.25, 3.05, -0.15), 0.15, 0.75, crystal, Vector3(-12, 0, -5))
	return 3.45


func _build_cannon() -> float:
	var stone := _mat(Color(0.55, 0.54, 0.5))
	var metal := _mat(Color(0.22, 0.23, 0.26), 0.35, 0.65)
	_add_cylinder(mesh_root, Vector3(0, 0.35, 0), 0.95, 0.65, stone)
	_add_cylinder(mesh_root, Vector3(0, 0.85, 0), 0.35, 0.45, stone)
	var barrel := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.28
	cyl.height = 1.35
	barrel.mesh = cyl
	barrel.material_override = metal
	barrel.position = Vector3(0.55, 0.95, 0)
	barrel.rotation_degrees = Vector3(0, 0, 82)
	mesh_root.add_child(barrel)
	_add_box(mesh_root, Vector3(-0.15, 1.05, 0), Vector3(0.45, 0.35, 0.35), metal)
	return 1.45


func _build_barracks() -> float:
	var wall := _mat(Color(0.62, 0.45, 0.3))
	var roof := _mat(Color(0.78, 0.32, 0.18))
	var door := _mat(Color(0.35, 0.22, 0.12))
	_add_box(mesh_root, Vector3(0, 0.75, 0), Vector3(3.0, 1.45, 2.1), wall)
	_add_box(mesh_root, Vector3(0, 1.65, 0), Vector3(3.15, 0.4, 2.25), roof)
	_add_box(mesh_root, Vector3(0, 0.75, 1.08), Vector3(0.85, 1.1, 0.2), door)
	_add_box(mesh_root, Vector3(-1.1, 1.95, 0), Vector3(0.5, 0.25, 0.5), roof)
	_add_box(mesh_root, Vector3(1.1, 1.95, 0), Vector3(0.5, 0.25, 0.5), roof)
	return 2.25


func _build_gold_storage() -> float:
	var stone := _mat(Color(0.62, 0.58, 0.52))
	var gold := _mat(Color(0.92, 0.78, 0.22), 0.42, 0.45)
	var dark := _mat(Color(0.35, 0.3, 0.22))
	_add_box(mesh_root, Vector3(0, 0.55, 0), Vector3(2.2, 1.05, 2.2), stone)
	_add_box(mesh_root, Vector3(0, 1.35, 0), Vector3(2.35, 0.35, 2.35), dark)
	_add_box(mesh_root, Vector3(0, 1.75, 0), Vector3(1.6, 0.45, 1.6), gold)
	_add_cylinder(mesh_root, Vector3(0.75, 2.05, 0.75), 0.18, 0.35, gold, Vector3(0, 0, 0))
	_add_cylinder(mesh_root, Vector3(-0.65, 2.05, -0.55), 0.16, 0.3, gold, Vector3(0, 0, 0))
	return 2.35


func _build_elixir_storage() -> float:
	var stone := _mat(Color(0.45, 0.38, 0.55))
	var purp := _mat(Color(0.48, 0.2, 0.78), 0.28, 0.12)
	var glow := _mat(Color(0.62, 0.35, 0.95), 0.22, 0.2)
	_add_box(mesh_root, Vector3(0, 0.5, 0), Vector3(2.1, 0.95, 2.1), stone)
	_add_cylinder(mesh_root, Vector3(-0.45, 1.35, 0.2), 0.55, 1.1, purp)
	_add_cylinder(mesh_root, Vector3(0.5, 1.45, -0.25), 0.48, 0.95, glow)
	_add_cylinder(mesh_root, Vector3(0, 2.35, 0), 0.35, 0.55, glow)
	return 2.65


func _build_farm() -> float:
	var wood := _mat(Color(0.42, 0.28, 0.14))
	var straw := _mat(Color(0.82, 0.68, 0.28))
	var crop := _mat(Color(0.28, 0.62, 0.22))
	var soil := _mat(Color(0.4, 0.3, 0.18))
	_add_box(mesh_root, Vector3(0, 0.12, 0), Vector3(2.6, 0.2, 2.6), soil)
	_add_box(mesh_root, Vector3(0, 0.55, 0), Vector3(2.0, 0.85, 1.6), wood)
	_add_box(mesh_root, Vector3(0, 1.1, 0), Vector3(2.15, 0.35, 1.75), straw)
	_add_box(mesh_root, Vector3(0, 0.45, 0.95), Vector3(1.4, 0.35, 0.25), crop)
	_add_cylinder(mesh_root, Vector3(-0.7, 0.75, -0.5), 0.12, 0.45, crop, Vector3(8, 0, 0))
	_add_cylinder(mesh_root, Vector3(0.65, 0.75, -0.45), 0.12, 0.45, crop, Vector3(-6, 0, 0))
	return 1.45


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	if label_3d:
		label_3d.text = "%s\n%d" % [_type_name(), hp]
	if hp <= 0:
		_destroyed()


func _exit_tree() -> void:
	match building_type:
		BuildingType.GOLD_STORAGE:
			GameState.remove_storage_bonus(true, false)
		BuildingType.ELIXIR_STORAGE:
			GameState.remove_storage_bonus(false, true)
		_:
			pass
	var p := get_parent()
	if p and p.has_method("notify_building_removed"):
		p.notify_building_removed(cell, self)


func _destroyed() -> void:
	if building_type == BuildingType.TOWN_HALL:
		GameState.game_over.emit()
	queue_free()
