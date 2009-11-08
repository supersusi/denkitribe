#ifndef FILTERED_INPUT_H
#define FILTERED_INPUT_H

class FilteredInputClass {
public:
  void init(int select, int minInput, int maxInput) {
    select_ = select;
    minInput_ = minInput;
    maxInput_ = maxInput;
    reset();
  }
  
  void reset() {
    value_ = 0;
    modified_ = false;
    accum_ = 0;
    sampleCount_ = 0;
  }
  
  boolean isModified() const {
    return modified_;
  }

  int getValue() const {
    return value_;
  }

  void update() {
    modified_ = false;
    doSample();
    if (sampleCount_ == (1 << kWindowSize)) {
      int value = 128L * ((accum_ >> kWindowSize) - minInput_) / (maxInput_ - minInput_);
      value = value > 127 ? 127 : (value < 0 ? 0 : value);
      if (value != value_) {
        modified_ = true;
        value_ = value;
      }
      accum_ = 0;
      sampleCount_ = 0;
    }
  }

private:
  static const int kWindowSize = 4;
  
  int select_;
  int minInput_;
  int maxInput_;
  
  int value_;
  boolean modified_;
  
  int accum_;
  int sampleCount_;

  void doSample() {
    if (select_ < 8) {
      digitalWrite(7, (select_ & 1) ? HIGH : LOW);
      digitalWrite(8, (select_ & 2) ? HIGH : LOW);
      digitalWrite(9, (select_ & 4) ? HIGH : LOW);
      delayMicroseconds(100);
      accum_ += analogRead(3);
    } else {
      accum_ += analogRead(select_ - 8);
    }
    sampleCount_++;
  }
};

#endif // FILTERED_INPUT_H

