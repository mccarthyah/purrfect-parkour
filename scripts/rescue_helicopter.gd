extends Node2D

const Art = preload("res://scripts/art.gd")
const APPROACH := 0.30
const LIFT := 0.55
const LOWER := 0.45
const DEPART := 0.25
const CABLE_DROP := Vector2(0, 83)
const BODY := Color("dd9352")
const GLASS := Color("a6ced4")

var pickup: Vector2
var drop_off: Vector2
var carry_height: float
var travel: float
var elapsed := 0.0
var carrying := false
var passenger_position: Vector2
var finished := false

func setup(from: Vector2, to: Vector2, clearance: float) -> void:
	pickup = from
	drop_off = to
	carry_height = minf(clearance, to.y - 135)
	travel = clampf(absf(from.x - to.x) / 1550.0, 0.25, 1.30)
	advance(0.0)

func advance(delta: float) -> void:
	elapsed += delta
	var step := elapsed
	var over_pickup := Vector2(pickup.x, carry_height)
	var over_drop := Vector2(drop_off.x, carry_height)
	carrying = step >= APPROACH and step < APPROACH + LIFT + travel + LOWER
	if step < APPROACH:
		passenger_position = pickup
		position = (pickup + Vector2(115, -155)).lerp(pickup - CABLE_DROP, _blend(step, APPROACH))
	else:
		step -= APPROACH
		if step < LIFT:
			passenger_position = pickup.lerp(over_pickup, _blend(step, LIFT))
		elif step < LIFT + travel:
			passenger_position = over_pickup.lerp(over_drop, _blend(step - LIFT, travel))
		elif carrying:
			passenger_position = over_drop.lerp(drop_off, _blend(step - LIFT - travel, LOWER))
		else:
			passenger_position = drop_off
		position = passenger_position - CABLE_DROP
		if not carrying:
			var departure := step - LIFT - travel - LOWER
			position += Vector2(116, -92) * _blend(departure, DEPART)
			modulate.a = 1.0 - _blend(departure, DEPART)
			finished = departure >= DEPART
	queue_redraw()

func _blend(time: float, duration: float) -> float:
	return smoothstep(0.0, 1.0, clampf(time / duration, 0.0, 1.0))

func _draw() -> void:
	if carrying:
		draw_line(Vector2(0, 10), Vector2(0, 48), Art.INK, 2.8, true)
		draw_line(Vector2(0, 11), Vector2(0, 48), Art.CREAM, 1.1, true)
		draw_arc(Vector2(0,48), 4, 0, PI, 10, Art.GOLD, 2.0, true)

	draw_line(Vector2(-15, -2), Vector2(-47, -9), Art.INK, 9, true)
	draw_line(Vector2(-15, -2), Vector2(-47, -9), BODY, 5, true)
	draw_line(Vector2(-47, -15), Vector2(-47, -4), Art.INK, 4, true)
	Art.panel(self, Rect2(-26,-16,55,31), BODY, 12, Art.INK, 2)
	Art.panel(self, Rect2(5,-13,20,15), GLASS, 6, Art.INK, 1)
	draw_line(Vector2(-18,5), Vector2(22,5), Art.CREAM, 2, true)
	for x in [-15, 15]:
		draw_line(Vector2(x, 14), Vector2(x, 22), Art.INK, 3, true)
	draw_line(Vector2(-22,22), Vector2(27,22), Art.INK, 3, true)

	draw_line(Vector2(0,-15), Vector2(0,-24), Art.INK, 3, true)
	var blade := 16.0 + 27.0 * absf(sin(elapsed * 65.0))
	draw_line(Vector2(-43,-25), Vector2(43,-25), Color(GLASS, 0.33), 6, true)
	draw_line(Vector2(-blade,-25), Vector2(blade,-25), Art.INK, 2.5, true)
	draw_circle(Vector2(0,-25), 3, Art.CREAM, true, -1.0, true)
