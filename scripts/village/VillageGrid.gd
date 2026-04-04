@tool
extends Node3D
## Orchestrateur de la grille du village.
## Ne contient aucune logique métier — tout est délégué aux modules.

const BUILDING_SCENE := preload("res://scenes/building.tscn")
const EDITOR_PREVIEW_ROOT_NAME  := "_EditorPreview"
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
	VillageBuilding.BuildingType.WORKSHOP,
	VillageBuilding.BuildingType.GUARD_TOWER,
]

# Modules
var grid_map:           VillageGridMap
var building_placer:    BuildingPlacer
var production_manager: ProductionManager
var hero_manager:       HeroManager
var input_handler:      InputHandler
var selection_manager:  SelectionManager
var grid_preview:       GridPreview
var path_visuals:       PathVisuals

var _build_mode: int = -1

@onready var camera_rig: Node3D = $"../CameraRig"
@onready var hud: Control       = $"../UI/HUD"


func _ready() -> void:
	if Engine.is_editor_hint():
		if _has_authored_starter_layout():
			_clear_editor_preview()
		else:
			_rebuild_editor_preview()
		return

	_init_modules()
	_clear_editor_preview()
	_register_authored_starter_layout()

	if not grid_map.has_town_hall():
		var center := Vector2i(int(GameState.GRID_SIZE.x / 2.0), int(GameState.GRID_SIZE.y / 2.0))
		building_placer.spawn_at_cell(VillageBuilding.BuildingType.TOWN_HALL, center, true)
	if grid_map.get_main_door() == null:
		building_placer.spawn_starter_door()

	hero_manager.spawn()
	GameState.recompute_storage_caps(grid_map.get_buildings())
	path_visuals.refresh_all()


func _init_modules() -> void:
	grid_map = VillageGridMap.new()
	add_child(grid_map)

	building_placer = BuildingPlacer.new()
	add_child(building_placer)
	building_placer.setup(grid_map, self)

	production_manager = ProductionManager.new()
	add_child(production_manager)
	production_manager.setup(grid_map, $ProductionTimer)

	hero_manager = HeroManager.new()
	add_child(hero_manager)
	hero_manager.setup(grid_map, self)

	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.primary_action.connect(_on_primary_action)

	selection_manager = SelectionManager.new()
	add_child(selection_manager)
	selection_manager.setup(grid_map, hero_manager, hud)

	grid_preview = GridPreview.new()
	add_child(grid_preview)
	grid_preview.setup(grid_map)

	path_visuals = PathVisuals.new()
	add_child(path_visuals)
	path_visuals.setup(grid_map)


# ---------------------------------------------------------------------------
# Starter layout
# ---------------------------------------------------------------------------

func _has_authored_starter_layout() -> bool:
	for child in get_children():
		if child is VillageBuilding:
			return true
	return false


func _register_authored_starter_layout() -> void:
	for child in get_children():
		if not (child is VillageBuilding):
			continue
		var b := child as VillageBuilding
		if not is_instance_valid(b):
			continue
		if b.building_type != VillageBuilding.BuildingType.DOOR:
			b.cell = grid_map.world_to_cell(b.position)
			grid_map.register(b.cell, b)
		else:
			grid_map.register_no_cell(b)


# ---------------------------------------------------------------------------
# Input → action
# ---------------------------------------------------------------------------

