extends Control
class_name BossIntro
## Nástup bosse jako v Clash of Clans: obrazovka ztmavne, zleva přijede hrdina
## na modré stuze, zprava boss na červené, uprostřed velké „VS“ s otřesem
## a pod tím jméno a přídomek bosse. Pak boss dopadne do arény.

const DUR := 1.8
const VS_AT := 0.38

var b: Battle
var bdef: Dictionary
var boss_tex: Texture2D
var hero_tex: Texture2D
var t := 0.0
var hit := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	t += delta
	if t >= VS_AT and not hit:
		hit = true
		Sfx.play("boom", -3.0)
		Game.vibrate(60)
		if b:
			b.shake(8.0)
	if t >= DUR:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var vs := size
	var cx := vs.x * 0.5
	var cy := vs.y * 0.42
	var fade := minf(clampf(t / 0.2, 0.0, 1.0), clampf((DUR - t) / 0.25, 0.0, 1.0))
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.05, 0.03, 0.1, 0.7 * fade))
	# otřes celé scény po dopadu „VS“
	var sh := Vector2.ZERO
	if t > VS_AT and t < VS_AT + 0.3:
		var amp := 10.0 * (1.0 - (t - VS_AT) / 0.3)
		sh = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	# stuhy přijedou z okrajů a na konci zase odjedou
	var k_in := _back(clampf(t / 0.34, 0.0, 1.0))
	var k_out := pow(clampf((t - (DUR - 0.3)) / 0.3, 0.0, 1.0), 2.0)
	var lx := (k_in - 1.0) * vs.x * 0.6 - k_out * vs.x * 0.7
	var rx := (1.0 - k_in) * vs.x * 0.6 + k_out * vs.x * 0.7
	var bh := 118.0
	var left := PackedVector2Array([Vector2(-40, cy - bh * 0.5), Vector2(cx - 36, cy - bh * 0.5), Vector2(cx - 84, cy + bh * 0.5), Vector2(-40, cy + bh * 0.5)])
	var right := PackedVector2Array([Vector2(cx + 84, cy - bh * 0.5), Vector2(vs.x + 40, cy - bh * 0.5), Vector2(vs.x + 40, cy + bh * 0.5), Vector2(cx + 36, cy + bh * 0.5)])
	Art.shape(self, Art.xform(left, Vector2(lx, 0) + sh), Color("2f8fe8"), 4.0, 0.7)
	Art.shape(self, Art.xform(right, Vector2(rx, 0) + sh), Color("e2382c"), 4.0, 0.7)
	# portréty
	_portrait(Vector2(cx - 270 + lx, cy) + sh, hero_tex, Color("9fd6ff"), Color("3a7bd5"), 0.56, 2.5)
	_portrait(Vector2(cx + 270 + rx, cy) + sh, boss_tex, Color("ffb0a0"), Color("b8262c"), 0.5, 2.1)
	# „VS“ přiletí zvětšené a dopadne
	if t >= VS_AT - 0.12:
		var kv := clampf((t - (VS_AT - 0.12)) / 0.12, 0.0, 1.0)
		var sc := lerpf(2.6, 1.0, kv) * (1.0 + 0.08 * maxf(0.0, 1.0 - (t - VS_AT) * 5.0))
		var a := kv * clampf((DUR - t) / 0.25, 0.0, 1.0)
		var c := Vector2(cx, cy) + sh
		draw_set_transform(c, -0.08, Vector2(sc, sc))
		Art.shape(self, Art.star(Vector2.ZERO, 92, 58, 12), Color(1, 0.62, 0.15, a), 4.0, 0.0)
		Art.text(self, Vector2(0, 34), "VS", 96, Color(1, 0.86, 0.25, a), 14)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# jméno a přídomek bosse
	if t >= 0.5:
		var an := clampf((t - 0.5) / 0.2, 0.0, 1.0) * clampf((DUR - t) / 0.25, 0.0, 1.0)
		var ny := cy + bh * 0.5 + 72.0 + (1.0 - an) * 20.0
		Art.text(self, Vector2(cx, ny), str(bdef.get("name", "")), 50, Color(1, 0.86, 0.3, an), 11)
		Art.text(self, Vector2(cx, ny + 40), str(bdef.get("title", "")), 25, Color(1, 0.96, 0.8, an), 7)


func _portrait(c: Vector2, tex: Texture2D, inner: Color, ring: Color, y_shift: float, fit: float) -> void:
	var r := 92.0
	draw_circle(c + Vector2(0, 6), r + 6, Color(0, 0, 0, 0.3))
	Art.circle(self, c, r + 6, Art.GOLD, 4.0)
	draw_circle(c, r, ring)
	draw_circle(c, r - 7, inner)
	if tex:
		var ts := tex.get_size()
		var s := (r * fit) / maxf(ts.x, ts.y)
		var sz := ts * s
		draw_texture_rect(tex, Rect2(c - Vector2(sz.x * 0.5, sz.y * y_shift), sz), false)


## Pružný dojezd (přejede kousek a vrátí se).
func _back(k: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(k - 1.0, 3.0) + c1 * pow(k - 1.0, 2.0)
