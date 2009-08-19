#include <LedControl.h>

// Used to handle an LED matrix as a screen
class DisplayBufferClass {
public:
  LedControl led_;     // MAX7219 controller

  int8_t rows_[3][8];  // screen (row) buffer
  int8_t selector_;    // layer selector
  
  DisplayBufferClass()
  : led_(2, 4, 3, 1),  // DIN, CLK, LOAD, cascading
    selector_(0) {
    clear();
  }
  
  void initialize() {
    led_.shutdown(0, false);
  }
  
  void clear() {
    for (int8_t layer = 0; layer < 3; ++layer) {
      for (int8_t row = 0; row < 8; ++row) {
        rows_[layer][row] = 0;
      }
    }
  }
  
  void setPixel(int8_t col, int8_t row, int8_t level) {
    if (level == 0) return;
    rows_[level - 1][row] |= (col == 0) ? 0x80 : 1 << (col - 1);
  }
  
  void update() {
    // darken the screen while update
    led_.setIntensity(0, 0);
    // update the screen
    for (int8_t row = 0; row < 8; ++row) {
      led_.setRow(0, row, rows_[selector_][row]);
    }
    // set the intensity
    if (selector_ == 1) {
      led_.setIntensity(0, 3);
    } else if (selector_ == 2) {
      led_.setIntensity(0, 15);
    }
    // advance the layer selector
    selector_ = (selector_ == 2) ? 0 : selector_ + 1;
    // minimum wait
    delay(1);
  }
};

DisplayBufferClass Display;

// 2D water surface simulator class
class WaterSurfaceClass {
public:
  static const int8_t kSize = 8;  // surface size (width and height)
  
  // surface height map type
  typedef int16_t HeightMap[kSize + 2][kSize + 2]; 

  HeightMap maps_[2];    // height maps
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
        h -= (h >> 5);
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
        if (h >= 1200) {
          Display.setPixel(x, y, 3);
        } else if (h >= 800) {
          Display.setPixel(x, y, 2);
        } else if (h >= 400) {
          Display.setPixel(x, y, 1);
        }
      }
    }
  }
};

WaterSurfaceClass Water;

void updateFrame() {
  Water.update();
  Water.display();
  for (int8_t i = 0; i < 6; ++i) {
    Display.update();
  }
}

void setup(){
  Display.initialize();
}

void loop(){
  int8_t x = random(8);
  int8_t y = random(8);
  
  Water.setHeight(x, y, 2000);
  updateFrame();
  Water.setHeight(x, y, 3000);
  updateFrame();
  Water.setHeight(x, y, 6000);
  updateFrame();
  Water.setHeight(x, y, 3000);
  updateFrame();
  Water.setHeight(x, y, 2000);
  updateFrame();
  
  for (int8_t i = 0; i < 100; ++i) {
    updateFrame();
  }
}

