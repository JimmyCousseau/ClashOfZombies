extends Node3D
## Muraille de pierre autour de la grille du village (collision + rendu).

var _mat_stone: StandardMaterial3D


func _ready() -> void:
	if get_child_count() > 0:
		return
	_mat_stone = StandardMaterial3D.new()
	_mat_stone.albedo_color = Color(0.58, 0.55, 0.5)
	_mat_stone.roughness = 0.92
	var inner: float = GameState.get_inner_half_extent()
	var w: float = GameState.WALL_THICKNESS
	var h: float = GameState.WALL_HEIGHT
	var y: float = h * 0.5 - 0.02
	var span: float = 2.0 * inner + 2.0 * w
	
	_add_wall(Vector3(0, y, -(inner + w * 0.5)), Vector3(span, h, w))
	
	var door_width: float = 1.5
	var left_span: float = inner - door_width * 0.5
	var right_span: float = inner - door_width * 0.5
	_add_wall(Vector3(-(door_width * 0.5 + left_span * 0.5), y, (inner + w * 0.5)), Vector3(left_span, h, w))
	_add_wall(Vector3((door_width * 0.5 + right_span * 0.5), y, (inner + w * 0.5)), Vector3(right_span, h, w))
	
	_add_wall(Vector3(-(inner + w * 0.5), y, 0), Vector3(w, h, span))
	_add_wall(Vector3((inner + w * 0.5), y, 0), Vector3(w, h, span))


func _add_wall(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = _mat_stone
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)
