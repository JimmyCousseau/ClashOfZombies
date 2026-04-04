@tool
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
	DOOR,
	PATH,
}

const BARRACKS_MAX_SOLDIERS: int = 3
const BUILDING_VISUAL_SCENES: Dictionary = {
	BuildingType.TOWN_HALL: preload("res://scenes/building_visuals/town_hall_visual.tscn"),
	BuildingType.GOLD_MINE: preload("res://scenes/building_visuals/gold_mine_visual.tscn"),
	BuildingType.ELIXIR_COLLECTOR: preload("res://scenes/building_visuals/elixir_collector_visual.tscn"),
	BuildingType.CANNON: preload("res://scenes/building_visuals/cannon_visual.tscn"),
	BuildingType.BARRACKS: preload("res://scenes/building_visuals/barracks_visual.tscn"),
	BuildingType.GOLD_STORAGE: preload("res://scenes/building_visuals/gold_storage_visual.tscn"),
	BuildingType.ELIXIR_STORAGE: preload("res://scenes/building_visuals/elixir_storage_visual.tscn"),
	BuildingType.FARM: preload("res://scenes/building_visuals/farm_visual.tscn"),
	BuildingType.DOOR: preload("res://scenes/building_visuals/door_visual.tscn"),
	BuildingType.PATH: preload("res://scenes/building_visuals/path_visual.tscn"),
}
const BUILDING_VISUAL_TOP_Y: Dictionary = {
	BuildingType.TOWN_HALL: 4.2,
	BuildingType.GOLD_MINE: 2.15,
	BuildingType.ELIXIR_COLLECTOR: 3.45,
	BuildingType.CANNON: 1.45,
	BuildingType.BARRACKS: 2.25,
	BuildingType.GOLD_STORAGE: 2.35,
	BuildingType.ELIXIR_STORAGE: 2.65,
	BuildingType.FARM: 1.45,
	BuildingType.DOOR: 1.1,
	BuildingType.PATH: 0.12,
}

@export var building_type: BuildingType = BuildingType.GOLD_MINE
@export var use_generated_visuals: bool = false
var cell: Vector2i = Vector2i.ZERO
var level: int = 1
var max_hp: int = 200
var hp: int = 200
var is_destroyed: bool = false

@onready var mesh_root: Node3D = $MeshRoot
@onready var visual_container: Node3D = $MeshRoot/VisualContainer
@onready var label_3d: Label3D = $MeshRoot/Label3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var cannon_barrel: MeshInstance3D = null


func _ready() -> void:
	_recalculate_stats(true)
	_apply_visual()
	_update_label()
	if Engine.is_editor_hint():
		return
	if building_type == BuildingType.BARRACKS:
		call_deferred("_spawn_initial_garrison")


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
		BuildingType.DOOR:
			return 600
		BuildingType.PATH:
			return 70
		_:
			return 250


func get_max_level() -> int:
	match building_type:
		BuildingType.TOWN_HALL:
			return 4
		BuildingType.GOLD_MINE, BuildingType.ELIXIR_COLLECTOR, BuildingType.CANNON:
			return 4
		BuildingType.BARRACKS, BuildingType.GOLD_STORAGE, BuildingType.ELIXIR_STORAGE, BuildingType.FARM:
			return 3
		BuildingType.DOOR:
			return 1
		BuildingType.PATH:
			return 1
	return 1


func _recalculate_stats(fill_hp: bool = false) -> void:
	var base_hp: int = _default_hp()
	var hp_factor: float = 1.0 + float(maxi(level - 1, 0)) * 0.4
	max_hp = int(round(float(base_hp) * hp_factor))
	if fill_hp:
		hp = max_hp
	else:
		hp = clampi(hp, 0, max_hp)


func _update_label() -> void:
	if label_3d == null:
		return
	label_3d.visible = building_type != BuildingType.PATH
	label_3d.font_size = 52
	label_3d.modulate = Color(1, 0.95, 0.85)
	label_3d.outline_modulate = Color(0.1, 0.08, 0.05, 0.95)
	label_3d.pixel_size = 0.012
	if building_type == BuildingType.PATH:
		return
	if building_type == BuildingType.DOOR and is_destroyed:
		label_3d.text = "%s\nDetruite" % _type_name()
		return
	label_3d.text = "%s N%d\n%d/%d" % [_type_name(), level, hp, max_hp]


