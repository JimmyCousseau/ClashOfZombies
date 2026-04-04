extends BuildingBehavior
class_name CannonBehavior

## Comportement de la tourelle (cannon).
## Gère les stats, le résumé, et l'instanciation de l'IA.


func _on_setup() -> void:
	var ai := CannonAI.new()
	ai.name = "CannonAI"
	building.add_child(ai)
	ai.setup(building)


func get_range() -> float:
	return 12.0 + float(maxi(building.level - 1, 0)) * 1.5


func get_damage() -> int:
	return 35 + maxi(building.level - 1, 0) * 14


func get_cooldown() -> float:
	return maxf(0.45, 0.9 - float(maxi(building.level - 1, 0)) * 0.1)


func get_effect_summary() -> String:
	return "Dégâts %d | Portée %.1f" % [get_damage(), get_range()]


func get_upgrade_summary() -> String:
	if not building.can_upgrade():
		return "Niveau maximum atteint."
	return "Plus de portée et de dégâts."
