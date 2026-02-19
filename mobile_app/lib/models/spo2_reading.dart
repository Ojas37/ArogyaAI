import 'package:flutter/material.dart';

enum Spo2Symptom {
  shortnessOfBreath,
  fastHeartbeat,
  coughing,
  wheezing,
  chestPain,
  confusion,
  blueLips,
  none,
}

class Spo2Reading {
  final int spo2;
  final String category;
  final Color color;
  final String title;
  final String message;
  final IconData icon;

  Spo2Reading({
    required this.spo2,
    required this.category,
    required this.color,
    required this.title,
    required this.message,
    required this.icon,
  });
}
