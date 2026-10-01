extends RefCounted
class_name BossArt
## Kresby 14 bossů. Plátno má 260 × 260 jednotek, střed je (0,0).

const SIZE := Vector2(260, 260)


static func draw(ci: CanvasItem, id: String, t: float) -> void:
	var fn := Callable(BossArt, "_" + id)
	if fn.is_valid():
		fn.call(ci, t)


static func _legs(ci: CanvasItem, t: float, y: float, spread: float, col: Color, r: float = 16.0) -> void:
	var st := 1.0 if t > 0.5 else -1.0
	for s: int in [-1, 1]:
		Art.blob(ci, Vector2(s * spread + st * s * 3.0, y - st * s * 3.0), r * 1.35, r, col, 3.5, 0.6)


static func _arm(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float = 18.0) -> void:
	Art.stick(ci, a, b, col, w, 3.5)
	Art.circle(ci, b, w * 0.65, col, 3.5)


static func _crown(ci: CanvasItem, c: Vector2, s: float) -> void:
	Art.icon_crown(ci, c, s)


# ---------------------------------------------------------------- Karlovarský: Vřídelní obr

static func _vridlo(ci: CanvasItem, t: float) -> void:
	_legs(ci, t, 96, 46, Color("7d858c"), 18)
	for s: int in [-1, 1]:
		_arm(ci, Vector2(s * 70, 10), Vector2(s * 100, 50 + (t - 0.5) * 10 * s), Color("9aa3ad"), 22)
	# kamenná kašna
	var basin := Art.poly([-84, -10, 84, -10, 70, 80, -70, 80])
	Art.shape(ci, Art.grow(basin, 8), Color("aab3bd"), 4.0)
	for i in 4:
		Art.safe_poly(ci, Art.rrect(Rect2(-70 + i * 36, 20 + (i % 2) * 22, 30, 16), 4), Color(1, 1, 1, 0.1))
	Art.flat(ci, Art.rrect(Rect2(-96, -22, 192, 22), 10), Color("c4ccd6"), 4.0)
	# gejzír
	var h := 118.0 if t > 0.5 else 108.0
	var jet := Art.poly([-26, -22, -18, -h * 0.6, -8, -h, 8, -h - 4, 20, -h * 0.65, 28, -22])
	Art.shape(ci, jet, Color("8fdcff"), 3.5, 0.6)
	Art.safe_poly(ci, Art.poly([-8, -24, -4, -h * 0.85, 4, -h * 0.9, 8, -24]), Color(1, 1, 1, 0.6))
	for p in [[-40, -h * 0.7, 16], [36, -h * 0.75, 18], [-16, -h - 6, 14], [20, -h + 2, 12]]:
		Art.blob(ci, Vector2(p[0], p[1]), p[2], p[2] * 0.8, Color("f2fbff"), 3.0, 0.5)
	Art.eyes(ci, Vector2(0, 30), 56, 12.0, true, Vector2(0, 0.2))
	Art.mouth_grin(ci, Vector2(0, 54), 22, 14)


# ---------------------------------------------------------------- Plzeňský: Pivní král

static func _pivni_kral(ci: CanvasItem, t: float) -> void:
	_legs(ci, t, 100, 40, Color("7a4520"), 17)
	# ucho korbele
	var handle := Art.ring_sector(Vector2(70, 10), 26, 42, -PI * 0.5, PI * 0.5, 16)
	Art.shape(ci, handle, Color("e8f6ff"), 4.0, 0.5)
	var glass := Art.rrect(Rect2(-70, -60, 140, 160), 24)
	Art.outline(ci, glass, 4.0)
	Art.grad(ci, glass, Color("ffd04a"), Color("e08a10"))
	for i in 4:
		Art.safe_poly(ci, Art.rrect(Rect2(-56 + i * 32, -48, 12, 136), 6), Color(1, 1, 1, 0.13))
	for b in [[-30, 60, 5], [24, 70, 4], [40, 20, 6], [-44, 10, 4], [6, 40, 3]]:
		Art.circle(ci, Vector2(b[0], b[1] - (t * 8)), b[2], Color(1, 1, 1, 0.55), 0.0)
	# pěna a koruna
	var foam := PackedVector2Array()
	for i in 25:
		var a := PI + PI * i / 24.0
		foam.append(Vector2(cos(a) * 82, -60 + sin(a) * 26 + sin(i * 1.7) * 6))
	foam.append(Vector2(80, -40))
	for i in 9:
		foam.append(Vector2(80 - i * 20, -42 + (8 if i % 2 == 0 else 0) + 6))
	foam.append(Vector2(-82, -40))
	Art.shape(ci, foam, Color("fffaf0"), 4.0, 0.5)
	_crown(ci, Vector2(0, -102), 34)
	Art.eyes(ci, Vector2(0, 0), 52, 12.0, true)
	Art.mouth_grin(ci, Vector2(0, 30), 24, 16)
	var st := Art.poly([0, 18, 40, 14, 50, 26, 30, 24, 0, 24])
	Art.shape(ci, st, Color("8a4a1c"), 3.0, 0.4)
	Art.shape(ci, Art.xform(st, Vector2.ZERO, Vector2(-1, 1)), Color("8a4a1c"), 3.0, 0.4)


