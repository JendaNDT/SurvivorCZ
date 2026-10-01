extends RefCounted
class_name Regions
## 14 krajů Česka: sousedé, prostředí, nepřátelé a bossové.
## Pořadí dobývání si volí hráč, obtížnost se řídí počtem už dobytých krajů.

## Vzory země pro shader (viz shaders/ground.gdshader)
enum Ground { GRASS, COBBLE, DIRT, SNOW, FOREST, VINEYARD, METAL, FIELD, MEADOW }

const ORDER := ["KVK", "PLK", "ULK", "LBK", "HKK", "PAK", "STC", "PHA", "JHC", "VYS", "JHM", "OLK", "ZLK", "MSK"]

const DATA := {
	"KVK": {
		"name": "Karlovarský kraj", "short": "Karlovarsko", "capital": "Karlovy Vary",
		"label": [12.80, 50.17],
		"neighbors": ["PLK", "ULK"],
		"theme": "Lázně a horké prameny",
		"desc": "Kolonády, Vřídlo a lázeňské oplatky. Lázeňští hosté ti svůj pohárek jen tak nedají!",
		"ground": {"pattern": Ground.GRASS, "a": "6fcf3c", "b": "4fae2a", "c": "d9cfb8"},
		"decor": ["kolonada", "pramen", "zahon", "strom", "ker"],
		"enemies": ["host", "oplatka", "konvice"],
		"boss": "vridlo",
		"tint": "8fd65a",
	},
	"PLK": {
		"name": "Plzeňský kraj", "short": "Plzeňsko", "capital": "Plzeň",
		"label": [13.30, 49.62],
		"neighbors": ["KVK", "ULK", "STC", "JHC"],
		"theme": "Pivovary a Šumava",
		"desc": "Domov ležáku plzeňského typu. Sudy se kutálejí a pěna kypí přes okraj.",
		"ground": {"pattern": Ground.FIELD, "a": "c9c45a", "b": "9fae3c", "c": "e8d27a"},
		"decor": ["sudy", "smrk", "snop", "kamen", "ker"],
		"enemies": ["pena", "sud", "chmel"],
		"boss": "pivni_kral",
		"tint": "c4cf55",
	},
	"ULK": {
		"name": "Ústecký kraj", "short": "Ústecko", "capital": "Ústí nad Labem",
		"label": [13.80, 50.48],
		"neighbors": ["KVK", "PLK", "STC", "LBK"],
		"theme": "Uhelné doly a pískovcové skály",
		"desc": "Povrchové doly u Mostu a obří rypadla. Pozor na havíře a doutnající dynamit!",
		"ground": {"pattern": Ground.DIRT, "a": "8a6a4a", "b": "5e4530", "c": "2d2620"},
		"decor": ["hromada_uhli", "vozik", "piskovec", "suchy_strom", "kamen"],
		"enemies": ["havir", "uhli", "dynamit"],
		"boss": "rypadlo",
		"tint": "b39a6a",
	},
	"LBK": {
		"name": "Liberecký kraj", "short": "Liberecko", "capital": "Liberec",
		"label": [15.02, 50.70],
		"neighbors": ["ULK", "STC", "HKK"],
		"theme": "Ještěd, sklo a bižuterie",
		"desc": "Jizerské hory, sklárny a jablonecká bižuterie. Nad vším ční vysílač Ještěd.",
		"ground": {"pattern": Ground.FOREST, "a": "4f9a3a", "b": "2f6e28", "c": "7a5a36"},
		"decor": ["smrk", "krystal", "kamen", "paprad", "ker"],
		"enemies": ["banka", "brouk", "sklar"],
		"boss": "jested",
		"tint": "5fb04a",
	},
	"HKK": {
		"name": "Královéhradecký kraj", "short": "Hradecko", "capital": "Hradec Králové",
		"label": [15.72, 50.42],
		"neighbors": ["LBK", "STC", "PAK"],
		"theme": "Krkonoše a Krakonoš",
		"desc": "Sněžka, nejvyšší hora Česka. Krakonoš vládne horám i počasí.",
		"ground": {"pattern": Ground.SNOW, "a": "f4f8ff", "b": "cfdcef", "c": "9fb6d4"},
		"decor": ["snezny_smrk", "snezny_kamen", "bouda", "sanky"],
		"enemies": ["koule", "snehulak", "skritek"],
		"boss": "krakonos",
		"tint": "e6eef7",
	},
	"PAK": {
		"name": "Pardubický kraj", "short": "Pardubicko", "capital": "Pardubice",
		"label": [16.12, 49.88],
		"neighbors": ["HKK", "STC", "VYS", "JHM", "OLK"],
		"theme": "Perník a Velká pardubická",
		"desc": "Perníková města a slavné dostihy. Perníčci jsou sladcí, ale zlí.",
		"ground": {"pattern": Ground.MEADOW, "a": "7fd648", "b": "5cb52e", "c": "b98a52"},
		"decor": ["prekazka", "chaloupka", "seno", "strom", "ker"],
		"enemies": ["pernicek", "kun", "semtex"],
		"boss": "jezibaba",
		"tint": "a8d65a",
	},
	"STC": {
		"name": "Středočeský kraj", "short": "Středočesko", "capital": "Praha (sídlo kraje)",
		"label": [14.80, 49.78],
		"neighbors": ["PHA", "PLK", "ULK", "LBK", "HKK", "PAK", "VYS", "JHC"],
		"theme": "Hrady, kostnice a hora Blaník",
		"desc": "Karlštejn, kostnice v Kutné Hoře a hora Blaník, kde spí rytíři. Teď se probudili!",
		"ground": {"pattern": Ground.GRASS, "a": "78c94a", "b": "56a632", "c": "b9a98a"},
		"decor": ["vez", "nahrobek", "dub", "snop", "ker"],
		"enemies": ["kostlivec", "rytir", "lucistnik"],
		"boss": "blanik",
		"tint": "7fcf4f",
	},
	"PHA": {
		"name": "Hlavní město Praha", "short": "Praha", "capital": "Praha",
		"label": [14.44, 50.07],
		"neighbors": ["STC"],
		"theme": "Stověžatá matka měst",
		"desc": "Dlažba Starého Města, holubi, turisté a Golem. O půlnoci ožívá Orloj.",
		"ground": {"pattern": Ground.COBBLE, "a": "c4b8a2", "b": "9a8e7c", "c": "5e554a"},
		"decor": ["lampa_praha", "lavicka", "trdelnik", "kasna"],
		"enemies": ["turista", "holub", "golem"],
		"boss": "orloj",
		"tint": "e8c66a",
	},
	"JHC": {
		"name": "Jihočeský kraj", "short": "Jihočesko", "capital": "České Budějovice",
		"label": [14.35, 49.10],
		"neighbors": ["PLK", "STC", "VYS", "JHM"],
		"theme": "Rybníky a vodníci",
		"desc": "Třeboňské rybníky plné kaprů. Vodníci tu schovávají dušičky pod hrníčky.",
		"ground": {"pattern": Ground.MEADOW, "a": "6cc85a", "b": "48a24a", "c": "4aa3d8"},
		"decor": ["rakos", "leknin", "vrba", "lodka", "ker"],
		"enemies": ["kapr", "rak", "vodnik"],
		"boss": "vodnik_kral",
		"tint": "6ac77a",
	},
	"VYS": {
		"name": "Kraj Vysočina", "short": "Vysočina", "capital": "Jihlava",
		"label": [15.58, 49.40],
		"neighbors": ["JHC", "STC", "PAK", "JHM"],
		"theme": "Lesy, houby a brambory",
		"desc": "Hluboké lesy a žulové balvany. Houbaři pozor: tady houby sbírají tebe.",
		"ground": {"pattern": Ground.FOREST, "a": "5a9a3a", "b": "3c7a2c", "c": "8a6a3a"},
		"decor": ["smrk", "houby", "balvan", "parez", "paprad"],
		"enemies": ["brambora", "divocak", "muchomurka"],
		"boss": "hribi_kral",
		"tint": "6aa84a",
	},
	"JHM": {
		"name": "Jihomoravský kraj", "short": "Jižní Morava", "capital": "Brno",
		"label": [16.55, 49.05],
		"neighbors": ["JHC", "VYS", "PAK", "OLK", "ZLK"],
		"theme": "Vinice a Brněnský drak",
		"desc": "Vinohrady Pálavy, netopýři z Macochy a slavný Brněnský drak.",
		"ground": {"pattern": Ground.VINEYARD, "a": "c9a36a", "b": "a07c4a", "c": "5fae3a"},
		"decor": ["vinna_reva", "sud_vino", "sklep", "kamen", "ker"],
		"enemies": ["hrozen", "netopyr", "vinar"],
		"boss": "drak",
		"tint": "c9b06a",
	},
	"OLK": {
		"name": "Olomoucký kraj", "short": "Olomoucko", "capital": "Olomouc",
		"label": [17.10, 49.82],
		"neighbors": ["PAK", "JHM", "ZLK", "MSK"],
		"theme": "Tvarůžky, Haná a Jeseníky",
		"desc": "Úrodná Haná, voňavé olomoucké tvarůžky a duch Jeseníků.",
		"ground": {"pattern": Ground.FIELD, "a": "d8c65a", "b": "b5a43c", "c": "86c24a"},
		"decor": ["snop", "kasna", "bedna_syr", "strom", "ker"],
		"enemies": ["tvaruzek", "hanak", "praded"],
		"boss": "syrovy_kral",
		"tint": "d6c95a",
	},
	"ZLK": {
		"name": "Zlínský kraj", "short": "Zlínsko", "capital": "Zlín",
		"label": [17.78, 49.20],
		"neighbors": ["JHM", "OLK", "MSK"],
		"theme": "Valašsko a Baťovy boty",
		"desc": "Dřevěné roubenky, švestkové sady a obuvnická tradice Zlína.",
		"ground": {"pattern": Ground.GRASS, "a": "84cf48", "b": "5aa832", "c": "9a6a3a"},
		"decor": ["roubenka", "svestka_strom", "plot", "krabice", "ker"],
		"enemies": ["svestka", "bota", "valach"],
		"boss": "obri_bota",
		"tint": "9ad65a",
	},
	"MSK": {
		"name": "Moravskoslezský kraj", "short": "Ostravsko", "capital": "Ostrava",
		"label": [18.05, 49.80],
		"neighbors": ["OLK", "ZLK"],
		"theme": "Hutě, ocel a uhlí",
		"desc": "Vysoké pece Vítkovic a rozžhavená ocel. Tady se kuje železo, dokud je žhavé.",
		"ground": {"pattern": Ground.METAL, "a": "7d858c", "b": "5a6168", "c": "ff7a1a"},
		"decor": ["komin", "nosnik", "struska", "sud_olej", "vozik"],
		"enemies": ["hutnik", "ingot", "tatra"],
		"boss": "pec",
		"tint": "a0a8b0",
	},
}

