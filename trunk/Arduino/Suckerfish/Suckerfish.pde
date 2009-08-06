#include <avr/pgmspace.h>
#include <TimerOne.h>
#include "Sequence.h"

// BPM - You can modify this value
const uint16_t kBpm = 130;

// MIDI output class (allstatic)
class MidiOut {
public:
  static void initialize() {
    Serial.begin(31250);
  }
  static void sendMessage(char status, char data1, char data2) {
    Serial.print(status, BYTE);
    Serial.print(data1, BYTE);
    Serial.print(data2, BYTE);
  }
  static void sendAllSoundOff() {
    Serial.print(0xb0, BYTE);
    Serial.print(0x78, BYTE);
    Serial.print(0x00, BYTE);
  }
  static void sendAllNoteOff() {
    Serial.print(0xb0, BYTE);
    Serial.print(0x7b, BYTE);
    Serial.print(0x00, BYTE);
  }
  static void sendClock() {
    Serial.print(0xf8, BYTE);
  }
  static void sendStart() {
    Serial.print(0xfa, BYTE);
  }
  static void sendStop() {
    Serial.print(0xfc, BYTE);
  }
};

// Pattern selector class (allstatic)
class Selector {
public:
  static const uint8_t kFirstPin_ = 4;
  static void initialize() {
    for (uint8_t i = 0; i < 4; ++i) {
      pinMode(kFirstPin_ + i, INPUT);
      digitalWrite(kFirstPin_ + i, HIGH);  // pull-up
    }
  }
  static int getIndex() {
    return (digitalRead(kFirstPin_ + 0) ? 1 : 0) +
           (digitalRead(kFirstPin_ + 1) ? 2 : 0) +
           (digitalRead(kFirstPin_ + 2) ? 4 : 0) +
           (digitalRead(kFirstPin_ + 3) ? 8 : 0);
  }
};

// Pattern sequencer class
class Sequencer {
public:
  uint16_t dataOffset_;  // Data offset to the current event
  uint8_t stepCount_;    // Step count from the previous event
  // Constructor
  Sequencer() {
    resetPattern();
    stepCount_ = 0;
  }
  // Reset and start the next pattern
  void resetPattern() {
    dataOffset_ = startPoints[Selector::getIndex()];
  }
  // Start playing
  void start() {
    resetPattern();
    stepCount_ = 0;
    MidiOut::sendStart();
    processEvent();
  }
  // Stop playing
  void stop() {
    MidiOut::sendStop();
    MidiOut::sendAllNoteOff();
  }
  // Advance the time and process events
  void doStep() {
    stepCount_ ++;
    processEvent();
  }
  // Process the events on the current timestep
  void processEvent() {
    while (true) {
      uint8_t delta = pgm_read_byte_near(sequenceData + dataOffset_);
      // Terminate the current pattern if delta == 0xff
      if (delta == 0xff) {
        resetPattern();
        continue;
      }
      // Sufficient time has passed?
      if (delta > stepCount_) return;
      stepCount_ -= delta;
      // Process this event
      dataOffset_++;
      MidiOut::sendMessage(pgm_read_byte_near(sequenceData + dataOffset_++),
                           pgm_read_byte_near(sequenceData + dataOffset_++),
                           pgm_read_byte_near(sequenceData + dataOffset_++));
    }
  }
};

// The global instance of the pattern sequencer
Sequencer sequencer;

// Indicator driver (allstatic)
class Indicator {
public:
  static const uint8_t kPin_ = 3;
  static void initialize() {
    pinMode(kPin_, OUTPUT);
  }
  static void setLight(boolean flag) {
    digitalWrite(kPin_, flag ? HIGH : LOW);
  }
};

// Clock driver (allstatic)
class Clock {
public:
  static uint8_t noteInterval_;  // Interval counter for note
  static uint8_t beatInterval_;  // Interval counter for beat
  static boolean firstClock_;    // True until the first clock
  // Start the clock
  static void start() {
    noteInterval_ = 5;
    beatInterval_ = 3;
    firstClock_ = true;
    Timer1.initialize(60UL * 1000 * 1000 / (kBpm * 24));
    Timer1.attachInterrupt(tick);
    Indicator::setLight(true);
    MidiOut::sendClock();
  }
  // Stop the clock
  static void stop() {
    Timer1.detachInterrupt();
    Indicator::setLight(false);
  }
  // Handler for the timer interruption
  static void tick() {
    // Ignore the first clock
    if (firstClock_) {
      firstClock_ = false;
      return;
    }
    // Send a clock
    MidiOut::sendClock();
    // Process the sequence
    if (noteInterval_ == 0) {
      sequencer.doStep();
      noteInterval_ = 6;
      // Process the indicator
      if (beatInterval_ == 0) {
        Indicator::setLight(true);
        beatInterval_ = 4;
      } else {
        Indicator::setLight(false);
      }
      beatInterval_--;
    }
    noteInterval_--;
  }
};
uint8_t Clock::noteInterval_;
uint8_t Clock::beatInterval_;
boolean Clock::firstClock_;

// Play switch interface (allstatic)
class PlaySwitch {
public:
  static const uint8_t kPin_ = 2;
  static const uint8_t kDelay_ = 60;
  static uint8_t offCount_;
  static void initialize() {
    pinMode(kPin_, INPUT);
    digitalWrite(kPin_, HIGH);  // pull-up
    offCount_ = 0;
  }
  static boolean update() {
    boolean result = false;
    if (digitalRead(kPin_)) {
      if (offCount_ < kDelay_) offCount_++;
    } else {
      if (offCount_ == kDelay_) {
        result = true;
      }
      offCount_ = 0;
    }
    return result;
  }
};
uint8_t PlaySwitch::offCount_;

// event handlers
void setup() {
  MidiOut::initialize();
  MidiOut::sendAllSoundOff();
  Selector::initialize();
  Indicator::initialize();
  PlaySwitch::initialize();
}
void loop() {
  static boolean playing = false;
  if (PlaySwitch::update()) {
    playing ^= true;
    if (playing) {
      sequencer.start();
      Clock::start();
    } else {
      Clock::stop();
      sequencer.stop();
    }
  }
}
