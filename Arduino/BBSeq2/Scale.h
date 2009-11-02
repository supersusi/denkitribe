// Used to pick a pitch on a musical scale.
class ScaleClass {
public:
  // Pentatonic scale.
  int pickPitchPentatonic(int index) {
    static int pitchArray[32] = {
      36, 38, 40, 43, 45,
      48, 50, 52, 55, 57,
      60, 62, 64, 67, 69,
      72, 74, 76, 79, 81,
      84, 86, 88, 91, 93,
      96, 98, 100, 103, 105,
      108, 110
    };
    return pitchArray[index & 31];
  };
  // Pick a pitch on the current scale.
  int pickPitch(int index) {
    return pickPitchPentatonic(index);
  }
};

// Global instance.
ScaleClass Scale;
