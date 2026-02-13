enum BloodSugarLevel {
  red,    // Emergency
  orange, // Urgent
  green,  // Normal/Manage
}

enum BloodSugarSymptom {
  confusion,
  fainting,
  vomiting,
  breathingTrouble,
  unconscious,
  excessiveThirst,
  frequentUrination,
  fatigue,
  blurredVision,
  none,
}

class BloodSugarReading {
  final double sugarValue; // mg/dL
  final List<BloodSugarSymptom> symptoms;
  final DateTime timestamp;
  final BloodSugarLevel level;
  final String message;
  final String facilityType; // hospital, clinic, pharmacy

  BloodSugarReading({
    required this.sugarValue,
    required this.symptoms,
    required this.timestamp,
    required this.level,
    required this.message,
    required this.facilityType,
  });

  bool get isEmergency => level == BloodSugarLevel.red;
  bool get isUrgent => level == BloodSugarLevel.orange;
  bool get isNormal => level == BloodSugarLevel.green;

  bool get hasSevereSymptoms {
    return symptoms.any((symptom) =>
        symptom == BloodSugarSymptom.confusion ||
        symptom == BloodSugarSymptom.fainting ||
        symptom == BloodSugarSymptom.vomiting ||
        symptom == BloodSugarSymptom.breathingTrouble ||
        symptom == BloodSugarSymptom.unconscious);
  }

  Map<String, dynamic> toJson() {
    return {
      'sugarValue': sugarValue,
      'symptoms': symptoms.map((s) => s.toString().split('.').last).toList(),
      'timestamp': timestamp.toIso8601String(),
      'level': level.toString().split('.').last,
      'message': message,
      'facilityType': facilityType,
    };
  }

  factory BloodSugarReading.fromJson(Map<String, dynamic> json) {
    return BloodSugarReading(
      sugarValue: json['sugarValue'],
      symptoms: (json['symptoms'] as List)
          .map((s) => BloodSugarSymptom.values.firstWhere(
              (e) => e.toString().split('.').last == s))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
      level: BloodSugarLevel.values.firstWhere(
          (e) => e.toString().split('.').last == json['level']),
      message: json['message'],
      facilityType: json['facilityType'],
    );
  }
}