# ---------------------------------------------------------------- Ústecký: Kolesové rypadlo

static func _rypadlo(ci: CanvasItem, t: float) -> void:
	# pásy
	Art.shape(ci, Art.rrect(Rect2(-100, 70, 200, 40), 20), Color("3a3a3a"), 4.0)
	for i in 8:
		Art.circle(ci, Vector2(-84 + i * 24, 90), 7, Color("8d97a3"), 2.5)
	# trup
	Art.shape(ci, Art.rrect(Rect2(-80, 10, 150, 64), 10), Color("f2a20c"), 4.0)
	for i in 4:
		ci.draw_line(Vector2(-70 + i * 36, 14), Vector2(-70 + i * 36, 70), Color("c97a00"), 3.0, true)
	# kabina s očima
	Art.shape(ci, Art.rrect(Rect2(10, -30, 60, 44), 8), Color("f2a20c"), 4.0)
	Art.flat(ci, Art.rrect(Rect2(18, -22, 44, 22), 5), Color("9fe3ff"), 3.0)
	Art.eyes(ci, Vector2(40, -11), 22, 7.0, true, Vector2(-0.5, 0.2))
	# výložník a kolo s korečky
	Art.stick(ci, Vector2(-20, 20), Vector2(-70, -50), Color("d98e04"), 16.0, 4.0)
	var rot := 0.3 if t > 0.5 else 0.0
	var c := Vector2(-74, -56)
	for i in 8:
		var a := rot + TAU * i / 8.0
		var p := c + Vector2(cos(a), sin(a)) * 46
		Art.stick(ci, c, p, Color("6c7580"), 6.0, 2.5)
	Art.circle(ci, c, 48, Color(0, 0, 0, 0), 0.0)
	ci.draw_arc(c, 46, 0, TAU, 40, Art.OUTLINE, 12.0, true)
	ci.draw_arc(c, 46, 0, TAU, 40, Color("8d97a3"), 6.0, true)
	for i in 8:
		var a := rot + TAU * i / 8.0 + 0.2
		var p := c + Vector2(cos(a), sin(a)) * 52
		var bucket := Art.xform(Art.poly([-11, -9, 11, -9, 8, 9, -8, 9]), p, Vector2.ONE, a + PI * 0.5)
		Art.shape(ci, bucket, Color("d7262c"), 3.0, 0.5)
		Art.safe_poly(ci, Art.ellipse(p, 5, 3, 8, a), Color("2b2b2b"))
	Art.circle(ci, c, 12, Color("f2a20c"), 3.0)


# ---------------------------------------------------------------- Liberecký: Ještěd

