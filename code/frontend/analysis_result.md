# Projekt-Analyse: Gehirnzellen Massaker (IoT Drink Mixer Frontend)

> Analyse erstellt am: 2026-05-03

---

## 1. Überblick

**Projektname:** `iot_drink_mixer` (Anzeigename: *Gehirnzellen Massaker* / *Braincell Massacre*)

**Typ:** Flutter Multi-Plattform App (Android, iOS, Linux, macOS, Windows, Web)

**Zweck:** Eine mobile App, die ein **Schere-Stein-Papier-Trinkspiel** für zwei Spieler steuert. Die App kommuniziert über **Bluetooth Low Energy (BLE)** mit einem ESP32-Mikrocontroller, der die Gestenerkennung übernimmt und einen Cocktail-Mixer (mit 4 Pumpen) ansteuert. Der Verlierer muss einen vom System per **KI-Bildanalyse** ausgewählten Cocktail trinken.

**Flutter SDK:** `^3.7.2`
**Versionsnummer:** `1.0.0+1`

---

## 2. Architektur

Die App folgt einer **feature-basierten Architektur** mit klarer Trennung von UI, Services und Modellen.

```
lib/
├── main.dart                 → App-Einstieg, MaterialApp, Routing
├── core/
│   └── theme/                → Design-System (Farben, Typografie, Radien, Theme)
├── data/
│   └── cocktail_catalog.dart → Hardcodierter KI-Cocktail-Katalog
├── models/                   → Datenmodelle (Drink, Cocktail, Gesture, RoundResult)
├── services/                 → Business-Logic & externe Schnittstellen (BLE, ML)
└── features/
    ├── home/                 → Startseite + BLE-Verbindungsmanagement
    ├── game/                 → Spielablauf, Foto-Capture, Spielmechanik
    └── recipes/              → Rezeptkatalog mit Filter & Suche
```

### Architektonische Stärken
- **Sauber getrennte Schichten** (UI ↔ Service ↔ Modell)
- **Interface-basiertes Service-Design** (`DrinkService`, `MixerService`, `CocktailService`) → leicht testbar / mock-bar
- **Dependency Injection** über Konstruktor-Parameter (siehe `GameScreen`)
- **Singleton-BLE-Service** mit eingebautem Test-Modus (kein ESP32 nötig zur Entwicklung)
- **Stream-basierte Reaktivität** für BLE-Status und Nachrichten

---

## 3. Hauptkomponenten

### 3.1 BLE-Kommunikation (Kern der App)

Die App nutzt den **Nordic UART Service (NUS)** für die Kommunikation mit dem ESP32.

**UUIDs:**
- Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- TX (App → ESP32): `6E400002-...`
- RX (ESP32 → App): `6E400003-...`

**Protokoll:**

| Richtung | Befehl | Zweck |
|---|---|---|
| App → ESP | `start` | Spiel beginnen |
| ESP → App | `start_ok` | Bestätigung |
| ESP → App | `runde_x_y_z` | Rundenergebnis (x=Runde, y=P1-Geste, z=P2-Geste, 0=Stein, 1=Papier, 2=Schere) |
| App → ESP | `runde_ok` | Bestätigung Runde erhalten |
| App → ESP | `mix_a_b_c_d` | Mixbefehl, Mengen in ml für 4 Pumpen |
| ESP → App | `mix_ok` | Cocktail fertig |

**Wichtige Klassen:**
- `BleService` (Singleton, `lib/services/ble_service.dart`) — Verbindung, Scan, Senden, Empfangen, Test-Modus
- `BleBackendService` — empfängt Rundendaten und parst sie
- `BleMixerService` — sendet Cocktail-Bestellung

### 3.2 Spiellogik

- **Best-of-3-Modus:** Gewinner steht fest sobald ein Spieler 2 Runden gewinnt oder nach 3 Runden mehr Siege hat
- **Phasen** (`GamePhase` enum): `waitingRound → showingRound → gameOver → drinkSelecting → drinkSending → drinkReady`
- **State Management:** Nur Standard-`StatefulWidget`/`setState` (kein Provider, Riverpod, BLoC, …)

### 3.3 KI-Bildanalyse (Cocktail-Empfehlung)

Beim Spielende wird der Verlierer fotografiert (Selfie) und sein Foto durch **Google ML Kit** analysiert:

- **Face Detection** → Lächeln, Augenöffnung, Kopfneigung
- **Image Labeling** → Farben, Stimmungs-Tags

Anhand des `ImageProfile` werden vier Cocktails per heuristischem Scoring bewertet:

| Cocktail | Profil |
|---|---|
| **Long Island Iced Tea** | selbstbewusst, ernst, dunkel |
| **Old Fashioned** | sophisticated, ruhig, warm |
| **Mojito** | fröhlich, frisch, hell |
| **Zombie** | abenteuerlustig, exotisch, intensiv |

Das beste Match wird als Empfehlung gewählt und auf einen der vier physischen Drinks (Pumpen-Mengen) gemappt.

