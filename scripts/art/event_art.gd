extends RefCounted
class_name EventArt
## Kresby událostí v boji (M7): oltář, boží muka, prokletý obelisk, kramář s vozíkem
## a zamčená truhla. Bod (0,0) je na zemi uprostřed (kresby stojí na zemi).
## t > 0.5 je „aktivní“ podoba (rozžhavený obelisk, otevřená truhla).

const SIZES := {
	"oltar": Vector2(140, 130),
	"muka": Vector2(90, 225),
	"obelisk": Vector2(170, 225),
	"kramar": Vector2(210, 170),
	"truhla": Vector2(130, 120),
}


static func size_of(id: String) -> Vector2:
	return SIZES.get(id, Vector2(100, 100))


static func origin_of(id: String) -> Vector2:
	var s := size_of(id)
	return Vector2(0.5, (s.y - 16.0) / s.y)


static func draw(ci: CanvasItem, id: String, t: float) -> void:
	var fn := Callable(EventArt, "_" + id)
	if fn.is_valid():
		fn.call(ci, t)


## Kamenný oltář s rudou látkou, svícny a zlatým kalichem.
static func _oltar(ci: CanvasItem, _t: float) -> void:
	Art.shadow(ci, Vector2(0, 2), 62, 12)
	Art.shape(ci, Art.rrect(Rect2(-50, -44, 100, 44), 6), Art.STONE, 3.0)
	for x in [-30, 0, 30]:
		ci.draw_line(Vector2(x, -40), Vector2(x, -4), Color(0, 0, 0, 0.15), 2.0, true)
	Art.shape(ci, Art.rrect(Rect2(-60, -58, 120, 16), 5), Art.STONE.lightened(0.2), 3.0)
	var cloth := Art.poly([-36, -44, 36, -44, 30, -10, 0, -18, -30, -10])
	Art.shape(ci, cloth, Color("b8262c"), 2.5, 0.7)
	ci.draw_polyline(Art.poly([-30, -12, 0, -20, 30, -12]), Art.GOLD, 3.0, true)
	Art.shape(ci, Art.star(Vector2(0, -32), 7, 3.5, 4), Art.GOLD, 2.0, 0.0)
	for s: int in [-1, 1]:
		var cx := s * 44.0
		Art.flat(ci, Art.rrect(Rect2(cx - 5, -82, 10, 24), 3), Color("f6ecd2"), 2.5)
		Art.shape(ci, Art.poly([cx, -98, cx + 5, -88, cx, -82, cx - 5, -88]), Color("ff9a2a"), 2.0, 0.0)
		ci.draw_circle(Vector2(cx, -88), 3.0, Color("fff2b0"))
	# kalich
	Art.shape(ci, Art.poly([-12, -84, 12, -84, 6, -70, 3, -66, 3, -62, 9, -60, -9, -60, -3, -62, -3, -66, -6, -70]), Art.GOLD, 2.5, 0.7)
	ci.draw_circle(Vector2(0, -86), 6.0, Color(0.85, 0.4, 1.0, 0.5))


## Boží muka: kamenný sloup s výklenkem, stříškou a železným křížem.
static func _muka(ci: CanvasItem, _t: float) -> void:
	Art.shadow(ci, Vector2(0, 2), 34, 9)
	Art.shape(ci, Art.rrect(Rect2(-26, -14, 52, 14), 3), Art.STONE.darkened(0.1), 3.0)
	Art.shape(ci, Art.rrect(Rect2(-12, -112, 24, 100), 4), Color("d9cfb8"), 3.0)
	Art.shape(ci, Art.rrect(Rect2(-24, -150, 48, 42), 4), Color("e8dfc8"), 3.0)
	Art.flat(ci, Art.rrect(Rect2(-15, -143, 30, 28), 10), Color("3a6fb5"), 2.5)
	Art.circle(ci, Vector2(0, -131), 6.0, Art.GOLD, 2.0)
	ci.draw_line(Vector2(-6, -121), Vector2(6, -121), Art.GOLD, 3.0, true)
	var roof := Art.poly([-32, -146, 0, -172, 32, -146])
	Art.shape(ci, roof, Color("b8452c"), 3.0, 0.8)
	Art.stick(ci, Vector2(0, -170), Vector2(0, -196), Color("3a3a40"), 4.0, 2.0)
	Art.stick(ci, Vector2(-9, -188), Vector2(9, -188), Color("3a3a40"), 4.0, 2.0)


## Prokletý obelisk z tmavého kamene se svítícími runami (t > 0.5 = probuzená kletba).
static func _obelisk(ci: CanvasItem, t: float) -> void:
	var lit := t > 0.5
	var glow := Color("ff4d6d") if lit else Color("c27bff")
	Art.shadow(ci, Vector2(0, 2), 44, 11)
	if lit:
		for k in 5:
			ci.draw_circle(Vector2(0, -90), 70.0 - k * 10.0, Color(1, 0.3, 0.4, 0.05 + k * 0.03))
	Art.shape(ci, Art.rrect(Rect2(-36, -18, 72, 18), 3), Color("4a4458"), 3.0)
	var body := Art.poly([-22, -16, 22, -16, 14, -168, 0, -190, -14, -168])
	Art.shape(ci, body, Color("3c3450"), 3.0)
	for i in 5:
		var y := -40.0 - i * 26.0
		var w := 10.0 - i * 1.2
		ci.draw_polyline(Art.poly([-w, y, 0, y - 9, w, y, 0, y + 9, -w, y]), glow, 2.5, true)
	ci.draw_circle(Vector2(0, -170), 5.0, glow)


