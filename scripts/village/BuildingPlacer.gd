extends Node
class_name BuildingPlacer

## Placement des bâtiments sur la grille ou aux positions fixes (tours).
## Délègue la conversion de coordonnées à VillageGridMap.

const BUILDING_SCENE := preload("res://scenes/building.tscn")

const TOWER_SNAP_POSITIONS: Array[Vector3] = [
	Vector3(-14.575, 1.4, -14.575),
	Vector3( 14.575, 1.4, -14.575),
	Vector3(-14.575, 1.4,  14.575),
	Vector3( 14.575, 1.4,  14.575),
	Vector3(-1.5,    1.4,  14.575),
	Vector3( 1.5,    1.4,  14.575),
]
const TOWER_SNAP_DISTANCE := 2.0

var _grid_map: VillageGridMap
var _parent: Node3D          # VillageGrid, pour add_child


func setup(grid_map: VillageGridMap, parent: Node3D) -> void:
	_grid_map = grid_map
	_parent = parent


# ---------------------------------------------------------------------------
# API principale
# ---------------------------------------------------------------------------

## Place un bâtiment depuis un point monde (dispatch grille ou tour).
func try_place_at_world(hit: Vector3, building_type: int) -> bool:
	if building_type == VillageBuilding.BuildingType.GUARD_TOWER:
		return _try_place_tower(hit)
	var cell: Vector2i = _grid_map.world_to_cell(hit)
	if not _grid_map.is_cell_in_bounds(cell):
		return false
	return spawn_at_cell(building_type, cell, false)


## Spawn un bâtiment à une cellule précise.
## free=true → aucun coût déduit (utilisé pour le layout de départ).
func spawn_at_cell(building_type: int, cell: Vector2i, free: bool) -> bool:
	var existing: VillageBuilding = _grid_map.get_building_at(cell)
	if existing != null:
		# On peut écraser un chemin par un autre bâtiment
		if is_instance_valid(existing) \
				and existing.building_type == VillageBuilding.BuildingType.PATH \
				and building_type != VillageBuilding.BuildingType.PATH:
			existing.queue_free()
		else:
			return false

	if building_type == VillageBuilding.BuildingType.TOWN_HALL and _grid_map.has_town_hall():
		return false

	if not free:
		var cost: Dictionary = GameState.BUILD_COST.get(building_type, {})
		if not GameState.spend(cost):
			return false

	var b: VillageBuilding = BUILDING_SCENE.instantiate()
	b.building_type = building_type as VillageBuilding.BuildingType
	b.cell = cell
	b.position = _grid_map.cell_to_world(cell)
	_parent.add_child(b)
	_grid_map.register(cell, b)
	GameState.recompute_storage_caps(_grid_map.get_buildings())
	GameState.invalidate_navigation()
	return true


## Place la porte de départ (position fixe, hors grille).
func spawn_starter_door() -> void:
	var b: VillageBuilding = BUILDING_SCENE.instantiate()
	b.building_type = VillageBuilding.BuildingType.DOOR
	b.cell = Vector2i.ZERO
	b.position = GameState.get_door_position()
	_parent.add_child(b)
	_grid_map.register_no_cell(b)
	GameState.invalidate_navigation()


# ---------------------------------------------------------------------------
# Tours de garde (placement par snap)
# ---------------------------------------------------------------------------

func _try_place_tower(hit: Vector3) -> bool:
	for tower_pos in TOWER_SNAP_POSITIONS:
		if hit.distance_to(tower_pos) >= TOWER_SNAP_DISTANCE:
			continue
		var cost: Dictionary = GameState.BUILD_COST.get(VillageBuilding.BuildingType.GUARD_TOWER, {})
		if not GameState.spend(cost):
			return false
		var b: VillageBuilding = BUILDING_SCENE.instantiate()
		b.building_type = VillageBuilding.BuildingType.GUARD_TOWER
		b.position = tower_pos
		b.level = 1
		_parent.add_child(b)
		_grid_map.register_no_cell(b)
		GameState.invalidate_navigation()
		return true
	return false


func get_tower_snap_positions() -> Array[Vector3]:
	return TOWER_SNAP_POSITIONS
