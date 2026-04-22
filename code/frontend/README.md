# Gehirnzellen Massaker – Flutter App

Rock-Paper-Scissors Trinkspiel mit BLE-Kommunikation zum ESP32 Mixer.

---

## Projektstruktur

```
lib/
├── features/
│   ├── home/          → Startseite, BLE-Verbindung
│   ├── game/          → Spielablauf, Rundenlogik
│   └── recipes/       → Rezeptkatalog
├── models/            → Gesture, RoundResult, Drink
└── services/
    ├── ble_service.dart         → BLE Singleton (Verbindung, Senden, Empfangen)
    ├── ble_backend_service.dart → Empfängt Rundendaten vom ESP32
    ├── ble_mixer_service.dart   → Sendet Mixbefehl an ESP32
    ├── backend_service.dart     → Interface + Mock
    ├── drink_service.dart       → Interface + Mock
    └── mixer_service.dart       → Interface + Mock
```

---

## BLE Kommunikation

Die App kommuniziert über den **Nordic UART Service (NUS)** mit dem ESP32.

### UUIDs

| | UUID |
|---|---|
| Service | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` |
| RX (App → ESP32) | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` |
| TX (ESP32 → App) | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` |

### Protokoll

```
1. Spielstart
   App  →  "start"
   ESP  →  "start_ok"

2. Pro Runde (3 Runden)
   ESP  →  "runde_x_y_z"
   App  →  "runde_ok"

   x = Rundennummer (1, 2, 3)
   y = Geste Spieler 1 (0=Stein, 1=Papier, 2=Schere)
   z = Geste Spieler 2 (0=Stein, 1=Papier, 2=Schere)

   Beispiel: "runde_1_0_2" → Runde 1, Spieler1 Stein, Spieler2 Schere

3. Mixbefehl
   App  →  "mix_a_b_c_d"
   ESP  →  "mix_ok"

   a, b, c, d = Menge in ml pro Pumpe (Pumpe 0–3)
   Beispiel: "mix_30_20_10_40"
```

---

## ESP32 Firmware

Der ESP32 muss den Nordic UART Service implementieren. Basis-Firmware mit Arduino:

```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define NUS_SERVICE "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define NUS_RX      "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define NUS_TX      "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

BLECharacteristic* pTx;

void bleNotify(String msg) {
  pTx->setValue(msg.c_str());
  pTx->notify();
}

class RxCallback : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) {
    String msg = String(c->getValue().c_str());
    msg.trim();

    if (msg == "start") {
      // Spiel starten, Sensoren initialisieren
      bleNotify("start_ok");

    } else if (msg == "runde_ok") {
      // Nächste Runde: Gesten erkennen, dann senden:
      // bleNotify("runde_2_1_0");

    } else if (msg.startsWith("mix_")) {
      // Format: mix_a_b_c_d
      // Pumpen ansteuern, danach:
      bleNotify("mix_ok");
    }
  }
};

void setup() {
  BLEDevice::init("ESP32-Mixer");
  BLEServer* srv = BLEDevice::createServer();
  BLEService* svc = srv->createService(NUS_SERVICE);

  pTx = svc->createCharacteristic(NUS_TX, BLECharacteristic::PROPERTY_NOTIFY);
  pTx->addDescriptor(new BLE2902());

  BLECharacteristic* pRx = svc->createCharacteristic(
    NUS_RX,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  pRx->setCallbacks(new RxCallback());

  svc->start();
  BLEDevice::getAdvertising()->addServiceUUID(NUS_SERVICE);
  BLEDevice::startAdvertising();
}

void loop() {
  // Gestenerkennungs-Logik hier
}
```

### Mixbefehl parsen (ESP32)

```cpp
// msg = "mix_30_20_10_40"
void handleMix(String msg) {
  int parts[4];
  int idx = 0;
  String remaining = msg.substring(4); // nach "mix_"

  while (idx < 4) {
    int sep = remaining.indexOf('_');
    if (sep == -1) {
      parts[idx++] = remaining.toInt();
      break;
    }
    parts[idx++] = remaining.substring(0, sep).toInt();
    remaining = remaining.substring(sep + 1);
  }

  // parts[0] = Pumpe 0 (ml)
  // parts[1] = Pumpe 1 (ml)
  // parts[2] = Pumpe 2 (ml)
  // parts[3] = Pumpe 3 (ml)
}
```

---

## App starten

### Voraussetzungen

```bash
flutter pub get
flutter run
```

### Mit echtem ESP32

1. ESP32 mit NUS-Firmware flashen
2. App starten
3. **BLE STATUS** auf der Startseite antippen
4. ESP32 in der Liste auswählen → verbinden
5. Spiel starten

### Ohne ESP32 (Test Modus)

1. App starten
2. **"Test Modus (ohne ESP32)"** auf der Startseite drücken
3. Spiel starten
4. **🐛-Button** im GameScreen drückt → Nachrichten manuell senden
5. Der Log zeigt was die App sendet (blau) und was simuliert wird (grün)

---

## Pumpen-Mapping

Die Getränke sind in `lib/services/drink_service.dart` definiert.  
`pumpAmounts: [Pumpe0, Pumpe1, Pumpe2, Pumpe3]` in ml.

| Getränk | Pumpe 0 | Pumpe 1 | Pumpe 2 | Pumpe 3 |
|---|---|---|---|---|
| Tropical Chaos | 30 ml | 20 ml | 10 ml | 40 ml |
| Sour Loser | 20 ml | 30 ml | 20 ml | 30 ml |
| Blue Regret | 10 ml | 40 ml | 30 ml | 20 ml |
| Bitter Defeat | 40 ml | 10 ml | 10 ml | 40 ml |

Die Werte können dort direkt angepasst werden sobald die Pumpen kalibriert sind.
