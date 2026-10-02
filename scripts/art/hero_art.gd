extends RefCounted
class_name HeroArt
## Hrdinové (M8). Kreslí se natočení doprava, doleva se zrcadlí. Parametr t = fáze chůze (0/1).
## Čech – bojovník v železné přilbě s chocholem a pláštěm v barvách vlajky,
## Bivoj – silák v kožichu s kyjem, Libuše – kněžna ve věnci s holí s lipovým listem,
## Horymír – jezdec na bílém koni Šemíkovi (větší kresba).

const SIZE := Vector2(130, 164)
const SIZES := {"cech": Vector2(130, 164), "bivoj": Vector2(140, 168), "libuse": Vector2(130, 168), "horymir": Vector2(200, 200)}
const SKIN := Color("f5bf8e")
const BEARD := Color("9a521f")
const STEEL := Color("c3ccd6")
const TUNIC := Color("2f6ad1")
const CAPE_RED := Color("d7262c")


static func size_of(id: String) -> Vector2:
	return SIZES.get(id, SIZE)


static func draw(ci: CanvasItem, t: float, id: String = "cech") -> void:
	match id:
		"bivoj":
			_bivoj(ci, t)
		"libuse":
			_libuse(ci, t)
		"horymir":
			_horymir(ci, t)
		_:
			_cech(ci, t)


static func _cech(ci: CanvasItem, t: float) -> void:
	var step := 1.0 if t > 0.5 else -1.0
	# plášť (za tělem) – bílá a červená, vlaje dozadu
	var cape := Art.poly([-6, -14, -34, 34 + step * 3, -22, 40, -4, 38, 8, 0])
	Art.shape(ci, cape, CAPE_RED, 3.0)
	var cape_w := Art.poly([-6, -14, -24, 8, -12, 10, 4, -6])
	Art.safe_poly(ci, cape_w, Color("f6f6f6"))
	# nohy
	for s: int in [-1, 1]:
		var lx: float = s * 9.0
		var ly := 36.0 + step * s * 3.0
		Art.stick(ci, Vector2(lx, 24), Vector2(lx + step * s * 2.0, ly), Color("5a3a22"), 9.0, 2.5)
		Art.blob(ci, Vector2(lx + 4.0 + step * s * 2.0, ly + 4.0), 9.5, 6.0, Color("7a4520"), 2.5)
	# zadní ruka
	_arm(ci, Vector2(-14, 4), Vector2(-24, 18 - step * 2))
	# tělo – modrá tunika s opaskem a sponou
	Art.shape(ci, Art.ellipse(Vector2(0, 12), 22, 20, 32), TUNIC, 3.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-21, 17, 42, 7), 3), Color("6b3e1c"))
	Art.circle(ci, Vector2(0, 20.5), 4.5, Art.GOLD, 2.0)
	Art.safe_poly(ci, Art.ellipse(Vector2(0, -4), 15, 6, 18), Color("9aa7b4"))
	# hlava
	Art.blob(ci, Vector2(3, -20), 22, 21, SKIN, 3.0)
	Art.blob(ci, Vector2(-17, -18), 4.5, 6, SKIN.darkened(0.06), 2.0, 0.3)
	# vous (pod pusou)
	var beard := Art.poly([-10, -9, 18, -9, 16, 1, 8, 9, 2, 10, -6, 4])
	Art.shape(ci, beard, BEARD, 2.5, 0.6)
	# oči a nos
	Art.eyes(ci, Vector2(7, -21), 15, 4.6, true, Vector2(0.55, 0.15))
	Art.blob(ci, Vector2(13, -13), 5.5, 5, SKIN.darkened(0.1), 2.0, 0.5)
	# knír
	for s: int in [-1, 1]:
		var tip := Vector2(10 + s * 14, -5)
		var st := Art.poly([10, -10, tip.x, tip.y - 3, tip.x + s * 3, tip.y + 3, 10, -5])
		Art.shape(ci, st, BEARD.darkened(0.1), 2.0, 0.4)
	# přilba s chocholem
	var helm := Art.arc_pts(Vector2(3, -33), 23.5, PI * 1.0, TAU, 20)
	helm.append(Vector2(26.5, -30))
	helm.append(Vector2(-20.5, -30))
	Art.shape(ci, helm, STEEL, 3.0)
	Art.flat(ci, Art.rrect(Rect2(-22, -36, 51, 7), 3), Art.GOLD, 2.0)
	for i in 4:
		Art.circle(ci, Vector2(-14 + i * 12, -32.5), 1.6, Color("fff1a8"), 0.0)
	var plume := Art.poly([-4, -54, 0, -66, 12, -72, 22, -66, 10, -60, 6, -54])
	Art.shape(ci, plume, CAPE_RED, 2.5)
	Art.circle(ci, Vector2(2, -55), 4, Art.GOLD, 2.0)
	# přední ruka s mečem
	var hand := Vector2(24, 12 + step)
	var tip2 := hand + Vector2(18, -34)
	Art.stick(ci, hand.lerp(tip2, 0.12), tip2, Color("eef3f7"), 6.5, 2.5)
	ci.draw_line(hand.lerp(tip2, 0.2), tip2.lerp(hand, 0.1), Color("aab8c4"), 1.5, true)
	Art.stick(ci, hand + Vector2(-7, -3), hand + Vector2(7, 4), Art.GOLD, 4.5, 2.0)
	_arm(ci, Vector2(14, 4), hand)


