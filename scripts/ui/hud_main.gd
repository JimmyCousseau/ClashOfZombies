extends Control
## Script principal HUD - orchestre tous les composants UI

@onready var bottom_panel: PanelContainer = $BottomDock/PanelContainer
@onready var top_bar: PanelContainer = $TopBar
@onready var toggle_btn: Button = $TopBar/MarginContainer/HBoxContainer/ToggleBuildBar
@onready var inventory_btn: Button = $TopBar/MarginContainer/HBoxContainer/BtnInventory
@onready var test_btn: Button = $TopBar/MarginContainer/HBoxContainer/BtnTest
@onready var bottom_dock: Control = $BottomDock
@onready var build_list: VBoxContainer = $BottomDock/PanelContainer/MarginContainer/VBox/BuildScroll/BuildList
@onready var building_buttons: Node = $BottomDock/PanelContainer/BuildingButtons
@onready var door_panel: PanelContainer = $DoorDock/PanelContainer
@onready var door_dock: Control = $DoorDock
@onready var door_status_label: Label = $DoorDock/PanelContainer/MarginContainer/VBox/HeroStatus
@onready var door_focus_label: Label = $DoorDock/PanelContainer/MarginContainer/VBox/HeroFocus
@onready var door_action_btn: Button = $DoorDock/PanelContainer/MarginContainer/VBox/HBox/BtnDoorAction
@onready var door_focus_btn: Button = $DoorDock/PanelContainer/MarginContainer/VBox/HBox/BtnDoorFocus
@onready var building_panel: PanelContainer = $BuildingDock/PanelContainer
@onready var building_dock: Control = $BuildingDock
@onready var building_title_label: Label = $BuildingDock/PanelContainer/MarginContainer/VBox/BuildingTitle
@onready var building_status_label: Label = $BuildingDock/PanelContainer/MarginContainer/VBox/BuildingStatus
@onready var building_detail_label: Label = $BuildingDock/PanelContainer/MarginContainer/VBox/BuildingDetail
@onready var building_action_btn: Button = $BuildingDock/PanelContainer/MarginContainer/VBox/HBox/BtnBuildingAction
@onready var building_upgrade_btn: Button = $BuildingDock/PanelContainer/MarginContainer/VBox/HBox/BtnBuildingUpgrade
@onready var building_destroy_btn: Button = $BuildingDock/PanelContainer/MarginContainer/VBox/HBox/BtnBuildingDestroy
@onready var inventory_panel: PanelContainer = $InventoryDock/PanelContainer
@onready var inventory_dock: Control = $InventoryDock
@onready var inventory_body_label: Label = $InventoryDock/PanelContainer/MarginContainer/VBox/InventoryBody
@onready var test_panel: PanelContainer = $TestDock/PanelContainer
@onready var test_dock: Control = $TestDock
@onready var test_status_label: Label = $TestDock/PanelContainer/MarginContainer/VBox/TestStatus
@onready var test_feedback_label: Label = $TestDock/PanelContainer/MarginContainer/VBox/TestFeedback
@onready var test_resources_btn: Button = $TestDock/PanelContainer/MarginContainer/VBox/TestActions/BtnTestResources
@onready var test_wave_btn: Button = $TestDock/PanelContainer/MarginContainer/VBox/TestActions/BtnTestWave
@onready var test_horde_btn: Button = $TestDock/PanelContainer/MarginContainer/VBox/TestActions/BtnTestHorde
@onready var test_clear_btn: Button = $TestDock/PanelContainer/MarginContainer/VBox/TestActions/BtnTestClear
@onready var test_door_btn: Button = $TestDock/PanelContainer/MarginContainer/VBox/TestActions/BtnTestDoor

var _test_feedback_text: String = ""
var _test_feedback_timer: float = 0.0


