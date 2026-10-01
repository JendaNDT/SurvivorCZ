extends RefCounted
class_name EnemyArt
## Kresby nepřátel. Každý nepřítel se kreslí kolem bodu (0,0), parametr t je fáze
## animace (0 nebo 1) – střídají se dva snímky chůze.

static func draw(ci: CanvasItem, id: String, t: float) -> void:
	var fn := Callable(EnemyArt, "_" + id)
	if fn.is_valid():
		fn.call(ci, t)
	else:
		Art.blob(ci, Vector2.ZERO, 16, 16, Color.MAGENTA)


static func _feet(ci: CanvasItem, t: float, y: float, spread: float, col: Color, r: float = 6.0) -> void:
	var st := 1.0 if t > 0.5 else -1.0
	for s: int in [-1, 1]:
		Art.blob(ci, Vector2(s * spread + st * s * 2.0, y - st * s * 1.5), r * 1.3, r, col, 2.5, 0.6)


static func _arm(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float = 7.0) -> void:
	Art.stick(ci, a, b, col, w, 2.5)
	Art.circle(ci, b, w * 0.62, col, 2.5)


# ================================================================ Karlovarský

static func _host(ci: CanvasItem, t: float) -> void:
	# lázeňský host v županu s pohárkem
	_feet(ci, t, 24, 8, Color("e8e2ff"), 5.0)
	var robe := Art.poly([-17, -6, 17, -6, 20, 24, -20, 24])
	Art.shape(ci, Art.grow(robe, 2), Color("f2f2ff"), 3.0)
	for i in 4:
		Art.safe_poly(ci, Art.rrect(Rect2(-18 + i * 10, -4, 4, 27), 2), Color("8fb7ff"))
	Art.safe_poly(ci, Art.rrect(Rect2(-19, 8, 38, 5), 2), Color("ff7aa8"))
	Art.blob(ci, Vector2(0, -18), 15, 14, Color("f5c39a"), 3.0)
	# pleš a vousy po stranách
	for s: int in [-1, 1]:
		Art.blob(ci, Vector2(s * 13, -16), 5, 6, Color("e9e9e9"), 2.0, 0.3)
	Art.eyes(ci, Vector2(0, -20), 11, 3.2, true)
	Art.blob(ci, Vector2(0, -14), 3.5, 3, Color("e8a07a"), 1.5, 0.3)
	Art.mouth_line(ci, Vector2(0, -8), 5, -2)
	# lázeňský pohárek
	_arm(ci, Vector2(12, 0), Vector2(22, -4), Color("f2f2ff"))
	var cup := Art.poly([18, -16, 28, -16, 27, -2, 19, -2])
	Art.shape(ci, cup, Color("ffffff"), 2.5, 0.6)
	Art.stick(ci, Vector2(27, -12), Vector2(33, -18), Color("ffffff"), 3.0, 2.0)
	Art.safe_poly(ci, Art.rrect(Rect2(19, -11, 8, 3), 1), Color("6fb8ff"))


static func _oplatka(ci: CanvasItem, t: float) -> void:
	# kulatá lázeňská oplatka, kutálí se
	var rot := 0.35 if t > 0.5 else -0.1
	var disc := Art.ellipse(Vector2(0, 2), 22, 22, 36)
	Art.shape(ci, disc, Color("f1cf8e"), 3.0)
	Art.safe_poly(ci, Art.ellipse(Vector2(0, 2), 17, 17, 30), Color("e3b56a"))
	for i in 5:
		var off := -12.0 + i * 6.0
		var a := Vector2(off, -14).rotated(rot) + Vector2(0, 2)
		var b := Vector2(off, 18).rotated(rot) + Vector2(0, 2)
		ci.draw_line(a, b, Color("c9954c"), 1.8, true)
		var c := Vector2(-14, off).rotated(rot) + Vector2(0, 2)
		var d := Vector2(18, off).rotated(rot) + Vector2(0, 2)
		ci.draw_line(c, d, Color("c9954c"), 1.8, true)
	Art.shine(ci, Vector2(-8, -10), 7, 3.5, 0.5)
	Art.eyes(ci, Vector2(0, -1), 14, 4.2, true)
	Art.mouth_grin(ci, Vector2(0, 8), 6, 5)


static func _konvice(ci: CanvasItem, t: float) -> void:
	# porcelánová konvice s modrým vzorem
	_feet(ci, t, 34, 14, Color("ffffff"), 7.0)
	Art.stick(ci, Vector2(24, 2), Vector2(42, -18), Color("f4f6ff"), 9.0, 3.0)
	var handle := Art.ring_sector(Vector2(-28, 2), 10, 17, PI * 0.5, PI * 1.5, 14)
	Art.shape(ci, handle, Color("f4f6ff"), 3.0, 0.5)
	var body := Art.ellipse(Vector2(0, 6), 32, 28, 40)
	Art.shape(ci, body, Color("f6f8ff"), 3.5)
	# modrý cibulák
	for i in 6:
		var a := TAU * i / 6.0
		var p := Vector2(0, 10) + Vector2(cos(a) * 18, sin(a) * 12)
		Art.safe_poly(ci, Art.ellipse(p, 4.5, 3, 10, a), Color("3c6fd6"))
	Art.safe_poly(ci, Art.rrect(Rect2(-30, 22, 60, 4), 2), Color("3c6fd6"))
	# víčko
	Art.blob(ci, Vector2(0, -22), 16, 6, Color("f6f8ff"), 3.0)
	Art.circle(ci, Vector2(0, -30), 5, Art.GOLD, 2.5)
	Art.eyes(ci, Vector2(0, 0), 18, 5.0, true)
	Art.mouth_line(ci, Vector2(0, 12), 8, -3)


# ================================================================ Plzeňský

static func _pena(ci: CanvasItem, t: float) -> void:
	var wob := 1.0 if t > 0.5 else 0.0
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		var r := 22.0 + sin(a * 5 + wob) * 2.5 + cos(a * 3) * 1.5
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.85 + 4))
	Art.shape(ci, pts, Color("fff8e6"), 3.0)
	for b in [[-10, -6, 4], [8, -10, 3], [12, 8, 3.5], [-12, 10, 2.5], [2, 14, 2]]:
		ci.draw_arc(Vector2(b[0], b[1]), b[2], 0, TAU, 12, Color("e6d7b0"), 1.5, true)
	Art.safe_poly(ci, Art.ellipse(Vector2(0, 20), 18, 4, 18), Color("f2b632"))
	Art.eyes(ci, Vector2(0, 0), 14, 4.5, true)
	Art.mouth_grin(ci, Vector2(0, 9), 5, 4, false)


static func _sud(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 36, 14, Color("5a3a22"), 7.0)
	var body := Art.rrect(Rect2(-28, -30, 56, 64), 18)
	Art.shape(ci, body, Color("b06a2c"), 3.5)
	for x: float in [-14, 0, 14]:
		ci.draw_line(Vector2(x, -28), Vector2(x, 32), Color("7d4518"), 2.0, true)
	for y: float in [-18, 20]:
		var hoop := Art.rrect(Rect2(-30, y - 4, 60, 8), 3)
		Art.shape(ci, hoop, Color("8d97a3"), 2.5, 0.5)
	Art.circle(ci, Vector2(0, 8), 6, Color("6b3e1c"), 2.5)
	Art.eyes(ci, Vector2(0, -6), 18, 5.0, true)
	Art.mouth_line(ci, Vector2(0, 14), 7, -3)
	Art.shine(ci, Vector2(-14, -22), 6, 3, 0.4)


