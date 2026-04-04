@tool
extends Node3D
## Grille du village, placement des bâtiments, production.

const BUILDING_SCENE := preload("res://scenes/building.tscn")
const HERO_SCENE := preload("res://scenes/hero.tscn")
const BARBARIAN_SCENE := preload("res://scenes/barbarian.tscn")
const ZOMBIE_SCENE := preload("res://scenes/zombie.tscn")
const TOUCH_TAP_SLOP := 14.0
const EDITOR_PREVIEW_ROOT_NAME := "_EditorPreview"
const HERO_START_MARKER_NAME := "HeroStart"
const EDITOR_PREVIEW_BUILDING_TYPES: Array[int] = [
	VillageBuilding.BuildingType.TOWN_HALL,
	VillageBuilding.BuildingType.GOLD_MINE,
	VillageBuilding.BuildingType.ELIXIR_COLLECTOR,
	VillageBuilding.BuildingType.CANNON,
	VillageBuilding.BuildingType.BARRACKS,
	VillageBuilding.BuildingType.GOLD_STORAGE,
	VillageBuilding.BuildingType.ELIXIR_STORAGE,
	VillageBuilding.BuildingType.FARM,
	VillageBuilding.BuildingType.DOOR,
	VillageBuilding.BuildingType.PATH,
]

var _grid: Dictionary = {} # Vector2i -> VillageBuilding
var _build_mode: int = -1
var _buildings: Array[VillageBuilding] = []
var _touch_tap_candidates: Dictionary = {}
var _hero: Node = null
var _selected_building: VillageBuilding = null

@onready var camera_rig: Node3D = $"../CameraRig"
@onready var hud: Control = $"../UI/HUD"


func _ready() -> void:
	if Engine.is_editor_hint():
		if _has_authored_starter_layout():
			_clear_editor_preview()
		else:
			_rebuild_editor_preview()
		return
	_clear_editor_preview()
	_register_authored_starter_layout()
	if not _has_town_hall():
		_place_starter_town_hall()
	if _get_main_door() == null:
		_place_starter_door()
	_spawn_hero()
	$ProductionTimer.timeout.connect(_on_production_timer)
	GameState.recompute_storage_caps(_buildings)
	_refresh_all_path_visuals()


func _has_authored_starter_layout() -> bool:
	for child in get_children():
		if child is VillageBuilding:
			return true
	return false


func _register_authored_starter_layout() -> void:
	_grid.clear()
	_buildings.clear()
	for child in get_children():
		if not (child is VillageBuilding):
			continue
		var building := child as VillageBuilding
		if building == null or not is_instance_valid(building):
			continue
		if building.building_type != VillageBuilding.BuildingType.DOOR:
			building.cell = _world_to_cell(building.position)
			_grid[building.cell] = building
		_buildings.append(building)


func get_main_door_world_position() -> Vector3:
	for child in get_children():
		if child is VillageBuilding:
			var building := child as VillageBuilding
			if building and is_instance_valid(building) and building.building_type == VillageBuilding.BuildingType.DOOR:
				if building.is_inside_tree():
					return building.global_position
				return global_position + building.position
	return Vector3(0, 0, GameState.get_inner_half_extent() + GameState.WALL_THICKNESS * 0.5)


func _rebuild_editor_preview() -> void:
	_clear_editor_preview()
	var preview_root := Node3D.new()
	preview_root.name = EDITOR_PREVIEW_ROOT_NAME
	add_child(preview_root)

	for index in EDITOR_PREVIEW_BUILDING_TYPES.size():
		var building: VillageBuilding = BUILDING_SCENE.instantiate()
		building.building_type = EDITOR_PREVIEW_BUILDING_TYPES[index]
		building.position = _get_editor_preview_building_position(index)
		if building.building_type == VillageBuilding.BuildingType.PATH:
			building.cell = Vector2i(index, 0)
		preview_root.add_child(building)

	var hero: Node3D = HERO_SCENE.instantiate()
	hero.position = Vector3(-4.0, 0.0, 6.0)
	preview_root.add_child(hero)

	var barbarian: Node3D = BARBARIAN_SCENE.instantiate()
	barbarian.position = Vector3(0.0, 0.0, 6.0)
	preview_root.add_child(barbarian)

	var zombie: Node3D = ZOMBIE_SCENE.instantiate()
	zombie.position = Vector3(4.0, 0.0, 6.0)
	preview_root.add_child(zombie)


func _clear_editor_preview() -> void:
	var preview_root := get_node_or_null(EDITOR_PREVIEW_ROOT_NAME)
	if preview_root:
		preview_root.free()


