extends RefCounted
class_name HeroDefs
## Hrdinové (M8) z českých pověstí (podle Starých pověstí českých).
## start  = startovní zbraň, start_level = její úroveň (slabší zbraně začínají výš),
## start2 = druhá startovní zbraň (úroveň 1)
## mods   = úpravy statistik: hp, speed, xp (podíl), knock (navíc k odhozu),
##          rerolls (přehození navíc), dash_cd (zkrácení nabíjení úskoku), dash_len (delší úskok),
##          dash_dmg (úskok zraňuje)
## ult    = ultimátka (Battle.use_ult), ult_name = popisek tlačítka
## unlock = podmínka odemčení: bosses (poražení bossové), region (dobytý kraj), stars (hvězdy)

const ORDER := ["cech", "bivoj", "libuse", "horymir"]

const DATA := {
	"cech": {
		"name": "Čech", "title": "Praotec, který přivedl lid pod Říp",
		"start": "mec", "mods": {},
		"ult": "hrom", "ult_name": "HROM", "ult_desc": "Blesky zasáhnou všechny nepřátele na obrazovce",
		"traits": ["vyvážený hrdina", "začíná s mečem"],
		"unlock": {}, "unlock_text": "",
	},
	"bivoj": {
		"name": "Bivoj", "title": "Silák, který přinesl živého kance",
		"start": "stity", "mods": {"hp": 0.30, "knock": 0.5, "speed": -0.10},
		"ult": "kanci_uder", "ult_name": "KANČÍ ÚDER", "ult_desc": "Dupnutí odhodí a na 2 s omráčí vše kolem",
		"traits": ["+30 % životů", "+50 % odhoz", "−10 % rychlosti", "začíná s kruhovými štíty"],
		"unlock": {"bosses": 3}, "unlock_text": "Poraz 3 bosse",
	},
	"libuse": {
		"name": "Kněžna Libuše", "title": "Věštkyně, která předpověděla slávu Prahy",
		"start": "blesk", "start_level": 3, "start2": "aura", "mods": {"xp": 0.20, "rerolls": 1, "hp": -0.10},
		"ult": "vestba", "ult_name": "VĚŠTBA", "ult_desc": "Nepřátelé na 4 s zamrznou",
		"traits": ["+20 % zkušeností", "+1 přehození karet", "−10 % životů", "začíná s bleskem a mrazivou aurou"],
		"unlock": {"region": "PHA"}, "unlock_text": "Dobyj Prahu",
	},
	"horymir": {
		"name": "Horymír a Šemík", "title": "Kůň Šemík s ním skočil z Vyšehradu",
		"start": "kuse", "start_level": 3, "start2": "sekera", "mods": {"speed": 0.15, "hp": 0.15, "dash_cd": 0.4, "dash_len": 0.4, "dash_dmg": true},
		"ult": "skok", "ult_name": "SKOK", "ult_desc": "Šemík skočí ve směru pohybu a dopad otřese zemí",
		"traits": ["+15 % rychlosti a životů", "delší úskok, který zraňuje", "úskok nabitý o 40 % dřív", "začíná s kuší a sekerou"],
		"unlock": {"stars": 20}, "unlock_text": "Získej 20 hvězd",
	},
}


static func get_hero(id: String) -> Dictionary:
	return DATA.get(id, DATA["cech"])


static func mod(id: String, key: String, default: Variant = 0.0) -> Variant:
	return get_hero(id).mods.get(key, default)
