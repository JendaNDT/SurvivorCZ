extends RefCounted
class_name MapArt
## Drobné kresby pro mapu (hory, stromky, hrad) a pomocné vrstvy mapy.


static func mountain(ci: CanvasItem, _t: float) -> void:
	var m := Art.poly([-40, 0, -12, -48, 0, -40, 14, -58, 42, 0])
	Art.shape(ci, m, Color("8d8174"), 2.5)
	var snow := Art.poly([-18, -38, -12, -48, 0, -40, 14, -58, 24, -38, 14, -42, 6, -34, -4, -36, -10, -32])
	Art.shape(ci, snow, Color("f6f8ff"), 2.0, 0.3)
	ci.draw_line(Vector2(14, -58), Vector2(20, -6), Color(0, 0, 0, 0.12), 6.0)


static func tree(ci: CanvasItem, _t: float) -> void:
	Art.shadow(ci, Vector2(3, 0), 12, 4, 0.25)
	Art.stick(ci, Vector2(0, 0), Vector2(0, -12), Color("8a5a2a"), 4.0, 1.5)
	Art.blob(ci, Vector2(0, -22), 13, 12, Color("4fae2a"), 2.0)


static func pine(ci: CanvasItem, _t: float) -> void:
	Art.shadow(ci, Vector2(3, 0), 10, 4, 0.25)
	Art.stick(ci, Vector2(0, 0), Vector2(0, -8), Color("8a5a2a"), 4.0, 1.5)
	for i in 3:
		var y := -6.0 - i * 11.0
		var w := 12.0 - i * 2.5
		Art.shape(ci, Art.poly([-w, y, 0, y - 18, w, y]), Color("2f7a3a"), 2.0, 0.6)


static func castle(ci: CanvasItem, _t: float) -> void:
	Art.shadow(ci, Vector2(4, 0), 34, 8, 0.3)
	Art.shape(ci, Art.rrect(Rect2(-30, -34, 60, 34), 4), Color("c9c1b3"), 3.0)
	for x in [-30, -12, 6, 22]:
		Art.flat(ci, Art.rrect(Rect2(x - 1, -42, 10, 10), 2), Color("c9c1b3"), 2.0)
	Art.shape(ci, Art.rrect(Rect2(-12, -62, 24, 30), 3), Color("d6cfc2"), 3.0)
	Art.shape(ci, Art.poly([-16, -60, 0, -80, 16, -60]), Color("d7462c"), 2.5)
	Art.flat(ci, Art.arc_pts(Vector2(0, -12), 8, PI, TAU, 8), Color("5a3a1a"), 2.0)


## Šipka, která ukazuje na první kraj.
static func arrow(ci: CanvasItem, _t: float) -> void:
	var pts := Art.poly([-10, -16, 10, -16, 10, 0, 18, 0, 0, 16, -18, 0, -10, 0])
	Art.shape(ci, pts, Art.GOLD, 2.5, 0.5)


## Stín ostrova, pěna u břehu a skalnatý okraj (pod krajinou).
class MapUnder extends Node2D:
	var m: MapScreen

	func _draw() -> void:
		var o := m.outline_all
		if o.size() < 3:
			return
		Art.safe_poly(self, Art.xform(Art.grow(o, 10), Vector2(10, 26)), Color(0, 0.1, 0.25, 0.35))
		var foam := Art.grow(o, 9)
		Art.safe_poly(self, Art.xform(foam, Vector2(0, 18)), Color(1, 1, 1, 0.55))
		Art.safe_poly(self, Art.xform(Art.grow(o, 3.5), Vector2(0, 17)), Art.OUTLINE)
		Art.safe_poly(self, Art.xform(o, Vector2(0, 16)), Color("6b4424"))
		Art.safe_poly(self, Art.xform(o, Vector2(0, 8)), Color("8a5a2e"))
		Art.safe_poly(self, Art.xform(o, Vector2(0, 4)), Color("3f8f2a"))
		Art.safe_poly(self, Art.grow(o, 3.5), Art.OUTLINE)


## Výplně krajů (shader přidá texturu trávy).
class MapLand extends Node2D:
	var m: MapScreen

	func _draw() -> void:
		for id in Regions.ORDER:
			var pts: PackedVector2Array = m.shapes[id]
			var col := Color(Regions.DATA[id].tint)
			match m.state_of(id):
				"locked":
					col = col.darkened(0.3).lerp(Color("7d8a74"), 0.45)
				"conquered":
					col = col.lightened(0.08)
			Art.grad(self, pts, col.lightened(0.08), col.darkened(0.1))


