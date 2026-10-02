extends Control
class_name BattleOverlay
## Okna přes bitvu: výběr vylepšení, truhla, pauza, výhra a prohra.

var b: Battle
var dim: ColorRect
var content: Control


class Board extends Control:
	## Dřevěná deska s pergamenem a stuhou s nadpisem.
	var title := ""
	var ribbon_col := Color("e2382c")

	func _draw() -> void:
		Art.panel(self, Rect2(Vector2.ZERO, size))
		if title != "":
			Art.ribbon(self, Vector2(size.x * 0.5, 4), minf(size.x * 0.8, Art.text_width(title, 34) + 90.0), 58, ribbon_col, title, 34)


class Painter extends Control:
	var fn: Callable

	func _draw() -> void:
		fn.call(self)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim = ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.1, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	add_child(dim)
	content = Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)


func _clear() -> void:
	for c in content.get_children():
		c.queue_free()
	dim.visible = true
	dim.modulate.a = 0.0
	var tw := dim.create_tween()
	tw.tween_property(dim, "modulate:a", 1.0, 0.2)
	mouse_filter = Control.MOUSE_FILTER_STOP


func hide_all() -> void:
	for c in content.get_children():
		c.queue_free()
	dim.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _pop(c: Control, delay: float = 0.0) -> void:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2(0.4, 0.4)
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(c, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(c, "modulate:a", 1.0, 0.15)


func _title(text: String, col: Color, y: float, sub: String = "") -> void:
	var p := Painter.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size = Vector2(size.x, 120)
	p.position = Vector2(0, y)
	p.fn = func(ci: Control) -> void:
		var w := Art.text_width(text, 42) + 110.0
		Art.ribbon(ci, Vector2(ci.size.x * 0.5, 40), w, 70, col, text, 42)
		if sub != "":
			Art.text(ci, Vector2(ci.size.x * 0.5, 108), sub, 22, Color("fff6c8"), 6)
	content.add_child(p)
	_pop(p)


# ---------------------------------------------------------------- výběr vylepšení

func show_choice(cards: Array, source: String) -> void:
	_clear()
	if source == "chief":
		_title("TRUHLA NÁČELNÍKA!", Color("e8a010"), 8.0, "Poklad náčelníka – vyber si odměnu")
	elif source == "chest":
		_title("TRUHLA!", Color("b25cff"), 8.0, "Poklad z elity – vyber si odměnu")
	else:
		_title("NOVÁ ÚROVEŇ!", Color("3fa8ff"), 8.0, "Vyber si jedno vylepšení")
	_cards(cards)
	var row_y := size.y - 92.0
	var rr := CCButton.make("Přehodit", Color("3fb2ff"), Vector2(230, 70), 26)
	rr.icon_key = "icon:reroll"
	rr.icon_scale = 0.42
	rr.badge = str(b.rerolls)
	rr.disabled = b.rerolls <= 0
	rr.position = Vector2(size.x * 0.5 - 250, row_y)
	rr.pressed.connect(func():
		var nc := b.reroll(source)
		if not nc.is_empty():
			show_choice(nc, source))
	content.add_child(rr)
	var sk := CCButton.make("Přeskočit", Color("a7adb3"), Vector2(230, 70), 26)
	sk.sub = "+%d zlata, +10 %% života" % (8 + b.tier * 2)
	sk.font_size = 24
	sk.position = Vector2(size.x * 0.5 + 20, row_y)
	sk.pressed.connect(func():
		b.skip_card()
		b.choose({"type": "none"}))
	content.add_child(sk)


func _cards(cards: Array) -> void:
	var cw := 250.0
	var ch := 400.0
	var gap := 26.0
	var total := cards.size() * cw + (cards.size() - 1) * gap
	if total > size.x - 40:
		cw = (size.x - 40 - (cards.size() - 1) * gap) / cards.size()
		total = cards.size() * cw + (cards.size() - 1) * gap
	var x0 := size.x * 0.5 - total * 0.5
	var y := maxf(130.0, (size.y - ch) * 0.5 - 10.0)
	for i in cards.size():
		var c := UpgradeCard.new()
		c.card = cards[i]
		c.b = b
		c.size = Vector2(cw, ch)
		c.position = Vector2(x0 + i * (cw + gap), y)
		var cd: Dictionary = cards[i]
		c.pressed.connect(func(): b.choose(cd))
		content.add_child(c)
		_pop(c, 0.06 * i)


# ---------------------------------------------------------------- pauza

func show_pause() -> void:
	_clear()
	var bw := 470.0
	var bh := 430.0
	var board := Board.new()
	board.title = "PAUZA"
	board.ribbon_col = Color("3fa8ff")
	board.size = Vector2(bw, bh)
	board.position = (size - board.size) * 0.5
	content.add_child(board)
	_pop(board)
	var info := Painter.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size = Vector2(bw, 120)
	info.position = Vector2(0, 50)
	info.fn = func(ci: Control) -> void:
		var cx := ci.size.x * 0.5
		ci.draw_string(Art.font, Vector2(0, 30), b.region.name, HORIZONTAL_ALIGNMENT_CENTER, ci.size.x, 26, Color("4a2c12"))
		ci.draw_string(Art.font, Vector2(0, 64), "Úroveň %d   ·   Zabito %d   ·   Zlato %d" % [b.level, b.kills, b.gold_run], HORIZONTAL_ALIGNMENT_CENTER, ci.size.x, 19, Color("6b4a2a"))
		var side := "vlevo" if bool(Game.setting("left_handed")) else "vpravo"
		ci.draw_string(Art.font, Vector2(0, 94), "Táhni prstem kdekoli, úskok a hrom jsou " + side, HORIZONTAL_ALIGNMENT_CENTER, ci.size.x, 16, Color("8a6a4a"))
	board.add_child(info)
	var y := 180.0
	var cont := CCButton.make("Pokračovat", Art.BTN_GREEN, Vector2(320, 74), 30)
	cont.position = Vector2((bw - 320) * 0.5, y)
	cont.pressed.connect(b.resume_game)
	board.add_child(cont)
	var st := CCButton.make("Nastavení", Art.BTN_BLUE, Vector2(320, 64), 24)
	st.icon_key = "ui:gear"
	st.icon_scale = 0.42
	st.position = Vector2((bw - 320) * 0.5, y + 86)
	st.pressed.connect(show_settings)
	board.add_child(st)
	var quit := CCButton.make("Vzdát se", Art.BTN_RED, Vector2(320, 64), 24)
	quit.position = Vector2((bw - 320) * 0.5, y + 162)
	quit.pressed.connect(func():
		b.lose())
	board.add_child(quit)


func show_settings() -> void:
	_clear()
	var board := SettingsBoard.make(false)
	board.size.y = minf(board.size.y, size.y - 16)
	board.position = (size - board.size) * 0.5
	board.back_pressed.connect(show_pause)
	content.add_child(board)
	_pop(board)


# ---------------------------------------------------------------- výhra a prohra

func show_win(stars: int, gold: int, first: bool) -> void:
	_clear()
	var all := Game.all_conquered()
	_title("KRAJ DOBYT!", Color("6fcf2f"), 20.0, b.region.name)
	var st := Painter.new()
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st.size = Vector2(size.x, 200)
	st.position = Vector2(0, 150)
	var labels := ["Kraj dobyt", "Aspoň 50 % životů", "Boss do 60 s"]
	st.fn = func(ci: Control) -> void:
		var cx := ci.size.x * 0.5
		for i in 3:
			var c := Vector2(cx + (i - 1) * 150, 70 - (18 if i == 1 else 0))
			var r := 54.0 if i == 1 else 46.0
			Art.icon_star(ci, c, r, i < stars)
			Art.text(ci, c + Vector2(0, r + 34), labels[i], 17, Color.WHITE if i < stars else Color(1, 1, 1, 0.5), 5)
	content.add_child(st)
	_pop(st, 0.15)
	var gp := Painter.new()
	gp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gp.size = Vector2(size.x, 70)
	gp.position = Vector2(0, 370)
	gp.fn = func(ci: Control) -> void:
		var cx := ci.size.x * 0.5
		var r := Rect2(cx - 150, 6, 300, 52)
		Art.safe_poly(ci, Art.rrect(r, 26), Color(0, 0, 0, 0.4))
		Art.icon_coin(ci, Vector2(cx - 112, 32), 20)
		Art.text(ci, Vector2(cx + 14, 44), "+%d zlata" % gold, 30, Color("ffd23f"), 8)
	content.add_child(gp)
	_pop(gp, 0.35)
	var txt := "Odemkly se sousední kraje!" if first and not all else ("Celé Česko je tvoje!" if all else "")
	if txt != "":
		var tp := Painter.new()
		tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tp.size = Vector2(size.x, 40)
		tp.position = Vector2(0, 446)
		tp.fn = func(ci: Control) -> void:
			Art.text(ci, Vector2(ci.size.x * 0.5, 28), txt, 24, Color("bfffa8"), 6)
		content.add_child(tp)
	var cont := CCButton.make("Pokračovat", Art.BTN_GREEN, Vector2(320, 80), 32)
	cont.position = Vector2((size.x - 320) * 0.5, size.y - 120)
	cont.pressed.connect(func(): b.leave("ending" if all and first else "map"))
	content.add_child(cont)
	_pop(cont, 0.5)


func show_lose(gold: int) -> void:
	_clear()
	_title("PORÁŽKA", Color("d7262c"), 40.0, b.region.name + " zatím odolal…")
	var bw := 520.0
	var board := Board.new()
	board.size = Vector2(bw, 250)
	board.position = Vector2((size.x - bw) * 0.5, 200)
	content.add_child(board)
	_pop(board, 0.1)
	var info := Painter.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size = Vector2(bw, 150)
	info.position = Vector2(0, 26)
	var tl := b.time_left()
	info.fn = func(ci: Control) -> void:
		var lines := [
			"Dosažená úroveň: %d" % b.level,
			"Poražení nepřátelé: %d" % b.kills,
			("Zbývalo přežít: %d:%02d" % [int(tl) / 60, int(tl) % 60]) if b.boss == null else "Boss měl ještě %d %% životů" % int(100.0 * maxf(0.0, b.boss.hp) / b.boss.max_hp),
		]
		for i in lines.size():
			ci.draw_string(Art.font, Vector2(0, 30 + i * 34), lines[i], HORIZONTAL_ALIGNMENT_CENTER, ci.size.x, 22, Color("4a2c12"))
		var gtxt := "Získané zlato: %d" % gold
		var gw := Art.text_width(gtxt, 22)
		Art.icon_coin(ci, Vector2(ci.size.x * 0.5 - gw * 0.5 - 22, 132), 15)
		ci.draw_string(Art.font, Vector2(0, 140), gtxt, HORIZONTAL_ALIGNMENT_CENTER, ci.size.x, 22, Color("8a5a00"))
	board.add_child(info)
	var retry := CCButton.make("Zkusit znovu", Art.BTN_GREEN, Vector2(270, 76), 28)
	retry.position = Vector2(size.x * 0.5 - 290, size.y - 116)
	retry.pressed.connect(func(): b.leave("retry"))
	content.add_child(retry)
	var mp := CCButton.make("Na mapu", Art.BTN_YELLOW, Vector2(270, 76), 28)
	mp.position = Vector2(size.x * 0.5 + 20, size.y - 116)
	mp.pressed.connect(func(): b.leave("map"))
	content.add_child(mp)
	_pop(retry, 0.3)
	_pop(mp, 0.36)
