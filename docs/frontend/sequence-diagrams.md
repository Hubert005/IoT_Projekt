# Frontend — Sequence Diagrams

Internal flows of the Flutter app. Wire-level handshakes (BLE frames against the ESP32) belong in [`../cross-dependencies/sequence-diagrams.md`](../cross-dependencies/sequence-diagrams.md); this page only shows what happens **inside** the app, including the ML pipeline.

All paths are relative to [`code/frontend/lib/`](../../code/frontend/lib/). For the `GamePhase` state machine that complements §5–§8 see [features.md](features.md).

## 1 — App startup

```mermaid
sequenceDiagram
    autonumber
    participant FW as Flutter framework
    participant App as MyApp
    participant Home as HomePage
    FW->>App: main() — main.dart:5<br/>runApp(MyApp())
    App->>Home: MaterialApp.home = HomePage()
    Home->>Home: initState()<br/>subscribe BleService.connectionStream
    Note over Home: visible: header, status row,<br/>nav, test-mode button
```

The connection-stream subscription drives the BLE status badge throughout the session. `dispose()` cancels it.

## 2 — BLE scan & connect

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant Home as HomePage
    participant Ble as BleService.instance
    participant FBP as flutter_blue_plus
    U->>Home: tap status row
    Home->>Home: open _BleScanSheet
    Home->>Ble: startScan()
    Ble->>FBP: FlutterBluePlus.startScan(timeout: 10s)
    FBP-->>Home: scanResults stream (live list)
    U->>Home: pick a device
    Home->>Ble: connect(device)
    Ble->>FBP: device.connect() + discoverServices()
    FBP-->>Ble: NUS service + TX/RX chars
    Ble->>FBP: rxChar.setNotifyValue(true)
    Ble-->>Home: connectionStream emits true
```

Errors during `connect` bubble to a `SnackBar`. If `_connected` is already true, `connect` first awaits `disconnect()` to release the prior link.

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
    Note over Home: same UI as real connection;<br/>`send()` re-routes to sentMessages,<br/>`inject()` simulates inbound
```

From now on the debug panel inside the game (§6/§8 plumbing) plays the role of the ESP — see [features.md](features.md) "End-to-end test-mode walkthrough".

## 4 — Photo capture

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant PC as PhotoCapturePage
    participant IP as ImagePicker
    participant Game as GameScreen
    U->>PC: arrive from "START GAME"
    U->>PC: tap Player 1 card
    PC->>IP: pickImage(camera, front, quality 85)
    IP-->>PC: _p1Path
    U->>PC: tap Player 2 card
    PC->>IP: pickImage(camera, front, quality 85)
    IP-->>PC: _p2Path
    U->>PC: tap "START GAME" (enabled)
    Note over PC: build BleBackendService(),<br/>BleMixerService(),<br/>MockDrinkService()
    PC->>Game: Navigator.pushReplacement(GameScreen(...))
```

`MockDrinkService` is the production ML-backed implementation despite the name — see [known-issues.md F-2](known-issues.md#f-2-mockdrinkservice-is-misnamed).

## 5 — Game init

```mermaid
sequenceDiagram
    autonumber
    participant Game as GameScreen
    participant Ble as BleService.instance
    Note over Game: initState() → _init()
    alt BleService.isConnected
        Game->>Ble: send("start")
        Game->>Ble: waitForMessage("start_ok", 60s)
        Ble-->>Game: "start_ok"
    end
    Note over Game: → _playRound() (§6)
```

If the BLE link is not connected (no real device and test mode disabled), `_init` skips both the `send` and the `waitForMessage` and goes straight to `_playRound` — but the round itself will then block at the BLE wait in §6 with no way forward.

## 6 — Play one round

```mermaid
sequenceDiagram
    autonumber
    participant Game as GameScreen
    participant BBS as BleBackendService
    participant Ble as BleService.instance
    Note over Game: _phase = waitingRound
    Game->>BBS: getRoundResult(_currentRound)
    BBS->>Ble: waitForMessage("runde_", 60s)
    Ble-->>BBS: "runde_x_y_z"
    BBS->>BBS: parse → p1, p2 gestures
    BBS->>Ble: send("runde_ok")
    BBS-->>Game: RoundResult(round, p1, p2, winner)
    Note over Game: append to _rounds,<br/>_phase = showingRound, hold 2s
    alt _seriesWinner != null
        Note over Game: _phase = gameOver, hold 1.5s<br/>→ _selectDrink() (§7)
    else
        Note over Game: _currentRound++,<br/>recurse into _playRound() (§6)
    end
```

`_seriesWinner` is best-of-three: first player to 2 wins, or the majority after 3 rounds. Draws inside the series do not short-circuit. Round count from the wire (`parts[1]`) is ignored — the app tracks it itself.

## 7 — Select drink (ML pipeline)

```mermaid
sequenceDiagram
    autonumber
    participant Game as GameScreen
    participant MDS as MockDrinkService
    participant GMK as GoogleMLKitCocktailService
    participant IAS as ImageAnalyzerService
    Note over Game: _phase = drinkSelecting
    Game->>MDS: selectDrinkWithCocktail(loser, loserImagePath)
    MDS->>GMK: selectCocktail(loserImagePath)
    GMK->>IAS: initialize() (idempotent)
    GMK->>IAS: analyzeImage(loserImagePath)
    IAS-->>GMK: ImageProfile { face?, smile, eyes, head Y/Z, top-10 labels }
    alt !faceDetected
        Note over GMK: fallback → CocktailCatalog.getRandom()
    else
        GMK->>GMK: _scoreLongIsland / OldFashioned / Mojito / Zombie
        GMK->>GMK: arg-max → cocktail id
        GMK->>GMK: CocktailCatalog.getById(id)
    end
    GMK-->>MDS: CocktailData
    MDS->>MDS: _mapCocktailToDrink(cocktail)
    Note over MDS: ⚠ switch ids don't match catalog ids<br/>→ always _drinks[0] (Tropical Chaos)<br/>see known-issues.md F-1
    MDS-->>Game: DrinkSelectionResult { cocktail, drink }
    Note over Game: _phase = drinkSending → §8
```

The default-branch bug in `_mapCocktailToDrink` ([known-issues.md F-1](known-issues.md#f-1-cocktail-id--drink-id-drift-makes-ml-pipeline-ineffective)) is the highest-priority correctness issue in the frontend — until it is fixed, the four `_score*` heuristics influence only the *displayed* cocktail name and description, not the pump amounts.

## 8 — Order drink (BLE mix)

```mermaid
sequenceDiagram
    autonumber
    participant Game as GameScreen
    participant BMS as BleMixerService
    participant Ble as BleService.instance
    Note over Game: _phase = drinkSending
    Game->>BMS: orderDrink(drink)
    BMS->>Ble: send("mix_${p[0]}_${p[1]}_${p[2]}_${p[3]}")
    BMS->>Ble: waitForMessage("mix_ok", 60s)
    Ble-->>BMS: "mix_ok"
    BMS-->>Game: resolved
    Note over Game: _phase = drinkReady<br/>(CocktailRecommendation + back-to-start)
```

The full wire-level chain that follows the `send("mix_…")` call (BLE → ESP → UART → Nano → pumps → buzzer → ack chain) is documented in [`../cross-dependencies/sequence-diagrams.md`](../cross-dependencies/sequence-diagrams.md) §3.
