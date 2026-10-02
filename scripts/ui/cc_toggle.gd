extends Control
class_name CCToggle
## Přepínač: popisek a kreslený vypínač (zelený ZAP, šedý VYP). Ťukne se kamkoli.

signal toggled_to(on: bool)

var caption := ""
var on := false
var knob := 0.0


static func make(text_: String, value: bool, sz: Vector2) -> CCToggle:
	var t := CCToggle.new()
	t.caption = text_
	t.on = value
	t.knob = 1.0 if value else 0.0
	t.custom_minimum_size = sz
	t.size = sz
	return t


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		on = not on
		Sfx.play("click", -6.0, 0.05, 0.0)
		var tw := create_tween()
		tw.tween_property(self, "knob", 1.0 if on else 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_method(func(_v: float): queue_redraw(), 0.0, 1.0, 0.16)
		toggled_to.emit(on)
		accept_event()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Art.safe_poly(self, Art.rrect(r, 14), Color(Art.WOOD_DARK, 0.12))
	draw_string(Art.font, Vector2(16, size.y * 0.5 + 8), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 120, 21, Color("4a2c12"))
	# vypínač
	var sw := Rect2(size.x - 100, size.y * 0.5 - 19, 88, 38)
	var col := Art.BTN_GREEN.lerp(Color("9aa0a6"), 1.0 - knob)
	var pill := Art.rrect(sw, 19)
	Art.outline(self, pill, 3.0)
	Art.grad(self, pill, col.darkened(0.25), col.lightened(0.1))
	var label := "ZAP" if on else "VYP"
	var lx := sw.position.x + (24.0 if on else 62.0)
	Art.text(self, Vector2(lx, sw.position.y + 26), label, 15, Color.WHITE, 4)
	var kc := Vector2(lerpf(sw.position.x + 19, sw.end.x - 19, knob), sw.get_center().y)
	draw_circle(kc + Vector2(0, 3), 16, Color(0, 0, 0, 0.3))
	Art.circle(self, kc, 15, Color("f4f6f8"), 3.0)
	draw_circle(kc + Vector2(-4, -5), 5, Color(1, 1, 1, 0.9))
