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
  // Minor pentatonic scale.
  int pickPitchMinorPentatonic(int index) {
    static int pitchArray[32] = {
      36, 39, 41, 43, 46,
      48, 51, 53, 55, 58,
      60, 63, 65, 67, 70,
      72, 75, 77, 79, 82,
      84, 87, 89, 91, 94,
      96, 99, 101, 103, 106,
      108, 111
    };
    return pitchArray[index & 31];
  };
  // Natural minor scale.
  int pickPitchMinor(int index) {
    static int pitchArray[32] = {
      36, 38, 39, 41, 43, 44, 46,
      48, 50, 51, 53, 55, 56, 58,
      60, 62, 63, 65, 67, 68, 70,
      72, 74, 75, 77, 79, 80, 80,
      84, 86, 87, 89
    };
    return pitchArray[index & 31];
  };
  // Pick a pitch on the current scale.
  int pickPitch(int index) {
    return pickPitchMinor(index);
  }
};

// Global instance.
ScaleClass Scale;
