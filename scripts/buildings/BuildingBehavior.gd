extends Node
class_name BuildingBehavior

## Classe de base pour tous les comportements de bâtiment.
## Chaque sous-classe gère la logique d'un type de bâtiment spécifique.

var building: VillageBuilding


func setup(b: VillageBuilding) -> void:
	building = b
	_on_setup()


## Appelé après setup(). Surcharger dans les sous-classes.
func _on_setup() -> void:
	pass


## Résumé affiché dans l'UI (ex: "Dégâts 25 | Portée 14")
func get_effect_summary() -> String:
	return ""


## Résumé de l'amélioration suivante
func get_upgrade_summary() -> String:
	if not building.can_upgrade():
		return "Niveau maximum atteint."
	return "Effets améliorés."


## Coût de réparation pour un montant donné
func get_repair_cost(amount: int) -> Dictionary:
	return GameState.get_repair_cost(building.building_type, amount)


## Coût d'amélioration
func get_upgrade_cost() -> Dictionary:
	return GameState.get_upgrade_cost(building.building_type, building.level)
