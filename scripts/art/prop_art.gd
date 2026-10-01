extends RefCounted
class_name PropArt
## Dekorace prostředí. Bod (0,0) je místo, kde předmět stojí na zemi.

const DEFAULT_SIZE := Vector2(150, 150)
## Ploché dekorace leží na zemi pod postavami (nejsou řazené podle hloubky).
const FLAT := ["zahon", "leknin", "lodka", "pramen"]
const BIG := ["kolonada", "vez", "komin", "bouda", "chaloupka", "roubenka", "sklep", "trdelnik", "piskovec", "pramen", "kasna", "lodka", "leknin"]
const TALL := ["smrk", "snezny_smrk", "vez", "komin", "piskovec", "kolonada", "lampa", "lampa_praha", "dub", "vrba", "strom", "svestka_strom", "suchy_strom"]


static func size_of(id: String) -> Vector2:
	if id in TALL:
		return Vector2(170, 240)
	return DEFAULT_SIZE


static func origin_of(id: String) -> Vector2:
	var s := size_of(id)
	return Vector2(0.5, (s.y - 26.0) / s.y)


static func draw(ci: CanvasItem, id: String, t: float) -> void:
	var fn := Callable(PropArt, "_" + id)
	if fn.is_valid():
		fn.call(ci, t)
	else:
		_kamen(ci, t)


static func _sh(ci: CanvasItem, rx: float, ry: float = 0.0) -> void:
	Art.shadow(ci, Vector2(4, 2), rx, ry if ry > 0 else rx * 0.32, 0.25)


static func _trunk(ci: CanvasItem, h: float, w: float = 14.0) -> void:
	var tr := Art.poly([-w * 0.5, 0, w * 0.5, 0, w * 0.35, -h, -w * 0.35, -h])
	Art.shape(ci, Art.grow(tr, 2), Color("8a5a2a"), 3.0, 0.6)