## Hory a řeky na mapě (zeměpisné délky a šířky, přibližně).
const MOUNTAINS := [
	[12.75, 50.40, 1.0], [13.10, 50.52, 1.0], [13.45, 50.62, 0.9],
	[13.35, 49.12, 1.0], [13.70, 48.92, 1.1], [14.05, 48.75, 0.9],
	[15.30, 50.82, 0.8], [15.62, 50.72, 1.2], [15.90, 50.70, 1.0],
	[16.40, 50.18, 0.8], [16.85, 50.20, 0.9], [17.20, 50.06, 1.1],
	[18.25, 49.52, 1.0], [18.55, 49.50, 0.9], [13.85, 49.75, 0.7],
	[17.95, 48.98, 0.7],
]

const RIVERS := {
	"Vltava": [[14.20, 48.66], [14.32, 48.81], [14.47, 48.98], [14.40, 49.20], [14.31, 49.45], [14.38, 49.75], [14.42, 50.05], [14.40, 50.20], [14.47, 50.35]],
	"Labe": [[15.54, 50.72], [15.80, 50.40], [15.83, 50.21], [15.78, 50.04], [15.20, 50.03], [15.04, 50.19], [14.47, 50.35], [14.20, 50.52], [14.03, 50.66], [14.21, 50.78], [14.25, 50.88]],
	"Morava": [[16.85, 50.18], [17.00, 49.90], [17.25, 49.59], [17.39, 49.30], [17.46, 49.07], [17.13, 48.85], [16.95, 48.62]],
	"Odra": [[17.70, 49.60], [18.05, 49.72], [18.29, 49.84], [18.35, 49.92]],
	"Ohře": [[12.20, 50.10], [12.87, 50.23], [13.25, 50.32], [13.80, 50.38], [14.13, 50.53]],
	"Dyje": [[15.40, 48.95], [16.05, 48.85], [16.60, 48.80], [16.95, 48.62]],
}


static func get_region(id: String) -> Dictionary:
	var d: Dictionary = DATA[id].duplicate()
	d["id"] = id
	return d


static func shape(id: String) -> PackedVector2Array:
	var arr: Array = RegionShapes.SHAPES[id]
	var pts := PackedVector2Array()
	var i := 0
	while i + 1 < arr.size():
		pts.append(Vector2(arr[i], arr[i + 1]))
		i += 2
	return pts


static func label_pos(id: String) -> Vector2:
	var l: Array = DATA[id].label
	return RegionShapes.project(l[0], l[1])


## Délka přežití v sekundách: 2:30 na začátku, 4:15 na konci tažení (+ souboj s bossem).
static func duration_for_tier(tier: int) -> float:
	return 150.0 + tier * 8.0
