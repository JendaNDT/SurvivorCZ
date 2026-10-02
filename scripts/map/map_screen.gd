extends Control
class_name MapScreen
## Mapa Česka se 14 kraji. Kraj se dá napadnout, když sousedí s už dobytým
## (na začátku jen Karlovarský). Ťuknutím na kraj se otevře jeho karta.

signal attack(id: String)
signal ending

var open_on_start := ""
var water: ColorRect
var root: Node2D
var land: MapArt.MapLand
var details: MapArt.MapDetails
var live: MapArt.MapLive
var clouds: MapArt.MapClouds
var topbar: MapUI.TopBar
var daily_bt: CCButton
var heat_bar: MapUI.HeatBar
var popup_layer: Control
var selected := ""
var map_scale := 1.0
var time_s := 0.0
var outline_all := PackedVector2Array()
var fresh: Array = []
var shapes := {}

const MAP_SIZE := Vector2(1000, 574)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for id in Regions.ORDER:
		shapes[id] = Regions.shape(id)
	outline_all = _union_outline()
	water = ColorRect.new()
	water.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wm := ShaderMaterial.new()
	wm.shader = load("res://shaders/water.gdshader")
	water.material = wm
	water.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(water)
	root = Node2D.new()
	add_child(root)
	var under := MapArt.MapUnder.new()
	under.m = self
	root.add_child(under)
	land = MapArt.MapLand.new()
	land.m = self
	var lm := ShaderMaterial.new()
	lm.shader = load("res://shaders/map_land.gdshader")
	land.material = lm
	root.add_child(land)
	details = MapArt.MapDetails.new()
	details.m = self
	root.add_child(details)
	live = MapArt.MapLive.new()
	live.m = self
	root.add_child(live)
	clouds = MapArt.MapClouds.new()
	clouds.m = self
	add_child(clouds)
	topbar = MapUI.TopBar.new()
	topbar.m = self
	add_child(topbar)
	# hra po dohrání (M9): denní výzva vlevo dole, volič žáru vpravo dole
	daily_bt = CCButton.make("Denní výzva", Art.BTN_BLUE, Vector2(230, 66), 24)
	daily_bt.icon_key = "ui:swords"
	daily_bt.icon_scale = 0.42
	daily_bt.pressed.connect(func(): show_daily())
	add_child(daily_bt)
	heat_bar = MapUI.HeatBar.new()
	heat_bar.m = self
	add_child(heat_bar)
	popup_layer = Control.new()
	popup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(popup_layer)
	resized.connect(_layout)
	await _bake()
	_layout()
	Sfx.start_music("map")
	fresh = Game.fresh_unlocks.duplicate()
	Game.fresh_unlocks.clear()
	if not fresh.is_empty():
		Sfx.play("chest")
		var names := []
		for id in fresh:
			names.append(Regions.DATA[id].short)
		_toast("Odemčeno: " + ", ".join(names))
	# podmínky mohly být splněné už ve starším uložení
	Game.check_hero_unlocks()
	if not Game.fresh_heroes.is_empty():
		var hn := []
		for hid in Game.fresh_heroes:
			hn.append(HeroDefs.get_hero(hid).name)
		Game.fresh_heroes.clear()
		_hero_unlocked_toast("Nový hrdina: " + ", ".join(hn) + "!")
	if not Game.crash_report.is_empty():
		var rep: Dictionary = Game.crash_report
		Game.crash_report = {}
		rep["android"] = CrashInfo.describe(CrashInfo.last_exit())
		Game.note("hlášení o pádu: " + " | ".join(rep["android"]))
		show_crash_report(rep)
	elif not Game.data.get("intro_seen", false):
		show_intro()
	elif Game.perf_offer > 0.0:
		show_perf_offer(Game.perf_offer)
		Game.perf_offer = 0.0
	elif open_on_start == "shop":
		show_shop()
	elif open_on_start == "heroes":
		show_heroes()
	elif open_on_start == "daily":
		show_daily()
	elif open_on_start == "settings":
		show_settings()
	elif open_on_start == "perf":
		show_perf_offer(31.0)
	elif open_on_start == "quit":
		show_quit_confirm()
	elif open_on_start == "crash":
		var tomb := {"signal": "SIGSEGV", "code": "SEGV_MAPERR", "fault": 0x10, "abort": "", "causes": ["null pointer dereference"], "thread": "AudioThread", "frames": ["#00 libgodot_android.so +0x1a2b3c", "#01 libgodot_android.so +0x1a2000", "#02 libc.so +0x55aa"]}
		var demo := CrashInfo.describe({"reason": 5, "status": 11, "desc": "crash", "pss_mb": 212, "tomb": tomb})
		show_crash_report({"screen": "mapa", "tex_mb": 32.6, "nodes": 38, "fps": 120, "uptime": 4, "version": "1.2.4", "quality": "high", "android": demo, "log": ["[0 s] start, verze 1.2.4", "[1 s] obrazovka: mapa", "[1 s] pečení 6 kreseb (map:mountain…)", "[1 s] pečení hotovo"]})
	elif open_on_start.begins_with("region:"):
		select(open_on_start.substr(7))
	elif Game.all_conquered() and not Game.data.get("ending_seen", false):
		Game.data.ending_seen = true
		Game.save_game()
		ending.emit()


