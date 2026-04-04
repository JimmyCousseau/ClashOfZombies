class_name IconGenerator
extends Node
## Génère des icônes simples pour les boutons

static func create_gold_icon() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_box(img, Rect2i(5, 10, 22, 6), Color(0.45, 0.31, 0.18))
	_draw_box(img, Rect2i(8, 17, 18, 6), Color(0.57, 0.39, 0.22))
	_draw_line(img, Vector2(7, 9), Vector2(25, 15), Color(0.68, 0.5, 0.32), 1)
	return ImageTexture.create_from_image(img)

static func create_elixir_icon() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_box(img, Rect2i(6, 16, 20, 8), Color(0.48, 0.5, 0.52))
	_draw_box(img, Rect2i(10, 10, 6, 6), Color(0.58, 0.6, 0.62))
	_draw_box(img, Rect2i(17, 8, 7, 7), Color(0.38, 0.4, 0.42))
	return ImageTexture.create_from_image(img)

static func create_barracks_icon() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_box(img, Rect2i(4, 8, 24, 16), Color(0.62, 0.45, 0.3))
	_draw_box(img, Rect2i(10, 12, 4, 8), Color(0.35, 0.22, 0.12))
	_draw_box(img, Rect2i(18, 12, 4, 8), Color(0.35, 0.22, 0.12))
	return ImageTexture.create_from_image(img)

static func create_cannon_icon() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_circle(img, Vector2(16, 18), 8, Color(0.55, 0.54, 0.5))
	_draw_line(img, Vector2(16, 10), Vector2(22, 4), Color(0.22, 0.23, 0.26), 2)
	return ImageTexture.create_from_image(img)

static func create_farm_icon() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_box(img, Rect2i(4, 12, 24, 12), Color(0.4, 0.3, 0.18))
	_draw_box(img, Rect2i(8, 6, 3, 8), Color(0.28, 0.62, 0.22))
	_draw_box(img, Rect2i(16, 6, 3, 8), Color(0.28, 0.62, 0.22))
	_draw_box(img, Rect2i(24, 8, 2, 10), Color(0.28, 0.62, 0.22))
	return ImageTexture.create_from_image(img)

static func create_storage_icon() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_box(img, Rect2i(6, 10, 20, 16), Color(0.44, 0.36, 0.24))
	_draw_box(img, Rect2i(9, 13, 14, 10), Color(0.2, 0.22, 0.18))
	return ImageTexture.create_from_image(img)

static func create_town_hall_icon() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_box(img, Rect2i(6, 12, 20, 14), Color(0.72, 0.68, 0.58))
	_draw_box(img, Rect2i(8, 6, 16, 6), Color(0.82, 0.28, 0.18))
	_draw_box(img, Rect2i(14, 2, 4, 4), Color(0.95, 0.78, 0.22))
	return ImageTexture.create_from_image(img)

static func create_barbarian_icon() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_circle(img, Vector2(16, 8), 4, Color(0.72, 0.6, 0.48))
	_draw_box(img, Rect2i(11, 12, 10, 10), Color(0.22, 0.28, 0.3))
	_draw_box(img, Rect2i(10, 22, 12, 6), Color(0.18, 0.2, 0.18))
	_draw_box(img, Rect2i(20, 12, 3, 12), Color(0.42, 0.44, 0.46))
	return ImageTexture.create_from_image(img)

static func create_door_icon() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_box(img, Rect2i(8, 6, 16, 20), Color(0.44, 0.27, 0.14))
	_draw_box(img, Rect2i(6, 4, 3, 24), Color(0.2, 0.2, 0.22))
	_draw_box(img, Rect2i(23, 4, 3, 24), Color(0.2, 0.2, 0.22))
	_draw_circle(img, Vector2(19, 16), 2, Color(0.72, 0.72, 0.68))
	return ImageTexture.create_from_image(img)

static func create_path_icon() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_box(img, Rect2i(5, 20, 22, 6), Color(0.66, 0.64, 0.58))
	_draw_box(img, Rect2i(9, 12, 14, 5), Color(0.76, 0.74, 0.68))
	_draw_box(img, Rect2i(12, 6, 8, 4), Color(0.86, 0.82, 0.72))
	return ImageTexture.create_from_image(img)

static func _draw_box(img: Image, rect: Rect2i, color: Color) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				img.set_pixel(x, y, color)

static func _draw_circle(img: Image, center: Vector2, radius: float, color: Color) -> void:
	for x in range(maxi(0, int(center.x - radius)), mini(32, int(center.x + radius + 1))):
		for y in range(maxi(0, int(center.y - radius)), mini(32, int(center.y + radius + 1))):
			var dist := center.distance_to(Vector2(x, y))
			if dist <= radius:
				img.set_pixel(x, y, color)

static func _draw_line(img: Image, from: Vector2, to: Vector2, color: Color, thickness: int = 1) -> void:
	var diff := to - from
	var steps := int(diff.length()) + 1
	for i in range(steps):
		var t := float(i) / float(steps)
		var pos := from.lerp(to, t)
		for ox in range(-thickness, thickness + 1):
			for oy in range(-thickness, thickness + 1):
				var px := int(pos.x) + ox
				var py := int(pos.y) + oy
				if px >= 0 and px < 32 and py >= 0 and py < 32:
					img.set_pixel(px, py, color)
