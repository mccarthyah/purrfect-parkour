extends Area2D

var phase := 0.0
var taken := false

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 19
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	phase += delta * 3.2
	queue_redraw()

func _draw() -> void:
	if taken:
		return
	var y := sin(phase) * 5.0
	draw_set_transform(Vector2(0, y), 0, Vector2(1, 1))
	# Gold fish-shaped medal, with a little glint
	draw_colored_polygon(PackedVector2Array([Vector2(-14,0),Vector2(-25,-10),Vector2(-24,10),Vector2(-14,2),Vector2(-5,11),Vector2(9,11),Vector2(18,4),Vector2(18,-4),Vector2(9,-11),Vector2(-5,-11)]), Color("ffd34f"))
	draw_circle(Vector2(11,-3), 1.8, Color("5d5865"))
	draw_arc(Vector2(2,0), 6, -1.0, 1.0, 12, Color("fff3b0"), 2.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _on_body_entered(body: Node2D) -> void:
	if taken or not body.is_in_group("cat"): 
		return
	taken = true
	monitoring = false
	game_collected()
	queue_redraw()

func game_collected() -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.collect_medal(self)
