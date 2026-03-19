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
  delay(2000);
  Serial.println("ESP32-C3 serial monitor works");
}

void loop() {

  // For testing the Buttons, works so far
  if(!digitalRead(B0)){
    Serial.println("Button 0");
  }
  if(!digitalRead(B1)){
    Serial.println("Button 1");
  }
  if(!digitalRead(B2)){
    Serial.println("Button 2");
  }
  if(!digitalRead(B3)){
    Serial.println("Button 3");
  }
  if(!digitalRead(B4)){
    Serial.println("Button 4");
  }
  if(!digitalRead(B5)){
    Serial.println("Button 5");
  }
  if(!digitalRead(B6)){
    Serial.println("Button 6");
  }
  if(!digitalRead(B7)){
    Serial.println("Button 7");
  }
  if(!digitalRead(B8)){
    Serial.println("Button 8");
  }
  if(!digitalRead(B9)){
    Serial.println("Button 9");
  }

}
