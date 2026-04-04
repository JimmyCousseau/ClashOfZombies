extends BuildingBehavior
class_name GuardTowerBehavior

## Comportement de la tour de garde.
## Gère les stats archer, l'IA de tir et la visée.

const RANGE    := 14.0
const DAMAGE   := 25
const COOLDOWN := 1.2


func _on_setup() -> void:
	_spawn_ai()


func _spawn_ai() -> void:
	# IA de tir
	var ai := GuardTowerAI.new()
	ai.name = "GuardTowerAI"
	building.add_child(ai)
	ai.setup(building)

	# IA de visée archer (optionnelle selon le visuel)
	var visual_container: Node3D = building.get_node_or_null("MeshRoot/VisualContainer")
	if visual_container == null or visual_container.get_child_count() == 0:
		return
	var visual: Node3D = visual_container.get_child(0)
	var archer_node: Node3D = visual.get_node_or_null("Archer")
	if archer_node == null:
		return
	var bow: MeshInstance3D = archer_node.get_node_or_null("Bow")
	if bow == null:
		return

	var aiming: Node = load("res://scripts/archer_aiming.gd").new()
	aiming.name = "ArcherAimAI"
	building.add_child(aiming)
	aiming.setup(building, archer_node, bow)


func get_effect_summary() -> String:
	return "Dégâts %d | Portée %.1f | Cadence %.1fs" % [DAMAGE, RANGE, COOLDOWN]


func get_upgrade_summary() -> String:
	if not building.can_upgrade():
		return "Niveau maximum atteint."
	return "Archer plus précis et plus rapide."
