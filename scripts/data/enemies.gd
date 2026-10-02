extends RefCounted
class_name EnemyDefs
## Nepřátelé, náčelníci a bossové. Chování je společné (archetyp), vzhled a jméno patří ke kraji.

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
## death = vlastní tečka po smrti bosse (scripts/battle/boss_death.gd).
const BOSSES := {
	"vridlo": {"name": "Vřídelní obr", "title": "Pán horkých pramenů", "proj": "kapka", "summon": "host", "puddle": "a6e6ff",
		"death": "gejzir",
		"phases": [["slam", "radial"], ["rain", "summon"], ["puddle", "spiral"]]},
	"pivni_kral": {"name": "Pivní král", "title": "Vládce sudů a pěny", "proj": "pena", "summon": "sud", "puddle": "f2b632",
		"death": "pena",
		"phases": [["radial", "charge"], ["puddle", "summon"], ["spiral", "rain"]]},
	"rypadlo": {"name": "Kolesové rypadlo", "title": "Požírač krajiny", "proj": "uhel", "summon": "dynamit", "puddle": "2b2b2b",
		"death": "kolo",
		"phases": [["charge", "radial"], ["rain", "summon"], ["shockwave", "spiral"]]},
	"jested": {"name": "Ještěd", "title": "Vysílač, který ožil", "proj": "signal", "summon": "brouk", "puddle": "8fe9ff",
		"death": "signal",
		"phases": [["radial", "rain"], ["spiral", "summon"], ["shockwave", "slam"]]},
	"krakonos": {"name": "Krakonoš", "title": "Pán Krkonoš a počasí", "proj": "snehova", "summon": "snehulak", "puddle": "cfeaff",
		"death": "klobouk",
		"phases": [["slam", "radial"], ["rain", "summon"], ["shockwave", "spiral"]]},
	"jezibaba": {"name": "Perníková ježibaba", "title": "Paní perníkové chaloupky", "proj": "srdce", "summon": "pernicek", "puddle": "7ee05a",
		"death": "pernicky",
		"phases": [["puddle", "radial"], ["charge", "summon"], ["spiral", "rain"]]},
	"blanik": {"name": "Velitel blanických rytířů", "title": "Probuzený z hory Blaník", "proj": "sip", "summon": "rytir", "puddle": "9a7bd6",
		"death": "prapor",
		"phases": [["charge", "slam"], ["radial", "summon"], ["shockwave", "rain"]]},
	"orloj": {"name": "Pražský orloj", "title": "Smrtka už tahá za provaz", "proj": "hvezda", "summon": "golem", "puddle": "ffd84a",
		"death": "orloj",
		"phases": [["spiral", "radial"], ["summon", "rain", "slam"], ["shockwave", "charge"]]},
	"vodnik_kral": {"name": "Král vodníků", "title": "Strážce dušiček v hrníčcích", "proj": "hrnicek", "summon": "kapr", "puddle": "4aa3d8",
		"death": "dusicky",
		"phases": [["radial", "puddle"], ["summon", "rain"], ["spiral", "charge"]]},
	"hribi_kral": {"name": "Hřibí král", "title": "Vládce Vysočiny", "proj": "spora", "summon": "muchomurka", "puddle": "9be05a",
		"death": "houby",
		"phases": [["puddle", "slam"], ["summon", "radial"], ["rain", "shockwave"]]},
	"drak": {"name": "Brněnský drak", "title": "Postrach brněnské radnice", "proj": "ohen", "summon": "netopyr", "puddle": "ff8a2a",
		"death": "kour",
		"phases": [["charge", "radial"], ["rain", "summon"], ["spiral", "shockwave"]]},
	"syrovy_kral": {"name": "Tvarůžkový král", "title": "Nejvoňavější panovník Hané", "proj": "syr", "summon": "tvaruzek", "puddle": "c8e05a",
		"death": "smrad",
		"phases": [["puddle", "radial"], ["summon", "slam"], ["spiral", "rain"]]},
	"obri_bota": {"name": "Obří bota", "title": "Pýcha zlínské továrny", "proj": "hrebik", "summon": "bota", "puddle": "3a2a20",
		"death": "krabice",
		"phases": [["slam", "charge"], ["summon", "radial"], ["shockwave", "rain"]]},
	"pec": {"name": "Vysokopecní titán", "title": "Srdce ostravských hutí", "proj": "jiskra", "summon": "ingot", "puddle": "ff6a10",
		"death": "lava",
		"phases": [["puddle", "radial"], ["rain", "summon"], ["spiral", "shockwave", "charge"]]},
}


