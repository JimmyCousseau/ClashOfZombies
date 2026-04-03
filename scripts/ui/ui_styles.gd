class_name UIStyles
extends Node
## Gère les styles visuels de l'UI

static func style_top_bar(top_bar: PanelContainer) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.05, 0.04, 0.62)
	s.border_color = Color(0.4, 0.32, 0.14, 0.55)
	s.set_border_width_all(0)
	s.set_corner_radius_all(0)
	top_bar.add_theme_stylebox_override("panel", s)


static func style_bottom_panel(bottom_panel: PanelContainer, grid: GridContainer) -> void:
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
	
	for c in grid.get_children():
		if c is Button:
			var b := c as Button
			b.add_theme_stylebox_override("normal", btn_flat)
			b.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))


static func style_button(button: Button) -> void:
	var btn_flat := StyleBoxFlat.new()
	btn_flat.bg_color = Color(0.38, 0.28, 0.16, 1.0)
	btn_flat.border_color = Color(0.75, 0.58, 0.22, 1.0)
	btn_flat.set_border_width_all(2)
	btn_flat.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", btn_flat)
	button.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
	button.add_theme_font_size_override("font_size", 14)
