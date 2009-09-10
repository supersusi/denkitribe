// Used to output midi signals.
class MidiOutClass {
public:
  void initialize() {
    Serial.begin(31250);
  }  
  void send(char cmd, char data1, char data2) {
    Serial.print(cmd, BYTE);
    Serial.print(data1, BYTE);
    Serial.print(data2, BYTE);
  }
};

// Global instance
MidiOutClass MidiOut;

