extends Node2D
class_name Battle
## Bitva o jeden kraj: přežij časový limit, pak poraz bosse.
## Spojuje všechny systémy (hráč, nepřátelé, zbraně, střely, sběr, režisér, boss)
## a stará se o zkušenosti, výběr vylepšení, výhru a prohru.

enum State { LOADING, PLAY, LEVELUP, PAUSE, BOSS_INTRO, BOSS, WIN, LOSE }

signal finished(action: String)

const ULT_KILLS := 70.0
const ARENA_R := 420.0
const CHUNK := 640.0

var region_id := "KVK"
var region: Dictionary
## Hrdina této bitvy (M8) a jeho data z HeroDefs.
var hero_id := "cech"
var hero: Dictionary
var tier := 0
var duration := 150.0
var elapsed := 0.0
var state := State.LOADING
var resume_state := State.PLAY

var world: Node2D
var ground: ColorRect
var ground_mat: ShaderMaterial
var ground_fx_layer: Node2D
var ground_fx: GroundFx
var shadow_layer: Node2D
var pickup_layer: Node2D
var entity_layer: Node2D
var proj_layer: Node2D
var fx: Fx
var camera: Camera2D
var ui_layer: CanvasLayer
var hud: Hud
var controls: TouchControls
var overlay: BattleOverlay

var player: Player
var enemies: EnemyManager
var weapons: WeaponSystem
var projectiles: ProjectileSystem
var pickups: PickupSystem
var director: Director
var hazards: HazardSystem
var boss: Boss = null
## Náčelník v polovině kraje (null, když zrovna není).
var chief: MiniBoss = null
var chief_start := 0.0

var stats := {}
var level := 1
var xp := 0.0
var xp_need := 10.0
var kills := 0
var gold_run := 0
var rerolls := 2
var ult := 0.0
var revive_left := 0
var pending_levelups := 0
var pending_chests := 0
var pending_chief := 0
var pending_legend := 0
## Požehnání z božích muk: id -> zbývající sekundy (M7).
var buffs := {}
var events: EventSystem
var arena_center := Vector2.ZERO
var arena_radius := 0.0
var shake_amt := 0.0
var dmg_taken := 0.0
var boss_start := 0.0
var boss_time := 0.0
var chunks := {}
var chunk_t := 0.0
var offers_without_weapon := 0
var autoplay := false
var stars := 0
var time_total := 0.0
var low_quality := false
## Měření plynulosti v první bitvě (pod 40 FPS mapa nabídne úspornou grafiku).
var perf_frames := 0
var perf_time := 0.0
var bench := false
## Krátké zastavení při zásahu (hitstop) a zpomalení po smrti bosse.
var slowmo := false
var stop_serial := 0
var stop_end_ms := 0
var crit_stop_t := -10.0
var stops := 0
## Cuknutí kamery při kritickém zásahu.
var kick := Vector2.ZERO
var kick_t := -10.0
## Prach pod nohama podle země kraje.
var dust_col := Color(0.62, 0.55, 0.36, 0.7)
var dust_spark := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	low_quality = Game.low_quality()
	region = Regions.get_region(region_id)
	tier = Game.tier_for(region_id)
	hero_id = Game.hero()
	var arg_hero := _arg(OS.get_cmdline_user_args(), "--hero=")
	if HeroDefs.DATA.has(arg_hero):
		hero_id = arg_hero
	hero = HeroDefs.get_hero(hero_id)
	duration = Regions.duration_for_tier(tier)
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a == "--autoplay":
			autoplay = true
		if a.begins_with("--tier="):
			tier = int(a.substr(7))
			duration = Regions.duration_for_tier(tier)
	for a in args:
		if a.begins_with("--duration="):
			duration = float(a.substr(11))
	# test nástupu a smrti konkrétního bosse v libovolném kraji
	var test_boss := _arg(args, "--test-bossdeath=") + _arg(args, "--test-bossintro=")
	if test_boss != "" and EnemyDefs.BOSSES.has(test_boss):
		region = region.duplicate()
		region.boss = test_boss
	_build_layers()
	await _bake()
	_start()


# ---------------------------------------------------------------- stavba scény

func _build_layers() -> void:
	world = Node2D.new()
	add_child(world)
	ground = ColorRect.new()
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground_mat = ShaderMaterial.new()
	ground_mat.shader = load("res://shaders/ground.gdshader")
	var g: Dictionary = region.ground
	ground_mat.set_shader_parameter("pattern", g.pattern)
	_pick_dust(int(g.pattern))
	ground_mat.set_shader_parameter("col_a", Color(g.a))
	ground_mat.set_shader_parameter("col_b", Color(g.b))
	ground_mat.set_shader_parameter("col_c", Color(g.c))
	ground_mat.set_shader_parameter("quality", 0 if low_quality else 1)
	# rybníky a praskliny kreslí nástraha kraje, ne shader
	ground_mat.set_shader_parameter("hazard_off", 1 if HazardDefs.get_for(region_id).get("shader_off", false) else 0)
	ground.material = ground_mat
	world.add_child(ground)
	ground_fx_layer = Node2D.new()
	world.add_child(ground_fx_layer)
	shadow_layer = Node2D.new()
	world.add_child(shadow_layer)
	# varování a prach až nad stíny, ať je stín hrdiny nepřekryje
	ground_fx = GroundFx.new()
	world.add_child(ground_fx)
	pickup_layer = Node2D.new()
	world.add_child(pickup_layer)
	entity_layer = Node2D.new()
	entity_layer.y_sort_enabled = true
	world.add_child(entity_layer)
	proj_layer = Node2D.new()
	world.add_child(proj_layer)
	fx = Fx.new()
	world.add_child(fx)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * 0.92
	world.add_child(camera)
	camera.make_current()
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)


## Barva prachu pod nohama: tráva zelenohnědá, pole a vinice písková, hlína hnědá,
## dlažba šedá, sníh bílý, na plechu odletují jiskry.
func _pick_dust(pattern: int) -> void:
	match pattern:
		Regions.Ground.FIELD, Regions.Ground.VINEYARD:
			dust_col = Color(0.74, 0.62, 0.4, 0.7)
		Regions.Ground.DIRT:
			dust_col = Color(0.45, 0.34, 0.25, 0.6)
		Regions.Ground.COBBLE:
			dust_col = Color(0.8, 0.77, 0.72, 0.5)
		Regions.Ground.SNOW:
			dust_col = Color(0.82, 0.88, 0.98, 0.95)
		Regions.Ground.METAL:
			dust_col = Color("ffb030")
			dust_spark = true
		_:
			dust_col = Color(0.62, 0.55, 0.36, 0.7)


func dust_at(pos: Vector2) -> void:
	if dust_spark:
		for i in (2 if low_quality else 3):
			ground_fx.puff(pos, dust_col, true)
	else:
		ground_fx.puff(pos, dust_col)


