## Grid preview system for Village
## Shows valid placement cells with checkerboard pattern

extends Node


## Show grid preview for building type
func show_grid_preview(village: Node3D, building_type: int) -> void:
	village._hide_grid_preview()
	village._grid_preview_root = Node3D.new()
	village._grid_preview_root.name = "_GridPreview"
	village.add_child(village._grid_preview_root)
	
	if building_type == VillageBuilding.BuildingType.GUARD_TOWER:
		show_tower_preview(village)
	else:
		show_general_preview(village, building_type)


## Show tower preview (6 positions)
func show_tower_preview(village: Node3D) -> void:
	var tower_positions: Array[Vector3] = [
		Vector3(-14.575, 0, -14.575),
		Vector3(14.575, 0, -14.575),
		Vector3(-14.575, 0, 14.575),
		Vector3(14.575, 0, 14.575),
		Vector3(-1.5, 0, 14.575),
		Vector3(1.5, 0, 14.575),
	]
	
	for pos in tower_positions:
		create_tower_preview_visual(village, pos)


## Show general preview (checkerboard)
func show_general_preview(village: Node3D, building_type: int) -> void:
	var checkerboard_offset: int = 0
	
	for x in range(GameState.GRID_SIZE.x):
		for y in range(GameState.GRID_SIZE.y):
			var cell := Vector2i(x, y)
			if (cell.x + cell.y + checkerboard_offset) % 2 == 0:
				create_grid_cell_visual(village, cell)


## Hide grid preview
func hide_grid_preview(village: Node3D) -> void:
	if village._grid_preview_root and is_instance_valid(village._grid_preview_root):
		village._grid_preview_root.queue_free()
	village._grid_preview_root = null
	village._grid_preview_cells.clear()


## Create visual for grid cell
func create_grid_cell_visual(village: Node3D, cell: Vector2i) -> void:
	var world_pos: Vector3 = village._cell_to_world(cell)
	
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(GameState.CELL_SIZE - 0.1, 0.05, GameState.CELL_SIZE - 0.1)
	mesh_instance.mesh = box_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.2, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	
	mesh_instance.position = world_pos + Vector3(0, 0.1, 0)
	village._grid_preview_root.add_child(mesh_instance)
	village._grid_preview_cells[cell] = mesh_instance


## Create visual for tower position
func create_tower_preview_visual(village: Node3D, world_pos: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(1.5, 0.2, 1.5)
	mesh_instance.mesh = box_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 0.9, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	
	mesh_instance.position = world_pos + Vector3(0, 0.3, 0)
	village._grid_preview_root.add_child(mesh_instance)