func _get_editor_preview_building_position(index: int) -> Vector3:
	var columns: int = 5
	var spacing: float = 6.0
	var row: int = index / columns
	var column: int = index % columns
	var x_offset: float = (float(column) - 2.0) * spacing
	var z_offset: float = -8.0 - float(row) * spacing
	return Vector3(x_offset, 0.0, z_offset)


func set_build_mode(t: int) -> void:
	_build_mode = t


func clear_build_mode() -> void:
	_build_mode = -1


func notify_building_removed(c: Vector2i, b: VillageBuilding) -> void:
	if _grid.get(c, null) == b:
		_grid.erase(c)
	var i: int = _buildings.find(b)
	if i >= 0:
		_buildings.remove_at(i)
	if _selected_building == b:
		_selected_building = null
		_hide_building_panel()
	GameState.recompute_storage_caps(_buildings)
	_refresh_path_visuals_near(c)
	GameState.invalidate_navigation()


func _place_starter_town_hall() -> void:
	var center := Vector2i(GameState.GRID_SIZE.x / 2, GameState.GRID_SIZE.y / 2)
	_spawn_building_at_cell(VillageBuilding.BuildingType.TOWN_HALL, center, true)


func _place_starter_door() -> void:
	var b: VillageBuilding = BUILDING_SCENE.instantiate()
	b.building_type = VillageBuilding.BuildingType.DOOR
	b.cell = Vector2i.ZERO
	b.position = GameState.get_door_position()
	add_child(b)
	_buildings.append(b)
	GameState.invalidate_navigation()


func _spawn_hero() -> void:
	var allies: Node3D = get_tree().get_first_node_in_group("ally_units") as Node3D
	if allies == null:
		call_deferred("_spawn_hero")
		return
	_hero = HERO_SCENE.instantiate()
	allies.add_child(_hero)
	var hero_start := get_node_or_null(HERO_START_MARKER_NAME) as Node3D
	if hero_start:
		_hero.global_position = hero_start.global_position
		return
	var center := Vector2i(GameState.GRID_SIZE.x / 2, GameState.GRID_SIZE.y / 2)
	_hero.global_position = _cell_to_world(center) + Vector3(1.0, 0.0, 2.0)


func _spawn_building_at_cell(t: int, cell: Vector2i, free: bool) -> bool:
	var existing: Variant = _grid.get(cell, null)
	if existing != null:
		var existing_building := existing as VillageBuilding
		if existing_building and is_instance_valid(existing_building) and existing_building.building_type == VillageBuilding.BuildingType.PATH and t != VillageBuilding.BuildingType.PATH:
			existing_building.queue_free()
		else:
			return false
	if t == VillageBuilding.BuildingType.TOWN_HALL and _has_town_hall():
		return false
	if not free:
		var cost: Dictionary = GameState.BUILD_COST.get(t, {})
		if not GameState.spend(cost):
			return false

	var b: VillageBuilding = BUILDING_SCENE.instantiate()
	b.building_type = t
	b.cell = cell
	b.position = _cell_to_world(cell)
	add_child(b)
	_grid[cell] = b
	_buildings.append(b)
	GameState.recompute_storage_caps(_buildings)
	_refresh_path_visuals_near(cell)
	GameState.invalidate_navigation()
	if t == VillageBuilding.BuildingType.CANNON:
		var ai := CannonAI.new()
		ai.name = "CannonAI"
		b.add_child(ai)
		ai.setup(b)
	return true


func _has_town_hall() -> bool:
	for x in _buildings:
		if is_instance_valid(x) and x.building_type == VillageBuilding.BuildingType.TOWN_HALL:
			return true
	return false


func _cell_to_world(c: Vector2i) -> Vector3:
	var hw := GameState.GRID_SIZE.x * GameState.CELL_SIZE * 0.5
	var hd := GameState.GRID_SIZE.y * GameState.CELL_SIZE * 0.5
	return Vector3(
		c.x * GameState.CELL_SIZE + GameState.CELL_SIZE * 0.5 - hw,
		0.0,
		c.y * GameState.CELL_SIZE + GameState.CELL_SIZE * 0.5 - hd
	)