static func _arm(ci: CanvasItem, a: Vector2, b: Vector2) -> void:
	Art.stick(ci, a, b, SKIN, 9.0, 2.5)
	Art.circle(ci, b, 6.0, SKIN, 2.5)


# ---------------------------------------------------------------- Bivoj

static func _bivoj(ci: CanvasItem, t: float) -> void:
	var step := 1.0 if t > 0.5 else -1.0
	var fur := Color("c08a4e")
	var hair := Color("4a2a12")
	# nohy v onucích
	for s: int in [-1, 1]:
		var lx: float = s * 11.0
		var ly := 38.0 + step * s * 3.0
		Art.stick(ci, Vector2(lx, 24), Vector2(lx + step * s * 2.0, ly), Color("c9a77a"), 11.0, 2.5)
		for k in 3:
			ci.draw_line(Vector2(lx - 5, 27 + k * 4), Vector2(lx + 5, 29 + k * 4), Color("7a5230"), 2.0, true)
		Art.blob(ci, Vector2(lx + 4.0 + step * s * 2.0, ly + 4.0), 10.5, 6.5, Color("6b3e1c"), 2.5)
	# zadní holá paže
	_arm_thick(ci, Vector2(-18, 0), Vector2(-28, 18 - step * 2))
	# kožich
	Art.shape(ci, Art.ellipse(Vector2(0, 10), 27, 24, 32), fur, 3.0)
	for i in 7:
		var a := PI * 0.15 + i * 0.42
		Art.blob(ci, Vector2(cos(a) * 25.0, 10 + sin(a) * 22.0), 6, 5, fur.lightened(0.15), 2.0, 0.3)
	Art.safe_poly(ci, Art.rrect(Rect2(-25, 16, 50, 6), 3), Color("c9a77a"))
	# tesák kance na šňůrce
	Art.shape(ci, Art.poly([2, -4, 10, -2, 4, 6]), Color("f6f0e0"), 2.0, 0.3)
	# hlava, rozcuchané vlasy a mohutný vous
	Art.blob(ci, Vector2(4, -22), 21, 20, HeroArt.SKIN, 3.0)
	for p: Vector2 in [Vector2(-14, -34), Vector2(-4, -41), Vector2(9, -41), Vector2(-19, -22)]:
		Art.blob(ci, Vector2(p.x + 2, p.y), 10, 8, hair, 2.5, 0.4)
	var beard := Art.poly([-10, -12, 22, -11, 19, 2, 10, 12, 0, 14, -7, 7, -12, -2])
	Art.shape(ci, beard, hair, 2.5, 0.6)
	Art.eyes(ci, Vector2(8, -24), 15, 4.6, true, Vector2(0.55, 0.15))
	Art.blob(ci, Vector2(15, -16), 5.5, 5, HeroArt.SKIN.darkened(0.1), 2.0, 0.5)
	# přední paže s kyjem
	var hand := Vector2(28, 10 + step)
	var club_top := hand + Vector2(16, -44)
	Art.stick(ci, hand + Vector2(-2, 4), club_top, Color("8a5a2e"), 9.0, 2.5)
	Art.blob(ci, club_top, 13, 11, Color("9a6a36"), 3.0, 0.7)
	for k: Vector2 in [Vector2(-6, -4), Vector2(5, 3), Vector2(2, -8)]:
		ci.draw_circle(club_top + k, 2.2, Color("5a3418"))
	_arm_thick(ci, Vector2(18, 0), hand)


