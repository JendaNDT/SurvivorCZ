# Pravidla projektu Dobyj Česko! (pro Claude Code)

Godot 4.5, GDScript, renderer **GL Compatibility**, cílová platforma Android (na šířku, 1280×720, stretch `canvas_items` + `expand`).

Obecný návrh survivor hry (mechaniky, stat systém, milníky) je v `docs/survivor-hra-design.md`.

## Zásady

- **Žádné obrázky ani převzatá grafika.** Vše se kreslí v kódu přes `Art` (scripts/autoload/art.gd) a peče do textur přes `Baker`. Nové kresby přidávej jako statické funkce `_<id>(ci, t)` do příslušného souboru ve `scripts/art/` (dispatch jde přes `Callable(Třída, "_" + id)`).
- Kreslený styl: obrys `Art.outline`/`Art.shape` (3 jednotky), gradient světlejší nahoře, stín dole, odlesk vlevo nahoře, syté barvy, oči přes `Art.eyes`.
- **Obsah patří do `scripts/data/`** (kraje, nepřátelé, bossové, zbraně, vylepšení). Logika ve `scripts/battle/` z dat jen čte.
- UI se staví z kódu (Controls + vlastní `_draw`). Tlačítka = `CCButton.make(...)`, desky = `Art.panel`, nadpisy = `Art.ribbon`, text s obrysem = `Art.text`.
- Texty ve hře jsou česky, s diakritikou.

## Úskalí GDScriptu (už nás pálila)

- Typované cykly: `for s: int in [-1, 1]:`, jinak `var x := s * 2.0` neprojde („Cannot infer the type“).
- Hodnota ze slovníku (`stats.crit`, `w.st.dmg`) je Variant → piš `var x: float = ...`, ne `:=`.
- Používej `absf/minf/maxf/clampf`, ne `abs/min/max/clamp`.
- Nová `class_name` se zaregistruje až po `godot --headless --path . --import`.
- Nepřátelé se mažou přes `queue_free`; v mřížce (`EnemyManager.grid`) kontroluj `is_instance_valid`.
- Víceřádkové lambdy fungují, ale u `match` uvnitř lambdy raději použij metodu.

## Architektura bitvy

`Battle` (scripts/battle/battle.gd) vlastní vrstvy světa a systémy. Pořadí v `_process`: vstup → hráč → nepřátelé (+ boss) → zbraně → střely → sběr → režisér. Pauza (výběr karet, pauza) = `get_tree().paused`; overlaye mají `PROCESS_MODE_ALWAYS`. Útoky bosse jsou korutiny s `create_timer(t, false)` (respektují pauzu).

Náčelník (`MiniBoss`, scripts/battle/mini_boss.gd) dědí z `Boss` a sdílí jeho útoky. Má `is_boss` i `chief`, od dopadu žije v `EnemyManager.list` (zbraně ho najdou samy), ale pohyb si řídí sám přes `Battle._process`. Po smrti nebo útěku (`vanish`) se uzel uvolní až za 3 s, aby rozběhnuté korutiny útoků doběhly. Útoky nepřesouvej do statických funkcí: korutinu na instanci Godot po uvolnění uzlu neprobudí, statická by sáhla na smazaný objekt.

## Testování

```bash
G=godot   # binárka Godot 4.5
$G --headless --path . --import                      # kontrola chyb ve skriptech
xvfb-run -a $G --path . --rendering-driver opengl3 res://scenes/main.tscn -- --battle=KVK --autoplay --shots=/tmp/s --shot-times=10,60
xvfb-run -a $G --path . --rendering-driver opengl3 res://scenes/dev/gallery.tscn -- --page=1 --zoom=1.4 --shot=/tmp/g.png
```

Autoplay vypisuje každých 10 s úroveň, životy, zabití a zbraně – slouží k ladění balancu.

Rychlá simulace celého kraje bez grafiky (~20 s):

```bash
$G --headless --path . --fixed-fps 30 res://scenes/main.tscn -- --battle=MSK --autoplay --tier=13 --meta=2 --quit-at-end
```

`--meta=N` nastaví všechna vylepšení ze Zbrojnice na úroveň N (přepisuje uložený postup v tomto prostředí).

