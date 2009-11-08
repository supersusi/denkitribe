#ifndef TRIGGER_H
#define TRIGGER_H

class TriggerClass {
public:
  void init(const FilteredInputClass* pInTrigger,
            const FilteredInputClass* pInPitch,
            const FilteredInputClass* pInVelocity,
            int outChannel,
            int basePitch) {
    pInTrigger_ = pInTrigger;
    pInPitch_ = pInPitch;
    pInVelocity_ = pInVelocity;
    outChannel_ = outChannel;
    basePitch_ = basePitch;
    reset();
  }
  
  void reset() {
    currentNote_ = 0;
    flagDynamicPitch_ = false;
  }
  
  void setDynamicPitchFlag(boolean flag) {
    flagDynamicPitch_ = flag;
  }
  
  void update() {
    if (currentNote_ == 0) {
      if (pInTrigger_->getValue() > 32) {
        currentNote_ = basePitch_;
        if (flagDynamicPitch_) currentNote_ += (pInPitch_->getValue() >> 2);
        int velocity = ((pInVelocity_->getValue() * 3) >> 2) + 32;
        MidiOut.sendNoteOn(outChannel_, currentNote_, velocity);
      }
    } else {
      if (pInTrigger_->getValue() < 16) {
        MidiOut.sendNoteOff(outChannel_, currentNote_, 64);
        currentNote_ = 0;
      }
    }
  }

private:
  const FilteredInputClass* pInTrigger_;
  const FilteredInputClass* pInPitch_;
  const FilteredInputClass* pInVelocity_;
  int outChannel_;
  int basePitch_;

  int currentNote_;
  boolean flagDynamicPitch_;
};

#endif // TRIGGER_H