func _bake() -> void:
	var jobs := []
	var hid := hero_id
	for t in 2:
		jobs.append({"key": "hero:%s:%d" % [hid, t], "size": HeroArt.size_of(hid), "fn": func(ci, tt): HeroArt.draw(ci, tt, hid), "t": float(t)})
	jobs.append({"key": "shadow", "size": Vector2(44, 20), "fn": func(ci, _t): Art.safe_poly(ci, Art.ellipse(Vector2.ZERO, 20, 8, 24), Color(0, 0, 0, 0.3))})
	var glow_fn := func(ci: CanvasItem, _t: float) -> void:
		for k in 6:
			ci.draw_circle(Vector2.ZERO, 70 - k * 9, Color(1, 0.85, 0.2, 0.08 + k * 0.03))
	jobs.append({"key": "elite_glow", "size": Vector2(150, 150), "fn": glow_fn})
	for id in region.enemies:
		for t in 2:
			jobs.append({"key": "e:%s:%d" % [id, t], "size": Vector2.ONE * EnemyDefs.get_enemy(id).size, "fn": func(ci, tt): EnemyArt.draw(ci, id, tt), "t": float(t)})
	var bid: String = region.boss
	for t in 2:
		jobs.append({"key": "b:%s:%d" % [bid, t], "size": BossArt.SIZE, "fn": func(ci, tt): BossArt.draw(ci, bid, tt), "t": float(t)})
	var fx_ids := ["slash", "slash_gold", "axe", "bolt", "bullet", "fireball", "meteor", "flask", "puddle", "shield", "wagon", "frost", "xp0", "xp1", "xp2", "coin", "jidlo", "magnet", "chest"]
	fx_ids.append(EnemyDefs.BOSSES[bid].proj)
	fx_ids.append("crown")
	if region.has("chief"):
		fx_ids.append(EnemyDefs.MINIBOSSES[region.chief].proj)
	for id in region.enemies:
		var p = EnemyDefs.ENEMIES[id].get("proj")
		if p != null:
			fx_ids.append(p)
	for id in fx_ids:
		jobs.append({"key": "fx:" + id, "size": FxArt.size_of(id), "fn": func(ci, tt): FxArt.draw(ci, id, tt), "t": 1.0 if id == "chest" else 0.0})
	for id in region.decor + ["kul"]:
		jobs.append({"key": "prop:" + id, "size": PropArt.size_of(id), "fn": func(ci, tt): PropArt.draw(ci, id, tt), "origin": PropArt.origin_of(id)})
	jobs.append_array(HazardSystem.bake_jobs(region_id))
	jobs.append_array(EventSystem.bake_jobs())
	jobs.append_array(Main.icon_jobs())
	await Baker.bake_many(jobs)


func _start() -> void:
	enemies = EnemyManager.new()
	add_child(enemies)
	enemies.init(self)
	weapons = WeaponSystem.new()
	add_child(weapons)
	weapons.init(self)
	projectiles = ProjectileSystem.new()
	add_child(projectiles)
	projectiles.init(self)
	pickups = PickupSystem.new()
	add_child(pickups)
	pickups.init(self)
	director = Director.new()
	add_child(director)
	director.init(self)
	hazards = HazardSystem.new()
	add_child(hazards)
	hazards.init(self)
	events = EventSystem.new()
	world.add_child(events)
	world.move_child(events, ground_fx.get_index() + 1)
	events.init(self)
	player = Player.new()
	entity_layer.add_child(player)
	player.init(self)
	apply_quality()
	Game.setting_changed.connect(_on_setting)
	rerolls = 2 + int(Game.meta_value("m_reroll")) + int(HeroDefs.mod(hero_id, "rerolls", 0))
	revive_left = int(Game.meta_value("m_revive"))
	recalc_stats()
	player.hp = player.max_hp
	xp_need = need_for(level)
	weapons.add_weapon(str(hero.start))
	for k in int(hero.get("start_level", 1)) - 1:
		weapons.level_weapon(str(hero.start))
	if hero.has("start2"):
		weapons.add_weapon(str(hero.start2))
	camera.position = player.position
	hud = Hud.new()
	hud.b = self
	ui_layer.add_child(hud)
	controls = TouchControls.new()
	controls.b = self
	ui_layer.add_child(controls)
	overlay = BattleOverlay.new()
	overlay.b = self
	ui_layer.add_child(overlay)
	state = State.PLAY
	Sfx.start_music("battle")
	banner(region.name, Color("ffd23f"), region.theme)
	_update_chunks(true)
	_dev_tests()
	if int(Game.data.stats.get("runs", 0)) + int(Game.data.stats.get("defeats", 0)) == 0:
		await get_tree().create_timer(2.6, false).timeout
		banner("Táhni prstem vlevo!", Color("3fa8ff"), "Hrdina útočí sám, ty se jen hýbej")


## Vývojářské parametry pro snímky obrazovky jednotlivých oken.
func _dev_tests() -> void:
	var args := OS.get_cmdline_user_args()
	if "--test-levelup" in args or "--test-chest" in args:
		weapons.add_weapon("kuse")
		weapons.add_passive("kniha", 2)
		await get_tree().create_timer(1.5, false).timeout
		if "--test-chest" in args:
			open_chest()
		else:
			add_xp(xp_need)
	elif "--test-evo=A" in args or "--test-evo=B" in args:
		var set_a := "--test-evo=A" in args
		var ids: Array = ["mec", "sekera", "kuse", "ohen", "blesk"] if set_a else ["aura", "stity", "jed"]
		weapons.weapons.clear()
		for id in ids:
			weapons.add_weapon(id)
			for k in 7:
				weapons.level_weapon(id)
			weapons.add_passive(Upgrades.WEAPONS[id].evo_with, 0)
			weapons.evolve(Upgrades.WEAPONS[id].evo)
		print("evoluce: ", weapons.weapons.map(func(w): return w.id))
	elif "--test-win" in args:
		await get_tree().create_timer(1.0, false).timeout
		boss_time = 42.0
		win()
		if "--then-map" in args:
			await get_tree().create_timer(1.5, true).timeout
			leave("map")
	elif "--test-lose" in args or _arg(args, "--test-lose=") != "":
		var t := float(_arg(args, "--test-lose=")) if _arg(args, "--test-lose=") != "" else 1.0
		await get_tree().create_timer(t, false).timeout
		lose()
		if "--then-map" in args:
			await get_tree().create_timer(1.5, true).timeout
			leave("map")
	elif "--test-pause" in args or "--test-settings" in args:
		await get_tree().create_timer(1.0, false).timeout
		pause_game()
		if "--test-settings" in args:
			overlay.show_settings()
	elif "--bench" in args:
		_bench()
	elif "--test-bossintro" in args or _arg(args, "--test-bossintro=") != "":
		await get_tree().create_timer(0.5, false).timeout
		start_boss()
	elif "--test-bossdeath" in args or _arg(args, "--test-bossdeath=") != "":
		player.invuln = 1.0e9
		await get_tree().create_timer(0.5, false).timeout
		start_boss()
		while boss == null or boss.intro_t > 0.0:
			await get_tree().process_frame
		await get_tree().create_timer(0.4, false).timeout
		boss.hp = 0.0
	elif _arg(args, "--test-event=") != "":
		gold_run = 100
		await get_tree().create_timer(1.0, false).timeout
		events.spawn(_arg(args, "--test-event="), player.position + Vector2(0, 40))
	elif "--test-ult" in args:
		player.invuln = 1.0e9
		await get_tree().create_timer(1.0, false).timeout
		for k in 24:
			enemies.spawn(region.enemies[k % region.enemies.size()], player.position + Vector2.from_angle(TAU * k / 24.0) * 260.0, {"force": true})
		await get_tree().create_timer(1.2, false).timeout
		ult = 1.0
		use_ult()
	elif "--test-miniboss" in args:
		await get_tree().create_timer(1.5, false).timeout
		spawn_chief()
	elif "--test-chief-chest" in args or "--test-chief-chest=evo" in args:
		weapons.add_weapon("kuse")
		weapons.add_passive("kniha", 2)
		if "--test-chief-chest=evo" in args:
			for k in 7:
				weapons.level_weapon("mec")
			weapons.add_passive(Upgrades.WEAPONS["mec"].evo_with, 0)
		await get_tree().create_timer(1.5, false).timeout
		open_chest(2)