static func _jested(ci: CanvasItem, t: float) -> void:
	# hyperboloid věže: dole široký, nahoře úzký
	var pts := PackedVector2Array()
	for i in 15:
		var y := -104.0 + i * 13.0
		pts.append(Vector2(12.0 + pow((y + 104.0) / 182.0, 2) * 62.0, y))
	for i in range(14, -1, -1):
		var y := -104.0 + i * 13.0
		pts.append(Vector2(-(12.0 + pow((y + 104.0) / 182.0, 2) * 62.0), y))
	Art.shape(ci, pts, Color("d6dde5"), 4.0)
	for i in 7:
		var y := -80.0 + i * 13.0
		var w := 12.0 + pow((y + 104.0) / 182.0, 2) * 62.0
		ci.draw_line(Vector2(-w + 3, y), Vector2(w - 3, y), Color(0.55, 0.62, 0.7, 0.35), 2.0, true)
	# hora pod věží
	var hill := Art.poly([-124, 120, -70, 74, 0, 64, 70, 74, 124, 120])
	Art.shape(ci, hill, Color("4f9a3a"), 4.0)
	# prstenec s okny = obličej
	Art.shape(ci, Art.rrect(Rect2(-62, 6, 124, 30), 12), Color("e9eef3"), 3.5)
	Art.eyes(ci, Vector2(0, 21), 52, 9.5, true, Vector2(0, 0.25), Color("bff3ff"))
	Art.mouth_grin(ci, Vector2(0, 46), 16, 10)
	# anténa a signál
	Art.stick(ci, Vector2(0, -104), Vector2(0, -124), Color("d7262c"), 6.0, 3.0)
	Art.circle(ci, Vector2(0, -126), 6, Color("ffe14a") if t > 0.5 else Color("ff6a2a"), 3.0)
	for r in [16, 28]:
		ci.draw_arc(Vector2(0, -126), r + (4 if t > 0.5 else 0), -PI * 0.85, -PI * 0.15, 12, Color("8fe9ff"), 4.0, true)


# ---------------------------------------------------------------- Královéhradecký: Krakonoš

static func _krakonos(ci: CanvasItem, t: float) -> void:
	_legs(ci, t, 100, 36, Color("3a2412"), 17)
	# kabát
	var coat := Art.poly([-62, -20, 62, -20, 78, 96, -78, 96])
	Art.shape(ci, Art.grow(coat, 8), Color("2f7a4a"), 4.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-72, 40, 144, 12), 4), Color("6b3e1c"))
	# hůl
	Art.stick(ci, Vector2(96, 100), Vector2(104, -96), Color("7a4a24"), 10.0, 3.5)
	Art.blob(ci, Vector2(104, -104), 14, 14, Color("8fe9ff") if t > 0.5 else Color("bff3ff"), 3.0)
	_arm(ci, Vector2(60, -6), Vector2(96, 10), Color("2f7a4a"), 22)
	_arm(ci, Vector2(-60, -6), Vector2(-92, 34), Color("2f7a4a"), 22)
	# hlava a dlouhé vousy
	Art.blob(ci, Vector2(0, -50), 46, 42, Color("f2b98a"), 4.0)
	var beard := Art.poly([-44, -46, 44, -46, 40, 0, 20, 50, 0, 70, -20, 50, -40, 0])
	Art.shape(ci, beard, Color("f2f2f2"), 3.5, 0.5)
	for i in 4:
		ci.draw_line(Vector2(-24 + i * 16, -20), Vector2(-16 + i * 10, 40), Color(0.75, 0.75, 0.8, 0.6), 2.0, true)
	Art.eyes(ci, Vector2(0, -60), 34, 9.0, true)
	Art.blob(ci, Vector2(0, -46), 9, 8, Color("ff9a8a"), 3.0, 0.5)
	var st := Art.poly([0, -40, 32, -42, 40, -30, 24, -34, 0, -34])
	Art.shape(ci, st, Color("e6e6e6"), 3.0, 0.4)
	Art.shape(ci, Art.xform(st, Vector2.ZERO, Vector2(-1, 1)), Color("e6e6e6"), 3.0, 0.4)
	# klobouk s pérem
	Art.shape(ci, Art.ellipse(Vector2(0, -86), 62, 14, 28), Color("3a2a1a"), 4.0, 0.4)
	Art.shape(ci, Art.rrect(Rect2(-34, -122, 68, 38), 14), Color("3a2a1a"), 4.0, 0.4)
	var feather := Art.poly([24, -100, 50, -140, 58, -136, 34, -98])
	Art.shape(ci, feather, Color("d7262c"), 3.0, 0.4)


# ---------------------------------------------------------------- Pardubický: Perníková ježibaba

