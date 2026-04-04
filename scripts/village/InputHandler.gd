extends Node
class_name InputHandler

## Gère les événements souris et tactiles, émet un signal unique primary_action.

const TOUCH_TAP_SLOP := 14.0

signal primary_action(screen_pos: Vector2)

var _touch_candidates: Dictionary = {}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			primary_action.emit(mb.position)
		return

	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
		return

	if event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch_candidates.size() > 0:
			_touch_candidates.clear()
			return
		_touch_candidates[event.index] = event.position
		return
	if not _touch_candidates.has(event.index):
		return
	var start: Vector2 = _touch_candidates[event.index]
	_touch_candidates.erase(event.index)
	if start.distance_to(event.position) <= TOUCH_TAP_SLOP:
		primary_action.emit(event.position)


func _handle_drag(event: InputEventScreenDrag) -> void:
	if not _touch_candidates.has(event.index):
		return
	var start: Vector2 = _touch_candidates[event.index]
	if start.distance_to(event.position) > TOUCH_TAP_SLOP:
		_touch_candidates.erase(event.index)
