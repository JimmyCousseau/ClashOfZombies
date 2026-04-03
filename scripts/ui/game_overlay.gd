extends Node
## Gère l'écran de game over

@onready var overlay: ColorRect = $"../GameOverOverlay"
@onready var overlay_label: Label = $"../GameOverOverlay/Center/Label"


func _ready() -> void:
	GameState.game_over.connect(_on_game_over)
	overlay.visible = false


func _on_game_over() -> void:
	overlay.visible = true
	overlay_label.text = "Village détruit !"
