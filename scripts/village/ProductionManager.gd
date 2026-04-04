extends Node
class_name ProductionManager

## Gère le timer de production et le cycle de ressources automatiques.

var _grid_map: VillageGridMap
var _production_timer: Timer


func setup(grid_map: VillageGridMap, production_timer: Timer) -> void:
	_grid_map = grid_map
	_production_timer = production_timer
	_production_timer.timeout.connect(_on_tick)


func _on_tick() -> void:
	_grid_map.purge_invalid()
	var pack := GameState.get_production_pack_from_buildings(_grid_map.get_buildings())
	if not pack.is_empty():
		GameState.add_resources(pack)


## Snapshot de la production courante (pour l'UI).
func get_current_production_pack() -> Dictionary:
	_grid_map.purge_invalid()
	return GameState.get_production_pack_from_buildings(_grid_map.get_buildings())
