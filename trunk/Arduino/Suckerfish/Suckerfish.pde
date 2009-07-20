#include "avr/pgmspace.h"
#include "Sequence.h"

int selector = 3;
int dataOffset;

void setup() {
  Serial.begin(31250);
  sendMidi(0xb0, 0x78, 0); // all sound off
}

void loop() {
  dataOffset = startPoints[selector];
  while (true) {
    uint8_t delta  = pgm_read_byte_near(sequenceData + dataOffset++);
    uint8_t status = pgm_read_byte_near(sequenceData + dataOffset++);
    uint8_t data1  = pgm_read_byte_near(sequenceData + dataOffset++);
    uint8_t data2  = pgm_read_byte_near(sequenceData + dataOffset++);
    if (delta == 0xff) break;
    if (delta > 0) delay(120 * delta);
    sendMidi(status, data1, data2);
  }
}

void sendMidi(char stat, char data1, char data2) {
  Serial.print(stat, BYTE);
  Serial.print(data1, BYTE);
  Serial.print(data2, BYTE);
}
