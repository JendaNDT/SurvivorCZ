extends Node
## Sfx – zvuky syntetizované přímo v kódu (žádné zvukové soubory).

const RATE := 22050

var streams := {}
var players: Array[AudioStreamPlayer] = []
var last_play := {}
var next_player := 0
var music_player: AudioStreamPlayer
var want_music := ""
var generating := {}
var music_queue: Array = []
var music_thread: Thread
var music_mutex := Mutex.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_bus("Music")
	_make_bus("SFX")
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		players.append(p)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -12.0
	music_player.bus = "Music"
	add_child(music_player)
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
			music_player.stop()
		elif want_music != "" and not music_player.playing:
			start_music(want_music)


func play(name: String, vol_db: float = 0.0, pitch_var: float = 0.08, min_gap: float = 0.035) -> void:
	if sfx_vol() <= 0.001 or not streams.has(name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(last_play.get(name, -1.0)) < min_gap:
		return
	last_play[name] = now
	var p := players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = streams[name]
	p.volume_db = vol_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


func start_music(kind: String) -> void:
	want_music = kind
	if music_vol() <= 0.001:
		music_player.stop()
		return
	var key := "music_" + kind
	if streams.has(key):
		_play_music(key)
		return
	_prepare_music(kind)


## Hudba se generuje postupně v jednom vlákně na pozadí, aby hra nezamrzla.
func _prepare_music(kind: String) -> void:
	if generating.has(kind) or streams.has("music_" + kind):
		return
	generating[kind] = true
	music_mutex.lock()
	music_queue.append(kind)
	music_mutex.unlock()
	if music_thread == null:
		music_thread = Thread.new()
		music_thread.start(_music_worker)


func _music_worker() -> void:
	while true:
		music_mutex.lock()
		var kind: String = music_queue.pop_front() if not music_queue.is_empty() else ""
		music_mutex.unlock()
		if kind == "":
			break
		var w := _music(kind)
		_music_ready.call_deferred(kind, w)
	_music_done.call_deferred()


func _music_done() -> void:
	if music_thread:
		music_thread.wait_to_finish()
		music_thread = null
	if not music_queue.is_empty():
		music_thread = Thread.new()
		music_thread.start(_music_worker)


func _exit_tree() -> void:
	music_queue.clear()
	if music_thread:
		music_thread.wait_to_finish()
		music_thread = null


func _music_ready(kind: String, w: AudioStreamWAV) -> void:
	streams["music_" + kind] = w
	generating.erase(kind)
	if want_music == kind and music_vol() > 0.001:
		_play_music("music_" + kind)


func _play_music(key: String) -> void:
	if music_player.stream == streams[key] and music_player.playing:
		return
	music_player.stream = streams[key]
	music_player.play()


func stop_music() -> void:
	want_music = ""
	music_player.stop()


# ---------------------------------------------------------------- syntéza

func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
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


## Jednoduchá smyčka hudby: basa + bicí + melodie v pentatonice.
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
	b.resize(int(total * RATE))
	return _wav(b, true)
