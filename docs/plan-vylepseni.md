# Dobyj Česko! – implementační plán vylepšení

*Verze z 2. 10. 2026. Navazuje na stav ve větvi `claude/clever-wright-fqvffu` a na obecný návrh v [`survivor-hra-design.md`](survivor-hra-design.md).*

Plán pokrývá všechny navržené vylepšení: nástrahy a minibosse v krajích, telefon a nastavení, fakta a bestiář, nové hrdiny, události v boji, hru po dohrání, pocit z boje, hudbu podle oblasti a vydání na Google Play. Je rozdělený do deseti milníků. Každý milník je samostatné zadání pro Claude Code a končí hratelnou verzí s novým APK.

## Pořadí milníků

| # | Milník | Co přinese | Náročnost |
| --- | --- | --- | --- |
| M1 ✅ | Telefon a nastavení | úsporná grafika, FPS, vibrace, hlasitost hudby a efektů zvlášť, leváci | hotovo (verze 1.1.0) |
| M2 ✅ | Nástrahy krajů | 14 mechanik, každý kraj se hraje jinak | hotovo (verze 1.2.0) |
| M3 ✅ | Minibossové | náčelník v polovině každého kraje | hotovo (verze 1.3.0) |
| M4 | Pocit z boje | nástup bosse, krátké zastavení při zásahu, prach, smrti bossů | 1 session |
| M5 | Věděl jsi? a Kniha | fakta o krajích, bestiář, odznaky | 1 session |
| M6 | Hudba podle oblasti | dechovka, cimbál, hory, hutě, Praha | 1 session |
| M7 | Události v boji | oltář, boží muka, obelisk, kramář, zamčená truhla | 1–2 sessions |
| M8 | Hrdinové | Bivoj, kněžna Libuše, Horymír se Šemíkem | 2 sessions |
| M9 | Po dohrání | úrovně žáru, nekonečný režim, denní výzva | 2 sessions |
| M10 | Google Play | vlastní klíč, AAB, stránka v obchodě | 1 session + tvoje kroky |

**Proč toto pořadí:** M1 je první, protože hra ještě neběžela na skutečném telefonu a nastavení potřebují i další milníky. M2 a M3 nejvíc zlepší hratelnost. M4 je levný a výrazný. Hrdinové a hra po dohrání dávají smysl, až když je obsahu víc. Vydání je poslední.

---

## Společné základy

Tyto věci se dělají v prvním milníku, který je potřebuje, a dál se jen rozšiřují.

### Uložení verze 2

Dnešní `Game.load_game()` slučuje jen klíče nejvyšší úrovně. Nové vnořené části by se se starým uložením ztratily.

- `scripts/autoload/game.gd`: přidat `_deep_merge(defaults, loaded)` a `_migrate(data)`. Při načtení se doplní chybějící klíče z `default_data()` a zvýší `version`.
- Migrace z verze 1: `sound: false` se převede na hlasitost hudby i efektů 0.
- Nové části uložení (přibývají postupně podle milníků):

```gdscript
"version": 2,
"settings": {"music_vol": 0.8, "sfx_vol": 1.0, "vibrate": true,
             "quality": "high", "show_fps": false, "left_handed": false},
"bestiary": {"kills": {}, "bosses": {}},       # M5
"facts_seen": {},                                # M5
"badges": {},                                    # M5
"heroes": {"selected": "cech", "unlocked": ["cech"]},  # M8
"heat": {"unlocked": 0, "records": {}},          # M9
"endless": {},                                   # M9
"daily": {"last": "", "streak": 0, "best": {}},  # M9
```

- Pomocné funkce: `Game.setting(key)`, `Game.set_setting(key, value)` (uloží a vyšle `changed`).
- Test: uložení ze současné verze (vytvoří se spuštěním staré verze) se načte bez ztráty postupu.

### Obsah patří do dat

Stejně jako dnes: čísla a texty do `scripts/data/`, logika do `scripts/battle/`, kresby do `scripts/art/`.

| Nový soubor | Obsah |
| --- | --- |
| `scripts/data/hazards.gd` | nástrahy krajů (M2) |
| `scripts/data/heroes.gd` | hrdinové (M8) |
| `scripts/data/events.gd` | události v boji (M7) |
| `scripts/data/modifiers.gd` | žár a denní výzva (M9) |
| `scripts/data/badges.gd` | odznaky (M5) |

Fakta o krajích přibudou do `regions.gd` (`facts`), popisy nepřátel do `enemies.gd` (`lore`, `tip`), minibossové do `enemies.gd` (`MINIBOSSES`).

### Testovací parametry

Každá nová obrazovka a mechanika dostane parametr pro rychlé vyzkoušení. Patří do `Battle._dev_tests()` nebo `Main._ready()`:

`--quality=low`, `--left-handed`, `--show-fps`, `--hazard-now`, `--test-miniboss`, `--test-bossintro`, `--test-bossdeath=ID`, `--test-event=oltar|muka|obelisk|kramar|truhla`, `--hero=bivoj`, `--heat=5`, `--endless`, `--daily=2026-10-02`, `--screen=book|heroes|settings`, `--export-music=složka`.

