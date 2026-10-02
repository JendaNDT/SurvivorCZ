extends RefCounted
class_name FxArt
## Střely, efekty a sběratelné předměty.

const SIZES := {
	"slash": Vector2(260, 260), "slash_gold": Vector2(260, 260), "frost": Vector2(220, 220), "puddle": Vector2(150, 110),
	"wagon": Vector2(110, 90), "shield": Vector2(60, 60), "meteor": Vector2(110, 80), "chest": Vector2(90, 80),
	"jidlo": Vector2(80, 64), "magnet": Vector2(64, 64), "xp2": Vector2(44, 52), "crown": Vector2(64, 52),
}


static func size_of(id: String) -> Vector2:
	return SIZES.get(id, Vector2(44, 44))


static func draw(ci: CanvasItem, id: String, t: float) -> void:
	var fn := Callable(FxArt, "_" + id)
	if fn.is_valid():
		fn.call(ci, t)
	else:
		Art.blob(ci, Vector2.ZERO, 8, 8, Color.MAGENTA, 2.0)


# ---------------------------------------------------------------- zbraně hráče

static func _slash_shape(ci: CanvasItem, col: Color, edge: Color) -> void:
	var pts := PackedVector2Array()
	var n := 24
	for i in n + 1:
		var a := lerpf(-1.15, 1.15, float(i) / n)
		pts.append(Vector2(cos(a), sin(a)) * 112)
	for i in range(n, -1, -1):
		var a := lerpf(-1.15, 1.15, float(i) / n)
		var w := sin(PI * float(i) / n)
		pts.append(Vector2(cos(a), sin(a)) * (112 - 34 * w))
	var cols := PackedColorArray()
	for i in pts.size():
		var k := float(i % (n + 1)) / n
		cols.append(Color(col, 0.25 + 0.75 * sin(PI * k)))
	Art.outline(ci, pts, 2.0, Color(edge, 0.6))
	ci.draw_polygon(pts, cols)
	var inner := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(-1.0, 1.0, float(i) / n)
		inner.append(Vector2(cos(a), sin(a)) * 106)
	ci.draw_polyline(inner, Color(1, 1, 1, 0.9), 4.0, true)


static func _slash(ci: CanvasItem, _t: float) -> void:
	_slash_shape(ci, Color("dff3ff"), Color("3a8ad0"))


static func _slash_gold(ci: CanvasItem, _t: float) -> void:
	_slash_shape(ci, Color("fff1a0"), Color("d98e04"))


static func _axe(ci: CanvasItem, _t: float) -> void:
	Art.stick(ci, Vector2(-14, 14), Vector2(10, -10), Color("9a5b2a"), 5.0, 2.0)
	var blade := Art.poly([4, -18, 18, -16, 20, 0, 10, 4, 6, -6])
	Art.shape(ci, blade, Color("cfd8e0"), 2.5, 0.5)


static func _bolt(ci: CanvasItem, _t: float) -> void:
	Art.stick(ci, Vector2(-16, 0), Vector2(12, 0), Color("9a5b2a"), 3.0, 1.5)
	Art.shape(ci, Art.poly([10, -5, 20, 0, 10, 5]), Color("b8c3cf"), 2.0, 0.3)
	Art.shape(ci, Art.poly([-18, -6, -10, 0, -18, 6, -14, 0]), Color("e2382c"), 1.5, 0.2)


static func _bullet(ci: CanvasItem, _t: float) -> void:
	var trail := PackedVector2Array([Vector2(-20, -4), Vector2(0, -6), Vector2(0, 6), Vector2(-20, 4)])
	ci.draw_polygon(trail, PackedColorArray([Color(1, 0.6, 0.1, 0), Color(1, 0.8, 0.2, 0.9), Color(1, 0.8, 0.2, 0.9), Color(1, 0.6, 0.1, 0)]))
	Art.blob(ci, Vector2(2, 0), 6, 6, Color("4a5058"), 2.0)


static func _fireball(ci: CanvasItem, t: float) -> void:
	var trail := PackedVector2Array([Vector2(-20, -8), Vector2(0, -11), Vector2(6, 0), Vector2(0, 11), Vector2(-20, 8), Vector2(-14, 0)])
	Art.outline(ci, trail, 2.0)
	Art.grad(ci, trail, Color("ffe14a"), Color("ff5a10"))
	Art.blob(ci, Vector2(4, 0), 10, 10, Color("ffb030"), 2.5)
	Art.safe_poly(ci, Art.ellipse(Vector2(5, -1), 5, 5, 12), Color("fff6c0"))


