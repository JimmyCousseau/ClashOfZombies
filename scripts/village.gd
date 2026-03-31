extends Node3D
## Grille du village, placement des bâtiments, production.

const BUILDING_SCENE := preload("res://scenes/building.tscn")

var _grid: Dictionary = {} # Vector2i -> VillageBuilding
var _build_mode: VillageBuilding.BuildingType = VillageBuilding.BuildingType.GOLD_MINE
var _buildings: Array[VillageBuilding] = []

@onready var camera_rig: Node3D = $"../CameraRig"


func _ready() -> void:
	_place_starter_town_hall()
	_place_starter_door()
	$ProductionTimer.timeout.connect(_on_production_timer)


func set_build_mode(t: VillageBuilding.BuildingType) -> void:
	_build_mode = t


func notify_building_removed(c: Vector2i, b: VillageBuilding) -> void:
	_grid.erase(c)
	var i: int = _buildings.find(b)
	if i >= 0:
		_buildings.remove_at(i)


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


func _spawn_building_at_cell(t: VillageBuilding.BuildingType, cell: Vector2i, free: bool) -> void:
	if _grid.has(cell):
		return
	if t == VillageBuilding.BuildingType.TOWN_HALL and _has_town_hall():
		return
	if not free:
		var cost: Dictionary = GameState.BUILD_COST.get(t, {})
		if not GameState.spend(cost):
			return

	var b: VillageBuilding = BUILDING_SCENE.instantiate()
	b.building_type = t
	b.cell = cell
	b.position = _cell_to_world(cell)
	add_child(b)
	_grid[cell] = b
	_buildings.append(b)
	match t:
		VillageBuilding.BuildingType.GOLD_STORAGE:
			GameState.add_storage_bonus(true, false)
		VillageBuilding.BuildingType.ELIXIR_STORAGE:
			GameState.add_storage_bonus(false, true)
		_:
			pass
	if t == VillageBuilding.BuildingType.CANNON:
		var ai := CannonAI.new()
		ai.name = "CannonAI"
		b.add_child(ai)
		ai.setup(b)


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
			_try_place(mb.position)


func _try_place(screen_pos: Vector2) -> void:
	var cam: Camera3D = camera_rig.get_node("Camera3D") as Camera3D
	if cam == null:
		return
	var from := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return
	var t_hit: float = -from.y / dir.y
	if t_hit < 0:
		return
	var hit: Vector3 = from + dir * t_hit
	var cell := _world_to_cell(hit)
	if cell.x < 0 or cell.y < 0 or cell.x >= GameState.GRID_SIZE.x or cell.y >= GameState.GRID_SIZE.y:
		return
	if _grid.has(cell):
		return
	_spawn_building_at_cell(_build_mode, cell, false)


func _on_production_timer() -> void:
	var alive: Array[VillageBuilding] = []
	for b in _buildings:
		if is_instance_valid(b):
			alive.append(b)
	_buildings = alive
	GameState.tick_production_from_buildings(_buildings)


func get_buildings_snapshot() -> Array[VillageBuilding]:
	return _buildings.duplicate()


func repair_all() -> void:
	# Get all buildings that need repair, sorted by HP (lowest first)
	var damaged_buildings: Array[VillageBuilding] = []
	for b in _buildings:
		if is_instance_valid(b) and b.hp < b.max_hp:
			damaged_buildings.append(b)
	
	if damaged_buildings.is_empty():
		return
	
	# Sort by lowest HP first (prioritize most damaged)
	damaged_buildings.sort_custom(func(a, b): return a.hp < b.hp)
	
	var available_elixir: int = GameState.elixir
	
	# Try to repair each building in order
	for building in damaged_buildings:
		if available_elixir <= 0:
			break
		
		var missing_hp: int = building.max_hp - building.hp
		var repair_cost: int = building.get_repair_cost(missing_hp)
		
		if repair_cost <= available_elixir:
			# Can afford full repair
			building.repair(missing_hp)
			GameState.spend({"gold": 0, "elixir": repair_cost})
			available_elixir -= repair_cost
		else:
			# Partial repair with remaining elixir
			# Calculate how much HP we can restore with available elixir
			var cost_per_hp: float = GameState.REPAIR_COST_PER_HP.get(building.building_type, 1.0)
			var restorable_hp: int = int(available_elixir / cost_per_hp)
			
			if restorable_hp > 0:
				building.repair(restorable_hp)
				var actual_cost: int = building.get_repair_cost(restorable_hp)
				GameState.spend({"gold": 0, "elixir": actual_cost})
				available_elixir -= actual_cost