### Hotovo u každého milníku

1. `godot --headless --path . --import` bez chyb.
2. Rychlá simulace bez grafiky na 3 krajích (obtížnost 0, 7 a 13, `--meta=0/1/2`). Automat vyhraje aspoň 2 ze 3 a boss trvá 30–80 s.
3. Snímky nových obrazovek a mechanik pod Xvfb, kontrola vzhledu.
4. Nová kresba se objeví v galerii (`scenes/dev/gallery.tscn`, nová stránka).
5. Sestavené APK (`Android arm64` i univerzální), ověřený podpis.
6. Aktualizovaný `PROJECT_STATUS.md`, commit a push.
7. Ty si APK zahraješ na telefonu a napíšeš dojmy.

### Automatický hráč

`Battle._autopilot()` se rozšiřuje s každou mechanikou: uhýbá varovným čárám (`ground_fx.lines`), chodí k událostem a sbírá švestky. Bez toho by simulace balancu přestaly být užitečné.

---

## M1 Telefon a nastavení

**Cíl:** hra běží plynule i na slabším telefonu a nastavení je pohodlné.

**Stav: hotovo ve verzi 1.1.0.** Proti plánu dvě změny: plynulost se měří od 10. sekundy až do konce bitvy (na začátku je nepřátel málo, takže měření 5.–20. s by sekání neodhalilo), a úsporná grafika navíc vykresluje v základním rozlišení 1280×720 a obraz roztáhne (text je o kousek méně ostrý, grafika telefonu ale udělá víc než o polovinu méně práce).

### Úsporná grafika

Přepínač „Úsporná grafika“ v nastavení (`settings.quality = "low"`):

| Co | Vysoká | Úsporná |
| --- | --- | --- |
| Nepřátel naráz (`EnemyManager.CAP`) | 230 | 150 |
| Částice (`Fx.MAX_PARTS`, kouř po zabití) | 260, 7 obláčků | 90, 3 obláčky |
| Čísla zásahů (`Fx.MAX_NUMS`) | 60, všechna | 20, jen kritické a velké |
| Stíny nepřátel | ano | ne |
| Dekorace v kousku mapy | 1–4 | 0–2 |
| Shader země | celý | bez trsů trávy a s jednodušší dlažbou |

- `EnemyManager.CAP` se změní z konstanty na proměnnou nastavenou při startu bitvy.
- `shaders/ground.gdshader`: nový `uniform int quality`, při nízké kvalitě přeskočí `tufts()` a druhou vrstvu šumu.
- **Automatická nabídka:** v první bitvě se měří průměrné FPS mezi 5. a 20. sekundou. Pod 40 FPS se po bitvě ukáže stuha „Hra se seká – zapnout úspornou grafiku?“ s tlačítkem. Uloží se `perf_checked`, aby se nabídka neopakovala.

### Ukazatel FPS

Malý štítek v HUD pod ukazateli: FPS a počet nepřátel. Zapíná se v nastavení. Pomůže ti poslat mi přesná čísla z telefonu.

### Vibrace

- `Game.vibrate(ms)`: když je zapnutá a jde o Android, zavolá `Input.vibrate_handheld(ms)`.
- Kdy: zásah hrdiny 40 ms (silný 80 ms), dopad bossova útoku v blízkosti 60 ms, nová úroveň 25 ms, smrt bosse 150 ms.
- `export_presets.cfg`: u obou předvoleb `permissions/vibrate=true`.

### Hlasitost hudby a efektů zvlášť

- `scripts/autoload/sfx.gd`: v `_ready()` vytvořit sběrnice `Music` a `SFX` (`AudioServer.add_bus`), přehrávače efektů na `SFX`, hudbu na `Music`. Hlasitost přes `AudioServer.set_bus_volume_db(…, linear_to_db(v))`, při 0 ztlumit.
- Všechna místa s `Game.sound_on()` přejdou na hlasitosti.
- Nový ovládací prvek `scripts/ui/cc_slider.gd` (`CCSlider`): dřevěná drážka, zlatý jezdec, tažení prstem.

### Ovládání pro leváky

`TouchControls._dash_c()` a `_ult_c()` se při `left_handed` zrcadlí na levou stranu, nápověda joysticku na pravou. Joystick funguje kdekoli jako dnes.

### Nová deska nastavení

`scripts/ui/settings_board.gd` (`SettingsBoard`) sdílená mapou i pauzou v bitvě:

- Hudba (posuvník), Efekty (posuvník)
- Vibrace, Úsporná grafika, Ukazatel FPS, Ovládání pro leváky (přepínače ve stylu tlačítek)
- Jak hrát, Smazat postup (jen na mapě)

`MapScreen.show_settings()` a `BattleOverlay.show_pause()` ji použijí.

**Testy:** `--quality=low --show-fps`, porovnání snímků za sekundu pod Xvfb při 230 nepřátelích (vysoká vs. úsporná). Snímek desky nastavení.

