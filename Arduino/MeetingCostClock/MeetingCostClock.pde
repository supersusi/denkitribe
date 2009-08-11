#include <MsTimer2.h>

class CostCounter {
public:
  static const uint32_t kHourlyWage = 5000;
  static const uint32_t kNumAttendee = 3;
  static const uint32_t kFpCostPerSec = 0x100UL * kHourlyWage * kNumAttendee / (60UL * 60);
  static uint32_t fpCostTotal_;
  static void updateSecond() {
    fpCostTotal_ += kFpCostPerSec;
  }
  static uint32_t getCostTotal() {
    return fpCostTotal_ >> 8;
  }
};
uint32_t CostCounter::fpCostTotal_;

class Font {
public:
  static uint8_t getFontData(uint8_t radix, int8_t number, boolean dp) {
    // LED bit assignment
    //           7 6 5 4 3 2 1 0
    // Radix 1 - F A B P C G D E
    // Radix 2 - B A G F E D C P
    // Radix 3 - F A G B P C D E
    static const uint8_t fontData[3][10] = {
      {0xeb, 0x28, 0x67, 0x6e, 0xac, 0xce, 0xcf, 0xe8, 0xef, 0xee},
      {0xde, 0x82, 0xec, 0xe6, 0xb2, 0x76, 0x7e, 0xd2, 0xfe, 0xf6},
      {0xd7, 0x14, 0x73, 0x76, 0xb4, 0xe6, 0xe7, 0xd4, 0xf7, 0xf6}
    };
    static const uint8_t dpBits[3] = {0x10, 0x01, 0x08};
    uint8_t data = (number < 0) ? 0 : fontData[radix][number];
    if (dp) data |= dpBits[radix];
    return data;
  }
};


class Display {
public:
  static int8_t numbers_[3];
  static boolean points_[3];
  static uint8_t selector_;
  static void setNumbers(int8_t num1, boolean dp1,
                         int8_t num2, boolean dp2,
                         int8_t num3, boolean dp3) {
    numbers_[0] = num1;
    numbers_[1] = num2;
    numbers_[2] = num3;
    points_[0] = dp1;
    points_[1] = dp2;
    points_[2] = dp3;
  }
  static void refresh() {
      pinMode(10 + selector_, INPUT);
      selector_ = (selector_ == 2) ? 0 : selector_ + 1;
      
      uint8_t font = Font::getFontData(selector_,
                                       numbers_[selector_],
                                       points_[selector_]);
      
      for (uint8_t i = 0, bit = 1; i < 8; ++i, bit <<= 1) {
        if (font & bit) {
          pinMode(2 + i, OUTPUT);
        } else {
          pinMode(2 + i, INPUT);
        }
      }
      
      pinMode(10 + selector_, OUTPUT);
      delay(1);
  }
};
int8_t Display::numbers_[3];
boolean Display::points_[3];
uint8_t Display::selector_;

class ValueDisplay {
public:
  static void setValue(uint16_t value) {
    if (value < 10) {
      Display::setNumbers(value % 10, false, -1, false, -1, false);
    } else if (value < 100) {
      Display::setNumbers(value % 10, false, value % 100 / 10, false, -1, false);
    } else if (value < 1000) {
      Display::setNumbers(value % 10, false,
                          value % 100 / 10, false,
                          value % 1000 / 100, false);
    } else {
      Display::setNumbers(9, true, 9, true, 9, true);
    }
  }
  static void setTenThousandBase(uint32_t value) {
    if (value < 1000UL) {
      setValue(value);
    } else if (value < 100000UL) {
      uint16_t temp = value / 100;
      Display::setNumbers(temp % 10, false,
                          temp % 100 / 10, false,
                          temp % 1000 / 100, true);
    } else if (value < 1000000UL) {
      uint16_t temp = value / 1000;
      Display::setNumbers(temp % 10, false,
                          temp % 100 / 10, true,
                          temp % 1000 / 100, false);
    } else if (value < 10000000UL) {
      uint16_t temp = value / 10000;
      Display::setNumbers(temp % 10, false,
                          temp % 100 / 10, false,
                          temp % 1000 / 100, false);
    } else {
      Display::setNumbers(9, true, 9, true, 9, true);
    }
  }
};

void setup() {
  Serial.begin(9600);

  for (int i = 2; i < 10; ++i) {
    digitalWrite(i, LOW);
  }

  digitalWrite(10, HIGH);
  digitalWrite(11, HIGH);
  digitalWrite(12, HIGH);

  digitalWrite(14, HIGH);
  digitalWrite(15, HIGH);
  digitalWrite(16, HIGH);
  
  MsTimer2::set(1000, CostCounter::updateSecond);
  MsTimer2::start();
}

void loop() {
  Display::refresh();
  ValueDisplay::setTenThousandBase(CostCounter::getCostTotal());
}
