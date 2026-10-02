extends Control
class_name TouchControls
## Dotykové ovládání: plovoucí joystick (kdekoli mimo tlačítka),
## tlačítko úskoku, ultimátky a pauzy. Podporuje více prstů najednou.
## Pro leváky jsou úskok a hrom zrcadlově vlevo.
## Na počítači funguje i klávesnice (WASD/šipky, mezerník, E, Esc).

var b: Battle
var joy_index := -1
var joy_origin := Vector2.ZERO
var joy_pos := Vector2.ZERO
const JOY_R := 70.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


## Vodorovná poloha měřená od pravého okraje (pro leváky od levého).
func _from_side(x: float) -> float:
	return x if bool(Game.setting("left_handed")) else size.x - x


func _dash_c() -> Vector2:
	return Vector2(_from_side(110), size.y - 110)


func _ult_c() -> Vector2:
	return Vector2(_from_side(235), size.y - 70)


func _pause_c() -> Vector2:
	return Vector2(size.x - 52, 50)


func input_vector() -> Vector2:
	var v := Vector2.ZERO
	if joy_index >= 0:
		v = (joy_pos - joy_origin) / JOY_R
		if v.length() < 0.12:
			v = Vector2.ZERO
	var k := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up"))
	if Input.is_physical_key_pressed(KEY_D):
		k.x += 1
	if Input.is_physical_key_pressed(KEY_A):
		k.x -= 1
	if Input.is_physical_key_pressed(KEY_S):
		k.y += 1
	if Input.is_physical_key_pressed(KEY_W):
		k.y -= 1
	if k.length() > 0.1:
		v = k.normalized()
	return v.limit_length(1.0)


func _input(event: InputEvent) -> void:
	if b == null or b.state == Battle.State.LOADING:
		return
	var playing := b.state == Battle.State.PLAY or b.state == Battle.State.BOSS or b.state == Battle.State.BOSS_INTRO
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE and playing:
			b.player.dash()
		elif event.physical_keycode == KEY_E and playing:
			b.use_ult()
		elif event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_P:
			if playing:
				b.pause_game()
			elif b.state == Battle.State.PAUSE:
				b.resume_game()
		return
	if not playing:
		joy_index = -1
		return
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			if p.distance_to(_dash_c()) < 74.0:
				b.player.dash()
				get_viewport().set_input_as_handled()
			elif p.distance_to(_ult_c()) < 52.0:
				b.use_ult()
				get_viewport().set_input_as_handled()
			elif p.distance_to(_pause_c()) < 40.0:
				b.pause_game()
				get_viewport().set_input_as_handled()
			elif joy_index < 0:
				joy_index = event.index
				joy_origin = p
				joy_pos = p
				get_viewport().set_input_as_handled()
		elif event.index == joy_index:
			joy_index = -1
	elif event is InputEventScreenDrag and event.index == joy_index:
		joy_pos = event.position
		var d := joy_pos - joy_origin
		if d.length() > JOY_R:
			joy_origin = joy_pos - d.normalized() * JOY_R
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if b == null or b.player == null:
		return
	if b.state == Battle.State.WIN or b.state == Battle.State.LOSE:
		return
	# joystick
	if joy_index >= 0:
		draw_circle(joy_origin, JOY_R + 6, Color(0, 0, 0, 0.18))
		draw_arc(joy_origin, JOY_R, 0, TAU, 48, Color(1, 1, 1, 0.55), 4.0, true)
		var knob := joy_origin + (joy_pos - joy_origin).limit_length(JOY_R)
		draw_circle(knob + Vector2(0, 4), 32, Color(0, 0, 0, 0.25))
		draw_circle(knob, 33, Art.OUTLINE)
		draw_circle(knob, 30, Color("e9eef3"))
		draw_circle(knob + Vector2(-8, -10), 10, Color(1, 1, 1, 0.8))
	else:
		var hint := Vector2(size.x - _from_side(150), size.y - 140)
		draw_arc(hint, JOY_R, 0, TAU, 48, Color(1, 1, 1, 0.18), 3.0, true)
		draw_circle(hint, 24, Color(1, 1, 1, 0.12))
	# úskok
	var dc := _dash_c()
	var ready := b.player.can_dash()
	_round_button(dc, 62.0, Color("3fb2ff") if ready else Color("7d858c"), "ui:boot", 1.0 - b.player.dash_cd / Player.DASH_CD)
	Art.text(self, dc + Vector2(0, 86), "ÚSKOK", 18, Color.WHITE, 5)
	# ultimátka
	var uc := _ult_c()
	var full := b.ult >= 1.0
	var pulse := 1.0 + (0.08 * sin(b.time_total * 8.0) if full else 0.0)
	_round_button(uc, 44.0 * pulse, Color("ffc928") if full else Color("8a7a5a"), "ui:bolt", b.ult)
	Art.text(self, uc + Vector2(0, 64), "HROM", 16, Color.WHITE, 5)
	# pauza
	var pc := _pause_c()
	_round_button(pc, 30.0, Color("ffb030"), "ui:pause", 1.0)


func _round_button(c: Vector2, r: float, col: Color, icon: String, fill: float) -> void:
	draw_circle(c + Vector2(0, 6), r + 4, Color(0, 0, 0, 0.3))
	draw_circle(c, r + 4, Art.OUTLINE)
	draw_circle(c + Vector2(0, 4), r, col.darkened(0.4))
	draw_circle(c, r - 2, col)
	draw_circle(c + Vector2(0, -r * 0.25), r * 0.7, Color(col.lightened(0.3), 0.6))
	if fill < 1.0:
		draw_arc(c, r - 6, -PI * 0.5, -PI * 0.5 + TAU * clampf(fill, 0.0, 1.0), 40, Color(1, 1, 1, 0.9), 6.0, true)
	if Baker.has(icon):
		var t := Baker.tex(icon)
		var s := Vector2(r, r) * 1.25
		draw_texture_rect(t, Rect2(c - s * 0.5, s), false)
