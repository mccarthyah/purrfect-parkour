extends Control

const Art = preload("res://scripts/art.gd")
const TITLE_WORDMARK = preload("res://assets/title_wordmark.svg")
const INK := Color("111a25")
const PANEL := Color("223040")
const LINE := Color("46586b")
const TEXT := Color("f5f3e9")
const MUTED := Color("c0ccd3")
const GOLD := Color("edb963")
const TEAL := Color("97c8c5")

var game
var page := "home"
var config_path := "user://settings.cfg"
var fullscreen := false
var settings_error := false
var regular: Font
var bold: FontVariation
var pages: Dictionary = {}
var play_button: Button
var settings_button: Button
var about_button: Button
var display_button: Button
var fps_button: Button
var page_origin: Button
var stick_direction := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	regular = ThemeDB.fallback_font
	bold = FontVariation.new()
	bold.base_font = regular
	bold.variation_embolden = 0.8
	load_settings()

	var home := _page("home")
	play_button = _button(home, Rect2(78, 284, 328, 60), "PLAY", "play", _play, true)
	settings_button = _button(home, Rect2(78, 355, 328, 49), "SETTINGS", "settings", _open_settings)
	about_button = _button(home, Rect2(78, 415, 328, 49), "ABOUT", "about", _open_about)
	_link_focus([play_button, settings_button, about_button])

	var settings := _page("settings")
	display_button = _button(settings, Rect2(78, 252, 385, 50), "", "display", _toggle_display)
	fps_button = _button(settings, Rect2(78, 314, 385, 50), "", "fps", _toggle_fps)
	var settings_back := _button(settings, Rect2(78, 415, 214, 49), "BACK", "back", _back)
	_link_focus([display_button, fps_button, settings_back])
	_refresh_settings()

	var about := _page("about")
	_button(about, Rect2(78, 415, 214, 49), "BACK", "back", _back)
	_show("home", play_button)

func _page(key: String) -> Control:
	var parent := Control.new()
	parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(parent)
	pages[key] = parent
	return parent

