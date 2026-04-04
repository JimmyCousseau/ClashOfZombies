extends Node3D
class_name GridPreview

## Aperçu visuel semi-transparent lors du placement d'un bâtiment.

const TOWER_PREVIEW_POSITIONS: Array[Vector3] = [
	Vector3(-14.575, 1.5, -14.575),
	Vector3( 14.575, 1.5, -14.575),
	Vector3(-14.575, 1.5,  14.575),
	Vector3( 14.575, 1.5,  14.575),
	Vector3(-1.5,    1.5,  14.575),
	Vector3( 1.5,    1.5,  14.575),
]

var _grid_map: VillageGridMap
var _preview_root: Node3D = null


func setup(grid_map: VillageGridMap) -> void:
	_grid_map = grid_map


func show_for(building_type: int) -> void:
	hide()
	_preview_root = Node3D.new()
	_preview_root.name = "_GridPreview"
	add_child(_preview_root)

	if building_type == VillageBuilding.BuildingType.GUARD_TOWER:
		_show_tower_preview()
	else:
		_show_grid_preview()


func hide_preview() -> void:
	if _preview_root and is_instance_valid(_preview_root):
		_preview_root.queue_free()
	_preview_root = null


func _show_grid_preview() -> void:
	for x in range(GameState.GRID_SIZE.x):
		for y in range(GameState.GRID_SIZE.y):
			var cell := Vector2i(x, y)
			if (cell.x + cell.y) % 2 == 0:
				_create_cell_visual(_grid_map.cell_to_world(cell))


func _show_tower_preview() -> void:
	for pos in TOWER_PREVIEW_POSITIONS:
		_create_tower_visual(pos)


func _create_cell_visual(world_pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(GameState.CELL_SIZE - 0.1, 0.05, GameState.CELL_SIZE - 0.1)
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.2, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = world_pos + Vector3(0, 0.1, 0)
	_preview_root.add_child(mi)


func _create_tower_visual(world_pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.5, 0.2, 1.5)
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 0.9, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = world_pos + Vector3(0, 0.3, 0)
	_preview_root.add_child(mi)
