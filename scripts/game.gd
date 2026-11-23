extends Node2D

const CatScript = preload("res://scripts/player.gd")
const MedalScript = preload("res://scripts/medal.gd")
const BouncePadScript = preload("res://scripts/bounce_pad.gd")
const RescueHelicopter = preload("res://scripts/rescue_helicopter.gd")
const MainMenu = preload("res://scripts/main_menu.gd")
const ROOF_TILES = preload("res://assets/roof_tiles.svg")
const Art = preload("res://scripts/art.gd")

const ExtraLevels = preload("res://scripts/extra_levels.gd")
const MENU_FPS := 12
const BACKGROUND_Z := -2

var state := "title":
	set(value):
		state = value
		_update_frame_limit()
var cat
var camera: Camera2D
var hud
var main_menu: Control
var gameplay_fps := int(ProjectSettings.get_setting("application/run/max_fps"))
var platforms: Array[Dictionary] = []
var route_lines: Array[Dictionary] = []
var trees: Array[Vector2] = []
var medals: Array = []
var score := 0
var rescue_count := 0
var helicopter: Node2D
var total_medals := 0
var level_number := 1
var level_root: Node2D
var level_theme: Dictionary = {}
var finish_x := 6150.0
var finish_y := 390.0
var main_platform_count := 0
var spawn := Vector2(100, 390)
var checkpoint_index := 0
var checkpoints: Array = []
var checkpoint := Vector2(100, 390)
var message_timer := 0.0
var message := ""

func _ready() -> void:
	_update_frame_limit()
	z_index = BACKGROUND_Z
	add_to_group("game")
	cat = CatScript.new()
	cat.game = self
	cat.spawn_point = Vector2(100, 390)
	add_child(cat)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.5
	camera.limit_left = -480
	camera.limit_right = 6750
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
	cat.z_index = 2
	_load_level(1)
	main_menu = MainMenu.new()
	main_menu.game = self
	layer.add_child(main_menu)

func set_gameplay_fps(fps: int) -> void:
	gameplay_fps = fps
	_update_frame_limit()

func _update_frame_limit() -> void:
	Engine.max_fps = gameplay_fps if state == "playing" else MENU_FPS

func _load_level(number: int) -> void:
	if is_instance_valid(level_root):
		remove_child(level_root)
		level_root.queue_free()
	level_root = Node2D.new()
	add_child(level_root)
	level_number = number
	platforms.clear()
	route_lines.clear()
	trees.clear()
	medals.clear()
	level_theme = {}
	if level_number == 1:
		_build_rooftop_run()
		finish_x = 6150.0
		finish_y = 390.0
		main_platform_count = platforms.size()
		checkpoints = [[1740, Vector2(1815, 365)], [3900, Vector2(3990, 385)]]
	else:
		level_theme = ExtraLevels.LEVELS[level_number - 2]
		for roof in level_theme.platforms:
			_add_platform(roof[0], roof[1], roof[2], roof[3])
		trees.assign(level_theme.trees)
		for line in level_theme.get("lines", []):
			_add_route_line(line[0], line[1], line[2], line[3], line[4])
		for point in level_theme.medals:
			_add_medal(point.x, point.y)
		for point in level_theme.pads:
			_add_bounce_pad(point.x, point.y)
		checkpoints = []
		for point in level_theme.checkpoints:
			checkpoints.append([point.x, point])
		var last: Dictionary = platforms.back()
		finish_x = float(last.x + last.w - 80)
		finish_y = last.y
		main_platform_count = platforms.size()
		for ledge in level_theme.get("branches", []):
			_add_platform(ledge[0], ledge[1], ledge[2], ledge[3], true)
	total_medals = medals.size()
	spawn = Vector2(100, float(platforms[0].y) - 30)
	checkpoint = spawn
	checkpoint_index = 0
	score = 0
	message = ""
	message_timer = 0.0
	cat.position = spawn
	cat.velocity = Vector2.ZERO
	cat.air_jump_available = true
	cat.climbing = false
	cat.facing = 1.0
	camera.limit_right = int(finish_x) + 600
	_reset_camera()
	_build_scenery()
	queue_redraw()

func _reset_camera() -> void:
	camera.position = cat.position + Vector2(160, -130)
	camera.reset_smoothing()
	camera.force_update_scroll()

func level_name() -> String:
	return "Rooftop Run" if level_number == 1 else str(level_theme.name)

