extends RefCounted
class_name Upgrades
## Zbraně, pasivní předměty, evoluce a trvalá vylepšení (Zbrojnice).
## Vše je jen data – logika zbraní je v scripts/battle/weapons.gd.

const MAX_WEAPONS := 5
const MAX_PASSIVES := 5
const WEAPON_MAX_LEVEL := 8
const RARITY_MULT := [1.0, 1.5, 2.0, 3.0]
const RARITY_CHANCE := [0.70, 0.22, 0.07, 0.01]

const TAG_NAMES := {"fyz": "fyzické", "projektil": "projektil", "plocha": "plocha", "ohen": "oheň", "led": "led", "blesk": "blesk", "jed": "jed"}
const TAG_COLORS := {"fyz": "c9ced6", "projektil": "e0b070", "plocha": "8fd65a", "ohen": "ff6a2a", "led": "6fd0ff", "blesk": "ffe14a", "jed": "9be05a"}

const STAT_TEXT := {
	"dmg": "+%s poškození", "cd": "prodleva %s s", "area": "+%s %% plocha", "amount": "+%s kus",
	"pierce": "+%s průraz", "chain": "+%s přeskok", "dur": "trvání +%s s", "slow": "+%s %% zpomalení",
	"burn": "+%s poškození hořením", "speed": "+%s rychlost otáčení", "knock": "+%s odhoz",
}

const WEAPONS := {
	"mec": {"name": "Meč", "desc": "Seká v širokém oblouku směrem pohybu.", "tags": ["fyz"], "evo": "bruncvik", "evo_with": "sila",
		"base": {"dmg": 16.0, "cd": 1.1, "area": 1.0, "amount": 1, "knock": 180.0},
		"levels": [{"dmg": 6.0}, {"area": 0.2}, {"amount": 1}, {"dmg": 8.0}, {"cd": -0.15}, {"area": 0.25}, {"dmg": 12.0}]},
	"sekera": {"name": "Vrhací sekera", "desc": "Vyletí obloukem vzhůru a prosekne vše, co trefí.", "tags": ["fyz", "projektil"], "evo": "vir", "evo_with": "kniha",
		"base": {"dmg": 22.0, "cd": 1.6, "amount": 1, "area": 1.0, "pierce": 99},
		"levels": [{"amount": 1}, {"dmg": 8.0}, {"cd": -0.2}, {"amount": 1}, {"area": 0.3}, {"dmg": 12.0}, {"amount": 1}]},
	"kuse": {"name": "Kuše", "desc": "Střílí šipky na nejbližšího nepřítele.", "tags": ["fyz", "projektil"], "evo": "pistala", "evo_with": "hodiny",
		"base": {"dmg": 11.0, "cd": 0.9, "amount": 1, "pierce": 1, "speed": 720.0},
		"levels": [{"amount": 1}, {"dmg": 5.0}, {"pierce": 1}, {"cd": -0.15}, {"amount": 1}, {"dmg": 7.0}, {"pierce": 2}]},
	"ohen": {"name": "Ohnivá koule", "desc": "Exploduje a zapálí nepřátele v okolí.", "tags": ["ohen", "projektil", "plocha"], "evo": "peklo", "evo_with": "ohen_runa",
		"base": {"dmg": 16.0, "cd": 1.9, "amount": 1, "area": 1.0, "burn": 4.0, "speed": 380.0},
		"levels": [{"dmg": 6.0}, {"area": 0.25}, {"amount": 1}, {"burn": 3.0}, {"cd": -0.3}, {"area": 0.3}, {"amount": 1}]},
	"blesk": {"name": "Řetězový blesk", "desc": "Udeří a přeskakuje z nepřítele na nepřítele.", "tags": ["blesk"], "evo": "perun", "evo_with": "bour_amulet",
		"base": {"dmg": 15.0, "cd": 1.7, "amount": 1, "chain": 2},
		"levels": [{"chain": 1}, {"dmg": 6.0}, {"amount": 1}, {"cd": -0.25}, {"chain": 2}, {"dmg": 10.0}, {"amount": 1}]},
	"aura": {"name": "Mrazivá aura", "desc": "Mrazí a zpomaluje všechny kolem tebe.", "tags": ["led", "plocha"], "evo": "mraz", "evo_with": "led_krystal",
		"base": {"dmg": 5.0, "cd": 0.5, "area": 1.0, "slow": 0.3},
		"levels": [{"area": 0.2}, {"dmg": 3.0}, {"slow": 0.1}, {"area": 0.2}, {"dmg": 4.0}, {"cd": -0.1}, {"area": 0.3}]},
	"stity": {"name": "Kruhové štíty", "desc": "Dřevěné štíty krouží kolem a odrážejí nepřátele.", "tags": ["fyz"], "evo": "hradba", "evo_with": "brneni",
		"base": {"dmg": 11.0, "cd": 0.5, "amount": 2, "area": 1.0, "speed": 3.0},
		"levels": [{"amount": 1}, {"dmg": 5.0}, {"area": 0.2}, {"amount": 1}, {"speed": 0.8}, {"dmg": 8.0}, {"amount": 1}]},
	"jed": {"name": "Jedový kotlík", "desc": "Hází lahvičky, které nechají jedovatou louži.", "tags": ["jed", "plocha"], "evo": "bazina", "evo_with": "jed_ampule",
		"base": {"dmg": 5.0, "cd": 2.4, "amount": 1, "area": 1.0, "dur": 3.0},
		"levels": [{"area": 0.2}, {"amount": 1}, {"dmg": 3.0}, {"dur": 1.0}, {"cd": -0.4}, {"amount": 1}, {"dmg": 5.0}]},
}