func _ready() -> void:
	# Style l'UI
	UIStyles.style_top_bar(top_bar)
	UIStyles.style_bottom_panel(bottom_panel, build_list)
	UIStyles.style_info_panel(door_panel)
	UIStyles.style_info_panel(building_panel)
	UIStyles.style_info_panel(inventory_panel)
	UIStyles.style_info_panel(test_panel)
	UIStyles.style_button(toggle_btn)
	UIStyles.style_button(inventory_btn)
	UIStyles.style_button(test_btn)
	UIStyles.style_button(door_action_btn)
	UIStyles.style_button(door_focus_btn)
	UIStyles.style_button(building_action_btn)
	UIStyles.style_button(building_upgrade_btn)
	UIStyles.style_button(building_destroy_btn)
	UIStyles.style_button(test_resources_btn)
	UIStyles.style_button(test_wave_btn)
	UIStyles.style_button(test_horde_btn)
	UIStyles.style_button(test_clear_btn)
	UIStyles.style_button(test_door_btn)
	
	# Connecte les boutons d'action
	toggle_btn.pressed.connect(_on_toggle_build_bar)
	inventory_btn.pressed.connect(_on_toggle_inventory)
	test_btn.pressed.connect(_on_toggle_test_dock)
	door_action_btn.pressed.connect(_on_btn_door_action)
	door_focus_btn.pressed.connect(_on_btn_door_focus)
	building_action_btn.pressed.connect(_on_btn_building_action)
	building_upgrade_btn.pressed.connect(_on_btn_building_upgrade)
	building_destroy_btn.pressed.connect(_on_btn_destroy_building)
	test_resources_btn.pressed.connect(_on_btn_test_resources)
	test_wave_btn.pressed.connect(_on_btn_test_wave)
	test_horde_btn.pressed.connect(_on_btn_test_horde)
	test_clear_btn.pressed.connect(_on_btn_test_clear)
	test_door_btn.pressed.connect(_on_btn_test_door)
	
	# Cache l'UI au démarrage
	bottom_dock.visible = false
	door_dock.visible = false
	building_dock.visible = false
	inventory_dock.visible = false
	test_dock.visible = false


func _process(delta: float) -> void:
	if door_dock.visible:
		_refresh_door_panel()
	if building_dock.visible:
		_refresh_building_panel()
	if inventory_dock.visible:
		_refresh_inventory_panel()
	if test_dock.visible:
		_refresh_test_panel()
	if _test_feedback_timer > 0.0:
		_test_feedback_timer = maxf(0.0, _test_feedback_timer - delta)
		if _test_feedback_timer <= 0.0 and test_dock.visible:
			_refresh_test_feedback()


func _on_toggle_build_bar() -> void:
	bottom_dock.visible = not bottom_dock.visible


func is_build_menu_open() -> bool:
	return bottom_dock.visible


func on_build_placed() -> void:
	if building_buttons and building_buttons.has_method("clear_build_selection"):
		building_buttons.call("clear_build_selection")


func _on_toggle_inventory() -> void:
	if not inventory_dock.visible:
		test_dock.visible = false
	inventory_dock.visible = not inventory_dock.visible
	if inventory_dock.visible:
		_refresh_inventory_panel()


func _on_toggle_test_dock() -> void:
	if not test_dock.visible:
		inventory_dock.visible = false
	test_dock.visible = not test_dock.visible
	if test_dock.visible:
		_refresh_test_panel()
		_refresh_test_feedback()


func toggle_door_panel() -> void:
	building_dock.visible = false
	door_dock.visible = not door_dock.visible
	if door_dock.visible:
		_refresh_door_panel()


func hide_door_panel() -> void:
	door_dock.visible = false


func show_building_panel() -> void:
	door_dock.visible = false
	building_dock.visible = true
	_refresh_building_panel()


func hide_building_panel() -> void:
	building_dock.visible = false


func _on_btn_repair_all() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("repair_all"):
		village.repair_all()


func _on_btn_door_action() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("execute_hero_door_action"):
		village.call("execute_hero_door_action")
	_refresh_door_panel()


func _on_btn_door_focus() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("cycle_hero_focus"):
		village.call("cycle_hero_focus")
	_refresh_door_panel()


func _on_btn_building_action() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("execute_selected_building_action"):
		village.call("execute_selected_building_action")
	_refresh_building_panel()


func _on_btn_destroy_building() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("destroy_selected_building"):
		village.call("destroy_selected_building")
	_refresh_building_panel()


func _on_btn_building_upgrade() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("upgrade_selected_building"):
		village.call("upgrade_selected_building")
	_refresh_building_panel()


func _on_btn_test_resources() -> void:
	var pack := {"wood": 220, "stone": 220, "iron": 140, "food": 220}
	GameState.add_resources(pack)
	_push_test_feedback("Reserve de test ajoutee : %s" % GameState.format_resource_pack(pack, false))


func _on_btn_test_wave() -> void:
	var wave_manager: Node = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager and wave_manager.has_method("trigger_debug_next_wave") and wave_manager.call("trigger_debug_next_wave"):
		_push_test_feedback("La prochaine vague de nuit a ete lancee.")
		return
	_push_test_feedback("Une vague est deja en cours.")


func _on_btn_test_horde() -> void:
	var wave_manager: Node = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager and wave_manager.has_method("spawn_debug_reinforcements") and wave_manager.call("spawn_debug_reinforcements", 12):
		_push_test_feedback("Douze renforts zombies ont ete ajoutes autour du village.")
		return
	_push_test_feedback("Impossible d'ajouter des renforts pour l'instant.")