func refresh_visual_state() -> void:
	_apply_visual()
	_update_label()


func _type_name() -> String:
	match building_type:
		BuildingType.TOWN_HALL:
			return "Refuge"
		BuildingType.GOLD_MINE:
			return "Scierie"
		BuildingType.ELIXIR_COLLECTOR:
			return "Carrière"
		BuildingType.CANNON:
			return "Tourelle"
		BuildingType.BARRACKS:
			return "Abri"
		BuildingType.GOLD_STORAGE:
			return "Entrepôt"
		BuildingType.ELIXIR_STORAGE:
			return "Forge"
		BuildingType.FARM:
			return "Potager"
		BuildingType.DOOR:
			return "Porte"
		BuildingType.PATH:
			return "Chemin"
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
	cannon_barrel = null
	if visual_container:
		for visual_child in visual_container.get_children():
			visual_child.free()
	var ch: Array = mesh_root.get_children()
	for c in ch:
		if c != label_3d and c != visual_container:
			c.free()


func _apply_visual() -> void:
	_clear_parts()
	mesh_root.position = Vector3.ZERO
	var top_y: float = 2.0
	if not use_generated_visuals and _apply_authored_visual():
		top_y = float(BUILDING_VISUAL_TOP_Y.get(building_type, 2.0))
	else:
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
			BuildingType.DOOR:
				top_y = _build_door()
			BuildingType.PATH:
				top_y = _build_path()
	if level > 1 and building_type != BuildingType.PATH and not is_destroyed:
		_add_level_details(top_y)
	if label_3d:
		label_3d.position = Vector3(0, top_y + 0.35, 0)
	_set_collision_for_type()


func _apply_authored_visual() -> bool:
	if visual_container == null:
		return false
	if building_type == BuildingType.DOOR and is_destroyed:
		return false
	var visual_scene: PackedScene = BUILDING_VISUAL_SCENES.get(building_type, null)
	if visual_scene == null:
		return false
	var visual_instance := visual_scene.instantiate()
	visual_container.add_child(visual_instance)
	if building_type == BuildingType.CANNON:
		cannon_barrel = visual_instance.get_node_or_null("Barrel") as MeshInstance3D
	if building_type == BuildingType.PATH:
		_configure_authored_path_visual(visual_instance)
	return true


func _configure_authored_path_visual(visual_instance: Node) -> void:
	_set_visual_part_visibility(visual_instance, "NorthBase", _has_path_connection(Vector2i(0, -1)))
	_set_visual_part_visibility(visual_instance, "NorthTop", _has_path_connection(Vector2i(0, -1)))
	_set_visual_part_visibility(visual_instance, "SouthBase", _has_path_connection(Vector2i(0, 1)))
	_set_visual_part_visibility(visual_instance, "SouthTop", _has_path_connection(Vector2i(0, 1)))
	_set_visual_part_visibility(visual_instance, "WestBase", _has_path_connection(Vector2i(-1, 0)))
	_set_visual_part_visibility(visual_instance, "WestTop", _has_path_connection(Vector2i(-1, 0)))
	_set_visual_part_visibility(visual_instance, "EastBase", _has_path_connection(Vector2i(1, 0)))
	_set_visual_part_visibility(visual_instance, "EastTop", _has_path_connection(Vector2i(1, 0)))


func _set_visual_part_visibility(root: Node, node_name: String, is_visible: bool) -> void:
	var target := root.get_node_or_null(node_name) as Node3D
	if target:
		target.visible = is_visible


func _set_collision_for_type() -> void:
	var box := BoxShape3D.new()
	collision_shape.disabled = false
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
		BuildingType.DOOR:
			box.size = Vector3(1.5, 2.2, 0.8)
			collision_shape.position = Vector3(0, 1.1, 0)
			collision_shape.disabled = is_destroyed
		BuildingType.PATH:
			box.size = Vector3(1.65, 0.15, 1.65)
			collision_shape.position = Vector3(0, 0.04, 0)
			collision_shape.disabled = true
	collision_shape.shape = box


func _add_level_details(top_y: float) -> void:
	var detail_mat := _mat(Color(0.74, 0.72, 0.62), 0.45, 0.18)
	for i in range(level - 1):
		var x_offset: float = -0.24 + float(i) * 0.28
		_add_box(mesh_root, Vector3(x_offset, top_y - 0.12 + float(i) * 0.08, -0.12), Vector3(0.16, 0.22, 0.16), detail_mat)