## Úsporná grafika: méně nepřátel naráz, bez stínů, méně částic a dekorací, jednodušší země.
func apply_quality() -> void:
	low_quality = Game.low_quality()
	enemies.cap = EnemyManager.CAP_LOW if low_quality else EnemyManager.CAP_HIGH
	fx.set_low(low_quality)
	ground_mat.set_shader_parameter("quality", 0 if low_quality else 1)


func _on_setting(key: String) -> void:
	if key == "quality":
		apply_quality()


func _arg(args: PackedStringArray, prefix: String) -> String:
	for x in args:
		if x.begins_with(prefix):
			return x.substr(prefix.length())
	return ""


# ---------------------------------------------------------------- herní smyčka

func _process(delta: float) -> void:
	if state == State.LOADING:
		return
	if state == State.PLAY and elapsed > 10.0 and not Game.data.perf_checked and not low_quality:
		perf_frames += 1
		perf_time += delta
	if bench:
		_bench_fill()
	delta = minf(delta, 1.0 / 30.0)
	if autoplay and int(time_total / 10.0) != int((time_total + delta) / 10.0):
		print("[t=%5.1f] stav=%d lvl=%d hp=%d/%d zabito=%d nepřátel=%d zbraně=%s boss=%s" % [time_total + delta, state, level, int(player.hp), int(player.max_hp), kills, enemies.count(), str(weapons.weapons.map(func(w): return "%s%d" % [w.id, w.level])), ("%d/%d" % [int(boss.hp), int(boss.max_hp)]) if boss else "-"])
	if int(time_total * 0.5) != int((time_total + delta) * 0.5):
		var st_names := ["načítání", "přežívání", "výběr karty", "pauza", "příchod bosse", "boss", "výhra", "prohra"]
		var extra := (", boss %d %%" % int(100.0 * maxf(0.0, boss.hp) / boss.max_hp)) if boss else ""
		if chief:
			extra += ", náčelník %d %%" % int(100.0 * maxf(0.0, chief.hp) / chief.max_hp)
		Game.crumbs["battle"] = "%s %d:%02d, úroveň %d, nepřátel %d%s" % [st_names[state], int(elapsed) / 60, int(elapsed) % 60, level, enemies.count(), extra]
	time_total += delta
	if state == State.PLAY or state == State.BOSS or state == State.BOSS_INTRO:
		if state == State.PLAY:
			elapsed += delta
		var input := controls.input_vector()
		if autoplay:
			input = _autopilot()
		player.update(delta, input)
		enemies.update(delta)
		if boss:
			boss.boss_update(delta)
		if chief:
			chief.boss_update(delta)
		weapons.update(delta)
		projectiles.update(delta)
		pickups.update(delta)
		director.update(delta)
		hazards.update(delta)
		if state == State.PLAY:
			events.update(delta)
		_update_buffs(delta)
		if state == State.PLAY and elapsed >= duration:
			start_boss()
		if pending_levelups > 0 or pending_chests > 0 or pending_chief > 0 or pending_legend > 0:
			_open_choice()
	_update_camera(delta)
	chunk_t -= delta
	if chunk_t <= 0.0:
		chunk_t = 0.3
		_update_chunks(false)
	ground_mat.set_shader_parameter("time_s", time_total)


func _update_camera(delta: float) -> void:
	if player == null:
		return
	camera.position = camera.position.lerp(player.position, 1.0 - exp(-delta * 8.0))
	shake_amt = maxf(0.0, shake_amt - delta * 40.0)
	kick = kick.lerp(Vector2.ZERO, 1.0 - exp(-delta * 22.0))
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt + kick
	var vr := view_rect().grow(80.0)
	ground.position = vr.position
	ground.size = vr.size


func view_rect() -> Rect2:
	var vs := get_viewport_rect().size / camera.zoom
	return Rect2(camera.position - vs * 0.5, vs)


## Krátké zastavení hry při silném zásahu. Časovač ignoruje časové měřítko a běží
## i v pauze; během zpomalení po smrti bosse se zastavení nespouští.
func hitstop(ms: int) -> void:
	if slowmo or bench or get_tree().paused or (state != State.PLAY and state != State.BOSS):
		return
	var now := Time.get_ticks_msec()
	if now + ms <= stop_end_ms:
		return
	stop_end_ms = now + ms
	stops += 1
	stop_serial += 1
	var my := stop_serial
	Engine.time_scale = 0.05
	await get_tree().create_timer(ms / 1000.0, true, false, true).timeout
	if my == stop_serial and not slowmo:
		Engine.time_scale = 1.0


## Zruší běžící zastavení (pauza, výběr karet), aby okna nejela zpomaleně.
func _cancel_hitstop() -> void:
	stop_serial += 1
	stop_end_ms = 0
	if not slowmo:
		Engine.time_scale = 1.0


## Otřes kamery. Silné otřesy (dopady bossových útoků, hrom) i zavibrují.
func shake(amount: float) -> void:
	shake_amt = minf(22.0, maxf(shake_amt, amount))
	if amount >= 9.0:
		Game.vibrate(clampi(int(amount * 5.0), 40, 120))


# ---------------------------------------------------------------- dekorace v kouscích mapy

func _update_chunks(force: bool) -> void:
	if player == null and not force:
		return
	var vr := view_rect().grow(400.0)
	var c0 := Vector2i(floori(vr.position.x / CHUNK), floori(vr.position.y / CHUNK))
	var c1 := Vector2i(floori(vr.end.x / CHUNK), floori(vr.end.y / CHUNK))
	var keep := {}
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var k := Vector2i(cx, cy)
			keep[k] = true
			if not chunks.has(k):
				var nodes: Array = hazards.make_chunk(k) if hazards else []
				chunks[k] = nodes + _make_chunk(k)
	for k in chunks.keys():
		if not keep.has(k):
			for s in chunks[k]:
				if is_instance_valid(s):
					s.queue_free()
			chunks.erase(k)
			if hazards:
				hazards.drop_chunk(k)


func _make_chunk(k: Vector2i) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(k.x, k.y, region_id.hash()))
	var out := []
	var n := rng.randi_range(1, 4)
	if low_quality:
		n = int(n * 0.5)
	var decor: Array = region.decor
	var weights := []
	var wsum := 0.0
	for id in decor:
		var wgt := 0.3 if id in PropArt.BIG else 1.0
		weights.append(wgt)
		wsum += wgt
	for i in n:
		var pos := Vector2(k.x * CHUNK + rng.randf_range(30, CHUNK - 30), k.y * CHUNK + rng.randf_range(30, CHUNK - 30))
		if pos.length() < 220.0:
			continue
		if arena_radius > 0.0 and absf(pos.distance_to(arena_center) - arena_radius) < 90.0:
			continue
		var pick := rng.randf() * wsum
		var id: String = decor[0]
		for j in decor.size():
			pick -= weights[j]
			if pick <= 0.0:
				id = decor[j]
				break
		if hazards and not hazards.decor_ok(id, pos):
			continue
		if hazards:
			hazards.register_prop(k, id, pos)
		var s := Baker.sprite("prop:" + id)
		s.position = pos
		if rng.randf() < 0.5:
			s.flip_h = true
		s.scale *= rng.randf_range(0.85, 1.1)
		if id in PropArt.FLAT:
			ground_fx_layer.add_child(s)
		else:
			entity_layer.add_child(s)
		out.append(s)
	return out


