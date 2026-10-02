extends RefCounted
class_name HazardArt
## Kresby nástrah krajů (sud, kůň s žokejem, tramvaj, kombajn, kámen z katapultu…).
## Vozidla a koně jsou kreslení z boku a jedou doprava, doleva se zrcadlí.
## Bod (0,0) je u vozidel a koní na zemi uprostřed, u malých předmětů uprostřed.

const SIZES := {
	"sud": Vector2(90, 90),
	"kun": Vector2(210, 200),
	"tramvaj": Vector2(500, 210),
	"kombajn": Vector2(300, 220),
	"kamen": Vector2(84, 80),
	"balik": Vector2(90, 80),
	"svestka": Vector2(40, 46),
	"uhli": Vector2(56, 48),
	"hribek": Vector2(40, 40),
}
## Předměty, které stojí na zemi (origin dole), ostatní mají origin uprostřed.
const GROUNDED := ["kun", "tramvaj", "kombajn", "balik"]


static func size_of(id: String) -> Vector2:
	return SIZES.get(id, Vector2(80, 80))


static func origin_of(id: String) -> Vector2:
	if id in GROUNDED:
		var s := size_of(id)
		return Vector2(0.5, (s.y - 18.0) / s.y)
	return Vector2(0.5, 0.5)


static func draw(ci: CanvasItem, id: String, t: float) -> void:
	var fn := Callable(HazardArt, "_" + id)
	if fn.is_valid():
		fn.call(ci, t)


# ---------------------------------------------------------------- Plzeňsko

## Sud viděný z čela, při kutálení se otáčí.
static func _sud(ci: CanvasItem, _t: float) -> void:
	Art.circle(ci, Vector2.ZERO, 34, Color("8d97a3"), 3.5)
	Art.circle(ci, Vector2.ZERO, 27, Color("b06a2c"), 2.5)
	for x in [-14, -5, 4, 13]:
		ci.draw_line(Vector2(x, -sqrt(maxf(0.0, 27.0 * 27.0 - x * x)) + 2), Vector2(x, sqrt(maxf(0.0, 27.0 * 27.0 - x * x)) - 2), Color("7a4418"), 2.0, true)
	ci.draw_circle(Vector2(-8, -10), 9, Color(1, 1, 1, 0.18))
	Art.circle(ci, Vector2(10, 8), 5, Color("5a2c0a"), 2.0)
	for i in 8:
		var a := TAU * i / 8.0
		ci.draw_circle(Vector2(cos(a), sin(a)) * 30.5, 2.2, Color("e0e6ec"))


# ---------------------------------------------------------------- Pardubicko

