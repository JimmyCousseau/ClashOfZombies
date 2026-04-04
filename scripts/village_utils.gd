## Village utilities
## Grid conversion, door utilities, path helpers

extends Node


## Convert world position to grid cell
func world_to_cell(village: Node3D, world_pos: Vector3) -> Vector2i:
	var cell_size: float = GameState.CELL_SIZE
	var half_extent: float = GameState.get_inner_half_extent()
	var local_x: float = world_pos.x + half_extent
	var local_z: float = world_pos.z + half_extent
	var cell_x: int = int(local_x / cell_size)
	var cell_z: int = int(local_z / cell_size)
	return Vector2i(cell_x, cell_z)


## Convert grid cell to world position
func cell_to_world(village: Node3D, cell: Vector2i) -> Vector3:
	var cell_size: float = GameState.CELL_SIZE
	var half_extent: float = GameState.get_inner_half_extent()
	var world_x: float = float(cell.x) * cell_size - half_extent + cell_size * 0.5
	var world_z: float = float(cell.y) * cell_size - half_extent + cell_size * 0.5
	return Vector3(world_x, 0.0, world_z)


## Get main door building
func get_main_door(village: Node3D) -> VillageBuilding:
	for building in village._buildings:
		if is_instance_valid(building) and building.building_type == VillageBuilding.BuildingType.DOOR:
			if building.is_main_village_door():
				return building
	return null


## Get main door connection cell
func get_main_door_connection_cell(village: Node3D) -> Vector2i:
	return world_to_cell(village, GameState.get_door_inside_entry())


## Check if path connects to neighbor
func is_path_connected_to_neighbor(village: Node3D, path_cell: Vector2i, offset: Vector2i) -> bool:
	var neighbor_cell: Vector2i = path_cell + offset
	var neighbor := village._grid.get(neighbor_cell, null) as VillageBuilding
	if neighbor and is_instance_valid(neighbor) and neighbor.building_type == VillageBuilding.BuildingType.PATH:
		return true
	if offset == Vector2i(0, 1) and path_cell == get_main_door_connection_cell(village):
		var main_door: VillageBuilding = get_main_door(village)
		return main_door != null and is_instance_valid(main_door)
	return false


## Refresh all path visuals
func refresh_all_path_visuals(village: Node3D) -> void:
	for building in village._buildings:
		if is_instance_valid(building) and building.building_type == VillageBuilding.BuildingType.PATH:
			building.refresh_visual_state()


## Refresh path visuals near cell
func refresh_path_visuals_near(village: Node3D, cell: Vector2i) -> void:
	var cells: Array[Vector2i] = [
		cell,
		cell + Vector2i(0, -1),
		cell + Vector2i(0, 1),
		cell + Vector2i(-1, 0),
		cell + Vector2i(1, 0),
		get_main_door_connection_cell(village),
	]
	for target_cell in cells:
		var building := village._grid.get(target_cell, null) as VillageBuilding
		if building and is_instance_valid(building) and building.building_type == VillageBuilding.BuildingType.PATH:
			building.refresh_visual_state()


## Check if town hall exists
func has_town_hall(village: Node3D) -> bool:
	for building in village._buildings:
		if is_instance_valid(building) and building.building_type == VillageBuilding.BuildingType.TOWN_HALL:
			return true
	return false


## Place starter town hall
func place_starter_town_hall(village: Node3D) -> void:
	var center := Vector2i(GameState.GRID_SIZE.x / 2, GameState.GRID_SIZE.y / 2)
	var placement = load("res://scripts/village_placement.gd").new()
	placement.spawn_building_at_cell(village, VillageBuilding.BuildingType.TOWN_HALL, center, true)


## Place starter door
func place_starter_door(village: Node3D) -> void:
	var BUILDING_SCENE = preload("res://scenes/building.tscn")
	var b: VillageBuilding = BUILDING_SCENE.instantiate()
	b.building_type = VillageBuilding.BuildingType.DOOR
	b.cell = Vector2i.ZERO
	b.position = GameState.get_door_position()
	village.add_child(b)
	village._buildings.append(b)
	GameState.invalidate_navigation()
