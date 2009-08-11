#include <MsTimer2.h>

// ** You can modify these value **
class Config {
public:
  // average of hourly wage of your company
  static const int kHourlyWage = 5000;
  // default number of attendee of meetings
  static const int kDefaultAttendee = 5;
};

// Used to generate a bit pattern with a given character.
// This also processes blinking animation.
class LEDCharClass {
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
  static const uint8_t kAttrDP     = 0x10;  // decimal point
  static const uint8_t kAttrBlink  = 0x20;
  
  int8_t flasher_;

  LEDCharClass() {
    flasher_ = 0;
  }
  
  uint8_t getBits(int8_t pos, uint8_t ch) const {
    // blinking
    if ((ch & kAttrBlink) && (flasher_ & 1)) return 0;
    // character
    static const uint8_t charPatterns[3][16] = {
      {0xeb, 0x28, 0x67, 0x6e, 0xac, 0xce, 0xcf, 0xe8, 0xef, 0xee, 0, 0x2},
      {0xde, 0x82, 0xec, 0xe6, 0xb2, 0x76, 0x7e, 0xd2, 0xfe, 0xf6, 0, 0x4},
      {0xd7, 0x14, 0x73, 0x76, 0xb4, 0xe6, 0xe7, 0xd4, 0xf7, 0xf6, 0, 0x2}
    };
    uint8_t bits = charPatterns[pos][ch & 0xf];
    // decimal point
    if (ch & kAttrDP) {
      static const uint8_t dpPatterns[3] = {0x10, 0x01, 0x08};
      bits |= dpPatterns[pos];
    }
    return bits;
  }
  
  void onTick() {
    flasher_++;
  }
};

LEDCharClass LEDChar;

// Used to controlls the display via digital output pins.
class DisplayClass {
public:
  static const int8_t kCathodePin = 2;  // the first cathode pin
  static const int8_t kAnodePin = 10;   // the first anode pin

  uint8_t digits_[3];  // digit buffer
  int8_t refresher_;   // refresh counter

  void initialize() {
    digits_[0] = digits_[1] = digits_[2] = 0;
    refresher_ = 0;
    for (int8_t i = 0; i < 8; ++i) {
      digitalWrite(kCathodePin + i, LOW);
    }
    for (int8_t i = 0; i < 3; ++i) {
      digitalWrite(kAnodePin + i, HIGH);
    }
  }
  
  // Set the digits individually
  void setDigits(uint8_t digit1, uint8_t digit2, uint8_t digit3) {
    digits_[0] = digit1;
    digits_[1] = digit2;
    digits_[2] = digit3;
  }
  
  // Show a numerical value on the display
  void showNumber(int16_t num, uint8_t attr = 0) {
    if (num < 10) {
      setDigits(num % 10 | attr, LEDChar.kCharBlank, LEDChar.kCharBlank);
    } 
    else if (num < 100) {
      setDigits(num % 10 | attr, num % 100 / 10 | attr, LEDChar.kCharBlank);
    } 
    else if (num < 1000) {
      setDigits(num % 10 | attr, num % 100 / 10 | attr, num % 1000 / 100 | attr);
    } 
    else {
      uint8_t ch = 9 | LEDChar.kAttrBlink;
      setDigits(ch, ch, ch);
    }
  }
  
  // Show an amount of money on the display
  void showBill(int32_t num) {
    if (num < 100L) {
      setDigits(num % 10, num % 100 / 10, LEDChar.kCharUscore);
    } 
    else if (num < 10L * 10000) {
      int16_t temp = num / 100;
      setDigits(temp % 10, temp % 100 / 10, (temp % 1000 / 100) | LEDChar.kAttrDP);
    } 
    else if (num < 100L * 10000) {
      int16_t temp = num / 1000;
      setDigits(temp % 10, (temp % 100 / 10) | LEDChar.kAttrDP, temp % 1000 / 100);
    } 
    else if (num < 1000L * 10000) {
      int16_t temp = num / 10000;
      setDigits(temp % 10, temp % 100 / 10, temp % 1000 / 100);
    } else {
      uint8_t ch = 9 | LEDChar.kAttrBlink;
      setDigits(ch, ch, ch);
    }
  }
  
  void onRefresh() {
    // turn off the selected digit
    pinMode(kAnodePin + refresher_, INPUT);
    // advance the refresher
    refresher_ = (refresher_ == 2) ? 0 : refresher_ + 1;
    // generate a pattern for the selected digit
    uint8_t pattern = LEDChar.getBits(refresher_, digits_[refresher_]);
    // switch the LEDs
    for (uint8_t i = 0, bit = 1; i < 8; ++i, bit <<= 1) {
      pinMode(kCathodePin + i, (pattern & bit) ? OUTPUT : INPUT);
    }
    // turn on the selected digit
    pinMode(kAnodePin + refresher_, OUTPUT);
    // minimum wait
    delay(1);
  }
};

DisplayClass Display;