func _on_primary_action(screen_pos: Vector2) -> void:
	var cam: Camera3D = camera_rig.get_node("Camera3D") as Camera3D
	if cam == null:
		return

	# 1. Clic sur un bâtiment
	var clicked := _raycast_building(cam, screen_pos)
	if clicked:
		selection_manager.hide_door_panel()
		if clicked.building_type == VillageBuilding.BuildingType.DOOR and clicked.is_main_village_door():
			selection_manager.deselect()
			selection_manager.toggle_door_panel()
			return
		if clicked.building_type == VillageBuilding.BuildingType.DEFENSIVE_WALL:
			selection_manager.deselect()
			clicked.convert_wall_to_tower()
			return
		selection_manager.select(clicked)
		return

	# 2. Clic sur le sol
	var hit: Variant = _raycast_ground(cam, screen_pos)
	selection_manager.hide_door_panel()
	if hit == null:
		return

	# Porte détruite au sol
	var door: VillageBuilding = grid_map.get_main_door()
	if door and door.is_destroyed and hit.distance_to(GameState.get_door_position()) <= 1.45:
		selection_manager.deselect()
		selection_manager.toggle_door_panel()
		return

	var cell: Vector2i = grid_map.world_to_cell(hit)

	# Mode construction
	if _is_build_menu_open() and _build_mode >= 0:
		if building_placer.try_place_at_world(hit, _build_mode):
			selection_manager.deselect()
			path_visuals.refresh_near(cell)
			GameState.recompute_storage_caps(grid_map.get_buildings())
			if hud and hud.has_method("on_build_placed"):
				hud.call("on_build_placed")
		return

	# Sélection via cellule
	var cell_building: VillageBuilding = grid_map.get_building_at(cell)
	if cell_building and is_instance_valid(cell_building):
		selection_manager.select(cell_building)
		return

	# Déplacement héros
	selection_manager.deselect()
	if not _is_build_menu_open():
		hero_manager.move_to(hit)


# ---------------------------------------------------------------------------
# Raycasts
# ---------------------------------------------------------------------------

func _raycast_building(cam: Camera3D, screen_pos: Vector2) -> VillageBuilding:
	var from := cam.project_ray_origin(screen_pos)
	var to   := from + cam.project_ray_normal(screen_pos) * 200.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Variant = hit.get("collider", null)
	if collider is VillageBuilding:
		return collider as VillageBuilding
	return null


func _raycast_ground(cam: Camera3D, screen_pos: Vector2) -> Variant:
	var from := cam.project_ray_origin(screen_pos)
	var dir  := cam.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return null
	var t := -from.y / dir.y
	if t < 0:
		return null
	return from + dir * t


# ---------------------------------------------------------------------------
# Mode construction
# ---------------------------------------------------------------------------

func set_build_mode(t: int) -> void:
	_build_mode = t
	grid_preview.show_for(t)


func clear_build_mode() -> void:
	_build_mode = -1
	grid_preview.hide_preview()


func _is_build_menu_open() -> bool:
	if hud and hud.has_method("is_build_menu_open"):
		return hud.call("is_build_menu_open")
	return false


# ---------------------------------------------------------------------------
# Callbacks notifiés par les bâtiments
# ---------------------------------------------------------------------------

func notify_building_removed(c: Vector2i, b: VillageBuilding) -> void:
	grid_map.unregister(c, b)
	if selection_manager.get_selected() == b:
		selection_manager.deselect()
	GameState.recompute_storage_caps(grid_map.get_buildings())
	path_visuals.refresh_near(c)
	GameState.invalidate_navigation()


func notify_building_upgraded(b: VillageBuilding) -> void:
	GameState.recompute_storage_caps(grid_map.get_buildings())
	if b and b.building_type == VillageBuilding.BuildingType.PATH:
		path_visuals.refresh_near(b.cell)
	GameState.invalidate_navigation()


func notify_main_door_state_changed() -> void:
	path_visuals.refresh_near(grid_map.get_main_door_connection_cell())
	GameState.invalidate_navigation()


# Délégué aux chemins pour savoir s'ils sont connectés
func is_path_connected_to_neighbor(path_cell: Vector2i, offset: Vector2i) -> bool:
	return grid_map.is_path_connected_to_neighbor(path_cell, offset)


# ---------------------------------------------------------------------------
# API publique (héros / porte) — délégation directe
# ---------------------------------------------------------------------------

