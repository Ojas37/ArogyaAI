enum CholesterolLevel { green, yellow, red }

class CholesterolClassifier {
  static CholesterolLevel classify(double totalCholesterolMgDl) {
    if (totalCholesterolMgDl >= 240) {
      return CholesterolLevel.red;
    } else if (totalCholesterolMgDl >= 200) {
      return CholesterolLevel.yellow;
    } else {
      return CholesterolLevel.green;
    }
  }

  static String statusLabel(CholesterolLevel level) {
    switch (level) {
      case CholesterolLevel.green:
        return 'Normal';
      case CholesterolLevel.yellow:
        return 'Borderline';
      case CholesterolLevel.red:
        return 'High';
    }
  }

  static String advice(CholesterolLevel level) {
    switch (level) {
      case CholesterolLevel.green:
        return 'Cholesterol is in a healthy range.';
      case CholesterolLevel.yellow:
        return 'Borderline cholesterol. Consider diet and exercise.';
      case CholesterolLevel.red:
        return 'High cholesterol. Consult a doctor.';
    }
  }
}
