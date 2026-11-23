extends RefCounted

const INK := Color("29303b")
const CREAM := Color("fff4d9")
const GOLD := Color("edb963")
const CORAL := Color("56403e")

static func panel(canvas: CanvasItem, rect: Rect2, fill: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	canvas.draw_style_box(box, rect)

static func ellipse(canvas: CanvasItem, center: Vector2, radii: Vector2, fill: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * i / 32.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radii)
	canvas.draw_colored_polygon(points, fill)
	points.append(points[0])
	canvas.draw_polyline(points, fill, 1.0, true)

static func medal(canvas: CanvasItem, at: Vector2, size: float) -> void:
	canvas.draw_set_transform(at, 0, Vector2.ONE * size)
	canvas.draw_circle(Vector2(0, 2), 19, Color("533a35"), true, -1.0, true)
	canvas.draw_circle(Vector2.ZERO, 18, Color("b3763f"), true, -1.0, true)
	canvas.draw_circle(Vector2(0, -1), 15.5, GOLD, true, -1.0, true)
	canvas.draw_arc(Vector2(0, -1), 13, -2.9, -0.5, 20, CREAM, 1.4, true)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(-12, -5), Vector2(-12, 5)]), CORAL)
	ellipse(canvas, Vector2(1, 0), Vector2(8, 5.5), CORAL)
	canvas.draw_circle(Vector2(5, -1), 1.0, CREAM, true, -1.0, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func sparkle(canvas: CanvasItem, at: Vector2, size: float, fill: Color) -> void:
	var points := PackedVector2Array()
	for i in range(8):
		var angle := TAU * i / 8.0
		var length := size if i % 2 == 0 else size * 0.28
		points.append(at + Vector2(cos(angle), sin(angle)) * length)
	canvas.draw_colored_polygon(points, fill)