static func _arm_thick(ci: CanvasItem, a: Vector2, b: Vector2) -> void:
	Art.stick(ci, a, b, HeroArt.SKIN, 12.0, 2.5)
	Art.circle(ci, b, 7.5, HeroArt.SKIN, 2.5)


# ---------------------------------------------------------------- Libuše

static func _libuse(ci: CanvasItem, t: float) -> void:
	var step := 1.0 if t > 0.5 else -1.0
	var braid := Color("c9873a")
	# modrý plášť za tělem
	var cape := Art.poly([-4, -14, -32, 40 + step * 3, -10, 44, 8, -2])
	Art.shape(ci, cape, Color("2f6ad1"), 3.0)
	# cop vzadu
	for i in 5:
		Art.blob(ci, Vector2(-16 - i * 1.5, -14 + i * 9), 6.5, 5.5, braid, 2.0, 0.5)
	# bílé šaty
	var dress := Art.poly([-14, -6, 16, -6, 26, 40, -22, 40])
	Art.shape(ci, dress, Color("f6f3ea"), 3.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-16, 6, 34, 5), 2), Color("3a6fb5"))
	ci.draw_polyline(Art.poly([-20, 34, 24, 34]), Color("c9a24a"), 3.0, true)
	for s: int in [-1, 1]:
		Art.blob(ci, Vector2(s * 9.0 + 4.0 + step * s * 2.0, 43), 7.5, 4.5, Color("8a5a2e"), 2.0)
	# zadní ruka
	Art.stick(ci, Vector2(-12, -2), Vector2(-20, 16 - step * 2), Color("f6f3ea"), 8.0, 2.5)
	Art.circle(ci, Vector2(-20, 16 - step * 2), 5.0, HeroArt.SKIN, 2.0)
	# hlava
	Art.blob(ci, Vector2(3, -22), 19, 19, HeroArt.SKIN, 3.0)
	var hair_cap := Art.arc_pts(Vector2(1, -24), 20, PI * 0.95, TAU * 0.97, 18)
	hair_cap.append(Vector2(-12, -14))
	Art.shape(ci, hair_cap, braid, 2.5, 0.5)
	Art.eyes(ci, Vector2(8, -22), 14, 4.4, false, Vector2(0.55, 0.15))
	ci.draw_arc(Vector2(10, -13), 4.0, 0.2, PI - 0.2, 8, Color("8a3a2a"), 2.0, true)
	ci.draw_circle(Vector2(18, -15), 3.0, Color(1, 0.5, 0.5, 0.35))
	# věnec z listí a kvítí
	for i in 9:
		var a := PI * 1.02 + i * 0.13
		var p := Vector2(2, -26) + Vector2(cos(a), sin(a) * 0.75) * 21.0
		Art.shape(ci, Art.ellipse(p, 7, 4, 10, a + PI * 0.5), Color("4f9a3a"), 1.5, 0.3)
	for i in 4:
		var a := PI * 1.12 + i * 0.27
		var p := Vector2(2, -26) + Vector2(cos(a), sin(a) * 0.75) * 21.0
		Art.circle(ci, p + Vector2(0, -2), 4.0, Color("e2382c") if i % 2 == 0 else Color.WHITE, 1.5)
		ci.draw_circle(p + Vector2(0, -2), 1.5, Art.GOLD)
	# hůl s lipovým listem
	var hand := Vector2(22, 10 + step)
	Art.stick(ci, hand + Vector2(-2, 30), hand + Vector2(4, -50), Color("8a5a2e"), 5.5, 2.5)
	var leaf := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var r := 11.0 * (1.0 - sin(a) * 0.15) * (0.75 + 0.25 * absf(cos(a)))
		leaf.append(hand + Vector2(4, -62) + Vector2(cos(a) * r, sin(a) * r * 1.1 + (absf(cos(a * 0.5)) * -3.0)))
	Art.shape(ci, leaf, Color("6fcf2f"), 2.5, 0.6)
	ci.draw_line(hand + Vector2(4, -52), hand + Vector2(4, -70), Color("3f9020"), 1.5, true)
	Art.stick(ci, Vector2(12, -2), hand, Color("f6f3ea"), 8.0, 2.5)
	Art.circle(ci, hand, 5.5, HeroArt.SKIN, 2.0)


