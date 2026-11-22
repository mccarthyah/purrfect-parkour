extends Node2D

const CatScript = preload("res://scripts/player.gd")
const MedalScript = preload("res://scripts/medal.gd")
const SKY := Color("74b9d7")

var state := "title"
var cat
var camera: Camera2D
var hud
var platforms: Array[Dictionary] = []
var trees: Array[Vector2] = []
var medals: Array = []
var score := 0
var total_medals := 10
var checkpoint := Vector2(100, 390)
var message_timer := 0.0
var message := ""
var elapsed := 0.0

func _ready() -> void:
	add_to_group("game")
	_build_level()
	cat = CatScript.new()
	cat.game = self
	cat.spawn_point = Vector2(100, 390)
	add_child(cat)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.5
	camera.limit_left = -480
	camera.limit_right = 3880
	camera.limit_top = -270
	camera.limit_bottom = 920
	add_child(camera)
	camera.position = cat.position + Vector2(160, -130)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Node2D.new()
	hud.set_script(load("res://scripts/hud.gd"))
	hud.game = self
	layer.add_child(hud)
	queue_redraw()

func _build_level() -> void:
	# x, top y, width, style (roof, garden, finish)
	_add_platform(0, 420, 510, "roof")
	_add_platform(625, 350, 230, "garden")
	_add_platform(970, 410, 335, "roof")
	_add_platform(1450, 325, 235, "garden")
	_add_platform(1780, 395, 430, "roof")
	_add_platform(2335, 310, 220, "garden")
	_add_platform(2690, 395, 650, "finish")
	trees = [Vector2(735, 342), Vector2(1560, 317), Vector2(2445, 302)]
	# Shiny fish medals sit on tempting routes and high branches.
	_add_medal(250, 365)
	_add_medal(565, 330)
	_add_medal(735, 284)
	_add_medal(1100, 355)
	_add_medal(1500, 270)
	_add_medal(1645, 275)
	_add_medal(1925, 340)
	_add_medal(2190, 325)
	_add_medal(2450, 255)
	_add_medal(3025, 338)

func _add_platform(x: float, top: float, width: float, style: String) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	body.position = Vector2(x + width * 0.5, top + 14)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 28)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)
	platforms.append({"x": x, "y": top, "w": width, "style": style})

func _add_medal(x: float, y: float) -> void:
	var medal = MedalScript.new()
	medal.position = Vector2(x, y)
	add_child(medal)
	medals.append(medal)

func is_near_tree(x: float) -> bool:
	for tree in trees:
		if absf(x - tree.x) < 34:
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if state == "title" and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
			start_game()
		elif state == "won" and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
			restart_game()
		elif state == "playing" and event.keycode == KEY_ESCAPE:
			state = "paused" if state == "playing" else "playing"
		elif state == "paused" and event.keycode == KEY_ESCAPE:
			state = "playing"
		hud.queue_redraw()

func start_game() -> void:
	if state == "title":
		state = "playing"
		cat.position = Vector2(100, 390)
		cat.velocity = Vector2.ZERO
		camera.position_smoothing_enabled = false
		camera.position = cat.position + Vector2(160, -130)
		camera.position_smoothing_enabled = true
		hud.queue_redraw()

func restart_game() -> void:
	score = 0
	checkpoint = Vector2(100, 390)
	for medal in medals:
		medal.taken = false
		medal.monitoring = true
		medal.queue_redraw()
	cat.position = Vector2(100, 390)
	cat.velocity = Vector2.ZERO
	state = "playing"
	camera.position_smoothing_enabled = false
	camera.position = cat.position + Vector2(160, -130)
	camera.position_smoothing_enabled = true
	hud.queue_redraw()

func collect_medal(medal: Area2D) -> void:
	if state != "playing":
		return
	score += 1
	message = "Fish medal! Nice catch!"
	message_timer = 1.4
	if score == total_medals:
		message = "Every fish! You're a purrkour pro!"
		message_timer = 2.2
	hud.queue_redraw()

func cat_fell() -> void:
	cat.position = checkpoint
	cat.velocity = Vector2.ZERO
	cat.invulnerable = 1.0
	message = "Whoops! Try that jump again."
	message_timer = 1.7

func _process(delta: float) -> void:
	elapsed += delta
	if message_timer > 0:
		message_timer -= delta
	if camera and state == "playing":
		camera.position = cat.position + Vector2(160, -130)
	if state == "playing":
		if cat.position.x > 1740 and checkpoint.x < 1700:
			checkpoint = Vector2(1815, 365)
			message = "Checkpoint! You're doing great!"
			message_timer = 2.0
		if cat.position.x > 3220:
			state = "won"
			cat.velocity = Vector2.ZERO
		if cat.position.x > 3120:
			message = "Home stretch! Reach the rooftop garden!"
			message_timer = maxf(message_timer, 0.2)
		hud.queue_redraw()
	queue_redraw()