**Fallback:** Bei fehlgeschlagener Analyse oder ohne erkanntes Gesicht wird ein zufälliger Cocktail gewählt.

### 3.4 Drink-Mapping (Pumpen-Konfiguration)

| Getränk | Pumpe 0 | Pumpe 1 | Pumpe 2 | Pumpe 3 |
|---|---|---|---|---|
| Tropical Chaos | 30 ml | 20 ml | 10 ml | 40 ml |
| Sour Loser | 20 ml | 30 ml | 20 ml | 30 ml |
| Blue Regret | 10 ml | 40 ml | 30 ml | 20 ml |
| Bitter Defeat | 40 ml | 10 ml | 10 ml | 40 ml |

### 3.5 Design-System

Konsistentes Dark-Theme mit dunkelblauer Palette (`AppColors.background = #06121F`), Akzente in Hellblau/Grün und semantischen Farben (success, error, warning). Zentralisiert in `lib/core/theme/`.

---

## 4. Verwendete Pakete

| Paket | Version | Zweck |
|---|---|---|
| `flutter_blue_plus` | ^1.35.5 | BLE-Kommunikation mit ESP32 |
| `image_picker` | ^1.1.2 | Selfie-Aufnahme der Spieler |
| `camera` | ^0.11.0 | Kamera-Zugriff |
| `google_mlkit_face_detection` | ^0.13.0 | Gesichtserkennung & Klassifizierung |
| `google_mlkit_image_labeling` | ^0.14.0 | Bild-Labeling für Stimmungs-Tags |
| `cupertino_icons` | ^1.0.8 | iOS-Style Icons |
| `flutter_lints` | ^5.0.0 | Empfohlene Lint-Regeln |

---

## 5. Plattform-Konfiguration

### Android
- `android/app/src/main/AndroidManifest.xml` deklariert:
  - `CAMERA`-Berechtigung
  - `BLUETOOTH` & `BLUETOOTH_ADMIN` (≤ Android 11)
  - `BLUETOOTH_SCAN` (mit `neverForLocation`) & `BLUETOOTH_CONNECT` (Android 12+)
  - `bluetooth_le` als Pflicht-Feature

### iOS, macOS, Linux, Windows
Standard-Flutter-Templates vorhanden — Web/Desktop-Support strukturell gegeben, aber wahrscheinlich nicht der Haupt-Use-Case (BLE auf Desktop ist eingeschränkt).

---

## 6. Test- & Debug-Modus

