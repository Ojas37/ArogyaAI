enum TemperatureLevel { green, yellow, red }

class TemperatureClassifier {
  static TemperatureLevel classify(double tempC) {
    if (tempC < 35.0 || tempC > 40.0) {
      return TemperatureLevel.red;
    } else if (tempC < 36.0 || tempC > 37.5) {
      return TemperatureLevel.yellow;
    } else {
      return TemperatureLevel.green;
    }
  }

  static String statusLabel(TemperatureLevel level) {
    switch (level) {
      case TemperatureLevel.green:
        return 'Normal';
      case TemperatureLevel.yellow:
        return 'Borderline';
      case TemperatureLevel.red:
        return 'Critical';
    }
  }

  static String advice(TemperatureLevel level) {
    switch (level) {
      case TemperatureLevel.green:
        return 'Temperature is normal.';
      case TemperatureLevel.yellow:
        return 'Monitor temperature. Consult a doctor if symptoms.';
      case TemperatureLevel.red:
        return 'Critical temperature! Seek medical attention.';
    }
  }
}
