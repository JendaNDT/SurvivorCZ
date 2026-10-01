extends RefCounted
class_name IconArt
## Ikony zbraní, pasivních předmětů a vylepšení (plátno 80 × 80, střed 0,0).

const SIZE := Vector2(80, 80)


static func draw(ci: CanvasItem, id: String, t: float) -> void:
	var fn := Callable(IconArt, "_" + id)
	if fn.is_valid():
		fn.call(ci, t)
	else:
		Art.icon_star(ci, Vector2.ZERO, 24)


static func _sword(ci: CanvasItem, blade: Color, guard: Color, s: float = 1.0) -> void:
	var a := Vector2(-22, 22) * s
	var b := Vector2(24, -24) * s
	Art.stick(ci, a.lerp(b, 0.28), b, blade, 9.0 * s, 3.0)
	ci.draw_line(a.lerp(b, 0.35), b.lerp(a, 0.08), Color(1, 1, 1, 0.7), 2.0, true)
	Art.stick(ci, a, a.lerp(b, 0.22), Color("7a4520"), 7.0 * s, 3.0)
	var g := a.lerp(b, 0.26)
	var perp := (b - a).orthogonal().normalized() * 12 * s
	Art.stick(ci, g - perp, g + perp, guard, 6.0 * s, 3.0)
	Art.circle(ci, a, 5 * s, guard, 2.5)


static func _axe_shape(ci: CanvasItem, c: Vector2, s: float, rot: float) -> void:
	var handle := Art.xform(PackedVector2Array([Vector2(-20, 24), Vector2(10, -16)]), c, Vector2(s, s), rot)
	Art.stick(ci, handle[0], handle[1], Color("9a5b2a"), 6.0 * s, 2.5)
	var blade := Art.xform(Art.poly([2, -26, 24, -22, 28, 2, 14, 8, 8, -8]), c, Vector2(s, s), rot)
	Art.shape(ci, blade, Color("cfd8e0"), 3.0, 0.6)


# ---------------------------------------------------------------- zbraně

static func _mec(ci: CanvasItem, _t: float) -> void:
	_sword(ci, Color("eef3f7"), Art.GOLD)


static func _sekera(ci: CanvasItem, _t: float) -> void:
	_axe_shape(ci, Vector2.ZERO, 1.0, 0.0)


static func _kuse(ci: CanvasItem, _t: float) -> void:
	Art.stick(ci, Vector2(-26, 14), Vector2(18, -6), Color("9a5b2a"), 9.0, 3.0)
	ci.draw_arc(Vector2(10, -2), 26, -PI * 0.95, -PI * 0.05, 14, Art.OUTLINE, 9.0, true)
	ci.draw_arc(Vector2(10, -2), 26, -PI * 0.95, -PI * 0.05, 14, Color("6b3e1c"), 5.0, true)
	ci.draw_line(Vector2(-16, -2), Vector2(36, -2), Color("f4f4f4"), 2.0, true)
	Art.shape(ci, Art.poly([22, -8, 34, -2, 22, 4]), Color("b8c3cf"), 2.0, 0.3)


static func _ohen(ci: CanvasItem, t: float) -> void:
	var flame := Art.poly([0, -30, 12, -14, 22, -20, 24, 2, 16, 20, 0, 26, -16, 20, -24, 2, -20, -16, -10, -8])
	Art.outline(ci, flame, 3.0)
	Art.grad(ci, flame, Color("ffe14a"), Color("ff4a10"))
	Art.blob(ci, Vector2(0, 8), 11, 13, Color("fff1a0"), 0.0, 0.0)


static func _blesk(ci: CanvasItem, _t: float) -> void:
	Art.icon_bolt(ci, Vector2.ZERO, 30)


static func _snowflake(ci: CanvasItem, r: float, col: Color) -> void:
	for k in 3:
		var a := k * PI / 3.0 + PI / 6.0
		var d := Vector2(cos(a), sin(a)) * r
		Art.stick(ci, -d, d, col, 6.0, 2.5)
	for k in 6:
		var a := k * PI / 3.0 + PI / 6.0
		var p := Vector2(cos(a), sin(a)) * r * 0.6
		for s: int in [-1, 1]:
			var q := p + Vector2(cos(a + s * 0.8), sin(a + s * 0.8)) * r * 0.32
			ci.draw_line(p, q, Art.OUTLINE, 7.0, true)
			ci.draw_line(p, q, col, 3.5, true)
	Art.circle(ci, Vector2.ZERO, 6, col, 2.5)