static func _meteor(ci: CanvasItem, t: float) -> void:
	var trail := PackedVector2Array([Vector2(-50, -16), Vector2(0, -22), Vector2(14, 0), Vector2(0, 22), Vector2(-50, 16), Vector2(-36, 0)])
	Art.outline(ci, trail, 3.0)
	Art.grad(ci, trail, Color("ffe14a"), Color("ff3a10"))
	Art.blob(ci, Vector2(8, 0), 20, 20, Color("6a3a2a"), 3.0)
	for c in [[2, -6], [14, 6], [10, -10]]:
		Art.safe_poly(ci, Art.ellipse(Vector2(c[0], c[1]), 4, 3, 8), Color("ff8a2a"))


static func _flask(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.rrect(Rect2(-4, -16, 8, 10), 2), Color("cfefff"), 2.0, 0.3)
	Art.blob(ci, Vector2(0, 2), 11, 11, Color("8fe05a"), 2.5)
	Art.flat(ci, Art.rrect(Rect2(-5, -19, 10, 5), 2), Color("9a5b2a"), 1.5)
	Art.shine(ci, Vector2(-4, -2), 3, 4, 0.6, 0.3)


static func _puddle(ci: CanvasItem, _t: float) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var r := 60.0 + sin(a * 5) * 5 + cos(a * 3) * 3
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.62))
	Art.outline(ci, pts, 3.0, Color("2a5a1a"))
	ci.draw_colored_polygon(pts, Color("7ed04a"))
	Art.safe_poly(ci, Art.xform(pts, Vector2.ZERO, Vector2(0.75, 0.7)), Color("9be05a"))
	for b in [[-20, -6, 7], [18, 8, 5], [30, -10, 4], [-34, 10, 4], [4, -16, 3]]:
		Art.circle(ci, Vector2(b[0], b[1]), b[2], Color("c8f08a"), 1.5)


static func _shield(ci: CanvasItem, _t: float) -> void:
	Art.blob(ci, Vector2.ZERO, 22, 22, Color("b0703a"), 3.0)
	for i in 3:
		ci.draw_line(Vector2(-18 + i * 12, -14), Vector2(-18 + i * 12, 14), Color("7a4520"), 2.0, true)
	ci.draw_arc(Vector2.ZERO, 20, 0, TAU, 24, Color("8d97a3"), 4.0, true)
	Art.blob(ci, Vector2.ZERO, 7, 7, Color("cfd8e0"), 2.0)


static func _wagon(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.rrect(Rect2(-44, -30, 88, 34), 4), Color("9a5b2a"), 3.0)
	for i in 4:
		Art.flat(ci, Art.rrect(Rect2(-40 + i * 21, -42, 16, 20), 3), Color("d7262c") if i % 2 == 0 else Color("f4f4f4"), 2.0)
	for x in [-26, 26]:
		Art.circle(ci, Vector2(x, 8), 14, Color("7a4520"), 3.0)
		for k in 4:
			var a := k * PI / 4
			ci.draw_line(Vector2(x, 8) + Vector2(cos(a), sin(a)) * 12, Vector2(x, 8) - Vector2(cos(a), sin(a)) * 12, Color("c98a4a"), 2.0, true)
	Art.safe_poly(ci, Art.star(Vector2(0, -12), 8, 3.5), Color("ffd23f"))


static func _frost(ci: CanvasItem, _t: float) -> void:
	var r := 100.0
	ci.draw_circle(Vector2.ZERO, r, Color(0.55, 0.85, 1.0, 0.18), true, -1, true)
	ci.draw_circle(Vector2.ZERO, r * 0.7, Color(0.75, 0.93, 1.0, 0.12), true, -1, true)
	ci.draw_arc(Vector2.ZERO, r - 2, 0, TAU, 64, Color(0.85, 0.97, 1.0, 0.85), 4.0, true)
	for i in 6:
		var a := TAU * i / 6.0
		var c := Vector2(cos(a), sin(a)) * r * 0.62
		for k in 3:
			var b := k * PI / 3.0
			ci.draw_line(c - Vector2(cos(b), sin(b)) * 12, c + Vector2(cos(b), sin(b)) * 12, Color(1, 1, 1, 0.75), 3.0, true)


# ---------------------------------------------------------------- střely nepřátel

static func _orb(ci: CanvasItem, col: Color, r: float = 10.0) -> void:
	Art.blob(ci, Vector2.ZERO, r, r, col, 2.5)


