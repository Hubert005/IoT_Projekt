#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// =====================================================================
//  Pin-Mapping
// =====================================================================
#define B0 4
#define B1 3
#define B2 2
#define B3 1
#define B4 0
#define B5 10
#define B6 9
#define B7 8
#define B8 7
#define B9 6

#define RXD1 21
#define TXD1 20

bool lastB0 = HIGH;
bool lastB1 = HIGH;
bool lastB2 = HIGH;
bool lastB3 = HIGH;
bool lastB4 = HIGH;
bool lastB5 = HIGH;
bool lastB6 = HIGH;
bool lastB7 = HIGH;
bool lastB8 = HIGH;
bool lastB9 = HIGH;

// =====================================================================
//  BLE-Konfiguration (Nordic-UART-Profil; matched die Flutter-App
//  in lib/services/ble_connection.dart)
// =====================================================================
static const char* BLE_DEVICE_NAME = "DrDrDrSams";
static const char* BLE_SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
static const char* BLE_CHAR_RX_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // App -> ESP (Write)
static const char* BLE_CHAR_TX_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // ESP -> App (Notify)

BLEServer*         bleServer    = nullptr;
BLECharacteristic* bleTxChar    = nullptr;
BLECharacteristic* bleRxChar    = nullptr;
volatile bool      bleConnected = false;

// Eingangs-Buffer & Queue der bereits empfangenen, '\n'-terminierten Zeilen.
String              bleRxBuffer;
static const size_t BLE_QUEUE_SIZE = 8;
String              bleRxQueue[BLE_QUEUE_SIZE];
volatile size_t     bleRxHead = 0; // naechste zu lesende Position
volatile size_t     bleRxTail = 0; // naechste zu schreibende Position

// =====================================================================
//  Forward Declarations
// =====================================================================
String listenBTNround(int i);

// =====================================================================
//  Helpers
// =====================================================================

/// @brief Debouncing for Button presses
/// @param pin Button Pin
/// @return Bool
bool pressedStable(int pin) {
  if (digitalRead(pin) == LOW) {
    delay(10);
    return digitalRead(pin) == LOW;
  }
  return false;
}

/// @brief send String to Arduino NANO
/// @param cmd String to
void sendCMD(String cmd) {
  Serial.print("ESP sent: ");
  Serial.println(cmd);
  Serial1.println(cmd);
}

/// @brief Listen to Arduino NANO (blockt bis Zeilenende oder Timeout)
/// @return String recieved
String listenCMD() {
  String s = Serial1.readStringUntil('\n');
  s.trim();
  return s;
}

// ---------------------------------------------------------------------
//  BLE Queue
// ---------------------------------------------------------------------
static void bleEnqueue(const String& line) {
  size_t next = (bleRxTail + 1) % BLE_QUEUE_SIZE;
  if (next == bleRxHead) {
    // Queue voll -> aeltesten Eintrag verwerfen
    bleRxHead = (bleRxHead + 1) % BLE_QUEUE_SIZE;
  }
  bleRxQueue[bleRxTail] = line;
  bleRxTail = next;
}

static bool bleDequeue(String& out) {
  if (bleRxHead == bleRxTail) return false;
  out = bleRxQueue[bleRxHead];
  bleRxQueue[bleRxHead] = "";
  bleRxHead = (bleRxHead + 1) % BLE_QUEUE_SIZE;
  return true;
}

// ---------------------------------------------------------------------
//  BLE Callbacks
// ---------------------------------------------------------------------
class BleServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* /*s*/) override {
    bleConnected = true;
    Serial.println("BLE: Client verbunden");
  }
  void onDisconnect(BLEServer* /*s*/) override {
    bleConnected = false;
    Serial.println("BLE: Client getrennt - werbe wieder");
    // Empfangs-Queue / Buffer leeren, damit eine neue Session sauber startet
    bleRxBuffer = "";
    bleRxHead = 0;
    bleRxTail = 0;
    delay(100);
    BLEDevice::startAdvertising();
  }
};

class BleRxCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    std::string raw = c->getValue();
    if (raw.empty()) return;
    bleRxBuffer += String(raw.c_str());

    int nl;
    while ((nl = bleRxBuffer.indexOf('\n')) >= 0) {
      String line = bleRxBuffer.substring(0, nl);
      bleRxBuffer.remove(0, nl + 1);
      line.trim();
      if (line.length() > 0) {
        Serial.print("BLE RX: ");
        Serial.println(line);
        bleEnqueue(line);
      }
    }
  }
};

/// @brief Setup BLE-Server (NUS-Profil) - aus setup() einmal aufgerufen.
void initBLE() {
  BLEDevice::init(BLE_DEVICE_NAME);
  BLEDevice::setMTU(185);

  bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new BleServerCallbacks());

  BLEService* svc = bleServer->createService(BLE_SERVICE_UUID);

  bleTxChar = svc->createCharacteristic(
      BLE_CHAR_TX_UUID,
      BLECharacteristic::PROPERTY_NOTIFY);
  bleTxChar->addDescriptor(new BLE2902());

  bleRxChar = svc->createCharacteristic(
      BLE_CHAR_RX_UUID,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  bleRxChar->setCallbacks(new BleRxCallbacks());

  svc->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(BLE_SERVICE_UUID);
  adv->setScanResponse(true);
  adv->setMinPreferred(0x06);
  adv->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.print("BLE bereit als '");
  Serial.print(BLE_DEVICE_NAME);
  Serial.println("'");
}

/// @brief Send String to APP via Bluetooth
/// @param cmd String to send
void sendBLE(String cmd) {
  Serial.print("BLE TX: ");
  Serial.println(cmd);

  if (!bleConnected || bleTxChar == nullptr) return;

  String packet = cmd + "\n";
  bleTxChar->setValue((uint8_t*)packet.c_str(), packet.length());
  bleTxChar->notify();
}

/// @brief Listen to messages from Bluetooth APP (non-blocking).
///        Liefert "" wenn aktuell nichts in der Queue liegt.
/// @return String recieved
String listenBLE() {
  String line;
  if (bleDequeue(line)) return line;
  return "";
}

/// @brief Blockierende Variante - wartet bis eine Zeile kommt oder
///        bis [timeoutMs] abgelaufen sind. Liefert "" bei Timeout.
String listenBLEBlocking(unsigned long timeoutMs = 0) {
  unsigned long t0 = millis();
  for (;;) {
    String line = listenBLE();
    if (line.length() > 0) return line;
    if (timeoutMs > 0 && (millis() - t0) >= timeoutMs) return "";
    delay(5);
  }
}

// =====================================================================
//  Setup
// =====================================================================
/// @brief Button, Serial and Bluetooth connection setup
void setup() {
  pinMode(B0, INPUT_PULLUP);
  pinMode(B1, INPUT_PULLUP);
  pinMode(B2, INPUT_PULLUP);
  pinMode(B3, INPUT_PULLUP);
  pinMode(B4, INPUT_PULLUP);
  pinMode(B5, INPUT_PULLUP);
  pinMode(B6, INPUT_PULLUP);
  pinMode(B7, INPUT_PULLUP);
  pinMode(B8, INPUT_PULLUP);
  pinMode(B9, INPUT_PULLUP);

  Serial.begin(115200);
  Serial1.begin(9600, SERIAL_8N1, RXD1, TXD1);
  Serial1.setTimeout(30000); // Nano darf bis zu 30 s fuer Pumpen brauchen

  initBLE();
}

