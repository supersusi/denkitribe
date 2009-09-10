// Used to handle the indicator LED.
class IndicatorClass {
public:
  static const int8_t kPin = 9;
  
  void initialize() {
    pinMode(kPin, OUTPUT);
  }
  
  void update(int16_t intensity) {
    uint8_t phase_ = (intensity >> 2);
    if (phase_ < 128) {
      analogWrite(kPin, phase_);
    } else {
      analogWrite(kPin, 255 - phase_);
    }
  }
};

IndicatorClass Indicator;


