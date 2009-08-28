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

MidiOutClass MidiOut;

class BendSensor {
public:
  static const int8_t kTrim = 20;
  
  const int8_t pin_;
  int8_t value_;
  boolean modified_;
  int16_t rangeMin_;
  int16_t rangeMax_;
  
  BendSensor(int8_t pin)
  : pin_(pin),
    value_(0),
    modified_(false),
    rangeMin_(600),
    rangeMax_(700) {
  }
  
  void update() {
    int16_t input = analogRead(pin_);
    int8_t newValue;
    
    if (input <= rangeMin_) {
      rangeMin_ = input;
      newValue = 0;
    } else if (input >= rangeMax_) {
      rangeMax_ = input;
      newValue = 127;
    } else {
      newValue = 128L * (input - rangeMin_ - kTrim) /
                 (rangeMax_ - rangeMin_ - 2 * kTrim);
      if (newValue > 127) newValue = 127;
      if (newValue < 0) newValue = 0;
    }
    
    if (newValue != value_) {
      value_ = newValue;
      modified_ = true;
    } else {
      modified_ = false;
    }
  }
};

BendSensor finger1(0);
BendSensor finger2(2);
BendSensor finger3(3);
BendSensor finger4(1);

void setup() {
  MidiOut.initialize();
}

void loop() {
  finger1.update();
  finger2.update();
  finger3.update();
  finger4.update();
  if (finger1.modified_) MidiOut.send(0xb0, 0x30, finger1.value_);
  if (finger2.modified_) MidiOut.send(0xb0, 0x31, finger2.value_);
  if (finger3.modified_) MidiOut.send(0xb0, 0x32, finger3.value_);
  if (finger4.modified_) MidiOut.send(0xb0, 0x33, finger4.value_);
  delay(50);
}

