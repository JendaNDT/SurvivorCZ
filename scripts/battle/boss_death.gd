extends Node2D
class_name BossDeath
## Smrt bosse. Společná sekvence (otřes, bílé záblesky, boss se nakloní a propadne,
## výbuch mincí a konfet) a k tomu krátká tečka podle bosse (BOSSES[id].death):
## poslední gejzír, pěna po zemi, odkutálené kolo, klobouk v mlze a další.
## Je to uzel v bitvě: když se bitva uvolní, nic dalšího se už nespustí.

## Kdy (v herním čase po zpomalení) se přitáhnou mince a kdy přijde výhra.
const MAGNET_AT := 1.5
const WIN_AT := 2.3
## Kdy začne tečka a jak dlouho trvá.
const FLOURISH_AT := 0.25
const DUR := 1.9

var b: Battle
var boss: Boss
var kind := ""
var c := Vector2.ZERO
var g := Vector2.ZERO
var face := 1.0
var low := false
var t := 0.0
var ft := -1.0
var burst_done := false
## Částice tečky: {p, v, t, life, col, size, grav, drag, k}
var bits: Array = []
var emit_acc := 0.0
var under: Painter
## Stav jednotlivých teček.
var wheel := {}
var clock_ang := 0.0
var clock_w := 0.0
var bell := false
var landed: Array = []
var items: Array = []


## Kreslí věci na zemi (pěna, láva, louže) pod postavami.
class Painter extends Node2D:
	var fn: Callable

	func _draw() -> void:
		fn.call(self)


static func start(battle: Battle, dead: Boss) -> BossDeath:
	var d := BossDeath.new()
	d.b = battle
	d.boss = dead
	d.kind = str(dead.bdef.get("death", ""))
	d.c = dead.position
	d.g = dead.position + Vector2(0, 82)
	d.face = dead.face
	d.low = battle.low_quality
	battle.world.add_child(d)
	battle.world.move_child(d, battle.entity_layer.get_index() + 1)
	d.under = Painter.new()
	d.under.fn = d._draw_under
	battle.ground_fx_layer.add_child(d.under)
	d._common_start()
	return d


# ---------------------------------------------------------------- společná sekvence