func district_name() -> String:
	return "Moonlight Market" if level_number == 1 and cat.position.x >= 3400 else level_name()

func has_next_level() -> bool:
	return level_number <= ExtraLevels.LEVELS.size()

func _build_rooftop_run() -> void:
	# x, top y, width, style (roof, roof garden, finish)
	_add_platform(0, 420, 510, "roof")
	_add_platform(625, 350, 230, "balcony")
	_add_platform(970, 410, 335, "roof")
	_add_platform(1450, 325, 235, "balcony")
	_add_platform(1780, 395, 430, "roof")
	_add_platform(2335, 310, 220, "balcony")
	_add_platform(2690, 395, 650, "finish")
	# A second district turns the run into a longer adventure through the moonlit market.
	_add_platform(3520, 350, 230, "balcony")
	_add_platform(3870, 415, 400, "night")
	_add_platform(4390, 325, 220, "balcony")
	_add_platform(4710, 390, 420, "night")
	_add_platform(5220, 305, 230, "balcony")
	_add_platform(5550, 390, 720, "night_finish")
	_add_route_line(855, 970, 350, 410, true)
	_add_route_line(4610, 4710, 325, 390, false)
	trees = [Vector2(735, 342), Vector2(1560, 317), Vector2(2445, 302), Vector2(3635, 342), Vector2(4500, 317), Vector2(5335, 297)]
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
	# Moonlight Market — eight extra medals reward brave high jumps and tree climbs.
	_add_medal(3585, 292)
	_add_medal(3700, 255)
	_add_medal(4045, 365)
	_add_medal(4450, 265)
	_add_medal(4800, 335)
	_add_medal(5160, 320)
	_add_medal(5335, 245)
	_add_medal(5890, 330)
	# Launch points for the steep planted rooftops and the market entrance gap.
	_add_bounce_pad(1257, 410)
	_add_bounce_pad(3292, 395)
	_add_bounce_pad(4222, 415)

func _add_platform(x: float, top: float, width: float, style: String, ledge: bool = false) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	body.position = Vector2(x + width * 0.5, top + 14)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 28)
	shape.shape = rect
	body.add_child(shape)
	level_root.add_child(body)
	platforms.append({"x": x, "y": top, "w": width, "style": style, "ledge": ledge})

func _add_route_line(left: float, right: float, top: float, landing: float, laundry: bool) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2((left + right) * 0.5, top + 3)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(right - left + 12, 6)
	collider.shape = shape
	collider.one_way_collision = true
	body.add_child(collider)
	level_root.add_child(body)
	route_lines.append({"left": left, "right": right, "top": top, "landing": landing, "laundry": laundry})

func _add_medal(x: float, y: float) -> void:
	var medal = MedalScript.new()
	medal.position = Vector2(x, y)
	medal.z_index = 2
	level_root.add_child(medal)
	medals.append(medal)

func _add_bounce_pad(x: float, top: float) -> void:
	var pad = BouncePadScript.new()
	pad.position = Vector2(x, top)
	pad.game = self
	pad.z_index = 2
	level_root.add_child(pad)

func bounce_cat(body) -> void:
	body.velocity.y = -790.0
	body.air_jump_available = true
	show_message("Spring boost", 1.0)

func is_near_tree(x: float) -> bool:
	for tree in trees:
		if absf(x - tree.x) < 34:
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_confirm") and state == "won":
		cat.wait_for_jump_release = Input.is_action_pressed("jump")
		continue_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause_game") and (state == "playing" or state == "paused"):
		state = "paused" if state == "playing" else "playing"
		get_viewport().set_input_as_handled()

func start_game() -> void:
	if state == "title":
		main_menu.hide()
		state = "playing"
		show_message("Level 1 · " + level_name(), 2.0)

func continue_game() -> void:
	if state != "won":
		return
	var next := level_number + 1 if has_next_level() else 1
	if next == 1:
		rescue_count = 0
	_load_level(next)
	state = "playing"
	show_message("Level %d · %s" % [level_number, level_name()], 2.0)

func collect_medal(medal: Area2D) -> void:
	if state != "playing":
		return
	score += 1
	message = "Fish medal collected"
	message_timer = 1.4
	if score == total_medals:
		message = "All fish medals collected"
		message_timer = 2.2

