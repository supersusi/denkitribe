#include <avr/pgmspace.h>
#include <TimerOne.h>
#include "Sequence.h"

// BPM - You can modify this value
const uint16_t kBpm = 128;

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
  static const uint8_t kFirstPin_ = 2;
  static void initialize() {
    pinMode(kFirstPin_ + 0, INPUT);
    pinMode(kFirstPin_ + 1, INPUT);
  }
  static int getIndex() {
    return (digitalRead(kFirstPin_ + 0) ? 0 : 1) +
           (digitalRead(kFirstPin_ + 1) ? 0 : 2);
  }
};

// Pattern sequencer class
class Sequencer {
public:
  uint16_t offset_;    // Offset to the current event
  uint8_t delta_;      // Delta step value from the previous event
  // Constructor
  Sequencer() {
    resetPattern();
    delta_ = 0;
  }
  // Reset and start the next pattern
  void resetPattern() {
    offset_ = startPoints[Selector::getIndex()];
  }
  // Start playing
  void start() {
    resetPattern();
    delta_ = 0;
    MidiOut::sendStart();
  }
  // Stop playing
  void stop() {
    MidiOut::sendStop();
    MidiOut::sendAllNoteOff();
  }
  // Process the events on the current timestep
  void doStep() {
    delta_++;
    while (true) {
      uint8_t delta  = pgm_read_byte_near(sequenceData + offset_);
      // Terminate the current pattern if delta == 0xff
      if (delta == 0xff) {
        resetPattern();
        continue;
      }
      // Sufficient time has passed?
      if (delta > delta_) return;
      delta_ -= delta;
      // Process this event
      offset_++;
      MidiOut::sendMessage(pgm_read_byte_near(sequenceData + offset_++),
                           pgm_read_byte_near(sequenceData + offset_++),
                           pgm_read_byte_near(sequenceData + offset_++));
    }
  }
};

// The global instance of the pattern sequencer
Sequencer sequencer;

// Indicator driver (allstatic)
class Indicator {
public:
  static const uint8_t kPin_ = 5;
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
    noteInterval_ = 0;
    beatInterval_ = 0;
    firstClock_ = true;
    Timer1.initialize(60UL * 1000 * 1000 / (kBpm * 24));
    Timer1.attachInterrupt(tick);
  }
  // Stop the clock
  static void stop() {
    Timer1.detachInterrupt();
    Indicator::setLight(false);
  }
  // Handler for the timer interruption
  static void tick() {
    // Send a clock signal except the first clock
    if (firstClock_) {
      firstClock_ = false;
    } else {
      MidiOut::sendClock();
    }
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
  static const uint8_t kPin_ = 4;
  static const uint8_t kDelay_ = 60;
  static uint8_t offCount_;
  static void initialize() {
    pinMode(kPin_, INPUT);
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
