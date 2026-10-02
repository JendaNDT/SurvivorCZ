extends Node
class_name HazardSystem
## Nástrahy krajů (čísla a texty jsou v scripts/data/hazards.gd). Každý kraj má jednu:
## - pohyblivé: sudy, dostihoví koně, tramvaj, kombajn (jedou pruhem, který se předem ukáže),
## - dopady: gejzíry, kámen z katapultu, uhlí z pásu, výtrysk železa z praskliny,
## - terén v kouscích mapy: pásové dopravníky, rybníky, kruhy hub, praskliny, švestkové stromy,
## - počasí: mlha, vánice, vítr.
## Běžné nepřátele nástraha zabije, takže se vyplatí hordu do ní nalákat.
## V aréně bosse běží jen počasí a terén, ostatní nástrahy se vypnou.

const WEATHER := ["mlha", "vanice", "vitr"]
const ART_FOR := {
	"sudy": ["sud"], "dostih": ["kun"], "tramvaj": ["tramvaj"], "kombajn": ["kombajn", "balik"],
	"katapult": ["kamen"], "svestky": ["svestka"], "pasy": ["uhli"], "spory": ["hribek"],
}
const ANIMATED := ["kun", "kombajn"]

var b: Battle
var d: Dictionary = {}
var kind := ""
var fast := false
var timer := 0.0
var time := 0.0
var announced := false
var was_arena := false
## true, když nástraha mění rychlost nebo tlačí (volá se pak pro každého nepřítele)
var mods := false

var pending: Array = []
var movers: Array = []
var springs: Array = []
var craters: Array = []
var clouds: Array = []
var plums: Array = []
var falling: Array = []
var bales: Array = []
## Geometrie v kouscích mapy: Vector2i -> pole slovníků {type: belt|pond|ring|crack|tree|glow, …}
var geo := {}

var weather_t := 0.0
var weather_in := 0.0
var warn_t := 0.0
var wind_dir := Vector2.RIGHT
var still_t := 0.0
var freeze_t := 0.0
var spring_t := 0.0
var flakes: Array = []
var last_cam := Vector2.ZERO

var ground_node: Painter
var air_node: Painter
var weather_layer: CanvasLayer
var fog_rect: ColorRect
var overlay: Overlay


class Painter extends Node2D:
	var fn: Callable

	func _draw() -> void:
		fn.call(self)


class Overlay extends Control:
	var fn: Callable

	func _draw() -> void:
		fn.call(self)


## Kresby nástrahy daného kraje k upečení (Baker).
static func bake_jobs(region_id: String) -> Array:
	var id: String = HazardDefs.get_for(region_id).get("id", "")
	var jobs := []
	for art: String in ART_FOR.get(id, []):
		var frames: Array = [0.0, 1.0] if art in ANIMATED else [0.0]
		for t: float in frames:
			var key := "hz:" + art + (str(int(t)) if frames.size() > 1 else "")
			jobs.append({"key": key, "size": HazardArt.size_of(art), "fn": func(ci, tt): HazardArt.draw(ci, art, tt), "t": t, "origin": HazardArt.origin_of(art)})
	return jobs


func init(battle: Battle) -> void:
	b = battle
	d = HazardDefs.get_for(b.region_id)
	kind = d.get("id", "")
	fast = "--hazard-now" in OS.get_cmdline_user_args()
	timer = 2.0 if fast else float(d.get("first", 20.0))
	mods = kind in ["pasy", "vanice", "katapult", "rybniky", "vitr"]
	ground_node = Painter.new()
	ground_node.fn = _draw_ground
	b.world.add_child(ground_node)
	b.world.move_child(ground_node, b.ground.get_index() + 1)
	air_node = Painter.new()
	air_node.fn = _draw_air
	b.world.add_child(air_node)
	b.world.move_child(air_node, b.fx.get_index() + 1)
	if kind in WEATHER:
		weather_layer = CanvasLayer.new()
		weather_layer.layer = 5
		b.add_child(weather_layer)
		if kind == "mlha":
			fog_rect = ColorRect.new()
			fog_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var sm := ShaderMaterial.new()
			sm.shader = _fog_shader()
			fog_rect.material = sm
			fog_rect.visible = false
			weather_layer.add_child(fog_rect)
		overlay = Overlay.new()
		overlay.fn = _draw_weather
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		weather_layer.add_child(overlay)


# ---------------------------------------------------------------- hlavní smyčka

func update(delta: float) -> void:
	if kind == "":
		return
	time += delta
	var in_arena := b.arena_radius > 0.0
	if in_arena and not was_arena:
		was_arena = true
		if not kind in WEATHER:
			pending.clear()
	for p: Array in pending.duplicate():
		p[0] -= delta
		if p[0] <= 0.0:
			pending.erase(p)
			var fn_p: Callable = p[1]
			fn_p.call()
	timer -= delta
	if timer <= 0.0:
		var ev: Array = d.get("every", [20.0, 20.0])
		timer = 3.0 if fast else randf_range(ev[0], ev[1]) * (0.5 if b.heat >= 7 else 1.0)
		if not in_arena or kind in WEATHER:
			var fn := Callable(self, "_start_" + kind)
			if fn.is_valid():
				fn.call()
	_update_movers(delta)
	_update_falling(delta)
	_update_springs(delta)
	_update_craters(delta)
	_update_clouds(delta)
	_update_plums(delta)
	_update_geo(delta)
	_update_bales(delta)
	_update_weather(delta)
	ground_node.queue_redraw()
	air_node.queue_redraw()
	if overlay:
		overlay.queue_redraw()


func _after(t: float, fn: Callable) -> void:
	pending.append([t, fn])


func _announce() -> void:
	if announced:
		return
	announced = true
	b.banner(d.name, Color("ff9a2a"), d.hint, 3.8)


## Zranění hrdiny podílem jeho životů (s mírným růstem podle obtížnosti) a odhození.
func _hurt(src: Vector2, push: Vector2 = Vector2.ZERO, frac: float = -1.0) -> void:
	var p := b.player
	if p.invuln > 0.0:
		return
	var f: float = d.get("dmg", 0.1) if frac < 0.0 else frac
	b.hit_player(p.max_hp * f * (1.0 + 0.02 * b.tier), src, true)
	p.knock = push


## Malé trvalé poškození (mráz, pálení) bez otřesu a zvuku.
func _drain(v: float, col: Color) -> void:
	var p := b.player
	if p.invuln > 0.0 or (b.state != Battle.State.PLAY and b.state != Battle.State.BOSS):
		return
	p.hp -= v
	b.fx.number(p.position + Vector2(0, -50), v, false, col)
	if p.hp <= 0.0:
		p.hp = 0.01
		b.hit_player(1.0, p.position, true)