func _world_to_cell(p: Vector3) -> Vector2i:
	var hw := GameState.GRID_SIZE.x * GameState.CELL_SIZE * 0.5
	var hd := GameState.GRID_SIZE.y * GameState.CELL_SIZE * 0.5
	var x := int(floor((p.x + hw) / GameState.CELL_SIZE))
	var z := int(floor((p.z + hd) / GameState.CELL_SIZE))
	return Vector2i(x, z)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_handle_primary_action(mb.position)
		return
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
		return
	if event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch_tap_candidates.size() > 0:
			_touch_tap_candidates.clear()
			return
		_touch_tap_candidates[event.index] = event.position
		return
	if not _touch_tap_candidates.has(event.index):
		return
	var start_pos: Vector2 = _touch_tap_candidates[event.index]
	_touch_tap_candidates.erase(event.index)
	if start_pos.distance_to(event.position) > TOUCH_TAP_SLOP:
		return
	_handle_primary_action(event.position)


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not _touch_tap_candidates.has(event.index):
		return
	var start_pos: Vector2 = _touch_tap_candidates[event.index]
	if start_pos.distance_to(event.position) > TOUCH_TAP_SLOP:
		_touch_tap_candidates.erase(event.index)


func _handle_primary_action(screen_pos: Vector2) -> void:
	var clicked_building: VillageBuilding = _get_clicked_building(screen_pos)
	if clicked_building:
		if clicked_building.building_type == VillageBuilding.BuildingType.DOOR and clicked_building.is_main_village_door():
			_selected_building = null
			_hide_building_panel()
			_toggle_door_panel()
			return
		_hide_door_panel()
		_selected_building = clicked_building
		_show_building_panel()
		return
	var hit: Variant = _screen_to_ground(screen_pos)
	_hide_door_panel()
	if hit == null:
		return
	var hit_pos: Vector3 = hit as Vector3
	var main_door := _get_main_door()
	if main_door and main_door.is_destroyed and hit_pos.distance_to(GameState.get_door_position()) <= 1.45:
		_selected_building = null
		_hide_building_panel()
		_toggle_door_panel()
		return
	var cell: Vector2i = _world_to_cell(hit_pos)
	if _is_build_menu_open() and _build_mode >= 0:
		if _try_place_at_world(hit_pos):
			_selected_building = null
			_hide_building_panel()
			if hud and hud.has_method("on_build_placed"):
				hud.call("on_build_placed")
			return
	if _grid.has(cell):
		var cell_building := _grid.get(cell, null) as VillageBuilding
		if cell_building and is_instance_valid(cell_building):
			_selected_building = cell_building
			_show_building_panel()
			return
	_selected_building = null
	_hide_building_panel()
	if _is_build_menu_open():
		return
	command_hero_move(hit_pos)


func _get_clicked_building(screen_pos: Vector2) -> VillageBuilding:
	var cam: Camera3D = camera_rig.get_node("Camera3D") as Camera3D
	if cam == null:
		return null
	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * 200.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Variant = hit.get("collider", null)
	if collider is VillageBuilding:
		return collider as VillageBuilding
	return null


func _screen_to_ground(screen_pos: Vector2) -> Variant:
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


func _try_place_at_world(hit: Vector3) -> bool:
	if _build_mode < 0:
		return false
	var cell := _world_to_cell(hit)
	if cell.x < 0 or cell.y < 0 or cell.x >= GameState.GRID_SIZE.x or cell.y >= GameState.GRID_SIZE.y:
		return false
	return _spawn_building_at_cell(_build_mode, cell, false)


func command_hero_move(world_pos: Vector3) -> void:
	if _hero == null or not is_instance_valid(_hero):
		return
	_hero.move_within_village(world_pos)


func send_hero_on_exploration() -> void:
	if _hero == null or not is_instance_valid(_hero):
		return
	_hero.send_on_exploration()


func execute_hero_door_action() -> bool:
	var door: VillageBuilding = _get_main_door()
	if door and door.is_destroyed:
		return door.rebuild_main_door()
	if _hero == null or not is_instance_valid(_hero):
		return false
	if _hero.has_method("execute_primary_door_action"):
		return _hero.call("execute_primary_door_action")
	return false


func cycle_hero_focus() -> String:
	if _hero == null or not is_instance_valid(_hero):
		return "Bois"
	return _hero.cycle_exploration_focus()


func get_hero_focus_label() -> String:
	if _hero == null or not is_instance_valid(_hero):
		return "Bois"
	return _hero.get_exploration_focus_label()


func get_hero_status_text() -> String:
	if _hero == null or not is_instance_valid(_hero):
		return "Indisponible"
	return _hero.get_status_text()


func get_automatic_production_pack() -> Dictionary:
	var alive: Array[VillageBuilding] = []
	for building in _buildings:
		if is_instance_valid(building):
			alive.append(building)
	_buildings = alive
	return GameState.get_production_pack_from_buildings(_buildings)


