extends Node
class_name PickupSystem
## Elixír (zkušenosti), zlaťáky, svíčková (léčení), magnet a truhly
## (truhla s hodnotou 2 je od náčelníka).

const XP_CAP := 320


class Pick:
	var kind := "xp0"
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var value := 1
	var spr: Sprite2D
	var pull := false
	var spd := 0.0
	var t := 0.0


var b: Battle
var picks: Array = []
var xp_count := 0


func init(battle: Battle) -> void:
	b = battle


func _xp_kind(v: int) -> String:
	if v >= 25:
		return "xp2"
	if v >= 5:
		return "xp1"
	return "xp0"


func drop_xp(pos: Vector2, value: int) -> void:
	if xp_count >= XP_CAP:
		# příliš mnoho krystalů: přidej hodnotu k náhodnému existujícímu
		for k in 6:
			var p: Pick = picks[randi() % picks.size()]
			if p.kind.begins_with("xp") and not p.pull:
				p.value += value
				var nk := _xp_kind(p.value)
				if nk != p.kind:
					p.kind = nk
					p.spr.texture = Baker.tex("fx:" + nk)
				return
	drop(_xp_kind(value), pos, value)


func drop(kind: String, pos: Vector2, value: int = 1) -> void:
	var p := Pick.new()
	p.kind = kind
	p.pos = pos
	p.value = value
	var a := randf() * TAU
	p.vel = Vector2(cos(a), sin(a)) * randf_range(30.0, 110.0)
	p.spr = Baker.sprite("fx:" + kind)
	p.spr.position = pos
	if kind == "chest":
		p.spr.scale *= _chest_scale(p)
	b.pickup_layer.add_child(p.spr)
	picks.append(p)
	if kind.begins_with("xp"):
		xp_count += 1


## Truhla náčelníka (value 2) je větší.
func _chest_scale(p: Pick) -> float:
	if p.kind != "chest":
		return 1.0
	return 1.5 if p.value >= 2 else 1.1


## Truhly, které hrdina nestihl sebrat, k němu přiletí (třeba když přichází boss).
func pull_chests() -> void:
	for p in picks:
		if p.kind == "chest":
			p.pull = true


func magnetize_all() -> void:
	for p in picks:
		if p.kind.begins_with("xp") or p.kind == "coin":
			p.pull = true


func update(delta: float) -> void:
	var pp: Vector2 = b.player.position
	var mag: float = b.stats.magnet
	var i := picks.size() - 1
	while i >= 0:
		var p: Pick = picks[i]
		i -= 1
		p.t += delta
		var d := p.pos.distance_to(pp)
		if p.pull:
			p.spd += 1600.0 * delta
			p.pos = p.pos.move_toward(pp, p.spd * delta)
		else:
			p.pos += p.vel * delta
			p.vel *= 0.86
			var grab := mag if (p.kind.begins_with("xp") or p.kind == "coin") else 46.0
			if d < grab:
				p.pull = true
				p.spd = -120.0
		p.spr.position = p.pos + Vector2(0, -absf(sin(p.t * 3.5)) * 4.0)
		if p.kind == "chest" or p.kind == "magnet" or p.kind == "jidlo":
			p.spr.scale = Vector2.ONE * (1.0 + 0.08 * sin(p.t * 5.0)) * _chest_scale(p) / Baker.SCALE
		if d < 22.0 and p.pull:
			_collect(p)


func _collect(p: Pick) -> void:
	picks.erase(p)
	p.spr.queue_free()
	match p.kind:
		"xp0", "xp1", "xp2":
			xp_count -= 1
			b.add_xp(p.value)
			Sfx.play("pickup", -10.0, 0.15, 0.03)
		"coin":
			b.add_gold(p.value)
			Sfx.play("coin", -8.0)
		"jidlo":
			b.heal(b.player.max_hp * 0.3)
			b.fx.text(b.player.position + Vector2(0, -50), "Svíčková!", Color("8fff7a"))
			Sfx.play("chest", -4.0)
		"magnet":
			magnetize_all()
			Sfx.play("chest", -4.0)
		"chest":
			b.open_chest(p.value >= 2)


func clear() -> void:
	for p in picks:
		p.spr.queue_free()
	picks.clear()
	xp_count = 0
