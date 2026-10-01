extends Node
class_name EnemyManager
## Správa všech nepřátel: pohyb podle archetypu, vzájemné odpuzování přes
## prostorovou mřížku, stavové efekty, kontaktní poškození a smrt.

const CELL := 80.0
const CAP := 230
const FAR := 1150.0

var b: Battle
var list: Array[Enemy] = []
var grid := {}
var shadow_tex: Texture2D


func init(battle: Battle) -> void:
	b = battle
	shadow_tex = Baker.tex("shadow")


func count() -> int:
	return list.size()


func spawn(id: String, pos: Vector2, opts: Dictionary = {}) -> Enemy:
	if list.size() >= CAP and not opts.get("force", false):
		return null
	var d := EnemyDefs.get_enemy(id)
	var e := Enemy.new()
	e.setup(d, Baker.tex("e:%s:0" % id), Baker.tex("e:%s:1" % id))
	e.max_hp = d.hp * b.enemy_hp_mult()
	e.spd = d.spd * randf_range(0.9, 1.1) * b.enemy_speed_mult()
	e.dmg = d.dmg * b.enemy_dmg_mult()
	var vs := 1.0
	if opts.get("mini", false):
		e.mini = true
		e.max_hp *= 0.3
		e.r *= 0.62
		e.spd *= 1.25
		e.xp = 1
		vs = 0.6
	if opts.get("elite", false):
		e.elite = true
		e.max_hp *= 7.0 + b.tier * 0.5
		e.r *= 1.45
		e.dmg *= 1.4
		e.xp *= 12
		e.knock_res = 0.92
		vs *= 1.5
	e.hp = e.max_hp
	e.position = pos
	e.cd = randf_range(1.0, 2.5)
	b.entity_layer.add_child(e)
	if e.elite:
		e.glow = Baker.sprite("elite_glow")
		e.glow.scale *= vs * 0.9
		e.glow.show_behind_parent = true
		e.add_child(e.glow)
	e.set_visual_scale(vs)
	e.shadow = Sprite2D.new()
	e.shadow.texture = shadow_tex
	e.shadow.scale = Vector2(e.r / 20.0, e.r / 20.0)
	b.shadow_layer.add_child(e.shadow)
	list.append(e)
	return e


func update(delta: float) -> void:
	_build_grid()
	var pp: Vector2 = b.player.position
	var pdir: Vector2 = b.player.move_dir
	var i := list.size() - 1
	while i >= 0:
		var e: Enemy = list[i]
		i -= 1
		if not e.alive:
			continue
		if e.is_boss:
			continue
		_statuses(e, delta)
		if not e.alive:
			continue
		var to_p := pp - e.position
		var dist := to_p.length()
		var dir := to_p / maxf(dist, 0.001)
		var want := Vector2.ZERO
		var moving := true
		e.timer -= delta
		e.cd -= delta
		match e.state:
			Enemy.St.FLEE:
				want = -dir * e.spd * 2.0
				e.modulate.a = clampf(e.timer / 1.2, 0.0, 1.0)
				if e.timer <= 0.0:
					remove(e)
					continue
			Enemy.St.WINDUP:
				moving = false
				if e.timer <= 0.0:
					if e.beh == "charger":
						e.state = Enemy.St.DASH
						e.timer = 0.65
					else:
						_shoot(e, dir)
						e.state = Enemy.St.MOVE
						e.cd = randf_range(2.3, 3.2)
			Enemy.St.DASH:
				want = e.aux * 470.0
				if e.timer <= 0.0:
					e.state = Enemy.St.REST
					e.timer = 0.5
			Enemy.St.REST:
				moving = false
				if e.timer <= 0.0:
					e.state = Enemy.St.MOVE
					e.cd = randf_range(2.0, 3.0)
			Enemy.St.FUSE:
				want = dir * e.speed_now() * 0.3
				if e.timer <= 0.0:
					_explode(e)
					continue
			_:
				want = _move_behavior(e, dir, dist, delta)
		e.vel = want
		e.position += (e.vel + e.knock) * delta
		e.knock = e.knock.move_toward(Vector2.ZERO, delta * 900.0)
		# vzájemné odpuzování
		_separate(e)
		if b.arena_radius > 0.0:
			e.position = b.clamp_to_arena(e.position, e.r)
		# kontakt s hráčem
		if dist < e.r + b.player.r and e.state != Enemy.St.FLEE:
			b.hit_player(e.dmg, e.position)
		# nepřítel daleko mimo obrazovku se přesune před hráče
		if dist > FAR and e.state == Enemy.St.MOVE and b.arena_radius <= 0.0:
			var fwd := pdir if pdir.length() > 0.1 else -dir
			e.position = pp + fwd.rotated(randf_range(-0.8, 0.8)) * randf_range(700.0, 820.0)
		if absf(to_p.x) > 4.0:
			e.face = 1.0 if to_p.x > 0.0 else -1.0
		e.animate(delta, moving)
		e.shadow.position = e.position + Vector2(0, e.r * 1.25)