const EVOLUTIONS := {
	"bruncvik": {"name": "Bruncvíkův meč", "from": "mec", "desc": "Kouzelný meč z pověsti seká dokola sám od sebe.", "tags": ["fyz"],
		"base": {"dmg": 34.0, "cd": 0.85, "area": 1.6, "amount": 2, "knock": 260.0}},
	"vir": {"name": "Valašský vír", "from": "sekera", "desc": "Sekery létají do všech stran v široké spirále.", "tags": ["fyz", "projektil"],
		"base": {"dmg": 34.0, "cd": 1.3, "amount": 8, "area": 1.4, "pierce": 99}},
	"pistala": {"name": "Husitská píšťala", "from": "kuse", "desc": "Z „píšťaly“ vzniklo slovo pistole. Rychlé výbušné střely.", "tags": ["fyz", "projektil", "ohen"],
		"base": {"dmg": 20.0, "cd": 0.32, "amount": 2, "pierce": 2, "speed": 900.0, "area": 1.0}},
	"peklo": {"name": "Pekelný déšť", "from": "ohen", "desc": "Z nebe padají ohnivé meteority.", "tags": ["ohen", "plocha"],
		"base": {"dmg": 40.0, "cd": 0.9, "amount": 4, "area": 1.8, "burn": 10.0}},
	"perun": {"name": "Perunův hrom", "from": "blesk", "desc": "Slovanský bůh hromu zasáhne celé hordy.", "tags": ["blesk"],
		"base": {"dmg": 36.0, "cd": 0.9, "amount": 4, "chain": 8}},
	"mraz": {"name": "Věčný mráz", "from": "aura", "desc": "Ledová bouře, která skoro zastaví čas.", "tags": ["led", "plocha"],
		"base": {"dmg": 14.0, "cd": 0.35, "area": 2.0, "slow": 0.7}},
	"hradba": {"name": "Vozová hradba", "from": "stity", "desc": "Husitské vozy krouží kolem a drtí nepřátele.", "tags": ["fyz"],
		"base": {"dmg": 30.0, "cd": 0.35, "amount": 6, "area": 1.6, "speed": 3.6}},
	"bazina": {"name": "Morová bažina", "from": "jed", "desc": "Jedovatá bažina pohltí celé okolí.", "tags": ["jed", "plocha"],
		"base": {"dmg": 14.0, "cd": 1.2, "amount": 3, "area": 1.8, "dur": 5.0}},
}

const PASSIVES := {
	"sila": {"name": "Medvědí síla", "stat": "dmg_inc", "per": 0.10, "fmt": "+%d %% poškození", "pct": true, "tags": []},
	"brneni": {"name": "Kroužkové brnění", "stat": "armor", "per": 1.0, "fmt": "+%d brnění", "pct": false, "tags": []},
	"boty": {"name": "Sedmimílové boty", "stat": "speed_inc", "per": 0.08, "fmt": "+%d %% rychlost", "pct": true, "tags": []},
	"srdce": {"name": "Perníkové srdce", "stat": "hp_flat", "per": 20.0, "fmt": "+%d max. životů", "pct": false, "tags": []},
	"voda": {"name": "Živá voda", "stat": "regen", "per": 0.4, "fmt": "+%.1f života za s", "pct": false, "tags": []},
	"magnet": {"name": "Magnet", "stat": "magnet_inc", "per": 0.30, "fmt": "+%d %% dosah sběru", "pct": true, "tags": []},
	"hodiny": {"name": "Přesýpací hodiny", "stat": "cd_inc", "per": -0.07, "fmt": "%d %% prodleva útoků", "pct": true, "tags": []},
	"kniha": {"name": "Kniha kouzel", "stat": "area_inc", "per": 0.12, "fmt": "+%d %% plocha", "pct": true, "tags": ["plocha"]},
	"zrcadlo": {"name": "Kouzelné zrcadlo", "stat": "amount", "per": 1.0, "fmt": "+%d kus u všech zbraní", "pct": false, "tags": ["projektil"], "max": 2, "no_rarity": true},
	"ctyrlistek": {"name": "Čtyřlístek", "stat": "crit", "per": 0.06, "fmt": "+%d %% kritický zásah", "pct": true, "tags": []},
	"sova": {"name": "Moudrá sova", "stat": "xp_inc", "per": 0.12, "fmt": "+%d %% zkušeností", "pct": true, "tags": []},
	"ohen_runa": {"name": "Ohnivá runa", "stat": "tag_ohen", "per": 0.25, "fmt": "+%d %% poškození ohněm", "pct": true, "tags": ["ohen"]},
	"led_krystal": {"name": "Ledový krystal", "stat": "tag_led", "per": 0.25, "fmt": "+%d %% poškození ledem", "pct": true, "tags": ["led"]},
	"bour_amulet": {"name": "Bouřkový amulet", "stat": "tag_blesk", "per": 0.25, "fmt": "+%d %% poškození bleskem", "pct": true, "tags": ["blesk"]},
	"jed_ampule": {"name": "Jedová ampule", "stat": "tag_jed", "per": 0.25, "fmt": "+%d %% poškození jedem", "pct": true, "tags": ["jed"]},
}
const PASSIVE_MAX_LEVEL := 5

