extends RefCounted
class_name CrashInfo
## Proč Android minule ukončil hru: ApplicationExitInfo (Android 11+) a u nativního
## pádu výtah z „náhrobku“ (tombstone, Android 12+) – signál, příčina a kde v kódu
## hra spadla. Všechno přes JavaClassWrapper a AndroidRuntime (Godot 4.4+), bez pluginu.

const REASONS := {
	0: "neznámý důvod", 1: "hra se ukončila sama", 2: "ukončena signálem", 3: "málo paměti",
	4: "pád v Javě", 5: "nativní pád", 6: "nereagovala (ANR)", 7: "chyba při startu",
	8: "změna oprávnění", 9: "příliš zatěžovala systém", 10: "ukončil uživatel",
	11: "zastavil uživatel", 12: "spadla závislost", 13: "jiný důvod",
	14: "zmrazena systémem", 15: "změna balíčku", 16: "aktualizace hry",
}
const SIGNALS := {4: "SIGILL", 6: "SIGABRT", 7: "SIGBUS", 8: "SIGFPE", 9: "SIGKILL", 11: "SIGSEGV", 15: "SIGTERM"}


## Poslední ukončení hry podle Androidu. Na jiných systémech vrací prázdný slovník.
static func last_exit() -> Dictionary:
	if not OS.has_feature("android") or not Engine.has_singleton("AndroidRuntime"):
		return {}
	var rt = Engine.get_singleton("AndroidRuntime")
	var version = JavaClassWrapper.wrap("android.os.Build$VERSION")
	var sdk := int(version.SDK_INT) if version else 0
	if sdk < 30:
		return {"error": "Android API %d záznam o ukončení nemá" % sdk}
	var ctx = rt.getApplicationContext()
	if ctx == null:
		return {"error": "chybí kontext aplikace"}
	var am = ctx.getSystemService("activity")
	if am == null:
		return {"error": "chybí ActivityManager"}
	var list = am.getHistoricalProcessExitReasons(ctx.getPackageName(), 0, 1)
	if JavaClassWrapper.get_exception() != null or list == null:
		return {"error": "záznam o ukončení se nepodařilo přečíst"}
	var count := int(list.size())
	if count == 0:
		return {"error": "žádný záznam o ukončení"}
	var info = list.get(0)
	var d := {
		"reason": int(info.getReason()),
		"status": int(info.getStatus()),
		"desc": str(info.getDescription()),
		"time": int(info.getTimestamp()),
		"pss_mb": int(info.getPss()) / 1024,
		"rss_mb": int(info.getRss()) / 1024,
		"sdk": sdk,
	}
	if d.reason == 5 and sdk >= 31:
		var stream = info.getTraceInputStream()
		if stream != null:
			var bytes := _read_all(stream, sdk)
			stream.close()
			if bytes.size() > 0:
				d["tomb"] = parse_tombstone(bytes)
	return d


static func _read_all(stream, sdk: int) -> PackedByteArray:
	if sdk >= 33:
		var b = stream.readAllBytes()
		if b is PackedByteArray:
			return b
	var out := PackedByteArray()
	while out.size() < 131072:
		var c := int(stream.read())
		if c < 0:
			break
		out.append(c)
	return out


## Čitelné řádky pro hlášení o pádu.
static func describe(d: Dictionary) -> Array:
	var out := []
	if d.is_empty():
		return out
	if d.has("error"):
		out.append("Android: " + str(d.error))
		return out
	var reason: int = d.reason
	var line := "Android: %s" % REASONS.get(reason, "důvod %d" % reason)
	if reason == 5 or reason == 2:
		line += " (%s)" % SIGNALS.get(int(d.status), "signál %d" % int(d.status))
	line += ", paměť %d MB" % int(d.pss_mb)
	out.append(line)
	if str(d.desc) != "" and str(d.desc) != "<null>":
		out.append("popis: " + str(d.desc).substr(0, 100))
	var t: Dictionary = d.get("tomb", {})
	if not t.is_empty():
		out.append("%s %s, adresa 0x%x" % [t.signal, t.code, t.fault])
		if t.abort != "":
			out.append("abort: " + t.abort.substr(0, 100))
		for c in t.causes:
			out.append("příčina: " + str(c).substr(0, 100))
		if t.thread != "":
			out.append("vlákno: " + t.thread)
		out.append_array(t.frames)
	return out


