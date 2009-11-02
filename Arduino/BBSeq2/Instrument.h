class InstrumentClass {
public:
  static const int kVelocity = 100;
  
  const int channel_;
  int lastNoteNum_;
  
  InstrumentClass(int channel)
  : channel_(channel),
    lastNoteNum_(0) {}
  
  void sendNote(int pitchIndex) {
    endNote();
    if (pitchIndex > 0) {
      lastNoteNum_ = Scale.pickPitch(pitchIndex - 1);
      MidiOut.sendNoteOn(channel_, lastNoteNum_, kVelocity);
    } else {
      lastNoteNum_ = -1;
    }
  }
  
  void endNote() {
    if (lastNoteNum_ >= 0) {
      MidiOut.sendNoteOff(channel_, lastNoteNum_, kVelocity);
      lastNoteNum_ = -1;
    }
  }
};