static func _jezibaba(ci: CanvasItem, t: float) -> void:
	# koště
	Art.stick(ci, Vector2(-100, 90), Vector2(80, -40), Color("9a5b2a"), 8.0, 3.0)
	var bristle := Art.xform(Art.poly([0, -16, 40, -26, 44, 0, 40, 26, 0, 16]), Vector2(-112, 98), Vector2(-1, 1), -0.62)
	Art.shape(ci, bristle, Color("e8c060"), 3.0, 0.5)
	# sukně a tělo
	var dress := Art.poly([-50, -10, 50, -10, 76, 100, -76, 100])
	Art.shape(ci, Art.grow(dress, 6), Color("6a3a9a"), 4.0)
	for i in 5:
		Art.safe_poly(ci, Art.star(Vector2(-50 + i * 25, 60 + (i % 2) * 18), 6, 3, 5), Color("ffd23f"))
	var apron := Art.poly([-30, 10, 30, 10, 40, 96, -40, 96])
	Art.shape(ci, apron, Color("f6e7c4"), 3.0, 0.4)
	# perníkové srdce v ruce
	_arm(ci, Vector2(46, 0), Vector2(78, 24), Color("6a3a9a"), 18)
	Art.icon_heart(ci, Vector2(92, 30), 20, Color("b86b2c"))
	ci.draw_arc(Vector2(92, 28), 10, 0.3, PI - 0.3, 10, Color.WHITE, 2.5, true)
	# hlava, nos, šátek
	Art.blob(ci, Vector2(0, -50), 40, 38, Color("c8d9a0"), 4.0)
	var nose := Art.poly([4, -56, 30, -30, 34, -20, 22, -26, 4, -40])
	Art.shape(ci, nose, Color("b8c98a"), 3.0, 0.5)
	Art.circle(ci, Vector2(26, -26), 3.5, Color("8a6a3a"), 1.5)
	Art.eyes(ci, Vector2(-4, -60), 30, 8.5, true, Vector2(0.4, 0.2), Color("ffe14a"))
	Art.mouth_grin(ci, Vector2(-6, -24), 14, 8)
	var scarf := Art.poly([-46, -54, -40, -86, 0, -100, 40, -86, 46, -54, 30, -76, 0, -84, -30, -76])
	Art.shape(ci, scarf, Color("d7262c"), 3.5, 0.5)
	for d in [[-24, -84], [0, -92], [24, -84]]:
		Art.circle(ci, Vector2(d[0], d[1]), 4, Color.WHITE, 0.0)


# ---------------------------------------------------------------- Středočeský: Velitel blanických rytířů

static func _blanik(ci: CanvasItem, t: float) -> void:
	_legs(ci, t, 100, 40, Color("6c7580"), 18)
	var steel := Color("c3ccd6")
	# korouhev
	Art.stick(ci, Vector2(-96, 100), Vector2(-96, -120), Color("7a4a24"), 7.0, 3.0)
	var flag := Art.poly([-94, -118, -34, -110, -42, -92, -34, -74, -94, -80])
	Art.shape(ci, flag, Color("d7262c"), 3.0, 0.5)
	Art.safe_poly(ci, Art.star(Vector2(-66, -96), 9, 4), Color.WHITE)
	# brnění
	Art.shape(ci, Art.rrect(Rect2(-60, -20, 120, 110), 30), steel, 4.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-60, 40, 120, 12), 3), Color("6b3e1c"))
	Art.circle(ci, Vector2(0, 46), 9, Art.GOLD, 3.0)
	# meč
	var hand := Vector2(78, 20 + (t - 0.5) * 8)
	Art.stick(ci, hand + Vector2(4, -10), hand + Vector2(28, -130), Color("eef3f7"), 13.0, 3.5)
	Art.stick(ci, hand + Vector2(-16, -6), hand + Vector2(20, 2), Art.GOLD, 8.0, 3.0)
	_arm(ci, Vector2(52, -4), hand, steel, 22)
	_arm(ci, Vector2(-52, -4), Vector2(-90, 20), steel, 22)
	# přilba
	var helm := Art.rrect(Rect2(-44, -112, 88, 96), 30)
	Art.shape(ci, helm, steel, 4.0)
	Art.flat(ci, Art.rrect(Rect2(-32, -74, 64, 12), 4), Color("1a1a1a"), 3.0)
	for s: int in [-1, 1]:
		Art.circle(ci, Vector2(s * 15, -68), 5, Color("7dff8a") if t > 0.5 else Color("bfffc8"), 0.0)
	ci.draw_line(Vector2(0, -112), Vector2(0, -20), Color("8d97a3"), 4.0, true)
	for i in 3:
		Art.circle(ci, Vector2(-14 + i * 14, -40), 2.5, Color("4a5058"), 0.0)
	var plume := Art.poly([-8, -112, 0, -146, 30, -150, 40, -134, 14, -124, 8, -112])
	Art.shape(ci, plume, Color("d7262c"), 3.5)
	_crown(ci, Vector2(0, -116), 22)


