extends Node
## Game – trvalý stav hry: dobyté kraje, hvězdy, zlato, vylepšení ze Zbrojnice.

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 2
const START_REGION := "KVK"
const DEFAULT_SETTINGS := {
	"music_vol": 0.8,
	"sfx_vol": 1.0,
	"vibrate": true,
	"quality": "high",
	"show_fps": false,
	"left_handed": false,
}

signal changed
signal setting_changed(key: String)

var data: Dictionary = {}
## Parametry, které si předává mapa a bitva.
var pending_region: String = ""
## Kraje, které se právě odemkly (mapa je zvýrazní).
var fresh_unlocks: Array = []
## Hrdinové odemčení v poslední bitvě (mapa je ohlásí).
var fresh_heroes: Array = []
## Hrdina jen pro toto spuštění (--hero=…), uložení nemění.
var hero_override := ""
## Hra po dohrání (M9): žár jen pro toto spuštění (--heat=N, -1 = podle uložení),
## datum denní výzvy (--daily=RRRR-MM-DD) a právě hraná denní výzva.
var heat_override := -1
var daily_override := ""
var daily_run: Dictionary = {}
## Průměrné FPS z první bitvy, když se hra sekala (mapa pak nabídne úspornou grafiku).
var perf_offer := 0.0
var _vib_until := 0


## Černá skříňka: průběžný záznam, kde hra je. Když při dalším spuštění
## záznam říká „running“, hra minule spadla a mapa ukáže, kde se to stalo.
const SESSION_PATH := "user://session.json"
var crash_report: Dictionary = {}
var crumbs := {"screen": "start"}
var _crumb_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	note("start, verze %s" % ProjectSettings.get_setting("application/config/version", ""))
	load_game()
	_check_last_session()
	apply_quality.call_deferred()


func _process(delta: float) -> void:
	_crumb_t -= delta
	if _crumb_t <= 0.0:
		_crumb_t = 5.0
		_write_session("running")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_write_session("paused")
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_write_session("running")
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_PREDELETE:
			_write_session("closed")


## Zapíše, kde hra právě je (obrazovka, kraj, čas v bitvě…).
func crumb(values: Dictionary) -> void:
	for k in values.keys():
		crumbs[k] = values[k]
	if values.has("screen"):
		note("obrazovka: %s %s" % [values.screen, values.get("region", "")])
	_write_session("running")


## Řádek do logu (user://logs/godot.log). Po pádu ukáže hlášení posledních pár řádků.
func note(text: String) -> void:
	print("[%d s] %s" % [Time.get_ticks_msec() / 1000, text])


func session_end() -> void:
	_write_session("closed")


func _write_session(state: String) -> void:
	var d := crumbs.duplicate()
	d["state"] = state
	d["version"] = str(ProjectSettings.get_setting("application/config/version", ""))
	d["uptime"] = Time.get_ticks_msec() / 1000
	d["mem_mb"] = snappedf(OS.get_static_memory_usage() / 1048576.0, 0.1)
	d["tex_mb"] = snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1)
	d["nodes"] = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	d["fps"] = Engine.get_frames_per_second()
	d["quality"] = setting("quality") if not data.is_empty() else ""
	var f := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func _check_last_session() -> void:
	if FileAccess.file_exists(SESSION_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH))
		if parsed is Dictionary and parsed.get("state", "") == "running":
			crash_report = parsed
			crash_report["log"] = _last_log_lines()
			add_stat("crashes", 1)
			save_game()
	_write_session("running")


