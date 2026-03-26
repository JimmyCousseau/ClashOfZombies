extends Node3D
## Caméra isométrique : panoramique (glisser), zoom (molette / pincer simulé).

@export var pivot: Vector3 = Vector3.ZERO
@export var distance: float = 28.0
@export var min_distance: float = 14.0
@export var max_distance: float = 48.0
@export var yaw_deg: float = 45.0
@export var pitch_deg: float = 41.0

var _dragging: bool = false
var _last_screen: Vector2

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_update_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
			_last_screen = mb.position
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			distance = clampf(distance - 1.8, min_distance, max_distance)
			_update_camera_transform()
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			distance = clampf(distance + 1.8, min_distance, max_distance)
			_update_camera_transform()

	if event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		var delta_screen: Vector2 = mm.position - _last_screen
		_last_screen = mm.position
		var pan: Vector3 = Vector3(-delta_screen.x, 0, -delta_screen.y) * 0.04
		var yaw: float = deg_to_rad(yaw_deg)
		pan = pan.rotated(Vector3.UP, -yaw)
		pivot += pan
		_update_camera_transform()

	# Touch : un doigt = panoramique (approximation)
	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		var d := Vector3(-sd.relative.x, 0, -sd.relative.y) * 0.035
		var yaw2: float = deg_to_rad(yaw_deg)
		d = d.rotated(Vector3.UP, -yaw2)
		pivot += d
		_update_camera_transform()


func _update_camera_transform() -> void:
	var yaw: float = deg_to_rad(yaw_deg)
	var pitch: float = deg_to_rad(pitch_deg)
	var dir := Vector3(
		cos(pitch) * sin(yaw),
		sin(pitch),
		cos(pitch) * cos(yaw)
	).normalized()
	global_position = pivot + dir * distance
	if camera:
		camera.look_at(pivot, Vector3.UP)
