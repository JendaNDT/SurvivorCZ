# Dobyj Česko! – Project Status
*Naposled aktualizováno: 02. 10. 2026*

## 🎯 Co to je
Survivor strategie pro Android ve stylu Vampire Survivors: hrdina postupně dobývá 14 krajů Česka. Grafika připomíná Clash of Clans a celá vzniká v kódu.
Stack: Godot 4.5, GDScript, renderer GL Compatibility, export do APK (bez Gradle).

## ⏭️ Příští krok
**Zahrát si verzi 1.3.0 s náčelníky a napsat, jestli jsou moc silní nebo slabí. Pak milník M4 (pocit z boje).**
Hlavně: jak dlouho trvá souboj s náčelníkem (automat 20–50 s), jestli bije moc tvrdě na Zlínsku a Olomoucku a jestli je vidět šipka, když je mimo obrazovku. Celý plán je v `docs/plan-vylepseni.md`. Před M8 je potřeba odpovědět na otevřená rozhodnutí na konci plánu.

Balanc je vyladěný automatickým hráčem: rychlá simulace bez grafiky (`--headless --fixed-fps 30 … --autoplay --quit-at-end`) zvládne celý kraj za ~20–40 s. S nástrahami automat vyhrál 11 ze 14 krajů napoprvé a po opravě testovacího nástroje (délka kraje teď odpovídá obtížnosti) i Pardubicko, Vysočinu, Olomoucko a Zlínsko na vysoké obtížnosti. Boss trvá 35–95 s. S náčelníky (M3) vyhrál 23 z 28 bitev (každý kraj dvakrát), náčelník padl za 10–54 s. Čísla obtížnosti jsou v `scripts/battle/battle.gd` a `scripts/battle/director.gd`, nástrahy v `scripts/data/hazards.gd`, náčelníci v `scripts/data/enemies.gd` (`MINIBOSSES`) a `scripts/battle/mini_boss.gd`.

## ✅ Hotovo
- Mapa Česka se 14 kraji (skutečné hranice), odemykání sousedů, hvězdy, mlha nad zamčenými kraji, řeky, hory, hrady s vlajkou
- Karta kraje s bossem a nepřáteli, Zbrojnice (10 trvalých vylepšení za zlato), úvod „Jak hrát“, závěrečná oslava
- Bitva: joystick, úskok, ultimátka Hrom, 8 zbraní, 8 evolucí, 15 pasivních předmětů se vzácností a štítky
- Režisér vln (formace, obklíčení, elity s truhlou, poslední vlna), 7 archetypů nepřátel
- 42 nepřátel a 14 bossů kreslených kódem, každý boss má 3 fáze a útoky ohlášené na zemi
- 9 procedurálních textur země, 48 druhů dekorací, palisáda kolem arény bosse
- Syntetizované zvuky a 3 hudební smyčky (generují se na pozadí)
- Ukládání postupu (`user://save.json`), tlačítko Zpět na Androidu
- Podepsané APK a workflow pro GitHub Actions, které APK sestaví automaticky
- Vývojářská galerie kreseb, automatický hráč a rychlá simulace balancu bez grafiky
- Meč míří sám na nejbližšího nepřítele
- **M1 Telefon a nastavení (verze 1.1.0):**
  - nová deska nastavení na mapě i v pauze: posuvníky hudby a efektů, přepínače vibrací, úsporné grafiky, ukazatele FPS a ovládání pro leváky
  - úsporná grafika: 150 nepřátel místo 230, bez stínů, méně částic, čísel a dekorací, jednodušší země, vykreslování v 1280×720 (v testu při 1080p 2,6× rychlejší)
  - po první bitvě, která se sekala (pod 40 FPS), mapa sama nabídne úspornou grafiku
  - vibrace při zásahu, dopadu bossova útoku, hromu, nové úrovni, truhle a smrti bosse
  - uložení verze 2: starý postup se načte (ověřeno), vypnutý zvuk se převede na nulovou hlasitost, smazání postupu nastavení nechá
  - vývojářské parametry `--bench`, `--taps`, `--quality`, `--show-fps`, `--left-handed`, `--test-settings`, `--screen=settings|perf`
