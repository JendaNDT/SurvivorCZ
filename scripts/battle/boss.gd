extends Enemy
class_name Boss
## Boss kraje: tři fáze, útoky ohlášené na zemi předem (červené kruhy a čáry).
## Z Bosse dědí i náčelník (MiniBoss), takže útoky (_slam, _rain, …) jsou společné.
## Útoky jsou korutiny na instanci: když se uzel uvolní, Godot je už neprobudí
## a nesáhnou na smazaný objekt (sdílené statické funkce by to hlídat nemohly).

var b: Battle
var bdef: Dictionary
var phase := 0
var attack_t := 2.5
var busy := false
var last_attack := ""
var charge_vel := Vector2.ZERO
var charge_t := 0.0
var intro_t := 1.2
var intro_len := 1.2
## Prodleva mezi útoky v první fázi.
var attack_gap := 2.6
var phase_names := ["", "Fáze 2!", "Poslední fáze!"]


func init_boss(battle: Battle, boss_id: String, hp_total: float) -> void:
	b = battle
	is_boss = true
	bdef = EnemyDefs.BOSSES[boss_id]
	var d := {"id": boss_id, "beh": "boss", "r": 58.0, "xp": 0, "name": bdef.name}
	setup(d, Baker.tex("b:%s:0" % boss_id), Baker.tex("b:%s:1" % boss_id))
	max_hp = hp_total
	hp = hp_total
	spd = 70.0 * b.enemy_speed_mult()
	dmg = 15.0 * b.boss_dmg_mult()
	knock_res = 1.0
	set_visual_scale(0.8)
	shadow = Sprite2D.new()
	shadow.texture = Baker.tex("shadow")
	shadow.scale = Vector2(3.4, 3.0)
	b.shadow_layer.add_child(shadow)


func boss_update(delta: float) -> void:
	if not alive:
		return
	var pp: Vector2 = b.player.position
	var to_p := pp - position
	var dist := to_p.length()
	if intro_t > 0.0:
		intro_t -= delta
		var k := clampf(1.0 - intro_t / intro_len, 0.0, 1.0)
		body.position.y = -400.0 * pow(1.0 - k, 2)
		shadow.position = position + Vector2(0, r * 1.15)
		if intro_t <= 0.0:
			_landed()
		return
	# statusy (zpomalení, hoření)
	if slow_t > 0.0:
		slow_t -= delta
	if burn_t > 0.0:
		burn_t -= delta
		hp -= burn_dps * delta
	if poison_t > 0.0:
		poison_t -= delta
		hp -= poison_dps * delta
	if hp <= 0.0:
		die()
		return
	_check_phase()
	# pohyb
	if charge_t > 0.0:
		charge_t -= delta
		position += charge_vel * delta
		if charge_t <= 0.0:
			busy = false
	elif not busy:
		if dist > 150.0:
			position += to_p / dist * _move_speed(dist) * delta
		attack_t -= delta
		if attack_t <= 0.0:
			_start_attack()
	_after_move(delta)
	position = b.clamp_to_arena(position, r)
	if dist < r + b.player.r:
		b.hit_player(dmg, position)
	if absf(to_p.x) > 6.0:
		face = 1.0 if to_p.x > 0.0 else -1.0
	animate(delta, not busy)
	shadow.position = position + Vector2(0, r * 1.15)


## Dopad po příchodu shora.
func _landed() -> void:
	b.shake(18.0)
	Sfx.play("boom")
	b.fx.explosion(position + Vector2(0, 40), 140.0, Color("c9a06a"))
	var wv := b.ground_fx.shockwave(position, 520.0, 380.0, 26.0, Color(1, 0.8, 0.5))
	_track_wave(wv, 14.0)


func die() -> void:
	b.boss_killed()


## Fáze podle zbývajících životů.
func _check_phase() -> void:
	var want_phase := 0 if hp > max_hp * 0.66 else (1 if hp > max_hp * 0.33 else 2)
	if want_phase > phase:
		phase = want_phase
		b.banner(phase_names[phase], Color("ff5a48"))
		Sfx.play("boss", -2.0)
		b.shake(10.0)
		var wv := b.ground_fx.shockwave(position, 600.0, 420.0, 22.0, Color(1, 0.4, 0.3))
		_track_wave(wv, 10.0)
		attack_t = 1.0


func _move_speed(_dist: float) -> float:
	return speed_now() * (1.0 + phase * 0.15)


func _after_move(_delta: float) -> void:
	pass


## Násobek poškození útoků.
func power() -> float:
	return b.boss_dmg_mult()


func _attacks() -> Array:
	var list := []
	for i in phase + 1:
		list.append_array(bdef.phases[i])
	return list


func _start_attack() -> void:
	var list := _attacks()
	var pick: String = list[randi() % list.size()]
	if pick == last_attack and list.size() > 1:
		pick = list[(list.find(pick) + 1) % list.size()]
	last_attack = pick
	attack_t = maxf(1.2, attack_gap - phase * 0.5)
	busy = true
	match pick:
		"slam": await _slam()
		"rain": await _rain()
		"radial": await _radial()
		"spiral": await _spiral()
		"charge": await _charge()
		"charge2": await _charge2()
		"summon": await _summon()
		"puddle": await _puddle()
		"shockwave": await _shockwave()
	# výpad uvolní bosse sám, až doběhne (charge_t v boss_update)
	if pick != "charge" and pick != "charge2":
		busy = false