static func _chmel(ci: CanvasItem, t: float) -> void:
	# chmelová šiška – protáhlý šiškovitý tvar se šupinami
	_feet(ci, t, 24, 7, Color("4f8a1f"), 4.5)
	var col := Color("a5dc52")
	var cone := Art.poly([0, -28, 10, -20, 14, -6, 13, 8, 8, 18, 0, 22, -8, 18, -13, 8, -14, -6, -10, -20])
	Art.shape(ci, cone, col, 3.0)
	for row in 4:
		var y := -18.0 + row * 9.0
		var w := 12.0 - absf(row - 1.5) * 2.0
		ci.draw_arc(Vector2(-w * 0.45, y), w * 0.55, 0.2, PI - 0.2, 8, col.darkened(0.3), 1.8, true)
		ci.draw_arc(Vector2(w * 0.45, y + 4), w * 0.55, 0.2, PI - 0.2, 8, col.darkened(0.3), 1.8, true)
	var leaf := Art.poly([2, -26, 16, -34, 22, -28, 12, -24])
	Art.shape(ci, leaf, Color("5fae2a"), 2.0, 0.4)
	Art.eyes(ci, Vector2(0, -6), 12, 4.0, true)
	Art.mouth_line(ci, Vector2(0, 6), 4, 2)


# ================================================================ Ústecký

static func _havir(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 26, 8, Color("3a2a1a"), 5.0)
	# krumpáč přes rameno
	Art.stick(ci, Vector2(-16, 14), Vector2(8, -30), Color("9a5b2a"), 4.0, 2.0)
	var pick := Art.poly([-6, -30, 10, -40, 26, -34, 12, -32, 4, -26])
	Art.shape(ci, pick, Color("9aa3ad"), 2.0, 0.5)
	# montérky
	Art.shape(ci, Art.rrect(Rect2(-15, -4, 30, 28), 9), Color("2f4f8f"), 3.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-9, -2, 18, 10), 3), Color("3c63ad"))
	Art.blob(ci, Vector2(0, -16), 14, 13, Color("e3a983"), 3.0)
	# šmouhy uhlí
	Art.safe_poly(ci, Art.ellipse(Vector2(-7, -10), 4, 2.5, 10), Color(0.2, 0.2, 0.2, 0.45))
	Art.safe_poly(ci, Art.ellipse(Vector2(8, -8), 3, 2, 10), Color(0.2, 0.2, 0.2, 0.45))
	Art.eyes(ci, Vector2(0, -17), 11, 3.3, true)
	Art.mouth_line(ci, Vector2(0, -8), 4, -2)
	# helma s lampou
	var helm := Art.arc_pts(Vector2(0, -22), 15, PI, TAU, 14)
	helm.append(Vector2(17, -21))
	helm.append(Vector2(-17, -21))
	Art.shape(ci, helm, Color("ffd23f"), 2.5)
	Art.circle(ci, Vector2(0, -31), 4.5, Color("fff6c8"), 2.0)
	Art.safe_poly(ci, PackedVector2Array([Vector2(-3, -34), Vector2(3, -34), Vector2(10, -38), Vector2(-10, -38)]), Color(1, 1, 0.7, 0.35))


static func _uhli(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 40, 16, Color("2b2b2b"), 8.0)
	for s: int in [-1, 1]:
		_arm(ci, Vector2(s * 26, -2), Vector2(s * 40, 14 + (t - 0.5) * 6 * s), Color("3a3a3a"), 11.0)
	var body := Art.poly([-30, -30, -8, -42, 18, -36, 34, -16, 32, 18, 14, 34, -14, 34, -34, 14])
	Art.shape(ci, body, Color("3b3b3f"), 3.5)
	# žhnoucí praskliny
	for cr in [[-20, -20, -8, -4, -14, 8], [10, -28, 4, -14, 16, -4], [-4, 14, 8, 22, 18, 16]]:
		var pts := PackedVector2Array([Vector2(cr[0], cr[1]), Vector2(cr[2], cr[3]), Vector2(cr[4], cr[5])])
		ci.draw_polyline(pts, Color("ff7a1a"), 3.5, true)
		ci.draw_polyline(pts, Color("ffd23f"), 1.4, true)
	for f in [[-16, -32, 9], [12, -34, 7], [26, 0, 8]]:
		Art.safe_poly(ci, Art.ellipse(Vector2(f[0], f[1]), f[2], f[2] * 0.5, 8, 0.4), Color(1, 1, 1, 0.12))
	Art.eyes(ci, Vector2(0, -12), 20, 5.0, true, Vector2(0.1, 0.2), Color("ffb347"))
	Art.mouth_grin(ci, Vector2(0, 4), 10, 7)