## Náčelníci (minibossové) v polovině kraje: hlavní nepřítel kraje ve dvojnásobné
## velikosti s korunou. Útoky jsou stejné jako u bossů (scripts/battle/boss.gd),
## jen bez fází. „summon“ přivolá nepřítele kraje, „charge2“ je dvojitý výpad.
const MINIBOSSES := {
	"primar": {"base": "host", "name": "Lázeňský primář", "title": "Předepíše ti procházku po kolonádě",
		"attacks": ["summon", "radial"], "summon": "oplatka", "proj": "kapka", "puddle": "a6e6ff"},
	"sladek": {"base": "sud", "name": "Mistr sládek", "title": "Z hordy uvaří pořádnou pěnu",
		"attacks": ["charge", "puddle"], "summon": "chmel", "proj": "pena", "puddle": "f2b632"},
	"predak": {"base": "havir", "name": "Předák havířů", "title": "Zdař bůh, a pak to bouchne",
		"attacks": ["rain", "summon"], "summon": "dynamit", "proj": "uhel", "puddle": "2b2b2b"},
	"sklar_mistr": {"base": "sklar", "name": "Mistr sklář", "title": "Fouká střepy do všech stran",
		"attacks": ["spiral", "radial"], "summon": "brouk", "proj": "strep", "puddle": "8fe9ff"},
	"snehulak_obri": {"base": "snehulak", "name": "Obří sněhulák", "title": "Když dupne, třese se Sněžka",
		"attacks": ["slam", "radial"], "summon": "koule", "proj": "snehova", "puddle": "cfeaff"},
	"zokej": {"base": "kun", "name": "Žokej šampion", "title": "Vítěz Velké pardubické",
		"attacks": ["charge2", "summon"], "summon": "pernicek", "proj": "srdce", "puddle": "7ee05a"},
	"prapornik": {"base": "rytir", "name": "Rytíř praporečník", "title": "Nese korouhev blanického vojska",
		"attacks": ["charge", "slam"], "summon": "kostlivec", "proj": "sip", "puddle": "9a7bd6"},
	"golem_velky": {"base": "golem", "name": "Velký Golem", "title": "Rabi mu zapomněl vyndat šém",
		"attacks": ["slam", "shockwave"], "summon": "turista", "proj": "hvezda", "puddle": "c9a06a"},
	"kapr_obri": {"base": "kapr", "name": "Obří kapr", "title": "Nejtěžší úlovek z Rožmberka",
		"attacks": ["charge", "puddle"], "summon": "kapr", "proj": "kapka", "puddle": "4aa3d8"},
	"knour": {"base": "divocak", "name": "Kňour", "title": "Vůdce divočáků z Vysočiny",
		"attacks": ["charge", "summon"], "summon": "muchomurka", "proj": "spora", "puddle": "9be05a"},
	"vinar_stary": {"base": "vinar", "name": "Starý vinař", "title": "Do sklepa jen tak nikoho nepustí",
		"attacks": ["radial", "puddle"], "summon": "hrozen", "proj": "hrozen", "puddle": "8e3a9e"},
	"starosta": {"base": "hanak", "name": "Starosta Hané", "title": "Pantáta z celé Hané",
		"attacks": ["slam", "summon"], "summon": "tvaruzek", "proj": "syr", "puddle": "c8e05a"},
	"hajtman": {"base": "valach", "name": "Valašský hajtman", "title": "Valaška se mu ve slunci blýská",
		"attacks": ["slam", "charge"], "summon": "svestka", "proj": "hrebik", "puddle": "3a2a20"},
	"hutnik_mistr": {"base": "hutnik", "name": "Mistr hutník", "title": "Leje roztavené železo",
		"attacks": ["puddle", "rain"], "summon": "ingot", "proj": "jiskra", "puddle": "ff6a10"},
}


static func get_enemy(id: String) -> Dictionary:
	var e: Dictionary = ENEMIES[id]
	var d: Dictionary = BEHAVIOR[e.beh].duplicate()
	for k in e.keys():
		d[k] = e[k]
	d["id"] = id
	return d
