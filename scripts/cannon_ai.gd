extends Node
class_name CannonAI

const RANGE := 12.0
const DAMAGE := 35
const COOLDOWN := 0.9
const AIM_SPEED := 5.0

var _building: VillageBuilding
var _acc: float = 0.0
var _target: Unit = null


func setup(b: VillageBuilding) -> void:
	_building = b


func _process(delta: float) -> void:
	if not is_instance_valid(_building):
		return
	
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
	
	_target = best
	
	if _building.cannon_barrel and _target:
		_aim_at_target(delta)
	
	_acc += delta
	if _acc < COOLDOWN or not _target:
		return
	
	_acc = 0.0
	if _target:
		_fire_bullet(origin, _target)


func _aim_at_target(delta: float) -> void:
	var barrel: MeshInstance3D = _building.cannon_barrel
	var barrel_global_pos: Vector3 = barrel.global_position
	var target_pos: Vector3 = _target.global_position + Vector3(0, 0.5, 0)
	var direction: Vector3 = (target_pos - barrel_global_pos).normalized()
	
	var target_angle: float = atan2(direction.x, direction.z)
	var current_angle: float = barrel.rotation.y
	
	var angle_diff: float = angle_difference(current_angle, target_angle)
	var max_rotation: float = AIM_SPEED * delta
	
	if abs(angle_diff) > max_rotation:
		barrel.rotation.y += sign(angle_diff) * max_rotation
	else:
		barrel.rotation.y = target_angle
	
	var elevation_angle: float = atan2(direction.y, Vector2(direction.x, direction.z).length())
	barrel.rotation.x = -elevation_angle + deg_to_rad(82)


func angle_difference(from: float, to: float) -> float:
	var diff: float = to - from
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return diff


func _fire_bullet(origin: Vector3, target: Unit) -> void:
	var bullet_script: GDScript = load("res://scripts/bullet.gd")
	var bullet: Node3D = Node3D.new()
	bullet.set_script(bullet_script)
	bullet.global_position = _building.cannon_barrel.global_position
	if bullet.has_method("setup"):
		bullet.call("setup", target, DAMAGE)
	if _building and _building.get_parent():
		_building.get_parent().add_child(bullet)
	else:
		get_tree().root.add_child(bullet)
