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
## Průměrné FPS z první bitvy, když se hra sekala (mapa pak nabídne úspornou grafiku).
var perf_offer := 0.0
var _vib_until := 0


func _ready() -> void:
	load_game()
	apply_quality.call_deferred()


func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"conquered": {},
		"gold": 0,
		"upgrades": {},
		"intro_seen": false,
		"finished": false,
		"stats": {"kills": 0, "runs": 0, "defeats": 0, "bosses": 0},
		"settings": DEFAULT_SETTINGS.duplicate(),
		"perf_checked": false,
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
