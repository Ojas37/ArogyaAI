enum HeartRateLevel { green, yellow, red }

class HeartRateClassifier {
  static HeartRateLevel classify(int bpm) {
    if (bpm < 40 || bpm > 130) {
      return HeartRateLevel.red;
    } else if (bpm < 60 || bpm > 100) {
      return HeartRateLevel.yellow;
    } else {
      return HeartRateLevel.green;
    }
  }

  static String statusLabel(HeartRateLevel level) {
    switch (level) {
      case HeartRateLevel.green:
        return 'Normal';
      case HeartRateLevel.yellow:
        return 'Borderline';
      case HeartRateLevel.red:
        return 'Critical';
    }
  }

  static String advice(HeartRateLevel level) {
    switch (level) {
      case HeartRateLevel.green:
        return 'Heart rate is normal.';
      case HeartRateLevel.yellow:
        return 'Monitor your heart rate. Consult a doctor if symptoms.';
      case HeartRateLevel.red:
        return 'Critical heart rate! Seek medical attention.';
    }
  }
}