# ---------------------------------------------------------------- Praha: Orloj

static func _orloj(ci: CanvasItem, t: float) -> void:
	# kamenná věž
	Art.shape(ci, Art.rrect(Rect2(-90, -110, 180, 220), 12), Color("b8a88a"), 4.0)
	for row in 7:
		for col in 4:
			var off := 22.0 if row % 2 == 0 else 0.0
			Art.safe_poly(ci, Art.rrect(Rect2(-86 + col * 45 + off * 0.5, -104 + row * 31, 40, 26), 3), Color(1, 1, 1, 0.07))
	# střecha
	var roof := Art.poly([-100, -104, 0, -150, 100, -104])
	Art.shape(ci, roof, Color("3a5a4a"), 4.0)
	Art.circle(ci, Vector2(0, -152), 7, Art.GOLD, 3.0)
	# astronomický ciferník
	var c := Vector2(0, -18)
	Art.circle(ci, c, 72, Art.GOLD, 4.0)
	Art.circle(ci, c, 62, Color("2a5ab8"), 2.0)
	Art.safe_poly(ci, Art.ring_sector(c, 30, 62, 0, PI, 24), Color("1a2a5a"))
	Art.safe_poly(ci, Art.ring_sector(c, 30, 62, PI * 0.85, PI * 1.15, 6), Color("d98e04"))
	ci.draw_arc(c + Vector2(0, -12), 40, 0, TAU, 36, Art.GOLD, 3.0, true)
	for i in 12:
		var a := TAU * i / 12.0
		Art.circle(ci, c + Vector2(cos(a), sin(a)) * 67, 3.5, Color("fff3b0"), 1.5)
	# ručičky
	var rot := 0.25 if t > 0.5 else 0.0
	for h in [[-PI * 0.4 + rot, 54, 7.0], [PI * 0.2 - rot * 2, 40, 9.0]]:
		var tip: Vector2 = c + Vector2(cos(h[0]), sin(h[0])) * h[1]
		Art.stick(ci, c, tip, Art.GOLD, h[2], 3.0)
		Art.shape(ci, Art.star(tip, 9, 4), Art.GOLD, 2.5, 0.4)
	Art.circle(ci, c + Vector2(30, 6), 10, Color("fff3b0"), 3.0)
	Art.eyes(ci, c + Vector2(0, -22), 46, 11.0, true, Vector2(0, 0.2))
	# Smrtka se zvonkem
	var sk := Vector2(-74, 70)
	Art.blob(ci, sk + Vector2(0, 26), 18, 26, Color("3a3a4a"), 3.0)
	Art.blob(ci, sk, 15, 14, Color("efe9d8"), 3.0)
	for s: int in [-1, 1]:
		Art.circle(ci, sk + Vector2(s * 5.5, -1), 4, Color("1a1208"), 0.0)
	var bell := sk + Vector2(26, 6 + (6 if t > 0.5 else 0))
	Art.stick(ci, sk + Vector2(10, 14), bell, Color("efe9d8"), 4.0, 2.0)
	Art.shape(ci, Art.poly([bell.x - 8, bell.y, bell.x + 8, bell.y, bell.x + 11, bell.y + 14, bell.x - 11, bell.y + 14]), Art.GOLD, 2.5, 0.5)
	# okénka apoštolů
	for s: int in [-1, 1]:
		Art.flat(ci, Art.rrect(Rect2(s * 50 - 12, -100, 24, 26), 10), Color("1a1a2a"), 3.0)
		Art.blob(ci, Vector2(s * 50, -88), 7, 7, Color("f2b98a"), 2.0, 0.4)


# ---------------------------------------------------------------- Jihočeský: Král vodníků