func _wait(t: float) -> Signal:
	return get_tree().create_timer(t, false).timeout


func _proj_color() -> Color:
	return Color(bdef.puddle)


func _slam() -> void:
	var n := 1 + phase
	for i in n:
		if not alive:
			return
		var target: Vector2 = b.player.position + b.player.move_dir * 60.0
		var cb := func(pos: Vector2, rr: float) -> void:
			if b.player.position.distance_to(pos) < rr + b.player.r * 0.5:
				b.hit_player(22.0 * power(), pos, true)
			b.fx.explosion(pos, rr, Color("c9a06a"))
			b.shake(9.0)
			Sfx.play("boom", -4.0)
		b.ground_fx.circle_warn(target, 110.0, 1.0, Color(1, 0.15, 0.1), cb)
		await _wait(0.55)


func _rain() -> void:
	var n := 7 + phase * 3
	for i in n:
		if not alive:
			return
		var p: Vector2 = b.player.position + Vector2(randf_range(-240, 240), randf_range(-200, 200))
		if i % 3 == 0:
			p = b.player.position
		p = b.clamp_to_arena(p, 10.0)
		var cb := func(pos: Vector2, rr: float) -> void:
			if b.player.position.distance_to(pos) < rr + b.player.r * 0.4:
				b.hit_player(14.0 * power(), pos, true)
			b.fx.explosion(pos, rr, _proj_color())
			Sfx.play("hit", -6.0)
		b.ground_fx.circle_warn(p, 62.0, 0.95, _proj_color().lerp(Color(1, 0.2, 0.1), 0.5), cb)
		await _wait(0.14)


func _radial() -> void:
	var rings := 1 + (1 if phase >= 1 else 0)
	for k in rings:
		if not alive:
			return
		var n := 14 + phase * 4
		var off := randf() * TAU
		for i in n:
			var a := off + TAU * i / n
			b.projectiles.enemy_shot(bdef.proj, position, Vector2(cos(a), sin(a)) * (210.0 + phase * 25.0), 9.0 * power())
		Sfx.play("enemy_shot", -2.0)
		await _wait(0.45)


func _spiral() -> void:
	var a := randf() * TAU
	var steps := 26 + phase * 6
	for i in steps:
		if not alive:
			return
		for k in 2 + int(phase >= 2):
			var aa := a + TAU * k / (2.0 + float(phase >= 2))
			b.projectiles.enemy_shot(bdef.proj, position, Vector2(cos(aa), sin(aa)) * 230.0, 8.0 * power())
		a += 0.33
		if i % 4 == 0:
			Sfx.play("enemy_shot", -10.0)
		await _wait(0.09)


func _charge() -> void:
	busy = true
	var dir: Vector2 = (b.player.position - position).normalized()
	b.ground_fx.line_warn(position, dir, 640.0, r * 1.8, 0.9)
	Sfx.play("warn", -6.0)
	state = Enemy.St.WINDUP
	timer = 0.9
	await _wait(0.9)
	state = Enemy.St.MOVE
	if not alive:
		busy = false
		return
	charge_vel = dir * 820.0
	charge_t = 0.78
	Sfx.play("dash")


## Dva výpady za sebou (druhý míří tam, kde hrdina je po prvním).
func _charge2() -> void:
	await _charge()
	while alive and charge_t > 0.0:
		await get_tree().process_frame
	if not alive:
		return
	await _charge()


func _summon() -> void:
	var n := 5 + phase * 2
	var id: String = bdef.summon
	for i in n:
		var a := TAU * i / n
		var pos := position + Vector2(cos(a), sin(a)) * 120.0
		pos = b.clamp_to_arena(pos, 20.0)
		if b.enemies.spawn(id, pos, {"force": true}):
			b.fx.poof(pos)
	Sfx.play("boss", -8.0)
	await _wait(0.6)


func _puddle() -> void:
	var n := 3 + phase
	for i in n:
		if not alive:
			return
		var p: Vector2 = b.player.position + Vector2(randf_range(-160, 160), randf_range(-120, 120))
		if i == 0:
			p = b.player.position
		p = b.clamp_to_arena(p, 40.0)
		var cb := func(pos: Vector2, rr: float) -> void:
			b.projectiles.add_zone(pos, rr, 5.0 * power(), 6.0, true, [], _proj_color())
		b.ground_fx.circle_warn(p, 70.0, 0.7, _proj_color(), cb)
		await _wait(0.25)


func _shockwave() -> void:
	state = Enemy.St.WINDUP
	timer = 0.7
	Sfx.play("warn", -6.0)
	await _wait(0.7)
	state = Enemy.St.MOVE
	if not alive:
		return
	b.shake(12.0)
	Sfx.play("boom", -2.0)
	var waves := 1 + int(phase >= 2)
	for k in waves:
		if not alive:
			return
		var wv := b.ground_fx.shockwave(position, 330.0, 760.0, 30.0, _proj_color())
		_track_wave(wv, 16.0)
		await _wait(0.8)


## Rázová vlna zraní hráče, když přes něj přejde (úskokem se dá přeskočit).
func _track_wave(wv: Dictionary, dmg_base: float) -> void:
	while is_instance_valid(self) and alive and b.ground_fx.waves.has(wv):
		var d: float = b.player.position.distance_to(wv.c)
		if not wv.hit and absf(d - wv.r) < wv.w * 0.5 + b.player.r * 0.6:
			wv.hit = true
			b.hit_player(dmg_base * power(), wv.c, true)
		await get_tree().process_frame