## Běžného nepřítele nástraha zabije, elitě vezme část životů, náčelníkovi
## polovinu toho (nejvýš jednou za sekundu), bosse nechá být.
func _smash(e: Enemy, src: Vector2, drops: bool = true) -> void:
	if not e.alive or (e.is_boss and not e.chief):
		return
	var dir := (e.position - src).normalized()
	if e.chief:
		if b.time_total - float(e.hit_cd.get("hazard", -99.0)) < 1.0:
			return
		e.hit_cd["hazard"] = b.time_total
		var cdmg: float = e.max_hp * float(d.get("elite", 0.3)) * 0.5
		e.hp -= cdmg
		e.flash = 0.1
		b.fx.number(e.position + Vector2(0, -e.r - 6), cdmg, true, Color("ffb030"))
		# smrt řeší náčelník sám v příštím snímku (MiniBoss.die)
	elif e.elite:
		var dmg: float = e.max_hp * float(d.get("elite", 0.3))
		e.hp -= dmg
		e.flash = 0.1
		e.knock += dir * 520.0
		b.fx.number(e.position + Vector2(0, -e.r - 6), dmg, true, Color("ffb030"))
		if e.hp <= 0.0:
			b.enemies.kill(e, drops)
	else:
		b.enemies.kill(e, drops)


func _hit_area(pos: Vector2, r: float, push: Vector2) -> void:
	if b.player.position.distance_to(pos) < r + b.player.r * 0.5:
		_hurt(pos, push)
	for e in b.enemies.query(pos, r):
		_smash(e, pos)


# ---------------------------------------------------------------- vliv na pohyb

## Násobek rychlosti v daném místě (e == null je hrdina).
func speed_mult(pos: Vector2, e: Enemy) -> float:
	match kind:
		"vanice":
			if weather_in > 0.3:
				return 1.0 - float(d.enemy_slow if e else d.player_slow) * weather_in
		"rybniky":
			if _pond_at(pos) != null:
				if e and (e.id in d.swimmers or e.def.get("base", "") in d.swimmers):
					return 1.0 + float(d.swim_bonus)
				return 1.0 - float(d.slow)
		"katapult":
			for c in craters:
				if pos.distance_squared_to(c.pos) < c.r * c.r:
					return 1.0 - float(d.crater_slow)
	return 1.0


## Posun v daném místě (pásové dopravníky, vítr) v px/s.
func push_at(pos: Vector2, enemy: bool) -> Vector2:
	if kind == "pasy":
		for g in _geo_at(pos):
			if g.type == "belt":
				var rr: Rect2 = g.rect
				if rr.has_point(pos):
					return g.dir * float(d.belt_speed)
	elif kind == "vitr" and weather_t > 0.0:
		return wind_dir * float(d.enemy_push if enemy else d.push) * weather_in
	return Vector2.ZERO


## Vítr unáší i střely.
func shot_drift() -> Vector2:
	if kind == "vitr" and weather_t > 0.0:
		return wind_dir * float(d.push) * 0.8 * weather_in
	return Vector2.ZERO


## Místa, kterým se má automatický hráč vyhnout: [střed, poloměr].
func dangers() -> Array:
	var out := []
	for c in clouds:
		out.append([c.pos, c.r])
	for f in falling:
		if f.r > 0.0:
			out.append([f.to, f.r])
	for arr in geo.values():
		for g in arr:
			if g.type == "crack" and (g.warn > 0.0 or g.hot > 0.0):
				for i in range(0, g.pts.size(), 2):
					out.append([g.pts[i], float(d.w)])
	return out


## Pruhy, kterými právě něco jede: [začátek, konec, poloviční šířka].
func danger_lanes() -> Array:
	var out := []
	for m in movers:
		out.append([m.pos - m.dir * m.hl, m.pos + m.dir * 2400.0, m.hw + 30.0])
	return out


# ---------------------------------------------------------------- kousky mapy

func _ck(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / Battle.CHUNK), floori(pos.y / Battle.CHUNK))


func _geo_at(pos: Vector2) -> Array:
	return geo.get(_ck(pos), [])


func _geo_all(type: String) -> Array:
	var out := []
	for arr in geo.values():
		for g in arr:
			if g.type == type:
				out.append(g)
	return out


## Vytvoří geometrii nástrahy v kousku mapy; vrací uzly, které se uvolní s kouskem.
func make_chunk(k: Vector2i) -> Array:
	var nodes := []
	var items := []
	geo[k] = items
	if kind == "":
		return nodes
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(k.x, k.y, 9173 + b.region_id.hash()))
	var o := Vector2(k) * Battle.CHUNK
	match kind:
		"pasy":
			_chunk_belts(rng, o, items)
		"rybniky":
			_chunk_ponds(rng, o, items, nodes)
		"spory":
			_chunk_rings(rng, o, items, nodes)
		"praskliny":
			_chunk_cracks(rng, o, items)
		"svestky":
			_chunk_trees(rng, o, items, nodes)
	return nodes


func drop_chunk(k: Vector2i) -> void:
	geo.erase(k)


## Dekorace z Battle._make_chunk, které nástraha využívá (švestkové stromy, krystaly).
func register_prop(k: Vector2i, id: String, pos: Vector2) -> void:
	if kind == "svestky" and id == "svestka_strom":
		geo[k].append({"type": "tree", "pos": pos})
	elif kind == "mlha" and id == "krystal":
		geo[k].append({"type": "glow", "pos": pos})


## Může na tomto místě stát dekorace? (ne na pásu, v kruhu hub; lekníny jen ve vodě)
func decor_ok(id: String, pos: Vector2) -> bool:
	match kind:
		"rybniky":
			var wet := _pond_at(pos, 1.2) != null
			if id in ["leknin", "lodka"]:
				return _pond_at(pos, 0.7) != null
			return not wet
		"pasy":
			for g in _geo_at(pos):
				if g.type == "belt":
					var rr: Rect2 = g.rect
					if rr.grow(40.0).has_point(pos):
						return false
		"spory":
			for g in _geo_at(pos):
				if g.type == "ring" and pos.distance_to(g.c) < g.r + 40.0:
					return false
		"tramvaj":
			return absf(pos.y - _rail_y(pos.y)) > 90.0
	return true


func _chunk_belts(rng: RandomNumberGenerator, o: Vector2, items: Array) -> void:
	var sz: Array = d.belt_size
	for i in rng.randi_range(0, 2):
		var horiz := rng.randf() < 0.5
		var size := Vector2(sz[0], sz[1]) if horiz else Vector2(sz[1], sz[0])
		var p := o + Vector2(rng.randf_range(24.0, Battle.CHUNK - 24.0 - size.x), rng.randf_range(24.0, Battle.CHUNK - 24.0 - size.y))
		var rect := Rect2(p, size)
		if rect.grow(220.0).has_point(Vector2.ZERO):
			continue
		var clash := false
		for g in items:
			var rr: Rect2 = g.rect
			if rr.grow(40.0).intersects(rect):
				clash = true
		if clash:
			continue
		var sgn := 1.0 if rng.randf() < 0.5 else -1.0
		items.append({"type": "belt", "rect": rect, "dir": (Vector2.RIGHT if horiz else Vector2.DOWN) * sgn})


