extends Node2D

const Art = preload("res://scripts/art.gd")
const PANEL := Color("192430e6")
const PANEL_BORDER := Color("536473")
const TEXT := Color("eef1ee")
const MUTED := Color("b8c5cf")
const ACCENT := Color("edb963")
const BUTTON_TEXT := Color("1d2429")
const RESULTS_BUTTON := Rect2(355, 350, 250, 52)
const SCREEN := Rect2(0, 0, 960, 540)

var game
var font: Font
var heading: FontVariation
var last_display: Array = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	heading = FontVariation.new()
	heading.base_font = font
	heading.variation_embolden = 0.85
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var display: Array = [game.state, game.level_number, game.rescue_count]
	if game.state == "playing" or game.state == "paused":
		display.append_array([game.score, game.district_name(), _progress()])
		if game.state == "playing" and game.message_timer > 0:
			display.append(game.message)
	elif game.state == "won":
		display.append(RESULTS_BUTTON.has_point(get_viewport().get_mouse_position()))
	if display != last_display:
		last_display = display
		queue_redraw()

func _progress() -> int:
	return int(clampf(game.cat.position.x / game.finish_x * 100, 0, 100))

func _input(event: InputEvent) -> void:
	if game.state == "won" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if RESULTS_BUTTON.has_point(event.position):
			game.continue_game()

func _draw() -> void:
	if game == null:
		return
	match game.state:
		"playing":
			_draw_game_hud()
			if game.message_timer > 0:
				_draw_message(game.message)
		"paused":
			_draw_game_hud()
			_draw_pause()
		"won":
			_draw_results()

func _draw_game_hud() -> void:
	_draw_panel(Rect2(18, 16, 145, 64))
	Art.medal(self, Vector2(39, 37), 0.54)
	_draw_text("%02d / %02d" % [game.score, game.total_medals], Vector2(58, 43), 17, TEXT, heading)

	_draw_text("RESCUES   %d" % game.rescue_count, Vector2(31, 67), 13, MUTED)

	_draw_panel(Rect2(331, 16, 298, 44))
	_draw_center("%02d   /   %s" % [game.level_number, game.district_name().to_upper()], 40, 14, TEXT, heading)
	draw_rect(Rect2(346, 49, 268, 2), PANEL_BORDER)
	draw_rect(Rect2(346, 49, 268 * _progress() / 100.0, 2), ACCENT)

	_draw_panel(Rect2(771, 16, 171, 32))
	_draw_text("PAUSE   Esc / Start", Vector2(786, 37), 13, MUTED)

func _draw_message(message: String) -> void:
	var width := ceilf(font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x) + 36
	_draw_panel(Rect2(480 - width / 2.0, 77, width, 34))
	_draw_center(message, 99, 15, TEXT)

func _draw_pause() -> void:
	draw_rect(SCREEN, Color(0.04, 0.07, 0.10, 0.60))
	_draw_panel(Rect2(250, 168, 460, 204))
	draw_rect(Rect2(458, 194, 44, 3), ACCENT)
	_draw_center("PAUSED", 254, 44, TEXT, heading)
	_draw_center("Esc or Start / Options to resume", 299, 16, MUTED)
	_draw_center("Jump: Space or A / Cross  ·  Climb: Up / down", 335, 14, MUTED)

func _draw_results() -> void:
	draw_rect(SCREEN, Color(0.04, 0.07, 0.10, 0.62))
	_draw_panel(Rect2(218, 103, 524, 344))
	draw_rect(Rect2(459, 130, 42, 3), ACCENT)
	var more: bool = game.has_next_level()
	var title := "LEVEL %02d COMPLETE" % game.level_number if more else "CAMPAIGN COMPLETE"
	_draw_center(title, 182, 35, TEXT, heading)
	_draw_center(game.level_name(), 216, 18, MUTED)
	draw_line(Vector2(257, 239), Vector2(703, 239), PANEL_BORDER)
	_draw_center("FISH MEDALS   /   RUN RESCUES %d" % game.rescue_count, 269, 13, MUTED)
	_draw_center("%02d / %02d" % [game.score, game.total_medals], 319, 37, ACCENT, heading)
	_draw_button(RESULTS_BUTTON, "NEXT LEVEL" if more else "PLAY AGAIN")
	_draw_center("Enter or A / Cross", 428, 13, MUTED)

func _draw_button(rect: Rect2, label: String) -> void:
	var fill := ACCENT.lightened(0.18) if rect.has_point(get_viewport().get_mouse_position()) else ACCENT
	Art.panel(self, rect, fill, 4)
	draw_string(heading, rect.position + Vector2(0, 33), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 19, BUTTON_TEXT)

func _draw_panel(rect: Rect2) -> void:
	Art.panel(self, rect, PANEL, 5, PANEL_BORDER, 1)

func _draw_center(text: String, baseline: float, size: int, color: Color, face: Font = null) -> void:
	draw_string(face if face else font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, 960, size, color)

func _draw_text(text: String, at: Vector2, size: int, color: Color, face: Font = null) -> void:
	draw_string(face if face else font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
