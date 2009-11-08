#include <WProgram.h>
#include "FilteredInput.h"
#include "MidiOut.h"
#include "Trigger.h"

const int kPinMuxS1 = 7;
const int kPinMuxS2 = 8;
const int kPinMuxS3 = 9;
const int kPinMuxCom = 3;

const int kPinAccPitch = 1;
const int kPinAccRoll = 0;

const int kPinSwitchA1 = 2;
const int kPinSwitchA2 = 4;
const int kPinSwitchB1 = 10;
const int kPinSwitchB2 = 11;

const int kChannelCC = 0;
const int kChannelTrigger = 1;
const int kFirstCC = 30;

const int kNote1 = 40;  // O4 C
const int kNote2 = 44;  // O4 E
const int kNote3 = 47;  // O4 G
const int kNote4 = 51;  // O4 B

typedef FilteredInputTemplate
  <kPinMuxS1, kPinMuxS2, kPinMuxS3, kPinMuxCom> FilteredInput;
typedef TriggerTemplate<FilteredInput> Trigger;

FilteredInput knobs[8];
Trigger triggers[4];
boolean pitchBendFlag;

void setup() {
  FilteredInput::setup();
  
  digitalWrite(kPinSwitchA1, HIGH);
  digitalWrite(kPinSwitchA2, HIGH);
  digitalWrite(kPinSwitchB1, HIGH);
  digitalWrite(kPinSwitchB2, HIGH);
  
  knobs[0].init(7, 535, 600);
  knobs[1].init(1, 500, 770);
  knobs[2].init(5, 520, 770);
  knobs[3].init(3, 540, 780);
  knobs[4].init(4, 0, 1024);
  knobs[5].init(0, 0, 1024);
  knobs[6].init(8 + kPinAccPitch, 540, 310);
  knobs[7].init(8 + kPinAccRoll, 760, 560);
  
  triggers[0].init
    (&knobs[0], &knobs[6], &knobs[7], kChannelTrigger, kNote1);
  triggers[1].init
    (&knobs[1], &knobs[6], &knobs[7], kChannelTrigger, kNote2);
  triggers[2].init
    (&knobs[2], &knobs[6], &knobs[7], kChannelTrigger, kNote3);
  triggers[3].init
    (&knobs[3], &knobs[6], &knobs[7], kChannelTrigger, kNote4);
  
  pitchBendFlag = false;

  MidiOut.initialize();
  MidiOut.sendReset(kChannelCC);
  MidiOut.sendReset(kChannelTrigger);
}

void loop() {
  for (int i = 0; i < 8; ++i) {
    if (i == 6 && digitalRead(kPinSwitchA1) == LOW) continue;
    if (i == 7 && digitalRead(kPinSwitchA2) == LOW) continue;
    knobs[i].update();
    if (knobs[i].isModified()) {
      MidiOut.sendCC(kChannelCC, kFirstCC + i, knobs[i].getValue());
    }
  }
  
  if (!digitalRead(kPinSwitchB2)) {
    if (!pitchBendFlag || knobs[6].isModified()) {
      MidiOut.sendPitchBend(kChannelTrigger,
                            0x40 + (knobs[6].getValue() >> 1));
    }
    pitchBendFlag = true;
  } else {
    if (pitchBendFlag) {
      MidiOut.sendPitchBend(kChannelTrigger, 0x40);
      pitchBendFlag = false;
    }
  }
  
  boolean triggerPitchFlag = !digitalRead(kPinSwitchB1);
  for (int i = 0; i < 4; ++i) {
    triggers[i].setDynamicPitchFlag(triggerPitchFlag);
    triggers[i].update();
  }
}

