import '../models/blood_sugar_reading.dart';

class BloodSugarClassifier {
  /// Classify blood sugar reading into RED, ORANGE, or GREEN level
  static BloodSugarReading classifyReading({
    required double sugarValue,
    required List<BloodSugarSymptom> symptoms,
  }) {
    BloodSugarLevel level;
    String message;
    String facilityType;

    // Check for severe symptoms
    final hasSevereSymptoms = symptoms.any((symptom) =>
        symptom == BloodSugarSymptom.confusion ||
        symptom == BloodSugarSymptom.fainting ||
        symptom == BloodSugarSymptom.vomiting ||
        symptom == BloodSugarSymptom.breathingTrouble ||
        symptom == BloodSugarSymptom.unconscious);

    // Classification logic
    if (sugarValue >= 600 || hasSevereSymptoms) {
      // RED - Emergency
      level = BloodSugarLevel.red;
      message = 'EMERGENCY: Your reading is very high and may be life-threatening. '
          'Please seek emergency care NOW.';
      facilityType = 'hospital';
    } else if (sugarValue >= 300 || (sugarValue > 180 && symptoms.isNotEmpty)) {
      // ORANGE - Urgent
      level = BloodSugarLevel.orange;
      message = 'URGENT: Your blood sugar is high. '
          'Please consult a doctor or visit a clinic soon.';
      facilityType = 'hospital,clinic';
    } else {
      // GREEN - Normal/Manage
      level = BloodSugarLevel.green;
      if (sugarValue >= 80 && sugarValue <= 130) {
        message = 'Your fasting blood sugar is in the normal range. '
            'Continue monitoring and maintain healthy habits.';
      } else if (sugarValue < 180) {
        message = 'Your blood sugar is acceptable. '
            'Continue monitoring and consult with your doctor if needed.';
      } else {
        message = 'Your blood sugar is slightly elevated. '
            'Monitor closely and consult with your doctor.';
      }
      facilityType = 'pharmacy';
    }

    return BloodSugarReading(
      sugarValue: sugarValue,
      symptoms: symptoms,
      timestamp: DateTime.now(),
      level: level,
      message: message,
      facilityType: facilityType,
    );
  }

  /// Get emergency phone numbers based on country/region
  static String getEmergencyNumber({String country = 'IN'}) {
    // Default to India
    switch (country.toUpperCase()) {
      case 'IN':
        return '102'; // Ambulance in India
      case 'US':
        return '911';
      case 'UK':
        return '999';
      default:
        return '112'; // International emergency number
    }
  }

  /// Get severity color for UI
  static String getLevelColor(BloodSugarLevel level) {
    switch (level) {
      case BloodSugarLevel.red:
        return '#D32F2F'; // Red
      case BloodSugarLevel.orange:
        return '#F57C00'; // Orange
      case BloodSugarLevel.green:
        return '#388E3C'; // Green
    }
  }

  /// Get severity label
  static String getLevelLabel(BloodSugarLevel level) {
    switch (level) {
      case BloodSugarLevel.red:
        return 'EMERGENCY';
      case BloodSugarLevel.orange:
        return 'URGENT';
      case BloodSugarLevel.green:
        return 'NORMAL';
    }
  }
}
