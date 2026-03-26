extends Node
class_name CannonAI

const RANGE := 12.0
const DAMAGE := 35
const COOLDOWN := 0.9

var _building: VillageBuilding
var _acc: float = 0.0


func setup(b: VillageBuilding) -> void:
	_building = b


func _process(delta: float) -> void:
	if not is_instance_valid(_building):
		return
	_acc += delta
	if _acc < COOLDOWN:
		return
	_acc = 0.0
	var origin: Vector3 = _building.global_position + Vector3(0, 1.0, 0)
	var best: Unit = null
	var best_d2: float = RANGE * RANGE
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Unit
		if e == null or not is_instance_valid(e):
			continue
		var d2: float = origin.distance_squared_to(e.global_position)
		if d2 <= RANGE * RANGE and d2 < best_d2:
			best_d2 = d2
			best = e
	if best:
		best.take_damage(DAMAGE)
