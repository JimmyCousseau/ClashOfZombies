extends Node
class_name VillageGridMap

## Conversion coordonnées cellule ↔ monde.
## Source de vérité pour _grid et _buildings.

var _grid: Dictionary = {}          # Vector2i -> VillageBuilding
var _buildings: Array[VillageBuilding] = []


# ---------------------------------------------------------------------------
# Conversion
# ---------------------------------------------------------------------------

func cell_to_world(c: Vector2i) -> Vector3:
	var hw := GameState.GRID_SIZE.x * GameState.CELL_SIZE * 0.5
	var hd := GameState.GRID_SIZE.y * GameState.CELL_SIZE * 0.5
	return Vector3(
		c.x * GameState.CELL_SIZE + GameState.CELL_SIZE * 0.5 - hw,
		0.0,
		c.y * GameState.CELL_SIZE + GameState.CELL_SIZE * 0.5 - hd
	)


func world_to_cell(p: Vector3) -> Vector2i:
	var hw := GameState.GRID_SIZE.x * GameState.CELL_SIZE * 0.5
	var hd := GameState.GRID_SIZE.y * GameState.CELL_SIZE * 0.5
	return Vector2i(
		int(floor((p.x + hw) / GameState.CELL_SIZE)),
		int(floor((p.z + hd) / GameState.CELL_SIZE))
	)


func is_cell_in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < GameState.GRID_SIZE.x and c.y < GameState.GRID_SIZE.y


# ---------------------------------------------------------------------------
# Accès à la grille
# ---------------------------------------------------------------------------

func get_building_at(c: Vector2i) -> VillageBuilding:
	return _grid.get(c, null) as VillageBuilding


func has_cell(c: Vector2i) -> bool:
	return _grid.has(c)


func register(c: Vector2i, b: VillageBuilding) -> void:
	_grid[c] = b
	if not _buildings.has(b):
		_buildings.append(b)


func unregister(c: Vector2i, b: VillageBuilding) -> void:
	if _grid.get(c, null) == b:
		_grid.erase(c)
	_buildings.erase(b)


func register_no_cell(b: VillageBuilding) -> void:
	if not _buildings.has(b):
		_buildings.append(b)


func purge_invalid() -> void:
	var alive: Array[VillageBuilding] = []
	for b in _buildings:
		if is_instance_valid(b):
			alive.append(b)
	_buildings = alive


func get_buildings() -> Array[VillageBuilding]:
	return _buildings


func get_main_door() -> VillageBuilding:
	for b in _buildings:
		if is_instance_valid(b) and b.building_type == VillageBuilding.BuildingType.DOOR:
			return b
	return null


func has_town_hall() -> bool:
	for b in _buildings:
		if is_instance_valid(b) and b.building_type == VillageBuilding.BuildingType.TOWN_HALL:
			return true
	return false


func get_main_door_connection_cell() -> Vector2i:
	return world_to_cell(GameState.get_door_inside_entry())


func is_path_connected_to_neighbor(path_cell: Vector2i, offset: Vector2i) -> bool:
	var neighbor := get_building_at(path_cell + offset)
	if neighbor and is_instance_valid(neighbor) and neighbor.building_type == VillageBuilding.BuildingType.PATH:
		return true
	if offset == Vector2i(0, 1) and path_cell == get_main_door_connection_cell():
		var door := get_main_door()
		return door != null and is_instance_valid(door)
	return false
