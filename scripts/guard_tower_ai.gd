extends Node
class_name GuardTowerAI

const RANGE := 14.0
const DAMAGE := 25
const COOLDOWN := 1.2
const AIM_SPEED := 4.0

var _building: VillageBuilding
var _acc: float = 0.0
var _target: Unit = null


func setup(b: VillageBuilding) -> void:
	_building = b


func _process(delta: float) -> void:
	if not is_instance_valid(_building):
		return
	
	var origin: Vector3 = _building.global_position + Vector3(0, 2.0, 0)
	var best: Unit = null
	var range_value: float = RANGE
	var best_d2: float = range_value * range_value
	
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Unit
		if e == null or not is_instance_valid(e):
			continue
		var d2: float = origin.distance_squared_to(e.global_position)
		if d2 <= range_value * range_value and d2 < best_d2:
			best_d2 = d2
			best = e
	
	_target = best
	
	_acc += delta
	if _acc < COOLDOWN or not _target:
		return
	
	if GameState.arrows <= 0:
		return
	
	_acc = 0.0
	if _target:
		_fire_arrow(origin, _target)


func _fire_arrow(origin: Vector3, target: Unit) -> void:
	GameState.add_resources({"arrows": -1})
	
	var arrow_script: GDScript = load("res://scripts/bullet.gd")
	var arrow: Node3D = Node3D.new()
	arrow.set_script(arrow_script)
	arrow.global_position = origin
	if arrow.has_method("setup"):
		arrow.call("setup", target, DAMAGE)
	if _building and _building.get_parent():
		_building.get_parent().add_child(arrow)
	else:
		get_tree().root.add_child(arrow)