func _chunk_ponds(rng: RandomNumberGenerator, o: Vector2, items: Array, nodes: Array) -> void:
	if rng.randf() > 0.72:
		return
	var r := rng.randf_range(115.0, 185.0)
	var c := o + Vector2(rng.randf_range(r * 1.2 + 10.0, Battle.CHUNK - r * 1.2 - 10.0), rng.randf_range(r + 10.0, Battle.CHUNK - r - 10.0))
	if c.length() < r * 1.2 + 230.0:
		return
	var g := {"type": "pond", "c": c, "r": r, "p1": rng.randf() * TAU, "p2": rng.randf() * TAU, "ph": rng.randf() * TAU}
	var poly := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		poly.append(c + Vector2(cos(a), sin(a) * 0.75) * _pond_r(g, a))
	g["poly"] = poly
	g["shore"] = Art.grow(poly, 12.0)
	g["deep"] = Art.xform(Art.xform(poly, -c), c, Vector2(0.62, 0.62))
	items.append(g)
	# lekníny a občas loďka
	for i in rng.randi_range(1, 3):
		var a := rng.randf() * TAU
		var p := c + Vector2(cos(a), sin(a) * 0.75) * r * rng.randf_range(0.2, 0.6)
		var s := Baker.sprite("prop:leknin")
		s.position = p
		s.scale *= rng.randf_range(0.5, 0.7)
		s.flip_h = rng.randf() < 0.5
		b.ground_fx_layer.add_child(s)
		nodes.append(s)


func _pond_r(g: Dictionary, a: float) -> float:
	return g.r * (1.0 + 0.14 * sin(3.0 * a + g.p1) + 0.07 * sin(5.0 * a + g.p2))


func _pond_at(pos: Vector2, grow: float = 1.0) -> Variant:
	for g in _geo_at(pos):
		if g.type != "pond":
			continue
		var v: Vector2 = pos - g.c
		v.y /= 0.75
		if v.length() < _pond_r(g, v.angle()) * grow:
			return g
	return null


func _chunk_rings(rng: RandomNumberGenerator, o: Vector2, items: Array, nodes: Array) -> void:
	if rng.randf() > 0.6:
		return
	var r := rng.randf_range(72.0, 95.0)
	var c := o + Vector2(rng.randf_range(r + 30.0, Battle.CHUNK - r - 30.0), rng.randf_range(r + 30.0, Battle.CHUNK - r - 30.0))
	if c.length() < r + 240.0:
		return
	items.append({"type": "ring", "c": c, "r": r, "warn": 0.0})
	var n := rng.randi_range(9, 12)
	for i in n:
		var a := TAU * i / n + rng.randf_range(-0.15, 0.15)
		var s := Baker.sprite("hz:hribek")
		s.position = c + Vector2(cos(a), sin(a) * 0.8) * r * rng.randf_range(0.92, 1.08)
		s.scale *= rng.randf_range(0.8, 1.15)
		s.flip_h = rng.randf() < 0.5
		b.ground_fx_layer.add_child(s)
		nodes.append(s)


func _chunk_cracks(rng: RandomNumberGenerator, o: Vector2, items: Array) -> void:
	for i in rng.randi_range(1, 2):
		var p := o + Vector2(rng.randf_range(60.0, Battle.CHUNK - 60.0), rng.randf_range(60.0, Battle.CHUNK - 60.0))
		var a := rng.randf() * TAU
		var pts := PackedVector2Array([p])
		for s in rng.randi_range(6, 9):
			a += rng.randf_range(-0.6, 0.6)
			p += Vector2(cos(a), sin(a)) * rng.randf_range(38.0, 64.0)
			pts.append(p)
		var near_start := false
		for q in pts:
			if q.length() < 170.0:
				near_start = true
		if near_start:
			continue
		var bb := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			bb = bb.expand(q)
		items.append({"type": "crack", "pts": pts, "bbox": bb.grow(30.0), "warn": 0.0, "hot": 0.0, "tick": 0.0, "ph": rng.randf() * TAU})


func _chunk_trees(rng: RandomNumberGenerator, o: Vector2, items: Array, nodes: Array) -> void:
	for i in rng.randi_range(0, 2):
		var p := o + Vector2(rng.randf_range(40.0, Battle.CHUNK - 40.0), rng.randf_range(40.0, Battle.CHUNK - 40.0))
		if p.length() < 200.0:
			continue
		var s := Baker.sprite("prop:svestka_strom")
		s.position = p
		s.flip_h = rng.randf() < 0.5
		s.scale *= rng.randf_range(0.85, 1.05)
		b.entity_layer.add_child(s)
		nodes.append(s)
		items.append({"type": "tree", "pos": p})


func _update_geo(delta: float) -> void:
	for arr in geo.values():
		for g in arr:
			if g.type == "ring" and g.warn > 0.0:
				g.warn -= delta
			elif g.type == "crack":
				if g.warn > 0.0:
					g.warn -= delta
				if g.hot > 0.0:
					g.hot -= delta
					g.tick -= delta
					if g.tick <= 0.0:
						g.tick = 0.5
						_burn_crack(g)


# ---------------------------------------------------------------- Karlovarsko: gejzíry

func _start_gejzir() -> void:
	_announce()
	var cnt: Array = d.count
	var pp := b.player.position
	Sfx.play("warn", -10.0)
	for i in randi_range(cnt[0], cnt[1]):
		var pos: Vector2 = (pp + b.player.move_dir * 70.0) if i == 0 else (pp + Vector2.from_angle(randf() * TAU) * randf_range(120.0, 260.0))
		b.ground_fx.circle_warn(pos, float(d.r), float(d.warn), Color(0.55, 0.85, 1.0), _gejzir_burst)


func _gejzir_burst(pos: Vector2, r: float) -> void:
	Sfx.play("gejzir", -4.0, 0.1, 0.0)
	b.fx.explosion(pos, r, Color(0.85, 0.95, 1.0))
	b.fx.burst(pos, Color(1, 1, 1, 0.9), 10, 280.0, 7.0)
	_hit_area(pos, r, (b.player.position - pos).normalized() * 520.0)
	var life: float = d.spring_dur
	springs.append({"pos": pos, "r": r * 0.75, "life": life, "max": life})


