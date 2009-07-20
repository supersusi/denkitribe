#include <avr/pgmspace.h>
#include <TimerOne.h>
#include "Sequence.h"

// BPM - You can modify this value.
const uint16_t kBpm = 120;

// MIDI output device driver (allstatic)
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
  static void sendReset() {
    Serial.print(0xb0, BYTE);
    Serial.print(0x78, BYTE);
    Serial.print(0x00, BYTE);
  }
  static void sendClock() {
    Serial.print(0xf8, BYTE);
  }
};

// pattern selector device driver (allstatic)
class Selector {
public:
  static const uint8_t kFirstPin = 2;
  static void initialize() {
    pinMode(kFirstPin + 0, INPUT);
    pinMode(kFirstPin + 1, INPUT);
    pinMode(kFirstPin + 2, INPUT);
  }
  static int getIndex() {
    return (digitalRead(kFirstPin + 0) ? 0 : 1) +
           (digitalRead(kFirstPin + 1) ? 0 : 2) +
           (digitalRead(kFirstPin + 2) ? 0 : 4);
  }
};

// pattern sequencer class
class Sequencer {
public:
  uint16_t m_offset;  // offset to the current event
  uint8_t m_delta;    // delta step value from the previous event
  // constructor
  Sequencer() {
    resetPattern();
    m_delta = 0;
  }
  // reset and start the next pattern
  void resetPattern() {
    m_offset = startPoints[Selector::getIndex()];
  }
  // process the events on the current timestep
  void doStep() {
    m_delta++;
    while (true) {
      uint8_t delta  = pgm_read_byte_near(sequenceData + m_offset);
      // terminate the current pattern if delta == 0xff
      if (delta == 0xff) {
        resetPattern();
        continue;
      }
      // sufficient time has passed?
      if (delta > m_delta) return;
      m_delta -= delta;
      // process this event
      m_offset++;
      MidiOut::sendMessage(pgm_read_byte_near(sequenceData + m_offset++),
                           pgm_read_byte_near(sequenceData + m_offset++),
                           pgm_read_byte_near(sequenceData + m_offset++));
    }
  }
};

// the global instance of pattern sequencer
Sequencer sequencer;

// MIDI clock driver (allstatic)
class Clock {
public:
  static void initialize() {
    Timer1.initialize(60UL * 1000 * 1000 / (kBpm * 24));
    Timer1.attachInterrupt(tick);
  }
  static void tick() {
    static int interval;
    MidiOut::sendClock();
    if (interval == 0) {
      sequencer.doStep();
      interval = 6;
    }
    interval--;
  }
};

// event handlers
void setup() {
  MidiOut::initialize();
  MidiOut::sendReset();
  Selector::initialize();
  Clock::initialize();
}
void loop() {}
