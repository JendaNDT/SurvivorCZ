extends Node2D
class_name EventSystem
## Události v boji (M7). Režisér je pošle ve 30 % a 65 % času, 500–700 px od hrdiny
## (dvakrát po sobě ne stejnou). Když je hráč 40 s nechá být, zmizí. Uzel kreslí
## na zemi kruh dosahu a ukazatel postupu, kresba události stojí ve vrstvě postav.
## Data jsou ve scripts/data/events.gd, dialogy v BattleOverlay.

const LIFE := 40.0
const TOUCH := 70.0

var b: Battle
var list: Array = []
var last_id := ""


func init(battle: Battle) -> void:
	b = battle


static func bake_jobs() -> Array:
	var jobs := []
	for id in EventDefs.ORDER:
		for t in ([0.0, 1.0] if id in ["obelisk", "truhla"] else [0.0]):
			var key: String = "ev:%s%s" % [id, "" if t == 0.0 else "1"]
			jobs.append({"key": key, "size": EventArt.size_of(id), "fn": func(ci, tt): EventArt.draw(ci, id, tt), "t": t, "origin": EventArt.origin_of(id)})
	return jobs


# ---------------------------------------------------------------- vznik a zánik

func spawn_random() -> void:
	var ids: Array = EventDefs.ORDER.duplicate()
	ids.erase(last_id)
	spawn(ids[randi() % ids.size()])


func spawn(id: String, at: Variant = null) -> void:
	var def := EventDefs.get_for(id)
	var pos: Vector2
	if at is Vector2:
		pos = at
	else:
		pos = b.player.position + Vector2.from_angle(randf() * TAU) * randf_range(500.0, 700.0)
	last_id = id
	var spr := Baker.sprite("ev:" + id)
	spr.position = pos
	b.entity_layer.add_child(spr)
	var ev := {"id": id, "def": def, "pos": pos, "spr": spr, "life": LIFE, "engaged": false, "done": false,
		"inside": false, "progress": 0.0, "kills": 0, "elites": [], "killed": 0, "t": 0.0}
	list.append(ev)
	b.banner(str(def.name), Color(def.col), str(def.hint))
	Sfx.play("chest", -6.0)
	b.fx.poof(pos + Vector2(0, -30))
	Game.note("událost: " + id)


func _remove(ev: Dictionary, poof: bool = true) -> void:
	list.erase(ev)
	var spr: Sprite2D = ev.spr
	if is_instance_valid(spr):
		if poof:
			b.fx.poof(ev.pos + Vector2(0, -30))
			var tw := spr.create_tween()
			tw.tween_property(spr, "modulate:a", 0.0, 0.4)
			tw.tween_callback(spr.queue_free)
		else:
			spr.queue_free()


## Před bossem všechno zmizí.
func clear() -> void:
	for ev in list.duplicate():
		_remove(ev)


# ---------------------------------------------------------------- průběh

func update(delta: float) -> void:
	var pp: Vector2 = b.player.position
	for ev in list.duplicate():
		ev.t = float(ev.t) + delta
		if not ev.engaged:
			ev.life = float(ev.life) - delta
			if float(ev.life) <= 0.0:
				_log("%s zmizela" % ev.id)
				_remove(ev)
				continue
		var d := pp.distance_to(ev.pos)
		var r: float = ev.def.r
		match ev.id:
			"oltar", "kramar":
				if d < r:
					if not ev.inside:
						ev.inside = true
						_open_dialog(ev)
				else:
					ev.inside = false
			"muka":
				if d < r:
					ev.engaged = true
					ev.progress = float(ev.progress) + delta / float(ev.def.stand)
					if float(ev.progress) >= 1.0:
						ev.progress = 1.0
						_open_dialog(ev)
				else:
					ev.progress = maxf(0.0, float(ev.progress) - delta * 0.15)
			"obelisk":
				if d < r and not ev.engaged:
					_curse(ev)
	queue_redraw()


func _open_dialog(ev: Dictionary) -> void:
	if not b.event_pause():
		ev.inside = false
		return
	_log("%s: dialog" % ev.id)
	match ev.id:
		"oltar":
			b.overlay.show_altar(ev)
		"kramar":
			b.overlay.show_peddler(ev)
		"muka":
			b.overlay.show_blessing(ev)
	if b.autoplay:
		_auto(ev)


# ---------------------------------------------------------------- volby z dialogů