static func _vodnik_kral(ci: CanvasItem, t: float) -> void:
	_legs(ci, t, 100, 36, Color("2f6e2a"), 17)
	var coat := Art.poly([-60, -20, 60, -20, 74, 84, 40, 98, 0, 80, -40, 98, -74, 84])
	Art.shape(ci, Art.grow(coat, 6), Color("3fa84a"), 4.0)
	Art.safe_poly(ci, Art.poly([-8, -20, 8, -20, 6, 60, -6, 60]), Color("e2382c"))
	for i in 3:
		Art.circle(ci, Vector2(-26, 0 + i * 22), 4, Art.GOLD, 2.0)
		Art.circle(ci, Vector2(26, 0 + i * 22), 4, Art.GOLD, 2.0)
	var drip := 12.0 if t > 0.5 else 4.0
	for x in [-50, 44]:
		Art.shape(ci, Art.poly([x - 5, 96, x + 5, 96, x, 108 + drip]), Color("6fd0ff"), 2.0, 0.3)
	# hrníčky s dušičkami
	for s: int in [-1, 1]:
		var hand := Vector2(s * 98, 10 + (t - 0.5) * 8 * s)
		_arm(ci, Vector2(s * 56, -6), hand, Color("3fa84a"), 20)
		var cup := Art.poly([-16, 0, 16, 0, 12, 22, -12, 22])
		Art.shape(ci, Art.xform(cup, hand + Vector2(0, -34), Vector2(1, -1)), Color("f6f8ff"), 3.0, 0.5)
		Art.safe_poly(ci, Art.rrect(Rect2(hand.x - 14, hand.y - 30, 28, 3), 1), Color("3c6fd6"))
		Art.blob(ci, hand + Vector2(0, -12), 7, 9, Color(0.75, 0.92, 1.0, 0.85), 2.0, 0.3)
	Art.blob(ci, Vector2(0, -50), 44, 40, Color("8fd66a"), 4.0)
	Art.eyes(ci, Vector2(0, -56), 36, 10.0, true, Vector2(0, 0.25), Color("fffbe0"))
	Art.mouth_grin(ci, Vector2(0, -30), 18, 10)
	for s: int in [-1, 1]:
		Art.shape(ci, Art.poly([s * 40, -50, s * 62, -64, s * 56, -40]), Color("8fd66a"), 3.0, 0.4)
	# cylindr s korunou
	Art.shape(ci, Art.ellipse(Vector2(0, -86), 50, 12, 24), Color("2b4a2b"), 4.0, 0.4)
	Art.shape(ci, Art.rrect(Rect2(-30, -134, 60, 50), 6), Color("2b4a2b"), 4.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-30, -100, 60, 9), 2), Color("e2382c"))
	_crown(ci, Vector2(0, -146), 22)


# ---------------------------------------------------------------- Vysočina: Hřibí král

static func _hribi_kral(ci: CanvasItem, t: float) -> void:
	_legs(ci, t, 104, 34, Color("e9dcc0"), 16)
	var stem := Art.poly([-44, -10, 44, -10, 56, 70, 40, 100, -40, 100, -56, 70])
	Art.shape(ci, Art.grow(stem, 6), Color("f2e6c8"), 4.0)
	for i in 5:
		ci.draw_line(Vector2(-30 + i * 14, 20 + (i % 2) * 10), Vector2(-26 + i * 14, 34 + (i % 2) * 10), Color("cbb98a"), 3.0, true)
	for s: int in [-1, 1]:
		_arm(ci, Vector2(s * 50, 20), Vector2(s * 88, 50 + (t - 0.5) * 10 * s), Color("f2e6c8"), 20)
	Art.eyes(ci, Vector2(0, 14), 40, 10.0, true)
	var st := Art.poly([0, 36, 34, 32, 44, 44, 24, 42, 0, 42])
	Art.shape(ci, st, Color("7a4a24"), 3.0, 0.4)
	Art.shape(ci, Art.xform(st, Vector2.ZERO, Vector2(-1, 1)), Color("7a4a24"), 3.0, 0.4)
	# klobouk
	var cap := Art.arc_pts(Vector2(0, -10), 100, PI, TAU, 32)
	for i in 8:
		cap.append(Vector2(100 - i * 28.5, -6 + (6 if i % 2 == 0 else 0)))
	var capd := Art.xform(cap, Vector2.ZERO, Vector2(1, 0.72))
	Art.shape(ci, capd, Color("8a4a1c"), 4.0)
	Art.shine(ci, Vector2(-40, -54), 26, 10, 0.3)
	_crown(ci, Vector2(0, -92), 30)


