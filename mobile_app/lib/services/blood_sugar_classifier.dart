import '../models/blood_sugar_reading.dart';
import 'package:flutter/material.dart';

class BloodSugarClassifier {
  /// Classify blood sugar reading into 3 categories:
  /// - NORMAL → 70 to 140 mg/dL
  /// - MEDIUM → 141 to 250 OR below 70 mg/dL
  /// - EMERGENCY → Above 250 mg/dL
  static BloodSugarReading getSugarCategory({
    required double sugarValue,
    List<BloodSugarSymptom>? symptoms,
  }) {
    BloodSugarLevel level;
    String message;
    String facilityType;
    bool autoFetchHospitals;
    bool showAmbulanceButton;

    // Classification logic based on exact requirements
    if (sugarValue > 250) {
      // EMERGENCY
      level = BloodSugarLevel.red;
      message = 'Medical Emergency! Seek immediate care.';
      facilityType = 'hospital';
      autoFetchHospitals = true;
      showAmbulanceButton = true;
    } else if ((sugarValue >= 141 && sugarValue <= 250) || sugarValue < 70) {
      // MEDIUM
      level = BloodSugarLevel.orange;
      message = 'Your blood sugar is abnormal. Please consult a doctor.';
      facilityType = 'hospital';
      autoFetchHospitals = false;
      showAmbulanceButton = false;
    } else {
      // NORMAL (70 to 140)
      level = BloodSugarLevel.green;
      message = 'Your blood sugar is within the healthy range.';
      facilityType = '';
      autoFetchHospitals = false;
      showAmbulanceButton = false;
    }

    return BloodSugarReading(
      sugarValue: sugarValue,
      symptoms: symptoms ?? [],
      timestamp: DateTime.now(),
      level: level,
      message: message,
      facilityType: facilityType,
    );
  }

  /// Legacy method for backward compatibility
  static BloodSugarReading classifyReading({
    required double sugarValue,
    required List<BloodSugarSymptom> symptoms,
  }) {
    return getSugarCategory(
      sugarValue: sugarValue,
      symptoms: symptoms,
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
  static Color getLevelColor(BloodSugarLevel level) {
    switch (level) {
      case BloodSugarLevel.red:
        return Colors.red.shade600;
      case BloodSugarLevel.orange:
        return Colors.orange.shade600;
      case BloodSugarLevel.green:
        return Colors.green.shade600;
    }
  }

  /// Get icon for blood sugar level
  static IconData getIcon(BloodSugarLevel level) {
    switch (level) {
      case BloodSugarLevel.green:
        return Icons.check_circle;
      case BloodSugarLevel.orange:
        return Icons.warning;
      case BloodSugarLevel.red:
        return Icons.emergency;
    }
  }

  /// Get severity label
  static String getLevelLabel(BloodSugarLevel level) {
    switch (level) {
      case BloodSugarLevel.red:
        return 'EMERGENCY';
      case BloodSugarLevel.orange:
        return 'ABNORMAL';
      case BloodSugarLevel.green:
        return 'NORMAL';
    }
  }

  /// Determine if hospitals should be shown
  static bool shouldShowHospitals(BloodSugarLevel level) {
    return level == BloodSugarLevel.red || level == BloodSugarLevel.orange;
  }

  /// Determine if hospitals should be auto-fetched
  static bool shouldAutoFetchHospitals(BloodSugarLevel level) {
    return level == BloodSugarLevel.red;
  }

  /// Determine if ambulance button should be shown
  static bool shouldShowAmbulanceButton(BloodSugarLevel level) {
    return level == BloodSugarLevel.red;
  }
}
