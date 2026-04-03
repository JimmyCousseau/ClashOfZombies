class_name Unit
extends CharacterBody3D

enum Allegiance { PLAYER, ENEMY }

@export var allegiance: Allegiance = Allegiance.ENEMY
@export var move_speed: float = 4.5
@export var attack_range: float = 2.2
@export var attack_damage: int = 18
@export var attack_cooldown: float = 0.85

var hp: int = 90
var max_hp: int = 90
var _target_enemy: Unit = null
var _target_building: VillageBuilding = null
var _attack_acc: float = 0.0

@onready var mesh_root: Node3D = $MeshRoot

var _health_bar_container: Node3D = null
var _health_bar_bg: MeshInstance3D = null
var _health_bar_fill: MeshInstance3D = null


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	_update_health_bar()
	if hp <= 0:
		_on_death()


func _create_health_bar() -> void:
	_health_bar_container = Node3D.new()
	_health_bar_container.position = Vector3(0, 1.2, 0)
	add_child(_health_bar_container)
	
	var bg := MeshInstance3D.new()
	var bg_box := BoxMesh.new()
	bg_box.size = Vector3(0.8, 0.15, 0.05)
	bg.mesh = bg_box
	bg.material_override = _mat(Color(0.1, 0.1, 0.1, 0.7))
	_health_bar_container.add_child(bg)
	_health_bar_bg = bg
	
	var fill := MeshInstance3D.new()
	var fill_box := BoxMesh.new()
	fill_box.size = Vector3(0.8, 0.15, 0.06)
	fill.mesh = fill_box
	fill.material_override = _mat(Color(0.2, 0.8, 0.2, 0.9))
	_health_bar_container.add_child(fill)
	_health_bar_fill = fill
	
	_update_health_bar()


func _update_health_bar() -> void:
	if _health_bar_fill == null:
		return
	var ratio: float = float(hp) / float(max_hp)
	ratio = clampf(ratio, 0.0, 1.0)
	_health_bar_fill.scale.x = ratio
	_health_bar_fill.position.x = (1.0 - ratio) * -0.4


func _mat(c: Color, roughness: float = 0.8, metallic: float = 0.05) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = roughness
	m.metallic = metallic
	return m


func _pick_target() -> void:
	pass


func _on_death() -> void:
	queue_free()