**Hotovo, když:** posuvníky mění hlasitost hned a pamatují si ji, staré uložení se načte, na telefonu vibruje (ověříš ty) a úsporná grafika je v testu měřitelně rychlejší.

---

## M2 Nástrahy krajů

**Cíl:** každý kraj má vlastní mechaniku, se kterou se dá i chytře hrát: většina nástrah ublíží nepřátelům víc než hrdinovi, takže se vyplatí hordu do nich nalákat.

**Stav: hotovo ve verzi 1.2.0.** Proti plánu: zóny nástrah (oblaky spor, horké stopy, krátery) si vede přímo `HazardSystem`, takže `add_zone()` zůstal beze změny; vliv na pohyb je v `HazardSystem.speed_mult()` a `push_at()` místo `Battle.slow_at()`/`push_at()`. Koleje jsou po 800 px (ne 1100), aby tramvaj jezdila i u startu. V aréně bosse zůstává kromě počasí i terén (pásy, rybníky), vypnou se jen nástrahy, které padají nebo jezdí. Spolu s M2 přišla oprava stability (hudba bez vláken, uvolňování kreseb kraje, černá skříňka).

### Architektura

- `scripts/data/hazards.gd` (`HazardDefs`): pro každý kraj `id`, název, text na stuze při prvním výskytu, interval, poškození a další parametry.
- `scripts/battle/hazards.gd` (`HazardSystem`, Node): `init(b)`, `update(delta)`, `make_chunk(k, rng)` a pro každý typ funkce `_tick_<id>()`. Volá se v `Battle._process()` po režisérovi. V aréně bosse se vypínají kromě počasí (mlha, vánice, vítr).
- Při prvním výskytu stuha s názvem a nápovědou, například „Pozor, tramvaj! Nenech se srazit, ale nalákej na koleje hordu.“
- Sdílené nástroje:
  - varování na zemi už existují (`ground_fx.circle_warn`, `ground_fx.line_warn`),
  - `ProjectileSystem.add_zone()` dostane parametr `hits_enemies`, aby zóna mohla zranit hrdinu i nepřátele,
  - nové `Battle.push_at(pos) -> Vector2` (vítr, pásy) a `Battle.slow_at(pos) -> float` (voda, krátery), které čtou `Player.update()` i `EnemyManager.update()`,
  - geometrie v kouscích mapy (koleje, pásy, tůně, praskliny, kruhy hub) se generuje v `Battle._make_chunk()` přes `hazards.make_chunk()` a při odebrání kousku se uvolní.
- Kresby: `scripts/art/hazard_art.gd` (`HazardArt`), nová stránka galerie.
- Zvuky: zvonek tramvaje, dusot koní, vítr, gejzír, kombajn (syntéza v `sfx.gd`).
- Poškození: hrdinovi 12–25 % životů podle nástrahy, škálováno `boss_dmg_mult()`; běžné nepřátele nástraha většinou zabije.

### Nástrahy

| Kraj | Nástraha | Jak funguje |
| --- | --- | --- |
| Karlovarský | Gejzíry | Každých 10–14 s 2–3 kruhy u hrdiny (varování 1,2 s). Výtrysk páry zraní a odhodí. Na jeho místě zůstane na 5 s horký pramen, který hrdinu léčí 3 životy za sekundu. |
| Plzeňský | Valící se sudy | Každých 15 s varovný pruh přes obrazovku, po 1,5 s se jím skutálí 3 sudy. Srazí a odhodí vše. |
| Ústecký | Pásové dopravníky | V kouscích mapy leží pásy (300 × 70 px s pohyblivými pruhy). Kdo na nich stojí, toho unáší 150 px/s. Občas z pásu spadne uhlí (malé kruhy). |
| Liberecký | Jizerská mlha | Každých 30 s padne na 12 s mlha. Vidět je jen kruh asi 280 px kolem hrdiny (shader přes obrazovku). Skleněné krystaly v mlze svítí. |
| Královéhradecký | Krakonošova vánice | Každých 25 s vánice na 8 s. Hrdina −20 % rychlosti, nepřátelé −40 %. Kdo stojí na místě, mrzne (1 život za sekundu). |
| Pardubický | Dostih | Každých 18 s zatroubí trubka, objeví se pruh a proběhne jím stádo 4 koní s žokeji. Srazí vše. |
| Středočeský | Hradní katapult | Každých 9 s dopadne kámen (kruh 80 px, varování 1,4 s). Kráter pak 6 s zpomaluje. |
| Praha | Tramvaj | Svět protínají vodorovné koleje (asi každých 1100 px). Každých 12–16 s přijede tramvaj na kolej nejblíž hrdinovi: zvonek, varování 1,8 s. Nepřátele smete, hrdinovi vezme 25 % životů. |
| Jihočeský | Rybníky | Tůně, které dnes kreslí jen shader, se stanou skutečnými oblastmi. Brodění zpomaluje hrdinu i nepřátele o 40 %, kapři a vodníci jsou ve vodě naopak rychlejší. |
| Vysočina | Houbové spory | Kruhy hub každých 8 s vypustí oblak spor (zóna na 4 s), který otráví všechny uvnitř. |
| Jihomoravský | Vichr z Pálavy | Každých 20 s fouká 6 s vítr jedním směrem (šipka u okraje obrazovky, čáry ve vzduchu). Tlačí hrdinu, nepřátele i střely. |
| Olomoucký | Kombajn | Každých 16 s projede přes pole kombajn (varování 1,5 s). Nepřátele „sklidí“, hrdinovi vezme 20 % životů a nechá za sebou balíky slámy. |
| Zlínský | Padající švestky | Pod švestkovými stromy každé 3 s spadne švestka. Hrdinu po sebrání vyléčí o 4 životy, nepřítel na ní uklouzne a na 1 s se zastaví. |
| Moravskoslezský | Žhavé praskliny | Každých 12 s se rozžhaví prasklina v podlaze (varování 1,2 s) a vytryskne z ní roztavené železo. Zraní a nechá na 4 s žhavou stopu. |