func _common_start() -> void:
	Sfx.play("boom")
	Game.vibrate(150)
	b.shake(22.0)
	if b.hud:
		b.hud.flash_screen()
	for i in 2:
		b.fx.explosion(c + Vector2(randf_range(-50, 50), randf_range(-60, 30)), 90.0, Color("fff2b0"))
	# boss se nakloní a propadne, pak zmizí v bílém světle
	var tw := boss.create_tween().set_parallel(true)
	tw.tween_property(boss.body, "rotation", -0.34 * face, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(boss.body, "position:y", boss.body.position.y + 38.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(boss.body, "scale:y", boss.body.scale.y * 0.86, 1.1)
	tw.tween_property(boss, "modulate", Color(3, 3, 3, 0), 0.8).set_delay(0.5)


func _common_burst() -> void:
	burst_done = true
	Sfx.play("coin", -2.0)
	if b.hud:
		b.hud.flash_screen()
	for i in 5:
		b.fx.explosion(c + Vector2(randf_range(-60, 60), randf_range(-60, 60)), 90.0 + i * 20.0, Color("ffd23f"))
	for i in 20:
		b.pickups.drop("coin", c, 1, 900.0)
	b.fx.confetti(c + Vector2(0, -40), 46)


func _process(delta: float) -> void:
	t += delta
	if is_instance_valid(boss) and t < 0.5:
		boss.body.modulate = Color(2.6, 2.6, 2.6) if int(t * 16.0) % 2 == 0 else Color.WHITE
	if not burst_done and t >= 0.2:
		_common_burst()
	if t >= FLOURISH_AT:
		if ft < 0.0:
			ft = 0.0
			_begin()
		else:
			ft += delta
		_step(delta)
	_update_bits(delta)
	queue_redraw()
	under.queue_redraw()


# ---------------------------------------------------------------- tečky: začátek a průběh

func _begin() -> void:
	match kind:
		"gejzir":
			Sfx.play("gejzir", -2.0)
		"pena":
			Sfx.play("plop", -2.0)
			for i in _n(10):
				var a := randf_range(-PI * 0.95, -PI * 0.05)
				_bit(c + Vector2(0, -60), Vector2(cos(a), sin(a)) * randf_range(160, 320), 1.0, Color("fff4d6"), randf_range(9, 15), 700.0, 1.0, "blob")
		"kolo":
			Sfx.play("valeni", -2.0)
			wheel = {"p": c + Vector2(-60.0 * face, -48.0), "rot": 0.0, "dir": -face}
		"signal":
			Sfx.play("zap", -2.0)
		"klobouk":
			Sfx.play("vitr", -4.0)
			for i in _n(14):
				var off := Vector2.from_angle(randf() * TAU) * randf_range(10, 130)
				_bit(c + off, Vector2(randf_range(-30, 30), randf_range(-35, -10)), randf_range(1.4, 1.9), Color(1, 1, 1, 0.8), randf_range(30, 55), 0.0, 1.0, "puff")
		"pernicky":
			Sfx.play("chest", -4.0)
			var n := _n(12)
			for i in n:
				var a := TAU * i / n + randf_range(-0.15, 0.15)
				_bit(c + Vector2(0, -20), Vector2.from_angle(a) * randf_range(330, 430), 9.0, Color("b0703a"), 13.0, 0.0, 0.93, "heart")
		"prapor":
			Sfx.play("trubka", -4.0)
		"dusicky":
			Sfx.play("levelup", -8.0)
			for i in 5:
				var a := TAU * i / 5.0 + 0.4
				items.append({"p": g + Vector2(cos(a) * 120.0, sin(a) * 52.0), "at": 0.05 * i})
		"houby":
			Sfx.play("spory", -2.0)
			for i in _n(18):
				var a := randf() * TAU
				_bit(c + Vector2(0, -30), Vector2.from_angle(a) * randf_range(150, 260), randf_range(1.1, 1.5), Color(0.86, 0.8, 0.55, 0.75) if i % 2 == 0 else Color(0.66, 0.84, 0.46, 0.75), randf_range(14, 22), 0.0, 0.94, "puff")
			for i in 7:
				var a := TAU * i / 7.0
				items.append({"p": g + Vector2(cos(a) * 130.0, sin(a) * 58.0), "at": 0.2 + 0.07 * i})
		"kour":
			Sfx.play("praskani", -4.0)
		"smrad":
			Sfx.play("plop", -4.0)
		"krabice":
			for i in 6:
				var a := TAU * i / 6.0 + 0.3
				items.append({"p": g + Vector2(cos(a) * randf_range(105, 150), sin(a) * 62.0), "at": 0.1 * i, "rot": randf_range(-0.25, 0.25), "hit": false})
		"lava":
			Sfx.play("praskani", -2.0)


func _step(delta: float) -> void:
	emit_acc += delta * (0.5 if low else 1.0)
	var emit := false
	if emit_acc >= 1.0 / 45.0:
		emit_acc = 0.0
		emit = true
	match kind:
		"gejzir":
			if emit and ft < 0.95:
				var top := g + Vector2(0, -_geyser_h())
				for i in 2:
					_bit(top, Vector2(randf_range(-230, 230), randf_range(-260, -60)), 1.1, Color("a6e6ff") if randf() < 0.6 else Color.WHITE, randf_range(5, 9), 900.0, 1.0, "drop")
		"kolo":
			var p: Vector2 = wheel.p
			if ft < 0.35:
				var k := ft / 0.35
				p.y = lerpf(c.y - 48.0, g.y - 44.0, k * k)
			else:
				p.x += float(wheel.dir) * 400.0 * delta
				wheel.rot = float(wheel.rot) + float(wheel.dir) * 400.0 * delta / 44.0
				if emit:
					_bit(p + Vector2(0, 40), Vector2(-float(wheel.dir) * 60.0, -30), 0.5, b.dust_col, 10.0, 0.0, 0.95, "puff")
			wheel.p = p
		"signal":
			if emit and ft < 0.8:
				var tip := c + Vector2(0, -118)
				_bit(tip, Vector2.from_angle(randf() * TAU) * randf_range(200, 380), 0.6, Color("fff6a0") if randf() < 0.5 else Color("8fe9ff"), 3.5, 300.0, 1.0, "spark")
			for k in 3:
				var at := 0.25 * k
				if ft - delta < at and ft >= at:
					var tip2 := c + Vector2(0, -118)
					b.fx.lightning([tip2, tip2 + Vector2.from_angle(randf_range(-PI, 0)) * 140.0])
		"prapor":
			if ft - delta < 0.25 and ft >= 0.25:
				b.shake(6.0)
				Sfx.play("hit", -2.0)
				b.fx.burst(g + Vector2(46.0 * face, 0), b.dust_col, 8, 160.0, 7.0)
		"orloj":
			if ft < 1.1:
				clock_w = 30.0 * sin(PI * clampf(ft / 1.1, 0.0, 1.0))
				clock_ang += clock_w * delta
			elif not bell:
				bell = true
				clock_ang = 0.0
				Sfx.play("zvonek", 0.0, 0.0, 0.0)
				b.shake(5.0)
		"dusicky":
			if emit and ft < 1.0 and randf() < 0.35:
				var cup: Dictionary = items[randi() % items.size()]
				_bit(cup.p + Vector2(0, -14), Vector2(randf_range(-15, 15), randf_range(-90, -60)), 1.4, Color(0.92, 0.98, 1.0, 0.9), 9.0, 0.0, 1.0, "soul")
		"kour":
			if emit and ft < 1.3:
				var mouth := c + Vector2(82.0 * face, -22.0)
				var dark := Color(0.24, 0.24, 0.26, 0.75) if randf() < 0.5 else Color(0.42, 0.42, 0.44, 0.7)
				_bit(mouth, Vector2(face * randf_range(150, 260), randf_range(-130, -60)), 1.3, dark, randf_range(13, 22), -40.0, 0.97, "puff")
				if randf() < 0.25:
					_bit(mouth, Vector2(face * randf_range(120, 220), randf_range(-60, 20)), 0.4, Color("ff8a2a"), 4.0, 0.0, 0.95, "dot")
		"krabice":
			for it in items:
				var age: float = ft - float(it.at)
				if age >= 0.42 and not it.hit:
					it.hit = true
					Sfx.play("plop", -6.0, 0.1, 0.0)
					b.fx.burst(it.p, b.dust_col, 5, 120.0, 6.0)
		"lava":
			if emit and ft < 1.1:
				var r := _lava_r() * 0.6
				_bit(g + Vector2(randf_range(-r, r), randf_range(-r * 0.4, r * 0.4)), Vector2(randf_range(-120, 120), randf_range(-420, -220)), 0.8, Color("ffd23f") if randf() < 0.5 else Color("ff8a2a"), 3.5, 900.0, 1.0, "spark")


func _n(n: int) -> int:
	return maxi(1, int(n * 0.5)) if low else n


func _bit(p: Vector2, v: Vector2, life: float, col: Color, size: float, grav: float, drag: float, k: String) -> void:
	if bits.size() >= 160:
		return
	bits.append({"p": p, "v": v, "t": 0.0, "life": life, "col": col, "size": size, "grav": grav, "drag": drag, "k": k})


func _update_bits(delta: float) -> void:
	var i := bits.size() - 1
	while i >= 0:
		var p: Dictionary = bits[i]
		p.t = float(p.t) + delta
		var v: Vector2 = p.v
		v = v * pow(float(p.drag), delta * 60.0) + Vector2(0, float(p.grav) * delta)
		p.v = v
		p.p = (p.p as Vector2) + v * delta
		if p.k == "soul":
			p.p = (p.p as Vector2) + Vector2(sin(float(p.t) * 6.0 + i) * 30.0 * delta, 0)
		if float(p.t) >= float(p.life):
			bits.remove_at(i)
		i -= 1


func _geyser_h() -> float:
	return 460.0 * _ease_out(clampf(ft / 0.25, 0.0, 1.0)) * (1.0 - clampf((ft - 0.9) / 0.6, 0.0, 1.0))


func _lava_r() -> float:
	return 30.0 + 160.0 * _ease_out(clampf(ft / 0.8, 0.0, 1.0))


func _ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3.0)


func _fade() -> float:
	return clampf((DUR - ft) / 0.4, 0.0, 1.0)


# ---------------------------------------------------------------- kresby

func _draw_under(ci: Node2D) -> void:
	if ft < 0.0:
		return
	var fa := _fade()
	match kind:
		"gejzir":
			var r := 40.0 + 110.0 * _ease_out(clampf(ft / 0.6, 0.0, 1.0))
			Art.safe_poly(ci, Art.ellipse(g, r, r * 0.42, 32), Color(0.65, 0.9, 1.0, 0.45 * fa))
			Art.safe_poly(ci, Art.ellipse(g, r * 0.6, r * 0.25, 28), Color(1, 1, 1, 0.3 * fa))
		"pena":
			var r := 30.0 + 170.0 * _ease_out(clampf(ft / 0.9, 0.0, 1.0))
			var pts := _wobbly(g, r, 0.48, 3.0)
			Art.outline(ci, pts, 4.0, Color(Art.OUTLINE, 0.8 * fa))
			Art.safe_poly(ci, pts, Color(0.97, 0.91, 0.75, 0.95 * fa))
			Art.safe_poly(ci, _wobbly(g + Vector2(0, -3), r * 0.7, 0.42, 4.0), Color(1, 1, 0.95, 0.9 * fa))
			for i in 9:
				var a := i * 2.4
				var bp := g + Vector2(cos(a) * r * 0.62 * fmod(i * 0.37, 1.0), sin(a) * r * 0.27)
				var br := (3.0 + (i % 3) * 2.0) * (0.8 + 0.2 * sin(ft * 8.0 + i))
				ci.draw_circle(bp, br + 1.5, Color(0.8, 0.6, 0.2, 0.6 * fa))
				ci.draw_circle(bp, br, Color(1, 1, 1, fa))
		"lava":
			var r := _lava_r()
			var cool := clampf((ft - 1.0) / 0.8, 0.0, 1.0)
			var pts := _wobbly(g, r, 0.46, 2.0)
			Art.outline(ci, pts, 3.5, Color(Art.OUTLINE, fa))
			Art.safe_poly(ci, pts, Color(Color("ff6a10").lerp(Color("7a2a12"), cool), fa))
			Art.safe_poly(ci, _wobbly(g + Vector2(0, -2), r * 0.55, 0.4, 5.0), Color(1.0, 0.82, 0.25, (1.0 - cool) * fa))


func _wobbly(cc: Vector2, r: float, ry: float, speed: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var rr := r * (1.0 + 0.08 * sin(a * 5.0 + ft * speed))
		pts.append(cc + Vector2(cos(a) * rr, sin(a) * rr * ry))
	return pts


func _draw() -> void:
	if ft >= 0.0:
		_draw_flourish()
	for p in bits:
		var k: float = float(p.t) / float(p.life)
		var col: Color = p.col
		var pos: Vector2 = p.p
		var sz: float = p.size
		match p.k:
			"puff":
				draw_circle(pos, sz * (1.0 + 0.8 * k), Color(col, col.a * (1.0 - k)))
			"drop":
				draw_circle(pos, sz + 1.5, Color(Art.OUTLINE, 0.6 * (1.0 - k * k)))
				draw_circle(pos, sz, Color(col, 1.0 - k * k))
			"dot":
				draw_circle(pos, sz, Color(col, 1.0 - k))
			"spark":
				var v: Vector2 = p.v
				draw_line(pos, pos - v.normalized() * 9.0, Color(col, 1.0 - k), sz, true)
			"blob":
				Art.blob(self, pos, sz, sz * 0.8, col, 2.0, 0.5)
			"heart":
				Art.icon_heart(self, pos, sz, col)
				draw_arc(pos + Vector2(0, -1), sz * 0.55, PI * 1.1, PI * 1.9, 8, Color(1, 1, 1, 0.9), 2.0, true)
			"soul":
				var a := 1.0 - k
				var tail := PackedVector2Array([pos + Vector2(-sz * 0.8, 2), pos + Vector2(sz * 0.8, 2), pos + Vector2(sin(float(p.t) * 9.0) * 4.0, sz * 2.4)])
				draw_colored_polygon(tail, Color(col, col.a * a * 0.8))
				draw_circle(pos, sz, Color(col, col.a * a))
				for s: int in [-1, 1]:
					draw_circle(pos + Vector2(s * 3.2, -1), 1.6, Color(0.1, 0.15, 0.3, a))


func _draw_flourish() -> void:
	var fa := _fade()
	match kind:
		"gejzir":
			var h := _geyser_h()
			if h > 4.0:
				var top := g + Vector2(sin(ft * 20.0) * 4.0, -h)
				var col := PackedVector2Array([g + Vector2(-24, 0), g + Vector2(24, 0), top + Vector2(36, 0), top + Vector2(-36, 0)])
				Art.outline(self, col, 3.0)
				Art.grad(self, col, Color("e6f8ff"), Color("6cc6f0"))
				draw_colored_polygon(PackedVector2Array([g + Vector2(-6, 0), g + Vector2(6, 0), top + Vector2(10, 0), top + Vector2(-10, 0)]), Color(1, 1, 1, 0.55))
				Art.blob(self, top, 44, 26, Color("e6f8ff"), 3.0, 0.6)
		"kolo":
			if not wheel.is_empty():
				_draw_wheel(wheel.p, float(wheel.rot))
		"signal":
			var tip := c + Vector2(0, -118)
			for k in 4:
				var age := ft - 0.22 * k
				if age > 0.0:
					var r := age * 420.0
					var a := clampf(1.0 - r / 380.0, 0.0, 1.0)
					draw_arc(tip, r, 0, TAU, 48, Color(0.56, 0.91, 1.0, a), 7.0, true)
					draw_arc(tip, r, 0, TAU, 48, Color(1, 1, 1, a * 0.8), 2.5, true)
		"klobouk":
			var k := clampf((ft - 0.15) / 0.6, 0.0, 1.0)
			var hp := c.lerp(g, k * k) + Vector2(sin(ft * 9.0) * 14.0 * (1.0 - k), -120.0 * (1.0 - k) - 6.0 * k)
			_draw_hat(hp, sin(ft * 7.0) * 0.4 * (1.0 - k) + 0.15 * k)
		"pernicky":
			pass
		"prapor":
			_draw_flag(clampf(ft / 0.25, 0.0, 1.0))
			for i in 3:
				var age := ft - 0.3 - 0.3 * i
				if age > 0.0:
					var a := clampf(1.0 - (age - 0.9) / 0.5, 0.0, 1.0)
					var zp := c + Vector2(20, -80) + Vector2(32, -64) * age
					Art.text(self, zp, "Z", int(26 + age * 16.0), Color(0.86, 0.92, 1.0, a), 6)
		"orloj":
			_draw_clock(c + Vector2(0, -10), fa)
		"dusicky":
			for it in items:
				_draw_cup(it.p, clampf((ft - float(it.at)) / 0.2, 0.0, 1.0))
		"houby":
			for it in items:
				var k := clampf((ft - float(it.at)) / 0.3, 0.0, 1.0)
				if k > 0.0:
					_draw_mushroom(it.p, _back(k))
		"smrad":
			for i in 5:
				var age := ft - 0.15 * i
				if age > 0.0 and age < 1.3:
					var a := clampf(1.0 - age / 1.3, 0.0, 1.0)
					var base := c + Vector2(-60.0 + 30.0 * i, -90.0 - age * 80.0)
					var line := PackedVector2Array()
					for j in 9:
						line.append(base + Vector2(sin(j * 1.1 + ft * 7.0 + i) * 10.0, -j * 11.0))
					draw_polyline(line, Color(Art.OUTLINE, 0.7 * a), 10.0, true)
					draw_polyline(line, Color(0.62, 0.9, 0.2, a), 6.0, true)
			for i in 4:
				var ang := ft * (5.0 + i) + i * 1.7
				var fp := c + Vector2(0, -40) + Vector2(cos(ang) * (90.0 + i * 15.0), sin(ang) * 40.0)
				for s: int in [-1, 1]:
					draw_circle(fp + Vector2(s * 5.0, -5.0 + sin(ft * 60.0) * 2.0), 4.5, Color(0.9, 0.95, 1.0, 0.75 * fa))
				draw_circle(fp, 5.5, Color(0.08, 0.08, 0.08, fa))
		"krabice":
			for it in items:
				var age := ft - float(it.at)
				if age > 0.0:
					var k := clampf(age / 0.42, 0.0, 1.0)
					var p: Vector2 = it.p + Vector2(0, -520.0 * (1.0 - k * k))
					if k >= 1.0:
						p.y -= absf(sin(clampf((age - 0.42) / 0.25, 0.0, 1.0) * PI)) * 14.0
					_draw_box(p, float(it.rot))


func _draw_wheel(p: Vector2, rot: float) -> void:
	var r := 44.0
	draw_arc(p, r * 0.8, 0, TAU, 36, Art.OUTLINE, 14.0, true)
	draw_arc(p, r * 0.8, 0, TAU, 36, Color("5c636b"), 8.0, true)
	for i in 8:
		var a := rot + TAU * i / 8.0
		var d := Vector2.from_angle(a)
		draw_line(p, p + d * r * 0.76, Art.OUTLINE, 6.0, true)
		draw_line(p, p + d * r * 0.76, Color("8a929b"), 3.0, true)
		var bucket := Art.xform(Art.rrect(Rect2(-9, -8, 18, 16), 3), p + d * r, Vector2.ONE, a)
		Art.flat(self, bucket, Color("d8352c"), 2.5)
	Art.circle(self, p, 10.0, Art.GOLD, 3.0)


func _draw_hat(p: Vector2, rot: float) -> void:
	draw_set_transform(p, rot, Vector2.ONE)
	Art.shape(self, Art.ellipse(Vector2(0, 0), 50, 13, 28), Color("3a2a1e"), 3.0, 0.6)
	var crown := Art.poly([-27, 2, -22, -38, 22, -38, 27, 2])
	Art.shape(self, crown, Color("4a3626"), 3.0, 0.8)
	Art.flat(self, Art.rrect(Rect2(-26, -12, 52, 10), 2), Color("c0392b"), 2.5)
	Art.shape(self, Art.ellipse(Vector2(30, -30), 7, 26, 18, 0.5), Color("e2382c"), 2.5, 0.6)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_flag(k: float) -> void:
	var base := g + Vector2(46.0 * face, 0) + Vector2(0, -320.0 * (1.0 - k * k))
	var top := base + Vector2(0, -150)
	Art.stick(self, base, top, Color("7a5230"), 7.0)
	var flag := PackedVector2Array()
	for i in 6:
		flag.append(top + Vector2(i * 16.0 * face, 4.0 + sin(ft * 8.0 - i * 0.9) * 5.0 * i / 5.0))
	for i in range(5, -1, -1):
		flag.append(top + Vector2(i * 16.0 * face, 56.0 + sin(ft * 8.0 - i * 0.9) * 5.0 * i / 5.0))
	Art.shape(self, flag, Color("e2382c"), 3.0, 0.6)
	Art.shape(self, Art.star(top + Vector2(40.0 * face, 30.0 + sin(ft * 8.0 - 2.2) * 2.0), 11, 5), Color.WHITE, 2.0, 0.0)


func _draw_clock(cc: Vector2, a: float) -> void:
	if a <= 0.01:
		return
	var r := 74.0
	draw_circle(cc, r + 9, Color(Art.OUTLINE, a))
	draw_circle(cc, r + 6, Color(Art.GOLD, a))
	draw_circle(cc, r, Color(0.11, 0.23, 0.48, a))
	draw_arc(cc, r * 0.62, 0, TAU, 40, Color(0.85, 0.55, 0.1, 0.5 * a), 10.0, true)
	for i in 12:
		draw_circle(cc + Vector2.from_angle(TAU * i / 12.0) * (r - 10.0), 4.0 if i % 3 == 0 else 2.5, Color(Art.GOLD, a))
	var ah := -PI * 0.5 + clock_ang
	var am := -PI * 0.5 + clock_ang * 12.0
	for hand in [[ah, r * 0.5, 7.0], [am, r * 0.8, 5.0]]:
		var d := Vector2.from_angle(float(hand[0]))
		draw_line(cc, cc + d * float(hand[1]), Color(Art.OUTLINE, a), float(hand[2]) + 4.0, true)
		draw_line(cc, cc + d * float(hand[1]), Color(Art.GOLD, a), float(hand[2]), true)
	draw_circle(cc, 8.0, Color(Art.GOLD, a))
	if bell:
		var age := ft - 1.1
		for k in 2:
			var rr := r + 20.0 + (age - k * 0.15) * 260.0
			var aa := clampf(1.0 - (age - k * 0.15) / 0.6, 0.0, 1.0)
			if age - k * 0.15 > 0.0:
				draw_arc(cc, rr, 0, TAU, 48, Color(1, 0.86, 0.3, aa * a), 5.0, true)


func _draw_cup(p: Vector2, k: float) -> void:
	if k <= 0.0:
		return
	var s := _back(k)
	draw_set_transform(p, 0, Vector2(s, s))
	Art.shape(self, Art.poly([-11, -14, 11, -14, 8, 8, -8, 8]), Color("f6f0e0"), 2.5, 0.6)
	Art.flat(self, Art.ellipse(Vector2(0, -14), 12, 4, 16), Color("3a7bd5"), 2.0)
	draw_arc(Vector2(12, -4), 5.0, -PI * 0.5, PI * 0.5, 8, Art.OUTLINE, 3.0, true)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_mushroom(p: Vector2, s: float) -> void:
	draw_set_transform(p, 0, Vector2(s, s))
	Art.shape(self, Art.rrect(Rect2(-6, -14, 12, 16), 4), Color("efe2c4"), 2.5, 0.6)
	Art.shape(self, Art.ellipse(Vector2(0, -16), 16, 10, 20), Color("8a4a22"), 2.5, 0.9)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_box(p: Vector2, rot: float) -> void:
	draw_set_transform(p, rot, Vector2.ONE)
	Art.shape(self, Art.rrect(Rect2(-26, -18, 52, 28), 3), Color("d4823a"), 3.0, 0.7)
	Art.flat(self, Art.rrect(Rect2(-28, -22, 56, 10), 2), Color("9a5b2a"), 2.5)
	Art.flat(self, Art.rrect(Rect2(-10, -6, 20, 10), 2), Color("f6f0e0"), 0.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _back(k: float) -> float:
	var c1 := 1.70158
	return 1.0 + (c1 + 1.0) * pow(k - 1.0, 3.0) + c1 * pow(k - 1.0, 2.0)