func _move_behavior(e: Enemy, dir: Vector2, dist: float, delta: float) -> Vector2:
	var s := e.speed_now()
	match e.beh:
		"runner":
			var wig := dir.orthogonal() * sin(e.anim_t * 1.3) * 0.35
			return (dir + wig).normalized() * s
		"shooter":
			if e.cd <= 0.0 and dist < 460.0:
				e.state = Enemy.St.WINDUP
				e.timer = 0.4
				return Vector2.ZERO
			if dist > 290.0:
				return dir * s
			if dist < 210.0:
				return -dir * s * 0.8
			return dir.orthogonal() * s * 0.6
		"charger":
			if e.cd <= 0.0 and dist < 330.0:
				e.state = Enemy.St.WINDUP
				e.timer = 0.7
				e.aux = dir
				b.ground_fx.line_warn(e.position, dir, 330.0, e.r * 1.6, 0.7)
				return Vector2.ZERO
			return dir * s
		"kamikaze":
			if dist < e.r + b.player.r + 30.0:
				e.state = Enemy.St.FUSE
				e.timer = 0.6
				b.ground_fx.circle_warn(e.position, 78.0, 0.6, Color(1, 0.4, 0.1))
			return dir * s
	return dir * s


func _statuses(e: Enemy, delta: float) -> void:
	if e.slow_t > 0.0:
		e.slow_t -= delta
	var dot := 0.0
	if e.burn_t > 0.0:
		e.burn_t -= delta
		dot += e.burn_dps
	if e.poison_t > 0.0:
		e.poison_t -= delta
		dot += e.poison_dps
		if e.poison_t <= 0.0:
			e.poison_dps = 0.0
	if dot > 0.0:
		e.hp -= dot * delta
		if e.hp <= 0.0:
			kill(e)


func _separate(e: Enemy) -> void:
	var cx := floori(e.position.x / CELL)
	var cy := floori(e.position.y / CELL)
	for gx in range(cx - 1, cx + 2):
		for gy in range(cy - 1, cy + 2):
			var cell = grid.get(_key(gx, gy))
			if cell == null:
				continue
			for o in cell:
				if o == e or not is_instance_valid(o) or not o.alive:
					continue
				var d: Vector2 = e.position - o.position
				var min_d: float = (e.r + o.r) * 0.85
				var l2 := d.length_squared()
				if l2 < min_d * min_d and l2 > 0.0001:
					var l := sqrt(l2)
					var push := (min_d - l) * 0.5
					if o.is_boss:
						push *= 2.0
					e.position += d / l * push


func _key(gx: int, gy: int) -> int:
	return (gx + 32768) * 65536 + (gy + 32768)


