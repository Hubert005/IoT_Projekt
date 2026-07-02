# Arduino Nano — Sequence Diagrams

Internal flows of the Nano firmware. Wire-level handshakes that cross UART belong in [`../cross-dependencies/sequence-diagrams.md`](../cross-dependencies/sequence-diagrams.md); this page only shows what happens **inside** the Nano between two UART events.

All line references are to [`code/backend/code_arduino-nano/src/main.cpp`](../../code/backend/code_arduino-nano/src/main.cpp).

## 1 — Boot & setup

```mermaid
sequenceDiagram
    autonumber
    participant Pwr as Power
    participant Nano as Nano loop
    participant USB as USB Serial
    Pwr->>Nano: reset / power-on
    Note over Nano: setup() — main.cpp:26-36
    Nano->>Nano: pinMode(BUZZER, M0..M3) = OUTPUT
    Nano->>Nano: Serial.begin(115200)
    Nano->>Nano: espSerial.begin(9600)
    Nano->>USB: "Serial Started"
    Note over Nano: ready, loop() starts
```

Once `setup()` returns the Nano enters `loop()` and polls `espSerial` (§2).

## 2 — Idle poll loop

```mermaid
sequenceDiagram
    autonumber
    participant Nano as Nano loop
    participant RX as espSerial RX buffer
    participant USB as USB Serial
    Note over Nano: loop() top — main.cpp:38-47
    loop every iteration
        Nano->>RX: espSerial.available()?
        alt frame ready
            RX-->>Nano: readStringUntil('\n')
            Nano->>Nano: msg.trim()
            Nano->>USB: "Nano got: " + msg
            Note over Nano: branch on prefix → §3 if "mix_"
        else nothing pending
            Note over Nano: skip, next iteration
        end
    end
```

Anything that does not start with `mix_` is silently dropped after the USB echo.

## 3 — Mix command — happy path

```mermaid
sequenceDiagram
    autonumber
    participant Nano as Nano loop
    participant FET as FETs M0..M3<br/>(GPIO 2..5)
    participant Buzz as Buzzer<br/>(GPIO 10)
    participant ESP as espSerial TX
    Note over Nano: msg startsWith "mix_"<br/>(main.cpp:50)
    Nano->>Nano: msg.remove(0, 4)
    loop i = 0..3 (split on "_", last field = remainder)
        Nano->>Nano: durations[i] = field.toInt()
    end
    loop i = 0..3 (pump sequentially)
        Nano->>FET: digitalWrite(M0+i, HIGH)
        Note over Nano,FET: delay(durations[i]) — BLOCKING
        Nano->>FET: digitalWrite(M0+i, LOW)
    end
    Nano->>ESP: espSerial.println("mix_ok")
    Nano->>Buzz: HIGH 250ms → LOW 50ms → HIGH 250ms → LOW
    Note over Nano: msg = "", back to idle (§2)
```

Note that **`mix_ok` is emitted *before* the buzzer sequence** (line 73 vs 76–82). The app's `BleMixerService.orderDrink` resolves while the buzzer is still beeping — the user sees "Drink ready" ~550 ms before the audible confirmation ends.

Total wall-clock time the Nano is unavailable for a typical recipe `mix_30_20_10_40`: ~100 ms pumping + ~550 ms buzzer ≈ 650 ms (see [`../cross-dependencies/protocol.md`](../cross-dependencies/protocol.md) for the full latency budget). The pumps run **blocking** via `delay()` ([known-issues.md §5](known-issues.md#5-pumps-run-blocking-in-sequence)).

## 4 — Mix command — parse failure

```mermaid
sequenceDiagram
    autonumber
    participant Nano as Nano loop
    participant ESP as espSerial TX
    participant USB as USB Serial
    Note over Nano: msg startsWith "mix_"<br/>but a "_" separator is missing before field 4
    Nano->>Nano: msg.remove(0, 4)
    loop i = 0..3
        Nano->>Nano: indexOf('_')
        alt found, or i == 3 (remainder)
            Note over Nano: parse next field
        else underscoreIndex == -1 and i < 3
            Nano->>ESP: espSerial.println("mix_err")
            Nano->>USB: "Invalid message format"
            Note over Nano: return — no pumping, no mix_ok
        end
    end
```

The Nano now sends a `mix_err` NAK on parse failure (line 57) — previously it stayed silent (resolved [known-issues.md §4](known-issues.md)). The ESP reads this NAK but does **not** yet relay it to the app; combined with the ESP's 20 s `listenCMD` timeout, a malformed frame no longer hangs the firmware, but the app still relies on its own BLE timeout to notice. See [`../esp32-c3/known-issues.md` §3](../esp32-c3/known-issues.md).
