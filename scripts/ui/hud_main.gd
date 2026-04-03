extends Control
## Script principal HUD - orchestre tous les composants UI

@onready var bottom_panel: PanelContainer = $BottomDock/PanelContainer
@onready var top_bar: PanelContainer = $TopBar
@onready var toggle_btn: Button = $TopBar/MarginContainer/HBoxContainer/ToggleBuildBar
@onready var bottom_dock: Control = $BottomDock
@onready var repair_btn: Button = $BottomDock/PanelContainer/MarginContainer/VBox/BtnRepairAll
@onready var build_grid: GridContainer = $BottomDock/PanelContainer/MarginContainer/VBox/BuildGrid


func _ready() -> void:
	# Style l'UI
	UIStyles.style_top_bar(top_bar)
	UIStyles.style_bottom_panel(bottom_panel, build_grid)
	UIStyles.style_button(toggle_btn)
	
	# Connecte les boutons d'action
	toggle_btn.pressed.connect(_on_toggle_build_bar)
	repair_btn.pressed.connect(_on_btn_repair_all)
	
	# Cache l'UI au démarrage
	bottom_dock.visible = false


func _on_toggle_build_bar() -> void:
	bottom_dock.visible = not bottom_dock.visible


func _on_btn_repair_all() -> void:
	var village: Node3D = get_tree().get_first_node_in_group("village") as Node3D
	if village and village.has_method("repair_all"):
		village.repair_all()