func _bake() -> void:
	var jobs := []
	jobs.append({"key": "map:mountain", "size": Vector2(90, 70), "fn": MapArt.mountain, "origin": Vector2(0.5, 0.85)})
	jobs.append({"key": "map:tree", "size": Vector2(40, 50), "fn": MapArt.tree, "origin": Vector2(0.5, 0.85)})
	jobs.append({"key": "map:pine", "size": Vector2(36, 54), "fn": MapArt.pine, "origin": Vector2(0.5, 0.85)})
	jobs.append({"key": "map:castle", "size": Vector2(90, 90), "fn": MapArt.castle, "origin": Vector2(0.5, 0.8)})
	for hid in HeroDefs.ORDER:
		jobs.append({"key": "hero:%s:0" % hid, "size": HeroArt.size_of(hid), "fn": func(ci, tt): HeroArt.draw(ci, tt, hid), "t": 0.0})
	jobs.append({"key": "map:arrow", "size": Vector2(50, 50), "fn": MapArt.arrow})
	await Baker.bake_many(jobs)


func _layout() -> void:
	var vs := size
	if daily_bt:
		daily_bt.position = Vector2(20, vs.y - 84)
		daily_bt.badge = "" if Game.daily_won_today() else "!"
		heat_bar.position = Vector2(vs.x - heat_bar.size.x - 20, vs.y - 84)
		heat_bar.visible = Game.heat_unlocked() > 0
		heat_bar.refresh()
	var avail := Rect2(30, 92, vs.x - 60, vs.y - 112)
	map_scale = minf(avail.size.x / MAP_SIZE.x, avail.size.y / MAP_SIZE.y)
	var msz := MAP_SIZE * map_scale
	root.scale = Vector2(map_scale, map_scale)
	root.position = avail.position + (avail.size - msz) * 0.5
	for n in [land, details, live]:
		n.queue_redraw()


func refresh() -> void:
	land.queue_redraw()
	details.queue_redraw()
	topbar.queue_redraw()


func _process(delta: float) -> void:
	time_s += delta
	(water.material as ShaderMaterial).set_shader_parameter("time_s", time_s)


func _union_outline() -> PackedVector2Array:
	var acc: PackedVector2Array = shapes["STC"]
	for id in Regions.ORDER:
		if id == "STC" or id == "PHA":
			continue
		var res := Geometry2D.merge_polygons(acc, Art.grow(shapes[id], 0.6))
		var best := PackedVector2Array()
		for p in res:
			if not Geometry2D.is_polygon_clockwise(p) and p.size() > best.size():
				best = p
		if best.is_empty() and not res.is_empty():
			best = res[0]
		acc = best
	return acc


func state_of(id: String) -> String:
	if Game.is_conquered(id):
		return "conquered"
	if Game.is_available(id):
		return "available"
	return "locked"


func to_map(screen_pos: Vector2) -> Vector2:
	return (screen_pos - root.position) / map_scale


func region_at(screen_pos: Vector2) -> String:
	var p := to_map(screen_pos)
	for id in Regions.ORDER:
		if Regions.label_pos(id).distance_to(p) < 26.0:
			return id
	if Geometry2D.is_point_in_polygon(p, shapes["PHA"]):
		return "PHA"
	for id in Regions.ORDER:
		if Geometry2D.is_point_in_polygon(p, shapes[id]):
			return id
	return ""


func _gui_input(event: InputEvent) -> void:
	if popup_layer.get_child_count() > 0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id := region_at(event.position)
		if id != "":
			select(id)


func select(id: String) -> void:
	Game.note("kraj " + id)
	selected = id
	Sfx.play("click", -4.0)
	live.queue_redraw()
	show_region(id)


# ---------------------------------------------------------------- okna

