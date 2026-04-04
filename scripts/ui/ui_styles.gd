class_name UIStyles
extends Node
## Gère les styles visuels de l'UI

static func style_top_bar(top_bar: PanelContainer) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.34, 0.39, 0.35, 0.88)
	s.border_color = Color(0.72, 0.78, 0.7, 0.72)
	s.set_border_width_all(0)
	s.set_corner_radius_all(0)
	top_bar.add_theme_stylebox_override("panel", s)


static func style_bottom_panel(bottom_panel: PanelContainer, content_root: Control) -> void:
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0.42, 0.45, 0.4, 0.96)
	flat.border_color = Color(0.82, 0.86, 0.78, 1.0)
	flat.set_border_width_all(2)
	flat.set_corner_radius_all(8)
	flat.content_margin_left = 14
	flat.content_margin_top = 12
	flat.content_margin_right = 14
	flat.content_margin_bottom = 12
	bottom_panel.add_theme_stylebox_override("panel", flat)
	
	var btn_flat := StyleBoxFlat.new()
	btn_flat.bg_color = Color(0.55, 0.59, 0.52, 1.0)
	btn_flat.border_color = Color(0.9, 0.93, 0.86, 1.0)
	btn_flat.set_border_width_all(2)
	btn_flat.set_corner_radius_all(6)
	var btn_pressed := btn_flat.duplicate()
	btn_pressed.bg_color = Color(0.42, 0.48, 0.36, 1.0)
	btn_pressed.border_color = Color(0.95, 0.98, 0.9, 1.0)
	var btn_disabled := btn_flat.duplicate()
	btn_disabled.bg_color = Color(0.38, 0.4, 0.36, 0.8)
	btn_disabled.border_color = Color(0.62, 0.66, 0.6, 0.8)
	
	if content_root == null:
		return
	_apply_button_style_recursive(content_root, btn_flat, btn_pressed, btn_disabled)


static func _apply_button_style_recursive(root: Node, normal_style: StyleBoxFlat, pressed_style: StyleBoxFlat, disabled_style: StyleBoxFlat) -> void:
	for child in root.get_children():
		if child is Button:
			var button := child as Button
			button.add_theme_stylebox_override("normal", normal_style)
			button.add_theme_stylebox_override("pressed", pressed_style)
			button.add_theme_stylebox_override("hover", pressed_style)
			button.add_theme_stylebox_override("disabled", disabled_style)
			button.add_theme_color_override("font_color", Color(0.9, 0.92, 0.88))
			button.add_theme_color_override("font_disabled_color", Color(0.72, 0.74, 0.7))
		_apply_button_style_recursive(child, normal_style, pressed_style, disabled_style)


static func style_info_panel(panel: PanelContainer) -> void:
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0.46, 0.49, 0.44, 0.97)
	flat.border_color = Color(0.86, 0.9, 0.82, 1.0)
	flat.set_border_width_all(2)
	flat.set_corner_radius_all(8)
	flat.content_margin_left = 12
	flat.content_margin_top = 10
	flat.content_margin_right = 12
	flat.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", flat)


static func style_button(button: Button) -> void:
	var btn_flat := StyleBoxFlat.new()
	btn_flat.bg_color = Color(0.55, 0.59, 0.52, 1.0)
	btn_flat.border_color = Color(0.9, 0.93, 0.86, 1.0)
	btn_flat.set_border_width_all(2)
	btn_flat.set_corner_radius_all(6)
	var btn_pressed := btn_flat.duplicate()
	btn_pressed.bg_color = Color(0.42, 0.48, 0.36, 1.0)
	btn_pressed.border_color = Color(0.95, 0.98, 0.9, 1.0)
	var btn_disabled := btn_flat.duplicate()
	btn_disabled.bg_color = Color(0.38, 0.4, 0.36, 0.8)
	btn_disabled.border_color = Color(0.62, 0.66, 0.6, 0.8)
	button.add_theme_stylebox_override("normal", btn_flat)
	button.add_theme_stylebox_override("pressed", btn_pressed)
	button.add_theme_stylebox_override("hover", btn_pressed)
	button.add_theme_stylebox_override("disabled", btn_disabled)
	button.add_theme_color_override("font_color", Color(0.12, 0.14, 0.1))
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.74, 0.7))
	button.add_theme_font_size_override("font_size", 14)