# ---------------------------------------------------------------- statistiky

func recalc_stats() -> void:
	var w := weapons
	var pv := func(stat: String) -> float: return w.passive_value(stat) if w else 0.0
	stats = {
		"max_hp": (120.0 + pv.call("hp_flat")) * (1.0 + Game.meta_value("m_hp")),
		"regen": pv.call("regen") + Game.meta_value("m_regen"),
		"armor": pv.call("armor") + Game.meta_value("m_armor"),
		"speed": 210.0 * (1.0 + pv.call("speed_inc")) * (1.0 + Game.meta_value("m_speed")),
		"dmg": (1.0 + pv.call("dmg_inc")) * (1.0 + Game.meta_value("m_dmg")),
		"area": 1.0 + pv.call("area_inc"),
		"cd": maxf(0.45, 1.0 + pv.call("cd_inc")),
		"amount": pv.call("amount"),
		"magnet": 75.0 * (1.0 + pv.call("magnet_inc") + Game.meta_value("m_magnet")),
		"crit": 0.05 + pv.call("crit"),
		"xp": (1.0 + pv.call("xp_inc")) * (1.0 + Game.meta_value("m_xp")),
		"tag_ohen": pv.call("tag_ohen"),
		"tag_led": pv.call("tag_led"),
		"tag_blesk": pv.call("tag_blesk"),
		"tag_jed": pv.call("tag_jed"),
		"knock": 1.0,
	}
	# vlastnosti hrdiny (M8)
	stats.max_hp *= 1.0 + float(HeroDefs.mod(hero_id, "hp"))
	stats.speed *= 1.0 + float(HeroDefs.mod(hero_id, "speed"))
	stats.xp *= 1.0 + float(HeroDefs.mod(hero_id, "xp"))
	stats.knock += float(HeroDefs.mod(hero_id, "knock"))
	# požehnání z božích muk
	if buffs.has("sila"):
		stats.dmg *= 1.3
	if buffs.has("rychlost"):
		stats.speed *= 1.3
	if buffs.has("magnet"):
		stats.magnet *= 2.0
	if buffs.has("regen"):
		stats.regen += 3.0
	if player:
		var old := player.max_hp
		player.max_hp = stats.max_hp
		if player.max_hp > old:
			player.hp += player.max_hp - old


## Obtížnost: na začátku kraje mírná (hrdina začíná s jedním mečem),
## s časem a s počtem dobytých krajů roste.
func enemy_hp_mult() -> float:
	var f := clampf(elapsed / duration, 0.0, 1.0)
	return (1.0 + tier * 0.08) * (1.0 + f * (1.6 + tier * 0.18))


func enemy_dmg_mult() -> float:
	var f := clampf(elapsed / duration, 0.0, 1.0)
	return (1.0 + tier * 0.04) * (1.0 + f * (0.3 + tier * 0.015))


func boss_dmg_mult() -> float:
	return 1.0 + tier * 0.07


func enemy_speed_mult() -> float:
	return 1.0 + tier * 0.015


func need_for(lv: int) -> float:
	return 5.0 + 4.0 * lv + 0.3 * lv * lv


# ---------------------------------------------------------------- poškození

func damage_enemy(e: Enemy, amount: float, tags: Array, dir: Vector2 = Vector2.ZERO, knock: float = 0.0, can_crit: bool = true, quiet: bool = false) -> void:
	if not e.alive:
		return
	var m: float = stats.dmg
	for t in tags:
		m *= 1.0 + stats.get("tag_" + t, 0.0)
	var dmg := amount * m
	var crit: bool = can_crit and randf() < float(stats.crit)
	if crit:
		dmg *= 2.0
	if e.is_boss and e.intro_t > 0.0:
		return
	e.hp -= dmg
	e.flash = 0.07
	e.squash = Enemy.SQUASH
	if crit and time_total - kick_t > 0.2:
		kick_t = time_total
		kick = (dir if dir != Vector2.ZERO else Vector2.from_angle(randf() * TAU)) * 5.0
	if knock > 0.0 and not e.is_boss:
		e.knock += dir * knock * float(stats.get("knock", 1.0)) * (1.0 - e.knock_res)
	var col := Color("ffe14a") if crit else (Color("cfefff") if quiet else Color.WHITE)
	if not low_quality or crit or e.is_boss or e.elite:
		fx.number(e.position + Vector2(0, -e.r - 6), dmg, crit, col)
	Sfx.play("hit", -14.0, 0.2, 0.05)
	if e.hp <= 0.0:
		if e.is_boss:
			(e as Boss).die()
		else:
			if crit and time_total - crit_stop_t > 1.0:
				crit_stop_t = time_total
				hitstop(30)
			enemies.kill(e)


func apply_burn(e: Enemy, dps: float) -> void:
	e.burn_t = 2.0
	e.burn_dps = maxf(e.burn_dps if e.burn_t > 0 else 0.0, dps * stats.dmg * (1.0 + stats.tag_ohen))


func apply_poison(e: Enemy, dps: float) -> void:
	e.poison_t = 2.0
	e.poison_dps = minf(e.poison_dps + dps * 0.25, dps * 3.0) * (1.0 + stats.tag_jed * 0.5)


func explode_at(pos: Vector2, r: float, dmg: float, tags: Array, burn: float) -> void:
	fx.explosion(pos, r, Color("ff9a2a"))
	Sfx.play("boom", -12.0, 0.15, 0.06)
	for e in enemies.query(pos, r):
		damage_enemy(e, dmg, tags, (e.position - pos).normalized(), 160.0)
		if burn > 0.0 and e.alive:
			apply_burn(e, burn)


func nearest_enemy(pos: Vector2, max_d: float, exclude: Array = []) -> Enemy:
	var e := enemies.nearest(pos, max_d, exclude)
	if boss and boss.alive and boss.intro_t <= 0.0 and not exclude.has(boss):
		var bd := boss.position.distance_to(pos)
		if bd < max_d and (e == null or bd < e.position.distance_to(pos)):
			return boss
	return e


func random_visible_enemy() -> Enemy:
	if boss and boss.alive and boss.intro_t <= 0.0 and randf() < 0.45:
		return boss
	return enemies.random_visible()


func on_enemy_killed(e: Enemy, drops: bool) -> void:
	kills += 1
	ult = minf(1.0, ult + 1.0 / ULT_KILLS)
	fx.poof(e.position)
	Sfx.play("kill", -12.0, 0.15, 0.04)
	if events:
		events.on_kill(e)
	if not drops:
		return
	pickups.drop_xp(e.position, e.xp)
	var r := randf()
	if e.elite:
		hitstop(60)
		# elity z kletby obelisku nedávají vlastní truhlu (dostaneš legendární za všechny)
		if not e.has_meta("curse"):
			pickups.drop("chest", e.position)
		for i in 6:
			pickups.drop("coin", e.position, 1)
		return
	if r < 0.045:
		pickups.drop("coin", e.position, 1)
	elif r < 0.057:
		pickups.drop("jidlo", e.position)
	elif r < 0.061:
		pickups.drop("magnet", e.position)