// Used to sum up the cost of meeting.
class CostCounterClass {
public:
  int8_t numAttendee_;    // number of attendee of the meeting

  // these values are stored as a fixed point number (8 bit fractinal)
  int32_t fpCostPerSec_;  // cost per second
  int32_t fpTotalCost_;   // total cost

  void initialize() {
    numAttendee_ = Config::kDefaultAttendee;
    recalcCostPerSec();
    reset();
  }
  void reset() {
    fpTotalCost_ = 0;
  }
  void recalcCostPerSec() {
    fpCostPerSec_ = 0x100L * Config::kHourlyWage * numAttendee_ / (60 * 60);
  }

  int32_t getTotalCost() const {
    return fpTotalCost_ >> 8;
  }

  void incAttendee() {
    numAttendee_++;
    recalcCostPerSec();
  }
  void decAttendee() {
    if (numAttendee_ > 0) {
      numAttendee_--;
      recalcCostPerSec();
    }
  }

  void advanceSecond() {
    fpTotalCost_ += fpCostPerSec_;
  }
};

CostCounterClass CostCounter;

// Used to controll the timer device and receive timer events.
class TimerClass {
public:
  static boolean running_;
  static int8_t prescaler_;

  void initialize() {
    running_ = false;
    prescaler_ = 0;
    MsTimer2::set(100, onTick);
    MsTimer2::start();
  }

  void start() {
    running_ = true;
    digitalWrite(13, HIGH);
  }
  void stop() {
    running_ = false;
    prescaler_ = 0;
  }

  static void onTick() {
    LEDChar.onTick();
    if (prescaler_ == 9) {
      CostCounter.advanceSecond();
      digitalWrite(13, HIGH);
      prescaler_ = 0;
    } else {
      digitalWrite(13, LOW);
      if (running_) prescaler_++;
    }
  }
};

boolean TimerClass::running_;
int8_t TimerClass::prescaler_;

TimerClass Timer;

// Receives and processes start and stop button events.
class StartStopControllerClass {
public:
  static const int8_t kButtonPin = 16;
  static const int32_t kHoldTime = 1500;

  int32_t timeButtonDown_;   // time when the button was pressed down
  boolean running_;          // true while the counter is running

  void initialize() {
    digitalWrite(kButtonPin, HIGH);
    timeButtonDown_ = 0;
    running_ = false;
  }
  
  void update() {
    boolean button = (digitalRead(kButtonPin) == LOW);

    if (button) {
      if (timeButtonDown_ == 0) {
        timeButtonDown_ = millis();
      } else if (millis() - timeButtonDown_ >= kHoldTime) {
        if (running_) {
          Timer.stop();
          running_ = false;
        }
        CostCounter.reset();
      }
    } else if (timeButtonDown_ > 0) {
      if (millis() - timeButtonDown_ < kHoldTime) {
        if (running_) Timer.stop(); else Timer.start();
        running_ = !running_;
      }
      timeButtonDown_ = 0;
    }
  }
};

StartStopControllerClass StartStopController;

// Receives and processes increment/decrement button events.
class IncDecControllerClass {
public:
  static const int8_t kDecButtonPin = 14;
  static const int8_t kIncButtonPin = 15;
  static const int32_t kDisplayDuration = 1500;

  boolean prevDecButton_;  // previous state of input devices
  boolean prevIncButton_;
  int32_t timeDisplay_;    // time when display begins

  void initialize() {
    digitalWrite(kDecButtonPin, HIGH);
    digitalWrite(kIncButtonPin, HIGH);
    prevDecButton_ = false;
    prevIncButton_ = false;
    timeDisplay_ = 0;
  }
  
  boolean isModified() const {
    return millis() - timeDisplay_ < kDisplayDuration;
  }
  
  void update() {
    boolean decButton = (digitalRead(kDecButtonPin) == LOW);
    boolean incButton = (digitalRead(kIncButtonPin) == LOW);

    if (decButton && !prevDecButton_) {
      // increment
      CostCounter.incAttendee();
      timeDisplay_ = millis();
    } else if (incButton && !prevIncButton_) {
      // decrement
      CostCounter.decAttendee();
      timeDisplay_ = millis();
    }

    if (timeDisplay_ > 0 && millis() - timeDisplay_ >= kDisplayDuration) {
      timeDisplay_ = 0;
    }

    prevDecButton_ = decButton;
    prevIncButton_ = incButton;
  }
};

IncDecControllerClass IncDecController;

void setup() {
  Display.initialize();
  CostCounter.initialize();
  Timer.initialize();
  StartStopController.initialize();
  IncDecController.initialize();
}

void loop() {
  StartStopController.update();
  IncDecController.update();
  
  if (IncDecController.isModified()) {
    Display.showNumber(CostCounter.numAttendee_, LEDChar.kAttrBlink);
  } else {
    Display.showBill(CostCounter.getTotalCost());
  }
  
  Display.onRefresh();
}
