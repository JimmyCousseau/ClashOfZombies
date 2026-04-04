extends Node
## État global : ressources de survie, géométrie du village et navigation.

signal resources_changed
signal wave_started(wave_index: int)
signal game_over
signal door_destroyed
signal exploration_completed(report: String)

const GRID_SIZE := Vector2i(14, 14)
const CELL_SIZE := 2.0

const WALL_THICKNESS := 1.15
const WALL_HEIGHT := 1.42
const PATROL_OUTSET := 0.95
const DOOR_OPENING_WIDTH := 1.5
const DOOR_PATH_MARGIN := 1.2
const NAV_CELL_SIZE := 1.0
const NAV_MARGIN := 6.0

const STORAGE_CAP_BONUS: Dictionary = {
	VillageBuilding.BuildingType.GOLD_STORAGE: {"wood": 700, "stone": 700, "food": 500},
	VillageBuilding.BuildingType.ELIXIR_STORAGE: {"iron": 700},
}

const BUILD_REFUND_RATIO: float = 0.35
const SPECIAL_ITEM_ORDER: PackedStringArray = ["medicine", "parts", "tools", "artifacts"]
const SPECIAL_ITEM_LABELS: Dictionary = {
	"medicine": "Trousse medicale",
	"parts": "Pieces mecaniques",
	"tools": "Outils rares",
	"artifacts": "Artefacts",
}
const BUILD_DESCRIPTIONS: Dictionary = {
	VillageBuilding.BuildingType.TOWN_HALL: "Centre du refuge. Plus solide a chaque amelioration.",
	VillageBuilding.BuildingType.GOLD_MINE: "Produit du bois a intervalles reguliers.",
	VillageBuilding.BuildingType.ELIXIR_COLLECTOR: "Extrait de la pierre pour le chantier.",
	VillageBuilding.BuildingType.CANNON: "Defense automatique contre les zombies.",
	VillageBuilding.BuildingType.BARRACKS: "Heberge la garnison exterieure.",
	VillageBuilding.BuildingType.GOLD_STORAGE: "Augmente la reserve de bois, pierre et nourriture.",
	VillageBuilding.BuildingType.ELIXIR_STORAGE: "Augmente la reserve maximale de fer.",
	VillageBuilding.BuildingType.FARM: "Produit de la nourriture a chaque cycle.",
	VillageBuilding.BuildingType.DOOR: "Controle l'entree du village.",
	VillageBuilding.BuildingType.PATH: "Relie les batiments et structure les allees.",
	VillageBuilding.BuildingType.WORKSHOP: "Fabrique des boulets de canon.",
	VillageBuilding.BuildingType.GUARD_TOWER: "Tour de surveillance qui tire des fleches.",
	VillageBuilding.BuildingType.DEFENSIVE_WALL: "Mur defensif convertible en tour de garde.",
}

const BUILD_COST: Dictionary = {
	VillageBuilding.BuildingType.TOWN_HALL: {"wood": 140, "stone": 120, "iron": 70},
	VillageBuilding.BuildingType.GOLD_MINE: {"wood": 55, "stone": 20, "iron": 0},
	VillageBuilding.BuildingType.ELIXIR_COLLECTOR: {"wood": 35, "stone": 55, "iron": 0},
	VillageBuilding.BuildingType.CANNON: {"wood": 35, "stone": 90, "iron": 50},
	VillageBuilding.BuildingType.BARRACKS: {"wood": 100, "stone": 45, "iron": 20},
	VillageBuilding.BuildingType.GOLD_STORAGE: {"wood": 75, "stone": 40, "iron": 0},
	VillageBuilding.BuildingType.ELIXIR_STORAGE: {"wood": 55, "stone": 35, "iron": 45},
	VillageBuilding.BuildingType.FARM: {"wood": 35, "stone": 15, "iron": 0},
	VillageBuilding.BuildingType.DOOR: {"wood": 90, "stone": 45, "iron": 20},
	VillageBuilding.BuildingType.PATH: {"wood": 6, "stone": 8, "iron": 0},
	VillageBuilding.BuildingType.WORKSHOP: {"wood": 50, "stone": 30, "iron": 20},
	VillageBuilding.BuildingType.GUARD_TOWER: {"wood": 60, "stone": 40, "iron": 25},
	VillageBuilding.BuildingType.DEFENSIVE_WALL: {"wood": 30, "stone": 40, "iron": 0},
}

