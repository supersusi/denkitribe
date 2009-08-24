#include <LedControl.h>
#include <TimerOne.h>

// LED Dislay class
//
// Used to handle an LED matrix as a display via MAX7219.
// You can specify the brightness level of each of the
// pixels individually (in seven levels).
//
// This class uses TIMER1 with TimerOne library.
class LedDisplayClass {
public:
  void initialize() {
    selector_ = 0;
    clear();
    // Start the timer
    Timer1.initialize(3164);
    // Timer1.initialize(3955);
    Timer1.attachInterrupt(refresh);
  }
  
  void clear() {
    for (int8_t layer = 0; layer < 7; ++layer) {
      for (int8_t line = 0; line < 8; ++line) {
        lines_[layer][line] = 0;
      }
    }
  }
  
  void write(int8_t col, int8_t row, int8_t level) {
    if (level > 0) {
      // I mistakenly soldered the DP pin to MSB,
      // so I have to rotate one bit.
      lines_[level - 1][col] |= 1 << ((row - 1) & 7);
    }
  }
  
private:
  static LedControl led_;      // MAX7219 driver
  static uint8_t lines_[7][8]; // 7 layers x 8 lines
  static int8_t selector_;     // layer selector

  static void refresh() {
    // Shutdown the screen while update
    led_.shutdown(0, true);
    // Update the screen
    for (int8_t line = 0; line < 8; ++line) {
      led_.setRow(0, line, lines_[selector_][line]);
    }
    // Set new intensity
    static const int8_t tonemap[7] = {0, 1, 2, 3, 6, 10, 15};
    led_.setIntensity(0, tonemap[selector_]);
    // Turn on the screen
    led_.shutdown(0, false);
    // Advance the layer selector
    selector_ = (selector_ == 6) ? 0 : selector_ + 1;
  }
};

LedControl LedDisplayClass::led_(2, 4, 3, 1); // DIN, CLK, LOAD
uint8_t LedDisplayClass::lines_[7][8];
int8_t LedDisplayClass::selector_;

LedDisplayClass Display;

void setup(){
  Display.initialize();
}

void loop(){
  static int8_t offs;
  Display.clear();
  for (int8_t row = 0; row < 8; ++row) {
    for (int8_t col = 0; col < 8; ++col) {
      if (row + col < 8) {
        Display.write(col, row, (row + col + offs) & 7);
      } else {
        Display.write(col, row, (14 - row - col + offs) & 7);
      }
    }
  }
  delay(500);
  offs++;
}