Výkon: `--bench` drží plný počet nepřátel a vypíše průměrné FPS, porovnej `--quality=high` a `--quality=low` (pod Xvfb s `--resolution 1920x1080`). Ovládání se dá vyzkoušet přes `--taps="x,y@čas;a,b>c,d@čas"` (ťuknutí a tažení). Pod Xvfb běží hra pomalu, dávej mezi ťuknutí aspoň 1 s, jinak se překrývají.

- Nastavení čti přes `Game.setting(key)` a měň přes `Game.set_setting(key, value)` (vyšle `Game.setting_changed`). Nové klíče uložení přidej do `Game.default_data()`, starší uložení se doplní samo (`_deep_merge`).
- Nové efekty a nepřátelé musí brát ohled na úspornou grafiku (`Battle.low_quality`, `Fx.low`, `EnemyManager.cap`).
- **Zvuk:** hudba NEHRAJE přes `AudioStreamWAV`. Přehrávání dlouhé smyčkové WAV hudby v Godotu 4.5 na telefonu četlo za koncem dat a hra padala (náhrobek: `AudioStreamPlaybackWAV`, 16bit mono, vlákno AudioTrack, SIGSEGV na hranici stránky). Hudba jde přes `AudioStreamGenerator`, který `Sfx._feed_music()` každý snímek doplňuje z `PackedVector2Array` (mezipaměť `user://music_*_v2.bin`). Krátké efekty jsou malé `AudioStreamWAV` s kouskem ticha na konci, každý má vlastní přehrávač (`max_polyphony`). Přehrávačům neměň `stream`, když hrají, a nepřidávej sběrnice za běhu (jsou v `default_bus_layout.tres`).
- **UI:** nemaž a znovu nevytvářej tlačítka uvnitř jejich vlastního `pressed` (obchod tlačítka jen přepisuje). Akce, které mění obrazovku, volej přes `call_deferred`.
- Sonda hudby: `--dev-script=res://scripts/dev/music_probe.gd` vypisuje stav generátoru. Adresy z náhrobku jde rozebrat: `llvm-objdump -d --start-address=0x… lib/arm64-v8a/libgodot_android.so` (knihovna z APK, bez symbolů).
- **Testy na telefonu chybí, tak testuj takhle:** zvuk se skutečným mícháním přes `--audio-driver ALSA` (soubor `~/.asoundrc` s `pcm.!default { type null }`) a přístupy ke smazaným objektům v ladicím režimu `yes c | godot -d …` (ve verzi pro telefon by takový přístup hru shodil, editor ho bez `-d` neohlásí). Hledej v logu `Debugger Break`.
- Log: `Game.note("…")` zapíše řádek do `user://logs/godot.log`, každé ťuknutí na `CCButton` se zapisuje samo. Po pádu ukáže hlášení posledních 6 řádků.
- **Žádná vlákna.** Generování hudby ve vlákně na pozadí poškozovalo paměť a hra na telefonu padala. Dlouhé výpočty rozděl do snímků (`await get_tree().process_frame`), jako to dělá `Sfx._music`.
- Nástrahy krajů: data v `scripts/data/hazards.gd`, logika v `scripts/battle/hazards.gd` (`HazardSystem`), kresby v `scripts/art/hazard_art.gd`. Vliv na pohyb jde přes `speed_mult()` a `push_at()`, geometrie v kouscích mapy přes `make_chunk()`/`drop_chunk()`. Test: `--hazard-now`.
- Kresby kraje se po odchodu z bitvy uvolní (`Baker.purge`). Nové předpony klíčů pro kresby kraje přidej do `Battle.leave()`.
- Černá skříňka: `Game.crumb({...})` zapíše, kde hra je. Když minule spadla, mapa ukáže hlášení (`--screen=crash` je ukázka) s tlačítkem „Zkopírovat“. `CrashInfo` (scripts/diag/crash_info.gd) přes `JavaClassWrapper` a `AndroidRuntime` přečte z Androidu důvod ukončení (ApplicationExitInfo) a u nativního pádu výtah z náhrobku (signál, příčina, vlákno, rámce zásobníku). Knihovna `libgodot_android.so` v šabloně nemá symboly, rámce jsou jen posuny.
- Zátěžový test proti únikům paměti: `--soak=N --autoplay --duration=10` (vypisuje paměť, textury a uzly po každé bitvě).
- Pole, ze kterých se během procházení může mazat (střely, zóny), procházej přes `.duplicate()`.

## Na konci každé session

Aktualizuj `PROJECT_STATUS.md` (co je hotové, příští krok, známé bugy).
