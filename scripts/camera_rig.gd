extends Node3D
## Caméra isométrique avec pan ancré au sol, zoom molette/pincement et support tactile.

@export var pivot: Vector3 = Vector3.ZERO
@export var distance: float = 28.0
@export var min_distance: float = 14.0
@export var max_distance: float = 48.0
@export var yaw_deg: float = 45.0
@export var pitch_deg: float = 41.0
@export var wheel_zoom_step: float = 2.0
@export var pinch_zoom_factor: float = 0.02
@export var keyboard_pan_speed: float = 18.0
@export var pan_limit_margin: float = 8.0
@export var touch_drag_threshold: float = 12.0
@export var drag_pan_sensitivity: float = 1.35
@export var pan_smoothing: float = 16.0

var _mouse_dragging: bool = false
var _touch_points: Dictionary = {}
var _single_touch_index: int = -1
var _single_touch_start: Vector2 = Vector2.ZERO
var _single_touch_panning: bool = false
var _last_pinch_distance: float = 0.0
var _pivot_goal: Vector3 = Vector3.ZERO

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_pivot_goal = pivot
	_update_camera_transform()


func _process(delta: float) -> void:
	_process_keyboard_pan(delta)
	var weight: float = clampf(delta * pan_smoothing, 0.0, 1.0)
	pivot = pivot.lerp(_pivot_goal, weight)
	if pivot.distance_to(_pivot_goal) <= 0.001:
		pivot = _pivot_goal
	_update_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
		return
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
		return
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
		return
	if event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
		_mouse_dragging = event.pressed
		get_viewport().set_input_as_handled()
		return
	if not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_apply_zoom(-wheel_zoom_step)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_apply_zoom(wheel_zoom_step)
		get_viewport().set_input_as_handled()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _mouse_dragging:
		return
	_pan_from_relative(event.relative)
	get_viewport().set_input_as_handled()


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_points[event.index] = event.position
	else:
		_touch_points.erase(event.index)
	
	if _touch_points.size() == 1:
		var first_index: int = _touch_points.keys()[0]
		_single_touch_index = first_index
		_single_touch_start = _touch_points[first_index]
		_single_touch_panning = false
	elif _touch_points.size() >= 2:
		_single_touch_index = -1
		_single_touch_panning = false
		_last_pinch_distance = _get_touch_distance()
	else:
		_single_touch_index = -1
		_single_touch_panning = false


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	_touch_points[event.index] = event.position
	if _touch_points.size() >= 2:
		_handle_pinch_zoom()
		get_viewport().set_input_as_handled()
		return
	if _touch_points.size() != 1 or event.index != _single_touch_index:
		return
	if not _single_touch_panning:
		if _single_touch_start.distance_to(event.position) < touch_drag_threshold:
			return
		_single_touch_panning = true
	_pan_from_relative(event.relative)
	get_viewport().set_input_as_handled()


func _handle_pinch_zoom() -> void:
	var current_distance: float = _get_touch_distance()
	if current_distance <= 0.0:
		return
	if _last_pinch_distance > 0.0:
		var delta: float = current_distance - _last_pinch_distance
		_apply_zoom(-delta * pinch_zoom_factor)
	_last_pinch_distance = current_distance


func _process_keyboard_pan(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y -= 1.0
	if input_dir == Vector2.ZERO:
		return
	var forward := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(yaw_deg)).normalized()
	var right := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(yaw_deg)).normalized()
	var pan: Vector3 = (right * input_dir.x + forward * input_dir.y).normalized() * keyboard_pan_speed * delta
	_pivot_goal += pan
	_pivot_goal = _clamp_pivot(_pivot_goal)


func _pan_from_relative(delta_screen: Vector2) -> void:
	if camera == null:
		return
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	if viewport_size.y <= 0.0:
		return
	var pitch_rad: float = deg_to_rad(pitch_deg)
	var vertical_world_span: float = 2.0 * distance * tan(deg_to_rad(camera.fov * 0.5))
	var pixels_to_world: float = vertical_world_span / viewport_size.y
	pixels_to_world *= drag_pan_sensitivity / maxf(0.45, cos(pitch_rad))
	var right: Vector3 = camera.global_basis.x
	right.y = 0.0
	if right.length_squared() <= 0.0001:
		return
	right = right.normalized()
	var forward: Vector3 = -camera.global_basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return
	forward = forward.normalized()
	var pan: Vector3 = (-right * delta_screen.x + -forward * -delta_screen.y) * pixels_to_world
	_pivot_goal += pan
	_pivot_goal = _clamp_pivot(_pivot_goal)


func _apply_zoom(delta: float) -> void:
	distance = clampf(distance + delta, min_distance, max_distance)
	_update_camera_transform()

func _get_touch_distance() -> float:
	if _touch_points.size() < 2:
		return 0.0
	var points: Array = _touch_points.values()
	var a: Vector2 = points[0]
	var b: Vector2 = points[1]
	return a.distance_to(b)


func _clamp_pivot(value: Vector3) -> Vector3:
	var limit: float = GameState.get_patrol_ring_radius() + pan_limit_margin
	value.x = clampf(value.x, -limit, limit)
	value.z = clampf(value.z, -limit, limit)
	return value


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