func cat_fell() -> void:
	if state != "playing" or helicopter != null:
		return
	rescue_count += 1
	cat.velocity = Vector2.ZERO
	cat.climbing = false
	cat.set_deferred("collision_layer", 0)
	var clearance := float(platforms[0].y)
	for platform in platforms:
		clearance = minf(clearance, platform.y)
	helicopter = RescueHelicopter.new()
	helicopter.z_index = 3
	level_root.add_child(helicopter)
	helicopter.setup(cat.position, checkpoint, clearance - 165.0)
	show_message("Rescue inbound", 2.8)

func _update_rescue(delta: float) -> void:
	helicopter.advance(delta)
	cat.position = helicopter.passenger_position
	camera.position = cat.position + Vector2(120, -145)
	camera.reset_smoothing()
	if helicopter.finished:
		helicopter.queue_free()
		helicopter = null
		cat.set_deferred("collision_layer", 1)
		cat.air_jump_available = true
		cat.wait_for_jump_release = Input.is_action_pressed("jump")
		show_message("Rescue complete", 1.1)

func show_message(text: String, duration: float = 1.4) -> void:
	message = text
	message_timer = duration

func _process(delta: float) -> void:
	if helicopter != null:
		if state == "playing":
			_update_rescue(delta)
		return
	if message_timer > 0:
		message_timer -= delta
	if state == "playing":
		var target: Vector2 = cat.position + Vector2(160, -130)
		if camera.position != target:
			camera.position = target
		if checkpoint_index < checkpoints.size() and cat.position.x > checkpoints[checkpoint_index][0]:
			checkpoint = checkpoints[checkpoint_index][1]
			checkpoint_index += 1
			show_message("Checkpoint reached", 2.0)
		if cat.position.x > finish_x:
			state = "won"
			cat.velocity = Vector2.ZERO

func _build_scenery() -> void:
	var buildings := 49 if level_number == 1 else ceili((finish_x + 1400) / 160.0)
	for row in range(2):
		for start in range(0, buildings, 5):
			var skyline := _scenery_layer()
			skyline.draw.connect(_draw_skyline.bind(skyline, row, start))
	for line in route_lines:
		var crossing := _scenery_layer()
		crossing.draw.connect(_draw_route_line.bind(crossing, line))
	for platform in platforms:
		var rooftop := _scenery_layer()
		rooftop.draw.connect(_draw_rooftop.bind(rooftop, platform))
	for tree in trees:
		var canopy := _scenery_layer()
		canopy.draw.connect(_draw_tree.bind(canopy, tree))
	var signs := _scenery_layer()
	signs.draw.connect(_draw_signs.bind(signs))

func _scenery_layer() -> Node2D:
	var layer := Node2D.new()
	layer.z_index = 1
	level_root.add_child(layer)
	return layer

func _draw() -> void:
	_draw_sky()

func _draw_signs(canvas: Node2D) -> void:
	if level_number == 1:
		canvas.draw_line(Vector2(3512, 258), Vector2(3512, 350), Color("614054"), 6, true)
		_draw_lantern(canvas, Vector2(3512, 282))
	var flag_x := 6218.0 if level_number == 1 else finish_x + 18.0
	var top := Vector2(flag_x, finish_y - 97)
	canvas.draw_line(top + Vector2(0, 97), top, Art.CREAM, 5, true)
	canvas.draw_colored_polygon(PackedVector2Array([top + Vector2(2,1), top + Vector2(65,11),
		top + Vector2(50,29), top + Vector2(65,46), top + Vector2(2,40)]), Color("c95d79"))
	Art.sparkle(canvas, top + Vector2(24,23), 10, Art.GOLD)