func _get_main_door() -> VillageBuilding:
	for building in _buildings:
		if is_instance_valid(building) and building.building_type == VillageBuilding.BuildingType.DOOR:
			return building
	return null


func get_hero_door_action_label() -> String:
	if _hero == null or not is_instance_valid(_hero):
		return "Indisponible"
	if _hero.has_method("get_primary_door_action_label"):
		return _hero.call("get_primary_door_action_label")
	return "Action"


func can_execute_hero_door_action() -> bool:
	if _hero == null or not is_instance_valid(_hero):
		return false
	if _hero.has_method("can_execute_primary_door_action"):
		return _hero.call("can_execute_primary_door_action")
	return false


func get_door_panel_info() -> Dictionary:
	var door: VillageBuilding = _get_main_door()
	var door_status: String = "Porte : indisponible"
	var hero_line: String = "Hero : %s | Mission : %s" % [get_hero_status_text(), get_hero_focus_label()]
	var action_label: String = get_hero_door_action_label()
	var action_enabled: bool = can_execute_hero_door_action()
	var secondary_label: String = "Changer mission"
	var secondary_enabled: bool = true
	if door and is_instance_valid(door):
		if door.is_destroyed:
			door_status = "Porte principale detruite"
			action_label = "Reconstruire (%s)" % GameState.format_resource_pack(GameState.BUILD_COST.get(VillageBuilding.BuildingType.DOOR, {}), true)
			action_enabled = GameState.can_afford(GameState.BUILD_COST.get(VillageBuilding.BuildingType.DOOR, {}))
			secondary_label = "Mission indisponible"
			secondary_enabled = false
		else:
			door_status = "Porte : %d / %d" % [door.hp, door.max_hp]
	return {
		"status": door_status,
		"focus": hero_line,
		"action_label": action_label,
		"action_enabled": action_enabled,
		"secondary_label": secondary_label,
		"secondary_enabled": secondary_enabled,
	}


func debug_damage_main_door(amount: int = 250) -> bool:
	var door: VillageBuilding = _get_main_door()
	if door == null or not is_instance_valid(door) or door.is_destroyed:
		return false
	door.take_damage(maxi(1, amount))
	return true


func get_selected_building_panel_info() -> Dictionary:
	if _selected_building == null or not is_instance_valid(_selected_building):
		return {"valid": false}
	var title: String = _selected_building._type_name()
	var status: String = "Niveau %d / %d | PV : %d / %d" % [_selected_building.level, _selected_building.get_max_level(), _selected_building.hp, _selected_building.max_hp]
	var details: String = _selected_building.get_effect_summary()
	var action_label: String = "Aucune action"
	var action_enabled: bool = false
	if _selected_building.building_type == VillageBuilding.BuildingType.BARRACKS:
		var active_soldiers: int = _selected_building.get_barracks_active_soldier_count()
		var max_soldiers: int = _selected_building.get_barracks_max_soldiers()
		var missing: int = _selected_building.get_barracks_missing_soldier_count()
		var refill_cost: Dictionary = _selected_building.get_barracks_refill_cost()
		details = "Garnison : %d / %d" % [active_soldiers, max_soldiers]
		if missing > 0:
			details += "\nReformation : %s" % GameState.format_resource_pack(refill_cost, true)
			action_label = "Reformer"
			action_enabled = GameState.can_afford(refill_cost)
		else:
			action_label = "Garnison complete"
	else:
		if _selected_building.building_type == VillageBuilding.BuildingType.PATH:
			details += "\n" + GameState.get_build_description(_selected_building.building_type)
		else:
			details += "\n" + GameState.get_build_description(_selected_building.building_type)
	var upgrade_cost: Dictionary = _selected_building.get_upgrade_cost()
	var upgrade_label: String = "Ameliorer"
	var upgrade_enabled: bool = _selected_building.can_upgrade() and GameState.can_afford(upgrade_cost)
	if _selected_building.can_upgrade():
		upgrade_label = "Ameliorer (%s)" % GameState.format_resource_pack(upgrade_cost, true)
		details += "\n" + _selected_building.get_upgrade_summary()
	else:
		upgrade_label = "Niveau max"
	var refund: Dictionary = _selected_building.get_destroy_refund()
	var destroy_label: String = "Detruire"
	var refund_text: String = GameState.format_resource_pack(refund, true)
	if refund_text != "":
		destroy_label += " (%s)" % refund_text
	return {
		"valid": true,
		"title": title,
		"status": status,
		"details": details,
		"action_label": action_label,
		"action_enabled": action_enabled,
		"upgrade_label": upgrade_label,
		"upgrade_enabled": upgrade_enabled,
		"destroy_label": destroy_label,
		"destroy_enabled": _selected_building.can_player_destroy(),
	}


