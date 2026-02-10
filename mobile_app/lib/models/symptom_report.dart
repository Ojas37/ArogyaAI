class SymptomReport {
  final String id;
  final String userId;
  final String language;
  final String textInput;
  final List<String> symptoms;
  final Map<String, double>? vitals;
  final DateTime timestamp;
  final bool isSynced;

  SymptomReport({
    required this.id,
    required this.userId,
    required this.language,
    required this.textInput,
    this.symptoms = const [],
    this.vitals,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'language': language,
      'textInput': textInput,
      'symptoms': symptoms,
      'vitals': vitals,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory SymptomReport.fromJson(Map<String, dynamic> json) {
    return SymptomReport(
      id: json['id'],
      userId: json['userId'],
      language: json['language'],
      textInput: json['textInput'],
      symptoms: List<String>.from(json['symptoms'] ?? []),
      vitals: json['vitals'] != null 
          ? Map<String, double>.from(json['vitals']) 
          : null,
      timestamp: DateTime.parse(json['timestamp']),
      isSynced: json['isSynced'] ?? false,
    );
  }
}