func _modal() -> Control:
	for c in popup_layer.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_layer.add_child(dim)
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.18)
	return dim


func close_popup() -> void:
	selected = ""
	for c in popup_layer.get_children():
		c.queue_free()
	live.queue_redraw()


func _pop(c: Control, delay: float = 0.0) -> void:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2(0.5, 0.5)
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(c, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(c, "modulate:a", 1.0, 0.12)


func _close_button(parent: Control, pos: Vector2) -> void:
	var x := CCButton.make("✕", Art.BTN_RED, Vector2(56, 56), 26)
	x.radius = 28.0
	x.position = pos
	x.pressed.connect(close_popup)
	parent.add_child(x)


func show_region(id: String) -> void:
	var dim := _modal()
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			close_popup())
	var r := Regions.get_region(id)
	var st := state_of(id)
	var board := MapUI.RegionCard.new()
	board.m = self
	board.region = r
	board.st = st
	board.size = Vector2(minf(700.0, size.x - 40), minf(480.0, size.y - 24))
	board.position = (size - board.size) * 0.5 + Vector2(0, 8)
	popup_layer.add_child(board)
	_pop(board)
	_close_button(board, Vector2(board.size.x - 44, -14))
	var bt: CCButton
	if st == "locked":
		bt = CCButton.make("Zamčeno", Art.BTN_GREY, Vector2(300, 78), 30)
		bt.icon_key = "ui:lock"
		bt.icon_scale = 0.5
		bt.disabled = true
	elif st == "conquered":
		bt = CCButton.make("Znovu do boje", Art.BTN_YELLOW, Vector2(320, 78), 28)
		bt.icon_key = "ui:swords"
		bt.icon_scale = 0.5
	else:
		bt = CCButton.make("ÚTOK!", Art.BTN_GREEN, Vector2(300, 82), 38)
		bt.icon_key = "ui:swords"
		bt.icon_scale = 0.55
	bt.position = Vector2(maxf((board.size.x - bt.size.x) * 0.5, 226.0 if st != "locked" else 0.0), board.size.y - bt.size.y - 12)
	bt.pressed.connect(func():
		Sfx.play("warn", -6.0)
		attack.emit(id))
	board.add_child(bt)
	# hrdina do boje (M8)
	if st != "locked":
		var hb := CCButton.make("Změnit", Color("b25cff"), Vector2(104, 48), 20)
		hb.position = Vector2(88, board.size.y - 62)
		hb.pressed.connect(func(): show_heroes.call_deferred(id))
		board.add_child(hb)
	# portréty nepřátel a bosse se upečou na požádání
	var jobs := []
	for eid in r.enemies:
		jobs.append({"key": "e:%s:0" % eid, "size": Vector2.ONE * EnemyDefs.get_enemy(eid).size, "fn": func(ci, tt): EnemyArt.draw(ci, eid, tt)})
	var bid: String = r.boss
	jobs.append({"key": "b:%s:0" % bid, "size": BossArt.SIZE, "fn": func(ci, tt): BossArt.draw(ci, bid, tt)})
	await Baker.bake_many(jobs)
	if is_instance_valid(board):
		board.queue_redraw()


func show_shop() -> void:
	Game.note("zbrojnice")
	var dim := _modal()
	var shop := MapUI.ShopBoard.new()
	shop.m = self
	shop.size = Vector2(minf(1080.0, size.x - 30), minf(560.0, size.y - 20))
	shop.position = (size - shop.size) * 0.5 + Vector2(0, 6)
	popup_layer.add_child(shop)
	shop.build()
	_pop(shop)
	_close_button(shop, Vector2(shop.size.x - 44, -14))


## Deska hrdinů. Když se otevřela z karty kraje, po zavření se k ní vrátí.
func show_heroes(back_to: String = "") -> void:
	Game.note("hrdinové")
	Game.mark_heroes_seen()
	_modal()
	var hb := MapUI.HeroBoard.new()
	hb.m = self
	hb.size = Vector2(minf(1080.0, size.x - 30), minf(580.0, size.y - 16))
	hb.position = (size - hb.size) * 0.5 + Vector2(0, 6)
	popup_layer.add_child(hb)
	hb.build()
	_pop(hb)
	var x := CCButton.make("✕", Art.BTN_RED, Vector2(56, 56), 26)
	x.radius = 28.0
	x.position = Vector2(hb.size.x - 44, -14)
	x.pressed.connect(func():
		if back_to != "":
			select.call_deferred(back_to)
		else:
			close_popup())
	hb.add_child(x)
	topbar.queue_redraw()


