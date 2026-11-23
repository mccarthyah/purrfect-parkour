extends CharacterBody2D

const Art = preload("res://scripts/art.gd")
const RUN_SPEED := 310.0
const GRAVITY := 1450.0
const JUMP_SPEED := -610.0
const CLIMB_SPEED := 210.0

var game
var facing := 1.0
var climbing := false
var wait_for_jump_release := false
var air_jump_available := true
var walk_time := 0.0
var last_pose: Array = []
var spawn_point := Vector2(100, 390)

func _ready() -> void:
	add_to_group("cat")
	collision_layer = 1
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 15
	capsule.height = 48
	shape.shape = capsule
	shape.position = Vector2(0, -24)
	add_child(shape)
	position = spawn_point

func _physics_process(delta: float) -> void:
	if game == null or game.state != "playing" or game.helicopter != null:
		velocity = Vector2.ZERO
		_update_pose()
		return
	var input_x := Input.get_axis("move_left", "move_right")
	if input_x != 0:
		facing = signf(input_x)
		walk_time += delta * 12.0
	velocity.x = input_x * RUN_SPEED

	if wait_for_jump_release and not Input.is_action_pressed("jump"):
		wait_for_jump_release = false
	var jump_pressed := not wait_for_jump_release and Input.is_action_just_pressed("jump")
	var near_tree: bool = game.is_near_tree(global_position.x)
	climbing = near_tree and (Input.is_action_pressed("climb_up") or Input.is_action_pressed("climb_down"))
	if climbing:
		velocity.y = 0
		if Input.is_action_pressed("climb_up"):
			velocity.y = -CLIMB_SPEED
		elif Input.is_action_pressed("climb_down"):
			velocity.y = CLIMB_SPEED
		elif not is_on_floor():
			velocity.y = 0
		if jump_pressed and not Input.is_action_pressed("climb_up"):
			climbing = false
			velocity.y = JUMP_SPEED
	else:
		if is_on_floor():
			air_jump_available = true
			if velocity.y > 0:
				velocity.y = 0
		else:
			velocity.y += GRAVITY * delta
		if jump_pressed:
			if is_on_floor():
				velocity.y = JUMP_SPEED
			elif air_jump_available:
				velocity.y = JUMP_SPEED * 0.88
				air_jump_available = false
				game.show_message("Double jump", 1.0)

	move_and_slide()
	if position.y > 760:
		game.cat_fell()
	_update_pose()

func _update_pose() -> void:
	var pose := [facing, is_on_floor(), absf(velocity.x) > 5, climbing, walk_time,
		game != null and game.state == "playing"]
	if pose != last_pose:
		last_pose = pose
		queue_redraw()

func _draw() -> void:
	var running := is_on_floor() and absf(velocity.x) > 5
	var stride := sin(walk_time) if running or climbing else 0.0
	var bob := -absf(stride) * 2.0
	var orange := Color("dd934b")
	var dark := Color("382c31")
	var cream := Art.CREAM
	if is_on_floor():
		Art.ellipse(self, Vector2(0, 1), Vector2(22, 4), Color(dark, 0.20))
	draw_set_transform(Vector2(0, bob), 0.07 * facing if running else 0.0, Vector2(facing, 1))
	var tail := PackedVector2Array([Vector2(-9,-15), Vector2(-21,-17), Vector2(-29,-25), Vector2(-29,-35 + stride * 4)])
	draw_polyline(tail, dark, 9, true)
	draw_polyline(tail, orange, 5, true)
	draw_circle(tail[-1], 4.5, dark, true, -1.0, true)
	draw_circle(tail[-1], 2.8, cream, true, -1.0, true)
	Art.ellipse(self, Vector2(0,-14), Vector2(17,13), dark)
	Art.ellipse(self, Vector2(0,-15), Vector2(15,11), orange)
	var lift := 4.0 if not is_on_floor() and game.state == "playing" else 0.0
	for side in [-1, 1]:
		var paw := Vector2(side * 9 + stride * side * 5, -5 - maxf(stride * side * 5, lift))
		Art.ellipse(self, paw, Vector2(7,5), dark)
		Art.ellipse(self, paw + Vector2(0,-1), Vector2(5,3), cream)
	draw_colored_polygon(PackedVector2Array([Vector2(-16,-34),Vector2(-16,-55),Vector2(-3,-47),Vector2(9,-47),Vector2(22,-55),Vector2(23,-33)]), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(-13,-39),Vector2(-13,-50),Vector2(-4,-43)]), Color("bb7777"))
	draw_colored_polygon(PackedVector2Array([Vector2(12,-43),Vector2(20,-50),Vector2(20,-38)]), Color("bb7777"))
	Art.ellipse(self, Vector2(4,-33), Vector2(21,15), dark)
	Art.ellipse(self, Vector2(4,-33), Vector2(19,13), orange)
	for stripe in [-1, 0, 1]:
		draw_line(Vector2(4 + stripe * 5,-46), Vector2(5 + stripe * 4,-41 - absi(stripe)), Color("985738"), 2.4, true)
	Art.ellipse(self, Vector2(10,-26), Vector2(11,5), cream)
	for eye in [0, 16]:
		draw_line(Vector2(eye - 2,-35), Vector2(eye + 3,-34), dark, 1.4, true)
		Art.ellipse(self, Vector2(eye + 1,-33), Vector2(1.7,2.3), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(7,-28),Vector2(13,-28),Vector2(10,-25)]), Color("bf596f"))
	draw_line(Vector2(10,-25), Vector2(12,-24), dark, 1.1, true)
	draw_line(Vector2(-10,-29),Vector2(-17,-31),dark,1.1,true)
	draw_line(Vector2(-10,-26),Vector2(-17,-25),dark,1.1,true)
	draw_set_transform(Vector2.ZERO)