const REPAIR_COST_PER_HP: Dictionary = {
	VillageBuilding.BuildingType.TOWN_HALL: {"wood": 0.5, "stone": 0.8, "iron": 0.25},
	VillageBuilding.BuildingType.GOLD_MINE: {"wood": 0.6, "stone": 0.15},
	VillageBuilding.BuildingType.ELIXIR_COLLECTOR: {"wood": 0.25, "stone": 0.7},
	VillageBuilding.BuildingType.CANNON: {"stone": 0.85, "iron": 0.45},
	VillageBuilding.BuildingType.BARRACKS: {"wood": 0.7, "stone": 0.2},
	VillageBuilding.BuildingType.GOLD_STORAGE: {"wood": 0.55, "stone": 0.35},
	VillageBuilding.BuildingType.ELIXIR_STORAGE: {"stone": 0.45, "iron": 0.55},
	VillageBuilding.BuildingType.FARM: {"wood": 0.7},
	VillageBuilding.BuildingType.DOOR: {"wood": 0.85, "iron": 0.2},
	VillageBuilding.BuildingType.PATH: {"stone": 0.2},
	VillageBuilding.BuildingType.WORKSHOP: {"wood": 0.5, "stone": 0.3, "iron": 0.15},
	VillageBuilding.BuildingType.GUARD_TOWER: {"wood": 0.6, "stone": 0.4, "iron": 0.2},
	VillageBuilding.BuildingType.DEFENSIVE_WALL: {"wood": 0.3, "stone": 0.4},
}

const PRODUCTION: Dictionary = {
	VillageBuilding.BuildingType.GOLD_MINE: {"wood": 4},
	VillageBuilding.BuildingType.ELIXIR_COLLECTOR: {"stone": 4},
	VillageBuilding.BuildingType.FARM: {"food": 5},
}

const TRAIN_BARBARIAN_COST := {"food": 35, "wood": 20}
const BARBARIAN_RESURRECTION_RATIO: float = 0.2
const CANNONBALL_CRAFT_COST := {"iron": 2}
const ARROW_CRAFT_COST := {"wood": 2}
const EXPLORATION_FOCUS_ORDER: PackedStringArray = ["wood", "stone", "iron", "food", "salvage"]

var wood: int = 280
var stone: int = 220
var iron: int = 90
var food: int = 150
var items: int = 0
var cannonballs: int = 0
var arrows: int = 0
var special_items: Dictionary = {
	"medicine": 0,
	"parts": 0,
	"tools": 0,
	"artifacts": 0,
}

var wood_max: int = 1800
var stone_max: int = 1800
var iron_max: int = 1400
var food_max: int = 1500
var cannonballs_max: int = 300
var arrows_max: int = 300

var dead_barbarians: Dictionary = {} # barracks_id -> count

var enemies_alive: int = 0
var is_paused: bool = false

var _nav_astar: AStarGrid2D = null
var _nav_dirty: bool = true
var _nav_extent: float = 0.0
var _nav_width: int = 0


func get_inner_half_extent() -> float:
	return float(GRID_SIZE.x) * CELL_SIZE * 0.5


func get_door_position() -> Vector3:
	if is_inside_tree():
		var village: Node = get_tree().get_first_node_in_group("village")
		if village and village.has_method("get_main_door_world_position"):
			var authored_position: Variant = village.call("get_main_door_world_position")
			if authored_position is Vector3:
				return authored_position as Vector3
	return Vector3(0, 0, get_inner_half_extent() + WALL_THICKNESS * 0.5)


func get_door_outside_entry() -> Vector3:
	return get_door_position() + Vector3(0, 0, WALL_THICKNESS * 0.5 + DOOR_PATH_MARGIN)


func get_door_inside_entry() -> Vector3:
	return get_door_position() - Vector3(0, 0, WALL_THICKNESS * 0.5 + DOOR_PATH_MARGIN)


func get_door_attack_anchor(from_world: Vector3) -> Vector3:
	if is_inside_village(from_world):
		return get_door_inside_entry()
	return get_door_outside_entry()