func _build_town_hall() -> float:
	var stone := _mat(Color(0.62, 0.6, 0.54))
	var trim := _mat(Color(0.34, 0.38, 0.4))
	var roof := _mat(Color(0.34, 0.24, 0.18))
	var gold := _mat(Color(0.58, 0.58, 0.54), 0.5, 0.2)
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
	var wood := _mat(Color(0.45, 0.31, 0.18))
	var gold := _mat(Color(0.58, 0.42, 0.26), 0.45, 0.2)
	var dark := _mat(Color(0.24, 0.18, 0.12))
	_add_box(mesh_root, Vector3(0, 0.55, 0), Vector3(2.0, 1.05, 2.0), wood)
	_add_box(mesh_root, Vector3(0, 1.35, 0), Vector3(2.2, 0.45, 2.2), gold)
	_add_box(mesh_root, Vector3(0, 1.75, 0.95), Vector3(0.65, 0.35, 0.45), dark)
	_add_cylinder(mesh_root, Vector3(0.85, 1.15, -0.4), 0.35, 0.25, gold, Vector3(90, 0, 35))
	return 2.15


func _build_elixir_collector() -> float:
	var base := _mat(Color(0.32, 0.34, 0.32))
	var tank := _mat(Color(0.46, 0.48, 0.5), 0.4, 0.08)
	var glow := _mat(Color(0.58, 0.6, 0.62), 0.35, 0.08)
	var crystal := _mat(Color(0.38, 0.42, 0.45), 0.25, 0.1)
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
	cannon_barrel = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.28
	cyl.height = 1.35
	cannon_barrel.mesh = cyl
	cannon_barrel.material_override = metal
	cannon_barrel.position = Vector3(0.55, 0.95, 0)
	cannon_barrel.rotation_degrees = Vector3(0, 0, 82)
	mesh_root.add_child(cannon_barrel)
	_add_box(mesh_root, Vector3(-0.15, 1.05, 0), Vector3(0.45, 0.35, 0.35), metal)
	return 1.45


func _build_barracks() -> float:
	var wall := _mat(Color(0.48, 0.36, 0.24))
	var roof := _mat(Color(0.28, 0.22, 0.18))
	var door := _mat(Color(0.35, 0.22, 0.12))
	_add_box(mesh_root, Vector3(0, 0.75, 0), Vector3(3.0, 1.45, 2.1), wall)
	_add_box(mesh_root, Vector3(0, 1.65, 0), Vector3(3.15, 0.4, 2.25), roof)
	_add_box(mesh_root, Vector3(0, 0.75, 1.08), Vector3(0.85, 1.1, 0.2), door)
	_add_box(mesh_root, Vector3(-1.1, 1.95, 0), Vector3(0.5, 0.25, 0.5), roof)
	_add_box(mesh_root, Vector3(1.1, 1.95, 0), Vector3(0.5, 0.25, 0.5), roof)
	return 2.25


func _build_gold_storage() -> float:
	var stone := _mat(Color(0.42, 0.36, 0.24))
	var gold := _mat(Color(0.22, 0.24, 0.2), 0.42, 0.12)
	var dark := _mat(Color(0.18, 0.16, 0.12))
	_add_box(mesh_root, Vector3(0, 0.55, 0), Vector3(2.2, 1.05, 2.2), stone)
	_add_box(mesh_root, Vector3(0, 1.35, 0), Vector3(2.35, 0.35, 2.35), dark)
	_add_box(mesh_root, Vector3(0, 1.75, 0), Vector3(1.6, 0.45, 1.6), gold)
	_add_cylinder(mesh_root, Vector3(0.75, 2.05, 0.75), 0.18, 0.35, gold, Vector3(0, 0, 0))
	_add_cylinder(mesh_root, Vector3(-0.65, 2.05, -0.55), 0.16, 0.3, gold, Vector3(0, 0, 0))
	return 2.35


func _build_elixir_storage() -> float:
	var stone := _mat(Color(0.35, 0.36, 0.38))
	var purp := _mat(Color(0.24, 0.26, 0.28), 0.34, 0.18)
	var glow := _mat(Color(0.7, 0.34, 0.18), 0.28, 0.16)
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


