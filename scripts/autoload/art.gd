extends Node
## Art – paleta, písmo a kreslicí primitiva.
## Veškerá grafika hry vzniká v kódu: tvary se kreslí přes CanvasItem (_draw),
## stínují se gradienty, mají silné tmavé obrysy a lesklé odlesky („kreslené 3D“).

const OUTLINE := Color("2a1a0c")
const SHADOW := Color(0, 0, 0, 0.28)
const WHITE := Color(1, 1, 1)
const PARCHMENT := Color("f6e7c4")
const PARCHMENT_DARK := Color("dcc290")
const WOOD := Color("9a5b2a")
const WOOD_DARK := Color("6b3a17")
const WOOD_LIGHT := Color("c2803f")
const STONE := Color("9aa3ad")
const STONE_DARK := Color("6c7580")
const GOLD := Color("ffd23f")
const GOLD_DARK := Color("d98e04")
const ELIXIR := Color("e04bd6")
const ELIXIR_DARK := Color("8e1f9a")
const HP_RED := Color("ef3b2d")
const GRASS := Color("6cc53a")
const GRASS_DARK := Color("3f9020")
const SKY := Color("29a3e8")

const BTN_GREEN := Color("6fcf2f")
const BTN_YELLOW := Color("ffc928")
const BTN_BLUE := Color("3fb2ff")
const BTN_RED := Color("ff5a48")
const BTN_GREY := Color("a7adb3")
const BTN_PURPLE := Color("b25cff")

const RARITY_COLORS := [Color("b9c2cc"), Color("3fa8ff"), Color("b05cff"), Color("ffb310")]
const RARITY_NAMES := ["Běžná", "Vzácná", "Epická", "Legendární"]

var font: Font
var theme: Theme


func _ready() -> void:
	var fv := FontVariation.new()
	fv.base_font = ThemeDB.fallback_font
	fv.variation_embolden = 1.15
	fv.spacing_glyph = 1
	font = fv
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 22
	theme.set_color("font_color", "Label", WHITE)
	theme.set_color("font_outline_color", "Label", OUTLINE)
	theme.set_constant("outline_size", "Label", 8)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.45))
	theme.set_constant("shadow_offset_x", "Label", 0)
	theme.set_constant("shadow_offset_y", "Label", 3)
	theme.set_constant("shadow_outline_size", "Label", 8)
	get_tree().root.theme = theme


# ---------------------------------------------------------------- geometrie

func ellipse(c: Vector2, rx: float, ry: float, n: int = 32, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n)
	var cr := cos(rot)
	var sr := sin(rot)
	for i in n:
		var a := TAU * i / n
		var p := Vector2(cos(a) * rx, sin(a) * ry)
		pts[i] = c + Vector2(p.x * cr - p.y * sr, p.x * sr + p.y * cr)
	return pts


func rrect(r: Rect2, rad: float, seg: int = 6) -> PackedVector2Array:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(r.end.x - rad, r.position.y + rad), -PI / 2],
		[Vector2(r.end.x - rad, r.end.y - rad), 0.0],
		[Vector2(r.position.x + rad, r.end.y - rad), PI / 2],
		[Vector2(r.position.x + rad, r.position.y + rad), PI],
	]
	for c in corners:
		for i in seg + 1:
			var a: float = c[1] + (PI / 2) * i / seg
			pts.append(c[0] + Vector2(cos(a), sin(a)) * rad)
	return pts


