# Dobyj Česko!

Survivor strategie pro Android postavená v **Godotu 4.5**. Hrdina si postupně podmaňuje všech 14 krajů Česka. V každém kraji na něj ze všech stran útočí vlny nepřátel, kteří patří k danému kraji. Hrdina útočí sám, hráč ho jen vede joystickem, sbírá elixír (zkušenosti) a na každé nové úrovni si vybírá jedno ze tří vylepšení. Kraj je dobytý, když hrdina přežije do konce časomíry a porazí bosse.

Vzhled se inspiruje kresleným stylem Clash of Clans: syté barvy, silné tmavé obrysy, stínování „do 3D“, lesklá zaoblená tlačítka, dřevěné panely s pergamenem a výrazné písmo s obrysem. **Veškerá grafika vzniká v kódu.** Hra neobsahuje jediný obrázek ani grafiku převzatou odjinud.

Hra vychází z obecného návrhu v [`docs/survivor-hra-design.md`](docs/survivor-hra-design.md). Převzala z něj úskok, ultimátku, štítky zbraní a předmětů, vzácnosti karet, přehazování a přeskakování karet, evoluce, elity s truhlou, režiséra vln a bosse se třemi fázemi a ohlášenými útoky. Délku runu zkrátila na jeden kraj (3–5 minut) a místo PixiJS používá Godot.

## Instalace na telefon