func _build_door() -> float:
	if is_destroyed:
		var wreck_wood := _mat(Color(0.24, 0.18, 0.14))
		var wreck_metal := _mat(Color(0.22, 0.22, 0.24), 0.35, 0.55)
		_add_box(mesh_root, Vector3(-0.42, 0.52, 0), Vector3(0.22, 1.0, 0.28), wreck_wood)
		_add_box(mesh_root, Vector3(0.42, 0.52, 0), Vector3(0.22, 1.0, 0.28), wreck_wood)
		_add_box(mesh_root, Vector3(0.0, 0.08, 0.0), Vector3(1.1, 0.12, 0.48), wreck_metal)
		_add_box(mesh_root, Vector3(0.16, 0.2, 0.0), Vector3(0.55, 0.12, 0.24), wreck_wood)
		return 0.95
	var wood := _mat(Color(0.35, 0.22, 0.1))
	var metal := _mat(Color(0.18, 0.18, 0.2), 0.3, 0.6)
	var height_bonus: float = float(level - 1) * 0.08
	_add_box(mesh_root, Vector3(0, 0.15, 0), Vector3(1.5, 0.3, 0.8), metal)
	_add_box(mesh_root, Vector3(0, 0.65 + height_bonus * 0.3, 0), Vector3(1.2, 1.0 + height_bonus, 0.6), wood)
	_add_cylinder(mesh_root, Vector3(0.65, 0.65, 0), 0.08, 0.15, metal, Vector3(0, 0, 90))
	return 1.1 + height_bonus


func _build_path() -> float:
	var stone := _mat(Color(0.62, 0.62, 0.58), 0.96, 0.02)
	var dust := _mat(Color(0.76, 0.74, 0.68), 0.98, 0.0)
	var core_base := Vector3(1.1, 0.08, 1.1)
	var core_top := Vector3(0.82, 0.02, 0.82)
	var arm_offset: float = 0.63
	var arm_length: float = 1.26
	var arm_width: float = 1.02
	var arm_top_length: float = 1.08
	var arm_top_width: float = 0.74
	_add_box(mesh_root, Vector3(0, 0.03, 0), core_base, stone)
	_add_box(mesh_root, Vector3(0, 0.08, 0), core_top, dust)
	var north: bool = _has_path_connection(Vector2i(0, -1))
	var south: bool = _has_path_connection(Vector2i(0, 1))
	var west: bool = _has_path_connection(Vector2i(-1, 0))
	var east: bool = _has_path_connection(Vector2i(1, 0))
	if north:
		_add_box(mesh_root, Vector3(0, 0.03, -arm_offset), Vector3(arm_width, 0.08, arm_length), stone)
		_add_box(mesh_root, Vector3(0, 0.08, -arm_offset), Vector3(arm_top_width, 0.02, arm_top_length), dust)
	if south:
		_add_box(mesh_root, Vector3(0, 0.03, arm_offset), Vector3(arm_width, 0.08, arm_length), stone)
		_add_box(mesh_root, Vector3(0, 0.08, arm_offset), Vector3(arm_top_width, 0.02, arm_top_length), dust)
	if west:
		_add_box(mesh_root, Vector3(-arm_offset, 0.03, 0), Vector3(arm_length, 0.08, arm_width), stone)
		_add_box(mesh_root, Vector3(-arm_offset, 0.08, 0), Vector3(arm_top_length, 0.02, arm_top_width), dust)
	if east:
		_add_box(mesh_root, Vector3(arm_offset, 0.03, 0), Vector3(arm_length, 0.08, arm_width), stone)
		_add_box(mesh_root, Vector3(arm_offset, 0.08, 0), Vector3(arm_top_length, 0.02, arm_top_width), dust)
	return 0.12


func _has_path_connection(offset: Vector2i) -> bool:
	if building_type != BuildingType.PATH:
		return false
	var parent_node := get_parent()
	if parent_node and parent_node.has_method("is_path_connected_to_neighbor"):
		return bool(parent_node.call("is_path_connected_to_neighbor", cell, offset))
	return false


func take_damage(amount: int) -> void:
	if is_destroyed:
		return
	hp = maxi(0, hp - amount)
	_update_label()
	if hp <= 0:
		if building_type == BuildingType.DOOR and is_main_village_door():
			_break_main_door()
		else:
			_destroyed()


