#include <MsTimer2.h>

// LED pattern generator class
class LedPattern {
public:
  // * LED bit assignment
  //           7 6 5 4 3 2 1 0
  // digit 1 - F A B P C G D E
  // digit 2 - B A G F E D C P
  // digit 3 - F A G B P C D E

  // Spacial characters
  static const uint8_t kCharBlank  = 10;
  static const uint8_t kCharUscore = 11;
  // Attribute flgas
  static const uint8_t kAttrDP     = 0x10;  // add a decimal point
  static const uint8_t kAttrBlink  = 0x20;
  // Counter for blinking
  uint8_t blinker_;

  LedPattern() {
    blinker_ = 0;
  }
  // generate a bit pattern for a digit
  uint8_t getBitPattern(uint8_t pos, uint8_t ch) {
    static const uint8_t digitBits[3][16] = {
      {0xeb, 0x28, 0x67, 0x6e, 0xac, 0xce, 0xcf, 0xe8, 0xef, 0xee, 0, 0x2},
      {0xde, 0x82, 0xec, 0xe6, 0xb2, 0x76, 0x7e, 0xd2, 0xfe, 0xf6, 0, 0x4},
      {0xd7, 0x14, 0x73, 0x76, 0xb4, 0xe6, 0xe7, 0xd4, 0xf7, 0xf6, 0, 0x2}
    };
    static const uint8_t dpBits[3] = {0x10, 0x01, 0x08};
    // blinking
    if ((ch & kAttrBlink) && (blinker_ & 1)) return 0;
    // generate a pattern
    uint8_t pattern = digitBits[pos][ch & 0xf];
    if (ch & kAttrDP) pattern |= dpBits[pos];
    return pattern;
  }
  // Timer tick function
  void tick() {
    blinker_++;
  }
};
LedPattern ledPattern;

// Display controller class
class Display {
public:
  static const uint8_t kCathodePin = 2;
  static const uint8_t kAnodePin = 10;

  uint8_t digits_[3];
  uint8_t selector_;

  Display() {
    digits_[0] = digits_[1] = digits_[2] = 0;
    selector_ = 0;
  }
  // initialize the output device
  void initialize() {
    for (uint8_t i = 0; i < 8; ++i) {
      digitalWrite(kCathodePin + i, LOW);
    }
    for (uint8_t i = 0; i < 3; ++i) {
      digitalWrite(kAnodePin + i, HIGH);
    }
  }
  // set the digits individually
  void setDigits(uint8_t digit1, uint8_t digit2, uint8_t digit3) {
    digits_[0] = digit1;
    digits_[1] = digit2;
    digits_[2] = digit3;
  }
  // set a numeric value to the display
  void setValue(uint16_t value) {
    if (value < 10) {
      setDigits(value % 10, LedPattern::kCharBlank, LedPattern::kCharBlank);
    } 
    else if (value < 100) {
      setDigits(value % 10, value % 100 / 10, LedPattern::kCharBlank);
    } 
    else if (value < 1000) {
      setDigits(value % 10, value % 100 / 10, value % 1000 / 100);
    } 
    else {
      setDigits(9 | LedPattern::kAttrBlink,
                9 | LedPattern::kAttrBlink,
                9 | LedPattern::kAttrBlink);
    }
  }
  // set a numeric value and show as the cost
  void setCostValue(uint32_t value) {
    if (value < 100UL) {
      setDigits(value % 10, value % 100 / 10, LedPattern::kCharUscore);
    } 
    else if (value < 100000UL) {
      uint16_t temp = value / 100;
      setDigits(temp % 10, temp % 100 / 10, temp % 1000 / 100 | LedPattern::kAttrDP);
    } 
    else if (value < 1000000UL) {
      uint16_t temp = value / 1000;
      setDigits(temp % 10, temp % 100 / 10 | LedPattern::kAttrDP, temp % 1000 / 100);
    } 
    else if (value < 10000000UL) {
      uint16_t temp = value / 10000;
      setDigits(temp % 10, temp % 100 / 10, temp % 1000 / 100);
    } 
    else {
      setDigits(9 | LedPattern::kAttrBlink,
                9 | LedPattern::kAttrBlink,
                9 | LedPattern::kAttrBlink);
    }
  }
  // refresh function
  void refresh() {
    // turn off the selected digit
    pinMode(kAnodePin + selector_, INPUT);
    // advance the selector
    selector_ = (selector_ == 2) ? 0 : selector_ + 1;
    // generate a pattern for the selected digit
    uint8_t pattern = ledPattern.getBitPattern(selector_, digits_[selector_]);
    // switch the LEDs
    for (uint8_t i = 0, bit = 1; i < 8; ++i, bit <<= 1) {
      pinMode(kCathodePin + i, (pattern & bit) ? OUTPUT : INPUT);
    }
    // turn on the selected digit
    pinMode(kAnodePin + selector_, OUTPUT);
    // minimum wait
    delay(1);
  }
};
Display display;

// Cost counter class
class CostCounter {
public:
  // these values are stored as fixed point number (8 bit fractinal)
  uint32_t fpCostPerSec_;  // cost per second
  uint32_t fpTotalCost_;   // total cost
  // initialization
  void initialize(uint32_t hourlyWage, uint32_t numAttendee) {
    fpCostPerSec_ = 0x100UL * hourlyWage * numAttendee / (60UL * 60);
    fpTotalCost_ = 0;
  }
  // advance one second
  void advanceSecond() {
    fpTotalCost_ += fpCostPerSec_;
  }
  // get the total cost value
  uint32_t getTotalCost() const {
    return fpTotalCost_ >> 8;
  }
};
CostCounter costCounter;

// Timer management class
class Timer {
public:
  // initialization
  void initialize() {
    MsTimer2::set(250, Timer::tick);
  }
  // start the timer
  void start() {
    MsTimer2::start();
  }
  // stop the timer
  void stop() {
    MsTimer2::stop();
  }
  // timer tick function
  static void tick() {
    static uint8_t s_counter;
    ledPattern.tick();
    if (s_counter == 3) {
      costCounter.advanceSecond();
      digitalWrite(13, HIGH);
    } 
    else {
      digitalWrite(13, LOW);
    }
    s_counter = (s_counter + 1) & 3;
  }
};
Timer timer;

void setup() {
  digitalWrite(14, HIGH);
  digitalWrite(15, HIGH);
  digitalWrite(16, HIGH);
  display.initialize();
  costCounter.initialize(5000, 6);
  timer.initialize();
  timer.start();
}

void loop() {
  display.refresh();
  display.setCostValue(costCounter.getTotalCost());
}