func _draw_sky() -> void:
	if level_number != 1:
		var bounds := PackedVector2Array([Vector2(-1000,-300), Vector2(finish_x+1000,-300),
			Vector2(finish_x+1000,950), Vector2(-1000,950)])
		draw_polygon(bounds, PackedColorArray([level_theme.sky, level_theme.sky, level_theme.horizon, level_theme.horizon]))
		for i in range(ceili(finish_x / 380.0) + 2):
			var center := Vector2(i * 380 - 140, 70 + (i * 59) % 140)
			Art.ellipse(self, center, Vector2(60, 14), Color(Art.CREAM, 0.45))
			Art.ellipse(self, center + Vector2(-14,-13), Vector2(29, 17), Color(Art.CREAM, 0.55))
			if level_number == 3:
				Art.sparkle(self, center + Vector2(126,-47), 6, Art.CREAM)
		if _is_waterfront():
			var water := Color("535c93") if level_number == 3 else Color("4794a1")
			draw_rect(Rect2(-1000,478,finish_x+2000,472), water)
			for i in range(35):
				var wave := Vector2(-300 + i * 118, 493 + (i * 37) % 150)
				draw_line(wave, wave + Vector2(18 + i % 4 * 10, 0), Color("a6a9cf", 0.7), 2, true)
		_draw_level_motif()
		return
	var day_top := Color("578fa4")
	var day_bottom := Color("efcba4")
	var night_top := Color("242c48")
	var night_bottom := Color("825f7e")
	var sky := PackedVector2Array([Vector2(-1000,-300), Vector2(7300,-300), Vector2(7300,740), Vector2(-1000,740)])
	for i in range(36):
		var weight := float(i) / 35.0
		var x := 3060.0 + i * 20.0
		var left := -1000.0 if i == 0 else x
		var right := 7300.0 if i == 35 else x + 20
		sky[0].x = left
		sky[1].x = right
		sky[2].x = right
		sky[3].x = left
		var top := day_top.lerp(night_top, weight)
		var bottom := day_bottom.lerp(night_bottom, weight)
		var next := minf(weight + 1.0 / 35.0, 1.0)
		draw_polygon(sky, PackedColorArray([top, day_top.lerp(night_top, next), day_bottom.lerp(night_bottom, next), bottom]))
	draw_circle(Vector2(125,118), 62, Color("ffe7aa", 0.36), true, -1.0, true)
	draw_circle(Vector2(125,118), 46, Color("fff1be"), true, -1.0, true)
	draw_circle(Vector2(4108,105), 47, Color("eecef3", 0.18), true, -1.0, true)
	var moon := PackedVector2Array()
	for i in range(33):
		var angle := lerpf(-1.05, 2.61, float(i) / 32.0)
		moon.append(Vector2(4108,105) + Vector2(cos(angle), sin(angle)) * 33)
	for i in range(1, 24):
		var t := float(i) / 24.0
		moon.append((1.0-t)*(1.0-t)*moon[32] + 2.0*t*(1.0-t)*Vector2(4125,114) + t*t*moon[0])
	draw_colored_polygon(moon, Art.CREAM)
	for i in range(42):
		Art.sparkle(self, Vector2(3600 + (i * 173) % 3150, -40 + (i * 79) % 240), 2.5 + i % 4, Color("ffedc0", 0.75))
	for i in range(17):
		var at := Vector2(-220 + i * 416, 87 + (i * 67) % 115)
		var cloud := Color("fff4e2", 0.66) if at.x < 3300 else Color("dbaed4", 0.35)
		Art.ellipse(self, at, Vector2(47, 13), cloud)
		Art.ellipse(self, at + Vector2(-11,-12), Vector2(21, 16), cloud)

func _is_waterfront() -> bool:
	return level_number == 3 or level_theme.get("motif", "") == "coast"

func _draw_level_motif() -> void:
	match level_theme.get("motif", ""):
		"rain", "snow", "stars":
			for i in range(75):
				var at := Vector2(float((i*149) % int(finish_x+520)) - 200, -75 + (i*67)%370)
				if level_theme.motif == "rain":
					draw_line(at, at+Vector2(-4,12), Color("e5f5f6", 0.5), 1.6, true)
				elif level_theme.motif == "snow":
					draw_circle(at, 1.4 + i % 3, Color("ffffff", 0.72), true, -1.0, true)
				else:
					Art.sparkle(self, at, 2.0 + i % 5, Color("fff0b5", 0.8))
		"kites":
			for i in range(9):
				var at := Vector2(115 + i*355, 65 + (i*61)%135)
				var cloth: Color = [Color("ef9299"), Color("ffcb7c"), Color("b59adb")][i%3]
				draw_colored_polygon(PackedVector2Array([at-Vector2(0,22), at+Vector2(16,0),
					at+Vector2(0,29), at-Vector2(16,0)]), cloth)
				draw_polyline(PackedVector2Array([at+Vector2(0,25), at+Vector2(-6,41),
					at+Vector2(0,53), at+Vector2(-7,68)]), Art.CREAM, 2, true)
		"steam", "orchard", "coast":
			var sun := Vector2(finish_x*0.29,108)
			draw_circle(sun, 71, Color("ffe2a3", 0.42), true, -1.0, true)
			draw_circle(sun, 49, Color("fff0b8"), true, -1.0, true)

