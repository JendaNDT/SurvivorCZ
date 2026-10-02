extends Node2D
class_name GroundFx
## Varování na zemi (červené kruhy, čáry), rázové vlny bossů, hranice arény
## a prach pod nohama hrdiny (kreslí se pod postavami).

var warns: Array = []
var dust: Array = []
var lines: Array = []
var waves: Array = []
var arena_center := Vector2.ZERO
var arena_r := 0.0
var t := 0.0


## Kruh, který se vyplní; po skončení zavolá on_done(pos, r).
func circle_warn(pos: Vector2, r: float, dur: float, col: Color = Color(1, 0.15, 0.1), on_done: Callable = Callable()) -> void:
	warns.append({"pos": pos, "r": r, "t": 0.0, "dur": dur, "col": col, "cb": on_done})


func line_warn(pos: Vector2, dir: Vector2, length: float, width: float, dur: float) -> void:
	lines.append({"pos": pos, "dir": dir, "len": length, "w": width, "t": 0.0, "dur": dur})


## Obláček prachu (nebo jiskry na plechu). Barvu volí Battle podle země kraje.
func puff(pos: Vector2, col: Color, spark: bool = false) -> void:
	if dust.size() >= 24:
		dust.pop_front()
	if spark:
		var a := randf_range(-PI * 0.85, -PI * 0.15)
		dust.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * randf_range(110.0, 200.0), "t": 0.0, "life": 0.35, "col": col, "size": 3.0, "spark": true})
	else:
		dust.append({"pos": pos + Vector2(randf_range(-6, 6), 0), "vel": Vector2(randf_range(-18, 18), -16.0), "t": 0.0, "life": 0.6, "col": col, "size": randf_range(9.0, 13.0), "spark": false})


func shockwave(center: Vector2, speed: float, max_r: float, width: float, col: Color) -> Dictionary:
	var w := {"c": center, "r": 10.0, "speed": speed, "max": max_r, "w": width, "col": col, "hit": false}
	waves.append(w)
	return w


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	t += delta
	var i := warns.size() - 1
	while i >= 0:
		var w: Dictionary = warns[i]
		w.t += delta
		if w.t >= w.dur:
			warns.remove_at(i)
			if w.cb.is_valid():
				w.cb.call(w.pos, w.r)
		i -= 1
	i = lines.size() - 1
	while i >= 0:
		lines[i].t += delta
		if lines[i].t >= lines[i].dur:
			lines.remove_at(i)
		i -= 1
	i = waves.size() - 1
	while i >= 0:
		var wv: Dictionary = waves[i]
		wv.r += wv.speed * delta
		if wv.r > wv.max:
			waves.remove_at(i)
		i -= 1
	i = dust.size() - 1
	while i >= 0:
		var p: Dictionary = dust[i]
		p.t += delta
		p.pos += p.vel * delta
		if p.spark:
			p.vel += Vector2(0, 600.0 * delta)
		if p.t >= p.life:
			dust.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	for p in dust:
		var k: float = p.t / p.life
		var col: Color = p.col
		if p.spark:
			draw_line(p.pos, p.pos - (p.vel as Vector2).normalized() * 7.0, Color(col, 1.0 - k), p.size, true)
		else:
			draw_circle(p.pos, p.size * (1.0 + k * 0.9), Color(col, col.a * (1.0 - k)))
	if arena_r > 0.0:
		draw_arc(arena_center, arena_r + 6.0, 0, TAU, 96, Color(0, 0, 0, 0.25), 18.0, true)
		draw_arc(arena_center, arena_r - 4.0, 0, TAU, 96, Color(1, 0.85, 0.4, 0.35), 4.0, true)
	for w in warns:
		var k: float = w.t / w.dur
		var col: Color = w.col
		draw_circle(w.pos, w.r, Color(col, 0.16))
		draw_circle(w.pos, w.r * k, Color(col, 0.28))
		draw_arc(w.pos, w.r, 0, TAU, 40, Color(col, 0.85), 3.0, true)
	for l in lines:
		var k: float = l.t / l.dur
		var d: Vector2 = l.dir
		var n: Vector2 = d.orthogonal() * l.w * 0.5
		var a: Vector2 = l.pos
		var b2: Vector2 = l.pos + d * l.len
		var poly := PackedVector2Array([a + n, b2 + n, b2 - n, a - n])
		draw_colored_polygon(poly, Color(1, 0.15, 0.1, 0.16))
		var b3: Vector2 = a + d * l.len * k
		draw_colored_polygon(PackedVector2Array([a + n, b3 + n, b3 - n, a - n]), Color(1, 0.15, 0.1, 0.25))
		draw_polyline(PackedVector2Array([a + n, b2 + n, b2 - n, a - n, a + n]), Color(1, 0.2, 0.1, 0.8), 2.5, true)
	for wv in waves:
		var a2: float = 1.0 - wv.r / wv.max
		draw_arc(wv.c, wv.r, 0, TAU, 72, Color(wv.col, 0.55 * a2 + 0.2), wv.w, true)
		draw_arc(wv.c, wv.r, 0, TAU, 72, Color(1, 1, 1, 0.6 * a2), wv.w * 0.3, true)
