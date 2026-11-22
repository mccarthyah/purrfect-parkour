extends CharacterBody2D
const RUN_SPEED := 310.0
const GRAVITY := 1450.0
const JUMP_SPEED := -610.0
const CLIMB_SPEED := 210.0

var game
var facing := 1.0
var climbing := false
var air_jump_available := true
var walk_time := 0.0
var invulnerable := 0.0
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
	if game == null or game.state != "playing":
		velocity = Vector2.ZERO
		return
	if invulnerable > 0:
		invulnerable -= delta
	var input_x := Input.get_axis("move_left", "move_right")
	if input_x != 0:
		facing = signf(input_x)
		walk_time += delta * 12.0
	velocity.x = input_x * RUN_SPEED

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
		if Input.is_action_just_pressed("jump") and not Input.is_action_pressed("climb_up"):
			climbing = false
			velocity.y = JUMP_SPEED
	else:
		if is_on_floor():
			air_jump_available = true
			if velocity.y > 0:
				velocity.y = 0
		else:
			velocity.y += GRAVITY * delta
		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				velocity.y = JUMP_SPEED
			elif air_jump_available:
				velocity.y = JUMP_SPEED * 0.88
				air_jump_available = false
				game.show_message("Air-pounce! Great save!", 1.0)

	move_and_slide()
	if position.y > 760:
		game.cat_fell()
	queue_redraw()

func _draw() -> void:
	if invulnerable > 0 and int(invulnerable * 16) % 2 == 0:
		return
	var bob := sin(walk_time) * 2.0 if is_on_floor() and absf(velocity.x) > 5 else 0.0
	var lean := -0.10 * facing if absf(velocity.x) > 5 else 0.0
	draw_set_transform(Vector2(0, bob), lean, Vector2(1, 1))
	# Tail, ears, and soft shadow
	draw_set_transform(Vector2(1, 1), 0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 23, Color(0.08, 0.17, 0.24, 0.18))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_line(Vector2(-10 * facing, -17), Vector2(-20 * facing, -27), Color("f7a449"), 7, true)
	draw_circle(Vector2(-21 * facing, -28), 5, Color("f7a449"))
	# Body and head
	draw_colored_polygon(PackedVector2Array([Vector2(-13,-26),Vector2(-12,-38),Vector2(-22,-52),Vector2(-7,-48),Vector2(0,-53),Vector2(8,-48),Vector2(23,-52),Vector2(15,-37),Vector2(15,-26)]), Color("f7a449"))
	draw_circle(Vector2(0, -25), 16, Color("f7a449"))
	draw_circle(Vector2(-5, -25), 2.1, Color("26354b"))
	draw_circle(Vector2(7, -25), 2.1, Color("26354b"))
	draw_colored_polygon(PackedVector2Array([Vector2(-1,-19),Vector2(3,-19),Vector2(1,-16)]), Color("ee7e7f"))
	draw_line(Vector2(-5,-15), Vector2(1,-13), Color("754b40"), 1.5)
	draw_line(Vector2(3,-13), Vector2(8,-15), Color("754b40"), 1.5)
	# Paws
	var step := sin(walk_time) * 4.0 if is_on_floor() and absf(velocity.x) > 5 else 0.0
	draw_circle(Vector2(-8 + step, -5), 6, Color("f7a449"))
	draw_circle(Vector2(9 - step, -5), 6, Color("f7a449"))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
