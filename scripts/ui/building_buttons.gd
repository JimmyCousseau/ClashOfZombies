extends Node
## Gère la liste de cartes de construction.

const BUILD_CARDS: Array[Dictionary] = [
	{
		"type": VillageBuilding.BuildingType.GOLD_MINE,
		"title": "Scierie",
		"description": "Produit du bois pour les constructions et les reparations.",
	},
	{
		"type": VillageBuilding.BuildingType.ELIXIR_COLLECTOR,
		"title": "Carrière",
		"description": "Extrait de la pierre a chaque cycle de production.",
	},
	{
		"type": VillageBuilding.BuildingType.FARM,
		"title": "Potager",
		"description": "Genere de la nourriture pour la survie et la garnison.",
	},
	{
		"type": VillageBuilding.BuildingType.GOLD_STORAGE,
		"title": "Entrepôt",
		"description": "Augmente la reserve de bois, pierre et nourriture.",
	},
	{
		"type": VillageBuilding.BuildingType.ELIXIR_STORAGE,
		"title": "Forge",
		"description": "Augmente le stockage de fer et le travail du metal.",
	},
	{
		"type": VillageBuilding.BuildingType.CANNON,
		"title": "Tourelle",
		"description": "Defense automatique contre les vagues nocturnes.",
	},
	{
		"type": VillageBuilding.BuildingType.BARRACKS,
		"title": "Abri",
		"description": "Maintient la garnison exterieure et permet de la reformer.",
	},
	{
		"type": VillageBuilding.BuildingType.TOWN_HALL,
		"title": "Refuge",
		"description": "Centre du village. Plus solide et plus resistant aux assauts.",
	},
	{
		"type": VillageBuilding.BuildingType.PATH,
		"title": "Chemin",
		"description": "Structure les allees du village et fusionne avec les routes voisines.",
	},
	{
		"type": VillageBuilding.BuildingType.GUARD_TOWER,
		"title": "Tour d'Archer",
		"description": "Tour de defense tirable depuis les coins et pres de la porte.",
	},
	{
		"type": VillageBuilding.BuildingType.WORKSHOP,
		"title": "Atelier",
		"description": "Fabrique les ressources necessaires pour les tours (boulets, fleches).",
	},
]

@onready var mode_label: Label = $"../MarginContainer/VBox/ModeLabel"
@onready var build_list: VBoxContainer = $"../MarginContainer/VBox/BuildScroll/BuildList"
@onready var mission_button: Button = $"../MarginContainer/VBox/BtnMissionFocus"

var _current_mode: int = -1
var _report_timer: float = 0.0
var _report_text: String = ""
var _mission_refresh_timer: float = 0.0
var _build_buttons: Dictionary = {}
var _build_card_data: Dictionary = {}


func _ready() -> void:
	mission_button.pressed.connect(_on_btn_cycle_mission)
	GameState.exploration_completed.connect(_on_exploration_completed)
	_build_cards()
	call_deferred("_refresh_mission_button")
	clear_build_selection()


func _build_cards() -> void:
	for child in build_list.get_children():
		child.queue_free()
	_build_buttons.clear()
	_build_card_data.clear()
	for card in BUILD_CARDS:
		var building_type: int = int(card["type"])
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0.0, 94.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon = _get_card_icon(building_type)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = false
		button.clip_text = false
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.pressed.connect(func(): _set_build_mode(building_type))
		_style_card_button(button)
		build_list.add_child(button)
		_build_buttons[building_type] = button
		_build_card_data[building_type] = card.duplicate(true)
	_refresh_button_texts()


func _style_card_button(button: Button) -> void:
	UIStyles.style_button(button)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_constant_override("h_separation", 12)
	button.add_theme_color_override("font_color", Color(0.1, 0.12, 0.09))
	button.add_theme_color_override("font_disabled_color", Color(0.66, 0.68, 0.64))


