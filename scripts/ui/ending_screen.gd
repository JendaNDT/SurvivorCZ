extends Control
class_name EndingScreen
## Závěr hry: celé Česko je dobyté. Ohňostroj, statistiky a poděkování.

signal done

var t := 0.0
var rockets: Array = []
var sparks: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Sfx.play("win")
	Sfx.start_music("map")
	var bt := CCButton.make("Zpět na mapu", Art.BTN_GREEN, Vector2(320, 80), 30)
	bt.position = Vector2((size.x - 320) * 0.5, size.y - 110)
	bt.pressed.connect(func(): done.emit())
	add_child(bt)
	resized.connect(func(): bt.position = Vector2((size.x - 320) * 0.5, size.y - 110))


func _process(delta: float) -> void:
	t += delta
	if randf() < delta * 2.5:
		rockets.append({"p": Vector2(randf_range(100, size.x - 100), size.y), "v": Vector2(randf_range(-40, 40), randf_range(-620, -480)), "c": Color.from_hsv(randf(), 0.7, 1.0)})
	var i := rockets.size() - 1
	while i >= 0:
		var r: Dictionary = rockets[i]
		r.v.y += 420.0 * delta
		r.p += r.v * delta
		if r.v.y > -40.0:
			for k in 36:
				var a := TAU * k / 36.0
				sparks.append({"p": r.p, "v": Vector2(cos(a), sin(a)) * randf_range(120, 260), "c": r.c, "l": 1.2})
			rockets.remove_at(i)
			Sfx.play("boom", -14.0)
		i -= 1
	i = sparks.size() - 1
	while i >= 0:
		var s: Dictionary = sparks[i]
		s.v *= 0.97
		s.v.y += 120.0 * delta
		s.p += s.v * delta
		s.l -= delta
		if s.l <= 0.0:
			sparks.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("1a2a5a"))
	for k in 6:
		draw_rect(Rect2(0, size.y * (0.5 + k * 0.08), size.x, size.y), Color(0.15, 0.25 + k * 0.03, 0.55, 0.15))
	for r in rockets:
		draw_circle(r.p, 4, r.c)
	for s in sparks:
		draw_circle(s.p, 3.5 * s.l, Color(s.c, clampf(s.l, 0.0, 1.0)))
	var cx := size.x * 0.5
	var bob := sin(t * 2.0) * 6.0
	Art.ribbon(self, Vector2(cx, 120 + bob), 720, 96, Color("e2382c"), "", 30)
	Art.text(self, Vector2(cx, 140 + bob), "CELÉ ČESKO JE TVOJE!", 52, Color("ffd23f"), 12)
	Art.icon_crown(self, Vector2(cx, 40 + bob), 46)
	var st: Dictionary = Game.data.stats
	var lines := [
		"Dobyl jsi všech 14 krajů!",
		"Poražení nepřátelé: %d" % int(st.get("kills", 0)),
		"Poražení bossové: %d" % int(st.get("bosses", 0)),
		"Bitvy: %d   ·   Porážky: %d" % [int(st.get("runs", 0)) + int(st.get("defeats", 0)), int(st.get("defeats", 0))],
	]
	var stars := 0
	for id in Regions.ORDER:
		stars += Game.stars(id)
	lines.append("Hvězdy: %d / 42 – zkus získat všechny!" % stars)
	for i in lines.size():
		Art.text(self, Vector2(cx, 250 + i * 46), lines[i], 28 if i == 0 else 24, Color.WHITE, 7)