func _button(parent: Control, rect: Rect2, label: String, icon: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = label
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", bold)
	button.add_theme_font_size_override("font_size", 19 if primary else 16)
	button.add_theme_stylebox_override("normal", _button_style(GOLD if primary else PANEL, LINE))
	button.add_theme_stylebox_override("hover", _button_style(GOLD.lightened(0.15) if primary else Color("34485b"), TEAL))
	button.add_theme_stylebox_override("pressed", _button_style(GOLD.darkened(0.07) if primary else Color("2a3b4b"), TEAL))
	button.add_theme_stylebox_override("focus", _button_style(Color.TRANSPARENT, TEXT, 2))
	for key in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(key, INK if primary else TEXT)
	button.pressed.connect(action)
	button.draw.connect(_draw_button_icon.bind(button, icon, INK if primary else GOLD))
	parent.add_child(button)
	return button

func _button_style(fill: Color, outline: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	# Room for the hand-drawn icon and the end chevron.
	style.content_margin_left = 55
	style.content_margin_right = 38
	return style

func _link_focus(buttons: Array) -> void:
	for index in range(buttons.size()):
		var button: Button = buttons[index]
		button.focus_neighbor_top = button.get_path_to(buttons[posmod(index - 1, buttons.size())])
		button.focus_neighbor_bottom = button.get_path_to(buttons[(index + 1) % buttons.size()])

func _show(key: String, focus: Button) -> void:
	page = key
	for name in pages:
		pages[name].visible = name == page
	focus.grab_focus()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or game.state != "title":
		return
	if event.is_action_pressed("menu_confirm"):
		var focused := get_viewport().gui_get_focus_owner() as Button
		if focused != null and is_ancestor_of(focused):
			get_viewport().set_input_as_handled()
			focused.pressed.emit()
	elif page != "home" and event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		_back()
	else:
		_navigate(event)

func _navigate(event: InputEvent) -> void:
	var direction := 0
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		var next := int(signf(event.axis_value)) if absf(event.axis_value) >= 0.55 else 0
		if next == stick_direction:
			return
		stick_direction = next
		direction = next
	elif event.is_action_pressed("climb_up"):
		direction = -1
	elif event.is_action_pressed("climb_down"):
		direction = 1
	if direction == 0:
		return
	get_viewport().set_input_as_handled()
	var focused := get_viewport().gui_get_focus_owner() as Button
	if focused == null or not is_ancestor_of(focused):
		return
	var path := focused.focus_neighbor_top if direction < 0 else focused.focus_neighbor_bottom
	if not path.is_empty():
		var target := focused.get_node_or_null(path) as Control
		if target != null:
			target.grab_focus()

func _play() -> void:
	game.cat.wait_for_jump_release = Input.is_action_pressed("jump")
	game.start_game()

func _open_settings() -> void:
	page_origin = settings_button
	_show("settings", display_button)

func _open_about() -> void:
	page_origin = about_button
	_show("about", pages.about.get_child(0) as Button)

func _back() -> void:
	_show("home", page_origin)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		return
	fullscreen = bool(config.get_value("display", "fullscreen", false))
	var fps := int(config.get_value("display", "fps", 30))
	game.set_gameplay_fps(20 if fps == 20 else 30)
	_apply_display()

func _apply_display() -> void:
	if DisplayServer.get_name() != "headless":
		var mode := Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
		if get_window().mode != mode:
			get_window().mode = mode

func _toggle_display() -> void:
	fullscreen = not fullscreen
	_apply_display()
	_save_settings()
	_refresh_settings()

func _toggle_fps() -> void:
	game.set_gameplay_fps(20 if game.gameplay_fps == 30 else 30)
	_save_settings()
	_refresh_settings()

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "fps", game.gameplay_fps)
	settings_error = config.save(config_path) != OK

func _refresh_settings() -> void:
	display_button.text = "DISPLAY   /   " + ("FULLSCREEN" if fullscreen else "WINDOWED")
	fps_button.text = "FRAME LIMIT   /   %d FPS" % game.gameplay_fps
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 470, 540), INK)
	draw_polygon(PackedVector2Array([Vector2(470,0), Vector2(960,0), Vector2(960,540), Vector2(470,540)]),
		PackedColorArray([INK, Color(INK, 0.25), Color(INK, 0.25), INK]))
	draw_line(Vector2(78, 480), Vector2(882, 480), Color(TEAL, 0.42))
	_draw_emblem(Vector2(713, 253))
	match page:
		"home":
			draw_texture(TITLE_WORDMARK, Vector2(68, 78))
			_text("10 levels of rooftop parkour", Vector2(78, 246), 17, MUTED)
			_text("Navigate with ↑ / ↓, stick or D-pad   ·   Select with Enter or A / Cross", Vector2(78, 510), 14, TEXT)
		"settings":
			_page_heading("SETTINGS", "Display and performance")
			_text("20 FPS reduces rendering load. Physics stays at 60 Hz.", Vector2(78, 391), 15, MUTED)
			_text("Settings could not be saved." if settings_error else "Changes apply immediately.",
				Vector2(78, 510), 14, TEXT)
		"about":
			_page_heading("ABOUT", "Tabby Roof Run")
			_text("Cross 10 rooftop courses by running and double-jumping.", Vector2(78, 253), 16, TEXT)
			_text("Cross power lines and clotheslines, or jump the gaps.", Vector2(78, 282), 16, TEXT)
			_text("A helicopter returns you to the checkpoint after a fall.", Vector2(78, 311), 16, TEXT)
			_text("Rescues are unlimited.", Vector2(78, 340), 16, TEXT)
			_text("Move  A / D, arrows, stick or D-pad", Vector2(78, 372), 14, MUTED)
			_text("Jump  Space or A / Cross   ·   Climb  Up / down by a balcony tree", Vector2(78, 395), 14, MUTED)

func _page_heading(title: String, subtitle: String) -> void:
	draw_rect(Rect2(78, 94, 42, 3), GOLD)
	_text(title, Vector2(74, 163), 58, TEXT, bold)
	_text(subtitle, Vector2(78, 202), 20, TEAL)

