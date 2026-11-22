extends Node2D

var game
var font: Font
const INK := Color("283b52")
const CREAM := Color("fff6df")
const GOLD := Color("ffcf4e")
const BUTTON := Rect2(365, 365, 230, 64)

func _ready() -> void:
	font = ThemeDB.fallback_font
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point := get_viewport().get_mouse_position()
		if game.state == "title" and BUTTON.has_point(point):
			game.start_game()
		elif game.state == "won" and BUTTON.has_point(point):
			game.restart_game()

func _draw() -> void:
	if game == null:
		return
	if game.state == "title":
		_draw_title()
	elif game.state == "playing":
		_draw_game_hud()
		if game.message_timer > 0:
			_draw_message(game.message)
	elif game.state == "paused":
		_draw_game_hud()
		_draw_overlay("PAUSED", "Stretch those paws! Press Esc to keep going.", "Press Esc to resume")
	elif game.state == "won":
		_draw_win()

func _draw_title() -> void:
	_draw_panel(Rect2(200, 44, 560, 440), Color("fff5dc", 0.94))
	_draw_text_center("PURRFECT PARKOUR", 133, 43, Color("e87961"))
	_draw_text_center("A rooftop adventure for curious cats!", 169, 19, INK)
	# Little decorative fish and paw prints
	_draw_paw(Vector2(264, 215), 0.72, Color("f3ac67", 0.8))
	_draw_paw(Vector2(702, 213), 0.72, Color("f3ac67", 0.8))
	_draw_fish(Vector2(480, 224), 1.0)
	_draw_text_center("Jump rooftops • climb trees • collect fish medals", 274, 16, INK)
	_draw_text_center("Move: A / D or ← / →      Jump: Space / ↑", 308, 15, Color("59687a"))
	_draw_text_center("At a tree, hold ↑ or ↓ to climb!", 333, 15, Color("59687a"))
	var mouse := get_viewport().get_mouse_position()
	var color := Color("f2a94e") if BUTTON.has_point(mouse) else Color("efb94f")
	_draw_button(BUTTON, color, "LET'S PLAY!")
	_draw_text_center("Tip: fish can be tucked above the rooftops.", 458, 13, Color("8a7d6d"))

func _draw_game_hud() -> void:
	_draw_panel(Rect2(18, 16, 180, 56), Color("fff5dc", 0.94))
	_draw_fish(Vector2(43, 43), 0.62)
	_draw_text("FISH  %02d / %02d" % [game.score, game.total_medals], Vector2(63, 49), 17, INK)
	_draw_panel(Rect2(354, 16, 252, 42), Color("fff5dc", 0.82))
	_draw_text_center("ROOFTOP RUN  ✦  %d%%" % int(clampf(game.cat.position.x / 3220.0 * 100, 0, 100)), 44, 14, INK)
	_draw_panel(Rect2(712, 16, 230, 56), Color("fff5dc", 0.92))
	_draw_text("A / D  Move     SPACE  Jump", Vector2(726, 39), 11, INK)
	_draw_text("↑ / ↓ at trees   •   ESC pause", Vector2(726, 57), 11, INK)
	# Progress bar
	draw_rect(Rect2(369, 54, 222, 4), Color("d8d2bd"))
	draw_rect(Rect2(369, 54, 222 * clampf(game.cat.position.x / 3220.0, 0, 1), 4), Color("efad49"))

func _draw_message(text: String) -> void:
	_draw_panel(Rect2(278, 80, 404, 42), Color("fff5dc", 0.94))
	_draw_text_center(text, 107, 15, Color("b56058"))

func _draw_overlay(title: String, subtitle: String, footer: String) -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color(0.12, 0.2, 0.28, 0.45))
	_draw_panel(Rect2(220, 170, 520, 200), Color("fff5dc", 0.97))
	_draw_text_center(title, 238, 38, Color("e87961"))
	_draw_text_center(subtitle, 285, 16, INK)
	_draw_text_center(footer, 333, 15, Color("687384"))

func _draw_win() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color(0.12, 0.2, 0.28, 0.48))
	_draw_panel(Rect2(205, 80, 550, 390), Color("fff5dc", 0.97))
	_draw_text_center("YOU DID IT, SUPER CAT!", 151, 34, Color("e87961"))
	_draw_paw(Vector2(284, 219), 0.8, Color("f1af56"))
	_draw_paw(Vector2(676, 218), 0.8, Color("f1af56"))
	_draw_fish(Vector2(480, 211), 1.3)
	_draw_text_center("Rooftop champion! Fish medals: %d / %d" % [game.score, game.total_medals], 272, 17, INK)
	var praise := "A perfect catch! You found every fish!" if game.score == game.total_medals else "Every brave jump makes you better!"
	_draw_text_center(praise, 303, 15, Color("657489"))
	_draw_button(BUTTON, Color("efb94f"), "PLAY AGAIN")
	_draw_text_center("Press Enter to take another run", 458, 13, Color("8a7d6d"))

func _draw_button(rect: Rect2, color: Color, label: String) -> void:
	draw_rect(Rect2(rect.position.x, rect.position.y+5, rect.size.x, rect.size.y), Color("bf8050"))
	draw_rect(rect, color)
	_draw_text_center(label, rect.position.y + 40, 23, Color("fffaf0"))

func _draw_panel(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position.x, rect.position.y+4, rect.size.x, rect.size.y), Color(0.14,0.19,0.25,0.14))
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position.x+8, rect.position.y+7, rect.size.x-16, 2), Color(1,1,1,0.45))

func _draw_text_center(text: String, baseline: float, size: int, color: Color) -> void:
	draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, 960, size, color)

func _draw_text(text: String, at: Vector2, size: int, color: Color) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw_fish(at: Vector2, scale: float) -> void:
	draw_set_transform(at, 0, Vector2.ONE * scale)
	draw_colored_polygon(PackedVector2Array([Vector2(-10,0),Vector2(-23,-10),Vector2(-21,10),Vector2(-10,2),Vector2(-3,10),Vector2(11,10),Vector2(19,4),Vector2(19,-4),Vector2(11,-10),Vector2(-3,-10)]), GOLD)
	draw_circle(Vector2(12,-3), 1.6, INK)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_paw(at: Vector2, scale: float, color: Color) -> void:
	draw_set_transform(at, -0.2, Vector2.ONE * scale)
	draw_circle(Vector2(0,5), 12, color)
	draw_circle(Vector2(-13,-9), 5, color)
	draw_circle(Vector2(-4,-14), 5, color)
	draw_circle(Vector2(6,-14), 5, color)
	draw_circle(Vector2(15,-8), 5, color)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