func hit_player(dmg: float, src: Vector2, big: bool = false) -> void:
	if state != State.PLAY and state != State.BOSS:
		return
	if player.invuln > 0.0:
		return
	if player.hurt_cd > 0.0 and not big:
		return
	var d := maxf(1.0, dmg - stats.armor)
	player.hp -= d
	dmg_taken += d
	player.hurt_cd = Player.HURT_CD
	player.flash = 0.3
	if big:
		player.invuln = 0.6
		hitstop(50)
	fx.number(player.position + Vector2(0, -50), d, false, Color("ff5a48"))
	Game.vibrate(80 if big else 40)
	shake(5.0 if not big else 9.0)
	Sfx.play("hurt", -4.0, 0.1, 0.1)
	if player.hp <= 0.0:
		if revive_left > 0:
			revive_left -= 1
			player.hp = player.max_hp * 0.6
			player.invuln = 2.5
			banner("Druhá šance!", Color("ffd23f"))
			_shockwave_clear(player.position, 400.0)
			Sfx.play("levelup")
		else:
			lose()


func heal(v: float) -> void:
	player.hp = minf(player.max_hp, player.hp + v)
	fx.number(player.position + Vector2(0, -50), v, false, Color("8fff7a"))


func add_gold(v: int) -> void:
	gold_run += v


func clamp_to_arena(p: Vector2, r: float) -> Vector2:
	if arena_radius <= 0.0:
		return p
	var d := p - arena_center
	var maxd := arena_radius - r
	if d.length() > maxd:
		return arena_center + d.normalized() * maxd
	return p


func _shockwave_clear(pos: Vector2, r: float) -> void:
	fx.explosion(pos, r * 0.5, Color(1, 0.9, 0.5))
	for e in enemies.query(pos, r):
		if not e.is_boss:
			e.knock += (e.position - pos).normalized() * 600.0


# ---------------------------------------------------------------- zkušenosti a vylepšení

func add_xp(v: float) -> void:
	xp += v * stats.xp
	while xp >= xp_need:
		xp -= xp_need
		level += 1
		xp_need = need_for(level)
		pending_levelups += 1


## Truhla z elity (1) nabídne lepší karty, truhla náčelníka (2) evoluci nebo aspoň
## epickou kartu, legendární truhla z obelisku (3) legendární předměty.
func open_chest(kind: int = 1) -> void:
	if kind >= 3:
		pending_legend += 1
	elif kind == 2:
		pending_chief += 1
	else:
		pending_chests += 1
	Sfx.play("chest")


func _open_choice() -> void:
	if state != State.PLAY and state != State.BOSS:
		return
	resume_state = state
	state = State.LEVELUP
	_cancel_hitstop()
	get_tree().paused = true
	var cards: Array
	if pending_legend > 0:
		pending_legend -= 1
		Sfx.play("chest")
		Game.vibrate(60)
		cards = gen_cards(3, 2)
		overlay.show_choice(cards, "legend_chest")
	elif pending_chief > 0:
		pending_chief -= 1
		Sfx.play("chest")
		Game.vibrate(60)
		cards = gen_chief_cards()
		overlay.show_choice(cards, "chief")
	elif pending_chests > 0:
		pending_chests -= 1
		Sfx.play("chest")
		Game.vibrate(40)
		cards = gen_cards(3, 1)
		overlay.show_choice(cards, "chest")
	else:
		pending_levelups -= 1
		Sfx.play("levelup")
		Game.vibrate(25)
		cards = gen_cards(3, 0)
		overlay.show_choice(cards, "level")
	if autoplay:
		_auto_choose(cards)


func _auto_choose(cards: Array) -> void:
	await get_tree().create_timer(0.15, true).timeout
	if state == State.LEVELUP:
		var prio := {"evo": 5, "weapon_up": 4, "weapon_new": 3, "passive": 2}
		var best: Dictionary = cards[0]
		for c in cards:
			if prio.get(c.type, 0) > prio.get(best.type, 0):
				best = c
		choose(best)


# ---------------------------------------------------------------- události v boji (M7)

## Zastaví hru pro dialog události. Vrací false, když to teď nejde.
func event_pause() -> bool:
	if state != State.PLAY and state != State.BOSS:
		return false
	resume_state = state
	state = State.LEVELUP
	_cancel_hitstop()
	get_tree().paused = true
	return true


## Zavře dialog události (a otevře čekající výběr karet).
func event_resume() -> void:
	state = resume_state
	if pending_levelups > 0 or pending_chests > 0 or pending_chief > 0 or pending_legend > 0:
		_open_choice()
		return
	overlay.hide_all()
	get_tree().paused = false


## Výběr karet z události (hra už stojí, choose() ji pak pustí dál).
func offer_cards(cards: Array, source: String) -> void:
	overlay.show_choice(cards, source)
	if autoplay:
		_auto_choose(cards)


## Požehnání: id z EventDefs.BLESSINGS na dur sekund.
func add_buff(id: String, dur: float) -> void:
	buffs[id] = dur
	recalc_stats()


func _update_buffs(delta: float) -> void:
	if buffs.is_empty():
		return
	var gone := false
	for id in buffs.keys():
		buffs[id] = float(buffs[id]) - delta
		if float(buffs[id]) <= 0.0:
			buffs.erase(id)
			gone = true
	if gone:
		recalc_stats()


## Karty s nejnižší vzácností předmětů min_r (epická = 2).
func gen_min_rarity(min_r: int) -> Array:
	var cards := gen_cards(3, 1)
	var any := false
	for c in cards:
		if c.type == "passive" and not Upgrades.PASSIVES[c.id].get("no_rarity", false):
			c.rarity = maxi(int(c.rarity), min_r)
			any = true
	if not any:
		var p := _epic_passive()
		if not p.is_empty():
			p.rarity = min_r
			cards[cards.size() - 1] = p
	return cards


## Náhodné vylepšení (kramář): použije ho hned a vrátí jeho jméno.
func random_card(min_r: int) -> String:
	var p := _epic_passive()
	if not p.is_empty():
		p.rarity = min_r
		apply_card(p)
		return "%s (%s)" % [Upgrades.PASSIVES[p.id].name, Art.RARITY_NAMES[min_r]]
	for c in gen_cards(3, 1):
		if c.type == "weapon_up" or c.type == "weapon_new":
			apply_card(c)
			return Upgrades.WEAPONS[c.id].name
	add_gold(20)
	return "+20 zlata"


func choose(card: Dictionary) -> void:
	apply_card(card)
	fx.burst(player.position, Color("ffd23f"), 14, 260.0, 6.0)
	fx.explosion(player.position, 70.0, Color(1, 0.9, 0.4))
	if pending_levelups > 0 or pending_chests > 0 or pending_chief > 0:
		state = resume_state
		_open_choice()
		return
	state = resume_state
	overlay.hide_all()
	get_tree().paused = false


func reroll(source: String = "level") -> Array:
	if rerolls <= 0:
		return []
	rerolls -= 1
	if source == "chief":
		return gen_chief_cards()
	if source == "legend" or source == "legend_chest":
		return gen_cards(3, 2)
	if source == "epic":
		return gen_min_rarity(2)
	return gen_cards(3, 1 if source == "chest" else 0)


## Karty z truhly náčelníka: evoluce, pokud je k dispozici, jinak aspoň jedna epická.
func gen_chief_cards() -> Array:
	var cards := gen_cards(3, 1)
	for c in cards:
		if c.type == "evo":
			return cards
	for w in weapons.weapons:
		if Upgrades.is_evolution(w.id):
			continue
		var def: Dictionary = Upgrades.WEAPONS[w.id]
		if w.level >= Upgrades.WEAPON_MAX_LEVEL and weapons.passives.has(def.evo_with):
			cards[0] = {"type": "evo", "id": def.evo, "from": w.id}
			return cards
	var best := -1
	for i in cards.size():
		var c: Dictionary = cards[i]
		if c.type == "passive" and not Upgrades.PASSIVES[c.id].get("no_rarity", false):
			if best < 0 or int(c.rarity) > int(cards[best].rarity):
				best = i
	if best >= 0:
		cards[best].rarity = maxi(int(cards[best].rarity), 2)
		return cards
	var epic := _epic_passive()
	if not epic.is_empty():
		cards[cards.size() - 1] = epic
	return cards


