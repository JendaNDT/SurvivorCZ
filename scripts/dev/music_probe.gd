extends Node
## Sonda hudby: každou půlsekundu vypíše stav generátoru hudby.
## Spuštění: --dev-script=res://scripts/dev/music_probe.gd
var t := 0.0
func _process(d):
	t += d
	if int(t * 2) != int((t - d) * 2):
		var gen = Sfx.music_gen
		print("[probe %.1f] kind=%s playing=%s pos=%d avail=%s skips=%s tracks=%s" % [t, Sfx.music_kind, Sfx.music_player.playing, Sfx.music_pos, gen.get_frames_available() if gen else -1, gen.get_skips() if gen else -1, Sfx.music_tracks.keys()])
