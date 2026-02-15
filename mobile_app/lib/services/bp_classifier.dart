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
  static BPResult evaluate(double systolic, double diastolic) {
    if (systolic >= 180 || diastolic >= 120 || systolic < 70 || diastolic < 40) {
      return BPResult(
        level: BPLevel.red,
        status: 'Emergency',
        message: 'Critical BP! Seek medical attention immediately.',
        color: Colors.red.shade400,
      );
    } else if ((systolic >= 140 && systolic < 180) || (diastolic >= 90 && diastolic < 120) || (systolic < 90 && systolic >= 70) || (diastolic < 60 && diastolic >= 40)) {
      return BPResult(
        level: BPLevel.yellow,
        status: 'Warning',
        message: 'Your BP is borderline. Monitor regularly and consult a doctor.',
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
