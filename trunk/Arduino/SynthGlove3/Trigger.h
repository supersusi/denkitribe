#ifndef TRIGGER_H
#define TRIGGER_H

template <class InputClass>
class TriggerTemplate {
public:
  void init(const InputClass* pInTrigger,
            const InputClass* pInPitch,
            const InputClass* pInVelocity,
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
    flagDynamicPitch_ = false;
    currentNote_ = 0;
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
  const InputClass* pInTrigger_;
  const InputClass* pInPitch_;
  const InputClass* pInVelocity_;
  
  int outChannel_;
  int basePitch_;

  boolean flagDynamicPitch_;
  int currentNote_;
};

#endif // TRIGGER_H

