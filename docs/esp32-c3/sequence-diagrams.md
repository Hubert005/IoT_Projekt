# ESP32-C3 — Sequence Diagrams

Internal flows of the ESP32-C3 firmware. Wire-level handshakes that cross BLE or UART belong in [`../cross-dependencies/sequence-diagrams.md`](../cross-dependencies/sequence-diagrams.md); this page only shows what happens **inside** the ESP between two wire events.

All line references are to [`code/backend/code_esp32-c3/src/main.cpp`](../../code/backend/code_esp32-c3/src/main.cpp). For the corresponding state machine (Idle / Round / Mix), see [runtime.md](runtime.md).

## 1 — Boot & setup

```mermaid
sequenceDiagram
    autonumber
    participant Pwr as Power
    participant ESP as ESP loop
    Pwr->>ESP: reset / power-on
    Note over ESP: setup() — main.cpp:66-83
    ESP->>ESP: pinMode(B0..B9, INPUT_PULLUP)
    ESP->>ESP: Serial.begin(115200)
    ESP->>ESP: Serial1.setTimeout(20000)
    ESP->>ESP: Serial1.begin(9600, 8N1, RXD1=21, TXD1=20)
    Note over ESP: ready, loop() starts
```

Once `setup()` returns the firmware enters `loop()` and starts dispatching messages (next diagram). The BLE stack is **not** initialised here today — see [known-issues.md §1](known-issues.md#1-ble-stack-is-not-implemented).

## 2 — Main-loop dispatch

```mermaid
sequenceDiagram
    autonumber
    participant ESP as ESP loop
    Note over ESP: loop() — main.cpp:86-122
    ESP->>ESP: msg = listenBLE()
    Note over ESP: branch on msg
    alt msg == "start"
        Note over ESP: → §3 (round collection loop,<br/>until "stop"/timeout)
    else msg startsWith "mix_"
        Note over ESP: → §4 (mix relay)
    else other / empty
        Note over ESP: ignore, next loop iteration
    end
    ESP->>ESP: msg = ""
```

`listenBLE()` is the entry point for every game message. It currently has no body ([known-issues.md §1](known-issues.md#1-ble-stack-is-not-implemented)) so neither branch can fire on real hardware yet.

## 3 — Round collection & series loop

```mermaid
sequenceDiagram
    autonumber
    participant ESP as ESP loop
    participant P1 as Player 1 buttons<br/>B0=Rock, B1=Paper, B2=Scissors
    participant P2 as Player 2 buttons<br/>B3=Rock, B4=Paper, B5=Scissors
    Note over ESP: msg == "start" → sendBLE("start_ok")
    loop while playing (main.cpp:95-106)
        Note over ESP: listenBTNround(round) — main.cpp:127-187
        ESP->>P1: pressedStable(B0/B1/B2)?  → pl1
        ESP->>P2: pressedStable(B3) / raw B4,B5? → pl2
        ESP-->>ESP: sendBLE("runde_"+round+pl1+pl2)
        loop wait for ack (listenBLEBlocking 30s)
            alt "runde_ok"
                Note over ESP: round++, collect next round
            else "stop"
                Note over ESP: playing = false
            else "" (timeout/disconnect)
                Note over ESP: playing = false
            else other
                Note over ESP: ignore, keep waiting
            end
        end
    end
```

The series is open-ended: the **app** decides when best-of-three is over and sends `stop` (the ESP no longer counts to three itself). This is the **intended** behaviour; today it is blocked by three defects:

- `listenBLEBlocking(30000)` (line 100) is **undefined** — the firmware does not compile ([known-issues.md §6](known-issues.md)).
- `listenBTNround` has multiple bugs (B4/B5 read as `B3`, inverted loop and assignment guards, stale `lastBx`, raw reads on B4/B5) — [known-issues.md §2](known-issues.md#2-listenbtnroundint-i--multiple-defects-lines-127187).
- `listenBLE` / `sendBLE` are stubs ([known-issues.md §1](known-issues.md)).

Each round's return value is what the ESP sends to the app as `runde_<i>_<g1>_<g2>` — that wire frame is documented in [`../cross-dependencies/sequence-diagrams.md`](../cross-dependencies/sequence-diagrams.md) §2.

## 4 — Mix relay — ESP side

```mermaid
sequenceDiagram
    autonumber
    participant ESP as ESP loop
    participant S1 as Serial1<br/>(UART to Nano)
    Note over ESP: msg startsWith "mix_"<br/>(main.cpp:110-116)
    ESP->>S1: drain stale RX (while Serial1.available() read())
    ESP->>ESP: sendCMD(msg) — main.cpp:41-45
    ESP->>S1: Serial1.println(msg)  ("mix_a_b_c_d\n")
    Note over ESP: also Serial.println("ESP sent: " + msg)<br/>(USB debug echo)
    ESP->>S1: listenCMD() — main.cpp:49-51 (20s timeout)
    S1-->>ESP: "mix_ok\n" | "mix_err\n" | "" (timeout)
    alt == "mix_ok"
        Note over ESP: → sendBLE("mix_ok")<br/>(currently stubbed)
    else mix_err / timeout
        Note over ESP: dropped — not relayed to app<br/>(known-issues.md §3)
    end
```

`sendCMD` is opaque pass-through — the ESP never parses the body of `mix_*`. `listenCMD` now honours a 20 s timeout (`Serial1.setTimeout` in `setup()`), so a dead Nano no longer hangs the loop forever — but only an exact `"mix_ok"` is relayed to the app; a `mix_err` or a timeout is silently dropped ([known-issues.md §3](known-issues.md)). The Nano's side of the same exchange is in [`../arduino-nano/sequence-diagrams.md`](../arduino-nano/sequence-diagrams.md) §3.
