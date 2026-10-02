extends Node2D
## Vývojářská galerie: upeče a zobrazí všechny kresby (kontrola grafiky).
## Spuštění: godot --path . res://scenes/dev/gallery.tscn -- [--shot=soubor.png] [--page=N]
## Stránky: 0 hrdina, 1–2 nepřátelé, 3 bossové, 4–5 dekorace, 6 efekty a ikony, 7 nástrahy krajů,
## 8 náčelníci (nepřítel s korunou), 9 události v boji

var page := 0
var zoom := 1.0

func _ready() -> void:
	var shot := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot = a.substr(7)
		if a.begins_with("--page="):
			page = int(a.substr(7))
		if a.begins_with("--zoom="):
			zoom = float(a.substr(7))
	var jobs := []
	var ids := []
	if page == 0:
		jobs.append({"key": "hero0", "size": HeroArt.SIZE, "fn": HeroArt.draw, "t": 0.0})
		jobs.append({"key": "hero1", "size": HeroArt.SIZE, "fn": HeroArt.draw, "t": 1.0})
		ids = ["hero0", "hero1"]
	var all_enemies: Array = EnemyDefs.ENEMIES.keys()
	var start := 0 if page <= 1 else (page - 1) * 24
	var spacing := 140.0
	if page == 3:
		spacing = 260.0
		for id in EnemyDefs.BOSSES.keys():
			var key: String = "b_" + id
			jobs.append({"key": key, "size": BossArt.SIZE, "fn": func(ci, t): BossArt.draw(ci, id, t), "t": 0.0})
			ids.append(key)
	elif page == 7:
		spacing = 320.0
		for id in HazardArt.SIZES.keys():
			for t in ([0.0, 1.0] if id == "kun" else [0.0]):
				var key: String = "h_%s%s" % [id, "" if t == 0.0 else "1"]
				jobs.append({"key": key, "size": HazardArt.size_of(id), "fn": func(ci, tt): HazardArt.draw(ci, id, tt), "t": t, "origin": HazardArt.origin_of(id)})
				ids.append(key)
	elif page == 9:
		spacing = 230.0
		for id in EventDefs.ORDER:
			for t in ([0.0, 1.0] if id in ["obelisk", "truhla"] else [0.0]):
				var key: String = "v_%s%s" % [id, "" if t == 0.0 else "1"]
				jobs.append({"key": key, "size": EventArt.size_of(id), "fn": func(ci, tt): EventArt.draw(ci, id, tt), "t": t, "origin": EventArt.origin_of(id)})
				ids.append(key)
	elif page == 8:
		spacing = 175.0
		jobs.append({"key": "fx:crown", "size": FxArt.size_of("crown"), "fn": func(ci, t): FxArt.draw(ci, "crown", t)})
		for cid in EnemyDefs.MINIBOSSES.keys():
			var base: String = EnemyDefs.MINIBOSSES[cid].base
			var sz: float = EnemyDefs.get_enemy(base).size
			var key: String = "c_" + base
			jobs.append({"key": key, "size": Vector2(sz, sz), "fn": func(ci, t): EnemyArt.draw(ci, base, t), "t": 0.0})
			ids.append(key)
	elif page == 6:
		spacing = 92.0
		var fx := ["slash", "axe", "bolt", "bullet", "fireball", "meteor", "flask", "puddle", "shield", "wagon", "frost", "kapka", "pena", "uhel", "strep", "signal", "snehova", "srdce", "sip", "hvezda", "hrnicek", "spora", "hrozen", "ohen", "mlha", "syr", "hrebik", "jiskra", "xp0", "xp1", "xp2", "coin", "jidlo", "magnet", "chest"]
		for id in fx:
			var key: String = "f_" + id
			jobs.append({"key": key, "size": FxArt.size_of(id), "fn": func(ci, t): FxArt.draw(ci, id, t), "t": 1.0})
			ids.append(key)
		var icons: Array = Upgrades.WEAPONS.keys() + Upgrades.EVOLUTIONS.keys() + Upgrades.PASSIVES.keys() + ["reroll", "coin", "srdce_zlate", "hero"]
		for id in icons:
			var key: String = "i_" + id
			jobs.append({"key": key, "size": IconArt.SIZE, "fn": func(ci, t): IconArt.draw(ci, id, t), "t": 0.0})
			ids.append(key)
	elif page == 4 or page == 5:
		spacing = 170.0
		var all_props := []
		for rid in Regions.ORDER:
			for pid in Regions.DATA[rid].decor:
				if not pid in all_props:
					all_props.append(pid)
		var half := all_props.slice(0, 24) if page == 4 else all_props.slice(24)
		for id in half:
			var key: String = "p_" + id
			jobs.append({"key": key, "size": PropArt.size_of(id), "fn": func(ci, t): PropArt.draw(ci, id, t), "t": 0.0, "origin": PropArt.origin_of(id)})
			ids.append(key)
	elif page >= 1:
		for id in all_enemies.slice(start, start + 24):
			var sz: float = EnemyDefs.get_enemy(id).size
			var key: String = "e_" + id
			jobs.append({"key": key, "size": Vector2(sz, sz), "fn": func(ci, t): EnemyArt.draw(ci, id, t), "t": 0.0})
			ids.append(key)
	await Baker.bake_many(jobs)
	var x := maxf(75.0, spacing * 0.5 + 10.0) * zoom
	var y := maxf(85.0, spacing * 0.5 + 10.0) * zoom
	for k in ids:
		var s := Baker.sprite(k)
		s.position = Vector2(x, y)
		s.scale *= zoom
		if page == 7:
			s.position.y += 70.0 * zoom
		if page == 9:
			s.position.y += 60.0 * zoom
		if page == 8:
			MiniBoss.dress(s, k.substr(2))
			s.position.y += 30.0 * zoom
		add_child(s)
		var l := Label.new()
		l.text = k.substr(2)
		l.position = Vector2(x - 50, y + 50)
		l.add_theme_font_size_override("font_size", 14)
		add_child(l)
		x += spacing * zoom
		if x > 1220:
			x = maxf(75.0, spacing * 0.5 + 10.0) * zoom
			y += (spacing + 10) * zoom
	if shot != "":
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("6fcf3c"))