func _draw() -> void:
	# Big sky backdrop; the parallax layers create a breezy storybook city.
	draw_rect(Rect2(-1000, -800, 6000, 1800), SKY)
	draw_rect(Rect2(-1000, 260, 6000, 600), Color("ffe6b9"))
	# Sun and drifting clouds
	draw_circle(Vector2(780, 105), 45, Color("ffe9a5"))
	for cloud in [Vector2(150,115), Vector2(490,185), Vector2(980,125), Vector2(1430,165), Vector2(2110,110), Vector2(2790,160), Vector2(3250,95)]:
		_draw_cloud(cloud)
	# Distant pastel city silhouettes
	for i in range(19):
		var x := float(i) * 190 - 70
		var height := 95.0 + float((i * 47) % 115)
		var col := [Color("91c6ca"), Color("8dbdc4"), Color("9bcbd0")][i % 3]
		draw_rect(Rect2(x, 360-height, 145, height+80), col)
		draw_rect(Rect2(x+18, 385-height, 44, 25), Color("d5e8d2", 0.8))
		draw_rect(Rect2(x+83, 385-height, 40, 25), Color("f8d6a2", 0.85))
		for wy in range(0, int(height/37)):
			for wx in range(2):
				draw_rect(Rect2(x+20+wx*54, 398-height+wy*34, 20, 15), Color("f9dfaa", 0.7))
	# Roofs, bright ledges and rooftop details
	for p in platforms:
		var x: float = p.x
		var y: float = p.y
		var w: float = p.w
		var style: String = p.style
		var wall := Color("e98475") if style == "roof" else (Color("8cbb79") if style == "garden" else Color("e9a755"))
		draw_rect(Rect2(x, y, w, 220), wall)
		draw_rect(Rect2(x, y, w, 16), Color("fff1d2"))
		draw_rect(Rect2(x, y+16, w, 7), Color("d76566") if style != "garden" else Color("6b9e63"))
		# Repeated windows and tiny ledge planters
		for wx in range(26, int(w)-10, 62):
			draw_rect(Rect2(x+wx, y+57, 30, 42), Color("526c82", 0.8))
			draw_rect(Rect2(x+wx+4, y+61, 22, 33), Color("f9dd9d"))
			draw_line(Vector2(x+wx+15, y+61), Vector2(x+wx+15, y+94), Color("d18d63"), 2)
		if style == "garden":
			for plant_x in range(24, int(w)-15, 38):
				draw_line(Vector2(x+plant_x, y), Vector2(x+plant_x-4, y-18), Color("477b53"), 4)
				draw_line(Vector2(x+plant_x, y), Vector2(x+plant_x+7, y-13), Color("5a965d"), 4)
		else:
			for box_x in range(55, int(w)-35, 145):
				draw_rect(Rect2(x+box_x, y-23, 52, 22), Color("b76659"))
				draw_circle(Vector2(x+box_x+14, y-26), 13, Color("77a95f"))
				draw_circle(Vector2(x+box_x+33, y-29), 14, Color("6f9e5a"))
	# Trees are climbable; gold rings show the trunk route.
	for tree in trees:
		draw_rect(Rect2(tree.x-12, tree.y-126, 24, 150), Color("9a6745"))
		draw_rect(Rect2(tree.x-5, tree.y-126, 6, 150), Color("bd8551"))
		draw_circle(tree + Vector2(0,-137), 52, Color("58a86f"))
		draw_circle(tree + Vector2(-31,-122), 31, Color("6dbc78"))
		draw_circle(tree + Vector2(34,-118), 34, Color("4e9d68"))
		draw_circle(tree + Vector2(4,-163), 31, Color("78c87c"))
		for ring in range(3):
			draw_arc(Vector2(tree.x, tree.y-24-ring*34), 13, 0, TAU, 20, Color("f6d27d", 0.75), 2)
	# Finish marker
	draw_rect(Rect2(3260, 310, 5, 85), Color("fff2d1"))
	draw_colored_polygon(PackedVector2Array([Vector2(3265,310),Vector2(3320,330),Vector2(3265,350)]), Color("f28a74"))
	for i in range(8):
		draw_circle(Vector2(3180 + i*18, 355 + sin(elapsed*2+i)*4), 3, Color("fff4cc"))

func _draw_cloud(at: Vector2) -> void:
	var c := Color(1, 1, 1, 0.78)
	draw_circle(at, 20, c)
	draw_circle(at + Vector2(25,-8), 26, c)
	draw_circle(at + Vector2(53,0), 18, c)
	draw_rect(Rect2(at.x, at.y-1, 53, 20), c)
