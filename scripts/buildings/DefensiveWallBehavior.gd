extends BuildingBehavior
class_name DefensiveWallBehavior

## Comportement du mur défensif.
## Peut être converti en tour de garde.


func convert_to_guard_tower() -> bool:
	building.building_type = VillageBuilding.BuildingType.GUARD_TOWER
	building.level = 1
	building.behavior = null

	# Remplacer ce behavior par GuardTowerBehavior
	queue_free()
	building._apply_visual()

	var new_behavior := GuardTowerBehavior.new()
	new_behavior.name = "Behavior"
	building.add_child(new_behavior)
	new_behavior.setup(building)
	building.behavior = new_behavior

	return true


func get_effect_summary() -> String:
	return "Bloque le passage des ennemis."
