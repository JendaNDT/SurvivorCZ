extends Node
## Sfx – zvuky syntetizované přímo v kódu (žádné zvukové soubory).

const RATE := 22050

var streams := {}
## Každý zvuk má vlastní přehrávač (víc hlasů přes max_polyphony), hudba má
## přehrávač pro každou skladbu. Přehrávačům se nikdy nemění skladba, když hrají:
## na telefonu běží míchání zvuku ve vlastním vlákně a výměna by mohla hru shodit.
var players := {}
var music_players := {}
var last_play := {}
var want_music := ""
var generating := {}
var music_queue: Array = []
var music_busy := false

## Zvyš, když se změní skladby: hudba uložená v telefonu se pak složí znovu.
const MUSIC_VERSION := 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# sběrnice Music a SFX jsou v default_bus_layout.tres, tohle je jen pojistka
	_make_bus("Music")
	_make_bus("SFX")
	apply_volumes()
	Game.setting_changed.connect(_on_setting)
	_build()
	for k in ["map", "battle", "boss"]:
		_prepare_music(k)


## Hudba a efekty mají každý svou sběrnici, aby šla hlasitost nastavit zvlášť.
func _make_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus_name)
	AudioServer.set_bus_send(i, "Master")


func music_vol() -> float:
	return clampf(float(Game.setting("music_vol")), 0.0, 1.0)


func sfx_vol() -> float:
	return clampf(float(Game.setting("sfx_vol")), 0.0, 1.0)


func apply_volumes() -> void:
	for pair in [["Music", music_vol()], ["SFX", sfx_vol()]]:
		var i := AudioServer.get_bus_index(pair[0])
		var v: float = pair[1]
		AudioServer.set_bus_mute(i, v <= 0.001)
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


func _on_setting(key: String) -> void:
	if key != "music_vol" and key != "sfx_vol":
		return
	apply_volumes()
	if key == "music_vol":
		if music_vol() <= 0.001:
			_stop_all_music()
		elif want_music != "" and not _music_playing():
			start_music(want_music)


