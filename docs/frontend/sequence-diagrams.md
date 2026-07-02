# Frontend — Sequence Diagrams

Internal flows of the Flutter app. Wire-level handshakes (BLE frames against the ESP32) belong in [`../cross-dependencies/sequence-diagrams.md`](../cross-dependencies/sequence-diagrams.md); this page only shows what happens **inside** the app, including recipe generation and the ML pipeline.

All paths are relative to [`code/frontend/lib/`](../../code/frontend/lib/). For the `GamePhase` state machine that complements §6–§9 see [features.md](features.md).

## 1 — App startup + model wiring

```mermaid
sequenceDiagram
    autonumber
    participant FW as Flutter framework
    participant Main as main()
    participant Gemma as GemmaRecipeGeneratorService
    participant Store as RecipeStore.instance
    participant Home as HomePage
    FW->>Main: main() — main.dart
    Main->>Gemma: new (assetPath: assets/models/gemma.task)
    Main->>Store: useGenerator(gemma, modelStatus: gemma.status)
    Main->>Store: await load()  (setup + pool from shared_preferences)
    Main->>FW: runApp(MyApp)
    FW->>Home: MaterialApp.home = HomePage
    Home->>Home: initState() → subscribe connectionStream
```

Only `main.dart` wires the on-device model; tests and test mode keep the mock generator and never trigger a model load. `RecipeStore.load()` restores the persisted pump setup and cocktail pool before the first frame.

## 2 — BLE scan & connect

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant Home as HomePage / _BleScanSheet
    participant Ble as BleService.instance
    participant FBP as flutter_blue_plus
    U->>Home: tap status row
    Home->>Ble: startScan()
    Ble->>FBP: FlutterBluePlus.startScan(timeout: 10s)
    FBP-->>Home: scanResults stream
    U->>Home: pick a device
    Home->>Ble: connect(device)
    Ble->>FBP: device.connect(License.nonprofit) + discoverServices()
    FBP-->>Ble: NUS service + TX/RX chars
    Ble->>FBP: rxChar.setNotifyValue(true)
    Ble->>Ble: listen device.connectionState (drops flip connectionStream)
    Ble-->>Home: connectionStream emits true
```

Errors during `connect` bubble to a `SnackBar`. If already connected, `connect` first awaits `disconnect()`.

## 3 — Test mode

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant Home as HomePage
    participant Ble as BleService.instance
    U->>Home: tap "Test Modus (ohne ESP32)"
    Home->>Ble: enableTestMode()
    Ble->>Ble: _testMode = true, _connected = true
    Ble-->>Home: connectionStream emits true
    Note over Home: `send()` → sentMessages,<br/>`inject()` → backlog + messageStream
```

## 4 — Recipe generation (What's in the box)

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant RP as RecipesPage
    participant Store as RecipeStore
    participant Gen as RecipeGeneratorService<br/>(Gemma → mock fallback)
    U->>RP: "What's in the box" → enter 4 drinks
    RP->>Store: updateSetupAndRegenerate(PumpSetup)
    alt setup unchanged & pool exists
        Store->>Store: persist, notify (no regen)
    else changed / no pool
        Store->>Store: _generating = true, notify
        Store->>Gen: generate(setup)
        Gen-->>Store: List<GeneratedCocktail>
        Store->>Store: persist pool, _generating = false, notify
    end
    Store-->>RP: AnimatedBuilder rebuilds (tiles / spinner / empty)
```

`GemmaRecipeGeneratorService` lazily loads the on-device model and, on any failure (or <3 usable cocktails), falls back to `MockRecipeGeneratorService`. Model download/load progress is surfaced via `GemmaModelStatus` while `_GeneratingView` is shown. Incomplete setups clear the pool.

## 5 — Photo capture

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant PC as PhotoCapturePage
    participant IP as ImagePicker
    participant Game as GameScreen
    U->>PC: tap Player 1 / Player 2 card
    PC->>IP: pickImage(camera, front, quality 85)
    IP-->>PC: _p1Path / _p2Path
    U->>PC: "START GAME" (enabled when both set)
    Note over PC: build BleBackendService(),<br/>BleMixerService(), MockDrinkService()
    PC->>Game: Navigator.pushReplacement(GameScreen(...))
```