func star(c: Vector2, ro: float, ri: float, n: int = 5, rot: float = -PI / 2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := rot + PI * i / n
		var r := ro if i % 2 == 0 else ri
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func arc_pts(c: Vector2, r: float, a0: float, a1: float, n: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


## Prstenec/výseč mezi dvěma poloměry.
func ring_sector(c: Vector2, r0: float, r1: float, a0: float, a1: float, n: int = 16) -> PackedVector2Array:
	var outer := arc_pts(c, r1, a0, a1, n)
	var inner := arc_pts(c, r0, a1, a0, n)
	outer.append_array(inner)
	return outer


func xform(pts: PackedVector2Array, pos: Vector2, scl: Vector2 = Vector2.ONE, rot: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	var t := Transform2D(rot, scl, 0.0, pos)
	for i in pts.size():
		out[i] = t * pts[i]
	return out


func poly(arr: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var i := 0
	while i + 1 < arr.size():
		pts.append(Vector2(arr[i], arr[i + 1]))
		i += 2
	return pts


func grow(pts: PackedVector2Array, d: float) -> PackedVector2Array:
	var res := Geometry2D.offset_polygon(pts, d, Geometry2D.JOIN_ROUND)
	if res.is_empty():
		return pts
	var best: PackedVector2Array = res[0]
	for p in res:
		if p.size() > best.size():
			best = p
	return best


func bbox(pts: PackedVector2Array) -> Rect2:
	if pts.is_empty():
		return Rect2()
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


func point_in_poly(p: Vector2, pts: PackedVector2Array) -> bool:
	return Geometry2D.is_point_in_polygon(p, pts)


# ---------------------------------------------------------------- kreslení

func safe_poly(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3:
		return
	if Geometry2D.triangulate_polygon(pts).is_empty():
		return
	ci.draw_colored_polygon(pts, col)


func aa_edge(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float = 1.4) -> void:
	if pts.size() < 3:
		return
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, col, w, true)


## Svislý gradient přes barvy vrcholů.
func grad(ci: CanvasItem, pts: PackedVector2Array, top: Color, bot: Color) -> void:
	if pts.size() < 3 or Geometry2D.triangulate_polygon(pts).is_empty():
		return
	var r := bbox(pts)
	var cols := PackedColorArray()
	cols.resize(pts.size())
	for i in pts.size():
		var t := 0.0 if r.size.y <= 0.0 else (pts[i].y - r.position.y) / r.size.y
		cols[i] = top.lerp(bot, t)
	ci.draw_polygon(pts, cols)


## Obrys = zvětšený polygon v tmavé barvě (čisté zaoblené rohy).
func outline(ci: CanvasItem, pts: PackedVector2Array, w: float = 3.0, col: Color = OUTLINE) -> void:
	if w <= 0.0:
		return
	var g := grow(pts, w)
	safe_poly(ci, g, col)
	aa_edge(ci, g, col, 1.2)


## Hlavní „3D“ tvar: obrys + gradient + stín ve spodní části + lesk nahoře.
func shape(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float = 3.0, shade: float = 1.0) -> void:
	if pts.size() < 3:
		return
	outline(ci, pts, w)
	grad(ci, pts, col.lightened(0.18 * shade), col.darkened(0.12 * shade))
	if shade <= 0.0:
		return
	var r := bbox(pts)
	var k := minf(r.size.x, r.size.y) * 0.16
	var shifted := xform(pts, Vector2(-k * 0.55, -k))
	for cres in Geometry2D.clip_polygons(pts, shifted):
		safe_poly(ci, cres, Color(col.darkened(0.42), 0.55 * shade))
	# lesk
	var sh := ellipse(r.position + r.size * Vector2(0.36, 0.24), r.size.x * 0.2, r.size.y * 0.09, 18, -0.45)
	for part in Geometry2D.intersect_polygons(sh, pts):
		safe_poly(ci, part, Color(1, 1, 1, 0.42 * shade))


func blob(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, w: float = 3.0, shade: float = 1.0, rot: float = 0.0) -> void:
	shape(ci, ellipse(c, rx, ry, 36, rot), col, w, shade)


func flat(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float = 3.0) -> void:
	outline(ci, pts, w)
	safe_poly(ci, pts, col)
	aa_edge(ci, pts, col.darkened(0.1), 1.0)


func circle(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float = 3.0) -> void:
	if w > 0:
		ci.draw_circle(c, r + w, OUTLINE, true, -1, true)
	ci.draw_circle(c, r, col, true, -1, true)


func shadow(ci: CanvasItem, c: Vector2, rx: float, ry: float, a: float = 0.28) -> void:
	safe_poly(ci, ellipse(c, rx, ry, 28), Color(0, 0, 0, a))


func shine(ci: CanvasItem, c: Vector2, rx: float, ry: float, a: float = 0.5, rot: float = -0.5) -> void:
	safe_poly(ci, ellipse(c, rx, ry, 18, rot), Color(1, 1, 1, a))


## Tlustá čára s obrysem a kulatými konci.
func stick(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, width: float, w: float = 3.0) -> void:
	if w > 0:
		ci.draw_line(a, b, OUTLINE, width + w * 2, true)
		ci.draw_circle(a, width * 0.5 + w, OUTLINE, true, -1, true)
		ci.draw_circle(b, width * 0.5 + w, OUTLINE, true, -1, true)
	ci.draw_line(a, b, col, width, true)
	ci.draw_circle(a, width * 0.5, col, true, -1, true)
	ci.draw_circle(b, width * 0.5, col, true, -1, true)
	ci.draw_line(a + Vector2(-width * 0.15, -width * 0.2), b + Vector2(-width * 0.15, -width * 0.2), Color(col.lightened(0.35), 0.6), width * 0.3, true)


## Kreslené oči: bělmo, zornice, odlesk, volitelně zamračené obočí.
func eyes(ci: CanvasItem, c: Vector2, spacing: float, size: float, angry: bool = true, look: Vector2 = Vector2(0.15, 0.2), white: Color = WHITE) -> void:
	for s: int in [-1, 1]:
		var e := c + Vector2(spacing * 0.5 * s, 0)
		ci.draw_circle(e, size + 2.0, OUTLINE, true, -1, true)
		ci.draw_circle(e, size, white, true, -1, true)
		var p := e + look * size * 0.6
		ci.draw_circle(p, size * 0.55, OUTLINE, true, -1, true)
		ci.draw_circle(p + Vector2(-size * 0.18, -size * 0.2), size * 0.18, WHITE, true, -1, true)
		if angry:
			var bi := e + Vector2(-s * size * 0.95, -size * 0.55)
			var bo := e + Vector2(s * size * 1.25, -size * 1.25)
			ci.draw_line(bi, bo, OUTLINE, size * 0.7, true)
			ci.draw_circle(bi, size * 0.35, OUTLINE, true, -1, true)
			ci.draw_circle(bo, size * 0.35, OUTLINE, true, -1, true)


func mouth_grin(ci: CanvasItem, c: Vector2, w: float, h: float, teeth: bool = true) -> void:
	var pts := PackedVector2Array()
	for i in 11:
		var a := PI * i / 10.0
		pts.append(c + Vector2(cos(a) * w, sin(a) * h))
	outline(ci, pts, 2.0)
	safe_poly(ci, pts, Color("5a1010"))
	if teeth:
		safe_poly(ci, PackedVector2Array([c + Vector2(-w * 0.8, 0), c + Vector2(w * 0.8, 0), c + Vector2(w * 0.7, h * 0.3), c + Vector2(-w * 0.7, h * 0.3)]), WHITE)


func mouth_line(ci: CanvasItem, c: Vector2, w: float, curve: float = 3.0) -> void:
	var pts := PackedVector2Array()
	for i in 7:
		var t := float(i) / 6.0
		pts.append(c + Vector2(lerpf(-w, w, t), -sin(t * PI) * curve))
	ci.draw_polyline(pts, OUTLINE, 3.0, true)


# ---------------------------------------------------------------- text

func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color = WHITE, outline_px: int = 8, align: int = HORIZONTAL_ALIGNMENT_CENTER, width: float = -1.0) -> void:
	var w := width
	var p := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER and width < 0:
		w = 2000.0
		p.x -= 1000.0
	var sh := maxi(2, size / 10)
	ci.draw_string_outline(font, p + Vector2(0, sh), s, align, w, size, outline_px, Color(0, 0, 0, 0.5))
	ci.draw_string_outline(font, p, s, align, w, size, outline_px, OUTLINE)
	ci.draw_string(font, p, s, align, w, size, col)


func text_width(s: String, size: int) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


# ---------------------------------------------------------------- UI prvky

## Tlačítko jako v kreslených strategiích: spodní „hrana“, gradient, lesk, obrys.
func button(ci: CanvasItem, r: Rect2, col: Color, pressed: bool = false, rad: float = 18.0) -> Rect2:
	var lip := 7.0
	var face := Rect2(r.position, Vector2(r.size.x, r.size.y - lip))
	if pressed:
		face.position.y += lip * 0.7
	var full := rrect(Rect2(r.position, r.size), rad)
	shadow_rect(ci, Rect2(r.position + Vector2(2, 5), r.size), rad)
	outline(ci, full, 3.5)
	safe_poly(ci, rrect(Rect2(r.position + Vector2(0, lip), Vector2(r.size.x, r.size.y - lip)), rad), col.darkened(0.45))
	var fp := rrect(face, rad)
	grad(ci, fp, col.lightened(0.28), col.darkened(0.08))
	# vnitřní světlý okraj
	var inner := rrect(face.grow(-3), rad - 3)
	var cl := inner.duplicate()
	cl.append(inner[0])
	ci.draw_polyline(cl, Color(col.lightened(0.5), 0.55), 2.0, true)
	# lesk v horní polovině
	var gl := Rect2(face.position + Vector2(8, 5), Vector2(face.size.x - 16, face.size.y * 0.38))
	safe_poly(ci, rrect(gl, minf(rad - 6, gl.size.y * 0.5)), Color(1, 1, 1, 0.28))
	return face


func shadow_rect(ci: CanvasItem, r: Rect2, rad: float) -> void:
	safe_poly(ci, rrect(r, rad), Color(0, 0, 0, 0.25))


## Dřevěný rám s pergamenovou výplní.
func panel(ci: CanvasItem, r: Rect2, inner_col: Color = PARCHMENT, rad: float = 22.0) -> Rect2:
	shadow_rect(ci, Rect2(r.position + Vector2(4, 8), r.size), rad)
	var outer := rrect(r, rad)
	outline(ci, outer, 4.0)
	grad(ci, outer, WOOD_LIGHT, WOOD_DARK)
	# léta dřeva
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.size.x * 13 + r.size.y)
	for i in int(r.size.y / 9):
		var y := r.position.y + 6 + i * 9 + rng.randf_range(-2, 2)
		var x0 := r.position.x + 10 + rng.randf_range(0, 30)
		var x1 := r.end.x - 10 - rng.randf_range(0, 30)
		ci.draw_line(Vector2(x0, y), Vector2(x1, y + rng.randf_range(-2, 2)), Color(WOOD_DARK, 0.35), 1.5, true)
	var ir := r.grow(-14)
	var inner := rrect(ir, rad - 8)
	outline(ci, inner, 3.0)
	grad(ci, inner, inner_col.lightened(0.08), inner_col.darkened(0.08))
	# vnitřní stín u horní hrany
	safe_poly(ci, rrect(Rect2(ir.position, Vector2(ir.size.x, 8)), 6), Color(0, 0, 0, 0.08))
	# nýty v rozích
	for p: Vector2 in [r.position + Vector2(9, 9), Vector2(r.end.x - 9, r.position.y + 9), Vector2(r.position.x + 9, r.end.y - 9), r.end - Vector2(9, 9)]:
		ci.draw_circle(p, 5.5, OUTLINE, true, -1, true)
		ci.draw_circle(p, 4.0, Color("c9ccd1"), true, -1, true)
		ci.draw_circle(p + Vector2(-1, -1.3), 1.6, WHITE, true, -1, true)
	return ir


## Kamenná deska (např. časovač).
func stone_plate(ci: CanvasItem, r: Rect2, rad: float = 14.0) -> void:
	shadow_rect(ci, Rect2(r.position + Vector2(2, 5), r.size), rad)
	var p := rrect(r, rad)
	outline(ci, p, 3.5)
	grad(ci, p, Color("8d96a1"), Color("59616b"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.size.x)
	for i in 6:
		var c := r.position + Vector2(rng.randf_range(10, r.size.x - 10), rng.randf_range(8, r.size.y - 8))
		safe_poly(ci, ellipse(c, rng.randf_range(4, 9), rng.randf_range(2, 4), 10), Color(1, 1, 1, 0.08))
	safe_poly(ci, rrect(Rect2(r.position + Vector2(6, 4), Vector2(r.size.x - 12, r.size.y * 0.3)), 8), Color(1, 1, 1, 0.12))


## Stuha s nápisem (nadpisy oken).
func ribbon(ci: CanvasItem, c: Vector2, w: float, h: float, col: Color, label: String, size: int = 34) -> void:
	var hw := w * 0.5
	var tail := h * 0.75
	for s: int in [-1, 1]:
		var x0 := c.x + s * (hw - 10)
		var x1 := c.x + s * (hw + tail)
		var t := PackedVector2Array([Vector2(x0, c.y - h * 0.3), Vector2(x1, c.y - h * 0.3), Vector2(x1 - s * tail * 0.45, c.y + h * 0.2), Vector2(x1, c.y + h * 0.7), Vector2(x0, c.y + h * 0.7)])
		flat(ci, t, col.darkened(0.35), 3.0)
	var body := PackedVector2Array([Vector2(c.x - hw, c.y - h * 0.5), Vector2(c.x + hw, c.y - h * 0.5), Vector2(c.x + hw, c.y + h * 0.5), Vector2(c.x - hw, c.y + h * 0.5)])
	outline(ci, body, 3.5)
	grad(ci, body, col.lightened(0.25), col.darkened(0.15))
	safe_poly(ci, PackedVector2Array([Vector2(c.x - hw + 6, c.y - h * 0.42), Vector2(c.x + hw - 6, c.y - h * 0.42), Vector2(c.x + hw - 6, c.y - h * 0.12), Vector2(c.x - hw + 6, c.y - h * 0.12)]), Color(1, 1, 1, 0.25))
	text(ci, Vector2(c.x, c.y + size * 0.36), label, size, WHITE, 9)


## Ukazatel (HP, XP) – kulatý žlab se svítivou výplní.
func bar(ci: CanvasItem, r: Rect2, frac: float, col: Color, back: Color = Color("3a2a1a")) -> void:
	frac = clampf(frac, 0.0, 1.0)
	var rad := r.size.y * 0.5
	var outer := rrect(r, rad)
	outline(ci, outer, 3.0)
	safe_poly(ci, outer, back)
	safe_poly(ci, rrect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, r.size.y * 0.45)), rad * 0.6), Color(0, 0, 0, 0.25))
	if frac > 0.0:
		var fw := maxf(r.size.y, r.size.x * frac)
		var fr := Rect2(r.position, Vector2(fw, r.size.y)).grow(-2)
		var fp := rrect(fr, fr.size.y * 0.5)
		grad(ci, fp, col.lightened(0.3), col.darkened(0.2))
		safe_poly(ci, rrect(Rect2(fr.position + Vector2(4, 2), Vector2(maxf(2, fr.size.x - 8), fr.size.y * 0.35)), fr.size.y * 0.2), Color(1, 1, 1, 0.35))