# ---------------------------------------------------------------- protobuf náhrobku

static func _varint(b: PackedByteArray, pos: int) -> Array:
	var v := 0
	var shift := 0
	while pos < b.size() and shift < 64:
		var c := b[pos]
		pos += 1
		v |= (c & 0x7f) << shift
		if c & 0x80 == 0:
			break
		shift += 7
	return [v, pos]


## Pole [číslo pole, typ, hodnota] (hodnota je int nebo PackedByteArray).
static func _fields(b: PackedByteArray) -> Array:
	var out := []
	var pos := 0
	while pos < b.size():
		var r := _varint(b, pos)
		var key: int = r[0]
		pos = r[1]
		var f := key >> 3
		var wt := key & 7
		if wt == 0:
			r = _varint(b, pos)
			out.append([f, 0, r[0]])
			pos = r[1]
		elif wt == 1:
			pos += 8
		elif wt == 2:
			r = _varint(b, pos)
			var ln: int = r[0]
			pos = r[1]
			if ln < 0 or pos + ln > b.size():
				break
			out.append([f, 2, b.slice(pos, pos + ln)])
			pos += ln
		elif wt == 5:
			pos += 4
		else:
			break
	return out


static func _str(v) -> String:
	return (v as PackedByteArray).get_string_from_utf8() if v is PackedByteArray else ""


## Výtah z náhrobku (formát tombstone.proto z Androidu 12+).
static func parse_tombstone(b: PackedByteArray) -> Dictionary:
	var res := {"signal": "", "code": "", "fault": 0, "abort": "", "causes": [], "thread": "", "frames": []}
	var tid := 0
	var threads := []
	for f in _fields(b):
		var num: int = f[0]
		if num == 6 and f[1] == 0:
			tid = f[2]
		elif num == 10 and f[1] == 2:
			for s in _fields(f[2]):
				if s[0] == 2:
					res.signal = _str(s[2])
				elif s[0] == 4:
					res.code = _str(s[2])
				elif s[0] == 9 and s[1] == 0:
					res.fault = s[2]
		elif num == 14 and f[1] == 2:
			res.abort = _str(f[2])
		elif num == 15 and f[1] == 2:
			for s in _fields(f[2]):
				if s[0] == 1 and s[1] == 2:
					res.causes.append(_str(s[2]))
		elif num == 16 and f[1] == 2:
			threads.append(f[2])
	for entry in threads:
		var key := -1
		var val := PackedByteArray()
		for x in _fields(entry):
			if x[0] == 1 and x[1] == 0:
				key = x[2]
			elif x[0] == 2 and x[1] == 2:
				val = x[2]
		if key != tid:
			continue
		var n := 0
		for x in _fields(val):
			if x[0] == 2 and x[1] == 2:
				res.thread = _str(x[2])
			elif x[0] == 4 and x[1] == 2 and n < 14:
				var rel := 0
				var fn := ""
				var off := 0
				var file := ""
				for y in _fields(x[2]):
					if y[0] == 1 and y[1] == 0:
						rel = y[2]
					elif y[0] == 4:
						fn = _str(y[2])
					elif y[0] == 5 and y[1] == 0:
						off = y[2]
					elif y[0] == 6:
						file = _str(y[2]).get_file()
				var line := "#%02d %s +0x%x" % [n, file, rel]
				if fn != "":
					line += " " + fn.substr(0, 60) + ("+%d" % off if off > 0 else "")
				res.frames.append(line)
				n += 1
	return res
