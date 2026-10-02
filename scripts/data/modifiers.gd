extends RefCounted
class_name ModifierDefs
## Hra po dohrání (M9): úrovně žáru a modifikátory denní výzvy.
## Logika je v Battle (násobitele v enemy_hp_mult() a spol., Director, Boss, HazardSystem).

## Úrovně žáru 1–10. Platí všechny až do zvolené úrovně (sčítají se).
const HEAT := [
	{"desc": "Nepřátelé mají +15 % životů"},
	{"desc": "Elity chodí dvakrát častěji"},
	{"desc": "O jedno přehození karet méně"},
	{"desc": "Nepřátelé jsou o 10 % rychlejší"},
	{"desc": "Boss má 4. fázi: všechny útoky a rychleji"},
	{"desc": "Léčení je o polovinu slabší"},
	{"desc": "Nástrahy kraje dvakrát častěji"},
	{"desc": "Přijdou dva náčelníci"},
	{"desc": "Hrdina má o 20 % méně životů"},
	{"desc": "Krakonošova zkouška: boss +30 % životů, útočí bez prodlev"},
]
const MAX_HEAT := 10
## Odměna: +20 % zlata za každou úroveň žáru.
const HEAT_GOLD := 0.2

## Modifikátory denní výzvy (vybírají se dva podle data).
const DAILY := {
	"jedna_zbran": {"name": "Jen jedna zbraň", "desc": "Hrdina unese jedinou zbraň, zbytek jsou předměty"},
	"rychli": {"name": "Splašení nepřátelé", "desc": "Nepřátelé jsou 2× rychlejší, ale mají méně životů"},
	"elixir_leci": {"name": "Léčivý elixír", "desc": "Každá kapka elixíru trochu vyléčí"},
	"bez_uskoku": {"name": "Bez úskoku", "desc": "Úskok nefunguje, uhýbej po svých"},
	"obri": {"name": "Obři", "desc": "Nepřátelé jsou větší a mají víc životů"},
	"zlata_horecka": {"name": "Zlatá horečka", "desc": "Zlaťáky padají pětkrát častěji"},
}
## Obtížnost denní výzvy (stejná pro všechny, nezávisí na postupu).
const DAILY_TIER := 6
const DAILY_GOLD := 100
const DAILY_STREAK_GOLD := 10
const DAILY_STREAK_MAX := 7

## Nekonečný režim: každé 2 minuty přijde náčelník, vlny dál houstnou.
const ENDLESS_CHIEF_EVERY := 120.0


static func heat_desc(level: int) -> String:
	return str(HEAT[clampi(level, 1, MAX_HEAT) - 1].desc)