## Denní výzva: kraj, hrdina a dva modifikátory podle data.
func show_daily() -> void:
	Game.note("denní výzva")
	var dim := _modal()
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			close_popup())
	var info := Game.daily_info(Game.today())
	var board := MapUI.DailyBoard.new()
	board.m = self
	board.info = info
	board.size = Vector2(minf(780.0, size.x - 40), minf(500.0, size.y - 24))
	board.position = (size - board.size) * 0.5 + Vector2(0, 8)
	popup_layer.add_child(board)
	_pop(board)
	_close_button(board, Vector2(board.size.x - 44, -14))
	var won := Game.daily_won_today()
	var bt := CCButton.make("Hrát znovu" if won else "DO BOJE!", Art.BTN_GREEN, Vector2(300, 80), 30 if won else 36)
	bt.icon_key = "ui:swords"
	bt.icon_scale = 0.5
	bt.position = Vector2((board.size.x - 300) * 0.5, board.size.y - 92)
	bt.pressed.connect(func():
		Sfx.play("warn", -6.0)
		Game.daily_run = info
		attack.emit(str(info.region)))
	board.add_child(bt)
	# kresby kraje pro náhled
	var r := Regions.get_region(str(info.region))
	var bid: String = r.boss
	await Baker.bake_many([{"key": "b:%s:0" % bid, "size": BossArt.SIZE, "fn": func(ci, tt): BossArt.draw(ci, bid, tt)}])
	if is_instance_valid(board):
		board.queue_redraw()


func _hero_unlocked_toast(text: String) -> void:
	await get_tree().create_timer(1.2).timeout
	Sfx.play("levelup")
	_toast(text)
	topbar.queue_redraw()


func show_settings() -> void:
	Game.note("nastavení")
	_modal()
	var board := SettingsBoard.make(true)
	board.size.y = minf(board.size.y, size.y - 16)
	board.position = (size - board.size) * 0.5 + Vector2(0, 6)
	board.help_pressed.connect(show_intro)
	board.reset_done.connect(func():
		close_popup()
		refresh())
	popup_layer.add_child(board)
	_pop(board)
	_close_button(board, Vector2(board.size.x - 44, -14))


## Nabídka úsporné grafiky, když se první bitva sekala.
func show_perf_offer(fps: float) -> void:
	_modal()
	var board := MapUI.Board.new()
	board.title = "SEKÁ SE TO?"
	board.ribbon_col = Color("ff9a2a")
	board.size = Vector2(560, 320)
	board.position = (size - board.size) * 0.5
	popup_layer.add_child(board)
	_pop(board)
	var info := Label.new()
	info.text = "V bitvě běžela hra jen na %d snímků za sekundu.\nÚsporná grafika ubere efekty a nepřátele naráz\na hra poběží plynuleji. Změníš to i v nastavení." % roundi(fps)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", Color("4a2c12"))
	info.add_theme_constant_override("outline_size", 0)
	info.add_theme_constant_override("shadow_outline_size", 0)
	info.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	info.add_theme_font_size_override("font_size", 21)
	info.position = Vector2(20, 66)
	info.size = Vector2(520, 120)
	board.add_child(info)
	var yes := CCButton.make("Zapnout", Art.BTN_GREEN, Vector2(230, 70), 28)
	yes.position = Vector2(board.size.x * 0.5 - 246, board.size.y - 100)
	yes.pressed.connect(func():
		Game.set_setting("quality", "low")
		Game.apply_quality()
		close_popup())
	board.add_child(yes)
	var no := CCButton.make("Ne, díky", Art.BTN_GREY, Vector2(230, 70), 28)
	no.position = Vector2(board.size.x * 0.5 + 16, board.size.y - 100)
	no.pressed.connect(close_popup)
	board.add_child(no)


func show_intro() -> void:
	_modal()
	var intro := MapUI.IntroBoard.new()
	intro.m = self
	intro.size = Vector2(minf(820.0, size.x - 40), minf(560.0, size.y - 20))
	intro.position = (size - intro.size) * 0.5
	popup_layer.add_child(intro)
	_pop(intro)
	var play := CCButton.make("HRÁT", Art.BTN_GREEN, Vector2(280, 84), 40)
	play.position = Vector2((intro.size.x - 280) * 0.5, intro.size.y - 108)
	play.pressed.connect(func():
		Game.data.intro_seen = true
		Game.save_game()
		close_popup())
	intro.add_child(play)


