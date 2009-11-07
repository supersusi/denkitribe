#ifndef _MIDI_OUT_H_
#define _MIDI_OUT_H_

// Set one to debug in serial monitor.
#define MIDI_OUT_DEBUG 1

// Used to output midi signals.
class MidiOutClass {
public:
  void initialize() {
#if MIDI_OUT_DEBUG
    Serial.begin(9600);
#else
    Serial.begin(31250);
#endif
  }  
  void sendChannelMessage(int channel, char stat, char data1, char data2) {
#if MIDI_OUT_DEBUG
    Serial.print("Ch");
    Serial.print(channel);
    Serial.print(':');
    Serial.print(stat, DEC);
    Serial.print(',');
    Serial.print(data1, DEC);
    Serial.print(',');
    Serial.println(data2, DEC);
#else
    Serial.write((stat << 4) + channel);
    Serial.write(data1);
    Serial.write(data2);
#endif
  }
  void sendNoteOn(int channel, int pitch, int velocity) {
    sendChannelMessage(channel, 0x9, pitch, velocity);
  }
  void sendNoteOff(int channel, int pitch, int velocity) {
    sendChannelMessage(channel, 0x8, pitch, velocity);
  }
  void sendCC(int channel, int num, int value) {
    sendChannelMessage(channel, 0xb, num, value);
  }
  void sendReset(int channel) {
    sendChannelMessage(channel, 0xb, 0x7b, 0);
    sendChannelMessage(channel, 0xb, 0x79, 0);
    sendChannelMessage(channel, 0xb, 0x78, 0);
    sendChannelMessage(channel, 0xe, 0, 0x40);
  }
  void sendClock() {
#if not(MIDI_OUT_DEBUG)
    Serial.write(0xf8);
#endif
  }
  void sendStart() {
#if MIDI_OUT_DEBUG
    Serial.println("Start");
#else
    Serial.write(0xfa);
#endif
  }
  void sendStop() {
#if MIDI_OUT_DEBUG
    Serial.println("Stop");
#else
    Serial.write(0xfc);
#endif
  }
};

// Global instance.
MidiOutClass MidiOut;

#endif // _MIDI_OUT_H_