func get_attack_radius() -> float:
	if building_type == BuildingType.PATH:
		return 0.35
	if collision_shape == null or collision_shape.shape == null:
		return 0.75
	if collision_shape.shape is BoxShape3D:
		var box := collision_shape.shape as BoxShape3D
		return maxf(box.size.x, box.size.z) * 0.75
	return 0.75


func get_blocking_half_extents() -> Vector2:
	if building_type == BuildingType.PATH:
		return Vector2.ZERO
	if collision_shape == null or collision_shape.shape == null:
		return Vector2(0.75, 0.75)
	if collision_shape.shape is BoxShape3D:
		var box := collision_shape.shape as BoxShape3D
		return Vector2(box.size.x, box.size.z) * 0.5
	return Vector2(0.75, 0.75)


func repair(amount: int) -> int:
	if is_destroyed:
		return 0
	var old_hp := hp
	hp = mini(max_hp, hp + amount)
	var healed := hp - old_hp
	_update_label()
	return healed


func get_repair_cost(amount: int) -> Dictionary:
	return GameState.get_repair_cost(building_type, amount)


func can_upgrade() -> bool:
	return not is_destroyed and level < get_max_level()


func get_upgrade_cost() -> Dictionary:
	return GameState.get_upgrade_cost(building_type, level)


func upgrade() -> bool:
	if not can_upgrade():
		return false
	var cost: Dictionary = get_upgrade_cost()
	if not GameState.spend(cost):
		return false
	level += 1
	_recalculate_stats(true)
	refresh_visual_state()
	if get_parent() and get_parent().has_method("notify_building_upgraded"):
		get_parent().call("notify_building_upgraded", self)
	return true


func get_effect_summary() -> String:
	match building_type:
		BuildingType.GOLD_MINE:
			return "Production : %d bois / cycle" % int(get_production_pack().get("wood", 0))
		BuildingType.ELIXIR_COLLECTOR:
			return "Production : %d pierre / cycle" % int(get_production_pack().get("stone", 0))
		BuildingType.FARM:
			return "Production : %d nourriture / cycle" % int(get_production_pack().get("food", 0))
		BuildingType.ELIXIR_STORAGE, BuildingType.GOLD_STORAGE:
			return "Stock : %s" % GameState.format_resource_pack(get_storage_bonus_pack(), false)
		BuildingType.CANNON:
			return "Degats %d | Portee %.1f" % [get_cannon_damage(), get_cannon_range()]
		BuildingType.BARRACKS:
			return "Garnison max : %d" % get_barracks_max_soldiers()
		BuildingType.TOWN_HALL:
			return "Solidite renforcee du refuge."
		BuildingType.DOOR:
			return "Controle l'entree du village."
		BuildingType.PATH:
			return "Route connectee aux allees voisines."
	return ""


func get_upgrade_summary() -> String:
	if not can_upgrade():
		return "Niveau maximum atteint."
	match building_type:
		BuildingType.GOLD_MINE:
			return "Plus de bois par cycle."
		BuildingType.ELIXIR_COLLECTOR:
			return "Plus de pierre par cycle."
		BuildingType.FARM:
			return "Plus de nourriture par cycle."
		BuildingType.GOLD_STORAGE, BuildingType.ELIXIR_STORAGE:
			return "Capacite de stockage accrue."
		BuildingType.CANNON:
			return "Plus de portee et de degats."
		BuildingType.BARRACKS:
			return "Garnison maximale augmentee."
		BuildingType.TOWN_HALL:
			return "Refuge plus resistant."
	return "Effets ameliores."


func get_production_pack() -> Dictionary:
	var base_pack: Dictionary = GameState.PRODUCTION.get(building_type, {})
	if base_pack.is_empty() or is_destroyed:
		return {}
	var factor: float = 1.0 + float(maxi(level - 1, 0)) * 0.55
	var pack: Dictionary = {}
	for key in base_pack.keys():
		pack[String(key)] = int(round(float(base_pack[key]) * factor))
	return pack


func get_storage_bonus_pack() -> Dictionary:
	if is_destroyed:
		return {}
	var base_pack: Dictionary = GameState.STORAGE_CAP_BONUS.get(building_type, {})
	if base_pack.is_empty():
		return {}
	var factor: float = 1.0 + float(maxi(level - 1, 0)) * 0.6
	var pack: Dictionary = {}
	for key in base_pack.keys():
		pack[String(key)] = int(round(float(base_pack[key]) * factor))
	return pack