**Technická úskalí:**

- Rybníky a praskliny dnes kreslí shader. Aby hra věděla, kde jsou, musí se generovat v GDScriptu (`FastNoiseLite` se stejným semínkem) a kreslit jako polygony a čáry. Ve shaderu se pak vypnou, jinak by voda a praskliny byly vidět dvakrát: praskliny ve vzoru METAL úplně (používá ho jen Moravskoslezský kraj), tůně ve vzoru MEADOW jen pro Jihočeský kraj přes nový `uniform`, protože stejný vzor používá i Pardubický kraj (tam jsou to hliněné plochy).
- U Zlínska se v kouscích mapy přidá víc švestkových stromů, aby švestky padaly i tam, kde hrdina zrovna je.
- Mlha nesmí zakrýt HUD: patří do vlastní `CanvasLayer` mezi svět a HUD.

**Testy:** `--hazard-now` (nástraha každé 3 s), snímek každé nástrahy ve všech 14 krajích, simulace balancu v 6 krajích.

**Hotovo, když:** v každém kraji se nástraha objeví do 40 s, stuha ji vysvětlí a simulace projdou podle společných pravidel.

---

## M3 Minibossové

**Cíl:** v polovině kraje přijde silný náčelník, aby souboj neměl hluché místo.

**Stav: hotovo ve verzi 1.3.0.** Proti plánu:
- Útoky zůstaly v `boss.gd` a `MiniBoss` je dědí (žádný `boss_attacks.gd`). Útoky jsou korutiny na instanci: když se uzel uvolní, Godot je neprobudí. Sdílené statické funkce by po uvolnění sáhly na smazaný objekt, a to je přesně typ chyby, který na telefonu shodí hru.
- Náčelník má **25 %** životů bosse, ne 35 %. Zbraně se dělí mezi něj a hordu, takže s 35 % trval souboj s automatem 30–67 s. Útoky má na 60 % síly bosse. Na Zlínsku na nejvyšší obtížnosti bral hrdinovi 110 ze 144 životů za 10 s.
- Navíc: zlatá šipka k náčelníkovi mimo obrazovku, náčelník uteče, když přijde boss, nástrahy mu ubližují (polovina toho co elitě, nejvýš jednou za sekundu), pásy a vítr ho unášejí. Truhla náčelníka je větší a přehození karet v ní zase nabídne evoluci nebo epickou kartu. Kresba koruny sedí podle nejvyšších pixelů kresby, u divočáka je ručně posunutá na hlavu. Galerie má stranu 8 s náčelníky.
- Test: `--test-miniboss`, `--test-chief-chest` a `--test-chief-chest=evo`. Simulace všech 14 krajů po dvou bitvách: automat vyhrál 23 z 28 (před M3 11 ze 14), náčelníka porazil v 27 bitvách z 28, obvykle za 20–50 s. Ladicí režim: útěk náčelníka a 3 bitvy s přechody na mapu bez jediné chyby.

- Režisér (`scripts/battle/director.gd`): nová událost `miniboss` v 50 % času (místo dnešního obklíčení v 55 % se obklíčení posune na 60 %).
- **Kód:** útoky bosse se vytáhnou z `boss.gd` do sdíleného `scripts/battle/boss_attacks.gd`, aby je mohl použít i miniboss. `MiniBoss` (dědí z `Boss`) má jen dva útoky, žádné fáze, žádnou arénu a 35 % životů bosse.
- **Vzhled:** náčelník je hlavní nepřítel kraje ve dvojnásobné velikosti s korunou a zlatou září (nová kresba koruny přes stávající sprite). Nad ním malý ukazatel životů.
- **Odměna:** truhla, která nabídne evoluci, pokud je k dispozici, jinak aspoň epickou kartu.
- Data v `enemies.gd` (`MINIBOSSES`):