func _on_btn_test_clear() -> void:
	var wave_manager: Node = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager == null or not wave_manager.has_method("clear_all_zombies"):
		_push_test_feedback("Gestionnaire de vagues introuvable.")
		return
	var cleared: int = int(wave_manager.call("clear_all_zombies"))
	if cleared <= 0:
		_push_test_feedback("Aucun zombie a nettoyer.")
		return
	_push_test_feedback("%d zombies retires du terrain." % cleared)


func _on_btn_test_door() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("debug_damage_main_door") and village.call("debug_damage_main_door", 250):
		_push_test_feedback("La porte principale a subi 250 degats.")
		return
	_push_test_feedback("La porte est deja detruite ou indisponible.")


func _refresh_door_panel() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village == null or not village.has_method("get_door_panel_info"):
		return
	var info: Dictionary = village.call("get_door_panel_info")
	door_status_label.text = String(info.get("status", "Indisponible"))
	door_focus_label.text = String(info.get("focus", ""))
	door_action_btn.text = String(info.get("action_label", "Action"))
	door_action_btn.disabled = not bool(info.get("action_enabled", true))
	door_focus_btn.text = String(info.get("secondary_label", "Changer mission"))
	door_focus_btn.disabled = not bool(info.get("secondary_enabled", true))


func _refresh_building_panel() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village == null or not village.has_method("get_selected_building_panel_info"):
		return
	var info: Dictionary = village.call("get_selected_building_panel_info")
	if not bool(info.get("valid", false)):
		building_dock.visible = false
		return
	building_title_label.text = String(info.get("title", "Batiment"))
	building_status_label.text = String(info.get("status", ""))
	building_detail_label.text = String(info.get("details", ""))
	building_action_btn.text = String(info.get("action_label", "Aucune action"))
	building_action_btn.disabled = not bool(info.get("action_enabled", false))
	building_upgrade_btn.text = String(info.get("upgrade_label", "Ameliorer"))
	building_upgrade_btn.disabled = not bool(info.get("upgrade_enabled", false))
	building_destroy_btn.text = String(info.get("destroy_label", "Detruire"))
	building_destroy_btn.disabled = not bool(info.get("destroy_enabled", false))


func _refresh_inventory_panel() -> void:
	inventory_body_label.text = GameState.get_inventory_text()


func _refresh_test_panel() -> void:
	var lines: Array[String] = []
	var wave_manager: Node = get_tree().get_first_node_in_group("wave_manager")
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if GameState.enemies_alive > 0:
		var current_wave: int = 1
		if wave_manager and wave_manager.has_method("get_current_wave"):
			current_wave = int(wave_manager.call("get_current_wave"))
		lines.append("Invasion en cours : nuit %d" % current_wave)
	else:
		var next_wave: int = 1
		if wave_manager and wave_manager.has_method("get_next_wave_index"):
			next_wave = int(wave_manager.call("get_next_wave_index"))
		var time_text: String = "indisponible"
		if wave_manager and wave_manager.has_method("get_time_to_next"):
			time_text = _format_countdown(int(ceil(float(wave_manager.call("get_time_to_next")))))
		lines.append("Prochaine nuit %d dans %s" % [next_wave, time_text])
	lines.append("Zombies actifs : %d" % GameState.enemies_alive)
	if village and village.has_method("get_door_panel_info"):
		var door_info: Dictionary = village.call("get_door_panel_info")
		lines.append(String(door_info.get("status", "Porte indisponible")))
	var production_pack: Dictionary = {}
	if village and village.has_method("get_automatic_production_pack"):
		production_pack = village.call("get_automatic_production_pack")
	if production_pack.is_empty():
		lines.append("Production auto : aucune")
	else:
		lines.append("Production auto : %s / cycle" % GameState.format_resource_pack(production_pack, false))
	test_status_label.text = "\n".join(lines)


func _refresh_test_feedback() -> void:
	if _test_feedback_timer > 0.0 and _test_feedback_text != "":
		test_feedback_label.text = _test_feedback_text
		return
	test_feedback_label.text = "Tests rapides : reserve, vagues, horde, porte et nettoyage."


func _push_test_feedback(text: String) -> void:
	_test_feedback_text = text
	_test_feedback_timer = 5.0
	if test_dock.visible:
		test_feedback_label.text = text
		_refresh_test_panel()


func _format_countdown(total_seconds: int) -> String:
	var clamped: int = maxi(0, total_seconds)
	var hours: int = int(clamped / 3600.0)
	var minutes: int = int((clamped % 3600) / 60.0)
	var seconds: int = clamped % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
