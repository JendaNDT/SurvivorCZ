extends Node2D
class_name Player
## Hrdina. Hráč ovládá jen pohyb, úskok a ultimátku – útočí se samo.

const DASH_TIME := 0.2
const DASH_CD := 2.2
const HURT_CD := 0.6

var b: Battle
var r := 18.0
var hp := 120.0
var max_hp := 120.0
var move_dir := Vector2.ZERO
var face_dir := Vector2.RIGHT
var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := Vector2.RIGHT
var invuln := 0.0
var hurt_cd := 0.0
var flash := 0.0
## Odhození (nástrahy krajů), postupně slábne.
var knock := Vector2.ZERO
var anim_t := 0.0
var ghost_t := 0.0

var body: Sprite2D
var shadow: Sprite2D
var frames: Array = []


func init(battle: Battle) -> void:
	b = battle
	frames = [Baker.tex("hero:0"), Baker.tex("hero:1")]
	body = Sprite2D.new()
	body.texture = frames[0]
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	body.scale = Vector2.ONE * 0.62 / Baker.SCALE
	body.position = Vector2(0, -6)
	add_child(body)
	shadow = Sprite2D.new()
	shadow.texture = Baker.tex("shadow")
	shadow.scale = Vector2(1.15, 1.0)
	b.shadow_layer.add_child(shadow)


func can_dash() -> bool:
	return dash_cd <= 0.0 and dash_t <= 0.0


func dash() -> void:
	if not can_dash():
		return
	dash_t = DASH_TIME
	dash_cd = DASH_CD
	dash_dir = move_dir if move_dir.length() > 0.1 else face_dir
	invuln = maxf(invuln, DASH_TIME + 0.1)
	Sfx.play("dash", -4.0)
	b.fx.poof(position + Vector2(0, 20), Color(1, 1, 1, 0.7))


func update(delta: float, input: Vector2) -> void:
	move_dir = input.limit_length(1.0)
	if move_dir.length() > 0.15:
		face_dir = move_dir.normalized()
	dash_cd = maxf(0.0, dash_cd - delta)
	invuln = maxf(0.0, invuln - delta)
	hurt_cd = maxf(0.0, hurt_cd - delta)
	var vel: Vector2 = move_dir * b.stats.speed
	if b.hazards and b.hazards.mods:
		vel = vel * b.hazards.speed_mult(position, null) + b.hazards.push_at(position, false)
	if dash_t > 0.0:
		dash_t -= delta
		vel = dash_dir * b.stats.speed * 3.4
		ghost_t -= delta
		if ghost_t <= 0.0:
			ghost_t = 0.04
			_ghost()
	position += (vel + knock) * delta
	knock = knock.move_toward(Vector2.ZERO, delta * 1600.0)
	if b.arena_radius > 0.0:
		position = b.clamp_to_arena(position, r)
	# regenerace
	if b.stats.regen > 0.0 and hp < max_hp:
		hp = minf(max_hp, hp + b.stats.regen * delta)
	# animace
	var moving := vel.length() > 5.0
	anim_t += delta * (7.0 if moving else 2.0)
	body.texture = frames[int(anim_t) % 2] if moving else frames[0]
	var bob := sin(anim_t * PI) * (0.05 if moving else 0.025)
	var sx := 0.62 / Baker.SCALE
	body.scale = Vector2(sx * (1.0 + bob) * (1.0 if face_dir.x >= 0.0 else -1.0), sx * (1.0 - bob))
	body.position.y = -6.0 - (absf(sin(anim_t * PI)) * 3.0 if moving else 0.0)
	if flash > 0.0:
		flash -= delta
		body.modulate = Color(2.5, 1.2, 1.2) if int(flash * 20.0) % 2 == 0 else Color.WHITE
	elif invuln > 0.0 and dash_t <= 0.0:
		body.modulate = Color(1, 1, 1, 0.55 + 0.45 * sin(invuln * 40.0))
	else:
		body.modulate = Color.WHITE
	shadow.position = position + Vector2(0, 30)


func _ghost() -> void:
	var g := Sprite2D.new()
	g.texture = body.texture
	g.scale = body.scale
	g.texture_filter = body.texture_filter
	g.position = position + body.position
	g.modulate = Color(0.6, 0.85, 1.0, 0.55)
	b.entity_layer.add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.25)
	tw.tween_callback(g.queue_free)
