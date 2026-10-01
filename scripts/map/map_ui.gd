extends RefCounted
class_name MapUI
## Ovládací prvky mapy: horní lišta, karta kraje, Zbrojnice, úvod a deska.


## Dřevěná deska s nadpisem na stuze.
class Board extends Control:
	var title := ""
	var ribbon_col := Color("e2382c")

	func _draw() -> void:
		Art.panel(self, Rect2(Vector2.ZERO, size))
		if title != "":
			Art.ribbon(self, Vector2(size.x * 0.5, 4), minf(size.x * 0.8, Art.text_width(title, 34) + 90.0), 58, ribbon_col, title, 34)


## Horní lišta: logo, postup, zlato, Zbrojnice, nastavení.
class TopBar extends Control:
	var m: MapScreen
	var shop_bt: CCButton
	var gear_bt: CCButton

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		custom_minimum_size = Vector2(0, 86)
		size.y = 86
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		shop_bt = CCButton.make("Zbrojnice", Art.BTN_YELLOW, Vector2(200, 64), 24)
		shop_bt.icon_key = "ui:hammer"
		shop_bt.icon_scale = 0.45
		shop_bt.pressed.connect(func(): m.show_shop())
		add_child(shop_bt)
		gear_bt = CCButton.make("", Art.BTN_BLUE, Vector2(64, 64), 24)
		gear_bt.icon_key = "ui:gear"
		gear_bt.icon_scale = 0.5
		gear_bt.radius = 32.0
		gear_bt.pressed.connect(func(): m.show_settings())
		add_child(gear_bt)
		resized.connect(_place)
		Game.changed.connect(queue_redraw)
		_place()

	func _place() -> void:
		gear_bt.position = Vector2(size.x - 80, 12)
		shop_bt.position = Vector2(size.x - 296, 12)
		_update_badge()

	func _update_badge() -> void:
		var can := 0
		for id in Upgrades.META.keys():
			if Game.upgrade_level(id) < Upgrades.META[id].max and Game.gold() >= Game.meta_cost(id):
				can += 1
		shop_bt.badge = str(can) if can > 0 else ""
		shop_bt.queue_redraw()

	func _draw() -> void:
		_update_badge()
		# logo
		var lx := 24.0
		Art.text(self, Vector2(lx, 54), "DOBYJ", 40, Color("ffd23f"), 10, HORIZONTAL_ALIGNMENT_LEFT, 400)
		Art.text(self, Vector2(lx + Art.text_width("DOBYJ ", 40), 54), "ČESKO!", 40, Color("ff5a48"), 10, HORIZONTAL_ALIGNMENT_LEFT, 400)
		# postup
		var cx := size.x * 0.5 - 40.0
		var plate := Rect2(cx - 150, 12, 300, 62)
		Art.stone_plate(self, plate)
		var n := Game.conquered_count()
		Art.text(self, Vector2(cx, 38), "Dobyto %d / 14 krajů" % n, 21, Color.WHITE, 6)
		Art.bar(self, Rect2(cx - 120, 48, 240, 16), n / 14.0, Color("6fcf2f"))
		# zlato
		var gx := size.x - 470.0
		var gr := Rect2(gx, 22, 150, 42)
		Art.safe_poly(self, Art.rrect(gr, 21), Color(0, 0, 0, 0.4))
		Art.icon_coin(self, gr.position + Vector2(20, 21), 17)
		Art.text(self, gr.position + Vector2(44, 31), str(Game.gold()), 26, Color("ffd23f"), 7, HORIZONTAL_ALIGNMENT_LEFT, 110)


