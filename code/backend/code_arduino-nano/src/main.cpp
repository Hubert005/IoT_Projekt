#include <Arduino.h>
#include <Wire.h>

#include <SoftwareSerial.h>

SoftwareSerial espSerial(8, 9); // RX, TX

#define BUZZER 10
#define M0 2
#define M1 3
#define M2 4
#define M3 5
String msg;

void setup() {
  pinMode(BUZZER, OUTPUT);
  pinMode(M0, OUTPUT);
  pinMode(M1, OUTPUT);
  pinMode(M2, OUTPUT);
  pinMode(M3, OUTPUT);

  Serial.begin(115200);
  espSerial.begin(9600);
  Serial.println("Serial Started");
}

void loop() {

  if (espSerial.available()) {
    msg = espSerial.readStringUntil('\n');
    msg.trim();
    if (msg.length() > 0) {
      Serial.print("Nano got: ");
      Serial.println(msg);
    }
  }

  if(msg == "Beep"){
    digitalWrite(BUZZER, HIGH);
  } 
  if(msg == "No Beep!"){
    digitalWrite(BUZZER, LOW);
  }
  if(msg == "Button0On"){
    digitalWrite(M0, HIGH);
  } 
  if(msg == "Button0Off"){
    digitalWrite(M0, LOW);
  }

}
