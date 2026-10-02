extends Control
class_name Hud
## Horní lišta v bitvě: životy, elixír (zkušenosti), úroveň, čas, zlato, zabití,
## seznam zbraní, ukazatel bosse, šipka k náčelníkovi mimo obrazovku
## a oznámení uprostřed obrazovky.

var b: Battle
var snap := []
var banners: Array = []
var flash_a := 0.0
var redraw_t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func banner(text: String, col: Color, sub: String = "", dur: float = 2.4) -> void:
	banners.append({"text": text, "col": col, "sub": sub, "t": 0.0, "dur": dur})
	if banners.size() > 2:
		banners.pop_front()


var flash_col := Color(1, 1, 0.85)


func flash_screen(col: Color = Color(1, 1, 0.85)) -> void:
	flash_a = 0.85
	flash_col = col


func _process(delta: float) -> void:
	var paused := get_tree().paused
	if not paused:
		var i := banners.size() - 1
		while i >= 0:
			banners[i].t += delta
			if banners[i].t > banners[i].dur:
				banners.remove_at(i)
			i -= 1
		flash_a = maxf(0.0, flash_a - delta * 2.5)
	redraw_t -= delta
	if redraw_t <= 0.0 or not banners.is_empty() or flash_a > 0.0 or not _offscreen().is_empty():
		redraw_t = 0.1
		queue_redraw()


func _draw() -> void:
	if b == null or b.player == null:
		return
	var vs := size
	var top := 12.0
	# --- portrét a životy
	var pc := Vector2(52, 50)
	Art.circle(self, pc, 36, Color("3a5a8a"), 4.0)
	draw_circle(pc, 30, Color("6fb8ff"))
	var hkey := "icon:hero_" + b.hero_id
	if Baker.has(hkey):
		draw_texture_rect(Baker.tex(hkey), Rect2(pc - Vector2(34, 36), Vector2(68, 68)), false)
	ci_level_badge(pc + Vector2(-28, 28), b.level)
	var hp_r := Rect2(96, top + 6, 250, 26)
	Art.bar(self, hp_r, b.player.hp / b.player.max_hp, Art.HP_RED)
	Art.icon_heart(self, Vector2(98, top + 19), 16)
	Art.text(self, Vector2(hp_r.get_center().x + 8, hp_r.position.y + 20), "%d / %d" % [int(ceil(b.player.hp)), int(b.player.max_hp)], 18, Color.WHITE, 5)
	# --- elixír (zkušenosti)
	var xp_r := Rect2(96, top + 40, 250, 18)
	Art.bar(self, xp_r, b.xp / b.xp_need, Art.ELIXIR)
	Art.icon_elixir(self, Vector2(98, top + 47), 11)
	# --- zbraně a předměty
	var x := 100.0
	for w in b.weapons.weapons:
		_slot(Vector2(x, top + 76), "icon:" + w.id, w.level, Upgrades.is_evolution(w.id))
		x += 40.0
	x += 8.0
	for id in b.weapons.passives.keys():
		_slot(Vector2(x, top + 76), "icon:" + id, b.weapons.passives[id].level, false, 0.8)
		x += 34.0
	# --- požehnání z božích muk s odpočtem
	x = 100.0
	for id in b.buffs.keys():
		var key: String = EventDefs.BLESSINGS[id].icon
		_slot(Vector2(x, top + 118), key, 0, true)
		Art.text(self, Vector2(x + 22, top + 126), "%d" % ceili(float(b.buffs[id])), 16, Color("fff2b0"), 4, HORIZONTAL_ALIGNMENT_LEFT, 40)
		x += 64.0
	# --- čas uprostřed
	var cx := vs.x * 0.5
	if b.state == Battle.State.BOSS or b.state == Battle.State.BOSS_INTRO or b.boss != null:
		_boss_bar(cx, top)
	else:
		var plate := Rect2(cx - 78, top, 156, 52)
		Art.stone_plate(self, plate)
		var tl := b.time_left()
		var col := Color.WHITE if tl > 20.0 else Color("ffcf4a")
		Art.text(self, Vector2(cx, top + 39), "%d:%02d" % [int(tl) / 60, int(tl) % 60], 34, col, 8)
		Art.text(self, Vector2(cx, top + 70), "do příchodu bosse", 15, Color("fff6c8"), 5)
	# --- vpravo: zlato a zabití
	var rx := vs.x - 120.0
	_counter(Vector2(rx - 150, top + 6), "coin", str(b.gold_run))
	_counter(Vector2(rx - 150, top + 44), "skull", str(b.kills))
	if bool(Game.setting("show_fps")):
		var ft := "FPS %d · nepřátel %d" % [Engine.get_frames_per_second(), b.enemies.count()]
		Art.text(self, Vector2(rx - 150, top + 102), ft, 16, Color("bfffa8"), 5, HORIZONTAL_ALIGNMENT_LEFT, 260)
	# --- šipka k náčelníkovi, který je mimo obrazovku
	if not get_tree().paused:
		for tg in _offscreen():
			_arrow(tg[0], vs, tg[1])
	# --- oznámení
	var active := b.state == Battle.State.PLAY or b.state == Battle.State.BOSS or b.state == Battle.State.BOSS_INTRO
	if active:
		for i in banners.size():
			_draw_banner(banners[i], vs, i)
	if flash_a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(flash_col, flash_a * 0.6))
	# vinětace při nízkých životech
	if b.player.hp < b.player.max_hp * 0.3 and b.state != Battle.State.LOSE:
		var a := 0.25 + 0.15 * sin(b.time_total * 6.0)
		for k in 4:
			draw_rect(Rect2(Vector2.ZERO, Vector2(vs.x, 10 + k * 8)), Color(0.9, 0, 0, a * 0.25))
			draw_rect(Rect2(Vector2(0, vs.y - 10 - k * 8), Vector2(vs.x, 10 + k * 8)), Color(0.9, 0, 0, a * 0.25))