func get_outside_spawn_from_origin(origin: Vector3) -> Vector3:
	var planar := Vector2(origin.x, origin.z)
	if planar.length() < 0.15:
		planar = Vector2(0.0, 1.0)
	planar = planar.normalized()
	var radius: float = get_patrol_ring_radius() + 0.65
	return Vector3(planar.x * radius, 0.0, planar.y * radius)


func get_patrol_ring_radius() -> float:
	return get_inner_half_extent() + WALL_THICKNESS + PATROL_OUTSET


func is_inside_village(pos: Vector3) -> bool:
	var inner: float = get_inner_half_extent()
	return absf(pos.x) <= inner and absf(pos.z) <= inner


func is_in_door_corridor(pos: Vector3) -> bool:
	var half_width: float = DOOR_OPENING_WIDTH * 0.5 + 0.35
	return absf(pos.x) <= half_width


func get_current_utc_day_index() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


func get_next_utc_midnight_unix() -> int:
	var now: int = int(Time.get_unix_time_from_system())
	return int(now / 86400.0 + 1) * 86400


func get_resource_amount(resource_key: String) -> int:
	match resource_key:
		"wood":
			return wood
		"stone":
			return stone
		"iron":
			return iron
		"food":
			return food
		"items":
			return items
		"cannonballs":
			return cannonballs
		"arrows":
			return arrows
	return 0


func get_resource_max(resource_key: String) -> int:
	match resource_key:
		"wood":
			return wood_max
		"stone":
			return stone_max
		"iron":
			return iron_max
		"food":
			return food_max
		"items":
			return 9999
		"cannonballs":
			return cannonballs_max
		"arrows":
			return arrows_max
	return 0


func can_afford(cost: Dictionary) -> bool:
	for key in cost.keys():
		var resource_key: String = String(key)
		if get_resource_amount(resource_key) < int(cost[key]):
			return false
	return true


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for key in cost.keys():
		_set_resource_amount(String(key), get_resource_amount(String(key)) - int(cost[key]))
	resources_changed.emit()
	return true


func add_resources(pack: Dictionary) -> void:
	var changed: bool = false
	for key in pack.keys():
		var resource_key: String = String(key)
		var amount: int = int(pack[key])
		if amount == 0:
			continue
		var before: int = get_resource_amount(resource_key)
		_set_resource_amount(resource_key, before + amount)
		changed = changed or before != get_resource_amount(resource_key)
	if changed:
		resources_changed.emit()


func add_storage_bonus(building_type: VillageBuilding.BuildingType) -> void:
	var bonus: Dictionary = STORAGE_CAP_BONUS.get(building_type, {})
	_apply_storage_bonus(bonus, true)


func remove_storage_bonus(building_type: VillageBuilding.BuildingType) -> void:
	var bonus: Dictionary = STORAGE_CAP_BONUS.get(building_type, {})
	_apply_storage_bonus(bonus, false)


func get_production_pack_from_buildings(buildings: Array[VillageBuilding]) -> Dictionary:
	var pack: Dictionary = {}
	for b in buildings:
		if not is_instance_valid(b):
			continue
		var production: Dictionary = {}
		if b.has_method("get_production_pack"):
			production = b.call("get_production_pack")
		else:
			production = PRODUCTION.get(b.building_type, {})
		if production.is_empty():
			continue
		for key in production.keys():
			var resource_key: String = String(key)
			pack[resource_key] = int(pack.get(resource_key, 0)) + int(production[key])
	return pack


func tick_production_from_buildings(buildings: Array[VillageBuilding]) -> bool:
	var pack: Dictionary = get_production_pack_from_buildings(buildings)
	if pack.is_empty():
		return false
	add_resources(pack)
	return true


func recompute_storage_caps(buildings: Array[VillageBuilding]) -> void:
	wood_max = _get_default_resource_max("wood")
	stone_max = _get_default_resource_max("stone")
	iron_max = _get_default_resource_max("iron")
	food_max = _get_default_resource_max("food")
	for building in buildings:
		if not is_instance_valid(building):
			continue
		if building.has_method("get_storage_bonus_pack"):
			var bonus: Dictionary = building.call("get_storage_bonus_pack")
			for key in bonus.keys():
				var resource_key: String = String(key)
				_set_resource_max(resource_key, get_resource_max(resource_key) + int(bonus[key]))
	_set_resource_amount("wood", wood)
	_set_resource_amount("stone", stone)
	_set_resource_amount("iron", iron)
	_set_resource_amount("food", food)
	resources_changed.emit()


