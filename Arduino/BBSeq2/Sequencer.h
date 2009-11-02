class SequencerClass {
public:
  const int numPitch_;    // Number of the pitch lines.
  const int inputPort_;   // Analog input port number.
  const int muxPort0_;    // Digital output port numbers for control the mux.
  const int muxPort1_;
  const int muxPort2_;
  const int muxPort3_;
  
  int length_;     // Length of the sequence (modifiable).
  int stepPos_;    // Position of the current step.
  
  SequencerClass(int numPitch, int inputPort,
                 int muxPort0, int muxPort1, int muxPort2, int muxPort3)
  : numPitch_(numPitch),
    inputPort_(inputPort),
    muxPort0_(muxPort0),
    muxPort1_(muxPort1),
    muxPort2_(muxPort2),
    muxPort3_(muxPort3),
    length_(16),
    stepPos_(0) {
    pinMode(muxPort0_, OUTPUT);
    pinMode(muxPort1_, OUTPUT);
    pinMode(muxPort2_, OUTPUT);
    pinMode(muxPort3_, OUTPUT);
  }
  
  void reset() {
    stepPos_ = 0;
  }
  
  int fetchNote() {
    int pitchIndex = 0;
    if (stepPos_ < 16) {
      int select = 15 - stepPos_;
      digitalWrite(muxPort0_, (select & 1) ? HIGH : LOW);
      digitalWrite(muxPort1_, (select & 2) ? HIGH : LOW);
      digitalWrite(muxPort2_, (select & 4) ? HIGH : LOW);
      digitalWrite(muxPort3_, (select & 8) ? HIGH : LOW);
      delayMicroseconds(50);
      analogRead(inputPort_); // Dummy read
      pitchIndex = (analogRead(inputPort_) * numPitch_ + 512) >> 10;
    }
    if (++stepPos_ >= length_) stepPos_ = 0;
    return pitchIndex;
  }
};

