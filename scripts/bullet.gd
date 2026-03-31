class_name Bullet
extends Node3D

const SPEED := 25.0
const DAMAGE := 35

var _target: Unit = null
var _direction: Vector3 = Vector3.ZERO
var _damage: int = DAMAGE
var _lifetime: float = 5.0


func _ready() -> void:
	_build_visual()
	_lifetime -= get_physics_process_delta_time()


func setup(target: Unit, damage: int = DAMAGE) -> void:
	_target = target
	_damage = damage
	if target:
		_update_direction()


func _physics_process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0:
		queue_free()
		return
	
	if not is_instance_valid(_target):
		queue_free()
		return
	
	_update_direction()
	global_position += _direction * SPEED * delta
	
	var distance_to_target: float = global_position.distance_to(_target.global_position)
	if distance_to_target < 0.6:
		if is_instance_valid(_target):
			_target.take_damage(_damage)
		queue_free()


func _update_direction() -> void:
	if is_instance_valid(_target):
		_direction = (_target.global_position - global_position).normalized()


func _build_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.15
	sphere_mesh.height = 0.3
	mesh_instance.mesh = sphere_mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	mat.roughness = 0.5
	mesh_instance.material_override = mat
	
	add_child(mesh_instance)
