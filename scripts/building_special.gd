## Special building mechanics
## Door spikes, barbarian resurrection, wall conversion, garrison

extends Node


## Add spikes to door
func add_spikes(building: VillageBuilding) -> bool:
	if building.building_type != VillageBuilding.BuildingType.DOOR:
		return false
	building.is_spiked = true
	building._update_label()
	return true


## Get spike damage per second
func get_door_spike_damage_per_sec(building: VillageBuilding) -> float:
	if not building.is_spiked:
		return 0.0
	return 8.0


## Convert wall to guard tower
func convert_wall_to_tower(building: VillageBuilding) -> bool:
	if building.building_type != VillageBuilding.BuildingType.DEFENSIVE_WALL:
		return false
	
	building.building_type = VillageBuilding.BuildingType.GUARD_TOWER
	building.level = 1
	building._apply_visual()
	
	# Create tower AI
	var guard_tower_script = GDScript.new()
	guard_tower_script.source_code = load("res://scripts/guard_tower_ai.gd").source_code
	
	var guard_tower_ai = Node3D.new()
	guard_tower_ai.set_script(guard_tower_script)
	building.add_child(guard_tower_ai)
	guard_tower_ai.tower_building = building
	
	return true


## Resurrect a barbarian from this barracks
func resurrect_barbarian(building: VillageBuilding) -> bool:
	var barracks_id: int = building.get_instance_id()
	if not GameState.resurrect_barbarian(barracks_id):
		return false
	_spawn_barracks_soldiers(building, 1)
	return true


## Spawn initial garrison for barracks
func spawn_initial_garrison(building: VillageBuilding) -> void:
	if building.building_type != VillageBuilding.BuildingType.BARRACKS:
		return
	_spawn_barracks_soldiers(building, VillageBuilding.BARRACKS_MAX_SOLDIERS)


## Internal: spawn soldiers at barracks
func _spawn_barracks_soldiers(building: VillageBuilding, count: int) -> void:
	if count <= 0:
		return
	var allies: Node3D = building.get_tree().get_first_node_in_group("ally_units")
	if allies == null:
		return
	var spawn_center: Vector3 = building.global_position
	for i in count:
		var u: Barbarian = preload("res://scenes/barbarian.tscn").instantiate()
		u.allegiance = Unit.Allegiance.PLAYER
		u.hp = 100
		u.max_hp = 100
		u.move_speed = 5.0
		u.source_barracks_id = building.get_instance_id()
		u.set_guard_home(spawn_center)
		var offset: Vector3 = Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
		u.global_position = spawn_center + offset
		allies.add_child(u)
