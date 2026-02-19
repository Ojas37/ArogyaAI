import 'package:flutter/material.dart';
import '../models/spo2_reading.dart';

class Spo2Classifier {
  static Spo2Reading classifySpo2(int spo2, Set<Spo2Symptom> symptoms) {
    String category = getOxygenCategory(spo2, symptoms);
    Color color;
    String title;
    String message;
    IconData icon;

    switch (category) {
      case 'Emergency':
        color = Colors.red.shade700;
        title = 'MEDICAL EMERGENCY';
        message =
            'Critical oxygen level detected. Seek immediate medical attention.';
        icon = Icons.emergency;
        break;
      case 'Medium':
        color = Colors.orange.shade700;
        title = 'Low Oxygen Level';
        message = 'Your oxygen level is slightly low. Please consult a doctor.';
        icon = Icons.warning;
        break;
      default: // Normal
        color = Colors.green.shade700;
        title = 'Normal SpO₂';
        message = 'Your oxygen saturation is within the normal range.';
        icon = Icons.check_circle;
    }

    return Spo2Reading(
      spo2: spo2,
      category: category,
      color: color,
      title: title,
      message: message,
      icon: icon,
    );
  }

  static String getOxygenCategory(int spo2, Set<Spo2Symptom> symptoms) {
    final hasSevereSymptom = symptoms.any((s) =>
        s == Spo2Symptom.chestPain ||
        s == Spo2Symptom.blueLips ||
        s == Spo2Symptom.confusion);

    if (spo2 < 90) {
      return 'Emergency';
    }
    if (spo2 >= 90 && spo2 <= 94) {
      return hasSevereSymptom ? 'Emergency' : 'Medium';
    }
    // 95 to 100
    return 'Normal';
  }
}