func _get_card_icon(building_type: int) -> Texture2D:
	match building_type:
		VillageBuilding.BuildingType.GOLD_MINE:
			return IconGenerator.create_gold_icon()
		VillageBuilding.BuildingType.ELIXIR_COLLECTOR:
			return IconGenerator.create_elixir_icon()
		VillageBuilding.BuildingType.FARM:
			return IconGenerator.create_farm_icon()
		VillageBuilding.BuildingType.GOLD_STORAGE, VillageBuilding.BuildingType.ELIXIR_STORAGE:
			return IconGenerator.create_storage_icon()
		VillageBuilding.BuildingType.CANNON:
			return IconGenerator.create_cannon_icon()
		VillageBuilding.BuildingType.BARRACKS:
			return IconGenerator.create_barracks_icon()
		VillageBuilding.BuildingType.TOWN_HALL:
			return IconGenerator.create_town_hall_icon()
		VillageBuilding.BuildingType.PATH:
			return IconGenerator.create_path_icon()
		VillageBuilding.BuildingType.GUARD_TOWER:
			return IconGenerator.create_cannon_icon()
		VillageBuilding.BuildingType.WORKSHOP:
			return IconGenerator.create_storage_icon()
	return null


func _set_build_mode(building_type: int) -> void:
	_current_mode = building_type
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("set_build_mode"):
		village.set_build_mode(building_type)
	_sync_build_button_states()
	_refresh_mode_label()


func clear_build_selection() -> void:
	_current_mode = -1
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("clear_build_mode"):
		village.call("clear_build_mode")
	_sync_build_button_states()
	_refresh_mode_label()


func _process(delta: float) -> void:
	_mission_refresh_timer -= delta
	if _mission_refresh_timer <= 0.0:
		_refresh_mission_button()
		if _report_timer <= 0.0:
			_refresh_mode_label()
		_mission_refresh_timer = 0.2
	if _report_timer <= 0.0:
		return
	_report_timer -= delta
	if _report_timer <= 0.0:
		_report_text = ""
		_refresh_mode_label()


func _refresh_button_texts() -> void:
	for type_key in _build_buttons.keys():
		var button := _build_buttons[type_key] as Button
		var card: Dictionary = _build_card_data.get(type_key, {})
		if button == null or card.is_empty():
			continue
		var title: String = String(card.get("title", "?"))
		var description: String = String(card.get("description", ""))
		var cost_text: String = _format_cost(GameState.BUILD_COST.get(int(type_key), {}))
		button.text = "%s\nCout : %s\n%s" % [title, cost_text, description]


func _format_cost(cost: Dictionary) -> String:
	var formatted: String = GameState.format_resource_pack(cost, true)
	return formatted if formatted != "" else "gratuit"


func _on_btn_cycle_mission() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("cycle_hero_focus"):
		village.call("cycle_hero_focus")
	_refresh_mission_button()
	_refresh_mode_label()


func _on_exploration_completed(report: String) -> void:
	_report_text = report
	_report_timer = 6.0
	_refresh_mode_label()


func _refresh_mission_button() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	var focus_label: String = "Bois"
	if village and village.has_method("get_hero_focus_label"):
		focus_label = String(village.call("get_hero_focus_label"))
	mission_button.text = "Mission : %s" % focus_label


func _refresh_mode_label() -> void:
	if _report_timer > 0.0 and _report_text != "":
		mode_label.text = _report_text
		return
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	var focus_label: String = "Bois"
	if village and village.has_method("get_hero_focus_label"):
		focus_label = String(village.call("get_hero_focus_label"))
	var build_label: String = "Aucune"
	if _current_mode >= 0:
		var card: Dictionary = _build_card_data.get(_current_mode, {})
		build_label = String(card.get("title", "Aucune"))
	mode_label.text = "Construction : %s | Mission : %s" % [build_label, focus_label]


func _sync_build_button_states() -> void:
	for type_key in _build_buttons.keys():
		var button := _build_buttons[type_key] as Button
		if button:
			button.button_pressed = int(type_key) == _current_mode


func get_current_mode() -> int:
	return _current_mode