## Cíle mimo obrazovku, na které ukazuje šipka: [poloha na obrazovce, ikona]
## (náčelník = "crown", události = upečená kresba "ev:<id>").
func _offscreen() -> Array:
	var out := []
	if b == null or b.player == null:
		return out
	var view := Rect2(Vector2.ZERO, size).grow(-20.0)
	var xf: Transform2D = b.world.get_global_transform_with_canvas()
	if b.chief != null and b.chief.alive and b.chief.intro_t <= 0.0:
		var p: Vector2 = xf * b.chief.position
		if not view.has_point(p):
			out.append([p, "crown"])
	if b.events:
		for ev in b.events.list:
			var p2: Vector2 = xf * (ev.pos as Vector2)
			if not view.has_point(p2):
				out.append([p2, "ev:" + str(ev.id)])
	return out


func _arrow(p: Vector2, vs: Vector2, icon: String) -> void:
	# šipka jezdí po okraji obrazovky, nahoře pod horní lištou
	var inner := Rect2(Vector2(70, 140), vs - Vector2(140, 210))
	var c := inner.get_center()
	var dir := (p - c).normalized()
	var kx := (inner.end.x - c.x if dir.x > 0.0 else inner.position.x - c.x) / dir.x if absf(dir.x) > 0.001 else 1.0e9
	var ky := (inner.end.y - c.y if dir.y > 0.0 else inner.position.y - c.y) / dir.y if absf(dir.y) > 0.001 else 1.0e9
	var at := c + dir * minf(kx, ky)
	var pulse := 1.0 + 0.08 * sin(b.time_total * 8.0)
	var tri := Art.xform(Art.poly([26, 0, -8, -18, -2, 0, -8, 18]), at + dir * 14.0, Vector2(pulse, pulse), dir.angle())
	var ic := at - dir * 14.0
	if icon == "crown":
		Art.shape(self, tri, Color("ffb310"), 3.0, 0.5)
		Art.circle(self, ic, 20.0, Color("6b3a17"), 3.0)
		Art.icon_crown(self, ic + Vector2(0, 2), 12.0)
	else:
		Art.shape(self, tri, Color("6fd0ff"), 3.0, 0.5)
		Art.circle(self, ic, 24.0, Color("f6e7c4"), 3.0)
		if Baker.has(icon):
			var tex := Baker.tex(icon)
			var ts := tex.get_size()
			var k := 40.0 / maxf(ts.x, ts.y)
			draw_texture_rect(tex, Rect2(ic - ts * k * 0.5, ts * k), false)


