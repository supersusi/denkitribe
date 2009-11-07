#include <WProgram.h>
#include "MidiOut.h"

// MIDI settings
const int kChanCC = 0;   // For CC messaging.

class AnalogInput {
public:
  int select_;
  int minInput_;
  int maxInput_;
  int value_;
  
  void init(int select, int minInput, int maxInput) {
    select_ = select;
    minInput_ = minInput;
    maxInput_ = maxInput;
    value_ = 0;
  }
  
  boolean update() {
    digitalWrite(7, (select_ & 1) ? HIGH : LOW);
    digitalWrite(8, (select_ & 2) ? HIGH : LOW);
    digitalWrite(9, (select_ & 4) ? HIGH : LOW);
    delayMicroseconds(100);
    int value = max(analogRead(3) - minInput_, 0);
    value = value > 0 ? value : 0;
    value = min(128L * value / (maxInput_ - minInput_), 127);
    value = (value + value_) >> 1;
    boolean modFlag = (value != value_);
    value_ = value;
    return modFlag;
  }
};

AnalogInput analogs[6];

void setup() {
  pinMode(7, OUTPUT);
  pinMode(8, OUTPUT);
  pinMode(9, OUTPUT);
  
  analogs[0].init(7, 535, 600);
  analogs[1].init(1, 500, 770);
  analogs[2].init(5, 520, 770);
  analogs[3].init(3, 540, 780);
  analogs[4].init(4, 0, 1024);
  analogs[5].init(0, 0, 1024);

  MidiOut.initialize();
  MidiOut.sendReset(kChanCC);
}

void loop() {
  for (int i = 0; i < 6; ++i) {
    if (analogs[i].update()) {
      MidiOut.sendCC(kChanCC, 30 + i, analogs[i].value_);
    }
  }
}