| Kraj | Náčelník (vychází z) | Útoky |
| --- | --- | --- |
| Karlovarský | Lázeňský primář (host) | přivolání, kruh kapek |
| Plzeňský | Mistr sládek (sud) | výpad, pivní louže |
| Ústecký | Předák havířů (havíř) | déšť uhlí, přivolání dynamitů |
| Liberecký | Mistr sklář (sklář) | spirála střepů, kruh |
| Královéhradecký | Obří sněhulák (sněhulák) | dupnutí, kruh koulí |
| Pardubický | Žokej šampion (kůň) | dvojitý výpad, přivolání perníčků |
| Středočeský | Rytíř praporečník (rytíř) | výpad, úder |
| Praha | Velký Golem (golem) | úder, rázová vlna |
| Jihočeský | Obří kapr (kapr) | výpad, louže |
| Vysočina | Kňour (divočák) | výpad, přivolání muchomůrek |
| Jihomoravský | Starý vinař (vinař) | kruh hroznů, vinná louže |
| Olomoucký | Starosta Hané (Hanák) | úder, přivolání tvarůžků |
| Zlínský | Valašský hajtman (Valach) | úder, výpad |
| Moravskoslezský | Mistr hutník (hutník) | lávová louže, déšť jisker |

**Testy:** `--test-miniboss`, simulace balancu.

**Hotovo, když:** miniboss přijde v každém kraji, má název na stuze a ukazatel životů, a simulace projdou.

---

## M4 Pocit z boje

**Cíl:** boj víc „sedí“: nástup bosse jako v Clash of Clans, zásahy mají váhu.

- **Nástup bosse:** `BattleOverlay.show_boss_intro(bdef)` na 1,8 s během `State.BOSS_INTRO`. Obrazovka ztmavne, zleva přijede portrét hrdiny na modré stuze, zprava portrét bosse (upečený `b:<id>:0`) na červené, uprostřed velké „VS“ s otřesem, pod tím jméno a přídomek bosse. Pak boss dopadne jako dnes.
- **Krátké zastavení při zásahu:** `Battle.hitstop(ms)` nastaví `Engine.time_scale = 0.05` a vrátí ho časovačem, který ignoruje časové měřítko (`create_timer(t, true, false, true)`). Kdy: zabití elity 60 ms, kritické zabití 30 ms (nejvýš jednou za sekundu), změna fáze bosse 120 ms, silný zásah hrdiny 50 ms. Hlídat, aby se volání nepřekrývala se zpomalením po smrti bosse.
- **Prach pod nohama:** `Player.update()` při pohybu každých 0,18 s zavolá nové `Fx.dust(pos, ground)`. Barva podle země: tráva zelenohnědá, sníh bílá, hlína hnědá, plech jiskry.
- **Smrti bossů:** společná sekvence (otřes, bílé záblesky, boss se nakloní a propadne, výbuch mincí a konfet) a k tomu krátká vlastní tečka pro každého bosse, například:
  - Orloj: ručičky se roztočí a zvon naposledy zazvoní,
  - Vřídelní obr: poslední gejzír,
  - Pivní král: pěna vyteče po zemi,
  - Kolesové rypadlo: kolo se odkutálí,
  - Krakonoš: zmizí v mlze a zůstane po něm klobouk,
  - Brněnský drak: zhroutí se a z tlamy vyletí kouř.

  Data v `enemies.gd` (`BOSSES[...].death`), kód v novém `scripts/battle/boss_death.gd`.
- **Drobnosti:** nepřítel se při zásahu krátce smáčkne, kamera se při kritu jemně cukne, zvuk sbírání elixíru stoupá, když sbíráš rychle za sebou.

**Testy:** `--test-bossintro`, `--test-bossdeath=ID` pro všech 14 bossů, snímky.

**Hotovo, když:** nástup i smrt bosse jsou vidět na snímcích a zastavení při zásahu nerozbije zpomalení ani pauzu.

---

## M5 Věděl jsi? a Kniha

**Cíl:** hra mimochodem učí o krajích a dává důvod sbírat.

### Fakta o krajích

- `regions.gd`: každý kraj dostane pole `facts` se 2–3 položkami `{"text": …, "source": …}`. Zdroj se ve hře ukáže malým písmem, aby sis fakt mohl ověřit.
- Po výhře se na výherní obrazovce ukáže karta „Věděl jsi?“. Při opakovaném dobytí se fakta střídají (`facts_seen`).
- Karta dobytého kraje na mapě ukáže jeden fakt jako upoutávku.

**Návrhy faktů** (každý je potřeba před vložením do hry ověřit a doplnit zdroj):