func ci_level_badge(c: Vector2, lv: int) -> void:
	var pts := Art.poly([0, -16, 15, -8, 13, 10, 0, 18, -13, 10, -15, -8])
	Art.shape(self, Art.xform(pts, c), Color("3fa8ff"), 3.0)
	Art.text(self, c + Vector2(0, 7), str(lv), 18, Color.WHITE, 5)


func _slot(p: Vector2, key: String, lv: int, evo: bool, sc: float = 1.0) -> void:
	var s := 34.0 * sc
	var r := Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s))
	Art.outline(self, Art.rrect(r, 7), 2.5)
	Art.safe_poly(self, Art.rrect(r, 7), Color("ffd23f") if evo else Color("f6e7c4"))
	if Baker.has(key):
		draw_texture_rect(Baker.tex(key), r.grow(-2), false)
	if lv > 0:
		Art.text(self, p + Vector2(s * 0.42, s * 0.55), str(lv) if not evo else "★", 13, Color.WHITE, 4)


func _counter(p: Vector2, icon: String, value: String) -> void:
	var r := Rect2(p, Vector2(130, 32))
	Art.safe_poly(self, Art.rrect(r, 16), Color(0, 0, 0, 0.35))
	if icon == "coin":
		Art.icon_coin(self, p + Vector2(16, 16), 14)
	else:
		Art.icon_skull(self, p + Vector2(16, 16), 13)
	Art.text(self, p + Vector2(34, 25), value, 22, Color.WHITE, 6, HORIZONTAL_ALIGNMENT_LEFT, 100)


func _boss_bar(cx: float, top: float) -> void:
	if b.boss == null:
		Art.text(self, Vector2(cx, top + 40), "Boss se blíží…", 30, Color("ff8a6a"), 8)
		return
	var w := minf(520.0, size.x * 0.4)
	var r := Rect2(cx - w * 0.5, top + 30, w, 26)
	Art.bar(self, r, maxf(0.0, b.boss.hp) / b.boss.max_hp, Color("b8262c"))
	Art.text(self, Vector2(cx, top + 24), b.boss.bdef.name, 24, Color("ffd23f"), 7)
	for k in [0.33, 0.66]:
		var x: float = r.position.x + r.size.x * k
		draw_line(Vector2(x, r.position.y + 3), Vector2(x, r.end.y - 3), Color(0, 0, 0, 0.5), 2.0)


## Víc oznámení naráz se skládá pod sebe.
func _draw_banner(bn: Dictionary, vs: Vector2, idx: int = 0) -> void:
	var t: float = bn.t
	var k := clampf(t / 0.25, 0.0, 1.0)
	var out := clampf((t - float(bn.dur) + 0.5) / 0.5, 0.0, 1.0)
	var sc := 0.6 + 0.4 * (1.0 - pow(1.0 - k, 3)) + 0.06 * sin(clampf(t / 0.4, 0, 1) * PI)
	var a := 1.0 - out
	var c := Vector2(vs.x * 0.5, vs.y * 0.3 + idx * 112.0)
	var txt: String = bn.text
	var fs := 46
	var w := Art.text_width(txt, fs) + 80.0
	draw_set_transform(c, 0, Vector2(sc, sc))
	modulate.a = 1.0
	var col: Color = bn.col
	Art.ribbon(self, Vector2.ZERO, w, 64, Color(col.darkened(0.25), a), "", 30)
	Art.text(self, Vector2(0, 16), txt, fs, Color(1, 1, 1, a), 10)
	if bn.sub != "":
		Art.text(self, Vector2(0, 66), bn.sub, 24, Color(1, 0.96, 0.8, a), 7)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
