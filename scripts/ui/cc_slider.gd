extends Control
class_name CCSlider
## Posuvník: dřevěná drážka s barevnou výplní a zlatým jezdcem. Táhne se prstem.

signal value_changed(v: float)
signal drag_ended(v: float)

var value := 0.5
var color := Art.BTN_GREEN
var step := 0.05
var dragging := false

const KNOB_R := 19.0


static func make(v: float, col: Color, w: float) -> CCSlider:
	var s := CCSlider.new()
	s.value = v
	s.color = col
	s.custom_minimum_size = Vector2(w, 48)
	s.size = Vector2(w, 48)
	return s


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _track() -> Rect2:
	return Rect2(KNOB_R, size.y * 0.5 - 9, size.x - KNOB_R * 2.0, 18)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			_set_from(event.position.x)
		elif dragging:
			_set_from(event.position.x)
			dragging = false
			drag_ended.emit(value)
			queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		_set_from(event.position.x)
		accept_event()


func _set_from(x: float) -> void:
	var t := _track()
	var v := clampf((x - t.position.x) / t.size.x, 0.0, 1.0)
	v = snappedf(v, step)
	if not is_equal_approx(v, value):
		value = v
		value_changed.emit(value)
	queue_redraw()


func _draw() -> void:
	var t := _track()
	# drážka
	var groove := Art.rrect(t.grow(3), 12)
	Art.outline(self, groove, 3.0)
	Art.grad(self, groove, Art.WOOD_DARK.darkened(0.3), Art.WOOD_DARK)
	Art.safe_poly(self, Art.rrect(Rect2(t.position + Vector2(2, 1), Vector2(t.size.x - 4, 6)), 3), Color(0, 0, 0, 0.3))
	# výplň
	var fw := t.size.x * value
	if fw > 2.0:
		var fr := Rect2(t.position, Vector2(maxf(fw, t.size.y), t.size.y))
		var fp := Art.rrect(fr, 9)
		Art.grad(self, fp, color.lightened(0.3), color.darkened(0.15))
		Art.safe_poly(self, Art.rrect(Rect2(fr.position + Vector2(4, 2), Vector2(maxf(2.0, fr.size.x - 8), 5)), 2), Color(1, 1, 1, 0.35))
	# jezdec
	var c := Vector2(t.position.x + fw, size.y * 0.5)
	var r := KNOB_R * (1.12 if dragging else 1.0)
	draw_circle(c + Vector2(0, 4), r + 2, Color(0, 0, 0, 0.3))
	Art.circle(self, c, r, Art.GOLD, 3.5)
	draw_circle(c + Vector2(0, r * 0.25), r * 0.7, Art.GOLD_DARK)
	draw_circle(c, r * 0.62, Art.GOLD)
	draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.28, Color(1, 1, 1, 0.75))