| Kraj | Fakt |
| --- | --- |
| Karlovarský | Vřídlo, nejteplejší pramen Karlových Varů, má teplotu kolem 72 °C. |
| Plzeňský | Plzeňský ležák se vaří od roku 1842. |
| Ústecký | Pravčická brána v Českém Švýcarsku je největší přirozená pískovcová brána v Evropě. |
| Liberecký | Vysílač a hotel na Ještědu vznikl v letech 1966–1973 podle návrhu Karla Hubáčka. |
| Královéhradecký | Sněžka (1603 m) je nejvyšší hora Česka. |
| Pardubický | Velká pardubická se běží od roku 1874. |
| Středočeský | Hrad Karlštejn založil Karel IV. roku 1348. |
| Praha | Pražský orloj byl sestrojen v roce 1410. |
| Jihočeský | Rožmberk u Třeboně je největší rybník v Česku. |
| Vysočina | Historické centrum Telče je od roku 1992 na seznamu UNESCO. |
| Jihomoravský | Brněnský drak v průchodu Staré radnice je ve skutečnosti vycpaný krokodýl. |
| Olomoucký | Sloup Nejsvětější Trojice v Olomouci je od roku 2000 památkou UNESCO. |
| Zlínský | Tomáš Baťa založil obuvnickou firmu ve Zlíně v roce 1894. |
| Moravskoslezský | V Dolní oblasti Vítkovice se surové železo vyrábělo až do roku 1998. |

### Kniha (bestiář)

- Nové tlačítko „Kniha“ v horní liště mapy (`MapUI.TopBar`), ikona knihy.
- Deska se záložkami: **Nepřátelé** (14 krajů × 3 nepřátelé + boss + náčelník) a **Odznaky**.
- Neviděný nepřítel je černá silueta s „???“ (upečená textura s `modulate` černě). Viděný ukáže kresbu, jméno, krátký popis (`lore`), radu do boje (`tip`, například „Nabíhá v přímce – uskoč do strany“) a počet zabití. U bosse nejlepší čas a hvězdy.
- Data: `lore` a `tip` pro všech 42 nepřátel a 14 bossů v `enemies.gd`.
- Uložení: `bestiary.kills` a `bestiary.bosses` se zapisují na konci bitvy (ne při každém zabití).

### Odznaky

- `scripts/data/badges.gd`: asi 15 odznaků, každý s podmínkou a odměnou ve zlatě. Například:
  - První krok: dobyj první kraj,
  - Půlka Česka: dobyj 7 krajů,
  - Sběratel hvězd: získej všech 42 hvězd,
  - Bleskovka: poraz bosse do 30 sekund,
  - Nedotknutelný: dobyj kraj bez jediného zásahu,
  - Evolucionista: vytvoř všech 8 evolucí,
  - Tisícovka: poraz 1000 nepřátel v jedné bitvě,
  - Plná Kniha: potkej všechny nepřátele.
- Při získání stuha „Nový odznak!“ a zvuk truhly.
- Kresby odznaků: štíty v barvách vzácnosti s ikonou (`IconArt`).

**Testy:** `--screen=book`, snímky Knihy, výherní obrazovka s faktem.

**Hotovo, když:** Kniha se plní hraním, fakta mají zdroje a odznaky se dají získat.

---

## M6 Hudba podle oblasti

**Cíl:** každá oblast zní jinak a mapa má českou náladu.

- `scripts/autoload/sfx.gd`, funkce `_music(kind)`, nové styly:

| Styl | Kde | Jak zní |
| --- | --- | --- |
| Dechovka | mapa | polka ve 2/4 kolem 120 BPM: basa na první dobu, krátké akordy na druhou, veselá melodie „trubek“ v durové stupnici |
| Cimbálová | Jihomoravský, Zlínský, Olomoucký | brnkavý zvuk s rychlým doznivem a tremolem, lydická nebo harmonická moll stupnice, prodleva v basu |
| Hory | Královéhradecký, Liberecký, Karlovarský | pomalejší, pentatonika, „flétna“ (sinus s vibratem) |
| Hutě | Ústecký, Moravskoslezský | těžké údery „kovadliny“ (kovový šum), hluboký bzučák |
| Praha | Praha | rychlé arpeggio jako cembalo a tikání hodin |
| Bitva (dnešní) | ostatní kraje | beze změny |
| Boss | souboj s bossem | dnešní, s nástrojem oblasti |

- `regions.gd`: nové pole `music` u každého kraje.
- Pravidlo z CLAUDE.md platí dál: hudba se generuje v jednom vlákně na pozadí. Předem se připraví jen hudba mapy a aktuálního kraje (každá smyčka zabere asi 1 MB paměti).
- `--export-music=složka` uloží smyčky jako WAV (`AudioStreamWAV.save_to_wav()`), abys je mohl poslechnout a schválit dřív, než se zabudují.

**Hotovo, když:** schválíš ukázky a každá oblast hraje svůj styl.

---

## M7 Události v boji

**Cíl:** uprostřed boje přibydou rozhodnutí s rizikem a odměnou.

- Kdy: v 30 % a 65 % času jedna náhodná událost (dvakrát po sobě ne stejná), 500–700 px od hrdiny. U okraje obrazovky šipka s ikonou ukazuje směr. Když hráč událost 40 s ignoruje, zmizí.
- Kód: `scripts/battle/events.gd` (`EventSystem`), data `scripts/data/events.gd`, kresby `scripts/art/event_art.gd`, dialogy přes `BattleOverlay` (stejné desky jako dnes).

