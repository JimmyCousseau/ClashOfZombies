extends Node
class_name PathVisuals

## Rafraîchit le visuel des chemins (jonctions nord/sud/est/ouest).

var _grid_map: VillageGridMap


func setup(grid_map: VillageGridMap) -> void:
	_grid_map = grid_map


func refresh_all() -> void:
	for b in _grid_map.get_buildings():
		if is_instance_valid(b) and b.building_type == VillageBuilding.BuildingType.PATH:
			b.refresh_visual_state()


func refresh_near(cell: Vector2i) -> void:
	var cells: Array[Vector2i] = [
		cell,
		cell + Vector2i( 0, -1),
		cell + Vector2i( 0,  1),
		cell + Vector2i(-1,  0),
		cell + Vector2i( 1,  0),
		_grid_map.get_main_door_connection_cell(),
	]
	for c in cells:
		var b: VillageBuilding = _grid_map.get_building_at(c)
		if b and is_instance_valid(b) and b.building_type == VillageBuilding.BuildingType.PATH:
			b.refresh_visual_state()