## Dostihový kůň s žokejem. t = fáze cvalu (0/1).
static func _kun(ci: CanvasItem, t: float) -> void:
	var k := 1.0 if t > 0.5 else 0.0
	Art.shadow(ci, Vector2(0, 0), 62, 12, 0.25)
	var body_col := Color("8a4a1c")
	var leg_col := body_col.darkened(0.15)
	# nohy (zadní pár)
	var legs := [[-40, -54, -58 + k * 26, -4], [34, -54, 52 - k * 26, -4]]
	for l in legs:
		Art.stick(ci, Vector2(l[0], l[1]), Vector2(l[2], l[3]), leg_col.darkened(0.15), 9.0, 2.5)
	# ocas
	var tail := Art.poly([-58, -78, -86, -70, -96, -40, -80, -48, -66, -62])
	Art.shape(ci, tail, Color("3a2210"), 2.5, 0.5)
	# tělo
	Art.blob(ci, Vector2(-4, -72), 60, 26, body_col, 3.0)
	# krk a hlava
	var neck := Art.poly([30, -88, 56, -128, 74, -122, 58, -78])
	Art.shape(ci, neck, body_col, 3.0, 0.6)
	var head := Art.poly([52, -132, 70, -146, 98, -120, 96, -110, 72, -112])
	Art.shape(ci, head, body_col, 3.0, 0.6)
	Art.shape(ci, Art.poly([60, -144, 64, -158, 70, -142]), body_col, 2.0, 0.4)
	Art.eyes(ci, Vector2(76, -128), 0, 3.6, false, Vector2(0.6, 0.0))
	# hříva
	for i in 4:
		var c := Vector2(48 - i * 5, -132 + i * 12)
		Art.blob(ci, c, 7, 9, Color("3a2210"), 2.0, 0.3)
	# nohy (přední pár)
	var legs2 := [[-26, -54, -36 - k * 22, -2], [44, -56, 66 + k * 18 - 18, -2]]
	for l in legs2:
		Art.stick(ci, Vector2(l[0], l[1]), Vector2(l[2], l[3]), leg_col, 9.0, 2.5)
		ci.draw_circle(Vector2(l[2], l[3]), 5, Art.OUTLINE)
	# sedlo a dečka s číslem
	Art.flat(ci, Art.rrect(Rect2(-28, -96, 40, 30), 6), Color("ffffff"), 2.5)
	Art.text(ci, Vector2(-8, -74), str(3 + int(k) * 4), 18, Color("d7262c"), 4)
	# žokej
	Art.stick(ci, Vector2(-6, -100), Vector2(-14, -80), Color("f2e8d8"), 8.0, 2.0)
	Art.blob(ci, Vector2(4, -114), 15, 14, Color("ffd23f"), 3.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-6, -122, 20, 6), 2), Color("d7262c"))
	Art.blob(ci, Vector2(20, -136), 11, 11, Color("f5bf8e"), 2.5)
	var cap := Art.arc_pts(Vector2(20, -140), 12, PI, TAU, 12)
	cap.append(Vector2(36, -140))
	Art.shape(ci, cap, Color("d7262c"), 2.5, 0.5)
	Art.stick(ci, Vector2(14, -112), Vector2(46, -116), Color("ffd23f"), 6.0, 2.0)


# ---------------------------------------------------------------- Praha

## Pražská tramvaj (červená s krémovým pruhem), jede doprava.
static func _tramvaj(ci: CanvasItem, _t: float) -> void:
	Art.shadow(ci, Vector2(0, 0), 230, 16, 0.3)
	var red := Color("d7262c")
	var cream := Color("f6e7c4")
	# spodek a podvozky
	for x in [-150, 150]:
		Art.flat(ci, Art.rrect(Rect2(x - 40, -22, 80, 20), 6), Color("3a3a40"), 2.5)
		for wx in [-22, 22]:
			Art.circle(ci, Vector2(x + wx, -6), 9, Color("5a5f66"), 2.0)
	# skříň
	var body := Art.rrect(Rect2(-225, -128, 450, 108), 22)
	Art.shape(ci, body, red, 3.5, 0.6)
	# krémový pás s okny
	Art.flat(ci, Art.rrect(Rect2(-218, -116, 436, 50), 14), cream, 2.5)
	for i in 8:
		var x := -200.0 + i * 50.0
		if i == 2 or i == 5:
			continue
		Art.flat(ci, Art.rrect(Rect2(x, -110, 38, 36), 6), Color("8fd0f2"), 2.0)
		Art.safe_poly(ci, Art.poly([x + 4, -106, x + 18, -106, x + 6, -80]), Color(1, 1, 1, 0.5))
	# dveře
	for x in [-100, 50]:
		Art.flat(ci, Art.rrect(Rect2(x, -112, 40, 88), 5), Color("b81d22"), 2.5)
		Art.flat(ci, Art.rrect(Rect2(x + 5, -106, 13, 44), 3), Color("8fd0f2"), 1.5)
		Art.flat(ci, Art.rrect(Rect2(x + 22, -106, 13, 44), 3), Color("8fd0f2"), 1.5)
	# čelo s oknem řidiče a světlem
	Art.flat(ci, Art.rrect(Rect2(186, -116, 34, 46), 10), Color("8fd0f2"), 2.0)
	ci.draw_circle(Vector2(214, -40), 7, Color("fff6a0"))
	ci.draw_arc(Vector2(214, -40), 7, 0, TAU, 16, Art.OUTLINE, 2.0, true)
	# tabule s číslem linky
	Art.flat(ci, Art.rrect(Rect2(160, -140, 56, 16), 4), Color("2a1a0c"), 2.0)
	Art.text(ci, Vector2(188, -127), "22", 14, Color("ffd23f"), 2)
	# střecha a sběrač
	Art.flat(ci, Art.rrect(Rect2(-180, -138, 300, 12), 5), Color("c3ccd6"), 2.5)
	var pan := PackedVector2Array([Vector2(-60, -138), Vector2(-20, -170), Vector2(20, -138)])
	ci.draw_polyline(pan, Art.OUTLINE, 5.0, true)
	ci.draw_polyline(pan, Color("8d97a3"), 2.5, true)
	Art.stick(ci, Vector2(-50, -172), Vector2(10, -172), Color("8d97a3"), 4.0, 2.0)
	# lesk
	Art.safe_poly(ci, Art.rrect(Rect2(-210, -124, 380, 6), 3), Color(1, 1, 1, 0.3))


