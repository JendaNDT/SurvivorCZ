extends RefCounted
class_name HeroArt
## Hrdina – bojovník v železné přilbě s chocholem a pláštěm v barvách vlajky.
## Kreslí se natočený doprava, doleva se zrcadlí. Parametr t = fáze chůze (0/1).

const SIZE := Vector2(130, 164)
const SKIN := Color("f5bf8e")
const BEARD := Color("9a521f")
const STEEL := Color("c3ccd6")
const TUNIC := Color("2f6ad1")
const CAPE_RED := Color("d7262c")


static func draw(ci: CanvasItem, t: float) -> void:
	var step := 1.0 if t > 0.5 else -1.0
	# plášť (za tělem) – bílá a červená, vlaje dozadu
	var cape := Art.poly([-6, -14, -34, 34 + step * 3, -22, 40, -4, 38, 8, 0])
	Art.shape(ci, cape, CAPE_RED, 3.0)
	var cape_w := Art.poly([-6, -14, -24, 8, -12, 10, 4, -6])
	Art.safe_poly(ci, cape_w, Color("f6f6f6"))
	# nohy
	for s: int in [-1, 1]:
		var lx: float = s * 9.0
		var ly := 36.0 + step * s * 3.0
		Art.stick(ci, Vector2(lx, 24), Vector2(lx + step * s * 2.0, ly), Color("5a3a22"), 9.0, 2.5)
		Art.blob(ci, Vector2(lx + 4.0 + step * s * 2.0, ly + 4.0), 9.5, 6.0, Color("7a4520"), 2.5)
	# zadní ruka
	_arm(ci, Vector2(-14, 4), Vector2(-24, 18 - step * 2))
	# tělo – modrá tunika s opaskem a sponou
	Art.shape(ci, Art.ellipse(Vector2(0, 12), 22, 20, 32), TUNIC, 3.0)
	Art.safe_poly(ci, Art.rrect(Rect2(-21, 17, 42, 7), 3), Color("6b3e1c"))
	Art.circle(ci, Vector2(0, 20.5), 4.5, Art.GOLD, 2.0)
	Art.safe_poly(ci, Art.ellipse(Vector2(0, -4), 15, 6, 18), Color("9aa7b4"))
	# hlava
	Art.blob(ci, Vector2(3, -20), 22, 21, SKIN, 3.0)
	Art.blob(ci, Vector2(-17, -18), 4.5, 6, SKIN.darkened(0.06), 2.0, 0.3)
	# vous (pod pusou)
	var beard := Art.poly([-10, -9, 18, -9, 16, 1, 8, 9, 2, 10, -6, 4])
	Art.shape(ci, beard, BEARD, 2.5, 0.6)
	# oči a nos
	Art.eyes(ci, Vector2(7, -21), 15, 4.6, true, Vector2(0.55, 0.15))
	Art.blob(ci, Vector2(13, -13), 5.5, 5, SKIN.darkened(0.1), 2.0, 0.5)
	# knír
	for s: int in [-1, 1]:
		var tip := Vector2(10 + s * 14, -5)
		var st := Art.poly([10, -10, tip.x, tip.y - 3, tip.x + s * 3, tip.y + 3, 10, -5])
		Art.shape(ci, st, BEARD.darkened(0.1), 2.0, 0.4)
	# přilba s chocholem
	var helm := Art.arc_pts(Vector2(3, -33), 23.5, PI * 1.0, TAU, 20)
	helm.append(Vector2(26.5, -30))
	helm.append(Vector2(-20.5, -30))
	Art.shape(ci, helm, STEEL, 3.0)
	Art.flat(ci, Art.rrect(Rect2(-22, -36, 51, 7), 3), Art.GOLD, 2.0)
	for i in 4:
		Art.circle(ci, Vector2(-14 + i * 12, -32.5), 1.6, Color("fff1a8"), 0.0)
	var plume := Art.poly([-4, -54, 0, -66, 12, -72, 22, -66, 10, -60, 6, -54])
	Art.shape(ci, plume, CAPE_RED, 2.5)
	Art.circle(ci, Vector2(2, -55), 4, Art.GOLD, 2.0)
	# přední ruka s mečem
	var hand := Vector2(24, 12 + step)
	var tip2 := hand + Vector2(18, -34)
	Art.stick(ci, hand.lerp(tip2, 0.12), tip2, Color("eef3f7"), 6.5, 2.5)
	ci.draw_line(hand.lerp(tip2, 0.2), tip2.lerp(hand, 0.1), Color("aab8c4"), 1.5, true)
	Art.stick(ci, hand + Vector2(-7, -3), hand + Vector2(7, 4), Art.GOLD, 4.5, 2.0)
	_arm(ci, Vector2(14, 4), hand)


static func _arm(ci: CanvasItem, a: Vector2, b: Vector2) -> void:
	Art.stick(ci, a, b, SKIN, 9.0, 2.5)
	Art.circle(ci, b, 6.0, SKIN, 2.5)