// =====================================================================
//  Main Loop
// =====================================================================
/// @brief main loop
void loop() {
  // start listening to BLE (non-blocking)
  String msg = listenBLE();

  if (msg.length() == 0) {
    delay(5);
    return;
  }

  // ping
  if (msg == "ping") {
    sendBLE("pong");
  }

  // start game
  else if (msg == "start") {
    sendBLE("start_ok");
    for (int i = 0; i < 3; i++) {
      sendBLE(listenBTNround(i));
      // Auf "runde_ok" warten (max. 30 s, danach trotzdem weiter, damit
      // wir bei einem Disconnect nicht ewig haengen).
      while (true) {
        String ack = listenBLEBlocking(30000);
        if (ack == "runde_ok") break;
        if (ack.length() == 0) break; // Timeout
      }
    }
  }

  // start mixing - "mix_a_b_c_d"
  else if (msg.startsWith("mix_")) {
    sendCMD(msg);
    String reply = listenCMD();
    if (reply == "mix_ok") {
      sendBLE("mix_ok");
    } else {
      sendBLE("mix_err");
    }
  }

  // TODO: logic for manually using pumps
}

// =====================================================================
//  Game-Logik: Rundenerfassung ueber Buttons
// =====================================================================
/// @brief Listen to Buttons 0-5 for game
/// @param i game round
/// @return String "runde_x_y_z" for game round
String listenBTNround(int i) {
  String pl1 = "";
  String pl2 = "";

  String msg = "runde_";
  msg += i;

  while (pl1 == "" || pl2 == "") {
    bool b0 = digitalRead(B0);
    bool b1 = digitalRead(B1);
    bool b2 = digitalRead(B2);
    bool b3 = digitalRead(B3);
    bool b4 = digitalRead(B4);
    bool b5 = digitalRead(B5);

    if (pl1 == "") {
      if (pressedStable(B0) && lastB0 == HIGH) { Serial.println("Button 0"); pl1 = "_0"; }
      else if (pressedStable(B1) && lastB1 == HIGH) { Serial.println("Button 1"); pl1 = "_1"; }
      else if (pressedStable(B2) && lastB2 == HIGH) { Serial.println("Button 2"); pl1 = "_2"; }
    }
    if (pl2 == "") {
      if (pressedStable(B3) && lastB3 == HIGH) { Serial.println("Button 3"); pl2 = "_0"; }
      else if (pressedStable(B4) && lastB4 == HIGH) { Serial.println("Button 4"); pl2 = "_1"; }
      else if (pressedStable(B5) && lastB5 == HIGH) { Serial.println("Button 5"); pl2 = "_2"; }
    }

    lastB0 = b0;
    lastB1 = b1;
    lastB2 = b2;
    lastB3 = b3;
    lastB4 = b4;
    lastB5 = b5;

    delay(2);
  }
  return msg + pl1 + pl2;
}

// =====================================================================
//  Test-Helpers (raus, wenn echte Spiel-Logik laeuft)
// =====================================================================
/// @brief just for tests, remove later ...
void btnTest() {
  bool b0 = digitalRead(B0);
  bool b1 = digitalRead(B1);
  bool b2 = digitalRead(B2);
  bool b3 = digitalRead(B3);
  bool b4 = digitalRead(B4);
  bool b5 = digitalRead(B5);

  if (pressedStable(B0) && lastB0 == HIGH) { Serial.println("Button 0"); sendCMD("Beep"); }
  if (pressedStable(B1) && lastB1 == HIGH) { Serial.println("Fuck 1");   sendCMD("No Beep!"); }
  if (pressedStable(B2) && lastB2 == HIGH) { Serial.println("Fuck 2");   sendCMD("Button0On"); }
  if (pressedStable(B3) && lastB3 == HIGH) { Serial.println("Fuck 3");   sendCMD("Button0Off"); }
  if (!digitalRead(B4)) Serial.println("Fuck 4");
  if (!digitalRead(B5)) Serial.println("Fuck 5");
  if (!digitalRead(B6)) Serial.println("Fuck 6");
  if (!digitalRead(B7)) Serial.println("Fuck 7");
  if (!digitalRead(B8)) Serial.println("Fuck 8");
  if (!digitalRead(B9)) Serial.println("Fuck 9");

  lastB0 = b0;
  lastB1 = b1;
  lastB2 = b2;
  lastB3 = b3;
  lastB4 = b4;
  lastB5 = b5;
}
