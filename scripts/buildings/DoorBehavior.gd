extends BuildingBehavior
class_name DoorBehavior

## Comportement de la porte principale du village.
## Gère la destruction, la reconstruction et les piques.


func get_spike_damage_per_sec() -> float:
	return 8.0 if building.is_spiked else 0.0


func add_spikes() -> bool:
	if building.is_spiked:
		return false
	building.is_spiked = true
	building.refresh_visual_state()
	return true


func is_main_door() -> bool:
	return building.global_position.distance_to(GameState.get_door_position()) <= 0.25


func break_door() -> void:
	building.is_destroyed = true
	building.hp = 0
	building.refresh_visual_state()
	var parent_node := building.get_parent()
	if parent_node and parent_node.has_method("notify_main_door_state_changed"):
		parent_node.call("notify_main_door_state_changed")
	GameState.door_destroyed.emit()


func rebuild() -> bool:
	if not building.is_destroyed:
		return false
	var rebuild_cost: Dictionary = GameState.BUILD_COST.get(VillageBuilding.BuildingType.DOOR, {})
	if not GameState.spend(rebuild_cost):
		return false
	building.is_destroyed = false
	building._recalculate_stats(true)
	building.refresh_visual_state()
	var parent_node := building.get_parent()
	if parent_node and parent_node.has_method("notify_main_door_state_changed"):
		parent_node.call("notify_main_door_state_changed")
	return true


func get_effect_summary() -> String:
	return "Contrôle l'entrée du village."