## Trvalá vylepšení kupovaná za zlato mezi kraji.
const META := {
	"m_hp": {"name": "Odolnost", "desc": "+10 % max. životů", "per": 0.10, "max": 5, "cost": 60, "icon": "srdce"},
	"m_dmg": {"name": "Ostří", "desc": "+6 % poškození", "per": 0.06, "max": 5, "cost": 80, "icon": "sila"},
	"m_speed": {"name": "Lehký krok", "desc": "+4 % rychlost pohybu", "per": 0.04, "max": 4, "cost": 60, "icon": "boty"},
	"m_magnet": {"name": "Magnet", "desc": "+15 % dosah sběru", "per": 0.15, "max": 3, "cost": 50, "icon": "magnet"},
	"m_armor": {"name": "Pancíř", "desc": "+1 brnění", "per": 1.0, "max": 3, "cost": 120, "icon": "brneni"},
	"m_regen": {"name": "Bylinky", "desc": "+0,2 života za sekundu", "per": 0.2, "max": 3, "cost": 90, "icon": "voda"},
	"m_reroll": {"name": "Přehození", "desc": "+1 přehození karet za kraj", "per": 1.0, "max": 3, "cost": 100, "icon": "reroll"},
	"m_gold": {"name": "Lakota", "desc": "+15 % zlata", "per": 0.15, "max": 3, "cost": 90, "icon": "coin"},
	"m_xp": {"name": "Moudrost", "desc": "+8 % zkušeností", "per": 0.08, "max": 3, "cost": 90, "icon": "sova"},
	"m_revive": {"name": "Druhá šance", "desc": "Jednou za kraj vstaneš z mrtvých", "per": 1.0, "max": 1, "cost": 300, "icon": "srdce_zlate"},
}


static func weapon_def(id: String) -> Dictionary:
	if WEAPONS.has(id):
		return WEAPONS[id]
	return EVOLUTIONS[id]


static func is_evolution(id: String) -> bool:
	return EVOLUTIONS.has(id)


## Statistiky zbraně na dané úrovni.
static func weapon_stats(id: String, level: int) -> Dictionary:
	var def := weapon_def(id)
	var st: Dictionary = def.base.duplicate()
	if def.has("levels"):
		for i in mini(level - 1, def.levels.size()):
			var d: Dictionary = def.levels[i]
			for k in d.keys():
				st[k] = st.get(k, 0) + d[k]
	return st


static func level_text(id: String, next_level: int) -> String:
	var def := weapon_def(id)
	if next_level <= 1 or not def.has("levels"):
		return def.desc
	var d: Dictionary = def.levels[next_level - 2]
	var parts := []
	for k in d.keys():
		var v = d[k]
		var s := ""
		if k == "area" or k == "slow":
			s = str(int(round(v * 100)))
		elif k == "cd":
			s = ("%+.2f" % v).replace(".", ",")
		elif v is float and v != floor(v):
			s = ("%.1f" % v).replace(".", ",")
		else:
			s = str(int(v))
		parts.append(STAT_TEXT[k] % s)
	return ", ".join(parts)


static func passive_text(id: String, rarity: int) -> String:
	var p: Dictionary = PASSIVES[id]
	var v: float = p.per * (1.0 if p.get("no_rarity", false) else RARITY_MULT[rarity])
	if p.pct:
		return (p.fmt % int(round(v * 100))).replace("+-", "-")
	if p.fmt.contains("%.1f"):
		return (p.fmt % v).replace(".", ",")
	return p.fmt % int(round(v))