# ---------------------------------------------------------------- ikony UI

func icon_heart(ci: CanvasItem, c: Vector2, s: float, col: Color = HP_RED) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var t := TAU * i / 40.0
		var x := 16 * pow(sin(t), 3)
		var y := -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * s / 17.0)
	shape(ci, pts, col, 2.5)


func icon_coin(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, r * 0.18), r + 2.5, OUTLINE, true, -1, true)
	ci.draw_circle(c + Vector2(0, r * 0.18), r, GOLD_DARK.darkened(0.2), true, -1, true)
	blob(ci, c, r, r, GOLD, 2.5)
	safe_poly(ci, ellipse(c, r * 0.62, r * 0.62, 20), Color(GOLD_DARK, 0.5))
	safe_poly(ci, star(c, r * 0.45, r * 0.2), Color("fff3b0"))


func icon_elixir(ci: CanvasItem, c: Vector2, s: float, col: Color = ELIXIR) -> void:
	var pts := PackedVector2Array()
	for i in 30:
		var t := TAU * i / 30.0
		var r := s * (0.62 if sin(t) > 0 else 0.62 + 0.55 * pow(-sin(t), 3))
		pts.append(c + Vector2(cos(t) * s * 0.62, sin(t) * r) + Vector2(0, s * 0.2))
	shape(ci, pts, col, 2.5)


