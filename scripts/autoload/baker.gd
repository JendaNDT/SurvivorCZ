extends Node
## Baker – „vypeče“ kresbu z _draw() do textury.
## Kresba se jednou vykreslí do SubViewportu ve dvojnásobném rozlišení
## a pak se používá jako obyčejný sprite. Díky tomu hra zvládne stovky
## nepřátel i na slabším telefonu, a přitom je vše nakreslené kódem.

const SCALE := 2.0
const BATCH := 12

var cache := {}
var origins := {}
var headless := false


class Painter extends Node2D:
	var fn: Callable
	var t: float = 0.0

	func _draw() -> void:
		fn.call(self, t)


func _ready() -> void:
	headless = DisplayServer.get_name() == "headless"


func has(key: String) -> bool:
	return cache.has(key)


func tex(key: String) -> Texture2D:
	return cache.get(key)


## Uvolní kresby s danými předponami (kresby kraje po odchodu z bitvy),
## aby grafická paměť nerostla s každým navštíveným krajem.
func purge(prefixes: Array) -> void:
	for k: String in cache.keys():
		for p: String in prefixes:
			if k.begins_with(p):
				cache.erase(k)
				origins.erase(k)
				break


## jobs: pole slovníků {key, size: Vector2 (v jednotkách kresby), fn: Callable(ci, t), t, origin}
## origin = poloha bodu (0,0) kresby na plátně v poměru 0–1 (výchozí střed).
func bake_many(jobs: Array) -> void:
	var todo := []
	for j in jobs:
		if not cache.has(j.key):
			todo.append(j)
	if todo.is_empty():
		return
	Game.note("pečení %d kreseb (%s…)" % [todo.size(), todo[0].key])
	if headless:
		for j in todo:
			var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
			img.fill(Color.MAGENTA)
			cache[j.key] = ImageTexture.create_from_image(img)
		return
	var i := 0
	while i < todo.size():
		var group := todo.slice(i, i + BATCH)
		i += BATCH
		var vps := []
		for j in group:
			var vp := SubViewport.new()
			vp.transparent_bg = true
			vp.disable_3d = true
			vp.size = Vector2i(ceili(j.size.x * SCALE), ceili(j.size.y * SCALE))
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			var p := Painter.new()
			p.fn = j.fn
			p.t = j.get("t", 0.0)
			p.position = Vector2(vp.size) * j.get("origin", Vector2(0.5, 0.5))
			p.scale = Vector2(SCALE, SCALE)
			vp.add_child(p)
			add_child(vp)
			vps.append([j, vp])
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		for pair in vps:
			var vp: SubViewport = pair[1]
			var img := vp.get_texture().get_image()
			if img == null or img.is_empty():
				img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
			else:
				img.generate_mipmaps()
			cache[pair[0].key] = ImageTexture.create_from_image(img)
			origins[pair[0].key] = pair[0].get("origin", Vector2(0.5, 0.5))
			vp.queue_free()
	Game.note("pečení hotovo")


## Sprite z upečené textury (měřítko vrací kresbu do původní velikosti).
func sprite(key: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = cache.get(key)
	s.scale = Vector2.ONE / SCALE
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var o: Vector2 = origins.get(key, Vector2(0.5, 0.5))
	if s.texture and o != Vector2(0.5, 0.5):
		s.offset = -(o - Vector2(0.5, 0.5)) * s.texture.get_size()
	return s
