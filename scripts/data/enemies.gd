extends RefCounted
class_name EnemyDefs
## Nepřátelé a bossové. Chování je společné (archetyp), vzhled a jméno patří ke kraji.

## Výchozí hodnoty archetypů (úroveň 0, začátek kraje).
const BEHAVIOR := {
	"chaser":   {"hp": 13.0, "spd": 64.0, "dmg": 8.0, "r": 16.0, "xp": 1, "size": 92.0, "cost": 1.0},
	"runner":   {"hp": 8.0, "spd": 118.0, "dmg": 6.0, "r": 14.0, "xp": 1, "size": 90.0, "cost": 1.0},
	"tank":     {"hp": 70.0, "spd": 42.0, "dmg": 14.0, "r": 25.0, "xp": 5, "size": 150.0, "cost": 4.0},
	"shooter":  {"hp": 20.0, "spd": 58.0, "dmg": 8.0, "r": 17.0, "xp": 2, "size": 104.0, "cost": 3.0},
	"charger":  {"hp": 30.0, "spd": 62.0, "dmg": 12.0, "r": 19.0, "xp": 3, "size": 120.0, "cost": 3.0},
	"splitter": {"hp": 32.0, "spd": 56.0, "dmg": 9.0, "r": 20.0, "xp": 2, "size": 100.0, "cost": 3.0},
	"kamikaze": {"hp": 11.0, "spd": 96.0, "dmg": 20.0, "r": 15.0, "xp": 1, "size": 92.0, "cost": 2.0},
}

## Váhy výběru podle fáze kraje: [začátek, konec]
const WEIGHTS := {
	"chaser": [10.0, 8.0], "runner": [6.0, 7.0], "splitter": [3.0, 5.0], "tank": [0.6, 4.0],
	"shooter": [0.8, 3.5], "charger": [0.8, 3.5], "kamikaze": [1.5, 3.5],
}

const ENEMIES := {
	# Karlovarský
	"host": {"name": "Lázeňský host", "beh": "chaser"},
	"oplatka": {"name": "Lázeňská oplatka", "beh": "runner"},
	"konvice": {"name": "Porcelánová konvice", "beh": "tank"},
	# Plzeňský
	"pena": {"name": "Pivní pěna", "beh": "splitter"},
	"sud": {"name": "Valivý sud", "beh": "tank"},
	"chmel": {"name": "Chmelová šiška", "beh": "runner"},
	# Ústecký
	"havir": {"name": "Havíř", "beh": "chaser"},
	"uhli": {"name": "Uhelný golem", "beh": "tank"},
	"dynamit": {"name": "Dynamit", "beh": "kamikaze"},
	# Liberecký
	"banka": {"name": "Skleněná baňka", "beh": "splitter"},
	"brouk": {"name": "Bižuterní brouk", "beh": "runner"},
	"sklar": {"name": "Sklář", "beh": "shooter", "proj": "strep"},
	# Královéhradecký
	"koule": {"name": "Sněhová koule", "beh": "runner"},
	"snehulak": {"name": "Sněhulák", "beh": "tank"},
	"skritek": {"name": "Horský skřítek", "beh": "shooter", "proj": "snehova"},
	# Pardubický
	"pernicek": {"name": "Perníček", "beh": "chaser"},
	"kun": {"name": "Dostihový kůň", "beh": "charger"},
	"semtex": {"name": "Semtex", "beh": "kamikaze"},
	# Středočeský
	"kostlivec": {"name": "Kostlivec z kostnice", "beh": "chaser"},
	"rytir": {"name": "Blanický rytíř", "beh": "tank"},
	"lucistnik": {"name": "Lučištník", "beh": "shooter", "proj": "sip"},
	# Praha
	"turista": {"name": "Turista se selfie tyčí", "beh": "chaser"},
	"holub": {"name": "Pražský holub", "beh": "runner"},
	"golem": {"name": "Golem", "beh": "tank"},
	# Jihočeský
	"kapr": {"name": "Kapr", "beh": "runner"},
	"rak": {"name": "Rak", "beh": "tank"},
	"vodnik": {"name": "Vodník", "beh": "shooter", "proj": "kapka"},
	# Vysočina
	"brambora": {"name": "Brambora", "beh": "chaser"},
	"divocak": {"name": "Divočák", "beh": "charger"},
	"muchomurka": {"name": "Muchomůrka", "beh": "kamikaze"},
	# Jihomoravský
	"hrozen": {"name": "Hrozen", "beh": "splitter"},
	"netopyr": {"name": "Netopýr z Macochy", "beh": "runner"},
	"vinar": {"name": "Vinař", "beh": "shooter", "proj": "hrozen"},
	# Olomoucký
	"tvaruzek": {"name": "Tvarůžek", "beh": "chaser"},
	"hanak": {"name": "Hanák", "beh": "tank"},
	"praded": {"name": "Duch Praděda", "beh": "shooter", "proj": "mlha"},
	# Zlínský
	"svestka": {"name": "Švestka", "beh": "chaser"},
	"bota": {"name": "Baťovka", "beh": "charger"},
	"valach": {"name": "Valach s valaškou", "beh": "tank"},
	# Moravskoslezský
	"hutnik": {"name": "Hutník", "beh": "chaser"},
	"ingot": {"name": "Rozžhavený ingot", "beh": "splitter"},
	"tatra": {"name": "Tatrovka", "beh": "charger"},
}

