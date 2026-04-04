extends BuildingBehavior
class_name TownHallBehavior

## Comportement du refuge (Town Hall).
## Sa destruction déclenche le game over.


func get_effect_summary() -> String:
	return "Solidité renforcée du refuge."


func get_upgrade_summary() -> String:
	if not building.can_upgrade():
		return "Niveau maximum atteint."
	return "Refuge plus résistant."
