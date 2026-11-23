extends Area2D

const Art = preload("res://scripts/art.gd")

var phase := 0.0
var taken := false
@onready var game: Node = get_tree().get_first_node_in_group("game")

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 19
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if taken or game.state != "playing":
		return
	if not get_viewport_rect().grow(28).has_point(get_global_transform_with_canvas().origin):
		return
	phase += delta * 3.2
	queue_redraw()

func _draw() -> void:
	if taken:
		return
	var y := sin(phase) * 5.0
	Art.medal(self, Vector2(0, y), 1.0)
	Art.sparkle(self, Vector2(19, y - 13), 4.5 + sin(phase * 1.7) * 2.0, Art.CREAM)

func _on_body_entered(body: Node2D) -> void:
	if taken or game.state != "playing" or game.helicopter != null or not body.is_in_group("cat"):
		return
	taken = true
	set_deferred("monitoring", false)
	game.collect_medal(self)
	queue_redraw()