# ---------------------------------------------------------------- Olomoucko

## Kombajn s otáčivým přiháněčem vpředu (vpravo). t = fáze otáčení.
static func _kombajn(ci: CanvasItem, t: float) -> void:
	Art.shadow(ci, Vector2(0, 0), 130, 16, 0.3)
	var green := Color("3faa3a")
	# zadní kolo a přední kolo
	Art.circle(ci, Vector2(-80, -30), 28, Color("2f2f33"), 3.0)
	Art.circle(ci, Vector2(-80, -30), 13, Color("ffd23f"), 2.0)
	# tělo
	var body := Art.poly([-120, -40, -120, -120, -40, -130, 40, -130, 70, -100, 70, -40])
	Art.shape(ci, body, green, 3.5)
	# kabina
	Art.shape(ci, Art.rrect(Rect2(-10, -186, 64, 58), 10), green.lightened(0.05), 3.0, 0.6)
	Art.flat(ci, Art.rrect(Rect2(-2, -178, 48, 34), 6), Color("8fd0f2"), 2.0)
	Art.safe_poly(ci, Art.poly([2, -174, 18, -174, 6, -150]), Color(1, 1, 1, 0.55))
	ci.draw_circle(Vector2(22, -192), 6, Color("ffb030"))
	ci.draw_arc(Vector2(22, -192), 6, 0, TAU, 12, Art.OUTLINE, 2.0, true)
	# výsypná roura
	Art.stick(ci, Vector2(-110, -120), Vector2(-60, -158), Color("2e8a2e"), 12.0, 3.0)
	# přední kolo
	Art.circle(ci, Vector2(30, -36), 36, Color("2f2f33"), 3.0)
	Art.circle(ci, Vector2(30, -36), 17, Color("ffd23f"), 2.0)
	# žací lišta a přiháněč
	Art.flat(ci, Art.rrect(Rect2(70, -46, 72, 22), 6), Color("ffd23f"), 2.5)
	for i in 7:
		Art.stick(ci, Vector2(76 + i * 10, -26), Vector2(80 + i * 10, -14), Color("c3ccd6"), 3.0, 1.5)
	var rc := Vector2(112, -74)
	Art.circle(ci, rc, 34, Color(0, 0, 0, 0), 0.0)
	for i in 5:
		var a := TAU * i / 5.0 + t * 0.6
		var p := rc + Vector2(cos(a), sin(a)) * 30.0
		Art.stick(ci, rc, p, Color("e2382c"), 4.0, 2.0)
		Art.stick(ci, p + Vector2(-6, 0).rotated(a), p + Vector2(6, 0).rotated(a), Color("ffd23f"), 4.0, 1.5)
	Art.circle(ci, rc, 7, Color("e2382c"), 2.0)
	Art.stick(ci, Vector2(60, -96), rc, Color("2e8a2e"), 6.0, 2.0)
	# lesk
	Art.safe_poly(ci, Art.poly([-110, -118, -40, -124, -40, -116, -110, -110]), Color(1, 1, 1, 0.3))