static func _aura(ci: CanvasItem, _t: float) -> void:
	ci.draw_circle(Vector2.ZERO, 32, Color(0.5, 0.85, 1, 0.35), true, -1, true)
	_snowflake(ci, 26, Color("bff3ff"))


static func _stity(ci: CanvasItem, _t: float) -> void:
	Art.blob(ci, Vector2(0, 0), 28, 28, Color("b0703a"), 3.0)
	for i in 4:
		ci.draw_line(Vector2(-22 + i * 14, -20), Vector2(-22 + i * 14, 20), Color("7a4520"), 2.5, true)
	ci.draw_arc(Vector2.ZERO, 26, 0, TAU, 32, Color("8d97a3"), 5.0, true)
	Art.blob(ci, Vector2.ZERO, 9, 9, Color("cfd8e0"), 2.5)


static func _jed(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.rrect(Rect2(-6, -30, 12, 14), 3), Color("cfefff"), 2.5, 0.3)
	Art.blob(ci, Vector2(0, 4), 24, 22, Color("7ed04a"), 3.0)
	Art.flat(ci, Art.rrect(Rect2(-8, -34, 16, 7), 3), Color("9a5b2a"), 2.0)
	Art.icon_skull(ci, Vector2(0, 6), 10)


# ---------------------------------------------------------------- evoluce

static func _bruncvik(ci: CanvasItem, _t: float) -> void:
	ci.draw_circle(Vector2.ZERO, 34, Color(1, 0.9, 0.4, 0.35), true, -1, true)
	_sword(ci, Color("fff6c8"), Color("e2382c"), 1.1)


static func _vir(ci: CanvasItem, _t: float) -> void:
	for i in 3:
		var a := TAU * i / 3.0
		_axe_shape(ci, Vector2(cos(a), sin(a)) * 12, 0.62, a + 0.6)
	ci.draw_arc(Vector2.ZERO, 30, 0, PI * 1.5, 20, Color(1, 1, 1, 0.8), 3.0, true)


static func _pistala(ci: CanvasItem, _t: float) -> void:
	Art.stick(ci, Vector2(-30, 14), Vector2(-4, 4), Color("9a5b2a"), 10.0, 3.0)
	Art.stick(ci, Vector2(-6, 4), Vector2(28, -12), Color("6c7580"), 9.0, 3.0)
	Art.circle(ci, Vector2(30, -13), 6, Color("4a5058"), 2.5)
	Art.shape(ci, Art.star(Vector2(34, -26), 10, 4, 6), Color("ffb030"), 2.0, 0.3)


static func _peklo(ci: CanvasItem, t: float) -> void:
	var trail := Art.poly([-32, -30, -6, -14, 6, 4, -12, 4, -26, -10])
	Art.outline(ci, trail, 3.0)
	Art.grad(ci, trail, Color("ffe14a"), Color("ff4a10"))
	Art.blob(ci, Vector2(8, 10), 18, 18, Color("6a3a2a"), 3.0)
	Art.safe_poly(ci, Art.ellipse(Vector2(4, 6), 5, 4, 10), Color("ff8a2a"))


static func _perun(ci: CanvasItem, _t: float) -> void:
	for p in [[-14, -16], [14, -10], [0, -22]]:
		Art.blob(ci, Vector2(p[0], p[1]), 16, 11, Color("8d97b3"), 2.5, 0.5)
	Art.icon_bolt(ci, Vector2(-8, 12), 18)
	Art.icon_bolt(ci, Vector2(12, 14), 16)


static func _mraz(ci: CanvasItem, _t: float) -> void:
	ci.draw_circle(Vector2.ZERO, 34, Color(0.4, 0.75, 1, 0.45), true, -1, true)
	_snowflake(ci, 30, Color("e8fbff"))


static func _hradba(ci: CanvasItem, t: float) -> void:
	ci.draw_set_transform(Vector2(0, 4), 0, Vector2(0.62, 0.62))
	FxArt._wagon(ci, t)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func _bazina(ci: CanvasItem, t: float) -> void:
	ci.draw_set_transform(Vector2(0, 6), 0, Vector2(0.48, 0.48))
	FxArt._puddle(ci, t)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	Art.icon_skull(ci, Vector2(0, -6), 12)


# ---------------------------------------------------------------- pasivní předměty

static func _sila(ci: CanvasItem, _t: float) -> void:
	# medvědí tlapa
	Art.blob(ci, Vector2(0, 10), 22, 18, Color("8a5a3a"), 3.0)
	Art.blob(ci, Vector2(0, 12), 12, 9, Color("f2b0a0"), 2.0, 0.4)
	for i in 4:
		var a := -PI * 0.85 + i * PI * 0.23
		var c := Vector2(cos(a), sin(a)) * 24 + Vector2(0, 6)
		Art.blob(ci, c, 7, 8, Color("8a5a3a"), 2.5, 0.5)
		Art.blob(ci, c + Vector2(0, 1), 4, 4.5, Color("f2b0a0"), 0.0, 0.0)


