extends CanvasLayer
class_name CloudTransition
## Přechod mezi obrazovkami: obrazovku zakryjí nadýchané mraky a pak se rozestoupí.

var k := 0.0
var clouds: Array = []
var canvas: Control


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_paint)
	add_child(canvas)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 22:
		var side := -1.0 if i % 2 == 0 else 1.0
		clouds.append({"x": rng.randf_range(-0.1, 1.1), "y": rng.randf_range(-0.1, 1.1), "r": rng.randf_range(150, 260), "side": side, "d": rng.randf_range(0.0, 0.25)})


func cover() -> void:
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_method(_set_k, 0.0, 1.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tw.finished


func reveal() -> void:
	var tw := create_tween()
	tw.tween_interval(0.12)
	tw.tween_method(_set_k, 1.0, 0.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tw.finished
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_k(v: float) -> void:
	k = v
	canvas.queue_redraw()


func _paint() -> void:
	if k <= 0.001:
		return
	var vs := canvas.size
	canvas.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.85, 0.93, 1.0, clampf((k - 0.6) / 0.4, 0.0, 1.0)))
	for c in clouds:
		var kk := clampf((k - c.d) / (1.0 - c.d), 0.0, 1.0)
		if kk <= 0.0:
			continue
		var target := Vector2(c.x * vs.x, c.y * vs.y)
		var start := target + Vector2(c.side * (vs.x * 0.9 + c.r), 0)
		var p := start.lerp(target, kk)
		var r: float = c.r
		canvas.draw_circle(p + Vector2(0, r * 0.12), r, Color(0.62, 0.72, 0.85))
		canvas.draw_circle(p, r, Color(0.97, 0.99, 1.0))
		canvas.draw_circle(p + Vector2(-r * 0.3, -r * 0.35), r * 0.45, Color(1, 1, 1))