func get_repair_cost(building_type: VillageBuilding.BuildingType, amount: int) -> Dictionary:
	var ratios: Dictionary = REPAIR_COST_PER_HP.get(building_type, {})
	var cost: Dictionary = {}
	for key in ratios.keys():
		cost[String(key)] = int(ceil(float(amount) * float(ratios[key])))
	return cost


func get_upgrade_cost(building_type: VillageBuilding.BuildingType, current_level: int) -> Dictionary:
	var base_cost: Dictionary = BUILD_COST.get(building_type, {})
	var factor: float = 0.85 + float(maxi(current_level - 1, 0)) * 0.55
	var result: Dictionary = {}
	for key in base_cost.keys():
		var amount: int = int(ceil(float(base_cost[key]) * factor))
		if amount > 0:
			result[String(key)] = amount
	return result


func multiply_resource_pack(pack: Dictionary, factor: int) -> Dictionary:
	var result: Dictionary = {}
	for key in pack.keys():
		result[String(key)] = int(pack[key]) * maxi(0, factor)
	return result


func get_build_refund(building_type: VillageBuilding.BuildingType) -> Dictionary:
	var base_cost: Dictionary = BUILD_COST.get(building_type, {})
	var refund: Dictionary = {}
	for key in base_cost.keys():
		var resource_key: String = String(key)
		refund[resource_key] = int(floor(float(base_cost[key]) * BUILD_REFUND_RATIO))
	return refund


func get_build_description(building_type: VillageBuilding.BuildingType) -> String:
	return String(BUILD_DESCRIPTIONS.get(building_type, ""))


func format_resource_pack(pack: Dictionary, abbreviate: bool = false) -> String:
	var parts: Array[String] = []
	for key in ["wood", "stone", "iron", "food", "items"]:
		var amount: int = int(pack.get(key, 0))
		if amount <= 0:
			continue
		if abbreviate:
			match key:
				"wood":
					parts.append("%dB" % amount)
				"stone":
					parts.append("%dP" % amount)
				"iron":
					parts.append("%dF" % amount)
				"food":
					parts.append("%dN" % amount)
				"items":
					parts.append("%dObj" % amount)
		else:
			match key:
				"wood":
					parts.append("%d bois" % amount)
				"stone":
					parts.append("%d pierre" % amount)
				"iron":
					parts.append("%d fer" % amount)
				"food":
					parts.append("%d nourriture" % amount)
				"items":
					parts.append("%d objets" % amount)
	return " ".join(parts) if abbreviate else ", ".join(parts)


func get_special_items_snapshot() -> Dictionary:
	return special_items.duplicate()


func get_inventory_text() -> String:
	var lines: Array[String] = []
	lines.append("Bois : %d / %d" % [wood, wood_max])
	lines.append("Pierre : %d / %d" % [stone, stone_max])
	lines.append("Fer : %d / %d" % [iron, iron_max])
	lines.append("Nourriture : %d / %d" % [food, food_max])
	lines.append("Objets speciaux : %d" % items)
	lines.append("Boulets de canon : %d" % cannonballs)
	lines.append("Fleches : %d" % arrows)
	lines.append("")
	lines.append("Inventaire special :")
	for key in SPECIAL_ITEM_ORDER:
		lines.append("- %s : %d" % [SPECIAL_ITEM_LABELS.get(key, key), int(special_items.get(key, 0))])
	return "\n".join(lines)


func add_special_items(pack: Dictionary) -> void:
	var changed: bool = false
	for key in SPECIAL_ITEM_ORDER:
		var amount: int = int(pack.get(key, 0))
		if amount <= 0:
			continue
		special_items[key] = int(special_items.get(key, 0)) + amount
		changed = true
	if not changed:
		return
	items = 0
	for key in SPECIAL_ITEM_ORDER:
		items += int(special_items.get(key, 0))
	resources_changed.emit()


