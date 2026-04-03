extends Node
## Gère les boutons de construction et entraînement

@onready var mode_label: Label = $"../MarginContainer/VBox/ModeLabel"
@onready var build_grid: GridContainer = $"../MarginContainer/VBox/BuildGrid"

var _current_mode: VillageBuilding.BuildingType = VillageBuilding.BuildingType.GOLD_MINE


func _ready() -> void:
	build_grid.get_node("BtnGoldMine").pressed.connect(func(): _set_build_mode(VillageBuilding.BuildingType.GOLD_MINE))
	build_grid.get_node("BtnElixir").pressed.connect(func(): _set_build_mode(VillageBuilding.BuildingType.ELIXIR_COLLECTOR))
	build_grid.get_node("BtnFarm").pressed.connect(func(): _set_build_mode(VillageBuilding.BuildingType.FARM))
	build_grid.get_node("BtnGoldStorage").pressed.connect(func(): _set_build_mode(VillageBuilding.BuildingType.GOLD_STORAGE))
	build_grid.get_node("BtnElixirStorage").pressed.connect(func(): _set_build_mode(VillageBuilding.BuildingType.ELIXIR_STORAGE))
	build_grid.get_node("BtnCannon").pressed.connect(func(): _set_build_mode(VillageBuilding.BuildingType.CANNON))
	build_grid.get_node("BtnBarracks").pressed.connect(func(): _set_build_mode(VillageBuilding.BuildingType.BARRACKS))
	build_grid.get_node("BtnTownHall").pressed.connect(func(): _set_build_mode(VillageBuilding.BuildingType.TOWN_HALL))
	build_grid.get_node("BtnTrain").pressed.connect(_on_btn_train)
	
	_apply_button_icons()
	_set_build_mode(VillageBuilding.BuildingType.GOLD_MINE)


func _set_build_mode(building_type: VillageBuilding.BuildingType) -> void:
	_current_mode = building_type
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("set_build_mode"):
		village.set_build_mode(building_type)
	mode_label.text = "Placer : %s" % _get_building_name(building_type)


func _get_building_name(building_type: VillageBuilding.BuildingType) -> String:
	match building_type:
		VillageBuilding.BuildingType.GOLD_MINE:
			return "Mine d'or"
		VillageBuilding.BuildingType.ELIXIR_COLLECTOR:
			return "Collecteur d'élexir"
		VillageBuilding.BuildingType.CANNON:
			return "Canon"
		VillageBuilding.BuildingType.BARRACKS:
			return "Caserne"
		VillageBuilding.BuildingType.TOWN_HALL:
			return "Hôtel de ville"
		VillageBuilding.BuildingType.GOLD_STORAGE:
			return "Entrepôt d'or (+cap.)"
		VillageBuilding.BuildingType.ELIXIR_STORAGE:
			return "Réservoir d'élexir (+cap.)"
		VillageBuilding.BuildingType.FARM:
			return "Ferme (or + élexir)"
	return "?"


func _apply_button_icons() -> void:
	var buttons: Dictionary = {
		"BtnGoldMine": IconGenerator.create_gold_icon(),
		"BtnElixir": IconGenerator.create_elixir_icon(),
		"BtnFarm": IconGenerator.create_farm_icon(),
		"BtnGoldStorage": IconGenerator.create_storage_icon(),
		"BtnElixirStorage": IconGenerator.create_storage_icon(),
		"BtnCannon": IconGenerator.create_cannon_icon(),
		"BtnBarracks": IconGenerator.create_barracks_icon(),
		"BtnTownHall": IconGenerator.create_town_hall_icon(),
		"BtnTrain": IconGenerator.create_barbarian_icon(),
	}
	
	for btn_name: String in buttons:
		var btn: Button = build_grid.get_node(btn_name)
		btn.icon = buttons[btn_name]
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.expand_icon = true


func _on_btn_train() -> void:
	if not GameState.spend(GameState.TRAIN_BARBARIAN_COST):
		return
	
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village == null:
		GameState.add_resources(0, GameState.TRAIN_BARBARIAN_COST.get("elixir", 0))
		return
	
	var barracks: VillageBuilding = null
	for c in village.get_children():
		var b := c as VillageBuilding
		if b and is_instance_valid(b) and b.building_type == VillageBuilding.BuildingType.BARRACKS:
			barracks = b
			break
	
	if barracks == null:
		GameState.add_resources(0, GameState.TRAIN_BARBARIAN_COST.get("elixir", 0))
		return
	
	var allies: Node3D = get_tree().get_first_node_in_group("ally_units") as Node3D
	if allies == null:
		return
	
	var u: Barbarian = preload("res://scenes/barbarian.tscn").instantiate()
	u.allegiance = Unit.Allegiance.PLAYER
	u.hp = 100
	u.max_hp = 100
	u.move_speed = 5.0
	var offset: Vector3 = Vector3(randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0))
	u.global_position = barracks.global_position + offset
	allies.add_child(u)
	
	_set_build_mode(VillageBuilding.BuildingType.GOLD_MINE)


func get_current_mode() -> VillageBuilding.BuildingType:
	return _current_mode