Die App enthält einen eingebauten **Test-Modus** (Schaltfläche „Test Modus (ohne ESP32)" auf der Startseite):

- `BleService.enableTestMode()` simuliert eine BLE-Verbindung
- Gesendete Nachrichten landen im `sentMessages`-Stream statt im Funk
- Ein **Debug-Panel** (`BleDebugPanel`) im Spielbildschirm erlaubt das manuelle Injizieren von ESP-Nachrichten (Runden- und Mix-Bestätigungen)
- Live-Log zeigt blau (App → ESP) / grün (ESP → App)

Das ist ein **sehr gut umgesetztes Pattern** für Hardware-getriebene Apps.

---

## 7. Stärken

1. **Klare, lesbare Architektur** mit feature-basiertem Aufbau
2. **Vollständige Trennung** zwischen Hardware-Kommunikation und UI
3. **Hervorragender Test-Modus** für Entwicklung ohne ESP32
4. **Interface-Pattern** für Services ermöglicht einfaches Mocken/Austauschen
5. **Robuste BLE-Implementierung** mit Reconnect-Handling, Timeouts und Lifecycle-Management
6. **KI-Integration on-device** (Google ML Kit) — kein Server, keine Datenschutzprobleme
7. **Singleton-Pattern** für BLE-Service ist hier angemessen (genau ein Hardware-Endpoint)
8. **Gute Dokumentation** in `README.md` inklusive ESP32-Beispielcode

---

## 8. Verbesserungspotenzial / Beobachtungen

### 8.1 State Management
Die App nutzt ausschließlich `setState`. Bei wachsender Komplexität (mehr Screens, geteilter Zustand zwischen Tabs) wäre **Provider, Riverpod oder BLoC** empfehlenswert.

### 8.2 Casting auf `dynamic` in `GameScreen`
```dart
final selection = await (widget.drinkService as dynamic)
    .selectDrinkWithCocktail(...);
```
Hier wird `dynamic`-Casting verwendet, weil die Methode `selectDrinkWithCocktail` nicht im Interface `DrinkService` definiert ist (sie ist es laut aktueller Datei jedoch). **Dieses Cast kann entfernt werden** — das Interface enthält die Methode bereits.

### 8.3 Redundanter Code
- Im `RecipesPage` werden lokale Enums (`_RecipeFilter`, `_RecipeStatus`) und `_RecipeItem` definiert, die identisch zu denen in `lib/features/recipes/models/recipe_models.dart` sind. Die internen Enums werden nicht mehr verwendet → toter Code, sollte entfernt werden.

### 8.4 KI-Scoring etwas heuristisch
Die Punktevergabe pro Cocktail (`_scoreLongIsland` etc.) basiert auf festen Schwellwerten. Für eine Produktivversion könnte ein einfaches gewichtetes Modell oder Konfigurations-JSON sinnvoller sein.

### 8.5 `MockDrinkService` ist nicht mehr „mock"
Der Name suggeriert eine Mock-Implementierung, tatsächlich ist es aber die einzige Implementierung mit echter ML-Kit-Integration. **Umbenennung empfehlenswert** (z. B. `DefaultDrinkService` oder `MlKitDrinkService`).

### 8.6 Fehlerbehandlung bei BLE-Disconnect während Spiel
Wenn die BLE-Verbindung während eines Spiels abbricht, gibt es keinen User-feedback-Loop — `waitForMessage` würde nach 60 s timen, aber der UI-State bleibt im `waitingRound` hängen.

### 8.7 Testing
Es ist **keine Testabdeckung** sichtbar (`test/`-Ordner praktisch leer). Bei der klaren Service-Architektur wären Unit-Tests für `Gesture.versus`, `RoundResult`, `_score*`-Funktionen sehr leicht umsetzbar.

### 8.8 Hardcodierte Listen-Strings
Texte wie „Verbindung fehlgeschlagen", „Suche nach BLE-Geräten…" sind direkt im Code. Eine Internationalisierung (`flutter_localizations` + `arb`-Dateien) wäre für eine produktive App nützlich.

### 8.9 `recipes`-Feature unverbunden
Der Rezepte-Tab zeigt nur einen statischen Katalog (`recipe_catalog.dart`) mit Unsplash-Bildern. Es gibt **keine Verbindung zum Mixer** — dieses Feature ist offenbar UI-Demo / Preview-Status.

### 8.10 Build-Ordner im Repo
Im Workspace ist der `build/`-Ordner sichtbar (Android-Debug-Artefakte). Falls er versehentlich eingecheckt wurde, sollte `.gitignore` geprüft werden.

---

## 9. Reife & Status

| Bereich | Status |
|---|---|
| BLE-Kommunikation | **Produktiv** — robust, getestet, dokumentiert |
| Spiellogik | **Produktiv** — Best-of-3, Gestenerkennung remote |
| KI-Cocktail-Auswahl | **Funktional** — heuristisch, on-device, mit Fallback |
| Foto-Capture | **Produktiv** — Frontkamera, beide Spieler |
| Rezepte-Tab | **Demo / WIP** — nicht mit Hardware verbunden |
| Test-Modus | **Hervorragend umgesetzt** |
| Multi-Plattform | Android primär; iOS/Desktop strukturell, aber nicht ausgereift |
| Internationalisierung | Nicht vorhanden (Deutsch hardcoded) |
| Unit-Tests | Praktisch nicht vorhanden |

---

## 10. Empfehlungen (priorisiert)

1. **`dynamic`-Cast in `GameScreen._selectDrink` entfernen** — schnelle Verbesserung, mehr Type-Safety.
2. **Toten Code in `recipes_page.dart` aufräumen** (lokale Enums/Klasse).
3. **`MockDrinkService` umbenennen** zu etwas Beschreibenderem.
4. **Unit-Tests** für `Gesture`, `RoundResult` und ML-Scoring-Funktionen.
5. **BLE-Disconnect-Recovery** im `GameScreen` mit User-Feedback (Snackbar + Retry).
6. **State Management** (Riverpod/Provider) einführen, sobald weitere Features hinzukommen.
7. **Build-Artefakte** aus dem Repo entfernen, `.gitignore` prüfen.
8. **Internationalisierung** vorbereiten (auch wenn aktuell nur Deutsch).
9. **`recipes`-Feature** entweder fertigstellen (mit Mixer-Anbindung) oder vorerst entfernen.

---

## 11. Fazit

`Gehirnzellen Massaker` ist ein **gut strukturiertes, gut dokumentiertes Flutter-Projekt** mit einem klaren, gut umgesetzten Hardware-Integrations-Pattern. Die saubere Trennung zwischen BLE-Service und UI, das Interface-basierte Design und der eingebaute Test-Modus zeigen, dass der Autor IoT-typische Entwicklungsherausforderungen (Hardware nicht immer verfügbar, asynchrone Protokolle) **bewusst und durchdacht** gelöst hat.

Die App ist in ihrem **Kern-Spielablauf produktionsreif**. Die KI-Cocktail-Auswahl ist ein netter, kreativer Zusatz, der gut mit on-device-ML-Kit umgesetzt wurde. Hauptverbesserungspunkte liegen in **Code-Hygiene** (toter Code, dynamic-Casts), **Tests** und **Robustheit gegen BLE-Verbindungsabbrüche**.

Die Architektur ist solide genug, um die App problemlos zu erweitern — z. B. um mehr Cocktails, mehr Spielmodi, eine Web-Companion oder eine Cloud-Anbindung für globale Highscores.
