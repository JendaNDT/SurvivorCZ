extends Node
class_name ProjectileSystem
## Střely hráče i nepřátel a plošné zóny (jedové louže, lávové kaluže bossů).


class Proj:
	var kind := ""
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var dmg := 0.0
	var tags: Array = []
	var pierce := 0
	var r := 10.0
	var life := 2.0
	var hits := {}
	var spr: Sprite2D
	var spin := 0.0
	var grav := 0.0
	var explode_r := 0.0
	var burn := 0.0
	var knock := 120.0
	var hostile := false
	var lob := false
	var start := Vector2.ZERO
	var target := Vector2.ZERO
	var t := 0.0
	var dur := 0.0
	var zone_r := 0.0
	var zone_dmg := 0.0
	var zone_dur := 0.0
	var face_vel := true
	var nohit := false


class Zone:
	var pos := Vector2.ZERO
	var r := 50.0
	var life := 3.0
	var max_life := 3.0
	var dmg := 5.0
	var tick := 0.4
	var tick_t := 0.0
	var hostile := false
	var tags: Array = []
	var spr: Sprite2D


var b: Battle
var shots: Array = []
var enemy_shots: Array = []
var zones: Array = []


func init(battle: Battle) -> void:
	b = battle


func _make_sprite(key: String, layer: Node2D) -> Sprite2D:
	var s := Baker.sprite(key)
	layer.add_child(s)
	return s


func player_shot(kind: String, pos: Vector2, vel: Vector2, dmg: float, tags: Array, opts: Dictionary = {}) -> Proj:
	var p := Proj.new()
	p.kind = kind
	p.pos = pos
	p.vel = vel
	p.dmg = dmg
	p.tags = tags
	p.pierce = opts.get("pierce", 0)
	p.r = opts.get("r", 12.0)
	p.life = opts.get("life", 2.0)
	p.spin = opts.get("spin", 0.0)
	p.grav = opts.get("grav", 0.0)
	p.explode_r = opts.get("explode_r", 0.0)
	p.burn = opts.get("burn", 0.0)
	p.knock = opts.get("knock", 120.0)
	p.face_vel = opts.get("face_vel", true)
	p.nohit = opts.get("nohit", false)
	p.spr = _make_sprite("fx:" + kind, b.proj_layer)
	p.spr.position = pos
	var sc: float = opts.get("scale", 1.0)
	p.spr.scale *= sc
	if p.face_vel:
		p.spr.rotation = vel.angle()
	shots.append(p)
	return p


## Lahvička letí obloukem na cíl a vytvoří louži.
func lob_shot(kind: String, from: Vector2, to: Vector2, dur: float, zone_r: float, zone_dmg: float, zone_dur: float, tags: Array) -> void:
	var p := Proj.new()
	p.kind = kind
	p.lob = true
	p.start = from
	p.target = to
	p.pos = from
	p.dur = dur
	p.life = dur + 0.1
	p.zone_r = zone_r
	p.zone_dmg = zone_dmg
	p.zone_dur = zone_dur
	p.tags = tags
	p.spin = 8.0
	p.spr = _make_sprite("fx:" + kind, b.proj_layer)
	p.spr.position = from
	shots.append(p)


func enemy_shot(kind: String, pos: Vector2, vel: Vector2, dmg: float) -> void:
	var p := Proj.new()
	p.kind = kind
	p.pos = pos
	p.vel = vel
	p.dmg = dmg
	p.hostile = true
	p.r = 10.0
	p.life = 4.5
	p.spr = _make_sprite("fx:" + kind, b.proj_layer)
	p.spr.position = pos
	p.spr.rotation = vel.angle()
	p.spr.scale *= 1.25
	enemy_shots.append(p)


func add_zone(pos: Vector2, r: float, dmg: float, dur: float, hostile: bool, tags: Array = [], col: Color = Color.WHITE) -> void:
	var z := Zone.new()
	z.pos = pos
	z.r = r
	z.dmg = dmg
	z.life = dur
	z.max_life = dur
	z.hostile = hostile
	z.tags = tags
	z.tick = 0.5 if hostile else 0.4
	z.spr = Baker.sprite("fx:puddle")
	z.spr.position = pos
	z.spr.scale *= r / 60.0
	if hostile:
		z.spr.modulate = col
	b.ground_fx_layer.add_child(z.spr)
	zones.append(z)


