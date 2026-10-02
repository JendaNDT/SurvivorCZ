extends Node2D
class_name Fx
## Efekty nad scénou: čísla zásahů, blesky, výbuchy, částice.

var nums: Array = []
var bolts: Array = []
var booms: Array = []
var parts: Array = []

## Úsporná grafika: méně částic a čísel zásahů.
var low := false
var max_nums := 60
var max_parts := 260


func set_low(on: bool) -> void:
	low = on
	max_nums = 20 if on else 60
	max_parts = 90 if on else 260


func number(pos: Vector2, value: float, crit: bool = false, col: Color = Color.WHITE) -> void:
	if nums.size() >= max_nums:
		nums.pop_front()
	var txt := str(int(round(value))) if value >= 1.0 else str(snappedf(value, 0.1))
	nums.append({"pos": pos + Vector2(randf_range(-10, 10), -20), "txt": txt, "t": 0.0, "crit": crit, "col": col, "vx": randf_range(-25, 25)})


func text(pos: Vector2, s: String, col: Color, size: int = 24) -> void:
	nums.append({"pos": pos, "txt": s, "t": 0.0, "crit": true, "col": col, "vx": 0.0, "size": size})


func lightning(pts: Array, big: bool = false) -> void:
	var jag := []
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var c: Vector2 = pts[i + 1]
		var segs := 7
		for k in segs:
			var p := a.lerp(c, float(k) / segs)
			if k > 0:
				p += (c - a).orthogonal().normalized() * randf_range(-14, 14)
			jag.append(p)
	jag.append(pts[pts.size() - 1])
	bolts.append({"pts": PackedVector2Array(jag), "t": 0.0, "big": big})
	for i in range(1, pts.size()):
		burst(pts[i], Color("fff6a0"), 4, 120.0)


func explosion(pos: Vector2, r: float, col: Color = Color("ffb030")) -> void:
	booms.append({"pos": pos, "r": r, "t": 0.0, "col": col})
	burst(pos, col, 10, r * 3.0)


func burst(pos: Vector2, col: Color, n: int = 6, speed: float = 160.0, size: float = 5.0) -> void:
	if low:
		n = ceili(n * 0.5)
	for i in n:
		if parts.size() >= max_parts:
			parts.pop_front()
		var a := randf() * TAU
		parts.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * randf_range(speed * 0.3, speed), "t": 0.0, "life": randf_range(0.3, 0.6), "col": col, "size": randf_range(size * 0.6, size * 1.3)})


## Konfety ze smrti bosse: barevné papírky vyletí vzhůru a padají.
func confetti(pos: Vector2, n: int) -> void:
	if low:
		n = ceili(n * 0.4)
	var cols := [Color("ff4d6d"), Color("ffd23f"), Color("3fa8ff"), Color("6fcf2f"), Color("b25cff"), Color("ff8a2a")]
	for i in n:
		if parts.size() >= max_parts:
			parts.pop_front()
		var a := randf_range(-PI * 0.95, -PI * 0.05)
		parts.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * randf_range(250.0, 620.0), "t": 0.0, "life": randf_range(1.3, 2.0),
			"col": cols[randi() % cols.size()], "size": randf_range(5.0, 8.0), "conf": true, "rot": randf() * TAU, "spin": randf_range(-12.0, 12.0)})


func poof(pos: Vector2, col: Color = Color(1, 1, 1, 0.9)) -> void:
	var n := 3 if low else 7
	for i in n:
		if parts.size() >= max_parts:
			parts.pop_front()
		var a := TAU * i / float(n) + randf() * 0.5
		parts.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * randf_range(60, 130), "t": 0.0, "life": 0.45, "col": col, "size": randf_range(7, 11), "puff": true})


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	var i := nums.size() - 1
	while i >= 0:
		var n: Dictionary = nums[i]
		n.t += delta
		n.pos += Vector2(n.vx, -60.0 + n.t * 60.0) * delta
		if n.t > 0.8:
			nums.remove_at(i)
		i -= 1
	i = bolts.size() - 1
	while i >= 0:
		bolts[i].t += delta
		if bolts[i].t > 0.22:
			bolts.remove_at(i)
		i -= 1
	i = booms.size() - 1
	while i >= 0:
		booms[i].t += delta
		if booms[i].t > 0.4:
			booms.remove_at(i)
		i -= 1
	i = parts.size() - 1
	while i >= 0:
		var p: Dictionary = parts[i]
		p.t += delta
		p.pos += p.vel * delta
		if p.get("conf", false):
			var v: Vector2 = p.vel
			p.vel = Vector2(v.x * 0.97, minf(v.y * 0.97 + 700.0 * delta, 130.0))
			p.rot += p.spin * delta
		else:
			p.vel *= 0.9
		if p.t > p.life:
			parts.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	for bm in booms:
		var k: float = bm.t / 0.4
		var rr: float = bm.r * (0.4 + 0.8 * ease_out(k))
		draw_circle(bm.pos, rr, Color(bm.col, 0.45 * (1.0 - k)))
		draw_circle(bm.pos, rr * 0.6, Color(1, 1, 0.85, 0.6 * (1.0 - k)))
		draw_arc(bm.pos, rr, 0, TAU, 32, Color(1, 1, 1, 0.8 * (1.0 - k)), 4.0 * (1.0 - k) + 1.0, true)
	for p in parts:
		var k: float = p.t / p.life
		if p.get("puff", false):
			draw_circle(p.pos, p.size * (1.0 + k), Color(p.col, (1.0 - k) * p.col.a))
		elif p.get("conf", false):
			var pts := Art.xform(PackedVector2Array([Vector2(-1, -0.6), Vector2(1, -0.6), Vector2(1, 0.6), Vector2(-1, 0.6)]), p.pos, Vector2(p.size, p.size * absf(cos(p.rot * 1.7)) + 1.0), p.rot)
			draw_colored_polygon(pts, Color(p.col, minf(1.0, (1.0 - k) * 3.0)))
		else:
			draw_circle(p.pos, p.size * (1.0 - k * 0.6), Color(p.col, 1.0 - k))
	for bl in bolts:
		var a: float = 1.0 - bl.t / 0.22
		var w := 9.0 if bl.big else 6.0
		draw_polyline(bl.pts, Color(0.3, 0.5, 1.0, 0.5 * a), w * 2.2, true)
		draw_polyline(bl.pts, Color(0.75, 0.85, 1.0, a), w, true)
		draw_polyline(bl.pts, Color(1, 1, 1, a), w * 0.4, true)
	for n in nums:
		var k: float = n.t / 0.8
		var sz: int = n.get("size", 26 if n.crit else 19)
		var sc: float = 1.0 + (0.5 if n.crit else 0.25) * maxf(0.0, 1.0 - n.t * 8.0)
		var col: Color = n.col
		col.a = 1.0 - maxf(0.0, (k - 0.6) / 0.4)
		var fs := int(sz * sc)
		var p: Vector2 = n.pos
		draw_string_outline(Art.font, p + Vector2(-60, 0), n.txt, HORIZONTAL_ALIGNMENT_CENTER, 120, fs, 6, Color(Art.OUTLINE, col.a))
		draw_string(Art.font, p + Vector2(-60, 0), n.txt, HORIZONTAL_ALIGNMENT_CENTER, 120, fs, col)


func ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3.0)
