extends Node
class_name WeaponSystem
## Zbraně hráče a pasivní předměty. Každá zbraň střílí sama podle své prodlevy.

var b: Battle
var weapons: Array = []      # [{id, level, t, st, angle, sprites}]
var passives := {}           # id -> {level, value}


func init(battle: Battle) -> void:
	b = battle


# ---------------------------------------------------------------- správa

func has_weapon(id: String) -> bool:
	return get_weapon(id) != null


func get_weapon(id: String):
	for w in weapons:
		if w.id == id:
			return w
	return null


func add_weapon(id: String) -> void:
	var w := {"id": id, "level": 1, "t": 0.3, "st": Upgrades.weapon_stats(id, 1), "angle": 0.0, "sprites": []}
	weapons.append(w)
	_rebuild_visuals(w)


func level_weapon(id: String) -> void:
	var w = get_weapon(id)
	if w == null:
		add_weapon(id)
		return
	w.level = mini(w.level + 1, Upgrades.WEAPON_MAX_LEVEL)
	w.st = Upgrades.weapon_stats(id, w.level)
	_rebuild_visuals(w)


func evolve(evo_id: String) -> void:
	var from: String = Upgrades.EVOLUTIONS[evo_id].from
	var w = get_weapon(from)
	if w == null:
		return
	for s in w.sprites:
		s.queue_free()
	w.sprites = []
	w.id = evo_id
	w.level = Upgrades.WEAPON_MAX_LEVEL
	w.st = Upgrades.weapon_stats(evo_id, 1)
	_rebuild_visuals(w)


func passive_level(id: String) -> int:
	return passives[id].level if passives.has(id) else 0


func add_passive(id: String, rarity: int) -> void:
	var p: Dictionary = Upgrades.PASSIVES[id]
	var mult: float = 1.0 if p.get("no_rarity", false) else Upgrades.RARITY_MULT[rarity]
	if not passives.has(id):
		passives[id] = {"level": 0, "value": 0.0}
	passives[id].level += 1
	passives[id].value += p.per * mult
	b.recalc_stats()
	for w in weapons:
		_rebuild_visuals(w)


func passive_value(stat: String) -> float:
	var v := 0.0
	for id in passives.keys():
		if Upgrades.PASSIVES[id].stat == stat:
			v += passives[id].value
	return v


func tags_owned() -> Array:
	var tags := []
	for w in weapons:
		for t in Upgrades.weapon_def(w.id).tags:
			if not t in tags:
				tags.append(t)
	return tags


func _rebuild_visuals(w: Dictionary) -> void:
	for s in w.sprites:
		if is_instance_valid(s):
			s.queue_free()
	w.sprites = []
	match w.id:
		"aura", "mraz":
			var s := Baker.sprite("fx:frost")
			s.modulate = Color(1, 1, 1, 0.9) if w.id == "aura" else Color(0.7, 0.85, 1.2, 1.0)
			b.ground_fx_layer.add_child(s)
			w.sprites.append(s)
		"stity", "hradba":
			var n := int(w.st.amount) + int(b.stats.amount)
			for i in n:
				var s := Baker.sprite("fx:shield" if w.id == "stity" else "fx:wagon")
				s.scale *= 0.9 if w.id == "stity" else 0.75
				b.proj_layer.add_child(s)
				w.sprites.append(s)


# ---------------------------------------------------------------- střelba

func update(delta: float) -> void:
	for w in weapons:
		var st: Dictionary = w.st
		match w.id:
			"stity", "hradba":
				_orbit(w, delta)
				continue
			"aura", "mraz":
				_aura_visual(w, delta)
		w.t -= delta
		if w.t > 0.0:
			continue
		w.t = st.cd * b.stats.cd
		match w.id:
			"mec", "bruncvik": _slash(w)
			"sekera": _axes(w)
			"vir": _axe_whirl(w)
			"kuse", "pistala": _crossbow(w)
			"ohen": _fireball(w)
			"peklo": _meteors(w)
			"blesk", "perun": _lightning(w)
			"aura", "mraz": _aura_tick(w)
			"jed", "bazina": _poison(w)


func _amount(st: Dictionary) -> int:
	return int(st.get("amount", 1)) + int(b.stats.amount)


func _area(st: Dictionary) -> float:
	return float(st.get("area", 1.0)) * b.stats.area