func get_main_door_world_position() -> Vector3:
	for child in get_children():
		if child is VillageBuilding:
			var b := child as VillageBuilding
			if b and is_instance_valid(b) and b.building_type == VillageBuilding.BuildingType.DOOR:
				return b.global_position if b.is_inside_tree() else global_position + b.position
	return Vector3(0, 0, GameState.get_inner_half_extent() + GameState.WALL_THICKNESS * 0.5)


func command_hero_move(world_pos: Vector3)   -> void:   hero_manager.move_to(world_pos)
func send_hero_on_exploration()              -> void:   hero_manager.send_on_exploration()
func execute_hero_door_action()              -> bool:   return hero_manager.execute_door_action()
func cycle_hero_focus()                      -> String: return hero_manager.cycle_focus()
func get_hero_focus_label()                  -> String: return hero_manager.get_focus_label()
func get_hero_status_text()                  -> String: return hero_manager.get_status_text()
func get_hero_door_action_label()            -> String: return hero_manager.get_door_action_label()
func can_execute_hero_door_action()          -> bool:   return hero_manager.can_execute_door_action()
func get_door_panel_info()                   -> Dictionary: return selection_manager.get_door_panel_info()
func get_selected_building_panel_info()      -> Dictionary: return selection_manager.get_building_panel_info()
func execute_selected_building_action()      -> bool:   return selection_manager.execute_action()
func upgrade_selected_building()             -> bool:   return selection_manager.upgrade()
func destroy_selected_building()             -> bool:   return selection_manager.destroy()
func get_automatic_production_pack()         -> Dictionary: return production_manager.get_current_production_pack()
func get_buildings_snapshot()                -> Array[VillageBuilding]: return grid_map.get_buildings().duplicate()


func repair_all() -> void:
	var damaged: Array[VillageBuilding] = []
	for b in grid_map.get_buildings():
		if is_instance_valid(b) and b.hp < b.max_hp:
			damaged.append(b)
	if damaged.is_empty():
		return
	damaged.sort_custom(func(a, b): return a.hp < b.hp)
	for b in damaged:
		var missing := b.max_hp - b.hp
		var cost    := b.get_repair_cost(missing)
		if GameState.can_afford(cost):
			b.repair(missing)
			GameState.spend(cost)


func debug_damage_main_door(amount: int = 250) -> bool:
	var door: VillageBuilding = grid_map.get_main_door()
	if door == null or not is_instance_valid(door) or door.is_destroyed:
		return false
	door.take_damage(maxi(1, amount))
	return true


# ---------------------------------------------------------------------------
# Éditeur
# ---------------------------------------------------------------------------

func _rebuild_editor_preview() -> void:
	_clear_editor_preview()
	var root := Node3D.new()
	root.name = EDITOR_PREVIEW_ROOT_NAME
	add_child(root)
	for i in EDITOR_PREVIEW_BUILDING_TYPES.size():
		var b: VillageBuilding = BUILDING_SCENE.instantiate()
		b.building_type = EDITOR_PREVIEW_BUILDING_TYPES[i] as VillageBuilding.BuildingType
		b.position = _editor_preview_pos(i)
		if b.building_type == VillageBuilding.BuildingType.PATH:
			b.cell = Vector2i(i, 0)
		root.add_child(b)
	for scene in [preload("res://scenes/hero.tscn"), preload("res://scenes/barbarian.tscn"), preload("res://scenes/zombie.tscn")]:
		var n: Node3D = scene.instantiate()
		var index: int
		if scene == preload("res://scenes/hero.tscn"):
			index = 0
		elif scene == preload("res://scenes/barbarian.tscn"):
			index = 1
		else:
			index = 2
		n.position = Vector3([-4.0, 0.0, 4.0][index], 0.0, 6.0)
		root.add_child(n)


func _clear_editor_preview() -> void:
	var root := get_node_or_null(EDITOR_PREVIEW_ROOT_NAME)
	if root:
		root.free()


func _editor_preview_pos(index: int) -> Vector3:
	var col := index % 5
	var row := int(index / 5.0)
	return Vector3((float(col) - 2.0) * 6.0, 0.0, -8.0 - float(row) * 6.0)