static func _kapka(ci: CanvasItem, _t: float) -> void:
	var pts := Art.poly([0, -14, 7, -2, 9, 5, 5, 11, -5, 11, -9, 5, -7, -2])
	Art.shape(ci, Art.xform(pts, Vector2.ZERO, Vector2.ONE, PI * 0.5), Color("6fd0ff"), 2.5)


static func _pena(ci: CanvasItem, _t: float) -> void:
	for b in [[-4, -3, 7], [5, -2, 6], [0, 5, 7]]:
		Art.blob(ci, Vector2(b[0], b[1]), b[2], b[2], Color("fffaf0"), 2.0, 0.4)


static func _uhel(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.poly([-10, -4, -2, -11, 9, -6, 11, 5, 2, 11, -9, 6]), Color("3b3b3f"), 2.5)
	ci.draw_line(Vector2(-4, -2), Vector2(4, 3), Color("ff7a1a"), 2.0, true)


static func _strep(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.poly([-12, 0, 0, -6, 14, 0, 0, 6]), Color("9ff0ff"), 2.0, 0.6)


static func _signal(ci: CanvasItem, _t: float) -> void:
	for r in [5, 10, 15]:
		ci.draw_arc(Vector2(-8, 0), r, -0.9, 0.9, 10, Art.OUTLINE, 6.0, true)
		ci.draw_arc(Vector2(-8, 0), r, -0.9, 0.9, 10, Color("8fe9ff"), 3.0, true)


static func _snehova(ci: CanvasItem, _t: float) -> void:
	_orb(ci, Color("f4f8ff"), 10)


static func _srdce(ci: CanvasItem, _t: float) -> void:
	Art.icon_heart(ci, Vector2.ZERO, 11, Color("b86b2c"))
	ci.draw_arc(Vector2(0, -1), 6, 0.3, PI - 0.3, 8, Color.WHITE, 1.5, true)


static func _sip(ci: CanvasItem, _t: float) -> void:
	_bolt(ci, _t)


static func _hvezda(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.star(Vector2.ZERO, 13, 6), Art.GOLD, 2.5)


static func _hrnicek(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.poly([-9, 9, 9, 9, 7, -7, -7, -7]), Color("f6f8ff"), 2.0, 0.5)
	Art.safe_poly(ci, Art.rrect(Rect2(-8, -4, 16, 3), 1), Color("3c6fd6"))
	ci.draw_arc(Vector2(10, 1), 4, -PI * 0.5, PI * 0.5, 8, Art.OUTLINE, 2.5, true)


static func _spora(ci: CanvasItem, _t: float) -> void:
	ci.draw_circle(Vector2.ZERO, 12, Color(0.6, 0.9, 0.35, 0.45), true, -1, true)
	_orb(ci, Color("9be05a"), 7)


static func _hrozen(ci: CanvasItem, _t: float) -> void:
	_orb(ci, Color("7a3ab8"), 9)


static func _ohen(ci: CanvasItem, t: float) -> void:
	_fireball(ci, t)


static func _mlha(ci: CanvasItem, _t: float) -> void:
	ci.draw_circle(Vector2.ZERO, 14, Color(0.8, 0.92, 1.0, 0.35), true, -1, true)
	_orb(ci, Color("cfeaff"), 8)


static func _syr(ci: CanvasItem, _t: float) -> void:
	ci.draw_arc(Vector2.ZERO, 8, 0, TAU, 20, Art.OUTLINE, 9.0, true)
	ci.draw_arc(Vector2.ZERO, 8, 0, TAU, 20, Color("f2b632"), 5.0, true)


static func _hrebik(ci: CanvasItem, _t: float) -> void:
	Art.stick(ci, Vector2(-12, 0), Vector2(10, 0), Color("b8c3cf"), 3.0, 1.5)
	Art.flat(ci, Art.rrect(Rect2(-14, -6, 4, 12), 1), Color("8d97a3"), 1.5)


static func _jiskra(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.star(Vector2.ZERO, 12, 5, 6), Color("ffb030"), 2.0, 0.4)
	Art.circle(ci, Vector2.ZERO, 4, Color("fff6c0"), 0.0)


# ---------------------------------------------------------------- sběratelné předměty

static func _xp0(ci: CanvasItem, _t: float) -> void:
	Art.icon_elixir(ci, Vector2(0, -2), 11, Art.ELIXIR)