## Bossové: fáze se sčítají (ve 2. fázi útočí útoky z 1. i 2. fáze).
const BOSSES := {
	"vridlo": {"name": "Vřídelní obr", "title": "Pán horkých pramenů", "proj": "kapka", "summon": "host", "puddle": "a6e6ff",
		"phases": [["slam", "radial"], ["rain", "summon"], ["puddle", "spiral"]]},
	"pivni_kral": {"name": "Pivní král", "title": "Vládce sudů a pěny", "proj": "pena", "summon": "sud", "puddle": "f2b632",
		"phases": [["radial", "charge"], ["puddle", "summon"], ["spiral", "rain"]]},
	"rypadlo": {"name": "Kolesové rypadlo", "title": "Požírač krajiny", "proj": "uhel", "summon": "dynamit", "puddle": "2b2b2b",
		"phases": [["charge", "radial"], ["rain", "summon"], ["shockwave", "spiral"]]},
	"jested": {"name": "Ještěd", "title": "Vysílač, který ožil", "proj": "signal", "summon": "brouk", "puddle": "8fe9ff",
		"phases": [["radial", "rain"], ["spiral", "summon"], ["shockwave", "slam"]]},
	"krakonos": {"name": "Krakonoš", "title": "Pán Krkonoš a počasí", "proj": "snehova", "summon": "snehulak", "puddle": "cfeaff",
		"phases": [["slam", "radial"], ["rain", "summon"], ["shockwave", "spiral"]]},
	"jezibaba": {"name": "Perníková ježibaba", "title": "Paní perníkové chaloupky", "proj": "srdce", "summon": "pernicek", "puddle": "7ee05a",
		"phases": [["puddle", "radial"], ["charge", "summon"], ["spiral", "rain"]]},
	"blanik": {"name": "Velitel blanických rytířů", "title": "Probuzený z hory Blaník", "proj": "sip", "summon": "rytir", "puddle": "9a7bd6",
		"phases": [["charge", "slam"], ["radial", "summon"], ["shockwave", "rain"]]},
	"orloj": {"name": "Pražský orloj", "title": "Smrtka už tahá za provaz", "proj": "hvezda", "summon": "golem", "puddle": "ffd84a",
		"phases": [["spiral", "radial"], ["summon", "rain", "slam"], ["shockwave", "charge"]]},
	"vodnik_kral": {"name": "Král vodníků", "title": "Strážce dušiček v hrníčcích", "proj": "hrnicek", "summon": "kapr", "puddle": "4aa3d8",
		"phases": [["radial", "puddle"], ["summon", "rain"], ["spiral", "charge"]]},
	"hribi_kral": {"name": "Hřibí král", "title": "Vládce Vysočiny", "proj": "spora", "summon": "muchomurka", "puddle": "9be05a",
		"phases": [["puddle", "slam"], ["summon", "radial"], ["rain", "shockwave"]]},
	"drak": {"name": "Brněnský drak", "title": "Postrach brněnské radnice", "proj": "ohen", "summon": "netopyr", "puddle": "ff8a2a",
		"phases": [["charge", "radial"], ["rain", "summon"], ["spiral", "shockwave"]]},
	"syrovy_kral": {"name": "Tvarůžkový král", "title": "Nejvoňavější panovník Hané", "proj": "syr", "summon": "tvaruzek", "puddle": "c8e05a",
		"phases": [["puddle", "radial"], ["summon", "slam"], ["spiral", "rain"]]},
	"obri_bota": {"name": "Obří bota", "title": "Pýcha zlínské továrny", "proj": "hrebik", "summon": "bota", "puddle": "3a2a20",
		"phases": [["slam", "charge"], ["summon", "radial"], ["shockwave", "rain"]]},
	"pec": {"name": "Vysokopecní titán", "title": "Srdce ostravských hutí", "proj": "jiskra", "summon": "ingot", "puddle": "ff6a10",
		"phases": [["puddle", "radial"], ["rain", "summon"], ["spiral", "shockwave", "charge"]]},
}


static func get_enemy(id: String) -> Dictionary:
	var e: Dictionary = ENEMIES[id]
	var d: Dictionary = BEHAVIOR[e.beh].duplicate()
	for k in e.keys():
		d[k] = e[k]
	d["id"] = id
	return d
