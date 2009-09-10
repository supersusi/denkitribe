// Used to handle finger bend sensors.
class FingerInputClass {
public:
  static const int8_t kInputPin = 0;
  static const int8_t kSelectPin = 10;
  
  int16_t raw_[4];         // raw sensor value (0 - 1023)
  int16_t normalized_[4];  // normalized value (0 - 127)
  int16_t delta_[4];       // difference of normalized value
  
  void initialize() {
    for (int8_t i = 0; i < 4; ++i) {
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
    static const int16_t rangeMin[] = {370, 300, 300, 350};
    static const int16_t rangeMax[] = {420, 370, 410, 520};
     static const int16_t kThreshold = 100;
    
    for (int8_t i = 0; i < 4; ++i) {
      // supply voltage to the i-th finger
      int8_t pin = kSelectPin + i;
      pinMode(pin, OUTPUT);
      digitalWrite(pin, HIGH);
      // read the sensor 
      int16_t raw = analogRead(kInputPin);
      if (raw > kThreshold) {
        // apply low-pass filter to raw input value
        raw_[i] = (raw_[i] + raw) >> 1;
        // normalization
        int16_t temp = (raw_[i] - rangeMin[i]) << 6;
        temp = (temp / (rangeMax[i] - rangeMin[i])) << 1;
        temp = constrain(128 - temp, 0, 127);
        // update the normalized values
        delta_[i] = temp - normalized_[i];
        normalized_[i] = temp;
      } else {
        delta_[i] = 0;
      }
      // shutdown the ovltage supply
      digitalWrite(pin, LOW);
      pinMode(pin, INPUT);
    }
  }
};

// Global instance
FingerInputClass Finger;

