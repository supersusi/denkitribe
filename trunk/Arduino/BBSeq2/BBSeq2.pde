#include <WProgram.h>
#include <TimerOne.h>
#include "Input.h"
#include "MidiOut.h"
#include "Scale.h"

// BPM settings.
const int kBpmMin = 80;
const int kBpmMax = 180;

// Number of the pitch lines.
const int kNumPitch = 22;

// MIDI settings
const int kChannelA = 0;    // For instrument A.
const int kChannelB = 1;    // For instrument B.
const int kChannelC = 2;    // For CC messages.

class InstrumentClass {
public:
  static const int kVelocity = 100;
  
  const int channel_;
  int lastNoteNum_;
  
  InstrumentClass(int channel)
  : channel_(channel),
    lastNoteNum_(0) {}
  
  void sendNote(int pitchIndex) {
    endNote();
    if (pitchIndex > 0) {
      lastNoteNum_ = Scale.pickPitch(pitchIndex - 1);
      MidiOut.sendNoteOn(channel_, lastNoteNum_, kVelocity);
    } else {
      lastNoteNum_ = -1;
    }
  }
  
  void endNote() {
    if (lastNoteNum_ >= 0) {
      MidiOut.sendNoteOff(channel_, lastNoteNum_, kVelocity);
      lastNoteNum_ = -1;
    }
  }
};

class SequencerClass {
public:
  const int inputPort_;
  int length_;
  int stepPos_;
  
  SequencerClass(int inputPort)
  : inputPort_(inputPort),
    length_(16),
    stepPos_(0) {
    pinMode(10, OUTPUT);
    pinMode(11, OUTPUT);
    pinMode(12, OUTPUT);
    pinMode(13, OUTPUT);
  }
  
  void reset() {
    stepPos_ = 0;
  }
  
  int fetchNote() {
    int pitchIndex = 0;
    if (stepPos_ < 16) {
      int select = 15 - stepPos_;
      digitalWrite(13, (select & 1) ? HIGH : LOW);
      digitalWrite(12, (select & 2) ? HIGH : LOW);
      digitalWrite(11, (select & 4) ? HIGH : LOW);
      digitalWrite(10, (select & 8) ? HIGH : LOW);
      delayMicroseconds(50);
      analogRead(inputPort_); // Dummy read
      pitchIndex = (analogRead(inputPort_) * kNumPitch + 512) >> 10;
    }
    if (++stepPos_ >= length_) stepPos_ = 0;
    return pitchIndex;
  }
};

// Used to track the timer.
class TimerClass {
public:
  int tickCount_;
  int clockReady_;
  int noteReady_;
  
  TimerClass() {
    reset();
  }
  
  void reset() {
    tickCount_ = -1;
    clockReady_ = false;
    noteReady_ = false;
  }
  
  void tick() {
    // Ignore the first tick.
    if (tickCount_ == -1) {
      tickCount_ = 0;
    } else {
      clockReady_ = true;
      // Process a note per six ticks.
      if (++tickCount_ == 6) {
        noteReady_ = true;
        tickCount_ = 0;
      }
    }
  }
  
  long calcPeriod(int bpm) {
    return 60L * 1000 * 1000 / (bpm * 24);
  }
};

TimerClass Timer;

void TimerTickFunction() {
  Timer.tick();
}

// Used to observe a knob.
class KnobInputClass : public AnalogInputClass<KnobInputClass> {
  public:
  KnobInputClass(int port) : AnalogInputClass<KnobInputClass>(port) {}
  static int convertInput(int input) {
    return 127 - (input >> 3);
  }
};

// Used to observe the BPM slider.
class SliderInputClass : public AnalogInputClass<SliderInputClass> {
  public:
  SliderInputClass(int port) : AnalogInputClass<SliderInputClass>(port) {}
  static int convertInput(int input) {
    return kBpmMin + ((int32_t(kBpmMax - kBpmMin + 1) * input) >> 10);
  }
};

