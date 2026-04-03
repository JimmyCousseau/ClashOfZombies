extends Control

@onready var gold_label: Label = $TopBar/MarginContainer/HBoxContainer/GoldBlock/GoldLabel
@onready var elixir_label: Label = $TopBar/MarginContainer/HBoxContainer/ElixirBlock/ElixirLabel
@onready var wave_label: Label = $TopBar/MarginContainer/HBoxContainer/WaveLabel
@onready var mode_label: Label = $BottomDock/PanelContainer/MarginContainer/VBox/ModeLabel
@onready var overlay: ColorRect = $GameOverOverlay
@onready var overlay_label: Label = $GameOverOverlay/Center/Label
@onready var bottom_panel: PanelContainer = $BottomDock/PanelContainer
@onready var top_bar: PanelContainer = $TopBar
@onready var toggle_btn: Button = $TopBar/MarginContainer/HBoxContainer/ToggleBuildBar
@onready var bottom_dock: Control = $BottomDock
@onready var repair_btn: Button = $BottomDock/PanelContainer/MarginContainer/VBox/BtnRepairAll

var _mode: VillageBuilding.BuildingType = VillageBuilding.BuildingType.GOLD_MINE
var _wave_manager: Node3D = null
var _next_wave_timer: float = 0.0

func _style_top_bar() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.05, 0.04, 0.62)
	s.border_color = Color(0.4, 0.32, 0.14, 0.55)
	s.set_border_width_all(0)
	s.set_corner_radius_all(0)
	top_bar.add_theme_stylebox_override("panel", s)


func _ready() -> void:
	_style_top_bar()
	_style_bottom_panel()
	_style_toggle_button()
	toggle_btn.pressed.connect(_on_toggle_build_bar)
	repair_btn.pressed.connect(_on_btn_repair_all)
	GameState.wave_started.connect(_on_wave)
	GameState.game_over.connect(_on_game_over)
	GameState.resources_changed.connect(_refresh_resources)

	
	_wave_manager = get_tree().get_first_node_in_group("wave_manager")
	_update_wave_display()
	var v: VBoxContainer = $BottomDock/PanelContainer/MarginContainer/VBox
	v.get_node("BuildGrid/BtnGoldMine").pressed.connect(_on_btn_gold_mine)
	v.get_node("BuildGrid/BtnElixir").pressed.connect(_on_btn_elixir)
	v.get_node("BuildGrid/BtnFarm").pressed.connect(_on_btn_farm)
	v.get_node("BuildGrid/BtnGoldStorage").pressed.connect(_on_btn_gold_storage)
	v.get_node("BuildGrid/BtnElixirStorage").pressed.connect(_on_btn_elixir_storage)
	v.get_node("BuildGrid/BtnCannon").pressed.connect(_on_btn_cannon)
	v.get_node("BuildGrid/BtnBarracks").pressed.connect(_on_btn_barracks)
	v.get_node("BuildGrid/BtnTownHall").pressed.connect(_on_btn_town_hall)
	v.get_node("BuildGrid/BtnTrain").pressed.connect(_on_btn_train)
	_refresh_resources()
	_set_mode(VillageBuilding.BuildingType.GOLD_MINE)
	overlay.visible = false
	bottom_dock.visible = false


func _style_bottom_panel() -> void:
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0.22, 0.14, 0.08, 0.92)
	flat.border_color = Color(0.62, 0.48, 0.22, 1.0)
	flat.set_border_width_all(3)
	flat.set_corner_radius_all(10)
	flat.content_margin_left = 14
	flat.content_margin_top = 12
	flat.content_margin_right = 14
	flat.content_margin_bottom = 12
	bottom_panel.add_theme_stylebox_override("panel", flat)
	var btn_flat := StyleBoxFlat.new()
	btn_flat.bg_color = Color(0.38, 0.28, 0.16, 1.0)
	btn_flat.border_color = Color(0.75, 0.58, 0.22, 1.0)
	btn_flat.set_border_width_all(2)
	btn_flat.set_corner_radius_all(6)
	var grid: GridContainer = $BottomDock/PanelContainer/MarginContainer/VBox/BuildGrid
	for c in grid.get_children():
		if c is Button:
			var b := c as Button
			b.add_theme_stylebox_override("normal", btn_flat)
			b.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))


func _style_toggle_button() -> void:
	var btn_flat := StyleBoxFlat.new()
	btn_flat.bg_color = Color(0.38, 0.28, 0.16, 1.0)
	btn_flat.border_color = Color(0.75, 0.58, 0.22, 1.0)
	btn_flat.set_border_width_all(2)
	btn_flat.set_corner_radius_all(6)
	toggle_btn.add_theme_stylebox_override("normal", btn_flat)
	toggle_btn.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
	toggle_btn.add_theme_font_size_override("font_size", 14)


func _refresh_resources() -> void:
	gold_label.text = "%d / %d" % [GameState.gold, GameState.gold_max]
	elixir_label.text = "%d / %d" % [GameState.elixir, GameState.elixir_max]


func _process(delta: float) -> void:
	if not GameState.is_paused:
		_update_wave_display()


func _update_wave_display() -> void:
	var enemies: int = GameState.enemies_alive
	if enemies <= 0:
		if _wave_manager and _wave_manager.has_method("get_time_to_next"):
			var time_to_next: float = _wave_manager.call("get_time_to_next")
			if time_to_next > 0:
				var sec: int = int(ceil(time_to_next))
				wave_label.text = "Prochaine vague : %ds" % sec
			else:
				wave_label.text = "Vague complétée"
		else:
			wave_label.text = "Vague complétée"
	else:
		wave_label.text = "Zombies : %d" % enemies


func _on_wave(idx: int) -> void:
	wave_label.text = "Horde %d - Zombies : %d" % [idx, GameState.enemies_alive]


func _on_game_over() -> void:
	overlay.visible = true
	overlay_label.text = "Village détruit !"


func _set_mode(t: VillageBuilding.BuildingType) -> void:
	_mode = t
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("set_build_mode"):
		village.set_build_mode(t)
	mode_label.text = "Placer : %s" % _mode_name(t)


func _mode_name(t: VillageBuilding.BuildingType) -> String:
	match t:
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


func _on_btn_gold_mine() -> void:
	_set_mode(VillageBuilding.BuildingType.GOLD_MINE)


func _on_btn_elixir() -> void:
	_set_mode(VillageBuilding.BuildingType.ELIXIR_COLLECTOR)


func _on_btn_farm() -> void:
	_set_mode(VillageBuilding.BuildingType.FARM)


func _on_btn_gold_storage() -> void:
	_set_mode(VillageBuilding.BuildingType.GOLD_STORAGE)


func _on_btn_elixir_storage() -> void:
	_set_mode(VillageBuilding.BuildingType.ELIXIR_STORAGE)


func _on_btn_cannon() -> void:
	_set_mode(VillageBuilding.BuildingType.CANNON)


func _on_btn_barracks() -> void:
	_set_mode(VillageBuilding.BuildingType.BARRACKS)


func _on_btn_town_hall() -> void:
	_set_mode(VillageBuilding.BuildingType.TOWN_HALL)


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
	allies.add_child(u)
	u.global_position = barracks.global_position + Vector3(2.2, 0.0, 0.5)


func _on_toggle_build_bar() -> void:
	bottom_dock.visible = not bottom_dock.visible


func _on_btn_repair_all() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("repair_all"):
		village.repair_all()