- **M3 Náčelníci (verze 1.3.0):** v polovině každého kraje seskočí náčelník: hlavní nepřítel kraje ve dvojnásobné velikosti, se zlatou korunou, září, jménem a ukazatelem životů nad hlavou. Má dva útoky bosse (14 různých kombinací, např. dvojitý výpad žokeje, rázová vlna Golema). Když je mimo obrazovku, ukazuje na něj zlatá šipka. Po porážce padne větší truhla náčelníka: evoluce, když je k dispozici, jinak aspoň jedna epická karta. Když hrdina náčelníka nestihne porazit do příchodu bosse, náčelník uteče. Nástrahy mu ubližují, pásy a vítr ho unášejí. Galerie strana 8, testy `--test-miniboss` a `--test-chief-chest[=evo]`
- **M2 Nástrahy krajů (verze 1.2.0):** 14 mechanik (gejzíry, sudy, pásy, mlha, vánice, dostih, katapult, tramvaj, rybníky, spory, vítr, kombajn, švestky, praskliny), stuha s nápovědou při prvním výskytu, nové kresby (galerie strana 7) a 10 zvuků, automat se vyhýbá pruhům a nebezpečným místům
- **Stabilita (verze 1.2.0):**
  - hudba se už neskládá ve vlákně na pozadí (to dřív poškozovalo paměť), ale po kouscích v hlavním vlákně, a uloží se do telefonu
  - kresby kraje se po bitvě uvolní: grafická paměť se ustálí na ~32 MB (dřív rostla o ~10 MB s každým krajem)
  - opravena chyba ve smyčce nepřátel, když výbuch zabil víc nepřátel naráz
  - černá skříňka: po pádu mapa ukáže, kde a kdy k němu došlo, a hra zapisuje log i na telefonu (ověřeno násilným ukončením hry uprostřed bitvy)
  - zátěžový test `--soak=N`: 28 bitev za sebou bez úniku paměti
  - verze 1.2.1: gesto Zpět na mapě se zeptá „Ukončit hru?“ místo okamžitého konce, mapa už každý snímek nepřepočítává obrysy štítů, vlajek a šipky
  - verze 1.2.5: hudba přes `AudioStreamGenerator` místo smyčkové WAV (oprava pádu), efekty mají na konci kousek ticha, nová mezipaměť hudby `music_*_v2.bin`, sonda `--dev-script`
  - verze 1.2.4: hlášení o pádu čte z Androidu důvod ukončení a výtah z náhrobku, tlačítko „Zkopírovat“ dá celé hlášení do schránky
  - verze 1.2.3: log zapisuje otevření kraje, Zbrojnice, nastavení a začátek a konec pečení kreseb
  - verze 1.2.2: každý zvuk má vlastní přehrávač, sběrnice jsou v `default_bus_layout.tres`, obchod jen přepisuje tlačítka, log se zapisuje hned a hlášení o pádu ukáže posledních 6 řádků (ťuknutí, obrazovky)
  - nové testy: skutečné míchání zvuku (ALSA bez zvukové karty) a ladicí režim, který odhalí přístup ke smazaným objektům. 4 celé bitvy a 5 přechodů mapa ↔ bitva bez jediné chyby

## 📝 TODO
### Plán vylepšení (podrobně v `docs/plan-vylepseni.md`)
- ~~M1 Telefon a nastavení~~ hotovo
- ~~M2 Nástrahy krajů~~ hotovo
- ~~M3 Minibossové~~ hotovo
- M4 Pocit z boje: nástup bosse, zastavení při zásahu, prach, smrti bossů
- M5 Věděl jsi? a Kniha: fakta o krajích se zdroji, bestiář, odznaky
- M6 Hudba podle oblasti: dechovka, cimbál, hory, hutě, Praha
- M7 Události v boji: oltář, boží muka, obelisk, kramář, zamčená truhla
- M8 Hrdinové: Bivoj, kněžna Libuše, Horymír se Šemíkem
- M9 Po dohrání: úrovně žáru, nekonečný režim, denní výzva
- M10 Google Play: vlastní klíč, AAB, stránka v obchodě