## Posledních pár řádků logu z minulého běhu (Godot při startu starý log přejmenuje).
func _last_log_lines() -> Array:
	var dir := DirAccess.open("user://logs")
	if dir == null:
		return []
	var newest := ""
	for f in dir.get_files():
		if f.begins_with("godot") and f.ends_with(".log") and f != "godot.log" and f > newest:
			newest = f
	if newest == "":
		return []
	var lines := FileAccess.get_file_as_string("user://logs/" + newest).split("\n")
	var out := []
	for l in lines:
		var t := l.strip_edges()
		# chyba zvukového ovladače se objevuje jen na počítači bez zvukové karty
		if t == "" or "status < 0" in t or "ALSA" in t or t.begins_with("at:"):
			continue
		out.append(t.substr(0, 100))
	return out.slice(maxi(0, out.size() - 6))


func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"conquered": {},
		"gold": 0,
		"upgrades": {},
		"intro_seen": false,
		"finished": false,
		"stats": {"kills": 0, "runs": 0, "defeats": 0, "bosses": 0, "chiefs": 0},
		"settings": DEFAULT_SETTINGS.duplicate(),
		"perf_checked": false,
		"heroes": {"selected": "cech", "unlocked": ["cech"], "seen": ["cech"]},
		"heat": {"selected": 0, "unlocked": 0, "records": {}},
		"endless": {},
		"daily": {"last": "", "streak": 0, "results": {}},
	}


func load_game() -> void:
	data = default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = _migrate(_deep_merge(default_data(), parsed))


## Doplní do uloženého postupu klíče, které přibyly v novějších verzích hry
## (i ve vnořených slovnících), aby se starý postup neztratil.
func _deep_merge(defaults: Dictionary, loaded: Dictionary) -> Dictionary:
	var out := defaults.duplicate(true)
	for k in loaded.keys():
		if out.get(k) is Dictionary and loaded[k] is Dictionary:
			out[k] = _deep_merge(out[k], loaded[k])
		elif out.has(k) and typeof(out[k]) != typeof(loaded[k]) and not (_is_num(out[k]) and _is_num(loaded[k])):
			continue
		else:
			out[k] = loaded[k]
	return out


