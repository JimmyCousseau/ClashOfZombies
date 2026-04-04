extends BuildingBehavior
class_name WorkshopBehavior

## Comportement de l'atelier.
## Étendre ici pour ajouter une logique de craft ou de production.


func get_effect_summary() -> String:
	return "Permet la fabrication d'équipements."


func get_upgrade_summary() -> String:
	if not building.can_upgrade():
		return "Niveau maximum atteint."
	return "Recettes avancées débloquées."
