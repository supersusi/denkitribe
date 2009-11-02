class InstrumentClass {
public:
  static const int kVelocity = 100;
  
  const int channel_;
  int lastNoteNum_;
  
  InstrumentClass(int channel)
  : channel_(channel),
    lastNoteNum_(0) {}
  
  void sendNote(int pitchIndex, boolean tieMode = false) {
    if (pitchIndex > 0) {
      int noteNum = Scale.pickPitch(pitchIndex - 1);
      if (!tieMode || noteNum != lastNoteNum_) {
        endNote();
        MidiOut.sendNoteOn(channel_, noteNum, kVelocity);
        lastNoteNum_ = noteNum;
      }
    } else {
      endNote();
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

