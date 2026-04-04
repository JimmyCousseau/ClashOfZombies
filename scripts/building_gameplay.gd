## Gameplay mechanics for VillageBuilding
## Handles health, damage, repair, upgrades

extends Node


## Get default HP for building type
func get_default_hp(building_type: int) -> int:
	match building_type:
		VillageBuilding.BuildingType.TOWN_HALL:
			return 800
		VillageBuilding.BuildingType.CANNON:
			return 350
		VillageBuilding.BuildingType.BARRACKS:
			return 400
		VillageBuilding.BuildingType.GOLD_STORAGE, VillageBuilding.BuildingType.ELIXIR_STORAGE:
			return 320
		VillageBuilding.BuildingType.FARM:
			return 220
		VillageBuilding.BuildingType.DOOR:
			return 600
		VillageBuilding.BuildingType.PATH:
			return 70
		VillageBuilding.BuildingType.WORKSHOP:
			return 280
		VillageBuilding.BuildingType.GUARD_TOWER:
			return 350
		VillageBuilding.BuildingType.DEFENSIVE_WALL:
			return 250
		_:
			return 250


## Get max level for building type
func get_max_level(building_type: int) -> int:
	match building_type:
		VillageBuilding.BuildingType.TOWN_HALL:
			return 4
		VillageBuilding.BuildingType.GOLD_MINE, VillageBuilding.BuildingType.ELIXIR_COLLECTOR, VillageBuilding.BuildingType.CANNON:
			return 4
		VillageBuilding.BuildingType.BARRACKS, VillageBuilding.BuildingType.GOLD_STORAGE, VillageBuilding.BuildingType.ELIXIR_STORAGE, VillageBuilding.BuildingType.FARM:
			return 3
		VillageBuilding.BuildingType.DOOR:
			return 1
		VillageBuilding.BuildingType.PATH:
			return 1
		VillageBuilding.BuildingType.WORKSHOP, VillageBuilding.BuildingType.GUARD_TOWER:
			return 2
		VillageBuilding.BuildingType.DEFENSIVE_WALL:
			return 1
	return 1


## Get attack radius for building type
func get_attack_radius(building_type: int) -> float:
	match building_type:
		VillageBuilding.BuildingType.CANNON:
			return 8.5
		VillageBuilding.BuildingType.GUARD_TOWER:
			return 10.0
	return 0.0


## Get cannon damage
func get_cannon_damage(level: int) -> int:
	return 20 + level * 5


## Apply damage to building
func take_damage(building: VillageBuilding, amount: int) -> void:
	building.hp = maxi(0, building.hp - amount)
	building._update_label()
	if building.hp <= 0:
		building._on_destroyed()


## Repair building
func repair(building: VillageBuilding, amount: int) -> void:
	var new_hp: int = mini(building.max_hp, building.hp + amount)
	building.hp = new_hp
	building._update_label()


## Get repair cost for amount of HP
func get_repair_cost(building: VillageBuilding, missing_hp: int) -> Dictionary:
	var base_cost: Dictionary = GameState.BUILD_COST.get(int(building.building_type), {})
	if base_cost.is_empty():
		return {}
	
	var ratio: float = float(missing_hp) / float(building.max_hp)
	var cost: Dictionary = {}
	for resource in base_cost.keys():
		cost[resource] = int(base_cost[resource] * ratio)
	return cost


## Get upgrade cost
func get_upgrade_cost(building: VillageBuilding) -> Dictionary:
	var base_cost: Dictionary = GameState.BUILD_COST.get(int(building.building_type), {})
	if base_cost.is_empty():
		return {}
	
	var multiplier: float = pow(1.2, float(building.level))
	var cost: Dictionary = {}
	for resource in base_cost.keys():
		cost[resource] = int(base_cost[resource] * multiplier)
	return cost


## Get barracks refill cost
func get_barracks_refill_cost(level: int) -> Dictionary:
	var base_cost: Dictionary = GameState.BARBARIAN_RESURRECTION_RATIO
	var cost: Dictionary = {}
	for resource in base_cost.keys():
		cost[resource] = int(base_cost[resource] * pow(1.1, float(level)))
	return cost