func play(name: String, vol_db: float = 0.0, pitch_var: float = 0.08, min_gap: float = 0.035) -> void:
	if sfx_vol() <= 0.001 or not streams.has(name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(last_play.get(name, -1.0)) < min_gap:
		return
	last_play[name] = now
	var p: AudioStreamPlayer = players.get(name)
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = "SFX"
		p.max_polyphony = 4
		p.stream = streams[name]
		add_child(p)
		players[name] = p
	p.volume_db = vol_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


func start_music(kind: String) -> void:
	want_music = kind
	if music_vol() <= 0.001:
		_stop_all_music()
		return
	var key := "music_" + kind
	if streams.has(key):
		_play_music(key)
		return
	_prepare_music(kind)


## Hudba se skládá v hlavním vlákně po kouscích (jedna doba za snímek), aby hra
## nezamrzla. Vlákna na pozadí dřív na telefonu poškozovala paměť, proto žádná nejsou.
## Hotová smyčka se uloží do user:// a při dalším spuštění se jen načte.
func _prepare_music(kind: String) -> void:
	if generating.has(kind) or streams.has("music_" + kind):
		return
	generating[kind] = true
	music_queue.append(kind)
	if not music_busy:
		_music_loop()


func _music_loop() -> void:
	music_busy = true
	while not music_queue.is_empty():
		var kind: String = music_queue.pop_front()
		var w := _load_music(kind)
		if w == null:
			w = await _music(kind)
			_save_music(kind, w)
		_music_ready(kind, w)
	music_busy = false


func _music_path(kind: String) -> String:
	return "user://music_%s_v%d.pcm" % [kind, MUSIC_VERSION]


func _load_music(kind: String) -> AudioStreamWAV:
	var path := _music_path(kind)
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < RATE:
		return null
	return _wav_from_bytes(bytes, true)


## Zápis přes dočasný soubor, aby po nečekaném ukončení nezůstala useknutá hudba.
func _save_music(kind: String, w: AudioStreamWAV) -> void:
	var path := _music_path(kind)
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_buffer(w.data)
	f.close()
	DirAccess.rename_absolute(path + ".tmp", path)


func _music_ready(kind: String, w: AudioStreamWAV) -> void:
	streams["music_" + kind] = w
	generating.erase(kind)
	if want_music == kind and music_vol() > 0.001:
		_play_music("music_" + kind)


func _play_music(key: String) -> void:
	var p: AudioStreamPlayer = music_players.get(key)
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -12.0
		p.stream = streams[key]
		add_child(p)
		music_players[key] = p
	for k in music_players.keys():
		if k != key and music_players[k].playing:
			music_players[k].stop()
	if not p.playing:
		p.play()


func _music_playing() -> bool:
	for p in music_players.values():
		if p.playing:
			return true
	return false


func _stop_all_music() -> void:
	for p in music_players.values():
		p.stop()


func stop_music() -> void:
	want_music = ""
	_stop_all_music()


# ---------------------------------------------------------------- syntéza

func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	return _wav_from_bytes(bytes, loop)


## Totéž jako _wav, ale převod rozloží do více snímků (dlouhé hudební smyčky).
func _wav_async(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	var i := 0
	while i < samples.size():
		var end := mini(i + 20000, samples.size())
		for j in range(i, end):
			bytes.encode_s16(j * 2, int(clampf(samples[j], -1.0, 1.0) * 32000.0))
		i = end
		await get_tree().process_frame
	return _wav_from_bytes(bytes, loop)


func _wav_from_bytes(bytes: PackedByteArray, loop: bool) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = bytes.size() / 2
	return w


func _osc(wave: String, ph: float) -> float:
	match wave:
		"sin":
			return sin(ph * TAU)
		"sq":
			return 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
		"saw":
			return fmod(ph, 1.0) * 2.0 - 1.0
		"tri":
			var x := fmod(ph, 1.0)
			return 4.0 * x - 1.0 if x < 0.5 else 3.0 - 4.0 * x
	return 0.0


## Tón s plynulou změnou frekvence a obálkou.
func _tone(buf: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, wave: String, vol: float, attack: float = 0.005, curve: float = 1.5) -> void:
	var s0 := int(start * RATE)
	var n := int(dur * RATE)
	var ph := 0.0
	if buf.size() < s0 + n:
		buf.resize(s0 + n)
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		ph += f / RATE
		var env := minf(1.0, (i / float(RATE)) / attack) * pow(1.0 - t, curve)
		buf[s0 + i] += _osc(wave, ph) * vol * env


func _noise(buf: PackedFloat32Array, start: float, dur: float, vol: float, lp: float = 0.3, curve: float = 2.0) -> void:
	var s0 := int(start * RATE)
	var n := int(dur * RATE)
	if buf.size() < s0 + n:
		buf.resize(s0 + n)
	var y := 0.0
	var st := int(start * 7919.0 + dur * 104729.0) | 1
	for i in n:
		var t := float(i) / n
		st = (st * 1103515245 + 12345) & 0x7fffffff
		var r := float(st) / 1073741823.5 - 1.0
		y += (r - y) * lp
		buf[s0 + i] += y * vol * pow(1.0 - t, curve)


func _build() -> void:
	seed(1234)
	var b := PackedFloat32Array()
	_noise(b, 0, 0.07, 0.5, 0.5); _tone(b, 0, 0.09, 180, 60, "sin", 0.6)
	streams["hit"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0, 0.11, 520, 140, "sq", 0.18); _noise(b, 0, 0.1, 0.35, 0.4)
	streams["kill"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0, 0.07, 900, 1500, "sin", 0.35, 0.002, 1.0)
	streams["pickup"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0, 0.06, 1320, 1320, "sq", 0.15, 0.002, 0.5); _tone(b, 0.06, 0.2, 1760, 1760, "sq", 0.15, 0.002, 1.5)
	streams["coin"] = _wav(b)
	b = PackedFloat32Array()
	var notes := [523.25, 659.25, 783.99, 1046.5]
	for i in notes.size():
		_tone(b, i * 0.08, 0.3, notes[i], notes[i], "tri", 0.35, 0.005, 1.2)
	_tone(b, 0.32, 0.5, 1046.5, 1046.5, "sq", 0.12, 0.01, 1.5)
	streams["levelup"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0, 0.18, 240, 90, "saw", 0.3); _noise(b, 0, 0.12, 0.3, 0.3)
	streams["hurt"] = _wav(b)
	b = PackedFloat32Array()
	_noise(b, 0, 0.55, 0.9, 0.12, 2.2); _tone(b, 0, 0.45, 110, 35, "sin", 0.8, 0.002, 1.6)
	streams["boom"] = _wav(b)
	b = PackedFloat32Array()
	_noise(b, 0, 0.2, 0.45, 0.6, 1.0)
	streams["dash"] = _wav(b)
	b = PackedFloat32Array()
	_noise(b, 0, 0.14, 0.35, 0.8, 1.4); _tone(b, 0, 0.1, 300, 900, "sin", 0.12)
	streams["slash"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0, 0.06, 700, 380, "sq", 0.12, 0.001, 1.0)
	streams["shoot"] = _wav(b)
	b = PackedFloat32Array()
	for i in 6:
		_tone(b, i * 0.02, 0.05, randf_range(600, 1600), randf_range(200, 900), "saw", 0.16, 0.001, 1.0)
	_noise(b, 0, 0.16, 0.3, 0.9)
	streams["zap"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0, 1.2, 95, 55, "saw", 0.35, 0.05, 1.0); _tone(b, 0, 1.2, 97, 58, "saw", 0.3, 0.05, 1.0); _noise(b, 0, 1.0, 0.25, 0.1, 1.2)
	streams["boss"] = _wav(b)
	b = PackedFloat32Array()
	var fan := [[392.0, 0.0, 0.14], [523.25, 0.15, 0.14], [659.25, 0.3, 0.14], [783.99, 0.45, 0.7]]
	for n in fan:
		_tone(b, n[1], n[2] + 0.1, n[0], n[0], "sq", 0.16, 0.01, 0.8)
		_tone(b, n[1], n[2] + 0.1, n[0] * 0.5, n[0] * 0.5, "tri", 0.25, 0.01, 0.8)
	streams["win"] = _wav(b)
	b = PackedFloat32Array()
	var sad := [[392.0, 0.0], [349.23, 0.25], [311.13, 0.5], [261.63, 0.75]]
	for n in sad:
		_tone(b, n[1], 0.4, n[0], n[0] * 0.98, "tri", 0.3, 0.01, 1.0)
	streams["lose"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0, 0.05, 820, 620, "sin", 0.45, 0.001, 1.0)
	streams["click"] = _wav(b)
	b = PackedFloat32Array()
	for i in 8:
		_tone(b, i * 0.05, 0.2, 1200 + i * 180, 1200 + i * 180, "sin", 0.2, 0.002, 1.5)
	streams["chest"] = _wav(b)
	b = PackedFloat32Array()
	_noise(b, 0, 0.12, 0.25, 0.25); _tone(b, 0, 0.12, 140, 90, "sq", 0.12)
	streams["enemy_shot"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0, 0.4, 200, 800, "saw", 0.2, 0.01, 0.5); _noise(b, 0.1, 0.5, 0.5, 0.2, 1.5)
	streams["ult"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0, 0.25, 160, 160, "sq", 0.15, 0.002, 0.3); _tone(b, 0.3, 0.25, 160, 160, "sq", 0.15, 0.002, 0.3)
	streams["warn"] = _wav(b)
	_build_hazards()


## Zvuky nástrah krajů.
func _build_hazards() -> void:
	var b := PackedFloat32Array()
	for k in 2:
		var t0 := k * 0.2
		_tone(b, t0, 0.55, 1318.5, 1318.5, "sin", 0.35, 0.001, 2.2)
		_tone(b, t0, 0.55, 1975.5, 1975.5, "sin", 0.18, 0.001, 2.6)
		_tone(b, t0, 0.3, 2637.0, 2637.0, "sin", 0.08, 0.001, 3.0)
	streams["zvonek"] = _wav(b)
	b = PackedFloat32Array()
	var fan := [[392.0, 0.0, 0.12], [523.25, 0.13, 0.12], [659.25, 0.26, 0.12], [783.99, 0.39, 0.12], [659.25, 0.52, 0.1], [783.99, 0.63, 0.45]]
	for n in fan:
		_tone(b, n[1], n[2] + 0.05, n[0], n[0], "saw", 0.16, 0.01, 0.6)
		_tone(b, n[1], n[2] + 0.05, n[0] * 2.0, n[0] * 2.0, "sq", 0.04, 0.01, 0.8)
	streams["trubka"] = _wav(b)
	b = PackedFloat32Array()
	for i in 10:
		var t := i * 0.16 + (0.05 if i % 2 == 1 else 0.0)
		_noise(b, t, 0.06, 0.45, 0.08, 2.0)
		_tone(b, t, 0.07, 90, 50, "sin", 0.5, 0.001, 2.0)
	streams["dusot"] = _wav(b)
	b = PackedFloat32Array()
	_swell(b, 0.0, 2.2, 0.7, 0.04)
	_swell(b, 0.3, 1.6, 0.35, 0.12)
	streams["vitr"] = _wav(b)
	b = PackedFloat32Array()
	_swell(b, 0.0, 0.9, 0.8, 0.5)
	_tone(b, 0.0, 0.6, 70, 140, "sin", 0.35, 0.02, 1.5)
	streams["gejzir"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0.0, 1.8, 55, 60, "saw", 0.22, 0.1, 0.6)
	_tone(b, 0.0, 1.8, 57, 62, "saw", 0.18, 0.1, 0.6)
	_swell(b, 0.0, 1.8, 0.25, 0.15)
	streams["kombajn"] = _wav(b)
	b = PackedFloat32Array()
	_tone(b, 0.0, 0.14, 640, 220, "sin", 0.5, 0.001, 1.5)
	streams["plop"] = _wav(b)
	b = PackedFloat32Array()
	for i in 14:
		_noise(b, i * 0.05 + randf() * 0.03, 0.03, 0.4, 0.9, 2.5)
	_swell(b, 0.0, 0.8, 0.3, 0.3)
	streams["praskani"] = _wav(b)
	b = PackedFloat32Array()
	_swell(b, 0.0, 1.4, 0.6, 0.06)
	_tone(b, 0.0, 1.4, 62, 48, "sin", 0.45, 0.1, 0.8)
	streams["valeni"] = _wav(b)
	b = PackedFloat32Array()
	_swell(b, 0.0, 0.7, 0.5, 0.25)
	_tone(b, 0.0, 0.5, 300, 180, "sin", 0.12, 0.05, 1.0)
	streams["spory"] = _wav(b)


## Šum, který plynule zesílí a zeslábne (vítr, pára, motor).
func _swell(buf: PackedFloat32Array, start: float, dur: float, vol: float, lp: float) -> void:
	var s0 := int(start * RATE)
	var n := int(dur * RATE)
	if buf.size() < s0 + n:
		buf.resize(s0 + n)
	var y := 0.0
	var st := int(start * 7919.0 + dur * 104729.0 + lp * 1000.0) | 1
	for i in n:
		var t := float(i) / n
		st = (st * 1103515245 + 12345) & 0x7fffffff
		var r := float(st) / 1073741823.5 - 1.0
		y += (r - y) * lp
		buf[s0 + i] += y * vol * sin(t * PI)


## Jednoduchá smyčka hudby: basa + bicí + melodie v pentatonice.
## Skládá se po dobách (po každé počká na další snímek).
func _music(kind: String) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = {"map": 77, "battle": 99, "boss": 13}.get(kind, 5)
	var bpm: float = {"map": 96.0, "battle": 132.0, "boss": 150.0}.get(kind, 120.0)
	var beat := 60.0 / bpm
	var bars := 8
	var total := bars * 4 * beat
	var b := PackedFloat32Array()
	b.resize(int(total * RATE) + 10)
	var roots: Array = [110.0, 87.31, 98.0, 82.41]
	if kind == "battle":
		roots = [110.0, 110.0, 87.31, 98.0]
	elif kind == "boss":
		roots = [82.41, 82.41, 87.31, 77.78]
	var scale := [1.0, 1.125, 1.25, 1.5, 1.6875, 2.0]
	if kind == "boss":
		scale = [1.0, 1.189, 1.335, 1.5, 1.782, 2.0]
	for bar in bars:
		var root: float = roots[bar % roots.size()]
		for q in 4:
			var t := (bar * 4 + q) * beat
			_tone(b, t, beat * 0.9, root, root, "tri", 0.28, 0.01, 0.6)
			if kind != "map":
				_noise(b, t, 0.08, 0.35, 0.15, 3.0)
				_tone(b, t, 0.12, 120, 40, "sin", 0.5, 0.001, 2.0)
				_noise(b, t + beat * 0.5, 0.05, 0.18, 0.9, 3.0)
				if kind == "boss":
					_tone(b, t + beat * 0.5, beat * 0.4, root * 2.0, root * 2.0, "saw", 0.08, 0.005, 1.0)
			elif q % 2 == 1:
				_noise(b, t, 0.05, 0.12, 0.9, 3.0)
			if rng.randf() < 0.75:
				var f: float = root * 4.0 * scale[rng.randi() % scale.size()]
				_tone(b, t, beat * 0.45, f, f, "sq", 0.06, 0.005, 1.2)
				if rng.randf() < 0.5:
					var f2: float = root * 4.0 * scale[rng.randi() % scale.size()]
					_tone(b, t + beat * 0.5, beat * 0.45, f2, f2, "sq", 0.05, 0.005, 1.2)
			await get_tree().process_frame
	b.resize(int(total * RATE))
	return await _wav_async(b, true)