func _update_springs(delta: float) -> void:
	var on := false
	for s in springs.duplicate():
		s.life -= delta
		if s.life <= 0.0:
			springs.erase(s)
		elif b.player.position.distance_to(s.pos) < s.r:
			on = true
	if on:
		spring_t += delta
		if spring_t >= 1.0:
			spring_t -= 1.0
			if b.player.hp < b.player.max_hp:
				b.heal(float(d.spring_heal))
	else:
		spring_t = 0.0


# ---------------------------------------------------------------- Plzeňsko: sudy

func _start_sudy() -> void:
	_announce()
	var dir := Vector2.from_angle(randi_range(0, 7) * PI / 4.0)
	var center := b.player.position + dir.orthogonal() * randf_range(-110.0, 110.0)
	var start := center - dir * 1100.0
	b.ground_fx.line_warn(start, dir, 2200.0, 90.0, float(d.warn))
	Sfx.play("warn", -8.0)
	_after(d.warn, func():
		Sfx.play("valeni", -2.0, 0.05, 0.0)
		var r: float = d.r
		for i in int(d.count):
			var lat := dir.orthogonal() * (22.0 if i % 2 == 0 else -22.0)
			var m := _mover("sud", start - dir * (i * 150.0) + lat, dir, float(d.speed), r, r, 3.6)
			m.spin = float(d.speed) / r)


# ---------------------------------------------------------------- Pardubicko: dostih

func _start_dostih() -> void:
	_announce()
	var dir := Vector2.RIGHT if randf() < 0.5 else Vector2.LEFT
	var start := Vector2(b.player.position.x - dir.x * 1200.0, b.player.position.y + randf_range(-90.0, 90.0))
	b.ground_fx.line_warn(start, dir, 2400.0, 130.0, float(d.warn))
	Sfx.play("trubka", -2.0, 0.0, 0.0)
	_after(d.warn, func():
		Sfx.play("dusot", 0.0, 0.05, 0.0)
		for i in int(d.count):
			var lat := Vector2(0, 22.0 if i % 2 == 0 else -22.0)
			var m := _mover("kun", start - dir * (i * 170.0) + lat, dir, float(d.speed), 70.0, 34.0, 3.6)
			m.off = Vector2(0, 34))


# ---------------------------------------------------------------- Praha: tramvaj

func _rail_y(y: float) -> float:
	var gap: float = d.rail_gap
	var off: float = d.rail_off
	return roundf((y - off) / gap) * gap + off


func _start_tramvaj() -> void:
	var ry := _rail_y(b.player.position.y)
	if absf(ry - b.player.position.y) > 430.0:
		timer = 2.0
		return
	_announce()
	var dir := Vector2.RIGHT if randf() < 0.5 else Vector2.LEFT
	var start := Vector2(b.player.position.x - dir.x * 1400.0, ry)
	b.ground_fx.line_warn(start, dir, 2800.0, 120.0, float(d.warn))
	Sfx.play("zvonek", 0.0, 0.0, 0.0)
	_after(0.8, func(): Sfx.play("zvonek", 0.0, 0.0, 0.0))
	_after(d.warn, func():
		var m := _mover("tramvaj", start, dir, float(d.speed), 225.0, 52.0, 3.4)
		m.off = Vector2(0, 46))


# ---------------------------------------------------------------- Olomoucko: kombajn

func _start_kombajn() -> void:
	_announce()
	var dir := Vector2.RIGHT if randf() < 0.5 else Vector2.LEFT
	var start := Vector2(b.player.position.x - dir.x * 1200.0, b.player.position.y + randf_range(-70.0, 70.0))
	var w: float = d.width
	b.ground_fx.line_warn(start, dir, 2400.0, w, float(d.warn))
	Sfx.play("warn", -6.0)
	_after(d.warn, func():
		Sfx.play("kombajn", 0.0, 0.0, 0.0)
		var m := _mover("kombajn", start, dir, float(d.speed), 120.0, w * 0.5, 4.8)
		m.off = Vector2(0, 64)
		m["bale"] = 0.0)


func _update_bales(delta: float) -> void:
	for bl in bales.duplicate():
		bl.life -= delta
		if bl.life < 1.0:
			bl.spr.modulate.a = maxf(0.0, bl.life)
		if bl.life <= 0.0:
			bl.spr.queue_free()
			bales.erase(bl)


# ---------------------------------------------------------------- pohyblivé nástrahy

func _mover(id: String, pos: Vector2, dir: Vector2, speed: float, hl: float, hw: float, life: float) -> Dictionary:
	var anim := id in ANIMATED
	var spr := Baker.sprite("hz:" + id + ("0" if anim else ""))
	spr.flip_h = dir.x < 0.0
	b.entity_layer.add_child(spr)
	var m := {"id": id, "spr": spr, "pos": pos, "dir": dir, "speed": speed, "hl": hl, "hw": hw, "life": life,
		"hit": false, "spin": 0.0, "off": Vector2.ZERO, "anim": anim, "ft": 0.0}
	spr.position = pos
	movers.append(m)
	return m


func _in_box(p: Vector2, m: Dictionary, pad: float) -> bool:
	var local: Vector2 = p - m.pos
	var dir: Vector2 = m.dir
	return absf(local.dot(dir)) <= m.hl + pad and absf(local.dot(dir.orthogonal())) <= m.hw + pad


func _update_movers(delta: float) -> void:
	for m in movers.duplicate():
		var dir: Vector2 = m.dir
		m.pos += dir * m.speed * delta
		var spr: Sprite2D = m.spr
		spr.position = m.pos + m.off
		if m.spin != 0.0:
			spr.rotation += m.spin * delta * (1.0 if dir.x >= 0.0 else -1.0)
		if m.anim:
			m.ft += delta
			spr.texture = Baker.tex("hz:%s%d" % [m.id, int(m.ft * 9.0) % 2])
		for e in b.enemies.query(m.pos, m.hl + 12.0):
			if _in_box(e.position, m, e.r):
				_smash(e, m.pos - dir * 60.0)
		if not m.hit and _in_box(b.player.position, m, b.player.r * 0.6):
			m.hit = true
			var side: Vector2 = dir.orthogonal()
			if (b.player.position - m.pos).dot(side) < 0.0:
				side = -side
			_hurt(m.pos, side * 620.0 + dir * 200.0)
		if m.has("bale"):
			m.bale += m.speed * delta
			if m.bale >= 260.0:
				m.bale -= 260.0
				var s := Baker.sprite("hz:balik")
				s.position = m.pos - dir * 140.0 + Vector2(0, randf_range(-50.0, 50.0))
				s.flip_h = randf() < 0.5
				b.entity_layer.add_child(s)
				bales.append({"spr": s, "life": 10.0})
		m.life -= delta
		if m.life <= 0.0:
			spr.queue_free()
			movers.erase(m)