| Událost | Co se stane |
| --- | --- |
| Oltář | Hra se pozastaví a nabídne oběť: 20 % max. životů za legendární kartu, nebo 50 zlata z kraje za epickou kartu, nebo odejít. |
| Boží muka | Hrdina musí 5 s stát v kruhu (ukazatel postupu), nepřátelé útočí dál. Pak 60 s požehnání: +30 % poškození, nebo +30 % rychlosti, nebo dvojnásobný magnet, nebo regenerace 3 životy za sekundu. |
| Prokletý obelisk | Dotyk spustí kletbu: 3 elity a vlna. Po jejich porážce legendární truhla. |
| Kramář s vozíkem | Obchod za zlato z kraje: svíčková (vyléčí 50 %) 15, přehození karet 10, náhodná vzácná karta 30, magnet 8. |
| Zamčená truhla | Otevře se, když v jejím okolí padne 40 nepřátel (kruh postupu). |

- `Battle.gen_cards(n, luck)`: `luck = 2` zaručí legendární vzácnost u předmětů.
- Požehnání: nový slovník `Battle.buffs` s časovači, `recalc_stats()` je započítá, HUD ukáže ikonu s odpočtem.
- Automatický hráč chodí k událostem a volí rozumně (u oltáře jen při víc než 70 % životů).

**Testy:** `--test-event=oltar|muka|obelisk|kramar|truhla`, snímky dialogů.

**Hotovo, když:** v každé bitvě přijdou dvě události, všech pět funguje a simulace projdou.

---

## M8 Hrdinové

**Cíl:** různé začátky a styly hry. Hrdinové jsou z českých pověstí (podle Starých pověstí českých, podrobnosti je dobré ověřit).

| Hrdina | Start | Vlastnosti | Ultimátka | Odemčení |
| --- | --- | --- | --- | --- |
| Čech (dnešní) | Meč | vyvážený | Hrom | od začátku |
| Bivoj, silák, který podle pověsti přinesl živého kance | Kruhové štíty | +30 % životů, +50 % odhoz, −10 % rychlosti | Kančí úder: dupnutí, rázová vlna odhodí a na 2 s omráčí vše kolem | poraz 3 bosse |
| Kněžna Libuše, věštkyně, která předpověděla slávu Prahy | Řetězový blesk | +15 % zkušeností, +1 přehození, −15 % životů | Věštba: nepřátelé na 4 s zamrznou | dobyj Prahu |
| Horymír se Šemíkem, jehož kůň podle pověsti skočil z Vyšehradu | Kuše | +15 % rychlosti, delší úskok, který zraňuje a nabíjí se o 40 % rychleji | Šemíkův skok: velký skok ve směru joysticku s dopadem | získej 20 hvězd |

- Data: `scripts/data/heroes.gd` (`HeroDefs`).
- Kresby: `HeroArt.draw(ci, t)` se rozšíří na `draw(ci, t, hero_id)`. Společné tělo a pro každého vlastní kostým:
  - Bivoj: kožich, mohutné vousy, holé paže, kyj,
  - Libuše: dlouhý cop, věnec, bílé šaty s modrým pláštěm, hůl s lipovým listem,
  - Horymír: jezdec na bílém koni (větší sprite, asi 1,3×).
- Kód:
  - `Battle._start()`: startovní zbraň podle hrdiny,
  - `recalc_stats()`: úpravy statistik,
  - `use_ult()`: varianta ultimátky (`match`),
  - `Player.dash()`: Horymírův úskok,
  - HUD portrét `icon:hero_<id>`.
- UI: deska „Hrdinové“ z horní lišty mapy a řádek „Hrdina: [portrét] Změnit“ v kartě kraje. Zamčení hrdinové ukazují podmínku. Při odemčení stuha a zvuk.
- Odznaky z M5 se propojí (např. „Vyhraj s každým hrdinou“).

**Testy:** `--hero=bivoj|libuse|horymir`, simulace balancu pro každého hrdinu na 3 krajích, galerie s hrdiny.

**Hotovo, když:** všichni čtyři hrdinové jsou hratelní, mají vlastní ultimátku a v simulaci vyhrávají podobně často.

---

## M9 Po dohrání

**Cíl:** hra pokračuje i po dobytí všech 14 krajů.

### Úrovně žáru (1–10)

Odemknou se po závěrečné oslavě. V horní liště mapy přibude volič s plamínky. Úrovně se sčítají:

1. Nepřátelé +15 % životů.
2. Elity dvakrát častěji.
3. O jedno přehození karet méně.
4. Nepřátelé o 10 % rychlejší.
5. Boss má 4. fázi (všechny útoky, rychlejší).
6. Léčení o polovinu slabší.
7. Nástrahy dvakrát častěji.
8. Dva minibossové.
9. Hrdina začíná s −20 % životů.
10. Krakonošova zkouška: boss +30 % životů a útoky bez prodlevy navíc.

- Odměna +20 % zlata za každou úroveň. Mapa u kraje ukáže nejvyšší pokořený žár plamínky.
- Data: `scripts/data/modifiers.gd`. Kód: `Battle` čte aktivní modifikátory při startu (násobitele v `enemy_hp_mult()` a spol., režisér, `Boss`).

