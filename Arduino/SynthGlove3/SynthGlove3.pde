#include <WProgram.h>
#include "FilteredInput.h"
#include "MidiOut.h"
#include "Trigger.h"

// MIDI settings
const int kChanCC = 0;        // For CC messaging.
const int kChanTrigger = 1;   // For Trigger messaging.

FilteredInputClass Knobs[8];
TriggerClass Triggers[4];
boolean pitchBendFlag;

void setup() {
  pinMode(7, OUTPUT);
  pinMode(8, OUTPUT);
  pinMode(9, OUTPUT);
  
  digitalWrite(2, HIGH);
  digitalWrite(4, HIGH);
  digitalWrite(10, HIGH);
  digitalWrite(11, HIGH);
  
  Knobs[0].init(7, 535, 600);
  Knobs[1].init(1, 500, 770);
  Knobs[2].init(5, 520, 770);
  Knobs[3].init(3, 540, 780);
  Knobs[4].init(4, 0, 1024);
  Knobs[5].init(0, 0, 1024);
  Knobs[6].init(9, 540, 310);
  Knobs[7].init(8, 760, 560);
  
  Triggers[0].init(&Knobs[0], &Knobs[6], &Knobs[7], kChanTrigger, 40);
  Triggers[1].init(&Knobs[1], &Knobs[6], &Knobs[7], kChanTrigger, 44);
  Triggers[2].init(&Knobs[2], &Knobs[6], &Knobs[7], kChanTrigger, 47);
  Triggers[3].init(&Knobs[3], &Knobs[6], &Knobs[7], kChanTrigger, 51);
  
  pitchBendFlag = false;

  MidiOut.initialize();
  MidiOut.sendReset(kChanCC);
  MidiOut.sendReset(kChanTrigger);
}

void loop() {
  for (int i = 0; i < 8; ++i) {
    if (i == 6 && digitalRead(2) == LOW) continue;
    if (i == 7 && digitalRead(4) == LOW) continue;
    Knobs[i].update();
    if (Knobs[i].isModified()) {
      MidiOut.sendCC(kChanCC, 30 + i, Knobs[i].getValue());
    }
  }
  
  if (!digitalRead(11)) {
    if (!pitchBendFlag || Knobs[6].isModified()) {
      MidiOut.sendPitchBend(kChanTrigger, 0x40 + (Knobs[6].getValue() >> 1));
    }
    pitchBendFlag = true;
  } else {
    if (pitchBendFlag) {
      MidiOut.sendPitchBend(kChanTrigger, 0x40);
      pitchBendFlag = false;
    }
  }
  
  boolean triggerPitchFlag = !digitalRead(10);
  for (int i = 0; i < 4; ++i) {
    Triggers[i].setDynamicPitchFlag(triggerPitchFlag);
    Triggers[i].update();
  }
}