## Předmět, který jde vylepšit (nebo nově vzít), jako epická karta.
func _epic_passive() -> Dictionary:
	var ids: Array = Upgrades.PASSIVES.keys()
	ids.shuffle()
	for id in ids:
		var p: Dictionary = Upgrades.PASSIVES[id]
		if p.get("no_rarity", false):
			continue
		var lv := weapons.passive_level(id)
		if lv >= int(p.get("max", Upgrades.PASSIVE_MAX_LEVEL)):
			continue
		if lv == 0 and weapons.passives.size() >= Upgrades.MAX_PASSIVES:
			continue
		return {"type": "passive", "id": id, "level": lv + 1, "rarity": 2}
	return {}


func gen_cards(n: int, luck: int) -> Array:
	var pool := []
	var owned_tags := weapons.tags_owned()
	var new_weapon_ok := weapons.weapons.size() < Upgrades.MAX_WEAPONS
	var new_passive_ok := weapons.passives.size() < Upgrades.MAX_PASSIVES
	for w in weapons.weapons:
		if Upgrades.is_evolution(w.id):
			continue
		var def: Dictionary = Upgrades.WEAPONS[w.id]
		if w.level < Upgrades.WEAPON_MAX_LEVEL:
			pool.append([{"type": "weapon_up", "id": w.id, "level": w.level + 1}, 2.2])
		elif weapons.passives.has(def.evo_with):
			pool.append([{"type": "evo", "id": def.evo, "from": w.id}, 9.0])
	if new_weapon_ok:
		for id in Upgrades.WEAPONS.keys():
			if not weapons.has_weapon(id) and not _evolved_from(id):
				var wgt := 1.0
				if offers_without_weapon >= 2 and weapons.weapons.size() < 3:
					wgt = 6.0
				pool.append([{"type": "weapon_new", "id": id, "level": 1}, wgt])
	for id in Upgrades.PASSIVES.keys():
		var p: Dictionary = Upgrades.PASSIVES[id]
		var lv := weapons.passive_level(id)
		var mx: int = p.get("max", Upgrades.PASSIVE_MAX_LEVEL)
		if lv >= mx:
			continue
		if lv == 0 and not new_passive_ok:
			continue
		var wgt := 1.0 if lv > 0 else 0.75
		for t in p.tags:
			wgt *= 1.6 if t in owned_tags else 0.35
		for w in weapons.weapons:
			if not Upgrades.is_evolution(w.id) and Upgrades.WEAPONS[w.id].evo_with == id:
				wgt *= 1.5
		pool.append([{"type": "passive", "id": id, "level": lv + 1, "rarity": _roll_rarity(luck)}, wgt])
	var cards := []
	var has_weapon_card := false
	while cards.size() < n and not pool.is_empty():
		var total := 0.0
		for e in pool:
			total += e[1]
		var r := randf() * total
		var idx := 0
		for k in pool.size():
			r -= pool[k][1]
			if r <= 0.0:
				idx = k
				break
		var c: Dictionary = pool[idx][0]
		pool.remove_at(idx)
		if c.type == "weapon_new":
			has_weapon_card = true
		cards.append(c)
	offers_without_weapon = 0 if has_weapon_card else offers_without_weapon + 1
	if cards.size() < n:
		cards.append({"type": "gold", "amount": 25 + tier * 5})
	if cards.size() < n:
		cards.append({"type": "heal"})
	return cards


func _evolved_from(id: String) -> bool:
	for w in weapons.weapons:
		if Upgrades.is_evolution(w.id) and Upgrades.EVOLUTIONS[w.id].from == id:
			return true
	return false


func _roll_rarity(luck: int) -> int:
	if luck >= 2:
		return 3
	var r := randf()
	if luck > 0:
		r *= 0.55
	var acc := 0.0
	for i in range(3, -1, -1):
		acc += Upgrades.RARITY_CHANCE[i]
		if r < acc:
			return i
	return 0


func apply_card(card: Dictionary) -> void:
	match card.type:
		"weapon_new", "weapon_up":
			weapons.level_weapon(card.id)
		"evo":
			weapons.evolve(card.id)
			banner("Evoluce: " + Upgrades.EVOLUTIONS[card.id].name, Color("ffb310"))
		"passive":
			weapons.add_passive(card.id, card.rarity)
		"gold":
			add_gold(card.amount)
		"heal":
			heal(player.max_hp * 0.5)


func skip_card() -> void:
	add_gold(8 + tier * 2)
	heal(player.max_hp * 0.1)


# ---------------------------------------------------------------- ultimátka

func use_ult() -> void:
	if ult < 1.0 or (state != State.PLAY and state != State.BOSS):
		return
	ult = 0.0
	match str(hero.ult):
		"kanci_uder":
			_ult_stomp()
		"vestba":
			_ult_freeze()
		"skok":
			_ult_leap()
		_:
			_ult_hrom()


func ult_dmg() -> float:
	return 45.0 + level * 6.0


## Čech: blesky zasáhnou všechny nepřátele na obrazovce.
func _ult_hrom() -> void:
	Sfx.play("ult")
	shake(16.0)
	hud.flash_screen()
	var targets := enemies.visible()
	targets.shuffle()
	var dmg := 45.0 + level * 6.0
	for i in mini(targets.size(), 24):
		var e: Enemy = targets[i]
		fx.lightning([e.position + Vector2(randf_range(-40, 40), -650), e.position], true)
	for e in targets:
		damage_enemy(e, dmg, ["blesk"], (e.position - player.position).normalized(), 300.0, false)
	if boss and boss.alive and boss.intro_t <= 0.0:
		fx.lightning([boss.position + Vector2(0, -650), boss.position], true)
		damage_enemy(boss, dmg * 3.0, ["blesk"], Vector2.ZERO, 0.0, false)


## Bivoj: kančí úder – dupnutí, rázová vlna odhodí a na 2 s omráčí vše kolem.
func _ult_stomp() -> void:
	var pp := player.position
	Sfx.play("boom")
	shake(20.0)
	Game.vibrate(120)
	fx.explosion(pp + Vector2(0, 20), 160.0, Color("c9a06a"))
	ground_fx.shockwave(pp, 900.0, 460.0, 34.0, Color("c9a06a"))
	ground_fx.shockwave(pp, 600.0, 300.0, 20.0, Color(1, 0.9, 0.6))
	var dmg := ult_dmg() * 0.9
	for e in enemies.query(pp, 450.0):
		var dir: Vector2 = (e.position - pp).normalized()
		damage_enemy(e, dmg * (2.5 if e.is_boss else 1.0), ["fyz"], dir, 650.0, false)
		if e.alive and not e.is_boss:
			e.state = Enemy.St.REST
			e.timer = 2.0