static func _dynamit(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 26, 7, Color("6b3e1c"), 4.5)
	var body := Art.rrect(Rect2(-12, -24, 24, 48), 7)
	Art.shape(ci, body, Color("e2382c"), 3.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-12, -4, 24, 10), 2), Color("f6e7c4"))
	ci.draw_string(Art.font, Vector2(-9, 4), "TNT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Art.OUTLINE)
	# zápalná šňůra a jiskra
	var fuse := PackedVector2Array([Vector2(0, -24), Vector2(4, -30), Vector2(2, -35), Vector2(7, -38)])
	ci.draw_polyline(fuse, Art.OUTLINE, 4.0, true)
	ci.draw_polyline(fuse, Color("c9a06a"), 2.0, true)
	var sp := 9.0 if t > 0.5 else 7.0
	Art.shape(ci, Art.star(Vector2(8, -39), sp, sp * 0.4, 6), Color("ffe14a"), 2.0, 0.3)
	Art.eyes(ci, Vector2(0, -14), 12, 3.8, false, Vector2(0, -0.3))
	Art.mouth_grin(ci, Vector2(0, 12), 4, 4, false)


# ================================================================ Liberecký

static func _banka(ci: CanvasItem, t: float) -> void:
	# skleněná baňka s fialovou tekutinou
	var neck := Art.rrect(Rect2(-7, -36, 14, 22), 4)
	Art.shape(ci, neck, Color("bff3ff"), 3.0, 0.3)
	Art.flat(ci, Art.rrect(Rect2(-8, -40, 16, 7), 3), Color("b07a45"), 2.5)
	var body := Art.ellipse(Vector2(0, 8), 25, 24, 36)
	Art.outline(ci, body, 3.0)
	Art.safe_poly(ci, body, Color("d8f8ff"))
	var liquid := PackedVector2Array()
	var wave := 2.0 if t > 0.5 else -2.0
	for i in 21:
		var a := PI * i / 20.0
		liquid.append(Vector2(cos(a) * 23, 8 + sin(a) * 22))
	liquid.append(Vector2(-22, 2 - wave))
	liquid.append(Vector2(0, 2 + wave))
	liquid.append(Vector2(22, 2 - wave))
	Art.grad(ci, liquid, Color("d36cff"), Color("7a2ab8"))
	for b in [[-8, 14, 3], [6, 20, 2], [10, 8, 2.5]]:
		ci.draw_arc(Vector2(b[0], b[1]), b[2], 0, TAU, 10, Color(1, 1, 1, 0.6), 1.5, true)
	Art.shine(ci, Vector2(-12, -2), 5, 9, 0.6, 0.3)
	Art.eyes(ci, Vector2(2, 10), 14, 4.2, true)


static func _brouk(ci: CanvasItem, t: float) -> void:
	var st := 3.0 if t > 0.5 else -3.0
	for i in 3:
		var y := -6.0 + i * 9.0
		for s: int in [-1, 1]:
			Art.stick(ci, Vector2(s * 10, y), Vector2(s * 24, y + 6 + st * s * (1 if i % 2 == 0 else -1)), Color("3a2a1a"), 3.0, 1.5)
	for s: int in [-1, 1]:
		ci.draw_line(Vector2(s * 4, -22), Vector2(s * 12, -34), Art.OUTLINE, 2.5, true)
		Art.circle(ci, Vector2(s * 12, -34), 2.5, Color("ffd23f"), 1.5)
	Art.blob(ci, Vector2(0, -18), 10, 8, Color("2b2b3f"), 2.5)
	var shell := Art.ellipse(Vector2(0, 4), 18, 20, 30)
	Art.shape(ci, shell, Color("e0245e"), 3.0)
	# broušené kamínky
	for g in [[-7, -2, "ff5c8a"], [7, -2, "ff5c8a"], [0, 10, "ffb3cc"], [-8, 14, "c2185b"], [8, 14, "c2185b"]]:
		var d := Art.poly([0, -5, 4, 0, 0, 5, -4, 0])
		Art.safe_poly(ci, Art.xform(d, Vector2(g[0], g[1])), Color(g[2]))
	ci.draw_line(Vector2(0, -15), Vector2(0, 23), Art.OUTLINE, 2.0, true)
	Art.eyes(ci, Vector2(0, -19), 9, 2.8, true, Vector2(0, 0.3))


static func _sklar(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 28, 8, Color("3a2a1a"), 5.0)
	Art.shape(ci, Art.rrect(Rect2(-16, -6, 32, 32), 10), Color("e9e3d3"), 3.0)
	Art.shape(ci, Art.poly([-12, 0, 12, 0, 14, 26, -14, 26]), Color("8a5a32"), 2.5, 0.5)
	Art.blob(ci, Vector2(0, -18), 14, 13, Color("f2b98a"), 3.0)
	Art.eyes(ci, Vector2(0, -20), 11, 3.3, true)
	Art.blob(ci, Vector2(3, -12), 3, 2.5, Color("e8a07a"), 1.5, 0.3)
	# foukací píšťala se žhavou baňkou
	Art.stick(ci, Vector2(6, -8), Vector2(28, -16), Color("6c7580"), 3.5, 2.0)
	var glow := 9.0 if t > 0.5 else 8.0
	Art.blob(ci, Vector2(32, -18), glow, glow, Color("ffae3a"), 2.5)
	Art.shine(ci, Vector2(30, -21), 3, 2, 0.8)
	Art.blob(ci, Vector2(0, -30), 13, 4, Color("3a3a5a"), 2.5, 0.4)


# ================================================================ Královéhradecký

static func _koule(ci: CanvasItem, t: float) -> void:
	var rot := 0.4 if t > 0.5 else 0.0
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var r := 22.0 + sin(a * 7 + rot * 5) * 1.5
		pts.append(Vector2(cos(a) * r, sin(a) * r + 2))
	Art.shape(ci, pts, Color("f2f7ff"), 3.0)
	for d in [[-10, -8], [12, 6], [-4, 14], [10, -12]]:
		Art.safe_poly(ci, Art.ellipse(Vector2(d[0], d[1]).rotated(rot), 3.5, 2.5, 10), Color("c9d9ef"))
	Art.stick(ci, Vector2(-18, -10), Vector2(-28, -18), Color("6b3e1c"), 2.5, 1.5)
	Art.eyes(ci, Vector2(0, -2), 14, 4.2, true)
	Art.mouth_grin(ci, Vector2(0, 8), 6, 5)


static func _snehulak(ci: CanvasItem, t: float) -> void:
	Art.blob(ci, Vector2(0, 22), 34, 28, Color("f4f8ff"), 3.5)
	for i in 3:
		Art.circle(ci, Vector2(0, 8 + i * 11), 3.5, Color("2b2b2b"), 1.5)
	# ruce z větví
	for s: int in [-1, 1]:
		var b := Vector2(s * 46, -6 + (t - 0.5) * 8 * s)
		Art.stick(ci, Vector2(s * 26, 2), b, Color("6b3e1c"), 3.5, 2.0)
		Art.stick(ci, b.lerp(Vector2(s * 26, 2), 0.3), b + Vector2(s * 2, -10), Color("6b3e1c"), 2.5, 1.5)
	Art.blob(ci, Vector2(0, -18), 23, 21, Color("f4f8ff"), 3.5)
	# šála
	Art.shape(ci, Art.rrect(Rect2(-22, -4, 44, 9), 4), Color("e2382c"), 2.5, 0.5)
	Art.shape(ci, Art.rrect(Rect2(8, 0, 9, 20), 3), Color("e2382c"), 2.5, 0.5)
	# uhlíkové oči a mrkev
	for s: int in [-1, 1]:
		Art.circle(ci, Vector2(s * 8, -22), 4, Color("1a1a1a"), 1.0)
		ci.draw_line(Vector2(s * 14, -31), Vector2(s * 3, -27), Art.OUTLINE, 3.0, true)
	var nose := Art.poly([0, -18, 22, -14, 0, -12])
	Art.shape(ci, nose, Color("ff8a1a"), 2.0, 0.4)
	for i in 4:
		Art.circle(ci, Vector2(-8 + i * 5, -6 + absf(i - 1.5) * -1.5), 1.6, Color("1a1a1a"), 0.0)
	# kyblík
	var bucket := Art.poly([-15, -36, 15, -36, 12, -54, -12, -54])
	Art.shape(ci, bucket, Color("6f8fb3"), 3.0)
	Art.flat(ci, Art.rrect(Rect2(-18, -38, 36, 5), 2), Color("4a6a8f"), 2.0)


static func _skritek(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 26, 7, Color("6b3e1c"), 5.0)
	Art.shape(ci, Art.rrect(Rect2(-14, -2, 28, 26), 10), Color("2f6ad1"), 3.0)
	Art.blob(ci, Vector2(0, -12), 13, 12, Color("f5c39a"), 3.0)
	var beard := Art.poly([-11, -10, 11, -10, 8, 6, 0, 12, -8, 6])
	Art.shape(ci, beard, Color("f4f4f4"), 2.5, 0.4)
	Art.eyes(ci, Vector2(0, -15), 10, 3.0, true)
	Art.blob(ci, Vector2(0, -9), 3.5, 3, Color("ff9a8a"), 1.5, 0.3)
	var hat := Art.poly([-14, -18, 14, -18, 6, -32, 14, -44, 0, -36, -6, -30])
	Art.shape(ci, hat, Color("e2382c"), 3.0)
	# sněhová koule v ruce
	Art.blob(ci, Vector2(20, 0), 7, 7, Color("f4f8ff"), 2.5)
	Art.circle(ci, Vector2(14, 6), 4.5, Color("f5c39a"), 2.0)


# ================================================================ Pardubický

static func _pernicek(ci: CanvasItem, t: float) -> void:
	var st := 3.0 if t > 0.5 else -3.0
	var col := Color("b86b2c")
	var pts := PackedVector2Array()
	pts.append_array(Art.arc_pts(Vector2(0, -18), 13, PI * 0.75, PI * 2.25, 14))
	pts.append_array(Art.poly([12, -6, 24, -4 + st, 24, 6 + st, 12, 6, 12, 14, 18 + st, 30, 6 + st, 32, 0, 20, -6 - st, 32, -18 - st, 30, -12, 14, -12, 6, -24, 6 - st, -24, -4 - st, -12, -6]))
	Art.shape(ci, pts, col, 3.0)
	# poleva
	ci.draw_arc(Vector2(0, -18), 9.5, 0.3, PI - 0.3, 10, Color("fff6e6"), 2.0, true)
	for s: int in [-1, 1]:
		ci.draw_polyline(PackedVector2Array([Vector2(s * 16, -4), Vector2(s * 19, 0), Vector2(s * 22, -4)]), Color("fff6e6"), 2.0, true)
	for i in 2:
		Art.circle(ci, Vector2(0, 2 + i * 8), 2.6, Color("ff4d6d"), 1.5)
	Art.eyes(ci, Vector2(0, -20), 9, 3.0, true)


static func _kun(ci: CanvasItem, t: float) -> void:
	var st := 4.0 if t > 0.5 else -4.0
	var col := Color("8a4a1c")
	for lx in [-22, -12, 12, 22]:
		var o: float = st if (lx < 0) else -st
		Art.stick(ci, Vector2(lx, 8), Vector2(lx + o, 32), col.darkened(0.15), 6.0, 2.0)
		Art.blob(ci, Vector2(lx + o, 33), 4.5, 3, Color("2b2b2b"), 1.5, 0.2)
	# ocas
	var tail := Art.poly([-30, -6, -42, 0, -40, 16, -32, 6])
	Art.shape(ci, tail, Color("3a2412"), 2.5, 0.4)
	Art.shape(ci, Art.ellipse(Vector2(0, 0), 32, 15, 30), col, 3.0)
	# sedlo s číslem
	Art.shape(ci, Art.rrect(Rect2(-12, -15, 22, 16), 4), Color("e2382c"), 2.5, 0.4)
	ci.draw_string(Art.font, Vector2(-5, -2), "7", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	# krk a hlava
	var neck := Art.poly([18, -8, 30, -30, 40, -26, 32, 2])
	Art.shape(ci, neck, col, 3.0, 0.6)
	var head := Art.poly([28, -36, 42, -38, 50, -24, 46, -18, 34, -22])
	Art.shape(ci, head, col, 3.0, 0.6)
	var mane := Art.poly([20, -8, 26, -32, 32, -40, 30, -26, 26, -10])
	Art.shape(ci, mane, Color("3a2412"), 2.0, 0.3)
	Art.circle(ci, Vector2(37, -31), 3.2, Color.WHITE, 2.0)
	Art.circle(ci, Vector2(38, -31), 1.6, Art.OUTLINE, 0.0)
	ci.draw_line(Vector2(33, -36), Vector2(41, -34), Art.OUTLINE, 2.5, true)
	Art.circle(ci, Vector2(47, -22), 1.6, Art.OUTLINE, 0.0)


static func _semtex(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 24, 8, Color("3a3a3a"), 4.5)
	var body := Art.rrect(Rect2(-20, -18, 40, 38), 9)
	Art.shape(ci, body, Color("f08a24"), 3.0)
	# dráty
	ci.draw_polyline(PackedVector2Array([Vector2(-14, -16), Vector2(-20, -26), Vector2(-8, -30), Vector2(-2, -16)]), Color("e2382c"), 2.5, true)
	ci.draw_polyline(PackedVector2Array([Vector2(14, -16), Vector2(22, -24), Vector2(10, -30), Vector2(4, -16)]), Color("2f6ad1"), 2.5, true)
	# časovač
	Art.flat(ci, Art.rrect(Rect2(-12, 4, 24, 12), 3), Color("1a1a1a"), 2.0)
	var txt := "0:03" if t > 0.5 else "0:02"
	ci.draw_string(Art.font, Vector2(-10, 14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ff3b2d"))
	Art.eyes(ci, Vector2(0, -6), 14, 4.0, true)


# ================================================================ Středočeský

static func _kostlivec(ci: CanvasItem, t: float) -> void:
	var st := 3.0 if t > 0.5 else -3.0
	var bone := Color("efe9d8")
	for s: int in [-1, 1]:
		Art.stick(ci, Vector2(s * 6, 12), Vector2(s * 8 + st * s, 30), bone, 4.5, 2.0)
		Art.blob(ci, Vector2(s * 9 + st * s + 2, 31), 5, 3, bone, 2.0, 0.3)
		Art.stick(ci, Vector2(s * 12, -6), Vector2(s * 20, 10 - st * s), bone, 4.0, 2.0)
	# hrudník a žebra
	Art.stick(ci, Vector2(0, -8), Vector2(0, 14), bone, 4.5, 2.0)
	for i in 3:
		var y := -4.0 + i * 6.0
		ci.draw_arc(Vector2(0, y + 4), 11 - i, PI * 1.1, PI * 1.9, 10, Art.OUTLINE, 5.0, true)
		ci.draw_arc(Vector2(0, y + 4), 11 - i, PI * 1.1, PI * 1.9, 10, bone, 2.6, true)
	Art.blob(ci, Vector2(0, 14), 9, 4, bone, 2.0, 0.3)
	# lebka
	Art.blob(ci, Vector2(0, -20), 14, 13, bone, 3.0)
	Art.flat(ci, Art.rrect(Rect2(-8, -12, 16, 7), 3), bone, 2.0)
	for s: int in [-1, 1]:
		Art.circle(ci, Vector2(s * 5.5, -21), 4.2, Color("1a1208"), 0.0)
		Art.circle(ci, Vector2(s * 5.5, -21), 1.6, Color("7dff8a"), 0.0)
	for i in 3:
		ci.draw_line(Vector2(-4 + i * 4, -12), Vector2(-4 + i * 4, -6), Art.OUTLINE, 1.2, true)


static func _rytir(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 42, 14, Color("6c7580"), 8.0)
	var steel := Color("b8c3cf")
	Art.shape(ci, Art.rrect(Rect2(-24, -10, 48, 46), 14), steel, 3.5)
	Art.safe_poly(ci, Art.rrect(Rect2(-24, 14, 48, 7), 2), Color("6b3e1c"))
	# meč
	Art.stick(ci, Vector2(30, 10), Vector2(40, -36), Color("eef3f7"), 6.0, 2.5)
	Art.stick(ci, Vector2(22, 12), Vector2(36, 8), Art.GOLD, 4.0, 2.0)
	_arm(ci, Vector2(18, -2), Vector2(30, 12), steel, 10.0)
	# helma
	var helm := Art.rrect(Rect2(-20, -50, 40, 42), 14)
	Art.shape(ci, helm, steel, 3.5)
	Art.flat(ci, Art.rrect(Rect2(-14, -34, 28, 6), 2), Color("1a1a1a"), 1.5)
	for s: int in [-1, 1]:
		Art.circle(ci, Vector2(s * 7, -31), 2.2, Color("ff4d2a"), 0.0)
	ci.draw_line(Vector2(0, -50), Vector2(0, -12), Color("8d97a3"), 2.0, true)
	var plume := Art.poly([-4, -50, 0, -66, 14, -70, 18, -62, 6, -56, 4, -50])
	Art.shape(ci, plume, Color("e2382c"), 2.5)
	# štít
	var shield := Art.poly([-44, -14, -14, -14, -14, 10, -29, 26, -44, 10])
	Art.shape(ci, shield, Color("d7262c"), 3.0)
	Art.safe_poly(ci, Art.star(Vector2(-29, 2), 8, 3.5), Color("f6f6f6"))


static func _lucistnik(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 26, 8, Color("5a3a22"), 5.0)
	Art.shape(ci, Art.rrect(Rect2(-15, -4, 30, 28), 10), Color("3f8a3a"), 3.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-15, 8, 30, 5), 2), Color("6b3e1c"))
	# kapuce
	var hood := Art.poly([-17, -6, -15, -28, 0, -38, 15, -28, 17, -6])
	Art.shape(ci, hood, Color("2f6e2a"), 3.0)
	Art.blob(ci, Vector2(1, -16), 11, 10, Color("e9b08a"), 2.0, 0.6)
	Art.eyes(ci, Vector2(2, -17), 9, 2.8, true, Vector2(0.5, 0))
	# luk
	ci.draw_arc(Vector2(18, -4), 20, -PI * 0.42, PI * 0.42, 14, Art.OUTLINE, 6.0, true)
	ci.draw_arc(Vector2(18, -4), 20, -PI * 0.42, PI * 0.42, 14, Color("9a5b2a"), 3.0, true)
	var ta := Vector2(18, -4) + Vector2(cos(-PI * 0.42), sin(-PI * 0.42)) * 20
	var tb := Vector2(18, -4) + Vector2(cos(PI * 0.42), sin(PI * 0.42)) * 20
	ci.draw_line(ta, tb, Color("f4f4f4"), 1.2, true)
	Art.circle(ci, Vector2(16, -4), 4.5, Color("e9b08a"), 2.0)


# ================================================================ Praha

static func _turista(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 28, 8, Color("f4f4f4"), 5.0)
	# kraťasy a havajská košile
	Art.shape(ci, Art.rrect(Rect2(-14, 12, 28, 12), 4), Color("c9a87a"), 2.5, 0.5)
	Art.shape(ci, Art.rrect(Rect2(-16, -6, 32, 22), 10), Color("1fb5c9"), 3.0)
	for f in [[-8, 0], [6, 4], [-2, 12], [10, -2]]:
		Art.safe_poly(ci, Art.star(Vector2(f[0], f[1]), 4, 2, 5), Color("ffd23f"))
	Art.blob(ci, Vector2(0, -18), 14, 13, Color("ffad8a"), 3.0)
	# sluneční brýle
	for s: int in [-1, 1]:
		Art.flat(ci, Art.ellipse(Vector2(s * 6, -19), 5.5, 4, 12), Color("1a1a1a"), 1.5)
		Art.shine(ci, Vector2(s * 6 - 1.5, -20.5), 2, 1, 0.6)
	ci.draw_line(Vector2(-1, -19), Vector2(1, -19), Color("1a1a1a"), 2.0)
	Art.mouth_grin(ci, Vector2(0, -10), 5, 4)
	# klobouček
	Art.shape(ci, Art.ellipse(Vector2(0, -28), 18, 5, 20), Color("f2e2b0"), 2.5, 0.5)
	Art.shape(ci, Art.arc_pts(Vector2(0, -28), 11, PI, TAU, 10), Color("f2e2b0"), 2.5, 0.5)
	# selfie tyč s mobilem
	Art.stick(ci, Vector2(14, 0), Vector2(30, -30), Color("2b2b2b"), 2.5, 1.5)
	Art.flat(ci, Art.rrect(Rect2(25, -40, 10, 14), 2), Color("2b2b3f"), 2.0)
	Art.safe_poly(ci, Art.rrect(Rect2(27, -38, 6, 10), 1), Color("6fd0ff"))


static func _holub(ci: CanvasItem, t: float) -> void:
	var st := 2.0 if t > 0.5 else -2.0
	for s: int in [-1, 1]:
		Art.stick(ci, Vector2(s * 5, 12), Vector2(s * 6 + st * s, 24), Color("ff7a6a"), 3.0, 1.5)
	var tail := Art.poly([-14, 4, -28, 10, -26, 16, -12, 12])
	Art.shape(ci, tail, Color("6c7580"), 2.5, 0.4)
	Art.shape(ci, Art.ellipse(Vector2(-2, 4), 18, 13, 28), Color("9aa3ad"), 3.0)
	var wing := Art.poly([-14, -2, 6, -4, 10, 6, -10, 12])
	Art.shape(ci, wing, Color("7d858c"), 2.5, 0.5)
	for i in 2:
		ci.draw_line(Vector2(-6 + i * 6, 2), Vector2(-2 + i * 6, 10), Color("4a5058"), 2.0, true)
	# duhový krk a hlava
	Art.shape(ci, Art.ellipse(Vector2(10, -8), 9, 10, 20), Color("4fa88a"), 2.5, 0.6)
	Art.safe_poly(ci, Art.ellipse(Vector2(9, -5), 6, 4, 12), Color("a05ad0"))
	Art.blob(ci, Vector2(13, -18), 9, 8, Color("8d97a3"), 2.5)
	Art.circle(ci, Vector2(16, -20), 3.2, Color("ff8a1a"), 1.5)
	Art.circle(ci, Vector2(16.5, -20), 1.4, Art.OUTLINE, 0.0)
	var beak := Art.poly([20, -19, 28, -16, 20, -14])
	Art.shape(ci, beak, Color("4a4a4a"), 1.5, 0.2)
	Art.circle(ci, Vector2(20, -19), 2, Color("f4f4f4"), 0.0)


static func _golem(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 42, 16, Color("8a4a2a"), 9.0)
	var clay := Color("b8673a")
	for s: int in [-1, 1]:
		_arm(ci, Vector2(s * 28, -10), Vector2(s * 40, 16 + (t - 0.5) * 6 * s), clay.darkened(0.1), 13.0)
	var body := Art.poly([-30, -20, 30, -20, 34, 30, -34, 30])
	Art.shape(ci, Art.grow(body, 4), clay, 3.5)
	ci.draw_polyline(PackedVector2Array([Vector2(-14, 0), Vector2(-6, 8), Vector2(-12, 16)]), clay.darkened(0.35), 2.0, true)
	ci.draw_polyline(PackedVector2Array([Vector2(16, 4), Vector2(10, 14)]), clay.darkened(0.35), 2.0, true)
	var head := Art.rrect(Rect2(-20, -54, 40, 36), 10)
	Art.shape(ci, head, clay, 3.5)
	# šém na čele (svitek se znaky)
	Art.flat(ci, Art.rrect(Rect2(-11, -52, 22, 9), 2), Color("f6e7c4"), 1.5)
	for i in 3:
		ci.draw_line(Vector2(-7 + i * 7, -50), Vector2(-5 + i * 7, -45), Art.OUTLINE, 1.5, true)
	Art.eyes(ci, Vector2(0, -36), 18, 4.8, true, Vector2(0, 0.2), Color("ffe9a8"))
	Art.mouth_line(ci, Vector2(0, -25), 8, -2)


# ================================================================ Jihočeský

static func _kapr(ci: CanvasItem, t: float) -> void:
	var flop := 0.15 if t > 0.5 else -0.15
	var col := Color("c9a03a")
	var body := Art.ellipse(Vector2(0, 0), 24, 15, 32, flop)
	var tail := Art.xform(Art.poly([-20, 0, -34, -14, -30, 0, -34, 14]), Vector2.ZERO, Vector2.ONE, flop)
	Art.shape(ci, tail, Color("b5822a"), 2.5, 0.4)
	var fin := Art.xform(Art.poly([-6, -12, 6, -22, 10, -12]), Vector2.ZERO, Vector2.ONE, flop)
	Art.shape(ci, fin, Color("b5822a"), 2.5, 0.4)
	Art.shape(ci, body, col, 3.0)
	for i in 3:
		for j in 2:
			var c := Vector2(-10 + i * 7, -3 + j * 7).rotated(flop)
			ci.draw_arc(c, 3.5, PI * 0.2, PI * 0.8, 6, col.darkened(0.3), 1.5, true)
	Art.circle(ci, Vector2(14, -4).rotated(flop), 4.5, Color.WHITE, 2.0)
	Art.circle(ci, Vector2(15, -4).rotated(flop), 2.2, Art.OUTLINE, 0.0)
	ci.draw_line(Vector2(9, -10).rotated(flop), Vector2(18, -8).rotated(flop), Art.OUTLINE, 2.5, true)
	# vousky
	ci.draw_line(Vector2(22, 4).rotated(flop), Vector2(28, 12).rotated(flop), Art.OUTLINE, 1.5, true)
	Art.blob(ci, Vector2(23, 3).rotated(flop), 3.5, 3, Color("e88a6a"), 1.5, 0.2)


static func _rak(ci: CanvasItem, t: float) -> void:
	var col := Color("d4472c")
	var st := 3.0 if t > 0.5 else -3.0
	for i in 3:
		for s: int in [-1, 1]:
			Art.stick(ci, Vector2(s * 16, 6 + i * 8), Vector2(s * 34, 12 + i * 9 + st * s), col.darkened(0.2), 3.0, 1.5)
	# ocas
	for i in 3:
		Art.shape(ci, Art.rrect(Rect2(-14 + i * 2, 22 + i * 7, 28 - i * 4, 9), 4), col.darkened(0.05 * i), 2.5, 0.4)
	Art.shape(ci, Art.ellipse(Vector2(0, 4), 22, 22, 30), col, 3.5)
	# klepeta
	for s: int in [-1, 1]:
		Art.stick(ci, Vector2(s * 16, -6), Vector2(s * 30, -24), col, 6.0, 2.5)
		var claw := Art.poly([0, 0, 10, -10, 18, -6, 12, 0, 18, 6, 10, 10])
		Art.shape(ci, Art.xform(claw, Vector2(s * 30, -28), Vector2(s * 1.4, 1.4), -0.9 * s), col.lightened(0.05), 3.0)
	for s: int in [-1, 1]:
		ci.draw_line(Vector2(s * 6, -14), Vector2(s * 20, -46), Art.OUTLINE, 2.0, true)
	Art.eyes(ci, Vector2(0, -10), 14, 4.5, true)


static func _vodnik(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 26, 8, Color("2f6e2a"), 5.0)
	# zelený frak s kapajícím šosem
	var coat := Art.poly([-16, -6, 16, -6, 18, 22, 8, 26, 0, 20, -8, 26, -18, 22])
	Art.shape(ci, coat, Color("3fa84a"), 3.0)
	Art.safe_poly(ci, Art.poly([-3, -6, 3, -6, 2, 14, -2, 14]), Color("e2382c"))
	var drip := 30.0 if t > 0.5 else 28.0
	Art.shape(ci, Art.poly([8, 24, 10, drip, 6, drip]), Color("6fd0ff"), 1.5, 0.3)
	Art.blob(ci, Vector2(0, -16), 15, 13, Color("8fd66a"), 3.0)
	Art.eyes(ci, Vector2(0, -18), 12, 3.8, true, Vector2(0.2, 0.3), Color("fffbe0"))
	Art.mouth_grin(ci, Vector2(0, -9), 6, 4, false)
	# cylindr
	Art.shape(ci, Art.ellipse(Vector2(0, -27), 17, 4, 18), Color("2b4a2b"), 2.5, 0.3)
	Art.shape(ci, Art.rrect(Rect2(-10, -46, 20, 20), 3), Color("2b4a2b"), 2.5)
	Art.safe_poly(ci, Art.rrect(Rect2(-10, -32, 20, 4), 1), Color("e2382c"))
	# kapka v ruce
	Art.circle(ci, Vector2(20, 2), 4.5, Color("8fd66a"), 2.0)
	Art.shape(ci, Art.poly([20, -14, 26, -4, 20, 0, 14, -4]), Color("6fd0ff"), 2.0)


# ================================================================ Vysočina

static func _brambora(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 22, 9, Color("8a5a2a"), 5.0)
	var pts := PackedVector2Array()
	for i in 36:
		var a := TAU * i / 36.0
		var r := 20.0 + sin(a * 3 + 1) * 3 + cos(a * 5) * 1.5
		pts.append(Vector2(cos(a) * r * 1.05, sin(a) * r * 0.9))
	Art.shape(ci, pts, Color("c9935a"), 3.0)
	for d in [[-12, 8], [10, 10], [12, -10], [-6, -14], [2, 14]]:
		Art.safe_poly(ci, Art.ellipse(Vector2(d[0], d[1]), 2, 1.5, 8), Color("8a5a2a"))
	# klíček
	Art.stick(ci, Vector2(-8, -16), Vector2(-14, -26), Color("c8e86a"), 2.5, 1.5)
	Art.eyes(ci, Vector2(1, -3), 13, 4.0, true)
	Art.mouth_line(ci, Vector2(1, 7), 5, -2)


static func _divocak(ci: CanvasItem, t: float) -> void:
	var st := 4.0 if t > 0.5 else -4.0
	var col := Color("5a4334")
	for lx in [-18, -8, 10, 20]:
		var o: float = st if lx < 0 else -st
		Art.stick(ci, Vector2(lx, 8), Vector2(lx + o, 26), col.darkened(0.2), 6.0, 2.0)
	var body := Art.ellipse(Vector2(-2, 0), 28, 18, 30)
	Art.shape(ci, body, col, 3.5)
	# štětiny
	for i in 6:
		var x := -18.0 + i * 6.0
		ci.draw_line(Vector2(x, -16 + absf(i - 2.5)), Vector2(x - 2, -24 + absf(i - 2.5) * 1.5), Art.OUTLINE, 3.0, true)
	var head := Art.poly([14, -14, 34, -8, 40, 4, 30, 12, 14, 10])
	Art.shape(ci, head, col.lightened(0.05), 3.0)
	Art.blob(ci, Vector2(40, 2), 6, 6, Color("e08a8a"), 2.5, 0.4)
	for s: int in [-1, 1]:
		Art.circle(ci, Vector2(40 + s * 2, 2), 1.2, Art.OUTLINE, 0.0)
	var tusk := Art.poly([32, 8, 38, 0, 36, 10])
	Art.shape(ci, tusk, Color("fff6e0"), 2.0, 0.3)
	Art.circle(ci, Vector2(26, -6), 3.2, Color("ff4d2a"), 2.0)
	ci.draw_line(Vector2(21, -12), Vector2(30, -8), Art.OUTLINE, 2.5, true)
	var ear := Art.poly([18, -14, 20, -24, 26, -14])
	Art.shape(ci, ear, col, 2.0, 0.3)


static func _muchomurka(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 26, 7, Color("e9e3d3"), 4.5)
	var stem := Art.poly([-9, -4, 9, -4, 11, 24, -11, 24])
	Art.shape(ci, Art.grow(stem, 2), Color("f6f2e6"), 3.0)
	Art.shape(ci, Art.ellipse(Vector2(0, 2), 13, 4, 18), Color("f6f2e6"), 2.0, 0.3)
	var cap := Art.arc_pts(Vector2(0, -4), 26, PI, TAU, 24)
	cap.append(Vector2(26, -2))
	cap.append(Vector2(-26, -2))
	var pul := 1.0 if t > 0.5 else 0.0
	Art.shape(ci, Art.xform(cap, Vector2.ZERO, Vector2(1.0 + pul * 0.05, 1.0)), Color("e8262c"), 3.0)
	for d in [[-14, -12, 4], [0, -22, 4.5], [14, -12, 4], [-6, -6, 2.5], [8, -6, 2.5]]:
		Art.safe_poly(ci, Art.ellipse(Vector2(d[0], d[1]), d[2], d[2] * 0.8, 12), Color("fff6f0"))
	Art.eyes(ci, Vector2(0, 8), 10, 3.2, true)
	Art.mouth_grin(ci, Vector2(0, 15), 4, 3, false)


# ================================================================ Jihomoravský

static func _hrozen(ci: CanvasItem, t: float) -> void:
	var wob := 1.0 if t > 0.5 else -1.0
	var col := Color("7a3ab8")
	var berries := [[-14, -14], [0, -16], [14, -14], [-8, -2], [8, -2], [-16, 2], [16, 2], [0, 10], [-8, 18], [8, 18], [0, 28]]
	for b in berries:
		Art.blob(ci, Vector2(b[0] + wob * (1 if int(b[1]) % 2 == 0 else -1), b[1]), 9, 9, col, 2.5, 0.8)
	Art.stick(ci, Vector2(0, -24), Vector2(2, -34), Color("6b3e1c"), 3.0, 1.5)
	var leaf := Art.poly([2, -30, 14, -40, 26, -34, 20, -26, 10, -26])
	Art.shape(ci, leaf, Color("5fae2a"), 2.5, 0.5)
	Art.eyes(ci, Vector2(0, -2), 13, 4.0, true)
	Art.mouth_grin(ci, Vector2(0, 8), 4, 3, false)


static func _netopyr(ci: CanvasItem, t: float) -> void:
	var flap := 8.0 if t > 0.5 else -6.0
	var col := Color("4a2a6a")
	for s: int in [-1, 1]:
		var wing := Art.poly([0, -4, 14, -14 - flap, 30, -10 - flap, 32, 4 - flap * 0.5, 24, 0, 18, 8, 10, 2])
		Art.shape(ci, Art.xform(wing, Vector2.ZERO, Vector2(s, 1)), col.lightened(0.1), 2.5, 0.5)
	Art.blob(ci, Vector2(0, 0), 11, 12, col, 3.0)
	for s: int in [-1, 1]:
		Art.shape(ci, Art.poly([s * 4, -10, s * 10, -22, s * 10, -8]), col, 2.0, 0.3)
	Art.eyes(ci, Vector2(0, -2), 9, 3.0, true, Vector2(0, 0.2), Color("ffe14a"))
	for s: int in [-1, 1]:
		Art.safe_poly(ci, Art.poly([s * 2, 5, s * 4, 10, s * 5, 5]), Color.WHITE)


static func _vinar(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 26, 8, Color("3a2a1a"), 5.0)
	Art.shape(ci, Art.rrect(Rect2(-15, -6, 30, 30), 10), Color("f4f4f4"), 3.0)
	# modrotisková zástěra
	var apron := Art.poly([-12, 0, 12, 0, 13, 26, -13, 26])
	Art.shape(ci, apron, Color("1f4fa8"), 2.5, 0.4)
	for d in [[-6, 8], [5, 12], [-3, 19], [7, 21]]:
		Art.safe_poly(ci, Art.star(Vector2(d[0], d[1]), 2.5, 1.2, 4), Color("f4f4f4"))
	Art.blob(ci, Vector2(0, -16), 14, 13, Color("f2b98a"), 3.0)
	Art.eyes(ci, Vector2(0, -19), 11, 3.2, true)
	Art.blob(ci, Vector2(1, -11), 4, 3.5, Color("e2504a"), 1.5, 0.4)
	# slaměný klobouk
	Art.shape(ci, Art.ellipse(Vector2(0, -27), 20, 5, 20), Color("f2d27a"), 2.5, 0.5)
	Art.shape(ci, Art.arc_pts(Vector2(0, -27), 11, PI, TAU, 10), Color("f2d27a"), 2.5, 0.5)
	Art.safe_poly(ci, Art.rrect(Rect2(-11, -31, 22, 3), 1), Color("e2382c"))
	# sklenka vína
	Art.stick(ci, Vector2(21, 2), Vector2(21, 10), Color("e0f4ff"), 1.5, 1.5)
	Art.shape(ci, Art.poly([15, -10, 27, -10, 25, -1, 17, -1]), Color("e0f4ff"), 2.0, 0.2)
	Art.safe_poly(ci, Art.poly([16, -6, 26, -6, 25, -1, 17, -1]), Color("9a1f4a"))


# ================================================================ Olomoucký

static func _tvaruzek(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 24, 9, Color("c98a2a"), 4.5)
	var col := Color("f2b632")
	for i in 2:
		var y := 12.0 - i * 16.0
		Art.shape(ci, Art.rrect(Rect2(-20, y - 7, 40, 14), 7), col.lerp(Color("e89a2a"), i * 0.3), 3.0)
		Art.safe_poly(ci, Art.ellipse(Vector2(0, y - 3), 13, 3, 14), Color(1, 1, 1, 0.25))
	# zápach
	var wob := 2.0 if t > 0.5 else -2.0
	for s: int in [-1, 0, 1]:
		var pts := PackedVector2Array()
		for i in 6:
			pts.append(Vector2(s * 10 + sin(i * 1.4 + wob) * 3, -14 - i * 4))
		ci.draw_polyline(pts, Color("9be05a"), 2.5, true)
	Art.eyes(ci, Vector2(0, -4), 14, 3.6, true)
	Art.mouth_grin(ci, Vector2(0, 11), 5, 3, false)


static func _hanak(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 44, 14, Color("1a1a1a"), 8.0)
	# žluté kožené kalhoty
	Art.shape(ci, Art.rrect(Rect2(-22, 16, 44, 26), 8), Color("f2c632"), 3.0)
	Art.shape(ci, Art.ellipse(Vector2(0, 2), 32, 26, 32), Color("f6f6f6"), 3.5)
	# červená vesta
	var vest := Art.poly([-22, -10, -6, -14, -4, 22, -24, 18])
	Art.shape(ci, vest, Color("d7262c"), 2.5, 0.5)
	Art.shape(ci, Art.xform(vest, Vector2.ZERO, Vector2(-1, 1)), Color("d7262c"), 2.5, 0.5)
	for i in 3:
		Art.circle(ci, Vector2(-8, -6 + i * 8), 2, Art.GOLD, 1.0)
	for s: int in [-1, 1]:
		_arm(ci, Vector2(s * 28, -4), Vector2(s * 40, 12 + (t - 0.5) * 6 * s), Color("f6f6f6"), 12.0)
	Art.blob(ci, Vector2(0, -28), 20, 18, Color("f2b98a"), 3.5)
	Art.eyes(ci, Vector2(0, -32), 15, 4.2, true)
	for s: int in [-1, 1]:
		var st := Art.poly([0, -24, s * 18, -22, s * 22, -16, s * 12, -18, 0, -20])
		Art.shape(ci, st, Color("5a3a1a"), 2.0, 0.3)
	# široký klobouk s kytkou
	Art.shape(ci, Art.ellipse(Vector2(0, -44), 30, 7, 24), Color("1a1a1a"), 3.0, 0.3)
	Art.shape(ci, Art.rrect(Rect2(-14, -60, 28, 16), 6), Color("1a1a1a"), 3.0, 0.3)
	Art.safe_poly(ci, Art.rrect(Rect2(-14, -50, 28, 4), 1), Color("d7262c"))
	Art.safe_poly(ci, Art.star(Vector2(10, -52), 5, 2.5, 6), Color("ff8ab3"))


static func _praded(ci: CanvasItem, t: float) -> void:
	var fl := 2.0 if t > 0.5 else -2.0
	var col := Color(0.85, 0.93, 1.0, 0.92)
	var body := Art.poly([-16, -10, 16, -10, 20, 14, 12 + fl, 24, 4, 32, -4 + fl, 26, -14, 30, -20, 14])
	Art.outline(ci, body, 3.0, Color("2a3a5a"))
	Art.grad(ci, body, col, Color(0.6, 0.75, 0.95, 0.85))
	Art.blob(ci, Vector2(0, -18), 14, 13, Color("e8f2ff"), 3.0)
	var beard := Art.poly([-12, -14, 12, -14, 10, 4, 0, 18, -10, 4])
	Art.shape(ci, beard, Color("f6fbff"), 2.5, 0.3)
	Art.eyes(ci, Vector2(0, -20), 11, 3.2, true, Vector2(0, 0.2), Color("dff6ff"))
	# hůl
	Art.stick(ci, Vector2(20, -24), Vector2(22, 24), Color("8a6a4a"), 3.5, 2.0)
	Art.blob(ci, Vector2(20, -28), 6, 6, Color("6fd0ff"), 2.0)
	Art.shape(ci, Art.poly([-15, -24, 0, -40, 15, -24]), Color("cfe0f2"), 2.5, 0.3)


# ================================================================ Zlínský

static func _svestka(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 24, 7, Color("3a1f4a"), 4.5)
	Art.shape(ci, Art.ellipse(Vector2(0, 2), 19, 23, 32), Color("4a3a9a"), 3.0)
	Art.safe_poly(ci, Art.ellipse(Vector2(-4, -2), 12, 15, 24), Color(0.75, 0.75, 1.0, 0.2))
	ci.draw_arc(Vector2(10, 2), 18, PI * 0.6, PI * 1.25, 10, Color("2a1f5a"), 2.0, true)
	Art.stick(ci, Vector2(0, -20), Vector2(4, -30), Color("6b3e1c"), 3.0, 1.5)
	var leaf := Art.poly([4, -28, 16, -36, 24, -30, 14, -24])
	Art.shape(ci, leaf, Color("5fae2a"), 2.0, 0.4)
	Art.eyes(ci, Vector2(0, -2), 12, 3.8, true)
	Art.mouth_line(ci, Vector2(0, 8), 4, -2)


static func _bota(ci: CanvasItem, t: float) -> void:
	var st := 2.0 if t > 0.5 else -2.0
	var col := Color("8a4a1c")
	var shoe := Art.poly([-26, -24, -8, -24, -6, -6, 20, -4, 34, 4, 34, 14, -28, 14])
	Art.shape(ci, Art.xform(shoe, Vector2(0, st)), col, 3.0)
	Art.flat(ci, Art.rrect(Rect2(-30, 12 + st, 66, 8), 3), Color("2b2b2b"), 2.5)
	# tkaničky
	for i in 3:
		var y := -16.0 + i * 6.0 + st
		ci.draw_line(Vector2(-10, y), Vector2(-2, y + 3), Color("f4f4f4"), 2.5, true)
	Art.safe_poly(ci, Art.rrect(Rect2(-26, -26 + st, 18, 5), 2), col.darkened(0.3))
	Art.eyes(ci, Vector2(20, 3 + st), 10, 3.4, true, Vector2(0.6, 0))
	Art.shine(ci, Vector2(-16, -12 + st), 4, 6, 0.35, 0.2)


static func _valach(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 44, 14, Color("1a1a1a"), 8.0)
	Art.shape(ci, Art.rrect(Rect2(-22, 16, 44, 26), 8), Color("f6f6f6"), 3.0)
	Art.shape(ci, Art.ellipse(Vector2(0, 2), 30, 26, 32), Color("f6f6f6"), 3.5)
	var vest := Art.poly([-24, -12, -5, -14, -4, 22, -26, 18])
	Art.shape(ci, vest, Color("2b2b2b"), 2.5, 0.4)
	Art.shape(ci, Art.xform(vest, Vector2.ZERO, Vector2(-1, 1)), Color("2b2b2b"), 2.5, 0.4)
	for i in 3:
		Art.safe_poly(ci, Art.star(Vector2(-14, -4 + i * 8), 3, 1.4, 6), Color("e2382c"))
		Art.safe_poly(ci, Art.star(Vector2(14, -4 + i * 8), 3, 1.4, 6), Color("e2382c"))
	# valaška
	Art.stick(ci, Vector2(30, 30), Vector2(40, -40), Color("9a5b2a"), 4.5, 2.0)
	var axe := Art.poly([34, -42, 48, -46, 52, -36, 40, -34])
	Art.shape(ci, axe, Color("b8c3cf"), 2.5, 0.5)
	_arm(ci, Vector2(24, -2), Vector2(36, 8), Color("f6f6f6"), 12.0)
	_arm(ci, Vector2(-24, -2), Vector2(-36, 14), Color("f6f6f6"), 12.0)
	Art.blob(ci, Vector2(0, -28), 20, 18, Color("f2b98a"), 3.5)
	Art.eyes(ci, Vector2(0, -32), 15, 4.2, true)
	for s: int in [-1, 1]:
		var st := Art.poly([0, -24, s * 20, -24, s * 26, -14, s * 12, -18, 0, -20])
		Art.shape(ci, st, Color("2b1a0a"), 2.0, 0.3)
	Art.shape(ci, Art.ellipse(Vector2(0, -44), 30, 7, 24), Color("1a1a1a"), 3.0, 0.3)
	Art.shape(ci, Art.rrect(Rect2(-14, -58, 28, 14), 5), Color("1a1a1a"), 3.0, 0.3)
	Art.safe_poly(ci, Art.rrect(Rect2(-14, -49, 28, 3), 1), Color("e2382c"))


# ================================================================ Moravskoslezský

static func _hutnik(ci: CanvasItem, t: float) -> void:
	_feet(ci, t, 26, 8, Color("5a6168"), 5.0)
	var foil := Color("d9dee4")
	Art.shape(ci, Art.rrect(Rect2(-16, -6, 32, 30), 10), foil, 3.0)
	for i in 3:
		ci.draw_line(Vector2(-14, 0 + i * 8), Vector2(14, 2 + i * 8), Color(1, 1, 1, 0.5), 1.5, true)
	# kapuce s hledím
	Art.shape(ci, Art.rrect(Rect2(-15, -36, 30, 32), 12), foil, 3.0)
	var visor := Art.rrect(Rect2(-11, -28, 22, 14), 5)
	Art.flat(ci, visor, Color("2b2b3f"), 2.0)
	Art.safe_poly(ci, Art.poly([-8, -26, 0, -26, -6, -16, -10, -16]), Color(1, 0.6, 0.2, 0.7))
	Art.circle(ci, Vector2(4, -21), 2.2, Color("ffb347"), 0.0)
	Art.circle(ci, Vector2(-4, -21), 2.2, Color("ffb347"), 0.0)
	# tyč
	Art.stick(ci, Vector2(14, 10), Vector2(28, -26), Color("6c7580"), 3.5, 2.0)
	Art.circle(ci, Vector2(28, -27), 3.5, Color("ff7a1a"), 1.5)
	Art.circle(ci, Vector2(16, 8), 5, foil, 2.0)


static func _ingot(ci: CanvasItem, t: float) -> void:
	var wob := 1.5 if t > 0.5 else -1.5
	var pts := PackedVector2Array()
	for i in 36:
		var a := TAU * i / 36.0
		var r := 22.0 + sin(a * 4 + wob) * 2.0
		pts.append(Vector2(cos(a) * r * 1.1, sin(a) * r * 0.85 + 4))
	Art.outline(ci, pts, 3.0)
	Art.grad(ci, pts, Color("ffe14a"), Color("ff5a10"))
	for c in [[-12, -6, 7], [10, 12, 6], [14, -6, 4]]:
		Art.safe_poly(ci, Art.ellipse(Vector2(c[0], c[1]), c[2], c[2] * 0.6, 10, 0.5), Color(0.35, 0.12, 0.05, 0.55))
	Art.shine(ci, Vector2(-10, -10), 6, 3, 0.7)
	Art.eyes(ci, Vector2(0, 2), 14, 4.0, true, Vector2(0, 0.2), Color("fffbd0"))
	Art.mouth_grin(ci, Vector2(0, 11), 5, 3, false)


static func _tatra(ci: CanvasItem, t: float) -> void:
	var b := 1.0 if t > 0.5 else 0.0
	var col := Color("f07a1a")
	# korba
	Art.shape(ci, Art.rrect(Rect2(-40, -18 + b, 46, 30), 5), Color("8d97a3"), 3.0)
	for i in 3:
		ci.draw_line(Vector2(-34 + i * 14, -16 + b), Vector2(-34 + i * 14, 10 + b), Color("6c7580"), 2.0, true)
	# kabina
	var cab := Art.poly([4, -30, 30, -30, 38, -10, 38, 14, 4, 14])
	Art.shape(ci, Art.xform(cab, Vector2(0, b)), col, 3.0)
	Art.flat(ci, Art.xform(Art.poly([10, -26, 28, -26, 34, -12, 10, -12]), Vector2(0, b)), Color("9fe3ff"), 2.0)
	Art.circle(ci, Vector2(30, -18 + b), 3.0, Color.WHITE, 0.0)
	Art.circle(ci, Vector2(31, -18 + b), 1.6, Art.OUTLINE, 0.0)
	ci.draw_line(Vector2(24, -24 + b), Vector2(34, -21 + b), Art.OUTLINE, 2.5, true)
	# světla a mřížka
	Art.circle(ci, Vector2(37, 4 + b), 3.5, Color("fff3a0"), 2.0)
	for i in 3:
		ci.draw_line(Vector2(26, -2 + i * 4 + b), Vector2(36, -2 + i * 4 + b), Art.OUTLINE, 1.5, true)
	# kola
	for wx in [-28, -12, 24]:
		Art.circle(ci, Vector2(wx, 16), 9, Color("2b2b2b"), 2.5)
		Art.circle(ci, Vector2(wx, 16), 4, Color("b8c3cf"), 1.5)
