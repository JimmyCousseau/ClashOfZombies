extends BuildingBehavior
class_name ProducerBehavior

## Comportement des bâtiments producteurs de ressources.
## Utilisé par : Scierie (bois), Carrière (pierre), Potager (nourriture).


func get_production_pack() -> Dictionary:
	var base_pack: Dictionary = GameState.PRODUCTION.get(building.building_type, {})
	if base_pack.is_empty() or building.is_destroyed:
		return {}
	var factor := 1.0 + float(maxi(building.level - 1, 0)) * 0.55
	var pack: Dictionary = {}
	for key in base_pack.keys():
		pack[String(key)] = int(round(float(base_pack[key]) * factor))
	return pack


func get_effect_summary() -> String:
	var pack := get_production_pack()
	if pack.is_empty():
		return ""
	var resource_name := ""
	var amount := 0
	match building.building_type:
		VillageBuilding.BuildingType.GOLD_MINE:
			resource_name = "bois"
			amount = int(pack.get("wood", 0))
		VillageBuilding.BuildingType.ELIXIR_COLLECTOR:
			resource_name = "pierre"
			amount = int(pack.get("stone", 0))
		VillageBuilding.BuildingType.FARM:
			resource_name = "nourriture"
			amount = int(pack.get("food", 0))
	return "Production : %d %s / cycle" % [amount, resource_name]


func get_upgrade_summary() -> String:
	if not building.can_upgrade():
		return "Niveau maximum atteint."
	match building.building_type:
		VillageBuilding.BuildingType.GOLD_MINE:
			return "Plus de bois par cycle."
		VillageBuilding.BuildingType.ELIXIR_COLLECTOR:
			return "Plus de pierre par cycle."
		VillageBuilding.BuildingType.FARM:
			return "Plus de nourriture par cycle."
	return "Production augmentée."
