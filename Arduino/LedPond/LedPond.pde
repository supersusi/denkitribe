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

// 2D water surface simulator class
class WaterSurfaceClass {
public:
  static const int8_t kSize = 8;  // surface size (width and height)
  
  // surface height map
  typedef int16_t HeightMap[kSize + 2][kSize + 2]; 

  HeightMap maps_[2];    // height maps (double buffer)
  int8_t selector_;      // index of the current height map
  
  WaterSurfaceClass()
  : selector_(0) {
    for (int8_t i = 0; i < 2; ++i) {
      for (int8_t y = 0; y < kSize + 2; ++y) {
        for (int8_t x = 0; x < kSize + 2; ++x) {
          maps_[i][y][x] = 0;
        }
      }
    }
  }
  
  void setHeight(int8_t x, int8_t y, int16_t h) {
    maps_[selector_][y + 1][x + 1] = h;
  }
  
  void update() {
    const HeightMap& front = maps_[selector_];
    HeightMap& back = maps_[selector_ ^ 1];
    
    for (int8_t y = 1; y < kSize + 1; ++y) {
      for (int8_t x = 1; x < kSize + 1; ++x) {
        int32_t h = front[y][x - 1] + front[y - 1][x] +
                    front[y][x + 1] + front[y + 1][x];
        h -= back[y][x] << 1;
        h -= (h >> 4);
        back[y][x] = h >> 1;
      }
    }
    
    selector_ ^= 1;
  }
  
  void display() const {
    Display.clear();
    const HeightMap& front = maps_[selector_];
    for (int8_t y = 0; y < kSize; ++y) {
      for (int8_t x = 0; x < kSize; ++x) {
        int16_t h = front[y + 1][x + 1];
        if (h >= 30 + (7 << 6)) {
          Display.write(x, y, 7);
        } else if (h > 30) {
          Display.write(x, y, ((h - 30) >> 6) & 7);
        }
      }
    }
  }
};

WaterSurfaceClass Water;

void updateFrame() {
  Water.update();
  Water.display();
  delay(20);
}

void setup(){
  Display.initialize();
}

void loop(){
  if (analogRead(0) > 2) {
    int8_t x = random(8);
    int8_t y = random(8);
    
    Water.setHeight(x, y, 4000);
    updateFrame();
    Water.setHeight(x, y, 6000);
    updateFrame();
    Water.setHeight(x, y, 4000);
    updateFrame();
    
    for (int8_t i = 0; i < 20; ++i) {
      updateFrame();
    }
  }
  updateFrame();
}

