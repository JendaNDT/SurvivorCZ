extends Node
## Kontrola krátkého zastavení (hitstop): nesmí zůstat viset, nesmí zpomalit pauzu
## a nesmí přebít zpomalení po smrti bosse. Vypíše „HITSTOP OK“ nebo „HITSTOP CHYBA“.
## Spuštění: -- --battle=PHA --test-bossdeath --dev-script=res://scripts/dev/hitstop_check.gd

var step := 0
var t := 0.0
var errors := 0
var slow_seen := false


func _check(what: String, want: float) -> void:
	var ok := is_equal_approx(Engine.time_scale, want)
	if not ok:
		errors += 1
	print("hitstop: %s, měřítko %.2f (má být %.2f) %s" % [what, Engine.time_scale, want, "ok" if ok else "CHYBA"])


func _process(d: float) -> void:
	var b = get_parent().get("current")
	if not (b is Battle) or b.state == Battle.State.LOADING:
		return
	t += d / maxf(Engine.time_scale, 0.01)
	match step:
		0:
			if t > 0.1:
				b.hitstop(120)
				_check("během zastavení", 0.05)
				step = 1
				t = 0.0
		1:
			if t > 0.2:
				_check("po zastavení", 1.0)
				b.hitstop(120)
				b.pause_game()
				_check("pauza během zastavení", 1.0)
				step = 2
				t = 0.0
		2:
			if t > 0.3:
				_check("v pauze po 0,3 s", 1.0)
				b.resume_game()
				step = 3
				t = 0.0
		3:
			if b.slowmo and not slow_seen:
				slow_seen = true
				b.hitstop(60)
				_check("zastavení během zpomalení po smrti bosse", 0.35)
			elif slow_seen and not b.slowmo:
				_check("po zpomalení", 1.0)
				step = 4
			elif b.boss == null and t > 12.0:
				print("hitstop: boss nepřišel, část se zpomalením přeskočena (spusť s --test-bossdeath)")
				step = 4
		4:
			print("HITSTOP OK" if errors == 0 else "HITSTOP CHYBA (%d)" % errors)
			step = 5
