extends Area2D

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
	pulse += delta * 5.0
	queue_redraw()

func _draw() -> void:
	var squash := absf(sin(pulse)) * 3.0
	draw_rect(Rect2(-34, -7 + squash, 68, 8), Color("f6c75f"))
	draw_rect(Rect2(-30, -12 + squash, 60, 5), Color("fff1bd"))
	for i in range(5):
		var x := -23.0 + i * 11.5
		draw_line(Vector2(x, -4 + squash), Vector2(x + 5, 0), Color("d98268"), 2.5, true)
	draw_circle(Vector2(0, -13 + squash), 3, Color("fff9dc"))

func _on_body_entered(body) -> void:
	if body.is_in_group("cat") and body.velocity.y >= 0:
		game.bounce_cat(body)
