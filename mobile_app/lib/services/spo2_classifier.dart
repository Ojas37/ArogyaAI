enum SpO2Level { green, yellow, red }

enum SpO2Symptom {
  shortnessOfBreath,
  rapidBreathing,
  chestPain,
  confusion,
  blueLips,
  dizziness,
  fatigue,
  weakness,
  none,
}

class SpO2Classifier {
  static SpO2Level classify(double spo2) {
    if (spo2 < 90) {
      return SpO2Level.red;
    } else if (spo2 < 95) {
      return SpO2Level.yellow;
    } else {
      return SpO2Level.green;
    }
  }

  static String statusLabel(SpO2Level level) {
    switch (level) {
      case SpO2Level.green:
        return 'Normal';
      case SpO2Level.yellow:
        return 'Low';
      case SpO2Level.red:
        return 'Critical';
    }
  }

  static String advice(SpO2Level level) {
    switch (level) {
      case SpO2Level.green:
        return 'Oxygen saturation is normal.';
      case SpO2Level.yellow:
        return 'Low SpO2. Monitor and consult a doctor.';
      case SpO2Level.red:
        return 'Critical SpO2! Seek medical attention.';
    }
  }
}