func update(delta: float) -> void:
	_update_player_shots(delta)
	_update_enemy_shots(delta)
	_update_zones(delta)


func _update_player_shots(delta: float) -> void:
	var view: Rect2 = b.view_rect().grow(300.0)
	var drift: Vector2 = b.hazards.shot_drift() if b.hazards else Vector2.ZERO
	for p: Proj in shots.duplicate():
		if not shots.has(p):
			continue
		p.life -= delta
		if p.lob:
			p.t += delta
			var k := clampf(p.t / p.dur, 0.0, 1.0)
			p.pos = p.start.lerp(p.target, k) + Vector2(0, -sin(k * PI) * 120.0)
			p.spr.rotation += p.spin * delta
			p.spr.position = p.pos
			if k >= 1.0:
				add_zone(p.target, p.zone_r, p.zone_dmg, p.zone_dur, false, p.tags)
				Sfx.play("hit", -10.0)
				_free(p, shots)
			continue
		p.vel.y += p.grav * delta
		p.pos += (p.vel + (Vector2.ZERO if p.nohit else drift)) * delta
		p.spr.position = p.pos
		if p.spin != 0.0:
			p.spr.rotation += p.spin * delta
		elif p.face_vel:
			p.spr.rotation = p.vel.angle()
		var ended := p.life <= 0.0 or not view.has_point(p.pos)
		if p.nohit:
			ended = p.life <= 0.0
		elif not ended:
			for e in b.enemies.query(p.pos, p.r):
				if p.hits.has(e):
					continue
				p.hits[e] = true
				if p.explode_r > 0.0:
					ended = true
					break
				b.damage_enemy(e, p.dmg, p.tags, p.vel.normalized(), p.knock)
				if p.burn > 0.0:
					b.apply_burn(e, p.burn)
				p.pierce -= 1
				if p.pierce < 0:
					ended = true
					break
		if ended:
			if p.explode_r > 0.0 and p.life > -0.5:
				b.explode_at(p.pos, p.explode_r, p.dmg, p.tags, p.burn)
			_free(p, shots)


func _update_enemy_shots(delta: float) -> void:
	var pp: Vector2 = b.player.position
	var drift: Vector2 = b.hazards.shot_drift() if b.hazards else Vector2.ZERO
	for p: Proj in enemy_shots.duplicate():
		if not enemy_shots.has(p):
			continue
		p.life -= delta
		p.pos += (p.vel + drift) * delta
		p.spr.position = p.pos
		p.spr.rotation += delta * 4.0 if p.kind in ["hvezda", "jiskra", "syr", "uhel", "hrnicek", "srdce"] else 0.0
		if p.pos.distance_squared_to(pp) < pow(p.r + b.player.r * 0.8, 2):
			b.hit_player(p.dmg, p.pos)
			_free(p, enemy_shots)
			continue
		if p.life <= 0.0:
			_free(p, enemy_shots)


func _update_zones(delta: float) -> void:
	# kopie pole: smrt bosse během zásahu může zóny smazat
	for z: Zone in zones.duplicate():
		if not zones.has(z):
			continue
		z.life -= delta
		var a := clampf(z.life / 0.4, 0.0, 1.0) * clampf((z.max_life - z.life) / 0.2, 0.0, 1.0)
		z.spr.modulate.a = a * (0.85 if z.hostile else 0.75)
		z.tick_t -= delta
		if z.tick_t <= 0.0:
			z.tick_t = z.tick
			if z.hostile:
				if z.pos.distance_to(b.player.position) < z.r * 0.85:
					b.hit_player(z.dmg, z.pos, true)
			else:
				for e in b.enemies.query(z.pos, z.r * 0.9):
					b.damage_enemy(e, z.dmg, z.tags, Vector2.ZERO, 0.0)
					b.apply_poison(e, z.dmg * 0.6)
		if z.life <= 0.0:
			z.spr.queue_free()
			zones.erase(z)


func _free(p: Proj, arr: Array) -> void:
	if is_instance_valid(p.spr):
		p.spr.queue_free()
	arr.erase(p)


func clear_hostile() -> void:
	for p in enemy_shots.duplicate():
		_free(p, enemy_shots)
	for z in zones.duplicate():
		if z.hostile:
			z.spr.queue_free()
			zones.erase(z)
