extends Node
## Gère l'affichage des ressources

@onready var gold_label: Label = $"../TopBar/MarginContainer/HBoxContainer/GoldBlock/GoldLabel"
@onready var elixir_label: Label = $"../TopBar/MarginContainer/HBoxContainer/ElixirBlock/ElixirLabel"


func _ready() -> void:
	GameState.resources_changed.connect(_on_resources_changed)
	_refresh_resources()


func _refresh_resources() -> void:
	gold_label.text = "%d / %d" % [GameState.gold, GameState.gold_max]
	elixir_label.text = "%d / %d" % [GameState.elixir, GameState.elixir_max]


func _on_resources_changed() -> void:
	_refresh_resources()
