enum BMILevel { green, yellow, red }

class BMIClassifier {
  static BMILevel classify(double bmi) {
    if (bmi < 16.0 || bmi > 40.0) {
      return BMILevel.red;
    } else if (bmi < 18.5 || bmi > 30.0) {
      return BMILevel.yellow;
    } else {
      return BMILevel.green;
    }
  }

  static String statusLabel(BMILevel level) {
    switch (level) {
      case BMILevel.green:
        return 'Normal';
      case BMILevel.yellow:
        return 'Borderline';
      case BMILevel.red:
        return 'Critical';
    }
  }

  static String advice(BMILevel level) {
    switch (level) {
      case BMILevel.green:
        return 'BMI is normal.';
      case BMILevel.yellow:
        return 'Monitor weight. Consult a doctor if needed.';
      case BMILevel.red:
        return 'Critical BMI! Seek medical attention.';
    }
  }
}
