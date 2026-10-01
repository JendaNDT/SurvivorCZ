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
##   --screen=map|shop|ending   rovnou otevře danou obrazovku

var current: Node
var trans: CloudTransition
var shots_prefix := ""
var shot_times: Array = []
var shot_clock := 0.0
var loading: Control


static func icon_jobs() -> Array:
	var jobs := []
	var ids: Array = Upgrades.WEAPONS.keys() + Upgrades.EVOLUTIONS.keys() + Upgrades.PASSIVES.keys() + ["reroll", "coin", "srdce_zlate", "hero"]
	for id in ids:
		jobs.append({"key": "icon:" + id, "size": IconArt.SIZE, "fn": func(ci, t): IconArt.draw(ci, id, t)})
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
		elif a.begins_with("--screen="):
			screen = a.substr(9)
		elif a == "--reset":
			Game.reset()
		elif a == "--skip-intro":
			Game.data.intro_seen = true
		elif a.begins_with("--gold="):
			Game.data.gold = int(a.substr(7))
		elif a.begins_with("--conquer="):
			for id in a.substr(10).split(","):
				if id != "":
					Game.data.conquered[id] = 3
	await Baker.bake_many(icon_jobs())
	loading.queue_free()
	if battle_id != "":
		start_battle(battle_id, false)
	elif screen == "shop":
		show_map(false, "shop")
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
		var m := current as MapScreen
		if m.popup_layer.get_child_count() > 0:
			m.close_popup()
		else:
			get_tree().quit()
	elif current is EndingScreen:
		show_map()


func _process(delta: float) -> void:
	if shots_prefix == "" or shot_times.is_empty():
		return
	shot_clock += delta / maxf(Engine.time_scale, 0.01)
	if shot_clock >= shot_times[0]:
		var t: float = shot_times.pop_front()
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s_%03d.png" % [shots_prefix, int(t)])
		if shot_times.is_empty():
			get_tree().quit()


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
	var m := MapScreen.new()
	m.open_on_start = open
	m.attack.connect(func(id): start_battle(id))
	m.ending.connect(func(): show_ending())
	_swap(m, animate)


func start_battle(id: String, animate: bool = true) -> void:
	var b := Battle.new()
	b.region_id = id
	b.finished.connect(_on_battle_finished.bind(id))
	_swap(b, animate)


func _on_battle_finished(action: String, id: String) -> void:
	match action:
		"retry":
			start_battle(id)
		"ending":
			show_ending()
		_:
			show_map()


func show_ending(animate: bool = true) -> void:
	var e := EndingScreen.new()
	e.done.connect(func(): show_map())
	_swap(e, animate)