## Dotaz před ukončením hry (tlačítko nebo gesto Zpět na mapě).
func show_quit_confirm() -> void:
	_modal()
	var board := MapUI.Board.new()
	board.title = "UKONČIT HRU?"
	board.ribbon_col = Color("3fa8ff")
	board.size = Vector2(540, 270)
	board.position = (size - board.size) * 0.5
	popup_layer.add_child(board)
	_pop(board)
	var info := Label.new()
	info.text = "Postup je uložený, příště navážeš tam, kde hra skončila."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", Color("4a2c12"))
	info.add_theme_constant_override("outline_size", 0)
	info.add_theme_constant_override("shadow_outline_size", 0)
	info.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	info.add_theme_font_size_override("font_size", 21)
	info.position = Vector2(30, 70)
	info.size = Vector2(480, 70)
	board.add_child(info)
	var stay := CCButton.make("Hrát dál", Art.BTN_GREEN, Vector2(220, 70), 28)
	stay.position = Vector2(board.size.x * 0.5 - 236, board.size.y - 100)
	stay.pressed.connect(close_popup)
	board.add_child(stay)
	var quit := CCButton.make("Ukončit", Art.BTN_RED, Vector2(220, 70), 28)
	quit.position = Vector2(board.size.x * 0.5 + 16, board.size.y - 100)
	quit.pressed.connect(func():
		Game.session_end()
		get_tree().quit())
	board.add_child(quit)


## Hra minule spadla: ukáž, kde se to stalo, a nabídni zkopírování hlášení.
func show_crash_report(r: Dictionary) -> void:
	_modal()
	var board := MapUI.Board.new()
	board.title = "HRA MINULE SPADLA"
	board.ribbon_col = Color("d7262c")
	board.size = Vector2(minf(900.0, size.x - 30), minf(560.0, size.y - 16))
	board.position = (size - board.size) * 0.5
	popup_layer.add_child(board)
	_pop(board)
	var where := "mapa"
	if r.get("screen", "") == "bitva":
		var rid: String = r.get("region", "")
		where = "bitva, %s – %s" % [Regions.DATA[rid].short if Regions.DATA.has(rid) else rid, r.get("battle", "")]
	elif r.get("screen", "") != "":
		where = str(r.get("screen"))
	var lines := [
		"Kde: " + where,
		"Textury %s MB, uzlů %d, FPS %d, běžela %d s · verze %s · grafika %s" % [r.get("tex_mb", "?"), int(r.get("nodes", 0)), int(r.get("fps", 0)), int(r.get("uptime", 0)), r.get("version", "?"), "úsporná" if r.get("quality", "") == "low" else "vysoká"],
	]
	lines.append_array(r.get("android", []))
	lines.append("Poslední záznamy:")
	for l in r.get("log", []):
		lines.append("  " + str(l))
	var full := "Dobyj Česko! – hlášení o pádu\n" + "\n".join(lines)
	var head := Label.new()
	head.text = "Promiň, hra se nečekaně ukončila. Zkopíruj hlášení a pošli mi ho."
	_style_label(head, 19)
	head.position = Vector2(30, 58)
	head.size = Vector2(board.size.x - 60, 30)
	board.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 96)
	scroll.size = Vector2(board.size.x - 60, board.size.y - 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board.add_child(scroll)
	var info := Label.new()
	info.text = "\n".join(lines)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(scroll.size.x - 16, 0)
	_style_label(info, 16)
	scroll.add_child(info)
	var copy := CCButton.make("Zkopírovat", Art.BTN_BLUE, Vector2(240, 70), 26)
	copy.position = Vector2(board.size.x * 0.5 - 256, board.size.y - 96)
	copy.pressed.connect(func():
		DisplayServer.clipboard_set(full)
		copy.caption = "Zkopírováno"
		copy.queue_redraw())
	board.add_child(copy)
	var ok := CCButton.make("Rozumím", Art.BTN_GREEN, Vector2(240, 70), 26)
	ok.position = Vector2(board.size.x * 0.5 + 16, board.size.y - 96)
	ok.pressed.connect(close_popup)
	board.add_child(ok)


func _style_label(l: Label, fs: int) -> void:
	l.add_theme_color_override("font_color", Color("4a2c12"))
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("shadow_outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	l.add_theme_font_size_override("font_size", fs)


## Krátké oznámení dole na mapě.
func _toast(text: String) -> void:
	var p := MapUI.Toast.new()
	p.text = text
	p.size = Vector2(size.x, 70)
	p.position = Vector2(0, size.y - 90)
	add_child(p)