func icon_skull(ci: CanvasItem, c: Vector2, s: float) -> void:
	blob(ci, c + Vector2(0, -s * 0.1), s * 0.8, s * 0.72, Color("f2ede1"), 2.5, 0.6)
	flat(ci, rrect(Rect2(c + Vector2(-s * 0.45, s * 0.3), Vector2(s * 0.9, s * 0.45)), 4), Color("f2ede1"), 2.5)
	for sx: int in [-1, 1]:
		ci.draw_circle(c + Vector2(s * 0.3 * sx, 0), s * 0.22, OUTLINE, true, -1, true)
	safe_poly(ci, PackedVector2Array([c + Vector2(0, s * 0.15), c + Vector2(-s * 0.1, s * 0.32), c + Vector2(s * 0.1, s * 0.32)]), OUTLINE)


func icon_bolt(ci: CanvasItem, c: Vector2, s: float, col: Color = GOLD) -> void:
	var pts := poly([0.15, -1, -0.55, 0.12, -0.05, 0.12, -0.25, 1, 0.55, -0.2, 0.05, -0.2, 0.3, -1])
	shape(ci, xform(pts, c, Vector2(s, s)), col, 2.5)


func icon_lock(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_arc(c + Vector2(0, -s * 0.25), s * 0.42, PI, TAU, 16, OUTLINE, s * 0.32, true)
	ci.draw_arc(c + Vector2(0, -s * 0.25), s * 0.42, PI, TAU, 16, Color("b8bec6"), s * 0.18, true)
	shape(ci, rrect(Rect2(c + Vector2(-s * 0.62, -s * 0.25), Vector2(s * 1.24, s * 0.95)), s * 0.18), Color("f0b429"), 2.5)
	ci.draw_circle(c + Vector2(0, s * 0.12), s * 0.14, OUTLINE, true, -1, true)
	ci.draw_line(c + Vector2(0, s * 0.12), c + Vector2(0, s * 0.42), OUTLINE, s * 0.12)


func icon_swords(ci: CanvasItem, c: Vector2, s: float) -> void:
	for sx: int in [-1, 1]:
		var a := c + Vector2(-s * 0.75 * sx, s * 0.75)
		var b := c + Vector2(s * 0.7 * sx, -s * 0.7)
		stick(ci, a.lerp(b, 0.25), b, Color("e9eef2"), s * 0.22, 2.5)
		stick(ci, a, a.lerp(b, 0.2), WOOD, s * 0.2, 2.5)
		var g := a.lerp(b, 0.24)
		var perp := (b - a).orthogonal().normalized() * s * 0.3
		stick(ci, g - perp, g + perp, GOLD, s * 0.14, 2.5)


func icon_flag(ci: CanvasItem, base: Vector2, s: float, t: float = 0.0) -> void:
	stick(ci, base, base + Vector2(0, -s * 1.6), Color("8b5a2b"), s * 0.12, 2.0)
	var top := base + Vector2(s * 0.06, -s * 1.55)
	var pts := PackedVector2Array()
	var n := 8
	for i in n + 1:
		var x := s * 0.9 * i / n
		pts.append(top + Vector2(x, sin(i * 0.9 + t * 6.0) * s * 0.06))
	for i in range(n, -1, -1):
		var x := s * 0.9 * i / n
		pts.append(top + Vector2(x, s * 0.6 + sin(i * 0.9 + t * 6.0) * s * 0.06))
	outline(ci, pts, 2.0)
	# česká trikolóra
	var top_half := PackedVector2Array()
	var bot_half := PackedVector2Array()
	for i in n + 1:
		top_half.append(pts[i])
	for i in range(n, -1, -1):
		var p: Vector2 = pts[i]
		top_half.append(p + Vector2(0, s * 0.3))
	safe_poly(ci, pts, Color("d7141a"))
	safe_poly(ci, top_half, WHITE)
	var tri := PackedVector2Array([pts[0], pts[pts.size() - 1], top + Vector2(s * 0.42, s * 0.3)])
	safe_poly(ci, tri, Color("11457e"))


func icon_crown(ci: CanvasItem, c: Vector2, s: float) -> void:
	var pts := poly([-1, 0.55, -1.05, -0.45, -0.5, 0.0, 0.0, -0.75, 0.5, 0.0, 1.05, -0.45, 1, 0.55])
	shape(ci, xform(pts, c, Vector2(s, s)), GOLD, 2.5)
	for p: Vector2 in [Vector2(-1.05, -0.45), Vector2(0, -0.75), Vector2(1.05, -0.45)]:
		circle(ci, c + p * s, s * 0.14, Color("ff4d6d"), 2.0)


func icon_star(ci: CanvasItem, c: Vector2, r: float, filled: bool = true) -> void:
	var pts := star(c, r, r * 0.48)
	if filled:
		shape(ci, pts, GOLD, 3.0)
	else:
		outline(ci, pts, 3.0)
		safe_poly(ci, pts, Color("5b4a3a"))


func icon_pause(ci: CanvasItem, c: Vector2, s: float) -> void:
	for sx: int in [-1, 1]:
		flat(ci, rrect(Rect2(c + Vector2(s * 0.35 * sx - s * 0.18, -s * 0.55), Vector2(s * 0.36, s * 1.1)), 4), WHITE, 2.5)


func icon_boot(ci: CanvasItem, c: Vector2, s: float) -> void:
	var pts := poly([-0.35, -0.9, 0.25, -0.9, 0.25, 0.25, 0.85, 0.35, 0.95, 0.8, -0.35, 0.8])
	shape(ci, xform(pts, c, Vector2(s, s)), Color("a0612d"), 2.5)
	for i in 3:
		ci.draw_line(c + Vector2(-s * 0.7 - i * s * 0.25, -s * 0.2 + i * s * 0.3), c + Vector2(-s * 1.2 - i * s * 0.2, -s * 0.2 + i * s * 0.3), Color(1, 1, 1, 0.85), 3.0, true)


func icon_gear(ci: CanvasItem, c: Vector2, s: float) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var r := s * (1.0 if (i / 2) % 2 == 0 else 0.78)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	shape(ci, pts, Color("b9c1ca"), 2.5)
	circle(ci, c, s * 0.32, Color("59616b"), 2.0)


func icon_hammer(ci: CanvasItem, c: Vector2, s: float) -> void:
	stick(ci, c + Vector2(-s * 0.6, s * 0.8), c + Vector2(s * 0.3, -s * 0.2), WOOD_LIGHT, s * 0.2, 2.5)
	var head := xform(rrect(Rect2(-s * 0.55, -s * 0.28, s * 1.1, s * 0.56), 4), c + Vector2(s * 0.35, -s * 0.35), Vector2.ONE, -PI / 4)
	shape(ci, head, Color("8c96a3"), 2.5)