func get_cannon_range() -> float:
	return 12.0 + float(maxi(level - 1, 0)) * 1.5


func get_cannon_damage() -> int:
	return 35 + maxi(level - 1, 0) * 14


func get_cannon_cooldown() -> float:
	return maxf(0.45, 0.9 - float(maxi(level - 1, 0)) * 0.1)


func can_player_destroy() -> bool:
	if building_type == BuildingType.TOWN_HALL:
		return false
	if building_type == BuildingType.DOOR and is_main_village_door():
		return false
	return true


func is_main_village_door() -> bool:
	return building_type == BuildingType.DOOR and global_position.distance_to(GameState.get_door_position()) <= 0.25


func get_destroy_refund() -> Dictionary:
	return GameState.get_build_refund(building_type)


func get_barracks_max_soldiers() -> int:
	return BARRACKS_MAX_SOLDIERS + maxi(level - 1, 0)


func get_barracks_active_soldier_count() -> int:
	if building_type != BuildingType.BARRACKS:
		return 0
	var allies: Array = get_tree().get_nodes_in_group("allies")
	var alive_count: int = 0
	for ally in allies:
		if ally is Barbarian and is_instance_valid(ally):
			var barbarian := ally as Barbarian
			if barbarian.source_barracks_id == get_instance_id():
				alive_count += 1
	return alive_count


func get_barracks_missing_soldier_count() -> int:
	return maxi(0, BARRACKS_MAX_SOLDIERS - get_barracks_active_soldier_count())


func get_barracks_refill_cost() -> Dictionary:
	return GameState.multiply_resource_pack(GameState.TRAIN_BARBARIAN_COST, get_barracks_missing_soldier_count())


func refill_barracks() -> bool:
	if building_type != BuildingType.BARRACKS:
		return false
	var missing: int = get_barracks_missing_soldier_count()
	if missing <= 0:
		return false
	var cost: Dictionary = get_barracks_refill_cost()
	if not GameState.spend(cost):
		return false
	_spawn_barracks_soldiers(missing)
	return true


func _exit_tree() -> void:
	var p := get_parent()
	if p and p.has_method("notify_building_removed"):
		p.notify_building_removed(cell, self)


func _destroyed() -> void:
	match building_type:
		BuildingType.TOWN_HALL:
			GameState.game_over.emit()
		BuildingType.DOOR:
			GameState.door_destroyed.emit()
		_:
			pass
	queue_free()


func _break_main_door() -> void:
	is_destroyed = true
	hp = 0
	refresh_visual_state()
	var parent_node := get_parent()
	if parent_node and parent_node.has_method("notify_main_door_state_changed"):
		parent_node.call("notify_main_door_state_changed")
	GameState.door_destroyed.emit()


func rebuild_main_door() -> bool:
	if building_type != BuildingType.DOOR or not is_main_village_door() or not is_destroyed:
		return false
	var rebuild_cost: Dictionary = GameState.BUILD_COST.get(BuildingType.DOOR, {})
	if not GameState.spend(rebuild_cost):
		return false
	is_destroyed = false
	_recalculate_stats(true)
	refresh_visual_state()
	var parent_node := get_parent()
	if parent_node and parent_node.has_method("notify_main_door_state_changed"):
		parent_node.call("notify_main_door_state_changed")
	return true


func _spawn_initial_garrison() -> void:
	_spawn_barracks_soldiers(get_barracks_max_soldiers())


func _spawn_barracks_soldiers(count: int) -> void:
	if count <= 0:
		return
	var allies: Node3D = get_tree().get_first_node_in_group("ally_units")
	if allies == null:
		return
	var spawn_center: Vector3 = GameState.get_outside_spawn_from_origin(global_position)
	for i in count:
		var u: Barbarian = preload("res://scenes/barbarian.tscn").instantiate()
		u.allegiance = Unit.Allegiance.PLAYER
		u.hp = 100
		u.max_hp = 100
		u.move_speed = 5.0
		u.source_barracks_id = get_instance_id()
		u.set_guard_home(spawn_center)
		var offset: Vector3 = Vector3(randf_range(-2.4, 2.4), 0.0, randf_range(-2.4, 2.4))
		u.global_position = spawn_center + offset
		allies.add_child(u)
