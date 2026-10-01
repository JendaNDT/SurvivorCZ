# Dobyj Česko! – Project Status
*Naposled aktualizováno: 01. 10. 2026*

## 🎯 Co to je
Survivor strategie pro Android ve stylu Vampire Survivors: hrdina postupně dobývá 14 krajů Česka. Grafika připomíná Clash of Clans a celá vzniká v kódu.
Stack: Godot 4.5, GDScript, renderer GL Compatibility, export do APK (bez Gradle).

## ⏭️ Příští krok
**Zahrát si hru na telefonu a sepsat dojmy z obtížnosti.**
Balanc je vyladěný automatickým hráčem: rychlá simulace bez grafiky (`--headless --fixed-fps 30 … --autoplay --quit-at-end`) zvládne celý kraj za ~20 s. Automat vyhrál kraje na obtížnosti 0, 1, 5, 9, 12 i 13 (s vylepšeními ze Zbrojnice), souboj s bossem trval 40–70 s a celý kraj 4–5 minut. Čísla obtížnosti jsou v `scripts/battle/battle.gd` (`enemy_hp_mult`, `enemy_dmg_mult`, `boss_dmg_mult`, HP bosse ve `start_boss`) a v `scripts/battle/director.gd` (`rate`).

## ✅ Hotovo
- Mapa Česka se 14 kraji (skutečné hranice), odemykání sousedů, hvězdy, mlha nad zamčenými kraji, řeky, hory, hrady s vlajkou
- Karta kraje s bossem a nepřáteli, Zbrojnice (10 trvalých vylepšení za zlato), nastavení, úvod „Jak hrát“, závěrečná oslava
- Bitva: joystick, úskok, ultimátka Hrom, 8 zbraní, 8 evolucí, 15 pasivních předmětů se vzácností a štítky
- Režisér vln (formace, obklíčení, elity s truhlou, poslední vlna), 7 archetypů nepřátel
- 42 nepřátel a 14 bossů kreslených kódem, každý boss má 3 fáze a útoky ohlášené na zemi
- 9 procedurálních textur země, 48 druhů dekorací, palisáda kolem arény bosse
- Syntetizované zvuky a 3 hudební smyčky (generují se na pozadí)
- Ukládání postupu (`user://save.json`), tlačítko Zpět na Androidu
- Podepsané APK a workflow pro GitHub Actions, které APK sestaví automaticky
- Vývojářská galerie kreseb, automatický hráč a rychlá simulace balancu bez grafiky
- Meč míří sám na nejbližšího nepřítele (při couvání před hordou jinak sekal do prázdna)

## 📝 TODO
### Backlog (později)
- Víc postav hrdiny (design dokument: Strážce, Pyromantka, Lovec)
- Události na mapě kraje (oltář, svatyně, obchodník)
- Modulátory a fúze zbraní z design dokumentu
- Nastavení hlasitosti hudby a efektů zvlášť
- Denní výzva a úrovně žáru po dohrání

## 🐛 Známé bugy
- Žádné potvrzené. Výkon na slabých telefonech zatím neověřený (cíl je ~230 nepřátel naráz).
- Opraveno: generování hudby ve více vláknech najednou poškozovalo paměť (teď jedno vlákno).
- Opraveno: smrt bosse uprostřed zásahu jedovou kaluží mohla způsobit chybu indexu.

## 🏗️ Klíčová rozhodnutí
- **Godot místo PixiJS z design dokumentu:** zadání chtělo hru pro Android v Godotu.
- **Grafika:** kresby přes `_draw()` se jednou „upečou“ do textur (`Baker`), proto hra utáhne stovky nepřátel.
- **Délka kraje 3–5 minut** místo 20minutového runu z design dokumentu, aby to sedělo na mobil.
- **Obtížnost podle počtu dobytých krajů**, ne podle konkrétního kraje, protože pořadí si volí hráč.
- **Podpisový klíč pro instalaci mimo obchod je v repozitáři** (`android/sideload.keystore`), aby šly nové verze instalovat přes staré. Pro Google Play je potřeba vlastní soukromý klíč.

## 📁 Stav souborů
- `scripts/main.gd` – přepínání obrazovek a vývojářské parametry
- `scripts/autoload/` – kreslení (Art), pečení textur (Baker), uložení (Game), zvuk (Sfx)
- `scripts/data/` – kraje, nepřátelé, bossové, zbraně, vylepšení
- `scripts/art/` – všechny kresby
- `scripts/battle/` – logika bitvy
- `scripts/map/`, `scripts/ui/` – mapa a uživatelské rozhraní
- `shaders/` – země, moře, tráva na mapě
