## Building placement system for Village
## Handles placement validation, tower snapping, cell spawning

extends Node


## Set build mode (activate building placement)
func set_build_mode(village: Node3D, building_type: int) -> void:
	village._build_mode = building_type
	village._show_grid_preview(building_type)


## Clear build mode (deactivate building placement)
func clear_build_mode(village: Node3D) -> void:
	village._build_mode = -1
	village._hide_grid_preview()


## Try to place building at world position
func try_place_at_world(village: Node3D, hit: Vector3) -> bool:
	if village._build_mode < 0:
		return false
	
	if village._build_mode == VillageBuilding.BuildingType.GUARD_TOWER:
		return try_place_tower_at_world(village, hit)
	
	var cell := village._world_to_cell(hit)
	if cell.x < 0 or cell.y < 0 or cell.x >= GameState.GRID_SIZE.x or cell.y >= GameState.GRID_SIZE.y:
		return false
	return spawn_building_at_cell(village, village._build_mode, cell, false)


## Try to place tower at world position
func try_place_tower_at_world(village: Node3D, hit: Vector3) -> bool:
	var tower_positions: Array[Vector3] = [
		Vector3(-14.575, 0, -14.575),
		Vector3(14.575, 0, -14.575),
		Vector3(-14.575, 0, 14.575),
		Vector3(14.575, 0, 14.575),
		Vector3(-1.5, 0, 14.575),
		Vector3(1.5, 0, 14.575),
	]
	
	var snap_distance: float = 2.0
	for tower_pos in tower_positions:
		if hit.distance_to(tower_pos) < snap_distance:
			var cost: Dictionary = GameState.BUILD_COST.get(VillageBuilding.BuildingType.GUARD_TOWER, {})
			if not GameState.spend(cost):
				return false
			
			var BUILDING_SCENE = preload("res://scenes/building.tscn")
			var b: VillageBuilding = BUILDING_SCENE.instantiate()
			b.building_type = VillageBuilding.BuildingType.GUARD_TOWER
			b.position = tower_pos
			b.level = 1
			village.add_child(b)
			village._buildings.append(b)
			
			var guard_tower_script = GDScript.new()
			guard_tower_script.source_code = load("res://scripts/guard_tower_ai.gd").source_code
			var guard_tower_ai = Node3D.new()
			guard_tower_ai.set_script(guard_tower_script)
			b.add_child(guard_tower_ai)
			guard_tower_ai.tower_building = b
			
			GameState.invalidate_navigation()
			return true
	
	return false


## Spawn building at grid cell
func spawn_building_at_cell(village: Node3D, building_type: int, cell: Vector2i, free: bool) -> bool:
	var existing: Variant = village._grid.get(cell, null)
	if existing != null:
		var existing_building := existing as VillageBuilding
		if existing_building and is_instance_valid(existing_building) and existing_building.building_type == VillageBuilding.BuildingType.PATH and building_type != VillageBuilding.BuildingType.PATH:
			existing_building.queue_free()
		else:
			return false
	if building_type == VillageBuilding.BuildingType.TOWN_HALL and village._has_town_hall():
		return false
	if not free:
		var cost: Dictionary = GameState.BUILD_COST.get(building_type, {})
		if not GameState.spend(cost):
			return false

	var BUILDING_SCENE = preload("res://scenes/building.tscn")
	var b: VillageBuilding = BUILDING_SCENE.instantiate()
	b.building_type = building_type
	b.cell = cell
	b.position = village._cell_to_world(cell)
	b.level = 1
	village.add_child(b)
	village._buildings.append(b)
	village._grid[cell] = b
	GameState.recompute_storage_caps(village._buildings)
	if building_type == VillageBuilding.BuildingType.PATH:
		village._refresh_all_path_visuals()
	else:
		village._refresh_path_visuals_near(cell)
	GameState.invalidate_navigation()
	return true


## Check if town hall exists
func has_town_hall(village: Node3D) -> bool:
	for building in village._buildings:
		if is_instance_valid(building) and building.building_type == VillageBuilding.BuildingType.TOWN_HALL:
			return true
	return false