static func _crown(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var blobs := [[-0.55, 0.15, 0.62], [0.55, 0.15, 0.62], [0.0, -0.35, 0.72], [0.0, 0.25, 0.7]]
	var pts := PackedVector2Array()
	for b in blobs:
		var e := Art.ellipse(c + Vector2(b[0], b[1]) * r, r * b[2], r * b[2] * 0.9, 24)
		if pts.is_empty():
			pts = e
		else:
			var u := Geometry2D.merge_polygons(pts, e)
			if not u.is_empty():
				pts = u[0]
	Art.shape(ci, pts, col, 3.5)
	for i in 5:
		var a := TAU * i / 5.0 + 0.4
		Art.safe_poly(ci, Art.ellipse(c + Vector2(cos(a), sin(a) * 0.7) * r * 0.55, r * 0.16, r * 0.1, 10, a), Color(col.lightened(0.25), 0.6))


# ---------------------------------------------------------------- stromy a rostliny

static func _strom(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 42)
	_trunk(ci, 70)
	_crown(ci, Vector2(0, -96), 52, Color("4fae2a"))


static func _dub(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 50)
	_trunk(ci, 70, 22)
	_crown(ci, Vector2(0, -100), 62, Color("3f8f2a"))


static func _svestka_strom(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 42)
	_trunk(ci, 66)
	_crown(ci, Vector2(0, -94), 50, Color("58a832"))
	for p in [[-28, -84], [18, -76], [30, -104], [-12, -116], [4, -92], [-34, -108]]:
		Art.blob(ci, Vector2(p[0], p[1]), 6, 7.5, Color("4a3a9a"), 2.0, 0.6)


static func _smrk(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 36)
	_trunk(ci, 30, 12)
	for i in 4:
		var y := -24.0 - i * 40.0
		var w := 56.0 - i * 11.0
		var tri := Art.poly([-w, y, 0, y - 62, w, y])
		Art.shape(ci, Art.grow(tri, 3), Color("2f7a3a").lightened(i * 0.04), 3.0)


static func _snezny_smrk(ci: CanvasItem, _t: float) -> void:
	_smrk(ci, _t)
	for i in 4:
		var y := -24.0 - i * 40.0
		var w := 56.0 - i * 11.0
		var cap := Art.poly([-w * 0.45, y - 34, 0, y - 64, w * 0.45, y - 34, w * 0.2, y - 30, 0, y - 36, -w * 0.25, y - 28])
		Art.shape(ci, cap, Color("f4f8ff"), 2.0, 0.4)


static func _suchy_strom(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 30)
	_trunk(ci, 120, 18)
	for b in [[0, -80, -40, -130], [0, -100, 34, -150], [-20, -110, -46, -160], [10, -60, 44, -96]]:
		Art.stick(ci, Vector2(b[0], b[1]), Vector2(b[2], b[3]), Color("7a5232"), 7.0, 2.5)


static func _vrba(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 48)
	_trunk(ci, 60, 20)
	_crown(ci, Vector2(0, -104), 46, Color("7ab83a"))
	for i in 9:
		var x := -48.0 + i * 12.0
		var pts := PackedVector2Array([Vector2(x, -96), Vector2(x - 4, -60), Vector2(x + 2, -30)])
		ci.draw_polyline(pts, Art.OUTLINE, 7.0, true)
		ci.draw_polyline(pts, Color("8fcf4a"), 4.0, true)


static func _ker(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 40)
	_crown(ci, Vector2(0, -30), 34, Color("4fae2a"))
	for p in [[-16, -40], [10, -24], [18, -48], [-4, -56]]:
		Art.circle(ci, Vector2(p[0], p[1]), 4, Color("ff6a8a"), 1.5)


static func _paprad(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 30)
	for i in 7:
		var a := -PI * 0.5 + (i - 3) * 0.35
		var tip := Vector2(cos(a), sin(a)) * 62
		var leaf := Art.poly([0, 0, tip.x * 0.5 - 6, tip.y * 0.5, tip.x, tip.y, tip.x * 0.5 + 6, tip.y * 0.5])
		Art.shape(ci, leaf, Color("3f9a3a"), 2.5, 0.4)


static func _rakos(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 26)
	for i in 6:
		var x := -22.0 + i * 9.0
		var h := 70.0 + (i % 3) * 18.0
		Art.stick(ci, Vector2(x, 0), Vector2(x + (i - 3) * 3, -h), Color("6fae3a"), 3.0, 2.0)
		if i % 2 == 0:
			Art.shape(ci, Art.rrect(Rect2(x + (i - 3) * 3 - 5, -h - 4, 10, 26), 5), Color("7a4a24"), 2.0, 0.5)
	for s: int in [-1, 1]:
		var leaf := Art.poly([0, 0, s * 20, -50, s * 8, -40])
		Art.shape(ci, leaf, Color("5fa832"), 2.0, 0.3)


static func _zahon(ci: CanvasItem, _t: float) -> void:
	var bed := Art.ellipse(Vector2(0, -6), 56, 22, 28)
	Art.shape(ci, bed, Color("7a4a24"), 3.0, 0.4)
	var cols := ["ff4d6d", "ffd23f", "ffffff", "b25cff", "ff8a2a"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 16:
		var p := Vector2(rng.randf_range(-44, 44), rng.randf_range(-20, 6))
		ci.draw_line(p, p + Vector2(0, 8), Color("3f8f2a"), 2.0)
		Art.shape(ci, Art.star(p, 6, 3, 5), Color(cols[i % cols.size()]), 1.5, 0.3)
		Art.circle(ci, p, 1.8, Color("ffd23f"), 0.0)


static func _houby(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 34)
	for m in [[-18, 0, 1.0], [14, 4, 0.75], [30, -2, 0.55]]:
		var s: float = m[2]
		var c := Vector2(m[0], m[1])
		Art.shape(ci, Art.xform(Art.poly([-8, 0, 8, 0, 10, -26, -10, -26]), c, Vector2(s, s)), Color("f2e6c8"), 2.5, 0.5)
		var cap := Art.arc_pts(c + Vector2(0, -24 * s), 22 * s, PI, TAU, 14)
		Art.shape(ci, cap, Color("8a4a1c"), 2.5)


static func _parez(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 34)
	Art.shape(ci, Art.poly([-26, 0, 26, 0, 22, -34, -22, -34]), Color("8a5a2a"), 3.0)
	Art.shape(ci, Art.ellipse(Vector2(0, -34), 22, 9, 20), Color("e8c08a"), 2.5, 0.3)
	for r in [5, 10, 15]:
		ci.draw_arc(Vector2(0, -34), r, 0, TAU, 18, Color("b8875a"), 1.5, true)
	Art.stick(ci, Vector2(6, -36), Vector2(30, -70), Color("9a5b2a"), 4.0, 2.0)
	Art.shape(ci, Art.poly([-4, -34, 14, -44, 16, -30]), Color("b8c3cf"), 2.0, 0.4)


static func _vinna_reva(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 56, 10)
	for x in [-54, 54]:
		Art.stick(ci, Vector2(x, 0), Vector2(x, -80), Color("8a5a2a"), 6.0, 2.5)
	ci.draw_line(Vector2(-54, -60), Vector2(54, -60), Art.OUTLINE, 2.0, true)
	for i in 5:
		var c := Vector2(-40 + i * 20, -62)
		_crown(ci, c, 14, Color("5fae2a"))
	for i in 3:
		var c := Vector2(-28 + i * 28, -42)
		for g in [[0, 0], [-5, -6], [5, -6], [0, -12], [-5, 6], [5, 6], [0, 12]]:
			Art.circle(ci, c + Vector2(g[0], g[1]) * 0.8, 3.8, Color("7a3ab8"), 1.2)


# ---------------------------------------------------------------- kameny

static func _kamen(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 34)
	var rock := Art.poly([-34, 0, -28, -26, -6, -38, 20, -32, 34, -10, 30, 0])
	Art.shape(ci, rock, Color("9aa3ad"), 3.0)
	ci.draw_line(Vector2(-6, -36), Vector2(0, -16), Color(0.4, 0.45, 0.5, 0.5), 2.0, true)


static func _balvan(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 50)
	var rock := Art.poly([-50, 0, -44, -40, -14, -62, 26, -56, 50, -24, 46, 0])
	Art.shape(ci, rock, Color("b3a9a0"), 3.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 18:
		Art.circle(ci, Vector2(rng.randf_range(-36, 36), rng.randf_range(-48, -8)), 1.6, Color("5a524a") if i % 2 else Color("f4ede6"), 0.0)


static func _snezny_kamen(ci: CanvasItem, _t: float) -> void:
	_kamen(ci, _t)
	var cap := Art.poly([-28, -26, -6, -38, 20, -32, 30, -18, 16, -22, 4, -26, -12, -22])
	Art.shape(ci, cap, Color("f4f8ff"), 2.0, 0.4)


static func _piskovec(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 46)
	var pillar := Art.poly([-40, 0, -34, -60, -42, -110, -26, -170, 14, -178, 34, -130, 28, -70, 40, 0])
	Art.shape(ci, pillar, Color("d9a86a"), 3.5)
	for y in [-30, -64, -100, -140]:
		ci.draw_line(Vector2(-34, y), Vector2(30, y + 4), Color(0.55, 0.35, 0.18, 0.45), 3.0, true)
	_crown(ci, Vector2(-6, -180), 18, Color("3f8f2a"))


static func _krystal(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 34)
	for c in [[-16, 0, 1.0, -0.3], [12, 0, 1.3, 0.15], [28, 2, 0.8, 0.5]]:
		var cr := Art.xform(Art.poly([-8, 0, -9, -40, 0, -54, 9, -40, 8, 0]), Vector2(c[0], c[1]), Vector2(c[2], c[2]), c[3])
		Art.shape(ci, cr, Color("7fe6ff"), 2.5, 0.6)
		Art.safe_poly(ci, Art.xform(Art.poly([-2, -6, -3, -40, 2, -48, 3, -10]), Vector2(c[0], c[1]), Vector2(c[2], c[2]), c[3]), Color(1, 1, 1, 0.5))


static func _hromada_uhli(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 54)
	var heap := Art.poly([-56, 0, -30, -34, 0, -48, 30, -36, 56, 0])
	Art.shape(ci, heap, Color("2f2f33"), 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 14:
		var p := Vector2(rng.randf_range(-40, 40), rng.randf_range(-36, -4))
		Art.safe_poly(ci, Art.ellipse(p, 5, 3.5, 6, rng.randf()), Color(1, 1, 1, 0.13))


static func _struska(ci: CanvasItem, t: float) -> void:
	_sh(ci, 50)
	var heap := Art.poly([-52, 0, -26, -30, 4, -40, 32, -28, 52, 0])
	Art.shape(ci, heap, Color("4a3a34"), 3.0)
	for cr in [[-30, -10, -10, -26, 6, -18], [10, -30, 20, -14, 36, -8]]:
		var pts := PackedVector2Array([Vector2(cr[0], cr[1]), Vector2(cr[2], cr[3]), Vector2(cr[4], cr[5])])
		ci.draw_polyline(pts, Color("ff6a10"), 5.0, true)
		ci.draw_polyline(pts, Color("ffe14a"), 2.0, true)


# ---------------------------------------------------------------- stavby

static func _kolonada(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 74, 14)
	Art.shape(ci, Art.rrect(Rect2(-76, -10, 152, 12), 3), Color("d9d2c3"), 3.0, 0.5)
	for i in 4:
		var x := -60.0 + i * 40.0
		Art.shape(ci, Art.rrect(Rect2(x - 7, -130, 14, 122), 3), Color("f6f2ea"), 3.0, 0.6)
		Art.flat(ci, Art.rrect(Rect2(x - 11, -136, 22, 8), 2), Color("e9e3d3"), 2.5)
	Art.shape(ci, Art.rrect(Rect2(-80, -156, 160, 22), 4), Color("f0ebe0"), 3.0, 0.5)
	var roof := Art.poly([-84, -156, 0, -190, 84, -156])
	Art.shape(ci, roof, Color("e9e3d3"), 3.0, 0.6)
	Art.circle(ci, Vector2(0, -168), 7, Art.GOLD, 2.5)


static func _pramen(ci: CanvasItem, t: float) -> void:
	_sh(ci, 54, 16)
	Art.shape(ci, Art.ellipse(Vector2(0, -8), 56, 22, 32), Color("9aa3ad"), 3.0, 0.5)
	Art.safe_poly(ci, Art.ellipse(Vector2(0, -10), 44, 15, 28), Color("6fd0ff"))
	Art.shine(ci, Vector2(-14, -14), 14, 4, 0.5, 0.0)
	for i in 3:
		var x := -20.0 + i * 20.0
		var y := -40.0 - (t * 10.0) - i * 6.0
		Art.safe_poly(ci, Art.ellipse(Vector2(x, y), 12, 9, 14), Color(1, 1, 1, 0.55))


static func _lampa(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 18)
	Art.stick(ci, Vector2(0, 0), Vector2(0, -130), Color("2b3a2b"), 6.0, 2.5)
	Art.flat(ci, Art.rrect(Rect2(-10, -8, 20, 10), 3), Color("2b3a2b"), 2.5)
	Art.shape(ci, Art.poly([-14, -130, 14, -130, 10, -156, -10, -156]), Color("fff3a0"), 3.0, 0.3)
	Art.shape(ci, Art.poly([-18, -156, 18, -156, 0, -170]), Color("2b3a2b"), 3.0, 0.3)


static func _lampa_praha(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 18)
	Art.stick(ci, Vector2(0, 0), Vector2(0, -140), Color("2f4a3a"), 7.0, 2.5)
	Art.stick(ci, Vector2(0, -140), Vector2(26, -150), Color("2f4a3a"), 5.0, 2.0)
	Art.shape(ci, Art.poly([18, -150, 34, -150, 30, -172, 22, -172]), Color("fff3a0"), 3.0, 0.3)
	Art.shape(ci, Art.poly([16, -172, 36, -172, 26, -184]), Color("2f4a3a"), 2.5, 0.3)
	Art.flat(ci, Art.rrect(Rect2(-12, -14, 24, 14), 4), Color("2f4a3a"), 2.5)


static func _lavicka(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 50, 10)
	for x in [-40, 40]:
		Art.stick(ci, Vector2(x, 0), Vector2(x, -26), Color("2b3a2b"), 5.0, 2.0)
	for i in 3:
		Art.shape(ci, Art.rrect(Rect2(-50, -30 - i * 12, 100, 8), 3), Color("b0703a"), 2.5, 0.4)


static func _sudy(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 54)
	for b in [[-26, 0], [26, 0], [0, -42]]:
		var r := Art.rrect(Rect2(b[0] - 22, b[1] - 42, 44, 42), 12)
		Art.shape(ci, r, Color("b06a2c"), 3.0)
		for y in [12, 30]:
			Art.flat(ci, Art.rrect(Rect2(b[0] - 23, b[1] - 42 + y - 3, 46, 6), 2), Color("8d97a3"), 1.5)


static func _sud_vino(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 48)
	Art.shape(ci, Art.ellipse(Vector2(0, -32), 48, 30, 30), Color("9a5b2a"), 3.0)
	Art.shape(ci, Art.ellipse(Vector2(40, -32), 12, 26, 20), Color("b8763a"), 2.5, 0.4)
	for x in [-24, 8]:
		ci.draw_line(Vector2(x, -60), Vector2(x, -4), Color("6c7580"), 4.0, true)
	Art.flat(ci, Art.rrect(Rect2(46, -30, 12, 8), 2), Art.GOLD, 2.0)
	for x in [-30, 30]:
		Art.stick(ci, Vector2(x, 0), Vector2(x, -8), Color("6b3e1c"), 8.0, 2.0)


static func _sklep(ci: CanvasItem, _t: float) -> void:
	var mound := Art.poly([-70, 0, -54, -50, 0, -76, 54, -50, 70, 0])
	Art.shape(ci, mound, Color("5fae2a"), 3.0)
	var door := Art.arc_pts(Vector2(0, -26), 26, PI, TAU, 14)
	door.append(Vector2(26, 0))
	door.append(Vector2(-26, 0))
	Art.shape(ci, Art.grow(door, 5), Color("d9d2c3"), 3.0, 0.4)
	Art.shape(ci, door, Color("8a4a1c"), 2.0, 0.4)
	ci.draw_line(Vector2(0, -50), Vector2(0, 0), Art.OUTLINE, 2.0, true)
	Art.circle(ci, Vector2(8, -18), 3, Art.GOLD, 1.5)


static func _vez(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 50)
	Art.shape(ci, Art.rrect(Rect2(-40, -150, 80, 150), 6), Color("b8b0a2"), 3.5)
	for row in 7:
		for col in 3:
			var off := 13.0 if row % 2 == 0 else 0.0
			Art.safe_poly(ci, Art.rrect(Rect2(-38 + col * 27 + off, -146 + row * 21, 24, 17), 3), Color(1, 1, 1, 0.08))
	for i in 5:
		Art.flat(ci, Art.rrect(Rect2(-44 + i * 19, -166, 12, 18), 2), Color("b8b0a2"), 2.5)
	Art.flat(ci, Art.arc_pts(Vector2(0, -80), 12, PI, TAU, 10), Color("2b2b2b"), 2.5)
	var roof := Art.poly([-34, -164, 0, -220, 34, -164])
	Art.shape(ci, roof, Color("d7462c"), 3.0)


static func _nahrobek(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 36)
	var stone := Art.arc_pts(Vector2(0, -44), 24, PI, TAU, 14)
	stone.append(Vector2(24, 0))
	stone.append(Vector2(-24, 0))
	Art.shape(ci, stone, Color("9aa3ad"), 3.0)
	Art.flat(ci, Art.rrect(Rect2(-3, -54, 6, 26), 1), Color("6c7580"), 0.0)
	Art.flat(ci, Art.rrect(Rect2(-10, -46, 20, 6), 1), Color("6c7580"), 0.0)
	for b in [[-30, -4, -10, 2], [14, 0, 36, -6]]:
		Art.stick(ci, Vector2(b[0], b[1]), Vector2(b[2], b[3]), Color("efe9d8"), 4.0, 2.0)
	Art.blob(ci, Vector2(30, -8), 9, 8, Color("efe9d8"), 2.5, 0.3)


static func _bouda(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 64, 16)
	Art.shape(ci, Art.rrect(Rect2(-56, -66, 112, 66), 4), Color("9a5b2a"), 3.5)
	for i in 5:
		ci.draw_line(Vector2(-54, -12 - i * 12), Vector2(54, -12 - i * 12), Color("6b3a17"), 2.0, true)
	Art.flat(ci, Art.rrect(Rect2(-12, -40, 24, 40), 3), Color("6b3a17"), 2.5)
	for x in [-38, 38]:
		Art.flat(ci, Art.rrect(Rect2(x - 10, -50, 20, 18), 2), Color("fff3a0"), 2.5)
	var roof := Art.poly([-70, -60, 0, -112, 70, -60])
	Art.shape(ci, roof, Color("6b3a17"), 3.0)
	var snow := Art.poly([-72, -62, 0, -116, 72, -62, 56, -56, 30, -66, 0, -60, -30, -68, -56, -56])
	Art.shape(ci, snow, Color("f4f8ff"), 2.5, 0.4)


static func _chaloupka(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 60, 16)
	Art.shape(ci, Art.rrect(Rect2(-50, -64, 100, 64), 6), Color("b86b2c"), 3.5)
	for i in 6:
		Art.circle(ci, Vector2(-40 + i * 16, -8), 4, Color("ff4d6d") if i % 2 else Color("6fd0ff"), 1.5)
	Art.flat(ci, Art.arc_pts(Vector2(0, -26), 13, PI, TAU, 10), Color("6b3a17"), 2.5)
	Art.icon_heart(ci, Vector2(-30, -40), 10, Color("ff4d6d"))
	Art.icon_heart(ci, Vector2(30, -40), 10, Color("ff4d6d"))
	var roof := Art.poly([-64, -58, 0, -112, 64, -58])
	Art.shape(ci, roof, Color("8a4a1c"), 3.0)
	var icing := PackedVector2Array()
	for i in 13:
		var x := -60.0 + i * 10.0
		icing.append(Vector2(x, -60 - (64.0 - absf(x)) * 0.84 + (6 if i % 2 else 0)))
	ci.draw_polyline(icing, Color.WHITE, 4.0, true)


static func _roubenka(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 68, 16)
	Art.shape(ci, Art.rrect(Rect2(-60, -70, 120, 70), 4), Color("8a5a2a"), 3.5)
	for i in 6:
		var y := -6.0 - i * 12.0
		Art.flat(ci, Art.rrect(Rect2(-62, y - 5, 124, 9), 4), Color("9a6a3a"), 1.5)
		ci.draw_line(Vector2(-58, y + 4), Vector2(58, y + 4), Color("f4f0e0"), 1.5, true)
	for x in [-34, 34]:
		Art.flat(ci, Art.rrect(Rect2(x - 12, -54, 24, 22), 2), Color("6fd0ff"), 3.0)
		ci.draw_line(Vector2(x, -54), Vector2(x, -32), Color("f4f0e0"), 2.5)
	var roof := Art.poly([-74, -64, -44, -118, 44, -118, 74, -64])
	Art.shape(ci, roof, Color("5a3a1a"), 3.0)
	for i in 5:
		ci.draw_line(Vector2(-60 + i * 30, -66), Vector2(-40 + i * 20, -116), Color("3a2412"), 2.0, true)


static func _plot(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 64, 8)
	for y in [-14, -34]:
		Art.flat(ci, Art.rrect(Rect2(-64, y - 4, 128, 7), 2), Color("b0703a"), 2.0)
	for i in 7:
		var x := -60.0 + i * 20.0
		var pk := Art.poly([x - 6, 0, x + 6, 0, x + 6, -46, x, -54, x - 6, -46])
		Art.shape(ci, pk, Color("c98a4a"), 2.5, 0.4)


static func _seno(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 50)
	var stack := Art.arc_pts(Vector2(0, -10), 50, PI, TAU, 20)
	stack.append(Vector2(50, 0))
	stack.append(Vector2(-50, 0))
	Art.shape(ci, stack, Color("e8c060"), 3.0)
	for i in 8:
		var a := PI + PI * (i + 0.5) / 8.0
		ci.draw_line(Vector2(cos(a), sin(a)) * 40 + Vector2(0, -10), Vector2(cos(a), sin(a)) * 18 + Vector2(0, -10), Color("c99a3a"), 2.0, true)


static func _snop(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 30)
	var sheaf := Art.poly([-24, 0, -10, -40, -26, -76, 0, -66, 26, -76, 10, -40, 24, 0])
	Art.shape(ci, sheaf, Color("e8c060"), 3.0)
	Art.flat(ci, Art.rrect(Rect2(-14, -44, 28, 8), 3), Color("b0703a"), 2.0)
	for i in 5:
		Art.blob(ci, Vector2(-20 + i * 10, -76 + absf(i - 2) * 4), 4, 7, Color("f2d27a"), 1.5, 0.3)


static func _prekazka(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 64, 10)
	for x in [-56, 56]:
		Art.stick(ci, Vector2(x, 0), Vector2(x, -50), Color("f4f4f4"), 6.0, 2.5)
	_crown(ci, Vector2(0, -30), 30, Color("3f8f2a"))
	for y in [-46, -24]:
		Art.flat(ci, Art.rrect(Rect2(-60, y - 3, 120, 7), 3), Color("f4f4f4"), 2.0)
		for i in 6:
			Art.safe_poly(ci, Art.rrect(Rect2(-54 + i * 20, y - 3, 9, 7), 1), Color("e2382c"))


static func _sanky(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 40, 8)
	var runner := PackedVector2Array([Vector2(-40, 0), Vector2(36, 0), Vector2(46, -12)])
	ci.draw_polyline(runner, Art.OUTLINE, 7.0, true)
	ci.draw_polyline(runner, Color("8d97a3"), 3.5, true)
	for x in [-26, 20]:
		Art.stick(ci, Vector2(x, 0), Vector2(x, -16), Color("9a5b2a"), 5.0, 2.0)
	Art.shape(ci, Art.rrect(Rect2(-40, -24, 80, 10), 3), Color("c98a4a"), 2.5, 0.4)


static func _trdelnik(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 50, 12)
	Art.shape(ci, Art.rrect(Rect2(-46, -50, 92, 50), 5), Color("c98a4a"), 3.0)
	var awn := Art.rrect(Rect2(-54, -92, 108, 30), 6)
	Art.shape(ci, awn, Color("e2382c"), 3.0)
	for i in 4:
		Art.safe_poly(ci, Art.rrect(Rect2(-54 + i * 27 + 13, -92, 13, 30), 1), Color("f4f4f4"))
	for x in [-46, 46]:
		Art.stick(ci, Vector2(x, -50), Vector2(x, -62), Color("8a5a2a"), 5.0, 2.0)
	Art.shape(ci, Art.rrect(Rect2(-20, -62, 40, 16), 8), Color("d99a4a"), 2.5, 0.6)
	for i in 4:
		ci.draw_line(Vector2(-14 + i * 9, -62), Vector2(-10 + i * 9, -46), Color("8a4a1c"), 2.0, true)


static func _kasna(ci: CanvasItem, t: float) -> void:
	_sh(ci, 58, 18)
	Art.shape(ci, Art.ellipse(Vector2(0, -12), 58, 22, 32), Color("b8b0a2"), 3.0, 0.5)
	Art.safe_poly(ci, Art.ellipse(Vector2(0, -14), 46, 15, 28), Color("6fd0ff"))
	Art.shape(ci, Art.rrect(Rect2(-8, -64, 16, 52), 4), Color("c9c1b3"), 2.5, 0.5)
	Art.shape(ci, Art.ellipse(Vector2(0, -64), 22, 8, 20), Color("c9c1b3"), 2.5, 0.5)
	var h := 92.0 if t > 0.5 else 86.0
	Art.shape(ci, Art.poly([-4, -66, 0, -h, 4, -66]), Color("bff3ff"), 2.0, 0.3)
	for s: int in [-1, 1]:
		var pts := PackedVector2Array()
		for i in 8:
			var k := i / 7.0
			pts.append(Vector2(s * k * 34, -h + 4 + k * k * (h - 22)))
		ci.draw_polyline(pts, Art.OUTLINE, 5.0, true)
		ci.draw_polyline(pts, Color("bff3ff"), 3.0, true)


static func _leknin(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.ellipse(Vector2(0, -14), 66, 26, 32), Color("4aa3d8"), 3.0, 0.4)
	Art.shine(ci, Vector2(-26, -22), 18, 4, 0.35, 0.0)
	for p in [[-24, -12], [18, -20], [30, -6]]:
		var pad := Art.arc_pts(Vector2(p[0], p[1]), 11, 0.4, TAU - 0.1, 12)
		pad.append(Vector2(p[0], p[1]))
		Art.shape(ci, pad, Color("5fae2a"), 2.0, 0.3)
	Art.shape(ci, Art.star(Vector2(18, -24), 7, 3, 6), Color("ffb3cc"), 1.5, 0.3)


static func _lodka(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.ellipse(Vector2(0, -10), 70, 24, 32), Color("4aa3d8"), 3.0, 0.4)
	var boat := Art.poly([-40, -24, 40, -24, 30, -8, -30, -8])
	Art.shape(ci, boat, Color("9a5b2a"), 3.0)
	Art.flat(ci, Art.rrect(Rect2(-36, -28, 72, 6), 2), Color("c98a4a"), 2.0)
	Art.stick(ci, Vector2(-10, -26), Vector2(30, -48), Color("c98a4a"), 3.0, 1.5)


static func _vozik(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 46, 10)
	ci.draw_line(Vector2(-60, -2), Vector2(60, -2), Color("6c7580"), 4.0, true)
	for i in 6:
		Art.flat(ci, Art.rrect(Rect2(-56 + i * 22, -4, 8, 6), 1), Color("6b3e1c"), 1.0)
	Art.shape(ci, Art.poly([-40, -54, 40, -54, 32, -14, -32, -14]), Color("7d858c"), 3.0)
	Art.shape(ci, Art.poly([-34, -54, 0, -70, 34, -54]), Color("2f2f33"), 2.5, 0.4)
	for x in [-20, 20]:
		Art.circle(ci, Vector2(x, -10), 9, Color("3a3a3a"), 2.5)
		Art.circle(ci, Vector2(x, -10), 3, Color("b8c3cf"), 1.0)


static func _bedna_syr(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 40)
	Art.shape(ci, Art.rrect(Rect2(-40, -44, 80, 44), 4), Color("c98a4a"), 3.0)
	for y in [-30, -16]:
		ci.draw_line(Vector2(-38, y), Vector2(38, y), Color("8a5a2a"), 2.0, true)
	for i in 4:
		Art.shape(ci, Art.rrect(Rect2(-36 + i * 18, -58, 16, 14), 6), Color("f2b632"), 2.0, 0.5)
	for s: int in [-1, 0, 1]:
		ci.draw_polyline(PackedVector2Array([Vector2(s * 16, -62), Vector2(s * 16 + 4, -72), Vector2(s * 16, -82)]), Color("9be05a"), 2.5, true)


static func _krabice(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 40)
	Art.shape(ci, Art.rrect(Rect2(-44, -40, 88, 40), 3), Color("f2e2b0"), 3.0)
	Art.flat(ci, Art.rrect(Rect2(-48, -48, 96, 12), 3), Color("e2382c"), 2.5)
	ci.draw_string(Art.font, Vector2(-22, -12), "BOTY", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("8a4a1c"))


static func _komin(ci: CanvasItem, t: float) -> void:
	_sh(ci, 36)
	var ch := Art.poly([-26, 0, 26, 0, 16, -190, -16, -190])
	Art.shape(ci, ch, Color("a8483a"), 3.5)
	for i in 9:
		ci.draw_line(Vector2(-24 + i, -20 - i * 20), Vector2(24 - i, -20 - i * 20), Color(0.4, 0.15, 0.1, 0.45), 2.0, true)
	for y in [-60, -150]:
		Art.flat(ci, Art.rrect(Rect2(-22, y, 44, 8), 2), Color("e8e2d8"), 2.0)
	for p in [[0, -200, 14], [10, -214, 18], [-4, -230, 12]]:
		Art.blob(ci, Vector2(p[0] + t * 4, p[1]), p[2], p[2] * 0.8, Color("9a9a9a"), 2.5, 0.4)


static func _nosnik(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 56)
	for i in 3:
		var y := -10.0 - i * 16.0
		var x := -50.0 + i * 8.0
		Art.shape(ci, Art.rrect(Rect2(x, y - 12, 100 - i * 8, 12), 2), Color("7d858c"), 2.5, 0.5)
		Art.safe_poly(ci, Art.rrect(Rect2(x + 4, y - 8, 92 - i * 8, 4), 1), Color("a0612d"))


static func _sud_olej(ci: CanvasItem, _t: float) -> void:
	_sh(ci, 30)
	Art.shape(ci, Art.rrect(Rect2(-26, -62, 52, 62), 6), Color("2f6ad1"), 3.0)
	for y in [-46, -16]:
		Art.flat(ci, Art.rrect(Rect2(-28, y - 3, 56, 6), 2), Color("1f4fa8"), 1.5)
	Art.shape(ci, Art.ellipse(Vector2(0, -62), 26, 7, 20), Color("4a7ae0"), 2.5, 0.4)


static func _kul(ci: CanvasItem, _t: float) -> void:
	# kůl palisády kolem arény bosse
	Art.shadow(ci, Vector2(2, 2), 16, 6, 0.3)
	var log := Art.poly([-10, 0, 10, 0, 10, -58, 0, -72, -10, -58])
	Art.shape(ci, log, Color("9a5b2a"), 3.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-11, -40, 22, 5), 2), Color("d9c08a"))
	ci.draw_line(Vector2(-3, -6), Vector2(-3, -54), Color(0.4, 0.22, 0.1, 0.5), 2.0, true)