## Libuše: věštba – nepřátelé na obrazovce na 4 s zamrznou, nepřátelské střely zmizí.
func _ult_freeze() -> void:
	Sfx.play("ult")
	shake(8.0)
	hud.flash_screen(Color(0.75, 0.9, 1.0))
	projectiles.clear_hostile()
	var dmg := ult_dmg() * 0.5
	var targets := enemies.visible()
	var n := 0
	for e in targets:
		damage_enemy(e, dmg * (2.0 if e.is_boss else 1.0), ["led"], Vector2.ZERO, 0.0, false)
		if not e.alive:
			continue
		e.slow_t = 4.0
		e.slow_f = 0.6 if e.is_boss else 1.0
		if not e.is_boss:
			e.state = Enemy.St.REST
			e.timer = 4.0
		if n < 24:
			fx.burst(e.position, Color("bfe8ff"), 4, 120.0, 5.0)
			n += 1
	if boss and boss.alive and boss.intro_t <= 0.0:
		damage_enemy(boss, dmg * 2.0, ["led"], Vector2.ZERO, 0.0, false)
		boss.slow_t = 4.0
		boss.slow_f = 0.6


## Horymír: Šemíkův skok ve směru pohybu, dopad otřese zemí (dopadne v leap_land).
func _ult_leap() -> void:
	Sfx.play("dash")
	var dir: Vector2 = player.move_dir if player.move_dir.length() > 0.1 else player.face_dir
	player.leap(dir.normalized() * 400.0)


func leap_land(pos: Vector2) -> void:
	Sfx.play("boom")
	shake(16.0)
	Game.vibrate(100)
	fx.explosion(pos + Vector2(0, 20), 150.0, Color("e9eef3"))
	ground_fx.shockwave(pos, 800.0, 280.0, 26.0, Color(1, 1, 1))
	var dmg := ult_dmg() * 1.3
	for e in enemies.query(pos, 220.0):
		damage_enemy(e, dmg * (2.5 if e.is_boss else 1.0), ["fyz"], (e.position - pos).normalized(), 500.0, false)


# ---------------------------------------------------------------- náčelník

## Náčelník kraje seskočí kousek od hrdiny (režisér ho pošle v polovině kraje).
func spawn_chief() -> void:
	if chief != null or not region.has("chief") or state != State.PLAY:
		return
	var cdef: Dictionary = EnemyDefs.MINIBOSSES[region.chief]
	var a := randf() * TAU
	var pos := player.position + Vector2(cos(a), sin(a)) * 330.0
	ground_fx.circle_warn(pos, 110.0, 1.0, Color(1, 0.7, 0.1))
	chief = MiniBoss.new()
	entity_layer.add_child(chief)
	chief.position = pos
	chief.init_chief(self, region.chief, MiniBoss.HP_SHARE * boss_hp())
	chief_start = time_total
	banner("Náčelník: " + cdef.name, Color("ffb310"), cdef.title)
	Sfx.play("boss", -6.0)
	Game.note("náčelník: " + cdef.name)
	if autoplay:
		print("NÁČELNÍK %s, životy %d" % [cdef.name, int(chief.max_hp)])


func chief_killed(mb: MiniBoss) -> void:
	if not mb.alive:
		return
	kills += 1
	ult = minf(1.0, ult + 0.25)
	Game.add_stat("chiefs", 1)
	hitstop(90)
	Sfx.play("boom", -2.0)
	Game.vibrate(120)
	shake(14.0)
	for i in 3:
		fx.explosion(mb.position + Vector2(randf_range(-40, 40), randf_range(-40, 40)), 70.0 + i * 20.0, Color("ffd23f"))
	pickups.drop("chest", mb.position, 2)
	for i in 10:
		pickups.drop("coin", mb.position, 1)
	pickups.drop_xp(mb.position, 30)
	banner("Náčelník poražen!", Color("6fcf2f"), "Seber truhlu s pokladem")
	mb.vanish(0.6)
	if chief == mb:
		chief = null
	if autoplay:
		print("NÁČELNÍK poražen za %.0f s" % (time_total - chief_start))


# ---------------------------------------------------------------- boss, výhra, prohra

## Životy bosse podle úrovně hrdiny a počtu dobytých krajů (náčelník má jejich část).
func boss_hp() -> float:
	return (600.0 + 70.0 * level) * (1.0 + tier * 0.22)


func start_boss() -> void:
	state = State.BOSS_INTRO
	enemies.flee_all()
	projectiles.clear_hostile()
	if chief:
		# náčelník, kterého hrdina nestihl porazit, uteče
		if autoplay:
			print("NÁČELNÍK utekl, zbývalo %d %%" % int(100.0 * chief.hp / chief.max_hp))
		fx.poof(chief.position)
		chief.vanish(0.8)
		chief = null
	pickups.pull_chests()
	events.clear()
	arena_center = player.position
	arena_radius = ARENA_R
	ground_fx.arena_center = arena_center
	ground_fx.arena_r = arena_radius
	_build_palisade()
	var ztw := camera.create_tween()
	ztw.tween_property(camera, "zoom", Vector2.ONE * 0.8, 1.0).set_trans(Tween.TRANS_SINE)
	hud.banners.clear()
	overlay.show_boss_intro(EnemyDefs.BOSSES[region.boss], region.boss)
	Sfx.play("boss")
	Sfx.start_music("boss")
	await get_tree().create_timer(BossIntro.DUR, false).timeout
	if state != State.BOSS_INTRO:
		return
	boss = Boss.new()
	entity_layer.add_child(boss)
	boss.position = arena_center + Vector2(0, -200)
	boss.init_boss(self, region.boss, boss_hp())
	boss_start = time_total
	state = State.BOSS


