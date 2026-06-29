#include <Arduino.h>

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

/// @brief Listen to Arduino NANO
/// @return String recieved
String listenCMD(){
  return Serial1.readStringUntil('\n');
}

/// @brief Send String to APP via Bluetooth
/// @param cmd String to send
void sendBLE(String cmd){

}

/// @brief Listen to messages from Bluetooth APP
/// @return String recieved
String listenBLE(){

}

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
  Serial1.setTimeout(20000); // kuerzer als das App-Timeout (30 s), damit mix_err die App erreicht

  Serial1.begin(9600, SERIAL_8N1, RXD1, TXD1);
}

/// @brief main loop
void loop(){
  // start listening to BLE
  String msg = listenBLE();

  // start game
  if(msg == "start"){
    sendBLE("start_ok");
    int round = 0;
    bool playing = true;
    while (playing) {
      sendBLE(listenBTNround(round));
      // Auf "runde_ok" (naechste Runde) oder "stop" (Serie vorbei) warten.
      // Bei Timeout/Disconnect beenden wir die Serie, damit wir nicht haengen.
      while (true) {
        String ack = listenBLEBlocking(30000);
        if (ack == "runde_ok") { round++; break; }
        if (ack == "stop") { playing = false; break; }
        if (ack.length() == 0) { playing = false; break; }
        // unbekannte Nachricht -> ignorieren, weiter warten
      }
    }
  }

  // start mixing - "mix_a_b_c_d"
  else if (msg.startsWith("mix_")) {
    while (Serial1.available()) Serial1.read(); // stale Frames vor dem Mix verwerfen
    sendCMD(msg);
    if(listenCMD() == "mix_ok"){
      sendBLE("mix_ok");
    }
  }

  msg = "";

  // TODO: logic for manually using pumps

}

/// @brief Listen to Buttons 0-5 for game
/// @param i game round
/// @return String "runde_x_y_z" for game round
String listenBTNround(int i){

  bool b0 = digitalRead(B0);
  bool b1 = digitalRead(B1);
  bool b2 = digitalRead(B2);
  bool b3 = digitalRead(B3);
  bool b4 = digitalRead(B3);
  bool b5 = digitalRead(B3);

  String pl1 = "";
  String pl2 = "";

  String msg = "runde_";
  msg += i;

  while(pl1 != "" && pl2 != ""){
    bool b0 = digitalRead(B0);
    bool b1 = digitalRead(B1);
    bool b2 = digitalRead(B2);
    bool b3 = digitalRead(B3);
    bool b4 = digitalRead(B3);
    bool b5 = digitalRead(B3);

    if(pl1 != ""){
      if(pressedStable(B0) && lastB0 == HIGH){
        Serial.println("Button 0");
        pl1 = "_0";
      } 
      if(pressedStable(B1) && lastB1 == HIGH){
        Serial.println("Button 1");
        pl1 = "_1";
      } 
      if(pressedStable(B2) && lastB2 == HIGH){
        Serial.println("Button 2");
        pl1 = "_2";
      }
    }
    if(pl2 != ""){
      if(pressedStable(B3) && lastB3 == HIGH){
        Serial.println("Button 3");
        pl2 = "_0";
      } 
      if(!digitalRead(B4) && lastB4 == HIGH){
        Serial.println("Button 4");
        pl2 = "_1";
      } 
      if(!digitalRead(B5) && lastB5 == HIGH){
        Serial.println("Button 5");
        pl2 = "_2";
      } 
    }

    lastB0 = b0;
    lastB1 = b1;
    lastB2 = b2;
    lastB3 = b3;
    lastB4 = b4;
    lastB5 = b5;
  }
  return(msg + pl1 + pl2);
}






/// @brief just for tests, remove later ...
void btnTest() {

  bool b0 = digitalRead(B0);
  bool b1 = digitalRead(B1);
  bool b2 = digitalRead(B2);
  bool b3 = digitalRead(B3);
  bool b4 = digitalRead(B3);
  bool b5 = digitalRead(B3);

  if(pressedStable(B0) && lastB0 == HIGH){
    Serial.println("Button 0");
    // msg = "Beep\n";
    sendCMD("Beep");
  } 
  if(pressedStable(B1) && lastB1 == HIGH){
    Serial.println("Fuck 1");
    // msg= "No Beep!\n";
    sendCMD("No Beep!");
  } 
  if(pressedStable(B2) && lastB2 == HIGH){
    Serial.println("Fuck 2");
    // msg="Button0On\n";
    sendCMD("Button0On");
  } 
  if(pressedStable(B3) && lastB3 == HIGH){
    Serial.println("Fuck 3");
    // msg="Button0Off\n";
    sendCMD("Button0Off");
  } 
  if(!digitalRead(B4)){
    Serial.println("Fuck 4");
  } 
  if(!digitalRead(B5)){
    Serial.println("Fuck 5");
  } 

  // For testing the Buttons, works so far
  if(pressedStable(B0) && lastB0 == HIGH){
    Serial.println("Button 0");
    // msg = "Beep\n";
    sendCMD("Beep");
  } 
  if(pressedStable(B1) && lastB1 == HIGH){
    Serial.println("Fuck 1");
    // msg= "No Beep!\n";
    sendCMD("No Beep!");
  } 
  if(pressedStable(B2) && lastB2 == HIGH){
    Serial.println("Fuck 2");
    // msg="Button0On\n";
    sendCMD("Button0On");
  } 
  if(pressedStable(B3) && lastB3 == HIGH){
    Serial.println("Fuck 3");
    // msg="Button0Off\n";
    sendCMD("Button0Off");
  } 
  if(!digitalRead(B4)){
    Serial.println("Fuck 4");
  } 
  if(!digitalRead(B5)){
    Serial.println("Fuck 5");
  } 
  if(!digitalRead(B6)){
    Serial.println("Fuck 6");
  } 
  if(!digitalRead(B7)){
    Serial.println("Fuck 7");
  } 
  if(!digitalRead(B8)){
    Serial.println("Fuck 8");
  } 
  if(!digitalRead(B9)){
    Serial.println("Fuck 9");
  }

  lastB0 = b0;
  lastB1 = b1;
  lastB2 = b2;
  lastB3 = b3;

}
