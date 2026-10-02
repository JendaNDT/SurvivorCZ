extends Node
class_name Main
## Kořen hry: přepíná mezi mapou Česka, bitvou a závěrem. Přechody zakrývají mraky.
##
## Vývojářské parametry (za `--` na příkazové řádce):
##   --battle=KVK      rovnou spustí bitvu o kraj
##   --tier=N          obtížnost jako po N dobytých krajích
##   --autoplay        hraje počítač (test)
##   --shots=cesta     ukládá snímky obrazovky
##   --shot-times=2,8  kdy (v sekundách) snímky pořídit, pak hra skončí
##   --screen=map|shop|settings|perf|heroes|ending   rovnou otevře danou obrazovku
##   --quality=low, --show-fps, --left-handed   nastavení jen pro toto spuštění
##   --bench           v bitvě drží plný počet nepřátel a vypíše průměrné FPS
##   --dev-script=res://x.gd   přidá uzel s vývojářským skriptem (např. sonda zvuku)
##   --soak=N          zátěžový test: N bitev za sebou (mapa → bitva → mapa), po každé vypíše paměť
##   --taps=640,300@3;100,200>400,200@4   ťuknutí (x,y@čas) a tažení (a>b@čas) pro test ovládání

var current: Node
var trans: CloudTransition
var shots_prefix := ""
var shot_times: Array = []
var shot_clock := 0.0
var loading: Control
var taps: Array = []
var tap_clock := 0.0
var soak := 0
var soak_i := 0


static func icon_jobs() -> Array:
	var jobs := []
	var ids: Array = Upgrades.WEAPONS.keys() + Upgrades.EVOLUTIONS.keys() + Upgrades.PASSIVES.keys() + ["reroll", "coin", "srdce_zlate", "hero"]
	for id in ids:
		jobs.append({"key": "icon:" + id, "size": IconArt.SIZE, "fn": func(ci, t): IconArt.draw(ci, id, t)})
	# portréty hrdinů (M8): hlava a ramena, Horymír i se Šemíkem
	for hid in HeroDefs.ORDER:
		var k := 0.36 if hid == "horymir" else 0.5
		var off := Vector2(-4, 26) if hid == "horymir" else Vector2(0, 14)
		jobs.append({"key": "icon:hero_" + hid, "size": IconArt.SIZE, "fn": func(ci, t):
			ci.draw_set_transform(off, 0, Vector2(k, k))
			HeroArt.draw(ci, t, hid)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)})
	var ui := {
		"boot": func(ci, _t): Art.icon_boot(ci, Vector2(6, 0), 26),
		"bolt": func(ci, _t): Art.icon_bolt(ci, Vector2.ZERO, 28),
		"pause": func(ci, _t): Art.icon_pause(ci, Vector2.ZERO, 26),
		"lock": func(ci, _t): Art.icon_lock(ci, Vector2(0, 4), 26),
		"swords": func(ci, _t): Art.icon_swords(ci, Vector2.ZERO, 26),
		"gear": func(ci, _t): Art.icon_gear(ci, Vector2.ZERO, 26),
		"hammer": func(ci, _t): Art.icon_hammer(ci, Vector2.ZERO, 28),
		"star": func(ci, _t): Art.icon_star(ci, Vector2.ZERO, 30, true),
		"star_off": func(ci, _t): Art.icon_star(ci, Vector2.ZERO, 30, false),
		"crown": func(ci, _t): Art.icon_crown(ci, Vector2(0, 6), 30),
		"flag": func(ci, _t): Art.icon_flag(ci, Vector2(-12, 34), 36),
	}
	for k in ui.keys():
		jobs.append({"key": "ui:" + k, "size": Vector2(80, 80), "fn": ui[k]})
	return jobs


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	trans = CloudTransition.new()
	add_child(trans)
	_show_loading()
	var args := OS.get_cmdline_user_args()
	var battle_id := ""
	var screen := ""
	for a in args:
		if a.begins_with("--battle="):
			battle_id = a.substr(9)
		elif a.begins_with("--shots="):
			shots_prefix = a.substr(8)
		elif a.begins_with("--shot-times="):
			for t in a.substr(13).split(","):
				shot_times.append(float(t))
		elif a.begins_with("--dev-script="):
			var probe := Node.new()
			probe.set_script(load(a.substr(13)))
			probe.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(probe)
		elif a.begins_with("--soak="):
			soak = int(a.substr(7))
		elif a.begins_with("--taps="):
			for item in a.substr(7).split(";"):
				var parts := item.split("@")
				var pts := parts[0].split(">")
				var p0 := Vector2(float(pts[0].split(",")[0]), float(pts[0].split(",")[1]))
				var p1 := p0 if pts.size() < 2 else Vector2(float(pts[1].split(",")[0]), float(pts[1].split(",")[1]))
				taps.append({"t": float(parts[1]), "a": p0, "b": p1})
		elif a.begins_with("--screen="):
			screen = a.substr(9)
		elif a == "--reset":
			Game.reset()
		elif a == "--skip-intro":
			Game.data.intro_seen = true
		elif a == "--unlock-heroes":
			Game.data.heroes.unlocked = HeroDefs.ORDER.duplicate()
		elif a.begins_with("--heat="):
			Game.heat_override = int(a.substr(7))
		elif a.begins_with("--daily="):
			Game.daily_override = a.substr(8)
		elif a.begins_with("--gold="):
			Game.data.gold = int(a.substr(7))
		elif a.begins_with("--meta="):
			for id in Upgrades.META.keys():
				Game.data.upgrades[id] = mini(int(a.substr(7)), Upgrades.META[id].max)
		elif a.begins_with("--quality="):
			Game.data.settings.quality = a.substr(10)
			Game.apply_quality()
		elif a == "--show-fps":
			Game.data.settings.show_fps = true
		elif a == "--left-handed":
			Game.data.settings.left_handed = true
		elif a.begins_with("--conquer="):
			for id in a.substr(10).split(","):
				if id != "":
					Game.data.conquered[id] = 3
	await Baker.bake_many(icon_jobs())
	loading.queue_free()
	if soak > 0:
		show_map(false)
	elif "--daily-run" in args:
		Game.daily_run = Game.daily_info(Game.today())
		start_battle(str(Game.daily_run.region), false)
	elif battle_id != "":
		start_battle(battle_id, false)
	elif screen in ["shop", "settings", "perf", "crash", "quit", "heroes", "daily"]:
		show_map(false, screen)
	elif screen.begins_with("region:"):
		show_map(false, screen)
	elif screen == "ending":
		show_ending(false)
	else:
		show_map(false)