func _build_palisade() -> void:
	var n := 56
	for i in n:
		var a := TAU * i / n
		var s := Baker.sprite("prop:kul")
		s.position = arena_center + Vector2(cos(a), sin(a)) * (arena_radius + 14.0)
		s.scale *= randf_range(0.9, 1.05)
		entity_layer.add_child(s)
		s.scale.y *= 0.01
		var tw := s.create_tween()
		tw.tween_interval(i * 0.012)
		tw.tween_property(s, "scale:y", s.scale.x, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for k in chunks.keys():
		for s in chunks[k]:
			if is_instance_valid(s) and s.get_parent() != ground_fx_layer and s.position.distance_to(arena_center) < arena_radius + 40.0:
				s.modulate.a = 0.0


func boss_killed() -> void:
	if boss == null or not boss.alive:
		return
	boss.alive = false
	state = State.BOSS_INTRO
	boss_time = time_total - boss_start
	Game.add_stat("bosses", 1)
	enemies.flee_all()
	projectiles.clear_hostile()
	boss.shadow.visible = false
	# společná sekvence a tečka podle bosse (scripts/battle/boss_death.gd)
	BossDeath.start(self, boss)
	slowmo = true
	_cancel_hitstop()
	Engine.time_scale = 0.35
	await get_tree().create_timer(0.7, true, false, true).timeout
	slowmo = false
	Engine.time_scale = 1.0
	await get_tree().create_timer(BossDeath.MAGNET_AT, false).timeout
	pickups.magnetize_all()
	await get_tree().create_timer(BossDeath.WIN_AT - BossDeath.MAGNET_AT, false).timeout
	win()


func win() -> void:
	if state == State.WIN or state == State.LOSE:
		return
	state = State.WIN
	_perf_verdict()
	stars = 1
	if player.hp >= player.max_hp * 0.5:
		stars += 1
	if boss_time <= 60.0:
		stars += 1
	var reward := 40 + tier * 10 + stars * 15
	var total := int((gold_run + reward) * (1.0 + Game.meta_value("m_gold")))
	var first := Game.conquer(region_id, stars)
	var new_heroes := Game.check_hero_unlocks()
	Game.add_gold(total)
	Game.add_stat("kills", kills)
	Game.add_stat("runs", 1)
	Game.save_game()
	Sfx.stop_music()
	Sfx.play("win")
	overlay.show_win(stars, total, first)
	if autoplay:
		print("VÝHRA: hvězdy=%d zlato=%d čas=%.0f boss=%.0fs lvl=%d zabito=%d zastavení=%d hrdina=%s%s" % [stars, total, time_total, boss_time, level, kills, stops, hero_id, (" odemčen " + ",".join(new_heroes)) if not new_heroes.is_empty() else ""])
		if "--quit-at-end" in OS.get_cmdline_user_args():
			get_tree().quit()
		_soak_leave()


func lose() -> void:
	if state == State.WIN or state == State.LOSE:
		return
	state = State.LOSE
	_perf_verdict()
	player.hp = 0.0
	var total := int(gold_run * (1.0 + Game.meta_value("m_gold")))
	Game.add_gold(total)
	Game.add_stat("kills", kills)
	Game.add_stat("defeats", 1)
	Game.save_game()
	Sfx.stop_music()
	Sfx.play("lose")
	player.body.modulate = Color(0.5, 0.5, 0.5)
	overlay.show_lose(total)
	if autoplay:
		print("PROHRA: čas=%.0f lvl=%d zabito=%d boss=%s zastavení=%d hrdina=%s" % [time_total, level, kills, ("%d/%d" % [int(boss.hp), int(boss.max_hp)]) if boss else "-", stops, hero_id])
		if "--quit-at-end" in OS.get_cmdline_user_args():
			get_tree().quit()
		_soak_leave()


## Zátěžový test (--soak): po konci bitvy se sám vrátí na mapu.
func _soak_leave() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--soak="):
			await get_tree().create_timer(1.0, true).timeout
			leave("map")
			return


func pause_game() -> void:
	if state != State.PLAY and state != State.BOSS and state != State.BOSS_INTRO:
		return
	resume_state = state
	state = State.PAUSE
	_cancel_hitstop()
	get_tree().paused = true
	overlay.show_pause()


func resume_game() -> void:
	state = resume_state
	get_tree().paused = false
	overlay.hide_all()


func leave(action: String) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	# kresby nepřátel, bosse, dekorací a nástrah tohoto kraje se při dalším
	# vstupu upečou znovu; ikony, hrdina a efekty zůstávají
	Baker.purge(["e:", "b:", "prop:", "hz:", "ev:"])
	finished.emit(action)


func banner(text: String, col: Color, sub: String = "", dur: float = 2.4) -> void:
	if hud:
		hud.banner(text, col, sub, dur)


func time_left() -> float:
	return maxf(0.0, duration - elapsed)


## Po první bitvě (aspoň 20 s měření) se rozhodne, jestli nabídnout úspornou grafiku.
func _perf_verdict() -> void:
	if perf_time < 20.0 or Game.data.perf_checked:
		return
	var fps := perf_frames / perf_time
	Game.data.perf_checked = true
	if fps < 40.0:
		Game.perf_offer = fps
	Game.save_game()


# ---------------------------------------------------------------- měření výkonu (--bench)

## Drží plný počet nepřátel kolem nesmrtelného hrdiny a po 10 s vypíše průměrné FPS.
func _bench() -> void:
	for id in ["sekera", "ohen", "blesk", "aura"]:
		weapons.add_weapon(id)
		for k in 3:
			weapons.level_weapon(id)
	player.invuln = 1.0e9
	bench = true
	await get_tree().create_timer(3.0, false).timeout
	var f0 := Engine.get_process_frames()
	var t0 := Time.get_ticks_usec()
	var n_sum := 0
	var n_cnt := 0
	while Time.get_ticks_usec() - t0 < 10_000_000:
		await get_tree().process_frame
		n_sum += enemies.count()
		n_cnt += 1
	var secs := (Time.get_ticks_usec() - t0) / 1.0e6
	print("BENCH kvalita=%s FPS=%.1f nepřátel=%d okno=%s" % ["úsporná" if low_quality else "vysoká", (Engine.get_process_frames() - f0) / secs, n_sum / maxi(1, n_cnt), str(get_viewport().get_visible_rect().size)])
	get_tree().quit()


func _bench_fill() -> void:
	var ids: Array = region.enemies
	var guard := 0
	while enemies.count() < enemies.cap and guard < 40:
		guard += 1
		var a := randf() * TAU
		enemies.spawn(ids[randi() % ids.size()], player.position + Vector2(cos(a), sin(a)) * randf_range(420.0, 760.0))


# ---------------------------------------------------------------- autopilot (testy bez hráče)

func _autopilot() -> Vector2:
	var pp := player.position
	var push := Vector2.ZERO
	var near := enemies.nearest(pp, 600.0)
	if near and player.hp > player.max_hp * 0.35:
		var dn := near.position - pp
		if dn.length() > 110.0:
			push += dn.normalized() * 0.8
	for e in enemies.list:
		if not is_instance_valid(e) or not e.alive:
			continue
		var d: Vector2 = pp - e.position
		var dl := d.length()
		if dl < 85.0:
			push += d.normalized() * (85.0 - dl) / 30.0
	for p in projectiles.enemy_shots:
		var d: Vector2 = pp - p.pos
		if d.length() < 120.0:
			push += d.normalized() * 1.5
	var wander := Vector2(cos(time_total * 0.4), sin(time_total * 0.31))
	var to_gem := Vector2.ZERO
	var best := 99999.0
	for p in pickups.picks:
		var dd: float = p.pos.distance_to(pp)
		if dd < best and dd < 400.0:
			best = dd
			to_gem = (p.pos - pp).normalized()
	var ev_t := events.autopilot_target() if events else Vector2.INF
	if ev_t != Vector2.INF:
		var de := ev_t - pp
		if de.length() > 30.0:
			push += de.normalized() * 1.4
	if arena_radius > 0.0:
		var c := arena_center - pp
		if c.length() > arena_radius * 0.6:
			push += c.normalized() * 1.5
	for big: Boss in [boss, chief]:
		if big and big.alive:
			var db := pp - big.position
			if db.length() < 230.0:
				push += db.normalized() * 2.5
	for w in ground_fx.warns:
		var dw: Vector2 = pp - w.pos
		if dw.length() < w.r + 30.0:
			push += dw.normalized() * 2.0
	# pruhy nástrah (sudy, koně, tramvaj, kombajn) a nebezpečná místa
	var lanes := []
	for l in ground_fx.lines:
		lanes.append([l.pos, l.pos + l.dir * l.len, l.w * 0.5])
	lanes.append_array(hazards.danger_lanes())
	for ln in lanes:
		var cp := Geometry2D.get_closest_point_to_segment(pp, ln[0], ln[1])
		var dv := pp - cp
		if dv.length() < ln[2] + 50.0:
			var a: Vector2 = ln[0]
			var e2: Vector2 = ln[1]
			push += (dv.normalized() if dv.length() > 1.0 else (e2 - a).normalized().orthogonal()) * 3.0
	for z in hazards.dangers():
		var dz: Vector2 = pp - z[0]
		if dz.length() < z[1] + 40.0:
			push += dz.normalized() * 2.0
	if player.hp < player.max_hp * 0.5 and player.can_dash() and push.length() > 2.0:
		player.dash()
	if ult >= 1.0:
		use_ult()
	return (push * 1.6 + wander * 0.5 + to_gem * 0.7).limit_length(1.0)