# ---------------------------------------------------------------- dopady shora (kámen, uhlí, švestky)

## Předmět spadne na `pos` za `dur` sekund. r > 0 = červený kruh varování.
func _drop(id: String, pos: Vector2, dur: float, r: float, col: Color, on_land: Callable, from: Vector2, arc: bool = false) -> void:
	if r > 0.0:
		b.ground_fx.circle_warn(pos, r, dur, col)
	var spr := Baker.sprite("hz:" + id)
	b.proj_layer.add_child(spr)
	spr.position = pos + from
	falling.append({"spr": spr, "from": pos + from, "to": pos, "t": 0.0, "dur": dur, "cb": on_land, "r": r, "arc": arc})


func _update_falling(delta: float) -> void:
	for f in falling.duplicate():
		f.t += delta
		var k := clampf(f.t / f.dur, 0.0, 1.0)
		var spr: Sprite2D = f.spr
		var from: Vector2 = f.from
		var to: Vector2 = f.to
		if f.arc:
			spr.position = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 260.0)
			spr.rotation += delta * 5.0
		else:
			spr.position = from.lerp(to, k * k)
		if k >= 1.0:
			spr.queue_free()
			falling.erase(f)
			var cb: Callable = f.cb
			cb.call(to)


# ---------------------------------------------------------------- Ústecko: pásy a uhlí

func _start_pasy() -> void:
	var best: Variant = null
	var bd := 650.0
	for g in _geo_all("belt"):
		var gr: Rect2 = g.rect
		var dd: float = gr.get_center().distance_to(b.player.position)
		if dd < bd:
			bd = dd
			best = g
	if best == null:
		timer = 1.0
		return
	_announce()
	var rect: Rect2 = best.rect
	var dir: Vector2 = best.dir
	var end := rect.get_center() + dir * maxf(rect.size.x, rect.size.y) * 0.5
	var r: float = d.r
	for i in 3:
		var pos := end + dir * randf_range(40.0, 170.0) + dir.orthogonal() * randf_range(-60.0, 60.0)
		_drop("uhli", pos, float(d.warn) + i * 0.15, r, Color(1, 0.15, 0.1), func(p: Vector2): _coal_land(p, r), Vector2(0, -520))


func _coal_land(pos: Vector2, r: float) -> void:
	b.fx.burst(pos, Color("3a3a40"), 8, 200.0, 6.0)
	Sfx.play("hit", -4.0, 0.2, 0.0)
	_hit_area(pos, r, (b.player.position - pos).normalized() * 300.0)


# ---------------------------------------------------------------- Středočesko: katapult

func _start_katapult() -> void:
	_announce()
	var n := 1 if b.elapsed < b.duration * 0.6 else 2
	var r: float = d.r
	Sfx.play("warn", -8.0)
	for i in n:
		var target := b.player.position + b.player.move_dir * 90.0
		if i > 0:
			target += Vector2.from_angle(randf() * TAU) * randf_range(90.0, 200.0)
		var side := -1.0 if randf() < 0.5 else 1.0
		_drop("kamen", target, float(d.warn), r, Color(1, 0.3, 0.1), _stone_land, Vector2(side * 650.0, -420.0), true)


func _stone_land(pos: Vector2) -> void:
	var r: float = d.r
	Sfx.play("boom", -6.0, 0.1, 0.0)
	b.fx.explosion(pos, r, Color("c9a06a"))
	b.shake(6.0)
	_hit_area(pos, r, (b.player.position - pos).normalized() * 420.0)
	var life: float = d.crater_dur
	craters.append({"pos": pos, "r": r, "life": life, "max": life})


func _update_craters(delta: float) -> void:
	for c in craters.duplicate():
		c.life -= delta
		if c.life <= 0.0:
			craters.erase(c)


# ---------------------------------------------------------------- Vysočina: houbové spory

func _start_spory() -> void:
	var any := false
	var warn: float = d.warn
	for g in _geo_all("ring"):
		if g.c.distance_to(b.player.position) < 800.0:
			any = true
			g.warn = warn
			var gg: Dictionary = g
			_after(warn, func(): _spore_cloud(gg.c))
	if any:
		_announce()
		Sfx.play("warn", -12.0)


func _spore_cloud(pos: Vector2) -> void:
	Sfx.play("spory", -4.0, 0.1, 0.0)
	var life: float = d.cloud_dur
	clouds.append({"pos": pos, "r": float(d.r), "life": life, "max": life, "tick": 0.0})


func _update_clouds(delta: float) -> void:
	for c in clouds.duplicate():
		c.life -= delta
		c.tick -= delta
		if c.tick <= 0.0:
			c.tick = 0.5
			if b.player.position.distance_to(c.pos) < c.r:
				b.hit_player(b.player.max_hp * float(d.dmg) * (1.0 + 0.02 * b.tier), c.pos)
			for e in b.enemies.query(c.pos, c.r):
				if not e.is_boss or e.chief:
					e.poison_t = 2.0
					var share := 0.03 if e.chief else (0.25 if e.elite else 0.6)
					e.poison_dps = maxf(e.poison_dps, e.max_hp * share)
		if c.life <= 0.0:
			clouds.erase(c)


# ---------------------------------------------------------------- Zlínsko: švestky

func _start_svestky() -> void:
	var pp := b.player.position
	var vr := b.view_rect().grow(60.0)
	var cands := []
	for g in _geo_all("tree"):
		if vr.has_point(g.pos):
			cands.append(g)
	if cands.is_empty():
		timer = 1.0
		return
	_announce()
	cands.sort_custom(func(a, c): return a.pos.distance_squared_to(pp) < c.pos.distance_squared_to(pp))
	var g: Dictionary = cands[randi() % mini(3, cands.size())]
	var to: Vector2 = g.pos + Vector2(randf_range(-70.0, 70.0), randf_range(10.0, 46.0))
	var from: Vector2 = g.pos + Vector2(randf_range(-30.0, 30.0), -110.0) - to
	_drop("svestka", to, 0.45, 0.0, Color.WHITE, _plum_land, from)


func _plum_land(pos: Vector2) -> void:
	Sfx.play("plop", -6.0, 0.15, 0.0)
	var s := Baker.sprite("hz:svestka")
	s.position = pos
	b.pickup_layer.add_child(s)
	plums.append({"pos": pos, "spr": s, "life": 16.0})
	if plums.size() > int(d.max):
		var old: Dictionary = plums.pop_front()
		old.spr.queue_free()


