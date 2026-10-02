extends RefCounted
class_name HazardDefs
## Nástrahy krajů: každý kraj má jednu mechaniku, která ublíží nepřátelům
## stejně jako hrdinovi. Vyplatí se do ní hordu nalákat.
##
## first  = kdy (v sekundách) se nástraha objeví poprvé
## every  = rozmezí mezi dalšími výskyty
## dmg    = poškození hrdiny jako podíl jeho maximálních životů
## dur    = jak dlouho trvá počasí (mlha, vánice, vítr)
## Běžné nepřátele nástraha zabije, elitě vezme `elite` jejích životů.
## Logika je v scripts/battle/hazards.gd, kresby v scripts/art/hazard_art.gd.

const DATA := {
	"KVK": {
		"id": "gejzir", "name": "Gejzíry!", "hint": "Pára zraní každého, horký pramen pak léčí",
		"first": 16.0, "every": [10.0, 14.0], "dmg": 0.14, "elite": 0.3,
		"count": [2, 3], "r": 85.0, "warn": 1.2, "spring_dur": 5.0, "spring_heal": 3.0,
	},
	"PLK": {
		"id": "sudy", "name": "Valí se sudy!", "hint": "Sudy srazí každého v červeném pruhu",
		"first": 18.0, "every": [15.0, 15.0], "dmg": 0.16, "elite": 0.35,
		"warn": 1.5, "count": 3, "speed": 820.0, "r": 34.0,
	},
	"ULK": {
		"id": "pasy", "name": "Pásové dopravníky", "hint": "Pás unáší hrdinu i nepřátele, z konce padá uhlí",
		"first": 10.0, "every": [3.5, 5.5], "dmg": 0.1, "elite": 0.25,
		"belt_speed": 150.0, "belt_size": [300.0, 70.0], "warn": 1.0, "r": 46.0,
	},
	"LBK": {
		"id": "mlha", "name": "Jizerská mlha", "hint": "Vidíš jen kolem sebe, krystaly v mlze svítí",
		"first": 22.0, "every": [30.0, 30.0], "dur": 12.0, "view": 280.0,
	},
	"HKK": {
		"id": "vanice", "name": "Krakonošova vánice", "hint": "Všichni zpomalí. Nestůj na místě, jinak mrzneš!",
		"first": 18.0, "every": [25.0, 25.0], "dur": 8.0, "player_slow": 0.2, "enemy_slow": 0.4, "freeze": 1.0,
	},
	"PAK": {
		"id": "dostih", "name": "Dostih!", "hint": "Koně smetou všechno v pruhu, nalákej tam hordu",
		"first": 20.0, "every": [18.0, 18.0], "dmg": 0.18, "elite": 0.4,
		"warn": 1.6, "count": 4, "speed": 950.0,
	},
	"STC": {
		"id": "katapult", "name": "Hradní katapult", "hint": "Kámen zraní každého, kráter pak zpomaluje",
		"first": 14.0, "every": [9.0, 9.0], "dmg": 0.14, "elite": 0.35,
		"warn": 1.4, "r": 80.0, "crater_dur": 6.0, "crater_slow": 0.45,
	},
	"PHA": {
		"id": "tramvaj", "name": "Pozor, tramvaj!", "hint": "Nenech se srazit, ale nalákej na koleje hordu",
		"first": 16.0, "every": [12.0, 16.0], "dmg": 0.25, "elite": 0.5,
		"warn": 1.8, "speed": 1050.0, "rail_gap": 800.0, "rail_off": 260.0,
	},
	"JHC": {
		"id": "rybniky", "name": "Rybníky", "hint": "Ve vodě se brodíš pomalu, kapři a vodníci jsou rychlejší",
		"first": 6.0, "every": [999.0, 999.0], "slow": 0.4, "shader_off": true, "swim_bonus": 0.3, "swimmers": ["kapr", "vodnik"],
	},
	"VYS": {
		"id": "spory", "name": "Houbové spory", "hint": "Kruhy hub vypouštějí jed, nalákej do nich nepřátele",
		"first": 12.0, "every": [8.0, 8.0], "dmg": 0.035, "warn": 1.0, "cloud_dur": 4.0, "r": 95.0,
	},
	"JHM": {
		"id": "vitr", "name": "Vichr z Pálavy", "hint": "Vítr tlačí hrdinu, nepřátele i střely",
		"first": 16.0, "every": [20.0, 20.0], "dur": 6.0, "warn": 1.5, "push": 115.0, "enemy_push": 150.0,
	},
	"OLK": {
		"id": "kombajn", "name": "Kombajn!", "hint": "Sklidí nepřátele i tebe, uhni z pruhu",
		"first": 20.0, "every": [16.0, 16.0], "dmg": 0.2, "elite": 0.4,
		"warn": 1.5, "speed": 560.0, "width": 220.0,
	},
	"ZLK": {
		"id": "svestky", "name": "Padající švestky", "hint": "Švestka hrdinu vyléčí, nepřítel na ní uklouzne",
		"first": 8.0, "every": [3.0, 3.0], "heal": 4.0, "stun": 1.0, "max": 14,
	},
	"MSK": {
		"id": "praskliny", "name": "Žhavé praskliny", "hint": "Z prasklin tryská železo a chvíli pak pálí",
		"first": 14.0, "every": [12.0, 12.0], "dmg": 0.14, "elite": 0.35, "shader_off": true,
		"warn": 1.2, "trail_dur": 4.0, "trail_dmg": 0.03, "w": 34.0,
	},
}


static func get_for(region_id: String) -> Dictionary:
	return DATA.get(region_id, {})
