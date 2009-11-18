#include <WProgram.h>
#include <TimerOne.h>
#include "Input.h"
#include "MidiOut.h"
#include "Scale.h"
#include "Instrument.h"
#include "Sequencer.h"

// Number of the pitch lines.
const int kNumPitch = 22;

// BPM settings.
const int kBpmMin = 80;
const int kBpmMax = 130;

// MIDI settings
const int kChanInstA = 0;   // For instrument A.
const int kChanInstB = 1;   // For instrument B.
const int kChanInstC = 2;   // For instrument C (keyboard).
const int kChanCC = 3;      // For CC messaging.

class ClockClass {
public:
  int tickCount_;
  boolean clockReady_;  // "Ready to send a clock" flag.
  boolean noteReady_;   // "Ready to send the next note" flag.
  
  static long calcPeriodBpm(int bpm) {
    return 60L * 1000 * 1000 / (bpm * 24);
  }

  ClockClass() {
    reset(false);
  }
  
  void reset(boolean start) {
    tickCount_ = -1;
    clockReady_ = false;
    noteReady_ = start;
  }
  
  void tick() {
    // Ignore the first tick.
    if (tickCount_ == -1) {
      tickCount_ = 2;
    } else {
      clockReady_ = true;
      // Process a note per six ticks.
      if (++tickCount_ == 6) {
        noteReady_ = true;
        tickCount_ = 0;
      }
    }
  }
};

ClockClass Clock;

// Timer interruption function.
void TimerTick() {
  Clock.tick();
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

// Used to read a pitch value when keyboard input is enabled.
int readKeyboard() {
  digitalWrite(13, LOW);
  digitalWrite(12, LOW);
  digitalWrite(11, LOW);
  digitalWrite(10, LOW);
  delayMicroseconds(50);
  analogRead(5); // Dummy read
  int pitch = (analogRead(5) * kNumPitch) >> 10;
  return max(pitch - 1, 0);
}

InstrumentClass InstA(kChanInstA);
InstrumentClass InstB(kChanInstB);
InstrumentClass InstC(kChanInstC);

int seqMode;
SequencerClass SeqA(kNumPitch, 4, 13, 12, 11, 10);
SequencerClass SeqB(kNumPitch, 5, 13, 12, 11, 10);

DigitalInputClass Master(4);
DigitalInputClass SwitchA(5);
DigitalInputClass SwitchB(6);
DigitalInputClass ButtonA(7);
DigitalInputClass ButtonB(8);
KnobInputClass KnobA(0);
KnobInputClass KnobB(1);
KnobInputClass KnobC(2);
SliderInputClass BpmSlider(3);

// Used to observe the sequence mode switch.
int getSwitchValue() {
  return (SwitchA.state_ ? 1 : 0) + (SwitchB.state_ ? 2 : 0);
}

void setup() {
  MidiOut.initialize();
  MidiOut.sendReset(kChanInstA);
  MidiOut.sendReset(kChanInstB);
  MidiOut.sendReset(kChanInstC);
  seqMode = getSwitchValue();
  Timer1.initialize(Clock.calcPeriodBpm(BpmSlider.value_));
  // Say hello!!
  pinMode(3, OUTPUT);
  for (int i = 0; i < 0x180; ++i) {
    analogWrite(3, i & 0x7f);
    delay(1);
  }
}

void loop() {
  // Master control.
  if (Master.update() && Master.state_) {
    static boolean running = false;
    running = !running;
    if (running) {
      // Start the sequencer.
      MidiOut.sendStart();
      // Start the clock.
      Clock.reset(true);
      Timer1.attachInterrupt(TimerTick);
    } else {
      // Stop the clock.
      Timer1.detachInterrupt();
      Clock.reset(false);
      // Reset the status.
      MidiOut.sendStop();
      InstA.endNote();
      InstB.endNote();
      InstC.endNote();
      SeqA.reset();
      SeqB.reset();
    }
  }
  // Drive the sequencers.
  if (Clock.noteReady_) {
    if (SeqA.stepPos_ == 0) {
      // Switch the sequence mode (when it changes).
      int input = getSwitchValue();
      if (seqMode != input) {
        seqMode = input;
        // Reset B & C.
        SeqB.reset();
        InstB.endNote();
        InstC.endNote();
        // Apply mode settings.
        if (seqMode == 0) {
          SeqA.length_ = SeqB.length_ = 16;
        } else if (seqMode == 3) {
          SeqA.length_ = SeqB.length_ = 32;
          SeqB.stepPos_ = 16;
        } else {
          SeqA.length_ = 16;
          SeqB.length_ = 12;
        }
      }
    }
    // Process the next note.
    if (seqMode < 2) {
      InstA.sendNote(SeqA.fetchNote());
      InstB.sendNote(SeqB.fetchNote());
    } else {
      InstA.sendNote(SeqA.fetchNote() + SeqB.fetchNote());
    }
    // Keyboard input.
    if (SeqB.length_ < 16) InstC.sendNote(readKeyboard(), true);
    Clock.noteReady_ = false;
  }
  // Timing clock.
  if (Clock.clockReady_) {
    MidiOut.sendClock();
    Clock.clockReady_ = false;
  }
  // Switches.
  SwitchA.update();
  SwitchB.update();
  // Buttons.
  if (ButtonA.update()) {
    MidiOut.sendCC(kChanCC, 31, ButtonA.state_ ? 127 : 0); // CC#31
  }
  if (ButtonB.update()) {
    MidiOut.sendCC(kChanCC, 30, ButtonB.state_ ? 127 : 0); // CC#30
  }
  // Knobs.
  if (KnobA.update()) {
    MidiOut.sendCC(kChanCC, 32, KnobA.value_); // CC#32
  }
  if (KnobB.update()) {
    MidiOut.sendCC(kChanCC, 33, KnobB.value_); // CC#33
  }
  if (KnobC.update()) {
    MidiOut.sendCC(kChanCC, 34, KnobC.value_); // CC#34
  }
  // BPM Slider.
  if (BpmSlider.update()) {
    Timer1.setPeriod(Clock.calcPeriodBpm(BpmSlider.value_));
  }
  // Blink the LED.
  if (Clock.tickCount_ < 0) {
    analogWrite(3, 0);
  } else if (Clock.tickCount_ == 0) {
    analogWrite(3, 127);
  } else {
    analogWrite(3, 50 - Clock.tickCount_ * 10);
  }
}