## 6 — Game init (with abort guards)

```mermaid
sequenceDiagram
    autonumber
    participant Game as GameScreen
    participant Ble as BleService.instance
    Note over Game: initState()
    alt not connected
        Game->>Game: _abort("Kein Gerät verbunden…") → pop to home
    else connected
        Game->>Ble: subscribe connectionStream (drop mid-game → _abort)
        Game->>Ble: send("start")
        Game->>Ble: waitForMessage("start_ok")
        alt ok
            Game->>Game: _playRound() (§7)
        else timeout / error
            Game->>Game: _abort("Keine Antwort vom ESP32…")
        end
    end
```

## 7 — Play one round (with draws)

```mermaid
sequenceDiagram
    autonumber
    participant Game as GameScreen
    participant BBS as BleBackendService
    participant Ble as BleService.instance
    Note over Game: _phase = waitingRound
    Game->>BBS: getRoundResult(_currentRound)
    BBS->>Ble: waitForMessage("runde_")
    Ble-->>BBS: "runde_x_y_z"
    BBS->>BBS: parse → p1, p2
    BBS->>Ble: send("runde_ok")  (never sends "stop" — X-1)
    BBS-->>Game: RoundResult
    alt winner == null (draw)
        Note over Game: SnackBar, hold 2s, repeat round<br/>(no append, no round++)
    else decided
        Note over Game: append to _rounds, showingRound, hold 2s
        alt _seriesWinner != null
            Note over Game: gameOver, hold 1.5s → _selectDrink() (§8)
        else
            Note over Game: _currentRound++, recurse (§7)
        end
    end
```

Any BLE failure inside `getRoundResult` triggers `_abort`. `_seriesWinner` is best-of-three (first to 2, or majority after 3). Wire `parts[1]` is ignored.

## 8 — Select drink (pool + ML pipeline)

```mermaid
sequenceDiagram
    autonumber
    participant Game as GameScreen
    participant MDS as MockDrinkService
    participant Store as RecipeStore
    participant GMK as GoogleMLKitCocktailService
    participant IAS as ImageAnalyzerService
    Note over Game: _phase = drinkSelecting
    Game->>MDS: selectDrinkWithCocktail(loser, loserImagePath)
    MDS->>Store: pool
    alt pool non-empty (primary)
        MDS->>GMK: selectCocktail(loserImagePath, candidates: pool→CocktailData)
        GMK->>IAS: initialize() + analyzeImage()
        IAS-->>GMK: ImageProfile
        GMK->>GMK: _moodWeights → _scoreByTags → arg-max
        GMK-->>MDS: CocktailData (matched)
        MDS->>MDS: chosen GeneratedCocktail.toDrink() (pumpAmounts as-is)
    else pool empty (fallback)
        MDS->>GMK: selectCocktail(candidates: CocktailCatalog.cocktails)
        GMK-->>MDS: CocktailData
        MDS->>MDS: _mapCocktailToDrink(cocktail)  (ids match catalog)
    end
    MDS-->>Game: DrinkSelectionResult { cocktail, drink }
    Note over Game: _phase = drinkSending → §9
```

No-face or errors inside `GoogleMLKitCocktailService` degrade to a random candidate. A single-candidate pool is returned without analysis.

## 9 — Order drink (BLE mix)

```mermaid
sequenceDiagram
    autonumber
    participant Game as GameScreen
    participant BMS as BleMixerService
    participant Ble as BleService.instance
    Note over Game: _phase = drinkSending
    Game->>BMS: orderDrink(drink)
    BMS->>Ble: send("mix_${p0}_${p1}_${p2}_${p3}")
    BMS->>Ble: waitForMessage("mix_ok")
    alt mix_ok
        Ble-->>BMS: "mix_ok"
        BMS-->>Game: resolved → _phase = drinkReady
    else timeout / disconnect
        Note over Game: _abort("Keine Antwort vom ESP32…")
    end
```

The full wire-level chain that follows `send("mix_…")` (BLE → ESP → UART → Nano → pumps → buzzer → ack chain) is in [`../cross-dependencies/sequence-diagrams.md`](../cross-dependencies/sequence-diagrams.md) §3. The home-screen MIX RANDOM DRINK button runs §9 directly against a random pool cocktail (using `MockMixerService` in test mode).
