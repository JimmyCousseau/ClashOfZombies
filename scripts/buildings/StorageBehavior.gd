extends BuildingBehavior
class_name StorageBehavior

## Comportement des bâtiments de stockage.
## Utilisé par : Entrepôt (or/bois), Forge (élixir/pierre).


func get_storage_bonus_pack() -> Dictionary:
	if building.is_destroyed:
		return {}
	var base_pack: Dictionary = GameState.STORAGE_CAP_BONUS.get(building.building_type, {})
	if base_pack.is_empty():
		return {}
	var factor := 1.0 + float(maxi(building.level - 1, 0)) * 0.6
	var pack: Dictionary = {}
	for key in base_pack.keys():
		pack[String(key)] = int(round(float(base_pack[key]) * factor))
	return pack


func get_effect_summary() -> String:
	return "Stock : %s" % GameState.format_resource_pack(get_storage_bonus_pack(), false)


func get_upgrade_summary() -> String:
	if not building.can_upgrade():
		return "Niveau maximum atteint."
	return "Capacité de stockage accrue."