func _show_loading() -> void:
	loading = Control.new()
	loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	var lbl := Label.new()
	lbl.text = "Načítám…"
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.position -= Vector2(80, 30)
	loading.add_child(lbl)
	var cl := CanvasLayer.new()
	cl.add_child(loading)
	add_child(cl)


## Tlačítko Zpět na Androidu: v bitvě pauza, na mapě zavře okno, jinak ukončí hru.
func _notification(what: int) -> void:
	if current == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# telefon přešel do pozadí: bitvu pozastav
		if current is Battle and shots_prefix == "" and not (current as Battle).autoplay:
			(current as Battle).pause_game()
		return
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if current is Battle:
		var b := current as Battle
		if b.state == Battle.State.PAUSE:
			b.resume_game()
		else:
			b.pause_game()
	elif current is MapScreen:
		# Zpět (i gesto od okraje displeje) hru neukončí hned, nejdřív se zeptá.
		var m := current as MapScreen
		if m.popup_layer.get_child_count() > 0:
			m.close_popup()
		else:
			m.show_quit_confirm()
	elif current is EndingScreen:
		show_map()


func _process(delta: float) -> void:
	if not taps.is_empty():
		tap_clock += delta / maxf(Engine.time_scale, 0.01)
		if tap_clock >= taps[0].t:
			_tap(taps.pop_front())
	if shots_prefix == "" or shot_times.is_empty():
		return
	shot_clock += delta / maxf(Engine.time_scale, 0.01)
	if shot_clock >= shot_times[0]:
		var t: float = shot_times.pop_front()
		var img := get_viewport().get_texture().get_image()
		# celé sekundy: s_010.png, desetiny: s_010.5.png
		var stamp := "%03d" % int(t) if is_equal_approx(t, roundf(t)) else "%05.1f" % t
		img.save_png("%s_%s.png" % [shots_prefix, stamp])
		if shot_times.is_empty():
			get_tree().quit()


## Vývojářský test ovládání: stisk, tažení a puštění „prstu“ (myš se převede i na dotyk).
func _tap(step: Dictionary) -> void:
	var a: Vector2 = step.a
	var b: Vector2 = step.b
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = a
	press.global_position = a
	Input.parse_input_event(press)
	for i in 8:
		await get_tree().process_frame
		if a != b:
			var mv := InputEventMouseMotion.new()
			mv.button_mask = MOUSE_BUTTON_MASK_LEFT
			mv.position = a.lerp(b, (i + 1) / 8.0)
			mv.global_position = mv.position
			mv.relative = (b - a) / 8.0
			Input.parse_input_event(mv)
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.position = b
	rel.global_position = b
	Input.parse_input_event(rel)


func _swap(node: Node, animate: bool) -> void:
	if animate:
		await trans.cover()
	if current and is_instance_valid(current):
		current.queue_free()
	get_tree().paused = false
	current = node
	add_child(node)
	move_child(trans, -1)
	if animate:
		trans.reveal()


func show_map(animate: bool = true, open: String = "") -> void:
	Game.crumb({"screen": "mapa", "region": "", "battle": ""})
	var m := MapScreen.new()
	m.open_on_start = open
	m.attack.connect(func(id): start_battle(id))
	m.ending.connect(func(): show_ending())
	_swap(m, animate)
	if soak > 0:
		_soak_next()


func start_battle(id: String, animate: bool = true) -> void:
	Game.crumb({"screen": "bitva", "region": id, "battle": "načítání"})
	var b := Battle.new()
	b.region_id = id
	b.finished.connect(_on_battle_finished.bind(id))
	_swap(b, animate)


func _soak_next() -> void:
	await get_tree().create_timer(2.5).timeout
	print("SOAK %d: paměť %.1f MB, textury %.1f MB, uzlů %d, objektů %d, sirotků %d, cache %d" % [soak_i, OS.get_static_memory_usage() / 1048576.0, Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), Baker.cache.size()])
	if soak_i >= soak:
		get_tree().quit()
		return
	var id: String = Regions.ORDER[soak_i % Regions.ORDER.size()]
	soak_i += 1
	start_battle(id)


func _on_battle_finished(action: String, id: String) -> void:
	match action:
		"retry":
			start_battle(id)
		"ending":
			show_ending()
		_:
			show_map()


func show_ending(animate: bool = true) -> void:
	Game.crumb({"screen": "závěr", "region": "", "battle": ""})
	var e := EndingScreen.new()
	e.done.connect(func(): show_map())
	_swap(e, animate)