static func _brneni(ci: CanvasItem, _t: float) -> void:
	var shirt := Art.poly([-14, -26, 14, -26, 28, -14, 22, -2, 16, -6, 16, 26, -16, 26, -16, -6, -22, -2, -28, -14])
	Art.shape(ci, shirt, Color("aab5c2"), 3.0)
	for y in 5:
		for x in 4:
			ci.draw_arc(Vector2(-10 + x * 7 + (y % 2) * 3, -16 + y * 8), 3.2, 0, PI, 6, Color("6c7580"), 1.5, true)


static func _boty(ci: CanvasItem, _t: float) -> void:
	for s: int in [-1, 1]:
		var wing := Art.poly([0, 0, s * -10, -22, s * -24, -24, s * -18, -12, s * -26, -8, s * -14, 2])
		if s < 0:
			Art.shape(ci, Art.xform(wing, Vector2(-6, -2)), Color("f6f6f6"), 2.0, 0.4)
	Art.icon_boot(ci, Vector2(6, 2), 26)


static func _srdce(ci: CanvasItem, _t: float) -> void:
	Art.icon_heart(ci, Vector2(0, 2), 30, Color("b86b2c"))
	ci.draw_arc(Vector2(0, -2), 17, 0.35, PI - 0.35, 14, Color.WHITE, 3.0, true)
	Art.circle(ci, Vector2(-8, -8), 3, Color("ff4d6d"), 1.5)
	Art.circle(ci, Vector2(8, -8), 3, Color("6fd0ff"), 1.5)


static func _voda(ci: CanvasItem, _t: float) -> void:
	ci.draw_circle(Vector2(0, 4), 30, Color(0.4, 0.8, 1, 0.3), true, -1, true)
	Art.shape(ci, Art.rrect(Rect2(-7, -30, 14, 16), 3), Color("e0f6ff"), 2.5, 0.3)
	Art.blob(ci, Vector2(0, 6), 20, 20, Color("4ab8ff"), 3.0)
	Art.flat(ci, Art.rrect(Rect2(-9, -34, 18, 7), 3), Color("9a5b2a"), 2.0)
	Art.icon_heart(ci, Vector2(0, 8), 10, Color("ffffff"))


static func _magnet(ci: CanvasItem, t: float) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2(1.5, 1.5))
	FxArt._magnet(ci, t)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func _hodiny(ci: CanvasItem, _t: float) -> void:
	for y in [-28, 24]:
		Art.flat(ci, Art.rrect(Rect2(-22, y, 44, 7), 3), Color("9a5b2a"), 2.5)
	var glass := Art.poly([-16, -22, 16, -22, 4, 0, 16, 22, -16, 22, -4, 0])
	Art.shape(ci, glass, Color("dff6ff"), 2.5, 0.3)
	Art.safe_poly(ci, Art.poly([-10, -14, 10, -14, 2, -2, -2, -2]), Color("f2c632"))
	Art.safe_poly(ci, Art.poly([-12, 20, 12, 20, 0, 8]), Color("f2c632"))


static func _kniha(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.rrect(Rect2(-24, -28, 48, 56), 5), Color("7a3ab8"), 3.0)
	Art.flat(ci, Art.rrect(Rect2(16, -24, 6, 48), 2), Color("f6e7c4"), 1.5)
	Art.shape(ci, Art.star(Vector2(-3, 0), 13, 6), Art.GOLD, 2.0, 0.4)


static func _zrcadlo(ci: CanvasItem, _t: float) -> void:
	Art.stick(ci, Vector2(0, 12), Vector2(0, 32), Color("d98e04"), 7.0, 2.5)
	Art.blob(ci, Vector2(0, -6), 22, 24, Art.GOLD, 3.0)
	Art.blob(ci, Vector2(0, -6), 16, 18, Color("bfefff"), 0.0, 0.0)
	Art.shine(ci, Vector2(-6, -14), 4, 9, 0.8, 0.4)


static func _ctyrlistek(ci: CanvasItem, _t: float) -> void:
	Art.stick(ci, Vector2(0, 6), Vector2(6, 32), Color("3f8f2a"), 4.0, 2.0)
	for k in 4:
		var a := k * PI * 0.5 + PI * 0.25
		var c := Vector2(cos(a), sin(a)) * 13
		Art.icon_heart(ci, c, 13, Color("5fc83a"))