## Karta kraje: popis, nepřátelé, boss a tlačítko útoku.
class RegionCard extends Control:
	var m: MapScreen
	var region: Dictionary
	var st := ""

	func _draw() -> void:
		var r := region
		Art.panel(self, Rect2(Vector2.ZERO, size))
		var ribbon_col := Color("6fcf2f") if st == "conquered" else (Color("e2382c") if st == "available" else Color("8d8a85"))
		Art.ribbon(self, Vector2(size.x * 0.5, 4), minf(size.x * 0.82, Art.text_width(r.name, 32) + 90.0), 56, ribbon_col, r.name, 32)
		var ink := Color("4a2c12")
		var x0 := 30.0
		# boss vlevo
		var bc := Vector2(x0 + 110, 170)
		Art.circle(self, bc, 92, Color("3a2a4a"), 4.0)
		draw_circle(bc, 86, Color("5a3a7a"))
		draw_circle(bc + Vector2(0, -20), 60, Color(1, 1, 1, 0.08))
		var bkey: String = "b:%s:0" % r.boss
		if Baker.has(bkey):
			draw_texture_rect(Baker.tex(bkey), Rect2(bc - Vector2(92, 98), Vector2(184, 184)), false)
		var bdef: Dictionary = EnemyDefs.BOSSES[r.boss]
		Art.text(self, Vector2(bc.x, bc.y + 118), "BOSS", 16, Color("ff8a6a"), 5)
		draw_string(Art.font, Vector2(bc.x - 120, bc.y + 142), bdef.name, HORIZONTAL_ALIGNMENT_CENTER, 240, 20, ink)
		draw_string(Art.font, Vector2(bc.x - 120, bc.y + 164), bdef.title, HORIZONTAL_ALIGNMENT_CENTER, 240, 14, Color("7a5a3a"))
		# text vpravo
		var tx := x0 + 240.0
		var tw := size.x - tx - 30.0
		draw_string(Art.font, Vector2(tx, 82), r.theme, HORIZONTAL_ALIGNMENT_LEFT, tw, 24, Color("8a3a12"))
		draw_multiline_string(Art.font, Vector2(tx, 112), r.desc, HORIZONTAL_ALIGNMENT_LEFT, tw, 17, 3, ink)
		draw_string(Art.font, Vector2(tx, 186), "Nepřátelé:", HORIZONTAL_ALIGNMENT_LEFT, tw, 17, Color("7a5a3a"))
		for i in r.enemies.size():
			var eid: String = r.enemies[i]
			var c := Vector2(tx + 46 + i * 116, 236)
			Art.circle(self, c, 36, Color("e9dcc0"), 3.0)
			var key := "e:%s:0" % eid
			if Baker.has(key):
				var tex := Baker.tex(key)
				var s := tex.get_size() / Baker.SCALE * 0.72
				draw_texture_rect(tex, Rect2(c - s * 0.5, s), false)
			var nm: String = EnemyDefs.ENEMIES[eid].name
			var nfs := 13 if Art.text_width(nm, 13) < 112 else 11
			draw_string(Art.font, Vector2(c.x - 58, c.y + 54), nm, HORIZONTAL_ALIGNMENT_CENTER, 116, nfs, ink)
		# info
		var tier := Game.tier_for(r.id)
		var dur := Regions.duration_for_tier(tier)
		var yy := 318.0
		draw_string(Art.font, Vector2(tx, yy), "Přežij %d:%02d, pak poraz bosse" % [int(dur) / 60, int(dur) % 60], HORIZONTAL_ALIGNMENT_LEFT, tw, 18, ink)
		draw_string(Art.font, Vector2(tx, yy + 28), "Síla nepřátel:", HORIZONTAL_ALIGNMENT_LEFT, tw, 18, ink)
		var sx := tx + Art.text_width("Síla nepřátel: ", 18) + 6.0
		for i in 5:
			var filled := i <= int(tier / 3.0)
			var c := Vector2(sx + i * 22, yy + 22)
			Art.safe_poly(self, Art.grow(Art.ellipse(c, 7, 7, 12), 1.5), Art.OUTLINE)
			Art.safe_poly(self, Art.ellipse(c, 7, 7, 12), Color("e2382c") if filled else Color("c9b894"))
		if st == "conquered":
			var n := Game.stars(r.id)
			draw_string(Art.font, Vector2(tx, yy + 58), "Získané hvězdy:", HORIZONTAL_ALIGNMENT_LEFT, tw, 18, ink)
			for i in 3:
				var c := Vector2(tx + Art.text_width("Získané hvězdy: ", 18) + 14 + i * 26, yy + 51)
				Art.icon_star(self, c, 11, i < n)
		elif st == "locked":
			draw_string(Art.font, Vector2(tx, yy + 58), "Nejdřív dobyj některý sousední kraj.", HORIZONTAL_ALIGNMENT_LEFT, tw, 17, Color("a03a2a"))


