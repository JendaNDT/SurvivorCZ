extends Control
class_name SettingsBoard
## Deska nastavení, kterou sdílí mapa i pauza v bitvě:
## hlasitost hudby a efektů, vibrace, úsporná grafika, ukazatel FPS a ovládání pro leváky.

signal help_pressed
signal back_pressed
signal reset_done

const W := 700.0
const H := 470.0

var on_map := true
var music: CCSlider
var effects: CCSlider


static func make(map_mode: bool) -> SettingsBoard:
	var sb := SettingsBoard.new()
	sb.on_map = map_mode
	sb.size = Vector2(W, H)
	return sb


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	music = CCSlider.make(float(Game.setting("music_vol")), Art.BTN_BLUE, 380)
	music.position = Vector2(176, 74)
	music.value_changed.connect(func(v: float):
		Game.set_setting("music_vol", v, false)
		queue_redraw())
	music.drag_ended.connect(func(v: float): Game.set_setting("music_vol", v))
	add_child(music)
	effects = CCSlider.make(float(Game.setting("sfx_vol")), Art.BTN_GREEN, 380)
	effects.position = Vector2(176, 134)
	effects.value_changed.connect(func(v: float):
		Game.set_setting("sfx_vol", v, false)
		queue_redraw())
	effects.drag_ended.connect(func(v: float):
		Game.set_setting("sfx_vol", v)
		Sfx.play("coin", 0.0, 0.0, 0.0))
	add_child(effects)
	var toggles := [
		["Vibrace", "vibrate", bool(Game.setting("vibrate"))],
		["Úsporná grafika", "quality", Game.low_quality()],
		["Ukazatel FPS", "show_fps", bool(Game.setting("show_fps"))],
		["Pro leváky", "left_handed", bool(Game.setting("left_handed"))],
	]
	for i in toggles.size():
		var def: Array = toggles[i]
		var t := CCToggle.make(def[0], def[2], Vector2(312, 58))
		t.position = Vector2(34 + (i % 2) * 320, 196 + (i / 2) * 68)
		var key: String = def[1]
		t.toggled_to.connect(_on_toggle.bind(key))
		add_child(t)
	var by := H - 104.0
	if on_map:
		var help := CCButton.make("Jak hrát", Art.BTN_YELLOW, Vector2(250, 68), 26)
		help.position = Vector2(W * 0.5 - 266, by)
		help.pressed.connect(func(): help_pressed.emit())
		add_child(help)
		var reset := CCButton.make("Smazat postup", Art.BTN_RED, Vector2(250, 68), 24)
		reset.position = Vector2(W * 0.5 + 16, by)
		var armed := [false]
		reset.pressed.connect(func():
			if not armed[0]:
				armed[0] = true
				reset.caption = "Opravdu smazat?"
				reset.queue_redraw()
			else:
				Game.reset()
				Game.data.intro_seen = true
				Game.save_game()
				reset_done.emit())
		add_child(reset)
	else:
		var back := CCButton.make("Zpět", Art.BTN_GREEN, Vector2(260, 68), 28)
		back.position = Vector2((W - 260) * 0.5, by)
		back.pressed.connect(func(): back_pressed.emit())
		add_child(back)


func _on_toggle(on: bool, key: String) -> void:
	match key:
		"quality":
			Game.set_setting("quality", "low" if on else "high")
			Game.apply_quality()
		"vibrate":
			Game.set_setting("vibrate", on)
			if on:
				Game.vibrate(60)
		_:
			Game.set_setting(key, on)


func _draw() -> void:
	Art.panel(self, Rect2(Vector2.ZERO, size))
	var title := "NASTAVENÍ"
	Art.ribbon(self, Vector2(size.x * 0.5, 4), Art.text_width(title, 34) + 90.0, 58, Color("3fa8ff"), title, 34)
	var ink := Color("4a2c12")
	for row in [[86.0, "Hudba", music], [146.0, "Efekty", effects]]:
		var y: float = row[0]
		var sl: CCSlider = row[2]
		draw_string(Art.font, Vector2(40, y + 21), row[1], HORIZONTAL_ALIGNMENT_LEFT, 130, 24, ink)
		var pct := "%d %%" % roundi((sl.value if sl else 0.0) * 100.0)
		draw_string(Art.font, Vector2(574, y + 21), pct, HORIZONTAL_ALIGNMENT_RIGHT, 86, 22, Color("6b4a2a"))
	draw_string(Art.font, Vector2(0, 352), "Seká se hra? Zapni úspornou grafiku.", HORIZONTAL_ALIGNMENT_CENTER, size.x, 17, Color("8a6a4a"))
	var ver := "verze " + str(ProjectSettings.get_setting("application/config/version", ""))
	draw_string(Art.font, Vector2(0, size.y - 22), ver, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 30, 13, Color(0.42, 0.29, 0.16, 0.7))
