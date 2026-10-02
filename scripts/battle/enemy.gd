extends Node2D
class_name Enemy
## Jeden nepřítel. Logiku pohybu řídí EnemyManager, tady jsou jen data a vzhled.

enum St { MOVE, WINDUP, DASH, FUSE, REST, FLEE }

var def: Dictionary
var id: String
var beh: String
var hp := 10.0
var max_hp := 10.0
var spd := 60.0
var dmg := 5.0
var r := 16.0
var xp := 1
var elite := false
var mini := false
var is_boss := false
## Náčelník (MiniBoss): is_boss platí taky, ale náčelník žije v seznamu nepřátel.
var chief := false
var alive := true

var vel := Vector2.ZERO
var knock := Vector2.ZERO
var knock_res := 0.0
var state := St.MOVE
var timer := 0.0
var aux := Vector2.ZERO
var cd := 0.0

var slow_t := 0.0
var slow_f := 0.0
var burn_t := 0.0
var burn_dps := 0.0
var poison_t := 0.0
var poison_dps := 0.0
var flash := 0.0
var hit_cd := {}

var body: Sprite2D
var shadow: Sprite2D
var glow: Sprite2D
var frames: Array = []
var anim_t := 0.0
var base_scale := 1.0
var face := 1.0


func setup(d: Dictionary, tex0: Texture2D, tex1: Texture2D) -> void:
	def = d
	id = d.id
	beh = d.beh
	r = d.r
	xp = d.xp
	frames = [tex0, tex1]
	body = Sprite2D.new()
	body.texture = tex0
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(body)
	knock_res = 0.75 if beh == "tank" else 0.0
	anim_t = randf()


func set_visual_scale(s: float) -> void:
	base_scale = s
	body.scale = Vector2.ONE * (s / Baker.SCALE)


func animate(delta: float, moving: bool) -> void:
	anim_t += delta * (6.0 if moving else 2.0)
	var frame := int(anim_t) % 2
	body.texture = frames[frame]
	var bob := sin(anim_t * PI) * 0.06
	var sx := base_scale / Baker.SCALE
	body.scale = Vector2(sx * (1.0 + bob) * face, sx * (1.0 - bob))
	body.position.y = -absf(sin(anim_t * PI)) * 2.5
	if flash > 0.0:
		flash -= delta
		body.modulate = Color(2.4, 2.4, 2.4) if flash > 0.0 else _tint()
	elif state == St.WINDUP or state == St.FUSE:
		var blink := 0.5 + 0.5 * sin(timer * 30.0)
		body.modulate = Color(1.0 + blink, 1.0 - blink * 0.4, 1.0 - blink * 0.4)
	else:
		body.modulate = _tint()


func _tint() -> Color:
	if slow_t > 0.0:
		return Color(0.75, 0.9, 1.25)
	if poison_t > 0.0:
		return Color(0.8, 1.15, 0.75)
	if burn_t > 0.0:
		return Color(1.2, 0.9, 0.75)
	return Color.WHITE


func speed_now() -> float:
	var s := spd
	if slow_t > 0.0:
		s *= 1.0 - slow_f
	return s