## Hranice, řeky, hory, lesy, mlha nad zamčenými kraji, cedule a erby.
class MapDetails extends Node2D:
	var m: MapScreen

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		# řeky
		for name in Regions.RIVERS.keys():
			var pts := PackedVector2Array()
			for ll in Regions.RIVERS[name]:
				pts.append(RegionShapes.project(ll[0], ll[1]))
			var smooth := _smooth(pts)
			draw_polyline(smooth, Color("1f5a8a"), 6.5, true)
			draw_polyline(smooth, Color("5cc6ff"), 3.8, true)
			draw_polyline(smooth, Color(1, 1, 1, 0.35), 1.2, true)
		# hranice krajů
		for id in Regions.ORDER:
			var pts: PackedVector2Array = m.shapes[id]
			var cl := pts.duplicate()
			cl.append(pts[0])
			draw_polyline(cl, Color(0.16, 0.1, 0.05, 0.75), 2.6, true)
			draw_polyline(Art.xform(cl, Vector2(0.8, 1.2)), Color(1, 1, 1, 0.22), 1.0, true)
		# stromky
		for id in Regions.ORDER:
			if id == "PHA":
				continue
			var pts: PackedVector2Array = m.shapes[id]
			var bb := Art.bbox(pts)
			rng.seed = id.hash()
			var lp := Regions.label_pos(id)
			var placed := 0
			var tries := 0
			var pine: bool = id in ["LBK", "HKK", "VYS", "PLK", "JHC", "MSK", "ZLK", "OLK"]
			while placed < 9 and tries < 80:
				tries += 1
				var p := Vector2(rng.randf_range(bb.position.x, bb.end.x), rng.randf_range(bb.position.y, bb.end.y))
				if not Geometry2D.is_point_in_polygon(p, pts) or p.distance_to(lp) < 44.0:
					continue
				if Geometry2D.is_point_in_polygon(p, m.shapes["PHA"]):
					continue
				var key := "map:pine" if (pine and rng.randf() < 0.6) else "map:tree"
				if Baker.has(key):
					var tex := Baker.tex(key)
					var s := tex.get_size() / Baker.SCALE * 0.62
					draw_texture_rect(tex, Rect2(p - Vector2(s.x * 0.5, s.y * 0.85), s), false)
				placed += 1
		# hory
		if Baker.has("map:mountain"):
			var mt := Baker.tex("map:mountain")
			for mo in Regions.MOUNTAINS:
				var p := RegionShapes.project(mo[0], mo[1])
				var s: Vector2 = mt.get_size() / Baker.SCALE * 0.5 * mo[2]
				draw_texture_rect(mt, Rect2(p - Vector2(s.x * 0.5, s.y * 0.85), s), false)
		# mlha nad zamčenými kraji
		for id in Regions.ORDER:
			if m.state_of(id) != "locked":
				continue
			var pts: PackedVector2Array = m.shapes[id]
			var bb := Art.bbox(pts)
			rng.seed = id.hash() + 7
			for i in 14:
				var p := Vector2(rng.randf_range(bb.position.x, bb.end.x), rng.randf_range(bb.position.y, bb.end.y))
				if not Geometry2D.is_point_in_polygon(p, pts):
					continue
				var r := rng.randf_range(14, 26)
				draw_circle(p + Vector2(0, 3), r, Color(0.55, 0.62, 0.7, 0.25))
				draw_circle(p, r, Color(0.92, 0.95, 1.0, 0.42))
		# cedule s názvy
		for id in Regions.ORDER:
			_plate(id)

	func _smooth(pts: PackedVector2Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var p0 := pts[maxi(0, i - 1)]
			var p3 := pts[mini(pts.size() - 1, i + 2)]
			for k in 6:
				var t := k / 6.0
				var t2 := t * t
				var t3 := t2 * t
				out.append(0.5 * ((2.0 * a) + (-p0 + b) * t + (2.0 * p0 - 5.0 * a + 4.0 * b - p3) * t2 + (-p0 + 3.0 * a - 3.0 * b + p3) * t3))
		out.append(pts[pts.size() - 1])
		return out

	func _plate(id: String) -> void:
		var st := m.state_of(id)
		var lp := Regions.label_pos(id)
		var name: String = Regions.DATA[id].short
		var fs := 15
		var w := Art.text_width(name, fs) + 18.0
		var r := Rect2(lp + Vector2(-w * 0.5, 20), Vector2(w, 24))
		var col := Color("9a5b2a") if st != "locked" else Color("6c6a66")
		Art.safe_poly(self, Art.rrect(Rect2(r.position + Vector2(0, 3), r.size), 8), Color(0, 0, 0, 0.3))
		Art.flat(self, Art.rrect(r, 8), col, 2.0)
		Art.safe_poly(self, Art.rrect(Rect2(r.position + Vector2(3, 2), Vector2(r.size.x - 6, 8)), 4), Color(1, 1, 1, 0.15))
		Art.text(self, Vector2(lp.x, r.position.y + 18), name, fs, Color.WHITE if st != "locked" else Color("d8d8d8"), 4)
		if st == "conquered":
			var n := Game.stars(id)
			for i in 3:
				var c := Vector2(lp.x + (i - 1) * 15, r.end.y + 9)
				var pts := Art.star(c, 7, 3.2)
				Art.safe_poly(self, Art.grow(pts, 1.5), Art.OUTLINE)
				Art.safe_poly(self, pts, Art.GOLD if i < n else Color("5b4a3a"))


## Animované prvky: pulzující meče, vlajky, výběr kraje.
class MapLive extends Node2D:
	var m: MapScreen
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		if t < 4.0:
			for id in m.fresh:
				var lp := Regions.label_pos(id)
				for k in 3:
					var kk := fmod(t * 0.8 + k / 3.0, 1.0)
					draw_arc(lp, 20.0 + kk * 70.0, 0, TAU, 40, Color(1, 0.85, 0.2, (1.0 - kk) * (1.0 - t / 4.0)), 4.0, true)
		if m.selected != "":
			var pts: PackedVector2Array = m.shapes[m.selected]
			var cl := pts.duplicate()
			cl.append(pts[0])
			draw_polyline(cl, Color(1, 1, 0.6, 0.6 + 0.3 * sin(t * 6.0)), 5.0, true)
		for id in Regions.ORDER:
			var st := m.state_of(id)
			var lp := Regions.label_pos(id)
			match st:
				"available":
					var pulse := 0.5 + 0.5 * sin(t * 4.0 + id.hash() % 10)
					draw_circle(lp, 20 + pulse * 8.0, Color(1, 0.85, 0.3, 0.18 * (1.0 - pulse) + 0.08))
					draw_arc(lp, 20 + pulse * 10.0, 0, TAU, 32, Color(1, 0.9, 0.4, 0.7 * (1.0 - pulse)), 2.5, true)
					var bob := sin(t * 3.0) * 3.0
					_shield(lp + Vector2(0, -2 + bob), Color("e2382c"), "ui:swords")
					if Game.conquered_count() == 0 and Baker.has("map:arrow"):
						var ay := lp.y - 52 + sin(t * 5.0) * 6.0
						draw_texture_rect(Baker.tex("map:arrow"), Rect2(Vector2(lp.x - 25, ay - 25), Vector2(50, 50)), false)
				"locked":
					_shield(lp, Color("8d8a85"), "ui:lock")
				"conquered":
					if Baker.has("map:castle"):
						var tex := Baker.tex("map:castle")
						var s := tex.get_size() / Baker.SCALE * 0.5
						draw_texture_rect(tex, Rect2(lp - Vector2(s.x * 0.5, s.y * 0.8 - 6), s), false)
					Art.icon_flag(self, lp + Vector2(8, -28), 15, t + id.hash() % 7)

	## Obrys štítu se spočítá jednou a pak se jen posouvá (mapa se kreslí každý snímek).
	var shield_pts := PackedVector2Array()
	var shield_outline := PackedVector2Array()

	func _shield(c: Vector2, col: Color, icon: String) -> void:
		if shield_pts.is_empty():
			shield_pts = Art.poly([0, -18, 16, -12, 14, 6, 0, 18, -14, 6, -16, -12])
			shield_outline = Art.grow(shield_pts, 2.5)
		var sp := Art.xform(shield_pts, c)
		Art.safe_poly(self, Art.xform(shield_outline, c), Art.OUTLINE)
		Art.grad(self, sp, col.lightened(0.25), col.darkened(0.2))
		if Baker.has(icon):
			draw_texture_rect(Baker.tex(icon), Rect2(c - Vector2(13, 13), Vector2(26, 26)), false)


## Mraky plující nad mořem kolem mapy.
class MapClouds extends Control:
	var m: MapScreen
	var cl: Array = []
	var t := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		for i in 6:
			var y := rng.randf_range(0.04, 0.16) if i % 2 == 0 else rng.randf_range(0.86, 0.98)
			cl.append({"x": rng.randf(), "y": y, "s": rng.randf_range(0.6, 1.0), "v": rng.randf_range(6, 14)})

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for c in cl:
			var x: float = fmod(c.x * (size.x + 400.0) + t * c.v, size.x + 400.0) - 200.0
			var p := Vector2(x, c.y * size.y)
			var s: float = c.s
			for b in [[-40, 0, 34], [0, -14, 44], [42, 2, 32], [10, 10, 36]]:
				draw_circle(p + Vector2(b[0], b[1] + 8) * s, b[2] * s, Color(0.5, 0.6, 0.75, 0.18))
			for b in [[-40, 0, 34], [0, -14, 44], [42, 2, 32], [10, 10, 36]]:
				draw_circle(p + Vector2(b[0], b[1]) * s, b[2] * s, Color(1, 1, 1, 0.5))