# ---------------------------------------------------------------- Horymír na Šemíkovi

static func _horymir(ci: CanvasItem, t: float) -> void:
	var g := 1.0 if t > 0.5 else -1.0
	var white := Color("eef2f6")
	var mane := Color("aab3bd")
	# ocas a zadní nohy
	var tail := Art.poly([-44, -6, -66, 10 + g * 3, -62, 30, -50, 20, -40, 0])
	Art.shape(ci, tail, mane, 2.5, 0.5)
	for s: int in [-1, 1]:
		var x := -28.0 + s * 6.0
		var sw := g * s * 6.0
		Art.stick(ci, Vector2(x, 10), Vector2(x + sw, 42), white.darkened(0.08), 9.0, 2.5)
		Art.blob(ci, Vector2(x + sw + 2, 45), 6.5, 4.0, Color("5a5a60"), 2.0, 0.3)
		var fx := 26.0 + s * 6.0
		Art.stick(ci, Vector2(fx, 10), Vector2(fx - sw, 42), white.darkened(0.08), 9.0, 2.5)
		Art.blob(ci, Vector2(fx - sw + 2, 45), 6.5, 4.0, Color("5a5a60"), 2.0, 0.3)
	# tělo koně
	Art.shape(ci, Art.ellipse(Vector2(0, 2), 50, 22, 36), white, 3.0)
	# krk a hlava
	var neck := Art.poly([30, -8, 50, -46, 64, -42, 52, 4])
	Art.shape(ci, neck, white, 3.0)
	Art.shape(ci, Art.ellipse(Vector2(70, -42), 19, 10, 24, 0.6), white, 3.0)
	Art.shape(ci, Art.poly([52, -54, 55, -68, 61, -55]), white, 2.5, 0.5)
	for i in 5:
		Art.blob(ci, Vector2(47.0 - i * 4.0, -50.0 + i * 9.0), 6.0, 5.0, mane, 2.0, 0.4)
	Art.eyes(ci, Vector2(70, -52), 1.0, 3.5, false, Vector2(0.6, 0.1))
	ci.draw_circle(Vector2(82, -40), 2.0, Color("5a5a60"))
	# sedlo s čabrakou a uzda
	Art.shape(ci, Art.rrect(Rect2(-18, -24, 34, 22), 6), Color("c0392b"), 2.5, 0.6)
	ci.draw_polyline(Art.poly([-16, -6, 14, -6]), Art.GOLD, 2.5, true)
	ci.draw_polyline(Art.poly([16, -30, 50, -46, 76, -44]), Color("5a3418"), 2.5, true)
	# jezdec Horymír
	Art.stick(ci, Vector2(2, -26), Vector2(10, -2), Color("4a6a3a"), 10.0, 2.5)
	Art.blob(ci, Vector2(12, 4), 7.0, 4.5, Color("5a3418"), 2.0)
	Art.shape(ci, Art.ellipse(Vector2(0, -40), 15, 18, 28), Color("2f8a4a"), 3.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-14, -32, 28, 5), 2), Color("6b3e1c"))
	Art.blob(ci, Vector2(3, -66), 15, 15, HeroArt.SKIN, 3.0)
	Art.eyes(ci, Vector2(7, -67), 11, 3.8, true, Vector2(0.6, 0.15))
	for s: int in [-1, 1]:
		var tip := Vector2(9 + s * 10, -57)
		Art.shape(ci, Art.poly([9, -61, tip.x, tip.y - 2, tip.x + s * 2, tip.y + 2, 9, -57]), HeroArt.BEARD.darkened(0.1), 1.5, 0.4)
	# klobouk s pérem
	Art.shape(ci, Art.ellipse(Vector2(2, -78), 20, 5, 20), Color("3a5a2a"), 2.5, 0.5)
	Art.shape(ci, Art.rrect(Rect2(-10, -94, 22, 16), 6), Color("4a6a3a"), 2.5, 0.6)
	Art.shape(ci, Art.ellipse(Vector2(-10, -94), 4, 14, 16, -0.6), Color("e2382c"), 2.0, 0.5)
	# ruka s otěžemi
	Art.stick(ci, Vector2(8, -42), Vector2(22, -30), Color("2f8a4a"), 7.0, 2.5)
	Art.circle(ci, Vector2(22, -30), 4.5, HeroArt.SKIN, 2.0)