InstrumentClass InstrumentA(kChannelA);
InstrumentClass InstrumentB(kChannelB);
SequencerClass SequencerA(4);
SequencerClass SequencerB(5);
DigitalInputClass Master(4);
DigitalInputClass SwitchA(5);
DigitalInputClass SwitchB(6);
DigitalInputClass ButtonA(7);
DigitalInputClass ButtonB(8);
KnobInputClass KnobA(0);
KnobInputClass KnobB(1);
KnobInputClass KnobC(2);
SliderInputClass BpmSlider(3);

int getSwitchValue() {
  return (SwitchA.state_ ? 1 : 0) + (SwitchB.state_ ? 2 : 0);
}
int sequenceMode;

void sayHello() {
  pinMode(3, OUTPUT);
  for (int i = 0; i < 0x180; ++i) {
    analogWrite(3, i & 127);
    delay(1);
  }
}

void setup() {
  MidiOut.initialize();
  MidiOut.sendAllNoteOff(kChannelA);
  MidiOut.sendAllNoteOff(kChannelB);
  sayHello();
  sequenceMode = getSwitchValue();
  Timer1.initialize(Timer.calcPeriod(BpmSlider.value_));
}

void loop() {
  // Timing clock.
  if (Timer.clockReady_) {
    MidiOut.sendClock();
    Timer.clockReady_ = false;
  }
  // Drive the sequencers.
  if (Timer.noteReady_) {
    if (SequencerA.stepPos_ == 0) {
      int input = getSwitchValue();
      if (sequenceMode != input) {
        sequenceMode = input;
        SequencerB.reset();
        InstrumentB.endNote();
        if (sequenceMode == 0) {
          SequencerA.length_ = 16;
          SequencerB.length_ = 16;
        } else if (sequenceMode == 3) {
          SequencerA.length_ = 32;
          SequencerB.length_ = 32;
          SequencerB.stepPos_ = 16;
        } else {
          SequencerA.length_ = 16;
          SequencerB.length_ = 12;
        }
      }
    }
    if (sequenceMode < 2) {
      InstrumentA.sendNote(SequencerA.fetchNote());
      InstrumentB.sendNote(SequencerB.fetchNote());
    } else {
      InstrumentA.sendNote(SequencerA.fetchNote() + SequencerB.fetchNote());
    }
    Timer.noteReady_ = false;
  }
  // Master control.
  if (Master.update() && Master.state_) {
    static boolean running = false;
    running = !running;
    if (running) {
      // Start the sequencer.
      MidiOut.sendStart();
      // Start the timer.
      Timer1.attachInterrupt(TimerTickFunction);
    } else {
      // Stop the timer.
      Timer1.detachInterrupt();
      Timer.reset();
      // Reset the sequencer.
      MidiOut.sendStop();
      InstrumentA.endNote();
      InstrumentB.endNote();
      SequencerA.reset();
      SequencerB.reset();
    }
  }
  // Switches.
  SwitchA.update();
  SwitchB.update();
  // Buttons.
  if (ButtonA.update()) {
    MidiOut.sendCC(kChannelC, 31, ButtonA.state_ ? 127 : 0); // CC#31
  }
  if (ButtonB.update()) {
    MidiOut.sendCC(kChannelC, 30, ButtonB.state_ ? 127 : 0); // CC#30
  }
  // Knobs.
  if (KnobA.update()) {
    MidiOut.sendCC(kChannelC, 32, KnobA.value_); // CC#32
  }
  if (KnobB.update()) {
    MidiOut.sendCC(kChannelC, 33, KnobB.value_); // CC#33
  }
  if (KnobC.update()) {
    MidiOut.sendCC(kChannelC, 34, KnobC.value_); // CC#34
  }
  // BPM Slider.
  if (BpmSlider.update()) {
    Timer1.setPeriod(Timer.calcPeriod(BpmSlider.value_));
  }
  // Blink the LED.
  if (Timer.tickCount_ < 0) {
    analogWrite(3, 0);
  } else if (Timer.tickCount_ == 0) {
    analogWrite(3, 127);
  } else {
    analogWrite(3, 50 - Timer.tickCount_ * 10);
  }
}