func resolve_exploration(focus: String, day_index: int, loot_scale: float = 1.0) -> Dictionary:
	var normalized_focus: String = focus
	if not EXPLORATION_FOCUS_ORDER.has(normalized_focus):
		normalized_focus = "wood"
	var scale: float = 1.0 + float(maxi(day_index - 1, 0)) * 0.12
	scale *= clampf(loot_scale, 0.2, 1.0)
	var loot := {"wood": 0, "stone": 0, "iron": 0, "food": 0, "items": 0}
	match normalized_focus:
		"wood":
			loot["wood"] += int(round(randf_range(28.0, 48.0) * scale))
		"stone":
			loot["stone"] += int(round(randf_range(24.0, 44.0) * scale))
		"iron":
			loot["iron"] += int(round(randf_range(18.0, 34.0) * scale))
		"food":
			loot["food"] += int(round(randf_range(24.0, 40.0) * scale))
		"salvage":
			loot["items"] += 1 + randi() % 2
	for resource_key in ["wood", "stone", "iron", "food"]:
		if resource_key == normalized_focus:
			continue
		if randf() < 0.55:
			var amount: int = 0
			match resource_key:
				"wood":
					amount = int(round(randf_range(4.0, 14.0) * scale))
				"stone":
					amount = int(round(randf_range(3.0, 12.0) * scale))
				"iron":
					amount = int(round(randf_range(2.0, 9.0) * scale))
				"food":
					amount = int(round(randf_range(3.0, 12.0) * scale))
			loot[resource_key] += amount
	if randf() < 0.35 + float(day_index) * 0.02:
		loot["items"] += 1
	var special_pack: Dictionary = _roll_special_items(int(loot["items"]), normalized_focus)
	var resource_pack: Dictionary = loot.duplicate()
	resource_pack.erase("items")
	add_resources(resource_pack)
	add_special_items(special_pack)
	var report: String = _format_exploration_report(normalized_focus, loot)
	exploration_completed.emit(report)
	return {"loot": loot, "report": report}


func find_path(from_world: Vector3, to_world: Vector3, target_radius: float = 0.0) -> Array[Vector3]:
	var astar := _get_navigation_grid()
	var start_cell: Vector2i = _world_to_nav_cell(from_world)
	var goal_cell: Vector2i = _world_to_nav_cell(to_world)
	var start_walkable: Vector2i = _find_nearest_walkable_cell(astar, start_cell, from_world, 3)
	var goal_walkable: Vector2i = _find_nearest_walkable_cell(astar, goal_cell, to_world, maxi(2, int(ceil(target_radius / NAV_CELL_SIZE)) + 3))
	if start_walkable == Vector2i(-1, -1) or goal_walkable == Vector2i(-1, -1):
		return []
	var cell_path: Array[Vector2i] = astar.get_id_path(start_walkable, goal_walkable)
	if cell_path.is_empty():
		return []
	if cell_path.size() == 1:
		return [Vector3(to_world.x, 0.0, to_world.z)]
	var world_path: Array[Vector3] = []
	for i in cell_path.size():
		if i == 0:
			continue
		world_path.append(_nav_cell_to_world(cell_path[i]))
	return world_path


func invalidate_navigation() -> void:
	_nav_dirty = true


func register_enemy() -> void:
	enemies_alive += 1


func unregister_enemy() -> void:
	enemies_alive = maxi(0, enemies_alive - 1)


func _apply_storage_bonus(bonus: Dictionary, add_bonus: bool) -> void:
	if bonus.is_empty():
		return
	for key in bonus.keys():
		var resource_key: String = String(key)
		var delta: int = int(bonus[key])
		if add_bonus:
			_set_resource_max(resource_key, get_resource_max(resource_key) + delta)
		else:
			_set_resource_max(resource_key, maxi(_get_default_resource_max(resource_key), get_resource_max(resource_key) - delta))
			_set_resource_amount(resource_key, mini(get_resource_amount(resource_key), get_resource_max(resource_key)))
	resources_changed.emit()


func _get_default_resource_max(resource_key: String) -> int:
	match resource_key:
		"wood":
			return 1800
		"stone":
			return 1800
		"iron":
			return 1400
		"food":
			return 1500
		"cannonballs":
			return 300
		"arrows":
			return 300
		"items":
			return 9999
	return 0


