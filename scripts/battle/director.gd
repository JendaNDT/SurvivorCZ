extends Node
class_name Director
## Režisér vln: každou sekundu dostane „body hrozby“ a utrácí je za skupiny
## nepřátel v různých formacích. Ke konci kraje přitlačí a pošle elity,
## v polovině kraje pošle náčelníka, ve 30 % a 65 % událost (oltář, kramář…).

var b: Battle
var budget := 0.0
var group_t := 1.0
var events: Array = []


func init(battle: Battle) -> void:
	b = battle
	_build_events()


func _build_events() -> void:
	events = [
		{"at": 0.22, "kind": "ring", "done": false},
		{"at": 0.30, "kind": "event", "done": false},
		{"at": 0.38, "kind": "elite", "done": false},
		{"at": 0.50, "kind": "miniboss", "done": false},
		{"at": 0.60, "kind": "ring", "done": false},
		{"at": 0.65, "kind": "event", "done": false},
		{"at": 0.70, "kind": "elite", "done": false},
		{"at": 0.84, "kind": "final", "done": false},
		{"at": 0.90, "kind": "ring", "done": false},
	]
	# žár 2: elity dvakrát častěji, žár 8: druhý náčelník
	if b.heat >= 2:
		events.append({"at": 0.16, "kind": "elite", "done": false})
		events.append({"at": 0.80, "kind": "elite", "done": false})
	if b.heat >= 8:
		events.append({"at": 0.78, "kind": "miniboss", "done": false})


func rate(f: float) -> float:
	return (2.2 + 5.5 * f + 5.0 * f * f) * (1.0 + 0.06 * b.tier)


func update(delta: float) -> void:
	if b.state == Battle.State.BOSS:
		budget += 0.9 * (1.0 + 0.05 * b.tier) * delta
		group_t -= delta
		if group_t <= 0.0:
			group_t = randf_range(2.0, 3.0)
			_spawn_group(0.5, true)
		return
	if b.state != Battle.State.PLAY:
		return
	var f := clampf(b.elapsed / b.duration, 0.0, 1.0)
	if b.endless:
		# nekonečný boj: vlny dál houstnou
		f = 1.0 + b.endless_t / 240.0
	budget += rate(f) * delta
	group_t -= delta
	if group_t <= 0.0:
		group_t = randf_range(0.6, 1.3)
		_spawn_group(f, false)
	for ev in events:
		if not ev.done and f >= ev.at:
			# druhý náčelník počká, až padne první
			if ev.kind == "miniboss" and b.chief != null:
				continue
			ev.done = true
			_event(ev.kind, f)


func _pick_type(f: float) -> String:
	var ids: Array = b.region.enemies
	var total := 0.0
	var ws := []
	for id in ids:
		var beh: String = EnemyDefs.ENEMIES[id].beh
		var w: Array = EnemyDefs.WEIGHTS[beh]
		var v := lerpf(w[0], w[1], f)
		ws.append(v)
		total += v
	var r := randf() * total
	for k in ids.size():
		r -= ws[k]
		if r <= 0.0:
			return ids[k]
	return ids[0]


func spawn_radius() -> float:
	var rect: Rect2 = b.view_rect()
	return rect.size.length() * 0.5 + 50.0


func _spawn_group(f: float, in_arena: bool) -> void:
	var id := _pick_type(f)
	var cost: float = EnemyDefs.get_enemy(id).cost
	var maxn := int(4 + f * 10)
	var n := mini(int(budget / cost), maxn)
	if n <= 0:
		return
	if b.enemies.count() >= b.enemies.cap - 5:
		return
	budget -= n * cost
	var pp: Vector2 = b.player.position
	if in_arena:
		for k in n:
			var a := randf() * TAU
			var pos := b.arena_center + Vector2(cos(a), sin(a)) * (b.arena_radius - 30.0)
			if b.enemies.spawn(id, pos):
				b.fx.poof(pos)
		return
	var rad := spawn_radius()
	var form := randi() % 10
	if form < 5:
		# rozptýlení kolem dokola
		for k in n:
			var a := randf() * TAU
			b.enemies.spawn(id, pp + Vector2(cos(a), sin(a)) * rad * randf_range(1.0, 1.12))
	elif form < 8:
		# hlouček z jedné strany
		var a := randf() * TAU
		var c := pp + Vector2(cos(a), sin(a)) * rad
		for k in n:
			b.enemies.spawn(id, c + Vector2(randf_range(-70, 70), randf_range(-70, 70)))
	else:
		# zeď kolmo na směr
		var a := randf() * TAU
		var dir := Vector2(cos(a), sin(a))
		var c := pp + dir * rad
		for k in n:
			b.enemies.spawn(id, c + dir.orthogonal() * (k - n * 0.5) * 42.0)


func _event(kind: String, f: float) -> void:
	var pp: Vector2 = b.player.position
	match kind:
		"ring":
			var ids: Array = b.region.enemies
			var id: String = ids[0]
			for cand in ids:
				if EnemyDefs.ENEMIES[cand].beh in ["chaser", "runner"]:
					id = cand
					break
			var n := 22 + b.tier * 2
			var rad := spawn_radius() * 0.92
			for k in n:
				var a := TAU * k / n
				b.enemies.spawn(id, pp + Vector2(cos(a), sin(a)) * rad, {"force": true})
			b.banner("Obklíčení!", Color("ff6a4a"))
			Sfx.play("warn", -4.0)
		"elite":
			var ids: Array = b.region.enemies
			var id: String = ids[randi() % ids.size()]
			var a := randf() * TAU
			var e := b.enemies.spawn(id, pp + Vector2(cos(a), sin(a)) * spawn_radius() * 0.8, {"elite": true, "force": true})
			if e:
				b.banner("Elita: " + e.def.name, Color("ffd23f"))
				Sfx.play("warn", -4.0)
		"miniboss":
			b.spawn_chief()
		"event":
			b.events.spawn_random()
		"final":
			budget += 30.0 + b.tier * 4.0
			b.banner("Poslední vlna!", Color("ff8a2a"))
			Sfx.play("warn", -2.0)
