extends Node
class_name SelectionManager

## Gère la sélection de bâtiment et fournit les données pour les panels UI.

var _grid_map: VillageGridMap
var _hero_manager: HeroManager
var _hud: Control
var _selected: VillageBuilding = null


func setup(grid_map: VillageGridMap, hero_manager: HeroManager, hud: Control) -> void:
	_grid_map = grid_map
	_hero_manager = hero_manager
	_hud = hud


# ---------------------------------------------------------------------------
# Sélection
# ---------------------------------------------------------------------------

func select(b: VillageBuilding) -> void:
	_selected = b
	_show_building_panel()


func deselect() -> void:
	_selected = null
	_hide_building_panel()


func get_selected() -> VillageBuilding:
	return _selected


func is_selected_valid() -> bool:
	return _selected != null and is_instance_valid(_selected)


# ---------------------------------------------------------------------------
# Données panel bâtiment
# ---------------------------------------------------------------------------

func get_building_panel_info() -> Dictionary:
	@warning_ignore("confusable_local_usage")
	if not is_selected_valid():
		return {"valid": false}

	var b := _selected
	var title     := b._type_name()
	var status    := "Niveau %d / %d | PV : %d / %d" % [b.level, b.get_max_level(), b.hp, b.max_hp]
	var details   := b.get_effect_summary()
	var action_label   := "Aucune action"
	var action_enabled := false
	var upgrade_label := "Niveau max"
	var upgrade_enabled := false

	if b.building_type == VillageBuilding.BuildingType.BARRACKS:
		var active  := b.get_barracks_active_soldier_count()
		var max_sol := b.get_barracks_max_soldiers()
		var missing := b.get_barracks_missing_soldier_count()
		var cost    := b.get_barracks_refill_cost()
		details = "Garnison : %d / %d" % [active, max_sol]
		if missing > 0:
			details += "\nReformation : %s" % GameState.format_resource_pack(cost, true)
			action_label   = "Reformer"
			action_enabled = GameState.can_afford(cost)
		else:
			action_label = "Garnison complète"
	elif b.building_type == VillageBuilding.BuildingType.WORKSHOP:
		details = "Boulets de canon : %d\nFleches : %d" % [GameState.cannonballs, GameState.arrows]
		if GameState.can_afford(GameState.CANNONBALL_CRAFT_COST):
			action_label = "Fabriquer boulet (%s)" % GameState.format_resource_pack(GameState.CANNONBALL_CRAFT_COST, true)
			action_enabled = true
		else:
			action_label = "Boulet indisponible"
		if GameState.can_afford(GameState.ARROW_CRAFT_COST):
			upgrade_label = "Fabriquer fleche (%s)" % GameState.format_resource_pack(GameState.ARROW_CRAFT_COST, true)
			upgrade_enabled = true
		else:
			upgrade_label = "Fleche indisponible"
	else:
		details += "\n" + GameState.get_build_description(b.building_type)
		var upgrade_cost    := b.get_upgrade_cost()
		upgrade_enabled = b.can_upgrade() and GameState.can_afford(upgrade_cost)
		if b.can_upgrade():
			upgrade_label = "Améliorer (%s)" % GameState.format_resource_pack(upgrade_cost, true)
			details += "\n" + b.get_upgrade_summary()
		else:
			upgrade_label = "Niveau max"

	var refund      := b.get_destroy_refund()
	var refund_text := GameState.format_resource_pack(refund, true)
	var destroy_label := "Détruire" + (" (%s)" % refund_text if refund_text != "" else "")

	var repair_cost := b.get_repair_cost(b.max_hp - b.hp)
	var repair_enabled := b.hp < b.max_hp and GameState.can_afford(repair_cost)
	var repair_label: String
	if b.hp < b.max_hp:
		repair_label = "Réparer (%s)" % GameState.format_resource_pack(repair_cost, true)
	else:
		repair_label = "Réparé"

	return {
		"valid":           true,
		"title":           title,
		"status":          status,
		"details":         details,
		"action_label":    action_label,
		"action_enabled":  action_enabled,
		"upgrade_label":   upgrade_label,
		"upgrade_enabled": upgrade_enabled,
		"destroy_label":   destroy_label,
		"destroy_enabled": b.can_player_destroy(),
		"repair_label":    repair_label,
		"repair_enabled":  repair_enabled,
	}