func _set_resource_amount(resource_key: String, value: int) -> void:
	match resource_key:
		"wood":
			wood = clampi(value, 0, wood_max)
		"stone":
			stone = clampi(value, 0, stone_max)
		"iron":
			iron = clampi(value, 0, iron_max)
		"food":
			food = clampi(value, 0, food_max)
		"cannonballs":
			cannonballs = clampi(value, 0, cannonballs_max)
		"arrows":
			arrows = clampi(value, 0, arrows_max)
		"items":
			items = maxi(0, value)


func _set_resource_max(resource_key: String, value: int) -> void:
	match resource_key:
		"wood":
			wood_max = value
		"stone":
			stone_max = value
		"iron":
			iron_max = value
		"food":
			food_max = value
		"cannonballs":
			cannonballs_max = value
		"arrows":
			arrows_max = value


func _format_exploration_report(focus: String, loot: Dictionary) -> String:
	var labels := {
		"wood": "bois",
		"stone": "pierre",
		"iron": "fer",
		"food": "nourriture",
		"salvage": "fouille",
	}
	var parts: Array[String] = []
	for key in ["wood", "stone", "iron", "food", "items"]:
		var amount: int = int(loot.get(key, 0))
		if amount <= 0:
			continue
		match key:
			"wood":
				parts.append("%d bois" % amount)
			"stone":
				parts.append("%d pierre" % amount)
			"iron":
				parts.append("%d fer" % amount)
			"food":
				parts.append("%d nourriture" % amount)
			"items":
				parts.append("%d objets" % amount)
	if parts.is_empty():
		return "Exploration %s : rien trouvé." % labels.get(focus, "survie")
	return "Exploration %s : %s." % [labels.get(focus, "survie"), ", ".join(parts)]


func _roll_special_items(total_count: int, focus: String) -> Dictionary:
	var remaining: int = maxi(0, total_count)
	var rolled: Dictionary = {
		"medicine": 0,
		"parts": 0,
		"tools": 0,
		"artifacts": 0,
	}
	while remaining > 0:
		var roll: float = randf()
		var key: String = "parts"
		match focus:
			"food":
				if roll < 0.45:
					key = "medicine"
				elif roll < 0.75:
					key = "tools"
				elif roll < 0.95:
					key = "parts"
				else:
					key = "artifacts"
			"wood":
				if roll < 0.45:
					key = "tools"
				elif roll < 0.8:
					key = "parts"
				elif roll < 0.95:
					key = "medicine"
				else:
					key = "artifacts"
			"iron":
				if roll < 0.52:
					key = "parts"
				elif roll < 0.8:
					key = "tools"
				elif roll < 0.95:
					key = "medicine"
				else:
					key = "artifacts"
			"salvage":
				if roll < 0.42:
					key = "parts"
				elif roll < 0.72:
					key = "tools"
				elif roll < 0.9:
					key = "medicine"
				else:
					key = "artifacts"
			_:
				if roll < 0.4:
					key = "parts"
				elif roll < 0.7:
					key = "tools"
				elif roll < 0.92:
					key = "medicine"
				else:
					key = "artifacts"
		rolled[key] = int(rolled.get(key, 0)) + 1
		remaining -= 1
	return rolled


func register_dead_barbarian(barracks_id: int) -> void:
	dead_barbarians[barracks_id] = int(dead_barbarians.get(barracks_id, 0)) + 1


func get_dead_barbarian_count(barracks_id: int) -> int:
	return int(dead_barbarians.get(barracks_id, 0))


func can_resurrect_barbarian(barracks_id: int) -> bool:
	return get_dead_barbarian_count(barracks_id) > 0


func get_resurrection_cost(_barracks_id: int) -> Dictionary:
	var base_cost: Dictionary = TRAIN_BARBARIAN_COST.duplicate()
	var result: Dictionary = {}
	for key in base_cost.keys():
		result[key] = int(ceil(float(base_cost[key]) * BARBARIAN_RESURRECTION_RATIO))
	return result


func resurrect_barbarian(barracks_id: int) -> bool:
	if not can_resurrect_barbarian(barracks_id):
		return false
	var cost: Dictionary = get_resurrection_cost(barracks_id)
	if not spend(cost):
		return false
	dead_barbarians[barracks_id] = int(dead_barbarians.get(barracks_id, 0)) - 1
	return true


