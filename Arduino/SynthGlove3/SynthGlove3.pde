#include <WProgram.h>
#include "MidiOut.h"

// MIDI settings
const int kChanCC = 0;   // For CC messaging.

class AnalogInput {
public:
  static const int kWindowSize = 4;
  
  int select_;
  int minInput_;
  int maxInput_;

  int value_;
  int accum_;
  int sampleCount_;
  
  void init(int select, int minInput, int maxInput) {
    select_ = select;
    minInput_ = minInput;
    maxInput_ = maxInput;
    value_ = 0;
    accum_ = 0;
    sampleCount_ = 0;
  }
  
  void getSample() {
    if (select_ < 8) {
      digitalWrite(7, (select_ & 1) ? HIGH : LOW);
      digitalWrite(8, (select_ & 2) ? HIGH : LOW);
      digitalWrite(9, (select_ & 4) ? HIGH : LOW);
      delayMicroseconds(100);
      accum_ += analogRead(3);
    } else {
      accum_ += analogRead(select_ - 8);
    }
    sampleCount_++;
  }
  
  boolean update() {
    boolean modFlag = false;
    getSample();
    if (sampleCount_ == (1 << kWindowSize)) {
      int value = 128L * ((accum_ >> kWindowSize) - minInput_) / (maxInput_ - minInput_);
      value = value > 127 ? 127 : (value < 0 ? 0 : value);
      if (value != value_) {
        modFlag = true;
        value_ = value;
      }
      accum_ = 0;
      sampleCount_ = 0;
    }
    return modFlag;
  }
};

AnalogInput analogs[8];

void setup() {
  digitalWrite(2, HIGH);
  digitalWrite(4, HIGH);
  
  pinMode(7, OUTPUT);
  pinMode(8, OUTPUT);
  pinMode(9, OUTPUT);
  
  analogs[0].init(7, 535, 600);
  analogs[1].init(1, 500, 770);
  analogs[2].init(5, 520, 770);
  analogs[3].init(3, 540, 780);
  analogs[4].init(4, 0, 1024);
  analogs[5].init(0, 0, 1024);
  analogs[6].init(9, 540, 310);
  analogs[7].init(8, 760, 560);

  MidiOut.initialize();
  MidiOut.sendReset(kChanCC);
}

void loop() {
  for (int i = 0; i < 8; ++i) {
    if (i == 6 && digitalRead(2) == LOW) continue;
    if (i == 7 && digitalRead(4) == LOW) continue;
    if (analogs[i].update()) {
      MidiOut.sendCC(kChanCC, 30 + i, analogs[i].value_);
    }
  }
}