## Oltář: "hp" = 20 % max. životů za legendární kartu, "gold" = 50 zlata za epickou.
func altar(ev: Dictionary, choice: String) -> void:
	_log("oltář: " + choice)
	match choice:
		"hp":
			b.player.hp -= b.player.max_hp * float(ev.def.hp_cost)
			b.fx.number(b.player.position + Vector2(0, -50), b.player.max_hp * float(ev.def.hp_cost), false, Color("b25cff"))
			_consume(ev)
			Sfx.play("boss", -8.0)
			b.offer_cards(b.gen_cards(3, 2), "legend")
		"gold":
			b.gold_run -= int(ev.def.gold_cost)
			_consume(ev)
			Sfx.play("coin", -2.0)
			b.offer_cards(b.gen_min_rarity(2), "epic")
		_:
			# oltář zůstane, automat k němu už nechodí
			ev.declined = true
			b.event_resume()


## Boží muka: požehnání na `dur` sekund.
func bless(ev: Dictionary, id: String) -> void:
	_log("požehnání: " + id)
	b.add_buff(id, float(ev.def.dur))
	_consume(ev)
	b.fx.burst(b.player.position, Color("ffd23f"), 16, 280.0, 6.0)
	Sfx.play("levelup", -4.0)
	b.banner("Požehnání: " + str(EventDefs.BLESSINGS[id].name), Color("ffd23f"), str(EventDefs.BLESSINGS[id].desc) + " na %d s" % int(ev.def.dur))
	b.event_resume()


## Kramář: vrátí true, když se nákup povedl.
func buy(item: Dictionary) -> bool:
	var price: int = item.price
	if b.gold_run < price:
		return false
	_log("kramář: " + str(item.id))
	b.gold_run -= price
	Sfx.play("coin", -2.0)
	match str(item.id):
		"svickova":
			b.heal(b.player.max_hp * 0.5)
		"prehozeni":
			b.rerolls += 1
		"karta":
			var card_name := b.random_card(1)
			b.fx.text(b.player.position + Vector2(0, -70), card_name, Color("3fa8ff"), 22)
		"magnet":
			b.pickups.magnetize_all()
	return true


func leave_peddler(ev: Dictionary) -> void:
	_consume(ev)
	b.event_resume()


## Použitá událost zmizí (kramář odjede, oltář pohasne).
func _consume(ev: Dictionary) -> void:
	ev.done = true
	_remove(ev)


# ---------------------------------------------------------------- obelisk a truhla

func _curse(ev: Dictionary) -> void:
	_log("kletba")
	ev.engaged = true
	var spr: Sprite2D = ev.spr
	spr.texture = Baker.tex("ev:obelisk1")
	b.shake(10.0)
	Sfx.play("boss", -2.0)
	b.banner("Kletba!", Color("ff4d6d"), "Poraz tři elity a získáš legendární truhlu")
	var ids: Array = b.region.enemies
	var pp: Vector2 = b.player.position
	for i in int(ev.def.elites):
		var a := TAU * i / float(ev.def.elites) + randf() * 0.5
		var e := b.enemies.spawn(ids[randi() % ids.size()], pp + Vector2.from_angle(a) * 380.0, {"elite": true, "force": true})
		if e:
			e.set_meta("curse", true)
			(ev.elites as Array).append(e)
			b.fx.poof(e.position, Color(1, 0.4, 0.5, 0.9))
	var chaser: String = ids[0]
	for cand in ids:
		if EnemyDefs.ENEMIES[cand].beh in ["chaser", "runner"]:
			chaser = cand
			break
	var n := 14 + b.tier
	var rad := b.director.spawn_radius() * 0.9
	for k in n:
		b.enemies.spawn(chaser, pp + Vector2.from_angle(TAU * k / n) * rad, {"force": true})
	if (ev.elites as Array).is_empty():
		_curse_done(ev, ev.pos)


## Volá Battle při každém zabití (truhla počítá padlé kolem sebe, obelisk své elity).
func on_kill(e: Enemy) -> void:
	for ev in list.duplicate():
		match ev.id:
			"truhla":
				if e.position.distance_to(ev.pos) < float(ev.def.r):
					ev.engaged = true
					ev.kills = int(ev.kills) + 1
					if int(ev.kills) >= int(ev.def.kills):
						_unlock(ev)
			"obelisk":
				if (ev.elites as Array).has(e):
					ev.killed = int(ev.killed) + 1
					if int(ev.killed) >= (ev.elites as Array).size():
						_curse_done(ev, e.position)


