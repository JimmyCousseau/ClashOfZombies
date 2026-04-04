extends BuildingBehavior
class_name BarracksBehavior

## Comportement des baraquements.
## Gère la garnison, le recrutement et la résurrection des soldats.

const BASE_MAX_SOLDIERS := 3


func _on_setup() -> void:
	building.call_deferred("_spawn_initial_garrison")


func get_max_soldiers() -> int:
	return BASE_MAX_SOLDIERS + maxi(building.level - 1, 0)


func get_active_soldier_count() -> int:
	var allies: Array = building.get_tree().get_nodes_in_group("allies")
	var count := 0
	for ally in allies:
		if ally is Barbarian and is_instance_valid(ally):
			if (ally as Barbarian).source_barracks_id == building.get_instance_id():
				count += 1
	return count


func get_missing_soldier_count() -> int:
	return maxi(0, get_max_soldiers() - get_active_soldier_count())


func get_refill_cost() -> Dictionary:
	return GameState.multiply_resource_pack(GameState.TRAIN_BARBARIAN_COST, get_missing_soldier_count())


func refill() -> bool:
	var missing := get_missing_soldier_count()
	if missing <= 0:
		return false
	if not GameState.spend(get_refill_cost()):
		return false
	spawn_soldiers(missing)
	return true


func spawn_soldiers(count: int) -> void:
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
		u.global_position = spawn_center + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
		allies.add_child(u)


func resurrect() -> bool:
	if not GameState.resurrect_barbarian(building.get_instance_id()):
		return false
	spawn_soldiers(1)
	return true


func get_effect_summary() -> String:
	return "Garnison max : %d" % get_max_soldiers()


func get_upgrade_summary() -> String:
	if not building.can_upgrade():
		return "Niveau maximum atteint."
	return "Garnison maximale augmentée."
