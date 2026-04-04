extends Node
## Gère l'affichage des vagues

@onready var wave_label: Label = $"../TopBar/MarginContainer/HBoxContainer/WaveLabel"

var _wave_manager: Node3D = null


func _ready() -> void:
	_wave_manager = get_tree().get_first_node_in_group("wave_manager")
	GameState.wave_started.connect(_on_wave_started)
	_update_wave_display()


func _process(delta: float) -> void:
	if not GameState.is_paused:
		_update_wave_display()


func _update_wave_display() -> void:
	var enemies: int = GameState.enemies_alive
	if enemies <= 0:
		if _wave_manager and _wave_manager.has_method("get_time_to_next"):
			var time_to_next: float = _wave_manager.call("get_time_to_next")
			if time_to_next > 0:
				var next_wave: int = 1
				if _wave_manager.has_method("get_next_wave_index"):
					next_wave = int(_wave_manager.call("get_next_wave_index"))
				wave_label.text = "Nuit %d a 00:00 UTC dans %s" % [next_wave, _format_countdown(int(ceil(time_to_next)))]
			else:
				wave_label.text = "Aucune attaque en cours"
		else:
			wave_label.text = "Aucune attaque en cours"
	else:
		var wave_idx: int = 1
		if _wave_manager and _wave_manager.has_method("get_current_wave"):
			wave_idx = int(_wave_manager.call("get_current_wave"))
		wave_label.text = "Nuit %d - Zombies : %d" % [wave_idx, enemies]


func _on_wave_started(idx: int) -> void:
	wave_label.text = "Nuit %d - Zombies : %d" % [idx, GameState.enemies_alive]


func _format_countdown(total_seconds: int) -> String:
	var hours: int = int(total_seconds / 3600.0)
	var minutes: int = int((total_seconds % 3600) / 60.0)
	var seconds: int = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