### Nekonečný režim

- Po výhře nad bossem tlačítko „Bojovat dál“. Režisér pokračuje i za 100 % času (vlny dál houstnou, strop nepřátel zůstává) a každé 2 minuty přijde miniboss.
- Skóre je čas přežití po bossovi. Rekord kraje se ukáže v jeho kartě. Zlato se sbírá dál.

### Denní výzva

- Tlačítko „Denní výzva“ na mapě. Kraj, hrdina a dva modifikátory se vyberou podle data, takže je výzva ten den pro všechny stejná.
- Modifikátory, například:
  - jen jedna zbraň,
  - nepřátelé dvakrát rychlejší, ale slabší,
  - elixír léčí,
  - bez úskoku,
  - obří nepřátelé,
  - zlatá horečka (mince všude).
- Náhoda: semínko z data pro režiséra a karty (vlastní `RandomNumberGenerator` místo globálního `randf()`). Kvůli různému počtu snímků za sekundu nebude průběh úplně stejný, výběr kraje, hrdiny a modifikátorů ano.
- Odměna 100 zlata jednou denně plus série (+10 za každý den v řadě, nejvýš 7 dní). Výsledky se ukládají v telefonu.
- Online žebříček není v plánu: potřeboval by server.

**Testy:** `--heat=5`, `--endless`, `--daily=2026-10-02`, simulace na žáru 5 a 10.

**Hotovo, když:** po dohrání jde zvolit žár, nekonečný režim ukládá rekordy a denní výzva se mění každý den.

---

## M10 Google Play

**Cíl:** hra v obchodě Google Play.

### Co uděláš ty

1. Založíš vývojářský účet v Google Play Console (jednorázový poplatek 25 USD a ověření totožnosti).
2. U nových osobních účtů Google vyžaduje před vydáním uzavřené testování s alespoň 12 testery po dobu 14 dní. Pravidla se mění, ověř si aktuální stav v Play Console.
3. Vyplníš dotazník o obsahu (věkové hodnocení) a o datech (hra žádná data nesbírá).
4. Rozhodneš o názvu vývojáře a o tom, že hra bude zdarma a bez reklam (nebo jinak).

### Co se udělá v kódu

- **Vlastní podpisový klíč** (upload key) vytvořený přes `keytool`. **Nesmí do repozitáře.** Uloží se jako tajemství v GitHubu (keystore v base64 a hesla). Google pak podepisuje aplikaci vlastním klíčem (Play App Signing).
- **AAB místo APK:** Google Play vyžaduje formát AAB, který Godot vyrobí jen přes Gradle:
  - nová předvolba „Android Play“ v `export_presets.cfg`: `gradle_build/use_gradle_build=true`, `gradle_build/export_format=1`,
  - Android build template se nainstaluje parametrem `--install-android-build-template`,
  - cílová verze Androidu podle aktuálního požadavku Google Play (ověřit, co nastavuje Godot 4.5 ve výchozím stavu),
  - `version/code` se zvyšuje s každým vydáním.
- **Workflow** `.github/workflows/play.yml`: při značce `v*` sestaví podepsaný AAB a nahraje ho jako artefakt. Poprvé ho do Play Console nahraješ ručně.
- **Podklady pro obchod** vygenerované v kódu (bez převzaté grafiky):
  - ikona 512 × 512 z `icon.svg`,
  - grafika 1024 × 500 (nová vývojářská scéna ve stylu hry),
  - snímky obrazovky přes `--shots`,
  - krátký a dlouhý popis v češtině, případně v angličtině,
  - jednoduché zásady ochrany soukromí (stránka „hra nesbírá žádná data“).

**Hotovo, když:** AAB je v interním testování a z Google Play se nainstaluje na tvůj telefon.

---

## Otevřená rozhodnutí

Než se pustíme do příslušného milníku, potřebuju od tebe odpovědi:

- [ ] **Hrdinové (M8):** sedí Bivoj, kněžna Libuše a Horymír se Šemíkem, nebo chceš jiné postavy?
- [ ] **Odemykání hrdinů (M8):** za úspěchy (jak je v plánu), nebo nákupem za zlato?
- [ ] **Nekonečný režim (M9):** po každém bossovi, nebo až po dohrání celé hry?
- [ ] **Hudba (M6):** chceš nejdřív slyšet ukázky?
- [ ] **Google Play (M10):** zdarma a bez reklam? Pod jakým jménem vývojáře?

## Jak zadávat Claude Code

Jeden milník = jedno zadání (u větších milníků dvě). Například:

> Pokračuj v projektu SurvivorCZ. Implementuj milník M2 (nástrahy krajů) podle `docs/plan-vylepseni.md`. Drž se pravidel v `CLAUDE.md`, na konci aktualizuj `PROJECT_STATUS.md`, sestav APK a pošli mi ho.

Po každém milníku si APK zahraj a napiš, co ti sedí a co ne. Úpravy se pak zapracují, než se začne další milník.