func _update_plums(delta: float) -> void:
	var pp := b.player.position
	for pl in plums.duplicate():
		pl.life -= delta
		var gone: bool = pl.life <= 0.0
		if not gone and pp.distance_to(pl.pos) < b.player.r + 18.0:
			b.heal(float(d.heal))
			Sfx.play("pickup", -4.0)
			gone = true
		if not gone:
			for e in b.enemies.query(pl.pos, 10.0):
				if e.is_boss or e.state != Enemy.St.MOVE:
					continue
				e.state = Enemy.St.REST
				e.timer = float(d.stun)
				e.knock = Vector2.from_angle(randf() * TAU) * 120.0
				b.fx.burst(pl.pos, Color("6a4ab8"), 5, 120.0, 4.0)
				if not b.low_quality:
					b.fx.text(e.position + Vector2(0, -e.r - 14), "Uf!", Color("d9c8ff"), 18)
				gone = true
				break
		if gone:
			pl.spr.queue_free()
			plums.erase(pl)


# ---------------------------------------------------------------- Moravskoslezsko: praskliny

func _dist_poly(p: Vector2, pts: PackedVector2Array) -> float:
	var best := INF
	for i in pts.size() - 1:
		best = minf(best, Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1]).distance_to(p))
	return best


func _start_praskliny() -> void:
	var best: Variant = null
	var bd := 520.0
	for g in _geo_all("crack"):
		if g.warn > 0.0 or g.hot > 0.0:
			continue
		var dd := _dist_poly(b.player.position, g.pts)
		if dd < bd:
			bd = dd
			best = g
	if best == null:
		timer = 2.0
		return
	_announce()
	best.warn = float(d.warn)
	Sfx.play("praskani", -4.0, 0.05, 0.0)
	var gg: Dictionary = best
	_after(d.warn, func(): _erupt(gg))


func _erupt(g: Dictionary) -> void:
	Sfx.play("boom", -6.0, 0.1, 0.0)
	b.shake(5.0)
	var w: float = d.w
	var pts: PackedVector2Array = g.pts
	var pp := b.player.position
	if _dist_poly(pp, pts) < w * 0.5 + b.player.r * 0.5:
		_hurt(pp, Vector2.ZERO)
	var hit := {}
	for i in pts.size() - 1:
		var steps := maxi(1, int(pts[i].distance_to(pts[i + 1]) / 30.0))
		for s in steps:
			var p := pts[i].lerp(pts[i + 1], float(s) / steps)
			if not b.low_quality or s % 2 == 0:
				b.fx.burst(p, Color("ff8a1a"), 2, 200.0, 6.0)
			for e in b.enemies.query(p, w * 0.6):
				if not hit.has(e):
					hit[e] = true
					_smash(e, p)
	g.hot = float(d.trail_dur)
	g.tick = 0.5


func _burn_crack(g: Dictionary) -> void:
	var w: float = d.w
	var pts: PackedVector2Array = g.pts
	if _dist_poly(b.player.position, pts) < w * 0.5 + b.player.r * 0.4:
		_drain(b.player.max_hp * float(d.trail_dmg), Color("ff8a3a"))
	for i in range(0, pts.size(), 2):
		for e in b.enemies.query(pts[i], w):
			if not e.is_boss or e.chief:
				e.burn_t = 2.0
				e.burn_dps = maxf(e.burn_dps, e.max_hp * (0.02 if e.chief else 0.35))


# ---------------------------------------------------------------- počasí

func _start_mlha() -> void:
	_announce()
	weather_t = float(d.dur)
	Sfx.play("vitr", -10.0, 0.0, 0.0)


func _start_vanice() -> void:
	_announce()
	weather_t = float(d.dur)
	Sfx.play("vitr", -3.0, 0.0, 0.0)


func _start_vitr() -> void:
	_announce()
	wind_dir = Vector2.from_angle(randi_range(0, 7) * PI / 4.0)
	warn_t = float(d.warn)
	Sfx.play("vitr", -8.0, 0.0, 0.0)
	_after(d.warn, func():
		weather_t = float(d.dur)
		Sfx.play("vitr", 0.0, 0.0, 0.0))


func _start_rybniky() -> void:
	for g in _geo_all("pond"):
		if g.c.distance_to(b.player.position) < 650.0:
			_announce()
			return
	timer = 2.0


func _update_weather(delta: float) -> void:
	if not kind in WEATHER:
		return
	warn_t = maxf(0.0, warn_t - delta)
	if weather_t > 0.0:
		weather_t -= delta
		weather_in = minf(1.0, weather_in + delta / 1.2)
	else:
		weather_in = maxf(0.0, weather_in - delta / 1.2)
	if kind == "vanice" and weather_t > 0.0:
		if b.player.move_dir.length() < 0.15:
			still_t += delta
		else:
			still_t = 0.0
		if still_t > 0.5:
			freeze_t += delta
			if freeze_t >= 1.0:
				freeze_t -= 1.0
				_drain(float(d.freeze), Color("9fd8ff"))
	else:
		still_t = 0.0
	if fog_rect:
		fog_rect.visible = weather_in > 0.0
		if fog_rect.visible:
			var sm := fog_rect.material as ShaderMaterial
			sm.set_shader_parameter("center", b.world.get_global_transform_with_canvas() * b.player.position)
			sm.set_shader_parameter("rect_size", fog_rect.size)
			sm.set_shader_parameter("strength", weather_in)
			sm.set_shader_parameter("radius", float(d.view))
			sm.set_shader_parameter("time_s", time)
	if kind == "vanice" or kind == "vitr":
		_update_flakes(delta)


## Vločky a čáry větru v souřadnicích obrazovky (posouvají se s kamerou).
func _update_flakes(delta: float) -> void:
	if overlay == null:
		return
	var sz := overlay.size
	var n := 45 if b.low_quality else 100
	if kind == "vitr":
		n = 25 if b.low_quality else 45
	while flakes.size() < n:
		flakes.append({"p": Vector2(randf() * sz.x, randf() * sz.y), "s": randf_range(0.6, 1.4)})
	var cam := b.camera.position
	var dcam := (cam - last_cam) * b.camera.zoom.x
	last_cam = cam
	if dcam.length() > 200.0:
		dcam = Vector2.ZERO
	var v := Vector2(-120.0, 330.0) if kind == "vanice" else wind_dir * 900.0
	for f in flakes:
		var p: Vector2 = f.p + v * f.s * delta - dcam
		f.p = Vector2(fposmod(p.x, sz.x + 40.0), fposmod(p.y, sz.y + 40.0))


func _fog_shader() -> Shader:
	var s := Shader.new()
	s.code = """
shader_type canvas_item;
uniform vec2 center = vec2(640.0, 360.0);
uniform vec2 rect_size = vec2(1280.0, 720.0);
uniform float radius = 280.0;
uniform float strength = 0.0;
uniform float time_s = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	vec2 px = UV * rect_size;
	float n = noise(px * 0.006 + vec2(time_s * 0.06, time_s * 0.02)) * 0.6 + noise(px * 0.017 - vec2(time_s * 0.09, 0.0)) * 0.4;
	float dd = distance(px, center) + (n - 0.5) * 90.0;
	float a = smoothstep(radius * 0.5, radius * 1.25, dd) * (0.84 + 0.14 * n);
	COLOR = vec4(mix(vec3(0.76, 0.81, 0.87), vec3(0.94, 0.96, 0.98), n), a * strength);
}
"""
	return s


