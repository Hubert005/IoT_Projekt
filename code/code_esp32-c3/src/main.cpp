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

bool pressedStable(int pin) {
  if (digitalRead(pin) == LOW) {
    delay(10);
    return digitalRead(pin) == LOW;
  }
  return false;
}

void sendCmd(const char* cmd) {
  Serial.print("ESP sent: ");
  Serial.println(cmd);
  Serial1.println(cmd);
}

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
}

void loop() {

  bool b0 = digitalRead(B0);
  bool b1 = digitalRead(B1);
  bool b2 = digitalRead(B2);
  bool b3 = digitalRead(B3);

  // For testing the Buttons, works so far
  if(pressedStable(B0) && lastB0 == HIGH){
    Serial.println("Button 0");
    // msg = "Beep\n";
    sendCmd("Beep");
  } 
  if(pressedStable(B1) && lastB1 == HIGH){
    Serial.println("Fuck 1");
    // msg= "No Beep!\n";
    sendCmd("No Beep!");
  } 
  if(pressedStable(B2) && lastB2 == HIGH){
    Serial.println("Fuck 2");
    // msg="Button0On\n";
    sendCmd("Button0On");
  } 
  if(pressedStable(B3) && lastB3 == HIGH){
    Serial.println("Fuck 3");
    // msg="Button0Off\n";
    sendCmd("Button0Off");
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