func _tags(w: Dictionary) -> Array:
	return Upgrades.weapon_def(w.id).tags


func _slash(w: Dictionary) -> void:
	var st: Dictionary = w.st
	var n := int(st.amount)
	if w.id == "bruncvik":
		n += 2
	var radius := 135.0 * _area(st)
	# meč míří sám na nejbližšího nepřítele (hráč často couvá před hordou)
	var base_dir: Vector2 = b.player.face_dir
	var target: Enemy = b.nearest_enemy(b.player.position, radius * 1.6)
	if target:
		base_dir = (target.position - b.player.position).normalized()
	var gold: bool = w.id == "bruncvik"
	for k in n:
		var dir := base_dir.rotated(TAU * k / n)
		var spr := Baker.sprite("fx:slash_gold" if gold else "fx:slash")
		spr.rotation = dir.angle()
		spr.scale *= radius / 112.0
		spr.position = Vector2(0, -8)
		b.player.add_child(spr)
		spr.z_index = 3
		var tw := spr.create_tween()
		tw.tween_property(spr, "modulate:a", 0.0, 0.25).set_delay(0.05)
		tw.parallel().tween_property(spr, "rotation", spr.rotation + 0.35, 0.25)
		tw.tween_callback(spr.queue_free)
		for e in b.enemies.query(b.player.position, radius):
			var to: Vector2 = e.position - b.player.position
			if to.length() < 20.0 or absf(dir.angle_to(to)) < 1.25:
				b.damage_enemy(e, st.dmg, _tags(w), to.normalized(), st.knock)
	Sfx.play("slash", -6.0)


func _axes(w: Dictionary) -> void:
	var st: Dictionary = w.st
	var n := _amount(st)
	var a := _area(st)
	for k in n:
		var vx := randf_range(-170.0, 170.0) + b.player.face_dir.x * 90.0
		b.projectiles.player_shot("axe", b.player.position + Vector2(0, -10), Vector2(vx, -640.0 - k * 40.0), st.dmg, _tags(w),
			{"pierce": 99, "r": 18.0 * a, "life": 2.2, "spin": 14.0 * signf(vx + 0.01), "grav": 1350.0, "scale": 1.3 * a, "knock": 90.0, "face_vel": false})
	Sfx.play("shoot", -10.0)


func _axe_whirl(w: Dictionary) -> void:
	var st: Dictionary = w.st
	var n := _amount(st)
	var a := _area(st)
	var off := randf() * TAU
	for k in n:
		var dir := Vector2.RIGHT.rotated(off + TAU * k / n)
		b.projectiles.player_shot("axe", b.player.position, dir * 430.0, st.dmg, _tags(w),
			{"pierce": 99, "r": 20.0 * a, "life": 1.3, "spin": 16.0, "scale": 1.5 * a, "knock": 140.0, "face_vel": false})
	Sfx.play("shoot", -8.0)


func _crossbow(w: Dictionary) -> void:
	var st: Dictionary = w.st
	var n := _amount(st)
	var used := []
	var pist: bool = w.id == "pistala"
	for k in n:
		var target: Enemy = b.nearest_enemy(b.player.position, 750.0, used)
		var dir: Vector2 = b.player.face_dir
		if target:
			used.append(target)
			dir = (target.position - b.player.position).normalized()
		dir = dir.rotated(randf_range(-0.05, 0.05))
		var opts := {"pierce": int(st.pierce), "r": 12.0, "life": 1.4}
		if pist:
			opts["explode_r"] = 46.0 * _area(st)
			opts["scale"] = 1.3
		b.projectiles.player_shot("bullet" if pist else "bolt", b.player.position + Vector2(0, -8), dir * st.speed, st.dmg, _tags(w), opts)
	Sfx.play("shoot", -9.0)


func _fireball(w: Dictionary) -> void:
	var st: Dictionary = w.st
	var n := _amount(st)
	for k in n:
		var target: Enemy = b.random_visible_enemy()
		var dir: Vector2 = b.player.face_dir.rotated(randf_range(-0.5, 0.5))
		if target:
			dir = (target.position - b.player.position).normalized()
		b.projectiles.player_shot("fireball", b.player.position, dir * st.speed, st.dmg, _tags(w),
			{"r": 14.0, "life": 2.2, "explode_r": 62.0 * _area(st), "burn": st.burn, "scale": 1.3})
	Sfx.play("shoot", -8.0)


