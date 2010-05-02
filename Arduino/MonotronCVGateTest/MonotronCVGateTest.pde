#include "Spi.h"

const int kGatePin = 2;

void sendNote(int key) {
  int pitch = 0xa00L * key / 12;

  digitalWrite(SS_PIN, LOW);
  Spi.transfer(0x10 + (pitch >> 8));
  Spi.transfer(pitch & 0xff);
  digitalWrite(SS_PIN, HIGH);

  digitalWrite(kGatePin, HIGH);
  delay(400);
  digitalWrite(kGatePin, LOW);
  delay(100);
}

void setup() {
  pinMode(kGatePin, OUTPUT);
}

void loop() {
  sendNote(0);
  sendNote(2);
  sendNote(4);
  sendNote(5);
  sendNote(7);
  sendNote(9);
  sendNote(11);
  sendNote(12);
}