# ---------------------------------------------------------------- kreslení

func _draw_ground(ci: Node2D) -> void:
	var vr := b.view_rect().grow(140.0)
	var low := b.low_quality
	if kind == "tramvaj":
		_draw_rails(ci, vr)
	for arr in geo.values():
		for g in arr:
			match g.type:
				"belt":
					if vr.intersects(g.rect):
						_draw_belt(ci, g)
				"pond":
					if vr.grow(g.r * 1.3).has_point(g.c):
						_draw_pond(ci, g, low)
				"ring":
					if vr.has_point(g.c):
						_draw_ring(ci, g)
				"crack":
					if vr.intersects(g.bbox):
						_draw_crack(ci, g)
	for s in springs:
		_draw_spring(ci, s, low)
	for c in craters:
		var fade := clampf(c.life / 0.8, 0.0, 1.0) * clampf((c.max - c.life) / 0.2, 0.0, 1.0)
		Art.safe_poly(ci, Art.ellipse(c.pos, c.r, c.r * 0.7, 24), Color(0.28, 0.22, 0.16, 0.5 * fade))
		Art.safe_poly(ci, Art.ellipse(c.pos + Vector2(0, 4), c.r * 0.7, c.r * 0.45, 20), Color(0.18, 0.14, 0.1, 0.45 * fade))
		for i in 7:
			var a := TAU * i / 7.0
			ci.draw_circle(c.pos + Vector2(cos(a), sin(a) * 0.7) * c.r * 0.95, 6.0, Color(0.6, 0.58, 0.55, 0.8 * fade))
	for pl in plums:
		var pulse := 0.5 + 0.5 * sin(time * 4.0 + pl.pos.x)
		ci.draw_circle(pl.pos + Vector2(0, 4), 20.0 + 3.0 * pulse, Color(1.0, 0.95, 0.6, 0.22 + 0.12 * pulse))
	for f in falling:
		var k := clampf(f.t / f.dur, 0.0, 1.0)
		var rr := 10.0 + 14.0 * k
		Art.safe_poly(ci, Art.ellipse(f.to, rr, rr * 0.45, 14), Color(0, 0, 0, 0.35 * k))


func _draw_rails(ci: Node2D, vr: Rect2) -> void:
	var gap: float = d.rail_gap
	var off: float = d.rail_off
	var k0 := floori((vr.position.y - off) / gap)
	var k1 := ceili((vr.end.y - off) / gap)
	for k in range(k0, k1 + 1):
		var y := off + k * gap
		var x0 := vr.position.x
		var x1 := vr.end.x
		ci.draw_rect(Rect2(x0, y - 48.0, x1 - x0, 96.0), Color(0.36, 0.33, 0.29, 0.35))
		var sx := floorf(x0 / 64.0) * 64.0
		while sx < x1:
			ci.draw_rect(Rect2(sx, y - 34.0, 22.0, 68.0), Color(0.3, 0.27, 0.24, 0.35))
			sx += 64.0
		for s: int in [-1, 1]:
			var ry := y + s * 22.0
			ci.draw_line(Vector2(x0, ry + 2.0), Vector2(x1, ry + 2.0), Color("2a2622"), 10.0)
			ci.draw_line(Vector2(x0, ry - 1.0), Vector2(x1, ry - 1.0), Color("aab3bd"), 4.0)
			ci.draw_line(Vector2(x0, ry - 2.0), Vector2(x1, ry - 2.0), Color("eef3f7"), 1.5)


func _draw_belt(ci: Node2D, g: Dictionary) -> void:
	var r: Rect2 = g.rect
	var dir: Vector2 = g.dir
	var L := maxf(r.size.x, r.size.y)
	var W := minf(r.size.x, r.size.y)
	ci.draw_set_transform(r.get_center(), dir.angle())
	var outer := Rect2(-L * 0.5 - 10.0, -W * 0.5 - 6.0, L + 20.0, W + 12.0)
	Art.safe_poly(ci, Art.rrect(Rect2(outer.position + Vector2(3, 7), outer.size), 12), Color(0, 0, 0, 0.25))
	Art.outline(ci, Art.rrect(outer, 12), 3.0)
	Art.grad(ci, Art.rrect(outer, 12), Color("9aa3ad"), Color("5a6168"))
	var band := Rect2(-L * 0.5, -W * 0.5 + 5.0, L, W - 10.0)
	ci.draw_rect(band, Color("2c2c30"))
	var sp := 30.0
	var off := fposmod(time * float(d.belt_speed), sp)
	var x := -L * 0.5 + off
	while x < L * 0.5 - 2.0:
		if x > -L * 0.5 + 10.0:
			var pts := PackedVector2Array([Vector2(x - 9.0, -W * 0.5 + 12.0), Vector2(x, 0), Vector2(x - 9.0, W * 0.5 - 12.0)])
			ci.draw_polyline(pts, Color(1.0, 0.79, 0.16, 0.8), 4.0, true)
		x += sp
	for ex: float in [-L * 0.5 - 4.0, L * 0.5 + 4.0]:
		Art.flat(ci, Art.rrect(Rect2(ex - 7.0, -W * 0.5 - 2.0, 14.0, W + 4.0), 6), Color("c3ccd6"), 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0)


func _draw_pond(ci: Node2D, g: Dictionary, low: bool) -> void:
	var water := Color(b.region.ground.c)
	Art.safe_poly(ci, g.shore, Color("7a6a42"))
	Art.safe_poly(ci, g.poly, water)
	Art.safe_poly(ci, g.deep, water.darkened(0.15))
	var closed: PackedVector2Array = g.poly.duplicate()
	closed.append(g.poly[0])
	ci.draw_polyline(closed, Color(water.lightened(0.35), 0.8), 3.0, true)
	if low:
		return
	for i in 3:
		var k := fposmod(time * 0.35 + i / 3.0 + g.ph, 1.0)
		var rr: float = g.r * (0.2 + 0.6 * k)
		ci.draw_arc(g.c + Vector2(cos(g.ph + i * 2.0), sin(g.ph + i * 2.0) * 0.5) * g.r * 0.3, rr * 0.3, 0.0, TAU, 20, Color(1, 1, 1, 0.35 * (1.0 - k)), 2.0, true)
	for i in 4:
		var a: float = g.ph + i * 1.7
		var p: Vector2 = g.c + Vector2(cos(a), sin(a) * 0.6) * g.r * 0.5
		var s := 6.0 + 3.0 * sin(time * 2.0 + i)
		ci.draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color(1, 1, 1, 0.45), 2.0, true)


