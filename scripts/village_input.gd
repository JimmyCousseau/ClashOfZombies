## Input handling for Village
## Mouse and touch input processing

extends Node

const TOUCH_TAP_SLOP := 14.0


## Handle unhandled input events
func handle_unhandled_input(village: Node3D, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			village._handle_primary_action(mb.position)
		return
	if event is InputEventScreenTouch:
		handle_screen_touch(village, event as InputEventScreenTouch)
		return
	if event is InputEventScreenDrag:
		handle_screen_drag(village, event as InputEventScreenDrag)


## Handle screen touch
func handle_screen_touch(village: Node3D, event: InputEventScreenTouch) -> void:
	if event.pressed:
		if village._touch_tap_candidates.size() > 0:
			village._touch_tap_candidates.clear()
			return
		village._touch_tap_candidates[event.index] = event.position
		return
	if not village._touch_tap_candidates.has(event.index):
		return
	var start_pos: Vector2 = village._touch_tap_candidates[event.index]
	village._touch_tap_candidates.erase(event.index)
	if start_pos.distance_to(event.position) > TOUCH_TAP_SLOP:
		return
	village._handle_primary_action(event.position)


## Handle screen drag
func handle_screen_drag(village: Node3D, event: InputEventScreenDrag) -> void:
	if not village._touch_tap_candidates.has(event.index):
		return
	var start_pos: Vector2 = village._touch_tap_candidates[event.index]
	if start_pos.distance_to(event.position) > TOUCH_TAP_SLOP:
		village._touch_tap_candidates.erase(event.index)


## Get clicked building from screen position
func get_clicked_building(village: Node3D, screen_pos: Vector2) -> VillageBuilding:
	var camera_rig: Node3D = village.camera_rig
	var cam: Camera3D = camera_rig.get_node("Camera3D") as Camera3D
	if cam == null:
		return null
	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * 200.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	var hit: Dictionary = village.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Variant = hit.get("collider", null)
	if collider is VillageBuilding:
		return collider as VillageBuilding
	return null


## Convert screen position to ground position
func screen_to_ground(village: Node3D, screen_pos: Vector2) -> Variant:
	var camera_rig: Node3D = village.camera_rig
	var cam: Camera3D = camera_rig.get_node("Camera3D") as Camera3D
	if cam == null:
		return null
	var from := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return null
	var t_hit: float = -from.y / dir.y
	if t_hit < 0:
		return null
	return from + dir * t_hit
