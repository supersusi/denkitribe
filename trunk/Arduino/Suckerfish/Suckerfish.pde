#include "Sequence.h"

int sequenceSelect = 0;
const EventData* pCurrentEvent;

void setup() {
  Serial.begin(31250);
  sendMidi(0xb0, 0x78, 0); // all sound off
}

void loop() {
  pCurrentEvent = sequences[sequenceSelect];
  while (pCurrentEvent->delta != 0xff) {
    if (pCurrentEvent->delta > 0) {
      delay(100 * pCurrentEvent->delta);
    }
    sendMidi(pCurrentEvent->status,
             pCurrentEvent->data1,
             pCurrentEvent->data2);
    pCurrentEvent++;
  }
}

void sendMidi(char stat, char data1, char data2) {
  Serial.print(stat, BYTE);
  Serial.print(data1, BYTE);
  Serial.print(data2, BYTE);
}
