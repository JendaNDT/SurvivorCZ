extends Button
class_name UpgradeCard
## Karta vylepšení při postupu na další úroveň (rámeček podle vzácnosti).

var card: Dictionary
var b: Battle
var hover_t := 0.0


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(st, empty)
	resized.connect(func(): pivot_offset = size * 0.5)
	button_down.connect(_on_down)
	button_up.connect(_on_up)


func _on_down() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(0.95, 0.95), 0.06)


func _on_up() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)


func info() -> Dictionary:
	var c := card
	var out := {"name": "", "desc": "", "icon": "", "rarity": 0, "level": 0, "max": 0, "tag": "", "tags": [], "new": false}
	match c.type:
		"weapon_new", "weapon_up":
			var d: Dictionary = Upgrades.WEAPONS[c.id]
			out.name = d.name
			out.icon = c.id
			out.level = c.level
			out.max = Upgrades.WEAPON_MAX_LEVEL
			out.tags = d.tags
			out.new = c.type == "weapon_new"
			out.desc = d.desc if out.new else Upgrades.level_text(c.id, c.level)
			out.tag = "NOVÁ ZBRAŇ" if out.new else "ZBRAŇ"
		"evo":
			var d: Dictionary = Upgrades.EVOLUTIONS[c.id]
			out.name = d.name
			out.icon = c.id
			out.desc = d.desc
			out.rarity = 3
			out.tags = d.tags
			out.tag = "EVOLUCE!"
		"passive":
			var d: Dictionary = Upgrades.PASSIVES[c.id]
			out.name = d.name
			out.icon = c.id
			out.rarity = c.rarity
			out.level = c.level
			out.max = d.get("max", Upgrades.PASSIVE_MAX_LEVEL)
			out.tags = d.tags
			out.new = c.level == 1
			out.desc = Upgrades.passive_text(c.id, c.rarity)
			var evo_for := ""
			for wid in Upgrades.WEAPONS.keys():
				if Upgrades.WEAPONS[wid].evo_with == c.id:
					evo_for = Upgrades.WEAPONS[wid].name
			if evo_for != "":
				out.desc += "\nEvoluce: " + evo_for
			out.tag = Art.RARITY_NAMES[c.rarity].to_upper()
		"gold":
			out.name = "Měšec zlata"
			out.icon = "coin"
			out.desc = "+%d zlata" % c.amount
			out.tag = "ODMĚNA"
		"heal":
			out.name = "Svíčková"
			out.icon = "srdce"
			out.desc = "Vyléčí polovinu životů"
			out.tag = "ODMĚNA"
	return out


func _process(delta: float) -> void:
	hover_t += delta
	if card.get("rarity", 0) >= 2 or card.type == "evo":
		queue_redraw()


func _draw() -> void:
	var inf := info()
	var rc: Color = Art.RARITY_COLORS[inf.rarity]
	var r := Rect2(Vector2.ZERO, size)
	# záře pro vzácné karty
	if inf.rarity >= 2:
		var a := 0.25 + 0.15 * sin(hover_t * 4.0)
		Art.safe_poly(self, Art.rrect(r.grow(8), 26), Color(rc, a))
	Art.shadow_rect(self, Rect2(r.position + Vector2(4, 8), r.size), 20)
	var outer := Art.rrect(r, 20)
	Art.outline(self, outer, 4.0)
	Art.grad(self, outer, rc.lightened(0.3), rc.darkened(0.25))
	var inner_r := r.grow(-9)
	inner_r.position.y += 30
	inner_r.size.y -= 30
	var inner := Art.rrect(inner_r, 14)
	Art.outline(self, inner, 2.5)
	Art.grad(self, inner, Art.PARCHMENT.lightened(0.1), Art.PARCHMENT_DARK)
	# štítek nahoře
	Art.text(self, Vector2(size.x * 0.5, 30), inf.tag, 19, Color.WHITE, 6)
	# ikona v kruhu
	var ic := Vector2(size.x * 0.5, 104)
	Art.circle(self, ic, 50, Color("fff6dc"), 3.5)
	draw_circle(ic, 44, Color(rc, 0.25))
	if Baker.has("icon:" + inf.icon):
		draw_texture_rect(Baker.tex("icon:" + inf.icon), Rect2(ic - Vector2(44, 44), Vector2(88, 88)), false)
	if inf.new:
		var nb := Vector2(size.x - 34, 66)
		var pts := Art.star(nb, 26, 18, 10)
		Art.shape(self, pts, Color("e2382c"), 2.5, 0.4)
		Art.text(self, nb + Vector2(0, 5), "NOVÉ", 13, Color.WHITE, 4)
	# název
	Art.text(self, Vector2(size.x * 0.5, 186), inf.name, 25 if inf.name.length() < 16 else 21, Color.WHITE, 7)
	# hvězdičky úrovně
	if inf.max > 0:
		var n: int = inf.max
		var sw := minf(22.0, (size.x - 40) / n)
		var x0 := size.x * 0.5 - sw * (n - 1) * 0.5
		for i in n:
			var c := Vector2(x0 + i * sw, 212)
			var pts := Art.star(c, sw * 0.42, sw * 0.2)
			if i < inf.level:
				Art.safe_poly(self, Art.grow(pts, 1.5), Art.OUTLINE)
				Art.safe_poly(self, pts, Art.GOLD)
			else:
				Art.safe_poly(self, pts, Color(0.3, 0.2, 0.1, 0.35))
	# popis
	draw_multiline_string(Art.font, Vector2(18, 246), inf.desc, HORIZONTAL_ALIGNMENT_CENTER, size.x - 36, 18, 4, Color("4a2c12"))
	# štítky tagů
	var tags: Array = inf.tags
	if not tags.is_empty():
		var tw := 0.0
		for t in tags:
			tw += Art.text_width(Upgrades.TAG_NAMES[t], 13) + 18.0
		var x := size.x * 0.5 - tw * 0.5
		for t in tags:
			var label: String = Upgrades.TAG_NAMES[t]
			var w := Art.text_width(label, 13) + 14.0
			var tr := Rect2(x, size.y - 38, w, 22)
			Art.safe_poly(self, Art.rrect(tr, 11), Color(Upgrades.TAG_COLORS[t]))
			draw_string(Art.font, Vector2(x + 7, size.y - 22), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("2a1a0c"))
			x += w + 4.0
