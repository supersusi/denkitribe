#include <WProgram.h>
#include <TimerOne.h>
#include "Input.h"
#include "MidiOut.h"
#include "Scale.h"

// BPM settings.
const int kBpmMin = 80;
const int kBpmMax = 130;

// Number of the pitch lines.
const int kNumPitch = 22;

// MIDI settings
const int kChannelA = 0;
const int kChannelB = 1;
const int kChannelCC = 2;
const int kVelocity = 100;

// Used to process a sequencer with a multiplexer.
class SequencerClass {
public:
  const int kChannel_;
  const int kInputPort_;
  
  int stepPos_;
  int prevNote_;
  
  SequencerClass(int channel, int inputPort)
  : kChannel_(channel),
    kInputPort_(inputPort),
    stepPos_(0),
    prevNote_(-1) {
    pinMode(10, OUTPUT);
    pinMode(11, OUTPUT);
    pinMode(12, OUTPUT);
    pinMode(13, OUTPUT);
  }
  
  void stopAndReset() {
    // Send a note off message
    if (prevNote_ >= 0) {
      MidiOut.sendNoteOff(kChannel_, prevNote_, kVelocity);
    }
    // Reset the status.
    stepPos_ = 0;
    prevNote_ = -1;
  }
  
  void readAndSendNote() {
    // Set the multiplexer.
    int select = 0xf - stepPos_;
    digitalWrite(13, (select & 1) ? HIGH : LOW);
    digitalWrite(12, (select & 2) ? HIGH : LOW);
    digitalWrite(11, (select & 4) ? HIGH : LOW);
    digitalWrite(10, (select & 8) ? HIGH : LOW);
    delayMicroseconds(50);
    // Send a note off message.
    if (prevNote_ >= 0) {
      MidiOut.sendNoteOff(kChannel_, prevNote_, kVelocity);
    }
    // Fetch a note from the multiplexer.
    analogRead(kInputPort_); // Dummy read
    int index = (analogRead(kInputPort_) * kNumPitch + 512) >> 10;
    int note = (index == 0) ? -1 : Scale.pickPitch(index);
    if (note >= 0) {
      // Send a note on message.
      MidiOut.sendNoteOn(kChannel_, note, kVelocity);
    }
    // Advance the step position.
    stepPos_ = (stepPos_ + 1) & 0xf;
    prevNote_ = note;
  }
};

// Sequencer instances.
SequencerClass SequencerA(kChannelA, 4);
SequencerClass SequencerB(kChannelB, 5);

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

DigitalInputClass Master(4);
DigitalInputClass SwitchA(5);
DigitalInputClass SwitchB(6);
DigitalInputClass ButtonA(7);
DigitalInputClass ButtonB(8);
KnobInputClass KnobA(0);
KnobInputClass KnobB(1);
KnobInputClass KnobC(2);
SliderInputClass BpmSlider(3);

void setup() {
  pinMode(3, OUTPUT);
  MidiOut.initialize();
  MidiOut.sendAllNoteOff(kChannelA);
  MidiOut.sendAllNoteOff(kChannelB);
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
    SequencerA.readAndSendNote();
    SequencerB.readAndSendNote();
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
      SequencerA.stopAndReset();
      SequencerB.stopAndReset();
    }
  }
  // Switches.
  SwitchA.update();
  SwitchB.update();
  // Buttons.
  if (ButtonA.update()) {
    MidiOut.sendCC(kChannelCC, 31, ButtonA.state_ ? 127 : 0); // CC#31
  }
  if (ButtonB.update()) {
    MidiOut.sendCC(kChannelCC, 30, ButtonB.state_ ? 127 : 0); // CC#30
  }
  // Knobs.
  if (KnobA.update()) {
    MidiOut.sendCC(kChannelCC, 32, KnobA.value_); // CC#32
  }
  if (KnobB.update()) {
    MidiOut.sendCC(kChannelCC, 33, KnobB.value_); // CC#33
  }
  if (KnobC.update()) {
    MidiOut.sendCC(kChannelCC, 34, KnobC.value_); // CC#34
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