## Zbrojnice – trvalá vylepšení za zlato.
class ShopBoard extends Control:
	var m: MapScreen

	func build() -> void:
		for c in get_children():
			if c is CCButton and c.size.x > 60:
				c.queue_free()
		var ids: Array = Upgrades.META.keys()
		var cols := 5
		var cw := (size.x - 60.0 - (cols - 1) * 12.0) / cols
		var ch := 200.0
		for i in ids.size():
			var id: String = ids[i]
			var col := i % cols
			var row := i / cols
			var pos := Vector2(30 + col * (cw + 12.0), 96 + row * (ch + 18.0))
			var def: Dictionary = Upgrades.META[id]
			var lvl := Game.upgrade_level(id)
			var maxed: bool = lvl >= def.max
			var cost := Game.meta_cost(id)
			var bt := CCButton.make("MAX" if maxed else str(cost), Art.BTN_GREY if maxed else (Art.BTN_GREEN if Game.gold() >= cost else Art.BTN_RED), Vector2(cw - 30, 50), 24)
			if not maxed:
				bt.icon_key = "icon:coin"
				bt.icon_scale = 0.38
			bt.disabled = maxed
			bt.position = pos + Vector2(15, ch - 64)
			bt.pressed.connect(func():
				if Game.buy_upgrade(id):
					Sfx.play("coin")
					Sfx.play("levelup", -6.0)
				else:
					Sfx.play("hurt", -8.0)
				build()
				queue_redraw())
			add_child(bt)
		queue_redraw()

	func _draw() -> void:
		Art.panel(self, Rect2(Vector2.ZERO, size))
		Art.ribbon(self, Vector2(size.x * 0.5, 4), 330, 58, Color("ffb030"), "ZBROJNICE", 34)
		var gold_r := Rect2(30, 40, 170, 40)
		Art.safe_poly(self, Art.rrect(gold_r, 20), Color(0, 0, 0, 0.3))
		Art.icon_coin(self, gold_r.position + Vector2(20, 20), 16)
		Art.text(self, gold_r.position + Vector2(44, 30), str(Game.gold()), 24, Color("ffd23f"), 6, HORIZONTAL_ALIGNMENT_LEFT, 120)
		draw_string(Art.font, Vector2(size.x - 430, 66), "Vylepšení platí ve všech krajích.", HORIZONTAL_ALIGNMENT_RIGHT, 400, 16, Color("6b4a2a"))
		var ids: Array = Upgrades.META.keys()
		var cols := 5
		var cw := (size.x - 60.0 - (cols - 1) * 12.0) / cols
		var ch := 200.0
		var ink := Color("4a2c12")
		for i in ids.size():
			var id: String = ids[i]
			var def: Dictionary = Upgrades.META[id]
			var pos := Vector2(30 + (i % cols) * (cw + 12.0), 96 + (i / cols) * (ch + 18.0))
			var r := Rect2(pos, Vector2(cw, ch))
			Art.safe_poly(self, Art.rrect(Rect2(r.position + Vector2(0, 4), r.size), 14), Color(0, 0, 0, 0.18))
			Art.flat(self, Art.rrect(r, 14), Color("fff3d6"), 2.5)
			var ic := Vector2(r.position.x + 40, r.position.y + 44)
			Art.circle(self, ic, 30, Color("e9d3a0"), 2.5)
			var key: String = "icon:" + def.icon
			if Baker.has(key):
				draw_texture_rect(Baker.tex(key), Rect2(ic - Vector2(28, 28), Vector2(56, 56)), false)
			var nfs := 18 if Art.text_width(def.name, 18) < cw - 82 else 15
			draw_string(Art.font, Vector2(r.position.x + 76, r.position.y + 34), def.name, HORIZONTAL_ALIGNMENT_LEFT, cw - 80, nfs, ink)
			var lvl := Game.upgrade_level(id)
			for k in def.max:
				var c := Vector2(r.position.x + 82 + k * 16, r.position.y + 52)
				Art.safe_poly(self, Art.grow(Art.ellipse(c, 5.5, 5.5, 10), 1.5), Art.OUTLINE)
				Art.safe_poly(self, Art.ellipse(c, 5.5, 5.5, 10), Color("6fcf2f") if k < lvl else Color("c9b894"))
			draw_multiline_string(Art.font, Vector2(r.position.x + 12, r.position.y + 96), def.desc, HORIZONTAL_ALIGNMENT_CENTER, cw - 24, 15, 2, Color("6b4a2a"))


## Úvodní obrazovka s logem a návodem.
class IntroBoard extends Control:
	var m: MapScreen
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		Art.panel(self, Rect2(Vector2.ZERO, size))
		var cx := size.x * 0.5
		var bob := sin(t * 2.0) * 4.0
		Art.text(self, Vector2(cx - 120, 92 + bob), "DOBYJ", 72, Color("ffd23f"), 16)
		Art.text(self, Vector2(cx + 150, 92 - bob), "ČESKO!", 72, Color("ff5a48"), 16)
		Art.text(self, Vector2(cx, 134), "Survivor strategie o 14 krajích", 22, Color("fff6c8"), 6)
		if Baker.has("hero:0"):
			var tex := Baker.tex("hero:0")
			var s := tex.get_size() / Baker.SCALE * 1.4
			draw_texture_rect(tex, Rect2(Vector2(36, 170 + bob), s * 0.9), false)
		var ink := Color("4a2c12")
		var lines := [
			"Začni v Karlovarsku. Dobytý kraj odemkne sousedy.",
			"Joystickem se pohybuješ, hrdina útočí sám.",
			"Sbírej růžový elixír a vybírej vylepšení.",
			"Přežij do konce časomíry a poraz bosse kraje.",
			"Úskok tě chvíli chrání, Hrom zasáhne vše kolem.",
			"Za zlato kupuj trvalá vylepšení ve Zbrojnici.",
		]
		for i in lines.size():
			var y := 196.0 + i * 42.0
			Art.circle(self, Vector2(262, y - 7), 12, Color("6fcf2f"), 2.0)
			Art.text(self, Vector2(262, y), str(i + 1), 15, Color.WHITE, 4)
			draw_string(Art.font, Vector2(284, y), lines[i], HORIZONTAL_ALIGNMENT_LEFT, size.x - 300, 18, ink)


## Stuha s oznámením, která po chvíli zmizí.
class Toast extends Control:
	var text := ""
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		if t > 4.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := clampf(t / 0.3, 0.0, 1.0) * clampf((4.0 - t) / 0.5, 0.0, 1.0)
		modulate.a = a
		var w := Art.text_width(text, 28) + 90.0
		Art.ribbon(self, Vector2(size.x * 0.5, 34), w, 58, Color("ffb030"), text, 28)
