extends Boss
class_name MiniBoss
## Náčelník v polovině kraje: hlavní nepřítel kraje ve dvojnásobné velikosti
## se zlatou korunou a září. Dva útoky bosse, žádné fáze ani aréna.
## Žije v seznamu nepřátel (EnemyManager.list), takže ho zbraně najdou samy.
## Pohyb a útoky si řídí sám (EnemyManager přeskakuje is_boss), volá ho Battle.

const SIZE_K := 2.0
## Kolik životů má náčelník oproti bossovi (zbraně se dělí mezi něj a hordu).
const HP_SHARE := 0.25
## Posun koruny (v jednotkách kresby) u zvířat, která mají nejvýš hřbet, ne hlavu.
const CROWN_FIX := {"divocak": Vector2(24, 9)}

var bar: Bar
var shown_hp := -1.0
var glow_t := 0.0


## Ukazatel životů a jméno nad hlavou (nepřevrací se s kresbou).
class Bar extends Node2D:
	var mb: MiniBoss

	func _draw() -> void:
		var w := 128.0
		Art.text(self, Vector2(0, -8), mb.bdef.name, 18, Color("ffd23f"), 5)
		Art.bar(self, Rect2(-w * 0.5, 0, w, 15), maxf(0.0, mb.hp) / mb.max_hp, Color("b8262c"))


func init_chief(battle: Battle, chief_id: String, hp_total: float) -> void:
	b = battle
	is_boss = true
	chief = true
	bdef = EnemyDefs.MINIBOSSES[chief_id]
	var base := EnemyDefs.get_enemy(bdef.base)
	var d := {"id": chief_id, "base": bdef.base, "beh": "boss", "r": float(base.r) * SIZE_K, "xp": 40, "name": bdef.name}
	setup(d, Baker.tex("e:%s:0" % bdef.base), Baker.tex("e:%s:1" % bdef.base))
	max_hp = hp_total
	hp = hp_total
	spd = 78.0 * b.enemy_speed_mult()
	dmg = 10.0 * b.boss_dmg_mult()
	knock_res = 1.0
	intro_t = 1.0
	intro_len = 1.0
	attack_t = 1.6
	attack_gap = 2.4
	set_visual_scale(SIZE_K)
	glow = Baker.sprite("elite_glow")
	glow.scale *= float(base.size) / 100.0 * 1.7
	glow.show_behind_parent = true
	add_child(glow)
	var top := dress(body, bdef.base)
	shadow = Sprite2D.new()
	shadow.texture = Baker.tex("shadow")
	shadow.scale = Vector2(r / 20.0, r / 20.0)
	b.shadow_layer.add_child(shadow)
	bar = Bar.new()
	bar.mb = self
	bar.z_index = 10
	bar.position = Vector2(0, top * SIZE_K / Baker.SCALE - 18.0)
	bar.visible = false
	add_child(bar)


## Nasadí kresbě nepřítele korunu. Vrací horní okraj koruny v pixelech textury
## (kresba má střed v 0,0). Používá i galerie.
static func dress(spr: Sprite2D, base_id: String) -> float:
	var k := float(EnemyDefs.get_enemy(base_id).size) / 100.0 * 0.62
	var fix: Vector2 = CROWN_FIX.get(base_id, Vector2.ZERO)
	var anchor := crown_anchor(spr.texture) + fix * Baker.SCALE
	var crown := Baker.sprite("fx:crown")
	crown.scale = Vector2.ONE * k
	crown.rotation = -0.12
	crown.position = anchor + Vector2(0, -22.0 * k)
	spr.add_child(crown)
	return anchor.y - 64.0 * k


## Vršek hlavy: nejvyšší neprůhledné pixely kresby (kolem jejich středu sedí koruna).
static func crown_anchor(tex: Texture2D) -> Vector2:
	var sz := tex.get_size() if tex else Vector2(4, 4)
	var img := tex.get_image() if tex else null
	if img == null or img.get_width() < 16:
		return Vector2(0, -sz.y * 0.4)
	var used := img.get_used_rect()
	if used.size.y < 8:
		return Vector2(0, -sz.y * 0.4)
	var y0 := used.position.y
	var x0 := 1 << 30
	var x1 := -1
	for y in range(y0, mini(y0 + 12, used.end.y)):
		for x in range(used.position.x, used.end.x):
			if img.get_pixel(x, y).a > 0.5:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
	var cx: float = (x0 + x1) * 0.5 if x1 >= 0 else float(used.get_center().x)
	return Vector2(cx, y0 + 4.0) - sz * 0.5


func boss_update(delta: float) -> void:
	super.boss_update(delta)
	if not alive:
		return
	glow_t += delta
	glow.modulate.a = 0.75 + 0.25 * sin(glow_t * 4.0)
	if hp != shown_hp:
		shown_hp = hp
		bar.queue_redraw()


## Do seznamu nepřátel (a tím na mušku zbraní) se náčelník dostane až po dopadu.
func _landed() -> void:
	b.enemies.list.append(self)
	bar.visible = true
	b.shake(10.0)
	Sfx.play("boom", -4.0)
	b.fx.explosion(position + Vector2(0, 20), 90.0, Color("ffd23f"))
	var wv := b.ground_fx.shockwave(position, 420.0, 250.0, 22.0, Color(1, 0.85, 0.4))
	_track_wave(wv, 8.0)


func die() -> void:
	b.chief_killed(self)


func _check_phase() -> void:
	pass


## Náčelník nesmí hrdinovi utéct z obrazovky: když je daleko, dožene ho.
func _move_speed(dist: float) -> float:
	var s := speed_now() * (2.6 if dist > 850.0 else 1.0)
	if b.hazards and b.hazards.mods:
		s *= b.hazards.speed_mult(position, self)
	return s


## Pásy a vítr unášejí i náčelníka.
func _after_move(delta: float) -> void:
	if b.hazards and b.hazards.mods:
		position += b.hazards.push_at(position, true) * delta


func power() -> float:
	return b.boss_dmg_mult() * 0.6


func _attacks() -> Array:
	return bdef.attacks


## Zmizí ze hry: po porážce, nebo když přijde boss. Uzel se uvolní až po pár
## sekundách, aby rozběhnuté útoky (korutiny) stihly skončit.
func vanish(t: float) -> void:
	alive = false
	b.enemies.list.erase(self)
	bar.visible = false
	if is_instance_valid(shadow):
		shadow.queue_free()
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(2.5, 2.2, 1.2, 0.0), t)
	get_tree().create_timer(3.0, false).timeout.connect(queue_free)
