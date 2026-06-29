#include <Arduino.h>
#include <Wire.h>

#include <SoftwareSerial.h>

SoftwareSerial espSerial(8, 9); // RX, TX

#define BUZZER 10
#define M0 2
#define M1 3
#define M2 4
#define M3 5
#define B0 8

String msg;

/// @brief pump "Motor" for "duration" milliseconds
/// @param Motor Motor number (0-3)
/// @param duration Duration in milliseconds to pump
void pump(int Motor, int duration){
  digitalWrite(Motor, HIGH);
  delay (duration);
  digitalWrite(Motor, LOW);
}

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

  // msg is: mix_'duration Pump 0'_'duration Pump 1'_'duration Pump 2'_'duration Pump 3'
  if(msg.startsWith("mix_")){
    msg.remove(0, 4); // remove "mix_"
    int durations[4];
    for(int i = 0; i < 4; i++){
      int underscoreIndex = msg.indexOf('_');
      // last field has no trailing '_', take the remainder of the string
      if(underscoreIndex == -1 && i < 3){
        espSerial.println("mix_err"); // NAK so the ESP doesn't wait for a timeout
        Serial.println("Invalid message format");
        return;
      }
      String durationStr = (underscoreIndex == -1) ? msg : msg.substring(0, underscoreIndex);
      durations[i] = durationStr.toInt();
      if(underscoreIndex != -1){
        msg.remove(0, underscoreIndex + 1);
      }
    }
    // Pump the motors
    for(int i = 0; i < 4; i++){
      pump(M0 + i, durations[i]);
    }

    // send OK to ESP after pumping is complete
    espSerial.println("mix_ok");

    // Buzz to indicate completion
    digitalWrite(BUZZER, HIGH);
    delay(250);
    digitalWrite(BUZZER, LOW);
    delay(50);
    digitalWrite(BUZZER, HIGH);
    delay(250);
    digitalWrite(BUZZER, LOW);
  }

  msg = "";

  // TODO: add logic for manual pumping
}
