// Used to observe a digital input device.
class DigitalInputClass {
public:
  static const int kDelayCount = 3;
  
  const int port_;
  boolean state_;
  int delay_;     // Delay counter (used to avoid chattering).
  
  DigitalInputClass(int port)
  : port_(port),
    state_(false),
    delay_(0) {
    pinMode(port_, INPUT);
    digitalWrite(port_, HIGH);  // Enable pull-up resistor.
  }
  
  boolean update() {
    boolean input = (digitalRead(port_) == LOW);
    if (input != state_) {
      if (++delay_ == kDelayCount) {
        state_ = input;
        delay_ = 0;
        return true;
      }
    } else {
      delay_ = 0;
    }
    return false;
  }
};

// Used to observe an analog input device.
template <class _DerivedClass>
class AnalogInputClass {
public:
  const int port_;
  int value_;  // Current value.
  int sign_;   // Sign of difference.
  
  AnalogInputClass(int port)
  : port_(port),
    value_(0),
    sign_(true) {
    update();
  }
  
  boolean update() {
    int input = _DerivedClass::convertInput(analogRead(port_));
    // Check the difference.
    if (input == value_) return false;
    // Update the status.
    boolean sign = (input - value_) > 0;
    boolean modFlag = (sign == sign_);
    value_ = input;
    sign_ = sign;
    return modFlag;
  }
};

