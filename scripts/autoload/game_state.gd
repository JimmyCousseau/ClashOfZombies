extends Node
## État global : ressources, coûts, production, géométrie village / patrouille.

signal resources_changed
signal wave_started(wave_index: int)
signal game_over

const GRID_SIZE := Vector2i(14, 14)
const CELL_SIZE := 2.0

## Épaisseur mur (m) — doit correspondre à `wall_ring.gd`
const WALL_THICKNESS := 1.15
const WALL_HEIGHT := 1.42
## Distance du centre jusqu’à la ligne de patrouille des zombies (au-delà du mur)
const PATROL_OUTSET := 0.95

const STORAGE_GOLD_BONUS := 650
const STORAGE_ELIXIR_BONUS := 650

const BUILD_COST: Dictionary = {
	VillageBuilding.BuildingType.TOWN_HALL: {"gold": 0, "elixir": 500},
	VillageBuilding.BuildingType.GOLD_MINE: {"gold": 150, "elixir": 0},
	VillageBuilding.BuildingType.ELIXIR_COLLECTOR: {"gold": 0, "elixir": 150},
	VillageBuilding.BuildingType.CANNON: {"gold": 200, "elixir": 100},
	VillageBuilding.BuildingType.BARRACKS: {"gold": 250, "elixir": 250},
	VillageBuilding.BuildingType.GOLD_STORAGE: {"gold": 120, "elixir": 120},
	VillageBuilding.BuildingType.ELIXIR_STORAGE: {"gold": 120, "elixir": 120},
	VillageBuilding.BuildingType.FARM: {"gold": 180, "elixir": 140},
}

const PRODUCTION: Dictionary = {
	VillageBuilding.BuildingType.GOLD_MINE: {"gold": 4, "elixir": 0},
	VillageBuilding.BuildingType.ELIXIR_COLLECTOR: {"gold": 0, "elixir": 4},
	VillageBuilding.BuildingType.FARM: {"gold": 3, "elixir": 2},
}

const TRAIN_BARBARIAN_COST := {"gold": 0, "elixir": 50}

var gold: int = 800
var elixir: int = 800
var gold_max: int = 5000
var elixir_max: int = 5000

var enemies_alive: int = 0
var is_paused: bool = false


func get_inner_half_extent() -> float:
	return float(GRID_SIZE.x) * CELL_SIZE * 0.5


## Rayon du cercle où les zombies tournent (hors muraille).
func get_patrol_ring_radius() -> float:
	return get_inner_half_extent() + WALL_THICKNESS + PATROL_OUTSET


func add_storage_bonus(add_gold_cap: bool, add_elixir_cap: bool) -> void:
	if add_gold_cap:
		gold_max += STORAGE_GOLD_BONUS
	if add_elixir_cap:
		elixir_max += STORAGE_ELIXIR_BONUS
	resources_changed.emit()


func remove_storage_bonus(remove_gold_cap: bool, remove_elixir_cap: bool) -> void:
	if remove_gold_cap:
		gold_max = maxi(2500, gold_max - STORAGE_GOLD_BONUS)
		gold = mini(gold, gold_max)
	if remove_elixir_cap:
		elixir_max = maxi(2500, elixir_max - STORAGE_ELIXIR_BONUS)
		elixir = mini(elixir, elixir_max)
	resources_changed.emit()


func can_afford(cost: Dictionary) -> bool:
	return gold >= cost.get("gold", 0) and elixir >= cost.get("elixir", 0)


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	gold -= cost.get("gold", 0)
	elixir -= cost.get("elixir", 0)
	resources_changed.emit()
	return true


func add_resources(g: int, e: int) -> void:
	gold = clampi(gold + g, 0, gold_max)
	elixir = clampi(elixir + e, 0, elixir_max)
	resources_changed.emit()


func tick_production_from_buildings(buildings: Array[VillageBuilding]) -> void:
	var g := 0
	var e := 0
	for b in buildings:
		if not is_instance_valid(b):
			continue
		var p: Dictionary = PRODUCTION.get(b.building_type, {})
		g += p.get("gold", 0)
		e += p.get("elixir", 0)
	add_resources(g, e)


func register_enemy() -> void:
	enemies_alive += 1


func unregister_enemy() -> void:
	enemies_alive = maxi(0, enemies_alive - 1)
