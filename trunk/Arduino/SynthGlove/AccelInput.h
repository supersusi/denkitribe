// Used to read accelerometers.
class AccelInputClass {
public:
  static const int8_t kInputPin = 1;

  int16_t raw_[3];         // raw input value (0 - 1023)
  int16_t normalized_[3];  // normalized value (0 - 127)
  int16_t delta_[3];       // difference of normalized value

  void initialize() {
    for (int8_t i = 0; i < 3; ++i) {
      raw_[i] = normalized_[i] = delta_[i] = 0;
    }
  }
  
  int16_t getRawValue(int8_t i) const {
    return raw_[i];
  }
  
  int16_t getValue(int8_t i) const {
    return normalized_[i];
  }
  
  int16_t getDelta(int8_t i) const {
    return delta_[i];
  }

  void update() {
    static const int16_t offs[] = {512, 512, 580}; // +0g offset value
    static const int16_t kThreshold = 100;
    
    for (int8_t i = 0; i < 3; ++i) {
      int16_t raw = analogRead(kInputPin + i);
      if (raw > kThreshold) {
        // apply low-pass filter to raw input value
        raw_[i] = (raw_[i] + raw) >> 1;
        // normalization
        int16_t temp = ((raw_[i] - offs[i]) << 6) / 200;
        temp = constrain(abs(temp) << 1, 0, 127);
        // update the normalized values
        delta_[i] = temp - normalized_[i];
        normalized_[i] = temp;
      } else {
        delta_[i] = 0;
      }
    }
  }
};

// Global instance
AccelInputClass Accel;