static func _sova(ci: CanvasItem, _t: float) -> void:
	Art.blob(ci, Vector2(0, 4), 24, 26, Color("9a6a3a"), 3.0)
	Art.blob(ci, Vector2(0, 12), 14, 14, Color("e8d2a8"), 0.0, 0.0)
	for s: int in [-1, 1]:
		Art.shape(ci, Art.poly([s * 12, -16, s * 22, -32, s * 22, -14]), Color("9a6a3a"), 2.0, 0.3)
		Art.circle(ci, Vector2(s * 9, -6), 8, Color("fff6c0"), 2.5)
		Art.circle(ci, Vector2(s * 9, -6), 4, Art.OUTLINE, 0.0)
	Art.shape(ci, Art.poly([-4, 2, 4, 2, 0, 10]), Color("ffb030"), 1.5, 0.3)


static func _rune(ci: CanvasItem, col: Color) -> void:
	var stone := Art.poly([-22, -26, 18, -30, 26, 0, 20, 28, -18, 28, -26, 4])
	Art.shape(ci, stone, Color("7d858c"), 3.0)
	ci.draw_circle(Vector2.ZERO, 18, Color(col, 0.3), true, -1, true)


static func _ohen_runa(ci: CanvasItem, _t: float) -> void:
	_rune(ci, Color("ff6a2a"))
	var f := Art.poly([0, -18, 8, -4, 12, 8, 0, 16, -12, 8, -8, -4])
	Art.shape(ci, f, Color("ff8a2a"), 2.0, 0.3)


static func _led_krystal(ci: CanvasItem, t: float) -> void:
	ci.draw_set_transform(Vector2(-2, 24), 0, Vector2(1.0, 1.0))
	PropArt._krystal(ci, t)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func _bour_amulet(ci: CanvasItem, _t: float) -> void:
	ci.draw_arc(Vector2(0, -18), 16, PI * 1.1, TAU * 0.95, 14, Art.GOLD, 3.0, true)
	Art.blob(ci, Vector2(0, 6), 22, 22, Art.GOLD, 3.0)
	Art.blob(ci, Vector2(0, 6), 15, 15, Color("2a4ab8"), 2.0, 0.3)
	Art.icon_bolt(ci, Vector2(0, 6), 11)


static func _jed_ampule(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.rrect(Rect2(-10, -30, 20, 56), 9), Color("dff6ff"), 3.0, 0.3)
	Art.safe_poly(ci, Art.rrect(Rect2(-7, -6, 14, 29), 6), Color("8fe05a"))
	Art.flat(ci, Art.rrect(Rect2(-12, -34, 24, 8), 3), Color("6a3a9a"), 2.0)
	for b in [[-2, 4], [3, 14]]:
		Art.circle(ci, Vector2(b[0], b[1]), 2.5, Color("d0ffa8"), 0.0)


# ---------------------------------------------------------------- meta

static func _reroll(ci: CanvasItem, _t: float) -> void:
	for s: int in [-1, 1]:
		var a0 := 0.2 if s > 0 else PI + 0.2
		ci.draw_arc(Vector2.ZERO, 22, a0, a0 + PI * 0.75, 16, Art.OUTLINE, 11.0, true)
		ci.draw_arc(Vector2.ZERO, 22, a0, a0 + PI * 0.75, 16, Color("3fb2ff"), 6.0, true)
		var tip := Vector2(cos(a0 + PI * 0.75), sin(a0 + PI * 0.75)) * 22
		var dir := Vector2(cos(a0 + PI * 0.75 + PI * 0.5), sin(a0 + PI * 0.75 + PI * 0.5))
		var tri := PackedVector2Array([tip + dir * 10, tip + dir.orthogonal() * 9, tip - dir.orthogonal() * 9])
		Art.shape(ci, tri, Color("3fb2ff"), 2.5, 0.3)


static func _coin(ci: CanvasItem, _t: float) -> void:
	Art.icon_coin(ci, Vector2.ZERO, 26)


static func _srdce_zlate(ci: CanvasItem, _t: float) -> void:
	for s: int in [-1, 1]:
		var wing := Art.poly([0, 0, s * 18, -20, s * 34, -18, s * 28, -6, s * 34, 2, s * 18, 8])
		Art.shape(ci, Art.xform(wing, Vector2(s * 8, 0)), Color("f6f6f6"), 2.0, 0.3)
	Art.icon_heart(ci, Vector2(0, 2), 24, Art.GOLD)


static func _hero(ci: CanvasItem, t: float) -> void:
	ci.draw_set_transform(Vector2(0, 14), 0, Vector2(0.5, 0.5))
	HeroArt.draw(ci, t)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
