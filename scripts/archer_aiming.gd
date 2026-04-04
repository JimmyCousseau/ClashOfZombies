extends Node
class_name ArcherAimAI

const RANGE := 14.0

var _tower: VillageBuilding
var _archer_node: Node3D
var _bow: MeshInstance3D
var _target: Unit = null


func setup(tower: VillageBuilding, archer_node: Node3D, bow: MeshInstance3D) -> void:
	_tower = tower
	_archer_node = archer_node
	_bow = bow


func _process(_delta: float) -> void:
	if not is_instance_valid(_tower):
		return

	var origin: Vector3 = _tower.global_position + Vector3(0, 2.0, 0)
	var best: Unit = null
	var range_sq: float = RANGE * RANGE
	var best_d2: float = INF

	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Unit
		if e == null or not is_instance_valid(e):
			continue
		var d2: float = origin.distance_squared_to(e.global_position)
		if d2 <= range_sq and d2 < best_d2:
			best_d2 = d2
			best = e

	_target = best

	# Orienter l'archer vers la cible
	if _target and is_instance_valid(_target):
		var target_pos: Vector3 = _target.global_position
		var archer_pos: Vector3 = _tower.global_position + Vector3(0, 1.85, 0)
		var direction: Vector3 = (target_pos - archer_pos).normalized()

		# Rotation horizontale (Y)
		var look_y: float = atan2(direction.x, direction.z)
		_archer_node.rotation.y = look_y

		# Rotation verticale du corps (X) pour viser
		var horizontal_dist: float = Vector2(direction.x, direction.z).length()
		if horizontal_dist > 0.001:
			var look_x: float = atan2(direction.y, horizontal_dist)
			_archer_node.rotation.x = clamp(look_x, -PI * 0.4, PI * 0.3)