# ---------------------------------------------------------------- Jihomoravský: Brněnský drak

static func _drak(ci: CanvasItem, t: float) -> void:
	var col := Color("4f9a3a")
	var st := 6.0 if t > 0.5 else -6.0
	# ocas
	var tail := Art.poly([-40, 20, -90, 10 + st, -122, -10 + st, -104, 14 + st, -70, 44, -30, 50])
	Art.shape(ci, tail, col.darkened(0.08), 4.0)
	# nohy
	for lx in [-40, -10, 30, 56]:
		var o: float = st if lx < 0 else -st
		Art.stick(ci, Vector2(lx, 40), Vector2(lx + o, 84), col.darkened(0.15), 16.0, 3.5)
		Art.blob(ci, Vector2(lx + o + 6, 88), 14, 8, col.darkened(0.2), 3.0, 0.4)
	# křídla
	var wing := Art.poly([-10, -20, -40, -100 - st, 10, -76 - st, 30, -110 - st, 50, -40])
	Art.shape(ci, wing, Color("7ac94a"), 3.5, 0.5)
	# tělo
	Art.shape(ci, Art.ellipse(Vector2(0, 20), 70, 42, 36), col, 4.0)
	for i in 5:
		Art.shape(ci, Art.poly([-50 + i * 22, -18, -40 + i * 22, -36, -30 + i * 22, -18]), Color("e8c03a"), 2.5, 0.3)
	Art.safe_poly(ci, Art.ellipse(Vector2(0, 40), 50, 16, 24), Color("c8e08a"))
	# hlava – krokodýlí čenich
	var head := Art.poly([40, -10, 80, -34, 128, -24, 130, -6, 118, 4, 128, 14, 110, 26, 60, 24])
	Art.shape(ci, head, col, 4.0)
	for i in 5:
		Art.safe_poly(ci, Art.poly([74 + i * 10, 6, 79 + i * 10, 14, 84 + i * 10, 6]), Color.WHITE)
	Art.blob(ci, Vector2(76, -34), 14, 12, col, 3.0)
	Art.circle(ci, Vector2(78, -36), 8, Color("ffe14a"), 2.5)
	Art.safe_poly(ci, Art.ellipse(Vector2(80, -36), 2.5, 6, 10), Art.OUTLINE)
	ci.draw_line(Vector2(64, -48), Vector2(88, -40), Art.OUTLINE, 5.0, true)
	Art.circle(ci, Vector2(122, -22), 3, Art.OUTLINE, 0.0)
	if t > 0.5:
		Art.blob(ci, Vector2(140, 6), 10, 7, Color("ff8a2a"), 2.5, 0.3)


# ---------------------------------------------------------------- Olomoucký: Tvarůžkový král

static func _syrovy_kral(ci: CanvasItem, t: float) -> void:
	_legs(ci, t, 104, 40, Color("c98a2a"), 16)
	var col := Color("f2b632")
	for i in 4:
		var y := 76.0 - i * 40.0
		var w := 92.0 - i * 10.0
		Art.shape(ci, Art.rrect(Rect2(-w, y - 20, w * 2, 40), 20), col.lerp(Color("e8902a"), 0.15 * i), 4.0)
		Art.safe_poly(ci, Art.ellipse(Vector2(0, y - 10), w * 0.7, 5, 20), Color(1, 1, 1, 0.22))
	for s: int in [-1, 1]:
		_arm(ci, Vector2(s * 80, 30), Vector2(s * 108, 60 + (t - 0.5) * 10 * s), col.darkened(0.1), 20)
	Art.eyes(ci, Vector2(0, 0), 50, 11.0, true)
	Art.mouth_grin(ci, Vector2(0, 26), 22, 12)
	# zápach
	var wob := 6.0 if t > 0.5 else -6.0
	for s in [-2, -1, 0, 1, 2]:
		var pts := PackedVector2Array()
		for i in 8:
			pts.append(Vector2(s * 30 + sin(i * 1.2 + wob) * 8, -76 - i * 8))
		ci.draw_polyline(pts, Art.OUTLINE, 9.0, true)
		ci.draw_polyline(pts, Color("9be05a"), 5.0, true)
	_crown(ci, Vector2(0, -88), 30)