1. Stáhni soubor `DobyjCesko-arm64.apk` (25 MB, pro 64bitové telefony, tedy prakticky všechny z posledních let), nebo univerzální `DobyjCesko.apk` (50 MB, i pro starší 32bitové telefony). Sestavené APK se nekomituje do repozitáře, viz [Sestavení APK](#sestavení-apk).
2. Otevři ho v telefonu. Android se zeptá, jestli smí instalovat aplikace z tohoto zdroje. Povol to.
3. Nainstaluj a spusť **Dobyj Česko!**. Hra běží na šířku.

APK je podepsané „sideload“ klíčem z `android/sideload.keystore`, takže další verze půjde nainstalovat přes tu starou a postup zůstane uložený. Klíč je veřejný (heslo je v repozitáři), proto se hodí jen pro instalaci mimo obchod. Pro Google Play je potřeba vytvořit vlastní soukromý klíč.

## Jak se hraje

- Na začátku je otevřený jen **Karlovarský kraj**. Každý dobytý kraj odemkne všechny sousední kraje.
- **Pohyb:** polož prst kamkoli na obrazovku (mimo tlačítka) a objeví se joystick. Hrdina útočí sám, meč míří na nejbližšího nepřítele.
- **Úskok** (modré tlačítko vpravo dole): krátký rychlý skok, při kterém hrdinu nic nezraní. Nabíjí se 2,2 s.
- **Hrom** (žluté tlačítko): ultimátka, nabíjí se zabíjením. Zasáhne blesky všechny nepřátele na obrazovce.
- **Elixír** (růžové kapky) dává zkušenosti. Na každé nové úrovni vybíráš 1 ze 3 karet: novou zbraň, vyšší úroveň zbraně, nebo pasivní předmět. Karty můžeš **přehodit** (2× za kraj, víc se dá koupit) nebo **přeskočit** za trochu zlata a života.
- **Elity** (nepřátelé se zlatou září) přicházejí ve 38 % a 70 % času a padá z nich **truhla** s lepší odměnou.
- **Svíčková** doplní třetinu života, **magnet** přitáhne všechen elixír.
- Když časomíra doběhne, kolem hrdiny vyroste palisáda a přijde **boss**. Má tři fáze a jeho útoky se předem ukážou červeně na zemi.
- **Hvězdy:** 1 za dobytí, 2 když skončíš s aspoň polovinou životů, 3 když bosse porazíš do 60 sekund.
- **Zlato** (z mincí a za výhru) utratíš ve **Zbrojnici** za trvalá vylepšení: životy, poškození, rychlost, magnet, brnění, regeneraci, přehazování karet, víc zlata, víc zkušeností a „druhou šanci“.
- Obtížnost roste s počtem už dobytých krajů. Na pořadí tedy nezáleží, každý další kraj je o kus těžší. Kraj trvá zhruba 3 až 5 minut (časomíra 2:30 až 4:14 plus souboj s bossem).
- Hra končí oslavou, když dobudeš všech 14 krajů.

Na počítači funguje i klávesnice: **WASD / šipky** pohyb, **mezerník** úskok, **E** hrom, **Esc** pauza.

## Nastavení

Ozubené kolečko na mapě nebo **Nastavení** v pauze:

- **Hudba** a **Efekty**: hlasitost zvlášť, posuvníkem.
- **Vibrace**: telefon krátce zavibruje při zásahu, dopadu bossova útoku, nové úrovni a smrti bosse.
- **Úsporná grafika**: pro slabší telefony. Méně nepřátel naráz (150 místo 230), bez stínů, méně částic, čísel zásahů a dekorací, jednodušší textura země a vykreslování v základním rozlišení. V testu na počítači v rozlišení 1080p běžela hra 2,6× rychleji.
- **Ukazatel FPS**: v bitvě ukáže snímky za sekundu a počet nepřátel.
- **Pro leváky**: tlačítka úskoku a hromu se přesunou doleva.

Když se první bitva seká (pod 40 snímků za sekundu), hra po návratu na mapu sama nabídne úspornou grafiku.

## Kraje, nepřátelé a bossové

| Kraj | Prostředí | Nepřátelé | Boss |
| --- | --- | --- | --- |
| Karlovarský | lázeňský park, kolonády, prameny | lázeňský host, lázeňská oplatka, porcelánová konvice | **Vřídelní obr** |
| Plzeňský | pole, sudy, Šumava | pivní pěna (dělí se), valivý sud, chmelová šiška | **Pivní král** |
| Ústecký | uhelný důl, pískovcové skály | havíř, uhelný golem, dynamit (vybuchne) | **Kolesové rypadlo** |
| Liberecký | jizerský les, krystaly skla | skleněná baňka, bižuterní brouk, sklář (střílí) | **Ještěd** (vysílač, který ožil) |
| Královéhradecký | zasněžené Krkonoše | sněhová koule, sněhulák, horský skřítek | **Krakonoš** |
| Pardubický | dostihová louka, perníková chaloupka | perníček, dostihový kůň (nabíhá), Semtex | **Perníková ježibaba** |
| Středočeský | hrady, kostnice, Blaník | kostlivec z kostnice, blanický rytíř, lučištník | **Velitel blanických rytířů** |
| Praha | dlažba Starého Města | turista se selfie tyčí, pražský holub, Golem | **Pražský orloj** |
| Jihočeský | rybníky, rákosí, vrby | kapr, rak, vodník | **Král vodníků** (dušičky v hrníčcích) |
| Vysočina | hluboký les, houby, žula | brambora, divočák, muchomůrka | **Hřibí král** |
| Jihomoravský | vinice, sklepy | hrozen (dělí se), netopýr z Macochy, vinař | **Brněnský drak** |
| Olomoucký | Haná, pole, kašny | tvarůžek, Hanák, duch Praděda | **Tvarůžkový král** |
| Zlínský | Valašsko, roubenky, švestky | švestka, baťovka, Valach s valaškou | **Obří bota** |
| Moravskoslezský | ocelárny, struska, komíny | hutník, rozžhavený ingot, tatrovka | **Vysokopecní titán** |

Každý kraj má vlastní texturu země (tráva s cestičkami, dlažba, hlína, sníh, les, vinice, plech se žhavými prasklinami, pole, louka s tůňkami) a vlastní dekorace.

## Zbraně a evoluce

Zbraň na 8. úrovni se spárovaným pasivním předmětem nabídne **evoluci**.

| Zbraň | Evoluce (s předmětem) |
| --- | --- |
| Meč | Bruncvíkův meč (Medvědí síla) |
| Vrhací sekera | Valašský vír (Kniha kouzel) |
| Kuše | Husitská píšťala (Přesýpací hodiny) |
| Ohnivá koule | Pekelný déšť (Ohnivá runa) |
| Řetězový blesk | Perunův hrom (Bouřkový amulet) |
| Mrazivá aura | Věčný mráz (Ledový krystal) |
| Kruhové štíty | Vozová hradba (Kroužkové brnění) |
| Jedový kotlík | Morová bažina (Jedová ampule) |

Pasivní předměty mají vzácnost (běžná, vzácná, epická, legendární), která určuje sílu bonusu. Zbraně i předměty nesou štítky (oheň, led, blesk, jed, plocha…), a karty, které pasují k tvé sestavě, padají častěji.

## Jak vzniká grafika

- `scripts/autoload/art.gd` je knihovna kreslení: obrysy přes zvětšený polygon, svislé gradienty, stín ve spodní části tvaru, lesklé odlesky, oči s obočím, tlačítka, dřevěné panely, stuhy a ukazatele.
- Postavy, nepřátelé, bossové, dekorace, střely a ikony jsou funkce, které kreslí přes `CanvasItem` (`_draw`). Godot je pak jednou „upeče“ do textury ve dvojnásobném rozlišení (`scripts/autoload/baker.gd`). Hra díky tomu utáhne stovky nepřátel i na telefonu.
- Země a moře jsou shadery (`shaders/*.gdshader`), které texturu trávy, kamenů, sněhu nebo vln počítají ze souřadnic.
- Ikona aplikace je ručně napsané SVG (`icon.svg`).
- Zvuky a hudba se syntetizují v kódu (`scripts/autoload/sfx.gd`).
- Tvary krajů vycházejí z otevřených dat hranic krajů ČÚZK (RÚIAN), zjednodušených a převedených na souřadnice (`scripts/data/region_shapes.gd`).

## Projekt v Godotu

Otevři složku v Godotu 4.5 nebo novějším (Import → `project.godot`). Hlavní scéna je `scenes/main.tscn`. Téměř vše se staví z kódu, takže scény jsou minimální.

```
project.godot              nastavení (renderer GL Compatibility, orientace na šířku)
export_presets.cfg         export pro Android
icon.svg                   ikona aplikace
shaders/                   země v bitvě, moře a tráva na mapě
scripts/main.gd            přepínání mapa ↔ bitva ↔ závěr, přechod s mraky
scripts/autoload/          Art (kreslení), Baker (pečení textur), Game (uložení postupu), Sfx (zvuky)
scripts/data/              kraje, nepřátelé a bossové, zbraně a vylepšení, tvary krajů
scripts/art/               kresby hrdiny, nepřátel, bossů, dekorací, střel a ikon
scripts/battle/            bitva: hráč, nepřátelé, zbraně, střely, sběr, režisér vln, boss, efekty
scripts/map/               mapa Česka, karta kraje, Zbrojnice, úvod
scripts/ui/                tlačítka, posuvníky, přepínače, deska nastavení, HUD, dotykové ovládání, karty vylepšení, okna v bitvě, závěr
scripts/dev/, scenes/dev/  galerie kreseb pro kontrolu grafiky (do APK se nebalí)
```

## Sestavení APK

**Automaticky přes GitHub:** workflow `.github/workflows/android.yml` sestaví APK při každém pushi do `main`, nebo ho spustíš ručně v záložce *Actions → Android APK → Run workflow*. Hotový soubor stáhneš z detailu běhu v části *Artifacts*.

**Ručně v Godotu:** *Editor → Editor Settings → Export → Android* nastav cestu k Android SDK a k Javě (JDK 17+). Pak *Project → Export → Android → Export Project*. Pro podpis použij `android/sideload.keystore` (alias `dobyjcesko`, heslo `dobyjcesko`).

**Z příkazové řádky:**

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$PWD/android/sideload.keystore
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=dobyjcesko
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=dobyjcesko
godot --headless --path . --import
godot --headless --path . --export-release "Android" build/DobyjCesko.apk              # univerzální
godot --headless --path . --export-release "Android arm64" build/DobyjCesko-arm64.apk  # jen 64bit, poloviční velikost
```

## Testování

Parametry za `--` na příkazové řádce (viz `scripts/main.gd`):

```bash
godot --path . -- --battle=JHM --tier=5        # rovnou bitva o Jihomoravský kraj, obtížnost jako po 5 krajích
godot --path . -- --battle=KVK --autoplay      # hraje počítač, do konzole vypisuje průběh
godot --path . -- --skip-intro --conquer=KVK,PLK --gold=500   # mapa s dobytými kraji a zlatem
godot --path . -- --battle=KVK --autoplay --shots=/tmp/s --shot-times=10,60   # snímky obrazovky
godot --headless --path . --fixed-fps 30 -- --battle=MSK --autoplay --tier=13 --meta=2 --quit-at-end   # rychlá simulace bez grafiky
godot --path . -- --battle=STC --test-levelup                # okno s kartami (také --test-chest, --test-win, --test-lose, --test-pause, --test-settings)
godot --path . -- --battle=PHA --bench --quality=low         # plný počet nepřátel, po 13 s vypíše průměrné FPS (porovnání kvality)
godot --path . -- --screen=settings --taps="485,229>700,229@2"   # nastavení a simulované tažení prstem
godot --path . -- --battle=KVK --left-handed --show-fps      # nastavení jen pro jedno spuštění
godot --path . res://scenes/dev/gallery.tscn -- --page=3      # galerie kreseb (0 hrdina, 1–2 nepřátelé, 3 bossové, 4–5 dekorace, 6 efekty a ikony)
```