func _draw_skyline(canvas: Node2D, row: int, start: int) -> void:
	for i in range(start, mini(start + 5, 49)):
		var x := -640.0 + i * 160 + row * 74
		var y := 340.0 - (i * 39 + row * 45) % 126 + row * 84
		var night := clampf((x-3060)/700, 0, 1)
		var wall := Color("83aaad").lerp(Color("79648e"), night) if row == 0 else Color("648c94").lerp(Color("67567b"), night)
		if level_number != 1:
			var skyline: Color = level_theme.skyline
			wall = skyline.darkened(row * 0.13)
		var roof := wall.darkened(0.12)
		var ground := 478.0 if _is_waterfront() else 850.0
		canvas.draw_rect(Rect2(x, y, 136, ground - y), wall)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x-8,y+4),Vector2(x+41,y-34),Vector2(x+94,y-34),Vector2(x+144,y+4)]), roof)
		for col in range(3):
			Art.panel(canvas, Rect2(x+18+col*39,y+21,17,29), Color("e2dac1").lerp(Color("e8b37e"), night), 7)
		canvas.draw_rect(Rect2(x+9, y+68, 118, 4), roof)

func _draw_route_line(canvas: Node2D, line: Dictionary) -> void:
	var left := Vector2(line.left, line.top)
	var right := Vector2(line.right, line.top)
	var cable := Color("f4dc9d") if line.laundry else Color("adcfd2")
	canvas.draw_line(left - Vector2(5,0), right + Vector2(5,0), Art.INK, 7, true)
	canvas.draw_line(left - Vector2(5,0), right + Vector2(5,0), cable, 3, true)
	canvas.draw_line(right, Vector2(right.x, line.landing + 5), Art.INK, 5, true)
	canvas.draw_circle(left, 5, cable, true, -1.0, true)
	canvas.draw_circle(right, 5, cable, true, -1.0, true)
	if line.laundry:
		var clothes := [Color("d48e76"), Color("779fb9"), Color("dbcda1")]
		for i in range(3):
			var at := left.lerp(right, (i + 1) / 4.0)
			var drop := 16 + (i % 2) * 8
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-9,3), at + Vector2(9,3),
				at + Vector2(12,drop), at + Vector2(-7,drop + 2)]), clothes[i])
			canvas.draw_line(at + Vector2(-5,-2), at + Vector2(-5,5), Art.CREAM, 2, true)
	else:
		canvas.draw_polyline(PackedVector2Array([left + Vector2(0,8), left.lerp(right,0.25) + Vector2(0,15),
			left.lerp(right,0.5) + Vector2(0,19), left.lerp(right,0.75) + Vector2(0,15), right + Vector2(0,8)]),
			Art.INK, 2, true)