## Kramář s vozíkem: dřevěný vozík s pruhovanou plachtou, zbožím a kupcem.
static func _kramar(ci: CanvasItem, _t: float) -> void:
	Art.shadow(ci, Vector2(-10, 2), 92, 13)
	# plachta
	Art.stick(ci, Vector2(-78, -46), Vector2(-78, -112), Color("7a5230"), 5.0, 2.5)
	Art.stick(ci, Vector2(38, -46), Vector2(38, -112), Color("7a5230"), 5.0, 2.5)
	var tent := Art.poly([-90, -104, -20, -132, 50, -104, 50, -92, -90, -92])
	Art.shape(ci, tent, Color("f6f0e0"), 3.0, 0.6)
	for i in 4:
		var x0 := -90.0 + i * 35.0
		ci.draw_colored_polygon(Art.poly([x0, -92, x0 + 17, -92, x0 + 17, -104 - (14.0 - absf(x0 + 8.0 + 20.0) * 0.1), x0, -104 - (14.0 - absf(x0 + 20.0) * 0.1)]), Color("e2382c"))
	# zboží
	Art.shape(ci, Art.rrect(Rect2(-74, -76, 26, 28), 5), Color("b06a2c"), 2.5)
	Art.blob(ci, Vector2(-34, -60), 16, 13, Color("d8c08a"), 2.5)
	Art.blob(ci, Vector2(-6, -62), 12, 15, Color("6a9a3a"), 2.5)
	Art.icon_heart(ci, Vector2(18, -64), 11, Color("b0703a"))
	# vozík
	Art.shape(ci, Art.rrect(Rect2(-88, -50, 132, 34), 4), Art.WOOD, 3.0)
	for x in [-56, -24, 8]:
		ci.draw_line(Vector2(x, -46), Vector2(x, -20), Color(0, 0, 0, 0.2), 2.0, true)
	for wx in [-58, 18]:
		Art.circle(ci, Vector2(wx, -12), 16, Art.WOOD_DARK, 3.0)
		Art.circle(ci, Vector2(wx, -12), 5, Art.GOLD, 2.0)
	Art.stick(ci, Vector2(44, -30), Vector2(64, -18), Color("7a5230"), 5.0, 2.5)
	# kramář
	Art.shape(ci, Art.rrect(Rect2(62, -66, 34, 56), 12), Color("4a6a3a"), 3.0)
	Art.circle(ci, Vector2(79, -78), 15, Color("f2c79a"), 3.0)
	Art.shape(ci, Art.ellipse(Vector2(79, -92), 21, 6, 20), Color("3a2a1e"), 2.5, 0.5)
	Art.shape(ci, Art.rrect(Rect2(69, -110, 20, 18), 4), Color("4a3626"), 2.5, 0.6)
	Art.eyes(ci, Vector2(80, -80), 9.0, 3.2, false)
	ci.draw_polyline(Art.poly([70, -71, 79, -74, 88, -71]), Color("6b3a17"), 3.0, true)


## Zamčená truhla s řetězy a velkým zámkem (t > 0.5 = odemčená, víko pootevřené).
static func _truhla(ci: CanvasItem, t: float) -> void:
	var open := t > 0.5
	Art.shadow(ci, Vector2(0, 2), 56, 11)
	Art.shape(ci, Art.rrect(Rect2(-50, -54, 100, 54), 6), Color("8a4f22"), 3.5)
	var lid := Art.arc_pts(Vector2(0, -54), 50, PI, TAU, 18)
	var lid_y := -16.0 if open else 0.0
	Art.shape(ci, Art.xform(lid, Vector2(0, lid_y), Vector2(1, 0.55)), Color("a8622c"), 3.5)
	for x in [-34, 34]:
		Art.flat(ci, Art.rrect(Rect2(x - 5, -80 + lid_y * 0.5, 10, 80 - lid_y * 0.5), 2), Color("8d97a3"), 2.0)
	if open:
		for k in 4:
			ci.draw_circle(Vector2(0, -60), 40.0 - k * 8.0, Color(1, 0.85, 0.3, 0.1 + k * 0.06))
	else:
		# řetězy křížem
		for s: int in [-1, 1]:
			ci.draw_line(Vector2(-44.0 * s, -50.0), Vector2(40.0 * s, -8.0), Color("3a3a40"), 4.0, true)
			for i in 7:
				var p := Vector2(-44.0 * s + i * 14.0 * s, -50.0 + i * 7.0)
				ci.draw_arc(p, 5.0, 0, TAU, 10, Color("3a3a40"), 5.0, true)
				ci.draw_arc(p, 5.0, 0, TAU, 10, Color("aab3bd"), 2.5, true)
		Art.shape(ci, Art.rrect(Rect2(-13, -34, 26, 24), 5), Art.GOLD, 3.0)
		ci.draw_arc(Vector2(0, -34), 9.0, PI, TAU, 12, Art.OUTLINE, 7.0, true)
		ci.draw_arc(Vector2(0, -34), 9.0, PI, TAU, 12, Color("aab3bd"), 3.5, true)
		Art.circle(ci, Vector2(0, -24), 3.0, Art.OUTLINE, 0.0)