func _build_grid() -> void:
	grid.clear()
	for e in list:
		if not e.alive:
			continue
		var k := _key(floori(e.position.x / CELL), floori(e.position.y / CELL))
		var cell = grid.get(k)
		if cell == null:
			grid[k] = [e]
		else:
			cell.append(e)


## Nepřátelé v kruhu (pro zbraně a výbuchy).
func query(pos: Vector2, radius: float) -> Array:
	var out := []
	var c0x := floori((pos.x - radius - 60.0) / CELL)
	var c1x := floori((pos.x + radius + 60.0) / CELL)
	var c0y := floori((pos.y - radius - 60.0) / CELL)
	var c1y := floori((pos.y + radius + 60.0) / CELL)
	for gx in range(c0x, c1x + 1):
		for gy in range(c0y, c1y + 1):
			var cell = grid.get(_key(gx, gy))
			if cell == null:
				continue
			for e in cell:
				if is_instance_valid(e) and e.alive:
					var rr: float = radius + e.r
					if e.position.distance_squared_to(pos) <= rr * rr:
						out.append(e)
	if b.boss and b.boss.alive and not out.has(b.boss):
		var rr2 := radius + b.boss.r
		if b.boss.position.distance_squared_to(pos) <= rr2 * rr2:
			out.append(b.boss)
	return out


func nearest(pos: Vector2, max_d: float = 900.0, exclude: Array = []) -> Enemy:
	var best: Enemy = null
	var bd := max_d * max_d
	for e in list:
		if not e.alive or e.state == Enemy.St.FLEE or exclude.has(e):
			continue
		var d := e.position.distance_squared_to(pos)
		if d < bd:
			bd = d
			best = e
	return best


func random_visible() -> Enemy:
	var vis := []
	var rect: Rect2 = b.view_rect()
	for e in list:
		if e.alive and e.state != Enemy.St.FLEE and rect.has_point(e.position):
			vis.append(e)
	if vis.is_empty():
		return null
	return vis[randi() % vis.size()]


func visible() -> Array:
	var vis := []
	var rect: Rect2 = b.view_rect()
	for e in list:
		if e.alive and e.state != Enemy.St.FLEE and rect.has_point(e.position):
			vis.append(e)
	return vis


func _shoot(e: Enemy, dir: Vector2) -> void:
	var kind: String = e.def.get("proj", "kapka")
	b.projectiles.enemy_shot(kind, e.position, dir * 235.0, e.dmg * 0.9)
	Sfx.play("enemy_shot", -8.0)


func _explode(e: Enemy) -> void:
	var r := 78.0
	if e.position.distance_to(b.player.position) < r + b.player.r * 0.5:
		b.hit_player(e.dmg, e.position, true)
	b.fx.explosion(e.position, r, Color("ff8a2a"))
	Sfx.play("boom", -4.0)
	b.shake(6.0)
	for o in query(e.position, r):
		if o != e and o is Enemy and not o.is_boss:
			b.damage_enemy(o, e.max_hp * 2.0, [], (o.position - e.position).normalized(), 200.0, false)
	remove(e)


func kill(e: Enemy, drops: bool = true) -> void:
	if not e.alive:
		return
	e.alive = false
	b.on_enemy_killed(e, drops)
	if e.beh == "splitter" and not e.mini:
		for k in 3:
			var a := TAU * k / 3.0 + randf()
			var m := spawn(e.id, e.position + Vector2(cos(a), sin(a)) * 18.0, {"mini": true, "force": true})
			if m:
				m.knock = Vector2(cos(a), sin(a)) * 220.0
	remove(e)


func remove(e: Enemy) -> void:
	e.alive = false
	list.erase(e)
	if is_instance_valid(e.shadow):
		e.shadow.queue_free()
	e.queue_free()


func flee_all() -> void:
	for e in list:
		if e.alive and not e.is_boss:
			e.state = Enemy.St.FLEE
			e.timer = 1.2


func clear_all() -> void:
	for e in list.duplicate():
		remove(e)
