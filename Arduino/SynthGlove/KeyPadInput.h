// Used to handle a key pad unit of Power Glove.
class KeyPadInputClass {
public:
  static const int8_t kInputPin = 2; // to 74hc165 output pin
  static const int8_t kClockPin = 3; // to 74hc165 clock pin
  static const int8_t kLoadPin = 4;  // to 74hc165 load pin
  static const int8_t kGroupSelectPin = 6; // to pull-down lines
  
  uint8_t raw_[3];
  
  void initialize() {
    pinMode(kInputPin, INPUT);
    pinMode(kClockPin, OUTPUT);
    pinMode(kLoadPin, OUTPUT);
    
    for (int8_t group = 0; group < 3; ++group) {
      raw_[group] = 0;
      // enable high impedance state
      pinMode(kGroupSelectPin + group, INPUT);
    }
  }
  
  uint8_t getRawValue(int8_t group) const {
    return raw_[group];
  }
  
  void update() {
    for (int group = 0; group < 3; ++group) {
      int8_t pullDownPin = kGroupSelectPin + group;
      uint8_t raw = 0;
      // enable pull-down state
      pinMode(pullDownPin, OUTPUT);
      // load key pad status to the shift register
      digitalWrite(kLoadPin, LOW);
      digitalWrite(kLoadPin, HIGH);
      // read the bits from the shift register
      for (int i = 0; i < 8; ++i) {
        if (digitalRead(kInputPin) == LOW) {
          raw |= 1 << i;
        }
        // send a clock to the shift register
        digitalWrite(kClockPin, HIGH);
        digitalWrite(kClockPin, LOW);
      }
      // enable high impedance state
      pinMode(pullDownPin, INPUT);
      // update the value
      raw_[group] = raw;
    }
  }
};

// Global instance
KeyPadInputClass KeyPad;