func _draw_ring(ci: Node2D, g: Dictionary) -> void:
	ci.draw_circle(g.c, g.r + 14.0, Color(0.2, 0.35, 0.12, 0.22))
	if g.warn > 0.0:
		var pulse := 0.5 + 0.5 * sin(time * 22.0)
		ci.draw_circle(g.c, float(d.r), Color(0.7, 0.3, 0.95, 0.18 + 0.15 * pulse))
		ci.draw_arc(g.c, float(d.r), 0.0, TAU, 48, Color(0.85, 0.45, 1.0, 0.9), 3.0, true)


func _draw_crack(ci: Node2D, g: Dictionary) -> void:
	var pts: PackedVector2Array = g.pts
	ci.draw_polyline(pts, Color("1e1612"), 13.0, true)
	if g.hot > 0.0:
		var a := clampf(g.hot / 0.8, 0.0, 1.0)
		ci.draw_polyline(pts, Color(1.0, 0.35, 0.05, 0.55 * a), float(d.w), true)
		ci.draw_polyline(pts, Color(1.0, 0.75, 0.2, 0.9 * a), 10.0, true)
		ci.draw_polyline(pts, Color(1.0, 0.95, 0.7, a), 4.0, true)
	elif g.warn > 0.0:
		var pulse := 0.5 + 0.5 * sin(time * 26.0)
		ci.draw_polyline(pts, Color(1.0, 0.2, 0.1, 0.25 + 0.2 * pulse), float(d.w) + 8.0, true)
		ci.draw_polyline(pts, Color(1.0, 0.55 + 0.4 * pulse, 0.15, 1.0), 6.0, true)
	else:
		var glow := 0.35 + 0.15 * sin(time * 2.0 + g.ph)
		ci.draw_polyline(pts, Color(1.0, 0.45, 0.1, glow), 4.0, true)


func _draw_spring(ci: Node2D, s: Dictionary, low: bool) -> void:
	var fade := clampf(s.life / 0.8, 0.0, 1.0) * clampf((s.max - s.life) / 0.3, 0.0, 1.0)
	Art.safe_poly(ci, Art.ellipse(s.pos, s.r, s.r * 0.62, 28), Color(0.45, 0.8, 1.0, 0.6 * fade))
	Art.safe_poly(ci, Art.ellipse(s.pos, s.r * 0.6, s.r * 0.36, 20), Color(0.7, 0.92, 1.0, 0.55 * fade))
	ci.draw_arc(s.pos, s.r, 0.0, TAU, 32, Color(1, 1, 1, 0.5 * fade), 2.0, true)
	if low:
		return
	for i in 4:
		var k := fposmod(time * 0.6 + i * 0.25, 1.0)
		var p: Vector2 = s.pos + Vector2(sin(i * 2.3 + time) * s.r * 0.4, -k * 70.0)
		ci.draw_circle(p, 10.0 + k * 10.0, Color(1, 1, 1, 0.35 * (1.0 - k) * fade))


func _draw_air(ci: Node2D) -> void:
	var low := b.low_quality
	for c in clouds:
		var fade := clampf(c.life / 0.6, 0.0, 1.0) * clampf((c.max - c.life) / 0.4, 0.0, 1.0)
		var n := 5 if low else 9
		ci.draw_circle(c.pos, c.r, Color(0.45, 0.25, 0.6, 0.22 * fade))
		for i in n:
			var a := TAU * i / n + time * 0.7
			var p: Vector2 = c.pos + Vector2(cos(a), sin(a) * 0.7) * c.r * 0.55 + Vector2(0, -12.0 - 8.0 * sin(time * 2.0 + i))
			ci.draw_circle(p, c.r * 0.42, Color(0.7, 0.45, 0.95, 0.3 * fade))
			ci.draw_circle(p + Vector2(-6, -8), c.r * 0.18, Color(0.95, 0.85, 1.0, 0.3 * fade))
		ci.draw_circle(c.pos + Vector2(0, -10), c.r * 0.5, Color(0.6, 0.85, 0.35, 0.28 * fade))


func _draw_weather(ci: Control) -> void:
	var sz := ci.size
	if kind == "mlha":
		if weather_in <= 0.0:
			return
		var xf := b.world.get_global_transform_with_canvas()
		for g in _geo_all("glow"):
			var sp: Vector2 = xf * (g.pos + Vector2(0, -30))
			if Rect2(Vector2.ZERO, sz).grow(60.0).has_point(sp):
				for k in 4:
					ci.draw_circle(sp, 54.0 - k * 12.0, Color(0.5, 0.95, 1.0, 0.12 * weather_in))
	elif kind == "vanice":
		if weather_in <= 0.0:
			return
		ci.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.5, 0.62, 0.8, 0.2 * weather_in))
		for f in flakes:
			var p: Vector2 = f.p
			ci.draw_line(p, p + Vector2(4.0, -11.0) * f.s, Color(1, 1, 1, 0.5 * weather_in), 2.0 * f.s, true)
			ci.draw_circle(p, 2.6 * f.s, Color(1, 1, 1, 0.9 * weather_in))
		if still_t > 0.5:
			var a := clampf((still_t - 0.5) / 1.0, 0.0, 1.0) * weather_in
			for k in 5:
				var w := 14.0 + k * 12.0
				var col := Color(0.6, 0.85, 1.0, 0.1 * a)
				ci.draw_rect(Rect2(0, 0, sz.x, w), col)
				ci.draw_rect(Rect2(0, sz.y - w, sz.x, w), col)
				ci.draw_rect(Rect2(0, 0, w, sz.y), col)
				ci.draw_rect(Rect2(sz.x - w, 0, w, sz.y), col)
	elif kind == "vitr":
		if weather_in > 0.0:
			for f in flakes:
				var p: Vector2 = f.p
				ci.draw_line(p, p - wind_dir * 46.0 * f.s, Color(1, 1, 1, 0.45 * weather_in), 2.0, true)
		if warn_t > 0.0 or weather_t > 0.0:
			var blink := warn_t <= 0.0 or int(warn_t * 6.0) % 2 == 0
			if blink:
				var c := sz * 0.5 - wind_dir * Vector2(sz.x * 0.36, sz.y * 0.3)
				var arrow := Art.poly([-36, -13, 6, -13, 6, -28, 40, 0, 6, 28, 6, 13, -36, 13])
				Art.shape(ci, Art.xform(arrow, c, Vector2.ONE, wind_dir.angle()), Color("bfe8ff"), 3.0)
				Art.text(ci, c + Vector2(0, 52), "VÍTR", 20, Color.WHITE, 6)