func _curse_done(ev: Dictionary, at: Vector2) -> void:
	_log("kletba zlomena")
	b.banner("Kletba zlomena!", Color("6fcf2f"), "Legendární truhla je tvoje")
	b.pickups.drop("chest", at, 3)
	Sfx.play("chest")
	b.fx.explosion(ev.pos + Vector2(0, -80), 90.0, Color("ff4d6d"))
	_consume(ev)


func _unlock(ev: Dictionary) -> void:
	_log("truhla otevřena")
	var spr: Sprite2D = ev.spr
	spr.texture = Baker.tex("ev:truhla1")
	b.banner("Truhla se otevřela!", Color("3fa8ff"))
	Sfx.play("chest")
	b.fx.burst(ev.pos + Vector2(0, -40), Color("ffd23f"), 18, 300.0, 6.0)
	b.pickups.drop("chest", ev.pos + Vector2(0, 20))
	for i in 10:
		b.pickups.drop("coin", ev.pos + Vector2(0, 10), 1, 300.0)
	ev.done = true
	list.erase(ev)
	var tw := spr.create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(spr, "modulate:a", 0.0, 0.5)
	tw.tween_callback(spr.queue_free)


# ---------------------------------------------------------------- automatický hráč

func _log(s: String) -> void:
	if b.autoplay:
		print("UDÁLOST " + s)

## Kam má automat jít (Vector2.INF = nikam).
func autopilot_target() -> Vector2:
	var p := b.player
	for ev in list:
		if ev.done or ev.get("declined", false):
			continue
		match ev.id:
			"oltar", "kramar", "muka":
				return ev.pos
			"obelisk":
				if p.hp > p.max_hp * 0.6 and not ev.engaged:
					return ev.pos
			"truhla":
				if p.hp > p.max_hp * 0.4:
					return ev.pos
	return Vector2.INF


func _auto(ev: Dictionary) -> void:
	await get_tree().create_timer(0.2, true).timeout
	if not is_instance_valid(b) or b.state != Battle.State.LEVELUP:
		return
	var p := b.player
	match ev.id:
		"oltar":
			if p.hp > p.max_hp * 0.7:
				altar(ev, "hp")
			elif b.gold_run >= int(ev.def.gold_cost):
				altar(ev, "gold")
			else:
				altar(ev, "leave")
		"muka":
			bless(ev, "sila")
		"kramar":
			if p.hp < p.max_hp * 0.6:
				buy(EventDefs.SHOP[0])
			if b.gold_run >= 30:
				buy(EventDefs.SHOP[2])
			leave_peddler(ev)


# ---------------------------------------------------------------- kresba na zemi

func _draw() -> void:
	for ev in list:
		var c: Vector2 = ev.pos
		var col := Color(ev.def.col)
		var r: float = ev.def.r
		var fade := clampf(float(ev.life) / 5.0, 0.0, 1.0) if not ev.engaged else 1.0
		var pulse := 0.5 + 0.5 * sin(float(ev.t) * 4.0)
		var ry := 0.5
		var ring := Art.ellipse(c, r, r * ry, 48)
		draw_colored_polygon(ring, Color(col, (0.08 + 0.05 * pulse) * fade))
		ring.append(ring[0])
		draw_polyline(ring, Color(col, 0.7 * fade), 3.0, true)
		var k := -1.0
		if ev.id == "muka":
			k = float(ev.progress)
		elif ev.id == "truhla":
			k = float(ev.kills) / float(ev.def.kills)
		if k > 0.0:
			var arc := PackedVector2Array()
			var steps := maxi(2, int(48 * k))
			for i in steps + 1:
				var a := -PI * 0.5 + TAU * k * i / steps
				arc.append(c + Vector2(cos(a) * (r + 10.0), sin(a) * (r + 10.0) * ry))
			draw_polyline(arc, Color(Art.OUTLINE, 0.8), 11.0, true)
			draw_polyline(arc, col.lightened(0.2), 6.0, true)
		if ev.id == "truhla" and int(ev.kills) > 0:
			Art.text(self, c + Vector2(0, r * ry + 34.0), "%d / %d" % [int(ev.kills), int(ev.def.kills)], 20, Color.WHITE, 5)