func _is_num(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


func _migrate(d: Dictionary) -> Dictionary:
	var ver := int(d.get("version", 1))
	if ver < 2:
		# verze 1 měla jen vypínač zvuku
		if d.has("sound") and not bool(d.sound):
			d.settings.music_vol = 0.0
			d.settings.sfx_vol = 0.0
	d.erase("sound")
	d.version = SAVE_VERSION
	return d


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
	changed.emit()


## Smaže postup, nastavení zůstane.
func reset() -> void:
	var keep: Dictionary = data.get("settings", DEFAULT_SETTINGS).duplicate()
	var perf: bool = data.get("perf_checked", false)
	data = default_data()
	data.settings = keep
	data.perf_checked = perf
	save_game()


# ---------------------------------------------------------------- kraje

func is_conquered(id: String) -> bool:
	return data.conquered.has(id)


func stars(id: String) -> int:
	return int(data.conquered.get(id, 0))


func is_available(id: String) -> bool:
	if is_conquered(id):
		return true
	if id == START_REGION:
		return true
	for n in Regions.get_region(id).neighbors:
		if is_conquered(n):
			return true
	return false


func conquered_count() -> int:
	return data.conquered.size()


## Obtížnost roste s počtem už dobytých krajů (pořadí si hráč volí sám).
func tier_for(id: String) -> int:
	var t := conquered_count()
	if is_conquered(id):
		t -= 1
	return clampi(t, 0, 13)


func conquer(id: String, star_count: int) -> bool:
	var first := not is_conquered(id)
	var before := []
	for r in Regions.ORDER:
		if is_available(r):
			before.append(r)
	data.conquered[id] = maxi(stars(id), star_count)
	fresh_unlocks.clear()
	for r in Regions.ORDER:
		if is_available(r) and not r in before:
			fresh_unlocks.append(r)
	if conquered_count() >= Regions.ORDER.size():
		data.finished = true
	save_game()
	return first


func all_conquered() -> bool:
	return conquered_count() >= Regions.ORDER.size()


# ---------------------------------------------------------------- hrdinové (M8)

func hero() -> String:
	if hero_override != "":
		return hero_override
	var h: String = data.heroes.get("selected", "cech")
	return h if hero_unlocked(h) else "cech"


func set_hero(id: String) -> void:
	if not hero_unlocked(id):
		return
	data.heroes.selected = id
	save_game()
	changed.emit()


# ---------------------------------------------------------------- žár, nekonečno, denní výzva (M9)

## Nejvyšší odemčený žár (0 = ještě není, odemkne se po dobytí celého Česka).
func heat_unlocked() -> int:
	var u := int(data.heat.get("unlocked", 0))
	if u == 0 and all_conquered():
		u = 1
		data.heat.unlocked = 1
	return u


func heat() -> int:
	if heat_override >= 0:
		return clampi(heat_override, 0, ModifierDefs.MAX_HEAT)
	return clampi(int(data.heat.get("selected", 0)), 0, heat_unlocked())


func set_heat(n: int) -> void:
	data.heat.selected = clampi(n, 0, heat_unlocked())
	save_game()
	changed.emit()


func heat_record(region: String) -> int:
	return int(data.heat.records.get(region, 0))


## Výhra na žáru: zapíše rekord kraje a odemkne další úroveň. Vrací true, když se odemkla.
func heat_won(region: String, level: int) -> bool:
	if level <= 0:
		return false
	data.heat.records[region] = maxi(heat_record(region), level)
	var opened := false
	if level >= heat_unlocked() and level < ModifierDefs.MAX_HEAT:
		data.heat.unlocked = level + 1
		opened = true
	save_game()
	return opened


func endless_record(region: String) -> float:
	return float(data.endless.get(region, 0.0))


## Vrací true, když je to nový rekord kraje.
func set_endless_record(region: String, secs: float) -> bool:
	if secs <= endless_record(region):
		return false
	data.endless[region] = secs
	save_game()
	return true


## „2026-10-02“ → „2. 10. 2026“.
func date_cz(date: String) -> String:
	var p := date.split("-")
	if p.size() != 3:
		return date
	return "%d. %d. %s" % [int(p[2]), int(p[1]), p[0]]


func today() -> String:
	return daily_override if daily_override != "" else Time.get_date_string_from_system()


## Denní výzva pro dané datum: kraj, hrdina a dva modifikátory jsou pro všechny stejné.
func daily_info(date: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("dobyj-cesko-" + date)
	var region: String = Regions.ORDER[rng.randi() % Regions.ORDER.size()]
	var hero_id: String = HeroDefs.ORDER[rng.randi() % HeroDefs.ORDER.size()]
	var ids: Array = ModifierDefs.DAILY.keys()
	var a: String = ids[rng.randi() % ids.size()]
	ids.erase(a)
	var b2: String = ids[rng.randi() % ids.size()]
	return {"date": date, "region": region, "hero": hero_id, "mods": [a, b2], "seed": rng.randi()}


func daily_won_today() -> bool:
	return bool(data.daily.results.get(today(), {}).get("won", false))


## Série dní v řadě s výhrou (včetně dneška, když už dnes vyhrál).
func daily_streak() -> int:
	return int(data.daily.get("streak", 0))


## Zapíše výsledek denní výzvy. Odměnu dá jen za první výhru v daném dni.
func daily_result(won: bool, secs: float) -> int:
	var date := today()
	var res: Dictionary = data.daily.results.get(date, {"won": false, "tries": 0})
	res.tries = int(res.get("tries", 0)) + 1
	var reward := 0
	if won and not bool(res.won):
		res.won = true
		res["time"] = secs
		var yesterday := Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(date) - 86400)
		data.daily.streak = (daily_streak() + 1) if data.daily.last == yesterday else 1
		data.daily.last = date
		reward = ModifierDefs.DAILY_GOLD + ModifierDefs.DAILY_STREAK_GOLD * mini(daily_streak(), ModifierDefs.DAILY_STREAK_MAX)
	data.daily.results[date] = res
	save_game()
	return reward


## Kolik odemčených hrdinů hráč ještě neviděl na desce Hrdinové.
func unseen_heroes() -> int:
	var seen: Array = data.heroes.get("seen", ["cech"])
	var n := 0
	for id in data.heroes.unlocked:
		if not seen.has(id):
			n += 1
	return n


func mark_heroes_seen() -> void:
	data.heroes["seen"] = (data.heroes.unlocked as Array).duplicate()
	save_game()


func hero_unlocked(id: String) -> bool:
	return id == "cech" or (data.heroes.unlocked as Array).has(id)


func total_stars() -> int:
	var n := 0
	for id in data.conquered.keys():
		n += int(data.conquered[id])
	return n


## Postup k odemčení: [mám, potřebuji].
func hero_progress(id: String) -> Array:
	var u: Dictionary = HeroDefs.get_hero(id).unlock
	if u.has("bosses"):
		return [mini(int(data.stats.get("bosses", 0)), int(u.bosses)), int(u.bosses)]
	if u.has("region"):
		return [1 if is_conquered(u.region) else 0, 1]
	if u.has("stars"):
		return [mini(total_stars(), int(u.stars)), int(u.stars)]
	return [1, 1]


## Po bitvě: odemkne hrdiny, kteří splnili podmínku, a vrátí je.
func check_hero_unlocks() -> Array:
	var out := []
	for id in HeroDefs.ORDER:
		if hero_unlocked(id):
			continue
		var p := hero_progress(id)
		if int(p[0]) >= int(p[1]):
			(data.heroes.unlocked as Array).append(id)
			out.append(id)
	if not out.is_empty():
		fresh_heroes.append_array(out)
		save_game()
	return out


# ---------------------------------------------------------------- zlato a vylepšení

func gold() -> int:
	return int(data.gold)


func add_gold(n: int) -> void:
	data.gold = gold() + n
	save_game()


func upgrade_level(id: String) -> int:
	return int(data.upgrades.get(id, 0))


func buy_upgrade(id: String) -> bool:
	var def: Dictionary = Upgrades.META[id]
	var lvl := upgrade_level(id)
	if lvl >= def.max:
		return false
	var cost := meta_cost(id)
	if gold() < cost:
		return false
	data.gold = gold() - cost
	data.upgrades[id] = lvl + 1
	save_game()
	return true


func meta_cost(id: String) -> int:
	var def: Dictionary = Upgrades.META[id]
	return int(def.cost * pow(1.6, upgrade_level(id)))


func meta_value(id: String) -> float:
	return Upgrades.META[id].per * upgrade_level(id)


func add_stat(key: String, n: int) -> void:
	data.stats[key] = int(data.stats.get(key, 0)) + n


# ---------------------------------------------------------------- nastavení

func setting(key: String) -> Variant:
	return data.settings.get(key, DEFAULT_SETTINGS.get(key))


## save = false při tažení posuvníku (uloží se až po puštění).
func set_setting(key: String, value: Variant, save: bool = true) -> void:
	data.settings[key] = value
	setting_changed.emit(key)
	if save:
		save_game()


func low_quality() -> bool:
	return setting("quality") == "low"


## Úsporná grafika vykresluje v základním rozlišení a obraz roztáhne
## (na telefonech s vysokým rozlišením to ušetří víc než polovinu práce grafiky).
func apply_quality() -> void:
	var win := get_tree().root
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT if low_quality() else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS


## Krátké zavibrování telefonu (jen na Androidu a když je vibrace zapnutá).
func vibrate(ms: int) -> void:
	if not bool(setting("vibrate")) or not OS.has_feature("mobile"):
		return
	var now := Time.get_ticks_msec()
	if now < _vib_until:
		return
	_vib_until = now + ms + 60
	Input.vibrate_handheld(ms)
