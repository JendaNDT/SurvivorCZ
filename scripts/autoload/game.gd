extends Node
## Game – trvalý stav hry: dobyté kraje, hvězdy, zlato, vylepšení ze Zbrojnice.

const SAVE_PATH := "user://save.json"
const START_REGION := "KVK"

signal changed

var data: Dictionary = {}
## Parametry, které si předává mapa a bitva.
var pending_region: String = ""
## Kraje, které se právě odemkly (mapa je zvýrazní).
var fresh_unlocks: Array = []


func _ready() -> void:
	load_game()


func default_data() -> Dictionary:
	return {
		"version": 1,
		"conquered": {},
		"gold": 0,
		"upgrades": {},
		"sound": true,
		"intro_seen": false,
		"finished": false,
		"stats": {"kills": 0, "runs": 0, "defeats": 0, "bosses": 0},
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
		for k in parsed.keys():
			data[k] = parsed[k]


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
	changed.emit()


func reset() -> void:
	data = default_data()
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


func sound_on() -> bool:
	return bool(data.get("sound", true))
