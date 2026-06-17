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
    Note over ESP: setup() — main.cpp:66-81
    ESP->>ESP: pinMode(B0..B9, INPUT_PULLUP)
    ESP->>ESP: Serial.begin(115200)
    ESP->>ESP: Serial1.begin(9600, 8N1, RXD1=21, TXD1=20)
    Note over ESP: ready, loop() starts
```

Once `setup()` returns the firmware enters `loop()` and starts dispatching messages (next diagram). The BLE stack is **not** initialised here today — see [known-issues.md §1](known-issues.md#1-ble-stack-is-not-implemented).

## 2 — Main-loop dispatch

```mermaid
sequenceDiagram
    autonumber
    participant ESP as ESP loop
    Note over ESP: loop() — main.cpp:84-109
    ESP->>ESP: msg = listenBLE()
    Note over ESP: branch on msg
    alt msg == "start"
        Note over ESP: → §3 (round collection,<br/>3 iterations)
    else msg startsWith "mix_"
        Note over ESP: → §4 (mix relay)
    else other / empty
        Note over ESP: ignore, next loop iteration
    end
    ESP->>ESP: msg = ""
```

`listenBLE()` is the entry point for every game message. It currently has no body ([known-issues.md §1](known-issues.md#1-ble-stack-is-not-implemented)) so neither branch can fire on real hardware yet. The actual handshakes (`start_ok`, `runde_x_y_z`, `mix_ok`) leave the ESP through `sendBLE()`, which is also stubbed.

## 3 — Round collection — `listenBTNround(i)`

```mermaid
sequenceDiagram
    autonumber
    participant ESP as ESP loop
    participant P1 as Player 1 buttons<br/>B0=Rock, B1=Paper, B2=Scissors
    participant P2 as Player 2 buttons<br/>B3=Rock, B4=Paper, B5=Scissors
    Note over ESP: listenBTNround(i) — main.cpp:114-174
    ESP->>P1: digitalRead snapshot (b0..b2)
    ESP->>P2: digitalRead snapshot (b3..b5)
    loop until pl1 != "" && pl2 != ""
        ESP->>P1: pressedStable(B0/B1/B2)?
        Note over ESP: on rising edge → pl1 = "_0"/"_1"/"_2"
        ESP->>P2: pressedStable(B3) / !digitalRead(B4,B5)?
        Note over ESP: on rising edge → pl2 = "_0"/"_1"/"_2"
        ESP->>ESP: update lastBx
    end
    Note over ESP: return "runde_" + i + pl1 + pl2
```

This is the **intended** behaviour. Today the function has multiple bugs that prevent it from completing — see [known-issues.md §2](known-issues.md#2-listenbtnroundint-i--multiple-defects-lines-114174):

- B4 and B5 are read with `digitalRead(B3)` (typos).
- The outer loop guard is inverted (`while(pl1 != "" && pl2 != "")` instead of `while(pl1 == "" || pl2 == "")`).
- The inner assignment guards are also inverted.
- `lastBx` is updated from the entry-time snapshot, not the loop-time read.
- B4 / B5 use raw `!digitalRead()` instead of `pressedStable()`.

`listenBTNround` is called three times per series (see §2). Each call's return value is what the ESP then sends to the app as `runde_<i>_<g1>_<g2>` — that wire frame is documented in [`../cross-dependencies/sequence-diagrams.md`](../cross-dependencies/sequence-diagrams.md) §2.

## 4 — Mix relay — ESP side

```mermaid
sequenceDiagram
    autonumber
    participant ESP as ESP loop
    participant S1 as Serial1<br/>(UART to Nano)
    Note over ESP: msg startsWith "mix_"<br/>(main.cpp:98-103)
    ESP->>ESP: sendCMD(msg) — main.cpp:41-45
    ESP->>S1: Serial1.println(msg)  ("mix_a_b_c_d\n")
    Note over ESP: also Serial.println("ESP sent: " + msg)<br/>(USB debug echo)
    ESP->>S1: listenCMD() — main.cpp:49-51
    S1-->>ESP: "mix_ok\n" (blocking)
    Note over ESP: → sendBLE("mix_ok")<br/>(currently stubbed)
```

`sendCMD` is opaque pass-through — the ESP never parses the body of `mix_*`. `listenCMD` has **no timeout** ([known-issues.md §3](known-issues.md#3-listencmd-blocks-forever-lines-4951)); if the Nano never answers, this branch hangs the loop. The Nano's side of the same exchange is in [`../arduino-nano/sequence-diagrams.md`](../arduino-nano/sequence-diagrams.md) §3.
