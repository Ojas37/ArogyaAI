import 'package:flutter/material.dart';

enum BPLevel { green, yellow, red }

enum BPSymptom {
  headache,
  dizziness,
  chestPain,
  shortnessOfBreath,
  nosebleeds,
  visionProblems,
  fatigue,
  palpitations,
  none,
}

class BPResult {
  final BPLevel level;
  final String status;
  final String message;
  final Color color;
  BPResult({required this.level, required this.status, required this.message, required this.color});
}

class BPClassifier {
  /// Returns "Normal", "Medium", or "Emergency" based on systolic/diastolic ranges.
  static String getBpCategory(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120 || systolic < 70 || diastolic < 40) {
      return 'Emergency';
    }

    final bool elevatedHigh = (systolic >= 140 && systolic < 180) || (diastolic >= 90 && diastolic < 120);
    final bool elevatedLow = (systolic >= 70 && systolic < 90) || (diastolic >= 40 && diastolic < 60);

    if (elevatedHigh || elevatedLow) {
      return 'Medium';
    }

    return 'Normal';
  }

  static BPResult evaluate(double systolic, double diastolic) {
    final category = getBpCategory(systolic.round(), diastolic.round());

    if (category == 'Emergency') {
      return BPResult(
        level: BPLevel.red,
        status: 'Emergency',
        message: 'Critical BP! Seek medical attention immediately.',
        color: Colors.red.shade400,
      );
    } else if (category == 'Medium') {
      return BPResult(
        level: BPLevel.yellow,
        status: 'Medium',
        message: 'Your BP is outside the ideal range. Monitor closely and consult a doctor.',
        color: Colors.orange.shade400,
      );
    } else {
      return BPResult(
        level: BPLevel.green,
        status: 'Normal',
        message: 'Your BP is normal. Maintain healthy habits.',
        color: Colors.green.shade400,
      );
    }
  }
}