# ---------------------------------------------------------------- Zlínský: Obří bota

static func _obri_bota(ci: CanvasItem, t: float) -> void:
	var b := 4.0 if t > 0.5 else 0.0
	var col := Color("8a4a1c")
	var boot := Art.poly([-80, -110, -10, -110, -6, -20, 60, -10, 110, 20, 116, 60, -84, 60])
	Art.shape(ci, Art.xform(Art.grow(boot, 4), Vector2(0, b)), col, 4.0)
	Art.flat(ci, Art.rrect(Rect2(-92, 56 + b, 214, 26), 10), Color("2b2b2b"), 4.0)
	for i in 7:
		Art.circle(ci, Vector2(-74 + i * 30, 82 + b), 5, Color("6c7580"), 2.0)
	# tkaničky
	for i in 5:
		var y := -90.0 + i * 18.0 + b
		ci.draw_line(Vector2(-30, y), Vector2(4, y + 10), Art.OUTLINE, 9.0, true)
		ci.draw_line(Vector2(-30, y), Vector2(4, y + 10), Color("f4f4f4"), 5.0, true)
		Art.circle(ci, Vector2(-30, y), 4, Art.GOLD, 2.0)
	Art.flat(ci, Art.rrect(Rect2(-84, -116 + b, 78, 18), 6), col.darkened(0.3), 3.0)
	Art.eyes(ci, Vector2(60, 16 + b), 40, 10.0, true, Vector2(0.4, 0.1))
	Art.mouth_grin(ci, Vector2(66, 40 + b), 16, 9)
	Art.shine(ci, Vector2(-56, -60 + b), 10, 26, 0.3, 0.1)
	# nápis na podrážce
	ci.draw_string(Art.font, Vector2(-30, 78 + b), "ZLÍN", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("8d97a3"))


# ---------------------------------------------------------------- Moravskoslezský: Vysokopecní titán

static func _pec(ci: CanvasItem, t: float) -> void:
	_legs(ci, t, 104, 46, Color("4a5058"), 18)
	var rust := Color("8a5a3a")
	# komín a kouř
	Art.shape(ci, Art.rrect(Rect2(-22, -150, 44, 60), 6), Color("6c7580"), 4.0)
	for p in [[-10, -160, 16], [14, -172, 20], [-6, -188, 14]]:
		Art.blob(ci, Vector2(p[0] + (t * 6), p[1]), p[2], p[2] * 0.8, Color("8d8d8d"), 3.0, 0.4)
	# tělo pece
	var body := Art.poly([-70, -100, 70, -100, 86, 90, -86, 90])
	Art.shape(ci, Art.grow(body, 6), Color("7d858c"), 4.0)
	for i in 4:
		Art.flat(ci, Art.rrect(Rect2(-84 + i * 2, -70 + i * 44, 168 - i * 4, 10), 3), rust, 2.5)
		for j in 6:
			Art.circle(ci, Vector2(-70 + j * 28, -65 + i * 44), 2.5, Color("c9ccd1"), 0.0)
	# žhavé jádro
	var glow := Color("ffe14a") if t > 0.5 else Color("ffb030")
	Art.outline(ci, Art.rrect(Rect2(-40, 0, 80, 60), 16), 4.0)
	Art.grad(ci, Art.rrect(Rect2(-40, 0, 80, 60), 16), glow, Color("ff4a10"))
	Art.eyes(ci, Vector2(0, -40), 50, 11.0, true, Vector2(0, 0.2), Color("ffd0a0"))
	# ruce – licí pánve
	for s: int in [-1, 1]:
		var h := Vector2(s * 112, 30 + (t - 0.5) * 10 * s)
		_arm(ci, Vector2(s * 70, -20), h, Color("6c7580"), 22)
		var ladle := Art.arc_pts(h + Vector2(0, 6), 22, 0, PI, 12)
		Art.shape(ci, ladle, Color("4a5058"), 3.0, 0.4)
		Art.safe_poly(ci, Art.ellipse(h + Vector2(0, 8), 18, 5, 14), Color("ff8a1a"))