func execute_selected_building_action() -> bool:
	if _selected_building == null or not is_instance_valid(_selected_building):
		return false
	if _selected_building.building_type == VillageBuilding.BuildingType.BARRACKS:
		return _selected_building.refill_barracks()
	return false


func upgrade_selected_building() -> bool:
	if _selected_building == null or not is_instance_valid(_selected_building):
		return false
	return _selected_building.upgrade()


func destroy_selected_building() -> bool:
	if _selected_building == null or not is_instance_valid(_selected_building):
		return false
	if not _selected_building.can_player_destroy():
		return false
	GameState.add_resources(_selected_building.get_destroy_refund())
	var target: VillageBuilding = _selected_building
	_selected_building = null
	_hide_building_panel()
	target.queue_free()
	return true


func _is_build_menu_open() -> bool:
	if hud and hud.has_method("is_build_menu_open"):
		return hud.call("is_build_menu_open")
	return false


func _toggle_door_panel() -> void:
	if hud and hud.has_method("toggle_door_panel"):
		if hud.has_method("hide_building_panel"):
			hud.call("hide_building_panel")
		hud.call("toggle_door_panel")


func _hide_door_panel() -> void:
	if hud and hud.has_method("hide_door_panel"):
		hud.call("hide_door_panel")


func _show_building_panel() -> void:
	if hud and hud.has_method("show_building_panel"):
		hud.call("show_building_panel")


func _hide_building_panel() -> void:
	if hud and hud.has_method("hide_building_panel"):
		hud.call("hide_building_panel")


func _on_production_timer() -> void:
	var alive: Array[VillageBuilding] = []
	for b in _buildings:
		if is_instance_valid(b):
			alive.append(b)
	_buildings = alive
	var production_pack: Dictionary = GameState.get_production_pack_from_buildings(_buildings)
	if production_pack.is_empty():
		return
	GameState.add_resources(production_pack)


func get_buildings_snapshot() -> Array[VillageBuilding]:
	return _buildings.duplicate()


func notify_building_upgraded(building: VillageBuilding) -> void:
	GameState.recompute_storage_caps(_buildings)
	if building and building.building_type == VillageBuilding.BuildingType.PATH:
		_refresh_path_visuals_near(building.cell)
	GameState.invalidate_navigation()


func notify_main_door_state_changed() -> void:
	_refresh_path_visuals_near(_get_main_door_connection_cell())
	GameState.invalidate_navigation()


func _get_main_door_connection_cell() -> Vector2i:
	return _world_to_cell(GameState.get_door_inside_entry())


func is_path_connected_to_neighbor(path_cell: Vector2i, offset: Vector2i) -> bool:
	var neighbor_cell: Vector2i = path_cell + offset
	var neighbor := _grid.get(neighbor_cell, null) as VillageBuilding
	if neighbor and is_instance_valid(neighbor) and neighbor.building_type == VillageBuilding.BuildingType.PATH:
		return true
	if offset == Vector2i(0, 1) and path_cell == _get_main_door_connection_cell():
		var main_door: VillageBuilding = _get_main_door()
		return main_door != null and is_instance_valid(main_door)
	return false


func _refresh_all_path_visuals() -> void:
	for building in _buildings:
		if is_instance_valid(building) and building.building_type == VillageBuilding.BuildingType.PATH:
			building.refresh_visual_state()


func _refresh_path_visuals_near(cell: Vector2i) -> void:
	var cells: Array[Vector2i] = [
		cell,
		cell + Vector2i(0, -1),
		cell + Vector2i(0, 1),
		cell + Vector2i(-1, 0),
		cell + Vector2i(1, 0),
		_get_main_door_connection_cell(),
	]
	for target_cell in cells:
		var building := _grid.get(target_cell, null) as VillageBuilding
		if building and is_instance_valid(building) and building.building_type == VillageBuilding.BuildingType.PATH:
			building.refresh_visual_state()


func repair_all() -> void:
	var damaged_buildings: Array[VillageBuilding] = []
	for b in _buildings:
		if is_instance_valid(b) and b.hp < b.max_hp:
			damaged_buildings.append(b)
	if damaged_buildings.is_empty():
		return
	damaged_buildings.sort_custom(func(a, b): return a.hp < b.hp)
	for building in damaged_buildings:
		var missing_hp: int = building.max_hp - building.hp
		var repair_cost: Dictionary = building.get_repair_cost(missing_hp)
		if GameState.can_afford(repair_cost):
			building.repair(missing_hp)
			GameState.spend(repair_cost)