func _draw_emblem(center: Vector2) -> void:
	draw_set_transform(center)
	var frame := PackedVector2Array([Vector2(-135,-82), Vector2(0,-147), Vector2(135,-82),
		Vector2(135,74), Vector2(0,145), Vector2(-135,74)])
	draw_colored_polygon(frame, Color("1a2635"))
	frame.append(frame[0])
	draw_polyline(frame, Color("d2a765"), 4, true)
	draw_arc(Vector2(0,-22), 81, PI, TAU, 40, Color("558183"), 2, true)
	Art.sparkle(self, Vector2(76,-71), 11, GOLD)
	Art.sparkle(self, Vector2(-79,-46), 6, TEAL)
	# A tabby silhouette over stepped rooflines forms the game mark.
	draw_colored_polygon(PackedVector2Array([Vector2(-67,20), Vector2(-58,-69), Vector2(-22,-42),
		Vector2(27,-42), Vector2(62,-69), Vector2(70,20), Vector2(44,50), Vector2(0,65), Vector2(-43,50)]), GOLD)
	draw_colored_polygon(PackedVector2Array([Vector2(-49,-49), Vector2(-30,-35), Vector2(-52,-30)]), Color("aa663d"))
	draw_colored_polygon(PackedVector2Array([Vector2(53,-49), Vector2(34,-35), Vector2(56,-30)]), Color("aa663d"))
	draw_line(Vector2(-42,0), Vector2(-16,7), INK, 5, true)
	draw_line(Vector2(20,7), Vector2(45,0), INK, 5, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-8,22), Vector2(10,22), Vector2(1,31)]), INK)
	draw_polyline(PackedVector2Array([Vector2(-103,59), Vector2(-73,59), Vector2(-73,80),
		Vector2(-37,80), Vector2(-37,99), Vector2(0,116), Vector2(39,97), Vector2(39,75),
		Vector2(72,75), Vector2(72,52), Vector2(104,52)]), TEAL, 3, true)
	draw_set_transform(Vector2.ZERO)

func _draw_button_icon(button: Button, icon: String, ink: Color) -> void:
	var at := Vector2(29, button.size.y * 0.5)
	button.draw_set_transform(at)
	match icon:
		"play":
			button.draw_colored_polygon(PackedVector2Array([Vector2(-6,-9), Vector2(9,0), Vector2(-6,9)]), ink)
		"settings":
			for y in [-6, 0, 6]:
				button.draw_line(Vector2(-9,y), Vector2(9,y), ink, 1.7, true)
				button.draw_circle(Vector2(y * 0.6,y), 2.5, ink, true, -1.0, true)
		"about":
			button.draw_arc(Vector2.ZERO, 9, 0, TAU, 24, ink, 1.7, true)
			button.draw_circle(Vector2(0,-4), 1.3, ink, true, -1.0, true)
			button.draw_line(Vector2(0,-1), Vector2(0,5), ink, 1.7, true)
		"display":
			button.draw_rect(Rect2(-9,-7,18,12), ink, false, 1.7)
			button.draw_line(Vector2(-4,9), Vector2(4,9), ink, 1.7, true)
		"fps":
			button.draw_arc(Vector2(0,4), 9, PI, TAU, 20, ink, 1.7, true)
			button.draw_line(Vector2(0,4), Vector2(5,-2), ink, 1.7, true)
		"back":
			button.draw_polyline(PackedVector2Array([Vector2(4,-7), Vector2(-5,0), Vector2(4,7)]), ink, 1.8, true)
	button.draw_set_transform(Vector2(button.size.x - 22, button.size.y * 0.5))
	button.draw_polyline(PackedVector2Array([Vector2(-3,-5), Vector2(3,0), Vector2(-3,5)]), ink, 1.5, true)
	button.draw_set_transform(Vector2.ZERO)

func _text(label: String, at: Vector2, size: int, ink: Color, face: Font = null) -> void:
	draw_string(face if face else regular, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