## Kulatý balík slámy, který kombajn nechá za sebou.
static func _balik(ci: CanvasItem, _t: float) -> void:
	Art.shadow(ci, Vector2(0, 0), 36, 8, 0.25)
	Art.shape(ci, Art.rrect(Rect2(-34, -56, 52, 54), 10), Color("e8c45a"), 3.0)
	Art.blob(ci, Vector2(18, -29), 15, 27, Color("f2d77a"), 3.0, 0.5)
	for r in [6, 12, 18]:
		ci.draw_arc(Vector2(18, -29), r * 0.6, 0, TAU, 16, Color("b8913a"), 1.5, true)
	for y in [-44, -30, -16]:
		ci.draw_line(Vector2(-30, y), Vector2(4, y + 2), Color("b8913a"), 1.5, true)


# ---------------------------------------------------------------- Středočesko

static func _kamen(ci: CanvasItem, _t: float) -> void:
	var pts := Art.poly([-30, -8, -22, -28, 2, -34, 26, -22, 32, 4, 18, 28, -10, 30, -30, 14])
	Art.shape(ci, pts, Color("9aa3ad"), 3.5)
	for c in [[-10, -10, 6], [12, 8, 5], [-4, 14, 4]]:
		Art.safe_poly(ci, Art.ellipse(Vector2(c[0], c[1]), c[2], c[2] * 0.6, 10), Color("6c7580"))


# ---------------------------------------------------------------- Zlínsko

static func _svestka(ci: CanvasItem, _t: float) -> void:
	Art.blob(ci, Vector2(0, 4), 13, 15, Color("4a3a9a"), 3.0)
	ci.draw_arc(Vector2(2, 4), 10, -1.2, 1.4, 10, Color("2e2468"), 2.0, true)
	Art.stick(ci, Vector2(0, -10), Vector2(3, -18), Color("6b3e1c"), 3.0, 1.5)
	var leaf := Art.poly([3, -16, 16, -22, 14, -12])
	Art.shape(ci, leaf, Color("5fae2a"), 2.0, 0.4)
	ci.draw_circle(Vector2(-5, -2), 3.5, Color(1, 1, 1, 0.55))


# ---------------------------------------------------------------- Ústecko

static func _uhli(ci: CanvasItem, _t: float) -> void:
	var pts := Art.poly([-20, 4, -14, -12, 2, -16, 18, -8, 22, 8, 8, 16, -12, 14])
	Art.shape(ci, pts, Color("3a3a40"), 3.0)
	for c in [[-6, -6], [8, 2]]:
		Art.safe_poly(ci, Art.ellipse(Vector2(c[0], c[1]), 4, 2.5, 6), Color(1, 1, 1, 0.22))


# ---------------------------------------------------------------- Vysočina

## Hřibek do čarodějnického kruhu.
static func _hribek(ci: CanvasItem, _t: float) -> void:
	Art.shape(ci, Art.poly([-5, 12, 5, 12, 6, -2, -6, -2]), Color("f2e6c8"), 2.0, 0.4)
	var cap := Art.arc_pts(Vector2(0, 0), 13, PI, TAU, 12)
	Art.shape(ci, cap, Color("b0582a"), 2.5)
	ci.draw_circle(Vector2(-4, -6), 2.2, Color(1, 1, 1, 0.75))
	ci.draw_circle(Vector2(4, -4), 1.6, Color(1, 1, 1, 0.75))