### Backlog (později)
- Modulátory a fúze zbraní z design dokumentu

## 🐛 Známé bugy
- **Pády na plochu jsou opravené (verze 1.2.5, ověřeno na telefonu):** padalo to ve vlákně AudioTrack, ve funkci Godotu, která míchá 16bitový mono zvuk WAV (`AudioStreamPlaybackWAV`). Četla za koncem velkého bloku hudby. Hudba teď hraje přes `AudioStreamGenerator`. Pravidla, aby se to nevrátilo, jsou v `CLAUDE.md` (Zvuk).
- Zlínsko a Olomoucko na obtížnosti 11–12 vyhraje automat jen asi napůl (boss je těsně neporazí), Moravskoslezsko na obtížnosti 13 taky. Na Zlínsku jednou hrdina padl už v souboji s náčelníkem. Až si je zahraješ, napiš, jestli jsou moc těžké.
- Když telefon nestíhá 30 FPS, hra se zpomalí (krok simulace je omezený na 1/30 s).
- Opraveno: smrt bosse uprostřed zásahu jedovou kaluží mohla způsobit chybu indexu.

## 🏗️ Klíčová rozhodnutí
- **Godot místo PixiJS z design dokumentu:** zadání chtělo hru pro Android v Godotu.
- **Grafika:** kresby přes `_draw()` se jednou „upečou“ do textur (`Baker`), proto hra utáhne stovky nepřátel.
- **Délka kraje 3–5 minut** místo 20minutového runu z design dokumentu, aby to sedělo na mobil.
- **Obtížnost podle počtu dobytých krajů**, ne podle konkrétního kraje, protože pořadí si volí hráč.
- **Podpisový klíč pro instalaci mimo obchod je v repozitáři** (`android/sideload.keystore`), aby šly nové verze instalovat přes staré. Pro Google Play je potřeba vlastní soukromý klíč.
- **Úsporná grafika kreslí v základním rozlišení:** test ukázal, že hru brzdí vykreslování, ne herní logika (bez vykreslování 136 FPS). Text je pak o kousek méně ostrý.
- **Plynulost se měří od 10. s do konce bitvy**, ne 5.–20. s jako v plánu, protože na začátku je nepřátel málo.
- **Žádná vlákna na pozadí:** dlouhé výpočty se rozkládají do snímků. Vlákna v GDScriptu poškozovala paměť.
- **Nástrahy ubližují i nepřátelům:** běžné nepřátele zabijí, takže jsou zbraní i hrozbou. V aréně bosse běží jen počasí a terén.
- **Náčelník dědí z bosse:** útoky zůstaly v `boss.gd` (ne ve sdíleném souboru z plánu), protože korutina na instanci po uvolnění uzlu nesáhne na smazaný objekt. Náčelník má 25 % životů bosse (ne 35 %) a útoky na 60 % síly, jinak by trval přes minutu a na vysoké obtížnosti zabíjel.

## 📁 Stav souborů
- `scripts/main.gd` – přepínání obrazovek a vývojářské parametry
- `scripts/autoload/` – kreslení (Art), pečení textur (Baker), uložení a nastavení (Game), zvuk (Sfx)
- `scripts/data/` – kraje, nepřátelé, bossové, zbraně, vylepšení
- `scripts/art/` – všechny kresby
- `scripts/battle/` – logika bitvy (`hazards.gd` = nástrahy krajů, `mini_boss.gd` = náčelník)
- `scripts/map/`, `scripts/ui/` – mapa a uživatelské rozhraní (`settings_board.gd`, `cc_slider.gd`, `cc_toggle.gd`)
- `shaders/` – země, moře, tráva na mapě
