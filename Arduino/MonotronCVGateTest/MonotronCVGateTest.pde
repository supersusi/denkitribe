#include "Spi.h"

const int kGatePin = 2;

void sendNote(int key) {
  int pitch = 0xa00L * key / 12;

  digitalWrite(SS_PIN, LOW);
  Spi.transfer(0x10 + (pitch >> 8));
  Spi.transfer(pitch & 0xff);
  digitalWrite(SS_PIN, HIGH);

  digitalWrite(kGatePin, HIGH);
  delay(90);
  digitalWrite(kGatePin, LOW);
  delay(10);
}

void setup() {
  pinMode(kGatePin, OUTPUT);
}

void loop() {
  sendNote(0);
  sendNote(12);
  sendNote(11);
  sendNote(12);
  sendNote(16);
  sendNote(12);
  sendNote(11);
  sendNote(12);

  sendNote(0);
  sendNote(12);
  sendNote(10);
  sendNote(12);
  sendNote(16);
  sendNote(12);
  sendNote(10);
  sendNote(12);

  sendNote(0);
  sendNote(12);
  sendNote(9);
  sendNote(12);
  sendNote(16);
  sendNote(12);
  sendNote(9);
  sendNote(12);

  sendNote(0);
  sendNote(12);
  sendNote(8);
  sendNote(12);
  sendNote(16);
  sendNote(12);
  sendNote(8);
  sendNote(12);
}

