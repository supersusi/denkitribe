class Font {
public:
  static uint8_t getFontData(uint8_t radix, uint8_t decimal) {
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
    return fontData[radix][decimal];
  }
};


class Display {
public:
  static uint8_t decimals_[3];
  static uint8_t selector_;
  static void refresh() {
      pinMode(10 + selector_, INPUT);
      selector_ = (selector_ == 2) ? 0 : selector_ + 1;
      
      uint8_t font = Font::getFontData(selector_, decimals_[selector_]);
      
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
uint8_t Display::decimals_[3];
uint8_t Display::selector_;

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
}

void loop() {
  Display::refresh();
  int time = millis() / 50;
  Display::decimals_[0] = time % 10;
  Display::decimals_[1] = time % 100 / 10;
  Display::decimals_[2] = time % 1000 / 100;
}
