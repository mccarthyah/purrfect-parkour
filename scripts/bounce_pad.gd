extends Area2D

const Art = preload("res://scripts/art.gd")

var game
var pulse := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(68, 16)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if game.state != "playing":
		return
	if not get_viewport_rect().grow(40).has_point(get_global_transform_with_canvas().origin):
		return
	pulse += delta * 5.0
	queue_redraw()

func _draw() -> void:
	var squash := absf(sin(pulse)) * 3.0
	Art.panel(self, Rect2(-34, -8, 68, 10), Color("a84f64"), 5, Art.INK, 2)
	Art.panel(self, Rect2(-34, -16 + squash, 68, 13), Art.GOLD, 7, Art.INK, 2)
	draw_line(Vector2(-23,-12 + squash), Vector2(23,-12 + squash), Art.CREAM, 2, true)
	draw_polyline(PackedVector2Array([Vector2(-6,-20),Vector2(0,-25),Vector2(6,-20)]), Art.CREAM, 2.5, true)

func _on_body_entered(body) -> void:
	if game.state == "playing" and game.helicopter == null and body.is_in_group("cat") and body.velocity.y >= 0:
		game.bounce_cat(body)