func _meteors(w: Dictionary) -> void:
	var st: Dictionary = w.st
	var n := _amount(st)
	for k in n:
		var target: Enemy = b.random_visible_enemy()
		var to: Vector2 = target.position if target else b.player.position + Vector2(randf_range(-300, 300), randf_range(-200, 200))
		var from := to + Vector2(-260, -520)
		var t := 0.55 + k * 0.08
		b.projectiles.player_shot("meteor", from, (to - from) / t, st.dmg, _tags(w),
			{"nohit": true, "life": t, "explode_r": 70.0 * _area(st), "burn": st.burn, "scale": 1.1})
		b.ground_fx.circle_warn(to, 70.0 * _area(st), t, Color(1, 0.5, 0.1, 0.6))


func _lightning(w: Dictionary) -> void:
	var st: Dictionary = w.st
	var n := _amount(st)
	var hit_all := []
	for k in n:
		var first: Enemy = b.random_visible_enemy()
		if first == null:
			return
		var chain := [first]
		var cur: Enemy = first
		var hops := int(st.chain) + int(b.weapons.passive_value("tag_blesk") > 0.0)
		for h in hops:
			var nx: Enemy = b.nearest_enemy(cur.position, 190.0, chain + hit_all)
			if nx == null:
				break
			chain.append(nx)
			cur = nx
		var pts := [first.position + Vector2(randf_range(-60, 60), -700)]
		for e in chain:
			pts.append(e.position)
			b.damage_enemy(e, st.dmg, _tags(w), Vector2.ZERO, 40.0)
		hit_all.append_array(chain)
		b.fx.lightning(pts, w.id == "perun")
	Sfx.play("zap", -6.0)


func _aura_visual(w: Dictionary, delta: float) -> void:
	var radius := 85.0 * _area(w.st)
	if w.id == "mraz":
		radius *= 1.0
	var s: Sprite2D = w.sprites[0]
	s.position = b.player.position
	s.scale = Vector2.ONE * (radius / 100.0) / Baker.SCALE
	s.rotation += delta * 0.6


func _aura_tick(w: Dictionary) -> void:
	var st: Dictionary = w.st
	var radius := 85.0 * _area(st)
	var slow: float = st.slow + b.weapons.passive_value("tag_led") * 0.3
	for e in b.enemies.query(b.player.position, radius):
		b.damage_enemy(e, st.dmg, _tags(w), Vector2.ZERO, 0.0, true, true)
		e.slow_f = minf(0.85, maxf(e.slow_f if e.slow_t > 0 else 0.0, slow))
		e.slow_t = 0.7


func _orbit(w: Dictionary, delta: float) -> void:
	var st: Dictionary = w.st
	var n: int = w.sprites.size()
	if n == 0:
		return
	var radius := 85.0 * _area(st)
	w.angle += st.speed * delta
	var hit_r := 22.0 if w.id == "stity" else 36.0
	var now := b.elapsed
	for i in n:
		var a: float = w.angle + TAU * i / n
		var pos: Vector2 = b.player.position + Vector2(cos(a), sin(a)) * radius
		var s: Sprite2D = w.sprites[i]
		s.position = pos
		if w.id == "stity":
			s.rotation = a * 2.0
		else:
			s.rotation = a + PI * 0.5
		for e in b.enemies.query(pos, hit_r):
			var key: String = w.id
			if e.hit_cd.get(key, -1.0) > now:
				continue
			e.hit_cd[key] = now + st.cd
			b.damage_enemy(e, st.dmg, _tags(w), (e.position - b.player.position).normalized(), 260.0)


func _poison(w: Dictionary) -> void:
	var st: Dictionary = w.st
	var n := _amount(st)
	var r := 55.0 * _area(st)
	for k in n:
		var target: Enemy = b.random_visible_enemy()
		var to: Vector2 = b.player.position + Vector2(randf_range(-260, 260), randf_range(-180, 180))
		if target:
			to = target.position
		if w.id == "bazina":
			to = b.player.position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(60, 240)
		b.projectiles.lob_shot("flask", b.player.position + Vector2(0, -20), to, 0.55, r, st.dmg, st.dur, _tags(w))
	Sfx.play("shoot", -12.0)


func clear() -> void:
	for w in weapons:
		for s in w.sprites:
			if is_instance_valid(s):
				s.queue_free()
		w.sprites = []
