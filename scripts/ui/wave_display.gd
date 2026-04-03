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
				var sec: int = int(ceil(time_to_next))
				wave_label.text = "Prochaine vague : %ds" % sec
			else:
				wave_label.text = "Vague complétée"
		else:
			wave_label.text = "Vague complétée"
	else:
		wave_label.text = "Zombies : %d" % enemies


func _on_wave_started(idx: int) -> void:
	wave_label.text = "Horde %d - Zombies : %d" % [idx, GameState.enemies_alive]