# ---------------------------------------------------------------------------
# Données panel porte
# ---------------------------------------------------------------------------

func get_door_panel_info() -> Dictionary:
	var door: VillageBuilding = _grid_map.get_main_door()
	var status := "Porte : indisponible"
	var hero_line     := "Héro : %s | Mission : %s" % [_hero_manager.get_status_text(), _hero_manager.get_focus_label()]
	var action_label  := _hero_manager.get_door_action_label()
	var action_enabled := _hero_manager.can_execute_door_action()
	var secondary_label   := "Changer mission"
	var secondary_enabled := true

	if door and is_instance_valid(door):
		if door.is_destroyed:
			status        = "Porte principale détruite"
			var cost: Dictionary = GameState.BUILD_COST.get(VillageBuilding.BuildingType.DOOR, {})
			action_label   = "Reconstruire (%s)" % GameState.format_resource_pack(cost, true)
			action_enabled = GameState.can_afford(cost)
			secondary_label   = "Mission indisponible"
			secondary_enabled = false
		else:
			status = "Porte : %d / %d" % [door.hp, door.max_hp]

	return {
		"status":            status,
		"focus":             hero_line,
		"action_label":      action_label,
		"action_enabled":    action_enabled,
		"secondary_label":   secondary_label,
		"secondary_enabled": secondary_enabled,
	}


# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------

func execute_action() -> bool:
	if not is_selected_valid():
		return false
	if _selected.building_type == VillageBuilding.BuildingType.BARRACKS:
		return _selected.refill_barracks()
	if _selected.building_type == VillageBuilding.BuildingType.WORKSHOP:
		if GameState.can_afford(GameState.CANNONBALL_CRAFT_COST):
			GameState.spend(GameState.CANNONBALL_CRAFT_COST)
			GameState.cannonballs += 1
			GameState.resources_changed.emit()
			return true
	return false


func upgrade() -> bool:
	if not is_selected_valid():
		return false
	if _selected.building_type == VillageBuilding.BuildingType.WORKSHOP:
		if GameState.can_afford(GameState.ARROW_CRAFT_COST):
			GameState.spend(GameState.ARROW_CRAFT_COST)
			GameState.arrows += 1
			GameState.resources_changed.emit()
			return true
	return _selected.upgrade()


func repair_selected() -> bool:
	if not is_selected_valid():
		return false
	var missing := _selected.max_hp - _selected.hp
	if missing <= 0:
		return false
	var cost := _selected.get_repair_cost(missing)
	if not GameState.can_afford(cost):
		return false
	_selected.repair(missing)
	GameState.spend(cost)
	GameState.resources_changed.emit()
	return true


func destroy() -> bool:
	if not is_selected_valid():
		return false
	if not _selected.can_player_destroy():
		return false
	GameState.add_resources(_selected.get_destroy_refund())
	var target := _selected
	deselect()
	_grid_map.unregister(target.cell, target)
	target.queue_free()
	return true


# ---------------------------------------------------------------------------
# HUD helpers
# ---------------------------------------------------------------------------

func _show_building_panel() -> void:
	if _hud and _hud.has_method("show_building_panel"):
		_hud.call("show_building_panel")


func _hide_building_panel() -> void:
	if _hud and _hud.has_method("hide_building_panel"):
		_hud.call("hide_building_panel")


func toggle_door_panel() -> void:
	if _hud and _hud.has_method("toggle_door_panel"):
		_hide_building_panel()
		_hud.call("toggle_door_panel")


func hide_door_panel() -> void:
	if _hud and _hud.has_method("hide_door_panel"):
		_hud.call("hide_door_panel")