static func _xp1(ci: CanvasItem, _t: float) -> void:
	Art.icon_elixir(ci, Vector2(0, -2), 14, Color("a43cff"))


static func _xp2(ci: CanvasItem, _t: float) -> void:
	Art.icon_elixir(ci, Vector2(0, -2), 18, Color("3a2050"))
	Art.shine(ci, Vector2(-5, -4), 3, 5, 0.6, 0.3)


static func _coin(ci: CanvasItem, _t: float) -> void:
	Art.icon_coin(ci, Vector2.ZERO, 11)


static func _jidlo(ci: CanvasItem, _t: float) -> void:
	# svíčková s knedlíky na talíři
	Art.shape(ci, Art.ellipse(Vector2(0, 4), 34, 20, 30), Color("f6f8ff"), 3.0, 0.4)
	Art.safe_poly(ci, Art.ellipse(Vector2(0, 2), 26, 14, 26), Color("eef0f6"))
	Art.safe_poly(ci, Art.ellipse(Vector2(4, 2), 22, 11, 24), Color("e8a050"))
	for k in [[-14, -2], [-4, -4], [6, -2]]:
		Art.shape(ci, Art.rrect(Rect2(k[0] - 6, k[1] - 6, 12, 12), 3), Color("f6f0e0"), 1.5, 0.3)
	Art.shape(ci, Art.ellipse(Vector2(14, 4), 8, 5, 14), Color("8a4a2a"), 1.5, 0.4)
	Art.blob(ci, Vector2(10, -6), 5, 3.5, Color("fffaf0"), 1.5, 0.2)
	Art.circle(ci, Vector2(10, -9), 2.5, Color("e2382c"), 1.0)


static func _magnet(ci: CanvasItem, _t: float) -> void:
	ci.draw_arc(Vector2(0, -2), 16, PI, TAU, 18, Art.OUTLINE, 15.0, true)
	ci.draw_arc(Vector2(0, -2), 16, PI, TAU, 18, Color("e2382c"), 9.0, true)
	for s: int in [-1, 1]:
		Art.flat(ci, Art.rrect(Rect2(s * 16 - 5, -3, 10, 18), 2), Color("e2382c"), 2.5)
		Art.flat(ci, Art.rrect(Rect2(s * 16 - 5, 9, 10, 8), 2), Color("dfe5ea"), 0.0)


static func _chest(ci: CanvasItem, t: float) -> void:
	Art.shape(ci, Art.rrect(Rect2(-34, -10, 68, 34), 5), Color("9a5b2a"), 3.5)
	var lid := Art.arc_pts(Vector2(0, -10), 34, PI, TAU, 16)
	Art.shape(ci, Art.xform(lid, Vector2(0, 0), Vector2(1, 0.6)), Color("b0703a"), 3.5)
	for x in [-22, 22]:
		Art.flat(ci, Art.rrect(Rect2(x - 4, -30, 8, 54), 2), Color("ffd23f"), 2.0)
	Art.flat(ci, Art.rrect(Rect2(-7, -14, 14, 14), 3), Color("ffd23f"), 2.5)
	Art.circle(ci, Vector2(0, -7), 2.5, Art.OUTLINE, 0.0)
	if t > 0.5:
		Art.shape(ci, Art.star(Vector2(26, -32), 7, 3, 4), Color("fffbe0"), 1.5, 0.3)


## Koruna náčelníka (sedí na hlavě nepřítele, viz MiniBoss.dress).
static func _crown(ci: CanvasItem, _t: float) -> void:
	var pts := Art.poly([-22, 14, -24, -8, -12, 2, 0, -14, 12, 2, 24, -8, 22, 14])
	Art.shape(ci, pts, Art.GOLD, 3.0)
	# obruč
	var band := Art.rrect(Rect2(-23, 4, 46, 11), 3)
	Art.shape(ci, band, Art.GOLD_DARK.lightened(0.15), 2.5, 0.6)
	for p: Vector2 in [Vector2(-24, -10), Vector2(0, -17), Vector2(24, -10)]:
		Art.circle(ci, p, 4.0, Color("fff2b0"), 2.5)
	Art.circle(ci, Vector2(0, 9.5), 3.6, Color("ff4d6d"), 2.0)
	for s: int in [-1, 1]:
		Art.circle(ci, Vector2(s * 13, 9.5), 2.8, Color("3fa8ff") if s < 0 else Color("6fcf2f"), 2.0)
	Art.shine(ci, Vector2(-11, -2), 5, 2.5, 0.6, -0.6)