func _get_navigation_grid() -> AStarGrid2D:
	if _nav_astar == null or _nav_dirty:
		_nav_astar = _build_navigation_grid()
		_nav_dirty = false
	return _nav_astar


func _build_navigation_grid() -> AStarGrid2D:
	_nav_extent = get_patrol_ring_radius() + NAV_MARGIN
	_nav_width = int(ceil((_nav_extent * 2.0) / NAV_CELL_SIZE)) + 1
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, _nav_width, _nav_width)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	var blockers: Array[Dictionary] = _collect_building_blockers()
	for x in _nav_width:
		for y in _nav_width:
			var cell := Vector2i(x, y)
			var world: Vector3 = _nav_cell_to_world(cell)
			if _is_nav_point_blocked(world, blockers):
				astar.set_point_solid(cell, true)
	return astar


func _collect_building_blockers() -> Array[Dictionary]:
	var blockers: Array[Dictionary] = []
	var village: Node3D = get_tree().get_first_node_in_group("village")
	if village == null:
		return blockers
	for child in village.get_children():
		if child is VillageBuilding and is_instance_valid(child):
			var building := child as VillageBuilding
			if building.is_destroyed:
				continue
			var extents: Vector2 = building.get_blocking_half_extents()
			if extents.x <= 0.01 or extents.y <= 0.01:
				continue
			blockers.append({
				"pos": building.global_position,
				"extents": extents,
			})
	return blockers


func _is_nav_point_blocked(world: Vector3, blockers: Array[Dictionary]) -> bool:
	if _is_wall_blocked(world):
		return true
	for blocker in blockers:
		var pos: Vector3 = blocker["pos"]
		var extents: Vector2 = blocker["extents"]
		if absf(world.x - pos.x) <= extents.x and absf(world.z - pos.z) <= extents.y:
			return true
	return false


func _is_wall_blocked(world: Vector3) -> bool:
	var inner: float = get_inner_half_extent()
	var outer: float = inner + WALL_THICKNESS
	var in_north_wall: bool = world.z >= -outer and world.z <= -inner and absf(world.x) <= outer
	if in_north_wall:
		return true
	var in_south_wall: bool = world.z >= inner and world.z <= outer and absf(world.x) <= outer
	if in_south_wall and absf(world.x) > DOOR_OPENING_WIDTH * 0.5:
		return true
	var in_west_wall: bool = world.x >= -outer and world.x <= -inner and absf(world.z) <= outer
	if in_west_wall:
		return true
	var in_east_wall: bool = world.x >= inner and world.x <= outer and absf(world.z) <= outer
	return in_east_wall


func _find_nearest_walkable_cell(astar: AStarGrid2D, origin: Vector2i, target_world: Vector3, max_radius: int) -> Vector2i:
	var best: Vector2i = Vector2i(-1, -1)
	var best_dist: float = INF
	for radius in range(0, max_radius + 1):
		for x in range(origin.x - radius, origin.x + radius + 1):
			for y in range(origin.y - radius, origin.y + radius + 1):
				var cell := Vector2i(x, y)
				if not _is_nav_cell_in_bounds(cell, astar.region.size.x):
					continue
				if astar.is_point_solid(cell):
					continue
				var world: Vector3 = _nav_cell_to_world(cell)
				var dist: float = world.distance_to(target_world)
				if dist < best_dist:
					best = cell
					best_dist = dist
		if best != Vector2i(-1, -1):
			return best
	return best


func _is_nav_cell_in_bounds(cell: Vector2i, width: int) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < width


func _world_to_nav_cell(world: Vector3) -> Vector2i:
	if _nav_width <= 0:
		_nav_extent = get_patrol_ring_radius() + NAV_MARGIN
		_nav_width = int(ceil((_nav_extent * 2.0) / NAV_CELL_SIZE)) + 1
	var fx: float = (world.x + _nav_extent) / NAV_CELL_SIZE
	var fy: float = (world.z + _nav_extent) / NAV_CELL_SIZE
	return Vector2i(clampi(int(round(fx)), 0, _nav_width - 1), clampi(int(round(fy)), 0, _nav_width - 1))


func _nav_cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * NAV_CELL_SIZE - _nav_extent, 0.0, cell.y * NAV_CELL_SIZE - _nav_extent)
