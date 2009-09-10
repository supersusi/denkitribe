#include <WProgram.h>
#include "AccelInput.h"
#include "FingerInput.h"
#include "Indicator.h"
#include "KeyPadInput.h"
#include "MidiOut.h"

void setup() {
  Finger.initialize();
  Accel.initialize();
  KeyPad.initialize();
  Indicator.initialize();
  MidiOut.initialize();
}

void loop() {
  Finger.update();
  Accel.update();
  KeyPad.update();
  
  int16_t intensity = 0;

  for (int8_t i = 0; i < 4; ++i) {
    if (Finger.getDelta(i) != 0) {
      MidiOut.send(0xb0, 0x30 + i, Finger.getValue(i));
      intensity += Finger.getValue(i);
    }
  }

  Indicator.update(intensity);

  for (int8_t i = 0; i < 3; ++i) {
    if (Accel.getDelta(i) != 0) {
      MidiOut.send(0xb0, 0x34 + i, Accel.getValue(i));
    }
  }
  delay(10);  
}