func _draw_rooftop(canvas: Node2D, platform: Dictionary) -> void:
	var x: float = platform.x
	var y: float = platform.y
	var w: float = platform.w
	var balcony: bool = platform.style == "balcony"
	var night: bool = level_number == 3 or level_theme.get("motif", "") == "stars" or (level_number == 1 and x >= 3400)
	var trim := Color("c98064") if not night else Color("726a9c")
	var wall := Color("ae7063") if not night else Color("444865")
	if balcony:
		trim = Color("99bc80") if not night else Color("80bc9a")
		wall = Color("5b8071") if not night else Color("47776d")
	elif platform.style == "finish":
		trim = Art.GOLD
		wall = Color("c78a62")
	if level_number != 1 and not balcony:
		trim = Art.GOLD if platform.style == "finish" else level_theme.trim
		wall = level_theme.wall
	var edge := Art.INK
	if platform.ledge:
		# Upper penthouses and lower annexes use the same roof coping as the main route.
		Art.panel(canvas, Rect2(x, y, w, 28), wall, 4, edge, 2)
		canvas.draw_line(Vector2(x+5,y+4), Vector2(x+w-5,y+4), trim, 3, true)
		for dx in range(13, int(w)-7, 27):
			canvas.draw_line(Vector2(x+dx,y+10),Vector2(x+dx,y+24),edge.lightened(0.17),1,true)
		return
	var fascia := 28.0 if balcony else 62.0
	canvas.draw_rect(Rect2(x, y+fascia-2, w, 570), wall)
	canvas.draw_rect(Rect2(x+w-10, y+fascia, 10, 554), wall.darkened(0.14))
	if balcony:
		canvas.draw_line(Vector2(x+4,y-22), Vector2(x+w-4,y-22), trim, 3, true)
		for dx in range(5, int(w)-3, 18):
			canvas.draw_line(Vector2(x+dx,y-22),Vector2(x+dx,y),wall.darkened(0.35),2,true)
		Art.panel(canvas, Rect2(x,y,w,28), trim, 5, edge, 2)
	else:
		var tile_tint := Color("a89cc2") if night else Color.WHITE
		if level_theme.get("motif", "") == "snow":
			tile_tint = Color("c3d8f1")
		canvas.draw_texture_rect(ROOF_TILES, Rect2(x,y+2,w,60), true, tile_tint)
		canvas.draw_rect(Rect2(x,y+1,w,60), edge, false, 1.5)
		canvas.draw_line(Vector2(x+1,y+2),Vector2(x+w-1,y+2),trim.lightened(0.37),3,true)
		canvas.draw_line(Vector2(x+1,y+61),Vector2(x+w-1,y+61),edge,2,true)
	for dx in range(28, int(w)-38, 70):
		var window := Rect2(x+dx,y+fascia+35,34,52)
		Art.panel(canvas, window, Color("e7ad71") if night else Color("8cb6ba"), 14, wall.darkened(0.35), 3)
		canvas.draw_line(window.position+Vector2(17,6),window.position+Vector2(17,48),wall.darkened(0.25),2,true)
		canvas.draw_line(window.position+Vector2(4,28),window.position+Vector2(30,28),wall.darkened(0.25),2,true)
		Art.panel(canvas, Rect2(x+dx-3,y+fascia+83,40,6), trim, 3)
		if night and not balcony and dx % 3 != 0:
			_draw_lantern(canvas, Vector2(x+dx+50,y+fascia+24))
	for dx in range(22, int(w)-14, 43 if balcony else 126):
		var at := Vector2(x+dx,y)
		if balcony:
			Art.ellipse(canvas, at+Vector2(0,-13), Vector2(13,8), Color("4a8c74"))
			Art.ellipse(canvas, at+Vector2(2,-17), Vector2(6,8), Color("81bc85"))
			Art.panel(canvas, Rect2(at+Vector2(-12,-10),Vector2(24,10)), Color("936a52"), 2, edge, 1)
		else:
			Art.panel(canvas, Rect2(at+Vector2(-12,-14),Vector2(24,14)), wall.darkened(0.18), 3, edge, 1)
			for slit in [-7, 0, 7]:
				canvas.draw_line(at+Vector2(slit,-10),at+Vector2(slit,-4),trim,1.5,true)

func _draw_tree(canvas: Node2D, at: Vector2) -> void:
	var crown := at + Vector2(0,-119)
	canvas.draw_line(at+Vector2(0,8), crown, Color("69454c"), 22, true)
	canvas.draw_line(at+Vector2(-3,4), crown+Vector2(-3,0), Color("bd8961"), 9, true)
	canvas.draw_line(crown+Vector2(0,18), crown+Vector2(28,-3), Color("69454c"), 11, true)
	for step in range(3):
		Art.panel(canvas, Rect2(at+Vector2(-11,-22-step*30), Vector2(22,5)), Art.GOLD, 2, Color("69454c"), 1)
	Art.panel(canvas, Rect2(at+Vector2(-25,-4),Vector2(50,12)), Color("9b7353"), 3, Art.INK, 2)
	var leaves := Color("579878") if at.x < 3400 else Color("487c78")
	Art.ellipse(canvas,crown,Vector2(58,39),leaves.darkened(0.22))
	Art.ellipse(canvas,crown+Vector2(-19,-8),Vector2(35,29),leaves)
	Art.ellipse(canvas,crown+Vector2(19,-10),Vector2(38,31),leaves)
	Art.ellipse(canvas,crown+Vector2(-1,-28),Vector2(32,27),leaves.lightened(0.19))
	for offset in [Vector2(-32,-5),Vector2(-15,-32),Vector2(22,-27),Vector2(34,2)]:
		Art.ellipse(canvas,crown+offset,Vector2(4,6),Color("f7ba83"))

func _draw_lantern(canvas: Node2D, at: Vector2) -> void:
	canvas.draw_circle(at, 19, Color("ffce65", 0.19), true, -1.0, true)
	canvas.draw_line(at-Vector2(0,24),at-Vector2(0,8),Color("5e425a"),2,true)
	Art.panel(canvas, Rect2(at-Vector2(9,10),Vector2(18,23)), Color("ffba73"), 6, Color("8c4a60"), 2)
	canvas.draw_line(at-Vector2(0,7),at+Vector2(0,9),Art.CREAM,2,true)
