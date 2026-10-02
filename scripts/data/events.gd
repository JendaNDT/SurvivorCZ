extends RefCounted
class_name EventDefs
## Události v boji (M7): ve 30 % a 65 % času se kousek od hrdiny objeví jedna z nich.
## Když ji hráč 40 s nechá být, zmizí. Logika je v scripts/battle/events.gd,
## kresby v scripts/art/event_art.gd, dialogy v scripts/ui/battle_overlay.gd.
##
## r = poloměr, ve kterém událost reaguje na hrdinu (u truhly okruh, kde se počítají zabití)

const ORDER := ["oltar", "muka", "obelisk", "kramar", "truhla"]

const DATA := {
	"oltar": {"name": "Oltář", "hint": "Obětuj životy nebo zlato za vzácnou kartu", "col": "b25cff", "r": 70.0,
		"hp_cost": 0.2, "gold_cost": 50},
	"muka": {"name": "Boží muka", "hint": "Postůj 5 s v kruhu a získáš požehnání", "col": "ffd23f", "r": 95.0,
		"stand": 5.0, "dur": 60.0},
	"obelisk": {"name": "Prokletý obelisk", "hint": "Dotkni se ho a poraz kletbu: 3 elity a vlna", "col": "ff4d6d", "r": 70.0,
		"elites": 3},
	"kramar": {"name": "Kramář s vozíkem", "hint": "Nakup za zlato, které máš z kraje", "col": "ffb310", "r": 85.0},
	"truhla": {"name": "Zamčená truhla", "hint": "Otevře se, když u ní padne 40 nepřátel", "col": "3fa8ff", "r": 260.0,
		"kills": 40},
}

## Požehnání z božích muk (trvá `dur` sekund). icon = upečená ikona pro HUD a tlačítko.
const BLESSINGS := {
	"sila": {"name": "Síla", "desc": "+30 % poškození", "icon": "icon:sila"},
	"rychlost": {"name": "Rychlost", "desc": "+30 % rychlosti", "icon": "icon:boty"},
	"magnet": {"name": "Magnet", "desc": "dvojnásobný dosah sběru", "icon": "icon:magnet"},
	"regen": {"name": "Uzdravení", "desc": "+3 životy za sekundu", "icon": "icon:voda"},
}

## Zboží kramáře za zlato z kraje (dá se koupit víckrát).
const SHOP := [
	{"id": "svickova", "name": "Svíčková", "desc": "vyléčí polovinu života", "price": 15, "icon": "fx:jidlo"},
	{"id": "prehozeni", "name": "Přehození", "desc": "+1 přehození karet", "price": 10, "icon": "icon:reroll"},
	{"id": "karta", "name": "Vzácná karta", "desc": "náhodné vylepšení", "price": 30, "icon": "icon:kniha"},
	{"id": "magnet", "name": "Magnet", "desc": "přitáhne všechen elixír", "price": 8, "icon": "fx:magnet"},
]


static func get_for(id: String) -> Dictionary:
	return DATA.get(id, {})
